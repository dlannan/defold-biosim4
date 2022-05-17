-- // This converts sensor numbers to descriptive strings.
local sensorNameFunc = {
    [Sensor.AGE ] = function() return "age" end,
    [Sensor.BOUNDARY_DIST ] = function() return "boundary dist" end, 
    [Sensor.BOUNDARY_DIST_X ] = function() return "boundary dist X" end,
    [Sensor.BOUNDARY_DIST_Y ] = function() return "boundary dist Y" end,
    [Sensor.LAST_MOVE_DIR_X ] = function() return "last move dir X" end,
    [Sensor.LAST_MOVE_DIR_Y ] = function() return "last move dir Y" end,
    [Sensor.LOC_X ] = function() return "loc X" end,
    [Sensor.LOC_Y ] = function() return "loc Y" end,
    [Sensor.LONGPROBE_POP_FWD ] = function() return "long probe population fwd" end,
    [Sensor.LONGPROBE_BAR_FWD ] = function() return "long probe barrier fwd" end,
    [Sensor.BARRIER_FWD ] = function() return "short probe barrier fwd-rev" end,
    [Sensor.BARRIER_LR ] = function() return "short probe barrier left-right" end,
    [Sensor.OSC1 ] = function() return "osc1" end,
    [Sensor.POPULATION ] = function() return "population" end,
    [Sensor.POPULATION_FWD ] = function() return "population fwd" end,
    [Sensor.POPULATION_LR ] = function() return "population LR" end,
    [Sensor.RANDOM ] = function() return "random" end,
    [Sensor.SIGNAL0 ] = function() return "signal 0" end,
    [Sensor.SIGNAL0_FWD ] = function() return "signal 0 fwd" end,
    [Sensor.SIGNAL0_LR ] = function() return "signal 0 LR" end,
    [Sensor.GENETIC_SIM_FWD ] = function() return "genetic similarity fwd" end,
}

sensorName = function(sensor)

    local func = sensorNameFunc[sensor]
    if(func == nil) then print("[ERROR] Invalid Sensor Name: "..sensor); assert(false) end 
    return func()
end

local actionNameFunc = {
    [Action.MOVE_EAST ] = function() return "move east" end,
    [Action.MOVE_WEST ] = function() return "move west" end,
    [Action.MOVE_NORTH ] = function() return "move north" end,
    [Action.MOVE_SOUTH ] = function() return "move south" end,
    [Action.MOVE_FORWARD ] = function() return "move fwd" end,
    [Action.MOVE_X ] = function() return "move X" end,
    [Action.MOVE_Y ] = function() return "move Y" end,
    [Action.SET_RESPONSIVENESS ] = function() return "set inv-responsiveness" end,
    [Action.SET_OSCILLATOR_PERIOD ] = function() return "set osc1" end,
    [Action.EMIT_SIGNAL0 ] = function() return "emit signal 0" end,
    [Action.KILL_FORWARD ] = function() return "kill fwd" end,
    [Action.MOVE_REVERSE ] = function() return "move reverse" end,
    [Action.MOVE_LEFT ] = function() return "move left" end,
    [Action.MOVE_RIGHT ] = function() return "move right" end,
    [Action.MOVE_RL ] = function() return "move R-L" end,
    [Action.MOVE_RANDOM ] = function() return "move random" end,
    [Action.SET_LONGPROBE_DIST ] = function() return "set longprobe dist" end,    
}

-- // Converts action numbers to descriptive strings.
actionName = function(action)

    local func = actionNameFunc[action]
    if(func == nil) then print("[ERROR] Invalid Action Name: "..action); assert(false) end 
    return func()
end

local sensorShortNameFunc = {
    [Sensor.AGE ] = function() return "Age" end,
    [Sensor.BOUNDARY_DIST ] = function() return "ED" end,
    [Sensor.BOUNDARY_DIST_X ] = function() return "EDx" end,
    [Sensor.BOUNDARY_DIST_Y ] = function() return "EDy" end,
    [Sensor.LAST_MOVE_DIR_X ] = function() return "LMx" end,
    [Sensor.LAST_MOVE_DIR_Y ] = function() return "LMy" end,
    [Sensor.LOC_X ] = function() return "Lx" end,
    [Sensor.LOC_Y ] = function() return "Ly" end,
    [Sensor.LONGPROBE_POP_FWD ] = function() return "LPf" end,
    [Sensor.LONGPROBE_BAR_FWD ] = function() return "LPb" end,
    [Sensor.BARRIER_FWD ] = function() return "Bfd" end,
    [Sensor.BARRIER_LR ] = function() return "Blr" end,
    [Sensor.OSC1 ] = function() return "Osc" end,
    [Sensor.POPULATION ] = function() return "Pop" end,
    [Sensor.POPULATION_FWD ] = function() return "Pfd" end,
    [Sensor.POPULATION_LR ] = function() return "Plr" end,
    [Sensor.RANDOM ] = function() return "Rnd" end,
    [Sensor.SIGNAL0 ] = function() return "Sg" end,
    [Sensor.SIGNAL0_FWD ] = function() return "Sfd" end,
    [Sensor.SIGNAL0_LR ] = function() return "Slr" end,
    [Sensor.GENETIC_SIM_FWD ] = function() return "Gen" end,    
}
-- // This converts sensor numbers to mnemonic strings.
-- // Useful for later processing by graph-nnet.py.
sensorShortName = function(sensor)

    local func = sensorShortNameFunc[sensor]
    if(func == nil) then print("[ERROR] Invalid Sensor Short Name: "..sensor); assert(false) end 
    return func()
