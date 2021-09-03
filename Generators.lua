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
    local numBlueprintsFiles = #BlueprintPathsArray
    local numValidBlueprints = 0

    GetModHooks(ModDirectory)

    for i, fileDir in ipairs(BlueprintPathsArray) do
        for _, bp in ipairs(GetBlueprint(fileDir[1],fileDir[2])) do
            if isValidBlueprint(bp) then

                numValidBlueprints = numValidBlueprints + 1

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
                    tech = bp.unitTIndex,
                }

                ----------------------------------------------------------------

                local cattext = ''

                if _G.FooterCategories and _G.FooterCategories[1] then
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
                    if cattext ~= '' then
                        cattext = "\n<table align=center>\n<td>Categories : "..cattext
                    end
                end
                ----------------------------------------------------------------

                local md = io.open(OutputDirectory..bp.ID..'.md', "w"):write(headerstring..infoboxstring..bodytext..cattext.."\n"):close()

                ----------------------------------------------------------------

                if not sidebarData[modsidebarindex] then
                    sidebarData[modsidebarindex] = {ModInfo = ModInfo, Factions = {} }
                end

                local factioni = FactionIndexes[bp.General and bp.General.FactionName] or #FactionsByIndex

                if not sidebarData[modsidebarindex].Factions[factioni] then
                    sidebarData[modsidebarindex].Factions[factioni] = {}
                end

                table.insert(sidebarData[modsidebarindex].Factions[factioni], UnitInfo)
            end
        end
    end

    print( numValidBlueprints..' unit wiki page'..(numValidBlueprints ~= 1 and 's' or '')..' created from '..numBlueprintsFiles..' file'..(numValidBlueprints ~= 1 and 's' or '') )
end

local sortData = function(sorttable, sort)
    for modindex, moddata in ipairs(sorttable) do
        --for i = 1, #FactionsByIndex do--faction, unitarray in pairs(moddata[2]) do
        for i, faction in ipairs(FactionsByIndex) do
            --local faction = FactionsByIndex[i]
            local unitarray = moddata.Factions[i]
            if unitarray then
                table.sort(unitarray, function(a,b)

                    if sort == 'TechDescending-DescriptionAscending' then
                        local function sortkey(c) return (5-(c.tech or 0))..(c.desc or 'z error')..c.bpid end
                        return sortkey(a) < sortkey(b)

                    elseif sort == 'TechAscending-IDAscending' then
                        local function sortkey(c) return (c.tech or 5)..c.bpid end
                        return sortkey(a) < sortkey(b)

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

    local md = io.open(OutputDirectory..'_Sidebar.md', "w"):write(sidebarstring):close()

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
                {'', "<strong>Unit counts:</strong>" }
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

                local TechNames = {
                    'Tech 1',
                    'Tech 2',
                    'Tech 3',
                    'Experimental',
                    'Other',
                }

                mulString = mulString .. MDHead(faction,2)

                for unitI, unitData in ipairs(unitarray) do
                    local tech = unitData.tech or 5
                    if tech > curtechi then
                        curtechi = tech
                        mulString = mulString ..MDHead(TechNames[tech])
                    end

                    mulString = mulString .. [[<a title="]]..(unitData.name or unitData.bpid)..[[" href="]]..unitData.bpid..[["><img src="]]..unitIconRepo..unitData.bpid.."_icon.png\" /></a>\n"
                end
            end
        end

        table.insert(ModInfobox.Data, { 'Total:', tableSubcount(moddata.Factions) })

        md = io.open(OutputDirectory..stringSanitiseFile(moddata.ModInfo.name)..'.md', "w"):write(tostring(ModInfobox)..mulString):close()

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

        md = io.open(OutputDirectory..'_categories.'..cat..'.md', "w"):write(catstring):close()
        num = num+1
    end

    print("Generated "..num.." category pages")
end
