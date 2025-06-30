-- HELPERS
-----------------------------

local isInterruptionRequiredAfterNextMissile = function()
    if not MC.state.isChanneling then
        return false
    end

    local earliestCancelPoint = MageControlDB.minMissilesForSurgeCancel or 4

    if not MC.isInLastPossibleMissileWindow() then
        return false
    end

    local currentTime = GetTime()
    local currentMissileIndex = 0
    for i = 1, table.getn(MC.ARCANE_MISSILES_FIRE_TIMES) do
        if currentTime >= MC.ARCANE_MISSILES_FIRE_TIMES[i] then
            currentMissileIndex = i
        else
            break
        end
    end

    if currentMissileIndex < earliestCancelPoint then
        return false
    end

    local arcaneSurgeCooldownRemaining = MC.getActionSlotCooldownInSeconds(MC.getActionBarSlots().ARCANE_SURGE)

    local nextMissileIndex = currentMissileIndex + 1
    local timeUntilNextMissile = MC.ARCANE_MISSILES_FIRE_TIMES[nextMissileIndex] - currentTime
    
    local surgeCooldownReadyForNextMissile = arcaneSurgeCooldownRemaining <= timeUntilNextMissile

    MC.debugPrint("Current missile: " .. currentMissileIndex)
    MC.debugPrint("Next missile (last possible): " .. nextMissileIndex)
    MC.debugPrint("Time until next missile: " .. timeUntilNextMissile)
    MC.debugPrint("Surge cooldown ready for next missile: " .. tostring(surgeCooldownReadyForNextMissile))

    return surgeCooldownReadyForNextMissile and not MC.isHighHasteActive()
end

local isInterruptionRequired = function(spells, buffStates)
    local shouldCancelWhileHighHaste = MC.isHighHasteActive()
            and MC.state.isChanneling and
            not buffStates.arcaneRupture and
            spells.arcaneRuptureReady

    local shouldCancelWhileLowHaste = not MC.isHighHasteActive()
            and MC.state.isChanneling and
            not buffStates.arcaneRupture and
            spells.arcaneRuptureReady and
            not MC.isActionSlotCooldownReadyAndUsableInSeconds(MC.getActionBarSlots().ARCANE_SURGE, 1)

    return shouldCancelWhileHighHaste or shouldCancelWhileLowHaste
end

local handleChannelInterruption = function(spells, buffs, buffStates, forcedSurge)
    ChannelStopCastingNextTick()
    if (spells.arcaneSurgeReady or forcedSurge) then
        MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
    else
        MC.safeQueueSpell("Arcane Rupture", buffs, buffStates)
    end
    return true
end

-----------------------------
-- MAIN PRIO LOGIC
-----------------------------

MC.arcaneRotationPriority = {
    {
        name = "Channel Interruption for Rebuff",
        condition = function(state)
            return isInterruptionRequired(state.spells, state.buffStates)
        end,
        action = function(state)
            handleChannelInterruption(state.spells, state.buffs, state.buffStates, false)
            return true
        end
    },
    { --TODO: Get this to work
        name = "Channel Interruption for Surge at last second",
        condition = function(state)
            return isInterruptionRequiredAfterNextMissile(state.spells, state.buffStates)
        end,
        action = function(state)
            handleChannelInterruption(state.spells, state.buffs, state.buffStates, true)
            return true
        end
    },
    {
        name = "Wait for Cast",
        condition = function(state)
            return MC.shouldWaitForCast()
        end,
        action = function(state)
            MC.debugPrint("Ignored input since current cast is more than .75s away from finishing")
            return true
        end
    },
    {
        name = "Arcane Surge (Low Haste)",
        condition = function(state)
            return state.spells.arcaneSurgeReady and not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Trying to cast Arcane Surge")
            MC.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Clearcasting Missiles",
        condition = function(state)
            return state.buffStates.clearcasting and state.missilesWorthCasting
        end,
        action = function(state)
            MC.debugPrint("Clearcasting active and Arcane Missiles worth casting")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture Maintenance",
        condition = function(state)
            return state.spells.arcaneRuptureReady and 
                   not state.missilesWorthCasting and 
                   not MC.state.isCastingArcaneRupture
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture ready and not casting")
            MC.safeQueueSpell("Arcane Rupture", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Missiles Worth Casting",
        condition = function(state)
            return state.missilesWorthCasting
        end,
        action = function(state)
            MC.debugPrint("Arcane Missiles worth casting")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Arcane Surge)",
        condition = function(state)
            return MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER) and
                    state.spells.arcaneSurgeReady and
                    not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture is one GCD away, casting Arcane Surge")
            MC.safeQueueSpell("Arcane Surge", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Arcane Rupture One GCD Away (Fire Blast)",
        condition = function(state)
            return MC.isArcaneRuptureOneGlobalAwayAfterCurrentCast(state.slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER_FIREBLAST) and
                    state.spells.fireblastReady and
                    not MC.checkImmunity("fire") and
                    not MC.isHighHasteActive()
        end,
        action = function(state)
            MC.debugPrint("Arcane Rupture is one Fireblast GCD away, casting Fire Blast")
            MC.safeQueueSpell("Fire Blast", state.buffs, state.buffStates)
            return true
        end
    },
    {
        name = "Default Missiles",
        condition = function(state)
            return true -- Always true - this is the fallback
        end,
        action = function(state)
            MC.debugPrint("Defaulting to Arcane Missiles")
            MC.safeQueueSpell("Arcane Missiles", state.buffs, state.buffStates)
            return true
        end
    }
}

