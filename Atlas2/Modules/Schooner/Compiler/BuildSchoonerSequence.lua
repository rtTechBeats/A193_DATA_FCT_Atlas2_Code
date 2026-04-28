#!/usr/bin/env AtlasGroupProcess

-----------------------
-- ## BuildSchoonerSequence
--
-- Convert Schooner Main CSV & test definitions in YAML to targetPath in Lua
-- Expected to run in AtlasGroupProcess, getting input arguments from coreless plist
-- @author Robert Kaluhiokalani
-- @copyright 2021
-- @script BuildSchoonerSequence
-----------------------
-- set package.path and package.cpath by
-- 1. get path of current file: BuildSchoonerSequence.lua
-- 2. get Atlas2 Modules folder by trimming the filename and get its upper 2 level folder
--    because BuildSchoonerSequence.lua is in Modules/Schooner/Compiler
-- 3. set package.path to the Modules folder
-- 4. set package.cpath to Modules/Mooncake
local function setLuaLoadPath()
    local info = debug.getinfo(1, 'S')
    -- trim starting @ from info.source
    local compilerExecutable = info.source:gsub('^@', '')
    local compilerPath =
    compilerExecutable:gsub('BuildSchoonerSequence.lua', '')

    -- this file is in Modules/Schooner/Compiler/
    local atlas2ModulesPath = compilerPath .. '/../../'
    -- adding Compiler/ folders to lua path, for AtlasLua/Lua
    package.path = atlas2ModulesPath .. '/?.lua;'
    package.path = package.path .. atlas2ModulesPath .. '/?/init.lua;'

    -- to load mooncake_0.so in Modules/Mooncake/
    package.cpath = atlas2ModulesPath .. '/Mooncake/?.so'
end

setLuaLoadPath()

local C = require('Schooner.Compiler.Compiler')
local E = require('Schooner.Compiler.Errors')
local common = require('Schooner.SchoonerCommon')

local CompilerArgs = {}
CompilerArgs.__index = CompilerArgs

function CompilerArgs.new(args)
    if args == nil then
        E:emptyCompilerPlistKeys()
    end
    local self = setmetatable({}, CompilerArgs)
    self:setAndValidateKey(args)
    return self
end

function CompilerArgs:setAndValidateKey(args)
    -- create a copy of args
    local validKeys = common.compilerPlistKeys
    for k, v in pairs(args) do
        local expectedType = validKeys[k]
        if expectedType == nil then
            E:unexpectedCompilerPlistKey(k, validKeys)
        end
        if type(v) ~= expectedType then
            E:unexpectedCompilerPlistKeyType(k, v, expectedType)
        end
        self[k] = v
    end
end

-- coreless GroupArgs: 1 key-value dictionary
-- key: PrimaryAtlas2; value: string
-- key: SecondaryAtlas2; value: array of string
-- key: SkipActionPresenceCheck; value: boolean
-- key: SkipSequenceFlowchartMarkdownGeneration; value: boolean
local function getCompilerArgsFromGroupArgs()
    local args = CompilerArgs.new(Group.args[1])
    return args
end

function main()
    local args = getCompilerArgsFromGroupArgs()
    C.compileAndVerifyAtlas2Folders(args.PrimaryAtlas2, args.SecondaryAtlas2,
                                    args.SkipActionPresenceCheck,
                                    args.SkipSequenceFlowchartMarkdownGeneration)
end
