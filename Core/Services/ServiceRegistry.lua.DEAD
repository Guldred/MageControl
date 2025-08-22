-- MageControl Service Registry
-- Central registry for all service interfaces and implementations

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- Service Registry for dependency injection and service location
local ServiceRegistry = {}

-- Registered services
ServiceRegistry._services = {}
ServiceRegistry._interfaces = {}

-- Register a service implementation
ServiceRegistry.register = function(interfaceName, implementation)
    if not interfaceName or not implementation then
        error("ServiceRegistry.register: interfaceName and implementation are required")
    end
    
    ServiceRegistry._services[interfaceName] = implementation
    MageControl.Logger.debug("Registered service: " .. interfaceName, "ServiceRegistry")
end

-- Get a service implementation
ServiceRegistry.get = function(interfaceName)
    local service = ServiceRegistry._services[interfaceName]
    if not service then
        MageControl.Logger.error("Service not found: " .. interfaceName, "ServiceRegistry")
        return nil
    end
    return service
end

-- Register a service interface (for documentation and validation)
ServiceRegistry.registerInterface = function(interfaceName, interface)
    ServiceRegistry._interfaces[interfaceName] = interface
    MageControl.Logger.debug("Registered interface: " .. interfaceName, "ServiceRegistry")
end

-- Validate that a service implements the required interface
ServiceRegistry.validateService = function(interfaceName, implementation)
    local interface = ServiceRegistry._interfaces[interfaceName]
    if not interface then
        return true -- No interface defined, skip validation
    end
    
    for methodName, _ in pairs(interface) do
        if not implementation[methodName] then
            MageControl.Logger.error("Service missing method: " .. methodName .. " for interface: " .. interfaceName, "ServiceRegistry")
            return false
        end
    end
    
    return true
end

-- Initialize all registered services
ServiceRegistry.initializeAll = function()
    for interfaceName, service in pairs(ServiceRegistry._services) do
        if service.initialize then
            service.initialize()
            MageControl.Logger.debug("Initialized service: " .. interfaceName, "ServiceRegistry")
        end
    end
end

-- Export the service registry
MageControl.Services.Registry = ServiceRegistry
