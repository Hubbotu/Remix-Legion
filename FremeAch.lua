local addonName, addon = ...

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
-- CONTENT FRAME
---------------------------------------------------------
local contentFrame = CreateFrame("Frame", nil, mainFrame)
contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -30)
contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

---------------------------------------------------------
-- TABS
---------------------------------------------------------
local tabs = {}
local tabContent = {
    { name = "General", text = "" },
    { name = "Infinite Power", text = "" },
    { name = "Experience", text = "" },
    { name = "Cosmetics", text = "" },
    { name = "Feats", text = "" }
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
-- FEATS TAB (flush to left edge horizontally)
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
-- Infinite Power Tab
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
    -- Phase 1 - Skies of Fire (1-27)
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
    -- Phase 2 - Rise of the Nightfallen (28-30)
    { id = 42537, name = "Insurrection" },
    { id = 60854, name = "Heroic: Return to Karazhan" },
    { id = 60865, name = "The Nighthold" },
    -- Phase 4 - Argus Eternal (31-35)
    { id = 60870, name = "Tomb of Sargeras" },
    { id = 42647, name = "Breaching the Tomb" },
    { id = 42673, name = "Defending the Broken Isles I" },
    { id = 42672, name = "Defending the Broken Isles II" },
    { id = 60850, name = "Heroic: Cathedral of Eternal Night" },
    -- Phase 3 - Legionfall (36-41)
    { id = 42612, name = "You Are Now Prepared!" },
    { id = 42693, name = "Breaking the Legion I" },
    { id = 42696, name = "Greater Invasion Points I" },
    { id = 42697, name = "Greater Invasion Points II" },
    { id = 42320, name = "Legion Remix Dungeoneer" },
    { id = 60852, name = "Heroic: Seat of the Triumvirate" },
    { id = 60875, name = "Antorus, the Burning Throne" },
    { id = 61077, name = "Argus Invasion Point Bosses" }
}

local infinitePowerPhaseData = {
    {
        name = "Phase 1 - Skies of Fire",
        achievements = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 }
    },
    {
        name = "Phase 2 - Rise of the Nightfallen",
        achievements = { 28, 29, 30 }
    },
    {
        name = "Phase 3 - Legionfall",
        achievements = { 36, 37, 38, 39, 40, 41, 42, }
    },
    {
        name = "Phase 4 - Argus Eternal",
        achievements = { 31, 32, 33, 34, 35 }
    }
}

local infinitePowerPhaseLabels = {}
local infinitePowerAchievementTitles = {}
local infinitePowerLinkButtons = {}

-- Create phase labels and achievements
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
        -- Adjust x offset for Phase 1 (Skies of Fire) to move 7 pixels left
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

-- Phase Button Logic
local function ShowPhase(phaseIndex)
    for i = 1, 4 do
        local show = (i == phaseIndex)
        infinitePowerPhaseLabels[i]:SetShown(show)
        for _, title in ipairs(infinitePowerAchievementTitles[i]) do
            title:SetShown(show)
        end
        for _, btn in ipairs(infinitePowerLinkButtons[i]) do
            btn:SetShown(show)
        end
        phaseButtons[i]:SetEnabled(not show)
    end
    scrollFrame:SetShown(phaseIndex == 1)
end

for i, btn in ipairs(phaseButtons) do
    btn:SetScript("OnClick", function() ShowPhase(i) end)
end

-- Update Functions
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
    -- Adjust current time to midnight EEST for consistent day counting
    local currentDate = math.floor(currentTime / 86400) * 86400
    for i, phase in ipairs(phaseData) do
        local days = math.max(0, math.ceil((phase.startDate - currentDate) / 86400))
        local status
        if days <= 0 then
            status = "|cff00ff00Available|r"
        else
            status = "|cffff0000" .. days .. " days|r"
        end
        generalPhaseTexts[i]:SetText(phase.name .. ": " .. status)
    end
end

