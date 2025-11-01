local hideKnown = true
local filteredMerchantItems = {}

local function CreateToggleButton()
    if MerchantFrame.HideKnownButton then return end

    local btn = CreateFrame("Button", "HideKnownMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0)
    btn:SetSize(90, 22)
    btn:SetText("Hide Known")
    MerchantFrame.HideKnownButton = btn

    btn:SetScript("OnClick", function()
        hideKnown = not hideKnown
        btn:SetText(hideKnown and "Hide Known" or "Show All")
        MerchantFrame.page = 1
        MerchantFrame_Update()
    end)
end

local function IsItemKnown(link)
    if not link then return false end
    local itemID = GetItemInfoInstant(link)

    local spellName, spellID = GetItemSpell(link)
    if spellID and IsSpellKnown(spellID) then
        return true
    end

    if itemID and PlayerHasToy and PlayerHasToy(itemID) then
        return true
    end

    local tooltip = HKM_TooltipScanner or CreateFrame("GameTooltip", "HKM_TooltipScanner", UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(link)

    for i = 1, tooltip:NumLines() do
        local line = _G["HKM_TooltipScannerTextLeft"..i]
        if line then
            local text = line:GetText()
            if text and text:find(ITEM_SPELL_KNOWN) then
                return true
            end
        end
    end

    return false
end

local function BuildFilteredList()
    filteredMerchantItems = {}
    local totalItems = GetMerchantNumItems()

    for i = 1, totalItems do
        local link = GetMerchantItemLink(i)
        if not hideKnown or not IsItemKnown(link) then
            table.insert(filteredMerchantItems, i)
        end
    end
end

local function UpdateMerchantItemSlot(frame, merchantIndex)
    if not frame or not merchantIndex then return end

    local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(merchantIndex)
    local moneyFrame = _G[frame:GetName().."MoneyFrame"]
    local itemButton = _G[frame:GetName().."ItemButton"]

    if not name then
        frame:Hide()
        return
    end

    itemButton:SetID(merchantIndex)
    SetItemButtonTexture(itemButton, texture)
    SetItemButtonCount(itemButton, quantity)
    SetItemButtonStock(itemButton, numAvailable)

    _G[frame:GetName().."Name"]:SetText(name)
    MoneyFrame_Update(moneyFrame, price)
    frame.extendedCost = extendedCost
    frame:Show()
end

hooksecurefunc("MerchantFrame_Update", function()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    BuildFilteredList()

    local totalFiltered = #filteredMerchantItems
    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE
    local currentPage = MerchantFrame.page or 1
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, totalFiltered)

    if totalFiltered > itemsPerPage then
        MerchantPrevPageButton:Show()
        MerchantNextPageButton:Show()
    else
        MerchantPrevPageButton:Hide()
        MerchantNextPageButton:Hide()
    end

    MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, currentPage, math.max(1, math.ceil(totalFiltered / itemsPerPage)))

    for displaySlot = 1, itemsPerPage do
        local frame = _G["MerchantItem"..displaySlot]
        local index = filteredMerchantItems[startIndex + displaySlot - 1]

        if index then
            UpdateMerchantItemSlot(frame, index)
        else
            frame:Hide()
        end
    end
end)

MerchantFrame:HookScript("OnShow", CreateToggleButton)
