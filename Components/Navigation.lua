--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local NavigationData = {}

local FactionSort = {}
for faction, index in pairs(FactionCategoryIndexes) do FactionSort[faction] = index*10000 end

local MenuSortCats = {
    SORTCONSTRUCTION = 1000,
    SORTECONOMY      = 2000,
    SORTDEFENSE      = 3000,
    SORTSTRATEGIC    = 4000,
    SORTINTEL        = 5000,
    SORTOTHER        = 6000,
}

function TechDescendingDescriptionAscending(bp) return (5-(bp.TechIndex or 0))..(bp.TechDescription or 'z error')..bp.ID end
function TechAscendingIDAscending(bp) return (bp.TechIndex or 5)..bp.ID end
function BuildMenuSort(bp)
    return
    (FactionSort[bp.FactionCategory or 'OTHER'] +
    MenuSortCats[bp.SortCategory or 'SORTOTHER'] +
    (bp.BuildIconSortPriority or bp.StrategicIconSortPriority or 0))
    ..(tonumber(string.gsub(bp.id, '%W', ''), 36) or 0)
end
function mergeSortByOriginal(fun) return function(bp) return fun(getBP(bp.id)) end end

function GenerateModPageFor(ModInfo) return ModInfo.GenerateWikiPages and ((ModInfo.Units or 0)>0 or (ModInfo.UnitMerges or 0)>0) end

function SplitUnitsByTech(units, index)
    local groups = {{},{},{},{},{}}
    for id, bp in pairs(units) do
        if index then
            table.insert(groups[bp.TechIndex or 5], bp)
        else
            groups[bp.TechIndex or 5][id] = bp
        end
    end
    return groups
end

function TechTable(units, maxcols)
    local SortedUnits = SplitUnitsByTech(units, true)
    for i = 1, 5 do
        table.sort(SortedUnits[i], sortby(BuildMenuSort))
    end

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
                local tdtext = "\n"..(trow == 1 and '        '..xml:td{rowspan=trows~=1 and trows or nil}(i~=5 and xml:img{src='icons/T'..i..'.png', title='T'..i} or '').."\n" or '')
                for coli = 1, maxcols do
                    local buildbp = group[maxcols*(trow-1)+coli]
                    if buildbp then
                        tdtext = tdtext..'        '..xml:td( pageLink(buildbp.ID, UnitIcon(buildbp.ID, {width='64px', title=buildbp.TechDescription}) ) ).."\n"
                    end
                end
                trtext = trtext..'    '..xml:tr(tdtext..'    ').."\n"
            end
        end
    end
    return text..xml:table(trtext).."\n"
end

function InsertInNavigationData(bp)
    if not bp.ModInfo.GenerateWikiPages then return end
    local index = (bp.ModInfo.ModIndex or 0)

    if not NavigationData[index] then
        NavigationData[index] = {ModInfo = bp.ModInfo, Factions = {} }
    end

    local factioni = FactionCategoryIndexes[bp.FactionCategory or 'OTHER']

    if not NavigationData[index].Factions[factioni] then
        NavigationData[index].Factions[factioni] = {}
    end

    table.insert(NavigationData[index].Factions[factioni], bp)
end

