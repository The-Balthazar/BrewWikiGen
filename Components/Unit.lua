--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local all_units = {}

function getBP(id)
    return id and all_units[string.lower(id)]
end

local function UnitHeaderString(bp)
    return bp.General.UnitName and bp.TechDescription and string.format("\"%s\": %s\n----\n", bp.General.UnitName, bp.TechDescription)
    or bp.General.UnitName and string.format("\"%s\"\n----\n", bp.General.UnitName )
    or bp.TechDescription and string.format("%s\n----\n", bp.TechDescription)
    or ''
end

local function UnitInfobox(bp)
    local BPimg = 'images/units/'..bp.ID..'.jpg'
    return Infobox{
        Style = 'main-right',
        Header = {
            UnitIcon(bp.ID, {align='left', title=(bp.General.UnitName or 'The')..' unit icon'})..
            StrategicIcon(bp.StrategicIconName, {align='right'})..
            (bp.General.UnitName or xml:i'Unnamed')..xml:br()..(bp.TechDescription or xml:i'No description'),
            FileExists(OutputDirectory..BPimg) and xml:a{href=BPimg}(xml:img{width='256px', src=BPimg}) or nil
        },
        Data = GetUnitInfoboxData(bp),
    }
end

local function SetUnitCommonStrings(bp)
    bp.General.UnitName = LOC(bp.General.UnitName)
    bp.TechName = bp.TechIndex and
        LOC('<LOC wiki_tech_'..bp.TechIndex..'>')
    bp.TechDescription = (bp.TechIndex == 4 or not bp.TechIndex) and LOC(bp.Description) or (bp.TechName..' '..LOC(bp.Description))
end

function LoadModUnitBlueprints(ModInfo) -- First pass
    print(ModInfo.name)
    for id, bp in GetPairedModUnitBlueprints(ModInfo.location..(UnitBlueprintsFolder or '')) do
        assert( not all_units[id], LogEmoji('⚠️').." Found blueprints between mods with clashing ID "..id)
        bp.ModInfo = ModInfo
        bp.WikiPage = true
        all_units[id] = bp
        ModInfo.Units = (ModInfo.Units or 0)+1
    end
end

function LoadEnvUnitBlueprints(GeneratorDir)
    print("Loading environmental units")
    for id, bp in GetPairedModUnitBlueprints(GeneratorDir..'Environment') do
        if not all_units[id] then
            all_units[id] = bp
            bp.ModInfo = EnvironmentData.GenerateWikiPages and EnvironmentData
            if bp.ModInfo then
                bp.ModInfo.ModIndex = 0
                bp.ModInfo.Units = (bp.ModInfo.Units or 0)+1
            end
            bp.WikiPage = EnvironmentData.GenerateWikiPages
        end
    end
end

function CheckUnitBlueprintSanity()
    for id, bp in pairs(all_units) do
        BlueprintSanityChecks(bp)
    end
end

function CleanupBlueprintsFiles()
    for id, bp in pairs(all_units) do
        CleanupUnitBlueprintFile(bp)
    end
end

function GenerateUnitPages() -- Second pass
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
        if bp.WikiPage then
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

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--

function LoadModSystemBlueprintsFile(modDir)
    local SystemBlueprints = GetSandboxedLuaFile(modDir..'hook/lua/system/Blueprints.lua', "MohoLua")

    if SystemBlueprints and SystemBlueprints.WikiBlueprints then
        SystemBlueprints.WikiBlueprints({Unit=all_units})
    end
end
