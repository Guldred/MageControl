-- MageControl Setup Panel
-- Handles the setup tab in the options interface

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the SetupPanel module
local SetupPanel = MageControl.createModule("SetupPanel", {"ConfigManager", "Logger", "SpellSlotDetector"})

-- Panel state
SetupPanel.panel = nil
SetupPanel.autoDetectHelp = nil

-- Initialize the setup panel
SetupPanel.initialize = function()
    MageControl.Logger.debug("Setup Panel initialized", "SetupPanel")
end

-- Create the setup panel UI
SetupPanel.create = function(parent)
    if SetupPanel.panel then return end
    
    SetupPanel.panel = CreateFrame("Frame", nil, parent)
    SetupPanel.panel:SetWidth(360)
    SetupPanel.panel:SetHeight(100)
    SetupPanel.panel:SetPoint("TOP", parent, "TOP", 0, -10)

    -- Title
    local setupTitle = SetupPanel.panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    setupTitle:SetPoint("TOPLEFT", SetupPanel.panel, "TOPLEFT", 15, -5)
    setupTitle:SetText("Setup")
    setupTitle:SetTextColor(0.9, 0.9, 0.3, 1)

    -- Calculate button positioning
    local buttonsWidth = 120 + 20 + 90 + 20 + 90
    local startX = (360 - buttonsWidth) / 2

    -- Auto-detect button
    SetupPanel._createAutoDetectButton(startX)
    
    -- Lock/Unlock buttons
    SetupPanel._createLockButtons(startX)
end

-- Create auto-detect spell slots button
SetupPanel._createAutoDetectButton = function(startX)
    local autoDetectButton = CreateFrame("Button", nil, SetupPanel.panel)
    autoDetectButton:SetWidth(120)
    autoDetectButton:SetHeight(28)
    autoDetectButton:SetPoint("TOPLEFT", SetupPanel.panel, "TOPLEFT", startX, -30)
    autoDetectButton:SetText("Detect Spell Slots")
    autoDetectButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    autoDetectButton:SetBackdropColor(0.2, 0.6, 0.9, 0.8)
    autoDetectButton:SetBackdropBorderColor(0.4, 0.8, 1, 0.8)

    local autoDetectText = autoDetectButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoDetectText:SetPoint("CENTER", 0, 0)
    autoDetectText:SetText("Detect Spell Slots")
    autoDetectText:SetTextColor(1, 1, 1, 1)

    -- Button hover effects
    autoDetectButton:SetScript("OnEnter", function()
        autoDetectButton:SetBackdropColor(0.3, 0.7, 1, 0.9)
    end)

    autoDetectButton:SetScript("OnLeave", function()
        autoDetectButton:SetBackdropColor(0.2, 0.6, 0.9, 0.8)
    end)

    -- Help text
    SetupPanel.autoDetectHelp = SetupPanel.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    SetupPanel.autoDetectHelp:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -4)
    SetupPanel.autoDetectHelp:SetWidth(120)
    SetupPanel.autoDetectHelp:SetText("Find spells in action bars")
    SetupPanel.autoDetectHelp:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Button click handler
    autoDetectButton:SetScript("OnClick", function()
        local detector = MageControl.ModuleSystem.getModule("SpellSlotDetector")
        local optionsMessage = detector.autoDetectSlots()
        SetupPanel.autoDetectHelp:SetText(optionsMessage)
        SetupPanel.loadValues()
        MageControl.Logger.info("Spell slot auto-detection completed", "SetupPanel")
    end)
end

