
local function tableLen(a)
    local n = 0
    for i, v in pairs(a) do
        n = n+1
    end
    return n
end

local function arrayMaxI(a)
    local n
    for i, v in pairs(a) do
        n = not n and i or math.max(n, i)
    end
    return n
end

local function is_Sequential_Unbroken_OneIndexed_Array(val)
    return tableLen(val) == #val and arrayMaxI(val) == #val
end

local function indent(depth)
    return string.rep('    ', depth)
end

local inlineTableSerializer, serialiseValue

function serialiseValue(value)
    local valtype = type(value)
    if valtype == 'table' then
        print('This bp has an unexpected table and may look ugly')
        return inlineTableSerializer('', value)
    elseif (valtype == 'number' or valtype == 'boolean') then
        return tostring(value)
    end
    return string.format("%q", tostring(value))
end

function inlineArraySerializer(str, section)
    str = str..'{ '
    for k, v in sortedpairs(section) do
        str = str..serialiseValue(v)..', '
    end
    return str:gsub(', $', ' }')
end

function inlineTableSerializer(str, section)
    str = str..'{ '
    for k, v in sortedpairs(section) do
        str = str..k..' = '..serialiseValue(v)..','..(' '):rep(math.max(1, 6-serialiseValue(v):len()))
    end
    return str:gsub(',[ ]*$', ' }')
end

local function has_type_children(section, chosen)
    for k, v in pairs(section) do
        if type(v) == chosen then
            return true
        end
    end
end

local function has_only_type_children(section, chosen)
    for k, v in pairs(section) do
        if type(v) ~= chosen then
            return false
        end
    end
    return true
end

function bpsortpairs(set, sort)
    local keys = {}
    for k, v in pairs(set) do
        table.insert(keys, k)
    end

    local function sortNonTableFirst(a, b)
        local typeA, typeB = type(set[a]), type(set[b])
        if typeA == typeB then
            return a < b
        elseif typeA == 'table' or typeB == 'table' then
            return typeA ~= 'table'
        end
        return a < b
    end

    local function sortFilter(n)
        local namefilters = {
            {'^(CollisionOffset)', 'Size%1'},
            {'^(Mesh)(Name)$', 'Z0%2%1'},
            {'^(Albedo)(Name)$', 'Z1%2%1'},
            {'^(Normals)(Name)$', 'Z2%2%1'},
            {'^(Specular)(Name)$', 'Z3%2%1'},
        }
        if type(n) == 'string' then
            for i, subs in ipairs(namefilters) do
                n = n:gsub(subs[1], subs[2])
            end
            return n
        else
            return n
        end
    end

    local function sortDescriptionFirst(a, b)
        if a == 'Description' or b == 'Description' then
            return a == 'Description'
        end
        if type(a) == 'number' and type(b) ~= 'number' then
            print("WARNING: Blueprint contains mixed number/string keys in a table", a, b)
            return true
        end
        if type(a) ~= 'number' and type(b) == 'number' then
            print("WARNING: Blueprint contains mixed number/string keys in a table", a, b)
            return false
        end
        return sortFilter(a) < sortFilter(b)
    end

    -- Sort CollisionOffset next to size?

    table.sort(keys, sortDescriptionFirst)

    local i = 0
    return function()
        i = i+1
        return keys[i], set[ keys[i] ]
    end
end

local reserved = {
    ['and']    = 'and',
    ['break']  = 'break',
    ['do']     = 'do',
    ['else']   = 'else',
    ['elseif'] = 'elseif',

    ['end']      = 'end',
    ['false']    = 'false',
    ['for']      = 'for',
    ['function'] = 'function',
    ['if']       = 'if',

    ['in']    = 'in',
    ['local'] = 'local',
    ['nil']   = 'nil',
    ['not']   = 'not',
    ['or']    = 'or',

    ['repeat'] = 'repeat',
    ['return'] = 'return',
    ['then']   = 'then',
    ['true']   = 'true',
    ['until']  = 'until',
    ['while']  = 'while',
}

local function subInlineArraySerializer(str, section, depth)
    str = str .. "{\n"
    for k, v in ipairs(section) do
        str = str..indent(depth)..inlineTableSerializer('', v)..',\n'
    end
    return str..indent(depth-1)..'}'
end

