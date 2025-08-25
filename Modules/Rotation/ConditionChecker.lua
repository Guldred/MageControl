-- MageControl Condition Checker
-- Handles all rotation condition checking logic

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the ConditionChecker module
-- ConfigValidation is direct unified module, no dependency needed
local ConditionChecker = MageControl.createModule("ConditionChecker", {"Logger"})

-- Initialize the condition checker
ConditionChecker.initialize = function()
    MageControl.Logger.debug("Condition Checker initialized", "ConditionChecker")
end

-- Check if missiles interruption is required for Arcane Surge at last second
ConditionChecker.isMissilesInterruptionRequiredForSurge = function()
    if not MageControl.StateManager.current.isChanneling or MageControl.StateManager.isHighHasteActive() then
        return false
    end

    local earliestCancelPoint = MageControl.ConfigValidation.get("rotation.minMissilesForSurgeCancel") or 4

    if not MageControl.ArcaneSpecific.isInLastPossibleMissileWindow() then
        return false
    end

    local currentTime = GetTime()
    local currentMissileIndex = 0
    for i = 1, table.getn(MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES) do
        if currentTime >= MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES[i] then
            currentMissileIndex = i
        else
            break
        end
    end

    if currentMissileIndex < earliestCancelPoint then
        return false
    end

    local arcaneSurgeCooldownRemaining = MageControl.SpellCasting.getActionSlotCooldownInSeconds(MageControl.SpellCasting.getActionBarSlots().ARCANE_SURGE)
    local nextMissileIndex = currentMissileIndex + 1
    local timeUntilNextMissile = MageControl.ArcaneSpecific.ARCANE_MISSILES_FIRE_TIMES[nextMissileIndex] - currentTime
    local BUFFER_WINDOW = 0.1 -- Buffer window to account for lag and timing issues

    local surgeCooldownReadyForNextMissile = arcaneSurgeCooldownRemaining + BUFFER_WINDOW <= timeUntilNextMissile

    MageControl.Logger.debug("Current missile: " .. currentMissileIndex, "ConditionChecker")
    MageControl.Logger.debug("Next missile (last possible): " .. nextMissileIndex, "ConditionChecker")
    MageControl.Logger.debug("Time until next missile: " .. timeUntilNextMissile, "ConditionChecker")
    MageControl.Logger.debug("Surge cooldown ready for next missile: " .. tostring(surgeCooldownReadyForNextMissile), "ConditionChecker")

    return surgeCooldownReadyForNextMissile
end

-- Check if missiles interruption is required for Arcane Rupture rebuff
ConditionChecker.isMissilesInterruptionRequiredForRuptureRebuff = function(spells, buffStates)
    local shouldCancelWhileHighHaste = MageControl.StateManager.isHighHasteActive()
            and MageControl.StateManager.current.isChanneling and
            not buffStates.arcaneRupture and
            spells.arcaneRuptureReady

    local shouldCancelWhileLowHaste = not MageControl.StateManager.isHighHasteActive()
            and MageControl.StateManager.current.isChanneling and
            not buffStates.arcaneRupture and
            spells.arcaneRuptureReady and
            not MageControl.SpellCasting.isActionSlotCooldownReadyAndUsableInSeconds(MageControl.SpellCasting.getActionBarSlots().ARCANE_SURGE, 1)
            -- Last check is to make sure you dont use Rupture and then surge right after, which would reduce effective missiles time
            -- Ideally, we want to use Surge first, then rupture

    return shouldCancelWhileHighHaste or shouldCancelWhileLowHaste
end

-- Check if should wait for current cast to finish
ConditionChecker.shouldWaitForCast = function()
    return MageControl.SpellCasting.shouldWaitForCast()
end

-- Check if Arcane Surge is ready and low haste
ConditionChecker.isArcaneSurgeReadyLowHaste = function(state)
    return state.spells.arcaneSurgeReady and not MageControl.StateManager.isHighHasteActive()
end

-- Check if clearcasting missiles should be cast
ConditionChecker.shouldCastClearcastingMissiles = function(state)
    return state.buffStates.clearcasting and state.missilesWorthCasting
end

-- Check if Arcane Rupture maintenance is needed
ConditionChecker.needsArcaneRuptureMaintenance = function(state)
    return state.spells.arcaneRuptureReady and
    --TODO: Check if recasting rupture is better here. Might add empty debuff time
           --not state.missilesWorthCasting and
           not MageControl.StateManager.current.isCastingArcaneRupture
end

-- Check if missiles are worth casting
ConditionChecker.areMissilesWorthCasting = function(state)
    return state.missilesWorthCasting
end

-- Check if Arcane Rupture is one GCD away (for Arcane Surge)
ConditionChecker.isArcaneRuptureOneGCDAwayForSurge = function(state)
    local timing = MageControl.ConfigValidation.get("timing.GCD_BUFFER") or 1.5
    return MageControl.TimingCalculations.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, timing) and
            state.spells.arcaneSurgeReady and
            not MageControl.StateManager.isHighHasteActive()
end

-- Check if Arcane Rupture is one GCD away (for Fire Blast)
ConditionChecker.isArcaneRuptureOneGCDAwayForFireBlast = function(state)
    local timing = MageControl.ConfigValidation.get("timing.GCD_BUFFER_FIREBLAST") or 1.5
    return MageControl.TimingCalculations.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, timing) and
            state.spells.fireblastReady and
            not MageControl.ImmunityData.checkImmunity("fire") and
            not MageControl.StateManager.isHighHasteActive()
end

-- Check if should default to missiles (fallback condition)
ConditionChecker.shouldDefaultToMissiles = function(state)
    return true -- Always true - this is the fallback
end

-- Validate condition state
ConditionChecker.validateState = function(state)
    if not state then
        return false, "State is nil"
    end
    
    local requiredFields = {"spells", "buffStates", "slots", "missilesWorthCasting"}
    for _, field in ipairs(requiredFields) do
        if not state[field] then
            return false, "Missing required field: " .. field
        end
    end
    
    return true, "State is valid"
end

-- Get condition statistics
ConditionChecker.getStats = function()
    return {
        totalConditions = 9,
        availableConditions = {
            "isMissilesInterruptionRequiredForSurge",
            "isMissilesInterruptionRequiredForRuptureRebuff", 
            "shouldWaitForCast",
            "isArcaneSurgeReadyLowHaste",
            "shouldCastClearcastingMissiles",
            "needsArcaneRuptureMaintenance",
            "areMissilesWorthCasting",
            "isArcaneRuptureOneGCDAwayForSurge",
            "isArcaneRuptureOneGCDAwayForFireBlast"
        }
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("ConditionChecker", ConditionChecker)

-- Export for other modules
MageControl.Rotation.ConditionChecker = ConditionChecker
