-- MageControl WoW API Direct Access
-- Simple, direct access to World of Warcraft API functions
-- Location: Core/WoWApi.lua (no service registry, no interfaces)

MageControl = MageControl or {}
MageControl.WoWApi = {}

-- Player State Functions
MageControl.WoWApi.getPlayerMana = function()
    return UnitMana("player") or 0
end

MageControl.WoWApi.getPlayerMaxMana = function()
    return UnitManaMax("player") or 1
end

MageControl.WoWApi.getPlayerHealth = function()
    return UnitHealth("player") or 0
end

MageControl.WoWApi.getPlayerMaxHealth = function()
    return UnitHealthMax("player") or 1
end

MageControl.WoWApi.isPlayerInCombat = function()
    return UnitAffectingCombat("player") == 1
end

MageControl.WoWApi.isPlayerChanneling = function()
    return ChannelInfo() ~= nil
end

MageControl.WoWApi.getPlayerCastingInfo = function()
    local spell, rank, displayName, icon, startTime, endTime = CastingInfo()
    if spell then
        return {
            spell = spell,
            rank = rank,
            displayName = displayName,
            icon = icon,
            startTime = startTime,
            endTime = endTime,
            isChanneling = false
        }
    end

    -- Check for channeling
    spell, rank, displayName, icon, startTime, endTime = ChannelInfo()
    if spell then
        return {
            spell = spell,
            rank = rank,
            displayName = displayName,
            icon = icon,
            startTime = startTime,
            endTime = endTime,
            isChanneling = true
        }
    end

    return nil
end

-- Spell and Action Functions
MageControl.WoWApi.castSpellByName = function(spellName)
    if not spellName or spellName == "" then
        MageControl.Logger.error("castSpellByName: spellName is required", "WoWApi")
        return false
    end

    CastSpellByName(spellName)
    return true
end

MageControl.WoWApi.useAction = function(slot)
    if not slot or slot < 1 or slot > 120 then
        MageControl.Logger.error("useAction: invalid slot " .. tostring(slot), "WoWApi")
        return false
    end

    UseAction(slot)
    return true
end

MageControl.WoWApi.getActionCooldown = function(slot)
    if not slot then
        return 0, 0, 0
    end

    local start, duration, enabled = GetActionCooldown(slot)
    return start or 0, duration or 0, enabled or 0
end

MageControl.WoWApi.hasAction = function(slot)
    return HasAction(slot) == 1
end

MageControl.WoWApi.getActionInfo = function(slot)
    local actionType, id, subType = GetActionInfo(slot)
    return actionType, id, subType
end

-- Buff and Debuff Functions
MageControl.WoWApi.getPlayerBuffs = function()
    local buffs = {}
    local index = 1

    while true do
        local buffTexture = GetPlayerBuff(index, "HELPFUL")
        if not buffTexture or buffTexture == -1 then
            break
        end

        local timeLeft = GetPlayerBuffTimeLeft(index, "HELPFUL")
        local applications = GetPlayerBuffApplications(index, "HELPFUL")

        table.insert(buffs, {
            index = index,
            texture = buffTexture,
            timeLeft = timeLeft or 0,
            applications = applications or 1
        })

        index = index + 1
    end

    return buffs
end

MageControl.WoWApi.hasPlayerBuff = function(buffTexture)
    if not buffTexture then
        return false
    end

    local index = 1
    while true do
        local texture = GetPlayerBuff(index, "HELPFUL")
        if not texture or texture == -1 then
            break
        end

        if texture == buffTexture then
            return true
        end

        index = index + 1
    end

    return false
end

MageControl.WoWApi.getBuffTimeRemaining = function(buffTexture)
    if not buffTexture then
        return 0
    end

    local index = 1
    while true do
        local texture = GetPlayerBuff(index, "HELPFUL")
        if not texture or texture == -1 then
            break
        end

        if texture == buffTexture then
            return GetPlayerBuffTimeLeft(index, "HELPFUL") or 0
        end

        index = index + 1
    end

    return 0
end

MageControl.WoWApi.getSpellIdForName = function(spellName)
    if not spellName or type(spellName) ~= "string" then
        return 0
    end

    if GetSpellIdForName then
        return GetSpellIdForName(spellName)
    else
        -- Fallback: can't get ID without Nampower
        return 0
    end
end

MageControl.WoWApi.getSpellNameAndRankForId = function(spellId)
    if not spellId or type(spellId) ~= "number" or spellId <= 0 then
        return nil, nil
    end

    if GetSpellNameAndRankForId then
        return GetSpellNameAndRankForId(spellId)
    else
        -- Fallback: can't get name/rank without Nampower
        return nil, nil
    end
end

-- Target Functions
MageControl.WoWApi.getTargetName = function()
    return UnitName("target") or ""
end

MageControl.WoWApi.hasTarget = function()
    return UnitExists("target") == 1
end

MageControl.WoWApi.isTargetEnemy = function()
    return UnitCanAttack("player", "target") == 1
end

-- Time Functions
MageControl.WoWApi.getCurrentTime = function()
    return GetTime()
end

-- Backward compatibility - direct global access for easy discoverability
-- These point to the same functions but make it clear where they're defined
MC.WoWApi = MageControl.WoWApi
