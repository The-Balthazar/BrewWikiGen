--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local function Binary2bit(a,b) return (a and 2 or 0) + (b and 1 or 0) end

local function GetSectionExtraData(id, sect)
    return UnitData[id][sect] and (type(UnitData[id][sect]) == 'string' and "\n"..LOC(UnitData[id][sect]).."\n" or UnitData[id][sect])
end

function UnitHeaderString(bp)
    return bp.General.UnitName and bp.TechDescription and string.format("\"%s\": %s\n----\n", bp.General.UnitName, bp.TechDescription)
    or bp.General.UnitName and string.format("\"%s\"\n----\n", bp.General.UnitName )
    or bp.TechDescription and string.format("%s\n----\n", bp.TechDescription)
    or ''
end

function UnitBodytextLeadText(bp)

    local faction = FactionFromFactionCategory(bp.FactionCategory)

    local bodytext = bp.General.UnitName and
        string.format(
        LOC("<LOC wiki_intro_name>\"%s\""), bp.General.UnitName) or
        LOC('<LOC wiki_intro_nameless>This unnamed unit')

    local FactionText = {
        [0] = LOC('<LOC wiki_intro_factionless> is a factionless'),
        [1] = LOC('<LOC wiki_intro_faction_'..string.lower(faction or 'other')..'> is a'..(string.match(faction or '', '^[aeiouAEIOU]')and'n'or'')..' '..(faction or '')),
        [2] = LOC('<LOC wiki_intro_multifaction>, which has multiple factions, is a'),
    }
    FactionText[3]=FactionText[1]

    bodytext = bodytext..
    FactionText[Binary2bit(next(bp.FactionCategoryHash), bp.FactionCategory ~= 'OTHER')]..
    string.format(
        LOC('<LOC wiki_intro_motion_type> %s included in *%s*.'),
        LOC('<LOC wiki_intro_'..string.lower(bp.Physics.MotionType or 'RULEUMT_None')..'>'),
        bp.ModInfo.name
    ).."\n"

    local BuildIntroTDesc = {
        [0] = LOC('<LOC wiki_intro_tdesc_a>It is an unclassified unit with no defined tech level.'),
        [1] = string.format(LOC('<LOC wiki_intro_tdesc_b>It is an unclassified %s unit.'), string.lower(bp.TechName or '')),
        [2] = string.format(LOC('<LOC wiki_intro_tdesc_c>It is classified as a %s unit with no defined tech level.'), string.lower(bp.TechDescription or '')),
        [3] = string.format(LOC('<LOC wiki_intro_tdesc_d>It is classified as a %s unit.'), string.lower(bp.TechDescription or '')),
    }
    BuildIntroTDesc = BuildIntroTDesc[Binary2bit(bp.TechDescription,bp.TechName)]

    local BuildIntroBuild = {
        [0] = LOC('<LOC wiki_intro_build_a> It has no defined build description, and no categories to define common builders.').."\n",
        [1] = "\n<p><error:buildable unit with no build description></p>\n",--[[LOC('<LOC wiki_intro_build_b> It has no defined build description.')..]]
        [2] = "\n"..LOC('<LOC wiki_intro_build_c>This unit has no categories to define common builders, however the build description for it is:').."\n\n<blockquote>"..LOC(Description[bp.id] or '').."</blockquote>\n",
        [3] = "\n"..LOC('<LOC wiki_intro_build_d>The build description for this unit is:').."\n\n<blockquote>"..LOC(Description[bp.id] or '').."</blockquote>\n",
    }
    BuildIntroBuild = BuildIntroBuild[Binary2bit(Description[bp.id], arraySubFind(bp.Categories, 'BUILTBY'))]

    return bodytext..BuildIntroTDesc..BuildIntroBuild..(GetSectionExtraData(bp.ID, 'LeadSuffix') or '')
end

