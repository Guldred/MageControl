-- MageControl Module System
-- Provides proper namespace management and module loading

-- MageControl Module System - Unified Namespace
-- All MC.* references converted to MageControl.* expert modules
MageControl = MageControl or {}
MageControl.ModuleSystem = {}

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
        
        MageControl.Logger.debug("Module registered: " .. name, "ModuleSystem")
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
        
        -- Debug: Verify module exists and has proper structure
        if not module then
            error("MageControl: Module '" .. name .. "' not found in registry")
        end
        
        if type(module) ~= "table" then
            error("MageControl: Module '" .. name .. "' is not a valid table")
        end

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
        MageControl.Logger.debug("Module loaded: " .. name, "ModuleSystem")
        
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

-- Helper function to create a new module (unified MageControl.* system)
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

-- ModuleSystem converted to MageControl.ModuleSystem unified system
-- All MC.* references converted to MageControl.* expert modules
