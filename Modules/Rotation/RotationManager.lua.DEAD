-- MageControl Rotation Manager
-- Main controller for the arcane mage rotation system

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the RotationManager module
local RotationManager = MageControl.createModule("RotationManager", {"ConfigManager", "Logger"})

-- Module state
RotationManager.currentBuffs = {}
RotationManager.lastExecutionTime = 0
RotationManager.executionInterval = 0.1 -- Minimum time between rotation executions

-- Initialize the rotation manager
RotationManager.initialize = function()
    MageControl.Logger.debug("Rotation Manager initialized", "RotationManager")
end

-- Main rotation execution function
RotationManager.executeArcaneRotation = function()
    -- Prevent too frequent executions
    local currentTime = GetTime()
    if currentTime - RotationManager.lastExecutionTime < RotationManager.executionInterval then
        return
    end
    RotationManager.lastExecutionTime = currentTime

    -- Update global cooldown state
    RotationManager._updateGlobalCooldownState()
    
    -- Gather current rotation state
    local state = RotationManager._gatherRotationState()
    
    MageControl.Logger.debug("Evaluating spell priority", "RotationManager")

    -- Get priority system from PrioritySystem module
    local prioritySystem = MageControl.ModuleSystem.getModule("PrioritySystem")
    if not prioritySystem then
        MageControl.Logger.error("PrioritySystem module not found", "RotationManager")
        return
    end

    -- Execute highest priority action
    local priorities = prioritySystem.getArcaneRotationPriorities()
    for i, priority in ipairs(priorities) do
        if priority.condition(state) then
            MageControl.Logger.debug("Executing priority: " .. priority.name, "RotationManager")
            priority.action(state)
            return
        end
    end

    MageControl.Logger.error("No rotation priority matched!", "RotationManager")
end

-- Main arcane rotation entry point
RotationManager.arcaneRotation = function()
    RotationManager.currentBuffs = MC.getBuffs()
    RotationManager._checkManaWarning(RotationManager.currentBuffs)
    MC.checkChannelFinished()
    RotationManager.executeArcaneRotation()
end

-- Arcane Incantagos rotation (special target-based rotation)
RotationManager.arcaneIncantagos = function()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return
    end
    
    local spellToQueue = nil
    
    -- Check for Incantagos encounter spells first
    if MageControlDB.bossEncounters and MageControlDB.bossEncounters.incantagos and MageControlDB.bossEncounters.incantagos.enabled then
        spellToQueue = MC.INCANTAGOS_SPELL_MAP[targetName]
    end
    
    -- Check for training dummy spells if enabled and no Incantagos spell found
    if not spellToQueue and MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies then
        spellToQueue = MC.TRAINING_DUMMY_SPELL_MAP[targetName]
    end
    
    if spellToQueue then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        local isArcaneSpell = channeling == 1 or castId == MC.SPELL_INFO.ARCANE_RUPTURE.id
        
        if not isArcaneSpell then
            ChannelStopCastingNextTick()
        end
        
        QueueSpellByName(spellToQueue)
    else
        RotationManager.arcaneRotation()
    end
end

-- Stop channeling and cast Arcane Surge
RotationManager.stopChannelAndCastSurge = function()
    local spells = MC.getSpellAvailability()

    if spells.arcaneSurgeReady then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

-- Activate trinkets and Arcane Power based on priority
RotationManager.activateTrinketAndAP = function()
    local cooldownSystem = MageControl.ModuleSystem.getModule("CooldownSystem")
    if not cooldownSystem then
        MageControl.Logger.error("CooldownSystem module not found", "RotationManager")
        return false
    end

    return cooldownSystem.activatePriorityAction()
end

-- Private helper functions
RotationManager._updateGlobalCooldownState = function()
    if GetTime() - MC.state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS then
        MC.state.globalCooldownActive = false
    end
end

RotationManager._gatherRotationState = function()
    local buffs = RotationManager.currentBuffs
    local spells = MC.getSpellAvailability()
    local buffStates = MC.getCurrentBuffs(buffs)
    local slots = MC.getActionBarSlots()
    local missilesWorthCasting = MC.areMissilesWorthCasting()

    return {
        buffs = buffs,
        spells = spells,
        buffStates = buffStates,
        slots = slots,
        missilesWorthCasting = missilesWorthCasting
    }
end

RotationManager._checkManaWarning = function(buffs)
    -- Delegate to utility functions if available
    if MC.checkManaWarning then
        MC.checkManaWarning(buffs)
    end
end

-- Get rotation statistics
RotationManager.getStats = function()
    return {
        lastExecutionTime = RotationManager.lastExecutionTime,
        executionInterval = RotationManager.executionInterval,
        currentBuffsCount = table.getn(RotationManager.currentBuffs)
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("RotationManager", RotationManager)

-- Backward compatibility
MC.executeArcaneRotation = function()
    RotationManager.executeArcaneRotation()
end

MC.arcaneRotation = function()
    RotationManager.arcaneRotation()
end

MC.arcaneIncantagos = function()
    RotationManager.arcaneIncantagos()
end

MC.stopChannelAndCastSurge = function()
    RotationManager.stopChannelAndCastSurge()
end

MC.activateTrinketAndAP = function()
    return RotationManager.activateTrinketAndAP()
end

-- Export for other modules
MageControl.Rotation.Manager = RotationManager
