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

            cattext = cattext..'<a href="_categories.'..cat..'">'..cat..'</a>'
        end
    end
    if cattext ~= '' then
        cattext = "\n<table align=center>\n<td>Categories : "..cattext
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

        local catstring = 'Units with the <code>'..cat.."</code> category.\n<table>\n"
        for i, data in ipairs(datum) do
            catstring = catstring
            ..'<tr><td><a href="'..data.UnitInfo.bpid ..'"><img src="'..unitIconRepo..data.UnitInfo.bpid..'_icon.png" width="21px" /></a>'
            ..'<td><code>'..data.UnitInfo.bpid..'</code>'
            ..'<td><a href="'.. stringSanitiseFilename(data.ModInfo.name) ..'"><img src="'..IconRepo..'mods/'..(data.ModInfo.icon and stringSanitiseFilename(data.ModInfo.name, true, true) or 'mod')..'.png" width="21px" /></a>'
            ..'<td><a href="'..data.UnitInfo.bpid..'">'

            local switch = {
                [0] = (data.UnitInfo.bpid),
                [1] = (data.UnitInfo.name or '')..(data.UnitInfo.desc or ''),
                [2] = (data.UnitInfo.name or '')..': '..(data.UnitInfo.desc or ''),
            }

            catstring = catstring..switch[BinaryCounter{data.UnitInfo.name, data.UnitInfo.desc}].."</a>\n"
        end

        md = io.open(OutputDirectory..'_categories.'..cat..'.md', "w"):write(catstring):close()
        num = num+1
    end

    print("Generated "..num.." category pages")
end
