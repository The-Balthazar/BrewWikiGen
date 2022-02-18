--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local all_units = {}
local all_projectiles = {}
local all_blueprints = {
    Unit = all_units,
    Projectile = all_projectiles,
}

function getBP(id) return id and (all_units[id] or all_units[id:lower()]) end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint metadata                                                     ]]--
--[[ ---------------------------------------------------------------------- ]]--
local TotalBlueprintFiles = 0
local TotalValidBlueprints = 0
local TotalIgnoredBlueprints = 0

function printTotalBlueprintValues()
    if Logging.BlueprintTotals then
        print(TotalBlueprintFiles..' opened .bp file'..pluralS(TotalBlueprintFiles))
        print(TotalValidBlueprints..' processed blueprint'..pluralS(TotalValidBlueprints))
        print(TotalIgnoredBlueprints..' ignored blueprint'..pluralS(TotalIgnoredBlueprints))
    end
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint file utilities                                               ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function MatchesExclusion(name, exclusions)
    if not exclusions then return end
    for i, v in ipairs(exclusions) do
        if string.find(name,v) then return true end
    end
end
local function MatchesFileExclusion(name) return MatchesExclusion(name, BlueprintFileExclusions) end
local function MatchesFolderExclusion(name) return MatchesExclusion(name, BlueprintFolderExclusions) end
local function IsFileOrSystemFolder(name) return name:find'%.' end
local function IsGoodBlueprintFile(name) return name:lower():find'_unit.bp$' end

local function GetModBlueprintPaths(dir)
    local BlueprintPathsArray = {}
    do
        local dirsearch; dirsearch = function(folder, p)
            local file <close> = io.popen('dir "'..folder..'" /b '..(p or ''))
            for line in file:lines() do
                if line:find'.lnk$' then
                    local lnk = GetDirFromShellLnk(folder..'/'..line)
                    print("    Loading: ", lnk)
                    dirsearch(lnk)
                end

                if IsGoodBlueprintFile(line) and not MatchesFileExclusion(line) then
                    table.insert(BlueprintPathsArray, {folder, line})
                elseif not IsFileOrSystemFolder(line) and not MatchesFolderExclusion(line) then
                    dirsearch(folder..'/'..line)
                end
            end
        end

        dirsearch(dir, '/ad')
    end
    collectgarbage() -- Potentially a lot of garbage here
    return BlueprintPathsArray
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint data cleanup and validation                                  ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function bpTypeIs(bp, name) return getmetatable(bp).__name == name end

local function isValidBlueprint(bp)
    return bpTypeIs(bp,'Unit') and bp.Display and bp.Categories and bp.Defense and bp.Physics and bp.General
    or bpTypeIs(bp,'Projectile')
end

local function isExcludedId(id)
    if not BlueprintIdExclusions then return end
    for i, v in ipairs(BlueprintIdExclusions) do if v:lower() == id:lower() then return true end end
end

local function shortID(file)
    return string.match(file, "(.*)_[Uu][Nn][Ii][Tt].[Bb][Pp]$") or string.match(file, "(.*).[Bb][Pp]$")
end

local function fileCaseID(id)
    return id == id:lower() and id:upper() or id
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function RegisterBlueprintsFromFile(dir, file, modinfo)
    local filedir = dir..'/'..file
    local bps = GetSanitisedLuaFile(filedir, 'Blueprint').Blueprints
    for i, bp in ipairs(bps) do
        local id = bp.BlueprintId or shortID(file)
        bp.Source = filedir
        bp.SourceFolder = dir
        bp.SourceFileBlueprintCount = #bps
        if not bp.Merge and isValidBlueprint(bp) and not isExcludedId(id) then
            if bpTypeIs(bp,'Unit') then
                bp.id = id:lower()
                bp.ID = fileCaseID(id)
                assert(not all_units[bp.id], LogEmoji('⚠️').." Found blueprints between mods with clashing ID "..id)
                all_units[bp.id] = bp
                modinfo.Units = (modinfo.Units or 0)+1
                bp.ModInfo = modinfo
                bp.WikiPage = modinfo.GenerateWikiPages
            else

            end
        else
            TotalIgnoredBlueprints = TotalIgnoredBlueprints + 1
            if Logging.ExcludedBlueprints then
                print(LogEmoji('⚠️').." Excluding "..id,
                    (bp.Merge and "Merge") or
                    (not isValidBlueprint(bp) and "Invalid bp" ) or ""
                )
            end
        end
    end
end

function LoadBlueprints(modinfo)
    print(modinfo.name)
    local BlueprintPathsArray = GetModBlueprintPaths(modinfo.location..(modinfo.ModIndex~=0 and UnitBlueprintsFolder or ''))

    for i, dirData in ipairs(BlueprintPathsArray) do
        RegisterBlueprintsFromFile(dirData[1], dirData[2], modinfo)
    end

    --[[ Logging ]]--
    print('    Loaded '..(modinfo.Units or 0)..' blueprint'..pluralS(modinfo.Units)
    ..' from '..#BlueprintPathsArray..' file'..pluralS(#BlueprintPathsArray)..'. ' )
    TotalBlueprintFiles = TotalBlueprintFiles + #BlueprintPathsArray
    TotalValidBlueprints = TotalValidBlueprints + (modinfo.Units or 0)
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

function CleanupBlueprintsFiles()
    for id, bp in pairs(all_units) do
        CleanupUnitBlueprintFile(bp)
    end
end

local function SetUnitCommonStrings(bp)
    bp.General.UnitName = LOC(bp.General.UnitName)
    bp.TechName = bp.TechIndex and
        LOC('<LOC wiki_tech_'..bp.TechIndex..'>')
    bp.TechDescription = (bp.TechIndex == 4 or not bp.TechIndex) and LOC(bp.Description) or (bp.TechName..' '..LOC(bp.Description))
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

    if SystemBlueprints.WikiBlueprints then
        SystemBlueprints.WikiBlueprints({Unit=all_units})
    end
end
