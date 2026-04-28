local tree = {}
tree.__index = tree

-- Class to build a tree from CSV entries.
-- Each layer of the tree is for a key (ex: Layer 1 = Technology, Layer 2 = Coverage).
-- Example tree that support 3 keys with a few values in leaf nodes:
--         {T1, T2}
--         /      \
--       {C1}    {C2}
--        /           \
--    {P1={}, P2={}}  {Px={}}
-- Tree leaf (root[T1][C1][P1]) stores the test/limit item.

-- WARNING: This implementation assumes the tree is constructed/traversed
-- in the particular order of self.keys
-- E.g. if the tree is constructed with {Tech, Cov, TestParameters},
-- methods like add and find should always assume this order
-- for their args (row and values, resp.)

function tree.new(csvContent, keys, duplicateHandler)
    local self = setmetatable({}, tree)
    self.csvContent = csvContent
    self.tree = {}
    self.keys = keys

    local message = "[Internal] duplicateHandler in tree "
    message = message .. "must be a function, but got %s"
    message = message:format(type(duplicateHandler))
    assert(type(duplicateHandler) == 'function', message)
    self.duplicateHandler = duplicateHandler
    return self
end

function tree:buildTree()
    for _, row in ipairs(self.csvContent) do
        self:add(row, self.tree, 1)
    end
end

-- Recursively adds an array of values into tree
-- @arg     row         array of strings
-- @arg     root        root of (sub)tree to start adding
-- @arg     keyPtr      index of self.keys for current level in tree
function tree:add(row, root, keyPtr)
    local node = root
    local keys = self.keys

    for k = keyPtr, #keys do
        -- Product/StationType can be nil if not used & not defined
        -- If used -> defined -> empty replaced with IN
        local field = row[keys[k]] or ''
        if type(field) == 'string' then
            node[field] = node[field] or {}
            node = node[field]
            if k == #keys then
                self.duplicateHandler(row, node)
            end
        elseif type(field) == 'table' then
            local prev = node
            for _, val in ipairs(field) do
                node[val] = node[val] or {}
                node = node[val]
                if k < #keys then
                    -- Recurse with current node as root, skipping to next key
                    self:add(row, node, k + 1)
                else
                    -- Looking at leaf
                    self.duplicateHandler(row, node)
                end
                -- Once done, point node to previous level
                node = prev
            end
            return
        end
    end
end

-- @arg values      array of strings to search as nodes in tree
-- returns found node; error otherwise
function tree:find(values)
    local node = self.tree
    for _, value in ipairs(values) do
        if node == nil then
            error('value not found: ' .. value)
        end
        node = node[value]
    end
    return node
end

return tree
