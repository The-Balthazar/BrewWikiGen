local UsedProjectiles = {}

function GetProjectilePageLink(projid, unitbp)
    local projbp = getProj(projid)
    if projbp then
        UsedProjectiles[projbp.id] = UsedProjectiles[projbp.id] or {bp=projbp, users={}}
        UsedProjectiles[projbp.id].users[unitbp.id] = unitbp

        return WikiOptions.GenerateProjectilesPage and xml:a{href='Projectiles#'..stringSanitiseFilename(projbp.ID,1,1)}(xml:code(projShortId(projid))) or projShortId(projid)
    elseif projid then
        return "<error: can't find projectile: "..projid..">"..xml:code(projShortId(projid))
    end
end

local UsedShortProjIds = {}

local function projUsersList(users)
    local text = ''
    for id, bp in sortedpairs(users) do
        text = text..xml:a{href=bp.ID}(xml:code(bp.id))..'<br />'
    end
    return text.."\n"
end

local function projIcon(bp)
    local icon = 'icons/projectiles/'
    if bp.StrategicIconName then
        return icon..bp.StrategicIconName:match'([^/]+%.)[%a]+'..'png'
    --bp.Display.StrategicIconName appears to not be used
    elseif bp.Display.StrategicIconSize and bp.Display.StrategicIconSize ~= 0 then
        return icon..bp.Display.StrategicIconSize..'.png'
    end
end

function GenerateProjectilePage()
    local text = ''
    for projid, data in sortedpairs(UsedProjectiles) do
        local bp = data.bp
        printif(UsedShortProjIds[bp.ID], 'Warning: Duplicate projectile header name', bp.ID)
        UsedShortProjIds[bp.ID] = true
        local idlen = projid:len()
        local icon = projIcon(bp)
        text = text..MDHead(bp.ID)
        ..tostring(Infobox{
            Style = 'detail-left',
            Header = {'[Show] '..(bp.Description or (bp.Interface.HelpText ~= 0 and bp.Interface.HelpText) or bp.General.Weapon or bp.General.Category or '')},
            Data = {
                { 'Icon:', icon and xml:img{src=OutputAsset(icon)}},
                { 'ID:', xml:code{title=projid}(projid:sub(1,20)..(idlen>20 and'...'or'')), idlen>20 and projid},
                { 'Source:', bp.ModInfo.name },
                { 'Users:', projUsersList(data.users) },
                {''},
                {'Health:', bp.Defense.Health},
                {'Categories:', bp.Categories and stringConcatLB(bp.Categories, xml:code{},1)},
                {'Cost:',
                    InfoboxFlagsList{
                        bp.Economy.BuildCostEnergy and iconText('Energy', bp.Economy.BuildCostEnergy) ,
                        bp.Economy.BuildCostMass and iconText('Mass', bp.Economy.BuildCostMass),
                        bp.Economy.BuildTime and iconText('Time', bp.Economy.BuildTime),
                    }
                },
                {'Acceleration:', bp.Physics.Acceleration~=0 and bp.Physics.Acceleration},
                {'Max speed:', bp.Physics.MaxSpeed~=0 and bp.Physics.MaxSpeed},
                {'Turn rate:', bp.Physics.TurnRate~=0 and bp.Physics.TurnRate},
                {'Flags:',
                    InfoboxFlagsList{
                        bp.Physics.DestroyOnWater and 'Destroy on water',
                        bp.Physics.LeadTarget and 'Lead target',
                        bp.Physics.TrackTarget and 'Track target',
                        bp.Physics.TrackTargetGround and 'Track target ground',
                        bp.Physics.StayUnderwater and 'Stay underwater',
                        bp.Physics.CollideFriendlyShield and 'Collide friendly shields',
                    }
                },
            }
        })
    end
    UpdateGeneratedPartOfPage('Projectiles.md', 'brewwikiprojectileslead', "\nA list of all projectiles used by the weapons of units in this wiki.\n\n")
    UpdateGeneratedPartOfPage('Projectiles.md', 'brewwikiprojectiles', text)
    LogFullProjectileBp()
end

function LogFullProjectileBp()
    if not Info.ProjectileBlueprintCounts then return end
    local vals = {}
    for id, bp in pairs(all_blueprints.Projectile) do
        for section, group in pairs(bp) do
            if section ~= 'ID'
            and section ~= 'id'
            and section ~= 'ModInfo'
            and section ~= 'Source'
            and section ~= 'SourceFolder'
            and section ~= 'SourceFileBlueprintCount'
            then
                vals[section] = vals[section] or {}
                if type(group) == 'table' then
                    for k, v in pairs(group) do
                        if type(v) ~= 'table' then
                            vals[section][k] = vals[section][k] or {}
                            vals[section][k][v] = (vals[section][k][v] or 0)+1
                            --table.insert(vals[section][k], v)
                        end
                    end
                else
                    vals[section][group] = (vals[section][group] or 0)+1
                    --table.insert(vals[section], group)
                end
            end
        end
    end
    print('proj {')
    for section, group in sortedpairs(vals) do
        if type(group) == 'table' then
            print('',section, '= {')
            for k, v in sortedpairs(group) do
                if type(v) == 'table' then
                    print('','',k,'= {')
                    for k2, v2 in pairs(v) do
                        print('','','',k2,v2)
                    end
                    print('','','},')
                else
                    print('','',k,v)
                end
            end
        else
            print('',section,group)
        end
        print('','},')
    end
    print('},')
end