MC.cooldownActions = {
    TRINKET1 = {
        name = "First Trinket",
        isAvailable = function()
            local start, cooldown, enabled = GetInventoryItemCooldown("player", 13)
            return cooldown == 0 and enabled == 1
        end,
        execute = function()
            UseInventoryItem(13)
        end
    },
    TRINKET2 = {
        name = "Second Trinket",
        isAvailable = function()
            local start, cooldown, enabled = GetInventoryItemCooldown("player", 14)
            return cooldown == 0 and enabled == 1
        end,
        execute = function()
            UseInventoryItem(14)
        end
    },
    ARCANE_POWER = {
        name = "Arcane Power",
        isAvailable = function()
            local arcanePowerSlot = MageControlDB.actionBarSlots.ARCANE_POWER
            if not arcanePowerSlot or arcanePowerSlot <= 0 then
                return false
            end
            
            local start, duration = GetActionCooldown(arcanePowerSlot)
            local isCooldownReady = start == 0 or (start + duration <= GetTime())
            local hasSufficientMana = MageControlDB.minManaForArcanePowerUse <= MC.getCurrentManaPercent()
            
            return isCooldownReady and hasSufficientMana
        end,
        execute = function()
            CastSpellByName("Arcane Power")
        end
    }
}

MC.stopChannelAndCastSurge = function()
    local spells = MC.getSpellAvailability()

    if (spells.arcaneSurgeReady) then
        ChannelStopCastingNextTick()
        QueueSpellByName("Arcane Surge")
    end
end

local function updateGlobalCooldownState()
    if (GetTime() - MC.state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        MC.state.globalCooldownActive = false
    end
end

local function gatherRotationState()
    local buffs = MC.CURRENT_BUFFS
    local spells = MC.getSpellAvailability()
    local buffStates = MC.getCurrentBuffs(buffs)
    local slots = MC.getActionBarSlots()
    local missilesWorthCasting = MC.isMissilesWorthCasting(buffStates)
    
    return {
        buffs = buffs,
        spells = spells,
        buffStates = buffStates,
        slots = slots,
        missilesWorthCasting = missilesWorthCasting
    }
end

MC.executeArcaneRotation = function()
    updateGlobalCooldownState()
    
    local state = gatherRotationState()
    
    MC.debugPrint("Evaluating spell priority")

    for i, priority in ipairs(MC.arcaneRotationPriority) do
        if priority.condition(state) then
            if MC.DEBUG then
                MC.debugPrint("Executing priority: " .. priority.name)
            end
            priority.action(state)
            return
        end
    end

    MC.debugPrint("ERROR: No rotation priority matched!")
end

MC.arcaneRotation = function()
    MC.CURRENT_BUFFS = MC.getBuffs()
    MC.checkManaWarning(MC.CURRENT_BUFFS)
    MC.checkChannelFinished()
    MC.executeArcaneRotation()
end

MC.arcaneIncantagos = function()
    local targetName = UnitName("target")
    if not targetName or targetName == "" then
        return
    end
    
    local spellToQueue = MC.INCANTAGOS_SPELL_MAP[targetName]
    if spellToQueue then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        local isArcaneSpell = channeling == 1 or castId == MC.SPELL_INFO.ARCANE_RUPTURE.id
        
        if isArcaneSpell then
            SpellStopCasting()
        end
        
        QueueSpellByName(spellToQueue)
    else
        MC.arcaneRotation()
    end
end

MC.activateTrinketAndAP = function()
    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER" }
    end

    for i, priorityKey in ipairs(MageControlDB.cooldownPriorityMap) do
        local cooldownAction = MC.cooldownActions[priorityKey]
        if cooldownAction and cooldownAction.isAvailable() then
            cooldownAction.execute()
            return true
        end
    end
    
    return false
end