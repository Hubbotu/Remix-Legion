local ADDON_NAME = "ZamestoTV_Remix"

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
    INVTYPE_HAND = {INVSLOT_HANDS},
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
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if C_Item.DoesItemExist(itemLoc) then
                local item = Item:CreateFromItemLocation(itemLoc)
                if item:GetInventoryTypeName() == invType then
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
    local slots = EquipSlots[invType]
    if not slots or #slots == 0 then
        return false
    end

    -- Check if this item has the highest ilvl for its inventory type in the bag
    local highestIlvl, highestItemLoc = GetHighestIlvlInBag(invType)
    if not highestItemLoc or bagIlvl < highestIlvl then
        return false
    end
    local hBag, hSlot = highestItemLoc:GetBagAndSlot()
    if hBag ~= bag or hSlot ~= slot then
        return false
    end

    -- Compare with equipped items
    local equippedIlvls = {}
    for _, eqSlot in ipairs(slots) do
        local eqLoc = ItemLocation:CreateFromEquipmentSlot(eqSlot)
        local eqIlvl = 0
        if C_Item.DoesItemExist(eqLoc) then
            eqIlvl = C_Item.GetCurrentItemLevel(eqLoc) or 0
        end
        table.insert(equippedIlvls, eqIlvl)
    end

    local minEquippedIlvl = math.min(unpack(equippedIlvls))
    return bagIlvl > minEquippedIlvl
end

local function UpdateOverlayForButton(button)
    local bag = button:GetBagID()
    local slot = button:GetID()
    if not bag or not slot then
        return
    end

    local show = IsHighestIlvlItem(bag, slot)

    if not button.myCustomOverlay then
        button.myCustomOverlay = button:CreateTexture(nil, "OVERLAY")
        button.myCustomOverlay:SetTexture("Interface\\AddOns\\ZamestoTV_Remix\\Icons\\portal.tga")
        button.myCustomOverlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.myCustomOverlay:SetSize(16, 16)
    end

    button.myCustomOverlay:SetShown(show)
end

local function UpdateAllBagButtons()
    for containerIndex = 0, NUM_BAG_SLOTS do
        local frame = containerIndex == 0 and ContainerFrameCombinedBags or _G["ContainerFrame" .. (containerIndex + 1)]
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
    if event == "BAG_UPDATE" or event == "BAG_NEW_ITEMS_UPDATED" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_OPEN" or event == "PLAYER_LOGIN" then
        UpdateAllBagButtons()
    elseif event == "ITEM_LOCKED" or event == "ITEM_UNLOCKED" then
        C_Timer.After(0.1, UpdateAllBagButtons)
    end
end)

-- Hook into container frame generation
hooksecurefunc("ContainerFrame_GenerateFrame", function(contFrame)
    if contFrame.Items then
        for _, button in ipairs(contFrame.Items) do
            if button:IsShown() then
                UpdateOverlayForButton(button)
            end
        end
    end
end)

-- Fallback timer to ensure updates for new items
C_Timer.NewTicker(1, UpdateAllBagButtons)