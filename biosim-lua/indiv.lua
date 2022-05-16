
-- // Also see class Peeps.

Indiv {
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

Indiv.feedForward = function(self, simStep) -- // reads sensors, returns actions
end

Indiv.getSensor = function(self, Sensor, simStep)
end 

Indiv.createWiringFromGenome = function(self) -- // creates .nnet member from .genome member
end

Indiv.initialize = function(self, index, loc, genome)

    self.index = index_
    self.loc = loc_
    self.birthLoc = loc_
    grid:set(loc_, index_)
    self.age = 0
    self.oscPeriod = 34 -- // ToDo !!! define a constant
    self.alive = true
    self.lastMoveDir = Dir:random8()
    self.responsiveness = 0.5 -- // range 0.0..1.0
    self.longProbeDist = p.longProbeDistance
    self.challengeBits = false -- // will be set true when some task gets accomplished
    self.genome = table.deepcopy(genome_)
    self:createWiringFromGenome()
end 


Indiv.printNeuralNet = function(self)
end 

Indiv.printIGraphEdgeList = function(self)
end

Indiv.printGenome = function(self)
end

Indiv.getIGraphEdgeList = function(self, lines)
end

/********************************************************************************
This function does a neural net feed-forward operation, from sensor (input) neurons
through internal neurons to action (output) neurons. The feed-forward
calculations are evaluated once each simulator step (simStep).

There is no back-propagation in this simulator. Once an individual's neural net
brain is wired at birth, the weights and topology do not change during the
individual's lifetime.

The data structure Indiv::neurons contains internal neurons, and Indiv::connections
holds the connections between the neurons.

We have three types of neurons:

     input sensors - each gives a value in the range SENSOR_MIN.. SENSOR_MAX (0.0..1.0).
         Values are obtained from getSensor().

     internal neurons - each takes inputs from sensors or other internal neurons;
         each has output value in the range NEURON_MIN..NEURON_MAX (-1.0..1.0). The
         output value for each neuron is stored in Indiv::neurons[] and survives from
         one simStep to the next. (For example, a neuron that feeds itself will use
         its output value that was latched from the previous simStep.) Inputs to the
         neurons are summed each simStep in a temporary container and then discarded
         after the neurons' outputs are computed.

     action (output) neurons - each takes inputs from sensors or other internal
         neurons; In this function, each has an output value in an arbitrary range
         (because they are the raw sums of zero or more weighted inputs).
         The values of the action neurons are saved in local container
         actionLevels[] which is returned to the caller by value (thanks RVO).
********************************************************************************/

Indiv.feedForward(self, simStep)

    -- // This container is used to return values for all the action outputs. This array
    -- // contains one value per action neuron, which is the sum of all its weighted
    -- // input connections. The sum has an arbitrary range. Return by value assumes compiler
    -- // return value optimization.
    local actionLevels = {}
    -- actionLevels.fill(0.0); -- // undriven actions default to value 0.0

    -- // Weighted inputs to each neuron are summed in neuronAccumulators[]
    local neuronAccumulators = {}
    for i = 0, #self.nnet.neurons do neuronAccumulators[i] = 0.0 end 

    -- // Connections were ordered at birth so that all connections to neurons get
    -- // processed here before any connections to actions. As soon as we encounter the
    -- // first connection to an action, we'll pass all the neuron input accumulators
    -- // through a transfer function and update the neuron outputs in the indiv,
    -- // except for undriven neurons which act as bias feeds and don't change. The
    -- // transfer function will leave each neuron's output in the range -1.0..1.0.

    local neuronOutputsComputed = false
    for k, conn in pairs(nnet.connections) do
        if (conn.sinkType == ACTION and not neuronOutputsComputed) then 
            -- // We've handled all the connections from sensors and now we are about to
            -- // start on the connections to the action outputs, so now it's time to
            -- // update and latch all the neuron outputs to their proper range (-1.0..1.0)
            for neuronIndex = 0, #nnet.neurons -1 do
                if (nnet.neurons[neuronIndex].driven) then
                    nnet.neurons[neuronIndex].output = math.tanh(neuronAccumulators[neuronIndex])
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
            inputVal = nnet.neurons[conn.sourceNum].output
        end

        -- // Weight the connection's value and add to neuron accumulator or action accumulator.
        -- // The action and neuron accumulators will therefore contain +- float values in
        -- // an arbitrary range.
        if (conn.sinkType == ACTION) then
            actionLevels[conn.sinkNum] = actionLevels[conn.sinkNum] + inputVal * conn:weightAsFloat()
        else 
            neuronAccumulators[conn.sinkNum] = neuronAccumulators[conn.sinkNum] + inputVal * conn:weightAsFloat()
        end 
    end

    return actionLevels
end

-- // Returned sensor values range SENSOR_MIN..SENSOR_MAX
Indiv.getSensor = function(sensorNum, simStep) 

    local sensorVal = 0.0

    local sensorNumFunc = {
        Sensor.AGE = function()
        -- // Converts age (units of simSteps compared to life expectancy)
        -- // linearly to normalized sensor range 0.0..1.0
            return (float)age / p.stepsPerGeneration;
        end,
        Sensor.BOUNDARY_DIST = function()   
        -- // Finds closest boundary, compares that to the max possible dist
        -- // to a boundary from the center, and converts that linearly to the
        -- // sensor range 0.0..1.0
            local distX = math.min(loc.x, (p.sizeX - loc.x) - 1)
            local distY = math.min(loc.y, (p.sizeY - loc.y) - 1)
            local closest = math.min(distX, distY)
            local maxPossible = math.max(p.sizeX / 2 - 1, p.sizeY / 2 - 1)
            return closest / maxPossible
        end,
    
        Sensor.BOUNDARY_DIST_X = function()   
        -- // Measures the distance to nearest boundary in the east-west axis,
        -- // max distance is half the grid width; scaled to sensor range 0.0..1.0.
            local minDistX = math.min(loc.x, (p.sizeX - loc.x) - 1)
            return minDistX / (p.sizeX / 2.0)
        end,
    
        Sensor.BOUNDARY_DIST_Y = function()
        -- // Measures the distance to nearest boundary in the south-north axis,
        -- // max distance is half the grid height; scaled to sensor range 0.0..1.0.
            local minDistY = math.min(loc.y, (p.sizeY - loc.y) - 1)
            return minDistY / (p.sizeY / 2.0)
        end,

        Sensor.LAST_MOVE_DIR_X = function()   
        -- // X component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
            local lastX = lastMoveDir:asNormalizedCoord().x
            local val = 1.0 
            if(lastX == -1) then val = 0.0 end 
            sensorVal = val 
            if(lastX == 0) then sensorVal = 0.5 end 
            return sensorVal 
        
        end,

        Sensor.LAST_MOVE_DIR_Y = function()   
            -- // Y component -1,0,1 maps to sensor values 0.0, 0.5, 1.0
            local lastY = lastMoveDir:asNormalizedCoord().y
            local val = 1.0 
            if(lastY == -1) then val = 0.0 end 
            sensorVal = val 
            if(lastY == 0) then sensorVal = 0.5 end 
            return sensorVal 
        end,
    
        Sensor.LOC_X = function()
            -- // Maps current X location 0..p.sizeX-1 to sensor range 0.0..1.0
            return loc.x / (p.sizeX - 1)
        end,
    
        Sensor.LOC_Y = function()
            -- // Maps current Y location 0..p.sizeY-1 to sensor range 0.0..1.0
            return loc.y / (p.sizeY - 1)
        end,
    
        Sensor.OSC1 = function()
            -- // Maps the oscillator sine wave to sensor range 0.0..1.0;
            -- // cycles starts at simStep 0 for everbody.
            local phase = (simStep % oscPeriod) / (float)oscPeriod -- // 0.0..1.0
            local factor = -math.cos(phase * 2.0 * 3.1415927)
            assert(factor >= -1.0 and factor <= 1.0)
            factor = factor + 1.0   --  // convert to 0.0..2.0
            factor = factor / 2.0   --  // convert to 0.0..1.0
            sensorVal = factor
            -- // Clip any round-off error
            return math.min(1.0, math.max(0.0, sensorVal))
        end,
    
        Sensor.LONGPROBE_POP_FWD = function()   
            -- // Measures the distance to the nearest other individual in the
            -- // forward direction. If non found, returns the maximum sensor value.
            -- // Maps the result to the sensor range 0.0..1.0.
            return longProbePopulationFwd(loc, lastMoveDir, longProbeDist) / longProbeDist -- // 0..1
        end,
    
        Sensor.LONGPROBE_BAR_FWD = function()
            -- // Measures the distance to the nearest barrier in the forward
            -- // direction. If non found, returns the maximum sensor value.
            -- // Maps the result to the sensor range 0.0..1.0.
            return longProbeBarrierFwd(loc, lastMoveDir, longProbeDist) / longProbeDist -- // 0..1
        end,
    
        case Sensor.POPULATION = function()   
            -- // Returns population density in neighborhood converted linearly from
            -- // 0..100% to sensor range
            local countLocs = 0
            local countOccupied = 0
            local center = loc

            local f = function(Coord tloc) 
                countLocs = countLocs + 1
                if (grid:isOccupiedAt(tloc)) then 
                    countOccupied = countOccupied + 1
                end 
            end 

            visitNeighborhood(center, p.populationSensorRadius, f)
            return countOccupied / countLocs
        end,
    
        Sensor.POPULATION_FWD = function()
            -- // Sense population density along axis of last movement direction, mapped
            -- // to sensor range 0.0..1.0
            return getPopulationDensityAlongAxis(loc, lastMoveDir)
        end, 

        Sensor.POPULATION_LR = function()
            -- // Sense population density along an axis 90 degrees from last movement direction
            return getPopulationDensityAlongAxis(loc, lastMoveDir:rotate90DegCW())
        end, 

        Sensor.BARRIER_FWD = function()
            -- // Sense the nearest barrier along axis of last movement direction, mapped
            -- // to sensor range 0.0..1.0
            return getShortProbeBarrierDistance(loc, lastMoveDir, p.shortProbeBarrierDistance)
        end, 
    
        Sensor.BARRIER_LR = function()
            -- // Sense the nearest barrier along axis perpendicular to last movement direction, mapped
            -- // to sensor range 0.0..1.0
            return getShortProbeBarrierDistance(loc, lastMoveDir:rotate90DegCW(), p.shortProbeBarrierDistance)
        end, 

        Sensor.RANDOM = function()
            -- // Returns a random sensor value in the range 0.0..1.0.
            return randomUint() / UINT_MAX
        end, 
    
        Sensor.SIGNAL0 = function()
            -- // Returns magnitude of signal0 in the local neighborhood, with
            -- // 0.0..maxSignalSum converted to sensorRange 0.0..1.0
            return getSignalDensity(0, loc)
        end,

        Sensor.SIGNAL0_FWD = function()
            -- // Sense signal0 density along axis of last movement direction
            return getSignalDensityAlongAxis(0, loc, lastMoveDir)
        end,

        Sensor.SIGNAL0_LR = function()
            -- // Sense signal0 density along an axis perpendicular to last movement direction
            getSignalDensityAlongAxis(0, loc, lastMoveDir:rotate90DegCW())
        end, 

        Sensor.GENETIC_SIM_FWD = function()
            -- // Return minimum sensor value if nobody is alive in the forward adjacent location,
            -- // else returns a similarity match in the sensor range 0.0..1.0
            local loc2 = loc:ADD(lastMoveDir)
            if (grid:isInBounds(loc2) and grid:isOccupiedAt(loc2)) then
                local indiv2 = peeps:getIndiv(loc2)
                if (indiv2.alive) then
                    return genomeSimilarity(genome, indiv2.genome) -- // 0.0..1.0
                end 
            end
            return sensorVal
        end,
    }

    local newVal = sensorNumFunc[sensorNum]
    if(newVal == nil) then print("Invalid sensor number: "..tostring(sensorNum)) end
    sensorVal = newVal    

    if (math.isnan(sensorVal) or sensorVal < -0.01 or sensorVal > 1.01) then
        -- // std::cout << "sensorVal=" << (int)sensorVal << " for " << sensorName((Sensor)sensorNum) << std::endl;
        sensorVal = math.max(0.0, math.min(sensorVal, 1.0)) -- // clip
    end 

    assert(!math.isnan(sensorVal) and sensorVal >= -0.01 and sensorVal <= 1.01)
    return sensorVal
end


return Indiv