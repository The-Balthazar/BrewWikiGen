--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021 Sean 'Balthazar' Wheeldon                           Lua 5.4.2
--------------------------------------------------------------------------------

function GetSCMBoneNames(filename)
    local file = io.open(filename)
    local filestring = file:read('a')
    file:close()
    filestring = string.sub(
        filestring,
        string.find(filestring, 'NAME') + 4,
        string.find(filestring, string.char(197)..'SKEL')  -- 197 = 0xc5
    )

    local boneIndex = 1
    local bones = {}
    for i = 1, string.len(filestring) do
        local char = string.sub(filestring, i, i)
        local byte = string.byte(char)

        if byte == 0 then
            boneIndex = boneIndex + 1
        elseif byte ~= 197 then
            if not bones[boneIndex] then
                bones[boneIndex] = ''
            end
            bones[boneIndex] = bones[boneIndex]..char
        end
    end
    return bones
end

