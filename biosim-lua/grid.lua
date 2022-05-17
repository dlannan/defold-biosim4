
local tinsert = table.insert
local Coord = require("biosim-lua.Coord")

-- // Grid is a somewhat dumb 2D container of unsigned 16-bit values.
-- // Grid understands that the elements are either EMPTY, BARRIER, or
-- // otherwise an index value into the peeps container.
-- // The elements are allocated and cleared to EMPTY in the ctor.
-- // Prefer .at() and .set() for random element access. Or use Grid[x][y]
-- // for direct access where the y index is the inner loop.
-- // Element values are not otherwise interpreted by class Grid.

local Grid = {
    sizex   = 0,
    sizey   = 0,
    
    data = {},
    barrierLocations = {},
    barrierCenters = {},
}

Grid.EMPTY = 0 -- // Index value 0 is reserved
Grid.BARRIER = 0xffff

-- // Column order here allows us to access grid elements as data[x][y]
-- // while thinking of x as column and y as row
local Column = {
    zeroFill = function(self) for k,v in pairs(self.data) do v = 0 end end,
    GetRow = function(self, rowNum) return data[rowNum] end,
    size = function() return #data end,
    data = {},
}

Column.new = function(numRows) 
    local col = table.shallowcopy(Column) 
    for i = 1, numRows do col.data[i-1] = 0 end 
    return col
end

Grid.init = function(self, sizeX, sizeY) 
    self.sizex = sizeX
    self.sizey = sizeY
    self.data = {}
    for r = 0, sizeX do 
        self.data[r] = {}
        for s = 0, sizeX do 
            self.data[r][s] = Grid.EMPTY 
        end 
    end 
end

Grid.zeroFill = function(self) 
    for k,column in pairs(self.data) do
        for l, item in pairs(column) do
            item = Grid.EMPTY 
        end 
    end 
end

Grid.sizeX = function(self) return #self.data end
Grid.sizeY = function(self) return #self.data[1] end

Grid.at = function(self, loc) return 
    self.data[loc.x][loc.y] 
end 

Grid.atXY = function(self, x, y) 
    return self.data[x][y] 
end

Grid.isInBounds = function(self, loc) 
    return loc.x >= 0 and loc.x < self:sizeX() and loc.y >= 0 and loc.y < self:sizeY() 
end

Grid.isEmptyAt = function(self, loc) 
    return self:at(loc) == Grid.EMPTY 
end

Grid.isBarrierAt = function(self, loc) 
    return self:at(loc) == Grid.BARRIER 
end

-- // Occupied means an agent is living there.
Grid.isOccupiedAt = function(self, loc) 
    return self:at(loc) ~= Grid.EMPTY and self:at(loc) ~= Grid.BARRIER 
end

Grid.isBorder = function(self, loc) 
    return loc.x == 0 or loc.x == self:sizeX() - 1 or loc.y == 0 or loc.y == self:sizeY() - 1 
end

Grid.set = function(self, loc, val) 
    self.data[loc.x][loc.y] = val 
end

Grid.setXY = function(self, x, y, val) 
    self.data[x][y] = val 
end

Grid.findEmptyLocation = function(self) 
    
    loc = Coord.new()
    while (true) do
        loc.x = randomUint:GetRange(0, p.sizeX - 1)
        loc.y = randomUint:GetRange(0, p.sizeY - 1)
        if (self:isEmptyAt(loc)) then 
            break
        end
    end
    return loc
end 

Grid.createBarrier = function(barrierType)  print("empty") end
Grid.getBarrierLocations = function(self) return self.barrierLocations end
Grid.getBarrierCenters = function(self) return self.barrierCenters end
-- // Direct access:
Grid.GetColumn = function(self, columnXNum) return self.data[columnXNum] end 

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

-- // This generates barrier points, which are grid locations with value
-- // BARRIER. A list of barrier locations is saved in private member
-- // Grid::barrierLocations and, for some scenarios, Grid::barrierCenters.
-- // Those members are available read-only with Grid::getBarrierLocations().
-- // This function assumes an empty grid. This is typically called by
-- // the main simulator thread after Grid::init() or Grid::zeroFill().

-- // This file typically is under constant development and change for
-- // specific scenarios.

