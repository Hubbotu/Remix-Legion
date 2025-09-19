local function formatNumber(num)
    local formattedNum, color

    local function comma_value(value)
        local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub('(%d%d%d)', '%1' .. (LARGE_NUMBER_SEPERATOR)):reverse()) .. right
    end

    if num < 1000 then
        formattedNum = tostring(num)
    elseif num < 1000000 then
        formattedNum = comma_value(tostring(num))
    else
        formattedNum = string.format("%.2fM", num / 1000000)
    end

    if num >= 200000 then
        color = "|cffFFFF00" -- Yellow
    elseif num >= 100000 then
        color = "|cffFF8000" -- Orange
    elseif num >= 50000 then
        color = "|cffA335EE" -- Purple
    elseif num >= 30000 then
        color = "|cff0070FF" -- Blue
    elseif num >= 20000 then
        color = "|cffADD8E6" -- Light Blue
    elseif num >= 15000 then
        color = "|cff00FF00" -- Green 
    elseif num >= 10000 then
        color = "|cff90EE90" -- Light Green
    else
        color = "|cff808080" -- Gray
    end

    return formattedNum, color
end

local L = {
    ["enUS"] = {
        ["Threads"] = "|cffFFFFFFThreads:|r",
        ["Infinite Power"] = "Infinite Power",
    },
    ["ruRU"] = {
        ["Threads"] = "|cffFFFFFFНити:|r",
        ["Infinite Power"] = "Безграничная сила",
    },
    ["frFR"] = {
        ["Threads"] = "|cffFFFFFFFils:|r",
        ["Infinite Power"] = "Avantage du Coureur de Temps",
    },
}

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit and UnitIsPlayer(unit) then
        local currentLocale = GetLocale()
        
        local threadsSpellName = (L[currentLocale] and L[currentLocale]["Infinite Power"]) or "Infinite Power"
        local threadsAura = C_UnitAuras.GetAuraDataBySpellName(unit, threadsSpellName)
        if threadsAura then
            local total = 0
            for i = 1, 9 do
                total = total + (threadsAura.points[i] or 0)
            end
            local formattedTotal, color = formatNumber(total)
            local threadsText = (L[currentLocale] and L[currentLocale]["Threads"]) or "|cffFFFFFFThreads:|r"
            tooltip:AddLine("\n" .. threadsText .. " " .. color .. formattedTotal)
        end

        local powerSpellName = (L[currentLocale] and L[currentLocale]["Infinite Power"]) or "Infinite Power"
        local powerAura = C_UnitAuras.GetAuraDataBySpellName(unit, powerSpellName)
        if powerAura then
            local total = 0
            for i = 1, #powerAura.points do
                total = total + (powerAura.points[i] or 0)
            end
            local formattedTotal, color = formatNumber(total)
            local powerText = (L[currentLocale] and L[currentLocale]["Infinite Power"]) or "Infinite Power"
            tooltip:AddLine("\n|cff00FF00" .. powerText .. ":|r " .. color .. formattedTotal)
        end
    end

end)
