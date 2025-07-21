-- MageControl Action Manager
-- Manages spell casting, action coordination, timing calculations, and safety checks

MageControl = MageControl or {}
MageControl.Core = MageControl.Core or {}

-- Create the ActionManager module
local ActionManager = MageControl.createModule("ActionManager", {"StateManager", "ConfigManager", "Logger"})

-- Initialize the action manager
ActionManager.initialize = function()
    ActionManager._initializeSettings()
    MageControl.Logger.debug("Action Manager initialized", "ActionManager")
end

-- Initialize default settings
ActionManager._initializeSettings = function()
    -- Initialize action bar slots if not set
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE
        }
    end
    
    -- Initialize haste settings
    if not MageControlDB.haste then
        MageControlDB.haste = {
            BASE_VALUE = MC.HASTE.BASE_VALUE,
            HASTE_THRESHOLD = MC.HASTE.HASTE_THRESHOLD
        }
    end
    
    -- Initialize cooldown priority
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER" }
    end
    
    -- Initialize mana threshold for Arcane Power
    if not MageControlDB.minManaForArcanePowerUse then
        MageControlDB.minManaForArcanePowerUse = 50
    end
    
    -- Set Fireblast timing based on talent rank
    local timingByRank = {
        [0] = 1.5,
        [1] = 1.35,
        [2] = 1.2,
        [3] = 1.0
    }
    MC.TIMING.GCD_BUFFER_FIREBLAST = timingByRank[MC.getTalentRank(2,5)] or 1.5
    MageControl.Logger.debug("Set Fireblast Timing to " .. tostring(MC.TIMING.GCD_BUFFER_FIREBLAST) .. " seconds", "ActionManager")
end

-- Check if it's safe to cast a spell (mana safety checks)
ActionManager._isSafeToCast = function(spellName, buffs, buffStates)
    local arcanePowerTimeLeft = MC.getArcanePowerTimeLeft(buffs)

    if arcanePowerTimeLeft <= 0 then
        return true
    end

    local currentManaPercent = MC.getCurrentManaPercent()
    local spellCostPercent = MC.getSpellCostPercent(spellName, buffStates)
    local procCostPercent = 0

    if string.find(spellName, "Arcane") then
        procCostPercent = MC.BUFF_INFO.ARCANE_POWER.proc_cost_percent
    end

    local projectedManaPercent = currentManaPercent - spellCostPercent - procCostPercent
    local safetyThreshold = MC.BUFF_INFO.ARCANE_POWER.death_threshold + MC.BUFF_INFO.ARCANE_POWER.safety_buffer
    
    if projectedManaPercent < safetyThreshold then
        MageControl.Logger.warn(string.format("Spell %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!", 
                spellName, projectedManaPercent), "ActionManager")
        MC.printMessage(string.format("|cffff0000MageControl WARNING: %s could drop mana to %.1f%% (Death at 10%%) - BLOCKED!|r",
                spellName, projectedManaPercent))
        return false
    end

    return true
end

-- Safely queue a spell with all safety checks
ActionManager.safeQueueSpell = function(spellName, buffs, buffStates)
    if not spellName or spellName == "" then
        MageControl.Logger.error("Invalid spell name provided", "ActionManager")
        MC.printMessage("MageControl: Invalid spell name")
        return false
    end

    -- Debug unknown spells
    if MC.getSpellCostByName(spellName) == 0 then
        MageControl.Logger.debug("Unknown spell in safeQueueSpell: [" .. tostring(spellName) .. "]", "ActionManager")
    end

    -- Safety check
    if not ActionManager._isSafeToCast(spellName, buffs, buffStates) then
        MageControl.Logger.debug("Not safe to cast: " .. spellName, "ActionManager")
        return false
    end

    -- Queue the spell
    local success, error = MageControl.ErrorHandler.safeCall(
        function()
            QueueSpellByName(spellName)
        end,
        MageControl.ErrorHandler.TYPES.SPELL,
        {module = "ActionManager", spell = spellName}
    )
    
    if success then
        MageControl.Logger.debug("Queueing spell: " .. spellName, "ActionManager")
        return true
    else
        MageControl.Logger.error("Failed to queue spell " .. spellName .. ": " .. tostring(error), "ActionManager")
        return false
    end
