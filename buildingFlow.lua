--building flow functions...
function getLensesAndOrbs(building)
    local ret={}
    for k,v in pairs(building.contained_items) do
        if v.use_mode==2 then
            if v.item:getType()==df.item_type.TOOL then
                if v.item.subtype.id=="TOOL_ARCANE_LENS" or v.item.subtype.id=="TOOL_ARCANE_ORB" then
                    table.insert(ret,v.item)
                end
            end
        end
    end
    return ret
end
function flowBuilding(building,mana,manaType,disipate) --simple for now...
    local retSum=0
    local contents=getLensesAndOrbs(building)
    for k,v in pairs(contents) do
        retSum=retSum+simulateFlowItem(v,mana/#contents,manaType,disipate)
    end
    return retSum
end

function comenceFlow(building,mana,manaType)
    local amount=mana
    local build=building
    while build~=nil and amount>1 do
        print("Flowing...",amount,build)
        amount=getFlowFunction(build)(build,amount,manaType)
        amount=amount*FLOW_DAMPENING
        print("Left:",amount)
        local nextTrg=graph:getNext(build)
        if nextTrg and not nextTrg.is_node then
            build=df.building.find(nextTrg.id)
        else
            build=nil
        end
    end
end