local BronzeTracker = CreateFrame("Frame", "BronzeTrackerFrame", UIParent)

-- Initialize variables
local initialBronze = 0
local bronze = 0
local bronzeTimestamps = {}
local bronzeStartTime = 0
local bronzeBPH = 0
local sessionBronze = 0
local initialInfinitePower = 0
local infinitePower = 0
local infinitePowerTimestamps = {}
local infinitePowerStartTime = 0
local infinitePowerBPH = 0
local sessionInfinitePower = 0

-- Localization tables
local L = {
    enUS = {
        TOTAL_BRONZE = "Total Bronze: ",
        BRONZE_PER_HOUR = "Bronze per hour: ",
        BRONZE_THIS_SESSION = "Bronze this session: ",
        TOTAL_INFINITE_POWER = "Total Infinite Power: ",
        INFINITE_POWER_PER_HOUR = "Infinite Power per hour: ",
        INFINITE_POWER_THIS_SESSION = "Infinite Power this session: ",
        BRONZE_TRACKER = "Bronze & Infinite Power Tracker"
    },
    ruRU = {
        TOTAL_BRONZE = "Всего бронзы: ",
        BRONZE_PER_HOUR = "Бронзы в час: ",
        BRONZE_THIS_SESSION = "Бронзы за эту сессию: ",
        TOTAL_INFINITE_POWER = "Всего бесконечной силы: ",
        INFINITE_POWER_PER_HOUR = "Бесконечной силы в час: ",
        INFINITE_POWER_THIS_SESSION = "Бесконечной силы за эту сессию: ",
        BRONZE_TRACKER = "Отслеживание бронзы и бесконечной силы"
    },
    frFR = {
        TOTAL_BRONZE = "Bronze total: ",
        BRONZE_PER_HOUR = "Bronze par heure: ",
        BRONZE_THIS_SESSION = "Bronze cette session: ",
        TOTAL_INFINITE_POWER = "Puissance infinie totale: ",
        INFINITE_POWER_PER_HOUR = "Puissance infinie par heure: ",
        INFINITE_POWER_THIS_SESSION = "Puissance infinie cette session: ",
        BRONZE_TRACKER = "Suivi de bronze et puissance infinie"
    },
    deDE = {
        TOTAL_BRONZE = "Gesamtbronze: ",
        BRONZE_PER_HOUR = "Bronze pro Stunde: ",
        BRONZE_THIS_SESSION = "Bronze diese Sitzung: ",
        TOTAL_INFINITE_POWER = "Gesamte unendliche Kraft: ",
        INFINITE_POWER_PER_HOUR = "Unendliche Kraft pro Stunde: ",
        INFINITE_POWER_THIS_SESSION = "Unendliche Kraft diese Sitzung: ",
        BRONZE_TRACKER = "Bronze- und Unendliche-Kraft-Tracker"
    },
    esES = {
        TOTAL_BRONZE = "Bronce general: ",
        BRONZE_PER_HOUR = "Bronce por hora: ",
        BRONZE_THIS_SESSION = "Bronce esta sesión: ",
        TOTAL_INFINITE_POWER = "Poder infinito total: ",
        INFINITE_POWER_PER_HOUR = "Poder infinito por hora: ",
        INFINITE_POWER_THIS_SESSION = "Poder infinito esta sesión: ",
        BRONZE_TRACKER = "Rastreador de Bronce y Poder Infinito"
    },
    zhCN = {
        TOTAL_BRONZE = "Total bronze: ",
        BRONZE_PER_HOUR = "Bronze per hour: ",
        BRONZE_THIS_SESSION = "Bronze this session: ",
        TOTAL_INFINITE_POWER = "Total Infinite Power: ",
        INFINITE_POWER_PER_HOUR = "Infinite Power per hour: ",
        INFINITE_POWER_THIS_SESSION = "Infinite Power this session: ",
        BRONZE_TRACKER = "Bronze & Infinite Power Tracker"
    },
    zhTW = {
        TOTAL_BRONZE = "Total bronze: ",
        BRONZE_PER_HOUR = "Bronze per hour: ",
        BRONZE_THIS_SESSION = "Bronze this session: ",
        TOTAL_INFINITE_POWER = "Total Infinite Power: ",
        INFINITE_POWER_PER_HOUR = "Infinite Power per hour: ",
        INFINITE_POWER_THIS_SESSION = "Infinite Power this session: ",
        BRONZE_TRACKER = "Bronze & Infinite Power Tracker"
    },
    koKR = {
        TOTAL_BRONZE = "Total bronze: ",
        BRONZE_PER_HOUR = "Bronze per hour: ",
        BRONZE_THIS_SESSION = "Bronze this session: ",
        TOTAL_INFINITE_POWER = "Total Infinite Power: ",
        INFINITE_POWER_PER_HOUR = "Infinite Power per hour: ",
        INFINITE_POWER_THIS_SESSION = "Infinite Power this session: ",
        BRONZE_TRACKER = "Bronze & Infinite Power Tracker"
    }
}

