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

events={}

function worldLoaded()
    loadWorkshopTypes()
end
function mapLoaded()
    --start event ticker
    genNodes()
    genMaterials()
    --check building info and rebuild graphs
end
function mapUnloaded()
    --stop event ticker
    nodelist={}
    matlist={}
    --destroy graphs (optional)
end
events[SC_MAP_LOADED]=mapLoaded
events[SC_MAP_UNLOADED]=mapUnloaded
events[SC_WORLD_LOADED]=worldLoaded
function installHooks()
    require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=shopDispatch
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

    dfhack.onStateChange.arcane=nil
    print("Unloading OpusArcania")
end
events[SC_WORLD_UNLOADED]=removeHooks
if dfhack.isWorldLoaded() then
    worldLoaded()
end
if dfhack.isMapLoaded() then
    mapLoaded()
end

installHooks()