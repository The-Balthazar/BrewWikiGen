--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

local GetWeaponTargetLayers = function(weapon, unit)
    local fromLayers = motionTypes[unit.Physics.MotionType][2]
    local targetLayers = {}
    if weapon.FireTargetLayerCapsTable then
        for layer, targetstring in pairs(weapon.FireTargetLayerCapsTable) do
            if fromLayers[layer] then
                --Reusing the layer reference here, because we don't need the other one again.
                for layer, bit in pairs(LayerBits) do
                    if string.find(targetstring, layer) then
                        targetLayers[layer] = bit
                    end
                end
            end
        end
    end
    if weapon.AboveWaterTargetsOnly then
        targetLayers.Sub = nil
        targetLayers.Seabed = nil
    end
    return targetLayers, tableSum(targetLayers)
end

local GetWeaponTargets = function(weapon, unit)
    if IsDeathWeapon(weapon) then return end

    if weapon.TargetType == 'RULEWTT_Projectile' then
        local s = '<code>RULEWTT_Projectile</code>'
        local mapping = {
            {'STRATEGIC', '(Anti-strategic)'},
            { 'TACTICAL', '(Anti-tactical)'},
            {  'MISSILE', '(Anti-missile)'},
            {  'TORPEDO', '(Anti-torpedo)'},
        }
        for i, cats in ipairs(mapping) do
            if (weapon.TargetRestrictOnlyAllow == cats[1] or string.find(weapon.TargetRestrictOnlyAllow, cats[1])) then
                return s..xml:br()..cats[2]
            end
        end
        return s

    elseif weapon.TargetType == 'RULEWTT_Prop' then
        return xml:code('RULEWTT_Prop')..'<error:prop weapon;its a real thing but why>'

    else --'RULEWTT_Unit' is the default and generally not written
        local s = xml:code('RULEWTT_Unit')

        if weapon.TargetRestrictOnlyAllow and (weapon.TargetRestrictOnlyAllow == 'AIR' --[[or string.find(weapon.TargetRestrictOnlyAllow, 'AIR')]]) then
            return s..xml:br()..'(Anti-Air)'
        end

        local targetLayers, bitwiselayers = GetWeaponTargetLayers(weapon, unit)

        if bitwiselayers == 0 then
            return 'Untargeted'
        end

        --Note seabed and sub have been filtered out of 'above water target only' weapons
        local bitmap = {
            [1] = 'Anti-Land',  --land
            [2] = 'Anti-Seabed',  --seabed
            [3] = 'Anti-Terrain', --land seabed
            [4] = 'Anti-Submarine',  --sub
            [5] = 'Anti-Land &amp; Sub', --land and sub
            [6] = 'Anti-Underwater',  --seabed sub
            [7] = 'Anti-Land &amp; Underwater', --land seabed sub
            [8] = 'Anti-Ship',  -- water
            [9] = 'Anti-Surface',  --land water
            [10] = 'Anti-Ship &amp; Seabed', --seabed water
            [11] = 'Anti-Ship, Seabed, &amp; Land',--seabed water land
            [12] = 'Anti-Ship &amp; Sub', --water sub
            [13] = 'Anti-Surface &amp; Sub', --water sub land
            [14] = 'Anti-Naval', --water sub seabed
            [15] = 'Anti-Land &amp; Naval', --water sub seabed land
            [16] = 'Anti-Air',
            --[17] = 'error:something with air',
        }

        local lowAltAir

        if bitwiselayers >= 16 and (weapon.TargetRestrictDisallow and string.find(weapon.TargetRestrictDisallow, 'HIGHALTAIR')) then
            lowAltAir = 'Low-Altidude Anti-Air'
            bitwiselayers = bitwiselayers - 16
        end

        if bitwiselayers > 16 then
            return s..'<error:Weapon hits high alt air and other stuff>'
        end

        return s..'<br />('..(bitmap[bitwiselayers] and bitmap[bitwiselayers]..(lowAltAir and ', '..lowAltAir or '') or lowAltAir)..')'

    end
end

