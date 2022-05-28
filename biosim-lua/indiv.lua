
local Coord = require("biosim-lua.Coord")
require("biosim-lua.basicTypes")

-- // Also see class Peeps.

Indiv = {
    alive       = true,
    index       = -1,           -- // index into peeps[] container
    loc         = Coord.new(),  -- // refers to a location in grid[][]
    birthLoc    = Coord.new(),
    age         = 0,            -- // Age isnt age - its a timer?
    genome      = {},           
    nnet        = {},           -- // derived from .genome
    responsiveness = 0.0,       -- // 0.0..1.0 (0 is like asleep)
    oscPeriod   = 2.0,          -- // 2..4*p.stepsPerGeneration (TBD, see executeActions())
    longProbeDist = 0.0,        -- // distance for long forward probe for obstructions
    lastMoveDir = Dir.new(),    -- // direction of last movement
    challengeBits = 0,          -- // modified when the indiv accomplishes some task
}

Indiv.initialize = function(self, index, loc, genome)

    self.index = index
    self.loc = loc
    self.birthLoc = loc
    grid:set(loc, index)
    self.age = 0
    self.nnet = NeuralNet.new()
    self.oscPeriod = 34 -- // ToDo !!! define a constant
    self.alive = true
    self.responsiveness = 0.5 -- // range 0.0..1.0
    self.longProbeDist = p.longProbeDistance
    self.challengeBits = false -- // will be set true when some task gets accomplished
    self.genome = table.shallowcopy(genome)
    self.lastMoveDir = Dir.random8()

    self:createWiringFromGenome()
end 


Indiv.printNeuralNet = function(self)
end 

-- /********************************************************************************
-- This function does a neural net feed-forward operation, from sensor (input) neurons
-- through internal neurons to action (output) neurons. The feed-forward
-- calculations are evaluated once each simulator step (simStep).

-- There is no back-propagation in this simulator. Once an individual's neural net
-- brain is wired at birth, the weights and topology do not change during the
-- individual's lifetime.

-- The data structure Indiv::neurons contains internal neurons, and Indiv::connections
-- holds the connections between the neurons.

-- We have three types of neurons:

--      input sensors - each gives a value in the range SENSOR_MIN.. SENSOR_MAX (0.0..1.0).
--          Values are obtained from getSensor().

--      internal neurons - each takes inputs from sensors or other internal neurons;
--          each has output value in the range NEURON_MIN..NEURON_MAX (-1.0..1.0). The
--          output value for each neuron is stored in Indiv::neurons[] and survives from
--          one simStep to the next. (For example, a neuron that feeds itself will use
--          its output value that was latched from the previous simStep.) Inputs to the
--          neurons are summed each simStep in a temporary container and then discarded
--          after the neurons' outputs are computed.

--      action (output) neurons - each takes inputs from sensors or other internal
--          neurons; In this function, each has an output value in an arbitrary range
--          (because they are the raw sums of zero or more weighted inputs).
--          The values of the action neurons are saved in local container
--          actionLevels[] which is returned to the caller by value (thanks RVO).
-- ********************************************************************************/