-- Create lock/unlock frame buttons
SetupPanel._createLockButtons = function(startX)
    -- Lock button
    local lockButton = CreateFrame("Button", nil, SetupPanel.panel)
    lockButton:SetWidth(90)
    lockButton:SetHeight(28)
    lockButton:SetPoint("TOPLEFT", SetupPanel.panel, "TOPLEFT", startX + 120 + 20, -30)
    lockButton:SetText("Lock Frames")
    lockButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    lockButton:SetBackdropColor(0.8, 0.3, 0.3, 0.8)
    lockButton:SetBackdropBorderColor(1, 0.4, 0.4, 0.8)

    local lockText = lockButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockText:SetPoint("CENTER", 0, 0)
    lockText:SetText("Lock Frames")
    lockText:SetTextColor(1, 1, 1, 1)

    lockButton:SetScript("OnEnter", function()
        lockButton:SetBackdropColor(0.9, 0.4, 0.4, 0.9)
    end)

    lockButton:SetScript("OnLeave", function()
        lockButton:SetBackdropColor(0.8, 0.3, 0.3, 0.8)
    end)

    lockButton:SetScript("OnClick", function()
        SetupPanel._lockFrames()
    end)

    -- Unlock button
    local unlockButton = CreateFrame("Button", nil, SetupPanel.panel)
    unlockButton:SetWidth(90)
    unlockButton:SetHeight(28)
    unlockButton:SetPoint("LEFT", lockButton, "RIGHT", 20, 0)
    unlockButton:SetText("Unlock Frames")
    unlockButton:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    unlockButton:SetBackdropColor(0.3, 0.8, 0.4, 0.8)
    unlockButton:SetBackdropBorderColor(0.4, 1, 0.5, 0.8)

    local unlockText = unlockButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unlockText:SetPoint("CENTER", 0, 0)
    unlockText:SetText("Unlock Frames")
    unlockText:SetTextColor(1, 1, 1, 1)

    unlockButton:SetScript("OnEnter", function()
        unlockButton:SetBackdropColor(0.4, 0.9, 0.5, 0.9)
    end)

    unlockButton:SetScript("OnLeave", function()
        unlockButton:SetBackdropColor(0.3, 0.8, 0.4, 0.8)
    end)

    unlockButton:SetScript("OnClick", function()
        SetupPanel._unlockFrames()
    end)
end

-- Lock UI frames
SetupPanel._lockFrames = function()
    -- Use existing frame locking functions
    if MC.lockFrames then
        MC.lockFrames()
    end
    if MC.lockActionFrames then
        MC.lockActionFrames()
    end
    MageControl.Logger.info("UI frames locked", "SetupPanel")
end

-- Unlock UI frames
SetupPanel._unlockFrames = function()
    -- Use existing frame unlocking functions
    if MC.unlockFrames then
        MC.unlockFrames()
    end
    if MC.unlockActionFrames then
        MC.unlockActionFrames()
    end
    MageControl.Logger.info("UI frames unlocked", "SetupPanel")
end

-- Load current values
SetupPanel.loadValues = function()
    -- Update auto-detect help text with current status
    if SetupPanel.autoDetectHelp then
        local detector = MageControl.ModuleSystem.getModule("SpellSlotDetector")
        local status = detector.getStatus()
        
        if status.totalFound == status.totalRequired then
            SetupPanel.autoDetectHelp:SetText("All " .. status.totalRequired .. " spells configured")
            SetupPanel.autoDetectHelp:SetTextColor(0.2, 0.8, 0.2, 1) -- Green
        else
            SetupPanel.autoDetectHelp:SetText(status.totalFound .. "/" .. status.totalRequired .. " spells found")
            SetupPanel.autoDetectHelp:SetTextColor(0.8, 0.8, 0.2, 1) -- Yellow
        end
    end
end

-- Reset panel to defaults
SetupPanel.reset = function()
    MageControl.ConfigManager.resetSection("actionBarSlots")
    SetupPanel.loadValues()
    MageControl.Logger.info("Setup panel reset to defaults", "SetupPanel")
end

-- Register the module
MageControl.ModuleSystem.registerModule("SetupPanel", SetupPanel)

-- Export for other modules
MageControl.UI.Options.SetupPanel = SetupPanel
