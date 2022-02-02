--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

GetUnitInfoboxData = function(ModInfo, bp)
    return {
        {bp.WikiInfoboxNote and '', bp.WikiInfoboxNote and LOC(bp.WikiInfoboxNote)..(bp.WikiBalance and detailsLink('<LOC wiki_sect_balance>Balance') or '')},
        ----
        {'<LOC wiki_infobox_mod_source>'..'Source:',    xml:a{href=(stringSanitiseFilename(ModInfo.name))}(stringHTMLWrap(ModInfo.name, 20))},
        {'<LOC wiki_infobox_unitid>'    ..'Unit ID:',   xml:code(bp.id)},
        {'<LOC wiki_infobox_faction>'   ..'Faction:',   FactionFromFactionCategory(bp.FactionCategory)},
        {'<LOC wiki_infobox_factions>'  ..'Factions:',  not bp.FactionCategory and InfoboxFlagsList(FactionsFromFactionCatHash(bp.FactionCategoryHash)) },
        {'<LOC wiki_infobox_tech>'      ..'Tech level:', iconText(bp.unitTIndex, bp.unitTIndex and bp.unitTIndex..(bp.unitTIndex == 4 and ' (Experimental)' or '')) },
        {''},
        {'<LOC wiki_infobox_health>'    ..'Health:',
            (
                not bp.CategoriesHash.INVULNERABLE
                and iconText(
                    'Health',
                    bp.Defense and bp.Defense.MaxHealth,
                    (bp.Defense and bp.Defense.RegenRate and bp.Defense.RegenRate ~= 0 and ' (+'..bp.Defense.RegenRate ..'/s)')
                )
                or 'Invulnerable'
            )
        },
        {'<LOC wiki_infobox_armor>'     ..'Armour:', (bp.Defense and not bp.CategoriesHash.INVULNERABLE and bp.Defense.ArmorType and '<code>'..bp.Defense.ArmorType..'</code>')},
        {'<LOC wiki_infobox_shieldh>'   ..'Shield health:',
            iconText(
                'Shield',
                 tableSafe(bp.Defense, 'Shield', 'ShieldMaxHealth'),
                (tableSafe(bp.Defense, 'Shield', 'ShieldRegenRate') and ' (+'..bp.Defense.Shield.ShieldRegenRate..'/s)')
            )
        },
        {'<LOC wiki_infobox_shieldr>'   ..'Shield radius:', (tableSafe(bp.Defense, 'Shield', 'ShieldSize') and numberFormatNoTrailingZeros(bp.Defense.Shield.ShieldSize / 2))}, --Shield size is a scale multiplier, and so is effectively diameter
        {'<LOC wiki_infobox_defflags>'  ..'Flags:',
            InfoboxFlagsList{
                 bp.CategoriesHash.UNTARGETABLE and 'Untargetable' or '',
                (bp.CategoriesHash.UNSELECTABLE or not bp.CategoriesHash.SELECTABLE) and 'Unselectable' or '',
                (bp.Display and bp.Display.HideLifebars or bp.LifeBarRender == false) and 'Lifebars hidden' or '',
                tableSafe(bp.Defense,'Shield','AntiArtilleryShield') and 'Artillery shield' or '',
                tableSafe(bp.Defense,'Shield','PersonalShield') and 'Personal shield' or '',
            }
        },
        {''},
        {'<LOC wiki_infobox_cost_e>'    ..'Energy cost:',       iconText('Energy', bp.Economy and bp.Economy.BuildCostEnergy)},
        {'<LOC wiki_infobox_cost_m>'    ..'Mass cost:',         iconText('Mass',   bp.Economy and bp.Economy.BuildCostMass)},
        {'<LOC wiki_infobox_cost_t>'    ..'Build time:',        iconText('',       bp.Economy and bp.Economy.BuildTime, arraySubFind(bp.Categories, 'BUILTBY') and detailsLink('<LOC wiki_sect_construction>Construction') or '' )},
        {'<LOC wiki_infobox_maint_e>'   ..'Maintenance cost:',  iconText('Energy', bp.Economy and bp.Economy.MaintenanceConsumptionPerSecondEnergy,'/s')},
        {'<LOC wiki_infobox_buildrate>' ..'Build rate:',        iconText('Build',  bp.Economy and bp.Economy.BuildRate)},
        {'<LOC wiki_infobox_prod_e>'    ..'Energy production:', iconText('Energy', bp.Economy and bp.Economy.ProductionPerSecondEnergy, '/s')},
        {'<LOC wiki_infobox_prod_m>'    ..'Mass production:',   iconText('Mass',   bp.Economy and bp.Economy.ProductionPerSecondMass, '/s')},
        {'<LOC wiki_infobox_store_e>'   ..'Energy storage:',    iconText('Energy', bp.Economy and bp.Economy.StorageEnergy)},
        {'<LOC wiki_infobox_store_m>'   ..'Mass storage:',      iconText('Mass',   bp.Economy and bp.Economy.StorageMass)},
        {''},
        {'<LOC wiki_infobox_vision_r>'    ..'Vision radius:',       (bp.Intel and bp.Intel.VisionRadius or 10)},
        {'<LOC wiki_infobox_w_vision_r>'  ..'Water vision radius:', (bp.Intel and bp.Intel.WaterVisionRadius or 10)},
        {'<LOC wiki_infobox_radar_r>'     ..'Radar radius:',        (bp.Intel and bp.Intel.RadarRadius)},
        {'<LOC wiki_infobox_sonar_r>'     ..'Sonar radius:',        (bp.Intel and bp.Intel.SonarRadius)},
        {'<LOC wiki_infobox_omni_r>'      ..'Omni radius:',         (bp.Intel and bp.Intel.OmniRadius)},
        {'<LOC wiki_infobox_jammer_blips>'..'Jammer blips (radii):',
            (bp.Intel and bp.Intel.JamRadius)
            and
            (bp.Intel.JammerBlips or 0)..' ('..
            (bp.Intel.JamRadius.Min)..'‒'..
            (bp.Intel.JamRadius.Max)..')'
        },
        {'<LOC wiki_infobox_cloak_r>'       ..'Cloak radius:',         (bp.Intel and bp.Intel.CloakFieldRadius)},
        {'<LOC wiki_infobox_steath_radar_r>'..'Radar stealth radius:', (bp.Intel and bp.Intel.RadarStealthFieldRadius)},
        {'<LOC wiki_infobox_steath_sonar_r>'..'Sonar stealth radius:', (bp.Intel and bp.Intel.SonarStealthFieldRadius)},
        {'<LOC wiki_infobox_intelflags>'    ..'Flags:',
            bp.Intel and InfoboxFlagsList{
                (bp.Intel.Cloak and 'Cloak' or ''),
                (bp.Intel.RadarStealth and 'Radar stealth' or ''),
                (bp.Intel.SonarStealth and 'Sonar stealth' or ''),
            }
        },
        {''},
        {'<LOC wiki_infobox_motion>'         ..'Motion type:',       bp.Physics.MotionType and ('<code>'..bp.Physics.MotionType..'</code>')},
        {'<LOC wiki_infobox_build_layers>'   ..'Buildable layers:', (bp.Physics.MotionType == 'RULEUMT_None') and BuildableLayer(bp.Physics)},
        {'<LOC wiki_infobox_movement_speed>' ..'Movement speed:',   (bp.Air and bp.Air.MaxAirspeed or bp.Physics.MaxSpeed)},
        {'<LOC wiki_infobox_fuel>'           ..'Fuel:',             (bp.Physics.FuelUseTime and iconText('Fuel', formatTime(bp.Physics.FuelUseTime), '') )},
        {'<LOC wiki_infobox_elevation>'      ..'Elevation:',        (bp.Air and bp.Physics.Elevation)},
        {'<LOC wiki_infobox_transport_class>'..'Transport class:', (
            (
                bp.Physics.MotionType ~= 'RULEUMT_None' and (
                    bp.General and bp.General.CommandCaps and (
                        bp.General.CommandCaps.RULEUCC_CallTransport or bp.General.CommandCaps.RULEUCC_Dock
                    )
                    or bp.CategoriesHash.POD
                )
            ) and iconText('Attached',
                transportClassHookType(bp.Transport and bp.Transport.TransportClass or 1)
            )
        )},
        {'<LOC wiki_infobox_transport_capacity>'..'Transport capacity:', iconText('Attached',
            (
                bp.General and
                bp.General.CommandCaps and
                bp.General.CommandCaps.RULEUCC_Transport
                and bp.Transport
            ) and (
                bp.Transport.Class1Capacity and
                bp.Transport.Class1Capacity..detailsLink('<LOC wiki_sect_transport>Transport capacity')
            )
        )},
        {''},
        {'<LOC wiki_infobox_miscrad>' ..'Misc radius:', bp.CategoriesHash.OVERLAYMISC and bp.AI and bp.AI.StagingPlatformScanRadius, 'Defined by the air staging radius value. Often used to indicate things without a dedicated range ring.' },
        {'<LOC wiki_infobox_weapons>' ..'Weapons:',     bp.Weapon and #bp.Weapon..detailsLink('<LOC wiki_sect_weapons>Weapons')},
        {'<LOC wiki_infobox_wreckage>'..'Wreckage:',   tableSafe(bp.Wreckage,'WreckageLayers') and
            (
                bp.Wreckage.WreckageLayers.Land or
                bp.Wreckage.WreckageLayers.Seabed or
                bp.Wreckage.WreckageLayers.Water
            ) and
            InfoboxFlagsList{
                (bp.Wreckage.HealthMult or 1) ~= 0 and (iconText(
                    'Health',
                    numberFormatNoTrailingZeros(
                        bp.Defense.Health *
                        (bp.Wreckage.HealthMult or 1)
                    )
                ) or ''),
                bp.Economy.BuildCostMass * (bp.Wreckage.MassMult or 0) ~= 0 and (iconText(
                    'Mass',
                    numberFormatNoTrailingZeros(
                        bp.Economy.BuildCostMass *
                        (bp.Wreckage.MassMult or 0) *
                        (bp.Wreckage.HealthMult or 1)
                    )
                ) or ''),
                bp.Economy.BuildCostEnergy * (bp.Wreckage.EnergyMult or 0) ~= 0 and (iconText(
                    'Energy',
                    numberFormatNoTrailingZeros(
                        bp.Economy.BuildCostEnergy *
                        (bp.Wreckage.EnergyMult or 0) *
                        (bp.Wreckage.HealthMult or 1)
                    )
                ) or '')
            }
        },
    }
end

InfoboxFlagsList = function(spec)
    return setmetatable(spec, {

        __tostring = function(self)
            local s = ''
            for i, v in ipairs(self) do
                if v and tostring(v) ~= '' then
                    if s ~= '' then
                        s = s..'<br />'
                    end
                    s = s..tostring(v)
                end
            end
            return s
        end,

        __eq = function(t1, t2)
            return tostring(t1) == tostring(t2)
        end,

    })
end

local InfoboxHeader = function(style, data)
    local styles = {
        ['main-right1'] = [[
<table align="right">
    <thead>
        <tr>
            <th align="left" colspan="2">
                %s
            </th>
        </tr>
    </thead>
    <tbody>
]],
        ['main-right2'] = [[
<table align="right">
    <thead>
        <tr>
            <th colspan="2">
                %s
            </th>
        </tr>
        <tr>
            <th colspan="2">
                %s
            </th>
        </tr>
    </thead>
    <tbody>
]],
        ['detail-left1'] = "<details>\n<summary>%s</summary>\n<p>\n    <table>\n",
    }
    return string.format(styles[style..#data], table.unpack(data))
end

local InfoboxRow = function(th, td, tip)
    if th == '' then
        return "        "..xml:tr(xml:td{colspan=2, align='center'}(td or '')).."\n"
    elseif td and tostring(td) ~= '' then
        return
        "        "..xml:tr(
        "            "..xml:td{align='right'}(xml:strong(LOC(th or ''))),
        "            "..xml:td(tostring(td)..hoverTip(tip)),
        "        ").."\n"
    end
    return ''
end

local InfoboxEnd = function(style)
    local styles = {
        ['main-right'] = "    </tbody>\n</table>\n\n",
        ['detail-left'] = "    </table>\n</p>\n</details>\n",
    }
    return styles[style]
end

Infobox = function(spec)
    return setmetatable(spec, {

        __tostring = function(self)
            local infoboxstring = InfoboxHeader(self.Style, self.Header )
            if type(self.Data) == 'string' then
                infoboxstring = infoboxstring .. self.Data
            else
                for i, field in ipairs(self.Data) do
                    infoboxstring = infoboxstring .. InfoboxRow( table.unpack(field) )
                end
            end
            return infoboxstring .. InfoboxEnd(self.Style)
        end,

    })
end

DoToInfoboxDataCell = function(fun, infodata, key, value)
    for i, v in ipairs(infodata) do
        if noLOC(v[1]) == key then
            fun(v[2], value)
            break
        end
    end
end
