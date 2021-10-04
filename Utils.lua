--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Generic table functions
--------------------------------------------------------------------------------

arrayfind = function(array, str)
    if not array then return end
    for i, v in ipairs(array) do
        if v == str then
            return i
        end
    end
end

arraySubfind = function(array, str)
    if not array then return end
    for i, v in ipairs(array) do
        if string.find(v, str) then
            return v
        end
    end
end

arrayfindSub = function(array, n, m, str)
    if not array then return end
    for i, v in ipairs(array) do
        if string.sub(v, n, m) == str then
            return v
        end
    end
end

arraySubset = function(t1, t2)
    for k, v in ipairs(t1) do
        if type(v) == 'table' then
            for t, p in ipairs(v) do
                if t2[k][t] ~= p then
                    return false
                end
            end
        else
            if t2[k] ~= v then
                return false
            end
        end
    end
    return true
end

arrayEqual = function(t1, t2)
    return arraySubset(t1, t2) and arraySubset(t2, t1)
end

arrayAllCellsEqual = function(t)
    if #t == 1 then
        return true
    end
    for i=2, #t do
        if t[i] ~= t[i-1] then
            return false
        end
    end
    return true
end

tableOverwrites = function(t1, t2)
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

tableSubcount = function(t)
    local num = 0
    for i, v in pairs(t) do
        num = num + #v
    end
    return num
end

tableSubcounts = function(t)
    local nums = {}
    for i, v in pairs(t) do
        nums[i] = #v
    end
    return nums
end

tableSum = function(t)
    local total = 0
    for i, v in pairs(t) do
        total = total + v
    end
    return total
end

tableSafe = function(target, ...)
    if not target then
        return false
    end
    for i, t in ipairs{...} do
        if target[t] then
            target = target[t]
        else
            return false
        end
    end
    return target
end

--------------------------------------------------------------------------------
-- Generic string functions
--------------------------------------------------------------------------------

stringSanitiseForWindowsFilename = function(s)
    --I can't be bothered to look up how to regex this
    for i, v in ipairs{ '\\', '/', ':', '*', '?', '"', '<', '>', '|' } do -- Other not safe things I don't care about: '#', '$', '!', '&', "'", '{', '}', '@', '%%',
        s = string.gsub(s, v, '')
    end
    return s
end

stringSanitiseFile = function(s, lower, nospace)
    if type(s) ~= 'string' then return end
    if lower then s = string.lower(s) end
    if nospace then s = string.gsub(s, ' ', '-') end
    return stringSanitiseForWindowsFilename(s)
end

LOC = function(s)
    if type(s) == 'string' and string.sub(s, 1, 4)=='<LOC' then
        local i = string.find(s,">")
        local locK = string.sub(s, 6, i-1)
        if _G[locK] then
            return _G[locK]
        else
            return string.sub(s, i+1)
        end
    end
    return s
end

numberFormatNoTrailingZeros = function(n)
    str = tostring(n)
    if string.sub(str, -2) == '.0' then
        return tonumber(string.sub(str, 1, -3))
    end
    return n
end

hoverTip = function(s1, s2)
    return s1 and ' '..'<span title="'..s1..'" >'..(s2 and s2 or "(<u>?</u>)")..'</span>' or ''
end

pluralS = function(n) return n ~= 1 and 's' or '' end

--------------------------------------------------------------------------------

iconText = function(icon, text, text2)

    text = numberFormatNoTrailingZeros(text)
    text2 = numberFormatNoTrailingZeros(text2)

    local icons = {
        Health = IconRepo..'health.png',
        Regen = IconRepo..'health.png',
        Shield = IconRepo..'shield.png',

        Energy = IconRepo..'energy.png',
        Mass = IconRepo..'mass.png',
        Time = IconRepo..'time.png',

        Build = IconRepo..'build.png',

        Fuel = IconRepo..'fuel.png',
        Attached = IconRepo..'attached.png',
    }
    if icons[icon] and text then
        return '<img src="'..icons[icon]..'" title="'..icon..'" /> '..text..(text2 or '')
    elseif text then
        return text..(text2 or '')
    end
