--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint metadata                                                     ]]--
--[[ ---------------------------------------------------------------------- ]]--
local TotalBlueprintFiles = 0
local TotalValidBlueprints = 0
local TotalIgnoredBlueprints = 0

function printTotalBlueprintValues()
    if _G.Logging and _G.Logging.BlueprintTotals then
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
local function MatchesFileExclusion(name) return MatchesExclusion(name, _G.BlueprintFileExclusions) end
local function MatchesFolderExclusion(name) return MatchesExclusion(name, _G.BlueprintFolderExclusions) end
local function IsFileOrSystemFolder(name) return string.find(name, '%.') end
local function IsGoodBlueprintFile(name) return string.lower(string.sub(name,-8,-1)) == '_unit.bp' end

local function GetModBlueprintPaths(dir)
    local BlueprintPathsArray = {}

    local dirsearch; dirsearch = function(folder, p)
        local file <close> = io.popen('dir "'..folder..'" /b '..(p or ''))
        for line in file:lines() do
            if IsGoodBlueprintFile(line) and not MatchesFileExclusion(line) then
                table.insert(BlueprintPathsArray, {folder, line})
            elseif not IsFileOrSystemFolder(line) and not MatchesFolderExclusion(line) then
                dirsearch(folder..'/'..line)
            end
        end
    end

    dirsearch(dir..(_G.UnitBlueprintsFolder or ''), '/ad')

    return BlueprintPathsArray
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint data cleanup and validation                                  ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function BlueprintSetShortId(bp, file)
    local id = bp.BlueprintId or string.gsub(file, "_unit.bp", "")
    bp.id = string.lower(id) -- ID used by the game internally
    bp.ID = id == bp.id and string.upper(id) or id -- ID used by filenames
end

local MenuSortCats = {
    SORTCONSTRUCTION = 'SORTCONSTRUCTION',
    SORTECONOMY = 'SORTECONOMY',
    SORTDEFENSE = 'SORTDEFENSE',
    SORTSTRATEGIC = 'SORTSTRATEGIC',
    SORTINTEL = 'SORTINTEL',
}

local function BlueprintHashCategories(bp)
    bp.CategoriesHash = {
        -- Implicit categories
        [bp.id] = bp.id, -- lower case ID
        ALLUNITS = 'ALLUNITS',
    }
    bp.FactionCategoryHash = {}
    if not bp.Categories then return end
    for i, cat in ipairs(bp.Categories) do
        cat = string.upper(cat)
        bp.CategoriesHash[cat] = cat

        bp.SortCategory = bp.SortCategory or MenuSortCats[cat]

        if FactionCategoryIndexes[cat] then
            bp.FactionCategoryHash[cat] = cat
            if bp.FactionCategory == nil then
                bp.FactionCategory = cat
            else
                bp.FactionCategory = false -- has multiple faction categories
            end
        end
    end
    bp.SortCategory = bp.SortCategory or 'SORTOTHER'

    if bp.FactionCategory == nil then
        bp.FactionCategory = 'OTHER'
    end
end

local function GetUnitTechAndDescStrings(bp)
    -- Tech 1-3 units don't have the tech level in their desc exclicitly,
    -- Experimental *generally* do. This unified it so we don't have to check again.
    for i = 1, 3 do
        if bp.CategoriesHash['TECH'..i] then
            return i, 'Tech '..i, bp.Description and 'Tech '..i..' '..LOC(bp.Description)
        end
    end
    if bp.CategoriesHash.EXPERIMENTAL then
        return 4, 'Experimental', LOC(bp.Description)
    end
    return nil, nil, LOC(bp.Description)
end

local function BlueprintSetUnitTechAndDescStrings(bp)
    bp.unitTIndex, bp.unitTlevel, bp.unitTdesc = GetUnitTechAndDescStrings(bp)
end

local function isValidBlueprint(bp)
    return bp.Display and bp.Categories and bp.Defense and bp.Physics and bp.General
end

local function isExcludedId(id)
    if not _G.BlueprintIdExclusions then return end
    for i, v in ipairs(BlueprintIdExclusions) do if string.lower(v) == id then return true end end
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function GetPairedBlueprintsFromFile(dir, file)
    local bpfile = io.open(dir..'/'..file, 'r')
    local bpstring = bpfile:read('a')

    bpfile:close()

    local sanitiseSteps = {
        {'#',                 '--',       },
        {'\\',                '/',        },
        {'Sound%s*{',         '{',        },
        {'%a+Blueprint%s*{', 'return {', 1},
        {'%a+Blueprint%s*{', '{',         },
        {'}%s*{',             '}, {',     },
    }

    for i, v in ipairs(sanitiseSteps) do
        bpstring = string.gsub(bpstring, v[1], v[2], v[3])
    end

    local bps = {load(bpstring)()}

    assert(bps[1], "⚠️ Failed to load "..file)

    local validbps = {}

    for i, bp in ipairs(bps) do
        bp.SourceFolder = dir
        BlueprintSetShortId(bp, file)
        if not bp.Merge and isValidBlueprint(bp) and not isExcludedId(bp.id) then
            table.insert(validbps, bp)
        else
            TotalIgnoredBlueprints = TotalIgnoredBlueprints + 1
            if Logging.ExcludedBlueprints then
                print("⚠️ Excluding "..bp.id,
                    (bp.Merge and "Merge") or
                    (not isValidBlueprint(bp) and "Invalid bp" ) or ""
                )
            end
        end
    end

    return ipairs(validbps)
end

function ProcessBlueprint(bp)
    BlueprintHashCategories(bp)
    BlueprintSetUnitTechAndDescStrings(bp)
    BlueprintMeshBones(bp)
    BlueprintSanityChecks(bp)

    InsertInNavigationData(bp)
    GetBuildableCategoriesFromBp(bp)
end

function GetPairedModUnitBlueprints(modDir)
    local BlueprintPathsArray = GetModBlueprintPaths(modDir)
    local numBlueprintsFiles = #BlueprintPathsArray
    local numValidBlueprints = 0

    collectgarbage() -- Potentially a lot of garbage at this point, so force it to be sure.

    local ModUnitBlueprints = {}

    for i, fileDir in ipairs(BlueprintPathsArray) do
        for _, bp in GetPairedBlueprintsFromFile(fileDir[1],fileDir[2]) do
            assert(not ModUnitBlueprints[bp.id], "⚠️ Found blueprints within mod with clashing ID "..bp.id)
            ModUnitBlueprints[bp.id] = bp
            numValidBlueprints = numValidBlueprints + 1
        end
    end

    TotalBlueprintFiles = TotalBlueprintFiles + numBlueprintsFiles
    TotalValidBlueprints = TotalValidBlueprints + numValidBlueprints

    print('    Loaded '..numValidBlueprints..' blueprint'..pluralS(numValidBlueprints)
    ..' from '..numBlueprintsFiles..' file'..pluralS(numBlueprintsFiles)..'. ' )

    return pairs(ModUnitBlueprints)
end
