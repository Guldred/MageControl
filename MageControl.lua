-- MageControl Main Entry Point
-- Updated to use the new module system

SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

-- Initialize saved variables
MageControlDB = MageControlDB or {}

-- Legacy global namespace (will be phased out)
MC = MC or {}

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

-- Slash command handler (updated to use new systems)
SlashCmdList["MAGECONTROL"] = function(msg)
    -- Ensure addon is initialized
    if not MageControl.Initialization.isInitialized() then
        MageControl.Logger.error("MageControl is not yet initialized. Please wait a moment and try again.")
        return
    end
    
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    -- Use error handling for command execution
    local success, error = MageControl.ErrorHandler.safeCall(function()
        if command == "explosion" then
            MC.queueArcaneExplosion()
        elseif command == "arcane" then
            MC.arcaneRotation()
        elseif command == "surge" then
            MC.stopChannelAndCastSurge()
        elseif command == "debug" then
            local debugEnabled = MageControl.Logger.toggleDebug()
            MageControl.ConfigManager.set("ui.debugEnabled", debugEnabled)
        elseif command == "options" or command == "config" then
            MC.showOptionsMenu()
        elseif command == "arcaneinc" then
            MC.arcaneIncantagos()
        elseif command == "trinket" then
            MC.activateTrinketAndAP()
        elseif command == "reset" then
            MageControl.ConfigManager.reset()
            if MC.BuffDisplay_ResetPositions then
                MC.BuffDisplay_ResetPositions()
            end
            MageControl.Logger.info("Configuration reset to defaults")
        elseif command == "status" then
            local status = MageControl.Initialization.getStatus()
            MageControl.Logger.info(string.format("Initialization: %d/%d steps completed (%.1f%%)", 
                status.completed, status.total, status.percentage))
            MageControl.Logger.info("Modules loaded: " .. table.getn(MageControl.ModuleSystem.getModuleList()))
        elseif command == "errors" then
            local errors = MageControl.ErrorHandler.getErrorHistory()
            if table.getn(errors) == 0 then
                MageControl.Logger.info("No recent errors")
            else
                MageControl.Logger.info("Recent errors (" .. table.getn(errors) .. "):")
                for i = math.max(1, table.getn(errors) - 5), table.getn(errors) do
                    local err = errors[i]
                    MageControl.Logger.info("  " .. err.type .. ": " .. err.message)
                end
            end
        else
            -- Show help
            MageControl.Logger.info("MageControl Commands:")
            MageControl.Logger.info("  /mc arcane - Cast arcane attack sequence")
            MageControl.Logger.info("  /mc explosion - Queue arcane explosion")
            MageControl.Logger.info("  /mc options - Show options menu")
            MageControl.Logger.info("  /mc reset - Reset to default configuration")
            MageControl.Logger.info("  /mc debug - Toggle debug mode")
            MageControl.Logger.info("  /mc status - Show initialization status")
            MageControl.Logger.info("  /mc errors - Show recent errors")
        end
    end, MageControl.ErrorHandler.TYPES.UNKNOWN, {module = "SlashCommands"})
    
    if not success then
        MageControl.Logger.error("Command execution failed: " .. command)
    end
end
