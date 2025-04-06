SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

SlashCmdList["MAGECONTROL"] = function(msg)
    local command = string.lower(msg)

    if command == "atk" then
        
    elseif command == "arcane" then
        isRuptureRepeated = false
        checkChannelFinished()
        CastArcaneAttack()
    else
        print("MageControl: Unknown command. Available commands: arcane")
    end
end

local isChanneling = false
local channelFinishTime = 0
local isCastingArcaneRupture = false
local globalCooldownActive = false
local globalCooldownStart = 0
local lastSpellCast = ""
local isRuptureRepeated = false;

local FIREBLAST_ID = 10199
local ARCANE_SURGE_ID = 51936
local ARCANE_EXPLOSION_ID = 10202
local ARCANE_MISSILES_ID = 25345
local ARCANE_RUPTURE_ID = 51954

local spellNames = {
    [FIREBLAST_ID] = "Fireblast",
    [ARCANE_SURGE_ID] = "Arcane Surge",
    [ARCANE_EXPLOSION_ID] = "Arcane Explosion",
    [ARCANE_MISSILES_ID] = "Arcane Missiles",
    [ARCANE_RUPTURE_ID] = "Arcane Rupture"
  }

local ACTIONBAR_SLOT_FIREBLAST = 1
local ACTIONBAR_SLOT_ARCANE_RUPTURE = 2
local ACTIONBAR_SLOT_ARCANE_MISSILES = 3
local ACTIONBAR_SLOT_ARCANE_SURGE = 5

local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
MageControlFrame:RegisterEvent("SPELLCAST_START")
MageControlFrame:RegisterEvent("SPELLCAST_STOP")
MageControlFrame:RegisterEvent("SPELL_CAST_EVENT")
MageControlFrame:RegisterEvent("SPELLCAST_FAILED")
MageControlFrame:RegisterEvent("SPELLCAST_INTERRUPTED")

MageControlFrame:SetScript("OnEvent", function()
    if event == "SPELLCAST_CHANNEL_START" then
        isChanneling = true
        channelFinishTime = GetTime() + ((arg1 - 0)/1000)
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        isChanneling = false
    end
    if event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            isCastingArcaneRupture = true;
        end
    end 
    if event == "SPELLCAST_STOP" then
        isCastingArcaneRupture = false;
    end 
    if event == "SPELL_CAST_EVENT" then
        lastSpellCast = spellNames[arg2] or "Unknown Spell"
        if (arg2 == FIREBLAST_ID or arg2 == ARCANE_SURGE_ID or arg2 == ARCANE_EXPLOSION_ID) then
            globalCooldownActive = true;
            globalCooldownStart = GetTime();
        end
    end
    if (event=="SPELLCAST_FAILED" or event=="SPELLCAST_INTERRUPTED") then
        if (lastSpellCast == "Arcane Rupture" and not isRuptureRepeated) then
            isRuptureRepeated = true;
            CastArcaneAttack()
        end
    end
end)

function checkChannelFinished()
    if (channelFinishTime < GetTime()) then
        isChanneling = false
    end
end


