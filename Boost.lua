-- Create the main addon frame
local RemixAddon = CreateFrame("Frame", "RemixAddon", UIParent)

-- SavedVariables setup
RemixAddon_SavedVariables = RemixAddon_SavedVariables or {
    position = {
        point = "BOTTOM",
        relativeTo = "UIParent",
        relativePoint = "BOTTOM",
        x = 0,
        y = 150
    }
}

-- Toy data from your file
local Toys = {
    [1] = {
        itemId = 187898,
        name = "Scouting Map: True Cost of the Northrend Campaign",
        icon = 237387
    },
    [2] = {
        itemId = 140192,
        name = "Dalaran Hearthstone",
        icon = 1444943
    },
    [3] = {
        spell = 431280,
        name = "Warband Map to Everywhere All At Once",
        icon = 237387
    },
    -- Add more toys here as needed
}

-- Store all toy buttons
local toyButtons = {}
local isMoving = false

-- Create a container frame to hold all toy buttons
local toyContainer = CreateFrame("Frame", "RemixToyContainer", UIParent)
toyContainer:SetSize(200, 100)
toyContainer:SetMovable(true)
toyContainer:EnableMouse(true)
toyContainer:RegisterForDrag("LeftButton")
toyContainer:SetClampedToScreen(true)
toyContainer:Hide()

