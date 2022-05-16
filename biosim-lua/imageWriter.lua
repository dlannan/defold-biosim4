
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

ImageWriter = {
    droppedFrameCount   = 0,
    busy                = 0,
    dataReady           = false,
    data                = table.deepcopy(ImageFrameData),
    abortRequested      = false,
    skippedFrames       = 0,
}
    
-- // Pushes a new image frame onto .imageList.
-- //
saveOneFrameImmed = function( data)

    -- //using namespace cimg_library;

    -- // CImg<uint8_t> image(p.sizeX * p.displayScale, p.sizeY * p.displayScale,
    -- //                     1,   // Z depth
    -- //                     3,   // color channels
    -- //                     255);  // initial value
    local color = {}
    local imageFilename = ""
    imageFilename = imageFilename..p.imageDir.."frame-"..
                  string.format("%06d", data.generation)..
                  '-'..string.format("%06d", data.simStep)..".png";

    -- // Draw barrier locations
    color[0], color[1], color[2] = 0x88, 0x88, 0x88
    for k,loc in pairs(data.barrierLocs) do
            -- // image.draw_rectangle(
            -- //     loc.x       * p.displayScale - (p.displayScale / 2), ((p.sizeY - loc.y) - 1)   * p.displayScale - (p.displayScale / 2),
            -- //     (loc.x + 1) * p.displayScale, ((p.sizeY - (loc.y - 0))) * p.displayScale,
            -- //     color,  // rgb
            -- //     1.0);  // alpha
    end

    -- // Draw agents
    local maxColorVal = 0xb0
    local maxLumaVal = 0xb0;

    local rgbToLuma = function(r, g, b) return (r+r+r+b+g+g+g+g) / 8 end

    for i = 0, #data.indivLocs-1 do
        local c = data.indivColors[i]
        color[0] = (c)                  -- // R: 0..255
        color[1] = bit.lshift(bit.band(c, 0x1f), 3)   -- // G: 0..255
        color[2] = lit.lshift(bit.band(c, 7), 5)      -- // B: 0..255

        -- // Prevent color mappings to very bright colors (hard to see):
        if (rgbToLuma(color[0], color[1], color[2]) > maxLumaVal) then
            if (color[0] > maxColorVal) color[0] = color[0] % maxColorVal
            if (color[1] > maxColorVal) color[1] = color[1] % maxColorVal
            if (color[2] > maxColorVal) color[2] = color[2] % maxColorVal
        end 

        -- // image.draw_circle(
        -- //         data.indivLocs[i].x * p.displayScale,
        -- //         ((p.sizeY - data.indivLocs[i].y) - 1) * p.displayScale,
        -- //         p.agentSize,
        -- //         color,  // rgb
        -- //         1.0);  // alpha
    end

    -- //image.save_png(imageFilename.str().c_str(), 3);
    -- //imageList.push_back(image);

    -- //CImgDisplay local(image, "biosim3");
end 

ImageWriter.new = function()
    local imgw = table.deepcopy(ImageWriter)
    imgw.droppedFrameCount = 0
    imgw.busy = true 
    imgw.dataReady = false 
    imgw.abortRequested = false 
end 

ImageWriter.startNewGeneration = function(self)
    self.skippedFrames = 0 
end

