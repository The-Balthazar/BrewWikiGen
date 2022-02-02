--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

FactionIndexes = {
    UEF = 1,
    Aeon = 2,
    Cybran = 3,
    Seraphim = 4,
    Other = 5,
}

FactionsByIndex = {
    'UEF',
    'Aeon',
    'Cybran',
    'Seraphim',
    'Other',
}

FactionCategoryIndexes = {
    UEF = 1,
    AEON = 2,
    CYBRAN = 3,
    SERAPHIM = 4,
    OTHER = 5,
}

function FactionFromFactionCategory(cat) return FactionsByIndex[ FactionCategoryIndexes[cat] ] end
function FactionsFromFactionCatHash(hash)
    local array = {}
    for cat, _ in pairs(hash) do
        table.insert(array, FactionFromFactionCategory(cat))
    end
    table.sort(array)
    return array
end

LayerBits = {
    Land   = 1,
    Seabed = 2,
    Sub    = 4,
    Water  = 8,
    Air    = 16,
}

LayerHash = {
    LAYER_Land   = LOC('<LOC wiki_layer_land>Land'),
    LAYER_Seabed = LOC('<LOC wiki_layer_seabed>Seabed'),
    LAYER_Sub    = LOC('<LOC wiki_layer_sub>Sub'),
    LAYER_Water  = LOC('<LOC wiki_later_water>water'),
    LAYER_Air    = LOC('<LOC wiki_layer_air>Air'),
    --LAYER_Orbit  = LOC('<LOC wiki_layer_orbit>Orbit'),
}

LayersByIndex = {
    'LAYER_Land',
    'LAYER_Seabed',
    'LAYER_Sub',
    'LAYER_Water',
    'LAYER_Air',
    --'LAYER_Orbit',
}

-- Motion types mapped to layers they relevantly be firing from.
motionTypes = {
    RULEUMT_Air                = {Air = 16},
    RULEUMT_Amphibious         = {         Land = 1, Seabed = 2           },
    RULEUMT_AmphibiousFloating = {         Land = 1,             Water = 8},
    RULEUMT_Biped              = {         Land = 1                       },
    RULEUMT_Land               = {         Land = 1                       },
    RULEUMT_Hover              = {         Land = 1,             Water = 8},
    RULEUMT_Water              = {                               Water = 8},
    RULEUMT_SurfacingSub       = {Sub = 4,                       Water = 8},
    RULEUMT_None               = {Sub = 4, Land = 1, Seabed = 2, Water = 8},
    --RULEUMT_Special            = {'',{}}, -- Mentioned in the engine, but reports malformed if you try to use it
}

