-- FremeAch.lua (modified - full file)
local addonName, addon = ...

---------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------
local TREE_ID = 1161
local FINAL_NODE_ID = 108700

local ROWS = {
    { id = 1, name = "Nature", root = 108114 },
    { id = 2, name = "Fel",    root = 108113 },
    { id = 3, name = "Arcane", root = 108111 },
    { id = 4, name = "Storm",  root = 108112 },
    { id = 5, name = "Holy",   root = 108875 },
}

---------------------------------------------------------
-- INTERNAL ROOT-SWITCH LOGIC
---------------------------------------------------------

local SwitchCache = {
    cached_config = nil,
    base_path = nil,
    rows = {},
}

local function get_config_id()
    return C_Traits.GetConfigIDByTreeID(TREE_ID)
end

local function purchase_node_fully(config_id, node_id)
    local node_info = C_Traits.GetNodeInfo(config_id, node_id)
    if not node_info then return false end

    if #node_info.entryIDs > 1 then
        local entry_id = node_info.entryIDs[1]
        local ok = C_Traits.SetSelection(config_id, node_id, entry_id)
        local entry_info = C_Traits.GetEntryInfo(config_id, entry_id)
        for _ = 1, (entry_info and entry_info.maxRanks or 1) - 1 do
            ok = C_Traits.PurchaseRank(config_id, node_id)
            if not ok then return false end
        end
        return ok and true or false
    else
        for _ = 1, (node_info.maxRanks or 1) do
            local ok = C_Traits.PurchaseRank(config_id, node_id)
            if not ok then return false end
        end
        return true
    end
end

local function build_path(config_id, tree_id, stop_at_node_set, root_override)
    if not config_id then return nil end
    local tree_info = C_Traits.GetTreeInfo(config_id, tree_id)
    if not tree_info then return nil end
    local root_node_id = root_override or tree_info.rootNodeID
    if not root_node_id then return nil end

    local available = { root_node_id }
    local in_path = {}
    local visited = { [root_node_id] = true }

    local function cheapest(nodes)
        local cheapest_cost = math.huge
        local cheapest_node, cheapest_index
        for idx, node_id in ipairs(nodes) do
            local cost = C_Traits.GetNodeCost(config_id, node_id)
            local amount = (cost and cost[1] and cost[1].amount) or 0
            if amount < cheapest_cost then
                cheapest_cost = amount
                cheapest_node = node_id
                cheapest_index = idx
            end
        end
        return cheapest_node, cheapest_index
    end

    while #available > 0 do
        local next_node, next_index = cheapest(available)
        if not next_node then break end
        table.insert(in_path, next_node)
        table.remove(available, next_index)
        visited[next_node] = true

        local node_info = C_Traits.GetNodeInfo(config_id, next_node)
        if not node_info then break end
        for _, edge in ipairs(node_info.visibleEdges or {}) do
            local target = edge.targetNode
            if (not visited[target]) and (not (stop_at_node_set and stop_at_node_set[target])) then
                table.insert(available, target)
                visited[target] = true
            end
        end
    end

    return in_path
end

