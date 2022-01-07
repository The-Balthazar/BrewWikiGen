--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local function Binary2bit(a,b) return (a and 2 or 0) + (b and 1 or 0) end

UnitBodytextLeadText = function(ModInfo, bp)

    local bodytext = (bp.General.UnitName and '"'..LOC(bp.General.UnitName)..'" is a' or 'This unamed unit is a')
    ..(bp.General and bp.General.FactionName and string.upper(string.sub(bp.General.FactionName, 1, 1)) == 'A' and 'n ' or ' ')
    ..(bp.General and bp.General.FactionName and bp.General.FactionName..' ' or 'factionless ')
    ..(bp.Physics.MotionType and motionTypes[bp.Physics.MotionType][1] or 'structure')..' unit included in *'..ModInfo.name.."*.\n"

    local BuildIntroTDesc = {
        [0] = LOC('<LOC wiki_intro_tdesc_a>It is an unclassified unit with no defined tech level.'),
        [1] = string.format(LOC('<LOC wiki_intro_tdesc_b>It is an unclassified %s unit.'), string.lower(bp.unitTlevel or '')),
        [2] = string.format(LOC('<LOC wiki_intro_tdesc_c>It is classified as a %s unit with no defined tech level.'), string.lower(bp.unitTdesc or '')),
        [3] = string.format(LOC('<LOC wiki_intro_tdesc_d>It is classified as a %s unit.'), string.lower(bp.unitTdesc or '')),
    }
    BuildIntroTDesc = BuildIntroTDesc[Binary2bit(bp.unitTdesc,bp.unitTlevel)]

    local BuildIntroBuild = {
        [0] = LOC('<LOC wiki_intro_build_a> It has no defined build description, and no categories to define common builders.').."\n",
        [1] = LOC('<LOC wiki_intro_build_b> It has no defined build description.').."<error:buildable unit with no build description>\n",
        [2] = "\n"..LOC('<LOC wiki_intro_build_c>This unit has no categories to define common builders, however the build description for it is:').."\n\n<blockquote>"..LOC(Description[bp.id] or '').."</blockquote>\n",
        [3] = "\n"..LOC('<LOC wiki_intro_build_d>The build description for this unit is:').."\n\n<blockquote>"..LOC(Description[bp.id] or '').."</blockquote>\n",
    }
    BuildIntroBuild = BuildIntroBuild[Binary2bit(Description[bp.id], --[[bp.BuiltByCategories or]] arraySubFind(bp.Categories, 'BUILTBY'))]

    return bodytext..BuildIntroTDesc..BuildIntroBuild..GetModUnitData(bp.ID, 'LeadSuffix')
end

