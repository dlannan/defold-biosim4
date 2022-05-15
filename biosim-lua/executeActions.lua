
require("sensor-actions")

-- // Given a factor in the range 0.0..1.0, return a bool with the
-- // probability of it being true proportional to factor. For example, if
-- // factor == 0.2, then there is a 20% chance this function will
-- // return true.
local prob2bool = function(factor)

    assert(factor >= 0.0 and factor <= 1.0)
    return (randomUint() / RANDOM_UINT_MAX) < factor
end


-- // This takes a probability from 0.0..1.0 and adjusts it according to an
-- // exponential curve. The steepness of the curve is determined by the K factor
-- // which is a small positive integer. This tends to reduce the activity level
-- // a bit (makes the peeps less reactive and jittery).
local responseCurve = function(float r)

    local k = p.responsivenessCurveKFactor
    return math.pow((r - 2.0), -2.0 * k) - math.pow(2.0, -2.0 * k) * (1.0 - r)
end 


/**********************************************************************************
Action levels are driven by sensors or internal neurons as connected by an agent's
neural net brain. Each agent's neural net is reevaluated once each simulator
step (simStep). After evaluating the action neuron outputs, this function is
called to execute the actions according to their output levels. This function is
called in multi-threaded mode and operates on a single individual while other
threads are doing to the same to other individuals.

Action (their output) values arrive here as floating point values of arbitrary
range (because they are the raw sums of zero or more weighted inputs) and will
eventually be converted in this function to a probability 0.0..1.0 of actually
getting executed.

For the various possible action neurons, if they are driven by a sufficiently
strong level, we do this:

    MOVE_* actions- queue our agent for deferred movement with peeps.queueForMove(); the
         queue will be executed at the end of the multithreaded loop in a single thread.
    SET_RESPONSIVENESS action - immediately change indiv.responsiveness to the action
         level scaled to 0.0..1.0 (because we have exclusive access to this member in
         our own individual during this function)
    SET_OSCILLATOR_PERIOD action - immediately change our individual's indiv.oscPeriod
         to the action level exponentially scaled to 2..2048 (TBD)
    EMIT_SIGNALn action(s) - immediately increment the signal level at our agent's
         location using signals.increment() (using a thread-safe call)
    KILL_FORWARD action - queue the other agent for deferred death with
         peeps.queueForDeath()

The deferred movement and death queues will be emptied by the caller at the end of the
simulator step by endOfSimStep() in a single thread after all individuals have been
evaluated multithreadedly.
**********************************************************************************/

