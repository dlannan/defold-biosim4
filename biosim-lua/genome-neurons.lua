require("utils.copies") -- copy routines for tables

local tinsert = table.insert

-- // Each gene specifies one synaptic connection in a neural net. Each
-- // connection has an input (source) which is either a sensor or another neuron.
-- // Each connection has an output, which is either an action or another neuron.
-- // Each connection has a floating point weight derived from a signed 16-bit
-- // value. The signed integer weight is scaled to a small range, then cubed
-- // to provide fine resolution near zero.

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
    makeRandomWeight = function(self) return randomUint:GetRange(0, 0xffff) - 0x8000 end,

    -- // Make an int out of the 5 main components.
    GetData = function(self)

        if(self.data == nil) then 
            local r1 = bit.bor(bit.band(self.sourceType, 1), bit.lshift(bit.band(self.sourceNum, 0x7fff), 1) )
            local r2 = bit.bor(bit.band(self.sinkType, 1), bit.lshift(bit.band(self.sinkNum, 0x7fff), 1) )
            local out = r1 + bit.lshift(r2, 8) --  + bit.lshift(self.weight, 16)
            self.data = out
        end 
        return self.data 
    end,
}

Gene.new = function()
    return table.shallowcopy(Gene)
end 

-- // This structure is used while converting the connection list to a
-- // neural net. This helps us to find neurons that don't feed anything
-- // so that they can be removed along with all the connections that
-- // feed the useless neurons. We'll cull neurons with .numOutputs == 0
-- // or those that only feed themselves, i.e., .numSelfInputs == .numOutputs.
-- // Finally, we'll renumber the remaining neurons sequentially starting
-- // at zero using the .remappedNumber member.
Node = {
    remappedNumber = 0, 
    numOutputs = 0,
    numSelfInputs = 0,
    numInputsFromSensorsOrOtherNeurons = 0,
}

Node.new = function()
    return table.shallowcopy(Node)
end 

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

-- A special object built to handle the intricaies cof genome mainpulation
Genome = {
    total = 0,
    list = {},
}

Genome.count = function(self)
    return self.total
end

Genome.get = function(self, index) 
    return self.list[index]
end 

Genome.set = function(self, index, gene)
    self.list[index] = gene 
end

Genome.remove = function(self, index)
    self.total = self.total - 1
    table.remove( self.list, index )
end 

Genome.insert = function(self, index, gene)
    self.total = self.total + 1
    if(index) then 
        table.insert( self.list, index, gene )
    else 
        table.insert( self.list, gene )
    end
end

Genome_new = function()
    return table.deepcopy(Genome)
end 


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


NeuralNet = 
{
    connections  = {},      -- // connections are equivalent to genes

    Neuron = {
        output      = 0.0,
        driven      = false, -- // undriven neurons have fixed output values
    },
    neurons = {},
}

NeuralNet.new = function()
    return table.shallowcopy(NeuralNet)
end

-- // When a new population is generated and every individual is given a
-- // neural net, the neuron outputs must be initialized to something:
-- //const float initialNeuronOutput() { return (NEURON_RANGE / 2.0) + NEURON_MIN; }
initialNeuronOutput = function()  return 0.5 end

makeRandomGene = function() 
    local gene = table.shallowcopy(Gene)

    gene.sourceType = bit.band(randomUint:Get(), 1)
    gene.sourceNum = randomUint:GetRange(0, 127)
    gene.sinkType = bit.band(randomUint:Get(), 1)
    gene.sinkNum = randomUint:GetRange(0, 127)
    gene.weight = Gene.makeRandomWeight()

    return gene
end 

makeRandomGenome = function() 
    local genome = Genome_new()

    local length = randomUint:GetRange(p.genomeInitialLengthMin, p.genomeInitialLengthMax)
    for n = 1, length do 
        genome:insert( nil, makeRandomGene())
    end 

    return genome
end 

-- // Convert the indiv's genome to a renumbered connection list.
-- // This renumbers the neurons from their uint16_t values in the genome
-- // to the range 0..p.maxNumberNeurons - 1 by using a modulo operator.
-- // Sensors are renumbered 0..Sensor::NUM_SENSES - 1
-- // Actions are renumbered 0..Action::NUM_ACTIONS - 1
makeRenumberedConnectionList = function(connectionList, genome)

    local ctr = 0
    for k, gene in ipairs(genome.list) do
        local conn = table.shallowcopy(gene)

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
        table.insert(connectionList, conn)
    end 
end

