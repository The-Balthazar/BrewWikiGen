--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

local function SandboxedPrint(file, logtype)
    local FileMessages
    return function(...)
        if Logging.SandboxedFileLogs[logtype] then
            printif(not FileMessages,'Logs from', file)
            FileMessages = true
            print('        '..logtype..':',...)
        end
    end
end

local categories = setmetatable({},{
    __index = function(self, key)
        self[key] = setmetatable({'`'..key..'`'}, {
            __add = function(a, b) a[1] = '('..a[1]..' + '..b[1]..')' return a end,
            __sub = function(a, b) a[1] = '('..a[1]..' - '..b[1]..')' return a end,
            __mul = function(a, b) a[1] = '('..a[1]..' × '..b[1]..')' return a end,
            __div = function(a, b) a[1] = '('..a[1]..' ÷ '..b[1]..')' return a end,
        })
        return self[key]
    end
})

local Sandboxes = {
    HelpStrings = function()
        return {
            Description = {},
            Tooltips = {},
        }
    end,
    MohoLua = function(file)
        return {
            _VERSION = _VERSION,
            __active_mods = __active_mods,

            pairs  = sortedpairs,
            ipairs = ipairs,
            next   = next,

            print  = SandboxedPrint(file, 'Log'),
            LOG    = SandboxedPrint(file, 'Log'),
            SPEW   = SandboxedPrint(file, 'Debug'),
            _ALERT = SandboxedPrint(file, 'Log'),
            WARN   = SandboxedPrint(file, 'Warn'),

            error  = error,
            assert = assert,
            pcall  = pcall,

            table  = table,
            string = string,
            math   = math,

            type     = type,
            tostring = tostring,
            tonumber = tonumber,

            getmetatable = getmetatable,
            setmetatable = setmetatable,
        }
    end,
    Blueprint = function()
        local filebps = {}
        local function export(bptype)
            return function(t)
                local meta; meta = {
                    __name = bptype,
                    __index = function(self, val)
                        return rawget(meta, val)
                    end
                }
                table.insert(filebps, setmetatable(t, meta))
            end
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
    Buff = function(file)
        local filebps = {}
        local function export(bptype)
            return function(t)
                local meta; meta = {
                    __name = bptype,
                    __index = function(self, val)
                        return rawget(meta, val)
                    end
                }
                table.insert(filebps, setmetatable(t, meta))
            end
        end
        return {
            _VERSION = _VERSION,
            __active_mods = __active_mods,

            pairs  = sortedpairs,
            ipairs = ipairs,
            next   = next,

            print  = SandboxedPrint(file, 'Log'),
            LOG    = SandboxedPrint(file, 'Log'),
            SPEW   = SandboxedPrint(file, 'Debug'),
            _ALERT = SandboxedPrint(file, 'Log'),
            WARN   = SandboxedPrint(file, 'Warn'),
            import = SandboxedPrint(file, 'Warn'),

            error  = error,
            assert = assert,
            pcall  = pcall,

            table  = table,
            string = string,
            math   = math,

            type     = type,
            tostring = tostring,
            tonumber = tonumber,

            getmetatable = getmetatable,
            setmetatable = setmetatable,

            categories    = categories,
            BuffBlueprint = export'Buff',
            Buffs         = filebps,
        }
    end,
}

local function MatchesExclusion(name, exclusions)
    if not exclusions then return end
    for i, v in ipairs(exclusions) do
        if string.find(name:lower(),v) then return true end
    end
end

function FindBlueprints(dir, shell)
    local paths = {}

    local dirs = io.popen('dir "'..dir..'" /b /s /a-s-h-d | findstr /e .bp')
    for bppath in dirs:lines() do
        bppath = bppath:gsub('\\', '/')
        if not MatchesExclusion(bppath, BlueprintExclusions) then
            table.insert(paths, {string.match(bppath, '(.*/)([^/]*%.bp)')})
        end
    end
    dirs:close()

    if not shell and not paths[1] then -- Follow links only if we found nothing, and only follow one, once.
        dirs = io.popen('dir "'..dir..'" /b /s /a-s-h-d | findstr /e .lnk')
        for lnk in dirs:lines() do
            paths = FindBlueprints(GetDirFromShellLnk(lnk), true)
            break
        end
        dirs:close()
    end

    collectgarbage()
    return paths
end

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
    local filename = string.match(file, "[^/]+$")--name for errors
    local chunk, msg = load(filestring, filename, 't', env)
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

function LoadAdjacencyBuffs(dir)

    local env = GetSandboxedLuaFile(dir..'lua/sim/AdjacencyBuffs.lua', 'Buff')

    if env then
        for i, v in ipairs(env.Buffs) do
            Buffs[v.Name] = v
        end
        for i, v in pairs(env) do
            if type(v) == 'table' and type(v[1]) == 'string' then
                AdjacencyBuffs[i] = v
            end
        end
    end
    local log = '  Preloading: Adjacency Buffs'..(env and LogEmoji'🆗' or LogEmoji'❌')

    if Logging.BuffsLoaded then print(log) end
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
    if dir and not OutputAssets[dir] and not FileExists(OutputDirectory..dir) and FileExists(WikiGeneratorDirectory..dir) then
        local output = io.open(OutputDirectory..dir, 'wb')
        if not output then
            local mkdir = string.gsub(OutputDirectory..string.match(dir, '(.*)/'), '/', '\\')
            printif(Logging.FileAssetCopies, 'Creating directory', mkdir)
            os.execute("mkdir "..mkdir)
        end
        printif(Logging.FileAssetCopies, 'Copying asset to', OutputDirectory..dir)
        local file = output or io.open(OutputDirectory..dir, 'wb')
        file:write( io.open(WikiGeneratorDirectory..dir, 'rb'):read'all' )
        file:close()
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
