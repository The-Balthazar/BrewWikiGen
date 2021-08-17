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

--------------------------------------------------------------------------------

iconText = function(icon, text, text2)
    --icon = string.lower(icon)
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

--------------------------------------------------------------------------------

IsDeathWeapon = function(wep)
    return (wep.Label == 'DeathWeapon' or wep.Label == 'DeathImpact' or wep.WeaponCategory == 'Death')
end

bitcombine = function(asdf)
    local asd = 0
    for i, v in pairs(asdf) do
        asd = asd + v
    end
    return asd
end

GetTargetLayers = function(weapon, unit)
    local fromLayers = motionTypes[unit.Physics.MotionType][2]
    local targetLayers = {}
    if weapon.FireTargetLayerCapsTable then
        for layer, targetstring in pairs(weapon.FireTargetLayerCapsTable) do
            if fromLayers[layer] then
                --Reusing the layer reference here, because we don't need the other one again.
                for layer, bit in pairs(Layers) do
                    if string.find(targetstring, layer) then
                        targetLayers[layer] = bit
                    end
                end
            end
        end
    end
    if weapon.AboveWaterTargetsOnly then
        targetLayers.Sub = nil
        targetLayers.Seabed = nil
    end
    return targetLayers, bitcombine(targetLayers)
end

WepTarget = function(weapon, unit)
    if IsDeathWeapon(weapon) then
        return nil
    end

    if weapon.TargetType == 'RULEWTT_Projectile' then
        local s = '<code>'..weapon.TargetType..'</code>'
        local mapping = {
            {'STRATEGIC', '(Anti-strategic)'},
            { 'TACTICAL', '(Anti-tactical)'},
            {  'MISSILE', '(Anti-missile)'},
            {  'TORPEDO', '(Anti-torpedo)'},
        }
        for i, cats in ipairs(mapping) do
            if (weapon.TargetRestrictOnlyAllow == cats[1] or string.find(weapon.TargetRestrictOnlyAllow, cats[1])) then
                return s..'<br />'..cats[2]
            end
        end
        return s

    elseif weapon.TargetType == 'RULEWTT_Prop' then
        return '<code>'..weapon.TargetType..'</code><error:prop weapon;its a real thing but why>'

    else --'RULEWTT_Unit' is the default and generally not written
        local s = '<code>RULEWTT_Unit</code>'

        if weapon.TargetRestrictOnlyAllow and (weapon.TargetRestrictOnlyAllow == 'AIR' --[[or string.find(weapon.TargetRestrictOnlyAllow, 'AIR')]]) then
            return s .. '<br />(Anti-Air)'
        end

        local targetLayers, bitwiselayers = GetTargetLayers(weapon, unit)

        if bitwiselayers == 0 then
            return 'Untargeted'
        end

        --Note seabed and sub have been filtered out of 'above water target only' weapons
        local bitmap = {
            [1] = 'Anti-Land',  --land
            [2] = 'Anti-Seabed',  --seabed
            [3] = 'Anti-Terrain', --land seabed
            [4] = 'Anti-Submarine',  --sub
            [5] = 'Anti-Land &amp; Sub', --land and sub
            [6] = 'Anti-Underwater',  --seabed sub
            [7] = 'Anti-Land &amp; Underwater', --land seabed sub
            [8] = 'Anti-Ship',  -- water
            [9] = 'Anti-Surface',  --land water
            [10] = 'Anti-Ship &amp; Seabed', --seabed water
            [11] = 'Anti-Ship, Seabed, &amp; Land',--seabed water land
            [12] = 'Anti-Ship &amp; Sub', --water sub
            [13] = 'Anti-Surface &amp; Sub', --water sub land
            [14] = 'Anti-Naval', --water sub seabed
            [15] = 'Anti-Land &amp; Naval', --water sub seabed land
            [16] = 'Anti-Air',
            --[17] = 'error:something with air',
        }

        local lowAltAir

        if bitwiselayers >= 16 and (weapon.TargetRestrictDisallow and string.find(weapon.TargetRestrictDisallow, 'HIGHALTAIR')) then
            lowAltAir = 'Low-Altidude Anti-Air'
            bitwiselayers = bitwiselayers - 16
        end

        if bitwiselayers > 16 then
            return s..'<error:Weapon hits high alt air and other stuff>'
        end

        return s..'<br />('..(bitmap[bitwiselayers] and bitmap[bitwiselayers]..(lowAltAir and ', '..lowAltAir or '') or lowAltAir)..')'

    end
end

