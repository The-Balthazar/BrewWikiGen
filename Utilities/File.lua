--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

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

local Sandboxes = {
    HelpStrings = function()
        return {
            Description = {},
            Tooltips = {},
        }
    end,
    MohoLua = function(file)
        local env = {
            __active_mods = __active_mods,

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
        return env
    end
}

function GetSandboxedLuaFile(file, env)
    local env = env and Sandboxes[env](file) or {}
    local chunk, msg = loadfile(file, 'bt', env)
    if chunk then
        chunk()
        return env
    elseif not string.find(msg, 'No such file or directory') then
        print(msg)
    end
end

function LoadModInfo(dir, i)
    local ModInfo = assert(
        GetSandboxedLuaFile(dir..'mod_info.lua'),
        'Failed to load '..tostring(dir)..'mod_info.lua'
    )
    ModInfo.location = dir
    ModInfo.ModIndex = i
    return ModInfo
end

function LoadHelpStrings(dir)
    local log = '  Preloading: '
    for output, path in pairs{
        Description = 'lua/ui/help/unitdescription.lua',
        Tooltips    = 'lua/ui/help/tooltips.lua',
    } do
        local env = GetSandboxedLuaFile(dir..path, 'HelpStrings')
        if env then
            tableMergeCopy(_G[output], env[output])
        end
        log = log..' '..output..' '..(env and LogEmoji'🆗' or LogEmoji'❌')
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