end

local actionShortNameFunc = {
    [Action.MOVE_EAST ] = function() return "MvE" end,
    [Action.MOVE_WEST ] = function() return "MvW" end,
    [Action.MOVE_NORTH ] = function() return "MvN" end,
    [Action.MOVE_SOUTH ] = function() return "MvS" end,
    [Action.MOVE_X ] = function() return "MvX" end,
    [Action.MOVE_Y ] = function() return "MvY" end,
    [Action.MOVE_FORWARD ] = function() return "Mfd" end,
    [Action.SET_RESPONSIVENESS ] = function() return "Res" end,
    [Action.SET_OSCILLATOR_PERIOD ] = function() return "OSC" end,
    [Action.EMIT_SIGNAL0 ] = function() return "SG" end,
    [Action.KILL_FORWARD ] = function() return "Klf" end,
    [Action.MOVE_REVERSE ] = function() return "Mrv" end,
    [Action.MOVE_LEFT ] = function() return "MvL" end,
    [Action.MOVE_RIGHT ] = function() return "MvR" end,
    [Action.MOVE_RL ] = function() return "MRL" end,
    [Action.MOVE_RANDOM ] = function() return "Mrn" end,
    [Action.SET_LONGPROBE_DIST ] = function() return "LPD" end,
}

-- // Converts action numbers to mnemonic strings.
-- // Useful for later processing by graph-nnet.py.
actionShortName = function(action)

    local func = actionShortNameFunc[sensor]
    if(func == nil) then print("[ERROR] Invalid Action Short Name: "..action); assert(false) end 
    return func()
end


-- // List the names of the active sensors and actions to stdout.
-- // "Active" means those sensors and actions that are compiled into
-- // the code. See sensors-actions.h for how to define the enums.
printSensorsActions = function()

    pprint("Sensors:")
    for i = 0, Sensor.NUM_SENSES-1 do
        pprint("  "..sensorName(i) )
    end 
    pprint("Actions:")
    for i = 0, Action.NUM_ACTIONS -1 do
        pprint("  "..actionName(i) )
    end 
    pprint(" ")
end 


-- ///*
-- //Example format:
-- //
-- //    ACTION_NAMEa from:
-- //    ACTION_NAMEb from:
-- //        SENSOR i
-- //        SENSOR j
-- //        NEURON n
-- //        NEURON m
-- //    Neuron x from:
-- //        SENSOR i
-- //        SENSOR j
-- //        NEURON n
-- //        NEURON m
-- //    Neuron y ...
-- //*/
-- //void Indiv::printNeuralNet() const
-- //{
-- //    for (unsigned action = 0; action < Action::NUM_ACTIONS; ++action) {
-- //        bool actionDisplayed = false;
-- //        for (auto & conn : nnet.connections) {
-- //
-- //            assert((conn.sourceType == NEURON && conn.sourceNum < p.maxNumberNeurons)
-- //                || (conn.sourceType == SENSOR && conn.sourceNum < Sensor::NUM_SENSES));
-- //            assert((conn.sinkType == ACTION && conn.sinkNum < Action::NUM_ACTIONS)
-- //                || (conn.sinkType == NEURON && conn.sinkNum < p.maxNumberNeurons));
-- //
-- //            if (conn.sinkType == ACTION && (conn.sinkNum) == action) {
-- //                if (!actionDisplayed) {
-- //                    std::cout << "Action " << actionName((Action)action) << " from:" << std::endl;
-- //                    actionDisplayed = true;
-- //                }
-- //                if (conn.sourceType == SENSOR) {
-- //                    std::cout << "   " << sensorName((Sensor)(conn.sourceNum));
-- //                } else {
-- //                    std::cout << "   Neuron " << (conn.sourceNum % nnet.neurons.size());
-- //                }
-- //                std::cout << " " << conn.weightAsFloat() << std::endl;
-- //            }
-- //        }
-- //    }
-- //
-- //    for (size_t neuronNum = 0; neuronNum < nnet.neurons.size(); ++neuronNum) {
-- //        bool neuronDisplayed = false;
-- //        for (auto & conn : nnet.connections) {
-- //            if (conn.sinkType == NEURON && (conn.sinkNum) == neuronNum) {
-- //                if (!neuronDisplayed) {
-- //                    std::cout << "Neuron " << neuronNum << " from:" << std::endl;
-- //                    neuronDisplayed = true;
-- //                }
-- //                if (conn.sourceType == SENSOR) {
-- //                    std::cout << "   " << sensorName((Sensor)(conn.sourceNum));
-- //                } else {
-- //                    std::cout << "   Neuron " << (conn.sourceNum);
-- //                }
-- //                std::cout << " " << conn.weightAsFloat() << std::endl;
-- //            }
-- //        }
-- //    }
-- //}
-- //

