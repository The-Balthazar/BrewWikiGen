--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
OutputDirectory = nil

function GeneratorMain(Output)
    OutputDirectory = Output

    local WikiGeneratorDirectory = (debug.getinfo(1, 'S').short_src):match('.*/')

    local function safecall(...)
        local pass, msg = pcall(...)
        if not pass then print(msg) end
    end

    print("Starting BrewWikiGen")

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Load generator                                                     ]]--
    --[[ ------------------------------------------------------------------ ]]--
    for i, file in ipairs{
        'Environment/Localization.lua',
        'Environment/Game.lua',
        'Utilities/Blueprint.lua',
        'Utilities/Builders.lua',
        'Utilities/File.lua',
        'Utilities/Mesh.lua',
        'Utilities/Sanity.lua',
        'Utilities/String.lua',
        'Utilities/Table.lua',
        'Components/Bodytext.lua',
        'Components/Categories.lua',
        'Components/Infobox.lua',
        'Components/Navigation.lua',
        'Components/Unit.lua',
        'Components/Weapon.lua',
    } do
        safecall(dofile, WikiGeneratorDirectory..file)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Load data                                                          ]]--
    --[[ ------------------------------------------------------------------ ]]--
    -- Wiki data
    safecall(SetWikiLocalization, WikiGeneratorDirectory, WikiOptions.Language)
    if EnvironmentData.ExtraData  then safecall(dofile,           EnvironmentData.ExtraData) end

    -- Env data
    if EnvironmentData.LOC        then safecall(LoadLocalization, EnvironmentData.LOC) end
    if EnvironmentData.Lua        then safecall(LoadHelpStrings,  EnvironmentData.Lua) end
    if EnvironmentData.Blueprints then safecall(LoadEnvUnitBlueprints, WikiGeneratorDirectory) end

    -- Mod data
    for i, dir in ipairs(ModDirectories) do
        safecall(LoadModLocalization, dir) -- Load all localisation first.
        safecall(LoadModHelpStrings, dir)
        safecall(LoadModUnitBlueprints, dir, i)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Pre-compute data                                                   ]]--
    --[[ ------------------------------------------------------------------ ]]--
    for i, dir in ipairs(ModDirectories) do
        safecall(LoadModSystemBlueprintsFile, dir)
    end

    --[[ ------------------------------------------------------------------ ]]--
    --[[ Generate wiki                                                      ]]--
    --[[ ------------------------------------------------------------------ ]]--
    if WikiOptions.GenerateUnitPages     then safecall(GenerateUnitPages) end
    if WikiOptions.GenerateSidebar       then safecall(GenerateSidebar) end
    if WikiOptions.GenerateModPages      then safecall(GenerateModPages) end
    if WikiOptions.GenerateCategoryPages then safecall(GenerateCategoryPages) end
    if WikiOptions.GenerateHomePage      then safecall(GenerateHomePage) end

    safecall(printTotalBlueprintValues)
end
