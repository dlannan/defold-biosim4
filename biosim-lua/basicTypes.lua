local Coord = require("biosim-lua.Coord")

-- /*
-- Basic types used throughout the project:

-- Compass - an enum with enumerants SW, S, SE, W, CENTER, E, NW, N, NE

--     Compass arithmetic values:

--         6  7  8
--         3  4  5
--         0  1  2

-- Dir, Coord, Polar, and their constructors:

--     Dir - abstract type for 8 directions plus center
--     ctor Dir(Compass = CENTER)

--     Coord - signed int16_t pair, absolute location or difference of locations
--     ctor Coord() = 0,0

--     Polar - signed magnitude and direction
--     ctor Polar(Coord = 0,0)

-- Conversions

--     uint8_t = Dir.asInt()

--     Dir = Coord.asDir()
--     Dir = Polar.asDir()

--     Coord = Dir.asNormalizedCoord()
--     Coord = Polar.asCoord()

--     Polar = Dir.asNormalizedPolar()
--     Polar = Coord.asPolar()

-- Arithmetic

--     Dir.rotate(int n = 0)

--     Coord = Coord + Dir
--     Coord = Coord + Coord
--     Coord = Coord + Polar

--     Polar = Polar + Coord (additive)
--     Polar = Polar + Polar (additive)
--     Polar = Polar * Polar (dot product)

-- // This rotates a Dir value by the specified number of steps. There are
-- // eight steps per full rotation. Positive values are clockwise; negative
-- // values are counterclockwise. E.g., rotate(4) returns a direction 90
-- // degrees to the right.
local NW = Compass.NW; local N = Compass.N
local NE = Compass.NE;  local E = Compass.E
local SE = Compass.SE;  local S = Compass.S
local SW = Compass.SW;  local W = Compass.W
local C = Compass.CENTER

local rotations = { 
    SW, W, NW, N, NE, E, SE, S,
    S, SW, W, NW, N, NE, E, SE,
    SE, S, SW, W, NW, N, NE, E,
    W, NW, N, NE, E, SE, S, SW,
    C, C, C, C, C, C, C, C,
    E, SE, S, SW, W, NW, N, NE,
    NW, N, NE, E, SE, S, SW, W,
    N, NE, E, SE, S, SW, W, NW,
    NE, E, SE, S, SW, W, NW, N 
}


-- /*
--     A normalized Coord is a Coord with x and y == -1, 0, or 1.
--     A normalized Coord may be used as an offset to one of the
--     8-neighbors.
-- 
--     A Dir value maps to a normalized Coord using
-- 
--        Coord { (d%3) - 1, (trunc)(d/3) - 1  }
-- 
--        0 => -1, -1  SW
--        1 =>  0, -1  S
--        2 =>  1, -1, SE
--        3 => -1,  0  W
--        4 =>  0,  0  CENTER
--        5 =>  1   0  E
--        6 => -1,  1  NW
--        7 =>  0,  1  N
--        8 =>  1,  1  NE
-- */


local NormalizedCoords = { 
    Coord.new(-1,-1), --// SW
    Coord.new(0,-1),  --// S
    Coord.new(1,-1),  --// SE
    Coord.new(-1,0),  --// W
    Coord.new(0,0),   --// CENTER
    Coord.new(1,0),   --// E
    Coord.new(-1,1),  --// NW
    Coord.new(0,1),   --// N
    Coord.new(1,1)    --// NE
}

   
-- // Polar magnitudes are signed 32-bit integers so that they can extend across any 2D
-- // area defined by the Coord class.
Polar = {
    new = function(mag0, dir0) 
        return { mag = mag0 or 0, dir = Dir.Dir(dir0) or Compass.CENTER }
    end,
    asCoord = function(self) 
        -- // (Thanks to @Asa-Hopkins for this optimized function -- drm)
        -- // 3037000500 is 1/sqrt(2) in 32.32 fixed point
        local coordMags = {
            3037000500,  --// SW
            bit.lshift(1, 32),   --// S
            3037000500,  --// SE
            bit.lshift(1, 32),   --// W
            0,           --// CENTER
            bit.lshift(1, 32),   --// E
            3037000500,  --// NW
            bit.lshift(1, 32),   --// N
            3037000500   --// NE
        }
    
        local len = coordMags[self.dir:asInt() + 1] * self.mag
    
        -- // We need correct rounding, the idea here is to add/sub 1/2 (in fixed point)
        -- // and truncate. We extend the sign of the magnitude with a cast,
        -- // then shift those bits into the lower half, giving 0 for mag >= 0 and
        -- // -1 for mag<0. An XOR with this copies the sign onto 1/2, to be exact
        -- // we'd then also subtract it, but we don't need to be that precise.
    
        local temp = bit.bxor(bit.rshift(mag, 32), (bit.lshift(1, 31) - 1))
        len = (len + temp) / bit.lshift(1, 32) -- // Divide to make sure we get an arithmetic shift
    
        return NormalizedCoords[self.dir:asInt() + 1] * len
    end,

    mag = 0,
    dir = Compass.CENTER,
}

-- // Supports the eight directions in enum class Compass plus CENTER.
Dir = {
    
    Dir = function(self, dir) self.dir9 = dir or Compass.CENTER end,
    Get = function(self, d) self.dir9 = d; return self end,
    asInt = function(self) return math.floor(self.dir9 + 0.5) end,

    asNormalizedCoord = function(self) 
        return NormalizedCoords[self:asInt() + 1]
    end, -- // (-1, -0, 1, -1, 0, 1)
    asNormalizedPolar = function(self) 
        return Polar.new(1, dir9)
    end,

    rotate = function(self, n) 
        return rotations[self:asInt() * 8 + bit.band(n, 7) + 1]
    end,
    rotate90DegCW = function(self) return self:rotate(2) end,
    rotate90DegCCW = function(self) return self:rotate(-2) end,
    rotate180Deg = function(self)  return self:rotate(4) end,

    EQ = function(self, d)  return self:asInt() == d end,
    NEQ = function(self, d) return self:asInt() ~= d end,
    EQDir = function(self, d) return self:asInt() == d:asInt() end,
    NEQDir = function(self, d) return self:asInt() ~= d:asInt() end,

    dir9 = 0,
}  

Dir.new = function(newDir)
    local d = table.shallowcopy(Dir)
    d:Dir(newDir)
    return d
end 

Dir.random8 = function() 
    local d = Dir.new(Compass.N)
    return d:rotate(randomUint:GetRange(0, 7)) 
end

