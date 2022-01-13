--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------
function GetSandboxedLuaFile(file)
    local env = {}
    loadfile(file, 'bt', env)()
    return env
end

function GetExecutableSandboxedLuaFile(file)
    local env = {
        pairs = pairs,
        ipairs = ipairs,

        print = print,
        LOG = print,
        SPEW = print,
        _ALERT = print,
        WARN = print,

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
    return assert(modinfo, "⚠️ Failed to load "..dir.."mod_info.lua")
end

function LoadModHooks(ModDirectory)
    local log = '  Preloading: '
    for name, fileDir in pairs({
        ['Build descriptions'] = 'hook/lua/ui/help/unitdescription.lua',
        ['Tooltips']           = 'hook/lua/ui/help/tooltips.lua',
    }) do
        log = log..(pcall(dofile, ModDirectory..fileDir) and '🆗 ' or '❌ ')..name..' '
    end
    if Logging.ModHooksLoaded then
        print(log)
    end
end