-- Set the default language to English
local lang = GetLocale() -- Automatically sets to the game client locale

-- Function to set the language manually
local function SetLanguage(language)
    lang = language
end

-- Create a frame for displaying the information
local displayFrame = CreateFrame("Frame", "BronzeTrackerDisplay", UIParent, "BackdropTemplate")
displayFrame:SetSize(280, 155)
displayFrame:SetPoint("CENTER")
displayFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Make the frame draggable
displayFrame:SetMovable(true)
displayFrame:EnableMouse(true)
displayFrame:RegisterForDrag("LeftButton")
displayFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
displayFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save the position
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    BronzeTrackerDB.position = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end)

-- Create font strings for the display
local titleText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", 0, -10)
titleText:SetText(L[lang].BRONZE_TRACKER)

local totalBronzeText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
totalBronzeText:SetPoint("TOPLEFT", 10, -30)
totalBronzeText:SetText(L[lang].TOTAL_BRONZE .. "0")

local bronzeBPHText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bronzeBPHText:SetPoint("TOPLEFT", 10, -50)
bronzeBPHText:SetText(L[lang].BRONZE_PER_HOUR .. "0")

local sessionBronzeText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sessionBronzeText:SetPoint("TOPLEFT", 10, -70)
sessionBronzeText:SetText(L[lang].BRONZE_THIS_SESSION .. "0")

local totalInfinitePowerText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
totalInfinitePowerText:SetPoint("TOPLEFT", 10, -90)
totalInfinitePowerText:SetText(L[lang].TOTAL_INFINITE_POWER .. "0")

local infinitePowerBPHText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
infinitePowerBPHText:SetPoint("TOPLEFT", 10, -110)
infinitePowerBPHText:SetText(L[lang].INFINITE_POWER_PER_HOUR .. "0")

local sessionInfinitePowerText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sessionInfinitePowerText:SetPoint("TOPLEFT", 10, -130)
sessionInfinitePowerText:SetText(L[lang].INFINITE_POWER_THIS_SESSION .. "0")

-- Function to update the display
local function UpdateDisplay()
    totalBronzeText:SetText(L[lang].TOTAL_BRONZE .. bronze)
    bronzeBPHText:SetText(L[lang].BRONZE_PER_HOUR .. string.format("%.1f", bronzeBPH))
    sessionBronzeText:SetText(L[lang].BRONZE_THIS_SESSION .. sessionBronze)
    totalInfinitePowerText:SetText(L[lang].TOTAL_INFINITE_POWER .. infinitePower)
    infinitePowerBPHText:SetText(L[lang].INFINITE_POWER_PER_HOUR .. string.format("%.1f", infinitePowerBPH))
    sessionInfinitePowerText:SetText(L[lang].INFINITE_POWER_THIS_SESSION .. sessionInfinitePower)
end

-- OnUpdate script to update the display regularly
displayFrame:SetScript("OnUpdate", function(self, elapsed)
    UpdateDisplay()
end)

