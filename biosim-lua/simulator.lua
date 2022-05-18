
-- // Some of the survival challenges to try. Some are interesting, some
-- // not so much. Fine-tune the challenges by tweaking the corresponding code
-- // in survival-criteria.cpp.

require("biosim-lua.globals")

local Sim = {}

Sim.CHALLENGE_CIRCLE = 0
Sim.CHALLENGE_RIGHT_HALF = 1
Sim.CHALLENGE_RIGHT_QUARTER = 2
Sim.CHALLENGE_STRING = 3
Sim.CHALLENGE_CENTER_WEIGHTED = 4
Sim.CHALLENGE_CENTER_UNWEIGHTED = 40
Sim.CHALLENGE_CORNER = 5
Sim.CHALLENGE_CORNER_WEIGHTED = 6
Sim.CHALLENGE_MIGRATE_DISTANCE = 7
Sim.CHALLENGE_CENTER_SPARSE = 8
Sim.CHALLENGE_LEFT_EIGHTH = 9
Sim.CHALLENGE_RADIOACTIVE_WALLS = 10
Sim.CHALLENGE_AGAINST_ANY_WALL = 11
Sim.CHALLENGE_TOUCH_ANY_WALL = 12
Sim.CHALLENGE_EAST_WEST_EIGHTHS = 13
Sim.CHALLENGE_NEAR_BARRIER = 14
Sim.CHALLENGE_PAIRS = 15
Sim.CHALLENGE_LOCATION_SEQUENCE = 16
Sim.CHALLENGE_ALTRUISM = 17
Sim.CHALLENGE_ALTRUISM_SACRIFICE = 18

-- /**********************************************************************************************
-- Execute one simStep for one individual.

-- This executes in its own thread, invoked from the main simulator thread. First we execute
-- indiv.feedForward() which computes action values to be executed here. Some actions such as
-- signal emission(s) (pheromones), agent movement, or deaths will have been queued for
-- later execution at the end of the generation in single-threaded mode (the deferred queues
-- allow the main data structures (e.g., grid, signals) to be freely accessed read-only in all threads).

-- In order to be thread-safe, the main simulator-wide data structures and their
-- accessibility are:

--     grid - read-only
--     signals - (pheromones) read-write for the location where our agent lives
--         using signals.increment(), read-only for other locations
--     peeps - for other individuals, we can only read their index and genome.
--         We have read-write access to our individual through the indiv argument.

-- The other important variables are:

--     simStep - the current age of our agent, reset to 0 at the start of each generation.
--          For many simulation scenarios, this matches our indiv.age member.
--     randomUint - global random number generator, a private instance is given to each thread
-- **********************************************************************************************/
local simStepOneIndiv = function(indiv, simStep)

    if(indiv.alive == true) then indiv.age = indiv.age + 1 end -- // for this implementation, tracks simStep
    local actionLevels = indiv:feedForward(simStep)
    executeActions(indiv, actionLevels)
end


-- /********************************************************************************
-- Start of simulator

-- All the agents are randomly placed with random genomes at the start. The outer
-- loop is generation, the inner loop is simStep. There is a fixed number of
-- simSteps in each generation. Agents can die at any simStep and their corpses
-- remain until the end of the generation. At the end of the generation, the
-- dead corpses are removed, the survivors reproduce and then die. The newborns
-- are placed at random locations, signals (pheromones) are updated, simStep is
-- reset to 0, and a new generation proceeds.

-- The paramManager manages all the simulator parameters. It starts with defaults,
-- then keeps them updated as the config file (biosim4.ini) changes.

-- The main simulator-wide data structures are:
--     grid - where the agents live (identified by their non-zero index). 0 means empty.
--     signals - multiple layers overlay the grid, hold pheromones
--     peeps - an indexed set of agents of type Indiv indexes start at 1

-- The important simulator-wide variables are:
--     generation - starts at 0, then increments every time the agents die and reproduce.
--     simStep - reset to 0 at the start of each generation fixed number per generation.
--     randomUint - global random number generator

-- The threads are:
--     main thread - simulator
--     simStepOneIndiv() - child threads created by the main simulator thread
--     imageWriter - saves image frames used to make a movie (possibly not threaded
--         due to unresolved bugs when threaded)
-- ********************************************************************************/

diversity   = 0.0
murderCount = 0
generation  = 0
survivors   = 0

local DoSimStep = function( _ctx )

    -- randomUint:initialize() -- // seed the RNG, each thread has a private instance

    if(generation < p.maxGenerations) then -- // generation loop

        if(runMode == RunMode.RUN) then 
            murderCount = 0 -- // for reporting purposes

            for simStep = 0, p.stepsPerGeneration-1 do
            
                -- // multithreaded loop: index 0 is reserved, start at 1
                for indivIndex = 1, p.population do
                    if (peeps:getIndivIndex(indivIndex).alive) then
                        simStepOneIndiv(peeps:getIndivIndex(indivIndex), simStep)
                    end
                end 

                -- // In single-thread mode: this executes deferred, queued deaths and movements,
                -- // updates signal layers (pheromone), etc.
                murderCount = murderCount + peeps.deathQueueSize()
                endOfSimStep(simStep, generation)
                print(murderCount)
            end

            endOfGeneration(generation)
            p:updateFromConfigFile(generation + 1)
            local numberSurvivors = spawnNewGeneration(generation, murderCount)
            -- // if (numberSurvivors > 0 && (generation % p.genomeAnalysisStride == 0)) {
            -- //     displaySampleGenomes(p.displaySampleGenomes)
            -- // }
            survivors = numberSurvivors
            if (numberSurvivors == 0) then 
                generation = 0  -- // start over
            else
                generation = generation + 1
            end
        end

        -- if(runMode == RunMode.STOP or runMode == RunMode.ABORT) then
        --     break
        -- end 
    end 
end 

Sim.simulator = function(self, filename)
    printSensorsActions()   -- // show the agents' capabilities

    -- // Simulator parameters are available read-only through the global
    -- // variable p after paramManager is initialized.
    -- // Todo: remove the hardcoded parameter filename.
    p:setDefaults()
    p:registerConfigFile(filename)
    p:updateFromConfigFile(0)
    p:checkParameters()      -- // check and report any problems
    randomUint:initialize()             -- // seed the RNG for main-thread use

    -- // Allocate container space. Once allocated, these container elements
    -- // will be reused in each new generation.
    pprint(p.sizeX, p.sizeY)
    grid:init(p.sizeX, p.sizeY)         -- // the land on which the peeps live
    signals:init(p.signalLayers, p.sizeX, p.sizeY)  -- // where the pheromones waft
    peeps:init(p.population)            -- // the peeps themselves

    -- // If imageWriter is to be run in its own thread, start it here:
    -- //std::thread t(&ImageWriter::saveFrameThread, &imageWriter);
    -- //dmThread::New(saveFrameThread, 0x80000, (void *)&imageWriter, "biosim_imagewriter_thread");

    -- // Unit tests:
    -- //unitTestConnectNeuralNetWiringFromGenome();
    -- //unitTestGridVisitNeighborhood();

    initializeGeneration0()     -- // starting population
    runMode = RunMode.PAUSE

    -- TODO: Change from using threads to timer or similar.
    -- dmThread::New(DoSimStep, 0x80000, nullptr, "biosim_thread");
end 

Sim.simulationStep = function( void )
    DoSimStep()
end 

Sim.simulationDone = function( void )
    displaySampleGenomes(3)     -- // final report, for debugging
    print("Simulator exit.")
end 

Sim.simulationMode = function( mode )
    runMode = mode
end

return Sim
    