function execFile(fname)
    local file,err=loadfile("hack/scripts/OpusArcania/"..fname,'t',_ENV)
    if file==nil then
        error(err)
    else
        return file()
    end
end
execFile("settings.lua")
execFile("buildings.lua")
execFile("main.lua")
execFile("manaflow.lua")
execFile("effects.lua")
execFile("buildingflow.lua")

events={}

function worldLoaded()
    loadWorkshopTypes()
end
function modTick()
    for k,v in pairs(nodelist) do
        if v.size/NODE_CHANCE_BYSIZE<math.random() then
            manaFlow(v,v.size*NODE_ACTIVITY)
        end
    end
    print("Mod tick")
    modTicker=dfhack.timeout(SWEEP_TICKS,'ticks',modTick)
end
function mapLoaded()
    --start event ticker
    genNodes()
    genMaterials()
    genGraph()
    modTicker=dfhack.timeout(SWEEP_TICKS,'ticks',modTick)
    --check building info and rebuild graphs
end
function mapUnloaded()
    --stop event ticker
    nodelist={}
    matlist={}
    graph={}
    dfhack.timeout_active(modTicker,nil)
    --destroy graphs (optional)
end

function installHooks()
    require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=shopDispatch
    require("plugins.eventful").onReactionComplete.arcane=reactionDispatch
    --regen nodes, load node info on map load
    --discard old nodes on map unload
    --add removeHooks on world unload
    dfhack.onStateChange.arcane = function(code)
        if events[code] then
            events[code]()
        end
    end
    print("OpusArcania working...")
end
function removeHooks()    
    require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=nil
    require("plugins.eventful").onReactionComplete.arcane=nil
    dfhack.onStateChange.arcane=nil
    print("Unloading OpusArcania")
end
if graph then
    mapUnloaded()
end

events[SC_MAP_LOADED]=mapLoaded
events[SC_MAP_UNLOADED]=mapUnloaded
events[SC_WORLD_LOADED]=worldLoaded
events[SC_WORLD_UNLOADED]=removeHooks

if dfhack.isWorldLoaded() then
    worldLoaded()
end
if dfhack.isMapLoaded() then
    mapLoaded()
end

installHooks()