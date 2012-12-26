-- script file for Opus Arcania mod
execFile("random.lua")


nodelist=nodelist or{
}
matlist=matlist or{
}
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
function placeNode(rnd,block_x,block_y,z_min,z_max,id)
    local pos={x=rnd:get(block_x*16,block_x*16+16),
        y=rnd:get(block_y*16,block_y*16+16),z=rnd:get(z_min,z_max)}
    local ntype
    ntype=rnd:pick{nodeTypes.Fire,nodeTypes.Water,nodeTypes.Blood,nodeTypes.Stone,nodeTypes.Death,nodeTypes.Energy}
    local size=math.floor(rnd:get(3,15))
    table.insert(nodelist,{pos=pos,nodeType=ntype,size=size,id=id})
end
function genNodes()
    nodelist={}
    local myseed=hashString(df.global.world.worldgen.worldgen_parms.seed)
    local call_count=0
    local id=1
    for bx=0,df.global.world.map.x_count_block-1 do
    for by=0,df.global.world.map.y_count_block-1 do
        local newseed=makeSeed(myseed+6,bx+df.global.world.map.region_x*16,by+df.global.world.map.region_y*16)
        --math.randomseed(newseed)
        local rand=Mersenne(newseed)
        
        for i=0,df.global.world.map.z_count_block-1,NODE_Z_STEP do
            if rand:get() < NODE_CHANCE then
                placeNode(rand,bx,by,i,i+NODE_Z_STEP,id)
                id=id+1
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
--todo more distributions...
function genStone(gen,material)
    local ret=copyall(STONE_DEFAULT)
    if material.flags.SEDIMENTARY then
        ret[1]=ret[1]*0.75+gen:get(0,ret[1]*0.5)
        ret[2]=gen:get(0,ret[2]/2)
        ret[3]=gen:get(1,ret[3]*3)
        return ret
    elseif material.flags.IGNEOUS_INTRUSIVE then
        ret[1]=gen:get(ret[1],ret[1]*1.5)
        ret[3]=gen:get(ret[3],ret[3]+2)
        return ret
    elseif material.flags.IGNEOUS_EXTRUSIVE then
        ret[1]=ret[1]+gen:get(0,ret[1]*0.5)
        ret[3]=gen:get(ret[3]*0.75,ret[3]+1)
        return ret
    elseif material.flags.METAMORPHIC then
        ret[1]=gen:get(0,ret[1]*0.5)
        ret[2]=gen:get(ret[2]*2,ret[2]*5)
        ret[3]=gen:get(ret[3]*5,ret[3]*10)
        return ret
    elseif material.flags.METAL_ORE then
        ret={0,0,0}
        for k,v in pairs(material.metal_ore.mat_index) do
            local tval=matlist[0][v]
            print(tval,k,v,matlist[0][v])
            local weight=material.metal_ore.probability[k]/100
            ret[1]=ret[1]+tval[1]*weight
            ret[2]=ret[2]+tval[2]*weight
            ret[3]=ret[3]+tval[3]*weight
        end
        ret[1]=ret[1]*ORE_DAMPENING
        ret[2]=ret[2]*ORE_DAMPENING
        ret[3]=ret[3]*ORE_DAMPENING
        return ret
    elseif material.material.flags.IS_STONE then
        return ret
    else
        return {0,0,0}
    end
end
function genMetal(gen,material)
    local ret=copyall(METAL_DEFAULT)
    --todo add adamantine and/or other deep metals.
    if METAL_SPECIAL>gen:get() then --todo something more interesting, maybe special if have something...
        ret[1]=gen:get(0,50)
        ret[2]=gen:get(0,50)
        ret[3]=gen:get(0,50)
    else
        ret[1]=gen:get(ret[1]*0.5,ret[1]*1.5)
        ret[2]=gen:get(ret[2]*0.5,ret[2]*1.5)
        ret[3]=gen:get(ret[3]*0.5,ret[3]*1.5)
    end
    return ret
end
function genGem(gen,material)
    local ret=copyall(GEM_DEFAULT)
    ret[1]=gen:get(0,ret[1]*3)
    ret[2]=gen:get(ret[2],ret[2]*1.5)
    ret[3]=gen:get(ret[3]*0.5,ret[3]*1.5)
    return ret
end
function genMaterials()
    matlist={}
    local myseed=hashString(df.global.world.worldgen.worldgen_parms.seed)
    local rand=Mersenne(myseed)
    --inorganics:
    -- *stone
    -- *ore -- same as metal, less mass, less mcond
    -- *metal
    -- *gem
    local inorganics={}
    matlist[0]=inorganics
    for k,v in pairs(df.global.world.raws.inorganics) do
        if v.material.flags.IS_METAL then
            inorganics[k]=genMetal(rand,v)
        end
    end
    for k,v in pairs(df.global.world.raws.inorganics) do
        if inorganics[k]==nil then
            if v.material.flags.IS_GEM then
                inorganics[k]=genGem(rand,v)
            else
                inorganics[k]=genStone(rand,v)
            end
        end
    end
    for k,v in pairs(df.global.world.raws.inorganics) do
        print(string.format("%20s %d %d %d",v.id,inorganics[k][1],inorganics[k][2],inorganics[k][3]))
    end
    
end



