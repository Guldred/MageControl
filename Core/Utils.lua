MC.getTalentRank = function(tab, num)
    -- AP: GetTalentInfo(1,19)
    -- Fireblast: (2,5)
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab,num)
    return rank
end

MC.getActionBarSlots = function()
    return MageControlDB.actionBarSlots
end

MC.checkImmunity = function(type)
    local immunityList = MC.IMMUNITY_LIST[type] or {}
    local listExists = (MC.IMMUNITY_LIST[type] ~= nil)

    MC.debugPrint("Immunity check - Type: " .. type .. ", List exists: " .. tostring(listExists))
    MC.debugPrint("Target: " .. tostring(MC.CURRENT_TARGET))

    local isImmuneTarget = immunityList[MC.CURRENT_TARGET] or false
    MC.debugPrint("Is immune: " .. tostring(isImmuneTarget))

    return isImmuneTarget
end

MC.isValidActionSlot = function(slot)
    return slot and slot > 0 and slot <= 120
end

MC.getCurrentManaPercent = function()
    local maxMana = UnitManaMax("player")
    if maxMana and maxMana > 0 then
        return (UnitMana("player") / maxMana) * 100
    else
        return 0
    end
end

MC.normSpellName = function(name)
    if not name then return "" end
    return string.lower(name)
end

MC.getSpellCostByName = function(spellName)
    local normalizedName = MC.normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if MC.normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.cost
        end
    end
    return 0
end

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

MC.getBuffNameByID = function(buffID)
    for _, info in pairs(MC.BUFF_INFO) do
        if info.id == buffID then
            return info.name
        end
    end

    return "Untracked Buff"
end

MC.getSpellCostPercent = function(spellName, buffStates)
    local manaCost = MC.getModifiedSpellManaCost(spellName, buffStates)
    local maxMana = UnitManaMax("player")
    if maxMana and manaCost and manaCost > 0 then
        return (manaCost / maxMana) * 100
    end
    return 0
end

MC.checkChannelFinished = function()
    if (MC.state.channelFinishTime < GetTime()) then
        MC.state.isChanneling = false
    end
end

MC.getCurrentBuffs = function(buffs)
    return {
        clearcasting = MC.findBuff(buffs, MC.BUFF_INFO.CLEARCASTING.name),
        temporalConvergence = MC.findBuff(buffs, MC.BUFF_INFO.TEMPORAL_CONVERGENCE.name),
        arcaneRupture = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_RUPTURE.name),
        arcanePower = MC.findBuff(buffs, MC.BUFF_INFO.ARCANE_POWER.name)
    }
end

MC.isActionSlotCooldownReady = function(slot)
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

    return remaining <= 0 or isJustGlobalCooldown
end

MC.getActionSlotCooldownInMilliseconds = function(slot)
    if not MC.isValidActionSlot(slot) then
        return 0
    end

    local start, duration, enabled = GetActionCooldown(slot)
    local currentTime = GetTime()
    return (start + duration) - currentTime
end

MC.getCurrentHasteValue = function()
    local hastePercent = MageControlDB.haste.BASE_VALUE

    local hasteBuffs = {
        [MC.BUFF_INFO.ARCANE_POWER.name] = 30,
        [MC.BUFF_INFO.MIND_QUICKENING.name] = 33,
        [MC.BUFF_INFO.ENLIGHTENED_STATE.name] = 20,
        [MC.BUFF_INFO.SULFURON_BLAZE.name] = 5
    }

    for buffName, buffHaste in pairs(hasteBuffs) do
        if MC.findBuff(MC.CURRENT_BUFFS, buffName) ~= nil then
            hastePercent = hastePercent + buffHaste
        end
    end

    return hastePercent
end

MC.isHighHasteActive = function()
    local isAboveHasteThreshold = MC.getCurrentHasteValue() > MageControlDB.haste.HASTE_THRESHOLD
    return isAboveHasteThreshold
end

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

MC.showCurrentConfig = function()
    local slots = MC.getActionBarSlots()
    MC.printMessage("MageControl - Current Configuration:")
    MC.printMessage("  Fire Blast: Slot " .. slots.FIREBLAST)
    MC.printMessage("  Arcane Rupture: Slot " .. slots.ARCANE_RUPTURE)
    MC.printMessage("  Arcane Surge: Slot " .. slots.ARCANE_SURGE)
end

MC.getSpellIdByName = function(spellName)
    local normalizedName = MC.normSpellName(spellName)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if MC.normSpellName(spellInfo.name) == normalizedName then
            return spellInfo.id
        end
    end
    return nil
end

MC.getSpellNameById = function(spellId)
    for _, spellInfo in pairs(MC.SPELL_INFO) do
        if spellInfo.id == spellId then
            return spellInfo.name
        end
    end
    return tostring(spellId)
end