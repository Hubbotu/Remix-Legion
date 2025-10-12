local ADDON_NAME = "ZamestoTV_Remix"

-- Map inventory types to equipment slots.
-- Note: Gloves are INVTYPE_HAND (singular) and the slot is INVSLOT_HAND (singular).
local EquipSlots = {
    INVTYPE_HEAD = {INVSLOT_HEAD},
    INVTYPE_NECK = {INVSLOT_NECK},
    INVTYPE_SHOULDER = {INVSLOT_SHOULDER},
    INVTYPE_BODY = {INVSLOT_BODY},
    INVTYPE_CHEST = {INVSLOT_CHEST},
    INVTYPE_ROBE = {INVSLOT_CHEST},
    INVTYPE_WAIST = {INVSLOT_WAIST},
    INVTYPE_LEGS = {INVSLOT_LEGS},
    INVTYPE_FEET = {INVSLOT_FEET},
    INVTYPE_WRIST = {INVSLOT_WRIST},
    INVTYPE_HAND = {INVSLOT_HAND},        -- ✅ Correct mapping for gloves
    -- Accept both just in case some API path returns HANDS on your client
    INVTYPE_HANDS = {INVSLOT_HAND},       -- ✅ Defensive alias
    INVTYPE_FINGER = {INVSLOT_FINGER1, INVSLOT_FINGER2},
    INVTYPE_TRINKET = {INVSLOT_TRINKET1, INVSLOT_TRINKET2},
    INVTYPE_CLOAK = {INVSLOT_BACK},
    INVTYPE_WEAPON = {INVSLOT_MAINHAND, INVSLOT_OFFHAND},
    INVTYPE_SHIELD = {INVSLOT_OFFHAND},
    INVTYPE_2HWEAPON = {INVSLOT_MAINHAND},
    INVTYPE_WEAPONMAINHAND = {INVSLOT_MAINHAND},
    INVTYPE_WEAPONOFFHAND = {INVSLOT_OFFHAND},
    INVTYPE_HOLDABLE = {INVSLOT_OFFHAND},
    INVTYPE_RANGED = {INVSLOT_RANGED},
    INVTYPE_THROWN = {INVSLOT_RANGED},
    INVTYPE_RANGEDRIGHT = {INVSLOT_RANGED},
    INVTYPE_TABARD = {INVSLOT_TABARD},
}

local function GetHighestIlvlInBag(invType)
    local highestIlvl = 0
    local highestItemLoc = nil

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if C_Item.DoesItemExist(itemLoc) then
                local item = Item:CreateFromItemLocation(itemLoc)
                local itemInvType = item:GetInventoryTypeName()
                if itemInvType and EquipSlots[itemInvType] and itemInvType == invType then
                    local ilvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
                    if ilvl > highestIlvl then
                        highestIlvl = ilvl
                        highestItemLoc = itemLoc
                    end
                end
            end
        end
    end

    return highestIlvl, highestItemLoc
end

local function IsHighestIlvlItem(bag, slot)
    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not C_Item.DoesItemExist(itemLoc) then
        return false
    end

    local bagIlvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
    local item = Item:CreateFromItemLocation(itemLoc)
    local invType = item:GetInventoryTypeName()
    if not invType then
        return false
    end

    local slots = EquipSlots[invType]
    if not slots or #slots == 0 then
        return false
    end

    -- Is this the highest ilvl item of this type in the bags?
    local highestIlvl, highestItemLoc = GetHighestIlvlInBag(invType)
    if not highestItemLoc or bagIlvl < highestIlvl then
        return false
    end
    local hBag, hSlot = highestItemLoc:GetBagAndSlot()
    if hBag ~= bag or hSlot ~= slot then
        return false
    end

    -- Compare against equipped items for the relevant slots
    local equippedIlvls = {}
    for _, eqSlot in ipairs(slots) do
        if type(eqSlot) == "number" then
            local eqLoc = ItemLocation:CreateFromEquipmentSlot(eqSlot)
            local eqIlvl = 0
            if C_Item.DoesItemExist(eqLoc) then
                eqIlvl = C_Item.GetCurrentItemLevel(eqLoc) or 0
            end
            table.insert(equippedIlvls, eqIlvl)
        end
    end

    if #equippedIlvls == 0 then
        -- If we couldn't resolve any equipment slots, don't show.
        return false
    end

    local minEquippedIlvl = math.min(unpack(equippedIlvls))
    return bagIlvl > minEquippedIlvl
end

local function EnsureOverlay(button)
    if not button.myCustomOverlay then
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\AddOns\\ZamestoTV_Remix\\Icons\\upp1.tga")
        tex:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        tex:SetSize(16, 16)
        button.myCustomOverlay = tex
    end
    return button.myCustomOverlay
end

local function UpdateOverlayForButton(button)
    local bag = button.GetBagID and button:GetBagID()
    local slot = button.GetID and button:GetID()
    if bag == nil or slot == nil then
        return
    end

    local show = IsHighestIlvlItem(bag, slot)

    -- No special-casing for gloves anymore. The logic above handles everything uniformly.
    local overlay = EnsureOverlay(button)
    overlay:SetShown(show)
end

local function UpdateAllBagButtons()
    for containerIndex = 0, NUM_BAG_SLOTS do
        local frame = (containerIndex == 0) and ContainerFrameCombinedBags or _G["ContainerFrame" .. (containerIndex + 1)]
        if frame and frame:IsShown() and frame.Items then
            for _, button in ipairs(frame.Items) do
                if button:IsShown() then
                    UpdateOverlayForButton(button)
                end
            end
        end
    end
end

local frame = CreateFrame("Frame", ADDON_NAME .. "_Frame")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_NEW_ITEMS_UPDATED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("BAG_OPEN")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ITEM_LOCKED")
frame:RegisterEvent("ITEM_UNLOCKED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ITEM_LOCKED" or event == "ITEM_UNLOCKED" then
        C_Timer.After(0.5, UpdateAllBagButtons) -- small delay to avoid flicker while dragging
    else
        UpdateAllBagButtons()
    end
end)

-- Hook into container frame generation
hooksecurefunc("ContainerFrame_GenerateFrame", function(contFrame)
    if contFrame and contFrame.Items then
        for _, button in ipairs(contFrame.Items) do
            if button:IsShown() then
                UpdateOverlayForButton(button)
            end
        end
    end
end)

-- Periodic fallback update
C_Timer.NewTicker(2, UpdateAllBagButtons)