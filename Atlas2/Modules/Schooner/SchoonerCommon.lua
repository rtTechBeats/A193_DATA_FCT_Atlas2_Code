-- File to store constants shared across files
local common = {}

-- Start: Compiler output table keys
common.MAIN = 'main'
common.TEARDOWN = 'teardown'
common.TESTS = 'Tests'
common.ACTIONS = 'Actions'
common.LIMITS = 'limits'
common.CONDITIONS = 'conditions'
common.SAMPLING = 'samplings'
common.LIMIT_INFO = 'limitInfo'
common.TEST_PLAN_ATTRIBUTE = 'testPlanAttribute'
common.TEST_PLAN_FOR_MODES = 'testPlanForModes'
-- Defines actions for which certain Lua modules would need to be
-- replaced at scheduling time for testing purposes (Lua modules mocking)
common.MODULE_REPLACEMENTS = 'moduleReplacements'

common.MAIN_TESTS = common.MAIN .. common.TESTS
common.MAIN_ACTIONS = common.MAIN .. common.ACTIONS
common.TEARDOWN_TESTS = common.TEARDOWN .. common.TESTS
common.TEARDOWN_ACTIONS = common.TEARDOWN .. common.ACTIONS
-- End: Compiler output table keys

-- Start: Shared column names
common.SHARED_COLUMNS = {
    Technology = 'Technology',
    Coverage = 'Coverage',
    TestParameters = 'TestParameters',
    Product = 'Product',
    StationType = 'StationType',
    Mode = 'Mode'
    -- TODO: add more here
}
-- End: Shared column names

-- Start: Coverage/limit filters
common.MODE = 'mode'
common.PRODUCT = 'product'
common.STATION_TYPE = 'stationType'

common.ALL_FILTERS = {
    [common.SHARED_COLUMNS.Product] = common.PRODUCT,
    [common.SHARED_COLUMNS.StationType] = common.STATION_TYPE,
    [common.SHARED_COLUMNS.Mode] = common.MODE
}
-- End: Coverage/limit filters

-- Start: Keys for Reserved conditions
common.RESERVED_CONDITIONS = {
    NOCL = 'NoCl',
    ENABLE_SAMPLING = 'EnableSampling',
    PRODUCT = 'Product',
    MODE = 'Mode',
    STATIONTYPE = 'StationType'
}
common.ENABLE_SAMPLING_VALIDATOR =
{ type = 'IN', allowedList = { "YES", "NO" } }
common.NOCL_FLAG_DUT = "NoCl"
common.DUT = "dut"
-- End: Keys for Reserved conditions

-- Start: Keys for conditions
common.CONDITION_TYPE = { 'group', 'init', 'test' }
common.CONDITION_REMOVE_TYPE = { 'group', 'init' }
common.CONDITION_WHEN = { 'Group', 'Init', 'Test' }
-- End: Keys for conditions

-- Start: Fields for format checking
common.TECHNOLOGY = 'technology'
common.COVERAGE = 'coverage'
common.TEST_PARAMETERS = 'testParameters'
common.VARIABLE_NAME = 'varName'
common.CONDITION_NAME = 'conditionName'
common.SAMPLE_GROUP_SAMPLE_TABLE = 'sampleGroupName'
common.SAMPLE_GROUP_MAIN_TABLE = 'SamplingGroup'
-- End: Fields for format checking

-- Start: limit field names
common.RELAXED_LOWER_LIMIT = 'RelaxedLowerLimit'
common.LOWER_LIMIT = 'LowerLimit'
common.UPPER_LIMIT = 'UpperLimit'
common.RELAXED_UPPER_LIMIT = 'RelaxedUpperLimit'
-- End: limit field names

-- Start: Limit version
common.INSIGHT_SOFTWARE_VERSION_LENGTH_MAX = 48
common.LIMIT_VERSION_HASH_LENGTH = 7
-- End: Limit version

