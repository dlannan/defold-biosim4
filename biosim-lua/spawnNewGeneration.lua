
-- // Requires that the grid, signals, and peeps containers have been allocated.
-- // This will erase the grid and signal layers, then create a new population in
-- // the peeps container at random locations with random genomes.
initializeGeneration0 = function()

    -- // The grid has already been allocated, just clear and reuse it
    grid:zeroFill()
    grid:createBarrier(p.barrierType)

    -- // The signal layers have already been allocated, so just reuse them
    signals:zeroFill()
    
    -- // Spawn the population. The peeps container has already been allocated,
    -- // just clear and reuse it
    for index = 1, p.population do
        local indiv = peeps:getIndivIndex(index)
        indiv:initialize(index, grid:findEmptyLocation(), makeRandomGenome())
    end
    pprint("ZERO FILL and BARRIER DONE")
end


-- // Requires a container with one or more parent genomes to choose from.
-- // Called from spawnNewGeneration(). This requires that the grid, signals, and
-- // peeps containers have been allocated. This will erase the grid and signal
-- // layers, then create a new population in the peeps container with random
-- // locations and genomes derived from the container of parent genomes.
initializeNewGeneration = function(parentGenomes, generation)

    --generateChildGenome(const std::vector<Genome> &parentGenomes);

    -- // The grid, signals, and peeps containers have already been allocated, just
    -- // clear them if needed and reuse the elements
    grid:zeroFill()
    grid:createBarrier(p.barrierType)
    signals:zeroFill()

    -- // Spawn the population. This overwrites all the elements of peeps[]
    for index = 1, p.population do
        peeps:getIndivIndex(index):initialize(index, grid:findEmptyLocation(), generateChildGenome(parentGenomes))
    end 
end

-- // At this point, the deferred death queue and move queue have been processed
-- // and we are left with zero or more individuals who will repopulate the
-- // world grid.
-- // In order to redistribute the new population randomly, we will save all the
-- // surviving genomes in a container, then clear the grid of indexes and generate
-- // new individuals. This is inefficient when there are lots of survivors because
-- // we could have reused (with mutations) the survivors' genomes and neural
-- // nets instead of rebuilding them.
-- // Returns number of survivor-reproducers.
-- // Must be called in single-thread mode between generations.
spawnNewGeneration = function(generation, murderCount)

    local sacrificedCount = 0 -- // for the altruism challenge

    -- extern void appendEpochLog(unsigned generation, unsigned numberSurvivors, unsigned murderCount);
    -- extern std::pair<bool, float> passedSurvivalCriterion(const Indiv &indiv, unsigned challenge);
    -- extern void displaySignalUse();

    -- // This container will hold the indexes and survival scores (0.0..1.0)
    -- // of all the survivors who will provide genomes for repopulation.
    local parents = {} -- // <indiv index, score>

    -- // This container will hold the genomes of the survivors
    local parentGenomes = {}

    if (p.challenge ~= CHALLENGE_ALTRUISM) then 
        -- // First, make a list of all the individuals who will become parents; save
        -- // their scores for later sorting. Indexes start at 1.
        for index = 1, p.population do
            local passed = passedSurvivalCriterion(peeps:getIndivIndex(index), p.challenge)
            -- // Save the parent genome if it results in valid neural connections
            -- // ToDo: if the parents no longer need their genome record, we could
            -- // possibly do a move here instead of copy, although it's doubtful that
            -- // the optimization would be noticeable.
            if (passed.first and not peeps:getIndivIndex(index).nnet.connections:empty()) then
                tinsert(parents, { index, passed[2] } )
            end 
        end 
    else
        -- // For the altruism challenge, test if the agent is inside either the sacrificial
        -- // or the spawning area. We'll count the number in the sacrificial area and
        -- // save the genomes of the ones in the spawning area, saving their scores
        -- // for later sorting. Indexes start at 1.

        local considerKinship = true
        local sacrificesIndexes = {}  -- // those who gave their lives for the greater good

        for index = 1, p.population do
            -- // This the test for the spawning area:
            local passed = passedSurvivalCriterion(peeps:getIndivIndex(index), CHALLENGE_ALTRUISM)
            if (passed[1] and not peeps:getIndivIndex(index).nnet.connections:empty()) then
                tinsert(parents, { index, passed[2] } )
            else
                -- // This is the test for the sacrificial area:
                passed = passedSurvivalCriterion(peeps:getIndivIndex(index), CHALLENGE_ALTRUISM_SACRIFICE);
                if (passed[1] and not peeps:getIndivIndex(index).nnet.connections:empty()) then
                    if (considerKinship) then
                        tinsert(sacrificesIndexes, index)
                    else 
                        sacrificedCount = sacrificedCount + 1
                    end 
                end 
            end 
        end 

        local generationToApplyKinship = 10
        local altruismFactor = 10 -- // the saved:sacrificed ratio

        if (considerKinship) then 
            if (generation > generationToApplyKinship) then 
                -- // Todo: optimize!!!
                local threshold = 0.7

                local survivingKin = {}
                for passes = 0, altruismFactor -1 do 
                    for k,sacrificedIndex in pairs(sacrificesIndexes) do
                        -- // randomize the next loop so we don't keep using the first one repeatedly
                        local startIndex = randomUint(0, #parents - 1)
                        for count = 0, #parents do 
                            local possibleParent = parents[(startIndex + count) % #parents]
                            local g1 = peeps:getIndivIndex(sacrificedIndex).genome
                            local g2 = peeps:getIndivIndex(possibleParent.first).genome
                            local similarity = genomeSimilarity(g1, g2)
                            if (similarity >= threshold) then 
                                tinsert(survivingKin, possibleParent)
                                -- // mark this one so we don't use it again?
                                break
                            end 
                        end 
                    end 
                end 
                print(tostring(#parents).." passed, "..
                            tostring(#sacrificesIndexes).." sacrificed, "..
                            tostring(#survivingKin).." saved" )
                parents = survivingKin
            end 
        else 
            -- // Limit the parent list
            local numberSaved = sacrificedCount * altruismFactor
            print( tostring(#parents).." passed, "..sacrificedCount.." sacrificed, "..numberSaved.." saved")
            if (#parents == 0 and numberSaved < #parents) then 
                for i = 0, numberSaved do parents[i] = nil end 
            end 
        end 
    end 

    -- // Sort the indexes of the parents by their fitness scores
    table.sort( parents, function( k1, k2 ) return k1[2] > k2[2] end )

    -- // Assemble a list of all the parent genomes. These will be ordered by their
    -- // scores if the parents[] container was sorted by score
    parentGenomes = {}
    for k, parent in ipairs(parents) do
        tinsert(parentGenomes, peeps:getIndivIndex(parent[1]).genome)
    end

    -- // std::cout << "Gen " << generation << ", " << parentGenomes.size() << " survivors" << std::endl;
    appendEpochLog(generation, #parentGenomes, murderCount)
    -- //displaySignalUse(); // for debugging only

    -- // Now we have a container of zero or more parents' genomes

    if (#parentGenomes > 0) then 
        -- // Spawn a new generation
        initializeNewGeneration(parentGenomes, generation + 1)
    else
        -- // Special case: there are no surviving parents: start the simulation over
        -- // from scratch with randomly-generated genomes
        initializeGeneration0()
    end 

    return #parentGenomes
end
