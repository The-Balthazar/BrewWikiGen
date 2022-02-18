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
                print('Logs from', file)
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
        return {
            __active_mods = __active_mods,

            pairs = pairs,
            ipairs = ipairs,

            print = SandboxedPrint(file, 'Print:'),
            LOG = SandboxedPrint(file, 'Log:'),
            SPEW = SandboxedPrint(file, 'Debug:'),
            _ALERT = SandboxedPrint(file, 'Log:'),
            WARN = SandboxedPrint(file, 'Warn:'),

            error = error,
            assert = assert,

            table = table,
            string = string,
            math = math,

            type = type,
            tostring = tostring,
            tonumber = tonumber,
        }
    end,
    Blueprint = function()
        local filebps = {}
        local function export(bptype)
            return function(t) table.insert(filebps, setmetatable(t, {__name = bptype})) end
        end
        return {
            Sound = function(t) return setmetatable(t, {__name = 'Sound'}) end,
            BeamBlueprint         = export'Beam',
            MeshBlueprint         = export'Mesh',
            PropBlueprint         = export'Prop',
            EmitterBlueprint      = export'Emitter',
            ProjectileBlueprint   = export'Projectile',
            TrailEmitterBlueprint = export'TrailEmitter',
            UnitBlueprint         = export'Unit',
            Blueprints            = filebps,
        }
    end,
}

function GetSandboxedLuaFile(file, env)
    local env = env and Sandboxes[env](file) or {}
    local chunk, msg = loadfile(file, 'bt', env)
    if chunk then
        chunk()
        return env
    end
    printif(not string.find(msg, 'No such file or directory'), msg)
end

function GetSanitisedLuaFile(file, env)
    local env = env and Sandboxes[env](file) or {}
    local openfile = io.open(file, 'r')
    local filestring = (openfile:read'a')
        :gsub('#', '--')
        :gsub('\\[^"^\']', '/')
    openfile:close()
    --local filename = string.match(file, '/([^/.]+)$')
    local chunk, msg = load(filestring, file, 't', env)
    if chunk then
        chunk()
        return env
    end
    printif(not string.find(msg, 'No such file or directory'), msg)
end

function LoadModInfo(dir, i)
    local ModInfo = assert(
        GetSandboxedLuaFile(dir..'mod_info.lua'),
        'Failed to load '..tostring(dir)..'mod_info.lua'
    )
    ModInfo.location = dir
    ModInfo.ModIndex = i
    if ModInfo.GenerateWikiPages == nil then
        ModInfo.GenerateWikiPages = true
    end
    return ModInfo
end

function LoadHelpStrings(dir)
    local log = '  Preloading: '
    for output, path in pairs{
        Description = 'lua/ui/help/unitdescription.lua',
        Tooltips    = 'lua/ui/help/tooltips.lua',
    } do
        local env = GetSandboxedLuaFile(dir..path, 'HelpStrings')
        tableMergeCopy(_G[output], env[output])
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

function FileExists(dir)
    local file = io.open(dir, 'rb')
    return file and file:close()
end

local OutputAssets = {} -- reduce file loads by cachine processed files

function OutputAsset(dir)
    if not OutputAssets[dir] and not FileExists(OutputDirectory..dir) and FileExists(WikiGeneratorDirectory..dir) then
        local output = io.open(OutputDirectory..dir, 'wb')
        if not output then
            local mkdir = string.gsub(OutputDirectory..string.match(dir, '(.*)/'), '/', '\\')
            printif(Logging.FileAssetCopies, 'Creating directory', mkdir)
            os.execute("mkdir "..mkdir)
        end
        printif(Logging.FileAssetCopies, 'Copying asset to', OutputDirectory..dir); --this semicolon is actually important. Without it the next line tries to call the output of the printif.
        (output or io.open(OutputDirectory..dir, 'wb')):write(
            io.open(WikiGeneratorDirectory..dir, 'rb'):read('all')
        ):close()
        OutputAssets[dir] = true
    end
    return dir
end

function UnitIconDir(ID)
    local path = 'icons/units/'..ID..'_icon.png'
    return FileExists(OutputDirectory..path) and path or OutputAsset('icons/units/unidentified_icon.png')
end

function UnitIcon(ID, data)
    data = data or {}
    data.src = UnitIconDir(ID)
    return xml:img(data)
end

function StrategicIcon(icon, data)
    if not (WikiOptions.IncludeStrategicIcon and icon) then return '' end
    data = data or {}
    data.title = data.title or icon
    data.src = OutputAsset('icons/strategicicons/'..icon..'_rest.png')
    return xml:img(data)
end
