--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
local Language
local LocalizedStrings = {}

local function LoadLocalizationFile(FileLocation)
    local good, loc = pcall(GetSandboxedLuaFile, FileLocation)
    if good then
        for k, v in pairs(loc) do
            LocalizedStrings[k] = v
        end
    end
end

function LoadModLocalization(ModDirectory)
    LoadLocalizationFile(ModDirectory..'hook/loc/'..Language..'/strings_db.lua')
end

function SetWikiLocalization(WikiDirectory, lang)
    Language = lang
    LoadLocalizationFile(WikiDirectory..'Environment/loc/'..Language..'.lua')
end

function LOC(s)
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

function noLOC(s)
    return string.gsub(s, '%b<>', '')
end
