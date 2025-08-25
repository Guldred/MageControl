-- MageControl Action Handler
-- Handles all rotation action execution logic

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the ActionHandler module
-- ConfigValidation is direct unified module, no dependency needed
local ActionHandler = MageControl.createModule("ActionHandler", {"Logger"})

-- Initialize the action handler
ActionHandler.initialize = function()
    MageControl.Logger.debug("Action Handler initialized", "ActionHandler")
end

-- Handle missiles interruption for Arcane Rupture rebuff
ActionHandler.handleMissilesInterruptionForRuptureRebuff = function(spells, buffs, buffStates)
    ChannelStopCastingNextTick()
    if spells.arcaneSurgeReady and not MC.isHighHasteActive() then
        ActionHandler.castSpell("Arcane Surge", buffs, buffStates)
    else
        ActionHandler.castSpell("Arcane Rupture", buffs, buffStates)
    end
    return true
end

-- Handle missiles interruption for Arcane Surge
ActionHandler.handleMissilesInterruptionForSurge = function(buffs, buffStates)
    ChannelStopCastingNextTick()
    ActionHandler.castSpell("Arcane Surge", buffs, buffStates)
    return true
end

-- Handle waiting for cast to finish
ActionHandler.handleWaitForCast = function(state)
    MageControl.Logger.debug("Ignored input since current cast is more than .75s away from finishing", "ActionHandler")
    return true
end

-- Handle Arcane Surge casting (low haste)
ActionHandler.handleArcaneSurge = function(state)
    MageControl.Logger.debug("Trying to cast Arcane Surge", "ActionHandler")
    ActionHandler.castSpell("Arcane Surge", state.buffs, state.buffStates)
    return true
end

-- Handle clearcasting missiles
ActionHandler.handleClearcastingMissiles = function(state)
    MageControl.Logger.debug("Clearcasting active, casting Arcane Missiles", "ActionHandler")
    ActionHandler.castSpell("Arcane Missiles", state.buffs, state.buffStates)
    return true
end

-- Handle Arcane Rupture maintenance
ActionHandler.handleArcaneRuptureMaintenance = function(state)
    MageControl.Logger.debug("Arcane Rupture ready and not casting", "ActionHandler")
    ActionHandler.castSpell("Arcane Rupture", state.buffs, state.buffStates)
    return true
end

-- Handle missiles worth casting
ActionHandler.handleMissilesWorthCasting = function(state)
    MageControl.Logger.debug("Arcane Missiles worth casting", "ActionHandler")
    ActionHandler.castSpell("Arcane Missiles", state.buffs, state.buffStates)
    return true
end

-- Handle Arcane Rupture one GCD away (cast Arcane Surge)
ActionHandler.handleArcaneRuptureOneGCDSurge = function(state)
    MageControl.Logger.debug("Arcane Rupture is one GCD away, casting Arcane Surge", "ActionHandler")
    ActionHandler.castSpell("Arcane Surge", state.buffs, state.buffStates)
    return true
end

-- Handle Arcane Rupture one GCD away (cast Fire Blast)
ActionHandler.handleArcaneRuptureOneGCDFireBlast = function(state)
    MageControl.Logger.debug("Arcane Rupture is one Fireblast GCD away, casting Fire Blast", "ActionHandler")
    ActionHandler.castSpell("Fire Blast", state.buffs, state.buffStates)
    return true
end

-- Handle default missiles (fallback)
ActionHandler.handleDefaultMissiles = function(state)
    MageControl.Logger.debug("Defaulting to Arcane Missiles", "ActionHandler")
    ActionHandler.castSpell("Arcane Missiles", state.buffs, state.buffStates)
    return true
end

-- Safe spell casting with error handling
ActionHandler.castSpell = function(spellName, buffs, buffStates)
    local success, error = MageControl.ErrorHandler.safeCall(
        function()
            if MC.safeQueueSpell then
                MC.safeQueueSpell(spellName, buffs, buffStates)
            else
                -- Fallback to direct casting if safeQueueSpell is not available
                QueueSpellByName(spellName)
            end
        end,
        MageControl.ErrorHandler.TYPES.SPELL,
        {module = "ActionHandler", spell = spellName}
    )
    
    if success then
        MageControl.Logger.debug("Successfully queued spell: " .. spellName, "ActionHandler")
    else
        MageControl.Logger.error("Failed to cast spell: " .. spellName .. " - " .. tostring(error), "ActionHandler")
    end
    
    return success
end

-- Queue Arcane Explosion
ActionHandler.queueArcaneExplosion = function()
    local success, error = MageControl.ErrorHandler.safeCall(
            function()
                QueueSpellByName("Arcane Explosion")
            end,
            MageControl.ErrorHandler.TYPES.SPELL,
            {module = "ActionHandler", spell = "Arcane Explosion"}
    )
    
    if success then
        MageControl.Logger.debug("Successfully queued Arcane Explosion", "ActionHandler")
    else
        MageControl.Logger.error("Failed to queue Arcane Explosion: " .. tostring(error), "ActionHandler")
    end
    
    return success
end

-- Validate action parameters
ActionHandler.validateActionParams = function(spellName, buffs, buffStates)
    if not spellName or type(spellName) ~= "string" then
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

-- Get action statistics
ActionHandler.getStats = function()
    return {
        totalActions = 10,
        availableActions = {
            "handleMissilesInterruptionForRuptureRebuff",
            "handleMissilesInterruptionForSurge",
            "handleWaitForCast",
            "handleArcaneSurge",
            "handleClearcastingMissiles",
            "handleArcaneRuptureMaintenance",
            "handleMissilesWorthCasting",
            "handleArcaneRuptureOneGCDSurge",
            "handleArcaneRuptureOneGCDFireBlast",
            "handleDefaultMissiles"
        }
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("ActionHandler", ActionHandler)

-- Backward compatibility
MC.queueArcaneExplosion = function()
    -- Delegate to ActionManager for proper timing logic
    local actionManager = MageControl.ModuleSystem.getModule("ActionManager")
    if actionManager then
        return actionManager.queueArcaneExplosion()
    else
        -- Fallback to ActionHandler if ActionManager not available
        return ActionHandler.queueArcaneExplosion()
    end
end

-- Export for other modules
MageControl.Rotation.ActionHandler = ActionHandler
