#ifndef BASICTYPES_H_INCLUDED
#define BASICTYPES_H_INCLUDED

#include <vector>
#include <string>

/*
Basic types used throughout the project:

Compass - an enum with enumerants SW, S, SE, W, CENTER, E, NW, N, NE

    Compass arithmetic values:

        6  7  8
        3  4  5
        0  1  2

Dir, Coord, Polar, and their constructors:

    Dir - abstract type for 8 directions plus center
    ctor Dir(Compass = CENTER)

    Coord - signed int16_t pair, absolute location or difference of locations
    ctor Coord() = 0,0

    Polar - signed magnitude and direction
    ctor Polar(Coord = 0,0)

Conversions

    uint8_t = Dir.asInt()

    Dir = Coord.asDir()
    Dir = Polar.asDir()

    Coord = Dir.asNormalizedCoord()
    Coord = Polar.asCoord()

    Polar = Dir.asNormalizedPolar()
    Polar = Coord.asPolar()

Arithmetic

    Dir.rotate(int n = 0)

    Coord = Coord + Dir
    Coord = Coord + Coord
    Coord = Coord + Polar

    Polar = Polar + Coord (additive)
    Polar = Polar + Polar (additive)
    Polar = Polar * Polar (dot product)
*/

#include <cstdint>
#include <cmath>
#include <algorithm>
#include "random.h"

namespace BS {

extern bool unitTestBasicTypes();

enum { 
    Compass_SW = 0, 
    Compass_S, 
    Compass_SE, 
    Compass_W, 
    Compass_CENTER, 
    Compass_E, 
    Compass_NW, 
    Compass_N, 
    Compass_NE 
};

struct Dir;
struct Coord;
struct Polar;

// Supports the eight directions in enum class Compass plus CENTER.
struct __attribute__((packed)) Dir {
    static Dir random8() { return Dir(Compass_N).rotate(randomUint(0, 7)); }

    Dir(uint8_t dir = Compass_CENTER) : dir9{dir} {}
    Dir& operator=(const uint8_t& d) { dir9 = d; return *this; }
    uint8_t asInt() const { return (uint8_t)dir9; }
    Coord asNormalizedCoord() const;  // (-1, -0, 1, -1, 0, 1)
    Polar asNormalizedPolar() const;

    Dir rotate(int n = 0) const;
    Dir rotate90DegCW() const { return rotate(2); }
    Dir rotate90DegCCW() const { return rotate(-2); }
    Dir rotate180Deg() const { return rotate(4); }

    bool operator==(uint8_t d) const { return asInt() == (uint8_t)d; }
    bool operator!=(uint8_t d) const { return asInt() != (uint8_t)d; }
    bool operator==(Dir d) const { return asInt() == d.asInt(); }
    bool operator!=(Dir d) const { return asInt() != d.asInt(); }
private:
    uint8_t dir9;
};


// Coordinates range anywhere in the range of int16_t. Coordinate arithmetic
// wraps like int16_t. Can be used, e.g., for a location in the simulator grid, or
// for the difference between two locations.
struct __attribute__((packed)) Coord {
    Coord(int16_t x0 = 0, int16_t y0 = 0) : x{x0}, y{y0} { }
    bool isNormalized() const { return x >= -1 && x <= 1 && y >= -1 && y <= 1; }
    Coord normalize() const;
    unsigned length() const { return (int)(std::sqrt(x * x + y * y)); } // round down
    Dir asDir() const;
    Polar asPolar() const;

    bool operator==(Coord c) const { return x == c.x && y == c.y; }
    bool operator!=(Coord c) const { return x != c.x || y != c.y; }
    Coord operator+(Coord c) const { return Coord{(int16_t)(x + c.x), (int16_t)(y + c.y)}; }
    Coord operator-(Coord c) const { return Coord{(int16_t)(x - c.x), (int16_t)(y - c.y)}; }
    Coord operator*(int a) const { return Coord{(int16_t)(x * a), (int16_t)(y * a)}; }
    Coord operator+(Dir d) const { return *this + d.asNormalizedCoord(); }
    Coord operator-(Dir d) const { return *this - d.asNormalizedCoord(); }

    float raySameness(Coord other) const; // returns -1.0 (opposite) .. 1.0 (same)
    float raySameness(Dir d) const; // returns -1.0 (opposite) .. 1.0 (same)
public:
    int16_t x;
    int16_t y;
};


// Polar magnitudes are signed 32-bit integers so that they can extend across any 2D
// area defined by the Coord class.
struct __attribute__((packed)) Polar {
    explicit Polar(int mag0 = 0, uint8_t dir0 = Compass_CENTER)
         : mag{mag0}, dir{Dir{dir0}} { }
    explicit Polar(int mag0, Dir dir0)
         : mag{mag0}, dir{dir0} { }
    Coord asCoord() const;
public:
    int mag;
    Dir dir;
};


typedef std::vector<std::string>    lineType;

} // end namespace BS

#endif // BASICTYPES_H_INCLUDED
