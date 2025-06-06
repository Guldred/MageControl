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
        ARCANE_RUPTURE = 51954,
        FROSTBOLT_1 = 116,
        FROSTBOLT = 25304,
        FIREBALL = 25306
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
    
    ARCANE_POWER = {
        MANA_DRAIN_PER_SECOND = 1,
        DEATH_THRESHOLD = 10,
        SAFETY_BUFFER = 5,
        PROC_COST_PERCENT = 2
    },
    
    SPELL_COSTS = {
        ["Arcane Missiles"] = 655,
        ["Arcane Surge"] = 170,
        ["Arcane Rupture"] = 390,
        ["Fire Blast"] = 340,
        ["Fireblast"] = 340,
        ["Arcane Explosion"] = 390
    },
    
    SPELL_MODIFIERS = {
        ARCANE_MISSILES_RUPTURE_MULTIPLIER = 1.25,
        PROC_DAMAGE_COST_PERCENT = 2
    },

    HASTE = {
        BASE_TELEPORT_CAST_TIME = 10.0,
        TELEPORT_SPELLBOOK_ID = 0,
        CURRENT_HASTE_PERCENT = 0,
    },

    DEBUG = false
}

MC.SPELL_NAME[MC.SPELL_ID.FIREBLAST] = "Fireblast"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_SURGE] = "Arcane Surge"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_EXPLOSION] = "Arcane Explosion"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_MISSILES] = "Arcane Missiles"
MC.SPELL_NAME[MC.SPELL_ID.ARCANE_RUPTURE] = "Arcane Rupture"
MC.SPELL_NAME[MC.SPELL_ID.FROSTBOLT_1] = "Frostbolt (Rank 1)"
MC.SPELL_NAME[MC.SPELL_ID.FROSTBOLT] = "Frostbolt"
MC.SPELL_NAME[MC.SPELL_ID.FIREBALL] = "Fireball"

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
    expectedCastFinishTime = 0,
    cachedBuffs = nil
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

local function getCurrentManaPercent()
    return (UnitMana("player") / UnitManaMax("player")) * 100
end

local function getModifiedSpellManaCost(spellName, buffStates)
    if buffStates and buffStates.clearcasting then
        debugPrint("Clearcasting active - " .. spellName .. " costs 0 mana")
        return 0
    end
    
    local baseCost = MC.SPELL_COSTS[spellName] or 0
    
    if spellName == "Arcane Missiles" and buffStates and buffStates.arcaneRupture then
        local modifiedCost = baseCost * MC.SPELL_MODIFIERS.ARCANE_MISSILES_RUPTURE_MULTIPLIER
        debugPrint(string.format("Arcane Rupture active - Arcane Missiles cost: %.0f -> %.0f", baseCost, modifiedCost))
        return modifiedCost
    end
    
    return baseCost
end

local function getSpellCostPercent(spellName, buffStates)
    local manaCost = getModifiedSpellManaCost(spellName, buffStates)
    if manaCost and manaCost > 0 then
        return (manaCost / UnitManaMax("player")) * 100
    end
    return 0
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

local function findBuff(buffs, buffName)
    for i, buff in ipairs(buffs) do
        if buff.name == buffName then
            return buff
        end
    end
    return nil
end

local function getArcanePowerTimeLeft(buffs)
    local arcanePower = findBuff(buffs, MC.BUFF_NAME.ARCANE_POWER)
    return arcanePower and arcanePower.duration or 0
end

local function isSafeToCast(spellName, buffs, buffStates)
    local arcanePowerTimeLeft = getArcanePowerTimeLeft(buffs)
    
    if arcanePowerTimeLeft <= 0 then
        return true
    end
    
    local currentManaPercent = getCurrentManaPercent()
    local spellCostPercent = getSpellCostPercent(spellName, buffStates)
    local arcanePowerDrainPercent = arcanePowerTimeLeft * MC.ARCANE_POWER.MANA_DRAIN_PER_SECOND
    
    local procCostPercent = 0
    if string.find(spellName, "Arcane") then
        procCostPercent = MC.ARCANE_POWER.PROC_COST_PERCENT
    end
    
    local projectedManaPercent = currentManaPercent - spellCostPercent - procCostPercent
    
    debugPrint(string.format("Safety Check - Current: %.1f%%, Spell: %.1f%%, AP Drain: %.1f%%, Proc: %.1f%%, Projected: %.1f%%", 
        currentManaPercent, spellCostPercent, arcanePowerDrainPercent, procCostPercent, projectedManaPercent))
    
    local safetyThreshold = MC.ARCANE_POWER.DEATH_THRESHOLD + MC.ARCANE_POWER.SAFETY_BUFFER
    
    if projectedManaPercent < safetyThreshold then
        print(string.format("|cffff0000MageControl WARNING: %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!|r",
            spellName, projectedManaPercent))
        return false
    end
    
    return true