function UpdateGeneratedPartOfPage(page, tag, content)
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
    local sidebarstring = ''

    for modindex, moddata in sortedpairs(NavigationData) do
        if GenerateModPageFor(moddata.ModInfo) then
            sidebarstring = sidebarstring .. "<details markdown=\"1\">\n<summary>[Show] <a href=\""..stringSanitiseFilename(moddata.ModInfo.name)..[[">]]..moddata.ModInfo.name.."</a></summary>\n<p>\n<table>\n<tr>\n<td width=\"269px\">\n\n"
            for i, faction in ipairs(FactionsByIndex) do
                local unitarray = moddata.Factions[i]
                if unitarray then
                    sidebarstring = sidebarstring .. "<details>\n<summary>"..faction.."</summary>\n<p>\n\n"
                    for unitI, bp in sortedpairs(unitarray, TechDescendingDescriptionAscending) do

                        sidebarstring = sidebarstring .. '* '..xml:a{
                            title=(bp.General.UnitName or bp.ID),
                            href=stringSanitiseFilename(bp.ID)
                        }(bp.TechDescription or bp.ID).."\n"

                    end
                    sidebarstring = sidebarstring .. "</p>\n</details>\n"
                end
            end
            sidebarstring = sidebarstring .. "\n</td>\n</tr>\n</table>\n</p>\n</details>\n"
        end
    end

    UpdateGeneratedPartOfPage('_Sidebar.md', 'brewwikisidebar', sidebarstring)

    print("Generated navigation sidebar")
end

function GenerateModPages()
    for modindex, moddata in pairs(NavigationData) do
        if GenerateModPageFor(moddata.ModInfo) then
            local ModInfobox = Infobox{
                Style = 'main-right',
                Header = {
                    moddata.ModInfo.name,
                    xml:img{src='images/mods/'..(moddata.ModInfo.icon and stringSanitiseFilename(moddata.ModInfo.name, true, true) or 'mod')..'.png', width='256px'}
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

            local bpMergesSection = ''

            do
                local merges = {}
                for i = 1, #FactionsByIndex do
                    merges[i]={}
                end
                for id, bps in sortedpairs(merge_blueprints) do
                    for i, bp in ipairs(bps) do
                        if bp.ModInfo == moddata.ModInfo then
                            table.insert(merges[ FactionCategoryIndexes[getBP(id).FactionCategory or 'OTHER'] ], bp)
                        end
                    end
                end
                for cati, catbps in ipairs(merges) do
                    if #catbps ~= 0 then
                        if bpMergesSection == '' then
                            bpMergesSection = MDHead('Blueprint merges',2)
                        end
                        bpMergesSection = bpMergesSection..MDHead(FactionsByIndex[cati],3)
                        for i, bp in sortedpairs(catbps, mergeSortByOriginal(TechDescendingDescriptionAscending)) do

                            bpMergesSection = bpMergesSection..tostring(Infobox{
                                Style = 'detail-left',
                                Header = { '[Show] '..unitDescLink(bp.id) },
                                Data = InfoboxFormatRawBlueprint(bp,{{'<LOC wiki_infobox_unitid>Unit ID:', xml:code(bp.id)}}),
                            })
                        end
                    end
                end
            end

            local MDPageName = stringSanitiseFilename(moddata.ModInfo.name)..'.md'

            UpdateGeneratedPartOfPage(MDPageName, 'brewwikimodinfobox', tostring(ModInfobox))
            UpdateGeneratedPartOfPage(MDPageName, 'brewwikileadtext', leadString)
            UpdateGeneratedPartOfPage(MDPageName, 'brewwikimodunits', unitsSection)
            UpdateGeneratedPartOfPage(MDPageName, 'brewwikimergeunits', bpMergesSection)
        end
    end

    print("Generated "..#NavigationData.." mod pages")
end

function GenerateHomePage()
    local UnitMods = {}
    for modindex, moddata in sortedpairs(NavigationData) do
        if GenerateModPageFor(moddata.ModInfo) then
            table.insert(UnitMods, moddata)
        end
    end

    local colLimit = 6

    local numMods = #UnitMods
    local rows = math.ceil(numMods/colLimit)
    local col = numMods//rows
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
            local ModInfo = UnitMods[j].ModInfo

            homeModNav1 = homeModNav1.."\n"..xml:th{align='center'}(xml:a{href=stringSanitiseFilename(ModInfo.name)}(xml:img{
                src='images/mods/'..(ModInfo.icon and stringSanitiseFilename(ModInfo.name, true, true) or 'mod')..'.png',
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
