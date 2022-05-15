
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

Indiv.initialize = function(self, index, loc, genome)

    index = index_;
    loc = loc_;
    birthLoc = loc_;
    grid.set(loc_, index_);
    age = 0;
    oscPeriod = 34; // ToDo !!! define a constant
    alive = true;
    lastMoveDir = Dir::random8();
    responsiveness = 0.5; // range 0.0..1.0
    longProbeDist = p.longProbeDistance;
    challengeBits = (unsigned)false; // will be set true when some task gets accomplished
    genome = std::move(genome_);
    createWiringFromGenome();
end 

Indiv.createWiringFromGenome = function(self) -- // creates .nnet member from .genome member
end

Indiv.printNeuralNet = function(self)
end 

Indiv.printIGraphEdgeList = function(self)
end

Indiv.printGenome = function(self)
end

Indiv.getIGraphEdgeList = function(self, lines)
end

