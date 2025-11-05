local addonName = ...
KnownFilterDB = KnownFilterDB or { active = false }

local coreFrame = CreateFrame("Frame")
local controlBtn
local initialized = false
local markerCache = {}

------------------------------------------------------------
-- Utility helpers
------------------------------------------------------------
local function toLowerSafe(val)
    return type(val) == "string" and val:lower() or val
end

local function fetchMarker(btn)
    local name = btn and btn:GetName()
    if not name then return end

    if markerCache[name] then
        return markerCache[name]
    end

    local layer = CreateFrame("Frame", nil, btn)
    layer:SetAllPoints()
    layer:SetFrameLevel(btn:GetFrameLevel() + 2)

    local cross = layer:CreateLine()
    cross:SetColorTexture(1, 0, 0, 1)
    cross:SetThickness(3)
    cross:SetStartPoint("TOPLEFT", 4, -4)
    cross:SetEndPoint("BOTTOMRIGHT", -4, 4)

    local cross2 = layer:CreateLine()
    cross2:SetColorTexture(1, 0, 0, 1)
    cross2:SetThickness(3)
    cross2:SetStartPoint("BOTTOMLEFT", 4, 4)
    cross2:SetEndPoint("TOPRIGHT", -4, -4)

    layer.cross1 = cross
    layer.cross2 = cross2
    layer:Hide()
    markerCache[name] = layer
    return layer
end

------------------------------------------------------------
-- Known detection
------------------------------------------------------------
local knownPhrases = {
    "already known", "déjà connu", "bereits bekannt", "ya conocido",
    "già conosciuto", "já conhecido", "известно", "已收藏", "이미 배움"
}

local petPatterns = {
    "collected%s*%((%d+)%s*/%s*(%d+)%)",
    "collecté%s*%((%d+)%s*/%s*(%d+)%)",
    "bereits%s*%((%d+)%s*/%s*(%d+)%)",
    "已收集%s*%((%d+)%s*/%s*(%d+)%)",
    "수집%s*%((%d+)%s*/%s*(%d+)%)"
}

local function CheckIfKnown(link)
    if not link then return false end
    local itemID = C_Item.GetItemInfoInstant(link)
    if not itemID then return false end
    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end

    local tip = C_TooltipInfo.GetHyperlink(link)
    if not tip or not tip.lines then return nil end

    local known, uncollected, petCollected = false, false, false
    for _, ln in ipairs(tip.lines) do
        local text = ln.leftText and toLowerSafe(ln.leftText)
        if text then
            for _, phrase in ipairs(knownPhrases) do
                if text:find(phrase, 1, true) then
                    known = true
                    break
                end
            end
            for _, ptn in ipairs(petPatterns) do
                local have, total = text:match(ptn)
                if have and total and tonumber(have) > 0 and have == total then
                    petCollected = true
                end
            end
            if text:find("uncollected", 1, true)
            or text:find("not collected", 1, true)
            or text:find("unlearned", 1, true)
            or text:find("не собрано", 1, true)
            or text:find("未收集", 1, true)
            or text:find("수집 안 함", 1, true) then
                uncollected = true
            end
        end
    end

    return ((known or petCollected) and not uncollected) or false
end

------------------------------------------------------------
-- Refresh logic
------------------------------------------------------------
local retryFlag = false

local function UpdateMerchant()
    local enabled = KnownFilterDB.active
    local total = GetMerchantNumItems()
    local pending = false

    -- reset state
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local button = _G["MerchantItem"..i.."ItemButton"]
        local label = _G["MerchantItem"..i.."Name"]
        if label then label:SetTextColor(1, 1, 1) end
        if button then
            local mark = markerCache[button:GetName()]
            if mark then mark:Hide() end
        end
    end

    if not enabled then return end

    for i = 1, total do
        local link = GetMerchantItemLink(i)
        if link then
            local idx = i - (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE
            if idx >= 1 and idx <= MERCHANT_ITEMS_PER_PAGE then
                local known = CheckIfKnown(link)
                if known == nil then
                    pending = true
                elseif known then
                    local btn = _G["MerchantItem"..idx.."ItemButton"]
                    local txt = _G["MerchantItem"..idx.."Name"]
                    if txt then txt:SetTextColor(0.4, 1, 0.4) end
                    if btn then
                        local mk = fetchMarker(btn)
                        mk:Show()
                    end
                end
            end
        else
            pending = true
        end
    end

    if pending and not retryFlag then
        retryFlag = true
        C_Timer.After(0.3, function()
            retryFlag = false
            MerchantFrame_UpdateMerchantInfo()
        end)
    end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
    C_Timer.After(0.05, UpdateMerchant)
end)

------------------------------------------------------------
-- Toggle button
------------------------------------------------------------
local function BuildControl()
    if controlBtn then
        controlBtn:SetText(KnownFilterDB.active and "Hide Known" or "Show All")
        return
    end
    controlBtn = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
    controlBtn:SetSize(90, 22)
    controlBtn:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 10, 0)
    controlBtn:SetText(KnownFilterDB.active and "Hide Known" or "Show All")
    controlBtn:SetScript("OnClick", function()
        KnownFilterDB.active = not KnownFilterDB.active
        controlBtn:SetText(KnownFilterDB.active and "Hide Known" or "Show All")
        MerchantFrame_UpdateMerchantInfo()
    end)
end

------------------------------------------------------------
-- Tooltip enhancement
------------------------------------------------------------
local function EnhanceTooltip(tt)
    if type(tt.GetItem) ~= "function" then return end
    local _, link = tt:GetItem()
    if not link or not KnownFilterDB.active then return end
    if CheckIfKnown(link) then
        tt:AddLine("Hold Shift + Right-click to buy anyway", 0.7, 0.7, 0.7, true)
        tt:Show()
    end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, EnhanceTooltip)
else
    hooksecurefunc(GameTooltip, "SetHyperlink", EnhanceTooltip)
    hooksecurefunc(GameTooltip, "SetMerchantItem", EnhanceTooltip)
end

------------------------------------------------------------
-- Merchant button clicks
------------------------------------------------------------
local function HookClicks()
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local btn = _G["MerchantItem"..i.."ItemButton"]
        if btn and not btn.__KFHook then
            btn.__KFHook = true
            btn:HookScript("OnClick", function(self, button)
                if not KnownFilterDB.active then return end
                local txt = _G[self:GetParent():GetName().."Name"]
                if not txt then return end
                if IsShiftKeyDown() and button == "RightButton" then
                    UIErrorsFrame:AddMessage("Override purchase enabled", 0.5, 1, 0.5)
                    return
                end
                UIErrorsFrame:AddMessage("You already know this item", 1, 0, 0)
            end)
        end
    end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", HookClicks)

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("MERCHANT_SHOW")
coreFrame:SetScript("OnEvent", function(_, evt, arg)
    if evt == "ADDON_LOADED" and arg == addonName and not initialized then
        initialized = true
        BuildControl()
    elseif evt == "MERCHANT_SHOW" then
        BuildControl()
        C_Timer.After(0.05, function() MerchantFrame_UpdateMerchantInfo() end)
    end
end)
