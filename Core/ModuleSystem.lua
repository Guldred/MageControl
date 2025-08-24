-- MageControl Module System
-- Provides proper namespace management and module loading

-- Main namespace (consolidated to MC for simplicity and user familiarity)
MC = MC or {}
-- Legacy compatibility during migration
MageControl = MC -- Backward compatibility alias

-- Module registry
local modules = {}
local loadedModules = {}

-- Module system core
MC.ModuleSystem = {
    -- Register a new module
    registerModule = function(name, moduleDefinition)
        if modules[name] then
            error("MageControl: Module '" .. name .. "' is already registered")
        end
        
        if type(moduleDefinition) ~= "table" then
            error("MageControl: Module definition must be a table")
        end
        
        modules[name] = moduleDefinition
        loadedModules[name] = false
        
        MC.Logger.debug("Module registered: " .. name)
    end,
    
    -- Load a module (with dependency resolution)
    loadModule = function(name)
        if not modules[name] then
            error("MageControl: Module '" .. name .. "' is not registered")
        end
        
        if loadedModules[name] then
            return modules[name]
        end
        
        local module = modules[name]

        -- Load dependencies first
        if module.dependencies then
            for _, dependency in ipairs(module.dependencies) do
                MC.ModuleSystem.loadModule(dependency)
            end
        end
        
        -- Initialize the module
        if module.initialize and type(module.initialize) == "function" then
            module.initialize()
        end
        
        loadedModules[name] = true
        MC.Logger.debug("Module loaded: " .. name)
        
        return module
    end,
    
    -- Get a loaded module
    getModule = function(name)
        if not loadedModules[name] then
            return MC.ModuleSystem.loadModule(name)
        end
        return modules[name]
    end,
    
    -- Check if module is loaded
    isLoaded = function(name)
        return loadedModules[name] == true
    end,
    
    -- Load all registered modules
    loadAllModules = function()
        for name, _ in pairs(modules) do
            if not loadedModules[name] then
                MC.ModuleSystem.loadModule(name)
            end
        end
    end,
    
    -- Get list of all modules
    getModuleList = function()
        local moduleList = {}
        for name, _ in pairs(modules) do
            table.insert(moduleList, name)
        end
        return moduleList
    end
}

-- Helper function to create a new module
MC.createModule = function(name, dependencies)
    local module = {
        name = name,
        dependencies = dependencies or {},
        
        -- Module can define these methods
        initialize = nil,
        destroy = nil,
        
        -- Private module scope
        _private = {}
    }
    
    return module
end

-- Namespace helper for backward compatibility
MC.migrateToModule = function(legacyObject, moduleName)
    -- Helper to gradually migrate MC.* calls to proper modules
    -- This will help during the transition period
    if legacyObject and moduleName then
        local module = MC.ModuleSystem.getModule(moduleName)
        for key, value in pairs(legacyObject) do
            if not module[key] then
                module[key] = value
            end
        end
    end
end
