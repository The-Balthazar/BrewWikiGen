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

function hoverTip(title, text)
    return title and ' '..xml:span{title=title}(text or "(<u>?</u>)") or ''
end

function pluralS(n) return n ~= 1 and 's' or '' end

function pageLink(page,text)
    local bp = getBP(page)
    if (bp and not bp.WikiPage) then
        return text
    else
        return xml:a{href=stringSanitiseFilename(page)} (text or page)
    end
end
function sectionLink(section, text) return xml:a{href='#'..stringSanitiseFilename(section,1,1)}(text or section) end

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

        [1] = IconRepo..'T1.png',
        [2] = IconRepo..'T2.png',
        [3] = IconRepo..'T3.png',
        [4] = IconRepo..'T4.png',
    }
    local titles = {
        [1] = 'Tech 1',
        [2] = 'Tech 2',
        [3] = 'Tech 3',
        [4] = 'Experimental',
    }
    return text and ((icons[icon] and
        xml:img{src=icons[icon], title=(titles[icon] or icon)}..' ' or '')..text..(text2 or '')
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

function stringConcatLB(args)
    local s = ''
    if #args == 1 then s = args[1] else
        for i, v in ipairs(args) do
            s = s.."\n"..v
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
                local sorteddata = {}
                for key, val in pairs(data) do
                    table.insert(sorteddata,{key,val})
                end
                table.sort(sorteddata, function(a, b) return a[1]<b[1] end)
                for i, v in ipairs(sorteddata) do
                    attributes = attributes..' '..v[1]..'="'..v[2]..'"'
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
    return string.format(
        LOC('<LOC wiki_bracket_text> (%s)'),
        xml:a{href='#'..stringSanitiseFilename(LOC(section), true, true)}
        (LOC('<LOC wiki_infobox_details>Details'))
    )
end

function formatTime(n)
    local h, m, s = math.floor(n/3600), math.floor(n/60)%60, math.floor(n%60)
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
