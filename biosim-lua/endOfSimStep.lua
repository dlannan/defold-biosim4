local Sim = require("biosim-lua.simulator")

/*
At the end of each sim step, this function is called in single-thread
mode to take care of several things:

1. We may kill off some agents if a "radioactive" scenario is in progress.
2. We may flag some agents as meeting some challenge criteria, if such
   a scenario is in progress.
3. We then drain the deferred death queue.
4. We then drain the deferred movement queue.
5. We fade the signal layer(s) (pheromones).
6. We save the resulting world condition as a single image frame (if
   p.saveVideo is true).
*/

endOfSimStep = function( simStep, generation)

    if (p.challenge == Sim.CHALLENGE_RADIOACTIVE_WALLS) then 
        -- // During the first half of the generation, the west wall is radioactive,
        -- // where X == 0. In the last half of the generation, the east wall is
        -- // radioactive, where X = the area width - 1. There's an exponential
        -- // falloff of the danger, falling off to zero at the arena half line.
        local radioactiveX = 0
        if(simStep < p.stepsPerGeneration / 2) then radioactiveX = p.sizeX - 1 end 

        for index = 1, p.population do -- // index 0 is reserved
            local indiv = peeps:getIndivIndex(index)
            if (indiv.alive) then 
                local distanceFromRadioactiveWall = math.abs(indiv.loc.x - radioactiveX)
                if (distanceFromRadioactiveWall < p.sizeX / 2) then 
                    local chanceOfDeath = 1.0 / distanceFromRadioactiveWall
                    if (randomUint:Get() / RANDOM_UINT_MAX < chanceOfDeath) then
                        peeps.queueForDeath(indiv)
                    end 
                end 
            end 
        end
    end

    -- // If the individual is touching any wall, we set its challengeFlag to true.
    -- // At the end of the generation, all those with the flag true will reproduce.
    if (p.challenge == Sim.CHALLENGE_TOUCH_ANY_WALL) then
        for (index = 1, p.population do -- // index 0 is reserved
            indiv = peeps:getIndivIndex(index)
            if (indiv.loc.x == 0 or indiv.loc.x == p.sizeX - 1 or
                indiv.loc.y == 0 or indiv.loc.y == p.sizeY - 1) then
                indiv.challengeBits = true
            end 
        end 
    end

    -- // If this challenge is enabled, the individual gets a bit set in their challengeBits
    -- // member if they are within a specified radius of a barrier center. They have to
    -- // visit the barriers in sequential order.
    if (p.challenge == Sim.CHALLENGE_LOCATION_SEQUENCE) then
        local radius = 9.0
        for index = 1, p.population do -- // index 0 is reserved
            indiv = peeps:getIndivIndex(index)
            for n = 0, grid:getBarrierCenters():size() -1 do
                local bit = bit.lshift(1, n)
                if (bit.band(indiv.challengeBits, bit) == 0) then 
                    if ((indiv.loc:SUB( grid:getBarrierCenters()[n])):length() <= radius) then
                        indiv.challengeBits = bit.bor(indiv.challengeBits, bit)
                    end 
                    break
                end
            end 
        end 
    end 

    peeps:drainDeathQueue()
    peeps:drainMoveQueue()
    signals:fade(0) -- // takes layerNum  todo!!!

    -- // saveVideoFrameSync() is the synchronous version of saveVideFrame()
    if (p.saveVideo and ((generation % p.videoStride) == 0 or
                generation <= p.videoSaveFirstFrames or
                (generation >= p.parameterChangeGenerationNumber and
                    generation <= p.parameterChangeGenerationNumber + p.videoSaveFirstFrames))) then
        if (imageWriter:saveVideoFrameSync(simStep, generation)) then
            print("imageWriter busy")
        end 
        -- if (!imageWriter.saveVideoFrame(simStep, generation)) {
        --     print("imageWriter busy")
        -- end 
    end  
end 
