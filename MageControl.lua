-- MageControl Main Entry Point  
-- Converted to unified MageControl.* system - MC global namespace eliminated

SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

-- Initialize saved variables
MageControlDB = MageControlDB or {}
MageControl = MageControl or {}

-- MC global namespace eliminated - using unified MageControl.* expert modules only

-- Event frame for initialization
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local addonLoaded = false
local playerEntered = false

-- Initialize when both events have fired
local function tryInitialize()
    if addonLoaded and playerEntered and not MageControl.Initialization.isInitialized() then
        MageControl.Initialization.initialize()
    end
end

initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "MageControl" then
        addonLoaded = true
        tryInitialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerEntered = true
        tryInitialize()
    end
end)

-- Optimized command lookup table for better performance
local COMMAND_HANDLERS = {
    explosion = function() MageControl.SpellCasting.queueArcaneExplosion() end,
    arcane = function() MageControl.RotationEngine.arcaneRotation() end,
    surge = function() MageControl.SpellCasting.stopChannelAndCastSurge() end,
    debug = function()
        local debugEnabled = MageControl.Logger.toggleDebug()
        MageControl.ConfigManager.set("ui.debugEnabled", debugEnabled)
    end,
    options = function() MageControl.UI.OptionsManager.showOptionsMenu() end,
    config = function() MageControl.UI.OptionsManager.showOptionsMenu() end,
    
    -- New properly named cooldown command
    cooldown = function() 
        local cooldownSystem = MageControl.ModuleSystem.getModule("CooldownSystem")
        if cooldownSystem then
            cooldownSystem.activatePriorityAction()
        else
            MageControl.Logger.error("CooldownSystem module not found")
        end
    end,
    cooldowns = function() 
        local cooldownSystem = MageControl.ModuleSystem.getModule("CooldownSystem")
        if cooldownSystem then
            cooldownSystem.activatePriorityAction()
        else
            MageControl.Logger.error("CooldownSystem module not found")
        end
    end,
    cd = function() 
        local cooldownSystem = MageControl.ModuleSystem.getModule("CooldownSystem")
        if cooldownSystem then
            cooldownSystem.activatePriorityAction()
        else
            MageControl.Logger.error("CooldownSystem module not found")
        end
    end,
    
    -- Deprecated trinket command with warning
    trinket = function() 
        MageControl.Logger.warn("'/mc trinket' is deprecated. Use '/mc cooldown' or '/mc cd' instead.")
        MageControl.Logger.info("The new command activates trinkets AND Arcane Power based on your priority settings.")
        local cooldownSystem = MageControl.ModuleSystem.getModule("CooldownSystem") 
        if cooldownSystem then
            cooldownSystem.activatePriorityAction()
        else
            MageControl.Logger.error("CooldownSystem module not found")
        end
    end,
    reset = function()
        MageControl.ConfigManager.reset()
        MageControl.UI.BuffDisplay.resetPositions()
        MageControl.UI.ActionDisplay.resetPositions()
        MageControl.Logger.info("Configuration reset to defaults")
    end,
    status = function()
        local status = MageControl.Initialization.getStatus()
        MageControl.Logger.info(string.format("Initialization: %d/%d steps completed (%.1f%%)", 
            status.completed, status.total, status.percentage))
        MageControl.Logger.info("Modules loaded: " .. table.getn(MageControl.ModuleSystem.getModuleList()))
    end,
    errors = function()
        local errors = MageControl.ErrorHandler.getErrorHistory()
        local errorCount = table.getn(errors)
        if errorCount == 0 then
            MageControl.Logger.info("No recent errors")
        else
            MageControl.Logger.info("Recent errors (" .. errorCount .. "):")
            local startIndex = math.max(1, errorCount - 5)
            for i = startIndex, errorCount do
                local err = errors[i]
                MageControl.Logger.info("  " .. err.type .. ": " .. err.message)
            end
        end
    end
}

-- Pre-compiled pattern for better performance
local WORD_PATTERN = "%S+"

-- Optimized slash command handler
SlashCmdList["MAGECONTROL"] = function(msg)
    -- Early exit for uninitialized addon
    if not MageControl.Initialization.isInitialized() then
        MageControl.Logger.error("MageControl is not yet initialized. Please wait a moment and try again.")
        return
    end
    
    -- Optimized argument parsing - only parse first word for command lookup using Lua 5.0 compatible function
    local command = ""
    local iterator = string.gfind(msg, WORD_PATTERN)
    if iterator then
        command = iterator() or ""
        command = string.lower(command)
    end

    -- Use error handling for command execution
    local success, error = MageControl.ErrorHandler.safeCall(function()
        local handler = COMMAND_HANDLERS[command]
        if handler then
            handler()
        else
            -- Show help - cached help text for better performance
            if not MageControl._helpText then
                MageControl._helpText = {
                    "MageControl Commands:",
                    "  /mc arcane - Cast arcane attack sequence (intelligent boss detection)",
                    "  /mc explosion - Queue arcane explosion",
                    "  /mc options - Show options menu",
                    "  /mc reset - Reset to default configuration",
                    "  /mc debug - Toggle debug mode",
                    "  /mc status - Show initialization status",
                    "  /mc errors - Show recent errors",
                    "  /mc cooldown - Activate trinkets and Arcane Power",
                    "  /mc cd - Activate trinkets and Arcane Power"
                }
            end
            for i, line in ipairs(MageControl._helpText) do
                MageControl.Logger.info(line)
            end
        end
    end, MageControl.ErrorHandler.TYPES.SLASH_COMMAND)

    if not success then
        MageControl.Logger.error("Command execution failed: " .. tostring(error))
    end
end

-- Utility function to get inventory item cooldown in seconds (WoW 1.12.1 compatible)
MageControl.CacheUtils.getInventoryItemCooldownInSeconds = function(slot)
    if not slot then
        return 0
    end
    
    local start, cooldown, enabled = GetInventoryItemCooldown("player", slot)
    
    -- If item is not enabled or no cooldown, return 0
    if not enabled or enabled ~= 1 or not cooldown or cooldown == 0 then
        return 0
    end
    
    -- Calculate remaining cooldown time
    local currentTime = GetTime()
    local remainingTime = (start + cooldown) - currentTime
    
    -- Return remaining time or 0 if cooldown has expired
    return math.max(0, remainingTime)
end