local WepProjectiles = function(weapon)
    if not weapon.RackBones then return end
    local ProjectileCount
    if weapon.MuzzleSalvoDelay == 0 then
        ProjectileCount = math.max(1, #(weapon.RackBones[1].MuzzleBones or {'boop'} ) )
    else
        ProjectileCount = (weapon.MuzzleSalvoSize or 1)
    end
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * math.max(1, #(weapon.RackBones or {'boop'} ) )
    end
    return ProjectileCount
end

local GetDamageInstances = function(wep)
    local s = WepProjectiles(wep)
    if s and s > 1 then
        if wep.BeamCollisionDelay then
            s = tostring(s)..' beams'
        else
            s = tostring(s)..' projectiles'
        end
    else
        s = ''
    end
    local dot = wep.DoTPulses
    if dot and dot > 1 then
        if s ~= '' then
            s = s..'<br />'
        end
        s = s..dot.. ' DoT pulses'
    end
    if (wep.BeamLifetime and wep.BeamLifetime > 0) and wep.BeamCollisionDelay then
        if s ~= '' then
            s = s..'<br />'
        end
        s = math.ceil( (wep.BeamLifetime or 1) / (wep.BeamCollisionDelay + 0.1) )..' beam collisions'
    end
    if s == '' then s = nil end
    return s
end

local GetFiringCycle = function(wep)
    if IsDeathWeapon(wep) then
        return
    end
    if wep.RateOfFire and not (wep.BeamLifetime == 0 and wep.BeamCollisionDelay) then
        return ('Once every '..tostring(math.floor(10 / wep.RateOfFire + 0.5)/10)..'s' ), "Note: This doesn't count additional delays such as charging, reloading, and others."
    elseif (wep.BeamLifetime == 0 and wep.BeamCollisionDelay) then
        return ('Continuous beam<br />Once every '..((wep.BeamCollisionDelay or 0) + 0.1)..'s'), 'How often damage instances occur.'
    end
end

local GetWeaponBuffs = function(wep)
    if wep.Buffs then
        local buffs = ''
        for i, buff in ipairs(wep.Buffs) do
            if buff.BuffType then
                if buffs ~= '' then
                    buffs = buffs..'<br />'
                end
                buffs = buffs..'<code>'..buff.BuffType..'</code>'
            end
        end
        if buffs == '' then return end
        return buffs
    end
end

local DPSEstimate = function(weapon)
    -- Dont do death weapons, or weapons without RoF
    if IsDeathWeapon(weapon)
    or not weapon.RateOfFire
    or not (weapon.TargetType == 'RULEWTT_Unit' or not weapon.TargetType) then -- Undefined is 'Unit'
        return
    end

    local damage = (weapon.NukeInnerRingDamage or weapon.Damage)
    * (WepProjectiles(weapon) or 1)
    * math.max(weapon.DoTPulses or 1, 1)

    if (weapon.BeamLifetime and weapon.BeamLifetime > 0) and weapon.BeamCollisionDelay then
        damage = damage * math.ceil( (weapon.BeamLifetime or 1) / (weapon.BeamCollisionDelay + 0.1) )
    end

    --NeedToComputeBombDrop -- ROF isn't important to bombers

    local rof

    if weapon.RateOfFire and not (weapon.BeamLifetime == 0 and weapon.BeamCollisionDelay) then
        rof = 1 / (math.floor(10 / weapon.RateOfFire + 0.5)/10)

        local chargeRof = 10
        if weapon.EnergyRequired and weapon.EnergyDrainPerSecond then
            chargeRof = 1 / (math.floor((weapon.EnergyRequired / weapon.EnergyDrainPerSecond) * 10)/10)
        end
        rof = math.min(rof, chargeRof, 10)
    end

    if (weapon.BeamLifetime == 0 and weapon.BeamCollisionDelay) then
        rof = 1 / ((weapon.BeamCollisionDelay or 0) + 0.1)
    end

    return math.floor(damage * rof + 0.5)
end

local ArcTable = function(spec)
    return setmetatable(spec, {

        __tostring = function(self)
            if arrayAllCellsEqual(self) then
                if self[1] and self[1] ~= 0 and self[1] < 180 then
                    return self[1]+self[1]..'°'
                else
                    return ''
                end
            end
            local s = ''
            for i, v in ipairs(self) do
                if s ~= '' then
                    s = s..', '
                end
                if type(v) == 'number' then
                    s = s..v+v..'°'
                else
                    s = s..'false <error:unturreted weapon or non-number yaw>'
                end
            end
            return s
        end,

        __eq = function()
            return true
        end,

    })
end

--------------------------------------------------------------------------------

GetWeaponInfoboxData = function(wep, bp)
    return {
        {'Target type:', GetWeaponTargets(wep, bp)},
        {'DPS estimate:', NewDPSEstimate(wep), "Note: This only counts listed stats."},
        {
            'Damage:',
            (wep.NukeInnerRingDamage or wep.Damage),
            ( not (IsDeathWeapon(wep) and not wep.FireOnDeath) and "Note: This doesn't count additional scripted effects, such as splintering projectiles, and variable scripted damage.")
        },
        {'Damage to shields:', (wep.DamageToShields or wep.ShieldDamage)},
        {'Damage radius:', (wep.NukeInnerRingRadius or wep.DamageRadius)},
        {'Outer damage:', wep.NukeOuterRingDamage},
        {'Outer radius:', wep.NukeOuterRingRadius},
        {'Damage instances:', GetDamageInstances(wep)},
        {'Damage type:', wep.DamageType and '<code>'..wep.DamageType..'</code>'},
        {'Max range:', not IsDeathWeapon(wep) and wep.MaxRadius},
        {'Min range:', wep.MinRadius},
        {'Firing arc:', ArcTable{wep.Turreted and wep.TurretYawRange}},
        {'Firing cycle:', GetFiringCycle(wep)},
        {'Firing cost:',
            iconText(
                'Energy',
                wep.EnergyRequired and wep.EnergyRequired ~= 0 and
                (
                    wep.EnergyRequired ..
                    (wep.EnergyDrainPerSecond and ' ('..wep.EnergyDrainPerSecond..'/s for '..(math.ceil((wep.EnergyRequired/wep.EnergyDrainPerSecond)*10)/10)..'s)' or '')
                )
            )
        },
        {'Flags:',
            InfoboxFlagsList{
                (wep.ArtilleryShieldBlocks and 'Artillery shield blocks' or ''),
                --(wep.PrefersPrimaryWeaponTarget and 'Prefers primary target' or ''),
                --(wep.NotExclusive and 'Not exclusive' or ''),
                (wep.CollideFriendly and 'Collide friendly' or ''),
                (wep.DamageFriendly and 'Damage friendly' or ''),
            }
        },
        {'Projectile storage:', (wep.MaxProjectileStorage and (wep.InitialProjectileStorage or 0)..'/'..(wep.MaxProjectileStorage) )},
        {'Buffs:', GetWeaponBuffs(wep)},
    }
end

GetWeaponBodytextSectionString = function(bp)
    local compiledWeaponsTable = {}

    for i, wep in ipairs(bp.Weapon) do
        weapontable = GetWeaponInfoboxData(wep, bp)

        local CWTn = #compiledWeaponsTable
        if compiledWeaponsTable[1] and arrayEqual(compiledWeaponsTable[CWTn][3], weapontable) then
            compiledWeaponsTable[CWTn][2] = compiledWeaponsTable[CWTn][2] + 1
            DoToInfoboxDataCell(table.insert, compiledWeaponsTable[CWTn][3], 'Firing arc:', wep.Turreted and wep.TurretYawRange)
        else
            table.insert(compiledWeaponsTable, {(wep.DisplayName or wep.Label or '<i>Dummy Weapon</i>'), 1, weapontable})
        end
    end

    local text = ''
    for i, wepdata in ipairs(compiledWeaponsTable) do
        local weapontable = wepdata[3]

        if wepdata[2] ~= 1 then
            table.insert(weapontable, 1, {'', 'Note: Stats are per instance of the weapon.'} )
        end

        text = text .. tostring(Infobox{
            Style = 'detail-left',
            Header = { wepdata[1]..(wepdata[2] == 1 and '' or ' (×'..tostring(wepdata[2])..')') },
            Data = weapontable
        })
    end
    return text
end

--------------------------------------------------------------------------------
-- Weapon validation
--------------------------------------------------------------------------------
local function NumMuzzles(weapon)
        --Calculation only used for error checking
        local muzzles = 0
        for rk, rv in ipairs(weapon.RackBones) do
            muzzles = muzzles + (#rv.MuzzleBones or 0)
        end
        return muzzles / #weapon.RackBones
    end
local function TotalMuzzleFiringTime(weapon)
        return (NumMuzzles(weapon) - 1) * weapon.MuzzleSalvoDelay
    end
local function TotalFiringTimePossible(weapon)
        return not (TotalMuzzleFiringTime(weapon) > (1 / weapon.RateOfFire))
    end
local function weaponHasBasicValues(weapon)
        return weapon.RackBones and weapon.MuzzleSalvoSize and weapon.MuzzleSalvoDelay
    end
local function recoilAnimatorsPossible(weapon)
        return not (weapon.RackRecoilDistance ~= 0 and weapon.MuzzleSalvoDelay ~= 0)
    end
-- Weapon types ----------------------------------------------------------------
local function IsDefaultWeapon(weapon)
        return weaponHasBasicValues(weapon) and TotalFiringTimePossible(weapon) and recoilAnimatorsPossible(weapon)
    end
local function IsBeamWeapon(weapon)
        return weapon.BeamCollisionDelay and weapon.BeamLifetime and IsDefaultWeapon(weapon)
    end
local function IsContinuousBeam(weapon)
        return IsBeamWeapon(weapon) and weapon.BeamLifetime == 0
    end
function IsDeathWeapon(weapon)
        return (weapon.Label == 'DeathWeapon' or weapon.Label == 'DeathImpact' or weapon.WeaponCategory == 'Death')
    end
-- Weapon stats ----------------------------------------------------------------
local function weaponDamage(weapon)
        return (weapon.NukeInnerRingDamage or weapon.Damage)
    end
--[[local function weaponTotalDamage(weapon)
        return weaponDamage(weapon)
    end]]
local function BeamCollisionsPerSecond(weapon)
        return 1 / (weapon.BeamCollisionDelay + 0.1)
    end
local function BeamMaxTheoreticalDPS(weapon)
        return weaponDamage(weapon) * BeamCollisionsPerSecond(weapon) * #(tableSafe(weapon,1,Rackbones,1,MuzzleBones) or {true})
    end
--------------------------------------------------------------------------------
function NewDPSEstimate(weapon)
    if IsBeamWeapon(weapon) then
        local max = BeamMaxTheoreticalDPS(weapon)
        if IsContinuousBeam(weapon) then
            if max and max > 1 then
                return math.floor(max + 0.5)
            end
        else
            local dps = DPSEstimate(weapon)
            if dps and max and dps > max then
                return '<error:estimate exceeds max theoretically possible>Less than '..max
            else
                return dps
            end
        end
    elseif IsDefaultWeapon(weapon) then
        return DPSEstimate(weapon)
    end
end
