-- // Grid is a somewhat dumb 2D container of unsigned 16-bit values.
-- // Grid understands that the elements are either EMPTY, BARRIER, or
-- // otherwise an index value into the peeps container.
-- // The elements are allocated and cleared to EMPTY in the ctor.
-- // Prefer .at() and .set() for random element access. Or use Grid[x][y]
-- // for direct access where the y index is the inner loop.
-- // Element values are not otherwise interpreted by class Grid.

local EMPTY = 0 -- // Index value 0 is reserved
local BARRIER = 0xffff

Grid = {

    -- // Column order here allows us to access grid elements as data[x][y]
    -- // while thinking of x as column and y as row
    Column = {
        new = function( numRows) return { data = {} } end,
        zeroFill = function(self) for k,v in pairs(self.data) do v = 0 end end,
        GetRow = function(self, rowNum) return data[rowNum] end,
        size = function() return #data end,

        data = {},
    },

    init = function(self, sizeX, sizeY) end,
    zeroFill = function(self) for k,column in pairs(data) do column:zeroFill() end end,
    sizeX = function(self) return #data end,
    sizeY = function(self) return #data[1] end,
    isInBounds = function(loc) return loc.x >= 0 and loc.x < self:sizeX() and loc.y >= 0 and loc.y < self:sizeY() end
    bool isEmptyAt(Coord loc) const { return at(loc) == EMPTY; }
    bool isBarrierAt(Coord loc) const { return at(loc) == BARRIER; }
    -- // Occupied means an agent is living there.
    bool isOccupiedAt(Coord loc) const { return at(loc) != EMPTY && at(loc) != BARRIER; }
    bool isBorder(Coord loc) const { return loc.x == 0 || loc.x == sizeX() - 1 || loc.y == 0 || loc.y == sizeY() - 1; }
    uint16_t at(Coord loc) const { return data[loc.x][loc.y]; }
    uint16_t at(uint16_t x, uint16_t y) const { return data[x][y]; }

    void set(Coord loc, uint16_t val) { data[loc.x][loc.y] = val; }
    void set(uint16_t x, uint16_t y, uint16_t val) { data[x][y] = val; }
    Coord findEmptyLocation() const;
    void createBarrier(unsigned barrierType);
    const std::vector<Coord> &getBarrierLocations() const { return barrierLocations; }
    const std::vector<Coord> &getBarrierCenters() const { return barrierCenters; }
    -- // Direct access:
    Column & operator[](uint16_t columnXNum) { return data[columnXNum]; }
    const Column & operator[](uint16_t columnXNum) const { return data[columnXNum]; }
private:
    std::vector<Column> data;
    std::vector<Coord> barrierLocations;
    std::vector<Coord> barrierCenters;
};

extern void visitNeighborhood(Coord loc, float radius, std::function<void(Coord)> f);
extern void unitTestGridVisitNeighborhood();