end

-- Queue Arcane Explosion with GCD check
ActionManager.queueArcaneExplosion = function()
    local stateManager = MageControl.ModuleSystem.getModule("StateManager")
    if not stateManager then
        MageControl.Logger.error("StateManager not found", "ActionManager")
        return false
    end
    
    local gcdRemaining = MC.GLOBAL_COOLDOWN_IN_SECONDS - (GetTime() - stateManager.state.globalCooldownStart)
    if gcdRemaining < MC.TIMING.GCD_REMAINING_THRESHOLD then
        local buffs = stateManager.currentBuffs
        local buffStates = MC.getCurrentBuffs(buffs)
        return ActionManager.safeQueueSpell("Arcane Explosion", buffs, buffStates)
    end
    
    MageControl.Logger.debug("GCD remaining too high for Arcane Explosion: " .. gcdRemaining, "ActionManager")
    return false
end

-- Get spell availability information
ActionManager.getSpellAvailability = function()
    local slots = MC.getActionBarSlots()
    return {
        arcaneRuptureReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_RUPTURE, 0),
        arcaneSurgeReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.ARCANE_SURGE, 0),
        fireblastReady = MC.isActionSlotCooldownReadyAndUsableInSeconds(slots.FIREBLAST, 0) and
                (IsSpellInRange(MC.SPELL_INFO.FIREBLAST.id) == 1)
    }
end

-- Check if Arcane Rupture is one GCD away
ActionManager.isArcaneRuptureOneGCDAway = function(slot, timing)
    local cooldown = MC.getActionSlotCooldownInSeconds(slot)
    return (cooldown < timing and cooldown > 0)
end

-- Check if Arcane Rupture is one GCD away after current cast
ActionManager.isArcaneRuptureOneGCDAwayAfterCurrentCast = function(slot, timing)
    local cooldownInSeconds = MC.getActionSlotCooldownInSeconds(slot)
    local cooldownAfterCurrentCast = ActionManager.calculateRemainingTimeAfterCurrentCast(cooldownInSeconds)
    return (cooldownAfterCurrentCast < timing and cooldownAfterCurrentCast > 0)
end

-- Calculate remaining time after current cast finishes
ActionManager.calculateRemainingTimeAfterCurrentCast = function(time)
    local stateManager = MageControl.ModuleSystem.getModule("StateManager")
    if not stateManager then
        return time
    end
    
    local currentCastTimeRemaining = stateManager.state.expectedCastFinishTime - GetTime()
    if currentCastTimeRemaining < 0 then
        currentCastTimeRemaining = 0
    end
    
    local calculatedCooldownAfterCurrentCast = time - currentCastTimeRemaining
    if calculatedCooldownAfterCurrentCast < 0 then
        calculatedCooldownAfterCurrentCast = 0
    end
    
    MageControl.Logger.debug("Cooldown right now: " .. time .. " --- Cooldown after current cast: " .. calculatedCooldownAfterCurrentCast .. " seconds", "ActionManager")
    return calculatedCooldownAfterCurrentCast
end

-- Calculate Arcane Missile fire times
ActionManager.calculateArcaneMissileFireTimes = function(duration)
    local NUM_MISSILES = MageControl.ConfigManager.get("missiles.count") or 6
    local LAG_BUFFER = MageControl.ConfigManager.get("missiles.lagBuffer") or 0.05
    local timeStart = GetTime()
    local fireTimes = {}

    local durationInSeconds = duration / 1000
    local timePerMissile = durationInSeconds / NUM_MISSILES

    for i = 1, NUM_MISSILES do
        fireTimes[i] = timeStart + (i * timePerMissile) + LAG_BUFFER
    end
    
    MageControl.Logger.debug("Calculated " .. NUM_MISSILES .. " missile fire times over " .. durationInSeconds .. "s", "ActionManager")
    return fireTimes
