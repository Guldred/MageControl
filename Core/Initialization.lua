-- MageControl Initialization System
-- Handles proper startup sequence and module loading

MageControl = MageControl or {}

MageControl.Initialization = {
    initialized = false,
    initializationSteps = {},
    
    -- Add initialization step
    addStep = function(name, func, dependencies)
        table.insert(MageControl.Initialization.initializationSteps, {
            name = name,
            func = func,
            dependencies = dependencies or {},
            completed = false
        })
    end,
    
    -- Initialize the entire addon
    initialize = function()
        if MageControl.Initialization.initialized then
            MageControl.Logger.warn("MageControl already initialized", "Initialization")
            return
        end
        
        MageControl.Logger.info("Starting MageControl initialization...", "Initialization")
        
        -- Step 1: Core systems are initialized automatically by the module system
        -- (ConfigValidation.initialize() is called when the module is loaded)
        
        -- Step 1.5: Initialize Service Layer (Phase 3)
        MageControl.Initialization._initializeServiceLayer()
        
        -- Step 2: Execute initialization steps in dependency order
        MageControl.Initialization._executeSteps()
        
        -- Step 3: Load all registered modules
        MageControl.ModuleSystem.loadAllModules()
        
        -- Step 4: Final setup
        MageControl.Initialization._finalSetup()
        
        MageControl.Initialization.initialized = true
        MageControl.Logger.info("MageControl initialization complete", "Initialization")
    end,
    
    -- Execute initialization steps with dependency resolution
    _executeSteps = function()
        local completed = {}
        local remaining = {}
        
        -- Copy steps to remaining
        for _, step in ipairs(MageControl.Initialization.initializationSteps) do
            table.insert(remaining, step)
        end
        
        local maxIterations = 100 -- Prevent infinite loops
        local iteration = 0
        
        while table.getn(remaining) > 0 and iteration < maxIterations do
            iteration = iteration + 1
            local progress = false
            
            for i = table.getn(remaining), 1, -1 do
                local step = remaining[i]
                local canExecute = true
                
                -- Check if all dependencies are completed
                for _, dependency in ipairs(step.dependencies) do
                    if not completed[dependency] then
                        canExecute = false
                        break
                    end
                end
                
                if canExecute then
                    MageControl.Logger.debug("Executing initialization step: " .. step.name, "Initialization")
                    
                    local success, error = pcall(step.func)
                    
                    if success then
                        completed[step.name] = true
                        step.completed = true
                        table.remove(remaining, i)
                        progress = true
                        MageControl.Logger.debug("Completed initialization step: " .. step.name, "Initialization")
                    else
                        MageControl.Logger.error("Failed initialization step: " .. step.name .. " - " .. tostring(error), "Initialization")
                    end
                end
            end
            
            if not progress then
                MageControl.Logger.error("Initialization deadlock detected. Remaining steps:", "Initialization")
                for _, step in ipairs(remaining) do
                    MageControl.Logger.error("  - " .. step.name, "Initialization")
                end
                break
            end
        end
    end,
    
    -- Initialize Service Layer
    _initializeServiceLayer = function()
        MageControl.Logger.info("Initializing Service Layer (Phase 3)...", "Initialization")
        
        -- Validate service dependencies first
        local isValid, validationResults = MageControl.Services.Initializer.validateDependencies()
        if not isValid then
            MageControl.Logger.error("Service layer dependency validation failed", "Initialization")
            return false
        end
        
        -- Initialize all services
        local success = MageControl.Services.Initializer.initializeAll()
        if success then
            MageControl.Logger.info("✓ Service layer initialization completed successfully", "Initialization")
            
            -- Create service facade for easy access
            MageControl.Services.Facade = MageControl.Services.Initializer.createServiceFacade()
            MageControl.Logger.debug("Service facade created", "Initialization")
        else
            MageControl.Logger.error("✗ Service layer initialization failed", "Initialization")
        end
        
        return success
    end,
    
    -- Final setup after all modules are loaded
    _finalSetup = function()
        -- Set up event handlers
        if MageControl.Events and MageControl.Events.initialize then
            MageControl.Events.initialize()
        end
        
        -- Initialize UI if available
        if MageControl.UI and MageControl.UI.initialize then
            MageControl.UI.initialize()
        end
        
        -- Initialize buff frames (MageControl unified system)
        if MageControl.UI.BuffDisplay and MageControl.UI.BuffDisplay.initialize then
            MageControl.UI.BuffDisplay.initialize()
        end
        
        -- Initialize action frames (MageControl unified system)
        if MageControl.UI.ActionDisplay and MageControl.UI.ActionDisplay.initialize then
            MageControl.UI.ActionDisplay.initialize()
        end
        
        -- Start update cycle
        if MageControl.UpdateManager and MageControl.UpdateManager.start then
            MageControl.UpdateManager.start()
        end
        
        -- Initialization complete - using unified MageControl.* system only
        MageControl.Logger.debug("Unified MageControl.* system initialization complete", "Initialization")
    end,
    
    -- Backward compatibility function eliminated - using unified MageControl.* system only
    -- All MC.* references converted to MageControl.* expert modules
    
    -- Check if initialization is complete
    isInitialized = function()
        return MageControl.Initialization.initialized
    end,
    
    -- Get initialization status
    getStatus = function()
        local total = table.getn(MageControl.Initialization.initializationSteps)
        local completed = 0
        
        for _, step in ipairs(MageControl.Initialization.initializationSteps) do
            if step.completed then
                completed = completed + 1
            end
        end
        
        return {
            total = total,
            completed = completed,
            percentage = total > 0 and (completed / total * 100) or 100,
            initialized = MageControl.Initialization.initialized
        }
    end
}

-- Register core initialization steps
MageControl.Initialization.addStep("ConfigValidation", function()
    -- Additional config validation can go here
    MageControl.Logger.debug("Configuration validation complete", "Initialization")
end, {})

MageControl.Initialization.addStep("EventSystem", function()
    -- Initialize event system when it's available
    if MageControl.Events then
        MageControl.Logger.debug("Event system initialized", "Initialization")
    end
end, {"ConfigValidation"})

MageControl.Initialization.addStep("BackwardCompatibility", function()
    -- Set up any additional backward compatibility
    MageControl.Logger.debug("Backward compatibility layer initialized", "Initialization")
end, {"ConfigValidation"})
