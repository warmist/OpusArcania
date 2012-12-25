--building guis
local utils = require 'utils'
local gui = require 'gui'
local guidm = require 'gui.dwarfmode'
--[[
p = p1;
d = p2-p1;
N = max(abs(d));
s = d/N;

We need to take N steps of size s, then round each of the floating-point positions found:

disp(p1)
for ii=1:N
   p = p+s;
   disp(round(p))
end

--]]
function line(callback,x0, y0,z0, x1, y1,z1)
    local dx,dy,dz
    dx = x1-x0
    dy = y1-y0
    dz = z1-z0
    local cx,cy,cz
    cx=x0;cy=y0;cz=z0
    local N=math.max(math.abs(dx),math.abs(dy),math.abs(dz))
    local sx,sy,sz
    sx=dx/N;sy=dy/N;sz=dz/N
    for i=1,N do
        cx=cx+sx
        cy=cy+sy
        cz=cz+sz
        callback(math.floor(cx+0.5),math.floor(cy+0.5),math.floor(cz+0.5))
    end
end
customShops={}
function getShop(token)
    for k,v in pairs(df.global.world.raws.buildings.all) do
        if v.code==token then
            return v.id
        end
    end
end
acceptsArcane={}
function isArcaneAcceptor(cbld)
    if cbld:getType()==df.building_type.Workshop and cbld:getSubtype()==df.workshop_type.Custom then
        return acceptsArcane[df.building_def.find(cbld:getCustomType()).code]
    end
end
genRefType={"GraphConnections","ManaHold1","ManaHold2"}
function getOrCreateGenRef(building,refType)
    for k,ref in pairs(building.general_refs) do
        if ref:getType()==df.general_ref_type.CREATURE then
            if ref.anon_1==refType then
                return ref
            end
        end
    end
    local ref=df.general_ref_creaturest:new()
    ref.anon_1=refType
    building.general_refs:insert('#',ref)
    return ret
end
ManaHold = defclass(ManaHold)
function ManaHold:init(args)
    self.target=args.target
end
function ManaHold:get(manaType)--not building itself, items in it...
    local ref
    if manaType.id<5 then
        ref=getOrCreateGenRef(self.target,genRefType.ManaHold1)
        if manaType.id == 1 then
            return ref.anon_2
        elseif manaType.id == 2 then
            return ref.anon_3
        elseif manaType.id == 3 then
            return ref.anon_4
        else
            return ref.anon_5
        end
    else
        ref=getOrCreateGenRef(self.target,genRefType.ManaHold2)
        if manaType.id == 5 then
            return ref.anon_2
        elseif manaType.id == 6 then
            return ref.anon_3
        elseif manaType.id == 7 then
            return ref.anon_4
        else
            return ref.anon_5
        end
    end
end
function ManaHold:set(manaType,value)
    local ref
    --todo check if overcharge happens
    if manaType.id<5 then
        ref=getOrCreateGenRef(self.target,genRefType.ManaHold1)
        if manaType.id == 1 then
            ref.anon_2=value
        elseif manaType.id == 2 then
            ref.anon_3=value
        elseif manaType.id == 3 then
            ref.anon_4=value
        else
            ref.anon_5=value
        end
    else
        ref=getOrCreateGenRef(self.target,genRefType.ManaHold2)
        if manaType.id == 5 then
            ref.anon_2=value
        elseif manaType.id == 6 then
            ref.anon_3=value
        elseif manaType.id == 7 then
            ref.anon_4=value
        else
            ref.anon_5=value
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

ConnectorViewer=defclass(ConnectorViewer, CustomShopView)
function ConnectorViewer:init(args)
    local nodesinrange={}
    local bld=df.global.world.selected_building
    local center=utils.getBuildingCenter(bld)
    local con_sq=CONNECTOR_RANGE*CONNECTOR_RANGE
    for k,v in pairs(nodelist) do
        local dx,dy,dz
        dx=center.x-v.pos.x
        dy=center.y-v.pos.y
        dz=center.z-v.pos.z
        
        if dx*dx+dy*dy+dz*dz<con_sq then
            table.insert(nodesinrange,v)
        end
    end
    local bldinrange={}
    for k,cbld in pairs(df.global.world.buildings.all) do
        if cbld~=bld and isArcaneAcceptor(cbld) then
            local dx,dy,dz
            local pos=utils.getBuildingCenter(cbld)
            dx=center.x-pos.x
            dy=center.y-pos.y
            dz=center.z-pos.z
            if dx*dx+dy*dy+dz*dz<con_sq  then
                table.insert(bldinrange,cbld)
            end
        end
    end
    self.nodes=nodesinrange

    self.buildings=bldinrange
end
function ConnectorViewer:connectionStatus()
    return true, "Not connected"
end
function ConnectorViewer:onRenderBody(dc)
    dc:clear()
    dc:pen(COLOR_WHITE):seek(1,1):string("Arcane connector"):pen(COLOR_GREY)
    local ok, msg=self:connectionStatus()
    if ok then
        dc:seek(1,3):string(msg)
        dc:seek(1,4):key('CUSTOM_A'):string(": connect to node")
        dc:seek(1,5):key('CUSTOM_B'):string(": connect to building")
        dc:seek(1,7):string(string.format("Nodes in range:%d",#self.nodes))
        dc:seek(1,8):string(string.format("Arcane acceptors in range:%d",#self.buildings))
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
function ManaView:renderLine(dc,x,y,z)
    local chars={'>','#','<'}
    if z>=-1 and z<=1 then
        dc:seek(x,y):char(chars[z+2])
    end
end
function ManaView:onRenderNodes(dc)
    local view = self:getViewport()
    local map = self.df_layout.map
    local map_dc = gui.Painter.new(map)
    local cp=view:tileToScreen(df.global.cursor)
    
    for k,v in ipairs(nodelist) do
        local p=view:tileToScreen(v.pos)
        
        --print((p.x+p.y+dfhack.getTickCount()/1000)%#tilemess+1)
        self:renderNode(map_dc,v,p)
        if k==1 then
            line(dfhack.curry(self.renderLine,self,map_dc),p.x,p.y,p.z,cp.x,cp.y,cp.z)
        end
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
    if shop:getType()==df.building_type.Workshop and shop:getSubtype()==df.workshop_type.Custom and shop:getBuildStage()==shop:getMaxBuildStage() then
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
        print(shop:getCustomType(),dfhack.gui.getCurFocus())
        local valid_focus="dwarfmode/QueryBuilding/Some"
        if string.sub(dfhack.gui.getCurFocus(),1,#valid_focus)==valid_focus then
            ManaView():show()
        end
    end
end
function loadWorkshopTypes()
    customShops[getShop("ARCANE_VIEWER")]=ShopViewer
    customShops[getShop("ARCANE_BRIDGE1TO1")]=ConnectorViewer
    acceptsArcane["ARCANE_VIEWER"]=true
    acceptsArcane["ARCANE_BRIDGE1TO1"]=true
end