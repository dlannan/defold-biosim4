
require("biosim-lua.basicTypes")

getPopulationDensityAlongAxis = function( loc, dir)

    -- // Converts the population along the specified axis to the sensor range. The
    -- // locations of neighbors are scaled by the inverse of their distance times
    -- // the positive absolute cosine of the difference of their angle and the
    -- // specified axis. The maximum positive or negative magnitude of the sum is
    -- // about 2*radius. We don't adjust for being close to a border, so populations
    -- // along borders and in corners are commonly sparser than away from borders.
    -- // An empty neighborhood results in a sensor value exactly midrange; below
    -- // midrange if the population density is greatest in the reverse direction,
    -- // above midrange if density is greatest in forward direction.
    assert(dir:NEQ(Compass.CENTER)) --  // require a defined axis

    local sum = 0.0
    local dirVec = dir:asNormalizedCoord()
    local len = math.sqrt(dirVec.x * dirVec.x + dirVec.y * dirVec.y)
    local dirVecX = dirVec.x / len
    local dirVecY = dirVec.y / len -- // Unit vector components along dir

    local f = function(tloc) 
        if (tloc:NEQ(loc) and grid:isOccupiedAt(tloc)) then
            local offset = tloc:SUB(loc)
            local proj = dirVecX * offset.x + dirVecY * offset.y -- // Magnitude of projection along dir
            local contrib = proj / (offset.x * offset.x + offset.y * offset.y)
            sum = sum + contrib
        end
    end 

    visitNeighborhood(loc, p.populationSensorRadius, f)

    local maxSumMag = 6.0 * p.populationSensorRadius
    assert(sum >= -maxSumMag and sum <= maxSumMag)

    local sensorVal = 0.0
    sensorVal = sum / maxSumMag -- // convert to -1.0..1.0
    sensorVal = (sensorVal + 1.0) / 2.0 -- // convert to 0.0..1.0

    return sensorVal
end 


-- // Converts the number of locations (not including loc) to the next barrier location
-- // along opposite directions of the specified axis to the sensor range. If no barriers
-- // are found, the result is sensor mid-range. Ignores agents in the path.
getShortProbeBarrierDistance = function(loc0, dir, probeDistance)

    countFwd = 0
    countRev = 0
    local loc = loc0:ADD( dir )
    local numLocsToTest = probeDistance
    -- // Scan positive direction
    while (numLocsToTest > 0 and grid:isInBounds(loc) and not grid:isBarrierAt(loc)) do
        countFwd = countFwd + 1
        loc = loc:ADD(dir)
        numLocsToTest = numLocsToTest - 1
    end 
    if (numLocsToTest > 0 and not grid.isInBounds(loc)) then
        countFwd = probeDistance
    end 

    -- // Scan negative direction
    numLocsToTest = probeDistance
    loc = loc0:SUB(dir)
    while (numLocsToTest > 0 and grid:isInBounds(loc) and not grid:isBarrierAt(loc)) do
        countRev = countRev + 1
        loc = loc:SUB(dir)
        numLocsToTest = numLocsToTest - 1
    end 
    if (numLocsToTest > 0 and not grid:isInBounds(loc)) then
        countRev = probeDistance
    end

    local sensorVal = ((countFwd - countRev) + probeDistance) -- // convert to 0..2*probeDistance
    sensorVal = (sensorVal / 2.0) / probeDistance -- // convert to 0.0..1.0
    return sensorVal
end


getSignalDensity = function(layerNum, loc)

    -- // returns magnitude of the specified signal layer in a neighborhood, with
    -- // 0.0..maxSignalSum converted to the sensor range.

    countLocs = 0
    sum = 0
    center = loc

    local Locfunc = function(tloc) 
        countLocs = countLocs + 1
        sum = sum + signals:getMagnitude(layerNum, tloc)
    end 

    visitNeighborhood(center, p.signalSensorRadius, Locfunc)
    maxSum = countLocs * SIGNAL_MAX
    sensorVal = sum / maxSum -- // convert to 0.0..1.0

    return sensorVal
end


getSignalDensityAlongAxis = function(layerNum, loc, dir)

    -- // Converts the signal density along the specified axis to sensor range. The
    -- // values of cell signal levels are scaled by the inverse of their distance times
    -- // the positive absolute cosine of the difference of their angle and the
    -- // specified axis. The maximum positive or negative magnitude of the sum is
    -- // about 2*radius*SIGNAL_MAX (?). We don't adjust for being close to a border,
    -- // so signal densities along borders and in corners are commonly sparser than
    -- // away from borders.

    assert(dir:NEQ(Compass_CENTER)) -- // require a defined axis

    local sum = 0.0
    local dirVec = dir:asNormalizedCoord()
    local len = math.sqrt(dirVec.x * dirVec.x + dirVec.y * dirVec.y)
    local dirVecX = dirVec.x / len
    local dirVecY = dirVec.y / len -- // Unit vector components along dir

    local f = function(tloc) 
        if (tloc:NEQ(loc)) then
            local offset = tloc:SUBCOORD(loc)
            local proj = (dirVecX * offset.x + dirVecY * offset.y) -- // Magnitude of projection along dir
            local contrib = (proj * signals:getMagnitude(layerNum, loc)) / (offset.x * offset.x + offset.y * offset.y)
            sum = sum + contrib
        end 
    end 

    visitNeighborhood(loc, p.signalSensorRadius, f)

    local maxSumMag = 6.0 * p.signalSensorRadius * SIGNAL_MAX
    assert(sum >= -maxSumMag and sum <= maxSumMag)
    local sensorVal = sum / maxSumMag -- // convert to -1.0..1.0
    sensorVal = (sensorVal + 1.0) / 2.0 -- // convert to 0.0..1.0

    return sensorVal
end 


-- // Returns the number of locations to the next agent in the specified
-- // direction, not including loc. If the probe encounters a boundary or a
-- // barrier before reaching the longProbeDist distance, returns longProbeDist.
-- // Returns 0..longProbeDist.
longProbePopulationFwd = function(loc, dir, longProbeDist)

    assert(longProbeDist > 0)
    local count = 0
    loc = loc:ADDDIR( dir )
    local numLocsToTest = longProbeDist
    while (numLocsToTest > 0 and grid:isInBounds(loc) and grid:isEmptyAt(loc)) do
        count = count + 1
        loc = loc:ADDDIR( dir )
        numLocsToTest = numLocsToTest - 1
    end 
    if (numLocsToTest > 0 and (not grid:isInBounds(loc) or grid:isBarrierAt(loc))) then
        return longProbeDist
    else
        return count
    end 
end 


-- // Returns the number of locations to the next barrier in the
-- // specified direction, not including loc. Ignores agents in the way.
-- // If the distance to the border is less than the longProbeDist distance
-- // and no barriers are found, returns longProbeDist.
-- // Returns 0..longProbeDist.
longProbeBarrierFwd = function(loc, dir, longProbeDist)
    assert(longProbeDist > 0)
    local count = 0
    loc = loc:ADDDIR( dir )
    local numLocsToTest = longProbeDist
    while (numLocsToTest > 0 and grid:isInBounds(loc) and not grid:isBarrierAt(loc)) do
        count = count + 1
        loc = loc:ADDDIR(dir)
        numLocsToTest = numLocsToTest - 1
    end 
    if (numLocsToTest > 0 and not grid:isInBounds(loc)) then
        return longProbeDist
    else
        return count
    end 
end 

