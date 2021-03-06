--------------------------------------------------------------------------------
-- Supreme Commander mod threat calculator
-- Copyright 2018-2022 Sean 'Balthazar' Wheeldon                       Lua 5.4.2
--------------------------------------------------------------------------------
-- Note this is largely unchanged from https://github.com/The-Balthazar/BrewLAN/blob/806a689792fa14e071ed679ee37b3e34d55ecbbf/mods/BrewLAN_Plenae/Logger/hook/lua/system/Blueprints.lua#L345

local function CalculatedDamage(weapon)
    local ProjectileCount = math.max(1, #(weapon.RackBones[1].MuzzleBones or {}), weapon.MuzzleSalvoSize or 1 )
    if weapon.RackFireTogether then
        ProjectileCount = ProjectileCount * math.max(1, #(weapon.RackBones or {}) )
    end
    return ((weapon.Damage or 0) + (weapon.NukeInnerRingDamage or 0)) * ProjectileCount * (weapon.DoTPulses or 1)
end

local function HasCat(bp, cat) return bp.CategoriesHash[cat] or not bp.CategoriesHash and table.find(bp.Categories, cat) end

local function ShouldWeCalculateBuildRate(bp)
    if not bp.Economy.BuildRate or table.find(bp.Categories, 'WALL') then return end
    local TrueCats = {
        'FACTORY',
        'ENGINEER',
        'FIELDENGINEER',
        'CONSTRUCTION',
        'ENGINEERSTATION',
    }
    for i, v in ipairs(TrueCats) do
        if HasCat(bp, v) then
            return true
        end
    end

    return not (bp.General.UpgradesTo and table.find(bp.Economy.BuildableCategory or {}, bp.General.UpgradesTo)) and not (bp.Economy.BuildableCategory or {})[2]
end

local function ShieldRadius(bp) return math.max((bp.Defense.Shield.ShieldSize--[[diameter]] or 0)/2, bp.Defense.Shield.ShieldProjectionRadius or 0) end
local function IsPersonalShield(bp) return bp.Defense.Shield.PersonalShield or not HasCat(bp, 'TRANSPORT') and (ShieldRadius(bp) < math.max(bp.SizeX or 1, bp.SizeZ or 1) + 3) end
local function PersonalShieldThreat(bp) return IsPersonalShield(bp) and (shield.ShieldMaxHealth or 0) * 0.01 or 0 end
local function ShieldArea(bp) local rad=ShieldRadius(bp) return rad*rad*math.pi end
local function SkirtArea(bp) return (bp.Physics.SkirtSizeX or 3) * (bp.Physics.SkirtSizeY or 3) end
local function ShieldThreat(bp) return not IsPersonalShield(bp) and ((ShieldArea(bp)-SkirtArea(bp)) * (bp.Defense.Shield.ShieldMaxHealth or 0) * (bp.Defense.Shield.ShieldRegenRate or 1))/250000000 or 0 end
local function SpecialThreat(bp) return (HasCat(bp, 'SPECIALHIGHPRI') and 250 or 0) end
local function DockingThreat(bp) return (bp.Transport.DockingSlots or 0) end

function CalculateUnitThreatValues(bp)

    local ThreatData = {
        AirThreatLevel = 0,
        EconomyThreatLevel = ShieldThreat(bp) + SpecialThreat(bp) + DockingThreat(bp),
        SubThreatLevel = 0,
        SurfaceThreatLevel = 0,
        --These are temporary to be merged into the others after calculations
        HealthThreat = (bp.Defense.MaxHealth or 0) * 0.01,
        PersonalShieldThreat = PersonalShieldThreat(bp),
        UnknownWeaponThreat = 0,
    }
    local Warnings

    --Define eco production values
    if bp.Economy.ProductionPerSecondMass then
        --Mass prod + 5% of health
        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.ProductionPerSecondMass * 10 + (ThreatData.HealthThreat + ThreatData.PersonalShieldThreat) * 5
    end
    if bp.Economy.ProductionPerSecondEnergy then
        --Energy prod + 1% of health
        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.ProductionPerSecondEnergy * 0.1 + ThreatData.HealthThreat + ThreatData.PersonalShieldThreat
    end
    --0 off the personal health values if we alreaady used them
    if bp.Economy.ProductionPerSecondMass or bp.Economy.ProductionPerSecondEnergy then
        ThreatData.HealthThreat = 0
        ThreatData.PersonalShieldThreat = 0
    end

    --Calculate for build rates, ignore things that only upgrade
    if ShouldWeCalculateBuildRate(bp) then
        --non-mass producing energy production units that can build get off easy on the health calculation. Engineering reactor, we're looking at you
        if bp.Physics.MotionType == 'RULEUMT_None' then
            ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.BuildRate * 1 / (bp.Economy.BuilderDiscountMult or 1) * 2 + (ThreatData.HealthThreat + ThreatData.PersonalShieldThreat) * 2
        else
            ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.BuildRate  + (ThreatData.HealthThreat + ThreatData.PersonalShieldThreat) * 3
        end
        --0 off the personal health values if we alreaady used them
        ThreatData.HealthThreat = 0
        ThreatData.PersonalShieldThreat = 0
    end

    --Calculate for storage values.
    if bp.Economy.StorageMass then
        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.StorageMass * 0.001 + ThreatData.HealthThreat + ThreatData.PersonalShieldThreat
    end
    if bp.Economy.StorageEnergy then
        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + bp.Economy.StorageEnergy * 0.001 + ThreatData.HealthThreat + ThreatData.PersonalShieldThreat
    end
    --0 off the personal health values if we alreaady used them
    if bp.Economy.StorageMass or bp.Economy.StorageEnergy then
        ThreatData.HealthThreat = 0
        ThreatData.PersonalShieldThreat = 0
    end

    --Wepins
    if bp.Weapon then
        for i, weapon in ipairs(bp.Weapon) do
            if not weapon.EnabledByEnhancement then
                if weapon.RangeCategory == 'UWRC_AntiAir' or weapon.TargetRestrictOnlyAllow == 'AIR' or string.find(weapon.WeaponCategory or '', 'Anti Air') then
                    ThreatData.AirThreatLevel = ThreatData.AirThreatLevel + DPSEstimate(weapon) / 10
                elseif weapon.RangeCategory == 'UWRC_AntiNavy' or string.find(weapon.WeaponCategory or '', 'Anti Navy') then
                    if string.find(weapon.WeaponCategory or '', 'Bomb') or string.find(weapon.Label or '', 'Bomb') or weapon.NeedToComputeBombDrop or (bp.Air and bp.Air.Winged) then
                        --print("Bomb drop damage value " .. CalculatedDamage(weapon))
                        ThreatData.SubThreatLevel = ThreatData.SubThreatLevel + CalculatedDamage(weapon) / 100
                    else
                        ThreatData.SubThreatLevel = ThreatData.SubThreatLevel + DPSEstimate(weapon) / 10
                    end
                elseif weapon.RangeCategory == 'UWRC_DirectFire' or string.find(weapon.WeaponCategory or '', 'Direct Fire')
                or weapon.RangeCategory == 'UWRC_IndirectFire' or string.find(weapon.WeaponCategory or '', 'Artillery') then
                    --Range cutoff for artillery being considered eco and surface threat is 100
                    local wepDPS = DPSEstimate(weapon) or CalculatedDamage(weapon)
                    local rangeCutoff = 50
                    local econMult = 1
                    local surfaceMult = 0.1
                    if weapon.MinRadius and weapon.MinRadius >= rangeCutoff then
                        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + wepDPS * econMult
                    elseif weapon.MaxRadius and weapon.MaxRadius <= rangeCutoff then
                        ThreatData.SurfaceThreatLevel = ThreatData.SurfaceThreatLevel + wepDPS * surfaceMult
                    else
                        local distr = (rangeCutoff - (weapon.MinRadius or 0)) / (weapon.MaxRadius - (weapon.MinRadius or 0))
                        ThreatData.EconomyThreatLevel = ThreatData.EconomyThreatLevel + wepDPS * (1 - distr) * econMult
                        ThreatData.SurfaceThreatLevel = ThreatData.SurfaceThreatLevel + wepDPS * distr * surfaceMult
                    end
                elseif weapon.NeedToComputeBombDrop or string.find(weapon.WeaponCategory or '', 'Bomb') or string.find(weapon.Label or '', 'Bomb') then
                    --print("Bomb drop damage value " .. CalculatedDamage(weapon))
                    ThreatData.SurfaceThreatLevel = ThreatData.SurfaceThreatLevel + CalculatedDamage(weapon) / 100
                elseif string.find(weapon.WeaponCategory or '', 'Death') then
                    --print(ThreatData.EconomyThreatLevel, DPSEstimate(weapon) )
                    ThreatData.EconomyThreatLevel = math.floor(ThreatData.EconomyThreatLevel + (DPSEstimate(weapon) or 0) / 200)
                else
                    ThreatData.UnknownWeaponThreat = ThreatData.UnknownWeaponThreat + (DPSEstimate(weapon) or 0)
                    printif(Logging.ThreatCalculationWarnings, " * WARNING: Unknown weapon type on: " .. bp.id .. " with the weapon label: " .. (weapon.Label or "nil") )
                    Warnings = (Warnings or 0) + 1
                end
            end
        end
    end

    --See if it has real threat yet
    local checkthreat = 0
    for k, v in ipairs{ 'AirThreatLevel', 'EconomyThreatLevel', 'SubThreatLevel', 'SurfaceThreatLevel' } do
        checkthreat = checkthreat + ThreatData[v]
    end

    --Last ditch attempt to give it some threat
    if checkthreat < 1 then
        if ThreatData.UnknownWeaponThreat then
            --If we have no idea what it is still, it has threat equal to its unkown weapon DPS.
            ThreatData.EconomyThreatLevel = ThreatData.UnknownWeaponThreat
            ThreatData.UnknownWeaponThreat = 0
        elseif bp.Economy and bp.Economy.MaintenanceConsumptionPerSecondEnergy then
            --If we STILL have no idea what it's threat is, and it uses power, its obviously doing something fucky, so we'll use that.
            ThreatData.EconomyThreatLevel = bp.Economy.MaintenanceConsumptionPerSecondEnergy * 0.0175
        end
    end

    --Get rid of unused threat values
    for i, v in ipairs{'HealthThreat','PersonalShieldThreat', 'UnknownWeaponThreat'} do
        if ThreatData[v] and ThreatData[v] ~= 0 then
            printif(Logging.ThreatCalculationWarnings, "Unused " .. v .. " " .. ThreatData[v])
            ThreatData[v] = nil
        end
    end

    -- Only return different numbers.
    for i, v in pairs(ThreatData) do
        v = math.floor(v+0.5)
        ThreatData[i] = (bp.Defense[i] or 0) ~= v and v or nil
    end

    return ThreatData
end