-- Start: Test definition keys
-- A nested table which defines the data-type and required/optional keys at each level.
-- Each (required/optional) key must have a dataType, which is an array of allowed Lua types for that key.
-- Ex: plugins.dataType = {'table', 'string'}
common.TEST_DEF_KEYS = {
    dataType = { 'table' },
    requiredKeys = {
        technology = { dataType = { 'string' } },
        coverage = { dataType = { 'string' } },
        testParameters = { dataType = { 'string' } },
        sequence = {
            dataType = { 'table' },
            requiredKeys = {
                actions = {
                    dataType = { 'table' },
                    requiredKeys = { filename = { dataType = { 'string' } } },
                    optionalKeys = {
                        args = {
                            -- List of user defined values. No subkeys.
                            dataType = { 'table' }
                        },
                        plugins = {
                            -- List of user defined values, or '*'. No subkeys.
                            dataType = { 'table', 'string' }
                        },
                        policy = { dataType = { 'string' } },
                        background = { dataType = { 'boolean' } },
                        deps = {
                            -- List of user defined values. No subkeys.
                            dataType = { 'table' }
                        },
                        dataQuery = { dataType = { 'boolean' } }
                    }
                }
            },
            optionalKeys = {
                -- 'type' is the name of a key
                type = { dataType = { 'string' } }
            }
        }
    },
    optionalKeys = {
        inputs = {
            -- User defined keys and values, so no required/optional subkeys
            dataType = { 'table' }
        },
        outputs = {
            dataType = { 'table' },
            requiredKeys = { lookup = { dataType = { 'table' } } }
        },
        conditions = {
            dataType = { 'table' },
            requiredKeys = { lookup = { dataType = { 'table' } } }
        }
    }
}
-- End: Test definition keys

common.actionsType = { sequential = 'sequential', graph = 'graph' }

-- Start: Keys in compiler output
common.REQUIRED_COVERAGE_KEYS = {
    'mainActions',
    'mainTests',
    'limits',
    'testPlanAttribute'
}
common.OPTIONAL_COVERAGE_KEYS = {
    'samplings',
    'conditions',
    'teardownTests',
    'teardownActions',
    'limitInfo',
    'DisableOrphanedRecordChecking'
}
-- End: Keys in compiler output

-- Start: Magic numbers
common.NUM_FIELDS_IN_DEPS = 3
common.NUM_LIMIT_SPEC = 4
common.NUM_ACTION_SPEC = 4
common.NUM_TEST_SPEC = 3
common.NUM_VAR_SPEC = 4
common.NUM_HEADER_LINES = 1
common.MAX_LENGTH_OF_STATION_VERSION_WITH_DIVIDER = 47
common.MAX_LENGTH_OF_STATION_VERSION = 48
common.DEVICE_RESULT_RETURN_IDX = 4
-- End: Magic numbers

-- Start: ConditionEvaluator token type
common.TOKEN_TYPE_IDENTIFIER = 'identifier'
common.TOKEN_TYPE_OPERATOR = 'operator'
common.TOKEN_TYPE_VALUE = 'value'
common.TOKEN_TYPE_QUOTED_STRING = 'quotedString'
common.TOKEN_TYPE_GROUP = 'group'
-- End: ConditionEvaluator token type

-- Start: Special characters to escape in testParameters
-- E.g. These are the magic characters in Lua patterns, except for '*' (allowed for wildcard matches)
-- '[' and ']' are also omitted since they are not allowed in testParameters from loop syntax
-- '%' is handled separately
common.MAGIC_CHARACTERS = { '%(', '%)', '%.', '%+', '%-', '%?', '%^', '%$' }
-- End: Special characters to escape in testParameters