function CastArcaneAttack()
    -- Manage global CD
    if (GetTime() - globalCooldownStart > 1.5) then
        globalCooldownActive = false
    end

    -- TODO: 
    --FIXED: CASE spell wird abgebrochen, aber man queued missles vorher. !!!!!!!!!!!!!!!!!!!
    --FIXED: CASE nichts passiert wenn Arcane Rupture fast bereit ist (Range Problem mit Fire Blast?)
    --CASE: Haste > 20% skip Surge

    local buffsWithDurations = GetBuffs()
    local arcaneRuptureIsReady = IsActionSlotCooldownReady(2)
    local arcaneSurgeIsReadyAndActive = IsActionSlotCooldownReady(5)
    local isCurrentlyChannelingSomeSpell = isChanneling
    local playerHasLowMana = IsLowMana()
    local isFireblastReady = IsActionSlotCooldownReady(1)

    --print("Fireblast CD is " .. getFireblastCooldown)

    -- Extrahiere die Buffs, die uns interessieren:
    local clearcastingBuff = nil
    local temporalConvergenceBuff = nil
    local arcaneRuptureBuff = nil

    for i, buff in ipairs(buffsWithDurations) do
        if buff.name == "Clearcasting" then
            clearcastingBuff = buff
        elseif buff.name == "Temporal Convergence" then
            temporalConvergenceBuff = buff
        elseif buff.name == "Arcane Rupture" then
            arcaneRuptureBuff = buff
        end
    end
    

    -- TODO: Check warum nach Surge manchmal missles kommen statt Rupture

    if (isCurrentlyChannelingSomeSpell and not arcaneRuptureBuff and arcaneRuptureIsReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Rupture")
    end

    if clearcastingBuff and arcaneRuptureBuff and arcaneRuptureBuff.duration and arcaneRuptureBuff.duration > 2 then
        QueueSpellByName("Arcane Missiles")
        return
    end

    if arcaneSurgeIsReadyAndActive then
        QueueSpellByName("Arcane Surge")
        globalCooldownActive = true
        globalCooldownStart = GetTime()
        return
    end

    if temporalConvergenceBuff and temporalConvergenceBuff.duration and temporalConvergenceBuff.duration > 2.8 and arcaneRuptureIsReady and not isCastingArcaneRupture then
        QueueSpellByName("Arcane Rupture")
        return
    end

    if clearcastingBuff and playerHasLowMana then
        QueueSpellByName("Arcane Missiles")
        return
    end

    if arcaneRuptureIsReady and not isCastingArcaneRupture then
        QueueSpellByName("Arcane Rupture")
        return
    end

    if (isArcaneRuptureOneGlobalAway(ACTIONBAR_SLOT_ARCANE_RUPTURE) and isFireblastReady and IsSpellInRange(FIREBLAST_ID)) then
        QueueSpellByName("Fire Blast")
        globalCooldownActive = true
        globalCooldownStart = GetTime()
        return
    end
    QueueSpellByName("Arcane Missiles")
end

function GetBuffs()
    local buffs = {}
    for i = 0, 31 do 
        local buffIndex = GetPlayerBuff(i, "HELPFUL|PASSIVE")
        if buffIndex >= 0 then
        
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetPlayerBuff(buffIndex)
            local buffName = GameTooltipTextLeft1:GetText() or "Unbekannt"
            GameTooltip:Hide()
            
            local duration = GetPlayerBuffTimeLeft(buffIndex, "HELPFUL|PASSIVE")
            if (buffName == "Clearcasting" or buffName == "Temporal Convergence") then
                table.insert(buffs, { name = buffName, duration = duration })
            end
        end
    end

    for i = 0, 31 do 
        local buffIndex = GetPlayerBuff(i, "HARMFUL")
        if buffIndex >= 0 then
        
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetPlayerBuff(buffIndex)
            local buffName = GameTooltipTextLeft1:GetText() or ""
            GameTooltip:Hide()
            
            local duration = GetPlayerBuffTimeLeft(buffIndex, "HARMFUL")
            
            if (buffName == "Arcane Rupture") then
                table.insert(buffs, { name = buffName, duration = duration })
            end
        end
    end
    return buffs
end

function IsActionSlotCooldownReady(slot)
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable then
        --print("Spell im Slot " .. slot .. " ist nicht benutzbar (grau oder benötigt Proc).")
        return false
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    local remaining = (start + duration) - currentTime

    local isJustGlobalCooldown = false;

    if remaining > 0 and globalCooldownActive then
        local remainingGlobalCd = 1.6 - (GetTime() - globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
            --print("Just Global CD!")
        end
    end

    if remaining > 0 and not isJustGlobalCooldown then
        --print("Spell im Slot " .. slot .. " ist noch " .. math.floor(remaining) .. " Sekunden auf Cooldown.")
        return false
    else
        --print("Spell im Slot " .. slot .. " ist bereit.")
        return true
    end
end

function isArcaneRuptureOneGlobalAway(slot)
    local cooldown = getActionSlotCooldownInMilliseconds(slot)
    --print("Debug: Cooldown is " .. cooldown)
    return (cooldown < 1.6 and cooldown > 0)
end

function getActionSlotCooldownInMilliseconds(slot)
    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    local remaining = (start + duration) - currentTime
    return remaining
end

function IsLowMana()
    local currentMana = UnitMana("player")
    local maxMana = UnitManaMax("player")
    if maxMana <= 0 then
        return false 
    end

    local manaRatio = currentMana / maxMana
    if manaRatio < 0.2 then
        return true
    else
        return false
    end
end