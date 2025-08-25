-- MageControl Tab Manager
-- Manages tabbed interface system for options and other UI components

-- Initialize MC namespace
MC = MC or {}
MC.UI = MC.UI or {}
MC.UI.Framework = MC.UI.Framework or {}

-- Create the TabManager module
local TabManager = MageControl.createModule("TabManager", {"UIFramework", "Logger"})

-- Initialize the tab manager
TabManager.initialize = function()
    MageControl.Logger.debug("Tab Manager initialized", "TabManager")
end

-- TabManager class
local TabManagerClass = {}
TabManagerClass.__index = TabManagerClass

-- Create a new tab manager instance
TabManager.create = function(parent, config)
    local self = setmetatable({}, TabManagerClass)
    
    -- Configuration
    self.parent = parent
    self.config = config or {}
    self.tabWidth = self.config.tabWidth or MageControl.UI.Framework.UIFramework.STYLES.DIMENSIONS.TAB_WIDTH
    self.tabHeight = self.config.tabHeight or MageControl.UI.Framework.UIFramework.STYLES.DIMENSIONS.TAB_HEIGHT
    self.contentHeight = self.config.contentHeight or 350
    self.startY = self.config.startY or -40
    
    -- State
    self.tabs = {}
    self.panels = {}
    self.activeTab = nil
    self.tabContainer = nil
    self.contentContainer = nil
    
    self:_initialize()
    return self
end

-- Initialize the tab manager
function TabManagerClass:_initialize()
    -- Create tab container
    self.tabContainer = CreateFrame("Frame", nil, self.parent)
    self.tabContainer:SetWidth(self.parent:GetWidth())
    self.tabContainer:SetHeight(self.tabHeight + 10)
    self.tabContainer:SetPoint("TOP", self.parent, "TOP", 0, self.startY)
    
    -- Create content container
    self.contentContainer = CreateFrame("Frame", nil, self.parent)
    self.contentContainer:SetWidth(self.parent:GetWidth() - 20)
    self.contentContainer:SetHeight(self.contentHeight)
    self.contentContainer:SetPoint("TOP", self.tabContainer, "BOTTOM", 0, -5)
    
    MageControl.Logger.debug("Tab manager containers created", "TabManager")
end

-- Add a new tab
function TabManagerClass:addTab(id, title, createPanelFunc, config)
    if self.tabs[id] then
        MageControl.Logger.warn("Tab with ID '" .. id .. "' already exists", "TabManager")
        return false
    end
    
    local tabConfig = config or {}
    
    -- Create tab button
    local tab = MageControl.UI.Framework.UIFramework.createTab(
        self.tabContainer, 
        title, 
        tabConfig.width or self.tabWidth,
        self.tabHeight
    )
    
    -- Position tab
    local tabCount = 0
    for _ in pairs(self.tabs) do
        tabCount = tabCount + 1
    end
    
    local startX = (self.parent:GetWidth() - (tabCount + 1) * (self.tabWidth + 5)) / 2
    tab:SetPoint("LEFT", self.tabContainer, "LEFT", startX + tabCount * (self.tabWidth + 5), 0)
    
    -- Create panel
    local panel = CreateFrame("Frame", nil, self.contentContainer)
    panel:SetAllPoints(self.contentContainer)
    panel:Hide()
    
    -- Initialize panel content if function provided
    if createPanelFunc and type(createPanelFunc) == "function" then
        local success, error = MageControl.ErrorHandler.safeCall(
            createPanelFunc,
            MageControl.ErrorHandler.TYPES.UI,
            {module = "TabManager", tab = id},
            panel
        )
        
        if not success then
            MageControl.Logger.error("Failed to create panel for tab '" .. id .. "': " .. tostring(error), "TabManager")
        end
    end
    
    -- Tab click handler
    tab:SetScript("OnClick", function()
        self:selectTab(id)
    end)
    
    -- Store tab and panel
    self.tabs[id] = {
        button = tab,
        title = title,
        config = tabConfig
    }
    self.panels[id] = panel
    
    -- Select first tab automatically
    if not self.activeTab then
        self:selectTab(id)
    else
        -- Reposition existing tabs
        self:_repositionTabs()
    end
    
    MageControl.Logger.debug("Added tab: " .. id .. " (" .. title .. ")", "TabManager")
    return true
end

