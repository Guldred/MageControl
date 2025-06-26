SLASH_MAGECONTROL1 = "/magecontrol"
SLASH_MAGECONTROL2 = "/mc"

MageControlDB = MageControlDB or {}
MC = MC or {}

SlashCmdList["MAGECONTROL"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    if command == "explosion" then
        MC.queueArcaneExplosion()
    elseif command == "arcane" then
        MC.arcaneRotation()
    elseif command == "surge" then
        MC.stopChannelAndCastSurge()
    elseif command == "haste" then
        MC.printMessage("Current haste: " .. tostring(MC.getCurrentHasteValue()))
    elseif command == "debug" then
        MC.DEBUG = not MC.DEBUG
        MC.printMessage("MageControl Debug: " .. (MC.DEBUG and "enabled" or "disabled"))
    elseif command == "options" or command == "config" then
        MC.showOptionsMenu()
    elseif command == "set" and args[2] and args[3] then
        MC.setActionBarSlot(args[2], args[3])
    elseif command == "show" then
        MC.showCurrentConfig()
    elseif command == "arcaneinc" then
        MC.arcaneIncantagos()
    elseif command == "trinket" then
        MC.activateTrinketAndAP()
    elseif command == "toggle" then
        MC.BuffDisplay_ToggleLock()
    elseif command == "lock" then
        MC.lockFrames()
    elseif command == "unlock" then
        MC.unlockFrames()
    elseif command == "reset" then
        MageControlDB.actionBarSlots = {
            FIREBLAST = MC.DEFAULT_ACTIONBAR_SLOT.FIREBLAST,
            ARCANE_RUPTURE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_RUPTURE,
            ARCANE_SURGE = MC.DEFAULT_ACTIONBAR_SLOT.ARCANE_SURGE,
        }
        MageControlDB.haste = {
            BASE_VALUE = MC.HASTE.BASE_VALUE,
            HASTE_THRESHOLD = MC.HASTE.HASTE_THRESHOLD
        }
        MC.BuffDisplay_ResetPositions()
        MC.printMessage("MageControl: Configuration reset to defaults")
    else
        MC.printMessage("MageControl Commands:")
        MC.printMessage("  /mc arcane - Cast arcane attack sequence")
        MC.printMessage("  /mc explosion - Queue arcane explosion")
        MC.printMessage("  /mc options - Show options menu")
        MC.printMessage("  /mc set <spell> <slot> - Set actionbar slot")
        MC.printMessage("  /mc show - Show current configuration")
        MC.printMessage("  /mc reset - Reset to default slots")
        MC.printMessage("  /mc debug - Toggle debug mode")
    end
end

