--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

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

function BlueprintSanityChecks(bp)
    if not Sanity.BlueprintChecks or not bp.WikiPage then
        return
    end
    HashUnitCategories(bp) -- Sanity happens before this happens for reals, so do it again. It'll get overwritten later, but that's fine.

    local issues = {}

    do -- Tech category, strategic icon tech level, transport class
        local t1, t2, t3, t4 = bp.CategoriesHash.TECH1, bp.CategoriesHash.TECH2, bp.CategoriesHash.TECH3, bp.CategoriesHash.EXPERIMENTAL
        if BinaryCounter{t1, t2, t3, t4} > 1 then
            table.insert(issues, 'Multiple tech level categories')
        elseif t4 then -- Experimental things

            if Sanity.BlueprintStrategicIconChecks and bp.StrategicIconName ~= 'icon_experimental_generic' then
                table.insert(issues, 'Experimental without \'icon_experimental_generic\'')
            end

        else -- Tech 1-3
            local t=t1 and 1 or
                    t2 and 2 or
                    t3 and 3

            if Sanity.BlueprintStrategicIconChecks and t and bp.StrategicIconName and not string.find(bp.StrategicIconName, tostring(t)) and not arraySubFind(bp.Categories, 'WALL') then
                table.insert(issues, 'Tech '..t..' with strategic icon '..bp.StrategicIconName)
            end

            if t and bp.Physics.MotionType ~= 'RULEUMT_None'
            and (bp.General.CommandCaps and bp.General.CommandCaps.RULEUCC_CallTransport)
            and not bp.CategoriesHash.CANNOTUSEAIRSTAGING then
                local hook = bp.CategoriesHash.POD and 5 or t
                if (bp.Transport and bp.Transport.TransportClass or 1) ~= hook then
                    table.insert(issues, 'Tech '..t..(hook == 5 and ' drone unit' or '')..' with transport class '..(bp.Transport and bp.Transport.TransportClass or 1))
                end
            end

            local builtby = arraySubFind(bp.Categories, 'BUILTBY')
            if builtby and t then

                local function UpgradesFrom(to, from)
                    return (to.General.UpgradesFrom == from.id and from.General.UpgradesTo == to.id) and from
                end

                local upgrade = getBP(bp.General.UpgradesFrom)

                if upgrade and UpgradesFrom(bp, upgrade) then
                    --Upgrade
                else
                    for i = 1, 3 do
                        local builtI = string.gsub(builtby, '%d', i)
                        if bp.CategoriesHash[builtI] then
                            if i < t then
                                table.insert(issues, 'Tech '..t..' unit appears to have tier '..i..' built by cat.')
                            end
                        else
                            if i >= t then
                                table.insert(issues, 'Tech '..t..' unit appears to be missing tier '..i..' built by cat.')
                            end
                        end
                    end
                end
            end
        end
    end

    if bp.FactionCategory then
        if bp.General.FactionName ~= FactionsByIndex[ FactionCategoryIndexes[bp.FactionCategory] ] then
            table.insert(issues,
                FactionsByIndex[ FactionCategoryIndexes[bp.FactionCategory] ]..
                ' unit has bp.General.FactionName value '..tostring(bp.General.FactionName)
            )
        end
        if bp.Display.Mesh.LODs then
            local Shaders = {
                Seraphim = 'SERAPHIM',
                Aeon = 'AEON',
                AeonCZAR = 'AEON',
                Insect = 'CYBRAN',
                Unit = 'UEF',
            }
            for i, lod in ipairs(bp.Display.Mesh.LODs) do
                if Shaders[lod.ShaderName] and bp.FactionCategory ~= Shaders[lod.ShaderName] then
                    table.insert(issues, bp.FactionCategory.." LOD"..(i-1).." has non-standard faction shader "..lod.ShaderName)
                elseif not Shaders[lod.ShaderName] and Sanity.BlueprintPedanticChecks then
                    table.insert(issues, bp.FactionCategory.." LOD"..(i-1).." has unknown shader "..lod.ShaderName)
                end
            end
        end
        if bp.Display.Tarmacs then
            local tarmacmap = {
                x_01 = 'UEF',
                x_aeon_01 = 'AEON',
                x_cybran_01 = 'CYBRAN',
                x_seraphim_01 = 'SERAPHIM',
            }
            for i, v in ipairs(bp.Display.Tarmacs) do
                local tar = (v.Albedo):match'x.*01'
                if tarmacmap[tar] and tarmacmap[tar] ~= bp.FactionCategory then
                    table.insert(issues, bp.FactionCategory.." unit has "..(tarmacmap[tar]).." tarmac" )
                end
            end
        end
    end

    do -- Defence
        local armourMap = {
            RULEUMT_Air = 'Light',
            RULEUMT_None = 'Structure',
        }
        if armourMap[bp.Physics.MotionType] then
            if armourMap[bp.Physics.MotionType] ~= bp.Defense.ArmorType then
                table.insert(issues, "Armour type is "..tostring(bp.Defense.ArmorType).." when it should probably be "..armourMap[bp.Physics.MotionType])
            end
        elseif (bp.CategoriesHash.COMMAND or bp.CategoriesHash.SUBCOMMANDER) then
            if bp.Defense.ArmorType ~= 'Commander' then
                table.insert(issues, "Armour type is "..tostring(bp.Defense.ArmorType).." when it should probably be Commander")
            end
        elseif bp.CategoriesHash.EXPERIMENTAL then
            if bp.Defense.ArmorType ~= 'Experimental' then
                table.insert(issues, "Armour type is "..tostring(bp.Defense.ArmorType).." when it should probably be Experimental")
            end
        elseif bp.Defense.ArmorType ~= 'Normal' then
            table.insert(issues, "Armour type is "..tostring(bp.Defense.ArmorType).." when it should probably be Normal")
        end
    end

    do -- bp.General.Icon sanitisation
        local currenticon = (bp.General.Icon or 'land')
        local factoryicon
        local physicaicon

        if bp.Physics.MotionType == 'RULEUMT_None' then
            local blc = bp.Physics.BuildOnLayerCaps
            local BLwater = blc and (blc.LAYER_Water or blc.LAYER_Sub or blc.LAYER_Seabed) and 'sea'
            local BLland = (blc and blc.LAYER_Land or not blc) and 'land'

            local BLbin = BinaryCounter{BLland, BLwater}

            physicaicon = (BLbin == 1) and (BLland or BLwater) or 'amph'
        else
            physicaicon = IconMotionTypes[bp.Physics.MotionType].Icon
        end

        if bp.CategoriesHash.FACTORY then
            local Cair = bp.CategoriesHash.AIR and 'air'
            local Cland = bp.CategoriesHash.LAND and 'land'
            local Cnaval = bp.CategoriesHash.NAVAL and 'sea'

            local Cbin = BinaryCounter{Cair, Cland, Cnaval}

            factoryicon = (Cbin == 1) and (Cair or Cnaval or (Cland and physicaicon) ) or (Cbin ~= 0) and 'amph'
        end

        if currenticon ~= (factoryicon or physicaicon) then
            table.insert(issues, 'Icon background is '..currenticon..', should be '..(factoryicon or physicaicon))
        end
    end

    do -- Veteran stuff
        if bp.Buffs.Regen.Level1 and bp.Veteran.Level1 then
            local regen1 = bp.Buffs.Regen.Level1
            local kills1 = bp.Veteran.Level1
            local regenOdd = false
            local killsOdd = false
            for i = 2, 5 do
                if bp.Buffs.Regen['Level'..i] and bp.Buffs.Regen['Level'..i] ~= regen1 * i then
                    regenOdd = true
                end
                if bp.Veteran['Level'..i] and bp.Veteran['Level'..i] ~= kills1 * i then
                    killsOdd = true
                end
            end
            if regenOdd then
                table.insert(issues, 'Veteran regen levels have unusual subdivisions')
            end
            if killsOdd then
                table.insert(issues, 'Veteran kill requirements have unusual subdivisions')
            end
        end
    end

    do -- mesh stuff
        if bp.Bones then
            if bp.General and bp.General.CommandCaps
            and bp.General.CommandCaps.RULEUCC_CallTransport
            and bp.Physics.MotionType ~= 'RULEUMT_Air'
            and not table.find(bp.Bones, 'AttachPoint')
            then
                table.insert(issues, "Mesh has no valid transport attach bone.")
            end
        end
    end

    if Sanity.BlueprintPedanticChecks then
        local pedantry = {
            { bp.Interface,                                     'Redundant bp.Interface table' },
            { bp.Physics.MotionType ~= 'RULEUMT_None' and bp.Physics.BuildOnLayerCaps, 'Redundant bp.Physics.BuildOnLayerCaps table' },
            { bp.Physics.MotionType == 'RULEUMT_None' and bp.Physics.BuildOnLayerCaps and
                (
                    bp.Physics.BuildOnLayerCaps.LAYER_Air == false or
                    bp.Physics.BuildOnLayerCaps.LAYER_Land == false or
                    bp.Physics.BuildOnLayerCaps.LAYER_Orbit == false or
                    bp.Physics.BuildOnLayerCaps.LAYER_Seabed == false or
                    bp.Physics.BuildOnLayerCaps.LAYER_Sub == false or
                    bp.Physics.BuildOnLayerCaps.LAYER_Water == false
                ),                                              'Redundant false bp.Physics.BuildOnLayerCaps value'
            },
            { bp.Display.SpawnRandomRotation ~= nil,            'Redundant bp.Display.SpawnRandomRotation value' },
            { bp.Display.PlaceholderMeshName,                   'Redundant bp.Display.PlaceholderMeshName value' },
            { bp.CategoriesHash.OVERLAYANTIAIR,                 'Redundant cat OVERLAYANTIAIR' },
            { bp.CategoriesHash.OVERLAYANTINAVY,                'Redundant cat OVERLAYANTINAVY' },
            { bp.CategoriesHash.OVERLAYDEFENSE,                 'Redundant cat OVERLAYDEFENSE' },
            { bp.CategoriesHash.OVERLAYDIRECTFIRE,              'Redundant cat OVERLAYDIRECTFIRE' },
            { bp.CategoriesHash.OVERLAYINDIRECTFIRE,            'Redundant cat OVERLAYINDIRECTFIRE' },
            { arrayFindSub(bp.Categories, 1, 7, 'PRODUCT'),     'Probably redundant PRODUCT cat' },
            { bp.UseOOBTestZoom,                                'Redundant UseOOBTestZoom value' },
            { bp.General.Category,                              'Redundant bp.General.Category value' },
            { bp.General.Classification,                        'Redundant bp.General.Classification value' },
            { bp.General.TechLevel,                             'Redundant bp.General.TechLevel value' },
            { bp.General.UnitWeight,                            'Redundant bp.General.UnitWeight value' },
        }

        for i, check in ipairs(pedantry) do
            if check[1] then
                table.insert(issues, check[2])
            end
        end
    end

    if #issues > 0 then
        print('    '..bp.id..' has the following issues:')
        for i, str in ipairs(issues) do
            print('      '..str)
        end
    end
end

local miscData = {
    LODs = {},
}

function MiscLogs(bp)
    if bp.WikiPage and bp.Display.Mesh.LODs then
        miscData.LODs[#bp.Display.Mesh.LODs] = (miscData.LODs[#bp.Display.Mesh.LODs] or 0) + 1
        for i, lod in ipairs(bp.Display.Mesh.LODs) do
            miscData.lowest = miscData.lowest and math.min(lod.LODCutoff, miscData.lowest) or lod.LODCutoff
            miscData.highest = miscData.highest and math.max(lod.LODCutoff, miscData.highest) or lod.LODCutoff
        end
    end
end

function printMiscData()
    for i, v in sortedpairs(miscData) do
        print(i, v)
        --print("LODs", 'No. Units')
        if type(v) == 'table' then
            for j, k in ipairs(v) do
                print(j, k)
            end
        end
    end
end
