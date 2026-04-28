local runner = require('Schooner.ConditionRunner')

function main(name, generator, validator)
    local value = runner.runConditionGenerator(name, generator)
    runner.runConditionValidator(name, validator, value)
    return value
end