local function purchase_path(config_id, tree_id, nodes)
    if not nodes then return end
    local tries = 0
    local max_tries = (#nodes * 3) + 10
    while true do
        for i = #nodes, 1, -1 do
            local node_id = nodes[i]
            local info = C_Traits.GetNodeInfo(config_id, node_id)
            if info and info.ranksPurchased >= info.maxRanks then
                table.remove(nodes, i)
            else
                local ok = purchase_node_fully(config_id, node_id)
                if ok then
                    table.remove(nodes, i)
                end
            end
        end
        if #nodes == 0 then return end
        if tries >= max_tries then return end
        tries = tries + 1
    end
end

local function rebuild_paths_if_needed(config_id)
    if not config_id then return end
    if SwitchCache.cached_config == config_id then return end

    local stop_at = {}
    for _, row in ipairs(ROWS) do
        stop_at[row.root] = true
    end

    SwitchCache.base_path = build_path(config_id, TREE_ID, stop_at, nil) or {}
    SwitchCache.rows = {}
    for _, row in ipairs(ROWS) do
        SwitchCache.rows[row.id] = build_path(config_id, TREE_ID, nil, row.root) or {}
    end

    SwitchCache.cached_config = config_id
end

local function switch_to_root(row_id)
    local config_id = get_config_id()
    if not config_id then return end

    rebuild_paths_if_needed(config_id)

    local selected = nil
    for _, r in ipairs(ROWS) do
        if r.id == row_id then selected = r break end
    end
    if not selected then return end

    C_Traits.ResetTree(config_id, TREE_ID)

    if SwitchCache.base_path and #SwitchCache.base_path > 0 then
        purchase_path(config_id, TREE_ID, { unpack(SwitchCache.base_path) })
        purchase_path(config_id, TREE_ID, { unpack(SwitchCache.base_path) })
    end

    local path = SwitchCache.rows[row_id]
    if not path or #path == 0 then
        path = build_path(config_id, TREE_ID, nil, selected.root) or {}
        if #path == 0 then return end
    end

    C_Traits.TryPurchaseToNode(config_id, path[#path])
    C_Traits.TryPurchaseAllRanks(config_id, FINAL_NODE_ID)
    C_Traits.CommitConfig(config_id)
end

---------------------------------------------------------
-- MAIN BUTTON
---------------------------------------------------------
local remixButton = CreateFrame("Button", "RemixButton", UIParent, "UIPanelButtonTemplate")
remixButton:SetSize(80, 22)
remixButton:SetText("Remix")
remixButton:SetPoint("CENTER")
remixButton:RegisterForDrag("LeftButton")
remixButton:SetMovable(true)
remixButton:SetUserPlaced(true)
remixButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
remixButton:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

---------------------------------------------------------
-- MAIN FRAME
---------------------------------------------------------
local mainFrame = CreateFrame("Frame", "RemixFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(400, 600)
mainFrame:SetPoint("CENTER")
mainFrame:Hide()
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetMovable(true)
mainFrame:SetUserPlaced(true)
mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

---------------------------------------------------------
-- SIMPLE LABEL
---------------------------------------------------------
local contentFrame = CreateFrame("Frame", nil, mainFrame)
contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -30)
contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", contentFrame, "TOP", 0, -20)
title:SetText("")

local statusText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statusText:SetPoint("TOP", title, "BOTTOM", 0, -15)
statusText:SetText("")

---------------------------------------------------------
-- TOGGLE
---------------------------------------------------------
remixButton:SetScript("OnClick", function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end)

---------------------------------------------------------
-- ROOT BUTTONS (OPTIMIZED, LOW-LOAD VERSION)
---------------------------------------------------------

local QUEST_ICON = "Interface\\AddOns\\ZamestoTV_Remix\\Icons\\qqt.tga"

local ROWS = {
    { id = 1, name = "Nature", root = 108114 },
    { id = 2, name = "Fel", root = 108113 },
    { id = 3, name = "Arcane", root = 108111 },
    { id = 4, name = "Storm", root = 108112 },
    { id = 5, name = "Holy", root = 108875 },
}

local QUEST_ROOT_MAP = {
    [90115] = 108114, -- Nature
    [92439] = 108113, -- Fel
    [92440] = 108111, -- Arcane
    [92441] = 108112, -- Storm
    [92442] = 108875, -- Holy
}

local buttonsByRoot = {}
local questCache = {}
local needsQuestUpdate, needsTraitUpdate = false, false

---------------------------------------------------------
-- Utilities
---------------------------------------------------------

local function PlayerHasQuest(questID)
    -- Cached lookup
    if questCache[questID] ~= nil then
        return questCache[questID]
    end

    if C_QuestLog.IsOnQuest(questID) then
        questCache[questID] = true
        return true
    end

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.questID == questID then
            questCache[questID] = true
            return true
        end
    end

    questCache[questID] = false
    return false
end

local function UpdateQuestIcons()
    local changed = false
    for questID, rootID in pairs(QUEST_ROOT_MAP) do
        local hasQuest = PlayerHasQuest(questID)
        local btn = buttonsByRoot[rootID]
        if btn then
            if hasQuest and not btn.icon:IsShown() then
                btn.icon:Show()
                changed = true
            elseif not hasQuest and btn.icon:IsShown() then
                btn.icon:Hide()
                changed = true
            end
        end
    end
    return changed
end

local function UpdateRootSelection()
    local config_id = C_Traits.GetConfigIDByTreeID(TREE_ID)
    if not config_id then return end

    for _, data in ipairs(ROWS) do
        local btn = buttonsByRoot[data.root]
        if btn then
            local node_info = C_Traits.GetNodeInfo(config_id, data.root)
            if node_info and node_info.ranksPurchased > 0 then
                btn:SetText("|cff00ff00" .. data.name .. "|r")
            else
                btn:SetText(data.name)
            end
        end
    end
end

---------------------------------------------------------
-- Buttons
---------------------------------------------------------

for i, data in ipairs(ROWS) do
    local btn = CreateFrame("Button", "RemixRootButton" .. i, mainFrame, "UIPanelButtonTemplate")
    btn:SetSize(100, 22)
    btn:SetText(data.name)
    btn:SetPoint("TOPRIGHT", mainFrame, "TOPLEFT", -5, -30 - (i - 1) * 30)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(18, 18)
    btn.icon:SetPoint("RIGHT", btn, "LEFT", -4, 0)
    btn.icon:SetTexture(QUEST_ICON)
    btn.icon:Hide()

    btn:SetScript("OnClick", function()
        switch_to_root(data.id)
        needsTraitUpdate = true
    end)

    buttonsByRoot[data.root] = btn
end

---------------------------------------------------------
-- Event Handling (lightweight)
---------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_REMOVED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "TRAIT_CONFIG_UPDATED" then
        needsTraitUpdate = true
    else
        -- Debounce quest updates (batch them)
        needsQuestUpdate = true
    end
end)

---------------------------------------------------------
-- Background updater (every 1s, very light)
---------------------------------------------------------

local ticker = C_Timer.NewTicker(1, function()
    if needsQuestUpdate then
        questCache = {} -- clear cache on change
        UpdateQuestIcons()
        needsQuestUpdate = false
    end

    if needsTraitUpdate then
        UpdateRootSelection()
        needsTraitUpdate = false
    end
end)

---------------------------------------------------------
-- Initial setup
---------------------------------------------------------

C_Timer.After(1.5, function()
    questCache = {}
    UpdateQuestIcons()
    UpdateRootSelection()
end)

---------------------------------------------------------
-- TABS
---------------------------------------------------------
local tabs = {}
local tabContent = {
    { name = "General", text = "" },
    { name = "Infinite Power", text = "" },
    { name = "Experience", text = "" },
    { name = "Cosmetics", text = "" },
    { name = "Feats", text = "" },
    { name = "Settings", text = "" },
}

---------------------------------------------------------
-- GENERAL TAB
---------------------------------------------------------
local generalTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
generalTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
generalTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
generalTitle:SetJustifyH("CENTER")
generalTitle:SetText("Infinite Knowledge")
generalTitle:Hide()

local generalDescription = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalDescription:SetPoint("TOP", generalTitle, "BOTTOM", 0, -10)
generalDescription:SetJustifyH("CENTER")
generalDescription:SetText("Coalesced essence of knowledge, drawn from another\ntimeline. Infinite Knowledge increases the amount of\nInfinite Power gained from most sources.")
generalDescription:Hide()

local generalCurrency = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalCurrency:SetPoint("TOP", generalDescription, "BOTTOM", 0, -10)
generalCurrency:SetJustifyH("CENTER")
generalCurrency:Hide()

local generalExperienceBonus = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
generalExperienceBonus:SetFont("Fonts\\FRIZQT__.TTF", 20)
generalExperienceBonus:SetPoint("TOP", generalCurrency, "BOTTOM", 0, -10)
generalExperienceBonus:SetJustifyH("CENTER")
generalExperienceBonus:SetText("Experience Bonus")
generalExperienceBonus:Hide()

local generalAchievementProgress = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
generalAchievementProgress:SetPoint("TOP", generalExperienceBonus, "BOTTOM", 0, -10)
generalAchievementProgress:SetJustifyH("CENTER")
generalAchievementProgress:Hide()

local generalPhasesTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
generalPhasesTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
generalPhasesTitle:SetPoint("TOP", generalAchievementProgress, "BOTTOM", 0, -10)
generalPhasesTitle:SetJustifyH("CENTER")
generalPhasesTitle:SetText("Phases")
generalPhasesTitle:Hide()

local phaseData = {
    { name = "Phase 1 - Launch", startDate = 1759891200 },
    { name = "Phase 2 - Rise of the Nightfallen", startDate = 1761091200 },
    { name = "Phase 3 - Legionfall", startDate = 1762291200 },
    { name = "Phase 4 - Argus Eternal", startDate = 1763491200 },
    { name = "Phase 5 - Infinite Echoes", startDate = 1765065600 }
}

local generalPhaseTexts = {}
for i = 1, 5 do
    local phaseText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phaseText:SetPoint("TOPLEFT", generalPhasesTitle, "BOTTOMLEFT", -155, -10 - (i - 1) * 22)
    phaseText:SetJustifyH("LEFT")
    phaseText:SetWidth(360)
    phaseText:Hide()
    generalPhaseTexts[i] = phaseText
end

---------------------------------------------------------
-- EXPERIENCE TAB
---------------------------------------------------------
local experienceTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
experienceTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
experienceTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
experienceTitle:SetJustifyH("CENTER")
experienceTitle:SetText("Experience Bonus")
experienceTitle:Hide()

local experienceDescription = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
experienceDescription:SetPoint("TOP", experienceTitle, "BOTTOM", 0, -10)
experienceDescription:SetJustifyH("CENTER")
experienceDescription:SetText("Experience Bonus applies to 'This perfect relic resonates with\nyour Warband, permanently increasing all experience gains\nin Legion Remix by 10%'.")
experienceDescription:Hide()

local sharedAchievements = {
    { id = 42586, name = "Campaign: Suramar" },
    { id = 42317, name = "Campaign: Azsuna" },
    { id = 42596, name = "Campaign: Stormheim" },
    { id = 42617, name = "Campaign: Val'Sharah" },
    { id = 42552, name = "Campaign: Highmountain" }
}

local experienceAchievementTitles = {}
local experienceLinkButtons = {}
for i, ach in ipairs(sharedAchievements) do
    local prev = i == 1 and experienceDescription or experienceAchievementTitles[i - 1]
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
    title:SetJustifyH("LEFT")
    title:SetWidth(300)
    title:Hide()
    experienceAchievementTitles[i] = title

    local linkBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    linkBtn:SetSize(60, 22)
    linkBtn:SetText("Link")
    linkBtn:SetPoint("LEFT", title, "RIGHT", 5, 0)
    linkBtn:SetScript("OnClick", function()
        if not AchievementFrame then AchievementFrame_LoadUI() end
        if AchievementFrame then OpenAchievementFrameToAchievement(ach.id) end
    end)
    linkBtn:Hide()
    experienceLinkButtons[i] = linkBtn
end

---------------------------------------------------------
-- COSMETICS TAB
---------------------------------------------------------
local cosmeticsTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cosmeticsTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
cosmeticsTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
cosmeticsTitle:SetJustifyH("CENTER")
cosmeticsTitle:SetText("Rewards in Retail WoW")
cosmeticsTitle:Hide()

local cosmeticsTitlesLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cosmeticsTitlesLabel:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -60)
cosmeticsTitlesLabel:SetJustifyH("LEFT")
cosmeticsTitlesLabel:SetText("Titles")
cosmeticsTitlesLabel:Hide()

local cosmeticsTransmogsLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cosmeticsTransmogsLabel:SetPoint("TOPLEFT", cosmeticsTitlesLabel, "BOTTOMLEFT", 0, -90)
cosmeticsTransmogsLabel:SetJustifyH("LEFT")
cosmeticsTransmogsLabel:SetText("Transmogs")
cosmeticsTransmogsLabel:Hide()

local cosmeticsAchievements = {
    { id = 42301, name = "Timerunner" },
    { id = 60935, name = "Tenured in the Timeways IV" },
    { id = 61079, name = "Heroic Legion Remix Raids" },
    { id = 42691, name = "Timeworn Keystone Enthusiast" },
    { id = 61078, name = "Mythic Legion Remix Raids" },
    { id = 61337, name = "To Fel and Back" },
    { id = 61070, name = "Heroic Broken Isles World Quests IV" },
    { id = 42690, name = "Timeworn Keystone Hero" },
    { id = 42605, name = "Suramar" },
    { id = 42630, name = "Val'Sharah" },
    { id = 42582, name = "Stormheim" },
    { id = 42666, name = "The Broken Shore PH3" },
    { id = 42549, name = "Argus" },
    { id = 42583, name = "Mythic: Antorus the Burning Throne" },
    { id = 42319, name = "Azsuna" },
    { id = 42541, name = "Highmountain" }
}

local cosmeticsAchievementTitles = {}
local cosmeticsLinkButtons = {}
for i, ach in ipairs(cosmeticsAchievements) do
    local prev
    if i == 1 then
        prev = cosmeticsTitlesLabel
    elseif i == 5 then
        prev = cosmeticsTransmogsLabel
    else
        prev = cosmeticsAchievementTitles[i - 1]
    end
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
    title:SetJustifyH("LEFT")
    title:SetWidth(300)
    title:Hide()
    cosmeticsAchievementTitles[i] = title

    local linkBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    linkBtn:SetSize(60, 22)
    linkBtn:SetText("Link")
    linkBtn:SetPoint("LEFT", title, "RIGHT", 5, 0)
    linkBtn:SetScript("OnClick", function()
        if not AchievementFrame then AchievementFrame_LoadUI() end
        if AchievementFrame then OpenAchievementFrameToAchievement(ach.id) end
    end)
    linkBtn:Hide()
    cosmeticsLinkButtons[i] = linkBtn
end

local cosmeticsPetsLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cosmeticsPetsLabel:SetPoint("TOPLEFT", cosmeticsAchievementTitles[14], "BOTTOMLEFT", 0, -10)
cosmeticsPetsLabel:SetJustifyH("LEFT")
cosmeticsPetsLabel:SetText("Pets")
cosmeticsPetsLabel:Hide()

for i = 15, #cosmeticsAchievements do
    cosmeticsAchievementTitles[i]:ClearAllPoints()
    cosmeticsAchievementTitles[i]:SetPoint("TOPLEFT", i == 15 and cosmeticsPetsLabel or cosmeticsAchievementTitles[i - 1], "BOTTOMLEFT", 0, -10)
end

---------------------------------------------------------
-- FEATS TAB
---------------------------------------------------------
local featsTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
featsTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
featsTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
featsTitle:SetJustifyH("CENTER")
featsTitle:SetText("Myth+ Portals")
featsTitle:Hide()

local featsDescription = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
featsDescription:SetPoint("TOP", featsTitle, "BOTTOM", 0, -10)
featsDescription:SetJustifyH("CENTER")
featsDescription:SetText("To get the achievements listed below,\ncomplete the Myth+ at level 20+.")
featsDescription:Hide()

local featsStrengthTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
featsStrengthTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
featsStrengthTitle:SetPoint("TOP", featsDescription, "BOTTOM", 0, -175)
featsStrengthTitle:SetJustifyH("CENTER")
featsStrengthTitle:SetText("Feats of Strength")
featsStrengthTitle:Hide()

local featsStrengthDescription = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
featsStrengthDescription:SetPoint("TOP", featsStrengthTitle, "BOTTOM", 0, -10)
featsStrengthDescription:SetJustifyH("CENTER")
featsStrengthDescription:SetText("Complete Myth+ at level 49+ or level up\nan artifact to level 999.")
featsStrengthDescription:Hide()

local featsUnknownDescription = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
featsUnknownDescription:SetPoint("TOP", featsStrengthDescription, "BOTTOM", 0, -60)
featsUnknownDescription:SetJustifyH("CENTER")
featsUnknownDescription:SetText("Unknown how to get the achievement.")
featsUnknownDescription:Hide()

local featsAchievements = {
    { id = 16659, name = "Keystone Hero: Halls of Valor" },
    { id = 17850, name = "Keystone Hero: Neltharion's Lair" },
    { id = 19084, name = "Keystone Hero: Black Rook Hold" },
    { id = 19085, name = "Keystone Hero: Darkheart Thicket" },
    { id = 16658, name = "Keystone Hero: Court of Stars" },
    { id = 15692, name = "Keystone Hero: Return to Karazhan" },
    { id = 61339, name = "Putting the Finite in Infinite" },
    { id = 42807, name = "Cloudy With a Chance of Infernals" }
}

local featsAchievementTitles = {}
local featsLinkButtons = {}

-- Group 1: 6 Myth+ achievements
for i = 1, 6 do
    local prev = i == 1 and featsDescription or featsAchievementTitles[i - 1]
    local title = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -110 - (i - 1) * 25)
    title:SetJustifyH("LEFT")
    title:SetWidth(300)
    title:Hide()
    featsAchievementTitles[i] = title

    local linkBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    linkBtn:SetSize(60, 22)
    linkBtn:SetText("Link")
    linkBtn:SetPoint("LEFT", title, "RIGHT", 5, 0)
    linkBtn:SetScript("OnClick", function()
        if not AchievementFrame then AchievementFrame_LoadUI() end
        if AchievementFrame then OpenAchievementFrameToAchievement(featsAchievements[i].id) end
    end)
    linkBtn:Hide()
    featsLinkButtons[i] = linkBtn
