--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local NavigationData = {}

local function sortData(sorttable, sort)
    for modindex, moddata in ipairs(sorttable) do
        for i, faction in ipairs(FactionsByIndex) do
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

function MenuSortUnitsByTech(units)
    local techs = {
        'TECH1',
        'TECH2',
        'TECH3',
        'EXPERIMENTAL',
    }
    local groups = {{},{},{},{}}
    for id, bp in pairs(units) do
        for i = 1, 4 do
            if bp.CategoriesHash[techs[i] ] then
                table.insert(groups[i], bp)
                break
            end
        end
    end
    local MenuSortCats = {
        SORTCONSTRUCTION = 1000,
        SORTECONOMY = 2000,
        SORTDEFENSE = 3000,
        SORTSTRATEGIC = 4000,
        SORTINTEL = 5000,
        SORTOTHER = 6000,
    }
    local function sortKey(bp)
        return tonumber((MenuSortCats[bp.SortCategory] + (bp.BuildIconSortPriority or bp.StrategicIconSortPriority))..'.'..tonumber(string.gsub(bp.id, '%W', ''), 36))
    end
    local function MenuSort(a, b)
        return sortKey(a) < sortKey(b)
    end

    for i = 1, 4 do
        table.sort(groups[i], MenuSort)
    end
    return groups
end

function InsertInNavigationData(index, ModInfo, UnitInfo)

    if not NavigationData[index] then
        NavigationData[index] = {ModInfo = ModInfo, Factions = {} }
    end

    local factioni = FactionIndexes[UnitInfo.faction] or #FactionsByIndex

    if not NavigationData[index].Factions[factioni] then
        NavigationData[index].Factions[factioni] = {}
    end

    table.insert(NavigationData[index].Factions[factioni], UnitInfo)
end

function GenerateSidebar()
    sortData(NavigationData, 'TechDescending-DescriptionAscending')

    local sidebarstring = ''

    for modindex, moddata in ipairs(NavigationData) do
        local modname = moddata[1]

        sidebarstring = sidebarstring .. "<details markdown=\"1\">\n<summary>[Show] <a href=\""..stringSanitiseFilename(moddata.ModInfo.name)..[[">]]..moddata.ModInfo.name.."</a></summary>\n<p>\n<table>\n<tr>\n<td>\n\n"
        for i, faction in ipairs(FactionsByIndex) do
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
    sortData(NavigationData, 'TechAscending-IDAscending')

    for modindex, moddata in ipairs(NavigationData) do

        local ModInfobox = Infobox{
            Style = 'main-right',
            Header = {
                moddata.ModInfo.name,
                '<img src="'..ImageRepo..'mods/'..(moddata.ModInfo.icon and stringSanitiseFilename(moddata.ModInfo.name, true, true) or 'mod')..'.png" width="256px" />'
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

        for i = 1, #FactionsByIndex do
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

        md = io.open(OutputDirectory..stringSanitiseFilename(moddata.ModInfo.name)..'.md', "w"):write(tostring(ModInfobox)..mulString):close()

    end

    print("Generated "..#NavigationData.." mod pages")
end
