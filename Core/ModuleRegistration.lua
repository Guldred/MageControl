-- MageControl Module Registration (Event-Driven)
-- Defers module registration until ADDON_LOADED when all files are guaranteed loaded

MageControl = MageControl or {}
MageControl.ModuleRegistration = {}

-- Module registration function (called on ADDON_LOADED event)
MageControl.ModuleRegistration.registerAllModules = function()
    -- Register core modules that other modules depend on
    MageControl.ModuleSystem.registerModule("Logger", MageControl.Logger)
    -- ConfigValidation is a direct unified module, not registered with module system
    MageControl.ModuleSystem.registerModule("ErrorHandler", MageControl.ErrorHandler)
    MageControl.ModuleSystem.registerModule("StateManager", MageControl.StateManager)

    -- Register UI Framework modules (required for UI components)
    MageControl.ModuleSystem.registerModule("UIFramework", MageControl.UIFramework)
    MageControl.ModuleSystem.registerModule("TabManager", MageControl.TabManager)

    -- Register Rotation modules (required for rotation system dependencies)
    MageControl.ModuleSystem.registerModule("ConditionChecker", MageControl.ConditionChecker)
    MageControl.ModuleSystem.registerModule("ActionHandler", MageControl.ActionHandler)

    -- Log successful registration
    MageControl.Logger.debug("Core modules registered: Logger, ErrorHandler, StateManager, UIFramework, TabManager, ConditionChecker, ActionHandler (ConfigValidation is direct unified module)", "ModuleRegistration")
end
