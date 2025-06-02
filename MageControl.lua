SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

local MC = {
    GLOBAL_COOLDOWN_IN_SECONDS = 1.5,

    TIMING = {
        CAST_FINISH_THRESHOLD = 0.75,
        GCD_REMAINING_THRESHOLD = 0.75,
        GCD_BUFFER = 1.6,
        ARCANE_RUPTURE_MIN_DURATION = 2
    },

    SPELL_ID = {
        FIREBLAST = 10199,
        ARCANE_SURGE = 51936,
        ARCANE_EXPLOSION = 10202,
        ARCANE_MISSILES = 25345,
        ARCANE_RUPTURE = 51954
    },

    DEFAULT_ACTIONBAR_SLOT = {
        FIREBLAST = 1,
        ARCANE_RUPTURE = 2,
        ARCANE_SURGE = 5
    },

    SPELL_NAME = {},

    BUFF_NAME = {
        CLEARCASTING = "Clearcasting",
        TEMPORAL_CONVERGENCE = "Temporal Convergence",
        ARCANE_POWER = "Arcane Power",
        ARCANE_RUPTURE = "Arcane Rupture"
    },

    DEBUG = false
}

MC.SPELL_NAME[MC.SPELL_ID.FIREBLAST] = "Fireblast"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_SURGE] = "Arcane Surge"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_EXPLOSION] = "Arcane Explosion"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_MISSILES] = "Arcane Missiles"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_RUPTURE] = "Arcane Rupture"

MageControlDB = MageControlDB or {}

local function initializeSettings()
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE
        }
    end
end

local function getActionBarSlots()
    return MageControlDB.actionBarSlots
end

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

local checkChannelFinished, CastArcaneAttack

local function debugPrint(message)
    if MC.DEBUG then
        print("MageControl Debug: " .. message)
    end
end

local function isValidActionSlot(slot)
    return slot and slot > 0 and slot <= 120
end

local function safeQueueSpell(spellName)
    if not spellName or spellName == "" then
        print("MageControl: Invalid spell name")
        return false
    end

    debugPrint("Queueing spell: " .. spellName)
    QueueSpellByName(spellName)
    return true
end

local function findBuff(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end

checkChannelFinished = function()
    if (state.channelFinishTime < GetTime()) then
        state.isChanneling = false
    end
end

local function QueueArcaneExplosion()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - state.globalCooldownStart)
    if(gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD) then
        safeQueueSpell("Arcane Explosion")
    end
