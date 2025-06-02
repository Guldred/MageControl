SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

-- Globale Konstanten zusammenfassen
local MC = {
    -- Cooldown-Konstanten
    GLOBAL_COOLDOWN_IN_SECONDS = 1.5,
    
    -- Spell-IDs
    SPELL_ID = {
        FIREBLAST = 10199,
        ARCANE_SURGE = 51936,
        ARCANE_EXPLOSION = 10202,
        ARCANE_MISSILES = 25345,
        ARCANE_RUPTURE = 51954
    },
    
    -- Actionbar-Slots
    ACTIONBAR_SLOT = {
        FIREBLAST = 1,
        ARCANE_RUPTURE = 2,
        ARCANE_SURGE = 5
    },
    
    -- Spell-Namen
    SPELL_NAME = {}
}

-- Spell-Namen aus IDs generieren
MC.SPELL_NAME[MC.SPELL_ID.FIREBLAST] = "Fireblast"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_SURGE] = "Arcane Surge"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_EXPLOSION] = "Arcane Explosion"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_MISSILES] = "Arcane Missiles"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_RUPTURE] = "Arcane Rupture"

-- Zustandsvariablen zusammenfassen
local state = {
    isChanneling = false,
    channelFinishTime = 0,
    isCastingArcaneRupture = false,
    globalCooldownActive = false,
    globalCooldownStart = 0,
    lastSpellCast = "",
    isRuptureRepeated = false,
    expectedCastFinishTime = 0
}

-- Funktionsdeklarationen vorweg (damit Funktionen sich gegenseitig aufrufen können)
local checkChannelFinished, CastArcaneAttack

-- Prüft, ob der Channel beendet ist
checkChannelFinished = function()
    if (state.channelFinishTime < GetTime()) then
        state.isChanneling = false
    end
end

-- Führt Arcane Explosion aus, wenn der GCD fast abgelaufen ist
local function QueueArcaneExplosion()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - state.globalCooldownStart)
    if(gcdRemaining < 0.75) then
        QueueSpellByName("Arcane Explosion")
    end
end

-- Prüft, ob eine Aktionsleiste bereit ist
local function IsActionSlotCooldownReady(slot)
    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable then
        return false
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    local remaining = (start + duration) - currentTime
    
    -- Prüfen, ob nur der globale Cooldown aktiv ist
    local isJustGlobalCooldown = false
    if remaining > 0 and state.globalCooldownActive then
        local remainingGlobalCd = 1.6 - (GetTime() - state.globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
        end
    end

    if remaining > 0 and not isJustGlobalCooldown then
        return false
    else
        return true
    end
end

-- Holt den verbleibenden Cooldown eines Aktionsslots in Sekunden
local function getActionSlotCooldownInMilliseconds(slot)
    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

-- Prüft, ob Arcane Rupture in ca. einem Global Cooldown verfügbar ist
local function isArcaneRuptureOneGlobalAway(slot)
    local cooldown = getActionSlotCooldownInMilliseconds(slot)
    return (cooldown < 1.6 and cooldown > 0)
end

-- Holt alle aktiven Buffs mit Dauer
local function GetBuffs()
    local buffs = {}
    
    -- Hilfreiche Buffs
    for i = 0, 31 do 
        local buffIndex = GetPlayerBuff(i, "HELPFUL|PASSIVE")
        if buffIndex >= 0 then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetPlayerBuff(buffIndex)
            local buffName = GameTooltipTextLeft1:GetText() or "Unbekannt"
            GameTooltip:Hide()
            
            local duration = GetPlayerBuffTimeLeft(buffIndex, "HELPFUL|PASSIVE")
            if (buffName == "Clearcasting" or buffName == "Temporal Convergence" or buffName == "Arcane Power") then
                table.insert(buffs, { name = buffName, duration = duration })
            end
        end
    end

    -- Schädliche Buffs (für Arcane Rupture)
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

-- Führt die optimale Zaubersequenz aus
CastArcaneAttack = function()
    if (GetTime() - state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        state.globalCooldownActive = false
    end

    local buffsWithDurations = GetBuffs()
    local isArcaneRuptureReady = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.ARCANE_RUPTURE)
    local isArcaneSurgeReadyAndActive = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.ARCANE_SURGE)
    local isCurrentlyChannelingSomeSpell = state.isChanneling
    local isFireblastReadyAndInRange = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.FIREBLAST) and (IsSpellInRange(MC.SPELL_ID.FIREBLAST) == 1)

    local clearCastingBuff = nil
    local temporalConvergenceBuff = nil
    local arcaneRuptureBuff = nil
    local arcanePowerBuff = nil

    for i, buff in ipairs(buffsWithDurations) do
        if buff.name == "Clearcasting" then
            clearCastingBuff = buff
        elseif buff.name == "Temporal Convergence" then
            temporalConvergenceBuff = buff
        elseif buff.name == "Arcane Rupture" then
            arcaneRuptureBuff = buff
        elseif buff.name == "Arcane Power" then
            arcanePowerBuff = buff
        end
    end

    if (isCurrentlyChannelingSomeSpell and not arcaneRuptureBuff and isArcaneRuptureReady) then
        ChannelStopCastingNextTick()
        if (isArcaneSurgeReadyAndActive and not arcanePowerBuff) then
            QueueSpellByName("Arcane Surge")
        else
            QueueSpellByName("Arcane Rupture")
        end
        return
    end

    local timeToCastFinish = state.expectedCastFinishTime - GetTime()
    if (timeToCastFinish > 0.75) then
        return
    end

    if (isArcaneSurgeReadyAndActive and not arcanePowerBuff) then
        QueueSpellByName("Arcane Surge")
        return
    end

    if clearCastingBuff and arcaneRuptureBuff and arcaneRuptureBuff.duration and arcaneRuptureBuff.duration > 2 then
        QueueSpellByName("Arcane Missiles")
        return
    end

    if isArcaneRuptureReady and not state.isCastingArcaneRupture then
        QueueSpellByName("Arcane Rupture")
        return
    end

    if (isArcaneRuptureOneGlobalAway(MC.ACTIONBAR_SLOT.ARCANE_RUPTURE) and isFireblastReadyAndInRange) then
        if (isArcaneSurgeReadyAndActive) then
            QueueSpellByName("Arcane Surge")
            return
        elseif (isFireblastReadyAndInRange) then
            QueueSpellByName("Fire Blast")
            return
        end
    end

    QueueSpellByName("Arcane Missiles")