end

-- Group 2: "Putting the Finite in Infinite"
local title7 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title7:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -310)
title7:SetJustifyH("LEFT")
title7:SetWidth(300)
title7:Hide()
featsAchievementTitles[7] = title7

local linkBtn7 = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
linkBtn7:SetSize(60, 22)
linkBtn7:SetText("Link")
linkBtn7:SetPoint("LEFT", title7, "RIGHT", 5, 0)
linkBtn7:SetScript("OnClick", function()
    if not AchievementFrame then AchievementFrame_LoadUI() end
    if AchievementFrame then OpenAchievementFrameToAchievement(featsAchievements[7].id) end
end)
linkBtn7:Hide()
featsLinkButtons[7] = linkBtn7

-- Group 3: "Cloudy With a Chance of Infernals"
local title8 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title8:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -380)
title8:SetJustifyH("LEFT")
title8:SetWidth(300)
title8:Hide()
featsAchievementTitles[8] = title8

local linkBtn8 = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
linkBtn8:SetSize(60, 22)
linkBtn8:SetText("Link")
linkBtn8:SetPoint("LEFT", title8, "RIGHT", 5, 0)
linkBtn8:SetScript("OnClick", function()
    if not AchievementFrame then AchievementFrame_LoadUI() end
    if AchievementFrame then OpenAchievementFrameToAchievement(featsAchievements[8].id) end
end)
linkBtn8:Hide()
featsLinkButtons[8] = linkBtn8

