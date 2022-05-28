require("utils.copies")
local Coord = require("biosim-lua.Coord")
local Indiv = require("biosim-lua.indiv")

tinsert = table.insert

-- // This class keeps track of alive and dead Indiv's and where they
-- // are in the Grid.
-- // Peeps allows spawning a live Indiv at a random or specific location
-- // in the grid, moving Indiv's from one grid location to another, and
-- // killing any Indiv.
-- // All the Indiv instances, living and dead, are stored in the private
-- // .individuals member. The .cull() function will remove dead members and
-- // replace their slots in the .individuals container with living members
-- // from the end of the container for compacting the container.
-- // Each Indiv has an identifying index in the range 1..0xfffe that is
-- // stored in the Grid at the location where the Indiv resides, such that
-- // a Grid element value n refers to .individuals[n]. Index value 0 is
-- // reserved, i.e., .individuals[0] is not a valid individual.
-- // This class does not manage properties inside Indiv except for the
-- // Indiv's location in the grid and its aliveness.
Peeps = {
    individuals = {}, -- // Index value 0 is reserved
    deathQueue  = {}, 
    moveQueue   = {},
}

Peeps.init = function(self, population)
    -- // Index 0 is reserved, so add one:
    for i=0, population do 
        self.individuals[i] = Indiv_new()
    end 
end

-- // Safe to call during multithread mode.
-- // Indiv will remain alive and in-world until end of sim step when
-- // drainDeathQueue() is called. It's ok if the same agent gets
-- // queued for death multiple times. It does not make sense to
-- // call this function for agents already dead.
Peeps.queueForDeath = function(self, indiv)
    assert(indiv.alive)

    tinsert(self.deathQueue, indiv.index)
end 

-- // Called in single-thread mode at end of sim step. This executes all the
-- // queued deaths, removing the dead agents from the grid.
Peeps.drainDeathQueue = function(self)
    for k, index in pairs(self.deathQueue) do
        indiv = peeps:getIndivIndex(index)
        grid:set(indiv.loc, 0)
        indiv.alive = false
    end 
    self.deathQueue = {}
end 

-- // Safe to call during multithread mode. Indiv won't move until end
-- // of sim step when drainMoveQueue() is called. Should only be called
-- // for living agents. It's ok if multiple agents are queued to move
-- // to the same location; only the first one will actually get moved.
Peeps.queueForMove = function(self, indiv, newLoc)
    assert(indiv.alive)
    tinsert(self.moveQueue, { indiv.index, newLoc })
end 

-- // Called in single-thread mode at end of sim step. This executes all the
-- // queued movements. Each movement is typically one 8-neighbor cell distance
-- // but this function can move an individual any arbitrary distance. It is
-- // possible that an agent queued for movement was recently killed when the
-- // death queue was drained, so we'll ignore already-dead agents.
Peeps.drainMoveQueue = function(self) 
    for k, moveRecord in pairs(self.moveQueue) do
        local indiv = peeps:getIndivIndex(moveRecord[1])
        if (indiv.alive) then 
            local newLoc = moveRecord[2]
            local moveDir = Dir.new(newLoc:SUBCOORD(indiv.loc):asDir())
            if (grid:isEmptyAt(newLoc)) then
                grid:set(indiv.loc, 0)
                grid:set(newLoc, indiv.index)
                indiv.loc = newLoc
                indiv.lastMoveDir = moveDir
            end 
        end 
    end 
    self.moveQueue = {}
end 

Peeps.deathQueueSize = function(self)  
    return #self.deathQueue 
end

-- // getIndiv() does no error checking -- check first that loc is occupied
Peeps.getIndiv = function(self, loc)
    return self.individuals[grid:at(loc)] 
end 

-- // Direct access:
Peeps.getIndivIndex = function(self, index)  
    return self.individuals[index] 
end

return Peeps