local addonName, addon = ...
 
-- Create a function to add options to the Interface Options Addons panel
local function AddAddonOptions()
    
    -- Create Panel with unique frame name
    local panel = CreateFrame("Frame", "ZTVOptionsPanel", UIParent)
    
    -- Give it a more friendly display name
    panel.name = "ZamestoTV: Gold" 
 
    -- Create a checkbox for QuestCompletionFrame with unique name
    local completionCheckBox = CreateFrame("CheckButton", "ZTV_QuestCompletionFrameCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    completionCheckBox:SetPoint("TOPLEFT", 16, -16)
    completionCheckBox.Text:SetText("Enable Quest Completion Frame") -- Replace with your desired default text
    completionCheckBox.tooltipText = "Enable the Quest Completion Frame" -- Replace with your desired default tooltip text
 
    -- If QuestCompletionFrame is your own frame I would suggest giving it a unique name like adding ZTV_ infront like I did above
    completionCheckBox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        -- Handle the checkbox state change here
        if isChecked then
            -- Checkbox is checked, enable QuestCompletionFrame
            QuestCompletionFrame:Show()
        else
            -- Checkbox is unchecked, disable QuestCompletionFrame
            QuestCompletionFrame:Hide()
        end
    end)
 
    -- Create a checkbox for ZAMTimer777 frame
    local timerCheckBox = CreateFrame("CheckButton", "ZAMTimer777Checkbox", panel, "InterfaceOptionsCheckButtonTemplate")
    timerCheckBox:SetPoint("TOPLEFT", completionCheckBox, "BOTTOMLEFT", 0, -8)
    timerCheckBox.Text:SetText("Enable ZAMTimer777 Frame") -- Replace with your desired default text
    timerCheckBox.tooltipText = "Enable the ZAMTimer777 Frame" -- Replace with your desired default tooltip text
 
    timerCheckBox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        -- Handle the checkbox state change here
        if isChecked then
            -- Checkbox is checked, enable ZAMTimer777 frame
            ZAMTimer777:Show()
        else
            -- Checkbox is unchecked, disable ZAMTimer777 frame
            ZAMTimer777:Hide()
        end
    end)
 
    -- Add the panel to the Interface Options Addons category
    -- InterfaceOptions_AddCategory(panel)  -- this is the old way
    
    -- Use the new way to register this set up as a Canvas Layout ( which gives similar layout control back to the addon creator )
    -- Notice I have added this to the addon wide data table to ensure other files have access to this category value.
    -- Also notice that I have given the category a link to the addonName.  This should be what shows up on the list of addons.
    -- You MIGHT be able to use panel.name though
    addon.category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
    Settings.RegisterAddOnCategory(addon.category)
    -- Handle language localization
    local locale = GetLocale()
	    if locale == "ruRU" then
        -- Russian localization
        completionCheckBox.Text:SetText("Список Дел: Показать/скрыть")
        completionCheckBox.tooltipText = "Список Дел: Показать/скрыть"
        timerCheckBox.Text:SetText("Таймер: Показать/скрыть")
        timerCheckBox.tooltipText = "Таймер: Показать/скрыть"
        panel.name = "ZamestoTV: Gold"
    elseif locale == "enUS" then
        -- English localization
        completionCheckBox.Text:SetText("To Do List: Show/Hide")
        completionCheckBox.tooltipText = "To Do List: Show/Hide"
        timerCheckBox.Text:SetText("Timer: Show/Hide")
        timerCheckBox.tooltipText = "Timer: Show/Hide"
        panel.name = "ZamestoTV: Gold"
    end
end
 
-- Register the addon-specific options when the player logs in
local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    AddAddonOptions()
end)