averageGenomeLength = function()

    count = 100
    numberSamples = 0
    sum = 0

    while (count > 0) do
        sum = sum + peeps:getIndivIndex(randomUint:GetRange(1, p.population)).genome:size()
        numberSamples = numberSamples + 1
        count = count - 1
    end 
    return sum / numberSamples
end 


-- // The epoch log contains one line per generation in a format that can be
-- // fed to graphlog.gp to produce a chart of the simulation progress.
-- // ToDo: remove hardcoded filename.
appendEpochLog = function(generation, numberSurvivors, murderCount)

    local foutput

    if (generation == 0) then
        foutput = io.open(p.logDir + "/epoch-log.txt", "r")
        foutput = io.close()
    end 

    foutput = io.open(p.logDir + "/epoch-log.txt", "a")
    if(foutput) then
        foutput:write( tostring(generation).." "..tostring(numberSurvivors).." "
            ..tostring(geneticDiversity()).." "..tostring(averageGenomeLength()).." "..tostring(murderCount).."\n")
    else
        assert(false)
    end 
end 


-- // Print stats about pheromone usage.
displaySignalUse = function()

    if (Sensor.SIGNAL0 > Sensor.NUM_SENSES and Sensor.SIGNAL0_FWD > Sensor.NUM_SENSES and Sensor.SIGNAL0_LR > Sensor.NUM_SENSES) then
        return
    end

    sum = 0
    count = 0

    for x = 0, p.sizeX do
        for y = 0, p.sizeY do
            local magnitude = signals:getMagnitude(0, Coord.new( x, y ))
            if (magnitude ~= 0) then
                count = count + 1
                sum = sum + magnitude
            end 
        end 
    end 
    pprint("Signal spread "..tostring(count / (p.sizeX * p.sizeY)).."%, average "..tostring(sum / (p.sizeX * p.sizeY)) )
end 


-- // Print how many connections occur from each kind of sensor neuron and to
-- // each kind of action neuron over the entire population. This helps us to
-- // see which sensors and actions are most useful for survival.
displaySensorActionReferenceCounts = function()

    local sensorCounts = {}
    local actionCounts = {}

    for index = 1, p.population do
        if (peeps:getIndivIndex(index).alive) then
            local indiv = peeps:getIndivIndex(index)
            for k, gene in pairs(indiv.nnet.connections) do 
                if (gene.sourceType == SENSOR) then 
                    assert(gene.sourceNum < Sensor.NUM_SENSES)
                    sensorCounts[gene.sourceNum] = sensorCounts[gene.sourceNum] + 1
                end 
                if (gene.sinkType == ACTION) then 
                    assert(gene.sinkNum < Action.NUM_ACTIONS)
                    actionCounts[gene.sinkNum] = actionCounts[gene.sinkNum] + 1
                end
            end 
        end 
    end 

    pprint("Sensors in use:")
    for i = 0, #sensorCounts - 1 do
        if (sensorCounts[i] > 0) then 
            pprint("  "..tostring(sensorCounts[i]).." - "..sensorName(i) )
        end 
    end 
    pprint("Actions in use:")
    for i = 0, #actionCounts - 1 do 
        if (actionCounts[i] > 0) then 
            pprint( "  "..tostring(actionCounts[i]).." - "..actionName(i) )
        end 
    end 
end 


displaySampleGenomes = function(count)

    local index = 1 -- // indexes start at 1
    for index = 1, p.population do 
        if (peeps:getIndivIndex(index).alive) then 
            pprint( "---------------------------\nIndividual ID "..tostring(index))
            peeps:getIndivIndex(index):printGenome()
            pprint(" ")

            -- //peeps:getIndivIndex(index):printNeuralNet()
            peeps:getIndivIndex(index):printIGraphEdgeList()

            pprint("---------------------------")
        end 
    end 

    displaySensorActionReferenceCounts();
end 