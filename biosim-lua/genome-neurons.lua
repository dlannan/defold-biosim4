require("utils.copies") -- copy routines for tables

local tinsert = table.insert

-- // Each gene specifies one synaptic connection in a neural net. Each
-- // connection has an input (source) which is either a sensor or another neuron.
-- // Each connection has an output, which is either an action or another neuron.
-- // Each connection has a floating point weight derived from a signed 16-bit
-- // value. The signed integer weight is scaled to a small range, then cubed
-- // to provide fine resolution near zero.

local SENSOR = 1 -- // always a source
local ACTION = 1 -- // always a sink
local NEURON = 0 -- // can be either a source or sink

Gene = {
    sourceType  = 0, --   // SENSOR or NEURON
    sourceNum   = 0,
    sinkType    = 0, --   // NEURON or ACTION
    sinkNum     = 0,
    weight      = 0,

    f1          = 8.0,
    f2          = 64.0,

    -- //float weightAsFloat() { return std::pow(weight / f1, 3.0) / f2; }
    weightAsFloat = function(self)  return self.weight / 8192.0 end,
    makeRandomWeight = function(self) return randomUint(0, 0xffff) - 0x8000 end,
}

-- // This structure is used while converting the connection list to a
-- // neural net. This helps us to find neurons that don't feed anything
-- // so that they can be removed along with all the connections that
-- // feed the useless neurons. We'll cull neurons with .numOutputs == 0
-- // or those that only feed themselves, i.e., .numSelfInputs == .numOutputs.
-- // Finally, we'll renumber the remaining neurons sequentially starting
-- // at zero using the .remappedNumber member.
local Node = {
    remappedNumber = 0, 
    numOutputs = 0,
    numSelfInputs = 0,
    numInputsFromSensorsOrOtherNeurons = 0,
}

-- // Two neuron renumberings occur: The original genome uses a uint16_t for
-- // neuron numbers. The first renumbering maps 16-bit unsigned neuron numbers
-- // to the range 0..p.maxNumberNeurons - 1. After culling useless neurons
-- // (see comments above), we'll renumber the remaining neurons sequentially
-- // starting at 0.
local NodeMap  = {}  -- // key is neuron number 0..p.maxNumberNeurons - 1

local ConnectionList = {}

-- // An individual's genome is a set of Genes (see Gene comments above). Each
-- // gene is equivalent to one connection in a neural net. An individual's
-- // neural net is derived from its set of genes.
Genome = {}


-- // An individual's "brain" is a neural net specified by a set
-- // of Genes where each Gene specifies one connection in the neural net (see
-- // Genome comments above). Each neuron has a single output which is
-- // connected to a set of sinks where each sink is either an action output
-- // or another neuron. Each neuron has a set of input sources where each
-- // source is either a sensor or another neuron. There is no concept of
-- // layers in the net: it's a free-for-all topology with forward, backwards,
-- // and sideways connection allowed. Weighted connections are allowed
-- // directly from any source to any action.

-- // Currently the genome does not specify the activation function used in
-- // the neurons. (May be hardcoded to std::tanh() !!!)

-- // When the input is a sensor, the input value to the sink is the raw
-- // sensor value of type float and depends on the sensor. If the output
-- // is an action, the source's output value is interpreted by the action
-- // node and whether the action occurs or not depends on the action's
-- // implementation.

-- // In the genome, neurons are identified by 15-bit unsigned indices,
-- // which are reinterpreted as values in the range 0..p.genomeMaxLength-1
-- // by taking the 15-bit index modulo the max number of allowed neurons.
-- // In the neural net, the neurons that end up connected get new indices
-- // assigned sequentially starting at 0.


local NeuralNet = 
{
    connections  = {},      -- // connections are equivalent to genes

    Neuron = {
        output      = 0.0,
        driven      = false, -- // undriven neurons have fixed output values
    },
    neurons = {},
}

-- // When a new population is generated and every individual is given a
-- // neural net, the neuron outputs must be initialized to something:
-- //const float initialNeuronOutput() { return (NEURON_RANGE / 2.0) + NEURON_MIN; }
initialNeuronOutput = function()  return 0.5 end

makeRandomGene = function() 
    local gene = table.deepcopy(Gene)

    gene.sourceType = bit.band(randomUint(), 1)
    gene.sourceNum = randomUint(0, 0x7fff)
    gene.sinkType = bit.band(randomUint(), 1)
    gene.sinkNum = randomUint(0, 0x7fff)
    gene.weight = Gene.makeRandomWeight()

    return gene
