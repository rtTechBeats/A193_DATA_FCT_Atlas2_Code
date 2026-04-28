-- empty action as starting action for a test with condition.
-- Currently choice node's choice path can only point to an action resolvable.
-- so if I want to do "if action return true, run test A",
-- I need to create this dummy startion action x for A,
-- strong order x to test A's all critical actions,
-- then route the choice node to x.
-- this can be improved if Atlas support routing to a Test resolvable in choice path.
function main() end