local specificTableSerializer = {
    Audio = function(str, sounds, depth)
        local maxKeySize, maxBankSize, maxCueSize = 0, 0, 0

        for k, v in pairs(sounds) do
            if type(v) == 'table' then
                maxKeySize = math.max(maxKeySize, string.len(k))
                maxBankSize = math.max(maxBankSize, string.len(v.Bank))
                maxCueSize = math.max(maxCueSize, string.len(v.Cue))
            else
                print('WARNING: non-table value in audio table. Discarding ', k, v)
                sounds[k] = nil
            end
        end

        str = str .. "{\n"
        for k, v in sortedpairs(sounds) do
            str = str..indent(depth)
            ..k..(' '):rep(maxKeySize-string.len(k)+1)
            ..'= Sound { Bank = \''..v.Bank..'\','..(' '):rep(maxBankSize-string.len(v.Bank)+1)
            ..'Cue = \''..v.Cue..'\','..(' '):rep(maxCueSize-string.len(v.Cue)+1)
            ..(v.LodCutoff and 'LodCutoff = \''..v.LodCutoff..'\'' or '')
            ..' },\n'
        end
        return str..indent(depth-1)..'}'
    end,
    RaisedPlatforms = function(str, points, depth)
        str = str .."{\n"..indent(depth)..'--X,     Z,     height -- Offsets from center\n\n'
        local mod12Comments = {
            [3] = 'Top left',
            [6] = 'Top right',
            [9] = 'Bottom left',
            [0] = 'Bottom right',
        }
        for i, point in ipairs(points) do
            local m3, m12 = i%3, i%12
            if i%3 == 1 then
                str = str..indent(depth)
            end
            str = str..tostring(point)..','..(' '):rep(math.max(1, 6-tostring(point):len()))
            if i%3 == 0 then
                if mod12Comments[m12] then
                    str = str..'  --'..mod12Comments[m12]
                end
                str = str..'\n'
            end
            if i%12 == 0 and points[i+1] then
                str = str..'\n'
            end
        end
        return str..indent(depth-1)..'}'
    end,
    --Orientations = inlineArraySerializer,
    RollOffPoints = subInlineArraySerializer,
    BlinkingLights = subInlineArraySerializer,
    DamageEffects = subInlineArraySerializer,
}

local function tableSerialize(str, val, key, depth)
    if next(val) then
        if specificTableSerializer[key] then
            str = specificTableSerializer[key](str, val, depth + 1)
        elseif is_Sequential_Unbroken_OneIndexed_Array(val) then
            if #val == 1 and 'table' ~= type(val[1]) then
                str = inlineArraySerializer(str, val)
            elseif has_only_type_children(val, 'number') and #val < 5 then
                str = inlineArraySerializer(str, val)
            else
                str = str .. "{\n"
                for i, v in ipairs(val) do
                    str = str .. blueprintSerialize(v, i, depth + 1) .. ",\n"
                end
                str = str .. indent(depth) .. '}'
            end
        else
            if tableLen(val) == 1 and not has_type_children(val, 'table') then
                str = inlineTableSerializer(str, val)
            else
                str = str .. "{\n"
                for k, v in bpsortpairs(val) do --sortedpairs(val) do--
                    if type(k) == 'number' then
                        k = '['..tostring(k)..']'
                    elseif k:find'^%A' or k:find'[^%w_]' or reserved[k] then
                        k = string.format("[%q]", tostring(k) )
                    end
                    str = str .. blueprintSerialize(v, k, depth + 1) .. ",\n"
                end
                str = str .. indent(depth) .. '}'
            end
        end

    else
        str = str .. '{}'
    end
    return str
end

local tableNameMap = {
    Beam       = 'BeamBlueprint',
    Mesh       = 'MeshBlueprint',
    Prop       = 'PropBlueprint',
    Emitter    = 'EmitterBlueprint',
    Projectile = 'ProjectileBlueprint',
    Trail      = 'TrailEmitterBlueprint',
    Unit       = 'UnitBlueprint',
    Sound      = 'Sound',
}

-- key and depth only to be used by the self-calls
function blueprintSerialize(val, key, depth)
    depth = depth or 0
    str = indent(depth)
    local valtype = type(val)
    if type(key) ~= 'number' then
        local metaname = valtype == 'table' and tableNameMap[getmetatable(val).__name]
        str = str..(key and (key..' = '..(metaname or '')) or (metaname or 'return '))
    end

    if valtype == 'table' then
        str = tableSerialize(str, val, key, depth)

    else
        str = str .. serialiseValue(val)
    end

    return str
end