---------------------------------------------------------
-- SETTINGS TAB
---------------------------------------------------------
local settingsTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
settingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
settingsTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
settingsTitle:SetJustifyH("CENTER")
settingsTitle:SetText("Settings")
settingsTitle:Hide()

local settingsDesc = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
settingsDesc:SetPoint("TOP", settingsTitle, "BOTTOM", 0, -10)
settingsDesc:SetJustifyH("CENTER")
settingsDesc:SetText("All addon settings.")
settingsDesc:Hide()

-- Auto-open chests
local autoChestLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoChestLabel:SetPoint("TOPLEFT", settingsDesc, "BOTTOMLEFT", -100, -30)
autoChestLabel:SetJustifyH("LEFT")
autoChestLabel:SetText("Auto-open chests")
autoChestLabel:Hide()

local autoChestBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
autoChestBtn:SetSize(60, 22)
autoChestBtn:SetPoint("LEFT", autoChestLabel, "RIGHT", 10, 0)
autoChestBtn:SetScript("OnClick", function()
    SlashCmdList["ZORR"]()
    autoChestBtn:SetText(openableScanEnabled and "On/Off" or "On/Off")
end)
autoChestBtn:Hide()

-- Bronze Tracker
local bronzeLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bronzeLabel:SetPoint("TOPLEFT", autoChestLabel, "BOTTOMLEFT", 0, -20)
bronzeLabel:SetJustifyH("LEFT")
bronzeLabel:SetText("Bronze Tracker")
bronzeLabel:Hide()

local bronzeBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
bronzeBtn:SetSize(60, 22)
bronzeBtn:SetPoint("LEFT", bronzeLabel, "RIGHT", 10, 0)
bronzeBtn:SetScript("OnClick", function()
    SlashCmdList["BRONZETRACKER"]()
end)
bronzeBtn:SetText("On/Off")
bronzeBtn:Hide()

---------------------------------------------------------
-- INFINITE POWER TAB
---------------------------------------------------------
local infinitePowerTitle = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
infinitePowerTitle:SetFont("Fonts\\FRIZQT__.TTF", 20)
infinitePowerTitle:SetPoint("TOP", contentFrame, "TOP", 0, -20)
infinitePowerTitle:SetJustifyH("CENTER")
infinitePowerTitle:SetText("How to Earn Infinite Knowledge")
infinitePowerTitle:Hide()

-- Infinite Power Content Frame
local infinitePowerContent = CreateFrame("Frame", nil, contentFrame)
infinitePowerContent:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -90)
infinitePowerContent:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", 0, 10)
infinitePowerContent:Hide()

-- Scroll Frame for Phase 1
local scrollFrame = CreateFrame("ScrollFrame", "RemixInfinitePowerScrollFrame", infinitePowerContent, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", infinitePowerContent, "TOPLEFT", 0, 0)
scrollFrame:SetPoint("BOTTOMRIGHT", infinitePowerContent, "BOTTOMRIGHT", -26, 0)
scrollFrame:Hide()

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(360, 832) -- 26 achievements * 32 pixels
scrollFrame:SetScrollChild(scrollChild)

-- Phase Buttons
local phaseButtons = {}
local phaseButtonLabels = { "P1", "P2", "P3", "P4" }
for i = 1, 4 do
    local btn = CreateFrame("Button", "RemixPhaseButton" .. i, contentFrame, "UIPanelButtonTemplate")
    btn:SetSize(40, 22)
    btn:SetText(phaseButtonLabels[i])
    btn:SetPoint("TOPLEFT", infinitePowerTitle, "BOTTOMLEFT", (i - 1) * 45, -10)
    btn:Hide()
    phaseButtons[i] = btn
end

-- Infinite Power Achievements
local infinitePowerAchievements = {
    -- Phase 1
    { id = 42314, name = "Unlimited Power" },
    { id = 42315, name = "Unlimited Power II" },
    { id = 42505, name = "Unlimited Power III" },
    { id = 42506, name = "Unlimited Power IV" },
    { id = 42507, name = "Unlimited Power V" },
    { id = 42508, name = "Unlimited Power VI" },
    { id = 42509, name = "Unlimited Power VII" },
    { id = 42510, name = "Unlimited Power VIII" },
    { id = 42511, name = "Unlimited Power IX" },
    { id = 42512, name = "Unlimited Power X" },
    { id = 42513, name = "Unlimited Power XI" },
    { id = 42514, name = "Unlimited Power XII" },
    { id = 61108, name = "Lorerunner of Azsuna" },
    { id = 61111, name = "Lorerunner of Val'Sharah" },
    { id = 61109, name = "Lorerunner of Highmountain" },
    { id = 61110, name = "Lorerunner of Stormheim" },
    { id = 61112, name = "Lorerunner of Suramar" },
    { id = 42555, name = "Broken Isles World Quests IV" },
    { id = 61053, name = "Legionslayer III" },
    { id = 61113, name = "Legion Dungeons: Threats of the Isle" },
    { id = 61114, name = "Legion Dungeons: Power of the Ancients" },
    { id = 61115, name = "Legion Dungeons: Might of the Legion" },
    { id = 42688, name = "Timeworn Keystone Adept" },
    { id = 61076, name = "Broken Isles World Bosses" },
    { id = 60859, name = "The Emerald Nightmare" },
    { id = 60860, name = "Trial of Valor" },
    { id = 61075, name = "Heroic Legion Remix Raider" },
    { id = 42313, name = "Remixing Time" },
    -- Phase 2
    { id = 42537, name = "Insurrection" },
    { id = 60854, name = "Heroic: Return to Karazhan" },
    { id = 60855, name = "Heroic: Return to Karazhan" },
    { id = 60865, name = "The Nighthold" },
    -- Phase 3
    { id = 60870, name = "Tomb of Sargeras" },
    { id = 42647, name = "Breaching the Tomb" },
    { id = 42673, name = "Defending the Broken Isles I" },
    { id = 42672, name = "Defending the Broken Isles II" },
    { id = 60850, name = "Heroic: Cathedral of Eternal Night" },
    { id = 61080, name = "Broken Shore World Bosses" },
    -- Phase 4
    { id = 42612, name = "You Are Now Prepared!" },
    { id = 42693, name = "Breaking the Legion I" },
    { id = 42696, name = "Greater Invasion Points I" },
    { id = 42697, name = "Greater Invasion Points II" },
    { id = 60852, name = "Heroic: Seat of the Triumvirate" },
    { id = 42320, name = "Legion Remix Dungeoneer" },
    { id = 61073, name = "Heroic Legion Remix Dungeoneer" },
    { id = 61074, name = "Mythic Legion Remix Dungeoneer" },
    { id = 60875, name = "Antorus, the Burning Throne" },
    { id = 61077, name = "Argus Invasion Point Bosses" },
}

local infinitePowerPhaseData = {
    { name = "Phase 1 - Skies of Fire 28/36", achievements = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28} },
    { name = "Phase 2 - Rise of the Nightfallen 32/36", achievements = {29,30,31,32} },
    { name = "Phase 3 - Legionfall 38/36", achievements = {33,34,35,36,37,38} },
    { name = "Phase 4 - Argus Eternal 48/36", achievements = {39,40,41,42,43,44,45,46,47,48} }
}

