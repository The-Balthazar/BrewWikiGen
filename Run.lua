--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local OutputDirectory = "C:/BrewLAN.wiki/"
local WikiGeneratorDirectory = "C:/BrewWikiGen/"

EnvironmentData = {
    name = 'Forged Alliance',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
    location = 'C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata/',

    GenerateWikiPages = false, --Generate pages for env blueprints
    RebuildBlueprints = false, --Rebuild env blueprints
    RunSanityChecks = false,   --Sanity check env bps

    base64 = {
        UnitIcons = false,
    },

    Lua = 'C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata/',
    LOC = 'C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata/',
    ExtraData = 'C:/BrewLAN/mods/BrewLAN/documentation/Wiki Data.lua',

    PreModBlueprints = {},
    PostModBlueprints = {},
}

WikiOptions = {
    Language = 'US', -- These are not ISO_639-1. As an Englishman I am offended.

    GenerateHomePage = true,
    GenerateSidebar = true,
    GenerateModPages = true,
    GenerateUnitPages = true,
    GenerateProjectilesPage = true,
    GenerateCategoryPages = true,

    -- Unit page options
    IncludeStrategicIcon = true,
    AbilityDescriptions = true,
    BalanceNote = '<LOC wiki_balance_stats_steam>Displayed stats are from when launched on the steam/retail version of the game.',
    ConstructionNote = '<LOC wiki_builders_note_steam>Build times from the Steam/retail version of the game:',
    BuildListSaysModUnits = true,

    OnlineRepoUnitPageBlueprintLink = 'https://github.com/The-Balthazar/BrewLAN/tree/master/',
    LocalRepuUnitPageBlueprintLink = 'C:/BrewLAN/',
}

RebuildBlueprintOptions = {
    RebuildBpFiles = true,
    RemoveUnusedValues = true,
    CleanupBuildOnLayerCaps = true,
    CleanupGeneralBackgroundIcon = true,
    CleanupWreckageLayers = true,
    CleanupCommandCaps = true,
    CleanupIntelOverlayCategories = true,
    RemoveMilitaryOverlayCategories = true,
    RemoveProductCategories = true,
    RecalculateThreat = true,
}

CleanupOptions = {
    CleanUnitBpFiles = false,
    CleanUnitBpGeneral = false,
    CleanUnitBpDisplay = false,
    CleanUnitBpInterface = false,
    CleanUnitBpUseOOBTestZoom = false,
    CleanUnitBpThreat = false,
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

BlueprintExclusions = {
    '/z[^/]*_unit%.bp', --bp files that start with z
    '/op[ec][^/]*_unit%.bp', --bp files like OPE2001
    '/[ux][arse]c[^/]*_unit%.bp', --Exclude civilian units.
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

Logging = { -- Functional logs
    LogEmojiSupported  = false,

    LocalisationLoaded = false,
    HelpStringsLoaded  = false,
    BuffsLoaded        = false,
    SCMLoadIssues      = false,
    SandboxedFileLogs  = {
        Debug = false, -- SPEW
        Log   = true, -- LOG, _ALERT, print
        Warn  = true, -- WARN
    },

    ExcludedBlueprints = false,
    BlueprintTotals    = true,
    MissingUnitImage   = true,

    ChangeDiscarded    = true,
    NewFileWrites      = true,
    FileAppendWrites   = true,
    FileUpdateWrites   = false,
    FileAssetCopies    = true,

    ThreatCalculationWarnings = false,
}
Sanity = { -- Advice logs
    BlueprintChecks         = false,
    BlueprintPedanticChecks = false,
    BlueprintStrategicIconChecks = false,
}
Info = { -- Misc data logs
    UnitLODCounts = false,
    ProjectileBlueprintCounts = false,
}

dofile(WikiGeneratorDirectory.."Main.lua")
GeneratorMain(OutputDirectory)

