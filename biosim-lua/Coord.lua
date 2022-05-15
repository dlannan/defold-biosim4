
local B2N ={ [true]=1, [false]=0 }

-- // This rotates a Dir value by the specified number of steps. There are
-- // eight steps per full rotation. Positive values are clockwise; negative
-- // values are counterclockwise. E.g., rotate(4) returns a direction 90
-- // degrees to the right.
local NW = Compass.NW; local N = Compass.N
local NE = Compass.NE;  local E = Compass.E
local SE = Compass.SE;  local S = Compass.S
local SW = Compass.SW;  local W = Compass.W
local C = Compass.CENTER

-- // Coordinates range anywhere in the range of int16_t. Coordinate arithmetic
-- // wraps like int16_t. Can be used, e.g., for a location in the simulator grid, or
-- // for the difference between two locations.

local Coord = {
    new = function(x0, y0) { return { x=0; y=0 } end,
    x = 0,
    y = 0,
}

Coord.isNormalized = function(self) return self.x >= -1 and self.x <= 1 and self.y >= -1 and self.y <= 1 end
Coord.asDir = function(self) 
    -- // tanN/tanD is the best rational approximation to tan(22.5) under the constraint that
    -- // tanN + tanD < 2**16 (to avoid overflows). We don't care about the scale of the result,
    -- // only the ratio of the terms. The actual rotation is (22.5 - 1.5e-8) degrees, whilst
    -- // the closest a pair of int16_t's come to any of these lines is 8e-8 degrees, so the result is exact
    local tanN = 13860
    local tanD = 33461
    local conversion = {  
        S, C, SW, N, SE, E, N,
        N, N, N, W, NW, N, NE, N, N
    }

    local xp = x * tanD + y * tanN
    local yp = y * tanD - x * tanN

    -- // We can easily check which side of the four boundary lines
    -- // the point now falls on, giving 16 cases, though only 9 are
    -- // possible.
    return conversion[B2N[yp > 0] * 8 + B2N[xp > 0] * 4 + B2N[yp > xp] * 2 + B2N[yp >= -xp] + 1]
end

Coord.normalize = function(self) 
    return self:asDir():asNormalizedCoord()
end
Coord.length = function(self) return math.sqrt(self.x * self.x + self.y * self.y) end --// round down
Coord.asPolar = function(self) 
    return Polar.new( self:length(), self:asDir() )
end

Coord.EQ = function(self, c) return self.x == c.x and self.y == c.y end
Coord.NEQ = function(self, c) return self.x ~= c.x or self.y ~= c.y end
Coord.ADD = function(self, c) return self:new((self.x + c.x), (self.y + c.y)) end
Coord.SUB = function(self, c) return self:new((self.x - c.x), (self.y - c.y)) end
Coord.MUL = function(self, a) return self:new((self.x * a), (self.y * a)) end
Coord.ADDDir = function(self, d) return self:ADD(d:asNormalizedCoord()) end
Coord.SUBDir = function(self, d) return self:SUB(d:asNormalizedCoord()) end

Coord.raySameness = function(self, other) 
    local mag = (self.x * self.x + self.y * self.y) * (other.x * other.x + other.y * other.y)
    if (mag == 0) then
        return 1.0 -- // anything is "same" as zero vector
    end

    return (self.x * other.x + self.y * other.y) / math.sqrt(mag)
end -- // returns -1.0 (opposite) .. 1.0 (same)
Coord.raySamenessDir = function(self, d) 
    return self:raySameness(d:asNormalizedCoord())
end -- // returns -1.0 (opposite) .. 1.0 (same)

return Coord