end

-- Slash-Befehle
SlashCmdList["MAGECONTROL"] = function(msg)
    local command = string.lower(msg)

    if command == "explosion" then
        QueueArcaneExplosion()
    elseif command == "arcane" then
        state.isRuptureRepeated = false
        checkChannelFinished()
        CastArcaneAttack()
    else
        print("MageControl: Unknown command. Available commands: arcane, explosion")
    end
end

-- Event-Handler erstellen und registrieren
local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
MageControlFrame:RegisterEvent("SPELLCAST_START")
MageControlFrame:RegisterEvent("SPELLCAST_STOP")
MageControlFrame:RegisterEvent("SPELL_CAST_EVENT")
MageControlFrame:RegisterEvent("SPELLCAST_FAILED")
MageControlFrame:RegisterEvent("SPELLCAST_INTERRUPTED")

-- Event-Handler-Funktion
MageControlFrame:SetScript("OnEvent", function()
    if event == "SPELLCAST_CHANNEL_START" then
        state.isChanneling = true
        state.channelFinishTime = GetTime() + ((arg1 - 0)/1000)
        state.expectedCastFinishTime = state.channelFinishTime
    
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        state.isChanneling = false
        state.expectedCastFinishTime = 0
    
    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            state.isCastingArcaneRupture = true
            state.expectedCastFinishTime = GetTime() + (arg2/1000)
        end
    
    elseif event == "SPELLCAST_STOP" then
        state.isCastingArcaneRupture = false
    
    elseif event == "SPELL_CAST_EVENT" then
        state.lastSpellCast = MC.SPELL_NAME[arg2] or "Unknown Spell"
        
        if (arg2 == MC.SPELL_ID.FIREBLAST or 
            arg2 == MC.SPELL_ID.ARCANE_SURGE or 
            arg2 == MC.SPELL_ID.ARCANE_EXPLOSION) then
            
            state.globalCooldownActive = true
            state.globalCooldownStart = GetTime()
            state.expectedCastFinishTime = GetTime() + MC.GLOBAL_COOLDOWN_IN_SECONDS
        end
    
    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        state.isChanneling = false
        state.isCastingArcaneRupture = false
        state.expectedCastFinishTime = 0
        
        if (state.lastSpellCast == "Arcane Rupture" and not state.isRuptureRepeated) then
            state.isRuptureRepeated = true
            CastArcaneAttack()
        end
    end
end)