-- Start: Format style for various fields
-- Formats applied to each field during compilation.
common.FIELD_FORMAT = {
    [common.TECHNOLOGY] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9-]*',
        ['isRequired'] = true
    },
    [common.COVERAGE] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9-]*',
        ['isRequired'] = true
    },
    -- Shark: before adding loop support, TestParameters can be any printable char
    -- including alphanumers + all punctuation: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~)
    -- Adding loop means [] is blocked.
    -- TODO: need to check if we should allow the others
    [common.TEST_PARAMETERS] = { ['format'] = '[^%[%]]*', ['isRequired'] = false },
    [common.VARIABLE_NAME] = {
        ['format'] = '[_a-zA-Z][_a-zA-Z0-9]*',
        ['isRequired'] = true
    },
    [common.CONDITION_NAME] = {
        ['format'] = '^[a-zA-Z_][0-9a-zA-Z_]*$',
        ['isRequired'] = true
    },
    [common.SAMPLE_GROUP_SAMPLE_TABLE] = {
        ['format'] = '^[a-zA-Z_][0-9a-zA-Z_]*$',
        ['isRequired'] = true
    },
    [common.SAMPLE_GROUP_MAIN_TABLE] = {
        ['format'] = '^[a-zA-Z_][0-9a-zA-Z_]*$',
        ['isRequired'] = false
    },
    [common.MODE] = { ['format'] = '^[A-Z][a-zA-Z0-9_]*', ['isRequired'] = false },
    [common.PRODUCT] = { ['format'] = '.+', ['isRequired'] = false },
    [common.STATION_TYPE] = { ['format'] = '.+', ['isRequired'] = false }
}
common.dependencyFormat = '{([%s%w-_.,"\'/]+)}'
-- End: Format style for various fields

-- Special Technology in Limit table to disable orphaned record checking
common.DisableOrphanedRecordChecking = 'DisableOrphanedRecordChecking'

common.operatorMap = {
    ['=='] = 'EQ',
    ['~='] = 'NE',
    ['>'] = 'GT',
    ['<'] = 'LT',
    ['>='] = 'GE',
    ['<='] = 'LE',
    ['('] = 'LP',
    [')'] = 'RP'
}

-- Key meanings:
-- TestConditions - conditions used in Conditions column of Main.csv
-- TestFilters - Mode/Product/StationType used in Main.csv
-- yamlInputs - conditions used in yaml test block inputs key
-- yamlConditions - conditions used in yaml test block conditions key (e.g. generating test conditions)
-- LimitConditions - conditions used in Conditions column of Limits.csv
-- LimitFilters - Mode/Product/StationType used in Limits.csv
-- LimitRequired - conditions used in Required column
common.conditionUsage = {
    testConditions = true,
    testFilters = true,
    yamlInputs = true,
    yamlConditions = true,
    limitConditions = true,
    limitFilters = true,
    limitRequired = true
}

common.separators = {
    PARALLEL = 'PARALLEL',
    TEARDOWN = 'TEARDOWN',
    PHASE = 'PHASE'
}

local assets = '/Assets/'
local schoonerAssets = assets .. 'Coverage/'
-- all path are based on Atlas2/
common.compilerDefaultLocations = {
    main = { path = schoonerAssets .. 'MainTable.csv' },
    limit = { path = schoonerAssets .. 'LimitsTable.csv' },
    condition = { path = schoonerAssets .. 'ConditionTable.csv' },
    sample = { optional = true, path = schoonerAssets .. 'SampleTable.csv' },
    limitTableVersion = {
        optional = true,
        path = schoonerAssets .. 'LimitTableVersion.txt'
    },
    output = { path = '/Modules/coverage/coverage.lua' },
    -- destination of sequence markdown using mermaid syntax
    markdown = { path = schoonerAssets .. 'SequenceFlowchart.md' },
    -- multiple
    testDefinition = {
        multiple = true,
        path = schoonerAssets .. 'TestDefinitions'
    },
    plists = { optional = true, multiple = true, path = '/Config' },
    actions = { optional = true, multiple = true, path = '/Actions' }
}

-- option in config file should be useful both when compile in mink and on station
-- currently we don't have such a case so keep the code here
-- but does not expect any key.
common.compilerConfig = {
    -- $ATLAS_ASSETS to be replaced by real Atlas2 assets folder.
    filePath = schoonerAssets .. 'CompilerSetting.yaml',
    keys = {}
}

STRING = 'string'
BOOLEAN = 'boolean'
TABLE = 'table'

-- plist keys in compiler plist used by AtlasGroupProcess
-- Internal keys; station should not use this directly.
common.compilerPlistKeys = {
    PrimaryAtlas2 = STRING,
    SecondaryAtlas2 = TABLE,
    SkipActionPresenceCheck = BOOLEAN,
    SkipSequenceFlowchartMarkdownGeneration = BOOLEAN
}

return common
