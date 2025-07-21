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
        480, 
        520
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
            contentHeight = 450,
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
    
    -- Boss Encounters tab
    OptionsManager.tabManager:addTab(
        "encounters",
        "Encounters",
        OptionsManager._createBossEncountersPanel
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
    
    -- Auto-detect frame
    local autoDetectFrame = CreateFrame("Frame", nil, panel)
    autoDetectFrame:SetWidth(440)
    autoDetectFrame:SetHeight(50)
    autoDetectFrame:SetPoint("TOP", panel, "TOP", 0, -40)
    
    -- Auto-detect description
    local autoDetectDesc = uiFramework.createText(autoDetectFrame, "Click to automatically scan all action bars and configure spell slots", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUBTEXT)
    autoDetectDesc:SetPoint("TOP", autoDetectFrame, "TOP", 0, -5)
    autoDetectDesc:SetWidth(420)
    autoDetectDesc:SetJustifyH("CENTER")
    
    -- Auto-detect button
    local autoDetectButton = uiFramework.createButton(autoDetectFrame, "Auto-Detect", function()
        OptionsManager._performAutoDetection(panel)
    end)
    autoDetectButton:SetPoint("TOP", autoDetectDesc, "BOTTOM", 0, -8)
    
    -- Auto-detect result text
    local autoDetectResult = uiFramework.createText(autoDetectFrame, "", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUCCESS)
    autoDetectResult:SetPoint("TOP", autoDetectButton, "BOTTOM", 0, -5)
    autoDetectResult:SetWidth(420)
    autoDetectResult:SetJustifyH("CENTER")
    
    -- Details frame for additional feedback
    local detailsFrame = CreateFrame("Frame", nil, panel)
    detailsFrame:SetWidth(440)
    detailsFrame:SetHeight(40)
    detailsFrame:SetPoint("TOPLEFT", autoDetectFrame, "BOTTOMLEFT", 0, -10)
    
    -- Details text
    local detailsText = uiFramework.createText(detailsFrame, "", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT_MUTED)
    detailsText:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, -10)
    detailsText:SetWidth(420)
    detailsText:SetJustifyH("CENTER")
    
    -- Store references for auto-detect functionality
    panel.autoDetectButton = autoDetectButton
    panel.autoDetectResult = autoDetectResult
    panel.detailsText = detailsText
    
    -- Frame control section
    local frameControlFrame = CreateFrame("Frame", nil, panel)
    frameControlFrame:SetWidth(440)
    frameControlFrame:SetHeight(60)
    frameControlFrame:SetPoint("TOPLEFT", detailsFrame, "BOTTOMLEFT", 0, -10)
    
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
    
    -- Spell status section
    local statusFrame = CreateFrame("Frame", nil, panel)
    statusFrame:SetWidth(440)
    statusFrame:SetHeight(120)
    statusFrame:SetPoint("TOPLEFT", frameControlFrame, "BOTTOMLEFT", 0, -10)
    
    -- Create status display
    OptionsManager._createSpellSlotStatus(statusFrame)
    
    -- Store references for updating
    panel.autoDetectResult = autoDetectResult
    panel.statusFrame = statusFrame
    
    --[[-- Create hide and reload buttons
    local hideButton = uiFramework.createButton(frameControlFrame, "Hide Frame", function()
        OptionsManager.hide()
    end)
    hideButton:SetPoint("LEFT", frameControlFrame, "LEFT", 20, -20)
    
    local reloadButton = uiFramework.createButton(frameControlFrame, "Reload UI", function()
        ReloadUI()
    end)
    reloadButton:SetPoint("LEFT", hideButton, "RIGHT", 10, 0)]]
end

