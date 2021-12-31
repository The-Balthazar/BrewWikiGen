--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

-- returns the index of the first matching value in array
function arrayFind(array, str)
    if not array then return end
    for i, v in ipairs(array) do
        if v == str then
            return i
        end
    end
end

-- returns the first string from an array that contains the given substring
function arraySubFind(array, str)
    if not array then return end
    for i, v in ipairs(array) do
        if string.find(v, str) then
            return v
        end
    end
end

-- retuns the first string in an array with a specific substring
function arrayFindSub(array, n, m, str)
    if not array then return end
    for i, v in ipairs(array) do
        if string.sub(v, n, m) == str then
            return v
        end
    end
end

-- returns false if t2 has any child or grandchild values that don't match something in t1, else true
function arraySubset(t1, t2)
    for k, v in ipairs(t1) do
        if type(v) == 'table' then
            for t, p in ipairs(v) do
                if t2[k][t] ~= p then return end
            end
        else
            if t2[k] ~= v then return end
        end
    end
    return true
end

function arrayEqual(t1, t2)
    return arraySubset(t1, t2) and arraySubset(t2, t1)
end

-- Returns the value (or true if it's falsy) if all cells match eachother.
function arrayAllCellsEqual(t)
    for i=1, #t do
        if t[1] ~= t[i] then return end
    end
    return t[1] or true
end

function arrayRemoveByValue(t, val)
    local i = arrayFind(t, val)
    return i and table.remove(t, i)
end

function tableHasTrueChild(hash)
    if not hash then return end
    for k, v in pairs(hash) do
        if v then
            return true
        end
    end
end

-- Returns a new table which is a shallow copy of t1 with t2 shallow-copied over it
function tableOverwrites(t1, t2)
    local new = {}
    if t1 then
        for k, v in pairs(t1) do
            new[k] = v
        end
    end
    if t2 then
        for k, v in pairs(t2) do
            new[k] = v
        end
    end
    return new
end

-- shallow copies t2 into t1, returns t1 for good measure, but the original t1 reference would be the same
function tableMergeCopy(t1, t2)
    if t1 and t2 then
        for k, v in pairs(t2) do
            t1[k] = v
        end
    end
    return t1
end

-- #t for keyed tables
function tableTcount(t)
    local num = 0
    for i, v in pairs(t) do
        num = num+1
    end
    return num
end

-- Returns the number of grandchild elements. (Children of children, and no further)
function tableSubcount(t)
    local num = 0
    for i, v in pairs(t) do
        num = num + #v
    end
    return num
end

-- Returns the sum value of all children values
function tableSum(t)
    local total = 0
    for i, v in pairs(t) do
        total = total + v
    end
    return total
end

-- count of all true children
function BinaryCounter(t)
    local n = 0
    for i, v in pairs(t) do
        n = n + (v and 1 or 0)
    end
    return n
end

-- deep table navigation without risk of nil index error
-- input resembles : `bp.Defense, 'Shield', 'ShieldRegenRate'`
-- returns : bp.Defense.Shield.ShieldRegenRate if it exists, else false
function tableSafe(target, ...)
    if not target then return end
    for i, t in ipairs{...} do
        if target[t] then
            target = target[t]
        else return end
    end
    return target
end
