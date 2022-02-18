--------------------------------------------------------------------------------
-- Supreme Commander mod unit blueprint file cleanup
-- Copyright 2022 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local eq = '%s*=%s*'
local function st(s) return '[\'"]'..s..'[\'"]' end
local function threatName(s) return string.gsub(s, 'ThreatLevel', '') end

local function GetPrintedBlueprintSectionString(path, section)
    local bpfile = io.open(path)
    local bpstring = bpfile:read('a')
    bpfile:close()
    return string.match(bpstring, '([ ]*'..section..eq..'%b{})')
end

local function GetStringTableKey(sectionString) return string.match(sectionString, '[ ]*(.*)%s*=%s*%b{}') end
local function GetStringTableVal(sectionString) return load('return '..string.match(sectionString, '%b{}'))() end
local function ReadTableString(sectionString) return GetStringTableName(sectionString), GetStringTableVal(sectionString) end

local function ClearStringSectionLine(section, key, value)
    return string.gsub(section, '%s*'..key..eq..value..',', '')
end

local function FindReplaceInFile(path, find, replace)
    local bpfile = io.open(path)
    local bpstring = bpfile:read('a')
    bpfile:close()
    bpstring, replacements = string.gsub(bpstring, find, replace, 1)
    if replacements == 1 then
        bpfile = io.open(path, 'w'):write(bpstring):close()
        return true
    end
end

local function RepaceSectionInFile(path, section, replace)
    return FindReplaceInFile(path, '[ ]*'..section..eq..'%b{}', replace)
end

function CleanupUnitBlueprintFile(bp)
    if not bp.WikiPage then return end
    if bp.SourceFileBlueprintCount ~= 1 then
        return print"Can't cleanup "..bp.Source..", it contains multiple bps. Not implemented."
    else
        do
            local Depracated = {
                General = {
                    {'Category', st'[%a ]*'},
                    {'Classification', st'RULEUC_[%a]*'},
                    {'TechLevel', st'RULEUTL_[%a]*'},
                    {'UnitWeight', '%d'},
                },
                Display = {
                    {'PlaceholderMeshName', st'[%w]*'},
                    {'SpawnRandomRotation', '%a+'},
                },
                Interface = '%b{}',
                UseOOBTestZoom = '%d',
            }
            for section, sectionData in pairs(Depracated) do
                if CleanupOptions['CleanUnitBp'..section] then
                    local sectionString, updatedString, changesMade
                    local msg = 'Removed deprecated '..section..' value'

                    if type(sectionData) == 'table' then
                        sectionString = GetPrintedBlueprintSectionString(bp.Source, section)
                        msg = msg..'s: '

                        for i, v in ipairs(sectionData) do
                            if bp[section][ v[1] ] ~= nil then
                                msg = msg..' '..v[1]
                                updatedString, changesMade = ClearStringSectionLine(updatedString or sectionString, v[1], v[2])
                            end
                        end
                        printif(
                            changesMade and
                            (
                                FindReplaceInFile(bp.Source, sectionString, updatedString) or
                                RepaceSectionInFile(bp.Source, section, updatedString)
                            ),
                            msg..' in '..bp.Source
                        )
                    elseif type(sectionData) == 'string' then
                        printif(
                            FindReplaceInFile(bp.Source, '%s*'..section..eq..sectionData..',', ''),
                            msg..' in '..bp.Source
                        )
                    end
                end
            end
        end
        if CleanupOptions.CleanUnitBpThreat then
            local pass, threat = pcall(CalculateUnitThreatValues, bp)
            if pass and threat then
                local sectionString = GetPrintedBlueprintSectionString(bp.Source, 'Defense')
                local updatedString = sectionString
                local msg = 'Updating threat'
                for threatType, val in pairs(threat) do
                    if type(bp.Defense[threatType]) == 'number' then -- this should probably check an evaluated sectionString instead
                        if val == 0 then
                            updatedString = ClearStringSectionLine(updatedString, threatType, '%d+')
                        else
                            updatedString = string.gsub(updatedString, '([ ]*'..threatType..eq..')%d+', '%1'..val)
                        end
                    else
                        local spacing, otherThreat, eqspacing, otherval = string.match(updatedString, '(%s*)(%a+ThreatLevel)('..eq..')(%d*),')
                        if otherThreat then
                            local other = spacing..otherThreat..eqspacing..otherval..','
                            updatedString = string.gsub(updatedString, other, other..spacing..threatType..eqspacing..val..',', 1)

                        else
                            local theD, spacing = string.match(updatedString, '(Defense'..eq..'{)(%s+)')
                            updatedString = string.gsub(updatedString, theD, theD..spacing..threatType..' = '..val..',', 1)

                        end
                    end
                    msg = msg..' '..threatName(threatType)..' '..tostring(bp.Defense[threatType])..' -> '..val
                end
                if updatedString ~= sectionString then
                    printif(
                        FindReplaceInFile(bp.Source, sectionString, updatedString),
                        msg..' in '..bp.Source
                    )
                end
            end
        end
    end
end