Grid.createBarrier = function(self, barrierType)

    self.barrierLocations = {}
    self.barrierCenters = {} --  // used only for some barrier types

    local drawBox = function(minX, minY, maxX, maxY) 
        for x = minX, maxX do
            for y = minY, maxY do
                grid:set(x, y, BARRIER)
                tinsert(self.barrierLocations, {x, y} )
            end
        end 
    end

    if(barrierType == 0) then 
        return

    -- // Vertical bar in constant location
    elseif(barrierType == 1) then 
        
        local minX = p.sizeX / 2
        local maxX = minX + 1
        local minY = p.sizeY / 4
        local maxY = minY + p.sizeY / 2

        for x = minX, maxX do
            for y = minY, maxY do
                grid:set(x, y, Grid.BARRIER)
                tinsert(  self.barrierLocations, {x, y} )
            end
        end

    -- // Vertical bar in random location
    elseif(barrierType == 2) then 
        
        local minX = randomUint:GetRange(20, p.sizeX - 20)
        local maxX = minX + 1
        local minY = randomUint:GetRange(20, p.sizeY / 2 - 20)
        local maxY = minY + p.sizeY / 2

        for x = minX, maxX do
            for y = minY, maxY do 
                grid:set(x, y, Grid.BARRIER)
                tinsert(self.barrierLocations, {x, y} )
            end
        end 

    -- // five blocks staggered
    elseif(barrierType == 3) then 

        local blockSizeX = 2
        local blockSizeY = p.sizeX / 3

        local x0 = p.sizeX / 4 - blockSizeX / 2
        local y0 = p.sizeY / 4 - blockSizeY / 2
        local x1 = x0 + blockSizeX
        local y1 = y0 + blockSizeY

        drawBox(x0, y0, x1, y1)
        x0 = x0 + p.sizeX / 2
        x1 = x0 + blockSizeX
        drawBox(x0, y0, x1, y1)
        y0 = y0 + p.sizeY / 2
        y1 = y0 + blockSizeY
        drawBox(x0, y0, x1, y1)
        x0 = x0 - p.sizeX / 2
        x1 = x0 + blockSizeX
        drawBox(x0, y0, x1, y1)
        x0 = p.sizeX / 2 - blockSizeX / 2
        x1 = x0 + blockSizeX
        y0 = p.sizeY / 2 - blockSizeY / 2
        y1 = y0 + blockSizeY
        drawBox(x0, y0, x1, y1)
        return

    -- // Horizontal bar in constant location
    elseif(barrierType == 4) then 
        local minX = p.sizeX / 4;
        local maxX = minX + p.sizeX / 2;
        local minY = p.sizeY / 2 + p.sizeY / 4;
        local maxY = minY + 2;

        for x = minX, maxX do
            for y = minY, maxY do
                grid:set(x, y, Grid.BARRIER)
                tinsert(self.barrierLocations, {x, y} )
            end
        end

    -- // Three floating islands -- different locations every generation
    elseif(barrierType == 5) then 

        local radius = 3.0
        local margin = 2 * radius

        local randomLoc = function() 
-- //                return Coord( (int16_t)randomUint((int)radius + margin, p.sizeX - ((float)radius + margin)),
-- //                              (int16_t)randomUint((int)radius + margin, p.sizeY - ((float)radius + margin)) );
            return Coord.new( randomUint:GetRange(margin, p.sizeX - margin),
                            randomUint:GetRange(margin, p.sizeY - margin) )
        end 

        local center0 = randomLoc()
        local center1 = {}
        local center2 = {}

        while ( (center0:SUB(center1)):length() < margin ) do
            center1 = randomLoc()
        end

        while ( (center0:SUB(center2)):length() < margin or (center1:SUB(center2)):length() < margin) do
            center2 = randomLoc()
        end

        tinsert(self.barrierCenters, center0)
        -- //barrierCenters.push_back(center1);
        -- //barrierCenters.push_back(center2);

        local f = function(loc) 
            grid:set(loc, Grid.BARRIER)
            tinsert(self.barrierLocations, loc)
        end 

        visitNeighborhood(center0, radius, f)
        -- //visitNeighborhood(center1, radius, f);
        -- //visitNeighborhood(center2, radius, f);


    -- // Spots, specified number, radius, locations
    elseif(barrierType == 6) then 
        
        local numberOfLocations = 5
        local radius = 5.0

        local f = function(loc) 
            grid:set(loc, Grid.BARRIER)
            tinsert(self.barrierLocations, loc)
        end 

        local verticalSliceSize = p.sizeY / (numberOfLocations + 1)

        for n = 1, numberOfLocations do
            local loc = Coord.new( p.sizeX / 2, n * verticalSliceSize )
            visitNeighborhood(loc, radius, f)
            tinsert(self.barrierCenters, loc)
        end 

    else 
        assert(false)
    end 
end 
-- extern unitTestGridVisitNeighborhood();

return Grid