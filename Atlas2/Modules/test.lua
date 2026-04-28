local audioAna = Atlas.loadPlugin("RTAudioPlugin")
print(">>>>>>>>>>>>>>>>>>>>>>>>>1111111")
csv_path = "/Users/zhangpu/Desktop/mix_call/dmm_raw_data/dmm_sampling_raw_data_1KHz_1V8_0321_test.csv"
data_table = {}
local comFunc = require("Common/Utilities")

local function read_csv_to_float_table(file_path)
    local data_table = {}
    local file, err = io.open(file_path, "r")
    if not file then
        error("无法打开文件 '" .. file_path .. "': " .. (err or "未知错误"))
    end
    local i = 0
    -- 按行读取文件
    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then -- 跳过空行
            num = tonumber(line)
            if num then
            	i = i + 1
            	table.insert(data_table, num)
            	if i == 16384 then
            		break
            	end
            end
        end
    end

    file:close()
    return data_table
end

data_table = read_csv_to_float_table(csv_path)

print("data_table: ")
print(#data_table)
-- print(comFunc.dump(data_table))
ret = audioAna.analyze(data_table, 50000)
print(comFunc.dump(ret))