UnitBodytextSectionData = function(ModInfo, bp)
    return setmetatable({
        {
            '<LOC wiki_sect_abilities>Abilities',
            check = bp.Display and bp.Display.Abilities and #bp.Display.Abilities > 0,
            Data = function(bp)
                local text = LOC('<LOC wiki_abilities_hover_note>Hover over abilities to see effect descriptions.').."\n"
                for i, ability in ipairs(bp.Display.Abilities) do
                    text = text.."\n*"..abilityTitle(ability)
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_adjacency>Adjacency',
            check = arraySubFind(bp.Categories, 'SIZE') or bp.Adjacency,
            Data = function(bp)
                local CategorySizeString = arraySubFind(bp.Categories, 'SIZE')
                local CategorySizeNumber = CategorySizeString and tonumber(string.sub(CategorySizeString,5))

                local function GetEffectiveSkirtSize(bp, axe)
                    local sizeA = 'Size'..axe
                    local offsetA = 'SkirtOffset'..axe
                    local sizevalue = math.max(
                        bp.Footprint and bp.Footprint[sizeA] or bp[sizeA] or 1,
                        bp.Physics['Skirt'..sizeA] or 0
                    )
                    if math.floor(bp.Physics[offsetA] or 0) ~= (bp.Physics[offsetA] or 0) - 0.5 then
                        sizevalue = sizevalue - 1
                    end
                    return math.floor(sizevalue / 2) * 2
                end

                local EffectiveSize = math.max(2, GetEffectiveSkirtSize(bp,'X') ) + math.max(2, GetEffectiveSkirtSize(bp, 'Z'))

                local text = (CategorySizeString
                and string.format(
                    LOC("<LOC wiki_adjacency_part1>This unit counts as `%s` for adjacency effects from other structures. This theoretically means that it can be surrounded by exactly %s structures the size of a standard tech 1 power generator"),
                    CategorySizeString, string.sub(CategorySizeString,5)
                )..(
                EffectiveSize and (
                    EffectiveSize == CategorySizeNumber
                    and LOC('<LOC wiki_adjacency_part2_a>, which is accurate; meaning it can get the maximum intended buff effects')

                    or EffectiveSize > CategorySizeNumber
                    and string.format(
                        LOC('<LOC wiki_adjacency_part2_b>, however it is actually larger; meaning it receives %.1f%% better buffs than would normally be afforded it'),
                        (EffectiveSize / CategorySizeNumber - 1) * 100
                    )

                    or EffectiveSize < CategorySizeNumber
                    and string.format(
                        LOC('<LOC wiki_adjacency_part2_c>, however it is actually smaller; meaning it receives %.1f%% weaker buffs than a standard structure of the same skirt size'),
                        (1 - EffectiveSize / CategorySizeNumber) * 100
                    )
                ) or '')..LOC('<LOC wiki_adjacency_part3>. ') or '')

                if bp.Adjacency then
                    text = text..string.format(LOC('<LOC wiki_adjacency_bonus>The adjacency bonus `%s` is given by this unit.'), bp.Adjacency)
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_construction>Construction',
            check = bp.Economy and (bp.BuiltByCategories or arraySubFind(bp.Categories, 'BUILTBY')),
            Data = function(bp)
                local function BuilderList(bp)
                    local bilst = ''

                    if not bp.Economy.BuildCostEnergy then return '<error:no energy build cost>' end
                    if not bp.Economy.BuildCostMass then return '<error:no mass build cost>' end
                    if not bp.Economy.BuildTime then return '<error:no build time>' end

                    local function UpgradesFrom(to, from)
                        return to.General.UpgradesFrom == from.id and from.General.UpgradesTo == to.id
                    end

                    local function BuildByBulletPoint(bp, buildername, buildrate, upgrade)
                        if buildername and buildrate then
                            local secs = bp.Economy.BuildTime / buildrate
                            return "\n* "..iconText('Time', formatTime(secs) )
                            ..' ‒ '..iconText('Energy', math.floor(bp.Economy.BuildCostEnergy / secs + 0.5), '/s')
                            ..' ‒ '..iconText('Mass', math.floor(bp.Economy.BuildCostMass / secs + 0.5), '/s')
                            ..' — '..string.format(LOC(upgrade and 'Upgrade from %s' or 'Built by %s'), buildername)
                        elseif buildername then
                            return "\n* "..string.format(LOC('Built by %s'), buildername)
                        end
                    end

                    local builtbycats = {}

                    for i, cat in ipairs(bp.Categories) do
                        if string.find(cat, 'BUILTBY') then
                            builtbycats[cat] = defaultBuilderCats[cat] and (defaultBuilderCats[cat][3] or defaultBuilderCats[cat][2]) or true
                        end
                    end

                    local builderunits = {}
                    for buildcat, _ in pairs(bp.BuiltByCategories) do
                        local catunits = GetBuilderUnits(buildcat)
                        tableMergeCopy(builderunits, catunits)
                        local bbcat = string.match(buildcat, '(BUILTBY[%w]*)')
                        if builtbycats[bbcat] then
                            for builderid, builderbp in pairs(catunits) do
                                if (not defaultBuilderCats[bbcat]) or builderbp.Economy.BuildRate == builtbycats[bbcat] then
                                    builtbycats[bbcat] = nil
                                    break
                                end
                            end
                        end
                    end

                    for tech, group in ipairs(MenuSortUnitsByTech(builderunits)) do
                        for i, builderbp in ipairs(group) do
                            bilst = bilst..BuildByBulletPoint(bp, pageLink(builderbp.ID, builderbp.unitTdesc), builderbp.Economy.BuildRate, UpgradesFrom(bp, builderbp))
                        end
                    end

                    local tempcats = {}
                    for cat, v in pairs(builtbycats) do
                        table.insert(tempcats, cat)
                    end
                    table.sort(tempcats, function(a,b)
                        local function key(c) return string.gsub(c, '(%a*)(TIER%d)(%w*)','%1%3%2') end
                        return key(a) < key(b)
                    end)

                    for i, cat in ipairs(tempcats) do
                        if defaultBuilderCats[cat] then
                            bilst = bilst..BuildByBulletPoint(bp, LOC(defaultBuilderCats[cat][1]), defaultBuilderCats[cat][2])
                        --elseif string.find(cat, 'BUILTBY') then
                            --bilst = bilst..BuildByBulletPoint(bp, LOC('units with ').."<error:category /><code>"..cat.."</code>" )
                        end
                    end

                    --[[if bp.General.UpgradesFrom and not getBP(bp.General.UpgradesFrom) then
                        bilst = bilst..BuildByBulletPoint(bp, "<waring:unverifiable /><code>"..bp.General.UpgradesFrom.."</code>", nil, true )
                    end]]

                    return bilst
                end
                return LOC("<LOC wiki_builders_note>Build times from hard coded builders on the Steam/retail version of the game:")..BuilderList(bp)
            end
        },
        {
            '<LOC wiki_sect_orders>Order capabilities',
            check = bp.General and ( tableHasTrueChild(bp.General.CommandCaps) or tableHasTrueChild(bp.General.ToggleCaps) ),
            Data = function(bp)
                local orderButtonImage = function(orderName, bp)
                    local Order = tableOverwrites(defaultOrdersTable[orderName], bp and bp[orderName])
                    local returnstring

                    if Order then
                        local Tip = Tooltips[Order.helpText] or {title = 'error:'..Order.helpText..' no title'}
                        returnstring = '<img float="left" src="'..IconRepo..'orders/'..string.lower(Order.bitmapId)..'.png" title="'..LOC(Tip.title or '')..(Tip.description and Tip.description ~= '' and "\n"..LOC(Tip.description) or '')..'" />'
                    end
                    return returnstring or orderName, Order
                end

                local ordersarray = {}
                for i, hash in ipairs({bp.General.CommandCaps or {}, bp.General.ToggleCaps or {}}) do
                    for order, val in pairs(hash) do
                        if val then
                            table.insert(ordersarray, order)
                        end
                    end
                end
                table.sort(ordersarray, function(a, b) return (defaultOrdersTable[a].preferredSlot or 99) < (defaultOrdersTable[b].preferredSlot or 99) end)

                local text = LOC('<LOC wiki_orders_note>The following orders can be issued to the unit:').."\n<table>\n"
                local slot = 99
                for i, v in ipairs(ordersarray) do
                    local orderstring, order = orderButtonImage(v, bp.General.OrderOverrides)
                    if order then
                        if (slot <= 6 and order.preferredSlot >= 7) then
                            text = text.."<tr>\n"
                        end
                        slot = order.preferredSlot
                    end
                    text = text .. "<td>"..orderstring.."</td>\n"
                end
                return text.."</table>"
            end
        },
        {
            '<LOC wiki_sect_engineering>Engineering',
            check = bp.Economy and bp.Economy.BuildRate and
            (
                bp.Economy.BuildableCategory or bp.General and bp.General.CommandCaps and
                (
                    bp.General.CommandCaps.RULEUCC_Capture or
                    bp.General.CommandCaps.RULEUCC_Reclaim or
                    bp.General.CommandCaps.RULEUCC_Repair or
                    bp.General.CommandCaps.RULEUCC_Sacrifice
                )
            ),
            Data = function(bp)
                local eng = {}
                if bp.General and bp.General.CommandCaps then
                    local eng2 = {
                        {'capture', bp.General.CommandCaps.RULEUCC_Capture},
                        {'reclaim', bp.General.CommandCaps.RULEUCC_Reclaim},
                        {'repair', bp.General.CommandCaps.RULEUCC_Repair},
                        {'sacrifice', bp.General.CommandCaps.RULEUCC_Sacrifice},
                    }
                    for i, v in ipairs(eng2) do
                        if v[2] then
                            table.insert(eng, v)
                        end
                    end
                end
                local text = ''
                if #eng > 0 then
                    text = text..'The engineering capabilties of this unit consist of the ability to '
                    for i = 1, #eng do
                        text = text..eng[i][1]
                        if i < #eng then
                            text = text..', '
                        end
                        if i + 1 == #eng then
                            text = text..'and '
                        end
                        if i == #eng then
                            text = text..".\n"
                        end
                    end
                end

                if bp.Economy.BuildableCategory then

                    local BuildableUnits = GetBuildableUnits(bp.Economy.BuildableCategory)
                    local NumBuildable = tableTcount(BuildableUnits)

                    local TempBuildableCategory = tableMergeCopy({}, bp.Economy.BuildableCategory)

                    if bp.General.UpgradesTo then
                        if BuildableUnits[bp.General.UpgradesTo] then
                            local upgradeBp = BuildableUnits[bp.General.UpgradesTo]
                            text = text..'It can be upgraded into the '..pageLink(upgradeBp.ID, upgradeBp.unitTdesc)..".\n"

                            BuildableUnits[upgradeBp.id] = nil
                            NumBuildable = NumBuildable-1

                        elseif getBP(bp.General.UpgradesTo) then
                            local upgradeBp = getBP(bp.General.UpgradesTo)
                            text = text..'<error:upgrade not verified>It claims to upgradable into the '..pageLink(upgradeBp.ID, upgradeBp.unitTdesc)..", however build categories would indicate otherwise.\n"

                        else
                            local cat = arrayFind(TempBuildableCategory, bp.General.UpgradesTo)
                            if cat then
                                text = text..'It can be upgraded into <code>'..string.lower(bp.General.UpgradesTo).."</code>.\n"
                            else
                                text = text..'It is listed as upgradable into <code>'..string.lower(bp.General.UpgradesTo).."</code>.\n"
                            end

                        end
                        arrayRemoveByValue(TempBuildableCategory, bp.General.UpgradesTo)
                    end

                    if #TempBuildableCategory == 1 then
                        local buildBp = getBP(TempBuildableCategory[1])
                        if buildBp then
                            text = text..'It can build the '..pageLink(buildBp.ID, buildBp.unitTdesc)..".\n"

                            BuildableUnits[buildBp.id] = nil
                            NumBuildable = NumBuildable-1

                        else
                            text = text..'It has the build category <code>'..TempBuildableCategory[1]..'</code>.'..(NumBuildable~=0 and ' ' or "\n")
                        end
                    elseif #TempBuildableCategory > 1 then
                        text = text.."It has the build categories:\n"
                        for i, cat in ipairs(TempBuildableCategory) do
                            text = text.."* <code>"..cat.."</code>\n"
                        end
                        text = text..(NumBuildable > 0 and NumBuildable < 30 and "\n" or '')
                    end

                    local limit = 200 -- This is basically just to remove the list from the iyadesu page

                    if NumBuildable > 0 and NumBuildable <= limit then
                        do
                            local _,unitbp = next(BuildableUnits)
                            local bitcheck = {
                                [0] = string.format(LOC('This build category allows it to build the mod unit %s.'), pageLink(unitbp.ID, unitbp.unitTdesc) ).."\n",
                                [1] = "\n<details>\n<summary>"..LOC('This build category allows it to build the following mod units:').."\n\n".."</summary>\n\n",
                                [2] = string.format(LOC('These build categories allow it to build the mod unit %s.'), pageLink(unitbp.ID, unitbp.unitTdesc) ).."\n",
                                [3] = "\n<details>\n<summary>"..LOC('These build categories allow it to build the following mod units:').."\n\n".."</summary>\n\n",
                            }
                            text = text..bitcheck[Binary2bit(#TempBuildableCategory ~= 1, NumBuildable ~= 1)]
                        end

                        local SortedUnits = MenuSortUnitsByTech(BuildableUnits)

                        local maxcols = 8

                        if NumBuildable > 1 then

                            local colsneeded = 0

                            for i, group in ipairs(SortedUnits) do
                                if #group > maxcols then
                                    colsneeded = math.max(colsneeded, math.ceil(#group/ math.ceil(#group/maxcols) ))
                                else
                                    colsneeded = math.max(colsneeded, #group)
                                end
                            end

                            maxcols = math.min(maxcols, colsneeded)

                            local trtext = "\n"
                            for i, group in ipairs(SortedUnits) do
                                if group[1] then
                                    local trows = math.ceil(#group/maxcols)
                                    for trow = 1, trows do
                                        local tdtext = "\n"..(trow == 1 and '        '..xml:td{rowspan=trows~=1 and trows or nil}(xml:img{src=IconRepo..'T'..i..'.png', title='T'..i}).."\n" or '')
                                        for coli = 1, maxcols do
                                            local buildbp = group[maxcols*(trow-1)+coli]
                                            if buildbp then
                                                tdtext = tdtext..'        '..xml:td( pageLink(buildbp.ID, xml:img{src=unitIconRepo..buildbp.ID..'_icon.png', width='64px'}) ).."\n"
                                            end
                                        end
                                        trtext = trtext..'    '..xml:tr(tdtext..'    ').."\n"
                                    end
                                end
                            end
                            text = text..xml:table(trtext).."\n\n</details>\n"
                        end
                    elseif NumBuildable >= limit then
                        --text = text.."\nThis boi can build a lot of things.\n"
                    end
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_enhancements>Enhancements',
            check = bp.Enhancements,
            Data = function(bp)
                local EnhacementsSorted = {}
                for key, enh in pairs(bp.Enhancements) do
                    local SearchForRquisits
                    SearchForRquisits = function(enhancements, req)
                        for key, enh in pairs(enhancements) do
                            if req == enh.Prerequisite then
                                table.insert(EnhacementsSorted, {key, enh})
                                SearchForRquisits(enhancements, key)
                            end
                        end
                    end
                    if not enh.Prerequisite then
                        table.insert(EnhacementsSorted, {key, enh})
                        SearchForRquisits(bp.Enhancements, key)
                    end
                end
                local text = ''
                for i, enh in ipairs(EnhacementsSorted) do
                    local key = enh[1]
                    local enh = enh[2]
                    if key ~= 'Slots' and string.sub(key, -6, -1) ~= 'Remove' then
                        text = text..tostring(Infobox{
                            Style = 'detail-left',
                            Header = {enh.Name and LOC(enh.Name) or 'error:name'},
                            Data = {
                                { 'Description:', (LOC(Description[bp.id..'-'..string.lower(enh.Icon)]) or 'error:description') },
                                { 'Energy cost:', iconText('Energy', enh.BuildCostEnergy or 'error:energy') },
                                { 'Mass cost:', iconText('Mass', enh.BuildCostMass or 'error:mass') },
                                { 'Build time:', iconText('Time', enh.BuildTime and bp.Economy and bp.Economy.BuildRate and math.ceil(enh.BuildTime / bp.Economy.BuildRate) or 'error:time').." seconds" },
                                { 'Prerequisite:', (enh.Prerequisite and LOC(bp.Enhancements[enh.Prerequisite].Name) or 'None') },
                            },
                        })
                    end
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_transport>Transport capacity',
            check = bp.General and bp.General.CommandCaps and bp.General.CommandCaps.RULEUCC_Transport and bp.Transport,
            Data = function(bp)
                if bp.Bones then
                    local data = {
                        [1] = { Count = 0, Bone = 'Attachpoint',--[[Class = 1,]]Name = 'small' },
                        [2] = { Count = 0, Bone = 'Attachpoint_Med', Class = 2, Name = 'medium' },
                        [3] = { Count = 0, Bone = 'Attachpoint_Lrg', Class = 3, Name = 'large' },
                        [4] = { Count = 0, Bone = 'Attachpoint_Spr', Class = 4, Name = 'super size' },
                        [5] = { Count = 0, Bone = 'AttachSpecial', Class = 'S', Name = 'drone' },
                    }
                    for i, bone in pairs(bp.Bones) do
                        for i = 0, 4 do
                            if string.find(bone, data[5-i].Bone) then -- Work backwards because small matches 2-4
                                data[5-i].Count = data[5-i].Count + 1
                                break
                            end
                        end
                    end

                    local numSmallBones
                    local totalAttachBones = 0
                    local numGroupsClassLimited = 0
                    local numGroupsBoneLimited = 0
                    local numGroups = 0
                    local usedClasses = {}
                    for i, datum in ipairs(data) do
                        if not datum.Class then numSmallBones = datum.Count end
                        local LongClass = 'Class'..(datum.Class or 1)..'AttachSize'

                        if datum.Class and bp.Transport[LongClass] then
                            datum.Limit = numSmallBones/bp.Transport[LongClass]
                            if datum.Limit < datum.Count and datum.Count > 1 then numGroupsClassLimited = numGroupsClassLimited + 1 end
                            if datum.Limit > datum.Count and datum.Count > 1 then numGroupsBoneLimited = numGroupsBoneLimited + 1 end
                            if datum.Count ~= 0 then table.insert(usedClasses, { Class = LongClass, Name = datum.Name }) end
                        end

                        if datum.Count ~= 0 then numGroups = numGroups + 1 end

                        totalAttachBones = totalAttachBones + datum.Count
                    end

                    if totalAttachBones > 0 then
                        local text = 'This unit has '
                        local sects = {}
                        if (bp.Transport.DockingSlots and bp.Transport.DockingSlots > 0) then
                        --or (bp.Transport.StorageSlots and bp.Transport.StorageSlots > 0) then
                            text = text..bp.Transport.DockingSlots..' docking slot'..pluralS(bp.Transport.DockingSlots)..' consisting of '
                        end
                        for i, datum in ipairs(data) do
                            if datum.Count > 0 then
                                table.insert(sects, datum.Count..' '..datum.Name..' attach point'..pluralS(datum.Count))
                            end
                        end

                        for i, sect in ipairs(sects) do
                            if i > 1 then text = text..', ' end
                            if i == #sects and i > 1 then text = text..'and ' end
                            text = text..sect
                            if i == #sects then text = text..'. ' end
                        end

                        if numSmallBones
                        and numSmallBones > 1
                        and totalAttachBones > 1
                        and numGroups > 1 then
                            text = text.."Using an attach point that isn't small costs a number of small attach points. Specifically "
                            for i, datum in ipairs(usedClasses) do
                                if i > 1 then text = text..', ' end
                                if i == #usedClasses and i > 1 then text = text..'and ' end
                                text = text..bp.Transport[datum.Class]..' for '..datum.Name
                                if i == #usedClasses then text = text..'. ' end
                            end
                        end

                        if numGroupsClassLimited > 0 then
                            if numGroupsClassLimited == 1 then
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit < datum.Count then
                                        text = text..'Due to these costs, not all '..datum.Name..' attach points can be used concurrently; at most '..math.floor(datum.Limit)..' of them could be used at a given time, and the physical layout of them may reduce that number further.'
                                        break
                                    end
                                end
                            else--if numGroupsClassLimited > 1 then
                                text = text..'Due to these costs; at most '
                                local done = 0
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit < datum.Count then
                                        done = done + 1
                                        text = text..math.floor(datum.Limit)..' '..datum.Name

                                        if done < numGroupsClassLimited then text = text..', ' end
                                        if done + 1 == numGroupsClassLimited then text = text..'or ' end
                                    end
                                end
                                text = text..'attach points can be used concurrently, and this may be further reduced by the physical layout of said bones. '
                            end
                        end
                        if numGroupsBoneLimited > 0 then
                            if numGroupsBoneLimited == 1 then
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit > datum.Count then
                                        local freeSmalls = numSmallBones-(math.floor(datum.Count)*bp.Transport['Class'..datum.Class..'AttachSize'])

                                        text = text..'With all '..datum.Name..' bones occupied '..freeSmalls..' small attach point'..pluralS(freeSmalls)..' would be free still.'
                                        break
                                    end
                                end
                            else--if numGroupsBoneLimited > 1 then
                                text = text..'With all attach points of a given size occupied, there would still be a number of small points free. Specifically '
                                local done = 0
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit > datum.Count then
                                        done = done + 1
                                        local freeSmalls = numSmallBones-(math.floor(datum.Count)*bp.Transport['Class'..datum.Class..'AttachSize'])

                                        text = text..freeSmalls..' with '..datum.Name

                                        if done < numGroupsBoneLimited then text = text..', ' end
                                        if done + 1 == numGroupsBoneLimited then text = text..'or ' end
                                    end
                                end
                                text = text..'. '
                            end
                        end
                        return text
                    elseif --(bp.Transport.DockingSlots and bp.Transport.DockingSlots > 0) or
                    (bp.Transport.StorageSlots and bp.Transport.StorageSlots > 0) then
                        return 'This unit has '..bp.Transport.StorageSlots..' storage slots.'
                    end
                else
                    return "<error: cant load mesh>"
                end
            end
        },
        {
            '<LOC wiki_sect_weapons>Weapons',
            check = bp.Weapon,
            Data = GetWeaponBodytextSectionString
        },
        {
            '<LOC wiki_sect_vet>Veteran levels',
            check = bp.Veteran and bp.Veteran.Level1,
            Data = function(bp)
                local text
                if not bp.Weapon or (bp.Weapon and #bp.Weapon == 1 and IsDeathWeapon(bp.Weapon[1])) then
                    text = "This unit has defined veteran levels, despite not having any weapons. Other effects can still give experience towards those levels though, which are as follows; note they replace each other by default:\n"
                else
                    text = "Note: Each veteran level buff replaces the previous by default; values are shown here as written.\n"
                end

                for i = 1, 5 do
                    local lev = 'Level'..i
                    if bp.Veteran[lev] then
                        text = text .. "\n"..i..'. '..bp.Veteran[lev]..' kills gives: '..(bp.Defense and bp.Defense.MaxHealth and iconText('Health', '+'..numberFormatNoTrailingZeros(bp.Defense.MaxHealth / 10 * i) ) or 'error:vet defined and no defense defined' )
                        if bp.Buffs then
                            for buffname, buffD in pairs(bp.Buffs) do
                                if buffD[lev] then
                                    if buffname == 'Regen' then
                                        text = text..' (+'..buffD[lev]..'/s)'
                                    else
                                        text = text..' '..buffname..': '..buffD[lev]
                                    end
                                end
                            end
                        end
                    end
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_videos>Videos',
            check = pcall(function() assert(UnitData and UnitData[bp.ID] and UnitData[bp.ID].Videos and #UnitData[bp.ID].Videos > 0) end),
            Data = function(bp)
                local text = ''
                for i, video in ipairs(UnitData[bp.ID].Videos) do
                    if video.YouTube then
                        text = text..tostring(Infobox{
                            Style = 'detail-left',
                            Header = {video[1]},
                            Data =
                            '        '..xml:td(
                            '            '..xml:a{href='https://youtu.be/'..video.YouTube}(
                            '                '..xml:img{title=video[1], src='https://i.ytimg.com/vi/'..video.YouTube..'/mqdefault.jpg'},
                            '            '),
                            '        ').."\n"
                        })
                    end
                end
                return text
            end
        },
    }, {

        __tostring = function(self)
            local bodytext = ''
            for i, section in ipairs(self) do
                if section.check then
                    bodytext = bodytext..MDHead(section[1])..GetModUnitData(bp.ID, noLOC(section[1])..'Prefix')..section.Data(bp).."\n"..GetModUnitData(bp.ID, noLOC(section[1])..'Suffix')
                end
            end
            return bodytext
        end,

    })
end

--------------------------------------------------------------------------------

TableOfContents = function(BodyTextSections)
    local sections = 0

    for i, section in ipairs(BodyTextSections) do
        if section.check then
            sections = sections + 1
        end
    end

    if sections >= 3 then
        local text = "\n<details>\n<summary>"..LOC("<LOC wiki_toc_contents>Contents").."</summary>\n\n"
        local index = 1
        for i, section in ipairs(BodyTextSections) do
            if section.check then
                text = text .. index..'. – '..sectionLink(LOC(section[1])).."\n"
                index = index + 1
            end
        end
        return text.."</details>\n"
    end
    return ''
end

MDHead = function(header, hnum)
    return "\n"..string.rep('#', hnum or 3)..' '..LOC(header).."\n"
end

GetModUnitData = function(id, sect)
    if pcall(function()assert(UnitData[id])end) and UnitData[id][sect] then
        return "\n"..UnitData[id][sect].."\n"
    end
    return ''
end

--------------------------------------------------------------------------------
