local function formatNumber(num)
    local formattedNum, color
    local function comma_value(value)
        local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
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

local function formatVersatilityNumber(num)
    local formattedNum, color
    local function comma_value(value)
        local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
    end

    if num < 1000 then
        formattedNum = tostring(num) .. "%"
    elseif num < 1000000 then
        formattedNum = comma_value(tostring(num)) .. "%"
    else
        formattedNum = string.format("%.2fM%%", num / 1000000)
    end

    if num >= 850 then
        color = "|cffFFFF00" -- Yellow
    elseif num >= 750 then
        color = "|cffFF8000" -- Orange
    elseif num >= 500 then
        color = "|cffA335EE" -- Purple
    elseif num >= 400 then
        color = "|cff0070FF" -- Blue
    elseif num >= 300 then
        color = "|cffADD8E6" -- Light Blue
    elseif num >= 200 then
        color = "|cff00FF00" -- Green
    elseif num >= 100 then
        color = "|cff90EE90" -- Light Green
    else
        color = "|cff808080" -- Gray
    end

    return formattedNum, color
end

local L = {
    ["enUS"] = { ["Infinite Power"] = "Infinite Power", ["Versatility"] = "Versatility" },
    ["ruRU"] = { ["Infinite Power"] = "Бесконечная сила", ["Versatility"] = "Универсальность" },
    ["frFR"] = { ["Infinite Power"] = "Pouvoir infini", ["Versatility"] = "Polyvalence" },
    ["deDE"] = { ["Infinite Power"] = "Ewige Macht", ["Versatility"] = "Vielseitigkeit" },
    ["esES"] = { ["Infinite Power"] = "Poder infinito", ["Versatility"] = "Versatilidad" },
    ["zhCN"] = { ["Infinite Power"] = "永恒能量", ["Versatility"] = "全能" },
    ["zhTW"] = { ["Infinite Power"] = "恆龍之力", ["Versatility"] = "臨機應變" },
}

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    local _, unit = tooltip:GetUnit()
    if not (unit and UnitIsPlayer(unit)) then return end

    local currentLocale = GetLocale()
    local powerName = (L[currentLocale] and L[currentLocale]["Infinite Power"]) or "Infinite Power"
    local powerAura = C_UnitAuras.GetAuraDataBySpellName(unit, powerName)
        or C_UnitAuras.GetAuraDataBySpellName(unit, "Infinite Power")

    if not powerAura then return end

    -- Sum up Infinite Power
    local total = 0
    if powerAura.points then
        for i = 1, #powerAura.points do
            total = total + (powerAura.points[i] or 0)
        end
    end
    local formattedTotal, color = formatNumber(total)
    tooltip:AddLine("\n|cff00FF00" .. powerName .. ":|r " .. color .. formattedTotal)

    -- Versatility display (fifth line of points)
    if powerAura.points and powerAura.points[5] then
        local versaValue = powerAura.points[5]
        local formattedVersa, versaColor = formatVersatilityNumber(versaValue)
        local versaText = (L[currentLocale] and L[currentLocale]["Versatility"]) or "Versatility"
        tooltip:AddLine("\n|cff00FF00" .. versaText .. ":|r " .. versaColor .. formattedVersa)
    end
end)