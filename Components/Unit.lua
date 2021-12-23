--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local function UnitHeaderString(bp)
    return bp.General.UnitName and bp.unitTdesc and string.format("\"%s\": %s\n----\n", LOC(bp.General.UnitName), bp.unitTdesc)
    or bp.General.UnitName and string.format("\"%s\"\n----\n", LOC(bp.General.UnitName) )
    or bp.unitTdesc and string.format("%s\n----\n", bp.unitTdesc)
    or ''
end

local function UnitInfobox(ModInfo, bp)
    return Infobox{
        Style = 'main-right',
        Header = {string.format(
            '<img align="left" title="%s unit icon" src="%s_icon.png" />%s<br />%s',
            (LOC(bp.General.UnitName) or 'The'),
            unitIconRepo..bp.ID,
            (LOC(bp.General.UnitName) or '<i>Unnamed</i>'),
            (bp.unitTdesc or [[<i>No description</i>]])
        )},
        Data = GetUnitInfoboxData(ModInfo, bp),
    }
end

local function UnitConciseInfo(bp)
    return {
        bpid = bp.ID,
        name = LOC(bp.General.UnitName),
        desc = bp.unitTdesc,
        tech = bp.unitTIndex,
        faction = bp.General and bp.General.FactionName,
    }
end

function GenerateModUnitPages(ModDirectory, ModIndex)

    local ModInfo = GetModInfo(ModDirectory)
    print(ModInfo.name)

    for id, bp in GetPairedModUnitBlueprints(ModDirectory) do

        local BodyTextSections = UnitBodytextSectionData(ModInfo, bp)
        local UnitInfo = UnitConciseInfo(bp)

        local md = io.open(OutputDirectory..stringSanitiseFilename(bp.ID)..'.md', "w"):write(
            UnitHeaderString(bp)..
            tostring(UnitInfobox(ModInfo, bp))..
            UnitBodytextLeadText(ModInfo, bp)..
            TableOfContents(BodyTextSections)..
            tostring(BodyTextSections)..
            UnitPageCategories(ModInfo, UnitInfo, bp.CategoriesHash)..
            "\n"
        ):close()

        InsertInNavigationData(ModIndex, ModInfo, UnitInfo)
    end
end
