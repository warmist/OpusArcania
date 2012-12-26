--building guis
local utils = require 'utils'
local gui = require 'gui'
local guidm = require 'gui.dwarfmode'
local widgets =require 'gui.widgets'
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
function connectFromNode(building,node_id)
    node_id=node_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_2=connectionType.Node
    ref.anon_3=node_id
end
function connectToBuilding(building,building_id)
    building_id=building_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_4=connectionType.Building
    ref.anon_5=building_id
end
function connectToNode(building,node_id)
    node_id=node_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_4=connectionType.Node
    ref.anon_5=node_id
end
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
function renderNode(dc,node,screenpos)
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
            else
                best_build:fillSidebarMenu()
            end
            return
        end
        --check if there is a closer one
        -- or just loose selection, and update?
        --if SpecialWorkshop then
        --show it's menu...
    end
end
OrbViewer = defclass(OrbViewer, CustomShopView)
function OrbViewer:arcanistStatus()
    if not hasArcanist() then
        return false, "Arcanist is not assigned"
    else  --check office
        return true, "Arcanist is present"
    end
end
function OrbViewer:onRenderBody(dc)
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
function OrbViewer:onInput(keys)
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
function ConnectorViewer:renderLine(dc,x,y,z)
    local chars={'>','*','<'}
    if z>=-1 and z<=1 then
        dc:seek(x,y):char(chars[z+2])
    end
end
function ConnectorViewer:readConnection()
    local con={}
    local ref=getGenRef(self.building,genRefType.GraphConnections)
    if ref== nil then
        self.connections=con
        return
    end
    if ref.anon_2==connectionType.Node then
        con.from=nodelist[ref.anon_3]
    end
    if ref.anon_5<1 then
        con.to=nil
    else
        if ref.anon_4==connectionType.Node then
            con.to={node=nodelist[ref.anon_5],is_node=true}
        elseif ref.anon_4==connectionType.Building then
            con.to={build=df.building.find(ref.anon_5),is_node=false}
        end
    end
    self.connections=con
end
function ConnectorViewer:init(args)
    local nodesinrange={}
    local bld=df.global.world.selected_building
    self.building=bld
    
    self:readConnection()
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
    self.from=nil
    self.to=nil
    local con_from={{text="Nothing"}}
    local con_to={{text="Nothing"}}
    for k,v in pairs(nodesinrange) do
        table.insert(con_from,{text=v.nodeType.name,pos=v.pos,is_node=true,node=v})
        table.insert(con_to,{text=v.nodeType.name,pos=v.pos,is_node=true,node=v})
    end
    for k,v in pairs(bldinrange) do
        table.insert(con_to,{text=utils.call_with_string(v,"getName"),pos=utils.getBuildingCenter(v),is_node=false,build=v})
    end
    local mainPage=widgets.Panel{
        subviews={
                widgets.Label{
                text={"Arcane Connector","\n",
                {text=" : connect from node",key='CUSTOM_A',on_activate=self:callback("connectFrom")},"\n",
                {text=" : connect to building/node",key='CUSTOM_B',on_activate=self:callback("connectTo")}}
                ,frame = {l=1,t=1,yalign=0}}
                }
            }
    local connectFromPage=widgets.Panel{
        subviews={widgets.Label{text="Connect from:",frame = {l=1,t=1,yalign=0}},
                  widgets.List{choices=con_from,on_select=self:callback("centerOn"),on_submit=self:callback("setFrom"),frame = {l=1,t=3,yalign=0}}
                  }
        }
    local connectToPage=widgets.Panel{
        subviews={widgets.Label{text="Connect to:",frame = {l=1,t=1,yalign=0}},
                  widgets.List{choices=con_to,on_select=self:callback("centerOn"),on_submit=self:callback("setTo"),frame = {l=1,t=3,yalign=0}}
                  }
        }
    local pages=widgets.Pages{subviews={mainPage,connectFromPage,connectToPage},view_id="pages"}
    self:addviews{
        pages
    }
end
function ConnectorViewer:setFrom(index,choice)
    self.curNode=nil --choice.node
    if choice.text~="Nothing" then
        connectFromNode(self.building,choice.node.id)
    else
        connectFromNode(self.building,-1)
    end
    self:readConnection()
    self:mainScreen()
end
function ConnectorViewer:setTo(index,choice)
    if choice.text=="Nothing" then
        connectToNode(self.building,-1)
    elseif choice.is_node then
        connectToNode(self.building,choice.node.id)
    elseif not choice.is_node then
        connectToBuilding(self.building,choice.build.id)
    end
    self:readConnection()
    self:mainScreen()
end
function ConnectorViewer:centerViewOn(pos)
    if pos==nil then
        pos=utils.getBuildingCenter(self.building)
    end
    local cursor = guidm.getCursorPos()
    if cursor then
        guidm.setCursorPos(pos)
    else
        self.cursor = pos
    end
    self:getViewport():centerOn(pos):set()
