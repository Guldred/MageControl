-- MageControl Timing Calculations (Direct Access)
-- Expert on GCD timing, cooldown calculations, and action timing logic
-- Location: Core/Actions/TimingCalculations.lua (find timing calculations here)

MageControl = MageControl or {}
MageControl.TimingCalculations = {}

-- Check if Arcane Rupture is one GCD away
MageControl.TimingCalculations.isArcaneRuptureOneGCDAway = function(slot, timing)
    local cooldown = MageControl.StateManager.getActionSlotCooldownInSeconds(slot)
    return (cooldown < timing and cooldown > 0)
end

-- Check if Arcane Rupture is one GCD away after current cast
MageControl.TimingCalculations.isArcaneRuptureOneGCDAwayAfterCurrentCast = function(slot, timing)
    local cooldownInSeconds = MageControl.StateManager.getActionSlotCooldownInSeconds(slot)
    local cooldownAfterCurrentCast = MageControl.TimingCalculations.calculateRemainingTimeAfterCurrentCast(cooldownInSeconds)
    return (cooldownAfterCurrentCast < timing and cooldownAfterCurrentCast > 0)
end

-- Calculate remaining time after current cast finishes
MageControl.TimingCalculations.calculateRemainingTimeAfterCurrentCast = function(time)
    local stateManager = MageControl.StateManager
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
    
    MageControl.Logger.debug("Cooldown right now: " .. time .. " --- Cooldown after current cast: " .. calculatedCooldownAfterCurrentCast .. " seconds", "TimingCalculations")
    return calculatedCooldownAfterCurrentCast
end

-- Calculate Arcane Missile fire times
MageControl.TimingCalculations.calculateArcaneMissileFireTimes = function(duration)
    local NUM_MISSILES = MageControl.ConfigValidation.get("missiles.count") or 6
    local LAG_BUFFER = MageControl.ConfigValidation.get("missiles.lagBuffer") or 0.05
    local timeStart = GetTime()
    local fireTimes = {}

    local durationInSeconds = duration / 1000
    local timePerMissile = durationInSeconds / NUM_MISSILES

    for i = 1, NUM_MISSILES do
        fireTimes[i] = timeStart + (i * timePerMissile) + LAG_BUFFER
    end
    
    MageControl.Logger.debug("Calculated " .. NUM_MISSILES .. " missile fire times over " .. durationInSeconds .. "s", "TimingCalculations")
    return fireTimes
end

-- Check if we're in the last possible missile window for Surge
MageControl.TimingCalculations.isInLastPossibleMissileWindow = function()
    local stateManager = MageControl.StateManager
    if not stateManager then
        return false
    end
    
    if not stateManager.state.isChanneling or
            not stateManager.state.surgeActiveTill or
            not MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES or
            table.getn(MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES) == 0 then
        return false
    end

    local currentTime = GetTime()

    if stateManager.state.surgeActiveTill <= currentTime then
        return false
    end

    local lastPossibleMissileIndex = 0
    for i = 1, table.getn(MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES) do
        if MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES[i] <= stateManager.state.surgeActiveTill then
            lastPossibleMissileIndex = i
        else
            break
        end
    end

    if lastPossibleMissileIndex == 0 then
        return false
    end

    local currentMissileIndex = 0
    for i = 1, table.getn(MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES) do
        if currentTime >= MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES[i] then
            currentMissileIndex = i
        else
            break
        end
    end

    local nextMissileIndex = currentMissileIndex + 1

    local isNextMissileTheLast = (nextMissileIndex == lastPossibleMissileIndex)
    local isInWindow = (nextMissileIndex <= table.getn(MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES)) and
            (currentTime < MageControl.StateManager.ARCANE_MISSILES_FIRE_TIMES[nextMissileIndex])

    return isNextMissileTheLast and isInWindow
end

-- Initialize timing calculations system
MageControl.TimingCalculations.initialize = function()
    MageControl.Logger.debug("Timing Calculations system initialized", "TimingCalculations")
end

-- TimingCalculations converted to MageControl.TimingCalculations unified system
-- All MC.* references converted to MageControl.* expert modules