local infinitePowerPhaseLabels = {}
local infinitePowerAchievementTitles = {}
local infinitePowerLinkButtons = {}

for phaseIndex, phase in ipairs(infinitePowerPhaseData) do
    local parent = (phaseIndex == 1) and scrollChild or infinitePowerContent
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetText(phase.name)
    label:Hide()
    infinitePowerPhaseLabels[phaseIndex] = label

    infinitePowerAchievementTitles[phaseIndex] = {}
    infinitePowerLinkButtons[phaseIndex] = {}
    for i, achIndex in ipairs(phase.achievements) do
        local ach = infinitePowerAchievements[achIndex]
        local prevElement = i == 1 and infinitePowerPhaseLabels[phaseIndex] or infinitePowerAchievementTitles[phaseIndex][i - 1]
        local achTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        achTitle:SetPoint("TOPLEFT", prevElement, "BOTTOMLEFT", 0, -10)
        achTitle:SetJustifyH("LEFT")
        achTitle:SetWidth(300)
        achTitle:Hide()
        infinitePowerAchievementTitles[phaseIndex][i] = achTitle

        local linkBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        linkBtn:SetSize(60, 22)
        linkBtn:SetText("Link")
        if phaseIndex == 1 then
            linkBtn:SetPoint("TOPLEFT", achTitle, "TOPRIGHT", -6, 0)
        else
            linkBtn:SetPoint("TOPLEFT", achTitle, "TOPRIGHT", 5, 0)
        end
        linkBtn:SetScript("OnClick", function()
            if not AchievementFrame then AchievementFrame_LoadUI() end
            if AchievementFrame then OpenAchievementFrameToAchievement(ach.id) end
        end)
        linkBtn:Hide()
        infinitePowerLinkButtons[phaseIndex][i] = linkBtn
    end
end

local function ShowPhase(phaseIndex)
    for i = 1, 4 do
        local show = (i == phaseIndex)
        infinitePowerPhaseLabels[i]:SetShown(show)
        for _, title in ipairs(infinitePowerAchievementTitles[i]) do title:SetShown(show) end
        for _, btn in ipairs(infinitePowerLinkButtons[i]) do btn:SetShown(show) end
        phaseButtons[i]:SetEnabled(not show)
    end
    scrollFrame:SetShown(phaseIndex == 1)
end

for i, btn in ipairs(phaseButtons) do
    btn:SetScript("OnClick", function() ShowPhase(i) end)
end

---------------------------------------------------------
-- UPDATE FUNCTIONS
---------------------------------------------------------
local function UpdateCurrencyDisplay()
    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(3292)
    if currencyInfo then
        generalCurrency:SetText(currencyInfo.quantity .. "/" .. currencyInfo.maxQuantity)
    else
        generalCurrency:SetText("0/0")
    end
end

local function UpdateCosmeticsAchievementDisplay()
    for i, ach in ipairs(cosmeticsAchievements) do
        local title = cosmeticsAchievementTitles[i]
        local id, name, _, completed = GetAchievementInfo(ach.id)
        if name then
            title:SetText(name)
            if completed then title:SetTextColor(0, 1, 0) else title:SetTextColor(1, 0, 0) end
        else
            title:SetText(ach.name .. " (Unknown)")
            title:SetTextColor(1, 0, 0)
        end
    end
end

local function UpdateExperienceAchievementDisplay()
    for i, ach in ipairs(sharedAchievements) do
        local title = experienceAchievementTitles[i]
        local id, name, _, completed = GetAchievementInfo(ach.id)
        if name then
            title:SetText(name)
            if completed then title:SetTextColor(0, 1, 0) else title:SetTextColor(1, 0, 0) end
        else
            title:SetText(ach.name .. " (Unknown)")
            title:SetTextColor(1, 0, 0)
        end
    end
