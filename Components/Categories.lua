--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local categoryData = {}

function UnitPageCategories(ModInfo, UnitInfo, bpCatHash)
    if not (_G.FooterCategories and FooterCategories[1]) then return '' end

    local cattext = ''
    for i, cat in ipairs(FooterCategories) do
        if bpCatHash[cat] then

            if not categoryData[cat] then
                categoryData[cat] = {}
            end

            table.insert(categoryData[cat], {
                UnitInfo = UnitInfo,
                ModInfo = ModInfo
            })

            if cattext ~= '' then
                cattext = cattext..' · '
            end

            cattext = cattext.."\n"..xml:a{href='_categories.'..stringSanitiseFilename(cat)}(cat)
        end
    end
    if cattext ~= '' then
        cattext = "\n"..xml:table{align='center'}(
            xml:td{width='1215px'}('Categories : '..cattext),''
        )
    end
    return cattext
end

function GenerateCategoryPages()
    if not (_G.FooterCategories and FooterCategories[1]) then
        return
    end
    local num = 0
    for cat, datum in pairs(categoryData) do
        table.sort(datum, function(a,b) return (a.UnitInfo.tech or 5)..a.UnitInfo.bpid < (b.UnitInfo.tech or 5)..b.UnitInfo.bpid end)

        local function catRow(datum)
            local s = "\n"
            for i, data in ipairs(datum) do
                local switch = {
                    [0] = (data.UnitInfo.bpid),
                    [1] = (data.UnitInfo.name or '')..(data.UnitInfo.desc or ''),
                    [2] = (data.UnitInfo.name or '')..': '..(data.UnitInfo.desc or ''),
                }

                s = s..
                '    '..xml:tr(
                '        '..xml:td(xml:a{href=data.UnitInfo.bpid}(xml:img{src=unitIconRepo..data.UnitInfo.bpid..'_icon.png', width='21px'})),
                '        '..xml:td(xml:code{}(string.lower(data.UnitInfo.bpid))),
                '        '..xml:td(xml:a{href=stringSanitiseFilename(data.ModInfo.name)}(xml:img{src=IconRepo..'mods/'..(data.ModInfo.icon and stringSanitiseFilename(data.ModInfo.name, true, true) or 'mod')..'.png', width='21px'})),
                '        '..xml:td(xml:a{href=data.UnitInfo.bpid}(switch[BinaryCounter{data.UnitInfo.name, data.UnitInfo.desc}])),
                '    ').."\n"
            end
            return s
        end

        md = io.open(OutputDirectory..'_categories.'..cat..'.md', "w")
        :write('Units with the '..xml:code(cat).." category.\n"..xml:table(catRow(datum)).."\n")
        :close()
        num = num+1
    end

    print("Generated "..num.." category pages")
end