Indiv.feedForward = function(self, simStep)

    -- // This container is used to return values for all the action outputs. This array
    -- // contains one value per action neuron, which is the sum of all its weighted
    -- // input connections. The sum has an arbitrary range. Return by value assumes compiler
    -- // return value optimization.
    local actionLevels = {}
    for i=0, Action.NUM_ACTIONS do actionLevels[i] = 0.0 end -- // undriven actions default to value 0.0
    -- // Weighted inputs to each neuron are summed in neuronAccumulators[]
    local neuronAccumulators = {}
    local neuronCount = table.count(self.nnet.neurons)
    for i = 0, neuronCount do neuronAccumulators[i] = 0.0 end 

    -- // Connections were ordered at birth so that all connections to neurons get
    -- // processed here before any connections to actions. As soon as we encounter the
    -- // first connection to an action, we'll pass all the neuron input accumulators
    -- // through a transfer function and update the neuron outputs in the indiv,
    -- // except for undriven neurons which act as bias feeds and don't change. The
    -- // transfer function will leave each neuron's output in the range -1.0..1.0.

    local neuronOutputsComputed = false
    for k, conn in pairs(self.nnet.connections) do
        if ((conn.sinkType == ACTION) and (neuronOutputsComputed == false)) then 
            -- // We've handled all the connections from sensors and now we are about to
            -- // start on the connections to the action outputs, so now it's time to
            -- // update and latch all the neuron outputs to their proper range (-1.0..1.0)

            for neuronIndex = 0, neuronCount -1 do
                if (self.nnet.neurons[neuronIndex].driven) then
                    self.nnet.neurons[neuronIndex].output = math.tanh(neuronAccumulators[neuronIndex])
                end 
            end 
            neuronOutputsComputed = true
        end

        -- // Obtain the connection's input value from a sensor neuron or other neuron
        -- // The values are summed for now, later passed through a transfer function
        local inputVal = 0
        if (conn.sourceType == SENSOR) then 
            inputVal = self:getSensor(conn.sourceNum, simStep)
        else             
            inputVal = self.nnet.neurons[conn.sourceNum].output
        end

        -- // Weight the connection's value and add to neuron accumulator or action accumulator.
        -- // The action and neuron accumulators will therefore contain +- float values in
        -- // an arbitrary range.
        if (conn.sinkType == ACTION) then           
            actionLevels[conn.sinkNum] = actionLevels[conn.sinkNum] + inputVal * conn:weightAsFloat()
        else 
            -- pprint(conn.sinkNum, table.count(neuronAccumulators) )
            assert(neuronAccumulators[conn.sinkNum] ~= nil, "conn.sinkNum: "..conn.sinkNum.."    "..table.count(neuronAccumulators))
            neuronAccumulators[conn.sinkNum] = neuronAccumulators[conn.sinkNum] + inputVal * conn:weightAsFloat()
        end 
    end

    return actionLevels
end

