-- MageControl Configuration Manager
-- Centralizes all configuration and provides validation

MageControl = MageControl or {}

MageControl.ConfigManager = {
    -- Default configuration values
    defaults = {
        -- Action bar slots
        actionBarSlots = {
            FIREBLAST = 1,
            ARCANE_RUPTURE = 2,
            ARCANE_SURGE = 5
        },
        
        -- Timing configuration
        timing = {
            CAST_FINISH_THRESHOLD = 0.75,
            GCD_REMAINING_THRESHOLD = 0.75,
            GCD_BUFFER = 1.5,
            GCD_BUFFER_FIREBLAST = 1.5,
            ARCANE_RUPTURE_MIN_DURATION = 2
        },
        
        -- Haste configuration
        haste = {
            BASE_VALUE = 10,
            HASTE_THRESHOLD = 30
        },
        
        -- UI configuration
        ui = {
            debugEnabled = false,
            showBuffDisplay = true,
            showActionDisplay = true,
            lockFrames = false
        },
        
        -- Rotation settings
        rotation = {
            minMissilesForSurgeCancel = 4,
            minManaForArcanePowerUse = 50,
            enableAutoRotation = true,
            enableAutoTarget = true,
            preferredSpells = {"Arcane Missiles", "Arcane Rupture"}
        },
        
        -- Boss encounters configuration
        bossEncounters = {
            incantagos = {
                enabled = false,
                description = "Automatically pick correct spell for adds on Incantagos"
            }
        },
        
        -- Trinket and cooldown settings
        trinkets = {
            priorityList = {
                {type = "trinket", slot = 13, name = "Trinket Slot 1", id = "trinket1"},
                {type = "trinket", slot = 14, name = "Trinket Slot 2", id = "trinket2"},
                {type = "spell", name = "Arcane Power", spellId = 12042, id = "arcane_power"}
            }
        },
        
        -- Missile settings
        missiles = {
            count = 6,
            lagBuffer = 0.05
        },
        
        -- Buff settings
        buffs = {
            cacheMaxAge = 0.1
        },
        
        -- Constants
        constants = {
            GLOBAL_COOLDOWN_IN_SECONDS = 1.5
        }
    },
    
    -- Current configuration (merged with saved data)
    current = {},
    
    -- Performance optimized configuration access with path caching
    _pathCache = {},
    
    -- Optimized path parsing with caching
    _parsePath = function(path)
        if MageControl.ConfigManager._pathCache[path] then
            return MageControl.ConfigManager._pathCache[path]
        end
        
        local keys = {}
        for key in string.gfind(path, "[^.]+") do
            table.insert(keys, key)
        end
        
        MageControl.ConfigManager._pathCache[path] = keys
        return keys
    end,
    
    -- Optimized get configuration value with caching
    get = function(path)
        if not path then
            return MageControl.ConfigManager.current
        end
        
        local keys = MageControl.ConfigManager._parsePath(path)
        local value = MageControl.ConfigManager.current
        
        -- Optimized table traversal
        for i = 1, table.getn(keys) do
            local key = keys[i]
            if type(value) == "table" and value[key] ~= nil then
                value = value[key]
            else
                -- Only log warnings in debug mode to reduce overhead
                if MageControl.Logger.isDebugEnabled() then
                    MageControl.Logger.warn("Configuration path not found: " .. path, "ConfigManager")
                end
                return nil
            end
        end
        
        return value
    end,
    
    -- Optimized set configuration value with validation
    set = function(path, value)
        if not path then
            MageControl.Logger.error("Cannot set empty configuration path", "ConfigManager")
            return false
        end
        
        local keys = MageControl.ConfigManager._parsePath(path)
        local current = MageControl.ConfigManager.current
        
        -- Navigate to parent and set value efficiently
        local keyCount = table.getn(keys)
        for i = 1, keyCount - 1 do
            local key = keys[i]
            if type(current[key]) ~= "table" then
                current[key] = {}
            end
            current = current[key]
        end
        
        local finalKey = keys[keyCount]
        local oldValue = current[finalKey]
        current[finalKey] = value
        
        -- Only log in debug mode for performance
        if MageControl.Logger.isDebugEnabled() then
            MageControl.Logger.debug("Config set: " .. path .. " = " .. tostring(value), "ConfigManager")
        end
        
        return true
    end,
    
    -- Initialize configuration system
    initialize = function()
        -- Ensure saved variables exist
        MageControlDB = MageControlDB or {}
        
        -- Debug: Log what's in MageControlDB before merge
        if MageControlDB.trinkets and MageControlDB.trinkets.priorityList then
            MageControl.Logger.debug("Found saved trinkets.priorityList with " .. table.getn(MageControlDB.trinkets.priorityList) .. " items", "ConfigManager")
        else
            MageControl.Logger.debug("No saved trinkets.priorityList found, will use defaults", "ConfigManager")
        end
        
        -- Special handling for trinkets.priorityList to preserve user settings
        local savedTrinketList = nil
        if MageControlDB.trinkets and MageControlDB.trinkets.priorityList and table.getn(MageControlDB.trinkets.priorityList) > 0 then
            savedTrinketList = MageControlDB.trinkets.priorityList
            MageControl.Logger.debug("Preserving user's saved trinket priority list", "ConfigManager")
        end
        
        -- Merge defaults with saved configuration
        MageControl.ConfigManager.current = MageControl.ConfigManager._deepMerge(
            MageControl.ConfigManager.defaults,
            MageControlDB
        )
        
        -- Restore saved trinket list if it existed (prevent overwrite by defaults)
        if savedTrinketList then
            MageControl.ConfigManager.current.trinkets.priorityList = savedTrinketList
            MageControl.Logger.debug("Restored user's trinket priority list", "ConfigManager")
        end
        
        -- Debug: Log what's in current after merge
        local currentList = MageControl.ConfigManager.current.trinkets.priorityList
        if currentList then
            MageControl.Logger.debug("After merge, trinkets.priorityList has " .. table.getn(currentList) .. " items", "ConfigManager")
            for i, item in ipairs(currentList) do
                MageControl.Logger.debug("  Priority " .. i .. ": " .. (item.name or "unknown"), "ConfigManager")
            end
        end
        
        -- Validate configuration
        MageControl.ConfigManager._validateConfig()
        
        MageControl.Logger.info("Configuration system initialized", "ConfigManager")
    end,
    
    -- Reset configuration to defaults
    reset = function()
        MageControlDB = MageControl.ConfigManager._deepCopy(MageControl.ConfigManager.defaults)
        MageControl.ConfigManager.current = MageControl.ConfigManager._deepCopy(MageControl.ConfigManager.defaults)
        MageControl.Logger.info("Configuration reset to defaults", "ConfigManager")
    end,
    
    -- Reset specific section
    resetSection = function(section)
        if MageControl.ConfigManager.defaults[section] then
            MageControl.ConfigManager.current[section] = MageControl.ConfigManager._deepCopy(MageControl.ConfigManager.defaults[section])
            MageControlDB[section] = MageControl.ConfigManager._deepCopy(MageControl.ConfigManager.defaults[section])
            MageControl.Logger.info("Configuration section reset: " .. section, "ConfigManager")
        else
            MageControl.Logger.error("Unknown configuration section: " .. section, "ConfigManager")
        end
    end,
    
    -- Get all configuration
    getAll = function()
        return MageControl.ConfigManager.current
    end,
    
    -- Private helper functions
    _deepCopy = function(original)
        local copy = {}
        for key, value in pairs(original) do
            if type(value) == "table" then
                copy[key] = MageControl.ConfigManager._deepCopy(value)
            else
                copy[key] = value
            end
        end
        return copy
    end,
    
    _deepMerge = function(defaults, saved)
        local result = MageControl.ConfigManager._deepCopy(defaults)
        
        if type(saved) ~= "table" then
            return result
        end
        
        for key, value in pairs(saved) do
            if type(value) == "table" and type(result[key]) == "table" then
                result[key] = MageControl.ConfigManager._deepMerge(result[key], value)
            else
                result[key] = value
            end
        end
        
        return result
    end,
    
    _validateConfig = function()
        -- Add validation logic here as needed
        local config = MageControl.ConfigManager.current
        
        -- Validate action bar slots
        if config.actionBarSlots then
            for spell, slot in pairs(config.actionBarSlots) do
                if type(slot) ~= "number" or slot < 1 or slot > 120 then
                    MageControl.Logger.warn("Invalid action bar slot for " .. spell .. ": " .. tostring(slot), "ConfigManager")
                    config.actionBarSlots[spell] = MageControl.ConfigManager.defaults.actionBarSlots[spell]
                end
            end
        end
        
        -- Validate percentage values
        if config.rotation and config.rotation.minManaForArcanePowerUse then
            local mana = config.rotation.minManaForArcanePowerUse
            if type(mana) ~= "number" or mana < 0 or mana > 100 then
                MageControl.Logger.warn("Invalid mana percentage: " .. tostring(mana), "ConfigManager")
                config.rotation.minManaForArcanePowerUse = MageControl.ConfigManager.defaults.rotation.minManaForArcanePowerUse
            end
        end
    end
}

-- Backward compatibility helpers
MC.getActionBarSlots = function()
    return MageControl.ConfigManager.get("actionBarSlots") or MageControl.ConfigManager.defaults.actionBarSlots
end

MC.DEFAULT_ACTIONBAR_SLOT = MageControl.ConfigManager.defaults.actionBarSlots
MC.TIMING = MageControl.ConfigManager.defaults.timing
MC.HASTE = MageControl.ConfigManager.defaults.haste
MC.GLOBAL_COOLDOWN_IN_SECONDS = MageControl.ConfigManager.defaults.constants.GLOBAL_COOLDOWN_IN_SECONDS
