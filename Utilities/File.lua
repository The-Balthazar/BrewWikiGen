--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
function GetSandboxedLuaFile(file, env)
    local env = env or {}
    local chunk = loadfile(file, 'bt', env)
    if chunk then chunk() end
    return env
end

local FileMessages = {}

local function SandboxedPrint(file, logtype)
    return function(...)
        if Logging.SandboxedFileLogs then
            if not FileMessages[file] then
                FileMessages[file] = true
                print('Logs from ', file)
            end
            print('        '..logtype,...)
        end
    end
end

function GetExecutableSandboxedLuaFile(file)
    local env = {
        pairs = pairs,
        ipairs = ipairs,

        print = SandboxedPrint(file, 'Print: '),
        LOG = SandboxedPrint(file, 'Log: '),
        SPEW = SandboxedPrint(file, 'Debug: '),
        _ALERT = SandboxedPrint(file, 'Log: '),
        WARN = SandboxedPrint(file, 'Warn: '),

        table = table,
        string = string,
        math = math,

        type = type,
    }
    env.table.find = arrayFind
    GetSandboxedLuaFile(file, env)
    return env
end

function SafeGetSandboxedLuaFile(file)
    local ok, f = pcall(GetSandboxedLuaFile, file)
    return ok and f or Logging.LuaFileLoadIssues and print("Failed to load "..file)
end

function GetModInfo(dir)
    local modinfo = SafeGetSandboxedLuaFile(dir..'mod_info.lua')
    return assert(modinfo, LogEmoji('⚠️').." Failed to load "..dir.."mod_info.lua")
end

function LoadHelpStrings(dir)
    local log = '  Preloading: '
    for name, data in pairs{
        ['Build descriptions'] = {Path = 'lua/ui/help/unitdescription.lua', Output = 'Description'},
        ['Tooltips']           = {Path = 'lua/ui/help/tooltips.lua',        Output = 'Tooltips'   },
    } do
        local env = GetSandboxedLuaFile(dir..data.Path, {[data.Output]={}})
        tableMergeCopy(_G[data.Output], env[data.Output])
        log = log..' '..name..' '..(next(env[data.Output]) and LogEmoji('🆗') or LogEmoji('❌'))
    end
    if Logging.HelpStringsLoaded then print(log) end
end

function LoadModHelpStrings(ModDirectory)
    LoadHelpStrings(ModDirectory..'hook/')
end

function GetDirFromShellLnk(lnk)
    local linkfile = io.open(lnk, 'rb'):read('*all')
    return string.gsub(string.match(linkfile, '%a:\\[ \\%w%s%p]+'), '\\', '/')
end
