local runner = require('Schooner.ConditionRunner')

function main(name, validator, value)
    runner.runConditionValidator(name, validator, value)
    return value
end