end

local function UpdateFeatsAchievementDisplay()
    for i, ach in ipairs(featsAchievements) do
        local title = featsAchievementTitles[i]
        local id, name, _, completed = GetAchievementInfo(ach.id)
        if name then
            title:SetText(name)
            if completed then title:SetTextColor(0, 1, 0) else title:SetTextColor(1, 0, 0) end
        else
            title:SetText(ach.name .. " (Unknown)")
            title:SetTextColor(1, 0, 0)
        end
    end
end

local function UpdateInfinitePowerAchievementDisplay()
    for phaseIndex, phase in ipairs(infinitePowerPhaseData) do
        for i, achIndex in ipairs(phase.achievements) do
            local title = infinitePowerAchievementTitles[phaseIndex][i]
            local ach = infinitePowerAchievements[achIndex]
            local id, name, _, completed = GetAchievementInfo(ach.id)
            if name then
                title:SetText(name)
                if completed then title:SetTextColor(0, 1, 0) else title:SetTextColor(1, 0, 0) end
            else
                title:SetText(ach.name .. " (Unknown)")
                title:SetTextColor(1, 0, 0)
            end
        end
    end
end

local function UpdateGeneralAchievementProgress()
    local completedCount = 0
    for _, ach in ipairs(sharedAchievements) do
        local _, _, _, completed = GetAchievementInfo(ach.id)
        if completed then completedCount = completedCount + 1 end
    end
    local percentage = completedCount * 10
    generalAchievementProgress:SetText(string.format("%d%%/50%%", percentage))
end

local function UpdatePhaseTimers()
    local currentTime = GetServerTime()
    local currentDate = math.floor(currentTime / 86400) * 86400
    for i, phase in ipairs(phaseData) do
        local days = math.max(0, math.ceil((phase.startDate - currentDate) / 86400))
        local status = days <= 0 and "|cff00ff00Available|r" or "|cffff0000" .. days .. " days|r"
        generalPhaseTexts[i]:SetText(phase.name .. ": " .. status)
    end
end

---------------------------------------------------------
-- TAB SWITCHING
---------------------------------------------------------
for i, tabInfo in ipairs(tabContent) do
    local tabButton = CreateFrame("Button", "RemixTab" .. i, mainFrame, "UIPanelButtonTemplate")
    tabButton:SetSize(80, 22)
    tabButton:SetText(tabInfo.name)
    tabButton:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, -30 - (i - 1) * 30)
    tabButton:SetScript("OnClick", function()
        -- Hide all
        generalTitle:Hide(); generalDescription:Hide(); generalCurrency:Hide(); generalExperienceBonus:Hide(); generalAchievementProgress:Hide(); generalPhasesTitle:Hide()
        for _, t in ipairs(generalPhaseTexts) do t:Hide() end
        experienceTitle:Hide(); experienceDescription:Hide()
        cosmeticsTitle:Hide(); cosmeticsTitlesLabel:Hide(); cosmeticsTransmogsLabel:Hide(); cosmeticsPetsLabel:Hide()
        featsTitle:Hide(); featsDescription:Hide(); featsStrengthTitle:Hide(); featsStrengthDescription:Hide(); featsUnknownDescription:Hide()
        infinitePowerTitle:Hide(); infinitePowerContent:Hide()
        for _, t in ipairs(cosmeticsAchievementTitles) do t:Hide() end
        for _, b in ipairs(cosmeticsLinkButtons) do b:Hide() end
        for _, t in ipairs(experienceAchievementTitles) do t:Hide() end
        for _, b in ipairs(experienceLinkButtons) do b:Hide() end
        for _, t in ipairs(featsAchievementTitles) do t:Hide() end
        for _, b in ipairs(featsLinkButtons) do b:Hide() end
        for j = 1, 4 do phaseButtons[j]:Hide(); infinitePowerPhaseLabels[j]:Hide(); for _, t in ipairs(infinitePowerAchievementTitles[j]) do t:Hide() end; for _, b in ipairs(infinitePowerLinkButtons[j]) do b:Hide() end end
        scrollFrame:Hide()
        settingsTitle:Hide(); settingsDesc:Hide(); autoChestLabel:Hide(); autoChestBtn:Hide(); bronzeLabel:Hide(); bronzeBtn:Hide()

        -- Show selected
        if i == 1 then
            generalTitle:Show(); generalDescription:Show(); generalCurrency:Show(); generalExperienceBonus:Show(); generalAchievementProgress:Show(); generalPhasesTitle:Show()
            for _, t in ipairs(generalPhaseTexts) do t:Show() end
            UpdateCurrencyDisplay(); UpdateGeneralAchievementProgress(); UpdatePhaseTimers()
        elseif i == 2 then
            infinitePowerTitle:Show(); infinitePowerContent:Show(); for j = 1, 4 do phaseButtons[j]:Show() end; ShowPhase(1); UpdateInfinitePowerAchievementDisplay()
        elseif i == 3 then
            experienceTitle:Show(); experienceDescription:Show()
            for _, t in ipairs(experienceAchievementTitles) do t:Show() end
            for _, b in ipairs(experienceLinkButtons) do b:Show() end
            UpdateExperienceAchievementDisplay()
        elseif i == 4 then
            cosmeticsTitle:Show(); cosmeticsTitlesLabel:Show(); cosmeticsTransmogsLabel:Show(); cosmeticsPetsLabel:Show()
            for _, t in ipairs(cosmeticsAchievementTitles) do t:Show() end
            for _, b in ipairs(cosmeticsLinkButtons) do b:Show() end
            UpdateCosmeticsAchievementDisplay()
        elseif i == 5 then
            featsTitle:Show(); featsDescription:Show(); featsStrengthTitle:Show(); featsStrengthDescription:Show(); featsUnknownDescription:Show()
            for _, t in ipairs(featsAchievementTitles) do t:Show() end
            for _, b in ipairs(featsLinkButtons) do b:Show() end
            UpdateFeatsAchievementDisplay()
        elseif i == 6 then
            settingsTitle:Show(); settingsDesc:Show(); autoChestLabel:Show(); autoChestBtn:Show(); autoChestBtn:SetText(openableScanEnabled and "On" or "Off"); bronzeLabel:Show(); bronzeBtn:Show()
        end

        for j, t in ipairs(tabs) do t:SetEnabled(j ~= i) end
    end)
    tabs[i] = tabButton
