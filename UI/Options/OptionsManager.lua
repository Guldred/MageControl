-- MageControl Options Manager
-- Clean, structured, and easily expandable options interface system

MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Options = MageControl.UI.Options or {}

-- Create the OptionsManager module
local OptionsManager = MageControl.createModule("OptionsManager", {"UIFramework", "TabManager", "ConfigManager", "Logger"})

-- Module state
OptionsManager.frame = nil
OptionsManager.tabManager = nil
OptionsManager.isVisible = false

-- Initialize the options manager
OptionsManager.initialize = function()
    MageControl.Logger.debug("Options Manager initialized", "OptionsManager")
end

-- Show the options interface
OptionsManager.show = function()
    if OptionsManager.frame and OptionsManager.frame:IsVisible() then
        OptionsManager.hide()
    else
        OptionsManager._createInterface()
        OptionsManager.frame:Show()
        OptionsManager.isVisible = true
        OptionsManager._loadCurrentValues()
    end
end

-- Hide the options interface
OptionsManager.hide = function()
    if OptionsManager.frame then
        OptionsManager.frame:Hide()
        OptionsManager.isVisible = false
    end
end

-- Toggle the options interface
OptionsManager.toggle = function()
    if OptionsManager.isVisible then
        OptionsManager.hide()
    else
        OptionsManager.show()
    end
end

-- Create the main options interface
OptionsManager._createInterface = function()
    if OptionsManager.frame then
        return
    end
    
    -- Create main frame
    OptionsManager.frame = MageControl.UI.Framework.UIFramework.createFrame(
        "MageControlOptionsFrame", 
        UIParent, 
        400, 
        440
    )
    OptionsManager.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Create title
    local title = MageControl.UI.Framework.UIFramework.createTitle(OptionsManager.frame, "MageControl Options")
    title:SetPoint("TOP", OptionsManager.frame, "TOP", 0, -15)
    
    -- Create close button
    local closeButton = MageControl.UI.Framework.UIFramework.createCloseButton(OptionsManager.frame)
    closeButton:SetScript("OnClick", function()
        OptionsManager.hide()
    end)
    
    -- Create tab manager
    OptionsManager.tabManager = MageControl.UI.Framework.TabManager.create(
        OptionsManager.frame,
        {
            tabWidth = 80,
            tabHeight = 28,
            contentHeight = 350,
            startY = -40
        }
    )
    
    -- Add tabs
    OptionsManager._createTabs()
    
    MageControl.Logger.debug("Options interface created", "OptionsManager")
end

-- Create all tabs
OptionsManager._createTabs = function()
    -- Setup tab
    OptionsManager.tabManager:addTab(
        "setup",
        "Setup",
        OptionsManager._createSetupPanel
    )
    
    -- Priority tab
    OptionsManager.tabManager:addTab(
        "priority",
        "Priority",
        OptionsManager._createPriorityPanel
    )
    
    -- Settings tab
    OptionsManager.tabManager:addTab(
        "settings",
        "Settings",
        OptionsManager._createSettingsPanel
    )
    
    -- Info tab
    OptionsManager.tabManager:addTab(
        "info",
        "Info",
        OptionsManager._createInfoPanel
    )
end