makeGeneticColor = function(genome)

    return bit.bor(bit.bor(bit.bor(bit.bor(bit.bor(bit.bor(bit.bor(bit.band(#genome, 1)
         , bit.lshift(genome[1].sourceType, 1))
         , bit.lshift(genome[-1].sourceType, 2))
         , bit.lshift(genome[1].sinkType, 3))
         , bit.lshift(genome[-1].sinkType, 4))
         , bit.lshift(bit.band(genome[1].sourceNum, 1), 5))
         , bit.lshift(bit.band(genome[1].sinkNum, 1), 6))
         , bit.lshift(bit.band(genome[-1].sourceNum, 1), 7))
end


-- // This is a synchronous gate for giving a job to saveFrameThread().
-- // Called from the same thread as the main simulator loop thread during
-- // single-thread mode.
-- // Returns true if the image writer accepts the job; returns false
-- // if the image writer is busy. Always called from a single thread
-- // and communicates with a single saveFrameThread(), so no need to make
-- // a critical section to safeguard the busy flag. When this function
-- // sets the busy flag, the caller will immediate see it, so the caller
-- // won't call again until busy is clear. When the thread clears the busy
-- // flag, it doesn't matter if it's not immediately visible to this
-- // function: there's no consequence other than a harmless frame-drop.
-- // The condition variable allows the saveFrameThread() to wait until
-- // there's a job to do.
ImageWriter.saveVideoFrame = function(self, simStep, generation) 
    if (not self.busy) then
        self.busy = true
        -- // queue job for saveFrameThread()
        -- // We cache a local copy of data from params, grid, and peeps because
        -- // those objects will change by the main thread at the same time our
        -- // saveFrameThread() is using it to output a video frame.
        self.data.simStep = simStep
        self.data.generation = generation
        self.data.indivLocs = {}
        self.data.indivColors = {}
        self.data.barrierLocs = {}
        self.data.signalLayers = {}
        -- //todo!!!
        for index = 1, p.population do
            indiv = peeps[index]
            if (indiv.alive) then
                tinsert(self.data.indivLocs, indiv.loc)
                tinsert(self.data.indivColors, makeGeneticColor(indiv.genome))
            end
        end 

        local barrierLocs = grid:getBarrierLocations()
        for k,loc in pairs(barrierLocs) do
            tinsert(self.data.barrierLocs, loc)
        end 

        -- // tell thread there's a job to do
        self.dataReady = true
        
        return true
    else
        -- // image saver thread is busy, drop a frame
        droppedFrameCount = droppedFrameCount + 1
        return false
    end 
end 

ImageWriter.saveVideoFrameSync = function(self, simStep, generation)
    -- // We cache a local copy of data from params, grid, and peeps because
    -- // those objects will change by the main thread at the same time our
    -- // saveFrameThread() is using it to output a video frame.
    self.data.simStep = simStep
    self.data.generation = generation
    self.data.indivLocs = {}
    self.data.indivColors = {}
    self.data.barrierLocs = {}
    self.data.signalLayers = {}
    -- //todo!!!
    for index = 1, p.population do
        indiv = peeps[index]
        if (indiv.alive) then
            tinsert(self.data.indivLocs, indiv.loc)
            tinsert(self.data.indivColors, makeGeneticColor(indiv.genome))
        end
    end

    local barrierLocs = grid:getBarrierLocations()
    for k, loc in pairs(barrierLocs) do
        tinsert(self.data.barrierLocs, loc)
    end 

    saveOneFrameImmed(self.data)
    return true
end 

ImageWriter.saveGenerationVideo = function(self, generation) 
    -- // if (imageList.size() > 0) {
    -- //     std::stringstream videoFilename;
    -- //     videoFilename << p.imageDir.c_str() << "/gen-"
    -- //                   << std::setfill('0') << std::setw(6) << generation
    -- //                   << ".avi";
    -- //     cv::setNumThreads(2);
    -- //     imageList.save_video(videoFilename.str().c_str(),
    -- //                          25,
    -- //                          "H264");
    -- //     if (skippedFrames > 0) {
    -- //         std::cout << "Video skipped " << skippedFrames << " frames" << std::endl;
    -- //     }
    -- // }
    startNewGeneration()
end 

ImageWriter.abort = function(self) 
    self.busy = true
    self.abortRequested = true
    self.dataReady = true
end

ImageWriter.getData = function() 
    return data 
end


-- // Runs in a thread; wakes up when there's a video frame to generate.
-- // When this wakes up, local copies of Params and Peeps will have been
-- // cached for us to use.
saveFrameThread = function( _ctx)

    local imageWriter = _ctx
    imageWriter.busy = false -- // we're ready for business
    print("Imagewriter thread started.")

    while (true) do
        -- // wait for job on queue
        if(imageWriter.dataReady and imageWriter.busy) then 
            -- // save frame
            imageWriter.dataReady = false
            imageWriter.busy = false

            if (imageWriter.abortRequested) then 
                break
            end

        -- // save image frame
        -- //saveOneFrameImmed(imageWriter->data);

        -- //std::cout << "Image writer thread waiting..." << std::endl;
        -- //std::this_thread::sleep_for(std::chrono::seconds(2));

        end 
    end
    print("Image writer thread exiting.")
end

return ImageWriter