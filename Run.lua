--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local Language = 'US'-- These are not ISO_639-1. As an Englishman I am offended.
--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--

OutputDirectory = "C:/BrewLAN.wiki/"

local WikiGeneratorDirectory = "C:/BrewWikiGen/"

EnvironmentData = {
    Blueprints = true, --Search env for blueprints
    GenerateWikiPages = false, --Generate pages for env blueprints
    --Extra information
    ConstructionNote = '<LOC wiki_builders_note_steam>Build times from the Steam/retail version of the game:',
    ExtraData = 'C:/BrewLAN/mods/BrewLAN/documentation/Wiki Data.lua',
    --Psuedo mod-info for env.
    name = 'Forged Alliance',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
}

local ModDirectories = { -- In order
    'C:/BrewLAN/mods/BrewLAN/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewAir/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewIntel/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewMonsters/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewResearch/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewShields/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewTeaParty/',
    'C:/BrewLAN/mods/BrewLAN_Units/BrewTurrets/',
}

-- Optional, reduces scope of file search, which is the slowest part.
UnitBlueprintsFolder = 'units'

BlueprintFolderExclusions = { -- Excludes folders that match any of these (regex)
    '^[zZ]', --Starts with z or Z
    '^OP[EC]', --Exclude operation units, like OPE2001
    '^[UX][ARSE]C', --Exclude civilian units.
}

BlueprintFileExclusions = { -- Excludes _unit.bp files that match any of these (regex)
    '^[zZ]',
}

BlueprintIdExclusions = { -- Excludes blueprints with any of these IDs (case insensitive)
    'seb0105',
    'srl0000',
    'srl0001',
    'srl0002',
    'srl0003',
    'srl0004',
    'srl0005',
    'srl0006',
    'ssb2380',
    'ura0001', --Cybran build effect
}

-- Web path for img src. Could be relative, but would break on edit previews.
ImageRepo = "/The-Balthazar/BrewLAN/wiki/images/"
IconRepo = "/The-Balthazar/BrewLAN/wiki/icons/"
unitIconRepo = IconRepo.."units/" --[unit blueprintID]_icon.png, case sensitive.

FooterCategories = { -- In order
    'UEF',          'AEON',         'CYBRAN',       'SERAPHIM',
    'TECH1',        'TECH2',        'TECH3',        'EXPERIMENTAL',
    'MOBILE',
    'ANTIAIR',      'ANTINAVY',     'DIRECTFIRE',
    'AIR',          'LAND',         'NAVAL',
    'HOVER',
    'ECONOMIC',
    'SHIELD',       'PERSONALSHIELD',
    'BOMBER',       'TORPEDOBOMBER',
    'MINE',
    'COMMAND',      'SUBCOMMANDER', 'ENGINEER',     'FIELDENGINEER',
    'TRANSPORTATION',               'AIRSTAGINGPLATFORM',
    'SILO',
    'FACTORY',
    'ARTILLERY',
    'STRUCTURE',
}

Logging = {
    LogEmojiSupported  = false,
    ModHooksLoaded     = false,
    LuaFileLoadIssues  = true,
    SCMLoadIssues      = false,
    ExcludedBlueprints = false,
    BlueprintTotals    = true,
    SandboxedFileLogs  = true,
}
Sanity = {
    BlueprintChecks         = false,
    BlueprintPedanticChecks = false,
}

--[[ ---------------------------------------------------------------------- ]]--
--[[ Run                                                                    ]]--
--[[ ---------------------------------------------------------------------- ]]--

local function safecall(...)
    local pass, msg = pcall(...)
    if not pass then print(msg) end
end

print("Starting BrewWikiGen")

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
if EnvironmentData.ExtraData then
    safecall(dofile, EnvironmentData.ExtraData)
end
safecall(SetWikiLocalization, WikiGeneratorDirectory, Language)

for i, dir in ipairs(ModDirectories) do
    safecall(LoadModLocalization, dir) -- Load all localisation first.
    safecall(LoadModHooks, dir)
    safecall(LoadModUnitBlueprints, dir, i)
end
if EnvironmentData.Blueprints then
    safecall(LoadEnvUnitBlueprints, WikiGeneratorDirectory)
end
for i, dir in ipairs(ModDirectories) do
    safecall(LoadModSystemBlueprintsFile, dir)
end

safecall(GenerateUnitPages)
safecall(GenerateSidebar)
safecall(GenerateModPages)
safecall(GenerateCategoryPages)
safecall(GenerateHomePage)

safecall(printTotalBlueprintValues)