-- Create Priority Panel
OptionsManager._createPriorityPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    local title = uiFramework.createText(panel, "Trinket & Cooldown Priority", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    
    local desc = uiFramework.createText(panel, "Configure the activation order for trinkets and Arcane Power", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT)
    desc:SetPoint("TOP", title, "BOTTOM", 0, -8)
    desc:SetWidth(440)
    desc:SetJustifyH("CENTER")
    
    -- Priority list frame
    local listFrame = CreateFrame("Frame", nil, panel)
    listFrame:SetWidth(440)
    listFrame:SetHeight(200)
    listFrame:SetPoint("TOP", desc, "BOTTOM", 0, -15)
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

-- Create Boss Encounters Panel
OptionsManager._createBossEncountersPanel = function(panel)
    local uiFramework = MageControl.UI.Framework.UIFramework
    
    -- Title
    local title = uiFramework.createText(panel, "Boss Encounter Settings", uiFramework.STYLES.FONTS.TITLE, uiFramework.STYLES.COLORS.TITLE)
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -20)
    
    -- Description
    local description = uiFramework.createText(panel, "Configure automatic spell selection for specific boss encounters and testing", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TEXT)
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    
    -- Incantagos Setting
    local incantagosFrame = CreateFrame("Frame", nil, panel)
    incantagosFrame:SetWidth(400)
    incantagosFrame:SetHeight(60)
    incantagosFrame:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
    
    -- Incantagos checkbox
    local incantagosCheckbox = CreateFrame("CheckButton", nil, incantagosFrame, "UICheckButtonTemplate")
    incantagosCheckbox:SetWidth(24)
    incantagosCheckbox:SetHeight(24)
    incantagosCheckbox:SetPoint("TOPLEFT", incantagosFrame, "TOPLEFT", 0, 0)
    
    -- Incantagos label
    local incantagosLabel = uiFramework.createText(incantagosFrame, "Automatically pick correct spell for adds on Incantagos", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TEXT)
    incantagosLabel:SetPoint("LEFT", incantagosCheckbox, "RIGHT", 8, 0)
    
    -- Incantagos help text
    local incantagosHelp = uiFramework.createText(incantagosFrame, "When enabled, /mc arcane will automatically cast Fireball on \nRed Affinity and Frostbolt on Blue Affinity", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUBTEXT)
    incantagosHelp:SetPoint("TOPLEFT", incantagosLabel, "BOTTOMLEFT", 0, -5)
    
    -- Load current value
    local currentValue = MageControlDB.bossEncounters and MageControlDB.bossEncounters.incantagos and MageControlDB.bossEncounters.incantagos.enabled or false
    incantagosCheckbox:SetChecked(currentValue)
    
    -- Save on change
    incantagosCheckbox:SetScript("OnClick", function()
        local isChecked = incantagosCheckbox:GetChecked()
        
        -- Ensure the structure exists
        MageControlDB.bossEncounters = MageControlDB.bossEncounters or {}
        MageControlDB.bossEncounters.incantagos = MageControlDB.bossEncounters.incantagos or {}
        MageControlDB.bossEncounters.incantagos.enabled = isChecked
        
        MageControl.Logger.info("Incantagos encounter setting " .. (isChecked and "enabled" or "disabled"))
    end)
    
    -- Store reference for loading values
    panel.incantagosCheckbox = incantagosCheckbox
    
    -- Training Dummy Settings Section
    local dummyTitle = uiFramework.createText(panel, "Training Dummy Testing", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    dummyTitle:SetPoint("TOPLEFT", incantagosFrame, "BOTTOMLEFT", 0, -30)
    
    local dummyDescription = uiFramework.createText(panel, "Enable training dummy spell selection for testing the boss encounter system", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUBTEXT)
    dummyDescription:SetPoint("TOPLEFT", dummyTitle, "BOTTOMLEFT", 0, -5)
    
    -- Training Dummy Enable Setting
    local dummyFrame = CreateFrame("Frame", nil, panel)
    dummyFrame:SetWidth(400)
    dummyFrame:SetHeight(60)
    dummyFrame:SetPoint("TOPLEFT", dummyDescription, "BOTTOMLEFT", 0, -15)
    
    -- Training dummy checkbox
    local dummyCheckbox = CreateFrame("CheckButton", nil, dummyFrame, "UICheckButtonTemplate")
    dummyCheckbox:SetWidth(24)
    dummyCheckbox:SetHeight(24)
    dummyCheckbox:SetPoint("TOPLEFT", dummyFrame, "TOPLEFT", 0, 0)
    
    -- Training dummy label
    local dummyLabel = uiFramework.createText(dummyFrame, "Enable training dummy spell selection", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TEXT)
    dummyLabel:SetPoint("LEFT", dummyCheckbox, "RIGHT", 8, 0)
    
    -- Training dummy description
    local dummyDesc = uiFramework.createText(dummyFrame, "Heroic Training Dummy → Fireball, Expert Training Dummy → Frostbolt", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUBTEXT)
    dummyDesc:SetPoint("TOPLEFT", dummyLabel, "BOTTOMLEFT", 0, -5)
    
    -- Training dummy checkbox event handling
    dummyCheckbox:SetScript("OnClick", function()
        local isChecked = dummyCheckbox:GetChecked()
        MageControlDB.bossEncounters = MageControlDB.bossEncounters or {}
        MageControlDB.bossEncounters.enableTrainingDummies = isChecked
        
        if isChecked then
            MC.printMessage("Training dummy spell selection enabled for testing")
        else
            MC.printMessage("Training dummy spell selection disabled")
        end
    end)
    
    -- Store reference for loading values
    panel.incantagosCheckbox = incantagosCheckbox
    panel.dummyCheckbox = dummyCheckbox
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

-- Enhanced Smart Spell Detection System
OptionsManager._autoDetectSpells = function()
    local foundSlots = {}
    local duplicateSlots = {} -- Track multiple instances of same spell
    local spellIds = {
        FIREBLAST = 10199,
        ARCANE_RUPTURE = 51954,
        ARCANE_SURGE = 51936,
        ARCANE_POWER = 12042
    }
    
    local spellNames = {
        FIREBLAST = "Fire Blast",
        ARCANE_RUPTURE = "Arcane Rupture", 
        ARCANE_SURGE = "Arcane Surge",
        ARCANE_POWER = "Arcane Power"
    }

    -- Comprehensive action bar scanning
    MageControl.Logger.info("Scanning all 120 action bar slots for spells...")
    
    for slot = 1, 120 do
        if HasAction(slot) then
            local text, type, id = GetActionText(slot)
            text = text or ""
            type = type or ""
            id = id or 0
            
            for spellKey, targetId in pairs(spellIds) do
                if id == targetId then
                    if not foundSlots[spellKey] then
                        foundSlots[spellKey] = slot
                        MageControl.Logger.debug("Found " .. spellNames[spellKey] .. " at slot " .. slot, "SmartDetection")
                    else
                        -- Track duplicates for smart selection
                        if not duplicateSlots[spellKey] then
                            duplicateSlots[spellKey] = {foundSlots[spellKey]}
                        end
                        table.insert(duplicateSlots[spellKey], slot)
                        MageControl.Logger.debug("Found duplicate " .. spellNames[spellKey] .. " at slot " .. slot, "SmartDetection")
                    end
                end
            end
        end
    end

    -- Smart conflict resolution - prefer easily accessible slots
    for spellKey, slots in pairs(duplicateSlots) do
        local bestSlot = OptionsManager._selectOptimalSlot(slots, spellKey)
        foundSlots[spellKey] = bestSlot
        MageControl.Logger.info("Selected optimal slot " .. bestSlot .. " for " .. spellNames[spellKey] .. " (had " .. table.getn(slots) .. " options)")
    end

    -- Update configuration
    local updated = false
    if not MageControlDB.actionBarSlots then
        MageControlDB.actionBarSlots = {}
    end

    local changedSpells = {}
    for spellKey, slot in pairs(foundSlots) do
        if MageControlDB.actionBarSlots[spellKey] ~= slot then
            MageControlDB.actionBarSlots[spellKey] = slot
            table.insert(changedSpells, spellNames[spellKey] .. " → Slot " .. slot)
            updated = true
        end
    end

    -- Generate detailed feedback
    local requiredSpells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE"}
    local optionalSpells = {"ARCANE_POWER"}
    local missingRequired = {}
    local missingOptional = {}
    
    for _, spellKey in ipairs(requiredSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingRequired, spellNames[spellKey])
        end
    end
    
    for _, spellKey in ipairs(optionalSpells) do
        if not foundSlots[spellKey] then
            table.insert(missingOptional, spellNames[spellKey])
        end
    end

    -- Return comprehensive results
    local result = {
        success = table.getn(missingRequired) == 0,
        foundCount = 0,
        totalRequired = table.getn(requiredSpells),
        changedSpells = changedSpells,
        missingRequired = missingRequired,
        missingOptional = missingOptional,
        duplicatesResolved = 0
    }
    
    -- Count found spells and duplicates resolved
    for spellKey, _ in pairs(foundSlots) do
        result.foundCount = result.foundCount + 1
    end
    
    for spellKey, slots in pairs(duplicateSlots) do
        result.duplicatesResolved = result.duplicatesResolved + (table.getn(slots) - 1)
    end

    -- Generate user-friendly message
    if result.success and updated then
        result.message = "✓ Auto-detection complete! Found " .. result.foundCount .. " spells."
        if result.duplicatesResolved > 0 then
            result.message = result.message .. " Resolved " .. result.duplicatesResolved .. " duplicates."
        end
    elseif result.success and not updated then
        result.message = "✓ All spells already configured correctly."
    else
        result.message = "⚠ Missing required spells: " .. table.concat(missingRequired, ", ")
        if table.getn(missingOptional) > 0 then
            result.message = result.message .. " (Optional: " .. table.concat(missingOptional, ", ") .. ")"
        end
    end

    return result
end

-- Smart slot selection algorithm
OptionsManager._selectOptimalSlot = function(slots, spellKey)
    -- Preference order: 1-12 (main bars) > 13-24 (shift bar) > 25-36 (ctrl bar) > others
    local preferences = {
        {min = 1, max = 12, priority = 1},   -- Main action bar
        {min = 13, max = 24, priority = 2},  -- Shift action bar  
        {min = 25, max = 36, priority = 3},  -- Ctrl action bar
        {min = 37, max = 48, priority = 4},  -- Alt action bar
        {min = 49, max = 120, priority = 5}  -- Other bars
    }
    
    local bestSlot = slots[1]
    local bestPriority = 999
    
    for _, slot in ipairs(slots) do
        for _, pref in ipairs(preferences) do
            if slot >= pref.min and slot <= pref.max then
                if pref.priority < bestPriority then
                    bestSlot = slot
                    bestPriority = pref.priority
                elseif pref.priority == bestPriority and slot < bestSlot then
                    -- Within same priority, prefer lower slot numbers
                    bestSlot = slot
                end
                break
            end
        end
    end
    
    return bestSlot
end

-- Perform auto-detection with enhanced feedback
OptionsManager._performAutoDetection = function(panel)
    if not panel.autoDetectButton or not panel.autoDetectResult or not panel.detailsText then
        return
    end
    
    -- Show scanning state
    panel.autoDetectButton:SetText("🔄 Scanning...")
    panel.autoDetectButton:Disable()
    panel.autoDetectResult:SetText("Scanning all 120 action bar slots...")
    panel.autoDetectResult:SetTextColor(unpack(MageControl.UI.Framework.UIFramework.STYLES.COLORS.TEXT))
    
    -- Perform detection (with slight delay for UI feedback)
    local function performDetection()
        local result = OptionsManager._autoDetectSpells()
        
        -- Update main result
        panel.autoDetectResult:SetText(result.message)
        if result.success then
            panel.autoDetectResult:SetTextColor(unpack(MageControl.UI.Framework.UIFramework.STYLES.COLORS.SUCCESS))
        else
            panel.autoDetectResult:SetTextColor(unpack(MageControl.UI.Framework.UIFramework.STYLES.COLORS.WARNING))
        end
        
        -- Show detailed information
        local details = {}
        if table.getn(result.changedSpells) > 0 then
            table.insert(details, "Updated: " .. table.concat(result.changedSpells, ", "))
        end
        if result.duplicatesResolved > 0 then
            table.insert(details, "Resolved " .. result.duplicatesResolved .. " duplicate(s)")
        end
        if table.getn(result.missingOptional) > 0 then
            table.insert(details, "Optional missing: " .. table.concat(result.missingOptional, ", "))
        end
        
        if table.getn(details) > 0 then
            panel.detailsText:SetText(table.concat(details, " • "))
        else
            panel.detailsText:SetText("")
        end
        
        -- Update spell status display
        if panel.statusFrame then
            OptionsManager._updateSpellSlotStatus(panel.statusFrame)
        end
        
        -- Reset button
        panel.autoDetectButton:SetText("Auto-Detect")
        panel.autoDetectButton:Enable()
    end
    
    -- Use a timer for better UX (shows scanning state briefly)
    local timer = CreateFrame("Frame")
    timer.elapsed = 0
    timer:SetScript("OnUpdate", function()
        timer.elapsed = timer.elapsed + arg1
        if timer.elapsed >= 0.5 then -- 0.5 second delay
            performDetection()
            timer:SetScript("OnUpdate", nil)
        end
    end)
end

-- Enhanced spell slot status display with real-time validation
OptionsManager._createSpellSlotStatus = function(parent)
    local uiFramework = MageControl.UI.Framework.UIFramework
    local spells = {
        {key = "FIREBLAST", name = "Fire Blast", required = true},
        {key = "ARCANE_RUPTURE", name = "Arcane Rupture", required = true},
        {key = "ARCANE_SURGE", name = "Arcane Surge", required = true},
        {key = "ARCANE_POWER", name = "Arcane Power", required = false}
    }
    local yOffset = -25
    
    -- Status header
    local statusHeader = uiFramework.createText(parent, "Current Spell Configuration:", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TITLE)
    statusHeader:SetPoint("TOP", parent, "TOP", 0, -15)
    
    for i, spell in ipairs(spells) do
        local spellFrame = CreateFrame("Frame", nil, parent)
        spellFrame:SetWidth(340)
        spellFrame:SetHeight(22)
        spellFrame:SetPoint("TOP", parent, "TOP", 0, yOffset)
        
        -- Status indicator (colored dot)
        local statusDot = uiFramework.createText(spellFrame, "●", uiFramework.STYLES.FONTS.NORMAL, uiFramework.STYLES.COLORS.TEXT_MUTED)
        statusDot:SetPoint("LEFT", spellFrame, "LEFT", 10, 0)
        
        -- Spell name with required indicator
        local requiredText = spell.required and " *" or ""
        local spellName = uiFramework.createText(spellFrame, spell.name .. requiredText, uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT)
        spellName:SetPoint("LEFT", statusDot, "RIGHT", 5, 0)
        
        -- Slot information
        local slotText = uiFramework.createText(spellFrame, "Not configured", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.TEXT_MUTED)
        slotText:SetPoint("RIGHT", spellFrame, "RIGHT", -10, 0)
        
        -- Store references for updating
        parent[spell.key .. "_status"] = slotText
        parent[spell.key .. "_dot"] = statusDot
        parent[spell.key .. "_required"] = spell.required
        
        yOffset = yOffset - 25
    end
    
    --[[-- Legend
    local legendFrame = CreateFrame("Frame", nil, parent)
    legendFrame:SetWidth(340)
    legendFrame:SetHeight(20)
    legendFrame:SetPoint("TOP", parent, "TOP", 0, yOffset - 10)
    
    local legendText = uiFramework.createText(legendFrame, "● Configured  ● Missing  * Required", uiFramework.STYLES.FONTS.SMALL, uiFramework.STYLES.COLORS.SUBTEXT)
    legendText:SetPoint("CENTER", legendFrame, "CENTER", 0, 0)]]
    
    return parent
end

-- Enhanced spell slot status update with validation
OptionsManager._updateSpellSlotStatus = function(statusFrame)
    if not statusFrame or not MageControlDB.actionBarSlots then
        return
    end
    
    local uiFramework = MageControl.UI.Framework.UIFramework
    local spells = {"FIREBLAST", "ARCANE_RUPTURE", "ARCANE_SURGE", "ARCANE_POWER"}
    local configuredCount = 0
    local requiredCount = 0
    local requiredConfigured = 0
    
    for _, spellKey in ipairs(spells) do
        local statusText = statusFrame[spellKey .. "_status"]
        local statusDot = statusFrame[spellKey .. "_dot"]
        local isRequired = statusFrame[spellKey .. "_required"]
        
        if statusText and statusDot then
            local slot = MageControlDB.actionBarSlots[spellKey]
            
            if isRequired then
                requiredCount = requiredCount + 1
            end
            
            if slot and slot > 0 then
                -- Validate that the spell is actually in that slot
                local isValid = OptionsManager._validateSpellSlot(spellKey, slot)
                
                if isValid then
                    statusText:SetText("Slot " .. slot .. " ✓")
                    statusText:SetTextColor(unpack(uiFramework.STYLES.COLORS.SUCCESS))
                    statusDot:SetTextColor(unpack(uiFramework.STYLES.COLORS.SUCCESS))
                    configuredCount = configuredCount + 1
                    if isRequired then
                        requiredConfigured = requiredConfigured + 1
                    end
                else
                    statusText:SetText("Slot " .. slot .. " ⚠ (Invalid)")
                    statusText:SetTextColor(unpack(uiFramework.STYLES.COLORS.WARNING))
                    statusDot:SetTextColor(unpack(uiFramework.STYLES.COLORS.WARNING))
                end
            else
                local statusColor = isRequired and uiFramework.STYLES.COLORS.ERROR or uiFramework.STYLES.COLORS.TEXT_MUTED
                statusText:SetText(isRequired and "Missing (Required)" or "Not configured")
                statusText:SetTextColor(unpack(statusColor))
                statusDot:SetTextColor(unpack(statusColor))
            end
        end
    end
    
    -- Update overall status if there's a summary element
    if statusFrame.summaryText then
        local summaryColor = (requiredConfigured == requiredCount) and uiFramework.STYLES.COLORS.SUCCESS or uiFramework.STYLES.COLORS.WARNING
        statusFrame.summaryText:SetText(configuredCount .. "/4 spells configured (" .. requiredConfigured .. "/" .. requiredCount .. " required)")
        statusFrame.summaryText:SetTextColor(unpack(summaryColor))
    end
end

-- Validate that a spell is actually in the specified slot
OptionsManager._validateSpellSlot = function(spellKey, slot)
    if not HasAction(slot) then
        return false
    end
    
    local spellIds = {
        FIREBLAST = 10199,
        ARCANE_RUPTURE = 51954,
        ARCANE_SURGE = 51936,
        ARCANE_POWER = 12042
    }
    
    local targetId = spellIds[spellKey]
    if not targetId then
        return false
    end
    
    local text, type, id = GetActionText(slot)
    return id == targetId
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
    
    -- Load boss encounters panel values
    local encountersPanel = OptionsManager.tabManager:getPanel("encounters")
    if encountersPanel and encountersPanel.incantagosCheckbox then
        local currentValue = MageControlDB.bossEncounters and MageControlDB.bossEncounters.incantagos and MageControlDB.bossEncounters.incantagos.enabled or false
        encountersPanel.incantagosCheckbox:SetChecked(currentValue)
    end
    
    if encountersPanel and encountersPanel.dummyCheckbox then
        local currentValue = MageControlDB.bossEncounters and MageControlDB.bossEncounters.enableTrainingDummies or false
        encountersPanel.dummyCheckbox:SetChecked(currentValue)
    end
end

-- Register the module
MageControl.ModuleSystem.registerModule("OptionsManager", OptionsManager)

-- Backward compatibility
OptionsManager.showOptionsMenu = function()
    OptionsManager.toggle()
end

-- Global backward compatibility for MC.showOptionsMenu
MC.showOptionsMenu = function()
    OptionsManager.toggle()
end

-- Export for other modules
MageControl.UI.Options.OptionsManager = OptionsManager
