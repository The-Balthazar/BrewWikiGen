--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
function UnitInfobox(bp)
    local BPimg = 'images/units/'..bp.ID..'.jpg'
    return Infobox{
        Style = 'main-right',
        Header = {
            UnitIcon(bp.ID, {align='left', title=(bp.General.UnitName or 'The')..' unit icon'})..
            StrategicIcon(bp.StrategicIconName, {align='right'})..
            (bp.General.UnitName or xml:i'Unnamed')..xml:br()..(bp.TechDescription or xml:i'No description'),
            FileExists(OutputDirectory..BPimg) and xml:a{href=BPimg}(xml:img{width='256px', src=BPimg}) or Logging.MissingUnitImage and print(bp.id, "has no infobox image ("..BPimg..")") or nil
        },
        Data = {
            {bp.WikiInfoboxNote and '', bp.WikiInfoboxNote and LOC(bp.WikiInfoboxNote)..(bp.WikiBalance and detailsLink('<LOC wiki_sect_balance>Balance') or '')},
            ----
            {'<LOC wiki_infobox_mod_source>'..'Source:',    xml:a{href=(stringSanitiseFilename(bp.ModInfo.name))}(stringHTMLWrap(bp.ModInfo.name, 20))},
            {'<LOC wiki_infobox_unitid>'    ..'Unit ID:',
                WikiOptions.OnlineRepoUnitPageBlueprintLink and (
                    xml:a{
                        href=WikiOptions.OnlineRepoUnitPageBlueprintLink
                        ..bp.Source:gsub(WikiOptions.LocalRepuUnitPageBlueprintLink, '')
                    }(xml:code(bp.id))
                )
                or xml:code(bp.id)
            },
            {'<LOC wiki_infobox_faction>'   ..'Faction:',   bp.FactionCategory ~= 'OTHER' and categoryLink(bp.FactionCategory, FactionFromFactionCategory(bp.FactionCategory))},
            {'<LOC wiki_infobox_factions>'  ..'Factions:',  not bp.FactionCategory and InfoboxFlagsList(FactionsFromFactionCatHash(bp.FactionCategoryHash)) },
            {'<LOC wiki_infobox_tech>'      ..'Tech level:', iconText(bp.TechIndex, bp.TechIndex and bp.TechIndex..(bp.TechIndex == 4 and LOCBrackets(LOC'<LOC wiki_tech_4>Experimental') or '')) },
            {''},
            {'<LOC wiki_infobox_health>'    ..'Health:',
                (
                    not bp.CategoriesHash.INVULNERABLE
                    and iconText(
                        'Health',
                        bp.Defense.MaxHealth,
                        (bp.Defense.RegenRate and bp.Defense.RegenRate ~= 0 and LOCBrackets(LOCPlusPerSec(bp.Defense.RegenRate)))
                    )
                    or LOC'<LOC wiki_flag_invulnerable>Invulnerable'
                )
            },
            {'<LOC wiki_infobox_armor>'     ..'Armour:', (not bp.CategoriesHash.INVULNERABLE and bp.Defense.ArmorType and '<code>'..bp.Defense.ArmorType..'</code>')},
            {'<LOC wiki_infobox_shieldh>'   ..'Shield health:',
                iconText(
                    'Shield',
                     bp.Defense.Shield.ShieldMaxHealth,
                    (bp.Defense.Shield.ShieldRegenRate and LOCBrackets(LOCPlusPerSec(bp.Defense.Shield.ShieldRegenRate)) )
                )
            },
            {'<LOC wiki_infobox_shieldr>'   ..'Shield radius:', formatDistance(bp.Defense.Shield.ShieldSize and formatNumber(bp.Defense.Shield.ShieldSize / 2))}, --Shield size is a scale multiplier, and so is effectively diameter
            {'<LOC wiki_infobox_defflags>'  ..'Flags:',
                InfoboxFlagsList{
                    bp.CategoriesHash.UNTARGETABLE and LOC'<LOC wiki_flag_untargetable>Untargetable' or '',
                    (bp.CategoriesHash.UNSELECTABLE or not bp.CategoriesHash.SELECTABLE) and LOC'<LOC wiki_flag_unselectable>Unselectable' or '',
                    (bp.Display.HideLifebars or bp.LifeBarRender == false) and LOC'<LOC wiki_flag_nolife>Lifebars hidden' or '',
                    bp.Defense.Shield.AntiArtilleryShield and LOC'<LOC wiki_flag_artilleryshield>Artillery shield' or '',
                    bp.Defense.Shield.PersonalShield and LOC'<LOC wiki_flag_personalshield>Personal shield' or '',
                }
            },
            {''},
            {'<LOC wiki_infobox_deposit>'   ..'Build restriction:', bp.Physics.BuildRestriction=='RULEUBR_OnMassDeposit'and iconText('OnMass', xml:span{title=bp.Physics.BuildRestriction}(LOC'<LOC wiki_infobox_ruleubr_mass>Mass point')) or
                                                                    bp.Physics.BuildRestriction=='RULEUBR_OnHydrocarbonDeposit'and iconText('OnHydro', xml:span{title=bp.Physics.BuildRestriction}(LOC'<LOC wiki_infobox_ruleubr_hydro>Hydrocarbon'))},
            {'<LOC wiki_infobox_cost_cap>'  ..'Population cost:',   iconText('Unit',   (bp.General.CapCost or 1)~=1 and bp.General.CapCost)},
            {'<LOC wiki_infobox_cost_e>'    ..'Energy cost:',       iconText('Energy', bp.Economy.BuildCostEnergy)},
            {'<LOC wiki_infobox_cost_m>'    ..'Mass cost:',         iconText('Mass',   bp.Economy.BuildCostMass)},
            {'<LOC wiki_infobox_cost_t>'    ..'Build time:',        iconText('',       bp.Economy.BuildTime, bp.BuiltByCategories and detailsLink('<LOC wiki_sect_construction>Construction') or '' )},
            {'<LOC wiki_infobox_maint_e>'   ..'Maintenance cost:',  iconText('Energy', LOCPerSec(bp.Economy.MaintenanceConsumptionPerSecondEnergy))},
            {'<LOC wiki_infobox_buildrate>' ..'Build rate:',        iconText('Build',  bp.Economy.BuildRate)},
            {'<LOC wiki_infobox_prod_e>'    ..'Energy production:', iconText('Energy', LOCPerSec(bp.Economy.ProductionPerSecondEnergy))},
            {'<LOC wiki_infobox_prod_m>'    ..'Mass production:',   iconText('Mass',   LOCPerSec(bp.Economy.ProductionPerSecondMass))},
            {'<LOC wiki_infobox_store_e>'   ..'Energy storage:',    iconText('Energy', bp.Economy.StorageEnergy)},
            {'<LOC wiki_infobox_store_m>'   ..'Mass storage:',      iconText('Mass',   bp.Economy.StorageMass)},
            {''},
            {'<LOC wiki_infobox_vision_r>'    ..'Vision radius:',       formatDistance(bp.Intel.VisionRadius or 10)},
            {'<LOC wiki_infobox_w_vision_r>'  ..'Water vision radius:', formatDistance(bp.Intel.WaterVisionRadius or 10)},
            {'<LOC wiki_infobox_radar_r>'     ..'Radar radius:',        formatDistance(bp.Intel.RadarRadius)},
            {'<LOC wiki_infobox_sonar_r>'     ..'Sonar radius:',        formatDistance(bp.Intel.SonarRadius)},
            {'<LOC wiki_infobox_omni_r>'      ..'Omni radius:',         formatDistance(bp.Intel.OmniRadius)},
            {'<LOC wiki_infobox_jammer_blips>'..'Jammer blips (radii):',
                (bp.Intel.JamRadius)
                and
                (bp.Intel.JammerBlips or 0)..' ('..
                (bp.Intel.JamRadius.Min)..'‒'..
                (bp.Intel.JamRadius.Max)..')'
            },
            {'<LOC wiki_infobox_cloak_r>'       ..'Cloak radius:',         formatDistance(bp.Intel.CloakFieldRadius)},
            {'<LOC wiki_infobox_steath_radar_r>'..'Radar stealth radius:', formatDistance(bp.Intel.RadarStealthFieldRadius)},
            {'<LOC wiki_infobox_steath_sonar_r>'..'Sonar stealth radius:', formatDistance(bp.Intel.SonarStealthFieldRadius)},
            {'<LOC wiki_infobox_intelflags>'    ..'Flags:',
                InfoboxFlagsList{
                    (bp.Intel.Cloak and LOC'<LOC wiki_ability_cloak>Cloak' or ''),
                    (bp.Intel.RadarStealth and LOC'<LOC wiki_ability_radar_stealth>Radar stealth' or ''),
                    (bp.Intel.SonarStealth and LOC'<LOC wiki_ability_sonar_stealth>Sonar stealth' or ''),
                }
            },
            {''},
            {'<LOC wiki_infobox_motion>'         ..'Motion type:',      xml:code(bp.Physics.MotionType or 'RULEUMT_None')},
            {'<LOC wiki_infobox_build_layers>'   ..'Buildable layers:', ((bp.Physics.MotionType or 'RULEUMT_None') == 'RULEUMT_None') and BuildableLayer(bp.Physics)},
            {'<LOC wiki_infobox_movement_speed>' ..'Movement speed:',   formatSpeed(bp.Air.MaxAirspeed or bp.Physics.MaxSpeed, bp.Physics.MotionType == 'RULEUMT_Water' or bp.Physics.MotionType == 'RULEUMT_SurfacingSub')},
            {'<LOC wiki_infobox_fuel>'           ..'Fuel:',             (bp.Physics.FuelUseTime and iconText('Fuel', formatTime(bp.Physics.FuelUseTime), '') )},
            {'<LOC wiki_infobox_elevation>'      ..'Elevation:',        (bp.Air and bp.Physics.Elevation)},
            {'<LOC wiki_infobox_transport_class>'..'Transport class:', (
                (
                    (bp.Physics.MotionType or 'RULEUMT_None') ~= 'RULEUMT_None' and (
                        bp.General.CommandCaps.RULEUCC_CallTransport or
                        bp.General.CommandCaps.RULEUCC_Dock or
                        bp.CategoriesHash.POD
                    )
                ) and iconText('Attached',
                    transportClassHookType(bp.Transport.TransportClass or 1)
                )
            )},
            {'<LOC wiki_infobox_transport_capacity>'..'Transport capacity:', iconText('Attached',
                bp.General.CommandCaps.RULEUCC_Transport and
                bp.Transport.Class1Capacity and
                bp.Transport.Class1Capacity..detailsLink('<LOC wiki_sect_transport>Transport capacity')
            )},
            {'<LOC wiki_infobox_transportflags>'    ..'Flags:', InfoboxFlagsList{bp.Transport.CanFireFromTransport and '<LOC wiki_infobox_fire_from_transport>Fire from transport'}},
            {''},
            {'<LOC wiki_infobox_miscrad>' ..'Misc radius:', formatDistance(bp.CategoriesHash.OVERLAYMISC and bp.AI.StagingPlatformScanRadius), LOC'<LOC wiki_misc_radius_note>Defined by the air staging radius value. Often used to indicate things without a dedicated range ring.' },
            {'<LOC wiki_infobox_weapons>' ..'Weapons:',     bp.Weapon and #bp.Weapon..detailsLink('<LOC wiki_sect_weapons>Weapons')},
            {'<LOC wiki_infobox_wreckage>'..'Wreckage:',
                (
                    bp.Wreckage.WreckageLayers.Land or
                    bp.Wreckage.WreckageLayers.Seabed or
                    bp.Wreckage.WreckageLayers.Water
                ) and
                InfoboxFlagsList{
                    (bp.Wreckage.HealthMult or 1) ~= 0 and (iconText(
                        'Health',
                        formatNumber(
                            bp.Defense.Health *
                            (bp.Wreckage.HealthMult or 1)
                        )
                    ) or ''),
                    bp.Economy.BuildCostMass * (bp.Wreckage.MassMult or 0) ~= 0 and (iconText(
                        'Mass',
                        formatNumber(
                            bp.Economy.BuildCostMass *
                            (bp.Wreckage.MassMult or 0) *
                            (bp.Wreckage.HealthMult or 1)
                        )
                    ) or ''),
                    bp.Economy.BuildCostEnergy * (bp.Wreckage.EnergyMult or 0) ~= 0 and (iconText(
                        'Energy',
                        formatNumber(
                            bp.Economy.BuildCostEnergy *
                            (bp.Wreckage.EnergyMult or 0) *
                            (bp.Wreckage.HealthMult or 1)
                        )
                    ) or '')
                }
            },
        },
    }
end