-- Select a tab
function TabManagerClass:selectTab(id)
    if not self.tabs[id] then
        MageControl.Logger.warn("Tab with ID '" .. id .. "' not found", "TabManager")
        return false
    end
    
    -- Hide current panel and deactivate current tab
    if self.activeTab then
        if self.panels[self.activeTab] then
            self.panels[self.activeTab]:Hide()
        end
        if self.tabs[self.activeTab] then
            self.tabs[self.activeTab].button.setActive(false)
        end
    end
    
    -- Show new panel and activate new tab
    self.activeTab = id
    if self.panels[id] then
        self.panels[id]:Show()
    end
    if self.tabs[id] then
        self.tabs[id].button.setActive(true)
    end
    
    MageControl.Logger.debug("Selected tab: " .. id, "TabManager")
    return true
end

-- Remove a tab
function TabManagerClass:removeTab(id)
    if not self.tabs[id] then
        MageControl.Logger.warn("Tab with ID '" .. id .. "' not found", "TabManager")
        return false
    end
    
    -- Clean up UI elements
    if self.tabs[id].button then
        self.tabs[id].button:Hide()
        self.tabs[id].button = nil
    end
    if self.panels[id] then
        self.panels[id]:Hide()
        self.panels[id] = nil
    end
    
    -- Remove from collections
    self.tabs[id] = nil
    self.panels[id] = nil
    
    -- Select another tab if this was active
    if self.activeTab == id then
        self.activeTab = nil
        -- Select first available tab
        for tabId, _ in pairs(self.tabs) do
            self:selectTab(tabId)
            break
        end
    end
    
    -- Reposition remaining tabs
    self:_repositionTabs()
    
    MageControl.Logger.debug("Removed tab: " .. id, "TabManager")
    return true
end

-- Get the panel for a specific tab
function TabManagerClass:getPanel(id)
    return self.panels[id]
end

-- Get the active tab ID
function TabManagerClass:getActiveTab()
    return self.activeTab
end

-- Get all tab IDs
function TabManagerClass:getTabIds()
    local ids = {}
    for id, _ in pairs(self.tabs) do
        table.insert(ids, id)
    end
    return ids
end

-- Reposition all tabs
function TabManagerClass:_repositionTabs()
    local tabCount = 0
    for _ in pairs(self.tabs) do
        tabCount = tabCount + 1
    end
    
    if tabCount == 0 then
        return
    end
    
    local startX = (self.parent:GetWidth() - tabCount * (self.tabWidth + 5) + 5) / 2
    local currentX = startX
    
    for id, tabData in pairs(self.tabs) do
        if tabData.button then
            tabData.button:ClearAllPoints()
            tabData.button:SetPoint("LEFT", self.tabContainer, "LEFT", currentX, 0)
            currentX = currentX + self.tabWidth + 5
        end
    end
end

-- Update tab title
function TabManagerClass:updateTabTitle(id, newTitle)
    if not self.tabs[id] then
        MageControl.Logger.warn("Tab with ID '" .. id .. "' not found", "TabManager")
        return false
    end
    
    self.tabs[id].title = newTitle
    if self.tabs[id].button then
        self.tabs[id].button:SetText(newTitle)
    end
    
    MageControl.Logger.debug("Updated tab title: " .. id .. " -> " .. newTitle, "TabManager")
    return true
end

-- Enable/disable a tab
function TabManagerClass:setTabEnabled(id, enabled)
    if not self.tabs[id] then
        MageControl.Logger.warn("Tab with ID '" .. id .. "' not found", "TabManager")
        return false
    end
    
    local button = self.tabs[id].button
    if button then
        if enabled then
            button:Enable()
            button:SetAlpha(1.0)
        else
            button:Disable()
            button:SetAlpha(0.5)
            -- Switch to another tab if this one is active
            if self.activeTab == id then
                for tabId, _ in pairs(self.tabs) do
                    if tabId ~= id then
                        self:selectTab(tabId)
                        break
                    end
                end
            end
        end
    end
    
    MageControl.Logger.debug("Set tab enabled: " .. id .. " -> " .. tostring(enabled), "TabManager")
    return true
end

-- Get tab manager statistics
function TabManagerClass:getStats()
    return {
        totalTabs = (function()
            local count = 0
            for _ in pairs(self.tabs) do
                count = count + 1
            end
            return count
        end)(),
        activeTab = self.activeTab,
        tabIds = self:getTabIds()
    }
end

-- Register the module
MageControl.ModuleSystem.registerModule("TabManager", TabManager)

-- Export for other modules
MageControl.UI.Framework.TabManager = TabManager