end 

makeRandomGenome = function() 
    local genome = {}

    local length = randomUint(p.genomeInitialLengthMin, p.genomeInitialLengthMax)
    for n = 0, length-1 do 
        tinsert(genome, makeRandomGene())
    end 

    return genome
end 

-- // Convert the indiv's genome to a renumbered connection list.
-- // This renumbers the neurons from their uint16_t values in the genome
-- // to the range 0..p.maxNumberNeurons - 1 by using a modulo operator.
-- // Sensors are renumbered 0..Sensor::NUM_SENSES - 1
-- // Actions are renumbered 0..Action::NUM_ACTIONS - 1
local makeRenumberedConnectionList = function(connectionList, genome)

    connectionList = {}
    for k, gene in pairs(genome) do
        tinsert(connectionList, gene)
        local conn = connectionList[#connectionList]

        if (conn.sourceType == NEURON) then 
            conn.sourceNum = conn.sourceNum % p.maxNumberNeurons
        else 
            conn.sourceNum = conn.sourceNum % Sensor.NUM_SENSES
        end

        if (conn.sinkType == NEURON) then 
            conn.sinkNum = conn.sinkNum % p.maxNumberNeurons
        else 
            conn.sinkNum = conn.sinkNum % Action.NUM_ACTIONS
        end
    end 
end

-- // Scan the connections and make a list of all the neuron numbers
-- // mentioned in the connections. Also keep track of how many inputs and
-- // outputs each neuron has.
local makeNodeList(nodeMap, connectionList)

    nodeMap = {}

    for k, conn in pairs(connectionList) do
        if (conn.sinkType == NEURON) then
            local it = nodeMap[conn.sinkNum]
            if (it == nil) then
                assert(conn.sinkNum < p.maxNumberNeurons)
                nodeMap[conn.sinkNum] = {}
                it = nodeMap[conn.sinkNum]
                it.numOutputs = 0
                it.numSelfInputs = 0
                it.numInputsFromSensorsOrOtherNeurons = 0
            end

            if (conn.sourceType == NEURON and (conn.sourceNum == conn.sinkNum)) then
                it.numSelfInputs = it.numSelfInputs+1
            else 
                it.numInputsFromSensorsOrOtherNeurons = it.numInputsFromSensorsOrOtherNeurons + 1
            end 
            -- assert(nodeMap.count(conn.sinkNum) == 1);
        }
        if (conn.sourceType == NEURON) then 
            it = nodeMap[conn.sourceNum]
            if (it == nil) then 
                assert(conn.sourceNum < p.maxNumberNeurons)
                nodeMap[conn.sourceNum] = {}
                it = nodeMap[conn.sourceNum]
                it.numOutputs = 0
                it.numSelfInputs = 0
                it.numInputsFromSensorsOrOtherNeurons = 0
            end 
            it.numOutputs = it.numOutputs + 1
            -- assert(nodeMap.count(conn.sourceNum) == 1);
        end 
    end 
end

-- // During the culling process, we will remove any neuron that has no outputs,
-- // and all the connections that feed the useless neuron.
local removeConnectionsToNeuron(connections, nodeMap, neuronNumber)

    for k,itConn in pairs(connections) do
        if (itConn.sinkType == NEURON and itConn.sinkNum == neuronNumber) then
            -- // Remove the connection. If the connection source is from another
            -- // neuron, also decrement the other neuron's numOutputs:
            if (itConn.sourceType == NEURON) then
                --(nodeMap[itConn->sourceNum].numOutputs);
            end 
            itConn = nil 
        end
    end
end


