--magic flow functions
-- basic idea: magic comes in, and then out. In the middle it does something (e.g. could destroy item in the process)
genRefType={GraphConnections=1,ManaHold1=2,ManaHold2=3}
connectionType={None=0,Node=1,Building=2}
function getGenRef(building,refType)
    for k,ref in pairs(building.general_refs) do
        if ref:getType()==df.general_ref_type.CREATURE then
            if ref.anon_1==refType then
                return ref
            end
        end
    end
end
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
    return ref
end

ManaHold = defclass(ManaHold)
function ManaHold:init(args)
    self.target=args.target
end
function ManaHold:get(manaType)--not building itself, items in it...
    local ref
    if manaType.id<5 then
        ref=getGenRef(self.target,genRefType.ManaHold1)
        if ref==nil then return 0 end
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
        ref=getGenRef(self.target,genRefType.ManaHold2)
        if ref==nil then return 0 end
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
function ManaHold:getSum()
    local sum=0
    for k,v in pairs(nodeTypes) do
        sum=sum+self:get(v)
    end
    return sum
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
function ManaHold:add(manaType,value)
    self:set(manaType,self:get(manaType)+value)
end
function ManaHold:burn()
    for k,v in pairs(nodeTypes) do
        self:set(v,self:get(v)*MANA_BURN)
    end
end
function addManaItem(item,mana,manaType)
    if mana==0 then return 0,false; end
    local cond,mass,persist,transform=table.unpack(matlist[item:getActualMaterial()][item:getActualMaterialIndex()])
    local hold=ManaHold{target=item}
    if hold:getSum()+mana > persist then
        local over=(hold:getSum()+mana)-persist
        hold:add(manaType,mana-over)
        if transform~=nil then
            local ret,destroyed=transform(item,over,manaType)
            return ret,destroyed 
        else
            hold:burn()
            item:addWear(WEAR_OVERCHARGE+(over/5)*WEAR_MULTIPLIER,true,true) 
            return over,false
        end
    else
        hold:add(manaType,mana)
    end
    return 0,false
end
function simulateFlowItem(item,manaIn,manaType,disipate) -- normal flow a->b through item, if disipate all stuff gets dumped to area
    local mass,cond,persist=table.unpack(matlist[item:getActualMaterial()][item:getActualMaterialIndex()])
    print("Mana flowed in:"..manaIn)
    local overflow=math.max(manaIn-cond,0) --this is amount thats too much for normal conductance
    local normalflow=manaIn-overflow
    print("Normal:",normalflow," over:",overflow)
    local flowout=normalflow
    if overflow>mass then --if item can't manage that overflow, add damage
        print("Too much, adding damage")
        item:addWear(WEAR_OVERCHARGE+(overflow-mass)*WEAR_MULTIPLIER,false,false) 
        overflow=mass-- cap at mass
    end
    local mana=0 --collect mana from overflow and normal flow
    if persist~=0 then
        mana=mana+overflow*(persist*PERSIST_OVERFLOW)
        mana=mana+normalflow*(persist*PERSIST_FLOW)
        print("Collected mana due to persist:",mana)
        flowout=flowout-flowout*(persist*PERSIST_FLOW) --collected mana does not flow out
    end
    local areaflow,destroyed=addManaItem(item,mana,manaType)
    areaflow=areaflow+overflow*(1-persist*PERSIST_OVERFLOW) --overflow thats not collected gets radiated into the area
    print("Radiated mana:",areaflow)
    if destroyed or disipate then
        effectManaOutflowItem(item,areaflow+flowout,manaType)
        return 0
    else
        effectManaOutflowItem(item,areaflow,manaType)
        return flowout
    end
end

function manaFlow(node,amount)
    --[[if #node.outputs==0 then
        return
    end]]
    local manaType=node.nodeType
    --local con=graph:find({id=node.id,is_node=true})
    for k,v in pairs(node.outputs) do
        print("Flowing to:",k)
        local build=df.building.find(k)
        
        if build~=nil and getFlowFunction(build) then
            print("Comencing:",k)
            comenceFlow(build,amount,manaType)
        else
            print("culling removed building:",k)
            graph:remove({id=node.id,is_node=true},{id=k,is_node=false})
        end
    end