WepProjectiles = function(weapon, unit)
    if not weapon.RackBones then return end
    local ProjectileCount
    if weapon.MuzzleSalvoDelay == 0 then
        ProjectileCount = math.max(1, #(weapon.RackBones[1].MuzzleBones or {'boop'} ) )
    else
        ProjectileCount = (weapon.MuzzleSalvoSize or 1)
    end
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * math.max(1, #(weapon.RackBones or {'boop'} ) )
    end
    return ProjectileCount
end

DPSEstimate = function(weapon, unit)
    -- Dont do death weapons, or weapons without RoF
    if IsDeathWeapon(weapon) or not weapon.RateOfFire then
        return
    end
    -- Only do unit weapons, not projectile or the technically real but not really 'prop' weapons
    if not (weapon.TargetType == 'RULEWTT_Unit' or not weapon.TargetType) then
        return
    end

    local damage = (weapon.NukeInnerRingDamage or weapon.Damage)
    * (WepProjectiles(weapon, unit) or 1)
    * math.max(weapon.DoTPulses or 1, 1)

    if (weapon.BeamLifetime and weapon.BeamLifetime > 0) and weapon.BeamCollisionDelay then
        damage = damage * math.ceil( (weapon.BeamLifetime or 1) / (weapon.BeamCollisionDelay + 0.1) )
    end

    --NeedToComputeBombDrop -- ROF isn't important to bombers

    local rof

    if weapon.RateOfFire and not (weapon.BeamLifetime == 0 and weapon.BeamCollisionDelay) then
        rof = 1 / (math.floor(10 / weapon.RateOfFire + 0.5)/10)

        local chargeRof = 10
        if weapon.EnergyRequired and weapon.EnergyDrainPerSecond then
            chargeRof = 1 / (math.floor((weapon.EnergyRequired / weapon.EnergyDrainPerSecond) * 10)/10)
        end
        rof = math.min(rof, chargeRof, 10)
    end

    if (weapon.BeamLifetime == 0 and weapon.BeamCollisionDelay) then
        rof = 1 / ((weapon.BeamCollisionDelay or 0) + 0.1)
    end

    return math.floor(damage * rof + 0.5)
end

--------------------------------------------------------------------------------

abilityDesc = {
    ['Anti-Air']                        = 'Can shoot aircraft, including high-altitude air',
    ['Air Staging']                     = 'Aircraft can land on it for refuel and/or repair',
    ['Artillery Defense']               = 'Protects against artillery projectile weapons',
    ['Amphibious']                      = 'Can pass land and water',
    ['Aquatic']                         = 'Buildable on land and on or in water',
    ['Carrier']                         = 'Can build and/or store aircraft',
    ['Cloaking']                        = 'Can become hidden to visual sensors',
    ['Customizable']                    = 'Has optional enhancements to improve performance or unlock new featuers',
    ['Directional Sensor']              = 'Has non-standard intel that is off-centre', -- BrewLAN
    ['Volatile']                        = 'Has a death weapon',
    ['Deploys']                         = 'Needs to be stationary for one or more effects',
    ['Depth Charges']                   = 'Can attack water with projectiles immune to anti-torpedo',
    ['Engineering Suite']               = 'Has complete engineering features',
    ['Factory']                         = 'Can build units without entering command mode',
    ['Hover']                           = 'Can pass water and is immune to torpedoes',
    ['Jamming']                         = 'Creates false radar signals',
    ['Manual Launch']                   = 'Has a counted projectile weapon that needs manually controlling',
    ['Massive']                         = 'Damages things by treading on them',
    ['Missile Defense']                 = 'Has countermeasures for missiles that don\'t count as \'tactical\' or \'strategic\'', -- BrewLAN
    ['Not Capturable']                  = 'Is either unable to be, or never in a position to be, captured',
    ['Omni Sensor']                     = 'Has advanced intel that can see through counterintel',
    ['Personal Shield']                 = 'Has a shield that only effectively protects itself',
    ['Personal Stealth']                = 'Hidden to radar and/or sonar',
    ['Personal Teleporter']             = 'Has the ability to teleport without requiring an enhancement', -- BrewLAN
    ['Radar']                           = 'Can see blips of units not seen by vision that are on or above water',
    ['Reclaims']                        = 'Can harvest entities for resources; this damages them if they have health',
    ['Repairs']                         = 'Can fix damage on other units at the cost of resources',
    ['Sacrifice']                       = 'Can destroy itself to contribute to a build',
    ['Satellite Uplink']                = 'Prevents satellites from receiving damage from flying unguided',  -- BrewLAN
    ['Satellite Capacity: +0']          = 'Doesn\'t contribute towards satellite population capacity',-- BrewLAN
    ['Satellite Capacity: +1']          = 'Contributes 1 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +2']          = 'Contributes 2 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +3']          = 'Contributes 3 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +4']          = 'Contributes 4 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +5']          = 'Contributes 5 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity Unrestricted'] = 'Effectively removes satellite deployment limits', -- BrewLAN
    ['Shield Dome']                     = 'Has a bubble shield that can protect others',
    ['Sonar']                           = 'Can see blips of units not seen by vision that are on or below water',
    ['Stealth Field']                   = 'Hides itself and nearby others from radar and/or sonar',
    ['Strategic Missile Defense']       = 'Can target strategic missile projectiles',
    ['EMP Weapon']                      = "Can inflict 'stun'",
    ['Submersible']                     = 'Is a naval unit that can surface and dive',
    ['Suicide Weapon']                  = 'Has a single-use self-damaging weapon',
    ['Tactical Missiles']               = 'Has a weapon with projectiles that identify as tactical missiles', -- BrewLAN
    ['Tactical Missile Defense']        = 'Can target tactical missile projectiles',
    ['Tactical Missile Deflection']     = 'Can target and redirect tactical missile projectiles',
    ['Teleporter']                      = 'Can teleport itself and others', -- BrewLAN
    ['Torpedoes']                       = 'Has a weapon that can target things immersed in water',
    ['Torpedo Defense']                 = 'Can target torpedo projectiles',
    ['Transport']                       = 'Can carry other units',
    ['Upgradeable']                     = 'Can build a unit to replace itself',
}

