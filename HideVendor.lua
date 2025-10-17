local addonName = ...
local coreHandler = CreateFrame("Frame")
coreHandler:RegisterEvent("ADDON_LOADED")
coreHandler:RegisterEvent("MERCHANT_SHOW")

-- Initialize tooltip for item inspection
local inspectTip = CreateFrame("GameTooltip", "CullerTooltip", UIParent, "GameTooltipTemplate")
inspectTip:SetOwner(UIParent, "ANCHOR_NONE")

-- Define phrases indicating an item is already acquired
local acquiredPhrases = {
    _G.ITEM_SPELL_KNOWN, _G.ITEM_SPELL_KNOWN_S, _G.ITEM_SPELL_KNOWN_P,
    "Déjà connu", "Already known", "Already Known",
    "Bereits bekannt", "Ya conocido", "Già conosciuto",
    "Já conhecido", "Известно", "已收藏", "이미 배움"
}

-- Patterns for collected battle pets
local petAcquisitionPatterns = {
    "collecté%s*%(%d+/%d+%)", "collected%s*%(%d+/%d+%)",
    "bereits%s*gesammelt%s*%(%d+/%d+%)", "recogid[ao]%s*%(%d+/%d+%)",
    "raccolt[ao]%s*%(%d+/%d+%)", "coletad[ao]%s*%(%d+/%d+%)",
    "собран%s*%(%d+/%d+%)", "已收集%s*%(%d+/%d+%)", "수집%s*%(%d+/%d+%)"
}

-- Check if the player owns a toy
local function verifyToyOwnership(itemID)
    if PlayerHasToy then
        return PlayerHasToy(itemID)
    end
    return false
end

-- Verify if a pet is already collected
local function confirmPetOwnership(itemID)
    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local petID = select(13, C_PetJournal.GetPetInfoByItemID(itemID))
        if petID then
            local count = C_PetJournal.GetNumCollectedInfo(petID)
            return count and count > 0
        end
    end
    return false
end

-- Check if a transmog appearance is known
local function transmogKnown(itemID)
    if C_TransmogCollection and itemID then
        return C_TransmogCollection.PlayerHasTransmog(itemID)
    end
    return false
end

-- Inspect tooltip for acquisition status
local function examineTooltip(slot)
    inspectTip:ClearLines()
    inspectTip:SetMerchantItem(slot)
    local isAcquired = false
    local lineCount = inspectTip:NumLines()

    for i = 1, lineCount do
        local line = _G["CullerTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local lowered = text:lower()
                if not (lowered:match("vous collectionnez") or lowered:match("utiliser") or lowered:match("use:")) then
                    for _, phrase in pairs(acquiredPhrases) do
                        if phrase and lowered:find(phrase:lower()) then
                            isAcquired = true
                            break
                        end
                    end
                    if not isAcquired then
                        for _, pattern in pairs(petAcquisitionPatterns) do
                            if lowered:match(pattern) then
                                isAcquired = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return isAcquired
end

-- Determine if an item is already acquired
local function isItemAcquired(link, slot)
    if not link then return false end
    local itemID = select(1, GetItemInfoInstant(link))
    if not itemID then return false end
    return verifyToyOwnership(itemID) or confirmPetOwnership(itemID) or transmogKnown(itemID) or examineTooltip(slot)
end

-- Process merchant inventory display
local function manageMerchantDisplay()
    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10
    local currentPage = MerchantFrame and MerchantFrame.page or 1
    local totalItems = GetMerchantNumItems()
    local baseIndex = (currentPage - 1) * itemsPerPage
    local visibleItems = {}

    -- Collect indices of visible items for the current page only
    for i = baseIndex + 1, math.min(baseIndex + itemsPerPage, totalItems) do
        local itemLink = GetMerchantItemLink(i)
        if itemLink and (not isItemAcquired(itemLink, i) or ConfigStore.displayStyle == "show") then
            table.insert(visibleItems, i)
        end
    end

    -- Update merchant slots
    for slot = 1, itemsPerPage do
        local itemRow = _G["MerchantItem" .. slot]
        if itemRow then
            local itemIndex = visibleItems[slot]
            if itemIndex then
                itemRow:Show()
                -- Store the original item index to ensure proper rendering
                itemRow.itemIndex = itemIndex
            else
                itemRow:Hide()
            end
        end
    end
end

-- Delay execution until item data is cached
local isCheckingCache = false
local function waitForCache()
    if isCheckingCache then return end
    isCheckingCache = true
    local itemCount = GetMerchantNumItems()
    for i = 1, itemCount do
        if not GetMerchantItemLink(i) then
            C_Timer.After(0.2, function()
                isCheckingCache = false
                waitForCache()
            end)
            return
        end
    end
    isCheckingCache = false
    manageMerchantDisplay()
end

-- Hook into merchant frame updates
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
    if MerchantFrame and MerchantFrame:IsVisible() then
        C_Timer.After(0.1, waitForCache)
    end
end)

-- Create mode toggle button
local function setupToggleButton()
    if MerchantFrame.CullerToggle then return end
    local toggle = CreateFrame("Button", "CullerToggle", MerchantFrame, "UIPanelButtonTemplate")
    toggle:SetSize(80, 22)
    toggle:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 10, 3)
    toggle:SetText(ConfigStore.displayStyle == "hide" and "Show" or "Hide")

    toggle:SetScript("OnClick", function()
        ConfigStore.displayStyle = ConfigStore.displayStyle == "hide" and "show" or "hide"
        toggle:SetText(ConfigStore.displayStyle == "hide" and "Show" or "Hide")
        if MerchantFrame:IsVisible() then
            C_Timer.After(0.1, waitForCache)
        end
    end)

    MerchantFrame.CullerToggle = toggle
end

-- Handle addon events
coreHandler:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == addonName then
        ConfigStore = ConfigStore or { displayStyle = "hide" }
        setupToggleButton()
    elseif event == "MERCHANT_SHOW" then
        setupToggleButton()
        C_Timer.After(0.1, waitForCache)
    end
end)