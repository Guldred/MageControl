-- MageControl Event Service
-- Event-driven architecture for loose coupling between modules

MageControl = MageControl or {}
MageControl.Services = MageControl.Services or {}

-- Event Service Interface
local IEventService = {
    -- Event subscription
    subscribe = function(eventName, handler, priority) end,
    unsubscribe = function(eventName, handler) end,
    unsubscribeAll = function(eventName) end,
    
    -- Event publishing
    publish = function(eventName, eventData) end,
    publishAsync = function(eventName, eventData) end,
    
    -- Event management
    hasSubscribers = function(eventName) end,
    getSubscriberCount = function(eventName) end,
    listEvents = function() end,
    
    -- Event filtering and middleware
    addMiddleware = function(eventName, middleware) end,
    removeMiddleware = function(eventName, middleware) end
}

-- Event Service Implementation
local EventService = {}

-- Event storage
EventService._subscribers = {}
EventService._middleware = {}
EventService._asyncQueue = {}

-- Event subscription
EventService.subscribe = function(eventName, handler, priority)
    if not eventName or not handler then
        MageControl.Logger.error("Event name and handler are required", "EventService")
        return false
    end
    
    if not EventService._subscribers[eventName] then
        EventService._subscribers[eventName] = {}
    end
    
    local subscription = {
        handler = handler,
        priority = priority or 0,
        id = tostring(handler) .. "_" .. tostring(GetTime())
    }
    
    table.insert(EventService._subscribers[eventName], subscription)
    
    -- Sort by priority (higher priority first)
    table.sort(EventService._subscribers[eventName], function(a, b)
        return a.priority > b.priority
    end)
    
    MageControl.Logger.debug("Subscribed to event: " .. eventName .. " (priority: " .. subscription.priority .. ")", "EventService")
    return subscription.id
end

EventService.unsubscribe = function(eventName, handler)
    if not eventName or not handler then
        return false
    end
    
    local subscribers = EventService._subscribers[eventName]
    if not subscribers then
        return false
    end
    
    for i = table.getn(subscribers), 1, -1 do
        if subscribers[i].handler == handler then
            table.remove(subscribers, i)
            MageControl.Logger.debug("Unsubscribed from event: " .. eventName, "EventService")
            return true
        end
    end
    
    return false
end

EventService.unsubscribeAll = function(eventName)
    if not eventName then
        return false
    end
    
    EventService._subscribers[eventName] = {}
    MageControl.Logger.debug("Unsubscribed all handlers from event: " .. eventName, "EventService")
    return true
end

-- Event publishing
EventService.publish = function(eventName, eventData)
    if not eventName then
        MageControl.Logger.error("Event name is required", "EventService")
        return false
    end
    
    -- Apply middleware first
    local processedData = EventService._applyMiddleware(eventName, eventData)
    if processedData == nil then
        -- Middleware cancelled the event
        MageControl.Logger.debug("Event cancelled by middleware: " .. eventName, "EventService")
        return false
    end
    
    local subscribers = EventService._subscribers[eventName]
    if not subscribers or table.getn(subscribers) == 0 then
        MageControl.Logger.debug("No subscribers for event: " .. eventName, "EventService")
        return true
    end
    
    MageControl.Logger.debug("Publishing event: " .. eventName .. " to " .. table.getn(subscribers) .. " subscribers", "EventService")
    
    local successCount = 0
    for i, subscription in ipairs(subscribers) do
        local success, result = pcall(subscription.handler, processedData)
        if success then
            successCount = successCount + 1
            -- If handler returns false, stop propagation
            if result == false then
                MageControl.Logger.debug("Event propagation stopped by handler", "EventService")
                break
            end
        else
            MageControl.Logger.error("Event handler error for " .. eventName .. ": " .. tostring(result), "EventService")
        end
    end
    
    return successCount > 0
end

EventService.publishAsync = function(eventName, eventData)
    if not eventName then
        return false
    end
    
    -- Queue the event for async processing
    table.insert(EventService._asyncQueue, {
        eventName = eventName,
        eventData = eventData,
        timestamp = GetTime()
    })
    
    MageControl.Logger.debug("Queued async event: " .. eventName, "EventService")
    return true
end

-- Process async event queue
EventService._processAsyncQueue = function()
    if table.getn(EventService._asyncQueue) == 0 then
        return
    end
    
    local eventsToProcess = {}
    for i, event in ipairs(EventService._asyncQueue) do
        table.insert(eventsToProcess, event)
    end
    
    -- Clear the queue
    EventService._asyncQueue = {}
    
    -- Process events
    for i, event in ipairs(eventsToProcess) do
        EventService.publish(event.eventName, event.eventData)
    end