-- Function to initialize variables
local function Initialize()
    local bronzeInfo = C_CurrencyInfo.GetCurrencyInfo(3252)
    local infinitePowerInfo = C_CurrencyInfo.GetCurrencyInfo(3268)
    
    if bronzeInfo then
        initialBronze = bronzeInfo.quantity
        bronze = initialBronze
        bronzeTimestamps = {}
        bronzeStartTime = GetTime()
        bronzeBPH = 0
        sessionBronze = 0
    end
    
    if infinitePowerInfo then
        initialInfinitePower = infinitePowerInfo.quantity
        infinitePower = initialInfinitePower
        infinitePowerTimestamps = {}
        infinitePowerStartTime = GetTime()
        infinitePowerBPH = 0
        sessionInfinitePower = 0
    end

    -- Load saved variables
    if not BronzeTrackerDB then
        BronzeTrackerDB = {}
    end

    if BronzeTrackerDB.position then
        displayFrame:ClearAllPoints()
        displayFrame:SetPoint(BronzeTrackerDB.position.point, UIParent, BronzeTrackerDB.position.relativePoint, BronzeTrackerDB.position.xOfs, BronzeTrackerDB.position.yOfs)
    end

    if BronzeTrackerDB.isShown == nil then
        BronzeTrackerDB.isShown = true
    end

    if BronzeTrackerDB.isShown then
        displayFrame:Show()
    else
        displayFrame:Hide()
    end
end

-- Function to update currencies
local function UpdateCurrencies()
    local bronzeInfo = C_CurrencyInfo.GetCurrencyInfo(3252)
    local infinitePowerInfo = C_CurrencyInfo.GetCurrencyInfo(3268)
    
    -- Update Bronze
    if bronzeInfo then
        bronze = bronzeInfo.quantity
        sessionBronze = bronze - initialBronze

        if bronze == initialBronze then
            bronzeBPH = 0
        else
            local currentTime = GetTime()
            table.insert(bronzeTimestamps, currentTime)

            local cutoffTime = currentTime - 300
            while bronzeTimestamps[1] and bronzeTimestamps[1] < cutoffTime do
                table.remove(bronzeTimestamps, 1)
            end

            local threadCount = bronze - initialBronze
            local elapsedMinutes = (currentTime - bronzeStartTime) / 60
            local elapsedHours = elapsedMinutes / 60

            if elapsedHours > 0 then
                bronzeBPH = threadCount / elapsedHours
            else
                bronzeBPH = 0
            end
        end
    end
    
    -- Update Infinite Power
    if infinitePowerInfo then
        infinitePower = infinitePowerInfo.quantity
        sessionInfinitePower = infinitePower - initialInfinitePower

        if infinitePower == initialInfinitePower then
            infinitePowerBPH = 0
        else
            local currentTime = GetTime()
            table.insert(infinitePowerTimestamps, currentTime)

            local cutoffTime = currentTime - 300
            while infinitePowerTimestamps[1] and infinitePowerTimestamps[1] < cutoffTime do
                table.remove(infinitePowerTimestamps, 1)
            end

            local powerCount = infinitePower - initialInfinitePower
            local elapsedMinutes = (currentTime - infinitePowerStartTime) / 60
            local elapsedHours = elapsedMinutes / 60

            if elapsedHours > 0 then
                infinitePowerBPH = powerCount / elapsedHours
            else
                infinitePowerBPH = 0
            end
        end
    end
end

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        UpdateCurrencies()
    end
end

-- Register events
BronzeTracker:RegisterEvent("PLAYER_LOGIN")
BronzeTracker:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
BronzeTracker:SetScript("OnEvent", OnEvent)

-- Function to toggle the visibility of the frame
local function ToggleBronzeTrackerFrame()
    if displayFrame:IsShown() then
        displayFrame:Hide()
        BronzeTrackerDB.isShown = false
    else
        displayFrame:Show()
        BronzeTrackerDB.isShown = true
    end
end

-- Register the slash command
SLASH_BRONZETRACKER1 = '/bronze'
SlashCmdList["BRONZETRACKER"] = ToggleBronzeTrackerFrame