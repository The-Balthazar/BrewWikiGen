--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

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
local function MatchesFileExclusion(name) return MatchesExclusion(name, _G.BlueprintFileExclusions) end
local function MatchesFolderExclusion(name) return MatchesExclusion(name, _G.BlueprintFolderExclusions) end
local function IsFileOrSystemFolder(name) return string.find(name, '%.') end
local function IsGoodBlueprintFile(name) return string.lower(string.sub(name,-8,-1)) == '_unit.bp' end

local function GetModBlueprintPaths(dir)
    local BlueprintPathsArray = {}

    local dirsearch; dirsearch = function(folder, p)
        local file <close> = io.popen('dir "'..folder..'" /b '..(p or ''))
        for line in file:lines() do
            if string.sub(line, -4) == '.lnk' then
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

    local bps = {}

    local env = {
        Sound                    = function(t) return setmetatable(t, {__name = 'Sound'}) end,
        BeamBlueprint            = function(t) return setmetatable(t, {__name = 'BeamBlueprint'}) end,
        MeshBlueprint            = function(t) return setmetatable(t, {__name = 'MeshBlueprint'}) end,
        PropBlueprint            = function(t) return setmetatable(t, {__name = 'PropBlueprint'}) end,
        EmitterBlueprint         = function(t) return setmetatable(t, {__name = 'EmitterBlueprint'}) end,
        ProjectileBlueprint      = function(t) return setmetatable(t, {__name = 'ProjectileBlueprint'}) end,
        TrailEmitterBlueprint    = function(t) return setmetatable(t, {__name = 'TrailEmitterBlueprint'}) end,
        UnitBlueprint = function(t) table.insert(bps, setmetatable(t, {__name = 'UnitBlueprint'})) end,
    }

    local sanitiseSteps = {
        {'#',         '--'},
        {'\\[^"^\']', '/' },
    }

    for i, v in ipairs(sanitiseSteps) do
        bpstring = string.gsub(bpstring, v[1], v[2], v[3])
    end

    local chunk, msg = load(bpstring, file, 't', env)
    assert(chunk, msg)

    chunk()
    printif(not bps[1], '    No blueprints found in '..file)

    local validbps = {}

    for i, bp in ipairs(bps) do
        bp.SourceFolder = dir
        bp.Source = dir..'/'..file
        bp.SourceBlueprints = #bps
        BlueprintSetShortId(bp, file)
        if not bp.Merge and isValidBlueprint(bp) and not isExcludedId(bp.id) then
            table.insert(validbps, bp)
        else
            TotalIgnoredBlueprints = TotalIgnoredBlueprints + 1
            if Logging.ExcludedBlueprints then
                print(LogEmoji('⚠️').." Excluding "..bp.id,
                    (bp.Merge and "Merge") or
                    (not isValidBlueprint(bp) and "Invalid bp" ) or ""
                )
            end
        end
    end

    return ipairs(validbps)
end

function GetPairedModUnitBlueprints(modDir)
    local BlueprintPathsArray = GetModBlueprintPaths(modDir)
    local numBlueprintsFiles = #BlueprintPathsArray
    local numValidBlueprints = 0

    collectgarbage() -- Potentially a lot of garbage at this point, so force it to be sure.

    local ModUnitBlueprints = {}

    for i, fileDir in ipairs(BlueprintPathsArray) do
        for _, bp in GetPairedBlueprintsFromFile(fileDir[1],fileDir[2]) do
            assert(not ModUnitBlueprints[bp.id], LogEmoji('⚠️').." Found blueprints within mod with clashing ID "..bp.id)
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
