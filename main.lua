-- script file for Opus Arcania mod

local utils = require 'utils'
local gui = require 'gui'
local guidm = require 'gui.dwarfmode'
nodeTypes={

    Fire={color=COLOR_LIGHTRED,name="Forge" , desc="The endless burning of the forge"},
    Water={color=COLOR_BLUE, name="Flow"    , desc="The flow of water that persistently washes the lands"},
    
    Blood={color=COLOR_RED, name="Blood"    , desc="Only force that through the ages moved all that is alive"},
    Stone={color=COLOR_GRAY, name="Foundation",desc="The eternal and unmovable"},
    
    Death={color=COLOR_MAGENTA,name="Rust"   , desc="The force that grinds everything to dust and then some more"},
    Energy={color=COLOR_WHITE,name="Artifice",desc="The pure energy of creation that pulls existance from the void"},
}
nodelist=nodelist or{
}
NODE_CHANCE=0.05
NODE_Z_STEP=32
CONNECTOR_RANGE=80
RandomGenerator=defclass(RandomGenerator)
function RandomGenerator:get(min,max)
    local val=(self:gen())/bit32.bnot(0)
    if min~=nil and max~=nil then
        return min+val*(max-min)
    elseif min~=nil then
        return val*max
    else
        return val
    end
end
function RandomGenerator:pick(values)
    local val=self:get(1,#values+1)
    return values[math.floor(val)]
end
xorShift=defclass(xorShift,RandomGenerator)
function xorShift:init(seed)
    self:reseed(seed)
end
function xorShift:reseed(seed)
    self.x=seed
    self.y=362436069
    self.z=521288629
    self.w=88675123
end
function xorShift:genOnebit()
    local t=bit32.bxor(self.x,bit32.lshift(self.x,11))
    self.x=self.y
    self.y=self.z
    self.z=self.w
    self.w=bit32.bxor(self.w,bit32.rshift(self.w,19))
    self.w=bit32.bxor(self.w,bit32.bxor(t,bit32.rshift(t,8)))
    return self.w
end
function xorShift:gen()
    local g=0
    for k=1,32 do
        g=bit32.bor(bit32.lshift(g,1),bit32.band(self:genOnebit(),1))
    end
    return g
end
Mersenne=defclass(Mersenne,RandomGenerator) --TODO check if correct...
function Mersenne:init(seed)
    self.seed={}
    self.seed[0]=seed
    self.index=0
    for i=1,623 do
        self.seed[i]=bit32.band(0x6c078965 * (bit32.bxor(self.seed[i-1],bit32.rshift(self.seed[i-1],30))) + i,bit32.bnot(0)) -- 0x6c078965
    end
end
function Mersenne:generate_numbers()
    for i=0,623 do
        local y=bit32.band(self.seed[i],0x80000000)+bit32.band(self.seed[math.fmod(i+1,624)],0x7fffffff)
        self.seed[i]=bit32.bxor(self.seed[math.fmod(i+397,624)],bit32.rshift(y,1))
        if math.fmod(y,2)~=0 then
            self.seed[i]=bit32.bxor(self.seed[i],0x9908b0df)
        end
    end
end
function Mersenne:gen()
    if self.index==0 then
        self:generate_numbers()
    end
    local y=self.seed[self.index]
    y=bit32.bxor(y,bit32.rshift(y,11))
    y=bit32.bxor(y,bit32.band(bit32.lshift(y,7),0x9d2c5680))
    y=bit32.bxor(y,bit32.band(bit32.lshift(y,15),0xefc60000))
    y=bit32.bxor(y,bit32.rshift(y,18))
    
    self.index=math.fmod(self.index+1,624)
    return y
end
function xorRand()
    local y=xorRandSeed
    y=bit32.bxor(y,bit32.lshift(y,13))
    y=bit32.bxor(y,bit32.rshift(y,17))
    y=bit32.bxor(y,bit32.lshift(y,5))
    xorRandSeed=y
    return y
end

function hashString(input)
    local hash=0
    for i=1,#input do
        hash=bit32.bxor(bit32.rrotate(hash,i*4+7) ,string.byte(input,i))
    end
    return hash
end
function makeSeed(inputseed,block_x,block_y)
    local out_seed=inputseed
    out_seed=bit32.bxor(bit32.rrotate(out_seed,17) ,block_x)
    out_seed=bit32.bxor(bit32.rrotate(out_seed,8) ,block_y)
    return out_seed
end
function placeNode(rnd,block_x,block_y,z_min,z_max)
    local pos={x=rnd:get(block_x*16,block_x*16+16),
        y=rnd:get(block_y*16,block_y*16+16),z=rnd:get(z_min,z_max)}
    local ntype
    ntype=rnd:pick{nodeTypes.Fire,nodeTypes.Water,nodeTypes.Blood,nodeTypes.Stone,nodeTypes.Death,nodeTypes.Energy}
    local size=math.floor(rnd:get(3,15))
    table.insert(nodelist,{pos=pos,nodeType=ntype,size=size})
end
function genNodes()
    nodelist={}
    local myseed=hashString(df.global.world.worldgen.worldgen_parms.seed)
    local call_count=0
    for bx=0,df.global.world.map.x_count_block-1 do
    for by=0,df.global.world.map.y_count_block-1 do
        local newseed=makeSeed(myseed+6,bx+df.global.world.map.region_x*16,by+df.global.world.map.region_y*16)
        math.randomseed(newseed)
        local rand=Mersenne(newseed)
        
        for i=0,df.global.world.map.z_count_block-1,NODE_Z_STEP do
            if rand:get() < NODE_CHANCE then
                placeNode(rand,bx,by,i,i+NODE_Z_STEP)
            end
            call_count=call_count+1
        end
    end
    end
    --local max_nodes=df.global.world.map.x_count_block*df.global.world.map.y_count_block*((df.global.world.map.z_count_block-1)/NODE_Z_STEP)
    --[[ statistical checks
    local node_counts={0,0,0,0,0,0}
    for k,v in pairs(nodelist) do
        if v.nodeType==nodeTypes.Fire then
            node_counts[1]=node_counts[1]+1
        elseif v.nodeType==nodeTypes.Water then
            node_counts[2]=node_counts[2]+1
        elseif v.nodeType==nodeTypes.Blood then
            node_counts[3]=node_counts[3]+1
        elseif v.nodeType==nodeTypes.Stone then
            node_counts[4]=node_counts[4]+1
        elseif v.nodeType==nodeTypes.Death then
            node_counts[5]=node_counts[5]+1
        else --if v.nodeType==nodeTypes.Energy then
            node_counts[6]=node_counts[6]+1
        end
    end
    print(string.format("Generated %d/%d nodes. Thats %f percent.",#nodelist,call_count,(#nodelist/call_count)*100))
    for k,v in pairs(node_counts) do
        print(v/#nodelist)
    end
    --]]
end
genNodes()
tilemess={'x','%','.',';',"'",'"',"-","*","~"}
customShops={}
function getShop(token)
    for k,v in pairs(df.global.world.raws.buildings.all) do
        if v.code==token then
            return v.id
        end
    end
end
function wordWrap(inputstr,len,token) --if token==nil then split in the middle of word
    local ret={}
    if token~=nil then
        --TODO
    else
        for cur=1,#inputstr,len do
            table.insert(ret,string.sub(inputstr, cur,cur+len-1))
        end
    end
    return ret
end
function hasArcanist()
    local ent=df.global.ui.main.fortress_entity
    local pos_id
    for _,v in pairs(ent.positions.own) do
        if v.code=="RUNEMASTER" then --TODO ARCANIST
            pos_id=v.id
            break
        end
    end
    if pos_id == nil then
        qerror("entity does not have arcanist position")
    end
    for _,v in pairs(ent.positions.assignments) do
        if v.position_id==pos_id then
            if v.histfig ~= -1 then
                return v.histfig
            end
        end
    end
end
CustomShopView = defclass(CustomShopView, guidm.MenuOverlay)
function CustomShopView:updateBuilding()
     if df.global.world.selected_building==nil then
        self:dismiss()
        return
    end
    local cursor = guidm.getCursorPos()
    local pos=utils.getBuildingCenter(df.global.world.selected_building)
    local dx,dy,dz
    dx=pos.x-cursor.x
    dy=pos.y-cursor.y
    dz=pos.z-cursor.z
    local dist=math.max(math.abs(dx),math.abs(dy))
    if  dz~=0 or (dist>10) then
        --loose selection
        self:dismiss()
        df.global.world.selected_building=nil
        return
    else
        local was_build=df.global.world.selected_building
        local best_dist=dist
        local best_build=df.global.world.selected_building
        for k,v in pairs(df.global.world.buildings.all) do
            local npos=utils.getBuildingCenter(v)
            if npos.z==pos.z then
                local ndist=math.max(math.abs(npos.x-cursor.x),math.abs(npos.y-cursor.y))
                if ndist<best_dist then
                    best_dist=ndist
                    best_build=v
                end
            end
        end
        
        if best_build~= was_build then
            df.global.world.selected_building=best_build
            
            self:dismiss()
            if getShopWindow(best_build)~=nil then
                getShopWindow(best_build)():show(self.parent)
            end
            return
        end
        --check if there is a closer one
        -- or just loose selection, and update?
        --if SpecialWorkshop then
        --show it's menu...
    end
end
ShopViewer = defclass(ShopViewer, CustomShopView)
function ShopViewer:arcanistStatus()
    if not hasArcanist() then
        return false, "Arcanist is not assigned"
    else  --check office
        return true, "Arcanist is present"
    end
end
function ShopViewer:onRenderBody(dc)
    dc:clear()
    dc:pen(COLOR_WHITE):seek(1,1):string("Arcane viewer"):pen(COLOR_GREY)
    local ok, msg=self:arcanistStatus()
    if ok then
        dc:seek(1,3):string(msg)
        dc:seek(1,4):key('CUSTOM_A'):string(": view manafields")
        dc:seek(1,6):string(string.format("Nodes detected:%d",#nodelist))
    else
        dc:seek(1,3):string(msg)
    end
    

    dc:seek(1, math.max(dc:cursorY(), 21)):pen(COLOR_WHITE)
    dc:key('LEAVESCREEN'):string(": Back, ")
end
function ShopViewer:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
        self:sendInputToParent('LEAVESCREEN')
    --elseif keys.SELECT then
        --self:showCursor(self.cursor~=nil)
    elseif keys.CUSTOM_A then
        if self:arcanistStatus() then
            self:dismiss()
            ManaView():show(self.parent)
            return
        end
    elseif self:simulateCursorMovement(keys) then
        self:updateBuilding()
    end
end
customShops[getShop("ARCANE_VIEWER")]=ShopViewer
ConnectorViewer=defclass(ConnectorViewer, CustomShopView)
function ConnectorViewer:connectionStatus()
    return true, "Not connected"
end
function ConnectorViewer:onRenderBody(dc)
    dc:clear()
    dc:pen(COLOR_WHITE):seek(1,1):string("Arcane connector"):pen(COLOR_GREY)
    local ok, msg=self:connectionStatus()
    if ok then
        dc:seek(1,3):string(msg)
        dc:seek(1,4):key('CUSTOM_A'):string(": make connection")
        dc:seek(1,6):string(string.format("Nodes in range:",#nodelist))
    else
        dc:seek(1,3):string(msg)
    end
    

    dc:seek(1, math.max(dc:cursorY(), 21)):pen(COLOR_WHITE)
    dc:key('LEAVESCREEN'):string(": Back, ")
end
function ConnectorViewer:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
        self:sendInputToParent('LEAVESCREEN')
    --elseif keys.SELECT then
        --self:showCursor(self.cursor~=nil)
    elseif self:simulateCursorMovement(keys) then
        self:updateBuilding()
    end
end
customShops[getShop("ARCANE_BRIDGE1TO1")]=ConnectorViewer
ManaView = defclass(ManaView, guidm.MenuOverlay)

function ManaView:onShow()
    ManaView.super.onShow(self)

    self.old_cursor = guidm.getCursorPos()
    self.old_viewport = self:getViewport()

    self.mode = self.mode_main
    self:showCursor(true)
    self:updateNode()
end
function ManaView:showCursor(enable)
    local cursor = guidm.getCursorPos()
    if cursor and not enable then
        self.cursor = cursor
        guidm.clearCursorPos()
    elseif not cursor and enable then
        local view = self:getViewport()
        cursor = self.cursor
        if not cursor or not view:isVisible(cursor) then
            cursor = view:getCenter()
        end
        self.cursor = nil
        guidm.setCursorPos(cursor)
    end
end

function ManaView:updateNode()
    local cursor = guidm.getCursorPos()
    for k,v in ipairs(nodelist) do
        local dx=cursor.x-v.pos.x
        local dy=cursor.y-v.pos.y
        local dz=cursor.z-v.pos.z
        if math.abs(dx)+math.abs(dy)+math.abs(dz)<v.size then
            self.cur_node=v
            return
        end
    end
    self.cur_node=nil
end
function ManaView:renderNode(dc,node,screenpos)
    local col=node.nodeType.color
    local dz=screenpos.z --delta z
    if math.abs(dz)<node.size then
        for i=-node.size,node.size do
            for j=-node.size,node.size do
                if math.abs(i)+math.abs(j)+math.abs(dz)<node.size then
                    local tx,ty
                    tx=screenpos.x+i
                    ty=screenpos.y+j
                    local tile=tilemess[math.floor(tx+ty+dfhack.getTickCount()/100+tx*ty/5)%#tilemess+1]
                    dc:seek(tx,ty):char(tile, col)
                end
            end
        end
    end
end
function ManaView:onRenderNodes(dc)
    local view = self:getViewport()
    local map = self.df_layout.map
    local map_dc = gui.Painter.new(map)
    for k,v in ipairs(nodelist) do
        local p=view:tileToScreen(v.pos)
        --print((p.x+p.y+dfhack.getTickCount()/1000)%#tilemess+1)
        self:renderNode(map_dc,v,p)
        
    end
    local cursor = guidm.getCursorPos()
    if cursor then
        local cx, cy, cz = pos2xyz(view:tileToScreen(cursor))
        if cz == 0 then
            map_dc:seek(cx,cy):char('X', COLOR_YELLOW)
        end
    end
end
function ManaView:onRenderBody(dc)
    dc:clear()
    self:onRenderNodes(dc)
    if self.cur_node then
        dc:pen(COLOR_WHITE):seek(1):string(string.format("Node type:%8s",self.cur_node.nodeType.name))
        dc:seek(1,1):string("Size:"..tostring(self.cur_node.size))
        dc:seek(1,3):string("Description:")
        local desc=wordWrap(self.cur_node.nodeType.desc,20)
        for k,v in ipairs(desc) do
            dc:seek(1,3+k):string(v)
        end
    end
    -- existing connections
    dc:seek(1,dc.height-1):pen(COLOR_WHITE)
    dc:key('LEAVESCREEN'):string(": Back, ")
end
function ManaView:updateBuilding()
    if df.global.world.selected_building==nil then
        self:dismiss()
        return
    end
    local cursor = guidm.getCursorPos()
    local pos=utils.getBuildingCenter(df.global.world.selected_building)
    local dx,dy,dz
    dx=pos.x-cursor.x
    dy=pos.y-cursor.y
    dz=pos.z-cursor.z
    local dist=math.max(math.abs(dx),math.abs(dy))
    if  dz~=0 or (dist>10) then
        --loose selection
        self:dismiss()
        df.global.world.selected_building=nil
        return
    else
        local was_build=df.global.world.selected_building
        local best_dist=dist
        local best_build=df.global.world.selected_building
        for k,v in pairs(df.global.world.buildings.all) do
            local npos=utils.getBuildingCenter(v)
            if npos.z==pos.z then
                local ndist=math.max(math.abs(npos.x-cursor.x),math.abs(npos.y-cursor.y))
                if ndist<best_dist then
                    best_dist=ndist
                    best_build=v
                end
            end
        end
        
        if best_build~= was_build then
            --df.global.world.selected_building=nil
            self:dismiss()
            return
        end
        --check if there is a closer one
        -- or just loose selection, and update?
        --if SpecialWorkshop then
        --show it's menu...
    end
    self:showCursor(true)
end
function ManaView:onInput(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
        self:showCursor(true)
        self:sendInputToParent('LEAVESCREEN')
    --elseif keys.SELECT then
        --self:showCursor(self.cursor~=nil)
    elseif self:simulateCursorMovement(keys) then
        self:updateNode()
        --self:updateBuilding()
    end
end
function getShopWindow(shop)
    if shop:getType()==df.building_type.Workshop and shop:getSubtype()==df.workshop_type.Custom then
        return customShops[shop:getCustomType()]
    end
end
function shopDispatch(shop, call_native)
    local shopWindow=getShopWindow(shop)
    if shopWindow then
        --check if correct building type
        print(shop:getCustomType(),dfhack.gui.getCurFocus())
        local valid_focus="dwarfmode/QueryBuilding/Some"
        if string.sub(dfhack.gui.getCurFocus(),1,#valid_focus)==valid_focus then
            shopWindow():show()
        end
    end
end
function showMain(shop,call_native)
    if shop:getType()==df.building_type.Workshop and shop:getSubtype()==df.workshop_type.Custom then
        --check if correct building type
        print(shop:getCustomType(),dfhack.gui.getCurFocus())
        local valid_focus="dwarfmode/QueryBuilding/Some"
        if string.sub(dfhack.gui.getCurFocus(),1,#valid_focus)==valid_focus then
            ManaView():show()
        end
    end
end
require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=shopDispatch