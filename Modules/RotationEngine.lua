MC.arcaneRotationPriority = {
    {
        name = "Channel Interruption",
        condition = function(state)
            return MC.isInterruptionRequired(state.spells, state.buffStates)
        end,
        action = function(state)
            MC.handleChannelInterruption(state.spells, state.buffs, state.buffStates)
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

MC.incantagosSpellMap = {
    ["Heroic Training Dummy"] = "Fireball",
    ["Expert Training Dummy"] = "Frostbolt",
    ["Red Affinity"] = "Fireball",
    ["Blue Affinity"] = "Frostbolt"
}

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
    
    local spellToQueue = MC.incantagosSpellMap[targetName]
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