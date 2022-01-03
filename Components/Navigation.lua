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

local function UpdateGeneratedPartOfPage(page, tag, content)
    local md = io.open(OutputDirectory..page, "r")
    local mdstring = md and md:read('a')
    pcall(io.close,md)

    content = '<'..tag..">\n"..content..'</'..tag..'>'

    io.open(OutputDirectory..page, "w"):write(
        mdstring and string.find( mdstring, '<'..tag..'>' )
        and string.gsub( mdstring, '<'..tag..'>.*</'..tag..'>', content )
        or mdstring and mdstring.."\n"..content.."\n"
        or content
    ):close()
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

    UpdateGeneratedPartOfPage('_Sidebar.md', 'brewwikisidebar', sidebarstring)

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

function GenerateHomePage()
    local colLimit = 6

    local numMods = #NavigationData
    local rows = math.ceil(numMods/colLimit)
    local col = math.floor(numMods / rows)
    local extra = rows - (numMods % rows)
    local cols = {}
    for i = 1, rows do
        cols[i] = col + (i <= extra and 0 or 1) -- Adds the remainders to the last rows so the first is/are bigger
    end

    local homestring = ''

    local modindex = 0
    for i = 1, #cols do
        local homeModNav1, homeModNav2 = '', ''
        for j = modindex+1, modindex+cols[i] do
            local ModInfo = NavigationData[j].ModInfo

            homeModNav1 = homeModNav1.."\n"..xml:th{align='center'}(xml:a{href=stringSanitiseFilename(ModInfo.name)}(xml:img{
                src=ImageRepo..'mods/'..(ModInfo.icon and stringSanitiseFilename(ModInfo.name, true, true) or 'mod')..'.png',
                title=stringSanitiseFilename(ModInfo.name)
            }))

            homeModNav2 = homeModNav2.."\n"..xml:th{align='center'}(xml:a{href=stringSanitiseFilename(ModInfo.name)}(ModInfo.name))
        end
        homestring = homestring.. xml:table{align='center'}(xml:tr(homeModNav1),xml:tr(homeModNav2),'').."\n"
        modindex = cols[i]
    end

    homestring = homestring..xml:dl(
        xml:dt(xml:img{align='left', height='27px', src='https://raw.githubusercontent.com/The-Balthazar/BrewWikiGen/master/BrewWikiGen.png'}),
        xml:dd("\n\n*Powered by [BrewWikiGen](https://github.com/The-Balthazar/BrewWikiGen)*\n\n"),''
    )

    UpdateGeneratedPartOfPage('Home.md', 'brewwikihome', homestring)

    print("Generated home page")
end
