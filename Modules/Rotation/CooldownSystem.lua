-- MageControl Cooldown System
-- Manages trinket and Arcane Power activation logic

MageControl = MageControl or {}
MageControl.Rotation = MageControl.Rotation or {}

-- Create the CooldownSystem module  
-- ConfigValidation is direct unified module, no dependency needed
local CooldownSystem = MageControl.createModule("CooldownSystem", {"Logger"})

-- Initialize the cooldown system
CooldownSystem.initialize = function()
    MageControl.Logger.debug("Cooldown System initialized", "CooldownSystem")
end

-- Activate priority action (trinkets and Arcane Power)
CooldownSystem.activatePriorityAction = function()
    -- Read priority list from MageControlDB (where Priority Panel saves it)
    local priorityList = MageControlDB.trinkets and MageControlDB.trinkets.priorityList or {}
    
    if table.getn(priorityList) == 0 then
        -- Initialize with default priority if none exists
        priorityList = {
            {name = "Trinket Slot 1", type = "trinket", slot = 13},
            {name = "Trinket Slot 2", type = "trinket", slot = 14},
            {name = "Arcane Power", type = "spell", spellName = "Arcane Power"}
        }
        MageControl.Logger.debug("Using default trinket priority list", "CooldownSystem")
    end

    -- Map priority list items to MageControl.CooldownSystem.cooldownActions keys
    for i, priorityItem in ipairs(priorityList) do
        local actionKey = CooldownSystem._getActionKey(priorityItem)
        if actionKey then
            local cooldownAction = MageControl.CooldownSystem.cooldownActions[actionKey]
            if cooldownAction and cooldownAction.isAvailable() then
                MageControl.Logger.debug("Activating priority item: " .. priorityItem.name, "CooldownSystem")
                cooldownAction.execute()
                return true
            else
                if cooldownAction then
                    MageControl.Logger.debug("Priority item not available: " .. priorityItem.name, "CooldownSystem")
                else
                    MageControl.Logger.debug("No action defined for: " .. priorityItem.name, "CooldownSystem")
                end
            end
        end
    end

    MageControl.Logger.debug("No priority items were activated", "CooldownSystem")
    return false
end

-- Map priority list item to MageControl.CooldownSystem.cooldownActions key
CooldownSystem._getActionKey = function(item)
    if not item or not item.type then
        return nil
    end
    
    if item.type == "trinket" then
        if item.slot == 13 then
            return "TRINKET1"
        elseif item.slot == 14 then
            return "TRINKET2"
        end
    elseif item.type == "spell" and item.name == "Arcane Power" then
        return "ARCANE_POWER"
    end
    
    return nil
end

-- Get trinket cooldown information
CooldownSystem.getTrinketCooldowns = function()
    local cooldowns = {}
    local priorityList = MageControl.ConfigValidation.get("trinkets.priorityList") or {}
    
    for i, item in ipairs(priorityList) do
        if item.type == "trinket" and item.slot then
            local cooldownRemaining = MageControl.StateManager.getInventoryItemCooldownInSeconds(item.slot)
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
    local slots = MageControl.StateManager.getActionBarSlots()
    if not slots or not slots.ARCANE_POWER then
        return nil
    end
    
    local cooldownRemaining = MageControl.StateManager.getActionSlotCooldownInSeconds(slots.ARCANE_POWER)
    return {
        slot = slots.ARCANE_POWER,
        cooldownRemaining = cooldownRemaining,
        ready = cooldownRemaining <= 0
    }
end

-- Check if any priority items are ready
CooldownSystem.hasPriorityItemsReady = function()
    local priorityList = MageControl.ConfigValidation.get("trinkets.priorityList") or {}
    
    for i, item in ipairs(priorityList) do
        local actionKey = CooldownSystem._getActionKey(item)
        if actionKey then
            local cooldownAction = MageControl.CooldownSystem.cooldownActions[actionKey]
            if cooldownAction and cooldownAction.isAvailable() then
                return true
            end
        end
    end
    
    return false
end

-- Get cooldown system statistics
CooldownSystem.getStats = function()
    local priorityList = MageControl.ConfigValidation.get("trinkets.priorityList") or {}
    local readyCount = 0
    
    for i, item in ipairs(priorityList) do
        local actionKey = CooldownSystem._getActionKey(item)
        if actionKey then
            local cooldownAction = MageControl.CooldownSystem.cooldownActions[actionKey]
            if cooldownAction and cooldownAction.isAvailable() then
                readyCount = readyCount + 1
            end
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
