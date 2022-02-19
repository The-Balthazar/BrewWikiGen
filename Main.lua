--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
debug.setmetatable(nil, {__index={}})

OutputDirectory = nil
WikiGeneratorDirectory = nil
__active_mods = {}

function printif(check, ...) if check then print(...) end end

function GeneratorMain(Output)
    OutputDirectory = Output
    WikiGeneratorDirectory = (debug.getinfo(1, 'S').short_src):match('.*/')

    local function safecall(...)
        local pass, msg = pcall(...)
        printif(not pass, msg)
        return pass
    end

    print("Starting BrewWikiGen")

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Load generator                                                     ]]--
    --[[ ------------------------------------------------------------------ ]]--
    for i, file in ipairs{
        'Environment/Localization.lua',
        'Environment/Game.lua',
        'Utilities/Blueprints.lua',
        'Utilities/Builders.lua',
        'Utilities/Cleanup.lua',
        'Utilities/File.lua',
        'Utilities/Infobox.lua',
        'Utilities/Mesh.lua',
        'Utilities/Sanity.lua',
        'Utilities/String.lua',
        'Utilities/Table.lua',
        "Utilities/Threat.lua",
        'Components/Categories.lua',
        'Components/Navigation.lua',
        'Components/Projectiles.lua',
        'Components/Unit.lua',
        'Components/UnitBodytext.lua',
        'Components/UnitInfobox.lua',
        'Components/Weapon.lua',
    } do
        safecall(dofile, WikiGeneratorDirectory..file)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Load data                                                          ]]--
    --[[ ------------------------------------------------------------------ ]]--
    -- Wiki data
    safecall(SetWikiLocalization, WikiGeneratorDirectory, WikiOptions.Language)
    if EnvironmentData.ExtraData then safecall(dofile,           EnvironmentData.ExtraData) end

    -- Env data
    if EnvironmentData.LOC       then safecall(LoadLocalization, EnvironmentData.LOC) end
    if EnvironmentData.Lua       then safecall(LoadHelpStrings,  EnvironmentData.Lua) end
    if EnvironmentData.location  then safecall(LoadBlueprints,   EnvironmentData) end

    for i, dir in ipairs(ModDirectories) do
        __active_mods[i] = LoadModInfo(dir, i)
    end

    -- Mod data
    for i, mod in ipairs(__active_mods) do
        safecall(LoadModLocalization, mod.location)
        safecall(LoadModHelpStrings, mod.location)
        safecall(LoadBlueprints, mod)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Pre-compute data                                                   ]]--
    --[[ ------------------------------------------------------------------ ]]--
    for i, mod in ipairs(__active_mods) do
        safecall(LoadModSystemBlueprintsFile, mod.location)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Generate wiki                                                      ]]--
    --[[ ------------------------------------------------------------------ ]]--
    if Sanity.BlueprintChecks            then safecall(CheckUnitBlueprintSanity) end
    if Info.UnitLODCounts                then safecall(GetUnitMiscInfo) end
    if CleanupOptions.CleanUnitBpFiles   then safecall(CleanupBlueprintsFiles) end
    if WikiOptions.GenerateUnitPages     then safecall(GenerateUnitPages) end
    if WikiOptions.GenerateProjectilesPage then safecall(GenerateProjectilePage) end
    if WikiOptions.GenerateSidebar       then safecall(GenerateSidebar) end
    if WikiOptions.GenerateModPages      then safecall(GenerateModPages) end
    if WikiOptions.GenerateCategoryPages then safecall(GenerateCategoryPages) end
    if WikiOptions.GenerateHomePage      then safecall(GenerateHomePage) end

    safecall(printTotalBlueprintValues)
end
