-------------------------------------------------------------------
----***************************************************************
---- Auto require FixtureControl
----***************************************************************
-------------------------------------------------------------------
local constant = require("INVT/constants")
local Log = require("Common/logging")
local FixtureControl = {}


if constant.Fixture["FIXTURE_TYPE"] == 'uart' then
    FixtureControl = require("INVT/Modules/FixtureControl/FixtureUart")
elseif constant.Fixture["FIXTURE_TYPE"] == 'stream' then
    FixtureControl = require("INVT/Modules/FixtureControl/FixtureStream")
elseif constant.Fixture["FIXTURE_TYPE"] == 'simulator' then
    FixtureControl = require("INVT/Modules/FixtureControl/FixtureSimulator")
else
    Log.LogInfo("======ERROR: Undefined Fixture Type! ======")
    error("Undefined Fixture Type!")
end


return FixtureControl
