-- MageControl Data Repository Service
-- Abstraction layer for all data persistence operations

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- Data Repository Interface
local IDataRepository = {
    -- Configuration methods
    getConfig = function(path, defaultValue) end,
    setConfig = function(path, value) end,
    hasConfig = function(path) end,
    removeConfig = function(path) end,
    
    -- Bulk operations
    getConfigSection = function(section) end,
    setConfigSection = function(section, data) end,
    
    -- Validation and defaults
    validateConfig = function(path, value, validator) end,
    ensureDefaults = function(defaults) end,
    
    -- Persistence operations
    save = function() end,
    reload = function() end,
    reset = function(section) end
}

-- Data Repository Implementation
local DataRepository = {}

-- Internal helper to navigate nested paths
DataRepository._navigateToPath = function(data, path, createMissing)
    if not path or path == "" then
        return data
    end
    
    local parts = {}
    for part in string.gfind(path, "[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = data
    for i = 1, table.getn(parts) - 1 do
        local part = parts[i]
        if not current[part] then
            if createMissing then
                current[part] = {}
            else
                return nil
            end
        end
        current = current[part]
    end
    
    return current, parts[table.getn(parts)]
end

-- Configuration methods
DataRepository.getConfig = function(path, defaultValue)
    if not MageControlDB then
        MageControlDB = {}
    end
    
    if not path or path == "" then
        return MageControlDB
    end
    
    local parent, key = DataRepository._navigateToPath(MageControlDB, path, false)
    if parent and key and parent[key] ~= nil then
        return parent[key]
    end
    
    return defaultValue
end

DataRepository.setConfig = function(path, value)
    if not MageControlDB then
        MageControlDB = {}
    end
    
    if not path or path == "" then
        MageControl.Logger.error("Cannot set empty path", "DataRepository")
        return false
    end
    
    local parent, key = DataRepository._navigateToPath(MageControlDB, path, true)
    if parent and key then
        parent[key] = value
        MageControl.Logger.debug("Set config: " .. path .. " = " .. tostring(value), "DataRepository")
        return true
    end
    
    MageControl.Logger.error("Failed to set config path: " .. path, "DataRepository")
    return false
end

DataRepository.hasConfig = function(path)
    if not MageControlDB then
        return false
    end
    
    local parent, key = DataRepository._navigateToPath(MageControlDB, path, false)
    return parent and key and parent[key] ~= nil
end

DataRepository.removeConfig = function(path)
    if not MageControlDB then
        return false
    end
    
    local parent, key = DataRepository._navigateToPath(MageControlDB, path, false)
    if parent and key and parent[key] ~= nil then
        parent[key] = nil
        MageControl.Logger.debug("Removed config: " .. path, "DataRepository")
        return true
    end
    
    return false
end

-- Bulk operations
DataRepository.getConfigSection = function(section)
    return DataRepository.getConfig(section, {})
end

DataRepository.setConfigSection = function(section, data)
    if not data then
        MageControl.Logger.error("Cannot set nil data for section: " .. tostring(section), "DataRepository")
        return false
    end
    
    return DataRepository.setConfig(section, data)
end

-- Validation and defaults
DataRepository.validateConfig = function(path, value, validator)
    if not validator then
        return true
    end
    
    if type(validator) == "function" then
        return validator(value)
    elseif type(validator) == "string" then
        return type(value) == validator
    elseif type(validator) == "table" then
        -- Validator is a table of valid values
        for _, validValue in ipairs(validator) do
            if value == validValue then
                return true
            end
        end
        return false
    end
    
    return true
end

DataRepository.ensureDefaults = function(defaults)
    if not defaults then
        return
    end
    
    for path, defaultValue in pairs(defaults) do
        if not DataRepository.hasConfig(path) then
            DataRepository.setConfig(path, defaultValue)
            MageControl.Logger.debug("Set default config: " .. path, "DataRepository")
        end
    end
end

-- Persistence operations
DataRepository.save = function()
    -- In WoW, SavedVariables are automatically saved
    -- This method exists for future extensibility
    MageControl.Logger.debug("Configuration saved", "DataRepository")
    return true
end

DataRepository.reload = function()
    -- Reload from SavedVariables
    -- This would typically happen on addon load
    MageControl.Logger.debug("Configuration reloaded", "DataRepository")
    return true
end

DataRepository.reset = function(section)
    if section then
        DataRepository.removeConfig(section)
        MageControl.Logger.info("Reset config section: " .. section, "DataRepository")
    else
        MageControlDB = {}
        MageControl.Logger.info("Reset all configuration", "DataRepository")
    end
    return true
end

-- Specialized methods for common operations
DataRepository.getTrinketPriority = function()
    return DataRepository.getConfig("trinkets.priorityList", {
        {name = "Trinket Slot 1", type = "trinket", slot = 13},
        {name = "Trinket Slot 2", type = "trinket", slot = 14},
        {name = "Arcane Power", type = "spell", spellName = "Arcane Power"}
    })
end

DataRepository.setTrinketPriority = function(priorityList)
    return DataRepository.setConfig("trinkets.priorityList", priorityList)
end

DataRepository.getActionBarSlots = function()
    return DataRepository.getConfig("actionBarSlots", {})
end

DataRepository.setActionBarSlots = function(slots)
    return DataRepository.setConfig("actionBarSlots", slots)
end

DataRepository.getMinManaForArcanePower = function()
    return DataRepository.getConfig("minManaForArcanePowerUse", 50)
end

DataRepository.setMinManaForArcanePower = function(value)
    if DataRepository.validateConfig("minManaForArcanePowerUse", value, function(v) 
        return type(v) == "number" and v >= 0 and v <= 100 
    end) then
        return DataRepository.setConfig("minManaForArcanePowerUse", value)
    end
    return false
end

DataRepository.getMinMissilesForCancel = function()
    return DataRepository.getConfig("minMissilesForSurgeCancel", 4)
end

DataRepository.setMinMissilesForCancel = function(value)
    if DataRepository.validateConfig("minMissilesForSurgeCancel", value, function(v) 
        return type(v) == "number" and v >= 1 and v <= 6 
    end) then
        return DataRepository.setConfig("minMissilesForSurgeCancel", value)
    end
    return false
end

-- Initialize the service
DataRepository.initialize = function()
    -- Ensure MageControlDB exists
    if not MageControlDB then
        MageControlDB = {}
    end
    
    MageControl.Logger.debug("Data Repository initialized", "DataRepository")
end

-- Register the service interface and implementation
MageControl.Services.Registry.registerInterface("IDataRepository", IDataRepository)
MageControl.Services.Registry.register("DataRepository", DataRepository)

-- Export for direct access if needed
MageControl.Services.Data = DataRepository
