AutoScrapDB = AutoScrapDB or {}

local DEFAULTS = {
  itemLevel = 578,
  addCount = 9,
  Rarity = { ["2"] = true, ["3"] = true, ["4"] = false },
  Bags = { false, false, false, false, false },
  ItemStat = {
    ITEM_MOD_CRIT_RATING_SHORT = true,
    ITEM_MOD_AVOIDANCE_SHORT = true,
    ITEM_MOD_CR_LIFESTEAL_SHORT = true,
    ITEM_MOD_CR_SPEED_SHORT = true,
    ITEM_MOD_HASTE_RATING_SHORT = true,
    ITEM_MOD_MASTERY_RATING_SHORT = true,
    ITEM_MOD_VERSATILITY = true,
  },
}

local function InitDB()
  if not AutoScrapDB.config then AutoScrapDB.config = {} end
  local cfg = AutoScrapDB.config
  for k, v in pairs(DEFAULTS) do
    if cfg[k] == nil then
      if type(v) == "table" then
        cfg[k] = {}
        for kk, vv in pairs(v) do cfg[k][kk] = vv end
      else
        cfg[k] = v
      end
    end
  end
end

local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local UseContainerItem = C_Container.UseContainerItem
local GetItemInfo = GetItemInfo
local GetItemStats = C_Item.GetItemStats
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local GetItemClassInfo = GetItemClassInfo

local itemTypeArmor = select(1, GetItemClassInfo(4))

-------------------------------------------------------------
-- Equipment Slot Mapping
-------------------------------------------------------------
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

local function IsLowerThanEquipped(bag, slot)
  local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
  if not C_Item.DoesItemExist(itemLoc) then return false end

  local ilvl = C_Item.GetCurrentItemLevel(itemLoc) or 0
  local item = Item:CreateFromItemLocation(itemLoc)
  local invType = item:GetInventoryTypeName()
  if not invType then return false end

  local slots = EquipSlots[invType]
  if not slots or #slots == 0 then return false end

  local lowestEquippedIlvl = math.huge
  for _, eqSlot in ipairs(slots) do
    local eqLoc = ItemLocation:CreateFromEquipmentSlot(eqSlot)
    if C_Item.DoesItemExist(eqLoc) then
      local eqIlvl = C_Item.GetCurrentItemLevel(eqLoc) or 0
      if eqIlvl < lowestEquippedIlvl then
        lowestEquippedIlvl = eqIlvl
      end
    end
  end

  if lowestEquippedIlvl == math.huge then
    return false
  end

  return ilvl < lowestEquippedIlvl
end

local function ItemStatCheck(itemLink, cfg)
  if not itemLink then return false end
  local stats = GetItemStats(itemLink) or {}
  for k, v in pairs(cfg.ItemStat) do
    if stats[k] and not v then
      return false
    end
  end
  return true
end

local function ItemCheck(bag, slot, cfg)
  local itemLink = GetContainerItemLink(bag, slot)
  if not itemLink then return false end
  local itemInfo = GetContainerItemInfo(bag, slot)
  if not itemInfo or itemInfo.isLocked then return false end

  local _, _, itemRarity, _, _, itemType = GetItemInfo(itemLink)
  if not itemType or itemType ~= itemTypeArmor then return false end

  if not itemRarity or not cfg.Rarity[tostring(itemRarity)] then return false end

  local itemLevel = GetDetailedItemLevelInfo(itemLink) or 0
  if itemLevel <= 1 or itemLevel > cfg.itemLevel then return false end

  if not ItemStatCheck(itemLink, cfg) then return false end

  if not IsLowerThanEquipped(bag, slot) then return false end

  return true
end

local function GetItemLocation(cfg)
  for bag = 0, 4 do
    if not cfg.Bags[bag + 1] then
      local slots = GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        if ItemCheck(bag, slot, cfg) then
          return bag, slot
        end
      end
    end
  end
  return nil, nil
end

local function MoveItems(cfg)
  if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then
    return false
  end
  for i = 1, cfg.addCount do
    local bag, slot = GetItemLocation(cfg)
    if not bag or not slot then return false end
    UseContainerItem(bag, slot)
  end
  return true
end

local function CreateButton()
  local button = CreateFrame("Button", "AutoScrapButton", UIParent, "UIPanelButtonTemplate")
  button:SetSize(100, 24)
  button:SetText("Add Items")
  button:Hide()

  button:SetScript("OnClick", function()
    MoveItems(AutoScrapDB.config)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add low-level items to the Scrapping.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return button
end

local autoScrapButton = nil

local function HookScrapFrame(button)
  if not button then return end

  local function AnchorButton()
    if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then
      button:Hide()
      return
    end
    button:SetParent(ScrappingMachineFrame)

    local scrapBtn = ScrappingMachineFrame.ScrapButton
      or (ScrappingMachineFrame.ButtonFrame and ScrappingMachineFrame.ButtonFrame.ScrapButton)

    if scrapBtn then
      button:ClearAllPoints()
      button:SetPoint("BOTTOMRIGHT", scrapBtn, "TOPRIGHT", 0, 6)
    else
      button:ClearAllPoints()
      button:SetPoint("BOTTOMRIGHT", ScrappingMachineFrame, "BOTTOMRIGHT", -5, 35)
    end

    button:Show()
  end

  local function OnScrapShow() AnchorButton() end
  local function OnScrapHide() button:Hide() end

  if ScrappingMachineFrame then
    ScrappingMachineFrame:HookScript("OnShow", OnScrapShow)
    ScrappingMachineFrame:HookScript("OnHide", OnScrapHide)
    if ScrappingMachineFrame:IsShown() then AnchorButton() end
  else
    C_Timer.After(1, function() HookScrapFrame(button) end)
  end
end

local evframe = CreateFrame("Frame")
evframe:RegisterEvent("ADDON_LOADED")
evframe:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" then
    InitDB()
    if not autoScrapButton then
      autoScrapButton = CreateButton()
      HookScrapFrame(autoScrapButton)
    end
    self:UnregisterEvent("ADDON_LOADED")
  end
end)
