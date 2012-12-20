-- script file for Opus Arcania mod
dofile("hack/scripts/OpusArcania/random.lua")


nodelist=nodelist or{
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



