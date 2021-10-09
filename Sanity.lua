--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
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
    if not Sanity.BlueprintChecks or not isValidBlueprint(bp) then
        return
    end

    local issues = {}

    do -- Tech category, strategic icon tech level, transport class
        local t1, t2, t3, t4 = arrayfind(bp.Categories, 'TECH1'), arrayfind(bp.Categories, 'TECH2'), arrayfind(bp.Categories, 'TECH3'), arrayfind(bp.Categories, 'EXPERIMENTAL')
        if BinaryCounter(t1, t2, t3, t4) > 1 then
            table.insert(issues, 'Multiple tech level categories')
        elseif t4 then -- Experimental things

            if bp.StrategicIconName ~= 'icon_experimental_generic' then
                table.insert(issues, 'Experimental without \'icon_experimental_generic\'')
            end

        else -- Tech 1-3
            local t = t1 and 1 or t2 and 2 or t3 and 3

            if t and bp.StrategicIconName and not string.find(bp.StrategicIconName, tostring(t)) and not arraySubfind(bp.Categories, 'WALL') then
                table.insert(issues, 'Tech '..t..' with strategic icon '..bp.StrategicIconName)
            end

            if t and bp.Physics.MotionType ~= 'RULEUMT_None'
            and (bp.General.CommandCaps and bp.General.CommandCaps.RULEUCC_CallTransport)
            and not arrayfind(bp.Categories, 'CANNOTUSEAIRSTAGING')
            and (bp.Transport and bp.Transport.TransportClass or 1) ~= t then
                table.insert(issues, 'Tech '..t..' with transport class '..(bp.Transport and bp.Transport.TransportClass or 1))
            end

            local builtby = arrayfindSub(bp.Categories, 1, 7, 'BUILTBY')
            if builtby then

                for i = 1, 3 do
                    local builtI = string.gsub(builtby, '%d', i)
                    if arrayfind(bp.Categories, builtI) then
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

    do -- bp.General.Icon sanitisation
        local currenticon = (bp.General.Icon or 'land')
        local factoryicon
        local physicaicon

        if bp.Physics.MotionType == 'RULEUMT_None' then
            local blc = bp.Physics.BuildOnLayerCaps
            local BLwater = blc and (blc.LAYER_Water or blc.LAYER_Sub or blc.LAYER_Seabed) and 'sea'
            local BLland = (blc and blc.LAYER_Land or not blc) and 'land'

            local BLbin = BinaryCounter(BLland, BLwater)

            physicaicon = (BLbin == 1) and (BLland or BLwater) or 'amph'
        else
            physicaicon = IconMotionTypes[bp.Physics.MotionType].Icon
        end

        if arrayfind(bp.Categories, 'FACTORY') then
            local Cair = arrayfind(bp.Categories, 'AIR') and 'air'
            local Cland = arrayfind(bp.Categories, 'LAND') and 'land'
            local Cnaval = arrayfind(bp.Categories, 'NAVAL') and 'sea'

            local Cbin = BinaryCounter(Cair, Cland, Cnaval)

            factoryicon = (Cbin == 1) and (Cair or Cnaval or (Cland and physicaicon) ) or (Cbin ~= 0) and 'amph'
        end

        if currenticon ~= (factoryicon or physicaicon) then
            table.insert(issues, 'Icon background is '..currenticon..', should be '..(factoryicon or physicaicon))
        end
    end

    do -- Veteran stuff
        if tableSafe(bp.Buffs,'Regen','Level1') and tableSafe(bp.Veteran,'Level1') then
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
            and not arrayfind(bp.Bones, 'AttachPoint')
            then
                table.insert(issues, "Mesh has no valid transport attach bone.")
            end
        end
    end

    if Sanity.BlueprintPedanticChecks then
        local pedantry = {
            { bp.Interface,                                     'Redundant bp.Interface table' },
            { bp.Physics.MotionType ~= 'RULEUMT_None' and bp.Physics.BuildOnLayerCaps, 'Redundant bp.Physics.BuildOnLayerCaps table' },
            { bp.Display.SpawnRandomRotation,                   'Redundant bp.Display.SpawnRandomRotation value' },
            { bp.Display.PlaceholderMeshName,                   'Redundant bp.Display.PlaceholderMeshName value' },
            { arrayfind(bp.Categories, 'OVERLAYANTIAIR'),       'Redundant cat OVERLAYANTIAIR' },
            { arrayfind(bp.Categories, 'OVERLAYANTINAVY'),      'Redundant cat OVERLAYANTINAVY' },
            { arrayfind(bp.Categories, 'OVERLAYDEFENSE'),       'Redundant cat OVERLAYDEFENSE' },
            { arrayfind(bp.Categories, 'OVERLAYDIRECTFIRE'),    'Redundant cat OVERLAYDIRECTFIRE' },
            { arrayfind(bp.Categories, 'OVERLAYINDIRECTFIRE'),  'Redundant cat OVERLAYINDIRECTFIRE' },
            { arrayfindSub(bp.Categories, 1, 7, 'PRODUCT'),     'Probably redundant PRODUCT cat' },
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
        print(bp.id..' has the following issues:')
        for i, str in ipairs(issues) do
            print('    '..str)
        end
    end
end
