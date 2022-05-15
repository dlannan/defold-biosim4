
local tinsert = table.insert
local Coord = require("Coord")

-- // Grid is a somewhat dumb 2D container of unsigned 16-bit values.
-- // Grid understands that the elements are either EMPTY, BARRIER, or
-- // otherwise an index value into the peeps container.
-- // The elements are allocated and cleared to EMPTY in the ctor.
-- // Prefer .at() and .set() for random element access. Or use Grid[x][y]
-- // for direct access where the y index is the inner loop.
-- // Element values are not otherwise interpreted by class Grid.

local EMPTY = 0 -- // Index value 0 is reserved
local BARRIER = 0xffff

local Grid = {
    sizex   = 0,
    sizey   = 0,
    
    data = {},
    barrierLocations = {},
    barrierCenters = {},
}

-- // Column order here allows us to access grid elements as data[x][y]
-- // while thinking of x as column and y as row
local Column = {
    new = function( numRows ) return deepcopy(Grid) end,
    zeroFill = function(self) for k,v in pairs(self.data) do v = 0 end end,
    GetRow = function(self, rowNum) return data[rowNum] end,
    size = function() return #data end,

    data = {},
}

Grid.init = function(self, sizeX, sizeY) 
    self.sizex = sizeX
    self.sizey = sizeY
    self.data = {}
    for r = 1, sizeY do tinsert(self.data, Column.new(sizeY)) end 
end

Grid.zeroFill = function(self) for k,column in pairs(data) do column:zeroFill() end end
Grid.sizeX = function(self) return #data end
Grid.sizeY = function(self) return #data[1] end

Grid.at = function(self, loc) return self.data[loc.x][loc.y] end 
Grid.atXY = function(self, x, y) return self.data[x][y] end

Grid.isInBounds = function(self, loc) return loc.x >= 0 and loc.x < self:sizeX() and loc.y >= 0 and loc.y < self:sizeY() end
Grid.isEmptyAt = function(self, loc) return self:at(loc) == EMPTY end
Grid.isBarrierAt = function(self, loc) return self:at(loc) == BARRIER end
-- // Occupied means an agent is living there.
Grid.isOccupiedAt = function(self, loc) return self:at(loc) ~= EMPTY and self:at(loc) ~= BARRIER end
Grid.isBorder = function(self, loc) return loc.x == 0 or loc.x == self:sizeX() - 1 or loc.y == 0 or loc.y == self:sizeY() - 1 end

Grid.set = function(self, loc, val) self.data[loc.x][loc.y] = val end
Grid.setXY = function(self, x, y, val) self.data[x][y] = val end
Grid.findEmptyLocation = function() 
    
    loc = Coord.new()
    while (true) do
        loc.x = randomUint(0, p.sizeX - 1)
        loc.y = randomUint(0, p.sizeY - 1)
        if (grid.isEmptyAt(loc)) then 
            break
        end
    end
    return loc
end 

Grid.createBarrier = function(barrierType) end
Grid.getBarrierLocations(self) return self.barrierLocations end
Grid.getBarrierCenters(self) return barrierCenters end
-- // Direct access:
Grid.GetColumn(self, columnXNum) return self.data[columnXNum] end 

-- // This is a utility function used when inspecting a local neighborhood around
-- // some location. This function feeds each valid (in-bounds) location in the specified
-- // neighborhood to the specified function. Locations include self (center of the neighborhood).
visitNeighborhood = function(loc, radius, f)

    for  dx = math.min(radius, loc.x), math.min(radius, (p.sizeX - loc.x) - 1) do
        local x = loc.x + dx
        assert(x >= 0 and x < p.sizeX)
        local extentY = math.floor(math.sqrt(radius * radius - dx * dx) + 0.5)
        for dy = -math.min(extentY, loc.y), math.min(extentY, (p.sizeY - loc.y) - 1) do
            local y = loc.y + dy
            assert(y >= 0 and y < p.sizeY)
            f( Coord.new( x, y ) )
        end
    end
end

-- extern unitTestGridVisitNeighborhood();

return Grid