local addonName, addon = ...

-- Initialize the addon's saved variables
BarrelsOfFunDB = BarrelsOfFunDB or {
    active = false,
    index = nil
}

-- Quest IDs for tracking
local BucketQuest = {
    [45068] = 1, -- Suramar
    [45069] = 1, -- Azsuna
    [45070] = 1, -- Val'sharah
    [45071] = 1, -- Highmountain
    [45072] = 1, -- Stormheim
}

-- Create the main addon frame
local frame = CreateFrame("Frame", "BarrelsOfFunFrame", UIParent)

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "QUEST_ACCEPTED" then
        local questID = ...
        local _, _, _, mapID = UnitPosition("player")
        if mapID == 1220 and BucketQuest[questID] and not BarrelsOfFunDB.active then
            BarrelsOfFunDB.active = true
            BarrelsOfFunDB.index = nil
        end
    elseif event == "QUEST_REMOVED" then
        local questID = ...
        if BarrelsOfFunDB.active and BucketQuest[questID] then
            BarrelsOfFunDB.active = false
            BarrelsOfFunDB.index = nil
        end
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unit, _, _, spellID = ...
        if unit == "player" and spellID == 230884 then
            BarrelsOfFunDB.index = BarrelsOfFunDB.index or 1
        end
    elseif event == "RAID_TARGET_UPDATE" then
        if BarrelsOfFunDB.active and BarrelsOfFunDB.index then
            BarrelsOfFunDB.index = BarrelsOfFunDB.index + 1
            if BarrelsOfFunDB.index > 8 then
                BarrelsOfFunDB.index = 1
            end
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if not BarrelsOfFunDB.active or not BarrelsOfFunDB.index then
            return
        end
        local guid = UnitGUID("mouseover")
        if not guid then
            return
        end
        local type, _, _, _, _, npcID = strsplit("-", guid)
        if type == "Creature" and npcID == "115947" and not GetRaidTargetIndex("mouseover") then
            SetRaidTarget("mouseover", BarrelsOfFunDB.index)
        end
    end
end

-- Register events
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("RAID_TARGET_UPDATE")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

-- Set the event handler
frame:SetScript("OnEvent", OnEvent)

-- Optional: Print a message when the addon loads
local function OnAddonLoaded(self, event, loadedAddon)
    if loadedAddon == addonName then
        print("|cFF00FF00Barrels o' Fun|r: Addon loaded successfully.")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, event, ...)
    else
        OnEvent(self, event, ...)
    end
end)