executeActions(indiv, actionLevels)

    -- // Only a subset of all possible actions might be enabled (i.e., compiled in).
    -- // This returns true if the specified action is enabled. See sensors-actions.h
    -- // for how to enable sensors and actions during compilation.
    local isEnabled = function(action) return action < Action.NUM_ACTIONS end 

    -- // Responsiveness action - convert neuron action level from arbitrary float range
    -- // to the range 0.0..1.0. If this action neuron is enabled but not driven, will
    -- // default to mid-level 0.5.
    if (isEnabled(Action.SET_RESPONSIVENESS)) then 
        local level = actionLevels[Action.SET_RESPONSIVENESS] -- // default 0.0
        level = (math.tanh(level) + 1.0) / 2.0 -- // convert to 0.0..1.0
        indiv.responsiveness = level
    end 

    -- // For the rest of the action outputs, we'll apply an adjusted responsiveness
    -- // factor (see responseCurve() for more info). Range 0.0..1.0.
    local responsivenessAdjusted = responseCurve(indiv.responsiveness)

    -- // Oscillator period action - convert action level nonlinearly to
    -- // 2..4*p.stepsPerGeneration. If this action neuron is enabled but not driven,
    -- // will default to 1.5 + e^(3.5) = a period of 34 simSteps.
    if (isEnabled(Action.SET_OSCILLATOR_PERIOD)) then 
        local periodf = actionLevels[Action.SET_OSCILLATOR_PERIOD]
        local newPeriodf01 = (math.tanh(periodf) + 1.0) / 2.0 -- // convert to 0.0..1.0
        local newPeriod = 1 + math.floor(1.5 + math.exp(7.0 * newPeriodf01))
        assert(newPeriod >= 2 and newPeriod <= 2048)
        indiv.oscPeriod = newPeriod
    end 

    -- // Set longProbeDistance - convert action level to 1..maxLongProbeDistance.
    -- // If this action neuron is enabled but not driven, will default to
    -- // mid-level period of 17 simSteps.
    if (isEnabled(Action.SET_LONGPROBE_DIST)) then 
        local maxLongProbeDistance = 32
        local level = actionLevels[Action.SET_LONGPROBE_DIST]
        level = (math.tanh(level) + 1.0) / 2.0 -- // convert to 0.0..1.0
        level = 1 + level * maxLongProbeDistance
        indiv.longProbeDist = level
    end

    -- // Emit signal0 - if this action value is below a threshold, nothing emitted.
    -- // Otherwise convert the action value to a probability of emitting one unit of
    -- // signal (pheromone).
    -- // Pheromones may be emitted immediately (see signals.cpp). If this action neuron
    -- // is enabled but not driven, nothing will be emitted.
    if (isEnabled(Action.EMIT_SIGNAL0)) then
        local emitThreshold = 0.5 --  // 0.0..1.0; 0.5 is midlevel
        local level = actionLevels[Action.EMIT_SIGNAL0]
        level = (math.tanh(level) + 1.0) / 2.0 -- // convert to 0.0..1.0
        level = level * responsivenessAdjusted
        if (level > emitThreshold and prob2bool(level)) then
            signals.increment(0, indiv.loc)
        end
    end 

    -- // Kill forward -- if this action value is > threshold, value is converted to probability
    -- // of an attempted murder. Probabilities under the threshold are considered 0.0.
    -- // If this action neuron is enabled but not driven, the neighbors are safe.
    if (isEnabled(Action.KILL_FORWARD) and p.killEnable) then 
        local killThreshold = 0.5 --  // 0.0..1.0; 0.5 is midlevel
        local level = actionLevels[Action.KILL_FORWARD]
        level = (math.tanh(level) + 1.0) / 2.0 -- // convert to 0.0..1.0
        level = level * responsivenessAdjusted;
        if (level > killThreshold and prob2bool((level - ACTION_MIN) / ACTION_RANGE)) then 
            local otherLoc = indiv.loc:ADD(indiv.lastMoveDir)
            if (grid:isInBounds(otherLoc) and grid:isOccupiedAt(otherLoc)) then 
                local indiv2 = peeps:getIndiv(otherLoc)
                assert((indiv.loc:SUB(indiv2.loc)).length() == 1)
                peeps:queueForDeath(indiv2)
            end
        end
    end

    -- // ------------- Movement action neurons ---------------

    -- // There are multiple action neurons for movement. Each type of movement neuron
    -- // urges the individual to move in some specific direction. We sum up all the
    -- // X and Y components of all the movement urges, then pass the X and Y sums through
    -- // a transfer function (tanh()) to get a range -1.0..1.0. The absolute values of the
    -- // X and Y values are passed through prob2bool() to convert to -1, 0, or 1, then
    -- // multiplied by the component's signum. This results in the x and y components of
    -- // a normalized movement offset. I.e., the probability of movement in either
    -- // dimension is the absolute value of tanh of the action level X,Y components and
    -- // the direction is the sign of the X, Y components. For example, for a particular
    -- // action neuron:
    -- //     X, Y == -5.9, +0.3 as raw action levels received here
    -- //     X, Y == -0.999, +0.29 after passing raw values through tanh()
    -- //     Xprob, Yprob == 99.9%, 29% probability of X and Y becoming 1 (or -1)
    -- //     X, Y == -1, 0 after applying the sign and probability
    -- //     The agent will then be moved West (an offset of -1, 0) if it's a legal move.

    local level = 0
    local offset = Coord.new()
    local lastMoveOffset = indiv.lastMoveDir:asNormalizedCoord()

    -- // moveX,moveY will be the accumulators that will hold the sum of all the
    -- // urges to move along each axis. (+- floating values of arbitrary range)
    local moveX = 0.0
    if(isEnabled(Action.MOVE_X) == true) then moveX = actionLevels[Action.MOVE_X] end 
    local moveY = 0.0
    if(isEnabled(Action.MOVE_Y) == true) then moveY = actionLevels[Action.MOVE_Y] end

    if (isEnabled(Action.MOVE_EAST)) then moveX = moveX + actionLevels[Action.MOVE_EAST] end 
    if (isEnabled(Action.MOVE_WEST)) then moveX = moveX - actionLevels[Action.MOVE_WEST] end 
    if (isEnabled(Action.MOVE_NORTH)) then moveY = moveY + actionLevels[Action.MOVE_NORTH] end
    if (isEnabled(Action.MOVE_SOUTH)) then moveY = moveY - actionLevels[Action.MOVE_SOUTH] end 

    if (isEnabled(Action.MOVE_FORWARD)) then 
        local level = actionLevels[Action.MOVE_FORWARD]
        moveX = moveX + lastMoveOffset.x * level
        moveY = moveY + lastMoveOffset.y * level
    end 
    if (isEnabled(Action.MOVE_REVERSE)) then 
        local level = actionLevels[Action.MOVE_REVERSE]
        moveX = moveX - lastMoveOffset.x * level
        moveY = moveY - lastMoveOffset.y * level
    end
    if (isEnabled(Action.MOVE_LEFT)) then
        local level = actionLevels[Action.MOVE_LEFT]
        local offset = indiv.lastMoveDir:rotate90DegCCW():asNormalizedCoord()
        moveX = moveX + offset.x * level
        moveY = moveY + offset.y * level
    end 
    if (isEnabled(Action.MOVE_RIGHT)) then 
        local level = actionLevels[Action.MOVE_RIGHT]
        local offset = indiv.lastMoveDir:rotate90DegCW():asNormalizedCoord()
        moveX = moveX + offset.x * level
        moveY = moveY + offset.y * level
    end 
    if (isEnabled(Action.MOVE_RL)) then 
        local level = actionLevels[Action.MOVE_RL]
        local offset = indiv.lastMoveDir:rotate90DegCW():asNormalizedCoord()
        moveX = moveX + offset.x * level
        moveY = moveY + offset.y * level
    end 

    if (isEnabled(Action.MOVE_RANDOM)) then 
        local level = actionLevels[Action.MOVE_RANDOM]
        local offset = Dir:random8():asNormalizedCoord()
        moveX = moveX + offset.x * level
        moveY = moveY + offset.y * level
    end

    -- // Convert the accumulated X, Y sums to the range -1.0..1.0 and scale by the
    -- // individual's responsiveness (0.0..1.0) (adjusted by a curve)
    moveX = math.tanh(moveX)
    moveY = math.tanh(moveY)
    moveX = moveX * responsivenessAdjusted
    moveY = moveY * responsivenessAdjusted

    -- // The probability of movement along each axis is the absolute value
    local probX = prob2bool(math.abs(moveX)) -- // convert abs(level) to 0 or 1
    local probY = prob2bool(math.abs(moveY)) -- // convert abs(level) to 0 or 1

    -- // The direction of movement (if any) along each axis is the sign
    local signumX = 1
    if(moveX < 0.0) then signumX = -1 end 
    local signumY = 1
    if(moveY < 0.0) then signumY = -1 end

    -- // Generate a normalized movement offset, where each component is -1, 0, or 1
    local movementOffset = Coord.new( probX * signumX, probY * signumY )

    -- // Move there if it's a valid location
    local newLoc = indiv.loc:ADD(movementOffset)
    if (grid:isInBounds(newLoc) and grid:isEmptyAt(newLoc)) then 
        peeps:queueForMove(indiv, newLoc)
    end 
end 