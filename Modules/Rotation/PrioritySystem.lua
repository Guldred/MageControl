-- MageControl Priority System
-- Manages rotation priority logic and decision making

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the PrioritySystem module
local PrioritySystem = MageControl.createModule("PrioritySystem", {"ConditionChecker", "ActionHandler", "Logger"})

-- Initialize the priority system
PrioritySystem.initialize = function()
    MageControl.Logger.debug("Priority System initialized", "PrioritySystem")
end

-- Get the arcane rotation priorities
PrioritySystem.getArcaneRotationPriorities = function()
    local conditionChecker = MageControl.ModuleSystem.getModule("ConditionChecker")
    local actionHandler = MageControl.ModuleSystem.getModule("ActionHandler")
    
    if not conditionChecker or not actionHandler then
        MageControl.Logger.error("Required modules not found for priority system", "PrioritySystem")
        return {}
    end

    return {
        {
            name = "Channel Interruption for Rebuff",
            condition = function(state)
                return conditionChecker.isMissilesInterruptionRequiredForRuptureRebuff(state.spells, state.buffStates)
            end,
            action = function(state)
                return actionHandler.handleMissilesInterruptionForRuptureRebuff(state.spells, state.buffs, state.buffStates)
            end
        },
        {
            name = "Channel Interruption for Surge at last second",
            condition = function(state)
                return conditionChecker.isMissilesInterruptionRequiredForSurge()
            end,
            action = function(state)
                MageControl.Logger.debug("Arcane Missiles need to be interrupted to fire Surge while available", "PrioritySystem")
                return actionHandler.handleMissilesInterruptionForSurge(state.buffs, state.buffStates)
            end
        },
        {
            name = "Wait for Cast",
            condition = function(state)
                return conditionChecker.shouldWaitForCast()
            end,
            action = function(state)
                return actionHandler.handleWaitForCast(state)
            end
        },
        {
            name = "Arcane Surge (Low Haste)",
            condition = function(state)
                return conditionChecker.isArcaneSurgeReadyLowHaste(state)
            end,
            action = function(state)
                return actionHandler.handleArcaneSurge(state)
            end
        },
        {
            name = "Clearcasting Missiles",
            condition = function(state)
                return conditionChecker.shouldCastClearcastingMissiles(state)
            end,
            action = function(state)
                return actionHandler.handleClearcastingMissiles(state)
            end
        },
        {
            name = "Arcane Rupture Maintenance",
            condition = function(state)
                return conditionChecker.needsArcaneRuptureMaintenance(state)
            end,
            action = function(state)
                return actionHandler.handleArcaneRuptureMaintenance(state)
            end
        },
        {
            name = "Missiles Worth Casting",
            condition = function(state)
                return conditionChecker.areMissilesWorthCasting(state)
            end,
            action = function(state)
                return actionHandler.handleMissilesWorthCasting(state)
            end
        },
        {
            name = "Arcane Rupture One GCD Away (Arcane Surge)",
            condition = function(state)
                return conditionChecker.isArcaneRuptureOneGCDAwayForSurge(state)
            end,
            action = function(state)
                return actionHandler.handleArcaneRuptureOneGCDSurge(state)
            end
        },
        {
            name = "Arcane Rupture One GCD Away (Fire Blast)",
            condition = function(state)
                return conditionChecker.isArcaneRuptureOneGCDAwayForFireBlast(state)
            end,
            action = function(state)
                return actionHandler.handleArcaneRuptureOneGCDFireBlast(state)
            end
        },
        {
            name = "Default Missiles",
            condition = function(state)
                return conditionChecker.shouldDefaultToMissiles(state)
            end,
            action = function(state)
                return actionHandler.handleDefaultMissiles(state)
            end
        }
    }
end

-- Evaluate a single priority
PrioritySystem.evaluatePriority = function(priority, state)
    if not priority or not priority.condition or not priority.action then
        return false, "Invalid priority structure"
    end
    
    local valid, error = MageControl.Rotation.ConditionChecker.validateState(state)
    if not valid then
        return false, "Invalid state: " .. error
    end
    
    local success, conditionResult = MageControl.ErrorHandler.safeCall(
        priority.condition,
        MageControl.ErrorHandler.TYPES.MODULE,
        {module = "PrioritySystem", priority = priority.name},
        state
    )
    
    if not success then
        MageControl.Logger.error("Failed to evaluate condition for: " .. priority.name, "PrioritySystem")
        return false, "Condition evaluation failed"
    end
    
    return conditionResult, nil
end

-- Execute a priority action
PrioritySystem.executePriorityAction = function(priority, state)
    if not priority or not priority.action then
        return false, "Invalid priority action"
    end
    
    local success, actionResult = MageControl.ErrorHandler.safeCall(
        priority.action,
        MageControl.ErrorHandler.TYPES.MODULE,
        {module = "PrioritySystem", priority = priority.name},
        state
    )
    
    if not success then
        MageControl.Logger.error("Failed to execute action for: " .. priority.name, "PrioritySystem")
        return false
    end
    
    return actionResult or true
end

-- Find the highest priority action to execute
PrioritySystem.findHighestPriorityAction = function(state)
    local priorities = PrioritySystem.getArcaneRotationPriorities()
    
    for i, priority in ipairs(priorities) do
        local shouldExecute, error = PrioritySystem.evaluatePriority(priority, state)
        if shouldExecute then
            return priority, i
        elseif error then
            MageControl.Logger.warn("Priority evaluation error for '" .. priority.name .. "': " .. error, "PrioritySystem")
        end
    end
    
    return nil, nil
end

-- Get priority system statistics
PrioritySystem.getStats = function()
    local priorities = PrioritySystem.getArcaneRotationPriorities()
    return {
        totalPriorities = table.getn(priorities),
        priorityNames = (function()
            local names = {}
            for _, priority in ipairs(priorities) do
                table.insert(names, priority.name)
            end
            return names
        end)()
    }
end

-- Validate priority structure
PrioritySystem.validatePriority = function(priority)
    if not priority then
        return false, "Priority is nil"
    end
    
    if not priority.name or type(priority.name) ~= "string" then
        return false, "Priority must have a valid name"
    end
    
    if not priority.condition or type(priority.condition) ~= "function" then
        return false, "Priority must have a condition function"
    end
    
    if not priority.action or type(priority.action) ~= "function" then
        return false, "Priority must have an action function"
    end
    
    return true, "Priority is valid"
end

-- Register the module
MageControl.ModuleSystem.registerModule("PrioritySystem", PrioritySystem)

-- Backward compatibility
MC.arcaneRotationPriority = PrioritySystem.getArcaneRotationPriorities()

-- Export for other modules
MageControl.Rotation.PrioritySystem = PrioritySystem
