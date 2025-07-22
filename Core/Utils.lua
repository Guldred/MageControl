-- Performance optimized utility functions with caching
-- This module provides core utility functions for the MageControl addon
-- with performance optimizations including intelligent caching and reduced API calls

-- Cache for frequently accessed values to reduce expensive WoW API calls
local _manaCache = { value = 0, maxValue = 1, lastUpdate = 0 }
local _talentCache = {}
local _spellCostCache = {}
local CACHE_DURATION = 0.5 -- Cache mana for 0.5 seconds to balance accuracy vs performance

-- Pre-compiled pattern for better string performance
local SPELL_NAME_PATTERN = "%l+"

--[[
    Optimized mana percentage calculation with intelligent caching
    
    This function caches mana values for CACHE_DURATION seconds to reduce
    expensive UnitMana/UnitManaMax API calls during high-frequency rotation checks.
    
    @return number: Current mana percentage (0-100)
]]
MC.getCurrentManaPercent = function()
    local currentTime = GetTime()
    
    -- Only update cache if expired to reduce API overhead
    if (currentTime - _manaCache.lastUpdate) > CACHE_DURATION then
        _manaCache.maxValue = UnitManaMax("player") or 1
        _manaCache.value = UnitMana("player") or 0
        _manaCache.lastUpdate = currentTime
    end
    
    return _manaCache.maxValue > 0 and (_manaCache.value / _manaCache.maxValue) * 100 or 0
end

--[[
    Optimized talent rank lookup with long-term caching
    
    Talents don't change frequently, so we cache them for 30 seconds
    to dramatically reduce GetTalentInfo API calls.
    
    @param tab number: Talent tab (1-3)
    @param num number: Talent number within tab
    @return number: Current talent rank (0-5)
]]
MC.getTalentRank = function(tab, num)
    local cacheKey = tab .. "_" .. num
    local currentTime = GetTime()
    
    -- Check cache first - talents change infrequently
    if _talentCache[cacheKey] and (currentTime - _talentCache[cacheKey].lastUpdate) < 30 then
        return _talentCache[cacheKey].rank
    end
    
    -- Fetch from WoW API and cache result
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, num)
    
    _talentCache[cacheKey] = {
        rank = rank or 0,
        lastUpdate = currentTime
    }
    
    return rank or 0
end

--[[
    Optimized action bar slots access with null safety
    
    @return table: Action bar slots configuration or empty table
]]
MC.getActionBarSlots = function()
    return MageControlDB.actionBarSlots or {}
end

--[[
    Optimized immunity check with early exits and conditional logging
    
    Checks if current target is immune to specified damage type.
    Uses early exits for performance and conditional debug logging.
    
    @param type string: Immunity type to check (e.g., "ARCANE", "FIRE")
    @return boolean: True if target is immune to damage type
]]
MC.checkImmunity = function(type)
    -- Early exits for performance
    if not type or not MC.CURRENT_TARGET then
        return false
    end
    
    local immunityList = MC.IMMUNITY_LIST[type]
    if not immunityList then
        return false
    end
    
    local isImmune = immunityList[MC.CURRENT_TARGET] or false
    
    -- Only debug print if debug is enabled to reduce overhead
    if MageControl.Logger.isDebugEnabled() then
        MC.debugPrint("Immunity check - Type: " .. type .. ", Target: " .. tostring(MC.CURRENT_TARGET) .. ", Immune: " .. tostring(isImmune))
    end
    
    return isImmune
end

--[[
    Validates action slot numbers for WoW 1.12.1 compatibility
    
    @param slot number: Action slot to validate
    @return boolean: True if slot is valid (1-120)
]]
MC.isValidActionSlot = function(slot)
    return slot and slot > 0 and slot <= 120
end

--[[
    Optimized spell name normalization for consistent comparisons
    
    @param name string: Spell name to normalize
    @return string: Lowercase spell name or empty string
]]
MC.normSpellName = function(name)
    if not name or name == "" then 
        return "" 
    end
    return string.lower(name)
end

--[[
    Optimized spell cost lookup with persistent caching
    
    Caches spell costs permanently since they don't change during gameplay.
    Uses optimized iteration and early returns for better performance.
    
    @param spellName string: Name of spell to get cost for
    @return number: Mana cost of spell or 0 if not found
]]
MC.getSpellCostByName = function(spellName)
    if not spellName then
        return 0
    end
    
    -- Check permanent cache first - spell costs don't change
    if _spellCostCache[spellName] then
        return _spellCostCache[spellName]
    end
    
    local normalizedName = MC.normSpellName(spellName)
    local spellInfo = MC.SPELL_INFO
    
    -- Optimized lookup with direct iteration
    for spellKey, spell in pairs(spellInfo) do
        if MC.normSpellName(spell.name) == normalizedName then
            _spellCostCache[spellName] = spell.cost or 0
            return spell.cost or 0
        end
    end
    
    -- Cache negative results to prevent repeated lookups
    _spellCostCache[spellName] = 0
    return 0
