---@class addonTableBaganator
local addonTable = select(2, ...)
if not Syndicator or not Baganator then
  return
end

------------------------------------------------------------
-- ZAMESTO TV REMIX — BAGANATOR / SYNDICATOR INTEGRATION
------------------------------------------------------------
local ADDON_NAME = "ZamestoTV_Remix"
local ICON_PATH = "Interface\\AddOns\\ZamestoTV_Remix\\Icons\\upp1.tga"

------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------

addonTable.Utilities = addonTable.Utilities or {}

-- Trigger an update on all bag icons when conditions change
local function PostRefresh()
  local reasons = {}
  if Baganator.API.IsCornerWidgetActive("zamestotv") then
    table.insert(reasons, Baganator.Constants.RefreshReason.ItemWidgets)
  end
  if Baganator.API.IsUpgradePluginActive("zamestotv") then
    table.insert(reasons, Baganator.Constants.RefreshReason.Searches)
  end
  if #reasons > 0 then
    Baganator.API.RequestItemButtonsRefresh(reasons)
  end
end

------------------------------------------------------------
-- UPGRADE LOGIC
------------------------------------------------------------

-- Determine if an item should be considered "equippable" (armor/weapon)
local function ShouldShowForItem(itemLink)
  local classID = select(6, C_Item.GetItemInfoInstant(itemLink))
  return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
end

local function IsUpgradeItem(itemLink)
  if not itemLink or not ShouldShowForItem(itemLink) then
    return false
  end

  if type(PawnShouldItemLinkHaveUpgradeArrowUnbudgeted) == "function" then
    local ok, res = pcall(PawnShouldItemLinkHaveUpgradeArrowUnbudgeted, itemLink)
    if ok and res ~= nil then
      return res
    end
  end

  -- Try Blizzard's fallback upgrade API
  if type(IsItemAnUpgrade) == "function" then
    local ok2, res2 = pcall(IsItemAnUpgrade, itemLink)
    if ok2 and res2 ~= nil then
      return res2
    end
  end

  -- Fallback: Compare by item level vs equipped
  local itemLevel = select(4, GetItemInfo(itemLink)) or 0
  if itemLevel == 0 then
    return false
  end

  local equipLoc = select(9, GetItemInfo(itemLink))
  if not equipLoc then
    return false
  end

  local equipSlots = {
    INVTYPE_HEAD = { INVSLOT_HEAD },
    INVTYPE_NECK = { INVSLOT_NECK },
    INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
    INVTYPE_CHEST = { INVSLOT_CHEST },
    INVTYPE_ROBE = { INVSLOT_CHEST },
    INVTYPE_WAIST = { INVSLOT_WAIST },
    INVTYPE_LEGS = { INVSLOT_LEGS },
    INVTYPE_FEET = { INVSLOT_FEET },
    INVTYPE_WRIST = { INVSLOT_WRIST },
    INVTYPE_HAND = { INVSLOT_HAND },
    INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_CLOAK = { INVSLOT_BACK },
    INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_2HWEAPON = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE = { INVSLOT_OFFHAND },
    INVTYPE_SHIELD = { INVSLOT_OFFHAND },
  }

  local slots = equipSlots[equipLoc]
  if not slots then
    return false
  end

  local equippedMin = math.huge
  for _, slotID in ipairs(slots) do
    local equippedLink = GetInventoryItemLink("player", slotID)
    if equippedLink then
      local eqLevel = select(4, GetItemInfo(equippedLink)) or 0
      if eqLevel < equippedMin then
        equippedMin = eqLevel
      end
    end
  end

  if equippedMin == math.huge then
    return false
  end

  return itemLevel > equippedMin
end

------------------------------------------------------------
-- UPDATE TRIGGERS
------------------------------------------------------------
local upgradeCache = {}
local pending = {}
local updateFrame = CreateFrame("Frame")

local function GetUpgradeStatus(itemLink)
  if upgradeCache[itemLink] ~= nil then
    return upgradeCache[itemLink]
  end

  local result = IsUpgradeItem(itemLink)
  if result ~= nil then
    upgradeCache[itemLink] = result
    return result
  end

  if C_Item.IsItemDataCachedByID(itemLink) then
    upgradeCache[itemLink] = false
    return false
  end

  pending[itemLink] = true
  updateFrame:SetScript("OnUpdate", updateFrame.OnUpdate)
  return false
end

function updateFrame:OnUpdate()
  for link in pairs(pending) do
    local res = IsUpgradeItem(link)
    if res ~= nil then
      upgradeCache[link] = res
      pending[link] = nil
    end
  end
  if not next(pending) then
    self:SetScript("OnUpdate", nil)
    PostRefresh()
  end
end

------------------------------------------------------------
-- CORNER WIDGET (ICON IN BAGANATOR)
------------------------------------------------------------
Baganator.API.RegisterCornerWidget(
  ADDON_NAME,
  "zamestotv",
  ---@param _ any
  ---@param details table
  ---@return boolean|nil
  function(_, details)
    return ShouldShowForItem(details.itemLink) and GetUpgradeStatus(details.itemLink)
  end,
  ---@param itemButton Button
  function(itemButton)
    local tex = itemButton:CreateTexture(nil, "OVERLAY")
    tex:SetTexture(ICON_PATH)
    tex:SetSize(16, 16)
    return tex
  end,
  { corner = "top_left", priority = 2 }
)

------------------------------------------------------------
-- UPGRADE PLUGIN (FOR SEARCHES AND FILTERS)
------------------------------------------------------------
Baganator.API.RegisterUpgradePlugin(
  ADDON_NAME,
  "zamestotv",
  function(itemLink)
    local cached = upgradeCache[itemLink]
    if cached ~= nil then
      return cached
    end
    local res = ShouldShowForItem(itemLink) and GetUpgradeStatus(itemLink)
    if res == nil then
      pending[itemLink] = true
      updateFrame:SetScript("OnUpdate", updateFrame.OnUpdate)
    else
      upgradeCache[itemLink] = res
    end
    return res
  end
)

Syndicator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", function()
  if Baganator.API.IsCornerWidgetActive("zamestotv") or Baganator.API.IsUpgradePluginActive("zamestotv") then
    PostRefresh()
    upgradeCache = {}
  end
end)

local refreshFrame = CreateFrame("Frame")
refreshFrame:RegisterEvent("PLAYER_LEVEL_UP")
refreshFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
refreshFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
refreshFrame:SetScript("OnEvent", PostRefresh)

print("|cff00ff00ZamestoTV_Remix|r: Baganator/Syndicator integration loaded.")
