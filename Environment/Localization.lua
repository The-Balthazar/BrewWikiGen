--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local Language = 'US'--As an Englishman this offends me but that's what is in the game

local LocalizedStrings = {}

function SetModLocalization(ModDirectory)
    local good, loc = pcall(GetSandboxedLuaFile, ModDirectory..'hook/loc/'..Language..'/strings_db.lua')
    if good then
        for k, v in pairs(loc) do
            LocalizedStrings[k] = v
        end
    end
end

function SetWikiLocalization()

end

function LOC(s)
    --Lua regex could allow for '%b<>'
    if type(s) == 'string' and string.sub(s, 1, 4) == '<LOC' then
        local i = string.find(s,">")
        local locK = string.sub(s, 6, i-1)
        if LocalizedStrings[locK] then
            return LocalizedStrings[locK]
        else
            return string.sub(s, i+1)
        end
    end
    return s
end