end

--[[
    Calculates modified spell mana cost based on current buffs
    
    @param spellName string: Name of spell to calculate cost for
    @param buffStates table: Current buff states
    @return number: Modified mana cost of spell
]]
MC.getModifiedSpellManaCost = function(spellName, buffStates)
    if buffStates and buffStates.clearcasting then
        return 0
    end
    local baseCost = MC.getSpellCostByName(spellName)
    if MC.normSpellName(spellName) == "arcane missiles" and buffStates and buffStates.arcaneRupture then
        return baseCost * MC.SPELL_MODIFIERS.ARCANE_MISSILES_RUPTURE_MULTIPLIER
    end

    return baseCost
end

--[[
    Retrieves buff name by ID
    
    @param buffID number: ID of buff to retrieve name for
    @return string: Name of buff or "Untracked Buff" if not found
]]
MC.getBuffNameByID = function(buffID)
    for _, info in pairs(MC.BUFF_INFO) do
        if info.id == buffID then
            return info.name
        end
    end

    return "Untracked Buff"
end

--[[
    Calculates spell cost as a percentage of current mana
    
    @param spellName string: Name of spell to calculate cost for
    @param buffStates table: Current buff states
    @return number: Spell cost as a percentage of current mana
]]
MC.getSpellCostPercent = function(spellName, buffStates)
    local manaCost = MC.getModifiedSpellManaCost(spellName, buffStates)
    local maxMana = UnitManaMax("player")
    if maxMana and manaCost and manaCost > 0 then
        return (manaCost / maxMana) * 100
    end
    return 0
end

--[[
    Checks if channeling has finished
    
    @return boolean: True if channeling has finished
]]
MC.checkChannelFinished = function()
    if (MC.state.channelFinishTime < GetTime()) then
        MC.state.isChanneling = false
    end
end

--[[
    Retrieves current buffs
    
    @param buffs table: Current buffs
    @return table: Current buffs with additional information
]]
MC.getCurrentBuffs = function(buffs)
    return {
        clearcasting = MC.findBuff(buffs, MC.BUFF_INFO.CLEARCASTING.name),
        temporalConvergence = MC.findBuff(buffs, MC.BUFF_INFO.TEMPORAL_CONVERGENCE.name),
        arcaneRupture = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_RUPTURE.name),
        arcanePower = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    }
end

--[[
    Checks if action slot is ready and usable within specified time
    
    @param slot number: Action slot to check
    @param seconds number: Time in seconds to check for
    @return boolean: True if action slot is ready and usable within specified time
]]
MC.isActionSlotCooldownReadyAndUsableInSeconds = function(slot, seconds)
    if not MC.isValidActionSlot(slot) then
        return false
    end

    local isUsable, notEnoughMana = IsUsableAction(slot)
    if not isUsable then
        return false
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    local remaining = MC.calculateRemainingTimeAfterCurrentCast((start + duration) - currentTime)
    local isJustGlobalCooldown = false
    if remaining > 0 and MC.state.globalCooldownActive then
        local remainingGlobalCd = MC.TIMING.GCD_BUFFER - (GetTime() - MC.state.globalCooldownStart)
        if remainingGlobalCd >= remaining then
            isJustGlobalCooldown = true
        end
    end

    return (remaining + seconds) <= 0 or isJustGlobalCooldown
end

--[[
    Retrieves action slot cooldown in seconds
    
    @param slot number: Action slot to retrieve cooldown for
    @return number: Cooldown in seconds
]]
MC.getActionSlotCooldownInSeconds = function(slot)
    if not MC.isValidActionSlot(slot) then
        return 0
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

--[[
    Retrieves current haste value
    
    @return number: Current haste value
]]
MC.getCurrentHasteValue = function()
    local hastePercent = MageControlDB.haste.BASE_VALUE

    local hasteBuffs = {
        [MC.BUFF_INFO.ARCANE_POWER.name] = 30,
        [MC.BUFF_INFO.MIND_QUICKENING.name] = 33,
        [MC.BUFF_INFO.ENLIGHTENED_STATE.name] = 20,
        [MC.BUFF_INFO.SULFURON_BLAZE.name] = 5
    }

    local activeBuffs = {}
    for buffName, buffHaste in pairs(hasteBuffs) do
        local buff = MC.findBuff(MC.CURRENT_BUFFS, buffName)
        if buff ~= nil then
            hastePercent = hastePercent + buffHaste
            table.insert(activeBuffs, buffName .. " (+" .. buffHaste .. "%)")
        end
    end

    if table.getn(activeBuffs) > 0 then
        MC.debugPrint("Active haste buffs: " .. table.concat(activeBuffs, ", ") .. " | Total haste: " .. hastePercent .. "%")
    else
        MC.debugPrint("No haste buffs active | Base haste: " .. hastePercent .. "%")
    end

    return hastePercent
