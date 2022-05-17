
-- These are global tables. 
-- TODO: Make this a little more friendly

randomUint = require("biosim-lua.random")

require("biosim-lua.sensor-actions")

grid = require("biosim-lua.grid")       -- // The 2D world where the creatures live
signals = require("biosim-lua.signals") -- // A 2D array of pheromones that overlay the world grid
peeps = require("biosim-lua.peeps")     -- // The container of all the individuals in the population
imageWriter = require("biosim-lua.imageWriter") -- // This is for generating the movies

-- // The paramManager maintains a private copy of the parameter values, and a copy
-- // is available read-only through global variable p. Although this is not
-- // foolproof, you should be able to modify the config file during a simulation
-- // run and modify many of the parameters. See params.cpp and params.h for more info.
local paramManager = require("biosim-lua.params")


-- Global run state - this is mainly for threads when it was in C++. May remove
runMode = RunMode.STOP

-- This is a bit of a nasty global. Its used _everywhere_ so we will use this for the
--  time being. But.. BIG TODO - FIX THIS!
p = paramManager

require("biosim-lua.analysis")
require("biosim-lua.spawnNewGeneration")
require("biosim-lua.genome-neurons")