end

local function safeQueueSpell(spellName, buffs, buffStates)
    if not spellName or spellName == "" then
        print("MageControl: Invalid spell name")
        return false
    end
    
    if not isSafeToCast(spellName, buffs, buffStates) then
        return false
    end
    
    debugPrint("Queueing spell: " .. spellName)
    QueueSpellByName(spellName)
    return true
end

checkChannelFinished = function()
    if (state.channelFinishTime < GetTime()) then
        state.isChanneling = false
    end
end

local function getCurrentBuffs(buffs)
    return {
        clearcasting = findBuff(buffs, MC.BUFF_NAME.CLEARCASTING),
        temporalConvergence = findBuff(buffs, MC.BUFF_NAME.TEMPORAL_CONVERGENCE),
        arcaneRupture = findBuff(buffs, MC.BUFF_NAME.ARCANE_RUPTURE),
        arcanePower = findBuff(buffs, MC.BUFF_NAME.ARCANE_POWER)
    }
end

local function QueueArcaneExplosion()
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - state.globalCooldownStart)
    if(gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD) then
        local buffs = GetBuffs()
        local buffStates = getCurrentBuffs(buffs)
        safeQueueSpell("Arcane Explosion", buffs, buffStates)
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

local function getSpellAvailability()
    local slots = getActionBarSlots()
    return {
        arcaneRuptureReady = IsActionSlotCooldownReady(slots.ARCANE_RUPTURE),
        arcaneSurgeReady = IsActionSlotCooldownReady(slots.ARCANE_SURGE),
        fireblastReady = IsActionSlotCooldownReady(slots.FIREBLAST) and 
                        (IsSpellInRange(MC.SPELL_ID.FIREBLAST) == 1)
    }
end

local function shouldWaitForCast()
    local timeToCastFinish = state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

local function calculateHastePercent()
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetSpell(MC.HASTE.TELEPORT_SPELLBOOK_ID, "spell")

    local castTimeText = nil
    for i = 1, GameTooltip:NumLines() do
        local line = getglobal("GameTooltipTextLeft"..i)
        if line then
            local text = line:GetText()
            if text then
                local castTime = strmatch(text, "(%d+%.?%d*) sec cast")
                if castTime then
                    castTimeText = tonumber(castTime)
                    break
                end
            end
        end
    end

    GameTooltip:Hide()

    if castTimeText then
        local actualCastTime = castTimeText
        local hastePercent = ((MC.HASTE.BASE_TELEPORT_CAST_TIME - actualCastTime) / MC.HASTE.BASE_TELEPORT_CAST_TIME) * 100

        MC.HASTE.CURRENT_HASTE_PERCENT = math.max(0, hastePercent)

        debugPrint(string.format("Haste calculated: %.1f%% (Base: %.1fs, Current: %.1fs)",
                MC.HASTE.CURRENT_HASTE_PERCENT, MC.HASTE.BASE_TELEPORT_CAST_TIME, actualCastTime))

        return MC.HASTE.CURRENT_HASTE_PERCENT
    else
        debugPrint("Could not extract cast time from Tooltip")
        return 10
    end
end

local function isHighHasteActive()
    local isAboveThirtyHaste = calculateHastePercent() > 30
    return isAboveThirtyHaste
end

local function handleChannelInterruption(spells, buffStates, buffs)
    if (state.isChanneling and not buffStates.arcaneRupture and spells.arcaneRuptureReady) then
        ChannelStopCastingNextTick()
        if (buffStates.arcaneSurgeReady) then
            safeQueueSpell("Arcane Surge", buffs, buffStates)
        else
            safeQueueSpell("Arcane Rupture", buffs, buffStates)
        end
        return true
    end
    return false
end

