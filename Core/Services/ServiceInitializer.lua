-- MageControl Service Initializer
-- Coordinates the initialization of all service layer components

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- Service Initializer
local ServiceInitializer = {}

-- Service initialization order (dependencies first)
ServiceInitializer.INITIALIZATION_ORDER = {
    "WoWApiService",    -- No dependencies
    "DataRepository",   -- No dependencies  
    "EventService",     -- Depends on UpdateManager (optional)
    "RotationService"   -- Depends on all above services
}

-- Initialize all services in proper dependency order
ServiceInitializer.initializeAll = function()
    MageControl.Logger.info("Starting service layer initialization", "ServiceInitializer")
    
    local initializationResults = {}
    local successCount = 0
    local totalServices = table.getn(ServiceInitializer.INITIALIZATION_ORDER)
    
    for i, serviceName in ipairs(ServiceInitializer.INITIALIZATION_ORDER) do
        local success, errorMsg = ServiceInitializer._initializeService(serviceName)
        initializationResults[serviceName] = {
            success = success,
            error = errorMsg
        }
        
        if success then
            successCount = successCount + 1
            MageControl.Logger.info("✓ " .. serviceName .. " initialized successfully", "ServiceInitializer")
        else
            MageControl.Logger.error("✗ " .. serviceName .. " initialization failed: " .. (errorMsg or "Unknown error"), "ServiceInitializer")
        end
    end
    
    -- Log summary
    MageControl.Logger.info("Service initialization complete: " .. successCount .. "/" .. totalServices .. " services initialized", "ServiceInitializer")
    
    -- Publish initialization complete event
    local eventService = MageControl.Services.Registry.get("EventService")
    if eventService then
        eventService.publish(eventService.EVENTS.ADDON_INITIALIZED, {
            serviceResults = initializationResults,
            successCount = successCount,
            totalServices = totalServices
        })
    end
    
    return successCount == totalServices
end

-- Initialize a specific service
ServiceInitializer._initializeService = function(serviceName)
    local service = nil
    
    -- Direct access to services instead of registry lookup to avoid circular dependency
    if serviceName == "WoWApiService" then
        service = MageControl.Services.WoWApi
    elseif serviceName == "DataRepository" then
        service = MageControl.Services.Data
    elseif serviceName == "EventService" then
        service = MageControl.Services.Events
    elseif serviceName == "RotationService" then
        service = MageControl.Services.Rotation
    end
    
    if not service then
        return false, "Service not found: " .. serviceName
    end
    
    if not service.initialize then
        -- Service doesn't have an initialize method, consider it successful
        return true, nil
    end
    
    -- Call the service's initialize method with error handling
    local success, result = pcall(service.initialize)
    if not success then
        return false, tostring(result)
    end
    
    -- If initialize returns false explicitly, treat as failure
    if result == false then
        return false, "Service initialize method returned false"
    end
    
    return true, nil
end

-- Validate service dependencies
ServiceInitializer.validateDependencies = function()
    MageControl.Logger.debug("Validating service dependencies", "ServiceInitializer")
    
    local validationResults = {}
    local allValid = true
    
    -- Check that all required services are registered
    for i, serviceName in ipairs(ServiceInitializer.INITIALIZATION_ORDER) do
        local service = MageControl.Services.Registry.get(serviceName)
        local isValid = service ~= nil
        
        validationResults[serviceName] = {
            registered = isValid,
            hasInitialize = isValid and service.initialize ~= nil
        }
        
        if not isValid then
            allValid = false
            MageControl.Logger.error("Required service not registered: " .. serviceName, "ServiceInitializer")
        end
    end
    
    -- Validate specific service interfaces
    ServiceInitializer._validateServiceInterfaces(validationResults)
    
    return allValid, validationResults
end

