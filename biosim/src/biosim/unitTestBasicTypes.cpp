// unitTestBasicTypes.cpp
// This tests the types Dir, Coord, and Polar, and enum Compass.
// See basicTypes.h for more info about the basic types.

#include <cassert>
#include <cmath>
#include "basicTypes.h"

namespace BS {

// returns true only if a and b are the same to within
// 4 digits accuracy
bool areClosef(float a, float b)
{
    return std::abs(a - b) < 0.0001;
}


bool unitTestBasicTypes()
{
    // Dir

    // ctor from Compass
    // .asInt()
    // copy assignment
    Dir d1 = Dir(Compass_N);
    Dir d2 = Dir(Compass_CENTER);
    d1 = d2;
    assert(d1.asInt() == (int)Compass_CENTER);
    d1 = Dir(Compass_SW);
    assert(d1.asInt() == 0);
    d1 = Dir(Compass_S);
    assert(d1.asInt() == 1);
    d1 = Dir(Compass_SE);
    assert(d1.asInt() == 2);
    d1 = Dir(Compass_W);
    assert(d1.asInt() == 3);
    d1 = Dir(Compass_CENTER);
    assert(d1.asInt() == 4);
    d1 = Dir(Compass_E);
    assert(d1.asInt() == 5);
    d1 = Dir(Compass_NW);
    assert(d1.asInt() == 6);
    d1 = Dir(Compass_N);
    assert(d1.asInt() == 7);
    d1 = Dir(Compass_NE);
    assert(d1.asInt() == 8);

    assert(Dir(Compass_SW).asInt() == 0);
    assert(Dir(Compass_S).asInt()  == 1);
    assert(Dir(Compass_SE).asInt() == 2);
    assert(Dir(Compass_W).asInt()  == 3);
    assert(Dir(Compass_CENTER).asInt() == 4);
    assert(Dir(Compass_E).asInt()  == 5);
    assert(Dir(Compass_NW).asInt() == 6);
    assert(Dir(Compass_N).asInt()  == 7);
    assert(Dir(Compass_NE).asInt() == 8);
    assert(Dir((uint8_t)8).asInt() == 8);
    assert(Dir((uint8_t)((Dir((uint8_t)8)).asInt())).asInt() == 8);
    assert(Dir((uint8_t)(Dir(Compass_NE).asInt())).asInt() == 8);
    d2 = Compass_E;
    d1 = d2;
    assert(d1.asInt() == 5);
    d2 = d1;
    assert(d1.asInt() == 5);

    // .operator=() from Compass
    d1 = Compass_SW;
    assert(d1.asInt() == 0);
    d1 = Compass_SE;
    assert(d1.asInt() == 2);

    // [in]equality with Compass
    d1 = Compass_CENTER;
    assert(d1 == Compass_CENTER);
    d1 = Compass_SE;
    assert(d1 == Compass_SE);
    assert(Dir(Compass_W) == Compass_W);
    assert(Dir(Compass_W) != Compass_NW);

    // [in]equality with Dir
    d1 = Compass_N;
    d2 = Compass_N;
    assert(d1 == d2);
    assert(d2 == d1);
    d1 = Compass_NE;
    assert(d1 != d2);
    assert(d2 != d1);

    // .rotate()
    assert(d1.rotate(1) == Compass_E);
    assert(d1.rotate(2) == Compass_SE);
    assert(d1.rotate(-1) == Compass_N);
    assert(d1.rotate(-2) == Compass_NW);
    assert(Dir(Compass_N).rotate(1) == d1);
    assert(Dir(Compass_SW).rotate(-2) == Compass_SE);

    // .asNormalizedCoord()
    Coord c1 = Dir(Compass_CENTER).asNormalizedCoord();
    assert(c1.x == 0 && c1.y == 0);
    d1 = Compass_SW;
    c1 = d1.asNormalizedCoord();
    assert(c1.x == -1 && c1.y == -1);
    c1 = Dir(Compass_S).asNormalizedCoord();
    assert(c1.x == 0 && c1.y == -1);
    c1 = Dir(Compass_SE).asNormalizedCoord();
    assert(c1.x == 1 && c1.y == -1);
    c1 = Dir(Compass_W).asNormalizedCoord();
    assert(c1.x == -1 && c1.y == 0);
    c1 = Dir(Compass_E).asNormalizedCoord();
    assert(c1.x == 1 && c1.y == 0);
    c1 = Dir(Compass_NW).asNormalizedCoord();
    assert(c1.x == -1 && c1.y == 1);
    c1 = Dir(Compass_N).asNormalizedCoord();
    assert(c1.x == 0 && c1.y == 1);
    c1 = Dir(Compass_NE).asNormalizedCoord();
    assert(c1.x == 1 && c1.y == 1);

    // .asNormalizedPolar()
    d1 = Compass_SW;
    Polar p1 = d1.asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_SW);
    p1 = Dir(Compass_S).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_S);
    p1 = Dir(Compass_SE).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_SE);
    p1 = Dir(Compass_W).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_W);
    p1 = Dir(Compass_E).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_E);
    p1 = Dir(Compass_NW).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_NW);
    p1 = Dir(Compass_N).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_N);
    p1 = Dir(Compass_NE).asNormalizedPolar();
    assert(p1.mag == 1 && p1.dir == Compass_NE);

    // Coord
    // ctor from int16_t,int16_t
    c1 = Coord();
    assert(c1.x == 0 && c1.y == 0);
    c1 = Coord(1, 1);
    assert(c1.x == 1 && c1.y == 1);
    c1 = Coord(-6, 12);
    assert(c1.x == -6 && c1.y == 12);

    // copy assignment
    Coord c2 = Coord(9, 101);
    assert(c2.x == 9 && c2.y == 101);
    c1 = c2;
    assert(c1.x == 9 && c2.y == 101);

    // .isNormalized()
    assert(!c1.isNormalized());
    assert(Coord(0, 0).isNormalized());
    assert(Coord(0, 1).isNormalized());
    assert(Coord(1, 1).isNormalized());
    assert(Coord(-1, 0).isNormalized());
    assert(Coord(-1, -1).isNormalized());
    assert(!Coord(0, 2).isNormalized());
    assert(!Coord(1, 2).isNormalized());
    assert(!Coord(-1, 2).isNormalized());
    assert(!Coord(-2, 0).isNormalized());

    // .normalize()
    // .asDir()
    c1 = Coord(0, 0);
    c2 = c1.normalize();
    assert(c2.x == 0 && c2.y == 0);
    assert(c2.asDir() == Compass_CENTER);
    c1 = Coord(0, 1).normalize();
    assert(c1.x == 0 && c1.y == 1);
    assert(c1.asDir() == Compass_N);
    c1 = Coord(-1, 1).normalize();
    assert(c1.x == -1 && c1.y == 1);
    assert(c1.asDir() == Compass_NW);
    c1 = Coord(100, 5).normalize();
    assert(c1.x == 1 && c1.y == 0);
    assert(c1.asDir() == Compass_E);
    c1 = Coord(100, 105).normalize();
    assert(c1.x == 1 && c1.y == 1);
    assert(c1.asDir() == Compass_NE);
    c1 = Coord(-5, 101).normalize();
    assert(c1.x == 0 && c1.y == 1);
    assert(c1.asDir() == Compass_N);
    c1 = Coord(-500, 10).normalize();
    assert(c1.x == -1 && c1.y == 0);
    assert(c1.asDir() == Compass_W);
    c1 = Coord(-500, -490).normalize();
    assert(c1.x == -1 && c1.y == -1);
    assert(c1.asDir() == Compass_SW);
    c1 = Coord(-1, -490).normalize();
    assert(c1.x == 0 && c1.y == -1);
    assert(c1.asDir() == Compass_S);
    c1 = Coord(1101, -1090).normalize();
    assert(c1.x == 1 && c1.y == -1);
    assert(c1.asDir() == Compass_SE);
    c1 = Coord(1101, -3).normalize();
    assert(c1.x == 1 && c1.y == 0);
    assert(c1.asDir() == Compass_E);

    // .length()
    assert(Coord(0, 0).length() == 0);
    assert(Coord(0, 1).length() == 1);
    assert(Coord(-1, 0).length() == 1);
    assert(Coord(-1, -1).length() == 1); // round down
    assert(Coord(22, 0).length() == 22);
    assert(Coord(22, 22).length() == 31); // round down
    assert(Coord(10, -10).length() == 14); // round down
    assert(Coord(-310, 0).length() == 310);

    // .asPolar()
    p1 = Coord(0, 0).asPolar();
    assert(p1.mag == 0 && p1.dir == Compass_CENTER);
    p1 = Coord(0, 1).asPolar();
    assert(p1.mag == 1 && p1.dir == Compass_N);
    p1 = Coord(-10, -10).asPolar();
    assert(p1.mag == 14 && p1.dir == Compass_SW); // round down mag
    p1 = Coord(100, 1).asPolar();
    assert(p1.mag == 100 && p1.dir == Compass_E); // round down mag

    // operator+(Coord), operator-(Coord)
    c1 = Coord(0, 0) + Coord(6, 8);
    assert(c1.x == 6 && c1.y == 8);
    c1 = Coord(-70, 20) + Coord(10, -10);
    assert(c1.x == -60 && c1.y == 10);
    c1 = Coord(-70, 20) - Coord(10, -10);
    assert(c1.x == -80 && c1.y == 30);

    // operator*(int)
    c1 = Coord(0, 0) * 1;
    assert(c1.x == 0 && c1.y == 0);
    c1 = Coord(1, 1) * -5;
    assert(c1.x == -5 && c1.y == -5);
    c1 = Coord(11, 5) * -5;
    assert(c1.x == -55 && c1.y == -25);

    // operator+(Dir), operator-(Dir)
    c1 = Coord(0, 0);
    c2 = c1 + Dir(Compass_CENTER);
    assert(c2.x == 0 && c2.y == 0);
    c2 = c1 + Dir(Compass_E);
    assert(c2.x == 1 && c2.y == 0);
    c2 = c1 + Dir(Compass_W);
    assert(c2.x == -1 && c2.y == 0);
    c2 = c1 + Dir(Compass_SW);
    assert(c2.x == -1 && c2.y == -1);

    c2 = c1 - Dir(Compass_CENTER);
    assert(c2.x == 0 && c2.y == 0);
    c2 = c1 - Dir(Compass_E);
    assert(c2.x == -1 && c2.y == 0);
    c2 = c1 - Dir(Compass_W);
    assert(c2.x == 1 && c2.y == 0);
    c2 = c1 - Dir(Compass_SW);
    assert(c2.x == 1 && c2.y == 1);

    // raySameness()
    c1 = Coord { 0, 0 };
    c2 = Coord { 10, 11 };
    d1 = Compass_CENTER;
    assert(c1.raySameness(c2) == 1.0); // special case - zero vector
    assert(c2.raySameness(c1) == 1.0); // special case - zero vector
    assert(c2.raySameness(d1) == 1.0); // special case - zero vector
    c1 = c2;
    assert(c1.raySameness(c2) == 1.0);
    assert(areClosef(Coord(-10,-10).raySameness(Coord(10,10)), -1.0));
    c1 = Coord{0,11};
    c2 = Coord{20,0};
    assert(areClosef(c1.raySameness(c2), 0.0));
    assert(areClosef(c2.raySameness(c1), 0.0));
    c1 = Coord{0,444};
    c2 = Coord{113,113};
    assert(areClosef(c1.raySameness(c2), 0.707106781));
    c2 = Coord{113,-113};
    assert(areClosef(c1.raySameness(c2), -0.707106781));

    // Polar
    // ctor from mag, dir
    p1 = Polar();
    assert(p1.mag == 0 && p1.dir == Compass_CENTER);
    p1 = Polar(0, Compass_S);
    assert(p1.mag == 0 && p1.dir == Compass_S);
    p1 = Polar(10, Compass_SE);
    assert(p1.mag == 10 && p1.dir == Compass_SE);
    p1 = Polar(-10, Compass_NW);
    assert(p1.mag == -10 && p1.dir == Compass_NW);

    // .asCoord()
    c1 = Polar(0, Compass_CENTER).asCoord();
    assert(c1.x == 0 && c1.y == 0);
    c1 = Polar(10, Compass_CENTER).asCoord();
    assert(c1.x == 0 && c1.y == 0);
    c1 = Polar(20, Compass_N).asCoord();
    assert(c1.x == 0 && c1.y == 20);
    //c1 = Polar(12, Compass_W).asCoord();
    p1 = Polar(12, Compass_W);
    c1 = p1.asCoord();
    assert(c1.x == -12 && c1.y == 0);
    c1 = Polar(14, Compass_NE).asCoord();
    assert(c1.x == 10 && c1.y == 10);
    c1 = Polar(-14, Compass_NE).asCoord();
    assert(c1.x == -10 && c1.y == -10);
    c1 = Polar(14, Compass_E).asCoord();
    assert(c1.x == 14 && c1.y == 0);
    c1 = Polar(-14, Compass_E).asCoord();
    assert(c1.x == -14 && c1.y == 0);

    return true;
}

} // end namespace BS