-- Create Setup Panel
OptionsManager._createSetupPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    -- Title
    local title = uiFramework.createText(panel, "Spell Slot Configuration", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    
    -- Auto-detect section
    local autoDetectFrame = CreateFrame("Frame", nil, panel)
    autoDetectFrame:SetWidth(360)
    autoDetectFrame:SetHeight(80)
    autoDetectFrame:SetPoint("TOP", title, "BOTTOM", 0, -20)
    
    -- Auto-detect button
    local autoDetectButton = uiFramework.createButton(autoDetectFrame, "Auto-Detect Spells", 140, 28)
    autoDetectButton:SetPoint("TOP", autoDetectFrame, "TOP", 0, -10)
    
    -- Auto-detect result text
    local autoDetectResult = uiFramework.createText(autoDetectFrame, "", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT_MUTED)
    autoDetectResult:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -5)
    autoDetectResult:SetWidth(340)
    autoDetectResult:SetJustifyH("CENTER")
    
    -- Auto-detect functionality
    autoDetectButton:SetScript("OnClick", function()
        local result = OptionsManager._autoDetectSpells()
        autoDetectResult:SetText(result.message)
        if result.success then
            autoDetectResult:SetTextColor(unpack(uiFramework.STYLES.COLORS.SUCCESS))
        else
            autoDetectResult:SetTextColor(unpack(uiFramework.STYLES.COLORS.WARNING))
        end
    end)
    
    -- Frame control section
    local frameControlFrame = CreateFrame("Frame", nil, panel)
    frameControlFrame:SetWidth(360)
    frameControlFrame:SetHeight(60)
    frameControlFrame:SetPoint("TOP", autoDetectFrame, "BOTTOM", 0, -10)
    
    local frameTitle = uiFramework.createText(frameControlFrame, "Frame Controls", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    frameTitle:SetPoint("TOP", frameControlFrame, "TOP", 0, -5)
    
    -- Lock/Unlock buttons
    local lockButton = uiFramework.createButton(frameControlFrame, "Lock Frames", 90, 28)
    local unlockButton = uiFramework.createButton(frameControlFrame, "Unlock Frames", 90, 28)
    
    lockButton:SetPoint("LEFT", frameControlFrame, "LEFT", 90, -20)
    unlockButton:SetPoint("LEFT", lockButton, "RIGHT", 10, 0)
    
    lockButton:SetScript("OnClick", function()
        if MC.lockFrames then
            MC.lockFrames()
        end
    end)
    
    unlockButton:SetScript("OnClick", function()
        if MC.unlockFrames then
            MC.unlockFrames()
        end
    end)
    
    -- Spell slot status section
    local statusFrame = CreateFrame("Frame", nil, panel)
    statusFrame:SetWidth(360)
    statusFrame:SetHeight(120)
    statusFrame:SetPoint("TOP", frameControlFrame, "BOTTOM", 0, -10)
    
    local statusTitle = uiFramework.createText(statusFrame, "Current Spell Slots", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    statusTitle:SetPoint("TOP", statusFrame, "TOP", 0, -5)
    
    -- Store references for updating
    panel.autoDetectResult = autoDetectResult
    panel.statusFrame = statusFrame
    
    -- Create status display
    OptionsManager._createSpellSlotStatus(statusFrame)
end

-- Create Priority Panel
OptionsManager._createPriorityPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    -- Title
    local title = uiFramework.createText(panel, "Trinket Priority Configuration", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    
    -- Description
    local desc = uiFramework.createText(panel, "Choose the activation order for your cooldowns (highest priority first)", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT_MUTED)
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetWidth(360)
    desc:SetJustifyH("CENTER")
    
    -- Priority list frame
    local listFrame = CreateFrame("Frame", nil, panel)
    listFrame:SetWidth(360)
    listFrame:SetHeight(200)
    listFrame:SetPoint("TOP", desc, "BOTTOM", 0, -20)
    listFrame:SetBackdrop(uiFramework.BACKDROPS.FRAME)
    listFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    listFrame:SetBackdropBorderColor(unpack(uiFramework.STYLES.COLORS.BORDER))
    
    -- Fixed priority items (always these 3)
    local priorityItems = {}
    local itemFrames = {}
    
    -- Default priority order
    local defaultOrder = {
        {type = "trinket", slot = 13, name = "Trinket Slot 1", id = "trinket1"},
        {type = "trinket", slot = 14, name = "Trinket Slot 2", id = "trinket2"},
        {type = "spell", name = "Arcane Power", spellId = 12042, id = "arcane_power"}
    }
    
    local function refreshPriorityList()
        -- Clear existing frames
        for _, frame in ipairs(itemFrames) do
            frame:Hide()
            frame:SetParent(nil)
        end
        itemFrames = {}
        
        -- Get current priority order from config
        local savedOrder = MageControlDB.trinkets and MageControlDB.trinkets.priorityList or {}
        
        -- If no saved order or incomplete, use default
        if table.getn(savedOrder) ~= 3 then
            priorityItems = {}
            for i, item in ipairs(defaultOrder) do
                table.insert(priorityItems, item)
            end
        else
            priorityItems = savedOrder
        end
        
        -- Create UI for each priority item
        for i, item in ipairs(priorityItems) do
            local itemFrame = CreateFrame("Frame", nil, listFrame)
            itemFrame:SetWidth(320)
            itemFrame:SetHeight(35)
            itemFrame:SetPoint("TOP", listFrame, "TOP", 0, -(i-1) * 40 - 15)
            itemFrame:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2}
            })
            itemFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            itemFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
            
            -- Priority number (large, prominent)
            local priorityText = uiFramework.createText(itemFrame, tostring(i), uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
            priorityText:SetPoint("LEFT", itemFrame, "LEFT", 15, 0)
            
            -- Item name
            local itemText = uiFramework.createText(itemFrame, item.name, uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TEXT)
            itemText:SetPoint("LEFT", priorityText, "RIGHT", 20, 0)
            
            -- Up/Down buttons (use ASCII characters instead of Unicode)
            local upButton = uiFramework.createButton(itemFrame, "Up", 35, 25)
            local downButton = uiFramework.createButton(itemFrame, "Down", 35, 25)
            
            upButton:SetPoint("RIGHT", itemFrame, "RIGHT", -45, 0)
            downButton:SetPoint("RIGHT", itemFrame, "RIGHT", -5, 0)
            
            -- Create closure-safe functions with current index
            local currentIndex = i
            
            -- Disable up button for first item, down button for last item
            if currentIndex == 1 then
                upButton:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
                upButton:EnableMouse(false)
            else
                upButton:SetScript("OnClick", function()
                    -- Move item up - swap with previous item
                    local temp = priorityItems[currentIndex-1]
                    priorityItems[currentIndex-1] = priorityItems[currentIndex]
                    priorityItems[currentIndex] = temp
                    MageControlDB.trinkets = MageControlDB.trinkets or {}
                    MageControlDB.trinkets.priorityList = priorityItems
                    refreshPriorityList()
                end)
            end
            
            if currentIndex == table.getn(priorityItems) then
                downButton:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
                downButton:EnableMouse(false)
            else
                downButton:SetScript("OnClick", function()
                    -- Move item down - swap with next item
                    local temp = priorityItems[currentIndex+1]
                    priorityItems[currentIndex+1] = priorityItems[currentIndex]
                    priorityItems[currentIndex] = temp
                    MageControlDB.trinkets = MageControlDB.trinkets or {}
                    MageControlDB.trinkets.priorityList = priorityItems
                    refreshPriorityList()
                end)
            end
            
            table.insert(itemFrames, itemFrame)
        end
    end
    
    -- Reset button (centered at bottom)
    local resetButton = uiFramework.createButton(panel, "Reset to Default Order", 160, 28)
    resetButton:SetPoint("TOP", listFrame, "BOTTOM", 0, -20)
    
    resetButton:SetScript("OnClick", function()
        -- Reset to default order
        priorityItems = {}
        for i, item in ipairs(defaultOrder) do
            table.insert(priorityItems, item)
        end
        MageControlDB.trinkets = MageControlDB.trinkets or {}
        MageControlDB.trinkets.priorityList = priorityItems
        refreshPriorityList()
    end)
    
    -- Store references and initialize
    panel.refreshPriorityList = refreshPriorityList
    
    -- Initial load
    refreshPriorityList()
end

-- Create Settings Panel
OptionsManager._createSettingsPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    -- Title
    local title = uiFramework.createText(panel, "Rotation Settings", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    
    -- Arcane Power settings
    local apFrame = CreateFrame("Frame", nil, panel)
    apFrame:SetWidth(360)
    apFrame:SetHeight(80)
    apFrame:SetPoint("TOP", title, "BOTTOM", 0, -20)
    
    local apTitle = uiFramework.createText(apFrame, "Arcane Power Settings", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    apTitle:SetPoint("TOP", apFrame, "TOP", 0, -5)
    
    -- Minimum mana slider
    local manaLabel = uiFramework.createText(apFrame, "Minimum Mana:", uiFramework.STYLES.FONTS.SMALL)
    manaLabel:SetPoint("TOP", apTitle, "BOTTOM", 0, -10)
    manaLabel:SetJustifyH("CENTER")
    
    local manaSlider = uiFramework.createSlider(apFrame, 0, 100, 1, 200, 16)
    manaSlider:SetPoint("TOP", manaLabel, "BOTTOM", 0, -5)
    
    local manaValue = uiFramework.createText(apFrame, "50%", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TITLE)
    manaValue:SetPoint("TOP", manaSlider, "BOTTOM", 0, -5)
    manaValue:SetJustifyH("CENTER")
    
    -- Slider functionality
    manaSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() + 0.5)
        manaValue:SetText(value .. "%")
        MageControlDB.minManaForArcanePowerUse = value
    end)
    
    -- Arcane Surge settings
    local asFrame = CreateFrame("Frame", nil, panel)
    asFrame:SetWidth(360)
    asFrame:SetHeight(80)
    asFrame:SetPoint("TOP", apFrame, "BOTTOM", 0, -10)
    
    local asTitle = uiFramework.createText(asFrame, "Arcane Surge Settings", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    asTitle:SetPoint("TOP", asFrame, "TOP", 0, -5)
    
    -- Minimum missiles slider
    local missilesLabel = uiFramework.createText(asFrame, "Min Missiles for Cancel:", uiFramework.STYLES.FONTS.SMALL)
    missilesLabel:SetPoint("TOP", asTitle, "BOTTOM", 0, -10)
    missilesLabel:SetJustifyH("CENTER")
    
    local missilesSlider = uiFramework.createSlider(asFrame, 1, 6, 1, 200, 16)
    missilesSlider:SetPoint("TOP", missilesLabel, "BOTTOM", 0, -5)
    
    local missilesValue = uiFramework.createText(asFrame, "4", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TITLE)
    missilesValue:SetPoint("TOP", missilesSlider, "BOTTOM", 0, -5)
    missilesValue:SetJustifyH("CENTER")
    
    -- Missiles slider functionality
    missilesSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() + 0.5)
        missilesValue:SetText(tostring(value))
        MageControlDB.minMissilesForSurgeCancel = value
    end)
    
    -- Store references
    panel.manaSlider = manaSlider
    panel.manaValue = manaValue
    panel.missilesSlider = missilesSlider
    panel.missilesValue = missilesValue
