--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

local function GetSCMFileString(filename)
    local file = assert(io.open(filename, 'rb'), "Cant find mesh: "..filename)
    local filestring = assert(file:read('*all'), "Cant read mesh: "..filename)
    file:close()
    return filestring
end

local function FindSCMBoneArrayStartTagOffset(filestring)
    return string.find(filestring, 'NAME') or 61
end

local function FindSCMBoneArrayEndTagOffset(filestring, startoffset)
    return string.find(filestring, 'SKEL\x00\x00\x80\x3f', startoffset+16) --Catches ~99%
    or string.find(filestring, '\xc5SKEL', startoffset+15) --Catches 15/16, but only vanilla or 3dsmax exported. Blender uses the print-able character X as padding instead.
    or string.find(filestring, '\x00SKEL', startoffset+15) + 1 --Catches the remaining 1/16, but has overlap.
end

local function GetArrayFrom0x00DelimitedString(str)
    local things = {}
    string.gsub(str, '([^\x00]+)\x00', function(thing)
        table.insert(things, thing)
    end)
    return things
end

local function GetSCMBoneNames(filename)
    local filestring = GetSCMFileString( filename )
    local opentag = FindSCMBoneArrayStartTagOffset( filestring )
    local closetag = FindSCMBoneArrayEndTagOffset( filestring, opentag )
    return GetArrayFrom0x00DelimitedString(string.sub( filestring, opentag + 4, closetag - 1 ))
end

local function GetLOD0SCMFilename(bp)
    if bp.Display.MeshBlueprint then
        error("Mesh defined as blueprint that I've not implemented parsing of yet")

    elseif bp.Display.Mesh.LODs[1] then
        local path = string.lower(bp.Display.Mesh.LODs[1].MeshName or (bp.ID..'_lod0.scm'))

        if string.sub(path,1,1) == '/' then
            if string.sub(path,1,6) == '/mods/' then
                local sourceRoot = assert(string.find(bp.SourceFolder, '/mods/'), "Can't parse root folder to find absolute mod path: "..path)
                return string.sub(bp.SourceFolder, 1, sourceRoot -1)
            else
                error("Vanilla mesh: "..path)--return path
            end
        end

        return bp.SourceFolder..'/'..path
    end
    error("No mesh found")
end

function GetMeshBones(bp)
    local ok, msg = pcall(
        function(bp)
            bp.Bones = GetSCMBoneNames(GetLOD0SCMFilename(bp))
        end,
        bp
    )
    if Logging.SCMLoadIssues and not ok then print(bp.ID, msg) end
end