-- Tab Switching
for i, tabInfo in ipairs(tabContent) do
    local tabButton = CreateFrame("Button", "RemixTab" .. i, mainFrame, "UIPanelButtonTemplate")
    tabButton:SetSize(80, 22)
    tabButton:SetText(tabInfo.name)
    tabButton:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 5, -30 - (i - 1) * 30)
    tabButton:SetScript("OnClick", function()
        -- Hide all tab content
        generalTitle:Hide()
        generalDescription:Hide()
        generalCurrency:Hide()
        generalExperienceBonus:Hide()
        generalAchievementProgress:Hide()
        generalPhasesTitle:Hide()
        for _, phaseText in ipairs(generalPhaseTexts) do phaseText:Hide() end
        experienceTitle:Hide()
        experienceDescription:Hide()
        cosmeticsTitle:Hide()
        cosmeticsTitlesLabel:Hide()
        cosmeticsTransmogsLabel:Hide()
        cosmeticsPetsLabel:Hide()
        featsTitle:Hide()
        featsDescription:Hide()
        featsStrengthTitle:Hide()
        featsStrengthDescription:Hide()
        featsUnknownDescription:Hide()
        infinitePowerTitle:Hide()
        infinitePowerContent:Hide()
        for _, title in ipairs(cosmeticsAchievementTitles) do title:Hide() end
        for _, btn in ipairs(cosmeticsLinkButtons) do btn:Hide() end
        for _, title in ipairs(experienceAchievementTitles) do title:Hide() end
        for _, btn in ipairs(experienceLinkButtons) do btn:Hide() end
        for _, title in ipairs(featsAchievementTitles) do title:Hide() end
        for _, btn in ipairs(featsLinkButtons) do btn:Hide() end
        for j = 1, 4 do
            phaseButtons[j]:Hide()
            infinitePowerPhaseLabels[j]:Hide()
            for _, title in ipairs(infinitePowerAchievementTitles[j]) do title:Hide() end
            for _, btn in ipairs(infinitePowerLinkButtons[j]) do btn:Hide() end
        end
        scrollFrame:Hide()

        -- Show selected tab content
        if i == 1 then -- General
            generalTitle:Show()
            generalDescription:Show()
            generalCurrency:Show()
            generalExperienceBonus:Show()
            generalAchievementProgress:Show()
            generalPhasesTitle:Show()
            for _, phaseText in ipairs(generalPhaseTexts) do phaseText:Show() end
            UpdateCurrencyDisplay()
            UpdateGeneralAchievementProgress()
            UpdatePhaseTimers()
        elseif i == 2 then -- Infinite Power
            infinitePowerTitle:Show()
            infinitePowerContent:Show()
            for j = 1, 4 do phaseButtons[j]:Show() end
            ShowPhase(1)
            UpdateInfinitePowerAchievementDisplay()
        elseif i == 3 then -- Experience
            experienceTitle:Show()
            experienceDescription:Show()
            for _, title in ipairs(experienceAchievementTitles) do title:Show() end
            for _, btn in ipairs(experienceLinkButtons) do btn:Show() end
            UpdateExperienceAchievementDisplay()
        elseif i == 4 then -- Cosmetics
            cosmeticsTitle:Show()
            cosmeticsTitlesLabel:Show()
            cosmeticsTransmogsLabel:Show()
            cosmeticsPetsLabel:Show()
            for _, title in ipairs(cosmeticsAchievementTitles) do title:Show() end
            for _, btn in ipairs(cosmeticsLinkButtons) do btn:Show() end
            UpdateCosmeticsAchievementDisplay()
        elseif i == 5 then -- Feats
            featsTitle:Show()
            featsDescription:Show()
            featsStrengthTitle:Show()
            featsStrengthDescription:Show()
            featsUnknownDescription:Show()
            for _, title in ipairs(featsAchievementTitles) do title:Show() end
            for _, btn in ipairs(featsLinkButtons) do btn:Show() end
            UpdateFeatsAchievementDisplay()
        end

        -- Update tab button states
        for j, t in ipairs(tabs) do t:SetEnabled(j ~= i) end
    end)
    tabs[i] = tabButton
end

tabs[1]:SetEnabled(false)

-- Frame Show/Hide Logic
remixButton:SetScript("OnClick", function()
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end)

-- SavedVariables and Slash Command
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
        generalTitle:Show()
        generalDescription:Show()
        generalCurrency:Show()
        generalExperienceBonus:Show()
        generalAchievementProgress:Show()
        generalPhasesTitle:Show()
        for _, phaseText in ipairs(generalPhaseTexts) do phaseText:Show() end
        UpdateCurrencyDisplay()
        UpdateGeneralAchievementProgress()
        UpdatePhaseTimers()
    elseif not tabs[3]:IsEnabled() then
        experienceTitle:Show()
        experienceDescription:Show()
        for _, title in ipairs(experienceAchievementTitles) do title:Show() end
        for _, btn in ipairs(experienceLinkButtons) do btn:Show() end
        UpdateExperienceAchievementDisplay()
    elseif not tabs[4]:IsEnabled() then
        cosmeticsTitle:Show()
        cosmeticsTitlesLabel:Show()
        cosmeticsTransmogsLabel:Show()
        cosmeticsPetsLabel:Show()
        for _, title in ipairs(cosmeticsAchievementTitles) do title:Show() end
        for _, btn in ipairs(cosmeticsLinkButtons) do btn:Show() end
        UpdateCosmeticsAchievementDisplay()
    elseif not tabs[5]:IsEnabled() then
        featsTitle:Show()
        featsDescription:Show()
        featsStrengthTitle:Show()
        featsStrengthDescription:Show()
        featsUnknownDescription:Show()
        for _, title in ipairs(featsAchievementTitles) do title:Show() end
        for _, btn in ipairs(featsLinkButtons) do btn:Show() end
        UpdateFeatsAchievementDisplay()
    elseif not tabs[2]:IsEnabled() then
        infinitePowerTitle:Show()
        infinitePowerContent:Show()
        for j = 1, 4 do phaseButtons[j]:Show() end
        ShowPhase(1)
        UpdateInfinitePowerAchievementDisplay()
    end
end)

-- Timer for Phase Updates
C_Timer.NewTicker(86400, UpdatePhaseTimers)

-- Slash Command
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