end

transportClassHookType = function(transport)
    local hooks = {
        'Small',
        'Medium',
        'Large',
        nil,
        'Drone',
    }
    return hooks[transport]
end

abilityTitle = function(ability)
    return hoverTip( abilityDesc[ability] or 'error:description', ability)
end

BuildableLayer = function(phys)
    --This script assumes it's a structure. This doesn't matter to non-structures.
    if not phys.BuildOnLayerCaps then
        return 'Land'
    else
        local str = ''
        local IndexedLayers = {
            'LAYER_Land',
            'LAYER_Seabed',
            'LAYER_Sub',
            'LAYER_Water',
            'LAYER_Air',
        }
        for i, key in ipairs(IndexedLayers) do
        --for key, val in pairs(phys.BuildOnLayerCaps) do
            local val = phys.BuildOnLayerCaps[key]
            if val then
                str = str..string.sub(key, 7)..'<br />'
            end
        end
        return str
    end
end

BuilderList = function(bp)
    --local builders = {}
    --local cathash = {}
    local bilst = ''

    if not bp.Economy then return 'error:no eco table' end
    if not bp.Economy.BuildCostEnergy then return 'error:no build cost e' end
    if not bp.Economy.BuildCostMass then return 'error:no build cost m' end
    if not bp.Economy.BuildTime then return 'error:no build time' end

    for i, cat in ipairs(bp.Categories) do
        --cathash[cat] = string.find(cat, 'BUILTBY') and true or nil
        if buildercats[cat] then
            --table.insert(builders, )
            local secs = bp.Economy.BuildTime / buildercats[cat][2]
            bilst = bilst .. "\n* "..iconText('Time', string.format('%02d:%02d', math.floor(secs/60), math.floor(secs % 60) ) )..' ‒ '..iconText('Energy', math.floor(bp.Economy.BuildCostEnergy / secs + 0.5), '/s')..' ‒ '..iconText('Mass', math.floor(bp.Economy.BuildCostMass / secs + 0.5), '/s')..' — Built by '..buildercats[cat][1]
        elseif string.find(cat, 'BUILTBY') then
            bilst = bilst.."\n* <error:category />Unknown build category <code>"..cat.."</code>"
        end
    end

    return bilst
end

CheckCaps = function(hash)
    if not hash then return end
    for k, v in pairs(hash) do
        if v then
            return true
        end
    end
end

SortCaps = function(hash, order)
    if not hash then return end
    if not order then return end
    local array = {}
    for k, v in pairs(hash) do
        table.insert(array, k)
    end
    table.sort(array, function(a, b) return (order[a].preferredSlot or 99) < (order[b].preferredSlot or 99) end)
    return array
end

orderButtonImage = function(orderName, bp)
    local GetOrder = function()
        return tableOverwrites(defaultOrdersTable[orderName], bp and bp[orderName])
    end
    local Order = GetOrder()
    local returnstring

    if Order then
        local Tip = Tooltips[Order.helpText] or {title = 'error:'..Order.helpText..' no title'}
        returnstring = '<img float="left" src="'..IconRepo..'orders/'..string.lower(Order.bitmapId)..'.png" title="'..LOC(Tip.title or '')..(Tip.description and Tip.description ~= '' and "\n"..LOC(Tip.description) or '')..'" />'
    end
    return returnstring or orderName, Order
end

BinaryCounter = function(...)
    local n = 0
    local arg = {...}
    for i, v in pairs(arg) do
        n = n + (v and 1 or 0)
    end
    return n
end

--[[Binary = function(...)
    return --TODO:
end]]

Binary2bit = function(a,b)
    return (a and 2 or 0) + (b and 1 or 0)
end
--binarySwitch = function(a,b,c,d) return (a and 8 or 0) + (b and 4 or 0) + (c and 2 or 0) + (d and 1 or 0) end

