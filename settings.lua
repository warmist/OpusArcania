NODE_CHANCE=0.05
NODE_Z_STEP=32
CONNECTOR_RANGE=30
tilemess={'x','%','.',';',"'",'"',"-","*","~"}

nodeTypes={

    Fire={color=COLOR_LIGHTRED,name="Forge" , desc="The endless burning of the forge",id=1},
    Water={color=COLOR_BLUE, name="Flow"    , desc="The flow of water that persistently washes the lands",id=2},
    
    Blood={color=COLOR_RED, name="Blood"    , desc="Only force that through the ages moved all that is alive",id=3},
    Stone={color=COLOR_GRAY, name="Foundation",desc="The eternal and unmovable",id=4},
    
    Death={color=COLOR_MAGENTA,name="Rust"   , desc="The force that grinds everything to dust and then some more",id=5},
    Energy={color=COLOR_WHITE,name="Artifice",desc="The pure energy of creation that pulls existance from the void",id=6},
}

STONE_DEFAULT={20,1,1}
METAL_DEFAULT={15,2,8}
METAL_SPECIAL=0.2
GEM_DEFAULT={10,10,35}
ORE_DAMPENING=0.75
WEAR_TICKS = 806400
WEAR_OVERCHARGE=WEAR_TICKS/20
WEAR_MULTIPLIER=5
PERSIST_OVERFLOW=0.1
PERSIST_FLOW=0.01
MANA_BURN=0.8