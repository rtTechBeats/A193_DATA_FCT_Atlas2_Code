local common = require('Schooner.SchoonerCommon')
local M = {}

local function writeStringToFile(path, str, mode)
    if mode then
        assert(mode == "w" or mode == "a")
    else
        mode = "w"
    end

    local f = assert(io.open(path, mode))
    local success, err = pcall(f.write, f, str)
    assert(f:close())

    if not success then
        error(err)
    end
end

local function stringToAnchor(str)
    return string.gsub(string.lower(str), " ", "-")
end

local function generateTestDiagram(mode, tests)
    local diagram = ""
    for i, test in ipairs(tests) do
        diagram = diagram .. string.format("    T%d[<a href='#%s'>%s</a>]\n", i,
                                           stringToAnchor(
                                           mode .. ' ' .. test.fullName),
                                           test.fullName)

        if test.deps ~= nil then
            for _, depIndex in ipairs(test.deps) do
                diagram = diagram ..
                          string.format("    T%d --> T%d\n", depIndex, i)
            end
        end
    end
    local result = string.format("```mermaid\nflowchart\n%s\n```\n", diagram)
    return result
end

-- allTests: table of tests from all dags:
-- { main={}, teardown={} } when teardown test exists.
-- this is used to get test name when action get data from a different test
-- or a different dag
-- like `TestA action1 -.-> action2`
-- allActions: same as allTests but for actions
local function generateCoverageDiagram(allActions,
                                       testIndex,
                                       allTests,
                                       dagName)
    local diagram = ""
    -- action of current dag
    local actions = allActions[dagName]
    for i, action in ipairs(actions) do
        if action.testIdx == testIndex then
            diagram = diagram ..
                      string.format("    A%d(%s):::actionclass\n", i,
                                    action.name)

            -- Add explicit dependencies
            if action.deps ~= nil then
                for _, depIndex in ipairs(action.deps) do
                    diagram = diagram ..
                              string.format("    A%d --> A%d\n", depIndex, i)
                end
            end

            -- Add data dependencies
            for _, arg in ipairs(action.args or {}) do
                if arg.action ~= nil then
                    -- The source action might belong to a different test
                    local sourceAction
                    local sourceNode
                    if arg.action.dag and arg.action.dag == 'main' then
                        sourceAction = allActions[arg.action.dag][arg.action
                                       .actionIdx]
                        local mainTest =
                        allTests[arg.action.dag][sourceAction.testIdx]
                        local mainTestName = mainTest.fullName
                        sourceNode = string.format("main%d",
                                                   arg.action.actionIdx)
                        diagram = diagram ..
                                  string.format("    %s(%s: %s)\n", sourceNode,
                                                mainTestName, sourceAction.name)
                    else
                        sourceAction = actions[arg.action.actionIdx]
                        sourceNode = string.format("A%d", arg.action.actionIdx)
                        if sourceAction.testIdx ~= testIndex then

                            local sourceTest =
                            allTests[dagName][sourceAction.testIdx]
                            local sourceTestName = sourceTest.fullName
                            diagram = diagram ..
                                      string.format("    %s(%s: %s)\n",
                                                    sourceNode, sourceTestName,
                                                    sourceAction.name)
                        end
                    end
                    -- connect
                    diagram = diagram ..
                              string.format("    %s -.-> A%d\n", sourceNode, i)
                end
            end
        end
    end
    local result = string.format(
                   "```mermaid\nflowchart\n    classDef actionclass fill:#9FF3B9\n%s\n```\n",
                   diagram)
    return result
end

local function generateTestModesToc(modes)
    local result = ""
    for _, key in ipairs(modes) do
        result = result ..
                 string.format("1. [%s](#%s)\n", key, stringToAnchor(key))
    end
    return result
end

local function generateTestConditions(test)
    local products = test.product ~= nil and table.concat(test.product, ", ") or
                     "all"
    local stationTypes = test.stationType ~= nil and
                         table.concat(test.stationType, ", ") or "all"

    local results = "**Conditions:**\n\n"
    results = results .. string.format("* Products: %s\n", products)
    results = results .. string.format("* Station Types: %s\n", stationTypes)
    if test.Conditions ~= nil and test.Conditions ~= "" then
        results = results ..
                  string.format("* Conditions: %s\n", test.Conditions)
    end
    return results .. "\n"
end

function M.generateCoverageMarkdown(coverage, outputPath)

    -- Copy test mode names into an array to be able to sort it alphabetically.
    -- This is required to preserve the same order of coverages every time diagrams are generated.
    local modes = {}
    for testMode in pairs(coverage[common.TEST_PLAN_FOR_MODES]) do
        table.insert(modes, testMode)
    end
    table.sort(modes)

    local result = "# Test Modes\n\n"
    result = result .. generateTestModesToc(modes) .. "\n\n"

    for _, testMode in ipairs(modes) do
        local cov = coverage[common.TEST_PLAN_FOR_MODES][testMode]
        result = result .. string.format("## %s\n\n", testMode)

        local mainActions = cov.mainActions
        local mainTests = cov.mainTests
        local teardownActions = cov.teardownActions
        local teardownTests = cov.teardownTests
        local allTests = { main = mainTests, teardown = teardownTests }
        local allActions = { main = mainActions, teardown = teardownActions }

        -- Main test sequence
        result = result .. "**Main Test Sequence**\n\n"
        result = result .. generateTestDiagram(testMode, mainTests) .. "\n\n"

        local hasTeardown = (teardownTests ~= nil and #teardownTests > 0)

        if hasTeardown then
            -- Teardown test sequence
            result = result .. "**Teardown Test Sequence**\n\n"
            result = result .. generateTestDiagram(testMode, teardownTests) ..
                     "\n\n"
        end

        for index, test in ipairs(mainTests) do
            result = result ..
                     string.format("### %s\n\n",
                                   testMode .. ' ' .. test.fullName)
            result = result .. generateTestConditions(test)
            result = result .. "**Sequence:**\n\n"
            result = result ..
                     generateCoverageDiagram(allActions, index, allTests, 'main')
        end
        if hasTeardown then
            for index, test in ipairs(teardownTests) do
                result = result ..
                         string.format("### %s\n\n",
                                       testMode .. ' ' .. test.fullName)
                result = result .. generateTestConditions(test)
                result = result .. "**Sequence:**\n\n"
                result = result ..
                         generateCoverageDiagram(allActions, index, allTests,
                                                 'teardown')
            end
        end
    end

    writeStringToFile(outputPath, result)
end

return M