end

--[[
    Checks if high haste is active
    
    @return boolean: True if high haste is active
]]
MC.isHighHasteActive = function()
    local currentHaste = MC.getCurrentHasteValue()
    local threshold = MageControlDB.haste.HASTE_THRESHOLD
    local isAboveHasteThreshold = currentHaste >= threshold
    
    MC.debugPrint("High haste check: " .. currentHaste .. "% >= " .. threshold .. "% = " .. (isAboveHasteThreshold and "YES" or "NO"))
    
    return isAboveHasteThreshold
end

--[[
    Checks if arcane missiles are worth casting
    
    @param buffStates table: Current buff states
    @return boolean: True if arcane missiles are worth casting
]]
MC.isMissilesWorthCasting = function(buffStates)
    local ruptureBuff = buffStates.arcaneRupture

    if not ruptureBuff then
        return false
    end

    local remainingDuration = ruptureBuff:durationAfterCurrentSpellCast()
    MC.debugPrint("Arcane Rupture remaining duration by calculation: " .. remainingDuration)
    local hastePercent = MC.getCurrentHasteValue() / 100
    local channelTime = 6 / (1 + hastePercent)
    local requiredTime = channelTime * 0.4

    return remainingDuration >= requiredTime
end

--[[
    Sets action bar slot
    
    @param spellType string: Type of spell to set slot for
    @param slot number: Slot to set
]]
MC.setActionBarSlot = function(spellType, slot)
    local slotNum = tonumber(slot)
    if not slotNum or not MC.isValidActionSlot(slotNum) then
        MC.printMessage("MageControl: Invalid slot number. Must be between 1 and 120.")
        return
    end

    spellType = string.upper(spellType)
    if MageControlDB.actionBarSlots[spellType] then
        MageControlDB.actionBarSlots[spellType] = slotNum
        MC.printMessage("MageControl: " .. spellType .. " slot set to " .. slotNum)
    else
        MC.printMessage("MageControl: Unknown spell type. Use: FIREBLAST, ARCANE_RUPTURE, or ARCANE_SURGE")
    end
end

--[[
    Checks for mana warning
    
    @param buffs table: Current buffs
]]
MC.checkManaWarning = function(buffs)
    local arcanePowerTimeLeft = MC.getArcanePowerTimeLeft(buffs)
    if arcanePowerTimeLeft > 0 then
        local currentMana = MC.getCurrentManaPercent()
        local projectedMana = currentMana - (arcanePowerTimeLeft * MC.BUFF_INFO.ARCANE_POWER.mana_drain_per_second)

        if projectedMana < 15 and projectedMana > 10 then
            MC.printMessage("|cffffff00MageControl: LOW MANA WARNING - " .. math.floor(projectedMana) .. "% projected!|r")
        end
    end
end

--[[
    Shows current configuration
    
    Prints current configuration to chat
]]
MC.showCurrentConfig = function()
    local slots = MC.getActionBarSlots()
    MC.printMessage("MageControl - Current Configuration:")
    MC.printMessage("  Fire Blast: Slot " .. slots.FIREBLAST)
    MC.printMessage("  Arcane Rupture: Slot " .. slots.ARCANE_RUPTURE)
    MC.printMessage("  Arcane Surge: Slot " .. slots.ARCANE_SURGE)
end

--[[
    Retrieves spell ID by name
    
    @param spellName string: Name of spell to retrieve ID for
    @return number: ID of spell or nil if not found
]]
MC.getSpellIdByName = function(spellName)
    local normalizedName = MC.normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if MC.normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.id
        end
    end
    return nil
end

--[[
    Retrieves spell name by ID
    
    @param spellId number: ID of spell to retrieve name for
    @return string: Name of spell or spell ID as string if not found
]]
MC.getSpellNameById = function(spellId)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if spellInfo.id == spellId then
            return spellInfo.name
        end
    end
    return tostring(spellId)
end

--[[
    Checks if we should wait for cast to finish
    
    @return boolean: True if we should wait for cast to finish
]]
MC.shouldWaitForCast = function()
    local timeToCastFinish = MC.state.expectedCastFinishTime - GetTime()
    return timeToCastFinish > MC.TIMING.CAST_FINISH_THRESHOLD
end

--[[
    Updates current target
    
    Updates current target and prints debug message
]]
MC.updateCurrentTarget = function()
    MC.CURRENT_TARGET = UnitName("target") or "none"
    MC.debugPrint("New target is: " .. MC.CURRENT_TARGET)
end

--[[
    Retrieves arcane power time left
    
    @param buffs table: Current buffs
    @return number: Time left on arcane power buff
]]
MC.getArcanePowerTimeLeft = function(buffs)
    local arcanePower = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    return arcanePower and arcanePower:duration() or 0
end