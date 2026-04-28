local FactoryAutomationHelper = {}

function FactoryAutomationHelper.waitForAutomationMessage(groupIndex, automationBridgePlugin, userCallbacks)
    while (true) do
        local messageReceived = automationBridgePlugin.waitForAutomationMessages(groupIndex)
        local fixtureCmd = messageReceived[automationBridgePlugin.FIXTURE_COMMAND_KEY]
        local slotsToTest = messageReceived[automationBridgePlugin.SLOTS_TO_TEST_KEY]

        if (fixtureCmd) then
            local fixtureOperationSuccess = false
            if (fixtureCmd == automationBridgePlugin.FIXTURE_OPEN) then
                fixtureOperationSuccess = userCallbacks["fixtureOpen"]()
            elseif (fixtureCmd == automationBridgePlugin.FIXTURE_CLOSE) then
                fixtureOperationSuccess = userCallbacks["fixtureClose"]()
            else
                error("Unsupported fixture command")
            end
            automationBridgePlugin.confirmFixtureOperationDone(groupIndex, fixtureCmd, fixtureOperationSuccess)

        elseif (slotsToTest) then -- start message received
            return slotsToTest

        else
            error("Unsupported message type received")
        end
    end
end

return FactoryAutomationHelper
