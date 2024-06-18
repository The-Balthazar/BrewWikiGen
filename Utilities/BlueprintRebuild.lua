
--converts false values to nil, returns true if any values still exist
local function NilFalseValuesInFlagList(flaglist)
    if not flaglist then return end
    local anytrue
    for k, v in pairs(flaglist) do
        if not v then
            flaglist[k] = nil
        else
            anytrue = true
        end
    end
    return anytrue
end

local function Nil0ValuesInTable(group)
    if not group then return end
    for k, v in pairs(group) do
        if v == 0 then
            group[k] = nil
        end
    end
end

local function BuildOnLayerBitwiseValue(buildCaps)
    return
    (buildCaps.LAYER_Land and 1 or 0) +
    (buildCaps.LAYER_Seabed and 2 or 0) +
    (buildCaps.LAYER_Sub and 4 or 0) +
    (buildCaps.LAYER_Water and 8 or 0) +
    (buildCaps.LAYER_Air and 16 or 0)
end

local IconMotionTypes = {
    RULEUMT_Air                = { Icon = 'air', },
    RULEUMT_Amphibious         = { Icon = 'amph', },
    RULEUMT_AmphibiousFloating = { Icon = 'amph', },
    RULEUMT_Biped              = { Icon = 'land', },
    RULEUMT_Land               = { Icon = 'land', },
    RULEUMT_Hover              = { Icon = 'amph', },
    RULEUMT_Water              = { Icon = 'sea', },
    RULEUMT_SurfacingSub       = { Icon = 'sea', },
    RULEUMT_None               = { Icon = 'land', },
}

function RemoveRedundantBlueprintValues(bp)
    if bp.__name~='Unit' then return end
    -- Just straight up kill these, always. They do nothing
    if RebuildBlueprintOptions.RemoveUnusedValues then
        bp.General.Category = nil
        bp.General.Classification = nil
        bp.General.TechLevel = nil
        bp.General.UnitWeight = nil
        bp.Display.PlaceholderMeshName = nil
        bp.Display.SpawnRandomRotation = nil
        bp.UseOOBTestZoom = nil
        bp.Interface = nil
    end

    -- Build on layer caps
    if RebuildBlueprintOptions.CleanupBuildOnLayerCaps then
        if bp.Physics.MotionType ~= 'RULEUMT_None' -- Only structures use BuildOnLayerCaps
        or BuildOnLayerBitwiseValue(bp.Physics.BuildOnLayerCaps) == 1 then -- This is the undefined default
            bp.Physics.BuildOnLayerCaps = nil
        else
            NilFalseValuesInFlagList(bp.Physics.BuildOnLayerCaps)
        end
    end

    if RebuildBlueprintOptions.CleanupWreckageLayers then
        NilFalseValuesInFlagList(bp.Wreckage.WreckageLayers)
    end

    -- Command caps
    if RebuildBlueprintOptions.CleanupCommandCaps then
        if not NilFalseValuesInFlagList(bp.General.CommandCaps) then -- Clear false values
            bp.General.CommandCaps = nil -- Remove if nothing is true
        end
    end

    if RebuildBlueprintOptions.RemoveMilitaryOverlayCategories and bp.Categories then
        table.removeByValue(bp.Categories, 'OVERLAYANTIAIR')
        table.removeByValue(bp.Categories, 'OVERLAYANTINAVY')
        table.removeByValue(bp.Categories, 'OVERLAYDEFENSE')
        table.removeByValue(bp.Categories, 'OVERLAYDIRECTFIRE')
        table.removeByValue(bp.Categories, 'OVERLAYINDIRECTFIRE')
    end

    if RebuildBlueprintOptions.RemoveProductCategories and bp.Categories then
        table.removeByValue(bp.Categories, arrayFindSub(bp.Categories, 1, 7, 'PRODUCT') )
    end

    if RebuildBlueprintOptions.CleanupIntelOverlayCategories and bp.Categories then
        for i, set in ipairs{
            {'RadarRadius', 'OVERLAYRADAR'},
            {'SonarRadius', 'OVERLAYSONAR'},
            {'OmniRadius', 'OVERLAYOMNI'},
        } do
            if (bp.Intel[ set[1] ] or 0)>0 then
                if not table.find(bp.Categories, set[2]) then
                    table.insert(bp.Categories, set[2])
                end
            else
                table.removeByValue(bp.Categories, set[2])
            end
        end
        if (bp.Intel.RadarStealthFieldRadius or 0)>0
        or (bp.Intel.SonarStealthFieldRadius or 0)>0
        or (bp.Intel.CloakFieldRadius or 0)>0
        or (bp.Intel.JamRadius.Max or 0)>0 and (bp.Intel.JammerBlips or 0)>0 then
            if not table.find(bp.Categories, 'OVERLAYCOUNTERINTEL') then
                table.insert(bp.Categories, 'OVERLAYCOUNTERINTEL')
            end
        else
            table.removeByValue(bp.Categories, 'OVERLAYCOUNTERINTEL')
        end
    end

    if RebuildBlueprintOptions.CleanupGeneralBackgroundIcon and bp.General then
        local currenticon = (bp.General.Icon or 'land')
        local factoryicon
        local physicaicon

        if bp.Physics.MotionType ~= 'RULEUMT_None' then
            physicaicon = IconMotionTypes[bp.Physics.MotionType].Icon
        else
            local blc = bp.Physics.BuildOnLayerCaps
            local BLwater = blc and (blc.LAYER_Water or blc.LAYER_Sub or blc.LAYER_Seabed) and 'sea'
            local BLland = (blc and blc.LAYER_Land or not blc) and 'land'

            local BLbin = BinaryCounter{BLland, BLwater}

            physicaicon = (BLbin == 1) and (BLland or BLwater) or 'amph'

            if table.find(bp.Categories, 'FACTORY') then
                local Cair = table.find(bp.Categories, 'AIR') and 'air'
                local Cland = table.find(bp.Categories, 'LAND') and 'land'
                local Cnaval = table.find(bp.Categories, 'NAVAL') and 'sea'

                local Cbin = BinaryCounter{Cair, Cland, Cnaval}

                factoryicon = (Cbin == 1) and (Cair or Cnaval or (Cland and physicaicon) ) or (Cbin ~= 0) and 'amph'
            end
        end

        if currenticon ~= (factoryicon or physicaicon) then
            bp.General.Icon = (factoryicon or physicaicon)
        end
    end

    --if not bp.Display.MovementEffects.Land.Treads.ScrollTreads then LODs[1].Scrolling = nil end
