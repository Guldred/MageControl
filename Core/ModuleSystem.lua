-- MageControl Module System
-- Provides proper namespace management and module loading

-- Create the main namespace (keeping MC for backward compatibility during transition)
MageControl = MageControl or {}
MC = MC or {} -- Legacy global, will be phased out

-- Module registry
local modules = {}
local loadedModules = {}

-- Module system core
MageControl.ModuleSystem = {
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
        
        MageControl.Logger.debug("Module registered: " .. name)
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
                MageControl.ModuleSystem.loadModule(dependency)
            end
        end
        
        -- Initialize the module
        if module.initialize and type(module.initialize) == "function" then
            module.initialize()
        end
        
        loadedModules[name] = true
        MageControl.Logger.debug("Module loaded: " .. name)
        
        return module
    end,
    
    -- Get a loaded module
    getModule = function(name)
        if not loadedModules[name] then
            return MageControl.ModuleSystem.loadModule(name)
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
                MageControl.ModuleSystem.loadModule(name)
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
MageControl.createModule = function(name, dependencies)
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
MageControl.migrateToModule = function(legacyObject, moduleName)
    -- Helper to gradually migrate MC.* calls to proper modules
    -- This will help during the transition period
    if legacyObject and moduleName then
        local module = MageControl.ModuleSystem.getModule(moduleName)
        for key, value in pairs(legacyObject) do
            if not module[key] then
                module[key] = value
            end
        end
    end
end
