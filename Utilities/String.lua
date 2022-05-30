--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
rawset(string, 'gfind', string.gmatch) -- for 5.0 compatibility
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

function stringSanitiseXMLAttribute(s)
    return string.gsub(s, '"', "''")
end

function hoverTip(title, text)
    return title and ' '..xml:span{title=title}(text or "(<u>?</u>)") or ''
end

function pluralS(n) return n ~= 1 and 's' or '' end

function pageLink(page,text)
    local bp = getBP(page)
    if not bp or (bp and not bp.ModInfo.GenerateWikiPages) then
        return text or page
    else
        return xml:a{href=stringSanitiseFilename(page)} (text or page)
    end
end

function unitDescLink(id)
    local bp = getBP(id)
    if bp and not bp.ModInfo.GenerateWikiPages then
        return bp.TechDescription
    elseif bp and bp.ModInfo.GenerateWikiPages then
        return xml:a{href=stringSanitiseFilename(id)} (bp.TechDescription or id)
    end
    return id and xml:code(id) or nil
end

function sectionLink(section, text) return xml:a{href='#'..stringSanitiseFilename(section,1,1)}(text or section) end

function stringHTMLWrap(s, limit)
    if not (s and limit) then return s end
    local l = string.len(s)

    if l > limit then
        local len = string.match(s, "(%S+)"):len()
        -- not just returning gsub because we don't want it to return the number of replacements.
        s = string.gsub(s, "(%s+)(%S+)", function(space, word)
            len = len+1+(word):len()
            if len > limit then
                len = 0
                return xml:br()..word
            else
                return space..word
            end
        end)
    end
    return s
end

--------------------------------------------------------------------------------

function iconText(icon, text, text2)
    text = formatNumber(text)
    text2 = formatNumber(text2)

    local icons = {
        Health = 'icons/health.png',
        Regen = 'icons/health.png',
        Shield = 'icons/shield.png',

        Energy = 'icons/energy.png',
        Mass = 'icons/mass.png',
        Time = 'icons/time.png',

        Build = 'icons/build.png',

        Fuel = 'icons/fuel.png',
        Attached = 'icons/attached.png',

        Unit = 'icons/tank.png',

        OnMass = 'icons/mass_marker.png',
        OnHydro = 'icons/hydrocarbon_marker.png',

        [1] = 'icons/T1.png',
        [2] = 'icons/T2.png',
        [3] = 'icons/T3.png',
        [4] = 'icons/T4.png',
    }
    local titles = {
        OnMass = 'Mass marker',
        OnHydro = 'Hydrocarbon marker',
        [1] = 'Tech 1',
        [2] = 'Tech 2',
        [3] = 'Tech 3',
        [4] = 'Experimental',
    }
    return text and ((icons[icon] and
        xml:img{src=OutputAsset(icons[icon]), title=(titles[icon] or icon)}..' ' or '')..text..(text2 or '')
    )
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

function stringConcatLB(args, toeach, html)
    local s = ''
    if #args == 1 then s = toeach and toeach(args[1]) or args[1] else
        for i, v in ipairs(args) do
            s = s..((html and i~=1 and '<br />')or"\n")..(toeach and toeach(v) or v)
        end
    end
    return s
end

function stringConcatOxfordComma(args, toeach)
    local s = ''
    if #args == 1 then s = toeach and toeach(args[1]) or args[1] else
        for i, v in ipairs(args) do
            if s ~= '' then
                s = s..', '
            end
            if i == #args then
                s = s..'and '
            end
            s = s..(toeach and toeach(v) or v)
        end
    end
    return s
end

local EmptyHTML = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true,
}

