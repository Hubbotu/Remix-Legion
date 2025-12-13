-- AScrap.lua
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

-- API shortcuts
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local UseContainerItem = C_Container.UseContainerItem
local GetItemStats = C_Item.GetItemStats
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo
local GetInventoryItemLink = GetInventoryItemLink
local GetItemClassInfo = GetItemClassInfo
local GetItemInfo = GetItemInfo
local C_Timer = C_Timer

-- Only consider Armor items by class index (4 = Armor)
local itemTypes = {}
do
  local className = GetItemClassInfo(4) -- returns localized name for Armor
  if className then itemTypes[className] = true end
end

-- Equipment slot mapping (INVTYPE_* -> equipment slot(s))
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
  if not itemLink then return false end
  local stats = GetItemStats(itemLink)
  if not stats then return false end
  for statKey, allowed in pairs(cfg.ItemStat) do
    if stats[statKey] and not allowed then
      return false
    end
  end
  return true
end

local function IsEquippedHigher(itemEquipLoc, bagItemLevel, bagItemId)
  local slots = itemEquipLocToSlot[itemEquipLoc]
  if not slots then return false end
  for _, slot in ipairs(slots) do
    local eqLink = GetInventoryItemLink("player", slot)
    if eqLink then
      local eqItemLevel = GetDetailedItemLevelInfo(eqLink)
      if eqItemLevel and (eqItemLevel > bagItemLevel) then
        return true
      end
      local eqId = eqLink:match("item:(%d+):")
      if eqId and bagItemId and tostring(eqId) == tostring(bagItemId) and eqItemLevel and (eqItemLevel > bagItemLevel) then
        return true
      end
    end
  end
  return false
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
            if ItemStatCheck(itemLink, cfg) then
              if cfg.equippedLower then
                if IsEquippedHigher(itemEquipLoc, itemLevel, itemId) then
                  table.insert(cachedItems, { bag = bag, slot = slot })
                end
              else
                table.insert(cachedItems, { bag = bag, slot = slot })
              end
            end
          end
        end
      end
    end
  end
end

-- Build cache for exact item level, ignoring equipped check if specified
local function BuildItemCacheForLevel(cfg, targetLevel, ignoreEquipped)
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
            if itemLevel == targetLevel and ItemStatCheck(itemLink, cfg) then
              if ignoreEquipped then
                table.insert(cachedItems, { bag = bag, slot = slot })
              else
                if cfg.equippedLower then
                  if IsEquippedHigher(itemEquipLoc, itemLevel, itemId) then
                    table.insert(cachedItems, { bag = bag, slot = slot })
                  end
                else
                  table.insert(cachedItems, { bag = bag, slot = slot })
                end
              end
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

local function MoveItemsFromCache(cfg)
  if not ScrappingMachineFrame or not ScrappingMachineFrame:IsShown() then return false end
  if #cachedItems == 0 then return false end
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
-- UI buttons
------------------------------------------------------------

local function CreateButton()
  local button = CreateFrame("Button", "AutoScrapButton", UIParent, "UIPanelButtonTemplate")
  button:SetSize(100, 24)
  button:SetText("Add Items")
  button:Hide()
  button:SetScript("OnClick", function()
    cachedItems = {}
    BuildItemCache(AutoScrapDB.config)
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

local function CreateLevelButton()
  local button = CreateFrame("Button", "AutoScrap740Button", UIParent, "UIPanelButtonTemplate")
  button:SetSize(56, 24)
  button:SetText("779")
  button:Hide()
  button:SetScript("OnClick", function()
    local cfg = AutoScrapDB.config
    cachedItems = {}
    BuildItemCacheForLevel(cfg, 779, true) -- ignore equipped
    MoveItemsFromCache(cfg)
  end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Add equipment of item level 779 to the Scrapping Machine (ignores equipped comparison).", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return button
end

local autoScrapButton = nil
local level740Button = nil

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
      if button == autoScrapButton then
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", scrapBtn, "TOPRIGHT", 0, 3) -- moved 3px down
      elseif button == level740Button then
        if autoScrapButton then
          button:ClearAllPoints()
          button:SetPoint("RIGHT", autoScrapButton, "LEFT", -6, -2) -- align left & 3px down
        else
          button:ClearAllPoints()
          button:SetPoint("BOTTOMRIGHT", ScrappingMachineFrame, "BOTTOMRIGHT", -5, 32)
        end
      end
    else
      if button == autoScrapButton then
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", ScrappingMachineFrame, "BOTTOMRIGHT", -5, 32)
      else
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", ScrappingMachineFrame, "BOTTOMRIGHT", -70, 32)
      end
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
      level740Button = CreateLevelButton()
      HookScrapFrame(autoScrapButton)
      HookScrapFrame(level740Button)
    end
    self:UnregisterEvent("ADDON_LOADED")
  end
end)
