--[[
--! @defgroup securityutils Security Utilities
--! @{
--]] local SecurityUtils = {version = "1.2.18"}
local FileUtils = require "ALE.FileUtils"
local TypeUtils = require "ALE.TypeUtils"

--[[
--! @brief Converts string to binary representation as hex formatted string
--! @note Takes the input string, converts to byte representation (utf8) and creates a hex formatted string
--! @param code String, input string to be converted to hex
--]]
local function string2hexbytes(code)
    local s = ""
    for _, c in utf8.codes(code) do
        s = s .. string.format("%02X", c)
    end
    return s
end

--[[
--! @brief Generate a hash of a string
--]]
local function generateDigest(utilities, code, hash)
    assert(utilities, "Creating digest requires Atlas Utilities plugin instance")
    assert(#code > 0, "ERROR! String is empty [" .. tostring(code) .. "]. Cannot generate digest.")

    -- convert to a hex string
    local hexstring = string2hexbytes(code)
    print("Created hex string from code:\t [" .. hexstring .. "]")

    -- generate the hex string
    local hexdata = utilities.dataFromHexString(hexstring)
    local digest = Security.generateDigest(hexdata, hash)
    local hashStr = utilities.dataToHexString(digest)
    return hashStr
end

--[[
--! @brief Generate hash of a file
--]]
local function generateDigestFromFile(utilities, filepath, hash)
    assert(utilities, "Creating digest of filepath requires Atlas Utilities plugin instance")
    local fileBytes = utilities.readDataFromFile(filepath)
    local digest = Security.generateDigest(fileBytes, hash)
    return utilities.dataToHexString(digest)
end

--[[
--! @brief Produce a single digest from a set of digests.
--! @details Useful for encapsulating the state of the set in a single representation
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param hashlist Table (either array or dictionary) where each value is a digest (string)
--! @param hash Number, matches the Atlas Security.Digests enumeration
--! @returns String, digest of the concatonation of all the values
--]]
local function reduceHash(utilities, hashlist, hash)
    assert(utilities, "Creating digest requires Atlas Utilities plugin instance")
    local concat = ""
    local filelist = {}
    for filename in pairs(hashlist) do
        table.insert(filelist, filename)
    end
    table.sort(filelist)
    for _, v in ipairs(filelist) do
        local encoded = string2hexbytes(hashlist[v])
        concat = concat .. encoded
    end
    local finaldigest = Security.generateDigest(utilities.dataFromHexString(concat), hash)
    return utilities.dataToHexString(finaldigest)
end

--[[
--! @brief Authenticates the signature of the binary contents of a file, based on the public key provided
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param pathToFile Calculates the signature of the file at this path
--! @param pathToSignature Private encrypted key, as bytes
--! @param pathToPublicKey Public key, as bytes
--]]
function SecurityUtils.verifyFileSignature(utilities, pathToFile, pathToSignature, pathToPublicKey)
    assert(utilities, "Verifying file signature requires Atlas Utilities plugin")
    -- File that is desired to be secure
    local manifestBytes = utilities.readDataFromFile(pathToFile)
    -- Encrypted key calculated on the bytes of the file
    local expectedManifestSig = utilities.readDataFromFile(pathToSignature)
    -- Shared public key as bytes
    local publicKey = utilities.readDataFromFile(pathToPublicKey)
    Security.verifySignature(manifestBytes, expectedManifestSig, publicKey)
end

--[[
--! @brief Calculate SHA256 of a file
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param filepath Path to file to generate the digest for
--! @deprecated Function is deprecated. Consider switching to \ref CryptoPlugin "Crypto" plugin instead
--! @return String, the SHA256 as a hex string
--]]
function SecurityUtils.sha256(utilities, filepath)
    return SecurityUtils.generateDigestFromFile(utilities, filepath, Security.Digests.SHA256)
end

--[[
--! @brief Signs a file, using ".sig<filename>" for the signed file.
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param pathToFile String, path to the file to sign
--! @param privateKey String, private key
--! @return String, path to signed (.sig) file
--]]
function SecurityUtils.signFile(utilities, pathToFile, privateKey)
    if not utilities then
        error("Signing file requires Atlas Utilities plugin")
    end

    -- create a signature of the file
    local manifestBytes = utilities.readDataFromFile(pathToFile)
    local manifestSigBytes = Security.generateSignature(manifestBytes, privateKey)

    -- save this signature to a .sig file
    local manifestSigPath = pathToFile .. ".sig"
    utilities.writeDataToFile(manifestSigPath, manifestSigBytes)
    return manifestSigPath
end

--[[
--! @brief Calculate hash of string(s) based on a custom hashing algorithm (defined by Atlas built-ins)
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param code String OR a table array of strings, the string(s) to generate the hash from
--! @param hash Number, matches the Atlas Security.Digests enumeration: Security.Digests.MD5,
--!             Security.Digests.SHA256 etc.
--!     .MD5 : 1
--!     .SHA1 : 2
--!     .SHA224 : 3
--!     .SHA256 : 4
--!     .SHA384 : 5
--!     .SHA512 : 6
--! @deprecated Function is deprecated. Consider switching to \ref CryptoPlugin "Crypto" plugin instead
--! @return A hex string, the hash of the string. If the input is a list of strings,
--!         it returns a table of { original_string : hashed_string } pairs
--]]
function SecurityUtils.generateDigestFromString(utilities, code, hash)
    local o = {}
    if type(code) == type("") then
        o = generateDigest(utilities, code, hash)
    elseif type(code) == type({}) then
        for _, c in ipairs(code) do
            local d = generateDigest(utilities, c, hash)
            o[c] = d -- make { string : hash } pair
        end
        if not next(o) then
            error("Argument must be an array of strings i.e. a list of codes, which will each be hashed individually")
        end
    else
        error("Unknown input argument for code, check input is not nil")
    end
    return o
end

--[[
--! @brief Calculate hash of file(s) based on a custom hashing algorithm (defined by Atlas built-ins).
--! @note This will have the same output as reading out the contents of file as a string and generating
--!       a digest of that string
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param filepath String OR a table array of strings, the file(s) to generate the hash from
--! @param hash Number, matches the Atlas Security.Digests enumeration: Security.Digests.MD5,
--!             Security.Digests.SHA256 etc.
--!     .MD5 : 1
--!     .SHA1 : 2
--!     .SHA224 : 3
--!     .SHA256 : 4
--!     .SHA384 : 5
--!     .SHA512 : 6
--! @deprecated Function is deprecated. Consider switching to \ref CryptoPlugin "Crypto" plugin instead
--! @return A hex string, the hash of the file. If the input is a list of files,
--!         it returns a table of { path_to_original_file : hash_of_file } pairs
--]]
function SecurityUtils.generateDigestFromFile(utilities, filepath, hash)
    local o = {}
    if type(filepath) == type("") then
        o = generateDigestFromFile(utilities, filepath, hash)
    elseif type(filepath) == type({}) then
        for _, c in ipairs(filepath) do
            local d = generateDigestFromFile(utilities, c, hash)
            o[c] = d -- make { filepath : hash } pair
        end
        if not next(o) then
            error("Argument must be an array of strings i.e. a list of codes, which will each be hashed individually")
        end
    else
        error("Unknown input argument for filepath, check input is not nil")
    end
    return o
end

--[[
--! @brief Calculate hash of a folder based on a custom hashing algorithm (defined by Atlas built-ins).
--! @param utilities ALE NSData plugin instance (Atlas.loadPlugin("ALE/NSData"))
--! @param folderpath String, the directory path to calculate the hash from
--! @param hash Number, matches the Atlas Security.Digests enumeration:
--!             Security.Digests.MD5, Security.Digests.SHA256 etc.
--!     .MD5 : 1
--!     .SHA1 : 2
--!     .SHA224 : 3
--!     .SHA256 : 4
--!     .SHA384 : 5
--!     .SHA512 : 6
--! @deprecated Function is deprecated. Consider switching to \ref CryptoPlugin "Crypto" plugin instead
--! @return A hex string, the hash of the folder
--]]
function SecurityUtils.generateDigestFromDirectory(utilities, folderpath, hash)
    TypeUtils.assertString(folderpath)
    local o = {}
    local options = {recursive = true, filesOnly = true}
    local filelist = FileUtils.listDirectory(folderpath, options)
    for _, v in ipairs(filelist) do -- get the full path for all files
        table.insert(o, FileUtils.joinPaths(folderpath, v))
    end
    o = SecurityUtils.generateDigestFromFile(utilities, o, hash)
    return reduceHash(utilities, o, hash)
end

return SecurityUtils

--[[
--! @}
--]]
