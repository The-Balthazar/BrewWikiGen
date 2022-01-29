--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local NavigationData = {}

local function sortData(sorttable, sort)
    for modindex, moddata in pairs(sorttable) do
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
    local groups = {{},{},{},{},{}}
    for id, bp in pairs(units) do
        local bp = bp.bp or bp -- Convert from concise to bp
        for i = 1, 5 do
            if i == 5 or bp.CategoriesHash[techs[i] ] then
                table.insert(groups[i], bp)
                break
            end
        end
    end
    local MenuSortCats = {
        SORTCONSTRUCTION = 1000,
        SORTECONOMY      = 2000,
        SORTDEFENSE      = 3000,
        SORTSTRATEGIC    = 4000,
        SORTINTEL        = 5000,
        SORTOTHER        = 6000,
    }
    local FactionSort = {
        UEF      =  6000,
        AEON     =  7000,
        CYBRAN   =  8000,
        SERAPHIM =  9000,
        OTHER    = 10000,
    }
    local function sortKey(bp)
        return FactionSort[bp.FactionCategory or 'OTHER'] + MenuSortCats[bp.SortCategory] + (bp.BuildIconSortPriority or bp.StrategicIconSortPriority or 0) + tonumber('0.'..tonumber(string.gsub(bp.id, '%W', ''), 36))
    end
    local function MenuSort(a, b)
        return sortKey(a) < sortKey(b)
    end

    for i = 1, 5 do
        table.sort(groups[i], MenuSort)
    end
    return groups
end

