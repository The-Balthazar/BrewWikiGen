--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
function GetSandboxedLuaFile(file)
    local env = {}
    loadfile(file, 'bt', env)()
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
    local chunk = loadfile(file, 'bt', env)
    if chunk then chunk() end
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

function LoadModHooks(ModDirectory)
    local log = '  Preloading: '
    for name, fileDir in pairs({
        ['Build descriptions'] = 'hook/lua/ui/help/unitdescription.lua',
        ['Tooltips']           = 'hook/lua/ui/help/tooltips.lua',
    }) do
        log = log..' '..name..' '..(pcall(dofile, ModDirectory..fileDir) and LogEmoji('🆗') or LogEmoji('❌'))
    end
    if Logging.ModHooksLoaded then
        print(log)
    end
end