local function isMissilesWorthCasting(buffStates)
    local ruptureBuff = buffStates.arcaneRupture

    if not ruptureBuff then
        return false
    end

    local remainingDuration = ruptureBuff.duration
    local hastePercent = calculateHastePercent() / 100
    local channelTime = 6 / (1 + hastePercent)
    local requiredTime = channelTime * 0.6

    debugPrint("Required time for Arcane Missiles: %.1f%% vs %.1f%% remaining duration",
                        requiredTime, remainingDuration)

    return remainingDuration >= requiredTime
end

local function getFactionBasedPortSpell()
    local faction, localizedFaction = UnitFactionGroup("player")
    if (faction == "Alliance") then
        return "Teleport: Stormwind"
    else
        return "Teleport: Orgrimmar"
    end
end

local function getSpellbookSpellIdForName(spellName)
    local bookType = BOOKTYPE_SPELL
    local targetId = 0
    for spellBookId = 1, MAX_SPELLS do
        local name = GetSpellName(spellBookId, bookType)
        if not name then break end
        if name == spellName then
            targetId = spellBookId
            break
        end
    end
    return targetId
end

CastArcaneAttack = function()
    if (GetTime() - state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        state.globalCooldownActive = false
    end

    if (MC.HASTE.TELEPORT_SPELLBOOK_ID == 0) then
        MC.HASTE.TELEPORT_SPELLBOOK_ID = getSpellbookSpellIdForName(getFactionBasedPortSpell())
        print("MageControl set teleport spell ID: " .. MC.HASTE.TELEPORT_SPELLBOOK_ID)
    end

    local buffs = GetBuffs()
    local spells = getSpellAvailability()
    local buffStates = getCurrentBuffs(buffs)
    local slots = getActionBarSlots()
    local missilesWorthCasting = isMissilesWorthCasting(buffStates)

    debugPrint("Evaluating spell priority")

    if handleChannelInterruption(spells, buffStates, buffs) then
        return
    end

    if shouldWaitForCast() then
        debugPrint("Waiting for cast to finish")
        return
    end

    if (spells.arcaneSurgeReady and not isHighHasteActive()) then
        safeQueueSpell("Arcane Surge", buffs, buffStates)
        return
    end

    if (buffStates.clearcasting and missilesWorthCasting) then
        safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (spells.arcaneRuptureReady and not missilesWorthCasting and not state.isCastingArcaneRupture) then
        safeQueueSpell("Arcane Rupture", buffs, buffStates)
        return
    end

    if (missilesWorthCasting) then
        safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (isArcaneRuptureOneGlobalAway(slots.ARCANE_RUPTURE)) then
        if (spells.arcaneSurgeReady and not isHighHasteActive()) then
            safeQueueSpell("Arcane Surge", buffs, buffStates)
            return
        elseif (spells.fireblastReady) then
            safeQueueSpell("Fire Blast", buffs, buffStates)
            return
        end
    end

    safeQueueSpell("Arcane Missiles", buffs, buffStates)
end

local function checkManaWarning(buffs)
    local arcanePowerTimeLeft = getArcanePowerTimeLeft(buffs)
    if arcanePowerTimeLeft > 0 then
        local currentMana = getCurrentManaPercent()
        local projectedMana = currentMana - (arcanePowerTimeLeft * MC.ARCANE_POWER.MANA_DRAIN_PER_SECOND)
        
        if projectedMana < 15 and projectedMana > 10 then
            print("|cffffff00MageControl: LOW MANA WARNING - " .. math.floor(projectedMana) .. "% projected!|r")
        end
    end
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
        local buffs = GetBuffs()
        checkManaWarning(buffs)
        state.isRuptureRepeated = false
        checkChannelFinished()
        CastArcaneAttack()
    elseif command == "haste" then
        local haste = calculateHastePercent()
        print("Current Haste: " .. haste)
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
        print("MageControl loaded.")
        
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
        state.expectedCastFinishTime = GetTime()
        debugPrint("Spell cast stopped")
    
    elseif event == "SPELL_CAST_EVENT" then
        state.lastSpellCast = MC.SPELL_NAME[arg2] or "Unknown Spell"
        debugPrint("Spell cast: " .. state.lastSpellCast .. " with ID: " .. arg2)
        state.globalCooldownActive = true
        state.globalCooldownStart = GetTime()
        state.expectedCastFinishTime = GetTime() + MC.GLOBAL_COOLDOWN_IN_SECONDS
        debugPrint("Global cooldown activated")
    
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