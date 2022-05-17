

SENSOR = 1 -- // always a source
ACTION = 1 -- // always a sink
NEURON = 0 -- // can be either a source or sink

-- // This file defines which sensor input neurons and which action output neurons
-- // are compiled into the simulator. This file can be modified to create a simulator
-- // executable that supports only a subset of all possible sensor or action neurons.

-- // Neuron Sources (Sensors) and Sinks (Actions)

-- // These sensor, neuron, and action value ranges are here for documentation
-- // purposes. Most functions now assume these ranges. We no longer support changes
-- // to these ranges.
SENSOR_MIN = 0.0
SENSOR_MAX = 1.0
SENSOR_RANGE = SENSOR_MAX - SENSOR_MIN

NEURON_MIN = -1.0
NEURON_MAX = 1.0
NEURON_RANGE = NEURON_MAX - NEURON_MIN

ACTION_MIN = 0.0
ACTION_MAX = 1.0
ACTION_RANGE = ACTION_MAX - ACTION_MIN


-- // Place the sensor neuron you want enabled prior to NUM_SENSES. Any
-- // that are after NUM_SENSES will be disabled in the simulator.
-- // If new items are added to this enum, also update the name functions
-- // in analysis.cpp.
-- // I means data about the individual, mainly stored in Indiv
-- // W means data about the environment, mainly stored in Peeps or Grid
Sensor = {
    LOC_X   = 0,          -- // I distance from left edge
    LOC_Y   = 1,          -- // I distance from bottom
    BOUNDARY_DIST_X = 2,  -- // I X distance to nearest edge of world
    BOUNDARY_DIST   = 3,  -- // I distance to nearest edge of world
    BOUNDARY_DIST_Y = 4,  -- // I Y distance to nearest edge of world
    GENETIC_SIM_FWD = 5,  -- // I genetic similarity forward
    LAST_MOVE_DIR_X = 6,  -- // I +- amount of X movement in last movement
    LAST_MOVE_DIR_Y = 7,  -- // I +- amount of Y movement in last movement
    LONGPROBE_POP_FWD = 8,-- // W long look for population forward
    LONGPROBE_BAR_FWD = 9,-- // W long look for barriers forward
    POPULATION      = 10, -- // W population density in neighborhood
    POPULATION_FWD  = 11, -- // W population density in the forward-reverse axis
    POPULATION_LR   = 12, -- // W population density in the left-right axis
    OSC1            = 13, -- // I oscillator +-value
    AGE             = 14, -- // I
    BARRIER_FWD     = 15, -- // W neighborhood barrier distance forward-reverse axis
    BARRIER_LR      = 16, -- // W neighborhood barrier distance left-right axis
    RANDOM          = 17, -- //   random sensor value, uniform distribution
    SIGNAL0         = 18, -- // W strength of signal0 in neighborhood
    SIGNAL0_FWD     = 19, -- // W strength of signal0 in the forward-reverse axis
    SIGNAL0_LR      = 20, -- // W strength of signal0 in the left-right axis
    NUM_SENSES      = 21, -- // <<------------------ END OF ACTIVE SENSES MARKER
}

-- // Place the action neuron you want enabled prior to NUM_ACTIONS. Any
-- // that are after NUM_ACTIONS will be disabled in the simulator.
-- // If new items are added to this enum, also update the name functions
-- // in analysis.cpp.
-- // I means the action affects the individual internally (Indiv)
-- // W means the action also affects the environment (Peeps or Grid)
Action = {
    MOVE_X          = 0,             -- // W +- X component of movement
    MOVE_Y          = 1,             -- // W +- Y component of movement
    MOVE_FORWARD    = 2,             -- // W continue last direction
    MOVE_RL         = 3,             -- // W +- component of movement
    MOVE_RANDOM     = 4,             -- // W
    SET_OSCILLATOR_PERIOD   = 5,     -- // I
    SET_LONGPROBE_DIST      = 6,     -- // I
    SET_RESPONSIVENESS      = 7,     -- // I
    EMIT_SIGNAL0    = 8,             -- // W
    MOVE_EAST       = 9,             -- // W
    MOVE_WEST       = 10,            -- // W
    MOVE_NORTH      = 11,            -- // W
    MOVE_SOUTH      = 12,            -- // W
    MOVE_LEFT       = 13,            -- // W
    MOVE_RIGHT      = 14,            -- // W
    MOVE_REVERSE    = 15,            -- // W
    NUM_ACTIONS     = 16,            -- // <<----------------- END OF ACTIVE ACTIONS MARKER
    KILL_FORWARD    = 17,            -- // W
}

-- extern std::string sensorName(Sensor sensor);
-- extern std::string actionName(Action action);
-- extern void printSensorsActions(); // list the names to stdout