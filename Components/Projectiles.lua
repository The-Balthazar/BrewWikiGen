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

function GenerateProjectilePage()
    local text = ''
    for projid, data in sortedpairs(UsedProjectiles) do
        local bp = data.bp
        printif(UsedShortProjIds[bp.ID], 'Warning: Duplicate projectile header name', bp.ID)
        UsedShortProjIds[bp.ID] = true
        local idlen = projid:len()
        text = text..MDHead(bp.ID)
        ..tostring(Infobox{
            Style = 'detail-left',
            Header = {'[Show] '..(bp.Description or (bp.Interface.HelpText ~= 0 and bp.Interface.HelpText) or bp.General.Weapon or bp.General.Category or '')},
            Data = {
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
                {'Flags:',
                    InfoboxFlagsList{
                        bp.Physics.DestroyOnWater and 'Destroy on water',
                        bp.Physics.LeadTarget and 'Lead target',
                        bp.Physics.TrackTarget and 'Track target'
                    }
                },
            }
        })


    end
    UpdateGeneratedPartOfPage('Projectiles.md', 'brewwikiprojectileslead', "\nA list of all projectiles used by the weapons of units in this wiki.\n\n")
    UpdateGeneratedPartOfPage('Projectiles.md', 'brewwikiprojectiles', text)
end
