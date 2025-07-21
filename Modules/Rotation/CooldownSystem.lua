-- MageControl Cooldown System
-- Manages trinket and Arcane Power activation logic

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the CooldownSystem module
local CooldownSystem = MageControl.createModule("CooldownSystem", {"ConfigManager", "Logger"})

-- Initialize the cooldown system
CooldownSystem.initialize = function()
    MageControl.Logger.debug("Cooldown System initialized", "CooldownSystem")
end

-- Activate priority action (trinkets and Arcane Power)
CooldownSystem.activatePriorityAction = function()
    local priorityList = MageControl.ConfigManager.get("trinkets.priorityList") or {}
    
    if table.getn(priorityList) == 0 then
        MageControl.Logger.debug("No trinket priority list configured", "CooldownSystem")
        return false
    end

    for i, priorityItem in ipairs(priorityList) do
        if CooldownSystem._shouldActivateItem(priorityItem) then
            local success = CooldownSystem._activateItem(priorityItem)
            if success then
                MageControl.Logger.debug("Activated priority item: " .. priorityItem.name, "CooldownSystem")
                return true
            end
        end
    end

    MageControl.Logger.debug("No priority items were activated", "CooldownSystem")
    return false
end

-- Check if an item should be activated
CooldownSystem._shouldActivateItem = function(item)
    if not item or not item.slot then
        return false
    end

    -- Check if item is ready (not on cooldown)
    local cooldownRemaining = MC.getInventoryItemCooldownInSeconds(item.slot)
    if cooldownRemaining > 0 then
        MageControl.Logger.debug("Item " .. (item.name or "unknown") .. " on cooldown: " .. cooldownRemaining .. "s", "CooldownSystem")
        return false
    end

    -- Check mana threshold if configured
    if item.manaThreshold then
        local currentMana = UnitMana("player")
        local maxMana = UnitManaMax("player")
        local manaPercent = (currentMana / maxMana) * 100
        
        if manaPercent < item.manaThreshold then
            MageControl.Logger.debug("Mana too low for " .. (item.name or "unknown") .. ": " .. manaPercent .. "%", "CooldownSystem")
            return false
        end
    end

    -- Check health threshold if configured
    if item.healthThreshold then
        local currentHealth = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        local healthPercent = (currentHealth / maxHealth) * 100
        
        if healthPercent < item.healthThreshold then
            MageControl.Logger.debug("Health too low for " .. (item.name or "unknown") .. ": " .. healthPercent .. "%", "CooldownSystem")
            return false
        end
    end

    -- Check combat state if required
    if item.combatOnly and not UnitAffectingCombat("player") then
        MageControl.Logger.debug("Not in combat for combat-only item: " .. (item.name or "unknown"), "CooldownSystem")
        return false
    end

    return true
end

-- Activate an item
CooldownSystem._activateItem = function(item)
    if not item then
        return false
    end

    local success, error = MageControl.ErrorHandler.safeCall(
        function()
            if item.type == "trinket" and item.slot then
                UseInventoryItem(item.slot)
                MageControl.Logger.info("Used trinket: " .. (item.name or "slot " .. item.slot), "CooldownSystem")
            elseif item.type == "spell" and item.spellName then
                QueueSpellByName(item.spellName)
                MageControl.Logger.info("Cast spell: " .. item.spellName, "CooldownSystem")
            else
                MageControl.Logger.warn("Unknown item type or missing data: " .. (item.name or "unknown"), "CooldownSystem")
                return false
            end
            return true
        end,
        MageControl.ErrorHandler.TYPES.ITEM,
        {module = "CooldownSystem", item = item.name or "unknown"}
    )

    if not success then
        MageControl.Logger.error("Failed to activate item: " .. tostring(error), "CooldownSystem")
        return false
    end

    return true
end

-- Get trinket cooldown information
CooldownSystem.getTrinketCooldowns = function()
    local cooldowns = {}
    local priorityList = MageControl.ConfigManager.get("trinkets.priorityList") or {}
    
    for i, item in ipairs(priorityList) do
        if item.type == "trinket" and item.slot then
            local cooldownRemaining = MC.getInventoryItemCooldownInSeconds(item.slot)
            table.insert(cooldowns, {
                name = item.name or ("Slot " .. item.slot),
                slot = item.slot,
                cooldownRemaining = cooldownRemaining,
                ready = cooldownRemaining <= 0
            })
        end
    end
    
    return cooldowns
end

-- Get Arcane Power cooldown
CooldownSystem.getArcanePowerCooldown = function()
    local slots = MC.getActionBarSlots()
    if not slots or not slots.ARCANE_POWER then
        return nil
    end
    
    local cooldownRemaining = MC.getActionSlotCooldownInSeconds(slots.ARCANE_POWER)
    return {
        slot = slots.ARCANE_POWER,
        cooldownRemaining = cooldownRemaining,
        ready = cooldownRemaining <= 0
    }
end

-- Check if any priority items are ready
CooldownSystem.hasPriorityItemsReady = function()
    local priorityList = MageControl.ConfigManager.get("trinkets.priorityList") or {}
    
    for i, item in ipairs(priorityList) do
        if CooldownSystem._shouldActivateItem(item) then
            return true
        end
    end
    
    return false
end

-- Get cooldown system statistics
CooldownSystem.getStats = function()
    local priorityList = MageControl.ConfigManager.get("trinkets.priorityList") or {}
    local readyCount = 0
    
    for i, item in ipairs(priorityList) do
        if CooldownSystem._shouldActivateItem(item) then
            readyCount = readyCount + 1
        end
    end
    
    return {
        totalPriorityItems = table.getn(priorityList),
        readyItems = readyCount,
        trinketCooldowns = CooldownSystem.getTrinketCooldowns(),
        arcanePowerCooldown = CooldownSystem.getArcanePowerCooldown()
    }
end

-- Validate priority item structure
CooldownSystem.validatePriorityItem = function(item)
    if not item then
        return false, "Item is nil"
    end
    
    if not item.type or (item.type ~= "trinket" and item.type ~= "spell") then
        return false, "Item must have type 'trinket' or 'spell'"
    end
    
    if item.type == "trinket" and not item.slot then
        return false, "Trinket items must have a slot number"
    end
    
    if item.type == "spell" and not item.spellName then
        return false, "Spell items must have a spellName"
    end
    
    return true, "Item is valid"
end

-- Register the module
MageControl.ModuleSystem.registerModule("CooldownSystem", CooldownSystem)

-- Export for other modules
MageControl.Rotation.CooldownSystem = CooldownSystem