end

-- Create Info Panel
OptionsManager._createInfoPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    -- Title
    local title = uiFramework.createText(panel, "Addon Information", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    
    -- Version info
    local versionText = uiFramework.createText(panel, "MageControl v1.8.1", uiFramework.STYLES.FONTS.NORMAL)
    versionText:SetPoint("TOP", title, "BOTTOM", 0, -20)
    
    -- Dependencies
    local depsTitle = uiFramework.createText(panel, "Dependencies", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    depsTitle:SetPoint("TOP", versionText, "BOTTOM", 0, -20)
    
    local depsText = uiFramework.createText(panel, "", uiFramework.STYLES.FONTS.SMALL)
    depsText:SetPoint("TOP", depsTitle, "BOTTOM", 0, -10)
    depsText:SetWidth(340)
    depsText:SetJustifyH("CENTER")  -- Center align instead of left align
    
    -- Update dependencies info
    local depsInfo = OptionsManager._checkDependencies()
    depsText:SetText(depsInfo)
    
    -- Authors
    local authorsTitle = uiFramework.createText(panel, "Authors", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    authorsTitle:SetPoint("TOP", depsText, "BOTTOM", 0, -20)
    
    local authorsText = uiFramework.createText(panel, "Guldred, Nolin7777", uiFramework.STYLES.FONTS.NORMAL)
    authorsText:SetPoint("TOP", authorsTitle, "BOTTOM", 0, -10)
    
    -- Store references
    panel.depsText = depsText
end

-- Auto-detect spells functionality
OptionsManager._autoDetectSpells = function()
    local foundSlots = {}
    local spellIds = {
        FIREBLAST = 10199,
        ARCANE_RUPTURE = 51954,
        ARCANE_SURGE = 51936,
        ARCANE_POWER = 12042
    }

    for slot = 1, 120 do
        if HasAction(slot) then
            local text, type, id = GetActionText(slot)
            text = text or ""
            type = type or ""
            id = id or 0
            for spellKey, targetId in pairs(spellIds) do
                if id == targetId and not foundSlots[spellKey] then
                    foundSlots[spellKey] = slot
                end
            end
        end
    end

    local updated = false
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {}
    end

    for spellKey, slot in pairs(foundSlots) do
        MageControlDB.actionBarSlots[spellKey] = slot
        updated = true
    end

    local requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local missingSpells = {}
    for _, spellKey in ipairs(requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingSpells, spellKey)
        end
    end

    if updated and table.getn(missingSpells) == 0 then
        return {success = true, message = "All required spells found and configured!"}
    elseif table.getn(missingSpells) > 0 then
        return {success = false, message = "Missing spells: " .. table.concat(missingSpells, ", ")}
    else
        return {success = true, message = "All spells already configured."}
    end
end

-- Create spell slot status display
OptionsManager._createSpellSlotStatus = function(parent)
    local uiFramework = MageControl.UI.Framework.UIFramework
    local spells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local yOffset = -25
    
    for i, spellKey in ipairs(spells) do
        local spellFrame = CreateFrame("Frame", nil, parent)
        spellFrame:SetWidth(340)
        spellFrame:SetHeight(20)
        spellFrame:SetPoint("TOP", parent, "TOP", 0, yOffset)
        
        local spellName = uiFramework.createText(spellFrame, spellKey .. ":", uiFramework.STYLES.FONTS.SMALL)
        spellName:SetPoint("LEFT", spellFrame, "LEFT", 10, 0)
        
        local slotText = uiFramework.createText(spellFrame, "Not configured", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT_MUTED)
        slotText:SetPoint("RIGHT", spellFrame, "RIGHT", -10, 0)
        
        -- Store reference for updating
        parent[spellKey .. "_status"] = slotText
        
        yOffset = yOffset - 25
    end
end

-- Check dependencies
OptionsManager._checkDependencies = function()
    local output = "SuperWoW: "
    if SUPERWOW_VERSION then
        output = output .. "Version " .. tostring(SUPERWOW_VERSION)
    else
        output = output .. "Not found!"
    end

    output = output .. "\nNampower: "
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

-- Load current values into the interface
OptionsManager._loadCurrentValues = function()
    if not OptionsManager.tabManager then
        return
    end
    
    -- Load settings panel values
    local settingsPanel = OptionsManager.tabManager:getPanel("settings")
    if settingsPanel then
        -- Mana slider
        if settingsPanel.manaSlider then
            local manaValue = MageControlDB.minManaForArcanePowerUse or 50
            settingsPanel.manaSlider:SetValue(manaValue)
            settingsPanel.manaValue:SetText(manaValue .. "%")
        end
        
        -- Missiles slider
        if settingsPanel.missilesSlider then
            local missilesValue = MageControlDB.minMissilesForSurgeCancel or 4
            settingsPanel.missilesSlider:SetValue(missilesValue)
            settingsPanel.missilesValue:SetText(tostring(missilesValue))
        end
    end
    
    -- Load setup panel status
    local setupPanel = OptionsManager.tabManager:getPanel("setup")
    if setupPanel and setupPanel.statusFrame then
        OptionsManager._updateSpellSlotStatus(setupPanel.statusFrame)
    end
end

-- Update spell slot status display
OptionsManager._updateSpellSlotStatus = function(statusFrame)
    if not statusFrame or not MageControlDB.actionBarSlots then
        return
    end
    
    local spells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    for _, spellKey in ipairs(spells) do
        local statusText = statusFrame[spellKey .. "_status"]
        if statusText then
            local slot = MageControlDB.actionBarSlots[spellKey]
            if slot then
                statusText:SetText("Slot " .. slot)
                statusText:SetTextColor(unpack(uiFramework.STYLES.COLORS.SUCCESS))
            else
                statusText:SetText("Not configured")
                statusText:SetTextColor(unpack(uiFramework.STYLES.COLORS.TEXT_MUTED))
            end
        end
    end
end

-- Register the module
MageControl.ModuleSystem.registerModule("OptionsManager", OptionsManager)

-- Backward compatibility
MC.showOptionsMenu = function()
    OptionsManager.toggle()
end

-- Export for other modules
MageControl.UI.Options.OptionsManager = OptionsManager
