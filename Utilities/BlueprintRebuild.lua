
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

function RemoveRedundantBlueprintValues(bp)
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
    for id, bp in pairs(all_blueprints.Unit) do
        if bp.ModInfo.RebuildBlueprints ~= false and bp.SourceFileBlueprintCount == 1 and bp.Source then
            print('Rebuilding '..bp.Source)
            bp.Categories = CategoriesSortClean(bp.Categories)
            RemoveRedundantBlueprintValues(bp)
            if RebuildBlueprintOptions.RecalculateThreat then
                RecalculateBlueprintThreatValues(bp)
            end
            local bpfile = io.open(bp.Source, 'w')
            bpfile:write(blueprintSerialize(bp))
            bpfile:close()
        end
    end
end
