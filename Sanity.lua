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
    if not DoBlueprintSanityChecks or not isValidBlueprint(bp) then
        return
    end

    local issues = {}

    do
        local t1, t2, t3, t4 = arrayfind(bp.Categories, 'TECH1'), arrayfind(bp.Categories, 'TECH2'), arrayfind(bp.Categories, 'TECH3'), arrayfind(bp.Categories, 'EXPERIMENTAL')
        if BinaryCounter(t1, t2, t3, t4) > 1 then
            table.insert(issues, 'Multiple tech level categories')
        elseif t4 and bp.StrategicIconName ~= 'icon_experimental_generic' then
            table.insert(issues, 'Experimental without \'icon_experimental_generic\'')
        else
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

    if DoBlueprintSanityChecksPedantic then
        if bp.Interface then
            table.insert(issues, 'Redundant bp.Interface table')
        end
        if bp.Physics.MotionType ~= 'RULEUMT_None' and bp.Physics.BuildOnLayerCaps then
            table.insert(issues, 'Redundant bp.Physics.BuildOnLayerCaps table')
        end
        if bp.Display.SpawnRandomRotation then
            table.insert(issues, 'Redundant bp.Display.SpawnRandomRotation value')
        end
        if bp.Display.PlaceholderMeshName then
            table.insert(issues, 'Redundant bp.Display.PlaceholderMeshName value')
        end
        if arrayfind(bp.Categories, 'OVERLAYANTIAIR') then
            table.insert(issues, 'Redundant cat OVERLAYANTIAIR')
        end
        if arrayfind(bp.Categories, 'OVERLAYANTINAVY') then
            table.insert(issues, 'Redundant cat OVERLAYANTINAVY')
        end
        if arrayfind(bp.Categories, 'OVERLAYDEFENSE') then
            table.insert(issues, 'Redundant cat OVERLAYDEFENSE')
        end
        if arrayfind(bp.Categories, 'OVERLAYDIRECTFIRE') then
            table.insert(issues, 'Redundant cat OVERLAYDIRECTFIRE')
        end
        if arrayfind(bp.Categories, 'OVERLAYINDIRECTFIRE') then
            table.insert(issues, 'Redundant cat OVERLAYINDIRECTFIRE')
        end
    end

    if #issues > 0 then
        print(bp.id..' has the following issues:')
        for i, str in ipairs(issues) do
            print('    '..str)
        end
    end
end