end

-- Check if we're in the last possible missile window for Surge
ActionManager.isInLastPossibleMissileWindow = function()
    local stateManager = MageControl.ModuleSystem.getModule("StateManager")
    if not stateManager then
        return false
    end
    
    if not stateManager.state.isChanneling or
            not stateManager.state.surgeActiveTill or
            not MC.ARCANE_MISSILES_FIRE_TIMES or
            table.getn(MC.ARCANE_MISSILES_FIRE_TIMES) == 0 then
        return false
    end

    local currentTime = GetTime()

    if stateManager.state.surgeActiveTill <= currentTime then
        return false
    end

    local lastPossibleMissileIndex = 0
    for i = 1, table.getn(MC.ARCANE_MISSILES_FIRE_TIMES) do
        if MC.ARCANE_MISSILES_FIRE_TIMES[i] <= stateManager.state.surgeActiveTill then
            lastPossibleMissileIndex = i
        else
            break
        end
    end

    if lastPossibleMissileIndex == 0 then
        return false
    end

    local currentMissileIndex = 0
    for i = 1, table.getn(MC.ARCANE_MISSILES_FIRE_TIMES) do
        if currentTime >= MC.ARCANE_MISSILES_FIRE_TIMES[i] then
            currentMissileIndex = i
        else
            break
        end
    end

    local nextMissileIndex = currentMissileIndex + 1

    local isNextMissileTheLast = (nextMissileIndex == lastPossibleMissileIndex)
    local isInWindow = (nextMissileIndex <= table.getn(MC.ARCANE_MISSILES_FIRE_TIMES)) and
            (currentTime < MC.ARCANE_MISSILES_FIRE_TIMES[nextMissileIndex])

    return isNextMissileTheLast and isInWindow
end

-- Validate action parameters
ActionManager.validateActionParams = function(spellName, buffs, buffStates)
    if not spellName or type(spellName) ~= "string" or spellName == "" then
        return false, "Invalid spell name"
    end
    
    if buffs and type(buffs) ~= "table" then
        return false, "Buffs must be a table"
    end
    
    if buffStates and type(buffStates) ~= "table" then
        return false, "BuffStates must be a table"
    end
    
    return true, "Parameters are valid"
end

-- Get action manager statistics
ActionManager.getStats = function()
    local spellAvailability = ActionManager.getSpellAvailability()
    
    return {
        spellAvailability = spellAvailability,
        settingsInitialized = (MageControlDB.actionBarSlots ~= nil),
        fireblastTiming = MC.TIMING.GCD_BUFFER_FIREBLAST,
        minManaForAP = MageControlDB.minManaForArcanePowerUse,
        cooldownPriorityCount = table.getn(MageControlDB.cooldownPriorityMap or {})
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("ActionManager", ActionManager)

-- Backward compatibility
MC.initializeSettings = function()
    ActionManager._initializeSettings()
end
MC.safeQueueSpell = function(spellName, buffs, buffStates)
    return ActionManager.safeQueueSpell(spellName, buffs, buffStates)
end
MC.queueArcaneExplosion = function()
    return ActionManager.queueArcaneExplosion()
end
MC.getSpellAvailability = function()
    return ActionManager.getSpellAvailability()
end
MC.isArcaneRuptureOneGlobalAway = function(slot, timing)
    return ActionManager.isArcaneRuptureOneGCDAway(slot, timing)
end
MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast = function(slot, timing)
    return ActionManager.isArcaneRuptureOneGCDAwayAfterCurrentCast(slot, timing)
end
MC.calculateRemainingTimeAfterCurrentCast = function(time)
    return ActionManager.calculateRemainingTimeAfterCurrentCast(time)
end
MC.calculateArcaneMissileFireTimes = function(duration)
    return ActionManager.calculateArcaneMissileFireTimes(duration)
end
MC.isInLastPossibleMissileWindow = function()
    return ActionManager.isInLastPossibleMissileWindow()
end

-- Export for other modules
MageControl.Core.ActionManager = ActionManager
