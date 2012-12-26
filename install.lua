--install Opus Arcania
args={...}
--TODO: add check if already installed, add "-r"emove function (or uninstall)... Maybe generalize it for other mods.
if args[1]~="install" and args[1]~='-i' then
    print("Usage: install -i|install [entity_id1] [entity_id2] ...\n","Warning: this is an experimental script, backup raws. Generate a new world to play")
    return
end
function copyFile(from,to) --oh so primitive
    local filefrom=io.open(from,"rb")
    local fileto=io.open(to,"w+b")
    local buf=filefrom:read("*a")
    printall(buf)
    fileto:write(buf)
    filefrom:close()
    fileto:close()
end
function patchEntity(entity_file,entity_name)
    local input_file=io.open(dfhack.getHackPath().."scripts/OpusArcania/raws/entity patch.txt","r")
    local input_lines=input_file:read("*all")
    input_file:close()
    local badchars="[%:%[%]]"
    local find_string=entity_name:gsub(badchars,"%%%1")
    local entityFile=io.open(entity_file,"r")
    local buf=entityFile:read("*all")
    entityFile:close()
    local entityFile=io.open(entity_file,"w+")
    print("Patching:"..entity_name)
    buf=string.gsub(buf,find_string,entity_name.."\n"..input_lines)
    entityFile:write(buf)
    entityFile:close()
end
print("installing...")
local filelist={"building_arcane.txt","item_tool_arcane.txt","reaction_arcane.txt"}
for k,v in pairs(filelist) do
        copyFile(dfhack.getHackPath().."scripts/OpusArcania/raws/"..v,dfhack.getDFPath().."/raw/objects/"..v)
end
en_file=dfhack.getDFPath().."/raw/objects/entity_default.txt"
if args[2]==nil then
    patchEntity(en_file,"[ENTITY:MOUNTAIN]")
else
    for k=2,#args do
        patchEntity(en_file,"[ENTITY:"..args[k].."]")
    end
end

    