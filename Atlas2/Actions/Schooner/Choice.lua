-- action to run condition expression and return the result.
-- return true or nil, because the choice path is defined as
--  {true: starting action of the test}
-- so for false condition, it will cancel the test with its starting action
-- and for true condition, it will just run the starting action then the test.
-- args: list of key, value like [key1, value1, key2, value].
-- it is because value can be resolvable which can only be in arg, not in a table.
-- test and subtest is for logging purpose only.
function main(test, subtest, expression, ...)
    local msg = 'Test with condition: '
    msg = msg .. tostring(test) .. ' '
    msg = msg .. tostring(subtest)
    msg = msg .. ': ' .. tostring(expression)
    print(msg)
    local values = {}
    local key = nil
    for i, v in ipairs({ ... }) do
        if i % 2 == 1 then
            key = v
        else
            values[key] = v
            key = nil
        end
    end
    local plugin = Atlas.loadPlugin('ConditionEvaluator')
    local result = plugin.eval(expression, values)
    print('Test ' .. tostring(test) .. ' ' .. tostring(subtest) ..
          ' condition result: ' .. tostring(result))
    if result == true then
        return result
    else
        return nil
    end
end
