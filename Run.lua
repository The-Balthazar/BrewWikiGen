--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local OutputDirectory = "C:/BrewLAN.wiki/"
local WikiGeneratorDirectory = "C:/BrewWikiGen/Main.lua"

EnvironmentData = {
    Blueprints = true, --Search env for blueprints
    GenerateWikiPages = false, --Generate pages for env blueprints
    
    Factions = {
        {'NOMADS', 'Nomads'},
        {'ARM', 'Arm'},
        {'CORE', 'Core'},
    },

    Lua = 'C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata/',
    LOC = 'C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata/',
    ExtraData = 'C:/BrewLAN/mods/BrewLAN/documentation/Wiki Data.lua',
    -- Psuedo mod-info for env.
    name = 'Forged Alliance',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
}

WikiOptions = {
    Language = 'US', -- These are not ISO_639-1. As an Englishman I am offended.

    GenerateHomePage = true,
    GenerateSidebar = true,
    GenerateModPages = true,
    GenerateUnitPages = true,
    GenerateCategoryPages = true,

    -- Unit page options
    IncludeStrategicIcon = true,
    AbilityDescriptions = true,
    BalanceNote = '<LOC wiki_balance_stats_steam>Displayed stats are from when launched on the steam/retail version of the game.',
    ConstructionNote = '<LOC wiki_builders_note_steam>Build times from the Steam/retail version of the game:',
    BuildListSaysModUnits = true,
}

CleanupOptions = {
    CleanUnitBpFiles = true,

    CleanUnitBpGeneral = true,
    CleanUnitBpDisplay = true,
    CleanUnitBpInterface = true,
    CleanUnitBpUseOOBTestZoom = true,

    CleanUnitBpThreat = true,
}

ModDirectories = { -- In order
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
    'uea0001', -- UEF ACU drone
    'uea0003', -- UEF ACU drone
}

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

    LocalisationLoaded = false,
    HelpStringsLoaded  = false,
    SCMLoadIssues      = false,
    SandboxedFileLogs  = false,

    ExcludedBlueprints = false,
    BlueprintTotals    = true,

    ChangeDiscarded    = true,
    NewFileWrites      = true,
    FileAppendWrites   = true,
    FileUpdateWrites   = false,

    ThreatCalculationWarnings = false,
}
Sanity = {
    BlueprintChecks         = false,
    BlueprintPedanticChecks = false,
    BlueprintStrategicIconChecks = false,
}

dofile(WikiGeneratorDirectory)
GeneratorMain(OutputDirectory)