local sensorNumFunc = {
    [Sensor.AGE]= function(self)
    -- // Converts age (units of simSteps compared to life expectancy)
    -- // linearly to normalized sensor range 0.0..1.0
        return self.age / p.stepsPerGeneration
    end,
    [Sensor.BOUNDARY_DIST] = function(self)   
    -- // Finds closest boundary, compares that to the max possible dist
    -- // to a boundary from the center, and converts that linearly to the
    -- // sensor range 0.0..1.0
        local distX = math.min(self.loc.x, (p.sizeX - self.loc.x) - 1)
        local distY = math.min(self.loc.y, (p.sizeY - self.loc.y) - 1)
        local closest = math.min(distX, distY)
        local maxPossible = math.max(p.sizeX / 2 - 1, p.sizeY / 2 - 1)
        return closest / maxPossible
    end,

    [Sensor.BOUNDARY_DIST_X] = function(self)   
    -- // Measures the distance to nearest boundary in the east-west axis,
    -- // max distance is half the grid width; scaled to sensor range 0.0..1.0.
        local minDistX = math.min(self.loc.x, (p.sizeX - self.loc.x) - 1)
        return minDistX / (p.sizeX / 2.0)
    end,

    [Sensor.BOUNDARY_DIST_Y]= function(self)
    -- // Measures the distance to nearest boundary in the south-north axis,
    -- // max distance is half the grid height; scaled to sensor range 0.0..1.0.
        local minDistY = math.min(self.loc.y, (p.sizeY - self.loc.y) - 1)
        return minDistY / (p.sizeY / 2.0)
    end,

    [Sensor.LAST_MOVE_DIR_X]= function(self)   
    -- // X component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
        local lastX = self.lastMoveDir:asNormalizedCoord().x
        local val = 1.0 
        if(lastX == -1) then val = 0.0 end 
        local sensorVal = val 
        if(lastX == 0) then sensorVal = 0.5 end 
        return sensorVal 
    
    end,

    [Sensor.LAST_MOVE_DIR_Y]= function(self)   
        -- // Y component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
        local lastY = self.lastMoveDir:asNormalizedCoord().y
        local val = 1.0 
        if(lastY == -1) then val = 0.0 end 
        local sensorVal = val 
        if(lastY == 0) then sensorVal = 0.5 end 
        return sensorVal 
    end,

    [Sensor.LOC_X]= function(self)
        -- // Maps current X location 0..p.sizeX-1 to sensor range 0.0..1.0
        return self.loc.x / (p.sizeX - 1)
    end,

    [Sensor.LOC_Y]= function(self)
        -- // Maps current Y location 0..p.sizeY-1 to sensor range 0.0..1.0
        return self.loc.y / (p.sizeY - 1)
    end,

    [Sensor.OSC1]= function(self)
        -- // Maps the oscillator sine wave to sensor range 0.0..1.0;
        -- // cycles starts at simStep 0 for everbody.
        local phase = (simStep % self.oscPeriod) / self.oscPeriod -- // 0.0..1.0
        local factor = -math.cos(phase * 2.0 * 3.1415927)
        assert(factor >= -1.0 and factor <= 1.0)
        factor = factor + 1.0   --  // convert to 0.0..2.0
        factor = factor / 2.0   --  // convert to 0.0..1.0
        local sensorVal = factor
        -- // Clip any round-off error
        return math.min(1.0, math.max(0.0, sensorVal))
    end,

    [Sensor.LONGPROBE_POP_FWD] = function(self)   
        -- // Measures the distance to the nearest other individual in the
        -- // forward direction. If non found, returns the maximum sensor value.
        -- // Maps the result to the sensor range 0.0..1.0.
        return longProbePopulationFwd(self.loc, self.lastMoveDir, self.longProbeDist) / self.longProbeDist -- // 0..1
    end,

    [Sensor.LONGPROBE_BAR_FWD] = function(self)
        -- // Measures the distance to the nearest barrier in the forward
        -- // direction. If non found, returns the maximum sensor value.
        -- // Maps the result to the sensor range 0.0..1.0.
        return longProbeBarrierFwd(self.loc, self.lastMoveDir, self.longProbeDist) / self.longProbeDist -- // 0..1
    end,

    [Sensor.POPULATION]= function(self)   
        -- // Returns population density in neighborhood converted linearly from
        -- // 0..100% to sensor range
        local countLocs = 0
        local countOccupied = 0
        local center = self.loc

        local f = function(tloc) 
            countLocs = countLocs + 1
            if (grid:isOccupiedAt(tloc)) then 
                countOccupied = countOccupied + 1
            end 
        end 

        visitNeighborhood(center, p.populationSensorRadius, f)
        return countOccupied / countLocs
    end,

    [Sensor.POPULATION_FWD]= function(self)
        -- // Sense population density along axis of last movement direction, mapped
        -- // to sensor range 0.0..1.0
        return getPopulationDensityAlongAxis(self.loc, self.lastMoveDir)
    end, 

    [Sensor.POPULATION_LR]= function(self)
        -- // Sense population density along an axis 90 degrees from last movement direction
        return getPopulationDensityAlongAxis(self.loc, self.lastMoveDir:rotate90DegCW())
    end, 

    [Sensor.BARRIER_FWD]= function(self)
        -- // Sense the nearest barrier along axis of last movement direction, mapped
        -- // to sensor range 0.0..1.0
        return getShortProbeBarrierDistance(self.loc, self.lastMoveDir, p.shortProbeBarrierDistance)
    end, 

    [Sensor.BARRIER_LR]= function(self)
        -- // Sense the nearest barrier along axis perpendicular to last movement direction, mapped
        -- // to sensor range 0.0..1.0
        return getShortProbeBarrierDistance(self.loc, self.lastMoveDir:rotate90DegCW(), p.shortProbeBarrierDistance)
    end, 

    [Sensor.RANDOM]= function(self)
        -- // Returns a random sensor value in the range 0.0..1.0.
        return randomUint:Get() / UINT_MAX
    end, 

    [Sensor.SIGNAL0]= function(self)
        -- // Returns magnitude of signal0 in the local neighborhood, with
        -- // 0.0..maxSignalSum converted to sensorRange 0.0..1.0
        return getSignalDensity(0, self.loc)
    end,

    [Sensor.SIGNAL0_FWD]= function(self)
        -- // Sense signal0 density along axis of last movement direction
        return getSignalDensityAlongAxis(0, self.loc, self.lastMoveDir)
    end,

    [Sensor.SIGNAL0_LR]= function(self)
        -- // Sense signal0 density along an axis perpendicular to last movement direction
        return getSignalDensityAlongAxis(0, self.loc, self.lastMoveDir:rotate90DegCW())
    end, 

    [Sensor.GENETIC_SIM_FWD]= function(self)
        -- // Return minimum sensor value if nobody is alive in the forward adjacent location,
        -- // else returns a similarity match in the sensor range 0.0..1.0
        local loc2 = self.loc:ADDDIR(self.lastMoveDir)
        if (grid:isInBounds(loc2) and grid:isOccupiedAt(loc2)) then
            local indiv2 = peeps:getIndiv(loc2)
            if (indiv2.alive and indiv2.index > 0) then
                return genomeSimilarity(self.genome, indiv2.genome) -- // 0.0..1.0
            end 
        end
        return 0.0
    end, 
}

