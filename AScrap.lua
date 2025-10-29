AutoScrapDB = AutoScrapDB or {}

local DEFAULTS = {
  addCount = 9,
  Bags = { false, false, false, false, false },
  ItemStat = {
    ITEM_MOD_HASTE_RATING_SHORT = true,
    ITEM_MOD_MASTERY_RATING_SHORT = true,
    ITEM_MOD_VERSATILITY = true,
    ITEM_MOD_CRIT_RATING_SHORT = true,
    ITEM_MOD_CR_LIFESTEAL_SHORT = true,
    ITEM_MOD_CR_SPEED_SHORT = true,
    ITEM_MOD_CR_AVOIDANCE_SHORT = true,
  },
  equippedLower = true,
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

-- Quick API access
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local UseContainerItem = C_Container.UseContainerItem
local GetItemStats = C_Item.GetItemStats
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetItemClassInfo = GetItemClassInfo

-- Only consider Armor items
local itemTypes = { [GetItemClassInfo(4)] = true }

-- Equipment slot mapping
local itemEquipLocToSlot = {
  INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3}, INVTYPE_BODY = {4},
  INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5}, INVTYPE_WAIST = {6}, INVTYPE_LEGS = {7},
  INVTYPE_FEET = {8}, INVTYPE_WRIST = {9}, INVTYPE_HAND = {10},
  INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14},
  INVTYPE_WEAPON = {16, 17}, INVTYPE_SHIELD = {17},
  INVTYPE_RANGED = {16}, INVTYPE_CLOAK = {15}, INVTYPE_2HWEAPON = {16},
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function ItemStatCheck(itemLink, cfg)
  local stats = GetItemStats(itemLink)
  if not stats then return false end
  for k, v in pairs(cfg.ItemStat) do
    if stats[k] and not v then
      return false
    end
  end
  return true
end

local function ItemLevelEquippedHigher(itemEquipLoc, itemlevel, itemId)
  local slots = itemEquipLocToSlot[itemEquipLoc]
  if not slots then return false end

  local allHigher = false
  for _, slot in ipairs(slots) do
    local equippedItemLink = GetInventoryItemLink("player", slot)
    if equippedItemLink then
      local itemLevelEquipped = GetDetailedItemLevelInfo(equippedItemLink)
      local equippedId = equippedItemLink:match("item:(%d+):")
      if tostring(equippedId) == tostring(itemId) then
        if itemLevelEquipped > itemlevel then return true end
      end
      if itemLevelEquipped > itemlevel then
        allHigher = true
      end
    end
  end

  return allHigher
end

------------------------------------------------------------
-- Cached bag scan for eligible items
------------------------------------------------------------

local cachedItems = {}

local function BuildItemCache(cfg)
  wipe(cachedItems)

  for bag = 0, 4 do
    if not cfg.Bags[bag + 1] then
      local numSlots = GetContainerNumSlots(bag) or 0
      for slot = 1, numSlots do
        local itemInfo = GetContainerItemInfo(bag, slot)
        if itemInfo and not itemInfo.isLocked and itemInfo.hyperlink then
          local itemLink = itemInfo.hyperlink
          local _, _, _, _, _, itemType, _, _, itemEquipLoc = GetItemInfo(itemLink)
          if itemType and itemTypes[itemType] then
            local itemLevel = GetDetailedItemLevelInfo(itemLink)
            local itemId = itemLink:match("item:(%d+):")

            if cfg.equippedLower and not ItemLevelEquippedHigher(itemEquipLoc, itemLevel, itemId) then
              -- skip if not lower
            elseif ItemStatCheck(itemLink, cfg) then
              table.insert(cachedItems, { bag = bag, slot = slot })
            end
          end
        end
      end
    end
  end
end

------------------------------------------------------------
-- Move eligible items
------------------------------------------------------------

local function MoveItems(cfg)
  if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then return false end
  if #cachedItems == 0 then BuildItemCache(cfg) end

  local added = 0
  for i = 1, cfg.addCount do
    local entry = table.remove(cachedItems, 1)
    if not entry then break end
    UseContainerItem(entry.bag, entry.slot)
    added = added + 1
  end

  return added > 0
end

------------------------------------------------------------
-- UI button setup
------------------------------------------------------------

local function CreateButton()
  local button = CreateFrame("Button", "AutoScrapButton", UIParent, "UIPanelButtonTemplate")
  button:SetSize(100, 24)
  button:SetText("Add Items")
  button:Hide()

  button:SetScript("OnClick", function()
    cachedItems = {} -- reset before scanning
    MoveItems(AutoScrapDB.config)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add lower-level equipment to the Scrapping Machine.", 1, 1, 1, true)
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

  local function OnScrapShow()
    wipe(cachedItems)
    AnchorButton()
  end

  local function OnScrapHide() button:Hide() end

  if ScrappingMachineFrame then
    ScrappingMachineFrame:HookScript("OnShow", OnScrapShow)
    ScrappingMachineFrame:HookScript("OnHide", OnScrapHide)
    if ScrappingMachineFrame:IsShown() then AnchorButton() end
  else
    C_Timer.After(1, function() HookScrapFrame(button) end)
  end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------

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