defaultOrdersTable = {
    --commandCaps = {
    RULEUCC_Move                = { helpText = "move",              bitmapId = 'move',                  preferredSlot = 1    },
    RULEUCC_Stop                = { helpText = "stop",              bitmapId = 'stop',                  preferredSlot = 4    },
    RULEUCC_Attack              = { helpText = "attack",            bitmapId = 'attack',                preferredSlot = 2    },
    RULEUCC_Guard               = { helpText = "assist",            bitmapId = 'guard',                 preferredSlot = 5    },
    RULEUCC_Patrol              = { helpText = "patrol",            bitmapId = 'patrol',                preferredSlot = 3    },
    RULEUCC_RetaliateToggle     = { helpText = "mode",              bitmapId = 'stand-ground',          preferredSlot = 6    },

    RULEUCC_Repair              = { helpText = "repair",            bitmapId = 'repair',                preferredSlot = 12   },
    RULEUCC_Capture             = { helpText = "capture",           bitmapId = 'convert',               preferredSlot = 11   },
    RULEUCC_Transport           = { helpText = "transport",         bitmapId = 'unload',                preferredSlot = 8    },
    RULEUCC_CallTransport       = { helpText = "call_transport",    bitmapId = 'load',                  preferredSlot = 9    },
    RULEUCC_Nuke                = { helpText = "fire_nuke",         bitmapId = 'launch-nuke',           preferredSlot = 9.1  },
    RULEUCC_Tactical            = { helpText = "fire_tactical",     bitmapId = 'launch-tactical',       preferredSlot = 9.2  },
    RULEUCC_Teleport            = { helpText = "teleport",          bitmapId = 'teleport',              preferredSlot = 9.3  },
    RULEUCC_Ferry               = { helpText = "ferry",             bitmapId = 'ferry',                 preferredSlot = 9.4  },
    RULEUCC_SiloBuildTactical   = { helpText = "build_tactical",    bitmapId = 'silo-build-tactical',   preferredSlot = 7    },
    RULEUCC_SiloBuildNuke       = { helpText = "build_nuke",        bitmapId = 'silo-build-nuke',       preferredSlot = 7.1  },
    RULEUCC_Sacrifice           = { helpText = "sacrifice",         bitmapId = 'sacrifice',             preferredSlot = 9.5  },
    RULEUCC_Pause               = { helpText = "pause",             bitmapId = 'pause',                 preferredSlot = 17   },
    RULEUCC_Overcharge          = { helpText = "overcharge",        bitmapId = 'overcharge',            preferredSlot = 7.2  },
    RULEUCC_Dive                = { helpText = "dive",              bitmapId = 'dive',                  preferredSlot = 10   },
    RULEUCC_Reclaim             = { helpText = "reclaim",           bitmapId = 'reclaim',               preferredSlot = 10.1 },
    RULEUCC_SpecialAction       = { helpText = "special_action",    bitmapId = 'error:noimage',         preferredSlot = 21   },
    RULEUCC_Dock                = { helpText = "dock",              bitmapId = 'dock',                  preferredSlot = 12.1 },

    RULEUCC_Script              = { helpText = "special_action",    bitmapId = 'overcharge',            preferredSlot = 7.3  },
    --}

    --local toggleModes = {
    RULEUTC_ShieldToggle        = { helpText = "toggle_shield",     bitmapId = 'shield',                preferredSlot = 7.4  },
    RULEUTC_WeaponToggle        = { helpText = "toggle_weapon",     bitmapId = 'toggle-weapon',         preferredSlot = 7.5  },
    RULEUTC_JammingToggle       = { helpText = "toggle_jamming",    bitmapId = 'jamming',               preferredSlot = 8.1  },
    RULEUTC_IntelToggle         = { helpText = "toggle_intel",      bitmapId = 'intel',                 preferredSlot = 8.2  },
    RULEUTC_ProductionToggle    = { helpText = "toggle_production", bitmapId = 'production',            preferredSlot = 9.6  },
    RULEUTC_StealthToggle       = { helpText = "toggle_stealth",    bitmapId = 'stealth',               preferredSlot = 9.7  },
    RULEUTC_GenericToggle       = { helpText = "toggle_generic",    bitmapId = 'production',            preferredSlot = 10.2 },
    RULEUTC_SpecialToggle       = { helpText = "toggle_special",    bitmapId = 'activate-weapon',       preferredSlot = 11.1 },
    RULEUTC_CloakToggle         = { helpText = "toggle_cloak",      bitmapId = 'intel-counter',         preferredSlot = 11.2 },
}

Description = {}

Tooltips = {
    -- These two don't have entries on the default table
    mode                        = { title = "Fire State",                                           description = "" },
    call_transport              = { title = "Call Transport",                                       description = "Load into or onto another unit" },

    -- These could be deleted if you're importing env tooltips.
    move                        = { title = "<LOC tooltipui0000>Move",                              description = "" },
    attack                      = { title = "<LOC tooltipui0002>Attack",                            description = "" },
    patrol                      = { title = "<LOC tooltipui0004>Patrol",                            description = "" },
    stop                        = { title = "<LOC tooltipui0006>Stop",                              description = "" },
    assist                      = { title = "<LOC tooltipui0008>Assist",                            description = "" },
    build_tactical              = { title = "<LOC tooltipui0012>Build Missile",                     description = "<LOC tooltipui0013>Right-click to toggle Auto-Build" },
    build_tactical_auto         = { title = "<LOC tooltipui0335>Build Missile (Auto)",              description = "<LOC tooltipui0336>Auto-Build Enabled" },
    build_nuke                  = { title = "<LOC tooltipui0014>Build Strategic Missile",           description = "<LOC tooltipui0015>Right-click to toggle Auto-Build" },
    build_nuke_auto             = { title = "<LOC tooltipui0337>Build Strategic Missile (Auto)",    description = "<LOC tooltipui0338>Auto-Build Enabled" },
    overcharge                  = { title = "<LOC tooltipui0016>Overcharge",                        description = "" },
    transport                   = { title = "<LOC tooltipui0018>Transport",                         description = "" },
    fire_nuke                   = { title = "<LOC tooltipui0020>Launch Strategic Missile",          description = "" },
    fire_billy                  = { title = "<LOC tooltipui0664>Launch Advanced Tactical Missile",  description = "" },
    build_billy                 = { title = "<LOC tooltipui0665>Build Advanced Tactical Missile",   description = "<LOC tooltipui0013>" },
    fire_tactical               = { title = "<LOC tooltipui0022>Launch Missile",                    description = "" },
    teleport                    = { title = "<LOC tooltipui0024>Teleport",                          description = "" },
    ferry                       = { title = "<LOC tooltipui0026>Ferry",                             description = "" },
    sacrifice                   = { title = "<LOC tooltipui0028>Sacrifice",                         description = "" },
    dive                        = { title = "<LOC tooltipui0030>Surface/Dive Toggle",               description = "<LOC tooltipui0423>Right-click to toggle auto-surface" },
    dive_auto                   = { title = "<LOC tooltipui0030>Surface/Dive Toggle",               description = "<LOC tooltipui0424>Auto-surface enabled" },
    dock                        = { title = "<LOC tooltipui0425>Dock",                              description = "<LOC tooltipui0477>Recall aircraft to nearest air staging facility for refueling and repairs" },
    deploy                      = { title = "<LOC tooltipui0478>Deploy",                            description = "" },
    reclaim                     = { title = "<LOC tooltipui0032>Reclaim",                           description = "" },
    capture                     = { title = "<LOC tooltipui0034>Capture",                           description = "" },
    repair                      = { title = "<LOC tooltipui0036>Repair",                            description = "" },
    pause                       = { title = "<LOC tooltipui0038>Pause Construction",                description = "<LOC tooltipui0506>Pause/unpause current construction order" },
    toggle_omni                 = { title = "<LOC tooltipui0479>Omni Toggle",                       description = "<LOC tooltipui0480>Turn the selected units omni on/off" },
    toggle_shield               = { title = "<LOC tooltipui0040>Shield Toggle",                     description = "<LOC tooltipui0481>Turn the selected units shields on/off" },
    toggle_shield_dome          = { title = "<LOC tooltipui0482>Shield Dome Toggle",                description = "<LOC tooltipui0483>Turn the selected units shield dome on/off" },
    toggle_shield_personal      = { title = "<LOC tooltipui0484>Personal Shield Toggle",            description = "<LOC tooltipui0485>Turn the selected units personal shields on/off" },
    toggle_sniper               = { title = "<LOC tooltipui0647>Sniper Toggle",                     description = "<LOC tooltipui0648>Toggle sniper mode. Range, accuracy and damage are enhanced, but rate of fire is decreased when enabled" },
    toggle_weapon               = { title = "<LOC tooltipui0361>Weapon Toggle",                     description = "<LOC tooltipui0362>Toggle between air and ground weaponry" },
    toggle_jamming              = { title = "<LOC tooltipui0044>Radar Jamming Toggle",              description = "<LOC tooltipui0486>Turn the selected units radar jamming on/off" },
    toggle_intel                = { title = "<LOC tooltipui0046>Intelligence Toggle",               description = "<LOC tooltipui0487>Turn the selected units radar, sonar or Omni on/off" },
    toggle_radar                = { title = "<LOC tooltipui0488>Radar Toggle",                      description = "<LOC tooltipui0489>Turn the selection units radar on/off" },
    toggle_sonar                = { title = "<LOC tooltipui0490>Sonar Toggle",                      description = "<LOC tooltipui0491>Turn the selection units sonar on/off" },
    toggle_production           = { title = "<LOC tooltipui0048>Production Toggle",                 description = "<LOC tooltipui0492>Turn the selected units production capabilities on/off" },
    toggle_area_assist          = { title = "<LOC tooltipui0503>Area-Assist Toggle",                description = "<LOC tooltipui0564>Turn the engineering area assist capabilities on/off" },
    toggle_scrying              = { title = "<LOC tooltipui0494>Scrying Toggle",                    description = "<LOC tooltipui0495>Turn the selected units scrying capabilities on/off" },
    scry_target                 = { title = "<LOC tooltipui0496>Scry",                              description = "<LOC tooltipui0497>View an area of the map" },
    vision_toggle               = { title = "<LOC tooltipui0498>Vision Toggle",                     description = "" },
    toggle_stealth_field        = { title = "<LOC tooltipui0499>Stealth Field Toggle",              description = "<LOC tooltipui0500>Turn the selected units stealth field on/off" },
    toggle_stealth_personal     = { title = "<LOC tooltipui0501>Personal Stealth Toggle",           description = "<LOC tooltipui0502>Turn the selected units personal stealth field on/off" },
    toggle_cloak                = { title = "<LOC tooltipui0339>Personal Cloak",                    description = "<LOC tooltipui0342>Turn the selected units cloaking on/off" },
}

abilityDesc = {
    ['Anti-Air']                        = 'Can shoot aircraft, including high-altitude air',
    ['Air Staging']                     = 'Aircraft can land on it for refuel and/or repair',
    ['Artillery Defense']               = 'Protects against artillery projectile weapons',
    ['Amphibious']                      = 'Can pass land and water',
    ['Aquatic']                         = 'Buildable on land and on or in water',
    ['Carrier']                         = 'Can build and/or store aircraft',
    ['Cloaking']                        = 'Can become hidden to visual sensors',
    ['Customizable']                    = 'Has optional enhancements to improve performance or unlock new featuers',
    ['Directional Sensor']              = 'Has non-standard intel that is off-centre', -- BrewLAN
    ['Volatile']                        = 'Has a death weapon',
    ['Deploys']                         = 'Needs to be stationary for one or more effects',
    ['Depth Charges']                   = 'Can attack water with projectiles immune to anti-torpedo',
    ['Engineering Suite']               = 'Has complete engineering features',
    ['Factory']                         = 'Can build units without entering command mode',
    ['Hover']                           = 'Can pass water and is immune to torpedoes',
    ['Jamming']                         = 'Creates false radar signals',
    ['Manual Launch']                   = 'Has a counted projectile weapon that needs manually controlling',
    ['Massive']                         = 'Damages things by treading on them',
    ['Missile Defense']                 = 'Has countermeasures for missiles that don\'t count as \'tactical\' or \'strategic\'', -- BrewLAN
    ['Not Capturable']                  = 'Is either unable to be, or never in a position to be, captured',
    ['Omni Sensor']                     = 'Has advanced intel that can see through counterintel',
    ['Personal Shield']                 = 'Has a shield that only effectively protects itself',
    ['Personal Stealth']                = 'Hidden to radar and/or sonar',
    ['Personal Teleporter']             = 'Has the ability to teleport without requiring an enhancement', -- BrewLAN
    ['Radar']                           = 'Can see blips of units not seen by vision that are on or above water',
    ['Reclaims']                        = 'Can harvest entities for resources; this damages them if they have health',
    ['Repairs']                         = 'Can fix damage on other units at the cost of resources',
    ['Sacrifice']                       = 'Can destroy itself to contribute to a build',
    ['Satellite Uplink']                = 'Prevents satellites from receiving damage from flying unguided',  -- BrewLAN
    ['Satellite Capacity: +0']          = 'Doesn\'t contribute towards satellite population capacity',-- BrewLAN
    ['Satellite Capacity: +1']          = 'Contributes 1 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +2']          = 'Contributes 2 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +3']          = 'Contributes 3 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +4']          = 'Contributes 4 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity: +5']          = 'Contributes 5 towards the maximum deployable satellites',  -- BrewLAN
    ['Satellite Capacity Unrestricted'] = 'Effectively removes satellite deployment limits', -- BrewLAN
    ['Shield Dome']                     = 'Has a bubble shield that can protect others',
    ['Sonar']                           = 'Can see blips of units not seen by vision that are on or below water',
    ['Stealth Field']                   = 'Hides itself and nearby others from radar and/or sonar',
    ['Strategic Missile Defense']       = 'Can target strategic missile projectiles',
    ['EMP Weapon']                      = "Can inflict 'stun'",
    ['Submersible']                     = 'Is a naval unit that can surface and dive',
    ['Suicide Weapon']                  = 'Has a single-use self-damaging weapon',
    ['Tactical Missiles']               = 'Has a weapon with projectiles that identify as tactical missiles', -- BrewLAN
    ['Tactical Missile Defense']        = 'Can target tactical missile projectiles',
    ['Tactical Missile Deflection']     = 'Can target and redirect tactical missile projectiles',
    ['Teleporter']                      = 'Can teleport itself and others', -- BrewLAN
    ['Torpedoes']                       = 'Has a weapon that can target things immersed in water',
    ['Torpedo Defense']                 = 'Can target torpedo projectiles',
    ['Transport']                       = 'Can carry other units',
    ['Upgradeable']                     = 'Can build a unit to replace itself',
}
