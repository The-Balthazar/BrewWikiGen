--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--

WikiGeneratorDirectory = "C:/BrewWikiGen/"
OutputDirectory = "C:/BrewLAN.wiki/"

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

-- Not case senstive, matches files and folders that start with any of these.
BlueprintExclusions = {
    'z',
    'srl0000',
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
    'SHIELD',
    'BOMBER',       'TORPEDOBOMBER',
    'MINE',
    'COMMAND',      'SUBCOMMANDER', 'ENGINEER',     'FIELDENGINEER',
    'SILO',
    'FACTORY',
    'ARTILLERY',
    'STRUCTURE',
}

--[[ ---------------------------------------------------------------------- ]]--
--[[ Run                                                                    ]]--
--[[ ---------------------------------------------------------------------- ]]--

local safecall = function(...)
    local pass, msg = pcall(...)
    if not pass then print(msg) end
end

for i, file in ipairs({
    'Environment.lua',
    'Utils.lua',
    'Components/Infobox.lua',
    'Components/Bodytext.lua',
}) do
    safecall(dofile, WikiGeneratorDirectory..file)
end

safecall(dofile, ModDirectories[1]..'documentation/Wiki Data.lua')
safecall(dofile, WikiGeneratorDirectory..'Generators.lua')

for i, dir in ipairs(ModDirectories) do
    safecall(LoadModFilesMakeUnitPagesGatherData, dir, i)
end

safecall(GenerateSidebar)
safecall(GenerateModPages)
safecall(GenerateCategoryPages)
