-- MageControl UI Framework
-- Provides reusable UI components and styling for consistent interface design

MC = MC or {}
MC.UI = MC.UI or {}
MC.UI.Framework = MC.UI.Framework or {}

-- Create the UIFramework module
local UIFramework = MageControl.createModule("UIFramework", {"Logger"})

-- Initialize the UI framework
UIFramework.initialize = function()
    UIFramework._initializeStyles()
    MC.Logger.debug("UI Framework initialized", "UIFramework")
end

-- UI Style Constants
UIFramework.STYLES = {
    -- Colors
    COLORS = {
        BACKGROUND = {0.1, 0.1, 0.1, 0.9},
        BORDER = {0.4, 0.4, 0.4, 1.0},
        TITLE = {0.9, 0.9, 0.3, 1.0},
        TEXT = {0.9, 0.9, 0.9, 1.0},
        TEXT_MUTED = {0.7, 0.7, 0.7, 1.0},
        BUTTON_NORMAL = {0.2, 0.2, 0.2, 0.8},
        BUTTON_HIGHLIGHT = {0.3, 0.3, 0.3, 1.0},
        BUTTON_PRESSED = {0.1, 0.1, 0.1, 1.0},
        TAB_ACTIVE = {0.3, 0.3, 0.3, 1.0},
        TAB_INACTIVE = {0.15, 0.15, 0.15, 0.8},
        SUCCESS = {0.2, 0.8, 0.2, 1.0},
        WARNING = {0.9, 0.7, 0.2, 1.0},
        ERROR = {0.9, 0.2, 0.2, 1.0}
    },
    
    -- Dimensions
    DIMENSIONS = {
        FRAME_WIDTH = 480,
        FRAME_HEIGHT = 520,
        TAB_WIDTH = 75,
        TAB_HEIGHT = 26,
        BUTTON_WIDTH = 85,
        BUTTON_HEIGHT = 26,
        SLIDER_WIDTH = 180,
        SLIDER_HEIGHT = 14,
        PADDING = 8,
        SPACING = 4
    },
    
    -- Fonts
    FONTS = {
        TITLE = "GameFontNormal",
        NORMAL = "GameFontNormalSmall",
        SMALL = "GameFontNormalSmall",
        HIGHLIGHT = "GameFontHighlight"
    }
}

-- Initialize default styles
UIFramework._initializeStyles = function()
    -- Create backdrop templates
    UIFramework.BACKDROPS = {
        FRAME = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        },
        
        BUTTON = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        },
        
        TAB = {
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        }
    }
end

-- Create a styled frame
UIFramework.createFrame = function(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent or UIParent)
    frame:SetWidth(width or UIFramework.STYLES.DIMENSIONS.FRAME_WIDTH)
    frame:SetHeight(height or UIFramework.STYLES.DIMENSIONS.FRAME_HEIGHT)
    
    -- Apply styling
    frame:SetBackdrop(UIFramework.BACKDROPS.FRAME)
    frame:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BACKGROUND))
    frame:SetBackdropBorderColor(unpack(UIFramework.STYLES.COLORS.BORDER))
    
    -- Make it movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    return frame
end

-- Create a styled button
UIFramework.createButton = function(parent, text, param3, param4)
    local button = CreateFrame("Button", nil, parent)
    
    -- Handle different parameter signatures
    local width, height, callback
    if type(param3) == "function" then
        -- Signature: createButton(parent, text, callback)
        callback = param3
        width = UIFramework.STYLES.DIMENSIONS.BUTTON_WIDTH
        height = UIFramework.STYLES.DIMENSIONS.BUTTON_HEIGHT
    elseif type(param3) == "number" then
        -- Signature: createButton(parent, text, width, height)
        width = param3
        height = param4 or UIFramework.STYLES.DIMENSIONS.BUTTON_HEIGHT
    else
        -- Default signature: createButton(parent, text)
        width = UIFramework.STYLES.DIMENSIONS.BUTTON_WIDTH
        height = UIFramework.STYLES.DIMENSIONS.BUTTON_HEIGHT
    end
    
    button:SetWidth(width)
    button:SetHeight(height)
    
    -- Apply styling
    button:SetBackdrop(UIFramework.BACKDROPS.BUTTON)
    button:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_NORMAL))
    button:SetBackdropBorderColor(unpack(UIFramework.STYLES.COLORS.BORDER))
    
    -- Text
    if text then
        -- In WoW 1.12.1, we need to create a FontString explicitly for button text
        local fontString = button:CreateFontString(nil, "OVERLAY", UIFramework.STYLES.FONTS.NORMAL)
        fontString:SetText(text)
        fontString:SetTextColor(unpack(UIFramework.STYLES.COLORS.TEXT))
        fontString:SetPoint("CENTER", button, "CENTER", 0, 0)
        button:SetFontString(fontString)
    end
    
    -- Hover effects
    button:SetScript("OnEnter", function()
        this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_HIGHLIGHT))
    end)
    button:SetScript("OnLeave", function()
        this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_NORMAL))
    end)
    button:SetScript("OnMouseDown", function()
        this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_PRESSED))
    end)
    button:SetScript("OnMouseUp", function()
        this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_HIGHLIGHT))
    end)
    
    -- Set callback if provided
    if callback then
        button:SetScript("OnClick", callback)
    end
    
    return button