abilityTitle = function(ability)
    return '<span title="'..(abilityDesc[ability] or 'error:description')..'" >'..ability..'</span>'
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

buildercats = {
    BUILTBYTIER1FIELD            = {'Tech 1 Field Engineer',           5},  -- BrewLAN
    BUILTBYTIER2FIELD            = {'Tech 2 Field Engineer',           10}, -- BrewLAN
    BUILTBYTIER3FIELD            = {'Tech 3 Field Engineer',           15}, -- BrewLAN
    BUILTBYENGINEER              = {'Tech 1 Engineer',                 5},  -- R&D
    BUILTBYTIER1ENGINEER         = {'Tech 1 Engineer',                 5},
    BUILTBYTIER2ENGINEER         = {'Tech 2 Engineer',                 10},
    BUILTBYTIER3ENGINEER         = {'Tech 3 Engineer',                 15},
    BUILTBYCOMMANDER             = {'Armoured Command Unit',           10},
    BUILTBYTIER2COMMANDER        = {'Tech 2 Armoured Command Unit',    30},
    BUILTBYTIER3COMMANDER        = {'Tech 3 Armoured Command Unit',    90},
    BUILTBYTIER1FACTORY          = {'Tech 1 Factory',                  20},
    BUILTBYTIER2FACTORY          = {'Tech 2 Factory',                  40},
    BUILTBYTIER3FACTORY          = {'Tech 3 Factory',                  60},
    BUILTBYLANDTIER1FACTORY      = {'Tech 1 Land Factory',             20}, -- BrewLAN
    BUILTBYLANDTIER2FACTORY      = {'Tech 2 Land Factory',             40},
    BUILTBYLANDTIER3FACTORY      = {'Tech 3 Land Factory',             60}, -- BrewLAN
    BUILTBYTIER1SURFACEFACTORY   = {'Tech 1 Amphibious Factory',       20}, -- R&D
    BUILTBYTIER2SURFACEFACTORY   = {'Tech 2 Amphibious Factory',       40}, -- R&D
    BUILTBYTIER3SURFACEFACTORY   = {'Tech 3 Amphibious Factory',       60}, -- R&D
    BUILTBYQUANTUMGATE           = {'Tech 3 Quantum Gateway',          120},
    TRANSPORTBUILTBYTIER3FACTORY = {'Tech 3 Air Factory',              60},
    BUILTBYTIER3SPACEPORT        = {'Tech 3 Satellite Launch Complex', 100}, -- BrewLAN
    BUILTBYHEAVYWALL             = {'Tech 3 Armored Wall Segment',     1},   --BrewLAN
    BUILTBYGANTRY                = {'Experimental Factory',            240}, -- BrewLAN
    BUILTBYEXPERIMENTALSUB       = nil, -- Referenced in vanilla, but nothing uses this
}

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
            bilst = bilst.."\n* <error:category />Unknown build category <code>]]..cat..[[</code>"
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

FactionIndexes = {
    UEF = 1,
    Aeon = 2,
    Cybran = 3,
    Seraphim = 4,
    Other = 5,
}

FactionsByIndex = {
    'UEF',
    'Aeon',
    'Cybran',
    'Seraphim',
    'Other',
}

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

    --local time = os.clock()

    dirsearch(dir..(_G.UnitBlueprintsFolder or ''), '/ad')

    --print(os.clock() - time)

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

GetBlueprint = function(dir, file)
    local bp

    UnitBlueprint = function(a) bp = a end
    Sound = function(a) return a end

    assert(pcall(dofile, dir..'/'..file), "⚠️ Failed to load "..file)

    bp.ID = string.sub(file,1,-9)
    bp.id = string.lower(bp.ID)

    bp.unitTlevel, bp.unitTdesc = GetUnitTechAndDescStrings(bp)

    return bp
end

GetUnitTechAndDescStrings = function(bp)
    -- Tech 1-3 units don't have the tech level in their desc exclicitly,
    -- Experimental do. This unified it so we don't have to check again.
    for i = 1, 3 do
        if arrayfind(bp.Categories, 'TECH'..i) then
            return 'Tech '..i, 'Tech '..i..' '..LOC(bp.Description)
        end
    end
    if arrayfind(bp.Categories, 'EXPERIMENTAL') then
        return 'Experimental', LOC(bp.Description)
    end
    return nil, LOC(bp.Description)
end