end

-- Event management
EventService.hasSubscribers = function(eventName)
    if not eventName then
        return false
    end
    
    local subscribers = EventService._subscribers[eventName]
    return subscribers and table.getn(subscribers) > 0
end

EventService.getSubscriberCount = function(eventName)
    if not eventName then
        return 0
    end
    
    local subscribers = EventService._subscribers[eventName]
    return subscribers and table.getn(subscribers) or 0
end

EventService.listEvents = function()
    local events = {}
    for eventName, subscribers in pairs(EventService._subscribers) do
        if table.getn(subscribers) > 0 then
            table.insert(events, {
                name = eventName,
                subscriberCount = table.getn(subscribers)
            })
        end
    end
    return events
end

-- Middleware support
EventService.addMiddleware = function(eventName, middleware)
    if not eventName or not middleware then
        return false
    end
    
    if not EventService._middleware[eventName] then
        EventService._middleware[eventName] = {}
    end
    
    table.insert(EventService._middleware[eventName], middleware)
    MageControl.Logger.debug("Added middleware for event: " .. eventName, "EventService")
    return true
end

EventService.removeMiddleware = function(eventName, middleware)
    if not eventName or not middleware then
        return false
    end
    
    local middlewares = EventService._middleware[eventName]
    if not middlewares then
        return false
    end
    
    for i = table.getn(middlewares), 1, -1 do
        if middlewares[i] == middleware then
            table.remove(middlewares, i)
            MageControl.Logger.debug("Removed middleware from event: " .. eventName, "EventService")
            return true
        end
    end
    
    return false
end

EventService._applyMiddleware = function(eventName, eventData)
    local middlewares = EventService._middleware[eventName]
    if not middlewares or table.getn(middlewares) == 0 then
        return eventData
    end
    
    local processedData = eventData
    for i, middleware in ipairs(middlewares) do
        local success, result = pcall(middleware, processedData)
        if not success then
            MageControl.Logger.error("Middleware error for " .. eventName .. ": " .. tostring(result), "EventService")
            return nil -- Cancel event
        end
        
        if result == nil then
            -- Middleware cancelled the event
            return nil
        end
        
        processedData = result
    end
    
    return processedData
end

-- Common MageControl events
EventService.EVENTS = {
    -- Player state events
    PLAYER_MANA_CHANGED = "player.mana.changed",
    PLAYER_HEALTH_CHANGED = "player.health.changed",
    PLAYER_COMBAT_ENTERED = "player.combat.entered",
    PLAYER_COMBAT_LEFT = "player.combat.left",
    PLAYER_CASTING_STARTED = "player.casting.started",
    PLAYER_CASTING_FINISHED = "player.casting.finished",
    PLAYER_CHANNELING_STARTED = "player.channeling.started",
    PLAYER_CHANNELING_FINISHED = "player.channeling.finished",
    
    -- Spell events
    SPELL_CAST_SUCCESS = "spell.cast.success",
    SPELL_CAST_FAILED = "spell.cast.failed",
    SPELL_COOLDOWN_READY = "spell.cooldown.ready",
    
    -- Rotation events
    ROTATION_EXECUTED = "rotation.executed",
    ROTATION_ACTION_TAKEN = "rotation.action.taken",
    ROTATION_PRIORITY_CHANGED = "rotation.priority.changed",
    
    -- Configuration events
    CONFIG_CHANGED = "config.changed",
    CONFIG_RESET = "config.reset",
    CONFIG_LOADED = "config.loaded",
    
    -- UI events
    UI_OPTIONS_OPENED = "ui.options.opened",
    UI_OPTIONS_CLOSED = "ui.options.closed",
    UI_PRIORITY_CHANGED = "ui.priority.changed",
    
    -- System events
    ADDON_LOADED = "addon.loaded",
    ADDON_INITIALIZED = "addon.initialized",
    MODULE_REGISTERED = "module.registered",
    SERVICE_REGISTERED = "service.registered"
}

-- Initialize the service
EventService.initialize = function()
    -- Set up async queue processing
    if MageControl.Core and MageControl.Core.UpdateManager then
        MageControl.Core.UpdateManager.registerUpdateFunction(EventService._processAsyncQueue, 0.1, "EventService_AsyncQueue")
    end
    
    MageControl.Logger.debug("Event Service initialized", "EventService")
end

-- Service registration removed - ServiceInitializer now uses direct access

-- Export for direct access
MageControl.Services.Events = EventService
