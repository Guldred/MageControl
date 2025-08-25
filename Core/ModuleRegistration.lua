-- MageControl Module Registration
-- Registers all core modules with the module system

-- Register core modules that other modules depend on
MageControl.ModuleSystem.registerModule("Logger", MageControl.Logger)
-- ConfigValidation is a direct unified module, not registered with module system
MageControl.ModuleSystem.registerModule("ErrorHandler", MageControl.ErrorHandler)

-- Log successful registration
MageControl.Logger.debug("Core modules registered: Logger, ErrorHandler (ConfigValidation is direct unified module)", "ModuleRegistration")
