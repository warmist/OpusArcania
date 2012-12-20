-- random number generators

RandomGenerator=defclass(RandomGenerator)
function RandomGenerator:get(min,max)
    local val=(self:gen())/bit32.bnot(0)
    if min~=nil and max~=nil then
        return min+val*(max-min)
    elseif min~=nil then
        return val*max
    else
        return val
    end
end
function RandomGenerator:pick(values)
    local val=self:get(1,#values+1)
    return values[math.floor(val)]
end
xorShift=defclass(xorShift,RandomGenerator)
function xorShift:init(seed)
    self:reseed(seed)
end
function xorShift:reseed(seed)
    self.x=seed
    self.y=362436069
    self.z=521288629
    self.w=88675123
end
function xorShift:genOnebit()
    local t=bit32.bxor(self.x,bit32.lshift(self.x,11))
    self.x=self.y
    self.y=self.z
    self.z=self.w
    self.w=bit32.bxor(self.w,bit32.rshift(self.w,19))
    self.w=bit32.bxor(self.w,bit32.bxor(t,bit32.rshift(t,8)))
    return self.w
end
function xorShift:gen()
    local g=0
    for k=1,32 do
        g=bit32.bor(bit32.lshift(g,1),bit32.band(self:genOnebit(),1))
    end
    return g
end
Mersenne=defclass(Mersenne,RandomGenerator) --TODO check if correct...
function Mersenne:init(seed)
    self.seed={}
    self.seed[0]=seed
    self.index=0
    for i=1,623 do
        self.seed[i]=bit32.band(0x6c078965 * (bit32.bxor(self.seed[i-1],bit32.rshift(self.seed[i-1],30))) + i,bit32.bnot(0)) -- 0x6c078965
    end
end
function Mersenne:generate_numbers()
    for i=0,623 do
        local y=bit32.band(self.seed[i],0x80000000)+bit32.band(self.seed[math.fmod(i+1,624)],0x7fffffff)
        self.seed[i]=bit32.bxor(self.seed[math.fmod(i+397,624)],bit32.rshift(y,1))
        if math.fmod(y,2)~=0 then
            self.seed[i]=bit32.bxor(self.seed[i],0x9908b0df)
        end
    end
end
function Mersenne:gen()
    if self.index==0 then
        self:generate_numbers()
    end
    local y=self.seed[self.index]
    y=bit32.bxor(y,bit32.rshift(y,11))
    y=bit32.bxor(y,bit32.band(bit32.lshift(y,7),0x9d2c5680))
    y=bit32.bxor(y,bit32.band(bit32.lshift(y,15),0xefc60000))
    y=bit32.bxor(y,bit32.rshift(y,18))
    
    self.index=math.fmod(self.index+1,624)
    return y
end
