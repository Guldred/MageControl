SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

-- Globale Konstanten zusammenfassen
local MC = {
    -- Cooldown-Konstanten
    GLOBAL_COOLDOWN_IN_SECONDS = 1.5,
    
    -- Timing-Konstanten
    TIMING = {
        CAST_FINISH_THRESHOLD = 0.75,
        GCD_REMAINING_THRESHOLD = 0.75,
        GCD_BUFFER = 1.6,
        ARCANE_RUPTURE_MIN_DURATION = 2
    },
    
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
    SPELL_NAME = {},
    
    -- Buff-Namen
    BUFF_NAME = {
        CLEARCASTING = "Clearcasting",
        TEMPORAL_CONVERGENCE = "Temporal Convergence", 
        ARCANE_POWER = "Arcane Power",
        ARCANE_RUPTURE = "Arcane Rupture"
    },
    
    -- Debug-Modus
    DEBUG = false
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

-- Funktionsdeklarationen vorweg
local checkChannelFinished, CastArcaneAttack

-- Debug-Funktionalität
local function debugPrint(message)
    if MC.DEBUG then
        print("MageControl Debug: " .. message)
    end
end

-- Validierung für Actionbar-Slots
local function isValidActionSlot(slot)
    return slot and slot > 0 and slot <= 120
end

-- Sichere Spell-Ausführung
local function safeQueueSpell(spellName)
    if not spellName or spellName == "" then
        print("MageControl: Invalid spell name")
        return false
    end
    
    debugPrint("Queueing spell: " .. spellName)
    QueueSpellByName(spellName)
    return true
end

-- Hilfsfunktion zum Finden spezifischer Buffs
local function findBuff(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end

-- Prüft, ob der Channel beendet ist
checkChannelFinished = function()
    if (state.channelFinishTime < GetTime()) then
        state.isChanneling = false
    end
end

-- Führt Arcane Explosion aus, wenn der GCD fast abgelaufen ist
local function QueueArcaneExplosion()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - state.globalCooldownStart)
    if(gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD) then
        safeQueueSpell("Arcane Explosion")
    end
end

-- Prüft, ob eine Aktionsleiste bereit ist
local function IsActionSlotCooldownReady(slot)
    if not isValidActionSlot(slot) then
        return false
    end
    
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
        local remainingGlobalCd = MC.TIMING.GCD_BUFFER - (GetTime() - state.globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
        end
    end

    return remaining <= 0 or isJustGlobalCooldown
end

-- Holt den verbleibenden Cooldown eines Aktionsslots in Sekunden
local function getActionSlotCooldownInMilliseconds(slot)
    if not isValidActionSlot(slot) then
        return 0
    end
    
    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

-- Prüft, ob Arcane Rupture in ca. einem Global Cooldown verfügbar ist
local function isArcaneRuptureOneGlobalAway(slot)
    local cooldown = getActionSlotCooldownInMilliseconds(slot)
    return (cooldown < MC.TIMING.GCD_BUFFER and cooldown > 0)
end

-- Optimierte Buff-Suche
local function GetBuffs()
    local buffs = {}
    local relevantBuffs = {
        [MC.BUFF_NAME.CLEARCASTING] = true,
        [MC.BUFF_NAME.TEMPORAL_CONVERGENCE] = true,
        [MC.BUFF_NAME.ARCANE_POWER] = true
    }
    
    -- Hilfreiche Buffs
    for i = 0, 31 do 
        local buffIndex = GetPlayerBuff(i, "HELPFUL|PASSIVE")
        if buffIndex >= 0 then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetPlayerBuff(buffIndex)
            local buffName = GameTooltipTextLeft1:GetText() or "Unbekannt"
            GameTooltip:Hide()
            
            if relevantBuffs[buffName] then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HELPFUL|PASSIVE")
                table.insert(buffs, { name = buffName, duration = duration })
            end
        end
    end

    -- Schädliche Buffs (nur Arcane Rupture)
    for i = 0, 31 do 
        local buffIndex = GetPlayerBuff(i, "HARMFUL")
        if buffIndex >= 0 then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            GameTooltip:SetPlayerBuff(buffIndex)
            local buffName = GameTooltipTextLeft1:GetText() or ""
            GameTooltip:Hide()
            
            if buffName == MC.BUFF_NAME.ARCANE_RUPTURE then
                local duration = GetPlayerBuffTimeLeft(buffIndex, "HARMFUL")
                table.insert(buffs, { name = buffName, duration = duration })
            end
        end
    end
    
    return buffs
end

-- Prüft Spell-Verfügbarkeit
local function getSpellAvailability()
    return {
        arcaneRuptureReady = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.ARCANE_RUPTURE),
        arcaneSurgeReady = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.ARCANE_SURGE),
        fireblastReady = IsActionSlotCooldownReady(MC.ACTIONBAR_SLOT.FIREBLAST) and 
                        (IsSpellInRange(MC.SPELL_ID.FIREBLAST) == 1)
    }
end

