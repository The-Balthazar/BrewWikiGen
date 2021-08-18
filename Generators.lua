--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

local sidebarData = {}
local categoryData = {}

function LoadModFilesMakeUnitPagesGatherData(ModDirectory, modsidebarindex)
    local ModInfo = GetModInfo(ModDirectory)

    print('🔎 Searching for blueprints in '..ModInfo.name)

    local BlueprintPathsArray = GetModBlueprintPaths(ModDirectory)

    GetModHooks(ModDirectory)

    for i, fileDir in ipairs(BlueprintPathsArray) do

        local bp = GetBlueprint(fileDir[1],fileDir[2])

        local infoboxstring = tostring(Infobox{
            Style = 'main-right',
            Header = {string.format(
                '<img align="left" title="%s unit icon" src="%s_icon.png" />%s<br />%s',
                (LOC(bp.General.UnitName) or 'The'),
                unitIconRepo..bp.ID,
                (LOC(bp.General.UnitName) or '<i>Unnamed</i>'),
                (bp.unitTdesc or [[<i>No description</i>]])
            )},
            Data = GetUnitInfoboxData(ModInfo, bp),
        })

        local headerstring = bp.General.UnitName and bp.unitTdesc and string.format("\"%s\": %s\n----\n", LOC(bp.General.UnitName), bp.unitTdesc)
        or bp.General.UnitName and string.format("\"%s\"\n----\n", LOC(bp.General.UnitName) )
        or bp.unitTdesc and string.format("%s\n----\n", bp.unitTdesc)
        or ''

        local BodyTextSections = GetUnitBodytextSectionData(ModInfo, bp)

        local bodytext = GetUnitBodytextLeadText(ModInfo, bp) .. TableOfContents(BodyTextSections) .. tostring( BodyTextSections )

        local UnitInfo = {
            bpid = bp.ID,
            name = LOC(bp.General.UnitName),
            desc = bp.unitTdesc,
        }

        ------------------------------------------------------------------------

        local cattext = ''

        if _G.FooterCategories and _G.FooterCategories[1] then
            bodytext = bodytext.."\n<table align=center>\n<td>Categories : "

            for i, cat in ipairs(FooterCategories) do
                if arrayfind(bp.Categories, cat) then

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
        end
        ------------------------------------------------------------------------

        local md = io.open(OutputDirectory..bp.ID..'.md', "w")
        md:write(headerstring..infoboxstring..bodytext..cattext.."\n")
        md:close()

        ------------------------------------------------------------------------

        if not sidebarData[modsidebarindex] then
            sidebarData[modsidebarindex] = {ModInfo = ModInfo, Factions = {} }
        end

        local factioni = FactionIndexes[bp.General and bp.General.FactionName] or #FactionsByIndex

        if not sidebarData[modsidebarindex].Factions[factioni] then
            sidebarData[modsidebarindex].Factions[factioni] = {}
        end

        table.insert(sidebarData[modsidebarindex].Factions[factioni], UnitInfo)
    end

    print( #BlueprintPathsArray..' unit wiki page'..(#BlueprintPathsArray > 1 and 's' or '')..' created' )
end

local sortData = function(sorttable, sort)
    for modindex, moddata in ipairs(sorttable) do
        --for i = 1, #FactionsByIndex do--faction, unitarray in pairs(moddata[2]) do
        for i, faction in ipairs(FactionsByIndex) do
            --local faction = FactionsByIndex[i]
            local unitarray = moddata.Factions[i]
            if unitarray then
                table.sort(unitarray, function(a,b)
                    --return a[3] < b[3]
                    local g

                    if sort == 'TechDescending-DescriptionAscending' then
                        g = { ['Experi'] = 1, ['Tech 3'] = 2, ['Tech 2'] = 3, ['Tech 1'] = 4 }
                        return (g[string.sub(a.desc, 1, 6)] or 5)..a.desc < (g[string.sub(b.desc, 1, 6)] or 5)..b.desc

                    elseif sort == 'TechAscending-IDAscending' then
                        g = { ['Tech 1'] = 1, ['Tech 2'] = 2, ['Tech 3'] = 3, ['Experi'] = 4 }
                        return (g[string.sub(a.desc, 1, 6)] or 5)..a.bpid < (g[string.sub(b.desc, 1, 6)] or 5)..b.bpid

                    end
                end)
            end
        end
    end
end

function GenerateSidebar()
    sortData(sidebarData, 'TechDescending-DescriptionAscending')

    local sidebarstring = ''

    for modindex, moddata in ipairs(sidebarData) do
        local modname = moddata[1]

        sidebarstring = sidebarstring .. "<details markdown=\"1\">\n<summary>[Show] <a href=\""..stringSanitiseFile(moddata.ModInfo.name)..[[">]]..moddata.ModInfo.name.."</a></summary>\n<p>\n<table>\n<tr>\n<td>\n\n"
        for i, faction in ipairs(FactionsByIndex) do--faction, unitarray in pairs(moddata[2]) do
            --local faction = FactionsByIndex[i]
            local unitarray = moddata.Factions[i]
            if unitarray then
                sidebarstring = sidebarstring .. "<details>\n<summary>"..faction.."</summary>\n<p>\n\n"
                for unitI, unitData in ipairs(unitarray) do

                    sidebarstring = sidebarstring .. "* <a title=\""..(unitData.name or unitData.bpid)..[[" href="]]..unitData.bpid..[[">]]..(unitData.desc or unitData.bpid).."</a>\n"

                end
                sidebarstring = sidebarstring .. "</p>\n</details>\n"
            end
        end
        sidebarstring = sidebarstring .. "\n</td>\n</tr>\n</table>\n</p>\n</details>\n"
    end

    local md = io.open(OutputDirectory..'_Sidebar.md', "w")
    md:write(sidebarstring)
    md:close()

    print("Generated navigation sidebar")
end

function GenerateModPages()
    sortData(sidebarData, 'TechAscending-IDAscending')

    for modindex, moddata in ipairs(sidebarData) do

        local ModInfobox = Infobox{
            Style = 'main-right',
            Header = {
                moddata.ModInfo.name,
                '<img src="'..ImageRepo..'mods/'..(moddata.ModInfo.icon and stringSanitiseFile(moddata.ModInfo.name, true, true) or 'mod')..'.png" width="256px" />'
            },
            Data = {
                { 'Author:', moddata.ModInfo.author },
                { 'Version:', moddata.ModInfo.version },
                {''},
                {'', "<strong>Units:</strong>" }
            }
        }

        local mulString = '***'..moddata.ModInfo.name..'*** is a mod by '..(moddata.ModInfo.author or 'an unknown author')
        ..". Its mod menu description is:\n"
        .."<blockquote>"..(moddata.ModInfo.description or 'No description.').."</blockquote>\nVersion "
        ..moddata.ModInfo.version.." contains the following units:\n"

        for i = 1, #FactionsByIndex do--faction, unitarray in pairs(moddata[2]) do
            local faction = FactionsByIndex[i]
            local unitarray = moddata.Factions[i]
            if unitarray then

                table.insert(ModInfobox.Data, { faction..':', #moddata.Factions[i] })

                local curtechi = 0
                local thash = {
                    ['Tech 1'] = {1, 'Tech 1'},
                    ['Tech 2'] = {2, 'Tech 2'},
                    ['Tech 3'] = {3, 'Tech 3'},
                    ['Experi'] = {4, 'Experimental'},
                    ['Other']  = {5, 'Other'},
                }

                mulString = mulString .. MDHead(faction,2)

                for unitI, unitData in ipairs(unitarray) do
                    local tech = unitData.desc and thash[string.sub(unitData.desc, 1, 6)] or thash['Other']
                    if tech[1] > curtechi then
                        curtechi = tech[1]
                        mulString = mulString ..MDHead(tech[2])
                    end

                    mulString = mulString .. [[<a title="]]..(unitData.name or unitData.bpid)..[[" href="]]..unitData.bpid..[["><img src="]]..unitIconRepo..unitData.bpid.."_icon.png\" /></a>\n"
                end
            end
        end

        table.insert(ModInfobox.Data, { 'Total:', tableSubcount(moddata.Factions) })

        md = io.open(OutputDirectory..stringSanitiseFile(moddata.ModInfo.name)..'.md', "w")
        md:write(tostring(ModInfobox)..mulString)
        md:close()

    end

    print("Generated "..#sidebarData.." mod pages")
end

function GenerateCategoryPages()
    if not (_G.FooterCategories and _G.FooterCategories[1]) then
        return
    end
    local num = 0
    for cat, datum in pairs(categoryData) do
        table.sort(datum, function(a,b)
            g = { ['Tech 1'] = 1, ['Tech 2'] = 2, ['Tech 3'] = 3, ['Experi'] = 4 }
            return
            (g[a.UnitInfo.desc and string.sub(a.UnitInfo.desc, 1, 6)] or 5)..a.UnitInfo.bpid
            <
            (g[b.UnitInfo.desc and string.sub(b.UnitInfo.desc, 1, 6)] or 5)..b.UnitInfo.bpid
        end)

        local catstring = 'Units with the <code>'..cat.."</code> category.\n<table>\n"
        for i, data in ipairs(datum) do
            catstring = catstring
            ..'<tr><td><a href="'..data.UnitInfo.bpid ..'"><img src="'..unitIconRepo..data.UnitInfo.bpid..'_icon.png" width="21px" /></a>'
            ..'<td><code>'..data.UnitInfo.bpid..'</code>'
            ..'<td><a href="'.. stringSanitiseFile(data.ModInfo.name) ..'"><img src="'..IconRepo..'mods/'..(data.ModInfo.icon and stringSanitiseFile(data.ModInfo.name, true, true) or 'mod')..'.png" width="21px" /></a>'
            ..'<td><a href="'..data.UnitInfo.bpid..'">'

            local switch = {
                [0] = (data.UnitInfo.bpid),
                [1] = (data.UnitInfo.name or '')..(data.UnitInfo.desc or ''),
                [2] = (data.UnitInfo.name or '')..': '..(data.UnitInfo.desc or ''),
            }

            catstring = catstring..switch[BinaryCounter(data.UnitInfo.name, data.UnitInfo.desc)].."</a>\n"
        end

        md = io.open(OutputDirectory..'_categories.'..cat..'.md', "w")
        md:write(catstring)
        md:close()
        num = num+1
    end

    print("Generated "..num.." category pages")
end