-- Validate that services implement their required interfaces
ServiceInitializer._validateServiceInterfaces = function(results)
    -- Validate WoW API Service
    local wowApiService = MageControl.Services.Registry.get("WoWApiService")
    if wowApiService then
        local requiredMethods = {"getPlayerMana", "getPlayerMaxMana", "castSpellByName", "useAction", "getCurrentTime"}
        for i, method in ipairs(requiredMethods) do
            if not wowApiService[method] then
                results.WoWApiService.missingMethods = results.WoWApiService.missingMethods or {}
                table.insert(results.WoWApiService.missingMethods, method)
                MageControl.Logger.error("WoWApiService missing required method: " .. method, "ServiceInitializer")
            end
        end
    end
    
    -- Validate Data Repository
    local dataRepo = MageControl.Services.Registry.get("DataRepository")
    if dataRepo then
        local requiredMethods = {"getConfig", "setConfig", "getTrinketPriority", "getMinManaForArcanePower"}
        for i, method in ipairs(requiredMethods) do
            if not dataRepo[method] then
                results.DataRepository.missingMethods = results.DataRepository.missingMethods or {}
                table.insert(results.DataRepository.missingMethods, method)
                MageControl.Logger.error("DataRepository missing required method: " .. method, "ServiceInitializer")
            end
        end
    end
    
    -- Validate Event Service
    local eventService = MageControl.Services.Registry.get("EventService")
    if eventService then
        local requiredMethods = {"subscribe", "publish", "EVENTS"}
        for i, method in ipairs(requiredMethods) do
            if not eventService[method] then
                results.EventService.missingMethods = results.EventService.missingMethods or {}
                table.insert(results.EventService.missingMethods, method)
                MageControl.Logger.error("EventService missing required method: " .. method, "ServiceInitializer")
            end
        end
    end
end

-- Get service initialization status
ServiceInitializer.getInitializationStatus = function()
    local status = {}
    
    for i, serviceName in ipairs(ServiceInitializer.INITIALIZATION_ORDER) do
        local service = MageControl.Services.Registry.get(serviceName)
        status[serviceName] = {
            registered = service ~= nil,
            initialized = service and service._initialized == true
        }
    end
    
    return status
end

-- Shutdown all services (for cleanup)
ServiceInitializer.shutdownAll = function()
    MageControl.Logger.info("Shutting down service layer", "ServiceInitializer")
    
    -- Shutdown in reverse order
    for i = table.getn(ServiceInitializer.INITIALIZATION_ORDER), 1, -1 do
        local serviceName = ServiceInitializer.INITIALIZATION_ORDER[i]
        local service = MageControl.Services.Registry.get(serviceName)
        
        if service and service.shutdown then
            local success, errorMsg = pcall(service.shutdown)
            if success then
                MageControl.Logger.debug("✓ " .. serviceName .. " shutdown successfully", "ServiceInitializer")
            else
                MageControl.Logger.error("✗ " .. serviceName .. " shutdown failed: " .. tostring(errorMsg), "ServiceInitializer")
            end
        end
    end
end

-- Create service layer facade for easy access
ServiceInitializer.createServiceFacade = function()
    local facade = {}
    
    -- WoW API shortcuts
    facade.api = MageControl.Services.Registry.get("WoWApiService")
    
    -- Data access shortcuts
    facade.data = MageControl.Services.Registry.get("DataRepository")
    
    -- Event system shortcuts
    facade.events = MageControl.Services.Registry.get("EventService")
    
    -- Business logic shortcuts
    facade.rotation = MageControl.Services.Registry.get("RotationService")
    
    -- Convenience methods
    facade.getPlayerManaPercent = function()
        if not facade.api then return 0 end
        local mana = facade.api.getPlayerMana()
        local maxMana = facade.api.getPlayerMaxMana()
        return maxMana > 0 and (mana / maxMana) * 100 or 0
    end
    
    facade.isRotationReady = function()
        if not facade.api then return false end
        return facade.api.isPlayerInCombat() and facade.api.hasTarget() and not facade.api.isGlobalCooldownActive()
    end
    
    facade.executeRotationSafely = function()
        if not facade.rotation or not facade.isRotationReady() then
            return false
        end
        return facade.rotation.executeRotation()
    end
    
    return facade
end

-- Export the service initializer
MageControl.Services.Initializer = ServiceInitializer
