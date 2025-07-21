-- MageControl Priority Panel
-- Handles the priority tab in the options interface

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the PriorityPanel module
local PriorityPanel = MageControl.createModule("PriorityPanel", {"ConfigManager", "Logger"})

-- Panel state
PriorityPanel.panel = nil
PriorityPanel.priorityFrame = nil
PriorityPanel.displayItems = {}

-- Initialize the priority panel
PriorityPanel.initialize = function()
    MageControl.Logger.debug("Priority Panel initialized", "PriorityPanel")
end

-- Create the priority panel UI
PriorityPanel.create = function(parent)
    if PriorityPanel.panel then return end
    
    PriorityPanel.panel = CreateFrame("Frame", nil, parent)
    PriorityPanel.panel:SetWidth(360)
    PriorityPanel.panel:SetHeight(200)
    PriorityPanel.panel:SetPoint("TOP", parent, "TOP", 0, -10)

    -- Title
    local priorityTitle = PriorityPanel.panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    priorityTitle:SetPoint("TOPLEFT", PriorityPanel.panel, "TOPLEFT", 15, -5)
    priorityTitle:SetText("Trinket Priority")
    priorityTitle:SetTextColor(0.9, 0.8, 0.5, 1)

    -- Create priority list frame
    PriorityPanel._createPriorityFrame()
    
    -- Help text
    local priorityHelpFrame = PriorityPanel.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    priorityHelpFrame:SetPoint("TOP", PriorityPanel.priorityFrame, "BOTTOM", 0, -5)
    priorityHelpFrame:SetWidth(340)
    priorityHelpFrame:SetJustifyH("CENTER")
    priorityHelpFrame:SetText("Higher priority items are used first with /mc trinket")
    priorityHelpFrame:SetTextColor(0.7, 0.8, 0.9, 1)
end

-- Create the priority list frame
PriorityPanel._createPriorityFrame = function()
    -- Use existing priority frame creation if available
    if MC.createPriorityFrame then
        PriorityPanel.priorityFrame = MC.createPriorityFrame(PriorityPanel.panel)
        PriorityPanel.priorityFrame:ClearAllPoints()
        PriorityPanel.priorityFrame:SetPoint("TOP", PriorityPanel.panel, "TOP", 0, -30)
    else
        -- Create a simple priority frame if the existing one isn't available
        PriorityPanel.priorityFrame = CreateFrame("Frame", nil, PriorityPanel.panel)
        PriorityPanel.priorityFrame:SetWidth(300)
        PriorityPanel.priorityFrame:SetHeight(120)
        PriorityPanel.priorityFrame:SetPoint("TOP", PriorityPanel.panel, "TOP", 0, -30)
        PriorityPanel.priorityFrame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        PriorityPanel.priorityFrame:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
        PriorityPanel.priorityFrame:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.7)
        
        -- Add placeholder text
        local placeholderText = PriorityPanel.priorityFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        placeholderText:SetPoint("CENTER", PriorityPanel.priorityFrame, "CENTER", 0, 0)
        placeholderText:SetText("Priority List\n(Requires PriorityList component)")
        placeholderText:SetTextColor(0.7, 0.7, 0.7, 1)
    end
end

-- Load current values
PriorityPanel.loadValues = function()
    -- Initialize priority display items
    PriorityPanel.displayItems = {
        "TRINKET1",
        "TRINKET2", 
        "ARCANE_POWER"
    }
    
    -- Update priority display if available
    if MC.updatePriorityDisplay then
        MC.priorityUiDisplayItems = PriorityPanel.displayItems
        MC.updatePriorityDisplay()
    end
    
    -- Ensure cooldown priority map exists in config
    local currentPriority = MageControl.ConfigManager.get("rotation.cooldownPriorityMap")
    if not currentPriority then
        MageControl.ConfigManager.set("rotation.cooldownPriorityMap", {"TRINKET1", "TRINKET2", "ARCANE_POWER"})
    end
end

-- Save priority configuration
PriorityPanel.save = function()
    if PriorityPanel.displayItems and table.getn(PriorityPanel.displayItems) > 0 then
        MageControl.ConfigManager.set("rotation.cooldownPriorityMap", PriorityPanel.displayItems)
        MageControl.Logger.info("Priority configuration saved", "PriorityPanel")
        
        -- Debug output
        MageControl.Logger.debug("Priority Order saved:", "PriorityPanel")
        for i, priority in ipairs(PriorityPanel.displayItems) do
            MageControl.Logger.debug("  " .. i .. ". " .. priority, "PriorityPanel")
        end
    end
end

-- Reset panel to defaults
PriorityPanel.reset = function()
    local defaultPriority = {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
    MageControl.ConfigManager.set("rotation.cooldownPriorityMap", defaultPriority)
    PriorityPanel.displayItems = defaultPriority
    PriorityPanel.loadValues()
    MageControl.Logger.info("Priority panel reset to defaults", "PriorityPanel")
end

-- Get current priority order
PriorityPanel.getPriorityOrder = function()
    return PriorityPanel.displayItems or MageControl.ConfigManager.get("rotation.cooldownPriorityMap") or {"TRINKET1", "TRINKET2", "ARCANE_POWER"}
end

-- Set priority order
PriorityPanel.setPriorityOrder = function(newOrder)
    if type(newOrder) == "table" then
        PriorityPanel.displayItems = newOrder
        MageControl.ConfigManager.set("rotation.cooldownPriorityMap", newOrder)
        MageControl.Logger.debug("Priority order updated", "PriorityPanel")
    else
        MageControl.Logger.error("Invalid priority order - must be a table", "PriorityPanel")
    end
end

-- Register the module
MageControl.ModuleSystem.registerModule("PriorityPanel", PriorityPanel)

-- Backward compatibility
MC.priorityUiDisplayItems = PriorityPanel.displayItems

-- Export for other modules
MageControl.UI.Options.PriorityPanel = PriorityPanel
