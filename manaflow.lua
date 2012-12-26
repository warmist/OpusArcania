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
            item:addWear(WEAR_OVERCHARGE,true,true) 
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
        --effectManaOutflowItem(item,areaflow+flowout)
        return 0
    else
        --effectManaOutflowItem(item,areaflow)
        return flowout
    end
end
