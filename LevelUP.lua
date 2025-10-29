local ADDON_NAME = "ZamestoTV_Remix"

-- Map inventory types to equipment slots.
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
    INVTYPE_HAND = {INVSLOT_HAND},
    INVTYPE_HANDS = {INVSLOT_HAND},
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

-----------------------------------------------------------
-- PERFORMANCE: cache highest ilvls per inventory type
-----------------------------------------------------------
local highestIlvlCache = {} -- keys: invType -> { ilvl = number, bag = number, slot = number }

local function RebuildHighestIlvlCache()
    -- clear table (use wipe if available)
    if wipe then
        wipe(highestIlvlCache)
    else
        for k in pairs(highestIlvlCache) do highestIlvlCache[k] = nil end
    end

    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if C_Item.DoesItemExist(itemLoc) then
                -- Create Item object once and query inventory type
                local item = Item:CreateFromItemLocation(itemLoc)
                local itemInvType = item and item:GetInventoryTypeName()
                if itemInvType and EquipSlots[itemInvType] then
                    local ilvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
                    local cur = highestIlvlCache[itemInvType]
                    if (not cur) or (ilvl > cur.ilvl) then
                        highestIlvlCache[itemInvType] = { ilvl = ilvl, bag = bag, slot = slot }
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------
-- Determine whether a bag slot is the best to show overlay
-----------------------------------------------------------
local function IsHighestIlvlItem(bag, slot)
    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not C_Item.DoesItemExist(itemLoc) then
        return false
    end

    local item = Item:CreateFromItemLocation(itemLoc)
    if not item then return false end
    local invType = item:GetInventoryTypeName()
    if not invType then return false end

    local slots = EquipSlots[invType]
    if not slots or #slots == 0 then return false end

    -- Check cache (built once per update)
    local cache = highestIlvlCache[invType]
    if not cache then return false end

    local bagIlvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
    if bagIlvl < cache.ilvl then return false end
    if cache.bag ~= bag or cache.slot ~= slot then return false end

    -- Compare to equipped items for the relevant equip slots
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
        -- If we couldn't resolve equipped items, don't show
        return false
    end

    local minEquippedIlvl = math.min(unpack(equippedIlvls))
    return bagIlvl > minEquippedIlvl
end

-----------------------------------------------------------
-- Overlay / UI handling
-----------------------------------------------------------
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
    local overlay = EnsureOverlay(button)
    overlay:SetShown(show)
end

local function UpdateAllBagButtons()
    RebuildHighestIlvlCache()
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

-----------------------------------------------------------
-- Throttled update state (use a table instead of function fields)
-----------------------------------------------------------
local throttle = { pending = false }

local function ThrottledUpdate()
    if not throttle.pending then
        throttle.pending = true
        C_Timer.After(0.8, function()
            UpdateAllBagButtons()
            throttle.pending = false
        end)
    end
end

-----------------------------------------------------------
-- Frame / Event wiring
-----------------------------------------------------------
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
        -- slight delay to avoid flicker while dragging
        C_Timer.After(0.5, ThrottledUpdate)
    else
        ThrottledUpdate()
    end
end)

-- Hook into container frame generation so newly-generated frames/buttons update immediately
hooksecurefunc("ContainerFrame_GenerateFrame", function(contFrame)
    if contFrame and contFrame.Items then
        for _, button in ipairs(contFrame.Items) do
            if button:IsShown() then
                UpdateOverlayForButton(button)
            end
        end
    end
end)

-- no periodic NewTicker — we use event-driven + throttled updates
