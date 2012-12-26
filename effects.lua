--effects
function addLiquid(pos,amount,is_magma)
    local ttype=dfhack.maps.getTileType(pos2xyz(pos))
    if not ttype then return end
    local shape=df.tiletype.attrs[ttype].shape
    if shape~=df.tiletype_shape.WALL then
        local curblock=dfhack.maps.getTileBlock(pos2xyz(pos))
        local designation=curblock.designation[math.fmod(pos.x,16)][math.fmod(pos.y,16)]
        if (designation.flow_size==0 or designation.liquid_type==is_magma) and designation.flow_size~=7 then
            designation.flow_size=designation.flow_size+amount
            designation.liquid_type=is_magma
            dfhack.maps.enableBlockUpdates(curblock,true,true)
        end
    end
end
function randomisePos(pos,dist,z_also)
    local ret={}
    ret.x=pos.x+math.random(-dist,dist)
    ret.y=pos.y+math.random(-dist,dist)
    if z_also then
        ret.z=pos.z+math.random(-dist,dist)
    else
        ret.z=pos.z
    end
    return ret
end
function pickRandEvilCloud()
    local clouds={}
    for k,v in pairs(df.global.world.raws.inorganics) do
        if string.match(v.id,"EVIL_CLOUD_") then
            table.insert(clouds,k)
        end
    end
    return clouds[math.floor(math.random(1,#clouds))]
end
effectsArea={}
effectsArea[nodeTypes.Fire]=function(pos,amount)
    --make smoke, magmamist,fire, if big then add magma, maybe dragonfire?
    local ftype={df.flow_type.Smoke,df.flow_type.Fire,df.flow_type.MagmaMist}
    local chance=amount/AREA_SMALL 
    
    if math.random()<chance then
        local tpos=randomisePos(pos,1) 
        local cur_flow=ftype[math.floor(math.random(1,#ftype))]
        dfhack.maps.spawnFlow(tpos,cur_flow,1,0,amount)
    end
    
    if amount>AREA_BIG then
        local tpos=randomisePos(pos,1) 
        addLiquid(tpos,amount/AREA_BIG,true)
    end
end
effectsArea[nodeTypes.Water]=function(pos,amount)
    --make mist, steam, ice?, if big then add water
    local ftype={df.flow_type.Mist,df.flow_type.Steam}
    local chance=amount/AREA_SMALL 
    
    if math.random()<chance then
        local tpos=randomisePos(pos,1) 
        local cur_flow=ftype[math.floor(math.random(1,#ftype))]
        dfhack.maps.spawnFlow(tpos,cur_flow,1,0,amount)
    end
    
    if amount>AREA_BIG then
        local tpos=randomisePos(pos,1) 
        addLiquid(tpos,amount/AREA_BIG,false)
    end
end
effectsArea[nodeTypes.Blood]=function(pos,amount)
    --make blood mist, add blood on floor, e.g. EVIL_RAIN_...
    local ftype={df.flow_type.MaterialVapor,df.flow_type.MaterialGas}
    local chance=amount/AREA_SMALL 
    
    if math.random()<chance then
        local mt=df.global.world.raws.creatures.all
        local tpos=randomisePos(pos,1) 
        local mat_type,mat_index
        local id=math.floor(math.random(0,#mt-1))
        local caste_id=math.floor(math.random(0,#mt[id].caste-1))
        mat_type=mt[id].caste[caste_id].extracts.blood_mat
        mat_index=mt[id].caste[caste_id].extracts.blood_matidx
        dfhack.maps.spawnFlow(tpos,ftype[math.floor(math.random(1,#ftype))],mat_type,mat_index,(amount/AREA_SMALL)*15)
    end
end
effectsArea[nodeTypes.Stone]=function(pos,amount)
    --make stone dusts, vapors, cave in dust on area_big
    local ftype={df.flow_type.MaterialVapor,df.flow_type.MaterialGas}
    local chance=amount/AREA_SMALL 
    
    if math.random()<chance then
        local tpos=randomisePos(pos,1) 
        
        dfhack.maps.spawnFlow(tpos,ftype[math.floor(math.random(1,#ftype))],0,-1,math.min(amount,100))
    end
    
    if amount>AREA_BIG then
        for x=-1,1 do
            for y=-1,1 do
                if math.random()>0.3 then
                    local tpos={x=pos.x,y=pos.y,z=pos.z}
                    dfhack.maps.spawnFlow(tpos,df.flow_type.MaterialDust,0,-1,100)
                end
            end
        end
    end
end
effectsArea[nodeTypes.Death]=function(pos,amount)
    --make miasma, evil things, on area big huskyfing gasses
    
    local chance=amount/AREA_SMALL 
    if math.random()<chance then
        local tpos=randomisePos(pos,1) 
        dfhack.maps.spawnFlow(tpos,df.flow_type.Miasma,1,0,math.min(amount,100))
    end
    
    if amount>AREA_BIG then
        local tpos=randomisePos(pos,1) 
        dfhack.maps.spawnFlow(tpos,df.flow_type.MaterialGas,0,pickRandEvilCloud(),math.min(amount,100))
    end
end
effectsArea[nodeTypes.Energy]=function(pos,amount)
    --make spawn dusts, vapors and gasses of glass, gems, etc, maybe eat up veins?
    local ftype={df.flow_type.MaterialGas,df.flow_type.MaterialVapor}
    local chance=amount/AREA_SMALL 
    
    if math.random()<chance then
        local tpos=randomisePos(pos,1) 
        dfhack.maps.spawnFlow(tpos,ftype[math.random(1,#ftype)],df.builtin_mats.GLASS_CRYSTAL,-1,math.min(amount,100))
    end
    
    if amount>AREA_BIG then
        --[[local num=amount/AREA_BIG
        local ttype=dfhack.maps.getTileType(pos2xyz(pos))
        local shape=df.tiletype.attrs[ttype].shape
        if shape~=df.tiletype_shape.WALL then
            local curblock=dfhack.maps.getTileBlock(pos2xyz(pos))
            dfhack.maps.enableBlockUpdates(curblock,true,true)
        end--]]
        --print("TODO put evil material vein")
        --spawn creatures (rearly?)
    end
end

function effectManaOutflowItem(item,amount,manaType)
    local pos=xyz2pos(dfhack.items.getPosition(item))
    if pos~=nil then
        effectsArea[manaType](pos,amount)
    end
end