function UnitBodytextSectionData(bp)
    return setmetatable({
        {
            '<LOC wiki_sect_abilities>Abilities',
            check = bp.Display and bp.Display.Abilities and #bp.Display.Abilities > 0,
            Data = function(bp)
                local text = WikiOptions.AbilityDescriptions and LOC('<LOC wiki_abilities_hover_note>Hover over abilities to see effect descriptions.').."\n" or ''
                for i, ability in ipairs(bp.Display.Abilities) do
                    text = text.."\n*"..(WikiOptions.AbilityDescriptions and abilityTitle(ability) or ' '..LOC(ability))
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
                    return math.floor(sizevalue/2)*2
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
                    local adjline = string.format(LOC('<LOC wiki_adjacency_bonus>The adjacency bonus `%s` is given by this unit.'), bp.Adjacency)
                    local AdjacencyBuffs = AdjacencyBuffs[bp.Adjacency]

                    if AdjacencyBuffs then

                        local affects = {}
                        for i, buffName in ipairs(AdjacencyBuffs) do
                            if Buffs[buffName].Affects then
                                for effect, info in pairs(Buffs[buffName].Affects) do
                                    effect = BuffAffectsNames[effect] or effect
                                    if not table.find(affects, effect) then
                                        table.insert(affects, effect)
                                    end
                                end
                            end
                        end
                        table.sort(affects)

                        local numberBuffsTotal = #AdjacencyBuffs
                        local numberAffectsTotal = #affects

                        local function ordinalSuffix(val)
                            val = math.floor(val)%10
                            if val == 1 then
                                return 'st'
                            elseif val == 2 then
                                return 'nd'
                            elseif val == 3 then
                                return 'rd'
                            end
                            return 'th'
                        end

                        local function DisplayFraction(val)
                            if math.abs(val) < 1 then
                                local denominator1mod1 = (1 / math.abs(val)) % 1
                                local numerator = 1
                                if denominator1mod1 ~= 0 and (math.floor((((1/denominator1mod1))*100)+0.5)/100)%1 == 0 then
                                    numerator = math.floor(1/denominator1mod1+0.5)
                                end
                                local denominator = math.floor((((1 / math.abs(val))*100)*numerator)+0.5)/100
                                return (val<0 and '-' or '')..formatNumber(numerator)..'⁄'..formatNumber(denominator)--..'<sup>'..ordinalSuffix(denominator)..(numerator == 1 and '' or 's')..'</sup>'
                            end
                            return val
                        end

                        local function GetEffectVal(info)
                            local val = ''
                            local add = info.Add ~= 0
                            local mul = info.Mult ~= 1
                            if add then
                                val = val..(info.Add>0 and'+'or'')..DisplayFraction(info.Add)
                            end
                            if add and mul then
                                val = val..' and '
                            end
                            if mul then
                                val = val..'×'..DisplayFraction(info.Mult)
                            end
                            return val
                        end

                        if numberBuffsTotal == 1 and numberAffectsTotal == 1 then
                            local buff = Buffs[AdjacencyBuffs[1]]
                            local name, effect = next(buff.Affects)
                            local buffcat = buff.EntityCategory and '`'..buff.EntityCategory..'`' or buff.ParsedEntityCategory[1] or '`error`'
                            text = text.."\n\n"..adjline..' This gives '..GetEffectVal(effect)..' '..(BuffAffectsNames[name] or name)..' to '..buffcat..' units.'

                        else
                            text = text.."\n\n"..adjline..' This affects '..stringConcatOxfordComma(affects)..'.'

                            local cats = {}
                            local catOrder = {}

                            for i, buffName in ipairs(AdjacencyBuffs) do
                                local buff = Buffs[buffName]
                                if buff then
                                    local entCat = (buff.EntityCategory or buff.ParsedEntityCategory[1] or '`error`')
                                    if not cats[entCat] then
                                        cats[entCat] = {}
                                        table.insert(catOrder, entCat)
                                    end
                                    table.insert(cats[entCat], buff)
                                end
                            end

                            for i, cat in ipairs(catOrder) do
                                local catSet = cats[cat]
                                local buffInfo = Infobox{
                                    Style = 'detail-left',
                                    Header = {'<code>'..cat..'</code>'},
                                    Data = {},
                                }
                                for i, buff in ipairs(catSet) do
                                    if buff.Affects then
                                        for effect, info in sortedpairs(buff.Affects) do

                                            local title = BuffAffectsNames[effect] or effect
                                            title = title:sub(1,1):upper()..title:sub(2)..':'

                                            local val = GetEffectVal(info)

                                            table.insert(buffInfo.Data, {title, val})

                                        end
                                    end
                                end

                                text = text.."\n\n"..tostring(buffInfo)
                            end
                        end


                    else
                        text = text..adjline
                    end
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_balance>Balance',
            check = bp.WikiBalance or merge_blueprints[bp.id],
            Data = function(bp)
                local text = ''
                if bp.WikiBalance then
                    text = WikiOptions.BalanceNote and LOC'<LOC wiki_balance_dynamic_script>A dynamic balance script changes the stats of this unit on game launch based on the stats of other units.' or ''

                    if bp.WikiBalance.Affects then
                        text = (text ~= '' and text..' ' or '')..string.format(LOC((#bp.WikiBalance.Affects == 1) and
                            '<LOC wiki_balance_stats_affected_singular>Stats effected are from the %s blueprint section' or
                            '<LOC wiki_balance_stats_affected>Stats effected are from the %s blueprint sections'
                        ), stringConcatOxfordComma(bp.WikiBalance.Affects, xml:code{}))

                        if bp.WikiBalance.ReferenceIDs then
                            local refNum = #bp.WikiBalance.ReferenceIDs

                            text = text..string.format(LOC(refNum == 1 and '<LOC wiki_balance_based> and are based on %s' or
                            refNum == 2 and '<LOC wiki_balance_based_average> and are based on an average of %s and %s'),
                            unitDescLink(bp.WikiBalance.ReferenceIDs[1]),
                            unitDescLink(bp.WikiBalance.ReferenceIDs[2]))
                        end

                        text = text..".\n\n"
                    end
                    text = text..(WikiOptions.BalanceNote and LOC(WikiOptions.BalanceNote) or '')
                end
                if bp.WikiBalance and merge_blueprints[bp.id] then
                    text = text.."\n\n"
                end
                if merge_blueprints[bp.id] then
                    if #merge_blueprints[bp.id] == 1 then
                        text = text.."This unit has the folloing blueprint merge affecting it:\n"
                    else
                        text = text.."This unit is affected by the following blueprint merges:\n"
                    end
                    -- This should have been recursive.
                    for i, mergebp in ipairs(merge_blueprints[bp.id]) do
                        text = text..tostring(Infobox{
                            Style = 'detail-left',
                            Header = { 'From '..xml:i(mergebp.ModInfo.name) },
                            Data = InfoboxFormatRawBlueprint(mergebp),
                        })
                    end
                end
                return text
            end
        },
        {
            '<LOC wiki_sect_construction>Construction',
            check = bp.Economy and bp.BuiltByCategories,
            Data = function(bp)
                local function BuilderList(bp)
                    local bilst = ''

                    if not bp.Economy.BuildCostEnergy then return '<error:no energy build cost>' end
                    if not bp.Economy.BuildCostMass then return '<error:no mass build cost>' end
                    if not bp.Economy.BuildTime then return '<error:no build time>' end

                    local function UpgradesFrom(to, from)
                        return (to.General.UpgradesFrom == from.id and from.General.UpgradesTo == to.id) and from
                    end

                    local function BuildByBulletPoint(bp, buildername, buildrate, upgrade)
                        if buildername and buildrate and buildrate ~= 0 then
                            local secs = bp.Economy.BuildTime / buildrate
                            local costmult = upgrade and bp.Economy.HalfPriceUpgradeFromID and 0.5 or 1
                            local costminusE = upgrade and bp.Economy.DifferentialUpgradeCostCalculation and upgrade.Economy.BuildCostEnergy or 0
                            local costminusM = upgrade and bp.Economy.DifferentialUpgradeCostCalculation and upgrade.Economy.BuildCostMass or 0

                            return "\n* "..iconText('Time', formatTime(secs) )
                            ..' ‒ '..iconText('Energy', LOCPerSec(math.floor((bp.Economy.BuildCostEnergy * costmult - costminusE) / secs + 0.5)))
                            ..' ‒ '..iconText('Mass', LOCPerSec(math.floor((bp.Economy.BuildCostMass * costmult - costminusM) / secs + 0.5)))
                            ..' — '..string.format(LOC(upgrade and 'Upgrade from %s' or 'Built by %s'), buildername)
                        elseif buildername then
                            return "\n* "..
                            (buildrate == 0 and "<error:buildrate 0>" or '')..
                            string.format(LOC('Built by %s'), buildername)
                        end
                    end

                    local builderunits = {}

                    if bp.BuiltByCategories then
                        for buildcat, _ in pairs(bp.BuiltByCategories) do
                            local catunits = GetBuilderUnits(buildcat)
                            tableMergeCopy(builderunits, catunits)
                        end
                    end

                    for tech, group in ipairs(SplitUnitsByTech(builderunits)) do
                        for builderid, builderbp in sortedpairs(group, BuildMenuSort) do
                            if (builderid ~= 'ssl0403' and builderid ~= 'ssa0001') or bp.Wreckage or bp.CategoriesHash.RECLAIMABLE then
                                bilst = bilst..BuildByBulletPoint(bp,
                                    pageLink(
                                        builderbp.ID,
                                        -- For more context, it will include the name if it exists when no page will be linked to.
                                        (builderbp.General.UnitName and not builderbp.ModInfo.GenerateWikiPages and ('"'..builderbp.General.UnitName..'": ') or '')..builderbp.TechDescription
                                    ),
                                    builderbp.Economy.BuildRate,
                                    UpgradesFrom(bp, builderbp)
                                )
                            end
                        end
                    end

                    return bilst
                end

                return (WikiOptions.ConstructionNote and LOC(WikiOptions.ConstructionNote) or '')..BuilderList(bp)
            end
        },
        {
            '<LOC wiki_sect_orders>Order capabilities',
            check = bp.General and ( tableHasTrueChild(bp.General.CommandCaps) or tableHasTrueChild(bp.General.ToggleCaps) ),
            Data = function(bp)
                local function orderButtonImage(orderName, bp)
                    local Order = tableOverwrites(defaultOrdersTable[orderName], bp and bp[orderName])
                    local returnstring

                    if Order then
                        local Tip = Tooltips[Order.helpText] or {title = 'error:'..Order.helpText..' no title'}
                        returnstring = xml:img{
                            float = 'left',
                            src = OutputAsset('icons/orders/'..string.lower(Order.bitmapId)..'.png'),
                            title = LOC(Tip.title or '')..(Tip.description and Tip.description ~= '' and "\n"..LOC(Tip.description) or '')
                        }
                    end
                    return returnstring or orderName, Order
                end

                local text = LOC('<LOC wiki_orders_note>The following orders can be issued to the unit:').."\n<table>\n"
                local slot = 99
                for i, v in sortedpairs(
                    Unhash(bp.General.CommandCaps, bp.General.ToggleCaps),
                    function(a) return defaultOrdersTable[a].preferredSlot or 99 end
                ) do
                    local orderstring, order = orderButtonImage(v, bp.General.OrderOverrides)
                    if order then
                        if (slot <= 6 and order.preferredSlot >= 7) then
                            text = text.."<tr>\n"
                        end
                        slot = order.preferredSlot
                    end
                    text = text..xml:td(orderstring).."\n"
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
                        {'capture',   bp.General.CommandCaps.RULEUCC_Capture},
                        {'reclaim',   bp.General.CommandCaps.RULEUCC_Reclaim},
                        {'repair',    bp.General.CommandCaps.RULEUCC_Repair},
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

                    local BuildableUnits = GetBuildableModUnits(bp.Economy.BuildableCategory)
                    local BuildableEnvUnits = GetBuildableUnits(bp.Economy.BuildableCategory)
                    local NumBuildable = table.getsize(BuildableUnits)

                    local TempBuildableCategory = tableMergeCopy({}, bp.Economy.BuildableCategory)

                    if bp.General.UpgradesTo then
                        if BuildableEnvUnits[bp.General.UpgradesTo] then
                            local upgradeBp = BuildableEnvUnits[bp.General.UpgradesTo]
                            text = text..'It can be upgraded into the '..pageLink(upgradeBp.ID, upgradeBp.TechDescription)..".\n"

                            if BuildableUnits[upgradeBp.id] then
                                BuildableUnits[upgradeBp.id] = nil
                                NumBuildable = NumBuildable-1
                            end

                        elseif getBP(bp.General.UpgradesTo) then
                            local upgradeBp = getBP(bp.General.UpgradesTo)
                            text = text..'<error:upgrade not verified>It claims to upgradable into the '..pageLink(upgradeBp.ID, upgradeBp.TechDescription)..", however build categories would indicate otherwise.\n"

                        else
                            local cat = table.find(TempBuildableCategory, bp.General.UpgradesTo)
                            if cat then
                                text = text..'It can be upgraded into <code>'..string.lower(bp.General.UpgradesTo).."</code>.\n"
                            else
                                text = text..'It is listed as upgradable into <code>'..string.lower(bp.General.UpgradesTo).."</code>.\n"
                            end
                        end

                        table.removeByValue(TempBuildableCategory, bp.General.UpgradesTo)
                    end

                    if #TempBuildableCategory == 1 then
                        local buildBp = getBP(TempBuildableCategory[1])
                        if buildBp then
                            text = text..'It can build the '..pageLink(buildBp.ID, buildBp.TechDescription)..".\n"

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
                            local bitcheck = WikiOptions.BuildListSaysModUnits and {
                                [0] = string.format(LOC('This build category allows it to build the mod unit %s.'), pageLink(unitbp.ID, unitbp.TechDescription) ).."\n",
                                [1] = "\n<details>\n<summary>"..LOC('This build category allows it to build the following mod units:').."\n\n".."</summary>\n\n",
                                [2] = string.format(LOC('These build categories allow it to build the mod unit %s.'), pageLink(unitbp.ID, unitbp.TechDescription) ).."\n",
                                [3] = "\n<details>\n<summary>"..LOC('These build categories allow it to build the following mod units:').."\n\n".."</summary>\n\n",
                            } or {
                                [0] = string.format(LOC('This build category allows it to build the unit %s.'), pageLink(unitbp.ID, unitbp.TechDescription) ).."\n",
                                [1] = "\n<details>\n<summary>"..LOC('This build category allows it to build the following units:').."\n\n".."</summary>\n\n",
                                [2] = string.format(LOC('These build categories allow it to build the unit %s.'), pageLink(unitbp.ID, unitbp.TechDescription) ).."\n",
                                [3] = "\n<details>\n<summary>"..LOC('These build categories allow it to build the following units:').."\n\n".."</summary>\n\n",
                            }
                            text = text..bitcheck[Binary2bit(#TempBuildableCategory ~= 1, NumBuildable ~= 1)]
                        end

                        if NumBuildable > 1 then
                            text = text..TechTable(BuildableUnits, 8).."\n</details>\n"
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

                local EnhNames = {}
                local GoodEnhancements = {}
                local NumEnhs = 0
                local Slots = {}

                for key, enh in pairs(bp.Enhancements) do
                    if key ~= 'Slots' and enh.BuildTime and string.sub(key, -6) ~= 'Remove' then

                        GoodEnhancements[key] = enh
                        NumEnhs = NumEnhs+1
                        Slots[enh.Slot] = true

                        if not enh.Prerequisite then
                            table.insert(EnhNames, key)
                        end
                    end
                end
                table.sort(EnhNames)

                local SortedSlots = {}
                for slot, slotname in pairs(Slots) do
                    table.insert(SortedSlots, slot)
                end
                table.sort(SortedSlots)

                local NumSortKeyed = 0

                for i, name in pairs(EnhNames) do
                    GoodEnhancements[name].SortKey = i*10
                    NumSortKeyed = NumSortKeyed+1
                end

                -- Definitely could do this with less loops, but who's counting.
                while NumSortKeyed < NumEnhs do
                    for key, enh in pairs(GoodEnhancements) do
                        if not enh.SortKey and enh.Prerequisite and GoodEnhancements[enh.Prerequisite].SortKey then
                            enh.SortKey = 0.1 + GoodEnhancements[enh.Prerequisite].SortKey
                            NumSortKeyed = NumSortKeyed+1
                        end
                    end
                end

                local SortedEnhancements = {}
                for key, enh in pairs(GoodEnhancements) do
                    SortedEnhancements[enh.Slot] = SortedEnhancements[enh.Slot] or {}
                    table.insert(SortedEnhancements[enh.Slot], {key, enh})
                    table.sort(SortedEnhancements[enh.Slot], function(a, b)
                        return a[2].SortKey < b[2].SortKey
                    end)
                end

                local text = ''
                for islot, slot in ipairs(SortedSlots) do
                    if #SortedSlots > 1 then
                        text = text..MDHead('<LOC wiki_enhancements_slot_'..slot..'>'..slot, 4)
                    end

                    for ienh, enhD in ipairs(SortedEnhancements[slot]) do
                        local key = enhD[1]
                        local enh = enhD[2]
                        text = text..tostring(Infobox{
                            Style = 'detail-left',
                            Header = {enh.Name and LOC(enh.Name) or 'error:name'},
                            Data = {
                                { 'Description:', (LOC(Description[bp.id..'-'..string.lower(enh.Icon or 'error:icon')]) or 'error:description') },
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
                    local numDockSlots = bp.Transport.DockingSlots
                    local totalAttachBones = 0
                    local numGroupsClassLimited = 0
                    local numGroupsBoneLimited = 0
                    local numGroups = 0
                    local usedClasses = {}
                    for i, datum in ipairs(data) do
                        if not datum.Class then numSmallBones = datum.Count end
                        local LongClass = 'Class'..(datum.Class or 1)..'AttachSize'

                        if datum.Class and bp.Transport[LongClass] then
                            datum.Limit = (numDockSlots or numSmallBones)/bp.Transport[LongClass]
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
                        if (numDockSlots and numDockSlots > 0) then
                        --or (bp.Transport.StorageSlots and bp.Transport.StorageSlots > 0) then
                            text = text..numDockSlots..' docking slot'..pluralS(numDockSlots)..' consisting of '
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
                            text = text.."Using an attach point costs a number of docking slots. Specifically 1 for small"
                            for i, datum in ipairs(usedClasses) do
                                text = text..', '
                                if i == #usedClasses then text = text..'and ' end
                                text = text..bp.Transport[datum.Class]..' for '..datum.Name
                            end
                            text = text..'. '
                        end

                        if numGroupsClassLimited > 0 then
                            if numGroupsClassLimited == 1 then
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit < datum.Count then
                                        text = text..'Due to these costs not all '..datum.Name..' attach points can be used concurrently; at most '..math.floor(datum.Limit)..' of them could be used at a given time, and the physical layout of them may reduce that number further.'
                                        break
                                    end
                                end
                            else--if numGroupsClassLimited > 1 then
                                text = text..'Due to these costs at most '
                                local done = 0
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit < datum.Count then
                                        done = done + 1
                                        text = text..math.floor(datum.Limit)..' '..datum.Name

                                        if done < numGroupsClassLimited then text = text..', ' end
                                        if done + 1 == numGroupsClassLimited then text = text..'or ' end
                                    end
                                end
                                text = text..' attach points can be used concurrently, and this may be further reduced by the physical layout of said bones. '
                            end
                        end
                        if numGroupsBoneLimited > 0 then
                            if numGroupsBoneLimited == 1 then
                                for i, datum in ipairs(data) do
                                    if datum.Count > 1 and datum.Limit and datum.Limit > datum.Count then
                                        local freeSmalls = (numDockSlots or numSmallBones)-(math.floor(datum.Count)*bp.Transport['Class'..datum.Class..'AttachSize'])

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
                                        local freeSmalls = (numDockSlots or numSmallBones)-(math.floor(datum.Count)*bp.Transport['Class'..datum.Class..'AttachSize'])

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
                        text = text .. "\n"..i..'. '..bp.Veteran[lev]..' kills gives: '..(bp.Defense and bp.Defense.MaxHealth and iconText('Health', '+'..formatNumber(bp.Defense.MaxHealth / 10 * i) ) or 'error:vet defined and no defense defined' )
                        if bp.Buffs then

                            local sortedBuffs = {}
                            for buffname, buffD in pairs(bp.Buffs) do
                                if buffname ~= 'Regen' then
                                    table.insert(sortedBuffs, {buffname, buffD})
                                end
                            end
                            table.sort(sortedBuffs)
                            if bp.Buffs.Regen then
                                table.insert(sortedBuffs, 1, {'Regen', bp.Buffs.Regen})
                            end

                            for i, sortedbuff in ipairs(sortedBuffs) do
                                local buffname = sortedbuff[1]
                                local buffD = sortedbuff[2]
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
            '<LOC wiki_sect_gallery>Gallery',
            check = FileExists(OutputDirectory..'images/units/'..bp.ID..'-1.jpg'),
            Data = function(bp)
                local text = ''
                for img in galleryiter('images/units/'..bp.ID) do
                    text = text..(text ~= '' and "\n" or '')..xml:a{href=img}(xml:img{src=img, width='128px'})
                end
                return text
            end,
        },
        {
            '<LOC wiki_sect_videos>Videos',
            check = UnitData[bp.ID].Videos and #UnitData[bp.ID].Videos > 0,
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
        {
            '<LOC wiki_sect_trivia>Trivia',
            check = UnitData[bp.ID].Trivia,
            Data = function(bp)
                if type(UnitData[bp.ID].Trivia) == 'table' then
                    local text = ''
                    for i, v in ipairs(UnitData[bp.ID].Trivia) do
                        text = text.."\n* "..v
                    end
                    return text
                else
                    return UnitData[bp.ID].Trivia
                end
            end,
        },
    }, {

        __tostring = function(self)
            local bodytext = ''
            for i, section in ipairs(self) do
                local prefix = GetSectionExtraData(bp.ID, noLOC(section[1])..'Prefix')
                local suffix = GetSectionExtraData(bp.ID, noLOC(section[1])..'Suffix')
                local flag = GetSectionExtraData(bp.ID, noLOC(section[1]))
                local overwrite = type(flag) == 'string' and flag
                if section.check or flag then
                    bodytext = bodytext
                    ..MDHead(section[1])
                    ..(prefix or '')
                    ..(overwrite or (section.check and section.Data(bp)) or '').."\n"
                    ..(suffix or '')
                end
            end
            return bodytext
        end,

    })
end

--------------------------------------------------------------------------------

function TableOfContents(BodyTextSections)
    local sections = 0

    for i, section in ipairs(BodyTextSections) do
        if section.check then
            sections = sections + 1
        end
    end

    if sections >= 3 then
        local text = ''
        local index = 1
        for i, section in ipairs(BodyTextSections) do
            if section.check then
                text = text..index..'. – '..sectionLink(LOC(section[1])).."\n"
                index = index + 1
            end
        end
        return "\n"..xml:details(xml:summary(LOC"<LOC wiki_toc_contents>Contents"),'',text).."\n"
    end
    return ''
end

function MDHead(header, hnum)
    return "\n"..string.rep('#', hnum or 3)..' '..LOC(header).."\n"
end