end
--connection ={from={is_node,id},to={is_node,id}}
connectionGraph=defclass(connectionGraph)
function connectionGraph:getNext(building)
    local ref=getGenRef(building,genRefType.GraphConnections)
    if ref then
        if (ref.anon_4==connectionType.Node or ref.anon_4==connectionType.Building) and ref.anon_5>0 then
            local to={is_node=(ref.anon_4==connectionType.Node),id=ref.anon_5}
            return to
        end
    end    
end
function connectionGraph:connectFromNode(building,node_id)
    node_id=node_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_2=connectionType.Node
    ref.anon_3=node_id
end
function connectionGraph:connectToBuilding(building,building_id)
    building_id=building_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_4=connectionType.Building
    ref.anon_5=building_id
end
function connectionGraph:connectToNode(building,node_id)
    node_id=node_id or -1
    local ref=getOrCreateGenRef(building,genRefType.GraphConnections)
    ref.anon_4=connectionType.Node
    ref.anon_5=node_id
end
function connectionGraph:init(args)
    self:rebuild()
end
function connectionGraph:rebuild()
    self.graph={}
    for k,v in pairs(df.global.world.buildings.all) do
        local ref=getGenRef(v,genRefType.GraphConnections)
        
        if ref then
            
            if (ref.anon_2==connectionType.Node or ref.anon_2==connectionType.Building) and ref.anon_3>0 then
                local from={is_node=(ref.anon_2==connectionType.Node),id=ref.anon_3}
                local to={is_node=false,id=v.id}
                if not self:add(from,to) then
                    ref.anon_2=-1
                end
            end
            if (ref.anon_4==connectionType.Node or ref.anon_4==connectionType.Building) and ref.anon_5>0 then
                local to={is_node=(ref.anon_4==connectionType.Node),id=ref.anon_5}
                local from={is_node=false,id=v.id}
                if not self:add(from,to)then
                    ref.anon_4=-1
                end
            end
            
        end
    end
end
function connectionGraph:add(from,to)
    table.insert(self.graph,{from=from,to=to})
    if from.is_node then
        local curNode=nodelist[from.id]
        if to.is_node then
            error("Invalid connection, both from and to is node")
        else
            local to_build=df.building.find(to.id)
            if to_build==nil then return false end
            self:connectFromNode(to_build,from.id)
            curNode.outputs[to.id]=true
        end
    else
        local curBuilding=df.building.find(from.id)
        if curBuilding==nil then return false end
        if to.is_node then
            self:connectToNode(curBuilding,to.id)
        else
            local trg_build=df.building.find(to.id)
            if trg_build==nil then return false end
            self:connectToBuilding(curBuilding,to.id)
            self:connectToBuilding(trg_build,curBuilding.id)
        end
    end
    return true
end
function connectionGraph:match(connection,from,to)
    if from~=nil then
        if connection.from.is_node~=from.is_node then
            return false
        end
        if connection.from.id~=from.id then
            return false
        end
    end
    if to~=nil then
        if connection.to.is_node~=to.is_node then
            return false
        end
        if connection.to.id~=to.id then
            return false
        end
    end
    return true
end
function connectionGraph:remove(from,to)
    local con,key=self:find(from,to)
    if key==nil then return end
    table.remove(self.graph,key)
    if con.from.is_node then
        local curNode=nodelist[con.from.id]
        if con.to.is_node then
            --why?
            error("Invalid connection, both from and to is node")
        else
            if df.building.find(con.to.id)~=nil then
                self:connectFromNode(df.building.find(con.to.id))
            end
            curNode.outputs[con.to.id]=nil
        end
    else
        local curBuilding=df.building.find(con.from.id)
        if con.to.is_node then
            if curBuilding then
                self:connectToNode(curBuilding)
            end
        else
            if curBuilding then
                self:connectToBuilding(curBuilding)
            end
            if df.building.find(con.to.id) then
                self:connectToBuilding(df.building.find(con.to.id))
            end
        end
    end
end
function connectionGraph:find(from,to)
    for k,v in pairs(self.graph) do
        if self:match(v,from,to) then
            return v,k
        end
    end
end
function genGraph()
    graph=connectionGraph()
end