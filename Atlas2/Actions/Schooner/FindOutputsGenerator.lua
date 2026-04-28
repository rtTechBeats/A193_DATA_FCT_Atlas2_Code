-- Actions specially for find.outputs.
-- args: table1, value1, table2, value2, ...
-- table*: {testParameters = x, meta = {}}
-- returns: {key1 = {value = x, meta = {}}, ...}
function main(...)
    local args = { ... }
    assert(#args % 2 == 0,
           '[internal] [FindOuputsGenerator] action args should be pairs.')
    local ret = {}
    for i = 1, #args - 1, 2 do
        -- {meta = {}, testParameteres = ''}
        local value = args[i]
        local setting = args[i + 1]
        local t = { value = value, meta = setting.meta }
        ret[setting.testParameters] = t
    end
    return ret
end

