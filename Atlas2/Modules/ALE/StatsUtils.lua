--[[
--! @defgroup statsutils Statistics Utilities
--! @{
--!
--! @brief Statistical analysis utilities for numerical data processing
--!
--! @details This module provides a set of statistical functions for analyzing numerical datasets.
--! It includes descriptive statistics (mean, median, mode), measures of variability (standard deviation),
--! range analysis (min/max), and correlation analysis (R² score). All functions are designed to work
--! with Lua tables containing numerical data.
--!
--! **Common Usage Patterns:**
--!
--! ```lua
--! local StatsUtils = require "ALE.StatsUtils"
--!
--! -- Sample dataset
--! local data = {1.2, 2.5, 3.1, 2.8, 4.0, 2.5, 3.7, 2.1, 3.9, 2.5}
--!
--! -- Basic descriptive statistics
--! local avg = StatsUtils.mean(data)
--! local mid = StatsUtils.median(data)
--! local modes, frequency = StatsUtils.mode(data)
--! print("Mean:", avg)           -- 2.83
--! print("Median:", mid)         -- 2.65
--! print("Mode:", modes[1])      -- 2.5 (appears 3 times)
--! print("Frequency:", frequency) -- 3
--!
--! -- Variability analysis
--! local stdDev = StatsUtils.standardDeviation(data)
--! local minVal, maxVal = StatsUtils.minmax(data)
--! print("Standard Deviation:", stdDev)  -- ~0.89
--! print("Range:", minVal, "to", maxVal) -- 1.2 to 4.0
--!
--! -- Correlation analysis between two datasets
--! local x = {1, 2, 3, 4, 5}
--! local y = {2, 4, 6, 8, 10}  -- Perfect linear correlation
--! local r2 = StatsUtils.r2Score(x, y)
--! print("R² Score:", r2)  -- 1.0 (perfect correlation)
--!
--! -- Working with measurement data
--! local measurements = {23.1, 23.3, 23.0, 23.2, 23.4, 23.1, 23.3}
--! local avgMeasurement = StatsUtils.mean(measurements)
--! local precision = StatsUtils.standardDeviation(measurements)
--! local range_min, range_max = StatsUtils.minmax(measurements)
--!
--! print(string.format("Average: %.2f ± %.3f", avgMeasurement, precision))
--! print(string.format("Range: %.1f - %.1f", range_min, range_max))
--! ```
--]] local TypeUtils = require("ALE.TypeUtils")

local StatsUtils = {version = "1.2.18"}

--[[
--! @brief Calculate the arithmetic mean (average) of a numerical dataset
--! @param tab Table containing numerical values
--! @returns Number representing the arithmetic mean
--! @throws Error if table is empty or contains non-numerical values
--!
--! @details Uses the Kahan summation algorithm for improved numerical precision,
--! which reduces floating-point rounding errors when summing large datasets.
--!
--! ```lua
--! local data = {1.1, 2.2, 3.3, 4.4, 5.5}
--! local avg = StatsUtils.mean(data)  -- Returns 3.3
--! ```
--]]
function StatsUtils.mean(tab)
    local sum = 0
    local c = 0.0

    TypeUtils.assertTable(tab)
    assert(#tab > 0, "No elements in the input array")

    -- Using Kahan summation algorithm
    -- See https://en.wikipedia.org/wiki/Kahan_summation_algorithm for details.
    for _, v in pairs(tab) do
        TypeUtils.assertNumber(v)
        local y = v - c
        local t = sum + y
        c = (t - sum) - y
        sum = t
    end
    return (sum / #tab)
end

--[[
--! @brief Find the mode(s) of a dataset (most frequently occurring values)
--! @param t Table containing values (can be numbers, strings, or other comparable types)
--! @returns Two values: table of mode values, and their frequency count
--!
--! @details Returns all values that appear with the highest frequency. If multiple values
--! tie for the highest frequency (multimodal distribution), all are returned in a sorted table.
--!
--! ```lua
--! local data = {1, 2, 2, 3, 2, 4}
--! local modes, count = StatsUtils.mode(data)
--! -- modes = {2}, count = 3
--!
--! local multimodal = {1, 1, 2, 2, 3}
--! local modes2, count2 = StatsUtils.mode(multimodal)
--! -- modes2 = {1, 2}, count2 = 2
--! ```
--]]
function StatsUtils.mode(t)
    local counts = {}

    for _, v in pairs(t) do
        counts[v] = counts[v] and counts[v] + 1 or 1
    end

    local biggestCount = 0
    local biggestValues = {}

    for k, v in pairs(counts) do
        if v > biggestCount then
            biggestCount = v
            biggestValues = {k}
        elseif v == biggestCount then
            table.insert(biggestValues, k)
        end
    end
    table.sort(biggestValues)

    return biggestValues, biggestCount
end

--[[
--! @brief Calculate the median (middle value) of a numerical dataset
--! @param t Table containing numerical values
--! @returns Number representing the median value
--! @throws Error if table is empty or contains non-numerical values
--!
--! @details Preserves the original data by creating a sorted copy. For even-sized datasets,
--! returns the mean of the two middle values. For odd-sized datasets, returns the middle value.
--!
--! ```lua
--! local oddData = {1, 3, 2, 5, 4}
--! local median1 = StatsUtils.median(oddData)  -- Returns 3
--!
--! local evenData = {1, 2, 4, 5}
--! local median2 = StatsUtils.median(evenData)  -- Returns 3 (mean of 2 and 4)
--! ```
--]]
function StatsUtils.median(t)

    TypeUtils.assertTable(t)
    assert(#t > 0, "No elements in the input array")

    local temp = {}
    -- deep copy table so that when we sort it, the original is unchanged
    -- also weed out any non numbers
    for _, v in pairs(t) do
        TypeUtils.assertNumber(v)
        table.insert(temp, v)
    end

    table.sort(temp)

    -- If we have an even number of table elements or odd.
    if math.fmod(#temp, 2) == 0 then
        -- return mean value of middle two elements
        return (temp[#temp / 2] + temp[(#temp / 2) + 1]) / 2
    else
        -- return middle element
        return temp[math.ceil(#temp / 2)]
    end
end

--[[
--! @brief Calculate the population standard deviation of a numerical dataset
--! @param t Table containing numerical values
--! @returns Number representing the standard deviation
--! @throws Error if table is empty or contains non-numerical values
--!
--! @details Uses the population standard deviation formula (divides by N, not N-1).
--! Measures the spread of data points around the mean.
--!
--! ```lua
--! local data = {2, 4, 4, 4, 5, 5, 7, 9}
--! local stdDev = StatsUtils.standardDeviation(data)  -- Returns ~2.0
--! ```
--]]
function StatsUtils.standardDeviation(t)
    local m
    local vm
    local sum = 0
    local count = 0
    local result

    m = StatsUtils.mean(t)

    for _, v in pairs(t) do
        vm = v - m
        sum = sum + (vm * vm)
        count = count + 1
    end

    result = math.sqrt(sum / count)

    return result
end

--[[
--! @brief Find the minimum and maximum values in a numerical dataset
--! @param t Table containing numerical values
--! @returns Two numbers: minimum value, maximum value
--! @throws Error if table is empty or contains non-numerical values
--!
--! @details Efficiently finds the range of the dataset in a single pass.
--!
--! ```lua
--! local data = {3.2, 1.5, 4.8, 2.1, 5.0}
--! local min, max = StatsUtils.minmax(data)
--! -- min = 1.5, max = 5.0
--! local range = max - min  -- 3.5
--! ```
--]]
function StatsUtils.minmax(t)

    TypeUtils.assertTable(t)
    assert(#t > 0, "No elements in the input array")

    local max = -math.huge
    local min = math.huge

    for _, v in pairs(t) do
        TypeUtils.assertNumber(v)
        max = math.max(max, v)
        min = math.min(min, v)
    end

    return min, max
end

--[[
--! @brief Calculate the R² coefficient of determination between two datasets
--! @param x Table containing numerical values for the independent variable
--! @param y Table containing numerical values for the dependent variable (same length as x)
--! @returns Number representing the R² score (0 to 1, where 1 indicates perfect correlation)
--! @throws Error if tables contain non-numerical values or have different lengths
--!
--! @details Measures the proportion of variance in the dependent variable that is predictable
--! from the independent variable. R² = 1 indicates perfect linear correlation, R² = 0 indicates no correlation.
--!
--! @code
--! local x = {1, 2, 3, 4, 5}
--! local y = {2, 4, 6, 8, 10}  -- Perfect linear relationship: y = 2x
--! local r2 = StatsUtils.r2Score(x, y)  -- Returns 1.0
--!
--! local x2 = {1, 2, 3, 4}
--! local y2 = {1, 4, 2, 3}  -- No clear linear relationship
--! local r2_2 = StatsUtils.r2Score(x2, y2)  -- Returns value closer to 0
--! @endcode
--]]
function StatsUtils.r2Score(x, y)
    local Xm = StatsUtils.mean(x)
    local Ym = StatsUtils.mean(y)
    local sum1 = 0 -- (X - Xm)^2
    local sum2 = 0 -- (Y - Ym)^2
    local sum3 = 0 -- (X-Xm)*(Y-Ym)

    for k, v in pairs(x) do
        TypeUtils.assertNumber(v)
        local x1 = v - Xm
        local y1 = y[k] - Ym
        sum1 = sum1 + (x1 * x1)
        sum2 = sum2 + (y1 * y1)
        sum3 = sum3 + (x1 * y1)
    end

    return ((sum3 / math.sqrt(sum1 * sum2)) * (sum3 / math.sqrt(sum1 * sum2)))
end

-- ! Temporary function to create PascalCase aliases for all functions
-- ! to keep backward compatibility
local function createPascalCaseAliases(module)
    local camelCaseNames = {}
    for k, v in pairs(module) do
        if type(v) == "function" and k:match("^[a-z]") then
            table.insert(camelCaseNames, k)
        end
    end
    for _, name in ipairs(camelCaseNames) do
        local pascalCaseName = name:sub(1, 1):upper() .. name:sub(2)
        module[pascalCaseName] = module[name]
    end
end

createPascalCaseAliases(StatsUtils)
return StatsUtils

--[[
--! @}
--]]
