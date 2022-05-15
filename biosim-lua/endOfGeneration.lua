

-- // At the end of each generation, we save a video file (if p.saveVideo is true) and
-- // print some genomic statistics to stdout (if p.updateGraphLog is true).

endOfGeneration = function(generation)

    if (p.saveVideo and ((generation % p.videoStride) == 0
                or generation <= p.videoSaveFirstFrames
                or (generation >= p.parameterChangeGenerationNumber
                    and generation <= p.parameterChangeGenerationNumber + p.videoSaveFirstFrames))) then
        imageWriter.saveGenerationVideo(generation)
    end 

    if (p.updateGraphLog and (generation == 1 or ((generation % p.updateGraphLogStride) == 0))) then
        --std::system(p.graphLogUpdateCommand.c_str());
    end 
end 