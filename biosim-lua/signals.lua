require("utils.copies")

local Coord = require("biosim-lua.Coord")

tinsert = table.insert

local Column = {
    Get = function(self, rowNum) return self.data[rowNum] end,
    zeroFill = function(self) 
        for k,v in pairs(self.data) do v = 0 end
    end,
    data = {},
}

Column.new = function(numRows) 
    local col = table.shallowcopy(Column) 
    for i = 0, numRows do col.data[i] = 0 end 
    return col
end


local Layer = {

    GetColumn = function(self, colNum) 
        return self.data[colNum] 
    end,
    zeroFill = function(self) 
        for k,col in pairs(self.data) do col:zeroFill() end 
    end,
    data = {}
}

Layer.new = function(numCols, numRows) 
    local layer = table.shallowcopy(Layer)
    for i = 0, numCols do 
        layer.data[i] = Column.new(numRows)
    end
    return layer
end

Signals = {
      data = {},
}

Signals.init = function(self, numLayers, sizeX, sizeY)

    for n = 0, numLayers do 
        self.data[n] =  Layer.new(sizeX, sizeY)
    end
end 

Signals.Get = function(self, layerNum) 
    return self.data[layerNum] 
end 

Signals.getMagnitude = function(self, layerNum, loc) 
    return self.data[layerNum].data[loc.x].data[loc.y] 
end

-- // Increases the specified location by centerIncreaseAmount,
-- // and increases the neighboring cells by neighborIncreaseAmount

-- // Is it ok that multiple readers are reading this container while
-- // this single thread is writing to it?  todo!!!
Signals.increment = function(self, layerNum, loc) 
    local radius = 1.5
    local centerIncreaseAmount = 2
    local neighborIncreaseAmount = 1

    local lfunc = function(loc) 
        if (self.data[layerNum].data[loc.x].data[loc.y] < SIGNAL_MAX) then 
            self.data[layerNum].data[loc.x].data[loc.y] =
            math.min(SIGNAL_MAX, self.data[layerNum].data[loc.x].data[loc.y] + neighborIncreaseAmount)
        end
    end

    visitNeighborhood(loc, radius, lfunc)

    if (self.data[layerNum].data[loc.x].data[loc.y] < SIGNAL_MAX) then 
        self.data[layerNum].data[loc.x].data[loc.y] =
            math.min(SIGNAL_MAX, self.data[layerNum].data[loc.x].data[loc.y] + centerIncreaseAmount)
    end
end

Signals.zeroFill = function(self) 
    for k, layer in pairs(self.data) do 
        layer:zeroFill()
    end
end 

Signals.fade = function(self, layerNum)
    local fadeAmount = 1

    for x = 0, p.sizeX -1 do
        for y = 0, p.sizeY -1 do
            if (self.data[layerNum].data[x].data[y] >= fadeAmount) then 
                self.data[layerNum].data[x].data[y] = self.data[layerNum].data[x].data[y] - fadeAmount  -- // fade center cell
            else
                self.data[layerNum].data[x].data[y] = 0
            end 
        end
    end
end

return Signals