-- // If a neuron has no outputs or only outputs that feed itself, then we
-- // remove it along with all connections that feed it. Reiterative, because
-- // after we remove a connection to a useless neuron, it may result in a
-- // different neuron having no outputs.
local cullUselessNeurons(connections, nodeMap)

    local allDone = false
    while (allDone == false) do
        allDone = true
        for k,itNeuron in pairs(nodeMap) do
            assert(k < p.maxNumberNeurons);
            -- // We're looking for neurons with zero outputs, or neurons that feed itself
            -- // and nobody else:
            if (itNeuron.numOutputs == itNeuron.numSelfInputs) then --  // could be 0
                allDone = false
                -- // Find and remove connections from sensors or other neurons
                removeConnectionsToNeuron(connections, nodeMap, k)
                itNeuron = nil
            end
        end
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
Indiv.createWiringFromGenome = function()

    local nodeMap = {} --  // list of neurons and their number of inputs and outputs
    connectionList = {} -- // synaptic connections

    -- // Convert the indiv's genome to a renumbered connection list
    makeRenumberedConnectionList(connectionList, genome)

    -- // Make a node (neuron) list from the renumbered connection list
    makeNodeList(nodeMap, connectionList)

    -- // Find and remove neurons that don't feed anything or only feed themself.
    -- // This reiteratively removes all connections to the useless neurons.
    cullUselessNeurons(connectionList, nodeMap)

    -- // The neurons map now has all the referenced neurons, their neuron numbers, and
    -- // the number of outputs for each neuron. Now we'll renumber the neurons
    -- // starting at zero.

    assert(table.getn(nodeMap) <= p.maxNumberNeurons)
    local newNumber = 0
    for k,node in pairs(nodeMap) do
        assert(node.numOutputs != 0)
        node.remappedNumber = newNumber
        newNumber = newNumber + 1
    end

    -- // Create the indiv's connection list in two passes:
    -- // First the connections to neurons, then the connections to actions.
    -- // This ordering optimizes the feed-forward function in feedForward.cpp.

    nnet.connections = {}

    -- // First, the connections from sensor or neuron to a neuron
    for k,conn in pairs(connectionList) do
        if (conn.sinkType == NEURON) then
            tinsert(nnet.connections, conn)
            newConn = nnet.connections[#nnet.connections]
            -- // fix the destination neuron number
            newConn.sinkNum = nodeMap[newConn.sinkNum].remappedNumber
            -- // if the source is a neuron, fix its number too
            if (newConn.sourceType == NEURON) then
                newConn.sourceNum = nodeMap[newConn.sourceNum].remappedNumber
            end
        end
    end

    -- // Last, the connections from sensor or neuron to an action
    for k,conn in pairs(connectionList) do 
        if (conn.sinkType == ACTION) then 
            tinsert(nnet.connections, conn)
            local newConn = nnet.connections[#nnet.connections]
            -- // if the source is a neuron, fix its number
            if (newConn.sourceType == NEURON) then
                newConn.sourceNum = nodeMap[newConn.sourceNum].remappedNumber
            end
        end
    end

    -- // Create the indiv's neural node list
    nnet.neurons = {}
    for neuronNum = 0, table.getn(nodeMap) do 
        tinsert(nnet.neurons, {} )
        local last = #nnet.neurons
        nnet.neurons[last].output = initialNeuronOutput()
        nnet.neurons[last].driven = (nodeMap[neuronNum].numInputsFromSensorsOrOtherNeurons ~= 0)
    end 
end
    
-- // ---------------------------------------------------------------------------
-- // This applies a point mutation at a random bit in a genome.
local randomBitFlip = function(genome)

    local byteIndex = randomUint(0, #genome - 1) * sizeof(Gene)
    local elementIndex = randomUint(0, #genome - 1)
    local bitIndex8 = bit.lshift(1, randomUint(0, 7))

    local chance = randomUint() / RANDOM_UINT_MAX -- // 0..1
    if (chance < 0.2) then -- // sourceType
        genome[elementIndex].sourceType = bit.bxor(genome[elementIndex].sourceType, 1)
    elseif (chance < 0.4) then -- // sinkType
        genome[elementIndex].sinkType = bit.bxor(genome[elementIndex].sinkType, 1)
    elseif (chance < 0.6) then -- // sourceNum
        genome[elementIndex].sourceNum = bit.bxor(genome[elementIndex].sourceNum, bitIndex8)
    elseif (chance < 0.8) then -- // sinkNum
        genome[elementIndex].sinkNum = bit.bxor(genome[elementIndex].sinkNum, bitIndex8)
    else -- // weight
        genome[elementIndex].weight = bit.bxor(genome[elementIndex].weight, bit.lshift(1, randomUint(1, 15)) )
    end
end

-- // If the genome is longer than the prescribed length, and if it's longer
-- // than one gene, then we remove genes from the front or back. This is
-- // used only when the simulator is configured to allow genomes of
-- // unequal lengths during a simulation.
local cropLength = function(genome, length)

    if (#genome > length and length > 0) then
        if (randomUint() / RANDOM_UINT_MAX < 0.5) then
            -- // trim front
            local numberElementsToTrim = #genome - length
            for i=1, numberElementsToTrim do genome[i] = nil end 
        else 
            -- // trim back
            for i= #genome - length, #genome do genome[i] = nil end 
        end
    end
end

-- // Inserts or removes a single gene from the genome. This is
-- // used only when the simulator is configured to allow genomes of
-- // unequal lengths during a simulation.
local randomInsertDeletion = function(genome)
{
    local probability = p.geneInsertionDeletionRate
    if (randomUint() / RANDOM_UINT_MAX < probability) then
        if (randomUint() / RANDOM_UINT_MAX < p.deletionRatio) then
            -- // deletion
            if (#genome > 1) then 
                genome[ randomUint(0, genome.size() - 1) + 1 ] = nil
            end
        elseif (#genome < p.genomeMaxLength) then
            -- // insertion
            -- //genome.insert(genome.begin() + randomUint(0, genome.size() - 1), makeRandomGene());
            tinsert(genome, makeRandomGene())
        end
    end
end


-- // This function causes point mutations in a genome with a probability defined
-- // by the parameter p.pointMutationRate.
local applyPointMutations = function(genome)

    local numberOfGenes = #genome
    while (numberOfGenes > 0) do
        if ((randomUint() / RANDOM_UINT_MAX) < p.pointMutationRate) then
            randomBitFlip(genome)
        end
        numberOfGenes = numberOfGenes - 1
    end
end

-- // This generates a child genome from one or two parent genomes.
-- // If the parameter p.sexualReproduction is true, two parents contribute
-- // genes to the offspring. The new genome may undergo mutation.
-- // Must be called in single-thread mode between generations
local generateChildGenome = function(parentGenomes)

    -- // random parent (or parents if sexual reproduction) with random
    -- // mutations
    genome = {}

    local parent1Idx = 0
    local parent2Idx = 0

    -- // Choose two parents randomly from the candidates. If the parameter
    -- // p.chooseParentsByFitness is false, then we choose at random from
    -- // all the candidate parents with equal preference. If the parameter is
    -- // true, then we give preference to candidate parents according to their
    -- // score. Their score was computed by the survival/selection algorithm
    -- // in survival-criteria.cpp.
    if (p.chooseParentsByFitness and #parentGenomes > 1) then
        parent1Idx = randomUint(1, #parentGenomes - 1)
        parent2Idx = randomUint(0, parent1Idx - 1)
    else 
        parent1Idx = randomUint(0, #parentGenomes - 1)
        parent2Idx = randomUint(0, #parentGenomes - 1)
    end

    local g1 = parentGenomes[parent1Idx]
    local g2 = parentGenomes[parent2Idx]

    if (g1 == nil or g2 == nil) then
        print("invalid genome")
        assert(false)
    end

    local overlayWithSliceOf = function(gShorter) 
        local index0 = randomUint(0, #gShorter - 1)
        local index1 = randomUint(0, #gShorter)
        if (index0 > index1) then 
            local temp = index0
            index0 = index1
            index1 = temp
        end
        for i = index0, index1 do 
            genome[i] = gShorter[i]
        end
    end

    if (p.sexualReproduction) then 
        if (#g1 > #g2) then
            genome = g1
            overlayWithSliceOf(g2)
            assert(#genome > 0)
        else 
            genome = g2
            overlayWithSliceOf(g1)
            assert(#genome > 0)
        }

        -- // Trim to length = average length of parents
        local sum = #g1 + #g2;
        -- // If average length is not an integral number, add one half the time
        if (bit.band(sum, 1) and bit.band(randomUint(), 1)) then
            sum = sum + 1
        end
        cropLength(genome, sum / 2)
        assert(#genome>0)
    else
        genome = g2
        assert(#genome>0)
    end

    randomInsertDeletion(genome)
    assert(#genome > 0)
    applyPointMutations(genome)
    assert(#genome > 0)
    assert(#genome <= p.genomeMaxLength)

    return genome
end

unitTestConnectNeuralNetWiringFromGenome = function() end 

genomeSimilarity = function(g1, g2) end -- // 0.0..1.0
geneticDiversity = function() end -- // 0.0..1.0

