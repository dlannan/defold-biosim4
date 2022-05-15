#ifndef _HEADER_STATICS_
#define _HEADER_STATICS_

#include "params.h"
#include "grid.h"
#include "signals.h"
#include "peeps.h"
#include "imageWriter.h"

namespace BS
{

extern ParamManager paramManager; // manages simulator params from the config file plus more
extern const Params &p; // read-only simulator config params
extern Grid grid;  // 2D arena where the individuals live
extern Signals signals;  // pheromone layers
extern Peeps peeps;   // container of all the individuals
extern ImageWriter imageWriter; // This is for generating the movies
extern unsigned generation;
extern unsigned survivors;

}

#endif