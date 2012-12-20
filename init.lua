dofile("hack/scripts/OpusArcania/settings.lua")
dofile("hack/scripts/OpusArcania/buildings.lua")
dofile("hack/scripts/OpusArcania/main.lua")
function installHooks()
    require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=shopDispatch
    --event ticker
    --on load genNodes()
    --regen nodes, load node info on map load
    --discard old nodes on map unload
    --add removeHooks on world unload
end
function removeHooks()    
    require("plugins.eventful").onWorkshopFillSidebarMenu.arcane=nil
    --event ticker
    --unhook onmapload/unload
end