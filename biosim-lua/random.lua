


 RandomUintGenerator = {
        -- // for the Marsaglia algorithm
        rngx    = 0.0,
        rngy    = 0.0,
        rngz    = 0.0,
        rngc    = 0.0,
        -- // for the Jenkins algorithm
        a       = 0.0,
        b       = 0.0,
        c       = 0.0,
        d       = 0.0,
}

RandomUintGenerator.initialize = function() -- // must be called to seed the RNG

    if (p.deterministic) then
        -- // Initialize Marsaglia. Overflow wrap-around is ok. We just want
        -- // the four parameters to be unrelated. In the extremely unlikely
        -- // event that a coefficient is zero, we'll force it to an arbitrary
        -- // non-zero value. Each thread uses a different seed, yet
        -- // deterministic per-thread.
        self.rngx = p.RNGSeed + 123456789
        self.rngy = p.RNGSeed + 362436000
        self.rngz = p.RNGSeed + 521288629
        self.rngc = p.RNGSeed + 7654321
        if(rngx ~= 0) then rngx = 123456789 end 
        if(rngy ~= 0) then rngy = 123456789 end
        if(rngz ~= 0) then rngz = 123456789 end
        if(rngc ~= 0) then rngc = 123456789 end

        -- // Initialize Jenkins determinstically per-thread:
        self.a = 0xf1ea5eed
        self.b = p.RNGSeed 
        self.c = p.RNGSeed  
        self.d = p.RNGSeed 

        if (self.b == 0) then
            self.b = 123456789
            self.c = 123456789
            self.d = 123456789
        end
    else 
        -- // Non-deterministic initialization.
        -- // First we will get a random number from the built-in mt19937
        -- // (Mersenne twister) generator and use that to derive the
        -- // starting coefficients for the Marsaglia and Jenkins RNGs.
        -- // We'll seed mt19937 with time(), but that has a coarse
        -- // resolution and multiple threads might be initializing their
        -- // instances at nearly the same time, so we'll add the thread
        -- // number to uniquely seed mt19937 per-thread.
        local generator = math.random

        -- // Initialize Marsaglia, but don't let any of the values be zero:
        self.rngx = generator()
        self.rngy = generator()
        self.rngz = generator()
        self.rngc = generator()

        -- // Initialize Jenkins, but don't let any of the values be zero:
        self.a = 0xf1ea5eed
        self.b = generator()
        self.c = generator()
        self.d = generator()
    end
end 

-- // This returns a random 32-bit integer. Neither the Marsaglia nor the Jenkins
-- // algorithms are of cryptographic quality, but we don't need that. We just need
-- // randomness of shotgun quality. The Jenkins algorithm is the fastest.
-- // The Marsaglia algorithm is from http://www0.cs.ucl.ac.uk/staff/d.jones/GoodPracticeRNG.pdf
-- // where it is attributed to G. Marsaglia.
-- //
RandomUintGenerator.Get == function(self) 
    if (false) then
        -- // Marsaglia algorithm
        local t, a = 698769069, 698769069
        self.rngx = 69069 * self.rngx + 12345
        self.rngy = bit.xor(self.rngy, bit.lshift(rngy, 13))
        self.rngy = bit.xor(self.rngy, bit.rshift(rngy, 17))
        self.rngy = bit.xor(self.rngy, bit.lshift(rngy, 5)) -- /* y must never be set to zero! */
        t = a * self.rngz + self.rngc;
        self.rngc = bit.rshift(t, 32)/* Also avoid setting z=c=0! */
        return self.rngx + self.rngy + (self.rngz = t)
    else
        -- // Jenkins algorithm
        function rot32(x,k) return bit.bor(bit.lshift(x, k), bit.rshift(x, 32-k)) end
        local e = self.a - rot32(self.b, 27)
        self.a = bit.bxor(self.b, rot32(self.c, 17))
        self.b = self.c + self.d;
        self.c = self.d + self.e;
        self.d = self.e + self.a;
        return d
    end
end 

-- // Returns an unsigned integer between min and max, inclusive.
-- // Sure, there's a bias when using modulus operator where (max - min) is not
-- // a power of two, but we don't care if we generate one value a little more
-- // often than another. Our randomness does not have to be high quality.
-- // We do care about speed, because this will get called inside deeply nested
-- // inner loops. Alternatively, we could create a standard C++ "distribution"
-- // object here, but we would first need to investigate its overhead.
-- //
RandomUintGenerator.GetMinMax = function(self, min, max)
    assert(max >= min)
    return self:Get() % (max - min + 1)) + min
end


-- // The globally-scoped random number generator. Declaring it
-- // threadprivate causes each thread to instantiate a private instance.


RANDOM_UINT_MAX = 0xffffffff

return RandomUintGenerator