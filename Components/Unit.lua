--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local all_units = all_blueprints.Unit

local function SetUnitCommonStrings(bp)
    bp.General.UnitName = LOC(bp.General.UnitName)
    bp.TechName = bp.TechIndex and
        LOC('<LOC wiki_tech_'..bp.TechIndex..'>')
    bp.TechDescription = (bp.TechIndex == 4 or not bp.TechIndex) and LOC(bp.Description) or
    (bp.TechName and bp.Description and bp.TechName..' '..LOC(bp.Description))
end

function GenerateUnitPages()
    for id, bp in pairs(all_units) do
        HashUnitCategories(bp)
        SetUnitCommonStrings(bp)
        GetMeshBones(bp)

        InsertInNavigationData(bp)
        GetBuildableCategoriesFromBp(bp)
    end
    for id, bp in pairs(all_units) do
        BlueprintBuiltBy(bp)
    end
    for id, bp in pairs(all_units) do
        if bp.ModInfo.GenerateWikiPages then
            local ModInfo = bp.ModInfo
            local BodyTextSections = UnitBodytextSectionData(bp)

            local md = io.open(OutputDirectory..stringSanitiseFilename(bp.ID)..'.md', "w"):write(
                UnitHeaderString(bp)..
                tostring(UnitInfobox(bp))..
                UnitBodytextLeadText(bp)..
                TableOfContents(BodyTextSections)..
                tostring(BodyTextSections)..
                UnitPageCategories(bp)..
                "\n"
            ):close()
        end
    end
end

function CheckUnitBlueprintSanity()
    for id, bp in pairs(all_units) do
        BlueprintSanityChecks(bp)
    end
end

function GetUnitMiscInfo()
    for id, bp in pairs(all_units) do
        MiscLogs(bp)
    end
    printMiscData()
end
