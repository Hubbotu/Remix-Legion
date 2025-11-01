-- Hideitems.lua
-- Fully persistent "Hide Known" toggle using SavedVariables
-- Works after reload, logout, full restart

local eventFrame = CreateFrame("Frame")
local hideKnown = true  -- Default
local filteredMerchantItems = {}
local isInitialized = false

-- === WAIT FOR SAVEDVARIABLES ===
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        -- Safely read saved state
        if type(HideKnownDB) == "table" and HideKnownDB.hide ~= nil then
            hideKnown = HideKnownDB.hide
        else
            hideKnown = true  -- First time: default
            HideKnownDB = { hide = true }  -- Initialize properly
        end
        isInitialized = true

        -- If merchant is open, update now
        if MerchantFrame and MerchantFrame:IsShown() then
            CreateToggleButton()
            MerchantFrame_Update()
        end
    end
end)

-- === CREATE TOGGLE BUTTON ===
local function CreateToggleButton()
    if MerchantFrame.HideKnownButton then
        MerchantFrame.HideKnownButton:SetText(hideKnown and "Hide Known" or "Show All")
        return
    end

    if not isInitialized then return end

    local btn = CreateFrame("Button", "HideKnownMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0)
    btn:SetSize(90, 22)
    btn:SetText(hideKnown and "Hide Known" or "Show All")
    MerchantFrame.HideKnownButton = btn

    btn:SetScript("OnClick", function()
        hideKnown = not hideKnown
        HideKnownDB.hide = hideKnown  -- This now SAVES correctly
        btn:SetText(hideKnown and "Hide Known" or "Show All")
        MerchantFrame.page = 1
        MerchantFrame_Update()
    end)
end

-- === ITEM KNOWN CHECK ===
local function IsItemKnown(link)
    if not link then return false end
    local itemID = GetItemInfoInstant(link)

    local _, spellID = GetItemSpell(link)
    if spellID and IsSpellKnown(spellID) then return true end

    if itemID and PlayerHasToy and PlayerHasToy(itemID) then return true end

    local tooltip = CreateFrame("GameTooltip", "HKM_TooltipScanner", UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(link)

    for i = 1, tooltip:NumLines() do
        local line = _G["HKM_TooltipScannerTextLeft" .. i]
        if line and line:GetText() and line:GetText():find(ITEM_SPELL_KNOWN) then
            return true
        end
    end
    return false
end

-- === FILTER LIST ===
local function BuildFilteredList()
    filteredMerchantItems = {}
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        if not hideKnown or not IsItemKnown(link) then
            table.insert(filteredMerchantItems, i)
        end
    end
end

-- === UPDATE ITEM SLOT ===
local function UpdateMerchantItemSlot(frame, index)
    if not frame or not index then return end
    local name, texture, price, quantity, numAvailable, _, extendedCost = GetMerchantItemInfo(index)
    if not name then frame:Hide(); return end

    local itemButton = _G[frame:GetName().."ItemButton"]
    itemButton:SetID(index)
    SetItemButtonTexture(itemButton, texture)
    SetItemButtonCount(itemButton, quantity)
    SetItemButtonStock(itemButton, numAvailable)
    _G[frame:GetName().."Name"]:SetText(name)
    MoneyFrame_Update(_G[frame:GetName().."MoneyFrame"], price)
    frame.extendedCost = extendedCost
    frame:Show()
end

-- === HOOK MERCHANT UPDATE ===
hooksecurefunc("MerchantFrame_Update", function()
    if not isInitialized or not MerchantFrame:IsShown() then return end

    BuildFilteredList()
    local total = #filteredMerchantItems
    local perPage = MERCHANT_ITEMS_PER_PAGE
    local page = MerchantFrame.page or 1
    local start = (page - 1) * perPage + 1

    local showPages = total > perPage
    MerchantPrevPageButton:SetShown(showPages)
    MerchantNextPageButton:SetShown(showPages)
    MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, page, math.max(1, math.ceil(total / perPage)))

    for slot = 1, perPage do
        local frame = _G["MerchantItem" .. slot]
        local index = filteredMerchantItems[start + slot - 1]
        if index then
            UpdateMerchantItemSlot(frame, index)
        else
            frame:Hide()
        end
    end
end)

-- === ON MERCHANT OPEN ===
MerchantFrame:HookScript("OnShow", function()
    if isInitialized then
        CreateToggleButton()
        MerchantFrame_Update()
    end
end)