-- MageControl Module Registration
-- Registers all core modules with the module system

-- Register core modules that other modules depend on
MageControl.ModuleSystem.registerModule("Logger", MageControl.Logger)
MageControl.ModuleSystem.registerModule("ConfigManager", MageControl.ConfigManager)
MageControl.ModuleSystem.registerModule("ErrorHandler", MageControl.ErrorHandler)

-- Log successful registration
MageControl.Logger.debug("Core modules registered: Logger, ConfigManager, ErrorHandler", "ModuleRegistration")
