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
            enableAutoRotation = true
        },
        
        -- Constants
        constants = {
            GLOBAL_COOLDOWN_IN_SECONDS = 1.5
        }
    },
    
    -- Current configuration (merged with saved data)
    current = {},
    
    -- Initialize configuration system
    initialize = function()
        -- Ensure saved variables exist
        MageControlDB = MageControlDB or {}
        
        -- Merge defaults with saved configuration
        MageControl.ConfigManager.current = MageControl.ConfigManager._deepMerge(
            MageControl.ConfigManager.defaults,
            MageControlDB
        )
        
        -- Validate configuration
        MageControl.ConfigManager._validateConfig()
        
        MageControl.Logger.info("Configuration system initialized", "ConfigManager")
    end,
    
    -- Get configuration value
    get = function(path)
        local keys = {}
        for key in string.gfind(path, "[^.]+") do
            table.insert(keys, key)
        end
        
        local value = MageControl.ConfigManager.current
        for _, key in ipairs(keys) do
            if type(value) == "table" and value[key] ~= nil then
                value = value[key]
            else
                MageControl.Logger.warn("Configuration path not found: " .. path, "ConfigManager")
                return nil
            end
        end
        
        return value
    end,
    
    -- Set configuration value
    set = function(path, value)
        local keys = {}
        for key in string.gfind(path, "[^.]+") do
            table.insert(keys, key)
        end
        
        if table.getn(keys) == 0 then
            return false
        end
        
        local current = MageControl.ConfigManager.current
        local savedCurrent = MageControlDB
        
        -- Navigate to the parent of the target key
        for i = 1, table.getn(keys) - 1 do
            local key = keys[i]
            if type(current[key]) ~= "table" then
                current[key] = {}
            end
            if type(savedCurrent[key]) ~= "table" then
                savedCurrent[key] = {}
            end
            current = current[key]
            savedCurrent = savedCurrent[key]
        end
        
        -- Set the value
        local finalKey = keys[table.getn(keys)]
        current[finalKey] = value
        savedCurrent[finalKey] = value
        
        MageControl.Logger.debug("Configuration updated: " .. path .. " = " .. tostring(value), "ConfigManager")
        return true
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
