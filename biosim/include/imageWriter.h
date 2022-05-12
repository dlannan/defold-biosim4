#ifndef IMAGEWRITER_H_INCLUDED
#define IMAGEWRITER_H_INCLUDED

// Creates a graphic frame for each simStep, then
// assembles them into a video at the end of a generation.

#include <atomic>
#include <mutex>
#include <condition_variable>
#include <thread>
#include "indiv.h"
#include "params.h"
#include "peeps.h"

namespace BS {

// This holds all data needed to construct one image frame. The data is
// cached in this structure so that the image writer can work on it in
// a separate thread while the main thread starts a new simstep.
struct ImageFrameData {
    unsigned simStep;
    unsigned generation;
    std::vector<Coord> indivLocs;
    std::vector<uint8_t> indivColors;
    std::vector<Coord> barrierLocs;
    typedef std::vector<std::vector<uint8_t>> SignalLayer;  // [x][y]
    std::vector<SignalLayer> signalLayers; // [layer][x][y]
};

void saveFrameThread(void * _ctx); // runs in a thread

struct ImageWriter {
    ImageWriter();
    void startNewGeneration();
    bool saveVideoFrame(unsigned simStep, unsigned generation);
    bool saveVideoFrameSync(unsigned simStep, unsigned generation);
    void saveGenerationVideo(unsigned generation);
    void abort();
    std::atomic<unsigned> droppedFrameCount;

    ImageFrameData getData() { 
        std::unique_lock<std::mutex> lck(mutex_);
        return data; 
    }

    std::atomic<bool> busy;
    std::mutex mutex_;
    std::condition_variable condVar;
    bool dataReady;

    ImageFrameData data;
    bool abortRequested;
    unsigned skippedFrames;
};

extern ImageWriter imageWriter;

} // end namespace BS

#endif // IMAGEWRITER_H_INCLUDED