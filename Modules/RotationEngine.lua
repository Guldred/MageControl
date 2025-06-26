MC.executeArcaneRotation = function()
    if (GetTime() - MC.state.globalCooldownStart > MC.GLOBAL_COOLDOWN_IN_SECONDS) then
        MC.state.globalCooldownActive = false
    end

    local buffs = MC.CURRENT_BUFFS
    local spells = MC.getSpellAvailability()
    local buffStates = MC.getCurrentBuffs(buffs)
    local slots = MC.getActionBarSlots()
    local missilesWorthCasting = MC.isMissilesWorthCasting(buffStates)

    MC.debugPrint("Evaluating spell priority")

    if MC.handleChannelInterruption(spells, buffStates, buffs) then
        return
    end

    if MC.shouldWaitForCast() then
        MC.debugPrint("Ignored input since current cast is more than .75s away from finishing")
        return
    end

    if (spells.arcaneSurgeReady and not MC.isHighHasteActive()) then
        MC.debugPrint("Trying to cast Arcane Surge")
        MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
        return
    end

    if (buffStates.clearcasting and missilesWorthCasting) then
        MC.debugPrint("Clearcasting active and Arcane Missiles worth casting")
        MC.safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (spells.arcaneRuptureReady and not missilesWorthCasting and not MC.state.isCastingArcaneRupture) then
        MC.debugPrint("Arcane Rupture ready and not casting")
        MC.safeQueueSpell("Arcane Rupture", buffs, buffStates)
        return
    end

    if (missilesWorthCasting) then
        MC.debugPrint("Arcane Missiles worth casting")
        MC.safeQueueSpell("Arcane Missiles", buffs, buffStates)
        return
    end

    if (MC.isArcaneRuptureOneGlobalAway(slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER) and spells.arcaneSurgeReady) then
        MC.debugPrint("Arcane Rupture is one GCD away, casting Arcane Surge")
        MC.safeQueueSpell("Arcane Surge", buffs, buffStates)
        return
    end

    if (MC.isArcaneRuptureOneGlobalAway(slots.ARCANE_RUPTURE, MC.TIMING.GCD_BUFFER_FIREBLAST) and spells.fireblastReady and not MC.checkImmunity("fire")) then
        MC.debugPrint("Arcane Rupture is one Fireblast GCD away, casting Fire Blast")
        MC.safeQueueSpell("Fire Blast", buffs, buffStates)
        return
    end

    MC.debugPrint("Defaulting to Arcane Missiles")
    MC.safeQueueSpell("Arcane Missiles", buffs, buffStates)
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

    local targetSpellMap = {
        ["Heroic Training Dummy"] = "Fireball",
        ["Expert Training Dummy"] = "Frostbolt",
        ["Red Affinity"] = "Fireball",
        ["Blue Affinity"] = "Frostbolt"
    }

    local spellToQueue = targetSpellMap[targetName]
    if spellToQueue then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        local isArcaneSpell = channeling == 1 or castId == MC.SPELL_INFO.ARCANE_RUPTURE.id
        if (isArcaneSpell) then
            SpellStopCasting()
        end
        QueueSpellByName(spellToQueue)
    else
        MC.arcaneRotation()
    end
end

MC.activateTrinketAndAP = function()
    local s1, firstTrinketCurrentCooldown, firstTrinketCanBeEnabled = GetInventoryItemCooldown("player", 13)
    local isFirstTrinketUsable = firstTrinketCurrentCooldown == 0 and firstTrinketCanBeEnabled == 1
    local s2, secondTrinketCurrentCooldown, secondTrinketCanBeEnabled = GetInventoryItemCooldown("player", 14)
    local isSecondTrinketUsable = secondTrinketCurrentCooldown == 0 and secondTrinketCanBeEnabled == 1

    local arcanePowerSlot = MageControlDB.actionBarSlots.ARCANE_POWER
    local arcanePowerIsReady = false
    if arcanePowerSlot and arcanePowerSlot > 0 then
        local start, duration = GetActionCooldown(arcanePowerSlot)
        arcanePowerIsReady = (start == 0 or (start + duration <= GetTime())) and
                MageControlDB.minManaForArcanePowerUse <= MC.getCurrentManaPercent()
    end

    if not MageControlDB.cooldownPriorityMap then
        MageControlDB.cooldownPriorityMap = { "TRINKET1", "TRINKET2", "ARCANE_POWER"}
    end

    local availabilityMap = {
        TRINKET1 = isFirstTrinketUsable,
        TRINKET2 = isSecondTrinketUsable,
        ARCANE_POWER = arcanePowerIsReady
    }

    local actionMap = {
        TRINKET1 = function()
            UseInventoryItem(13)
        end,
        TRINKET2 = function()
            UseInventoryItem(14)
        end,
        ARCANE_POWER = function()
            CastSpellByName("Arcane Power")
        end
    }

    for i, priorityKey in ipairs(MageControlDB.cooldownPriorityMap) do
        if availabilityMap[priorityKey] then
            actionMap[priorityKey]()
            return true
        end
    end

    return false
end