-- // Returned sensor values range SENSOR_MIN..SENSOR_MAX
Indiv.getSensor = function(self, sensorNum, simStep) 

    local sensorVal = 0.0
    local func = sensorNumFunc[sensorNum]
    if(func == nil) then print("Invalid sensor number: "..tostring(sensorNum)) end
    sensorVal = func(self)
    
    if (sensorVal < -0.01 or sensorVal > 1.01) then
        -- // std::cout << "sensorVal=" << (int)sensorVal << " for " << sensorName((Sensor)sensorNum) << std::endl;
        sensorVal = math.max(0.0, math.min(sensorVal, 1.0)) -- // clip
    end 

    if(sensorVal ~= sensorVal) then sensorVal = 0 end 

    assert( (sensorVal == sensorVal) and sensorVal >= -0.01 and sensorVal <= 1.01, "[ASSERT] sensorVal: "..tostring(sensorVal).. "  sensorNum: "..tostring(sensorNum))
    return sensorVal
end

-- // Format: 32-bit hex strings, one per gene
Indiv.printGenome = function(self)

    local genesPerLine = 8
    local count = 0
    for k,gene in pairs(self.genome) do
        if (count == genesPerLine) then 
            io.write("\n")
            count = 0
        elseif(count ~= 0) then 
            io.write(" ")
        end 

        for i,c in gene do 
            io.write(string.char(tonumber(c)))
        end 
        count = count + 1
    end 
    io.write("\n")
    pprint(" ")
end

-- // This prints a neural net in a form that can be processed with
-- // graph-nnet.py to produce a graphic illustration of the net.
Indiv.printIGraphEdgeList = function(self) 

    for k, conn in pairs(self.nnet.connections) do
        if (conn.sourceType == SENSOR) then 
            pprint( sensorShortName(conn.sourceNum) )
        else
            pprint("N"..tostring(conn.sourceNum))
        end 

        pprint(" ")

        if (conn.sinkType == ACTION) then 
            pprint( actionShortName(conn.sinkNum) )
        else 
            pprint( "N" ..tostring(conn.sinkNum) )
        end 

        pprint( " "..tostring(conn.weight) )
    end 
end 

