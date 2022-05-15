require("utils.copies")

local Coord = require("Coord")

tinsert = table.insert

local SIGNAL_MIN = 0
local SIGNAL_MAX = UINT8_MAX

local Column = {
    new = function(self, numRows) self.data = {} end,
    Get = function(self, rowNum) return self.data[rowNum] end,
    zeroFill = function(self) for k,v in pairs(self.data) do v = 0 end,
    data = {},
}

local Layer = {
    new = function(self, numCols, numRows) 
        for i = 1, numCols do 
            tinsert(self.data, Column.new(numRows)) 
        end
    end,
    GetColumn = function(self, colNum) return self.data[colNum] end,
    zeroFill = function(self) for k,col in pairs(self.data) do col:zeroFill() end end,

    data = {}
}

Signals = {
      data = {},
}

Signals.init = function(self, numLayers, sizeX, sizeY)

    for n = 1, numLayers do 
        tinsert(self.data, Layer.new(sizeX, sizeY))
    end
end 

Signals.Get = function(self, layerNum) return self.data[layerNum] end 
Signals.getMagnitude = function(self, layerNum, loc) return self.data[layerNum][loc.x][loc.y] end

-- // Increases the specified location by centerIncreaseAmount,
-- // and increases the neighboring cells by neighborIncreaseAmount

-- // Is it ok that multiple readers are reading this container while
-- // this single thread is writing to it?  todo!!!
Signals.increment = function(self, layerNum, loc) 
    local radius = 1.5
    local centerIncreaseAmount = 2
    local neighborIncreaseAmount = 1

    local lfunc = function(loc) 
        if (signals[layerNum][loc.x][loc.y] < SIGNAL_MAX) then 
            signals[layerNum][loc.x][loc.y] =
                math.min(SIGNAL_MAX, signals[layerNum][loc.x][loc.y] + neighborIncreaseAmount)
        end
    end

    visitNeighborhood(loc, radius, lfunc)

    if (signals[layerNum][loc.x][loc.y] < SIGNAL_MAX) then 
        signals[layerNum][loc.x][loc.y] =
            math.min(SIGNAL_MAX, signals[layerNum][loc.x][loc.y] + centerIncreaseAmount)
    end
end

Signals.zeroFill = function(self) 
    for k, layer in pairs(self.data) do 
        layer:zeroFill()
    end
end 

Signals.fade(layerNum)
    local fadeAmount = 1

    for x = 0, p.sizeX -1 do
        for y = 0, p.sizeY -1 do
            if (signals[layerNum][x][y] >= fadeAmount) then 
                signals[layerNum][x][y] -= fadeAmount  -- // fade center cell
            else
                signals[layerNum][x][y] = 0
            end 
        end
    end
end

return Signals