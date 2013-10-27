--install Opus Arcania
args={...}
--TODO: add check if already installed. Maybe generalize it for other mods.

local filelist={"building_arcane.txt","item_tool_arcane.txt","reaction_arcane.txt","inorganic_arcane.txt"}
local en_file=dfhack.getDFPath().."/raw/objects/entity_default.txt"
local init_file=dfhack.getDFPath().."/raw/init.lua"
local guard={">>Opus Arcania patch","<<End patch"}
function copyFile(from,to) --oh so primitive
    local filefrom=io.open(from,"rb")
    local fileto=io.open(to,"w+b")
    local buf=filefrom:read("*a")
    printall(buf)
    fileto:write(buf)
    filefrom:close()
    fileto:close()
end
function patchInit(initFileName)
	local initFile=io.open(initFileName,"a")
	initFile:write(string.format("--%s\n%s\n--%s",guard[1],
		"dofile(dfhack.getHackPath()..'/scripts/OpusArcania/init.lua')",guard[2]))
	initFile:close()
end
function patchEntity(entity_file,entity_name)
    local input_file=io.open(dfhack.getHackPath().."scripts/OpusArcania/raws/entity patch.txt","r")
    local input_lines=guard[1].."\n"..input_file:read("*all").."\n"..guard[2]
    input_file:close()
    local badchars="[%:%[%]]"
    local find_string=entity_name:gsub(badchars,"%%%1") --escape some bad chars
    local entityFile=io.open(entity_file,"r")
    local buf=entityFile:read("*all")
    entityFile:close()
    local entityFile=io.open(entity_file,"w+")
    print("Patching:"..entity_name)
    buf=string.gsub(buf,find_string,entity_name.."\n"..input_lines)
    entityFile:write(buf)
    entityFile:close()
end
function findGuards(str,start)
	local pStart=string.find(str,guard[1],start)
	if pStart==nil then return nil end
	local pEnd=string.find(str,guard[2],pStart)
	if pEnd==nil then error("Start guard token found, but end was not found") end
	return pStart-1,pEnd+#guard[2]+1
end
function unPatchEntity(entity_file)
	local entityFile=io.open(entity_file,"r")
	local buf=entityFile:read("*all")
	local newBuf=""
	local pos=1
	local lastPos=1
	repeat 
		local endPos
		pos,endPos=findGuards(buf,lastPos)
		newBuf=newBuf..string.sub(buf,lastPos,pos)
		if endPos~=nil then
			lastPos=endPos
		end
	until pos==nil
	newBuf=newBuf..string.sub(buf,lastPos) --last bit
	entityFile:close()
	local entityFile=io.open(entity_file,"w+")
	entityFile:write(newBuf)
    entityFile:close()
end
if args[1]=="install" or args[1]=="-i" then
	print("installing...")
	
	for k,v in pairs(filelist) do
		copyFile(dfhack.getHackPath().."scripts/OpusArcania/raws/"..v,dfhack.getDFPath().."/raw/objects/"..v)
	end
	
	if args[2]==nil then
		patchEntity(en_file,"[ENTITY:MOUNTAIN]")
	else
		for k=2,#args do
			patchEntity(en_file,"[ENTITY:"..args[k].."]")
		end
	end
	patchInit(init_file)
	print("done")
	return
elseif args[1]=="uninstall" or args[1]=="-u" then
	print("removing...")
	for k,v in pairs(filelist) do
		os.remove(dfhack.getDFPath().."/raw/objects/"..v)
	end
	unPatchEntity(en_file)
	unPatchEntity(init_file) --TODO: leaves two "--" in the file
	print("done")
	return
end

print("Usage: install -i|install [entity_id1] [entity_id2] ...\n       install -u|uninstall","Warning: this is an experimental script, backup raws. Generate a new world to play")