-- // Scan the connections and make a list of all the neuron numbers
-- // mentioned in the connections. Also keep track of how many inputs and
-- // outputs each neuron has.
makeNodeList = function(nodeMap, connectionList)

    for k, conn in pairs(connectionList) do
        if (conn.sinkType == NEURON) then
            local it = nodeMap[conn.sinkNum]
            if (it == nil) then
                assert(conn.sinkNum < p.maxNumberNeurons)
                it = Node.new()
                it.numOutputs = 0
                it.numSelfInputs = 0
                it.numInputsFromSensorsOrOtherNeurons = 0
            end

            if ((conn.sourceType == NEURON) and (conn.sourceNum == conn.sinkNum)) then
                it.numSelfInputs = it.numSelfInputs+1
            else 
                it.numInputsFromSensorsOrOtherNeurons = it.numInputsFromSensorsOrOtherNeurons + 1
            end 
            nodeMap[conn.sinkNum] = it
            -- assert(nodeMap.count(conn.sinkNum) == 1);
        end
        if (conn.sourceType == NEURON) then 
            local it = nodeMap[conn.sourceNum]
            if (it == nil) then 
                assert(conn.sourceNum < p.maxNumberNeurons)
                it = Node.new()
                it.numOutputs = 0
                it.numSelfInputs = 0
                it.numInputsFromSensorsOrOtherNeurons = 0
            end 
            it.numOutputs = it.numOutputs + 1
            -- assert(nodeMap.count(conn.sourceNum) == 1);
            nodeMap[conn.sourceNum] = it
        end 
    end 
end

-- // During the culling process, we will remove any neuron that has no outputs,
-- // and all the connections that feed the useless neuron.
local removeConnectionsToNeuron = function(connections, nodeMap, neuronNumber)

    local forRemoval = {}
    for k,itConn in pairs(connections) do
        if (itConn.sinkType == NEURON and itConn.sinkNum == neuronNumber) then
            -- // Remove the connection. If the connection source is from another
            -- // neuron, also decrement the other neuron's numOutputs:
            if (itConn.sourceType == NEURON) then
                nodeMap[itConn.sourceNum].numOutputs = nodeMap[itConn.sourceNum].numOutputs - 1
            end 
            tinsert(forRemoval, k)
        end
    end
    for k,v in pairs(forRemoval) do connections[v] = nil end 
end


-- // If a neuron has no outputs or only outputs that feed itself, then we
-- // remove it along with all connections that feed it. Reiterative, because
-- // after we remove a connection to a useless neuron, it may result in a
-- // different neuron having no outputs.
cullUselessNeurons = function(connections, nodeMap)

    local allDone = false
    while (allDone == false) do
        allDone = true
        local forRemoval = {}

        for k, itNeuron in pairs(nodeMap) do
            assert(k < p.maxNumberNeurons, "[ERROR]"..k.."    "..p.maxNumberNeurons)
            -- // We're looking for neurons with zero outputs, or neurons that feed itself
            -- // and nobody else:
            if (itNeuron.numOutputs == itNeuron.numSelfInputs) then --  // could be 0
                allDone = false
                -- // Find and remove connections from sensors or other neurons
                pprint("Renmoving: ", itNeuron)
                removeConnectionsToNeuron(connections, nodeMap, k)
                tinsert(forRemoval, k)  
            end
        end

        for k,v in pairs(forRemoval) do nodeMap[v] = nil end 
    end
end
    