-- Function to save the current position
local function SavePosition()
    local point, relativeTo, relativePoint, x, y = toyContainer:GetPoint()
    local relativeToName = "UIParent" -- Default to UIParent
    
    if relativeTo and relativeTo.GetName then
        relativeToName = relativeTo:GetName() or "UIParent"
    end
    
    RemixAddon_SavedVariables.position = {
        point = point,
        relativeTo = relativeToName,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end

-- Function to load the saved position
local function LoadPosition()
    local pos = RemixAddon_SavedVariables.position
    if pos and pos.point then
        toyContainer:ClearAllPoints()
        local relativeTo = _G[pos.relativeTo] or UIParent
        toyContainer:SetPoint(pos.point, relativeTo, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position
        toyContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
    end
end

-- Function to create toy buttons
local function CreateToyButtons()
    local startX = -70 -- Start position for first button (centered for 3 buttons)
    
    for i, toyData in ipairs(Toys) do
        if not toyData or (not toyData.itemId and not toyData.spell) or not toyData.name then
            print("Error: Invalid toy data provided.")
            return
        end

        local buttonName = "RemixToyButton_" .. (toyData.itemId or toyData.spell)
        local toyButton = CreateFrame("Button", buttonName, toyContainer, "SecureActionButtonTemplate")
        toyButton:SetSize(64, 64) 
        toyButton:SetPoint("BOTTOM", toyContainer, "BOTTOM", startX + ((i-1) * 70), 0)
        toyButton:RegisterForClicks("AnyDown", "AnyUp")
        
        -- Set macro based on whether it's a toy or spell
        if toyData.itemId then
            toyButton:SetAttribute("type", "macro")
            toyButton:SetAttribute("macrotext", "/usetoy " .. toyData.name)
        elseif toyData.spell then
            toyButton:SetAttribute("type", "macro")
            toyButton:SetAttribute("macrotext", "/cast " .. toyData.name)
        end

        -- Create icon texture
        local icon = toyButton:CreateTexture(nil, "BACKGROUND")
        icon:SetAllPoints()
        
        -- Set texture - handle both icon IDs and file paths
        if type(toyData.icon) == "number" then
            -- It's a texture ID
            icon:SetTexture(toyData.icon)
        else
            -- It might be a file path, try to use it directly
            icon:SetTexture(toyData.icon)
        end
        
        -- Add border
        local border = toyButton:CreateTexture(nil, "BORDER")
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.7)
        border:SetPoint("CENTER", toyButton, "CENTER", 0, 1)
        border:SetSize(70, 70)

        -- Tooltip handling
        toyButton:SetScript("OnEnter", function(self)
            if not isMoving then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                if toyData.itemId then
                    GameTooltip:SetToyByItemID(toyData.itemId)
                elseif toyData.spell then
                    GameTooltip:SetSpellByID(toyData.spell)
                end
                GameTooltip:Show()
            end
        end)
        
        toyButton:SetScript("OnLeave", function(self)
            if not isMoving then
                GameTooltip:Hide()
            end
        end)

        -- Cooldown frame
        local cooldown = CreateFrame("Cooldown", nil, toyButton, "CooldownFrameTemplate")
        cooldown:SetAllPoints()

        -- Button text
        local text = toyButton:CreateFontString(nil, "OVERLAY")
        text:SetPoint("BOTTOM", toyButton, "TOP", 0, 5)
        text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        text:SetText(string.sub(toyData.name, 1, 8)) -- Shorter name for display
        text:SetTextColor(1, 1, 1, 1)
        
        toyButtons[i] = toyButton
    end
    
    -- Create a separate drag handle that doesn't interfere with button clicks
    local dragHandle = CreateFrame("Frame", nil, toyContainer)
    dragHandle:SetSize(200, 20)
    dragHandle:SetPoint("TOP", toyContainer, "TOP", 0, 10)
    dragHandle:SetMovable(true)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetAlpha(0.5) -- Make it semi-transparent
    
    -- Add visual indicator for the drag handle
    local handleTexture = dragHandle:CreateTexture(nil, "BACKGROUND")
    handleTexture:SetAllPoints()
    handleTexture:SetColorTexture(0.2, 0.2, 0.2, 0.7)
    
    local handleText = dragHandle:CreateFontString(nil, "OVERLAY")
    handleText:SetPoint("CENTER", dragHandle, "CENTER")
    handleText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    handleText:SetText("Drag to Move")
    handleText:SetTextColor(1, 1, 1, 1)
    
    -- Set up drag handling for the drag handle only
    dragHandle:SetScript("OnDragStart", function(self)
        isMoving = true
        toyContainer:StartMoving()
        GameTooltip:Hide()
    end)
    
    dragHandle:SetScript("OnDragStop", function(self)
        isMoving = false
        toyContainer:StopMovingOrSizing()
        SavePosition() -- Save position when dragging stops
    end)
    
    -- Make sure the container itself doesn't interfere with clicks
    toyContainer:EnableMouse(false)
    
    -- Load saved position
    LoadPosition()
end

-- Function to toggle all toy buttons visibility
local function ToggleToyButtons()
    if #toyButtons == 0 then
        CreateToyButtons()
    end

    if toyContainer:IsShown() then
        toyContainer:Hide()
    else
        toyContainer:Show()
    end
end

-- Function to reset container to default position
local function ResetButtonPositions()
    toyContainer:ClearAllPoints()
    toyContainer:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
    SavePosition() -- Save the reset position
    print("Toy buttons position reset")
end

-- Function to add the Remix button to Collections Journal
local function AddRemixButton()
    -- Check if CollectionsJournal exists
    if not CollectionsJournal then return end
    
    -- Create the Remix button
    local remixButton = CreateFrame("Button", "CollectionsJournalRemixButton", CollectionsJournal, "UIPanelButtonTemplate")
    remixButton:SetSize(100, 22)
    remixButton:SetPoint("TOPLEFT", CollectionsJournal, "TOPLEFT", 45, 20) -- Moved 20px right and 20px up
    remixButton:SetText("Remix")
    
    remixButton:SetScript("OnClick", ToggleToyButtons)
end

-- Event handling
RemixAddon:RegisterEvent("ADDON_LOADED")
RemixAddon:RegisterEvent("PLAYER_LOGIN")

RemixAddon:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ZamestoTV_ChatTranslator" then
        -- Addon loaded
        print("Remix Addon loaded")
    elseif event == "PLAYER_LOGIN" then
        -- Wait for UI to be fully loaded
        C_Timer.After(1, function()
            AddRemixButton()
            CreateToyButtons() -- Create but hide initially
        end)
    end
end)

-- Slash commands for easy access
SLASH_REMIX1 = "/remix"
SlashCmdList["REMIX"] = ToggleToyButtons

SLASH_REMIXRESET1 = "/remixreset"
SlashCmdList["REMIXRESET"] = ResetButtonPositions

print("Remix Addon initialized. Use /remix to toggle the toy buttons.")
print("Use the drag handle above the buttons to move them together. Use /remixreset to reset position.")
print("Position will be remembered between sessions.")