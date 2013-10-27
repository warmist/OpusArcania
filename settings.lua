NODE_CHANCE=0.05 -- chance to spawn node in 16x16xNODE_Z_STEP
NODE_Z_STEP=32
CONNECTOR_RANGE=30 --range of connectors
tilemess={'x','%','.',';',"'",'"',"-","*","~"}

nodeTypes={

    Fire={color=COLOR_LIGHTRED,name="Forge" , desc="The endless burning of the forge",id=1},
    Water={color=COLOR_BLUE, name="Flow"    , desc="The flow of water that persistently washes the lands",id=2},
    
    Blood={color=COLOR_RED, name="Blood"    , desc="Only force that through the ages moved all that is alive",id=3},
    Stone={color=COLOR_GRAY, name="Foundation",desc="The eternal and unmovable",id=4},
    
    Death={color=COLOR_MAGENTA,name="Rust"   , desc="The force that grinds everything to dust and then some more",id=5},
    Energy={color=COLOR_WHITE,name="Artifice",desc="The pure energy of creation that pulls existance from the void",id=6},
}
--defaults are in "MASS, CONDUCTIVITY, PERSISTANCE"
STONE_DEFAULT={20,1,1}
METAL_DEFAULT={15,2,8}
METAL_SPECIAL=0.2   --amount of special metals
GEM_DEFAULT={10,10,35}
ORE_DAMPENING=0.75  -- ores are that much less good
WEAR_TICKS = 806400 --one wear level
WEAR_OVERCHARGE=WEAR_TICKS/20 
WEAR_MULTIPLIER=5    --wear multiplier for overcharged
PERSIST_OVERFLOW=0.1 --amount mana saved in overflow
PERSIST_FLOW=0.01    --amount mana saved in normal flow
PERSIST_TRANSFORM=20 --minimal amount required to transform into mana type crystal
MANA_BURN=0.8 -- amount mana lost if item is overcharged
NODE_CHANCE_BYSIZE=15 -- max size=15, so if set to 30 it will get triggered each other sweep
NODE_ACTIVITY=1 --x Size
SWEEP_TICKS=100 --logic runs every this ticks

AREA_SMALL=3 -- this much overflow guarantees a small aoe effect
AREA_BIG=20  -- same for bigger effect

FLOW_DAMPENING=0.95 --less then 1 so loops eventually die
