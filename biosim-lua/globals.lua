
-- These are global tables. 
-- TODO: Make this a little more friendly

grid = require("grid")        // The 2D world where the creatures live
signals = require("signals")  // A 2D array of pheromones that overlay the world grid
peeps = require("peeps")      // The container of all the individuals in the population
imageWriter = require("ImageWriter") -- // This is for generating the movies

-- // The paramManager maintains a private copy of the parameter values, and a copy
-- // is available read-only through global variable p. Although this is not
-- // foolproof, you should be able to modify the config file during a simulation
-- // run and modify many of the parameters. See params.cpp and params.h for more info.
local paramManager = require("params")


-- Global run state - this is mainly for threads when it was in C++. May remove
RunMode runMode = RunMode.STOP

-- This is a bit of a nasty global. Its used _everywhere_ so we will use this for the
--  time being. But.. BIG TODO - FIX THIS!
p = paramManager