--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Generic string functions
--------------------------------------------------------------------------------
local WindowsReserved = '[\\/:%*%?"<>|]?' --\/:*?"<>|
local URIReserved = '[#]?'--'[!%*\'%(%);:@&=%+%$,/%?%%#%[%]]?' --!*'();:@&=+$,/?%#[]

function stringSanitiseFilename(s, lower, nospace)
    if type(s) ~= 'string' then return end
    if lower then s = string.lower(s) end
    if nospace then s = string.gsub(s, ' ', '-') end
    return string.gsub(s, WindowsReserved..URIReserved, '')
end

function numberFormatNoTrailingZeros(n)
    str = tostring(n)
    return string.sub(str, -2) == '.0' and tonumber(string.sub(str, 1, -3)) or n
end

function hoverTip(s1, s2)
    return s1 and ' '..'<span title="'..s1..'" >'..(s2 and s2 or "(<u>?</u>)")..'</span>' or ''
end

function pluralS(n) return n ~= 1 and 's' or '' end

--------------------------------------------------------------------------------

function iconText(icon, text, text2)
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

function transportClassHookType(transport)
    local hooks = {
        'Small',
        'Medium',
        'Large',
        nil,
        'Drone',
    }
    return hooks[transport]
end

function abilityTitle(ability)
    return hoverTip( LOC(abilityDesc[noLOC(ability)]) or 'error:description', LOC(ability))
end

function BuildableLayer(phys)
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