-- // ---------------------------------------------------------------------------
-- // This applies a point mutation at a random bit in a genome.
local randomBitFlip = function(genome)

    --local byteIndex = randomUint:GetRange(0, #genome - 1) * sizeof(Gene)
    local elementIndex = randomUint:GetRange(0, genome:count()-1)
    local bitIndex8 = bit.lshift(1, randomUint:GetRange(0, 7))

    local chance = randomUint:Get() / RANDOM_UINT_MAX -- // 0..1
    local gn = genome:get(elementIndex)
    assert(gn ~= nil, "[ERROR] "..tostring(gn).."   "..elementIndex.."   "..#genome.list)
    if (chance < 0.2) then -- // sourceType
        gn.sourceType = bit.bxor(gn.sourceType, 1)
    elseif (chance < 0.4) then -- // sinkType
        gn.sinkType = bit.bxor(gn.sinkType, 1)
    elseif (chance < 0.6) then -- // sourceNum
        gn.sourceNum = bit.bxor(gn.sourceNum, bitIndex8)
    elseif (chance < 0.8) then -- // sinkNum
        gn.sinkNum = bit.bxor(gn.sinkNum, bitIndex8)
    else -- // weight
        gn.weight = bit.bxor(gn.weight, bit.lshift(1, randomUint:GetRange(1, 15)) )
    end
end

-- // If the genome is longer than the prescribed length, and if it's longer
-- // than one gene, then we remove genes from the front or back. This is
-- // used only when the simulator is configured to allow genomes of
-- // unequal lengths during a simulation.
local cropLength = function(genome, length)

    if (genome:count() > length and length > 0) then
        if (randomUint:Get() / RANDOM_UINT_MAX < 0.5) then
            -- // trim front
            local numberElementsToTrim = genome:count() - length
            for i=1, numberElementsToTrim do genome:remove(i) end 
        else 
            -- // trim back
            for i= genome:count() - length, genome:count()-1 do genome:remove(i) end 
        end
    end
end

local copyupgenes = function( genome, insertgene )

    for i=genome:count(), insertgene+1, -1  do 
        genome:insert( i, genome.get(i) )
    end 
end 

local copydowngenes = function( genome, deletegene )

    for i=deletegene, genome:count()-1  do 
        genome:set(i, genome.get(i+1))
    end 
end 

-- // Inserts or removes a single gene from the genome. This is
-- // used only when the simulator is configured to allow genomes of
-- // unequal lengths during a simulation.
local randomInsertDeletion = function(genome)

    local probability = p.geneInsertionDeletionRate
    if (randomUint:Get() / RANDOM_UINT_MAX < probability) then
        if (randomUint:Get() / RANDOM_UINT_MAX < p.deletionRatio) then
            -- // deletion
            if (genome:count() > 1) then 
                local deletegene = randomUint:GetRange(0, genome:count() - 1)
                copydowngenes(genome, deletegene)
                genome:remove( deletegene )
            end
        else
            if (genome:count() < p.genomeMaxLength) then
                -- // insertion
                -- //genome.insert(genome.begin() + randomUint:GetRange(0, genome.size() - 1), makeRandomGene());
                local insertgene = randomUint:GetRange(0, genome:count() - 1)
                copyupgenes(genome, insertgene)
                genome:insert( insertgene, makeRandomGene())
            end
        end
    end
end


-- // This function causes point mutations in a genome with a probability defined
-- // by the parameter p.pointMutationRate.
local applyPointMutations = function(genome)

    local numberOfGenes = genome:count()
    while (numberOfGenes > 0) do
        if ((randomUint:Get() / RANDOM_UINT_MAX) < p.pointMutationRate) then
            randomBitFlip(genome)
        end
        numberOfGenes = numberOfGenes - 1
    end
end

-- // This generates a child genome from one or two parent genomes.
-- // If the parameter p.sexualReproduction is true, two parents contribute
-- // genes to the offspring. The new genome may undergo mutation.
-- // Must be called in single-thread mode between generations
generateChildGenome = function(parentGenomes)

    -- // random parent (or parents if sexual reproduction) with random
    -- // mutations
    local genome = Genome_new()

    local parent1Idx = 0
    local parent2Idx = 0

    -- // Choose two parents randomly from the candidates. If the parameter
    -- // p.chooseParentsByFitness is false, then we choose at random from
    -- // all the candidate parents with equal preference. If the parameter is
    -- // true, then we give preference to candidate parents according to their
    -- // score. Their score was computed by the survival/selection algorithm
    -- // in survival-criteria.cpp.
    if (p.chooseParentsByFitness and parentGenomes:count() > 1) then
        parent1Idx = randomUint:GetRange(1, parentGenomes:count())
        parent2Idx = randomUint:GetRange(0, parent1Idx-1)
    else 
        parent1Idx = randomUint:GetRange(0, parentGenomes:count()-1)
        parent2Idx = randomUint:GetRange(0, parentGenomes:count()-1)
    end

    local g1 = parentGenomes:get(parent1Idx)
    local g2 = parentGenomes:get(parent2Idx)

    if ((g1 == nil) or (g2 == nil)) then
        print("invalid genome")
        pprint(g1, g2)
        assert(false)
    end

    local overlayWithSliceOf = function(gShorter) 
        local index0 = randomUint:GetRange(0, table.count(gShorter) - 1)
        local index1 = randomUint:GetRange(0, table.count(gShorter) )
        if (index0 > index1) then 
            local temp = index0
            index0 = index1
            index1 = temp
        end
        for i = index0, index1 do 
            genome:set(i, gShorter[i])
        end
    end

    if (p.sexualReproduction) then 
        if (g1:count() > g2:count()) then
            genome = g1
            overlayWithSliceOf(g2)
            assert(genome:count() > 0)
        else 
            genome = g2
            overlayWithSliceOf(g1)
            assert( genome:count() > 0)
        end

        -- // Trim to length = average length of parents
        local sum = g1:count() + g2:count()
        -- // If average length is not an integral number, add one half the time
        if (bit.band(sum, 1) and bit.band(randomUint:Get(), 1)) then
            sum = sum + 1
        end
        cropLength(genome, sum / 2)
        assert(genome:count()>0)
    else
        genome = g2
        assert(genome:count()>0)
    end

    randomInsertDeletion(genome)
    assert(genome:count()>0)
    applyPointMutations(genome)
    assert(genome:count()>0)
    assert(genome:count() <= p.genomeMaxLength)

    return genome
end

unitTestConnectNeuralNetWiringFromGenome = function() end 



