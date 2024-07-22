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
        local function S(a) return type(a)=='table' and a[1] or a end
        self[key] = setmetatable({'`'..key..'`'}, {
            __add = function(a, b) return '('..S(a)..' + '..S(b)..')' end,
            __sub = function(a, b) return '('..S(a)..' - '..S(b)..')' end,
            __mul = function(a, b) return '('..S(a)..' × '..S(b)..')' end,
            __div = function(a, b) return '('..S(a)..' ÷ '..S(b)..')' end,
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
        local env = {
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
            debug  = {
                getinfo=debug.getinfo,
                traceback=debug.traceback,
            },

            type     = type,
            tostring = tostring,
            tonumber = tonumber,

            getmetatable = getmetatable,
            setmetatable = setmetatable,

            DiskFindFiles = function()error("Unsupported DiskFindFiles called by "..file) end,
        }
        env._G = env
        env.doscript = function(path)
            --NOTE: this just assumes it's only being ran from a file in env.
            --It'd need to translate the relative mounted path of the executed file else.
            local chunk, msg = loadfile(EnvironmentData.Lua..path, 'bt', env)
            if chunk then
                chunk()
                return env
            end
        end
        env.table.empty = function(t)
            if type(t) ~= 'table' then return true end
            return next(t) == nil
        end
        return env
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
        local env = {
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
        env._G = env
        return env
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

    local dirs
    if package.config:sub(1,1) == '\\' then
        dirs = io.popen('dir "'..dir..'" /b /s /a-s-h-d | findstr /e \\.bp')
    else
        dirs = io.popen("find '"..dir.."' -type f -name '*.bp'")
    end
    for bppath in dirs:lines() do
        bppath = bppath:gsub('\\', '/')
        if not MatchesExclusion(bppath, BlueprintExclusions) then
            table.insert(paths, {string.match(bppath, '(.*/)([^/]*%.bp)')})
        end
    end
    dirs:close()

    if not shell and not paths[1] then -- Follow links only if we found nothing, and only follow one, once.
        local dirs
        if package.config:sub(1,1) == '\\' then
            dirs = io.popen('dir "'..dir..'" /b /s /a-s-h-d | findstr /e \\.lnk')
        else
            dirs = io.popen("find '"..dir.."' -type f -name '*.lnk'")
        end
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
    ModInfo.RunSanityChecks = Sanity.BlueprintChecks

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

function LoadBuffs(dir, file)

    local env = GetSandboxedLuaFile(dir..file, 'Buff')

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
    local log = '  Preloading: '..file..(env and LogEmoji'🆗' or LogEmoji'❌')

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

function OutputAsset(dir, base64)
    if dir and not OutputAssets[dir] and not FileExists(OutputDirectory..dir) and FileExists(WikiGeneratorDirectory..dir) then
        local output = io.open(OutputDirectory..dir, 'wb')
        if not output then
            local mkdir = OutputDirectory..string.match(dir, '(.*)/')
            if package.config:sub(1,1) == '\\' then
                mkdir = string.gsub(mkdir, '/', '\\')
            end
            printif(Logging.FileAssetCopies, 'Creating directory', mkdir)
            os.execute('mkdir -p "'..mkdir..'"')
        end
        printif(Logging.FileAssetCopies, 'Copying asset to', OutputDirectory..dir)
        local file = output or io.open(OutputDirectory..dir, 'wb')
        file:write( io.open(WikiGeneratorDirectory..dir, 'rb'):read'all' )
        file:close()
        OutputAssets[dir] = true
    end
    return base64 and getBase64encodingFromPath(dir) or dir
end

function UnitIconDir(ID)--EnvironmentData.base64.UnitIcons
    local path = 'icons/units/'..ID..'_icon.png'
    return FileExists(OutputDirectory..path)
    and (EnvironmentData.base64.UnitIcons and getBase64encodingFromPath(path) or path)
    or OutputAsset('icons/units/unidentified_icon.png', EnvironmentData.base64.UnitIcons)
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

-- From http://lua-users.org/wiki/BaseSixtyFour
local bs = { [0] =
   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
   'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
   'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
   'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/',
}

local function base64encode(s)
   local byte, rep = string.byte, string.rep
   local pad = 2 - ((#s-1) % 3)
   s = (s..rep('\0', pad)):gsub("...", function(cs)
      local a, b, c = byte(cs, 1, 3)
      return bs[a>>2] .. bs[(a&3)<<4|b>>4] .. bs[(b&15)<<2|c>>6] .. bs[c&63]
   end)
   return s:sub(1, #s-pad) .. rep('=', pad)
end

function getBase64encodingFromPath(path)
    local encoding = path:match'[^.]*$'
    local file = io.open(OutputDirectory..path, 'rb')
    local filestring = file:read('*all')
    file:close()
    return 'data:image/'..encoding..';base64,'..base64encode(filestring)
end