function TechTable(units, maxcols)
    local SortedUnits = MenuSortUnitsByTech(units)
    local text = ''
    local colsneeded = 0

    for i, group in ipairs(SortedUnits) do
        colsneeded = math.max(colsneeded, #group > maxcols and math.ceil(#group/ math.ceil(#group/maxcols)) or #group )
    end

    maxcols = math.min(maxcols, colsneeded)

    local trtext = "\n"
    for i, group in ipairs(SortedUnits) do
        if group[1] then
            local trows = math.ceil(#group/maxcols)
            for trow = 1, trows do
                local tdtext = "\n"..(trow == 1 and '        '..xml:td{rowspan=trows~=1 and trows or nil}(i~=5 and xml:img{src=IconsPath..'T'..i..'.png', title='T'..i} or '').."\n" or '')
                for coli = 1, maxcols do
                    local buildbp = group[maxcols*(trow-1)+coli]
                    if buildbp then
                        tdtext = tdtext..'        '..xml:td( pageLink(buildbp.ID, xml:img{src=unitIconsPath..buildbp.ID..'_icon.png', width='64px', title=buildbp.unitTdesc}) ).."\n"
                    end
                end
                trtext = trtext..'    '..xml:tr(tdtext..'    ').."\n"
            end
        end
    end
    return text..xml:table(trtext).."\n\n</details>\n"
end

function InsertInNavigationData(bp)
    if not bp.WikiPage then return end
    local UnitInfo = UnitConciseInfo(bp)
    UnitInfo.bp = bp
    local index = bp.ModInfo.ModIndex

    if not NavigationData[index] then
        NavigationData[index] = {ModInfo = bp.ModInfo, Factions = {} }
    end

    local factioni = FactionIndexes[UnitInfo.faction] or #FactionsByIndex

    if not NavigationData[index].Factions[factioni] then
        NavigationData[index].Factions[factioni] = {}
    end

    table.insert(NavigationData[index].Factions[factioni], UnitInfo)
end

local function printif(check, ...) if check then print(...) end end

local function UpdateGeneratedPartOfPage(page, tag, content)
    local md = io.open(OutputDirectory..page, "r")
    local mdstring = md and md:read('a')
    pcall(io.close,md)

    if mdstring and string.find( mdstring, '<'..tag..' />' ) then
        return printif(Logging.ChangeDiscarded, "Found empty tag <"..tag.." /> discarding generation for section in "..page)
    end

    local tagsFound = mdstring and string.find( mdstring, '<'..tag..'>.*</'..tag..'>' )

    if tagsFound then    printif(Logging.FileUpdateWrites, "Found existing tag <"..tag.."> updating in "..page)
    elseif mdstring then printif(Logging.FileAppendWrites, "No <"..tag.."> tags found, appending content to "..page)
    else                 printif(Logging.NewFileWrites, "Generating fresh "..page)
    end

    content = '<'..tag..">\n"..content..'</'..tag..'>'

    io.open(OutputDirectory..page, "w"):write(
        tagsFound and string.gsub( mdstring, '<'..tag..'>.*</'..tag..'>', content )
        or mdstring and mdstring.."\n"..content.."\n"
        or content
    ):close()
end

function GenerateSidebar()
    local SidebarNavigationData = {}

    for i = (NavigationData[0] and 0 or 1), #NavigationData do
        SidebarNavigationData[i+(NavigationData[0] and 1 or 0)] = NavigationData[i]
    end

    sortData(SidebarNavigationData, 'TechDescending-DescriptionAscending')

    local sidebarstring = ''

    for modindex, moddata in ipairs(SidebarNavigationData) do
        local modname = moddata[1]

        sidebarstring = sidebarstring .. "<details markdown=\"1\">\n<summary>[Show] <a href=\""..stringSanitiseFilename(moddata.ModInfo.name)..[[">]]..moddata.ModInfo.name.."</a></summary>\n<p>\n<table>\n<tr>\n<td width=\"269px\">\n\n"
        for i, faction in ipairs(FactionsByIndex) do
            local unitarray = moddata.Factions[i]
            if unitarray then
                sidebarstring = sidebarstring .. "<details>\n<summary>"..faction.."</summary>\n<p>\n\n"
                for unitI, unitData in ipairs(unitarray) do

                    sidebarstring = sidebarstring .. '* '..xml:a{
                        title=(unitData.name or unitData.bpid),
                        href=stringSanitiseFilename(unitData.bpid)
                    }(unitData.desc or unitData.bpid).."\n"

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
    for modindex, moddata in pairs(NavigationData) do

        local ModInfobox = Infobox{
            Style = 'main-right',
            Header = {
                moddata.ModInfo.name,
                xml:img{src=ImagesPath..'mods/'..(moddata.ModInfo.icon and stringSanitiseFilename(moddata.ModInfo.name, true, true) or 'mod')..'.png', width='256px'}
            },
            Data = {
                { 'Author:', moddata.ModInfo.author },
                { 'Version:', moddata.ModInfo.version },
                {''},
                {'', xml:strong('Unit counts:') }
            }
        }

        local leadString = "\n***"..moddata.ModInfo.name..'*** is'..(modindex ~= 0 and' a mod' or '')..' by '..(moddata.ModInfo.author or 'an unknown author')..'.'
        ..(moddata.ModInfo.description and " Its mod menu description is:\n"
        ..xml:blockquote(moddata.ModInfo.description).."\n" or ' ')

        local unitsSection = (moddata.ModInfo.version and "Version "
        ..moddata.ModInfo.version or '*'..moddata.ModInfo.name..'*').." contains the following units:\n"

        for i = 1, #FactionsByIndex do
            local faction = FactionsByIndex[i]
            local unitarray = moddata.Factions[i]
            if unitarray then
                table.insert(ModInfobox.Data, { faction..':', #moddata.Factions[i] })
                unitsSection = unitsSection .. MDHead(faction) .. TechTable(unitarray, 8)
            end
        end

        table.insert(ModInfobox.Data, { 'Total:', tableSubcount(moddata.Factions) })

        local MDPageName = stringSanitiseFilename(moddata.ModInfo.name)..'.md'

        UpdateGeneratedPartOfPage(MDPageName, 'brewwikimodinfobox', tostring(ModInfobox))
        UpdateGeneratedPartOfPage(MDPageName, 'brewwikileadtext', leadString)
        UpdateGeneratedPartOfPage(MDPageName, 'brewwikimodunits', unitsSection)
    end

    print("Generated "..#NavigationData.." mod pages")
end

function GenerateHomePage()
    local colLimit = 6

    local numMods = #NavigationData + (NavigationData[0] and 1 or 0)
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
            local ModInfo = NavigationData[j - (NavigationData[0] and 1 or 0)].ModInfo

            homeModNav1 = homeModNav1.."\n"..xml:th{align='center'}(xml:a{href=stringSanitiseFilename(ModInfo.name)}(xml:img{
                src=ImagesPath..'mods/'..(ModInfo.icon and stringSanitiseFilename(ModInfo.name, true, true) or 'mod')..'.png',
                title=stringSanitiseFilename(ModInfo.name)
            }))

            homeModNav2 = homeModNav2.."\n"..xml:th{align='center'}(xml:a{href=stringSanitiseFilename(ModInfo.name)}(ModInfo.name))
        end
        if extra ~= rows then
            homestring = homestring.. xml:table{align='center'}(xml:tr(homeModNav1),xml:tr(homeModNav2),'').."\n"
        else
            homestring = homestring.. "\n"..xml:tr(homeModNav1).."\n"..xml:tr(homeModNav2)
        end
        modindex = cols[i]
    end
    if extra == rows then
        homestring = xml:table{align='center'}(homestring.."\n").."\n"
    end

    homestring = homestring..xml:dl(
        xml:dt(xml:img{align='left', height='27px', src='https://raw.githubusercontent.com/The-Balthazar/BrewWikiGen/master/BrewWikiGen.png'}),
        xml:dd("\n\n*Powered by [BrewWikiGen](https://github.com/The-Balthazar/BrewWikiGen)*\n\n"),''
    )

    UpdateGeneratedPartOfPage('Home.md', 'brewwikihome', homestring)

    print("Generated home page")
end
