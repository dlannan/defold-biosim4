
local Coord = require("biosim-lua.Coord")

local challengeFunc = {

    -- // Survivors are those inside the circular area defined by
    -- // safeCenter and radius
    [Sim.CHALLENGE_CIRCLE]= function(indiv)
    
        local safeCenter = Coord.new( (p.sizeX / 4.0), (p.sizeY / 4.0) )
        local radius = p.sizeX / 4.0

        local offset = safeCenter:SUBCOORD( indiv.loc )
        local distance = offset.length()
        if( distance <= radius ) then 
            return { true, (radius - distance) / radius }
        else
            return { false, 0.0 }
        end
    end,

    -- // Survivors are all those on the right side of the arena
    [Sim.CHALLENGE_RIGHT_HALF]= function(indiv)
        if(indiv.loc.x > p.sizeX / 2) then 
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are all those on the right quarter of the arena
    [Sim.CHALLENGE_RIGHT_QUARTER]= function(indiv)
        if(indiv.loc.x > p.sizeX / 2 + p.sizeX / 4) then 
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are all those on the left eighth of the arena
    [Sim.CHALLENGE_LEFT_EIGHTH]= function(indiv)
        if(indiv.loc.x < p.sizeX / 8) then 
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are those not touching the border and with exactly the number
    -- // of neighbors defined by neighbors and radius, where neighbors includes self
    [Sim.CHALLENGE_STRING]= function(indiv)
        
        local minNeighbors = 22
        local maxNeighbors = 2
        local radius = 1.5

        if (grid:isBorder(indiv.loc)) then 
            return { false, 0.0 }
        end 

        local count = 0
        local f = function(loc2)
            if (grid:isOccupiedAt(loc2)) then count = count + 1 end
        end 

        visitNeighborhood(indiv.loc, radius, f)
        if (count >= minNeighbors and count <= maxNeighbors) then 
            return { true, 1.0 }
        else
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are those within the specified radius of the center. The score
    -- // is linearly weighted by distance from the center.
    [Sim.CHALLENGE_CENTER_WEIGHTED]= function(indiv)
    
        local safeCenter = Coord.new( (p.sizeX / 2.0), (p.sizeY / 2.0) )
        local radius = p.sizeX / 3.0

        local offset = safeCenter:SUBCOORD(indiv.loc)
        local distance = offset.length()
        if(distance <= radius) then 
            return { true, (radius - distance) / radius }
        else
            return { false, 0.0 }
        end
    end,

    -- // Survivors are those within the specified radius of the center
    [Sim.CHALLENGE_CENTER_UNWEIGHTED]= function(indiv)
        local safeCenter = Coord((p.sizeX / 2.0), (p.sizeY / 2.0))
        local radius = p.sizeX / 3.0

        local offset = safeCenter:SUBCOORD(indiv.loc)
        local distance = offset.length()
        if(distance <= radius) then 
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are those within the specified outer radius of the center and with
    -- // the specified number of neighbors in the specified inner radius.
    -- // The score is not weighted by distance from the center.
    [Sim.CHALLENGE_CENTER_SPARSE]= function(indiv)
        local safeCenter = Coord.new( (p.sizeX / 2.0), (p.sizeY / 2.0) )
        local outerRadius = p.sizeX / 4.0
        local innerRadius = 1.5
        local minNeighbors = 5 -- // includes self
        local maxNeighbors = 8

        local offset = safeCenter:SUBCOORD( indiv.loc )
        local distance = offset:length()
        if (distance <= outerRadius) then 
            local count = 0
            local f = function(loc2)
                if (grid:isOccupiedAt(loc2)) then count = count + 1 end 
            end 

            visitNeighborhood(indiv.loc, innerRadius, f)
            if (count >= minNeighbors and count <= maxNeighbors) then
                return { true, 1.0 }
            end 
        end
        return { false, 0.0 }
    end,

    -- // Survivors are those within the specified radius of any corner.
    -- // Assumes square arena.
    [Sim.CHALLENGE_CORNER]= function(indiv)
    
        assert(p.sizeX == p.sizeY)
        local radius = p.sizeX / 8.0

        local distance = (Coord.new(0, 0):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, 1.0 }
        end
        distance = (Coord.new(0, p.sizeY - 1):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, 1.0 }
        end 
        distance = (Coord.new(p.sizeX - 1, 0):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then
            return { true, 1.0 }
        end 
        distance = (Coord.new(p.sizeX - 1, p.sizeY - 1):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, 1.0 }
        end 
        return { false, 0.0 }
    end,

    -- // Survivors are those within the specified radius of any corner. The score
    -- // is linearly weighted by distance from the corner point.
    [Sim.CHALLENGE_CORNER_WEIGHTED]= function(indiv)

        assert(p.sizeX == p.sizeY)
        local radius = p.sizeX / 4.0

        local distance = (Coord.new(0, 0):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, (radius - distance) / radius }
        end 
        distance = (Coord.new(0, p.sizeY - 1):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, (radius - distance) / radius }
        end 
        distance = (Coord.new(p.sizeX - 1, 0):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, (radius - distance) / radius }
        end 
        distance = (Coord.new(p.sizeX - 1, p.sizeY - 1):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, (radius - distance) / radius }
        end 
        return { false, 0.0 }
    end,

    -- // This challenge is handled in endOfSimStep(), where individuals may die
    -- // at the end of any sim step. There is nothing else to do here at the
    -- // end of a generation. All remaining alive become parents.
    [Sim.CHALLENGE_RADIOACTIVE_WALLS]= function(indiv)
        return { true, 1.0 }
    end,

    -- // Survivors are those touching any wall at the end of the generation
    [Sim.CHALLENGE_AGAINST_ANY_WALL]= function(indiv)
        local onEdge = indiv.loc.x == 0 or indiv.loc.x == p.sizeX - 1
                    or indiv.loc.y == 0 or indiv.loc.y == p.sizeY - 1

        if (onEdge) then 
            return { true, 1.0 }
        else
            return { false, 0.0 }
        end 
    end, 

    -- // This challenge is partially handled in endOfSimStep(), where individuals
    -- // that are touching a wall are flagged in their Indiv record. They are
    -- // allowed to continue living. Here at the end of the generation, any that
    -- // never touch a wall will die. All that touched a wall at any time during
    -- // their life will become parents.
    [Sim.CHALLENGE_TOUCH_ANY_WALL]= function(indiv)
        if (indiv.challengeBits ~= 0) then
            return { true, 1.0 }
        else
            return { false, 0.0 }
        end
    end,

    -- // Everybody survives and are candidate parents, but scored by how far
    -- // they migrated from their birth location.
    [Sim.CHALLENGE_MIGRATE_DISTANCE]= function(indiv)
        -- //unsigned requiredDistance = p.sizeX / 2.0;
        local distance = (indiv.loc:SUB(indiv.birthLoc)):length()
        distance = distance / (float)(math.max(p.sizeX, p.sizeY))
        return { true, distance }
    end,

    -- // Survivors are all those on the left or right eighths of the arena
    [Sim.CHALLENGE_EAST_WEST_EIGHTHS]= function(indiv)
        if(indiv.loc.x < p.sizeX / 8 or indiv.loc.x >= (p.sizeX - p.sizeX / 8)) then
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are those within radius of any barrier center. Weighted by distance.
    [Sim.CHALLENGE_NEAR_BARRIER]= function(indiv)
        local radius = 20.0
        -- //radius = 20.0;
        radius = p.sizeX / 2
        -- //radius = p.sizeX / 4;

        local barrierCenters = grid:getBarrierCenters()
        local minDistance = 1e8
        for k,center in pairs(barrierCenters) do
            local distance = (indiv.loc:SUBCOORD(center)):length()
            if (distance < minDistance) then 
                minDistance = distance
            end 
        end
        if (minDistance <= radius) then 
            return { true, 1.0 - (minDistance / radius) }
        else
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are those not touching a border and with exactly one neighbor which has no other neighbor
    [Sim.CHALLENGE_PAIRS]= function(indiv)
        local onEdge = indiv.loc.x == 0 or indiv.loc.x == p.sizeX - 1
                    or indiv.loc.y == 0 or indiv.loc.y == p.sizeY - 1

        if (onEdge) then 
            return { false, 0.0 }
        end 

        local count = 0
        for x = indiv.loc.x - 1, indiv.loc.x do
            for y = indiv.loc.y - 1, indiv.loc.y do
                local tloc = Coord.new( x, y )
                if (tloc:NEQ(indiv.loc) and grid:isInBounds(tloc) and grid:isOccupiedAt(tloc)) then
                    count = count + 1
                    if (count == 1) then 
                        for x1 = tloc.x - 1, tloc.x do
                            for y1 = tloc.y - 1, tloc.y do
                                local tloc1 = Coord.new( x1, y1 )
                                if (tloc1:NEQ(tloc) and tloc1:NEQ(indiv.loc) and grid:isInBounds(tloc1) and grid:isOccupiedAt(tloc1)) then
                                    return { false, 0.0 }
                                end 
                            end 
                        end
                    else
                        return { false, 0.0 }
                    end 
                end
            end 
        end 
        if (count == 1) then 
            return { true, 1.0 }
        else 
            return { false, 0.0 }
        end 
    end, 

    -- // Survivors are those that contacted one or more specified locations in a sequence,
    -- // ranked by the number of locations contacted. There will be a bit set in their
    -- // challengeBits member for each location contacted.
    [Sim.CHALLENGE_LOCATION_SEQUENCE]= function(indiv)
        local count = 0
        local bits = indiv.challengeBits
        local maxNumberOfBits = #bits * 8

        for n = 0, maxNumberOfBits-1 do
            if (bit.band(bits, bit.lshift(1, n)) ~= 0) then
                count = count + 1
            end 
        end 
        if (count > 0) then
            return { true, count / maxNumberOfBits }
        else 
            return { false, 0.0 }
        end 
    end,

    -- // Survivors are all those within the specified radius of the NE corner
    [Sim.CHALLENGE_ALTRUISM_SACRIFICE]= function(indiv)
        -- //float radius = p.sizeX / 3.0; // in 128^2 world, holds 1429 agents
        local radius = p.sizeX / 4.0 -- // in 128^2 world, holds 804 agents
        -- //float radius = p.sizeX / 5.0; // in 128^2 world, holds 514 agents

        local distance = (Coord.new(p.sizeX - p.sizeX / 4, p.sizeY - p.sizeY / 4):SUBCOORD(indiv.loc)):length()
        if (distance <= radius) then 
            return { true, (radius - distance) / radius }
        else 
            return { false, 0.0 }
        end 
    end,


    -- // Survivors are those inside the circular area defined by
    -- // safeCenter and radius
    [Sim.CHALLENGE_ALTRUISM] = function(indiv)
        local safeCenter = Coord.new( (p.sizeX / 4.0), (p.sizeY / 4.0) )
        local radius = p.sizeX / 4.0 -- // in a 128^2 world, holds 3216

        local offset = safeCenter:SUBCOORD(indiv.loc)
        local distance = offset:length()
        if(distance <= radius) then 
            return { true, (radius - distance) / radius }
        else 
            return { false, 0.0 }
        end 
    end,
}


-- // Returns true and a score 0.0..1.0 if passed, false if failed
passedSurvivalCriterion = function(indiv, challenge)

    if (indiv.alive == false) then 
        return { false, 0.0 }
    end 


    local cfunc = challengeFunc[challenge]
    local result = cfunc(indiv)
    assert(result ~= nil, "[ERROR] Challenge: ", challenge)
    return result
end
