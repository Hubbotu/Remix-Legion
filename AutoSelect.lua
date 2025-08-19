local addonName, addon = ...
local NPC_LIST = {
    ["Katy Stampwhistle"] = {48598},
    ["Gurgthock"] = {55253, 55252, 55251, 55250, 55249, 55248}, -- selects option 1, then 3
	["Myrrit"] = {109604, 109101, 109603}, 
	["Enaru Silverbark"] = {111047},
	["South Brazier"] = {109540},
	["West Brazier"] = {109545},
	["North Brazier"] = {109402},
	["East Brazier"] = {109550},
	["Earthward Challenger"] = {109656},
	["Tauren Statue"] = {109631},
	["Mr. Sunflower"] = {109736, 109578},
	["Secured Shipment"] = {109222},
	["Pipsee"] = {109721},
	["Suffusion Crucible"] = {108249},
	["Suffusion Mold"] = {108250},		
    -- Russian localized names
    ["Кэти Штемпельпупс"] = {48598},
    ["Гаргток"] = {55253, 55252, 55251, 55250, 55249, 55248}, 
	["Миррит"] = {109604, 109101, 109603}, 
	["Энару Серебряная Кора"] = {111047},
	["Южная жаровня"] = {109540},
	["Западная жаровня"] = {109545},
	["Северная жаровня"] = {109402},
	["Восточная жаровня"] = {109550},
	["Воинственный страж земли"] = {109656},
	["Статуя таурена"] = {109631},
	["Подсолнушек"] = {109736, 109578},
	["Защищенные ресурсы"] = {109222},	
	["Пипси"] = {109721},
	["Горнило насыщения"] = {108249},
	["Форма насыщения"] = {108250},	
}

local AutoGossip = CreateFrame("Frame")
function AutoGossip:OnEvent(_, type)
    if IsShiftKeyDown() then return end
    if type ~= Enum.PlayerInteractionType.Gossip then return end
    local npcName = GossipFrame.TitleContainer.TitleText:GetText()
    if not npcName then return end
    local gossips = NPC_LIST[npcName]
    if not gossips then
        -- Try to find localized NPC name if not found in the default language
        npcName = GetLocalizedNPCName(npcName)
        gossips = NPC_LIST[npcName]
        if not gossips then return end
    end
    local options = C_GossipInfo.GetOptions()
    if not options then return end
    for _, option in ipairs(options) do
        if tContains(gossips, option.gossipOptionID) then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            return
        end
    end
end

function GetLocalizedNPCName(npcName)
    local localizedNPCName = nil
    -- Add more language checks if needed
    if GetLocale() == "ruRU" then
        for name, gossips in pairs(NPC_LIST) do
            if gossips == npcName then
                localizedNPCName = name
                break
            end
        end
    end
    return localizedNPCName or npcName
end

AutoGossip:SetScript("OnEvent", AutoGossip.OnEvent)
AutoGossip:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")