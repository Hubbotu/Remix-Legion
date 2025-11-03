-- Hideitems.lua
-- Final: stable merchant "Hide Known" filter
-- Uses the same approach as LegionRemixHelper's MerchantUtils:
--  * Build filtered list of real merchant indices
--  * Populate merchant item slots with real indices using C_MerchantFrame.GetItemInfo
--  * Set itemButton:SetID(realIndex) so hover/purchase map correctly

local _G = _G
local tinsert = table.insert
local wipe = table.wipe

-- state
local eventFrame = CreateFrame("Frame")
local hideKnown = true
local filteredVendorItems = {}
local isInitialized = false
local knownCache = {}
local scanTooltip = nil

-- reusable tooltip scanner
local function GetScannerTooltip()
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "HKM_TooltipScanner", UIParent, "GameTooltipTemplate")
        scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return scanTooltip
end

-- cached "is item known" check
local function IsItemKnown(link)
    if not link then return false end
    local itemID = GetItemInfoInstant(link)
    if itemID and knownCache[itemID] ~= nil then
        return knownCache[itemID]
    end

    -- spells / toys quick checks
    local _, spellID = GetItemSpell(link)
    if spellID and IsSpellKnown(spellID) then
        if itemID then knownCache[itemID] = true end
        return true
    end
    if itemID and PlayerHasToy and PlayerHasToy(itemID) then
        knownCache[itemID] = true
        return true
    end

    -- tooltip fallback (search for "Already known" text)
    local tooltip = GetScannerTooltip()
    tooltip:ClearLines()
    tooltip:SetHyperlink(link)
    for i = 1, tooltip:NumLines() do
        local line = _G["HKM_TooltipScannerTextLeft" .. i]
        if line and line:GetText() and line:GetText():find(ITEM_SPELL_KNOWN) then
            if itemID then knownCache[itemID] = true end
            return true
        end
    end

    if itemID then knownCache[itemID] = false end
    return false
end

-- build filtered list (real merchant indices)
local function BuildFilteredList()
    wipe(filteredVendorItems)
    local total = GetMerchantNumItems() or 0
    if total <= 0 then return end

    for i = 1, total do
        local link = GetMerchantItemLink(i)
        if not hideKnown or (link and not IsItemKnown(link)) then
            tinsert(filteredVendorItems, i)
        end
    end
end

-- Helper: update per-slot visuals using the REAL merchant index
local function UpdateMerchantBtn(slotNum, realIndex)
    local merchantButton = _G["MerchantItem" .. slotNum]
    if not merchantButton then return end

    local itemNameFont = _G["MerchantItem" .. slotNum .. "Name"]
    local itemButton = _G["MerchantItem" .. slotNum .. "ItemButton"]
    local altCurrency = _G["MerchantItem" .. slotNum .. "AltCurrencyFrame"]

    -- clear slot (popItem behavior)
    itemNameFont:SetText("")
    if itemButton then
        itemButton:Hide()
        if itemButton.IconQuestTexture then itemButton.IconQuestTexture:Hide() end
    end
    if altCurrency then altCurrency:Hide() end
    SetItemButtonSlotVertexColor(merchantButton, 0.4, 0.4, 0.4)
    SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5)

    if not realIndex then
        -- nothing to show
        return
    end

    -- Use Blizzard API that returns current item data
    local item = C_MerchantFrame.GetItemInfo(realIndex)
    if not item or not item.name then
        return
    end

    -- Populate visuals from item info
    itemNameFont:SetText(item.name)
    SetItemButtonTexture(itemButton, item.texture)
    MerchantFrame_UpdateAltCurrency(realIndex, slotNum, CanAffordMerchantItem(realIndex))
    if altCurrency then altCurrency:Show() end

    local itemLink = GetMerchantItemLink(realIndex)
    MerchantFrameItem_UpdateQuality(merchantButton, itemLink)

    local merchantItemID = GetMerchantItemID(realIndex)
    local isHeirloom = merchantItemID and C_Heirloom and C_Heirloom.IsItemHeirloom and C_Heirloom.IsItemHeirloom(merchantItemID)
    local isKnownHeirloom = isHeirloom and C_Heirloom and C_Heirloom.PlayerHasHeirloom and C_Heirloom.PlayerHasHeirloom(merchantItemID)

    -- Important: set the button ID to the REAL merchant index so Blizzard's buy/tooltip logic maps correctly
    itemButton:SetID(realIndex)
    itemButton:Show()
    itemButton.link = itemLink
    itemButton.texture = item.texture

    if item.isQuestStartItem then
        itemButton.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
        itemButton.IconQuestTexture:Show()
    end

    -- tinting and desaturation (heirlooms / locked)
    if isKnownHeirloom then
        SetItemButtonDesaturated(itemButton, true)
        SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5)
        SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5)
        SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0.5, 0.5)
    elseif not item.isPurchasable then
        SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0)
        SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0)
        SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0)
    else
        SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0)
        SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
        SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
    end