end
function ConnectorViewer:centerOn(index,choice)
    self.curNode=nil
    if choice.text=="Nothing" then
        if self.subviews.pages~=nil and self.subviews.pages:getSelected()~=1 then
            self:centerViewOn()
        end
    else
        self:centerViewOn(choice.pos)
        if choice.is_node then
            self.curNode=choice.node
        end
        --is node?
    end
end
function ConnectorViewer:connectFrom()
    self.subviews.pages:setSelected(2)
end
function ConnectorViewer:connectTo()
    self.subviews.pages:setSelected(3)
end
function ConnectorViewer:connectionStatus()
    return true, "Not connected"
end
function ConnectorViewer:onRenderBody(dc)
    dc:clear()
    --[[dc:pen(COLOR_WHITE):seek(1,1):string("Arcane connector"):pen(COLOR_GREY)
    local ok, msg=self:connectionStatus()
    if ok then
        dc:seek(1,3):string(msg)
        dc:seek(1,4):key('CUSTOM_A'):string(": connect from node")
        dc:seek(1,5):key('CUSTOM_B'):string(": connect to building/node")
        dc:seek(1,7):string(string.format("Nodes in range:%d",#self.nodes))
        dc:seek(1,8):string(string.format("Arcane acceptors in range:%d",#self.buildings))
    else
        dc:seek(1,3):string(msg)
    end]]
    --[[
        line(dfhack.curry(self.renderLine,self,map_dc),p.x,p.y,p.z,cp.x,cp.y,cp.z)
    ]]
    local view = self:getViewport()
    local map = self.df_layout.map
    local map_dc = gui.Painter.new(map)
    
    if self.curNode~=nil then
        
        local p=view:tileToScreen(self.curNode.pos)
        --print((p.x+p.y+dfhack.getTickCount()/1000)%#tilemess+1)
        renderNode(map_dc,self.curNode,p)
    end
    local cp=view:tileToScreen(utils.getBuildingCenter(self.building))
    if self.connections.from~=nil then
        local p=view:tileToScreen(self.connections.from.pos)
        renderNode(map_dc,self.connections.from,p)
        line(dfhack.curry(self.renderLine,self,map_dc),p.x,p.y,p.z,cp.x,cp.y,cp.z)
    end
    if self.connections.to~=nil then
        if self.connections.to.is_node then
            local p=view:tileToScreen(self.connections.to.pos)
            renderNode(map_dc,self.connections.to,p)
            line(dfhack.curry(self.renderLine,self,map_dc),p.x,p.y,p.z,cp.x,cp.y,cp.z)
        else
            local p=view:tileToScreen(utils.getBuildingCenter(self.connections.to.build))
            line(dfhack.curry(self.renderLine,self,map_dc),p.x,p.y,p.z,cp.x,cp.y,cp.z)
        end
    end
    if self.connections.to~= nil or self.connections.from ~=nil then
        local cursor_pos=view:tileToScreen(guidm.getCursorPos())
        map_dc:seek(cursor_pos.x,cursor_pos.y):char('X', COLOR_YELLOW)
        if cp.z==0 then
            map_dc:seek(cp.x,cp.y):char('X', COLOR_GREEN)
        end
    end
    dc:seek(1, math.max(dc:cursorY(), 21)):pen(COLOR_WHITE)
    dc:key('LEAVESCREEN'):string(": Back, ")
end
function ConnectorViewer:mainScreen()
    self.subviews.pages:setSelected(1)
    self:centerViewOn()
end
function ConnectorViewer:onInput(keys)
    if keys.LEAVESCREEN then
        if self.subviews.pages:getSelected()~=1 then
            self:mainScreen()
        else
            self:dismiss()
            self:sendInputToParent('LEAVESCREEN')
        end
    
    --elseif keys.SELECT then
        --self:showCursor(self.cursor~=nil)
    
    elseif self.subviews.pages:getSelected()==1 and self:simulateCursorMovement(keys) then
        self:updateBuilding()
    end
    self.super.onInput(self,keys)
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


function ManaView:onRenderNodes(dc)
    local view = self:getViewport()
    local map = self.df_layout.map
    local map_dc = gui.Painter.new(map)
    local cp=view:tileToScreen(df.global.cursor)
    
    for k,v in ipairs(nodelist) do
        local p=view:tileToScreen(v.pos)
        
        --print((p.x+p.y+dfhack.getTickCount()/1000)%#tilemess+1)
        renderNode(map_dc,v,p)
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
    customShops[getShop("ARCANE_VIEWER")]=OrbViewer
    customShops[getShop("ARCANE_BRIDGE1TO1")]=ConnectorViewer
    acceptsArcane["ARCANE_VIEWER"]=true
    acceptsArcane["ARCANE_BRIDGE1TO1"]=true
end