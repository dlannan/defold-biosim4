// simulator.cpp - Main thread

// This file contains simulator(), the top-level entry point of the simulator.
// simulator() is called from main.cpp with a copy of argc and argv.
// If there is no command line argument, the simulator will read the default
// config file ("biosim4.ini" in the current directory) to get the simulation
// parameters for this run. If there are one or more command line args, then
// argv[1] must contain the name of the config file which will be read instead
// of biosim4.ini. Any args after that are ignored. The simulator code is
// in namespace BS (for "biosim").

#include <iostream>
#include <chrono>
#include <cassert>
#include <utility>
#include <algorithm>
#include <vector>

#include <dmsdk/sdk.h>
#include <dmsdk/dlib/thread.h>


#include "simulator.h"     // the simulator data structures
#include "imageWriter.h"   // this is for generating the movies

namespace BS {

extern void initializeGeneration0();
extern unsigned spawnNewGeneration(unsigned generation, unsigned murderCount);
extern void displaySampleGenomes(unsigned count);
extern void executeActions(Indiv &indiv, std::array<float, Action::NUM_ACTIONS> &actionLevels);
extern void endOfSimStep(unsigned simStep, unsigned generation);
extern void endOfGeneration(unsigned generation);

static RunMode runMode = RunMode::STOP;
static Grid grid;        // The 2D world where the creatures live
static Signals signals;  // A 2D array of pheromones that overlay the world grid
static Peeps peeps;      // The container of all the individuals in the population
static ImageWriter imageWriter; // This is for generating the movies

// The paramManager maintains a private copy of the parameter values, and a copy
// is available read-only through global variable p. Although this is not
// foolproof, you should be able to modify the config file during a simulation
// run and modify many of the parameters. See params.cpp and params.h for more info.
static ParamManager paramManager;
const Params &p { paramManager.getParamRef() }; // read-only params


/**********************************************************************************************
Execute one simStep for one individual.

This executes in its own thread, invoked from the main simulator thread. First we execute
indiv.feedForward() which computes action values to be executed here. Some actions such as
signal emission(s) (pheromones), agent movement, or deaths will have been queued for
later execution at the end of the generation in single-threaded mode (the deferred queues
allow the main data structures (e.g., grid, signals) to be freely accessed read-only in all threads).

In order to be thread-safe, the main simulator-wide data structures and their
accessibility are:

    grid - read-only
    signals - (pheromones) read-write for the location where our agent lives
        using signals.increment(), read-only for other locations
    peeps - for other individuals, we can only read their index and genome.
        We have read-write access to our individual through the indiv argument.

The other important variables are:

    simStep - the current age of our agent, reset to 0 at the start of each generation.
         For many simulation scenarios, this matches our indiv.age member.
    randomUint - global random number generator, a private instance is given to each thread
**********************************************************************************************/
void simStepOneIndiv(Indiv &indiv, unsigned simStep)
{
    if(indiv.alive == true) ++indiv.age; // for this implementation, tracks simStep
    auto actionLevels = indiv.feedForward(simStep);
    executeActions(indiv, actionLevels);
}




/********************************************************************************
Start of simulator

All the agents are randomly placed with random genomes at the start. The outer
loop is generation, the inner loop is simStep. There is a fixed number of
simSteps in each generation. Agents can die at any simStep and their corpses
remain until the end of the generation. At the end of the generation, the
dead corpses are removed, the survivors reproduce and then die. The newborns
are placed at random locations, signals (pheromones) are updated, simStep is
reset to 0, and a new generation proceeds.

The paramManager manages all the simulator parameters. It starts with defaults,
then keeps them updated as the config file (biosim4.ini) changes.

The main simulator-wide data structures are:
    grid - where the agents live (identified by their non-zero index). 0 means empty.
    signals - multiple layers overlay the grid, hold pheromones
    peeps - an indexed set of agents of type Indiv; indexes start at 1

The important simulator-wide variables are:
    generation - starts at 0, then increments every time the agents die and reproduce.
    simStep - reset to 0 at the start of each generation; fixed number per generation.
    randomUint - global random number generator

The threads are:
    main thread - simulator
    simStepOneIndiv() - child threads created by the main simulator thread
    imageWriter - saves image frames used to make a movie (possibly not threaded
        due to unresolved bugs when threaded)
********************************************************************************/

static unsigned generation  = 0;
static unsigned survivors   = 0;
static double   diversity   = 0.0;
static unsigned murderCount = 0;

static void DoSimStep( void * _ctx )
{
    randomUint.initialize(); // seed the RNG, each thread has a private instance

    while(generation < p.maxGenerations) { // generation loop

        if(runMode == RunMode::RUN) {
            murderCount = 0; // for reporting purposes

            for (unsigned simStep = 0; simStep < p.stepsPerGeneration; ++simStep) 
            {
                // multithreaded loop: index 0 is reserved, start at 1
                //#pragma omp for schedule(auto)
                for (unsigned indivIndex = 1; indivIndex <= p.population; ++indivIndex) {
                    if (peeps[indivIndex].alive) {
                        simStepOneIndiv(peeps[indivIndex], simStep);
                    }
                }

                // In single-thread mode: this executes deferred, queued deaths and movements,
                // updates signal layers (pheromone), etc.
                //#pragma omp single
                {
                    murderCount += peeps.deathQueueSize();
                    endOfSimStep(simStep, generation);
                }
            }

            //#pragma omp single
            {
                endOfGeneration(generation);
                paramManager.updateFromConfigFile(generation + 1);
                unsigned numberSurvivors = spawnNewGeneration(generation, murderCount);
                // if (numberSurvivors > 0 && (generation % p.genomeAnalysisStride == 0)) {
                //     displaySampleGenomes(p.displaySampleGenomes);
                // }
                survivors = numberSurvivors;
                if (numberSurvivors == 0) {
                    generation = 0;  // start over
                } else {
                    ++generation;
                }
            }
        }

        if(runMode == RunMode::STOP || runMode == RunMode::ABORT) {
            break;
        }
    }
}

void simulator(char *argv)
{
    printSensorsActions(); // show the agents' capabilities

    // Simulator parameters are available read-only through the global
    // variable p after paramManager is initialized.
    // Todo: remove the hardcoded parameter filename.
    paramManager.setDefaults();
    paramManager.registerConfigFile(argv);
    paramManager.updateFromConfigFile(0);
    paramManager.checkParameters(); // check and report any problems
    randomUint.initialize(); // seed the RNG for main-thread use

    // Allocate container space. Once allocated, these container elements
    // will be reused in each new generation.
    grid.init(p.sizeX, p.sizeY); // the land on which the peeps live
    signals.init(p.signalLayers, p.sizeX, p.sizeY);  // where the pheromones waft
    peeps.init(p.population); // the peeps themselves

    // If imageWriter is to be run in its own thread, start it here:
    //std::thread t(&ImageWriter::saveFrameThread, &imageWriter);
    //dmThread::New(saveFrameThread, 0x80000, (void *)&imageWriter, "biosim_imagewriter_thread");

    // Unit tests:
    //unitTestConnectNeuralNetWiringFromGenome();
    //unitTestGridVisitNeighborhood();

    initializeGeneration0(); // starting population
    runMode = RunMode::PAUSE;

    //#pragma omp single
    dmThread::New(DoSimStep, 0x80000, nullptr, "biosim_thread");
}

void simulationMode( int mode )
{   
    runMode = (RunMode)mode;
}

void simulationStep( void )
{   
}

void simulationDone( void ) 
{
    displaySampleGenomes(3); // final report, for debugging

    std::cout << "Simulator exit." << std::endl;

    // If imageWriter is in its own thread, stop it and wait for it here:
    //imageWriter.abort();
    //t.join();
}

} // end namespace BS