end

-- update page display and populate slots using filteredVendorItems
local function UpdateMerchantDisplay()
    if not isInitialized or not MerchantFrame or not MerchantFrame:IsShown() then return end

    local size = MERCHANT_ITEMS_PER_PAGE
    local totalFiltered = #filteredVendorItems
    -- avoid zero total causing divide issues; treat as 0 pages but show page 1
    local pages = math.max(1, math.ceil((totalFiltered > 0 and totalFiltered or 1) / size))
    local page = MerchantFrame.page or 1
    if page > pages then page = pages end
    MerchantFrame.page = page

    MerchantPrevPageButton:SetShown(totalFiltered > size)
    MerchantNextPageButton:SetShown(totalFiltered > size)
    MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, page, pages)

    for i = 1, size do
        local index = (page - 1) * size + i
        local realIndex = filteredVendorItems[index]
        UpdateMerchantBtn(i, realIndex)
    end
end

-- hook into Blizzard's merchant update to run our display update after Blizzard runs
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
    -- We run our display update after Blizzard populates — this ensures we override visuals safely.
    if isInitialized and MerchantFrame and MerchantFrame:IsShown() and hideKnown then
        UpdateMerchantDisplay()
    end
end)

-- handle merchant open: (re)build filtered list
local function OnMerchantShow()
    knownCache = {} -- reset known cache each merchant open to reflect new acquisitions in-session
    BuildFilteredList()
    MerchantFrame.page = 1
    MerchantPrevPageButton:Disable()
    MerchantNextPageButton:Enable()
    UpdateMerchantDisplay()
end

-- create toggle button (persistent SavedVariables)
local function CreateToggleButton()
    if MerchantFrame.HideKnownButton then
        MerchantFrame.HideKnownButton:SetText(hideKnown and "Hide Known" or "Show All")
        return
    end

    local btn = CreateFrame("Button", "HideKnownMerchantButton", MerchantFrame, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0)
    btn:SetSize(90, 22)
    btn:SetText(hideKnown and "Hide Known" or "Show All")
    MerchantFrame.HideKnownButton = btn

    btn:SetScript("OnClick", function()
        hideKnown = not hideKnown
        HideKnownDB.hide = hideKnown
        btn:SetText(hideKnown and "Hide Known" or "Show All")
        -- rebuild list and refresh display immediately
        BuildFilteredList()
        MerchantFrame.page = 1
        UpdateMerchantDisplay()
    end)
end

-- events
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "VARIABLES_LOADED" then
        if type(HideKnownDB) == "table" and HideKnownDB.hide ~= nil then
            hideKnown = HideKnownDB.hide
        else
            hideKnown = true
            HideKnownDB = { hide = true }
        end
        isInitialized = true
    elseif event == "MERCHANT_SHOW" then
        if isInitialized then
            CreateToggleButton()
            OnMerchantShow()
        end
    end
end)

-- ensure a full redraw when merchant updates (page change etc)
hooksecurefunc("MerchantFrame_Update", function()
    if isInitialized and MerchantFrame and MerchantFrame:IsShown() and hideKnown then
        -- If the merchant data changed under us we might need to rebuild filtered list.
        -- Rebuild if filtered list size doesn't match underlying merchant count heuristics.
        -- This avoids stale lists if items are added/removed while window is open.
        local num = GetMerchantNumItems() or 0
        -- cheap heuristic: if all filtered indices are within current merchant range we keep; else rebuild
        local needRebuild = false
        for _, idx in ipairs(filteredVendorItems) do
            if idx > num or idx < 1 then
                needRebuild = true
                break
            end
        end
        if needRebuild then
            BuildFilteredList()
        end
        UpdateMerchantDisplay()
    end
end)