GetModInfo = function(dir)
    assert(pcall(dofile, dir..'mod_info.lua'), "⚠️ Failed to load "..dir.."mod_info.lua")
    return {
        name = name,
        description = description,
        author = author,
        version = version,
        icon = icon and true -- A bool because I'm not committing to the dir structure of the mod(s) for the wiki files.
    }
end

GetModBlueprintPaths = function(dir)
    local BlueprintPathsArray = {}

    local FileOrSystemFolder = function(file)
        return (string.find(file, '%.'))
    end

    local GoodBlueprintFile = function(file)
        for i, v in ipairs(BlueprintExclusions) do
            if string.upper(string.sub(file,1, string.len(v))) == string.upper(v) then
                return false
            end
        end
        return (string.lower(string.sub(file,-8,-1)) == '_unit.bp')
    end

    local dirsearch; dirsearch = function(folder, p)
        local file <close> = io.popen('dir "'..folder..'" /b '..(p or ''))
        for line in file:lines() do
            if GoodBlueprintFile(line) then
                table.insert(BlueprintPathsArray, {folder, line})
            elseif not FileOrSystemFolder(line) then
                dirsearch(folder..'/'..line)
            end
        end
    end

    dirsearch(dir..(_G.UnitBlueprintsFolder or ''), '/ad')

    return BlueprintPathsArray
end

GetModHooks = function(ModDirectory)
    local log = 'Loading: '
    for name, fileDir in pairs({
        ['Build descriptions'] = 'hook/lua/ui/help/unitdescription.lua',
           ['US localisation'] = 'hook/loc/US/strings_db.lua',
                  ['Tooltips'] = 'hook/lua/ui/help/tooltips.lua',
    }) do
        log = log..(pcall(dofile, ModDirectory..fileDir) and '🆗 ' or '❌ ')..name..' '
    end
    print(log)
end

local function SetShortId(bp, file)
    local id = bp.BlueprintId or string.gsub(file, "_unit.bp", "")--string.gsub(file, "^.*/([^/]+)_[a-z]+%.bp$", "%1" )
    bp.id = string.lower(id)
    bp.ID = id == bp.id and string.upper(id) or id
end

local function GetUnitTechAndDescStrings(bp)
    -- Tech 1-3 units don't have the tech level in their desc exclicitly,
    -- Experimental *generally* do. This unified it so we don't have to check again.
    for i = 1, 3 do
        if arrayfind(bp.Categories, 'TECH'..i) then
            return i, 'Tech '..i, bp.Description and 'Tech '..i..' '..LOC(bp.Description)
        end
    end
    if arrayfind(bp.Categories, 'EXPERIMENTAL') then
        return 4, 'Experimental', LOC(bp.Description)
    end
    return nil, nil, LOC(bp.Description)
end

function GetBlueprintsFromFile(dir, file)
    local bpfile = io.open(dir..'/'..file, 'r')
    local bpstring = bpfile:read('a')

    bpfile:close()

    bpstring = string.gsub(bpstring, '#', '--')
    bpstring = string.gsub(bpstring, '\\', '/')
    bpstring = string.gsub(bpstring, 'Sound%s*{', '{')
    bpstring = string.gsub(bpstring, 'UnitBlueprint%s*{', 'return {', 1)
    bpstring = string.gsub(bpstring, 'UnitBlueprint%s*{', '{')
    bpstring = string.gsub(bpstring, '}%s*{', '}, {')

    local bps = {load(bpstring)()}

    assert(bps[1], "⚠️ Failed to load "..file)

    for i, bp in ipairs(bps) do
        SetShortId(bp, file)
        bp.unitTIndex, bp.unitTlevel, bp.unitTdesc = GetUnitTechAndDescStrings(bp)
        BlueprintSanityChecks(bp)
    end

    return bps
end

function isValidBlueprint(bp)
    return bp.Display and bp.Categories and bp.Defense and bp.Physics and bp.General
end