-- Prüft aktuelle Buffs
local function getCurrentBuffs()
    local buffs = GetBuffs()
    return {
        clearcasting = findBuff(buffs, MC.BUFF_NAME.CLEARCASTING),
        temporalConvergence = findBuff(buffs, MC.BUFF_NAME.TEMPORAL_CONVERGENCE),
        arcaneRupture = findBuff(buffs, MC.BUFF_NAME.ARCANE_RUPTURE),
        arcanePower = findBuff(buffs, MC.BUFF_NAME.ARCANE_POWER)
    }
end

-- Prüft, ob noch gecastet wird oder der Cast bald fertig ist
local function shouldWaitForCast()
    local timeToCastFinish = state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

-- Entscheidet über Channel-Unterbrechung
local function handleChannelInterruption(spells, buffs)
    if (state.isChanneling and not buffs.arcaneRupture and spells.arcaneRuptureReady) then
        ChannelStopCastingNextTick()
        if (spells.arcaneSurgeReady and not buffs.arcanePower) then
            safeQueueSpell("Arcane Surge")
        else
            safeQueueSpell("Arcane Rupture")
        end
        return true
    end
    return false
end

-- Führt die optimale Zaubersequenz aus
CastArcaneAttack = function()
    -- Global Cooldown Status aktualisieren
    if (GetTime() - state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        state.globalCooldownActive = false
    end

    local spells = getSpellAvailability()
    local buffs = getCurrentBuffs()

    debugPrint("Evaluating spell priority")

    -- Channel-Unterbrechung prüfen
    if handleChannelInterruption(spells, buffs) then
        return
    end

    -- Warten, wenn Cast noch läuft
    if shouldWaitForCast() then
        debugPrint("Waiting for cast to finish")
        return
    end

    -- Arcane Surge casten (höchste Priorität)
    if (spells.arcaneSurgeReady and not buffs.arcanePower) then
        safeQueueSpell("Arcane Surge")
        return
    end

    -- Arcane Missiles mit Clearcasting und Arcane Rupture Buff
    if buffs.clearcasting and buffs.arcaneRupture and 
       buffs.arcaneRupture.duration and buffs.arcaneRupture.duration > MC.TIMING.ARCANE_RUPTURE_MIN_DURATION then
        safeQueueSpell("Arcane Missiles")
        return
    end

    -- Arcane Rupture casten
    if spells.arcaneRuptureReady and not state.isCastingArcaneRupture then
        safeQueueSpell("Arcane Rupture")
        return
    end

    -- Filler-Spells wenn Arcane Rupture bald verfügbar
    if (isArcaneRuptureOneGlobalAway(MC.ACTIONBAR_SLOT.ARCANE_RUPTURE) and spells.fireblastReady) then
        if (spells.arcaneSurgeReady) then
            safeQueueSpell("Arcane Surge")
            return
        elseif (spells.fireblastReady) then
            safeQueueSpell("Fire Blast")
            return
        end
    end

    -- Standard-Filler: Arcane Missiles
    safeQueueSpell("Arcane Missiles")
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
    elseif command == "debug" then
        MC.DEBUG = not MC.DEBUG
        print("MageControl Debug: " .. (MC.DEBUG and "enabled" or "disabled"))
    else
        print("MageControl: Unknown command. Available commands: arcane, explosion, debug")
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
        debugPrint("Channel started, finish time: " .. state.channelFinishTime)
    
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        state.isChanneling = false
        state.expectedCastFinishTime = 0
        debugPrint("Channel stopped")
    
    elseif event == "SPELLCAST_START" then
        if arg1 == "Arcane Rupture" then
            state.isCastingArcaneRupture = true
            state.expectedCastFinishTime = GetTime() + (arg2/1000)
            debugPrint("Started casting Arcane Rupture")
        end
    
    elseif event == "SPELLCAST_STOP" then
        state.isCastingArcaneRupture = false
        debugPrint("Spell cast stopped")
    
    elseif event == "SPELL_CAST_EVENT" then
        state.lastSpellCast = MC.SPELL_NAME[arg2] or "Unknown Spell"
        debugPrint("Spell cast: " .. state.lastSpellCast)
        
        if (arg2 == MC.SPELL_ID.FIREBLAST or 
            arg2 == MC.SPELL_ID.ARCANE_SURGE or 
            arg2 == MC.SPELL_ID.ARCANE_EXPLOSION) then
            
            state.globalCooldownActive = true
            state.globalCooldownStart = GetTime()
            state.expectedCastFinishTime = GetTime() + MC.GLOBAL_COOLDOWN_IN_SECONDS
            debugPrint("Global cooldown activated")
        end
    
    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        state.isChanneling = false
        state.isCastingArcaneRupture = false
        state.expectedCastFinishTime = 0
        debugPrint("Spell failed/interrupted: " .. (state.lastSpellCast or "unknown"))
        
        if (state.lastSpellCast == "Arcane Rupture" and not state.isRuptureRepeated) then
            state.isRuptureRepeated = true
            debugPrint("Retrying Arcane Rupture")
            CastArcaneAttack()
        end
    end
end)