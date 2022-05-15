
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

return Indiv