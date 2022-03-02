--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local all_units = {}
local all_projectiles = {}
all_blueprints = {
    Unit = all_units,
    Projectile = all_projectiles,
}

merge_blueprints = {}

function getBP(id) return id and (all_units[id] or all_units[id:lower()]) end
function getProj(id) return id and (all_projectiles[id] or all_projectiles[id:lower()]) end

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
--[[ Blueprint data cleanup and validation                                  ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function shortID(file) return file:match"([^/]+)_[Uu][Nn][Ii][Tt]%.[Bb][Pp]$" or file:match"([^/]+)%.[Bb][Pp]$" end

local function longID(file, modinfo)
    local key = string.sub(file:lower(), modinfo.location:len())
    if (modinfo.ModIndex or 0) == 0 then
        return key
    else
        return string.match(file:lower(), '(/mods/.*)')
        or ('/mods'..string.match(modinfo.location:lower(), '(/[^/]+)/$')
        ..key)
    end
end

local function isValidUnitBlueprint(bp) return bp.__name=='Unit' and bp.Display and bp.Categories and bp.Defense and bp.General end

local function isExcludedId(id)
    if not BlueprintIdExclusions then return end
    for i, v in ipairs(BlueprintIdExclusions) do if v:lower() == id:lower() then return true end end
end

local function fileCaseID(id) return id == id:lower() and id:upper() or id end

function projShortId(id) return id:match('([^/]+)_[Pp][Rr][Oo][Jj]%.[Bb][Pp]') or id:match('([^/]+)%.[Bb][Pp]') end

function projSectionId(id) return projShortId(id):gsub('_',' '):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%d+)', '%1 %2') end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function LogExcludedBlueprint(id, bp)
    if getmetatable(bp).__name == 'Unit' or getmetatable(bp).__name == 'Projectile' then
        TotalIgnoredBlueprints = TotalIgnoredBlueprints + 1
        if Logging.ExcludedBlueprints then
            print(LogEmoji'⚠️'..' Excluding '..id,
                (bp.Merge and 'Merge') or
                (bp.__name=='Unit' and not isValidUnitBlueprint(bp) and 'Invalid unit bp') or ''
            )
        end
    end
end

local function RegisterBlueprintsFromFile(dir, file, modinfo)
    local filedir = dir..file
    local bps = GetSanitisedLuaFile(filedir, 'Blueprint').Blueprints
    for i, bp in ipairs(bps) do
        local id = bp.BlueprintId or shortID(file)
        local meta = getmetatable(bp)

        meta.Source = filedir
        meta.SourceFolder = dir
        meta.SourceFileBlueprintCount = #bps
        meta.ModInfo = modinfo

        bp.BlueprintId = nil
        meta.id = id:lower()
        meta.ID = fileCaseID(id)

        if isExcludedId(id) then
            LogExcludedBlueprint(id, bp)

        elseif bp.Merge and bp.__name=='Unit' then
            bp.Merge = nil
            meta.Merge = true
            merge_blueprints[bp.id] = merge_blueprints[bp.id] or {}
            table.insert(merge_blueprints[bp.id], bp)
            modinfo.UnitMerges = (modinfo.UnitMerges or 0)+1

        elseif not bp.Merge and isValidUnitBlueprint(bp) then
            printif(all_units[bp.id], LogEmoji'⚠️'..' Found non-merge clashing ID '..id..' using version from '..tostring(modinfo.name))
            all_units[bp.id] = bp
            modinfo.Units = (modinfo.Units or 0)+1

        elseif not bp.Merge and bp.__name=='Projectile' then
            meta.id = longID(filedir, modinfo)
            meta.ID = projSectionId(file)
            all_projectiles[bp.id] = bp
            modinfo.Projectiles = (modinfo.Projectiles or 0)+1

        else
            LogExcludedBlueprint(id, bp)
        end
    end
end

function LoadBlueprints(modinfo)
    print(modinfo.name)
    local BlueprintPathsArray = FindBlueprints(modinfo.location)

    for i, dirData in ipairs(BlueprintPathsArray) do
        RegisterBlueprintsFromFile(dirData[1], dirData[2], modinfo)
    end

    --[[ Logging ]]--
    print('    Loaded '..(modinfo.Units or 0)..' units, '..(modinfo.UnitMerges or 0)..' unit merges, and '..(modinfo.Projectiles or 0)..' projectiles from '..#BlueprintPathsArray..' .bp file'..pluralS(#BlueprintPathsArray)..'. ' )
    TotalBlueprintFiles = TotalBlueprintFiles + #BlueprintPathsArray
    TotalValidBlueprints = TotalValidBlueprints + (modinfo.Units or 0)
end

function CleanupBlueprintsFiles()
    for id, bp in pairs(all_units) do
        CleanupUnitBlueprintFile(bp)
    end
end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
function LoadModSystemBlueprintsFile(modDir)
    local SystemBlueprints = GetSandboxedLuaFile(modDir..'hook/lua/system/Blueprints.lua', "MohoLua")

    if SystemBlueprints.WikiBlueprints then
        SystemBlueprints.WikiBlueprints(all_blueprints)
    end
end
