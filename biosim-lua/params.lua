
require("utils.copies")
local inifile = require("utils.inifile")

RunMode = { STOP = 0, RUN = 1, PAUSE = 2, ABORT = 3 }
runMode = RunMode.STOP

-- // A private copy of Params is initialized by ParamManager::init(), then modified by
-- // UI events by ParamManager::uiMonitor(). The main simulator thread can get an
-- // updated, read-only, stable snapshot of Params with ParamManager::paramsSnapshot.

Params = {
    population          = 0, -- // >= 0
    stepsPerGeneration  = 0, -- // > 0
    maxGenerations      = 0, -- // >= 0
    numThreads          = 0, -- // > 0
    signalLayers        = 0, -- // >= 0
    genomeMaxLength     = 0, -- // > 0
    maxNumberNeurons    = 0, -- // > 0
    pointMutationRate   = 0, -- // 0.0..1.0
    geneInsertionDeletionRate = 0, -- // 0.0..1.0
    deletionRatio       = 0, -- // 0.0..1.0
    killEnable          = false,
    sexualReproduction  = false,
    chooseParentsByFitness = false,
    populationSensorRadius = 0, -- // > 0.0
    signalSensorRadius  = 0, -- // > 0
    responsiveness      = 0, -- // >= 0.0
    responsivenessCurveKFactor = 0, -- // 1, 2, 3, or 4
    longProbeDistance   = 0, -- // > 0
    shortProbeBarrierDistance = 0, -- // > 0
    valenceSaturationMag = 0, 
    saveVideo           = false,
    videoStride         = 0, -- // > 0
    videoSaveFirstFrames = 0, -- // >= 0, overrides videoStride
    displayScale        = 0,
    agentSize           = 0,
    genomeAnalysisStride = 0, -- // > 0
    displaySampleGenomes = 0, -- // >= 0
    genomeComparisonMethod = 0, -- // 0 = Jaro-Winkler 1 = Hamming
    updateGraphLog      = false,
    updateGraphLogStride = 0, -- // > 0
    challenge           = 0,
    barrierType         = 0, -- // >= 0
    deterministic       = false,
    RNGSeed             = 0, -- // >= 0

    -- // These must not change after initialization
    sizeX               = 2.0, -- // 2..0x10000
    sizeY               = 2.0, -- // 2..0x10000
    genomeInitialLengthMin = 0, -- // > 0 and < genomeInitialLengthMax
    genomeInitialLengthMax = 0, -- // > 0 and < genomeInitialLengthMin
    logDir              = "",
    imageDir            = "",
    graphLogUpdateCommand = "",

    -- // These are updated automatically and not set via the parameter file
    parameterChangeGenerationNumber = 0, -- // the most recent generation number that an automatic parameter change occured at
}

ParamManager = {

    privParams          = table.deepcopy(Params),
    configFilename      = "",
    lastModTime         = 0, -- // when config file was last read
}

ParamManager.getParamRef = function(self) return self.privParams end -- // for public read-only access

ParamManager.setDefaults = function(self) 
    local privParams = {}
    privParams.sizeX = 128
    privParams.sizeY = 128
    privParams.challenge = 6

    privParams.genomeInitialLengthMin = 24
    privParams.genomeInitialLengthMax = 24
    privParams.genomeMaxLength = 300
    privParams.logDir = "data/logs/"
    privParams.imageDir = "data/images/"
    privParams.population = 3000
    privParams.stepsPerGeneration = 300
    privParams.maxGenerations = 200000
    privParams.barrierType = 0
    privParams.numThreads = 4
    privParams.signalLayers = 1
    privParams.maxNumberNeurons = 5
    privParams.pointMutationRate = 0.001
    privParams.geneInsertionDeletionRate = 0.0
    privParams.deletionRatio = 0.5
    privParams.killEnable = false
    privParams.sexualReproduction = true
    privParams.chooseParentsByFitness = true
    privParams.populationSensorRadius = 2.5
    privParams.signalSensorRadius = 2.0
    privParams.responsiveness = 0.5
    privParams.responsivenessCurveKFactor = 2
    privParams.longProbeDistance = 16
    privParams.shortProbeBarrierDistance = 4
    privParams.valenceSaturationMag = 0.5
    privParams.saveVideo = true
    privParams.videoStride = 25
    privParams.videoSaveFirstFrames = 2
    privParams.displayScale = 8
    privParams.agentSize = 4
    privParams.genomeAnalysisStride = privParams.videoStride
    privParams.displaySampleGenomes = 5
    privParams.genomeComparisonMethod = 1
    privParams.updateGraphLog = true
    privParams.updateGraphLogStride = privParams.videoStride
    privParams.deterministic = false
    privParams.RNGSeed = 12345678
    privParams.graphLogUpdateCommand = "/usr/bin/gnuplot --persist ./tools/graphlog.gp"
    privParams.parameterChangeGenerationNumber = 0

    self.privParams = privParams
end

ParamManager.registerConfigFile = function(self, filename) 
    self.configFilename = filename
end 

ParamManager.ingestParameter = function(self, name, val)

    -- std::transform(name.begin(), name.end(), name.begin(),
    --                [](unsigned char c){ return std::tolower(c) })
    -- //std::cout << name << " " << val << '\n' << std::endl
    local pm = self.privParams[name]
    if(pm) then 
        self.privParams[name] = val
    else
        print("Invalid param: "..tostring(name).." = "..tostring(val))
    end
end

-- Essentially merge config into params
ParamManager.updateFromConfigFile = function(generationNumber)
    
    local tbl = inifile.load(self.configFilename)
    -- Iterate the config file and overwrite the params manager config
    for k,v in pairs(tbl.default) do 
        self.privParams[v.key] = v.value 
    end 
end 

ParamManager.checkParameters = function()
end 

-- // Returns a copy of params with default values overridden by the values
-- // in the specified config file. The filename of the config file is saved
-- // inside the params for future reference.
paramsInit = function(argc, argv)

end