-- // This prints a neural net in a form that can be processed with
-- // graph-nnet.py to produce a graphic illustration of the net.
Indiv.getIGraphEdgeList = function(self, lines) 

    for k, conn in pairs(self.nnet.connections) do 

        local line = ""
        if (conn.sourceType == SENSOR) then 
            line = line..sensorShortName(conn.sourceNum)
        else
            line = line.."N"
            line = line..tostring(conn.sourceNum)
        end 

        line = line.." -- "

        if (conn.sinkType == ACTION) then 
            line = line..actionShortName(conn.sinkNum)
        else
            line = line.."N"
            line = line..tostring(conn.sinkNum)
        end 

        line = line.."     "
        line = line..tostring(conn.weight)

        tinsert(lines, line)
    end 
end

-- // This function is used when an agent is spawned. This function converts the
-- // agent's inherited genome into the agent's neural net brain. There is a close
-- // correspondence between the genome and the neural net, but a connection
-- // specified in the genome will not be represented in the neural net if the
-- // connection feeds a neuron that does not itself feed anything else.
-- // Neurons get renumbered in the process:
-- // 1. Create a set of referenced neuron numbers where each index is in the
-- //    range 0..p.genomeMaxLength-1, keeping a count of outputs for each neuron.
-- // 2. Delete any referenced neuron index that has no outputs or only feeds itself.
-- // 3. Renumber the remaining neurons sequentially starting at 0.
Indiv.createWiringFromGenome = function(self)

    local nodeMap = {} --  // list of neurons and their number of inputs and outputs
    local connectionList = {} -- // synaptic connections

    -- // Convert the indiv's genome to a renumbered connection list
    makeRenumberedConnectionList(connectionList, self.genome)

    -- // Make a node (neuron) list from the renumbered connection list
    makeNodeList(nodeMap, connectionList)

    -- // Find and remove neurons that don't feed anything or only feed themself.
    -- // This reiteratively removes all connections to the useless neurons.
    cullUselessNeurons(connectionList, nodeMap)

    -- // The neurons map now has all the referenced neurons, their neuron numbers, and
    -- // the number of outputs for each neuron. Now we'll renumber the neurons
    -- // starting at zero.
    assert(table.count(nodeMap) <= p.maxNumberNeurons)
    local newNumber = 0
    for k,node in pairs(nodeMap) do
        assert(node.numOutputs ~= 0)
        node.remappedNumber = newNumber
        newNumber = newNumber + 1
    end

    -- // Create the indiv's connection list in two passes:
    -- // First the connections to neurons, then the connections to actions.
    -- // This ordering optimizes the feed-forward function in feedForward.cpp.

    self.nnet.connections = {}
    -- // First, the connections from sensor or neuron to a neuron
    for k,conn in pairs(connectionList) do
        if (conn.sinkType == NEURON) then
            local newConn = table.shallowcopy(conn)
            tinsert(self.nnet.connections, newConn)
            -- // fix the destination neuron number
            local newConnsinkNum = nodeMap[newConn.sinkNum].remappedNumber
            -- // if the source is a neuron, fix its number too    
            if (newConn.sourceType == NEURON) then
                newConn.sourceNum = nodeMap[newConn.sourceNum].remappedNumber
            end
        end
    end

    -- // Last, the connections from sensor or neuron to an action
    for k,conn in pairs(connectionList) do 
        if (conn.sinkType == ACTION) then 
            local newConn = table.shallowcopy(conn)
            tinsert(self.nnet.connections, newConn)
            -- // if the source is a neuron, fix its number
            if (newConn.sourceType == NEURON) then
                newConn.sourceNum = nodeMap[newConn.sourceNum].remappedNumber
            end
        end
    end

    -- // Create the indiv's neural node list
    self.nnet.neurons = {}
    local idx = 0
    for k,v in pairs(nodeMap) do 
        local newnode = Node.new()
        newnode.output = initialNeuronOutput()
        newnode.driven = (nodeMap[k].numInputsFromSensorsOrOtherNeurons ~= 0)
        self.nnet.neurons[idx] = newnode
        idx = idx + 1
    end 

end

Indiv_new = function()
    return table.shallowcopy(Indiv)
end 

return Indiv