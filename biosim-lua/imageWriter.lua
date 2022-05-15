
require("utils.copies")

-- // This holds all data needed to construct one image frame. The data is
-- // cached in this structure so that the image writer can work on it in
-- // a separate thread while the main thread starts a new simstep.
ImageFrameData = {
    simStep = 0,
    generation = 0,
    indivLocs = {},
    indivColors = {},
    barrierLocs = {},
    SignalLayer = {}, -- // [x][y]
    signalLayers = {}, -- // [layer][x][y]
}

ImageWriter = {}
    
ImageWriter.startNewGeneration = function() end
ImageWriter.saveVideoFrame = function(simStep, generation) end 
ImageWriter.saveVideoFrameSync = function(simStep, generation) end 
ImageWriter.saveGenerationVideo = function(generation) end 
ImageWriter.abort = function() end

ImageWriter.droppedFrameCount = 0

ImageWriter.getData = function() return data end

ImageWriter.busy = 0
ImageWriter.dataReady = false

ImageWriter.data = table.deepcopy(ImageFrameData)
ImageWriter.abortRequested = false
ImageWriter.skippedFrames = 0

return ImageWriter