-- MageControl WoW API Service
-- Abstraction layer for all World of Warcraft API interactions

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- WoW API Service Interface
local IWoWApiService = {
    -- Player state methods
    getPlayerMana = function() end,
    getPlayerMaxMana = function() end,
    getPlayerHealth = function() end,
    getPlayerMaxHealth = function() end,
    isPlayerInCombat = function() end,
    isPlayerChanneling = function() end,
    getPlayerCastingInfo = function() end,
    
    -- Spell and action methods
    castSpellByName = function(spellName) end,
    useAction = function(slot) end,
    useInventoryItem = function(slot) end,
    getActionCooldown = function(slot) end,
    getInventoryItemCooldown = function(slot) end,
    getSpellCooldown = function(spellName) end,
    hasAction = function(slot) end,
    getActionInfo = function(slot) end,
    
    -- Buff and debuff methods
    getPlayerBuffs = function() end,
    getPlayerDebuffs = function() end,
    hasPlayerBuff = function(buffName) end,
    getBuffTimeRemaining = function(buffName) end,
    
    -- Target methods
    hasTarget = function() end,
    getTargetHealth = function() end,
    isTargetEnemy = function() end,
    getTargetDistance = function() end,
    
    -- Timing methods
    getCurrentTime = function() end,
    getGlobalCooldown = function() end,
    isGlobalCooldownActive = function() end
}

-- WoW API Service Implementation
local WoWApiService = {}

-- Player state methods
WoWApiService.getPlayerMana = function()
    return UnitMana("player") or 0
end

WoWApiService.getPlayerMaxMana = function()
    return UnitManaMax("player") or 1
end

WoWApiService.getPlayerHealth = function()
    return UnitHealth("player") or 0
end

WoWApiService.getPlayerMaxHealth = function()
    return UnitHealthMax("player") or 1
end

WoWApiService.isPlayerInCombat = function()
    return UnitAffectingCombat("player") == 1
end

WoWApiService.isPlayerChanneling = function()
    return ChannelInfo() ~= nil
end

WoWApiService.getPlayerCastingInfo = function()
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

-- Spell and action methods
WoWApiService.castSpellByName = function(spellName)
    if not spellName then
        return false
    end
    CastSpellByName(spellName)
    return true
end

WoWApiService.useAction = function(slot)
    if not slot or slot < 1 or slot > 120 then
        return false
    end
    UseAction(slot)
    return true
end

WoWApiService.useInventoryItem = function(slot)
    if not slot or slot < 1 or slot > 19 then
        return false
    end
    UseInventoryItem(slot)
    return true
end

WoWApiService.getActionCooldown = function(slot)
    if not slot then
        return 0, 0
    end
    local start, duration = GetActionCooldown(slot)
    return start or 0, duration or 0
end

WoWApiService.getInventoryItemCooldown = function(slot)
    if not slot then
        return 0, 0
    end
    local start, duration = GetInventoryItemCooldown("player", slot)
    return start or 0, duration or 0
end

WoWApiService.getSpellCooldown = function(spellName)
    if not spellName then
        return 0, 0
    end
    local start, duration = GetSpellCooldown(spellName, BOOKTYPE_SPELL)
    return start or 0, duration or 0
end

WoWApiService.hasAction = function(slot)
    if not slot then
        return false
    end
    return HasAction(slot) == 1
end

WoWApiService.getActionInfo = function(slot)
    if not slot then
        return nil
    end
    local text, type, id = GetActionText(slot)
    return {
        text = text or "",
        type = type or "",
        id = id or 0
    }
end

-- Buff and debuff methods
WoWApiService.getPlayerBuffs = function()
    local buffs = {}
    local i = 1
    while UnitBuff("player", i) do
        local icon, applications = UnitBuff("player", i)
        table.insert(buffs, {
            index = i,
            icon = icon,
            applications = applications or 1
        })
        i = i + 1
    end
    return buffs
end

WoWApiService.hasPlayerBuff = function(buffName)
    if not buffName then
        return false
    end
    -- This is a simplified implementation - in practice, you'd need to match buff names
    local i = 1
    while UnitBuff("player", i) do
        -- In WoW 1.12.1, buff names aren't directly available, would need tooltip parsing
        i = i + 1
    end
    return false
end

-- Target methods
WoWApiService.hasTarget = function()
    return UnitExists("target") == 1
end

WoWApiService.getTargetHealth = function()
    return UnitHealth("target") or 0
end

WoWApiService.isTargetEnemy = function()
    return UnitCanAttack("player", "target") == 1
end

-- Timing methods
WoWApiService.getCurrentTime = function()
    return GetTime()
end

WoWApiService.getGlobalCooldown = function()
    -- In WoW 1.12.1, GCD is typically 1.5 seconds, modified by haste
    return 1.5
end

WoWApiService.isGlobalCooldownActive = function()
    -- Check if any action is on GCD
    local start, duration = GetActionCooldown(1)
    return start > 0 and duration > 0 and duration <= 1.5
end

-- Initialize the service
WoWApiService.initialize = function()
    MageControl.Logger.debug("WoW API Service initialized", "WoWApiService")
end

-- Register the service interface and implementation
MageControl.Services.Registry.registerInterface("IWoWApiService", IWoWApiService)
MageControl.Services.Registry.register("WoWApiService", WoWApiService)

-- Export for direct access if needed
MageControl.Services.WoWApi = WoWApiService
