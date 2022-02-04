--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local Language
local LocalizedStrings = {}

local function LoadLocalizationFile(FileLocation)
    local good, loc = pcall(GetSandboxedLuaFile, FileLocation)
    if good then
        if Logging.LocalisationLoaded then print("  Preloading LOC "..FileLocation) end
        for k, v in pairs(loc) do
            LocalizedStrings[k] = v
        end
    elseif Logging.LocalisationLoaded then print("  Failed to preload LOC "..FileLocation) end
end

function LoadLocalization(ModDirectory)
    LoadLocalizationFile(ModDirectory..'loc/'..Language..'/strings_db.lua')
end

function LoadModLocalization(ModDirectory)
    LoadLocalization(ModDirectory..'hook/')
end

function SetWikiLocalization(WikiDirectory, lang)
    Language = lang
    LoadLocalizationFile(WikiDirectory..'Environment/loc/'..Language..'.lua')
end

function LOC(s) return s and (LocalizedStrings[string.match(s, '<LOC ([^>.]*)>')] or noLOC(s)) end
function noLOC(s) return string.gsub(s, '<LOC [^>.]*>', '') end

function LOCBrackets(s) return s and string.format(LOC'<LOC wiki_bracket_text> (%s)', s) end
function LOCPerSec(s) return s and string.format(LOC'<LOC wiki_per_second>%s/s', numberFormatNoTrailingZeros(s)) end
function LOCPlusPerSec(s) return s and string.format(LOC'<LOC wiki_plus_per_second>+%s/s', numberFormatNoTrailingZeros(s)) end
