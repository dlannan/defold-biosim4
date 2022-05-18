


-- // Approximate gene match: Has to match same source, sink, with similar weight
-- //
genesMatch = function(g1, g2)

    return g1.sinkNum == g2.sinkNum
        and g1.sourceNum == g2.sourceNum
        and g1.sinkType == g2.sinkType
        and g1.sourceType == g2.sourceType
        and g1.weight == g2.weight
end


-- // The jaro_winkler_distance() function is adapted from the C version at
-- // https://github.com/miguelvps/c/blob/master/jarowinkler.c
-- // under a GNU license, ver. 3. This comparison function is useful if
-- // the simulator allows genomes to change length, or if genes are allowed
-- // to relocate to different offsets in the genome. I.e., this function is
-- // tolerant of gaps, relocations, and genomes of unequal lengths.
-- //
jaro_winkler_distance = function(genome1, genome2) 
    local dw = 0.0
    -- auto max = [](int a, int b) { return a > b ? a : b; };
    -- auto min = [](int a, int b) { return a < b ? a : b; };

    local s = genome1
    local a = genome2

    local i, j, l
    local m, t = 0, 0
    local sl = #s -- // strlen(s);
    local al = #a -- // strlen(a);

    local maxNumGenesToCompare = 20
    sl = math.min(maxNumGenesToCompare, sl) -- // optimization: approximate for long genomes
    al = math.min(maxNumGenesToCompare, al)

    local sflags = {}
    local aflags = {}
    local range = math.max(0, math.max(sl, al) / 2 - 1)

    if (not sl or not al) then return 0.0 end

    -- /* calculate matching characters */
    for i = 0, al-1 do
        local l = math.min(i + range + 1, sl)
        for j = math.max(i - range, 0), l-1 do
            if (genesMatch(a[i], s[j]) and not sflags[j]) then
                sflags[j] = 1
                aflags[i] = 1
                m = m + 1
                break
            end
        end
    end

    if (not m) then return 0.0 end 

    -- /* calculate character transpositions */
    local l = 0
    for i = 0, al-1 do
        if (aflags[i] == 1) then
            for j = l, sl-1 do 
                if (sflags[j] == 1) then
                    l = j + 1
                    break
                end
            end 
            if (not genesMatch(a[i], s[j])) then
                t = t + 1
            end 
        end 
    end 
    t = t / 2

    -- /* Jaro distance */
    dw = ((m / sl) + (m / al) + ((m - t) / m)) / 3.0
    return dw
end


-- // Works only for genomes of equal length
hammingDistanceBits = function(genome1, genome2)

    assert(#genome1 == #genome2)

    local p1 = genome1
    local p2 = genome2

    local numElements = #genome1
    local bytesPerElement = 4
    local lengthBytes = numElements * bytesPerElement
    local lengthBits = lengthBytes * 8
    local bitCount = 0

    for index = 1, #genome1 do 
        -- print(p1[index]:GetData(), p2[index]:GetData())
        bitCount = bitCount + bit.bxor(p1[index]:GetData(), p2[index]:GetData())
    end

    -- // For two completely random bit patterns, about half the bits will differ,
    -- // resulting in c. 50% match. We will scale that by 2X to make the range
    -- // from 0 to 1.0. We clip the value to 1.0 in case the two patterns are
    -- // negatively correlated for some reason.
    return 1.0 - math.min(1.0, (2.0 * bitCount) / lengthBits)
end

-- // Returns 0.0..1.0
-- //
-- // ToDo: optimize by approximation for long genomes
genomeSimilarity = function(g1, g2)

    if(p.genomeComparisonMethod == 0) then 
        return jaro_winkler_distance(g1, g2);
    elseif(p.genomeComparisonMethod == 1) then 
        return hammingDistanceBits(g1, g2)
    elseif(p.genomeComparisonMethod == 2) then 
        return hammingDistanceBytes(g1, g2)
    else
        assert(false)
    end
end


-- // returns 0.0..1.0
-- // Samples random pairs of individuals regardless if they are alive or not
geneticDiversity = function()

    if (p.population < 2) then return 0.0 end

    -- // count limits the number of genomes sampled for performance reasons.
    local count = math.min(1000, p.population) --    // todo: !!! p.analysisSampleSize;
    local numSamples = 0
    local similaritySum = 0.0

    while (count > 0) do
        local index0 = randomUint:GetRange(1, p.population - 1) -- // skip first and last elements
        local index1 = index0 + 1
        similaritySum = similaritySum + genomeSimilarity(peeps:getIndivIndex(index0).genome, peeps:getIndivIndex(index1).genome)
        count = count - 1
        numSamples = numSamples + 1
    end
    local diversity = 1.0 - (similaritySum / numSamples)
    return diversity
end 