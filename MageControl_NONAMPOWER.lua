SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

--TODO: Add Global CD Detection

SlashCmdList["MAGECONTROL"] = function(msg)
    local command = string.lower(msg)

    if command == "atk" then
        
    elseif command == "arcane" then
        checkChannelFinished()
        CastArcaneAttack()
    else
        print("MageControl: Unknown command. Available commands: arcane")
    end
end

local isChanneling = false
local channelFinishTime = 0

local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")

MageControlFrame:SetScript("OnEvent", function()
    if event == "SPELLCAST_CHANNEL_START" then
        isChanneling = true
        channelFinishTime = GetTime() + ((arg1 - 0)/1000)
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        isChanneling = false
    end
end)

function checkChannelFinished()
    if (channelFinishTime < GetTime()) then
        isChanneling = false
    end
end


function CastArcaneAttack()
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

    if isCurrentlyChannelingSomeSpell then
        return
    end

    if clearcastingBuff and arcaneRuptureBuff and arcaneRuptureBuff.duration and arcaneRuptureBuff.duration > 2 then
        CastSpellByName("Arcane Missiles")
        return
    end

    if arcaneSurgeIsReadyAndActive then
        CastSpellByName("Arcane Surge")
        return
    end

    if temporalConvergenceBuff and temporalConvergenceBuff.duration and temporalConvergenceBuff.duration > 2.3 and arcaneRuptureIsReady then
        CastSpellByName("Arcane Rupture")
        return
    end

    if clearcastingBuff and playerHasLowMana then
        CastSpellByName("Arcane Missiles")
        return
    end

    if arcaneRuptureIsReady then
        CastSpellByName("Arcane Rupture")
        return
    end

    if (isArcaneRuptureOneGlobalAway(2) and isFireblastReady) then
        CastSpellByName("Fire Blast")
        return
    end

    CastSpellByName("Arcane Missiles")
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
            local buffName = GameTooltipTextLeft1:GetText() or "Unbekannt"
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

    if remaining > 0 then
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