end

-- Create a styled tab button
UIFramework.createTab = function(parent, text, width, height)
    local tab = UIFramework.createButton(parent, text, 
        width or UIFramework.STYLES.DIMENSIONS.TAB_WIDTH, 
        height or UIFramework.STYLES.DIMENSIONS.TAB_HEIGHT)
    
    -- Tab-specific styling
    tab.isActive = false
    tab.setActive = function(active)
        tab.isActive = active
        if active then
            tab:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.TAB_ACTIVE))
        else
            tab:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.TAB_INACTIVE))
        end
    end
    
    -- Override hover for tabs
    tab:SetScript("OnEnter", function()
        if not this.isActive then
            this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.BUTTON_HIGHLIGHT))
        end
    end)
    tab:SetScript("OnLeave", function()
        if this.isActive then
            this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.TAB_ACTIVE))
        else
            this:SetBackdropColor(unpack(UIFramework.STYLES.COLORS.TAB_INACTIVE))
        end
    end)
    
    -- Initialize as inactive
    tab.setActive(false)
    
    return tab
end

-- Create a styled slider
UIFramework.createSlider = function(parent, min, max, step, width, height)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetWidth(width or UIFramework.STYLES.DIMENSIONS.SLIDER_WIDTH)
    slider:SetHeight(height or UIFramework.STYLES.DIMENSIONS.SLIDER_HEIGHT)
    
    -- Slider styling
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 3, right = 3, top = 6, bottom = 6}
    })
    
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetOrientation("HORIZONTAL")  
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetValue(min or 0)
    
    return slider
end

-- Create styled text
UIFramework.createText = function(parent, text, font, color)
    local fontString = parent:CreateFontString(nil, "ARTWORK", font or UIFramework.STYLES.FONTS.NORMAL)
    if text then
        fontString:SetText(text)
    end
    if color then
        fontString:SetTextColor(unpack(color))
    else
        fontString:SetTextColor(unpack(UIFramework.STYLES.COLORS.TEXT))
    end
    return fontString
end

-- Create a title text
UIFramework.createTitle = function(parent, text)
    return UIFramework.createText(parent, text, UIFramework.STYLES.FONTS.TITLE, UIFramework.STYLES.COLORS.TITLE)
end

-- Create a close button
UIFramework.createCloseButton = function(parent)
    local closeButton = CreateFrame("Button", nil, parent)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, -5)
    
    -- Close button texture
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    
    return closeButton
end

-- Layout helpers
UIFramework.layoutVertical = function(parent, elements, startY, spacing)
    spacing = spacing or UIFramework.STYLES.DIMENSIONS.SPACING
    local currentY = startY or -UIFramework.STYLES.DIMENSIONS.PADDING
    
    for i, element in ipairs(elements) do
        element:SetPoint("TOP", parent, "TOP", 0, currentY)
        currentY = currentY - element:GetHeight() - spacing
    end
    
    return currentY
end

UIFramework.layoutHorizontal = function(parent, elements, startX, spacing)
    spacing = spacing or UIFramework.STYLES.DIMENSIONS.SPACING
    local currentX = startX or UIFramework.STYLES.DIMENSIONS.PADDING
    
    for i, element in ipairs(elements) do
        element:SetPoint("LEFT", parent, "LEFT", currentX, 0)
        currentX = currentX + element:GetWidth() + spacing
    end
    
    return currentX
end

-- Utility functions
UIFramework.centerElement = function(element, parent, offsetX, offsetY)
    element:SetPoint("CENTER", parent, "CENTER", offsetX or 0, offsetY or 0)
end

UIFramework.showTooltip = function(element, title, text)
    element:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1, 1, true)
        if text then
            GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true)
        end
        GameTooltip:Show()
    end)
    element:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Export UIFramework to MC namespace
MC.UI.Framework.UIFramework = UIFramework

-- Register the module
MC.ModuleSystem.registerModule("UIFramework", UIFramework)

-- Backward compatibility
MageControl = MageControl or {}
MageControl.UI = MageControl.UI or {}
MageControl.UI.Framework = MageControl.UI.Framework or {}
MageControl.UI.Framework.UIFramework = UIFramework