end

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

    local isJustGlobalCooldown = false
    if remaining > 0 and state.globalCooldownActive then
        local remainingGlobalCd = MC.TIMING.GCD_BUFFER - (GetTime() - state.globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
        end
    end

    return remaining <= 0 or isJustGlobalCooldown
end

local function getActionSlotCooldownInMilliseconds(slot)
    if not isValidActionSlot(slot) then
        return 0
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

local function isArcaneRuptureOneGlobalAway(slot)
    local cooldown = getActionSlotCooldownInMilliseconds(slot)
    return (cooldown < MC.TIMING.GCD_BUFFER and cooldown > 0)
end

local function GetBuffs()
    local buffs = {}
    local relevantBuffs = {
        [MC.BUFF_NAME.CLEARCASTING] = true,
        [MC.BUFF_NAME.TEMPORAL_CONVERGENCE] = true,
        [MC.BUFF_NAME.ARCANE_POWER] = true
    }

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

local function getSpellAvailability()
    local slots = getActionBarSlots()
    return {
        arcaneRuptureReady = IsActionSlotCooldownReady(slots.ARCANE_RUPTURE),
        arcaneSurgeReady = IsActionSlotCooldownReady(slots.ARCANE_SURGE),
        fireblastReady = IsActionSlotCooldownReady(slots.FIREBLAST) and
                (IsSpellInRange(MC.SPELL_ID.FIREBLAST) == 1)
    }
end

local function getCurrentBuffs()
    local buffs = GetBuffs()
    return {
        clearcasting = findBuff(buffs, MC.BUFF_NAME.CLEARCASTING),
        temporalConvergence = findBuff(buffs, MC.BUFF_NAME.TEMPORAL_CONVERGENCE),
        arcaneRupture = findBuff(buffs, MC.BUFF_NAME.ARCANE_RUPTURE),
        arcanePower = findBuff(buffs, MC.BUFF_NAME.ARCANE_POWER)
    }
end

local function shouldWaitForCast()
    local timeToCastFinish = state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

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

CastArcaneAttack = function()
    if (GetTime() - state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        state.globalCooldownActive = false
    end

    local spells = getSpellAvailability()
    local buffs = getCurrentBuffs()
    local slots = getActionBarSlots()

    debugPrint("Evaluating spell priority")

    if handleChannelInterruption(spells, buffs) then
        return
    end

    if shouldWaitForCast() then
        debugPrint("Waiting for cast to finish")
        return
    end

    if (spells.arcaneSurgeReady and not buffs.arcanePower) then
        safeQueueSpell("Arcane Surge")
        return
    end

    if buffs.clearcasting and buffs.arcaneRupture and
            buffs.arcaneRupture.duration and buffs.arcaneRupture.duration > MC.TIMING.ARCANE_RUPTURE_MIN_DURATION then
        safeQueueSpell("Arcane Missiles")
        return
    end

    if spells.arcaneRuptureReady and not state.isCastingArcaneRupture then
        safeQueueSpell("Arcane Rupture")
        return
    end

    if (isArcaneRuptureOneGlobalAway(slots.ARCANE_RUPTURE) and spells.fireblastReady) then
        if (spells.arcaneSurgeReady) then
            safeQueueSpell("Arcane Surge")
            return
        elseif (spells.fireblastReady) then
            safeQueueSpell("Fire Blast")
            return
        end
    end

    safeQueueSpell("Arcane Missiles")
end

local function showOptionsMenu()
    if MageControlOptionsFrame and MageControlOptionsFrame:IsVisible() then
        MageControlOptionsFrame:Hide()
    else
        MageControlOptions_Show()
    end
end

local function setActionBarSlot(spellType, slot)
    local slotNum = tonumber(slot)
    if not slotNum or not isValidActionSlot(slotNum) then
        print("MageControl: Invalid slot number. Must be between 1 and 120.")
        return
    end

    spellType = string.upper(spellType)
    if MageControlDB.actionBarSlots[spellType] then
        MageControlDB.actionBarSlots[spellType] = slotNum
        print("MageControl: " .. spellType .. " slot set to " .. slotNum)
    else
        print("MageControl: Unknown spell type. Use: FIREBLAST, ARCANE_RUPTURE, or ARCANE_SURGE")
    end
end

local function showCurrentConfig()
    local slots = getActionBarSlots()
    print("MageControl - Current Configuration:")
    print("  Fireblast: Slot " .. slots.FIREBLAST)
    print("  Arcane Rupture: Slot " .. slots.ARCANE_RUPTURE)
    print("  Arcane Surge: Slot " .. slots.ARCANE_SURGE)
end

SlashCmdList["MAGECONTROL"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    if command == "explosion" then
        QueueArcaneExplosion()
    elseif command == "arcane" then
        state.isRuptureRepeated = false
        checkChannelFinished()
        CastArcaneAttack()
    elseif command == "debug" then
        MC.DEBUG = not MC.DEBUG
        print("MageControl Debug: " .. (MC.DEBUG and "enabled" or "disabled"))
    elseif command == "options" or command == "config" then
        showOptionsMenu()
    elseif command == "set" and args[2] and args[3] then
        setActionBarSlot(args[2], args[3])
    elseif command == "show" then
        showCurrentConfig()
    elseif command == "reset" then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE
        }
        print("MageControl: Configuration reset to defaults")
    else
        print("MageControl Commands:")
        print("  /mc arcane - Cast arcane attack sequence")
        print("  /mc explosion - Queue arcane explosion")
        print("  /mc options - Show options menu")
        print("  /mc set <spell> <slot> - Set actionbar slot")
        print("  /mc show - Show current configuration")
        print("  /mc reset - Reset to default slots")
        print("  /mc debug - Toggle debug mode")
    end
end

local MageControlFrame = CreateFrame("Frame")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_START")
MageControlFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
MageControlFrame:RegisterEvent("SPELLCAST_START")
MageControlFrame:RegisterEvent("SPELLCAST_STOP")
MageControlFrame:RegisterEvent("SPELL_CAST_EVENT")
MageControlFrame:RegisterEvent("SPELLCAST_FAILED")
MageControlFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
MageControlFrame:RegisterEvent("ADDON_LOADED")

MageControlFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "MageControl" then
        initializeSettings()
        print("MageControl loaded. Type /mc for commands.")

    elseif event == "SPELLCAST_CHANNEL_START" then
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