end

local function CategoriesSortClean(cats)
    if not cats then return end
    local hash = {}
    for i, cat in ipairs(cats) do
        hash[cat] = cat
    end
    local clean = {}
    for cat, cat in sortedpairs(hash) do
        table.insert(clean, cat)
    end
    return clean
end

function RecalculateBlueprintThreatValues(bp)
    if bp.__name~='Unit' then return end
    if not bp.Defense then return end
    local pass, threat = pcall(CalculateUnitThreatValues, bp)
    if pass and threat then
        for i, v in next, threat do
            bp.Defense[i] = v
        end
        Nil0ValuesInTable(bp.Defense)
    end
end

function RebuildBlueprintsFiles()
    local toRebuild = RebuildBlueprintOptions.RebuildBpFiles
    if type(toRebuild)~='table' then
        print(LogEmoji'⚠️'..' RebuildBlueprintOptions.RebuildBpFiles is using old format bool rather than hash of types')
    else
        for bpType, bool in pairs(RebuildBlueprintOptions.RebuildBpFiles) do
            if bool and all_blueprints[bpType] then
                for id, bp in pairs(all_blueprints[bpType]) do
                    if bp.ModInfo.RebuildBlueprints ~= false and bp.SourceFileBlueprintCount == 1 and bp.Source then
                        print('Rebuilding '..bp.Source)
                        bp.Categories = CategoriesSortClean(bp.Categories)
                        if bpType=='Unit' then
                            RemoveRedundantBlueprintValues(bp)
                            if RebuildBlueprintOptions.RecalculateThreat then
                                RecalculateBlueprintThreatValues(bp)
                            end
                        end
                        local bpfile = io.open(bp.Source, 'w')
                        bpfile:write(blueprintSerialize(bp))
                        bpfile:close()
                    end
                end
            elseif bool and not all_blueprints[bpType] then
                print(LogEmoji'⚠️'..' RebuildBpFiles blueprint type '..bpType..' isn\'t set to be loaded in EnvironmentData.LoadExtraBlueprints')
            end
        end
    end
end