end
tabs[1]:SetEnabled(false)

---------------------------------------------------------
-- FRAME SHOW/HIDE LOGIC
---------------------------------------------------------
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        RemixButtonState = RemixButtonState or { isShown = true }
        remixButton:SetShown(RemixButtonState.isShown)
    elseif event == "CURRENCY_DISPLAY_UPDATE" and not tabs[1]:IsEnabled() then
        UpdateCurrencyDisplay()
    elseif event == "ACHIEVEMENT_EARNED" then
        if not tabs[3]:IsEnabled() then UpdateExperienceAchievementDisplay() end
        if not tabs[4]:IsEnabled() then UpdateCosmeticsAchievementDisplay() end
        if not tabs[5]:IsEnabled() then UpdateFeatsAchievementDisplay() end
        if not tabs[2]:IsEnabled() then UpdateInfinitePowerAchievementDisplay() end
        if not tabs[1]:IsEnabled() then UpdateGeneralAchievementProgress() end
    end
end)

mainFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
mainFrame:RegisterEvent("ACHIEVEMENT_EARNED")

mainFrame:SetScript("OnShow", function()
    if not tabs[1]:IsEnabled() then
        generalTitle:Show(); generalDescription:Show(); generalCurrency:Show(); generalExperienceBonus:Show(); generalAchievementProgress:Show(); generalPhasesTitle:Show()
        for _, t in ipairs(generalPhaseTexts) do t:Show() end
        UpdateCurrencyDisplay(); UpdateGeneralAchievementProgress(); UpdatePhaseTimers()
    elseif not tabs[2]:IsEnabled() then
        infinitePowerTitle:Show(); infinitePowerContent:Show(); for j = 1, 4 do phaseButtons[j]:Show() end; ShowPhase(1); UpdateInfinitePowerAchievementDisplay()
    elseif not tabs[3]:IsEnabled() then
        experienceTitle:Show(); experienceDescription:Show()
        for _, t in ipairs(experienceAchievementTitles) do t:Show() end
        for _, b in ipairs(experienceLinkButtons) do b:Show() end
        UpdateExperienceAchievementDisplay()
    elseif not tabs[4]:IsEnabled() then
        cosmeticsTitle:Show(); cosmeticsTitlesLabel:Show(); cosmeticsTransmogsLabel:Show(); cosmeticsPetsLabel:Show()
        for _, t in ipairs(cosmeticsAchievementTitles) do t:Show() end
        for _, b in ipairs(cosmeticsLinkButtons) do b:Show() end
        UpdateCosmeticsAchievementDisplay()
    elseif not tabs[5]:IsEnabled() then
        featsTitle:Show(); featsDescription:Show(); featsStrengthTitle:Show(); featsStrengthDescription:Show(); featsUnknownDescription:Show()
        for _, t in ipairs(featsAchievementTitles) do t:Show() end
        for _, b in ipairs(featsLinkButtons) do b:Show() end
        UpdateFeatsAchievementDisplay()
    elseif not tabs[6]:IsEnabled() then
        settingsTitle:Show(); settingsDesc:Show(); autoChestLabel:Show(); autoChestBtn:Show(); autoChestBtn:SetText(openableScanEnabled and "On" or "Off"); bronzeLabel:Show(); bronzeBtn:Show()
    end
end)

C_Timer.NewTicker(86400, UpdatePhaseTimers)

SLASH_REMIX1 = "/remix"
SlashCmdList["REMIX"] = function()
    if remixButton:IsShown() then
        remixButton:Hide()
        RemixButtonState.isShown = false
    else
        remixButton:Show()
        RemixButtonState.isShown = true
    end
end

---------------------------------------------------------
-- Event frame for quest icons and trait updates (separate)
---------------------------------------------------------
-- Create a dedicated event handler to ensure quest icons and selection are updated reliably
local rootEventFrame = CreateFrame("Frame")
rootEventFrame:RegisterEvent("QUEST_ACCEPTED")
rootEventFrame:RegisterEvent("QUEST_REMOVED")
rootEventFrame:RegisterEvent("QUEST_TURNED_IN")
rootEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
rootEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rootEventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
rootEventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "QUEST_ACCEPTED" then
        -- arg1 = questLogIndex? some clients provide index, arg2 can be questID on some clients. Defer a bit to allow the log to populate.
        C_Timer.After(0.5, UpdateQuestIcons)
    elseif event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" then
        C_Timer.After(0.5, UpdateQuestIcons)
    elseif event == "QUEST_LOG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.0, function()
            UpdateQuestIcons()
            UpdateRootSelection()
        end)
    elseif event == "TRAIT_CONFIG_UPDATED" then
        C_Timer.After(0.2, UpdateRootSelection)
    end
end)

-- Ensure initial update on load
C_Timer.After(1.5, function()
    UpdateQuestIcons()
    UpdateRootSelection()
end)
