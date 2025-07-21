-- MageControl Options Manager
-- Main controller for the options interface

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the Options Manager module
local OptionsManager = MageControl.createModule("OptionsManager", {"ConfigManager", "Logger"})

-- Module state
OptionsManager.frame = nil
OptionsManager.isVisible = false

-- Initialize the options manager
OptionsManager.initialize = function()
    MageControl.Logger.debug("Options Manager initialized", "OptionsManager")
end

-- Show/hide the options menu
OptionsManager.show = function()
    if OptionsManager.frame and OptionsManager.frame:IsVisible() then
        OptionsManager.hide()
    else
        OptionsManager._showOptionsFrame()
    end
end

OptionsManager.hide = function()
    if OptionsManager.frame then
        OptionsManager.frame:Hide()
        OptionsManager.isVisible = false
    end
end

OptionsManager.toggle = function()
    if OptionsManager.isVisible then
        OptionsManager.hide()
    else
        OptionsManager.show()
    end
end

-- Create the main options frame
OptionsManager._showOptionsFrame = function()
    if not OptionsManager.frame then
        OptionsManager._createFrame()
    end
    
    -- Load current values
    OptionsManager._loadValues()
    
    OptionsManager.frame:Show()
    OptionsManager.isVisible = true
end

-- Create the main options frame
OptionsManager._createFrame = function()
    if OptionsManager.frame then return end

    OptionsManager.frame = CreateFrame("Frame", "MageControlOptionsFrame", UIParent)
    OptionsManager.frame:SetWidth(400)
    OptionsManager.frame:SetHeight(440)
    OptionsManager.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    OptionsManager.frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    OptionsManager.frame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    OptionsManager.frame:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)
    OptionsManager.frame:SetMovable(true)
    OptionsManager.frame:EnableMouse(true)
    OptionsManager.frame:RegisterForDrag("LeftButton")
    OptionsManager.frame:SetScript("OnDragStart", function() this:StartMoving() end)
    OptionsManager.frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, "MageControlOptionsFrame")

    -- Title
    local title = OptionsManager.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", OptionsManager.frame, "TOP", 0, -20)
    title:SetText("🔮 MageControl Options")
    title:SetTextColor(0.8, 0.9, 1, 1)

    -- Close button
    local closeButton = CreateFrame("Button", nil, OptionsManager.frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", OptionsManager.frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() OptionsManager.hide() end)

    -- Dependency info
    local dependencyInfo = OptionsManager.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dependencyInfo:SetPoint("TOP", title, "BOTTOM", 0, -10)
    dependencyInfo:SetText("📋 " .. OptionsManager._checkDependencies())
    dependencyInfo:SetTextColor(0.7, 0.8, 0.9, 1)

    -- Create tab container
    local tabContainer = CreateFrame("Frame", nil, OptionsManager.frame)
    tabContainer:SetPoint("TOPLEFT", OptionsManager.frame, "TOPLEFT", 10, -120)
    tabContainer:SetPoint("BOTTOMRIGHT", OptionsManager.frame, "BOTTOMRIGHT", -10, 10)
    tabContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    tabContainer:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
    tabContainer:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.7)

    -- Create tab system
    OptionsManager._createTabSystem(tabContainer)
    
    OptionsManager.frame:Hide()
end

-- Create the tab system and panels
OptionsManager._createTabSystem = function(tabContainer)
    -- Use the existing tab system from Button.lua
    local tabSystem = MC.setupTabSystem(OptionsManager.frame, tabContainer, {
        { title = "Setup" },
        { title = "Priorities" },
        { title = "Settings" }
    })

    local tabs = tabSystem.tabs
    local tabButtons = tabSystem.buttons

    -- Remove backdrop from tabs
    for i = 1, table.getn(tabs) do
        tabs[i]:SetBackdrop(nil)
    end

    -- Create panels for each tab
    OptionsManager._createSetupPanel(tabs[1])
    OptionsManager._createPriorityPanel(tabs[2])
    OptionsManager._createSettingsPanel(tabs[3])
end

-- Create setup panel
OptionsManager._createSetupPanel = function(parent)
    -- Delegate to SetupPanel module
    if MageControl.UI.Options.SetupPanel then
        MageControl.UI.Options.SetupPanel.create(parent)
    end
end

-- Create priority panel
OptionsManager._createPriorityPanel = function(parent)
    -- Delegate to PriorityPanel module
    if MageControl.UI.Options.PriorityPanel then
        MageControl.UI.Options.PriorityPanel.create(parent)
    end
end

-- Create settings panel
OptionsManager._createSettingsPanel = function(parent)
    -- Delegate to SettingsPanel module
    if MageControl.UI.Options.SettingsPanel then
        MageControl.UI.Options.SettingsPanel.create(parent)
    end
end

-- Check dependencies (SuperWoW, Nampower)
OptionsManager._checkDependencies = function()
    local output = "SuperWoW: "

    if SUPERWOW_VERSION then
        output = output .. " Version " .. tostring(SUPERWOW_VERSION)
    else
        output = output .. "Not found!"
    end

    output = output .. ".\\nNampower: "

    if GetNampowerVersion and GetNampowerVersion() then
        local major, minor, patch = GetNampowerVersion()

        if major and minor and patch then
            output = output .. "Version " .. tostring(major) .. "." .. tostring(minor) .. "." .. tostring(patch)
        else
            output = output .. "Version unknown (still ok)"
        end
    else
        output = output .. "Not found!"
    end

    return output
end

-- Load current configuration values
OptionsManager._loadValues = function()
    -- Delegate to individual panels to load their values
    if MageControl.UI.Options.SetupPanel and MageControl.UI.Options.SetupPanel.loadValues then
        MageControl.UI.Options.SetupPanel.loadValues()
    end
    if MageControl.UI.Options.PriorityPanel and MageControl.UI.Options.PriorityPanel.loadValues then
        MageControl.UI.Options.PriorityPanel.loadValues()
    end
    if MageControl.UI.Options.SettingsPanel and MageControl.UI.Options.SettingsPanel.loadValues then
        MageControl.UI.Options.SettingsPanel.loadValues()
    end
end

-- Register the module
MageControl.ModuleSystem.registerModule("OptionsManager", OptionsManager)

-- Backward compatibility
MC.showOptionsMenu = function()
    OptionsManager.show()
end

MC.optionsShow = function()
    OptionsManager.show()
end

-- Export for other modules
MageControl.UI.Options.Manager = OptionsManager