-- xml module
-- usage exammple:
-- xml:a{title='example' href='#rel-link'}('link text')
-- returns '<a href="#rel-link" title="example">link text</a>'
xml = setmetatable({},{
    __index = function(self, tag)
        tag = string.lower(tag)
        return function(self, data, ...)

            local attributes = ''
            if type(data) == 'table' then
                for key, val in sortedpairs(data) do
                    attributes = attributes..' '..key..'="'..stringSanitiseXMLAttribute(val)..'"'
                end
            end

            if EmptyHTML[tag] then return '<'..tag..attributes..' />' end

            self.empty = '<'..tag..attributes..' />'
            self.open, self.close = '<'..tag..attributes..'>', '</'..tag..'>'

            if type(data) == 'string' then
                return self.open..stringConcatLB{data,...}..self.close
            end

            return setmetatable(
                {self.open, self.close, self.empty},
                {
                    __call = function(self, ...)
                        return self[1]..stringConcatLB{...}..self[2]
                    end
                }
            )
        end
    end,
})

--[[
print(
''..xml:table{align='right'}(
'    '..xml:thead(
'        '..xml:tr(
'            '..xml:th{align='left', colspan=2}(
'                %s',
'            '),
'        '),
'    '),
'    '..xml:tbody(
'        ',
'    '),
''))
]]

function detailsLink(section)
    return LOCBrackets(
        xml:a{href='#'..stringSanitiseFilename(LOC(section), true, true)}
        (LOC'<LOC wiki_infobox_details>Details')
    )
end

function formatTime(n)
    local h, m, s = n//3600, n//60%60, math.floor(n%60)
    local good, time = pcall(string.format,
        (h~=0 and '%d:' or '')..'%02d:%02d',
        h~=0 and h or m,
        h~=0 and m or s,
        h~=0 and s or nil
    )
    if not good then
        print(time, h, m, s)
        return '<error: time>'..n
    else
        return time
    end
end

function formatNumber(n)
    str = tostring(n)
    return string.sub(str, -2) == '.0' and tonumber(string.sub(str, 1, -3)) or n
end

function formatKey(k)
    return k:gsub('_',' '):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%d+)', '%1 %2') or k
end

function formatSpeed(s, naval)
    return s and s~=0 and (
        not naval and ( s > 13.7 -- Mach 0.8 or greater
            and hoverTip(string.format('%0.0f km/h, %0.0f mph, Mach %0.2f', s*72, s*44.74, s*0.058309), string.format('%s (%0.0f m/s)', s, s*20)) --o (m): km, mph, Mach
            or hoverTip(string.format('%0.0f km/h, %0.0f mph', s*72, s*44.74), string.format('%s (%0.0f m/s)', s, s*20)) --o (m): km, mph
        )
        or hoverTip(string.format('%0.0f km/h, %0.0f kn', s*72, s*38.8769), string.format('%s (%0.0f m/s)', s, s*20)) --o (m): km, knots
    ) or s
end

function formatDistance(s)
    return s and s~=0 and (s < 25 -- 500m or less
        and hoverTip(string.format('%0.2f km, %0.2f mi', s*0.02, s*0.0124274), string.format('%s (%0.0f m)', s, s*20)) --o (m): km, mi
        or hoverTip(string.format('%0.0f m, %0.2f mi', s*20, s*0.0124274), string.format('%s (%s km)', s, formatNumber(s*0.02))) --o (km): m, mi
    ) or s
end

function BuildableLayer(phys)
    --This script assumes it's a structure. This doesn't matter to non-structures.
    if not phys.BuildOnLayerCaps then
        return LayerHash.LAYER_Land
    else
        local str = ''
        for i, layer in ipairs(LayersByIndex) do
            if phys.BuildOnLayerCaps[layer] then
                if str ~= '' then
                    str = str..xml:br()
                end
                str = str..LayerHash[layer]
            end
        end
        return str
    end
end

local LogEmojiHash = {
    ['⚠️'] = '(!)',
    ['🆗'] = '(OK)',
    ['❌'] = '(><)',
}

function LogEmoji(emoji)
    return Logging.LogEmojiSupported and emoji or LogEmojiHash[emoji]
end
