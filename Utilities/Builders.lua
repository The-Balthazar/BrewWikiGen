--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
--[[
-- Once pupulated, contents looks like:
BuildableCategories = {
    ['BUILTBYTIER3ENGINEER ENERGYSTORAGE UEF'] = {
        Builders = {
            seb1311 = [bp],
        },
        Buildable = {
            seb1205 = [bp],
        }
    }
}
]]
local BuildableCategories = {}

function GetBuildableCategoriesFromBp(bp)
    if not tableSafe(bp.Economy,'BuildableCategory') then return end

    for i, buildcat in ipairs(bp.Economy.BuildableCategory) do
        if not BuildableCategories[buildcat] then
            BuildableCategories[buildcat] = {
                Builders = {},
                Buildable = {},
            }
        end
        BuildableCategories[buildcat].Builders[bp.id] = bp
    end
end

local function HashHasAllCatsInString(hash, catstring)
    for cat in string.gmatch(catstring, "%w+") do
        if not hash[cat] then
            return
        end
    end
    return true
end

function BlueprintBuiltBy(bp)
    for buildcat, group in pairs(BuildableCategories) do
        if HashHasAllCatsInString(bp.CategoriesHash, buildcat) then
            BuildableCategories[buildcat].Buildable[bp.id] = bp
            if not bp.BuiltByCategories then bp.BuiltByCategories = {} end
            bp.BuiltByCategories[buildcat] = true
        end
    end
end

function GetBuildableUnits(buildcats)
    local units = {}
    for i, buildcat in ipairs(buildcats) do
        tableMergeCopy(units, BuildableCategories[buildcat].Buildable)
    end
    return units
end

function GetBuilderUnits(cat)
    return BuildableCategories[cat].Builders
end
