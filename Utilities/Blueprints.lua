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
local function shortID(file)
    return string.match(file, "([^/.]+)_[Uu][Nn][Ii][Tt]%.[Bb][Pp]$") or string.match(file, "([^/.]+)%.[Bb][Pp]$")
end

local function longID(file, modinfo)
    local key = string.sub(file:lower(), modinfo.location:len())
    if (modinfo.ModIndex or 0) == 0 then
        return key
    else
        return string.match(file:lower(), '(/mods/.*)')
        or ('/mods'..string.match(modinfo.location:lower(), '(/[^/.]+)/$')
        ..key)
    end
end

local function bpTypeIs(bp, name) return getmetatable(bp).__name == name end

local function isValidBlueprint(bp)
    return bpTypeIs(bp,'Unit') and bp.Display and bp.Categories and bp.Defense and bp.Physics and bp.General
    or bpTypeIs(bp,'Projectile')
end

local function isExcludedId(id)
    if not BlueprintIdExclusions then return end
    for i, v in ipairs(BlueprintIdExclusions) do if v:lower() == id:lower() then return true end end
end

local function fileCaseID(id) return id == id:lower() and id:upper() or id end

function projShortId(id) return id:match('([^/.]+)_[Pp][Rr][Oo][Jj]%.[Bb][Pp]') or id:match('([^/.]+)%.[Bb][Pp]') end

function projSectionId(id) return projShortId(id):gsub('_',' '):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%u%l+)', '%1 %2'):gsub('(%S)(%d+)', '%1 %2') end

--[[ ---------------------------------------------------------------------- ]]--
--[[ Blueprint loading                                                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local function RegisterBlueprintsFromFile(dir, file, modinfo)
    local filedir = dir..file
    local bps = GetSanitisedLuaFile(filedir, 'Blueprint').Blueprints
    for i, bp in ipairs(bps) do
        local id = bp.BlueprintId or shortID(file)
        bp.Source = filedir
        bp.SourceFolder = dir
        bp.SourceFileBlueprintCount = #bps
        bp.ModInfo = modinfo
        if not bp.Merge and isValidBlueprint(bp) and not isExcludedId(id) then
            if bpTypeIs(bp,'Unit') then
                bp.id = id:lower()
                bp.ID = fileCaseID(id)
                assert(not all_units[bp.id], LogEmoji'⚠️'.." Found blueprints between mods with clashing ID "..id)
                all_units[bp.id] = bp
                modinfo.Units = (modinfo.Units or 0)+1
            elseif bpTypeIs(bp,'Projectile') then
                bp.id = longID(filedir, modinfo)
                bp.ID = projSectionId(file)
                all_projectiles[bp.id] = bp
                modinfo.Projectiles = (modinfo.Projectiles or 0)+1
            end
            if bp.id then
            end
        elseif getmetatable(bp).__name == 'Unit' or getmetatable(bp).__name == 'Projectile' then
            TotalIgnoredBlueprints = TotalIgnoredBlueprints + 1
            if Logging.ExcludedBlueprints then
                print(LogEmoji'⚠️'.." Excluding "..id,
                    (bp.Merge and "Merge") or
                    (not isValidBlueprint(bp) and "Invalid bp" ) or ""
                )
            end
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
    print('    Loaded '..(modinfo.Units or 0)..' units and '..(modinfo.Projectiles or 0)..' projectiles from '..#BlueprintPathsArray..' file'..pluralS(#BlueprintPathsArray)..'. ' )
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