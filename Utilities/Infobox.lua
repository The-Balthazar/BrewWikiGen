--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

function InfoboxFlagsList(spec)
    return setmetatable(spec, {

        __tostring = function(self)
            local s = ''
            for i, v in ipairs(self) do
                if v and tostring(v) ~= '' then
                    if s ~= '' then
                        s = s..'<br />'
                    end
                    s = s..tostring(v)
                end
            end
            return s
        end,

        __eq = function(t1, t2)
            return tostring(t1) == tostring(t2)
        end,

    })
end

local function InfoboxHeader(style, data)
    local styles = {
        ['main-right1'] = [[
<table align="right">
    <thead>
        <tr>
            <th]]..(string.sub(data[1],1,4)=='<img'and' align="left"'or'')..[[ colspan="2">
                %s
            </th>
        </tr>
    </thead>
    <tbody>
]],
        ['main-right2'] = [[
<table align="right">
    <thead>
        <tr>
            <th]]..(string.sub(data[1],1,4)=='<img'and' align="left"'or'')..[[ colspan="2">
                %s
            </th>
        </tr>
        <tr>
            <th colspan="2">
                %s
            </th>
        </tr>
    </thead>
    <tbody>
]],
        ['detail-left1'] = "<details>\n<summary>%s</summary>\n<p>\n    <table>\n",
    }
    return string.format(styles[style..#data], table.unpack(data))
end

local function InfoboxRow(th, td, tip)
    if th == '' then
        return "        "..xml:tr(xml:td{colspan=2, align='center'}(td or '')).."\n"
    elseif td and tostring(td) ~= '' then
        return
        "        "..xml:tr(
        "            "..xml:td{align='right'}(xml:strong(LOC(th or ''))),
        "            "..xml:td(tostring(td)..hoverTip(tip)),
        "        ").."\n"
    end
    return ''
end

local function InfoboxEnd(style)
    local styles = {
        ['main-right'] = "    </tbody>\n</table>\n\n",
        ['detail-left'] = "    </table>\n</p>\n</details>\n",
    }
    return styles[style]
end

function Infobox(spec)
    return setmetatable(spec, {

        __tostring = function(self)
            local infoboxstring = InfoboxHeader(self.Style, self.Header )
            if type(self.Data) == 'string' then
                infoboxstring = infoboxstring .. self.Data
            else
                for i, field in ipairs(self.Data) do
                    infoboxstring = infoboxstring .. InfoboxRow( table.unpack(field) )
                end

                local spacer = InfoboxRow''
                infoboxstring = infoboxstring
                :gsub(spacer..spacer, spacer)
                :gsub(spacer..spacer, spacer)-- one pass would miss groups of 3+
                :gsub(spacer..'$', '')
            end
            return infoboxstring .. InfoboxEnd(self.Style)
        end,

    })
end

function DoToInfoboxDataCell(fun, infodata, key, value)
    for i, v in ipairs(infodata) do
        if noLOC(v[1]) == key then
            fun(v[2], value)
            break
        end
    end
end

function InfoboxFormatRawBlueprint(bp, data, k0)
    data = data or {}
    for k, v in sortedpairs(bp) do
        k = type(k)=='string'and stringHTMLWrap(k:gsub('_',' '):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%u%l+)', '%1 %2'),15) or k
        if type(v) ~= 'table' then
            v = type(v) == 'boolean' and xml:code(tostring(v)) or v
            table.insert(data, {k, v})

        elseif type(v[1])=='string' then
            local concatFunction = (v[1]:upper()==v[1] or getBP(v[1])) and xml:code{} or LOC
            table.insert(data, {k, stringConcatLB(v, concatFunction,1)})

        elseif next(v) then
            if type(v[1])~='table' then
                table.insert(data, {'',xml:b((type(k)=='number'and k0..' ' or '')..k)})
            end
            InfoboxFormatRawBlueprint(v, data, k)
            table.insert(data, {''})
        end
    end
    return data
end
