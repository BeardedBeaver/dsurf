module dsurf.cartesian;

import std.range;
import std.string;
import std.algorithm;
import std.conv;
import std.math;

/***********************************
* Class CartesianSurface represents regular rectangular-cell surface
* Authors: Dmitriy Linev
* License: MIT
* Date: 2019-2020
*/
class CartesianSurface  {

    /**
    * Default constructor, doesn`t allocate memory for height map
    */
    this() pure {
        m_xOrigin = 0;
        m_yOrigin = 0;
        m_dx = 0;
        m_dy = 0;
        m_nx = 0;
        m_ny = 0;
    }

    /** 
     * Sets surface header and allocates surface memory
     * Params:
     *   nx = number of nodes along X coordinate
     *   ny = number of nodes along Y coordinate
     *   xOrigin = surface origin X coordinate
     *   yOrigin = surface origin Y coordinate
     *   dx = surface increment (cell size) along X coordinate
     *   dy = surface increment (cell size) along Y coordinate
     */
    void setHeader(int nx, int ny, double xOrigin, double yOrigin, double dx, double dy) pure  {
        m_nx = nx;
        m_ny = ny;
        m_xOrigin = xOrigin;
        m_yOrigin = yOrigin;
        m_dx = dx;
        m_dy = dy;
        m_zd = new double[](m_nx * m_ny);
        m_z = m_zd.chunks(m_ny).array;
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(2, 2, 0, 0, 500, 500);
        surface.m_zd[] = 50;
        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                assert(surface.z[i][j] == 50);
    }

    /// Copy constructor, returns the exact copy of the given surface
    this(CartesianSurface surface) pure {
        this.setHeader(surface.nx, surface.ny, surface.xOrigin, surface.yOrigin, surface.dx, surface.dy);
        this.m_zd[] = surface.m_zd[];
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(2, 2, 0, 0, 500, 500);
        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                surface.z[i][j] = 50;

        auto s2 = new CartesianSurface(surface);
        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                assert(s2.z[i][j] == 50);

        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                s2.z[i][j] = 10;

        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                assert(s2.z[i][j] == 10);

        foreach(i; 0 .. surface.nx)
            foreach(j; 0 .. surface.ny)
                assert(surface.z[i][j] == 50);
    }

    /// Returns X coordinate of surface origin
    @property pure double xOrigin() const @safe @nogc { return m_xOrigin; }

    /// Returns Y coordinate of surface origin
    @property pure double yOrigin() const @safe @nogc { return m_yOrigin; }

    /// Returns surface increment (cell size) along X axis
    @property pure double dx() const @safe @nogc { return m_dx; }

    /// Returns surface increment (cell size) along Y axis
    @property pure double dy() const @safe @nogc { return m_dy; }

    /// Returns number of nodes along X axis 
    @property pure int nx() const @safe @nogc { return m_nx; }

    /// Returns number of nodes along Y axis 
    @property pure int ny() const @safe @nogc { return m_ny; }

    /// Returns minimum z value
    @property pure double zMin() const @safe @nogc { return m_zd[m_zd.minIndex]; }

    /// Returns maximum z value
    @property pure double zMax() const @safe @nogc { return m_zd[m_zd.maxIndex]; }

    /**
    Method to access height map.
    Returns: `Slice!(double*, 2)` containing surface`s height map with dimensions nx * ny
    Example:
    ---
    foreach (i; 0 .. surface.nx) {
        foreach (j; 0 .. surface.ny) {
            surface.z[i][j] = 0;
        }
    }
    ---
    */ 
    @property double[][] z() { return m_z; } 

    /// Returns `true` if point with given coordinates is inside surface boundaries, otherwise returns `false`
    bool isInsideSurface(double x, double y) const @nogc {
        if (x < m_xOrigin || y < m_yOrigin || x > m_xOrigin + m_dx * (m_nx - 1) || y > m_yOrigin + m_dy * (m_ny - 1))
            return false;
        return true;
    }

    /// Returns cell index from a given `X` coordinate. Maximum number is `nx - 1`
    /// Returns -1 if a given coordinate is outside the surface
    int cellXIndex(double x) const {
        if (x < m_xOrigin || x > m_xOrigin + m_dx * (m_nx - 1))
            return -1;  //TODO throw?  
        return  ((x - m_xOrigin) / m_dx).to!int;
    }

    /// Returns cell index from a given `Y` coordinate. Maximum number is `ny - 1`
    /// Returns `-1` if a given coordinate is outside the surface
    int cellYIndex(double y) const {
        if (y < m_yOrigin || y > m_yOrigin + m_dy * (m_ny - 1))
            return -1;   //TODO throw? 
        return ((y - m_yOrigin) / m_dy).to!int;
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(10, 10, 0, 1000, 500, 500);
        assert(surface.cellXIndex(-1000) == -1);
        assert(surface.cellYIndex(-1000) == -1);
        assert(surface.cellXIndex(0) == 0);
        assert(surface.cellYIndex(1000) == 0);
        assert(surface.cellXIndex(550) == 1);
        assert(surface.cellYIndex(1550) == 1);
        assert(surface.cellXIndex(5000) == -1);
        assert(surface.cellYIndex(6000) == -1);
    }

    /// Returns z value of a point with given coordinate using bilinear interpolation
    double getZ(double x, double y) {
        if (!isInsideSurface(x, y))
            return double.nan;
        immutable int i = cellXIndex(x);
        immutable int j = cellYIndex(y);

        if (i == m_nx - 1 && j == m_ny - 1)  //top right corner
            return m_z[nx - 1][ny - 1];
        else if (i == m_nx - 1) {   //right edge
            return m_z[i][j] + (m_z[i][j + 1] - m_z[i][j]) / m_dy * (y - (m_yOrigin + j * m_dy));
        }
        else if (j == m_ny - 1) {   //top edge
            return m_z[i][j] + (m_z[i + 1][j] - m_z[i][j]) / m_dx * (x - (m_xOrigin + i * m_dx));
        }

        //z: top left, top right, bottom left, bottom right
        double [] zcells = [m_z[i][j + 1], m_z[i + 1][j + 1], m_z[i][j], m_z[i + 1][j]];  

        immutable ulong blanks = zcells.count!isNaN;
        if (blanks > 1) {   // more than one node is blank - value in not defined
            return double.nan;
        }
        else if (blanks == 1) {     // one node is blank - tryng to reconstruct actual value
            if (isNaN(zcells[0])) {
                if (sqrt(pow(x - (m_xOrigin + i * m_dx), 2) + pow(y - (m_yOrigin + (j + 1) * m_dy), 2)) < 
                    sqrt(pow(x - (m_xOrigin + (i + 1) * m_dx), 2) + pow(y - (m_yOrigin + j * m_dy), 2)))    
                    // checking if given point is inside defined triangle
                    // by comparing a distance to the blank corner with a distance to the opposite corner
                    return double.nan;
                // if it is defined, reconstruct the missing corner assuming the fixed gradient along two opposite edges
                zcells[0] = zcells[2] + zcells[1] - zcells[3];  
            }
            else if (isNaN(zcells[1])) {
                if (sqrt(pow(x - (m_xOrigin + (i + 1) * m_dx), 2) + pow(y - (m_yOrigin + (j + 1) * m_dy), 2)) < 
                    sqrt(pow(x - (m_xOrigin + i * m_dx), 2) + pow(y - (m_yOrigin + j * m_dy), 2)))
                    return double.nan;
                zcells[1] = zcells[3] + zcells[0] - zcells[2];
            }
            else if (isNaN(zcells[2])) {
                if (sqrt(pow(x - (m_xOrigin + i * m_dx), 2) + pow(y - (m_yOrigin + j * m_dy), 2)) < 
                    sqrt(pow(x - (m_xOrigin + (i + 1) * m_dx), 2) + pow(y - (m_yOrigin + (j + 1) * m_dy), 2)))
                    return double.nan;
                zcells[2] = zcells[0] + zcells[3] - zcells[1];
            }
            else if (isNaN(zcells[3])) {
                if (sqrt(pow(x - (m_xOrigin + (i + 1) * m_dx), 2) + pow(y - (m_yOrigin + j * m_dy), 2)) < 
                    sqrt(pow(x - (m_xOrigin + i * m_dx), 2) + pow(y - (m_yOrigin + (j + 1) * m_dy), 2)))
                    return double.nan;
                zcells[3] = zcells[1] + zcells[2] - zcells[0];
            }
        }
        // bilinear interpolation
        immutable double z1 = (m_xOrigin + (i + 1) * m_dx - x) / dx * zcells[2] + 
                        (x - (m_xOrigin + i * m_dx)) / dx * zcells[3];
        immutable double z2 = (m_xOrigin + (i + 1) * m_dx - x) / dx * zcells[0] + 
                        (x - (m_xOrigin + i * m_dx)) / dx * zcells[1];
        return (m_yOrigin + (j + 1) * m_dy - y) / m_dy * z1 + 
            (y - (m_yOrigin + j * m_dy)) / m_dy * z2;
    }

    unittest {
        import dsurf.io: loadFromCps3Ascii;
        auto surface = new CartesianSurface;
        surface.loadFromCps3Ascii("./test/test_pet_rect_blank.cps");
        assert(isNaN(surface.getZ(5600, 250)));
        assert(!isNaN(surface.getZ(5600, 800)));
        assert(isNaN(surface.getZ(5700, 600)));
        assert(isNaN(surface.getZ(5600, 250)));
        assert(isNaN(surface.getZ(5850, 250)));
    }

    unittest {
        import dsurf.io: loadFromCps3Ascii;
        auto surface = new CartesianSurface;
        surface.loadFromCps3Ascii("./test/test_pet_sq.cps");
        assert(surface.nx == 3);
        assert(surface.ny == 3);
        surface.z[1][1] = double.nan;
        assert(isNaN(surface.getZ(5320.00, 700.00)));
        assert(isNaN(surface.getZ(5650.00, 715.00)));
        assert(isNaN(surface.getZ(5650.00, 300.00)));
        assert(isNaN(surface.getZ(5315.00, 300.00)));

        assert(approxEqual(surface.getZ(5120.00, 850.00), 2.42));
        assert(approxEqual(surface.getZ(5815.00, 850.00), 6.59));
        assert(approxEqual(surface.getZ(5800.00, 200.00), 5.20));
        assert(approxEqual(surface.getZ(5200.00, 200.00), 1.60));
    }

    /// Operators +=, -=, *=, /= overloading for two surfaces
    CartesianSurface opOpAssign(string op)(CartesianSurface rhs) {
        for (int i = 0; i < m_nx; i++) {
            for (int j = 0; j < m_ny; j++) {
                immutable double x = m_xOrigin + i * dx;
                immutable double y = m_yOrigin + j * dy;
                immutable double rhsz = rhs.getZ(x, y);
                if (isNaN(rhsz))
                    continue;
                static if (op == "+") 
                    m_z[i][j] += rhsz;
                else static if (op == "-")
                    m_z[i][j] -= rhsz;
                else static if (op == "*")
                    m_z[i][j] *= rhsz;
                else static if (op == "/") {
                    if (abs(rhsz) < 1e-9)
                        m_z[i][j] = double.nan;
                    else
                        m_z[i][j] /= rhsz;
                }
                else static assert(0, "Operator " ~ op ~ " not implemented");
            }
        }
        return this;
    }

    unittest {
        auto s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny)
                s1.z[i][j] = 50;

        auto s2 = new CartesianSurface(s1);
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny)
                s2.m_zd [] = 10;

        s1 /= s2;
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny) 
                assert(s1.z[i][j] == 5);

        s1 += s2;
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny)
                assert(s1.z[i][j] == 15);

        s1 *= s2;
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny) 
                assert(s1.z[i][j] == 150);

        s1 -= s2;
        foreach (i; 0 .. s1.nx)
            foreach (j; 0 .. s1.ny)
                assert(s1.z[i][j] == 140);
    }

    /// Operators +, -, *, / overloading for two surfaces
    CartesianSurface opBinary(string op)(CartesianSurface rhs) {
        CartesianSurface result = new CartesianSurface(this);
        static if (op == "+")
            result += rhs;
        else static if (op == "-")
            result -= rhs;
        else static if (op == "*")
            result *= rhs;
        else static if (op == "/")
            result /= rhs;
        else static assert(0, "Operator "~op~" not implemented");
        return result;
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(2, 2, 0, 0, 500, 500);
        surface.m_zd[] = 50;
        auto result = surface + surface;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 100);
            }

        result = surface * surface;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 2500);
            }
        
        result = surface - surface;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 0);
            }
        
        result = surface / surface;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 1);
            }
    }

    /// Operators +=, -=, *=, /= overloading for a surface and a fixed value
    CartesianSurface opOpAssign(string op)(double rhs) {
        static if (op == "+")
            m_zd [] += rhs;
        else static if (op == "-")
            m_zd [] -= rhs;
        else static if (op == "*")
            m_zd [] *= rhs;
        else static if (op == "/")
            m_zd [] /= rhs;
        else static assert(0, "Operator "~op~" not implemented");
        return this;   
    }

    /// Operators +, -, *, / overloading for a surface and a fixed value
    CartesianSurface opBinary(string op)(double rhs) {
        CartesianSurface result = new CartesianSurface(this);
        static if (op == "+")
            result += rhs;
        else static if (op == "-")
            result -= rhs;
        else static if (op == "*")
            result *= rhs;
        else static if (op == "/")
            result /= rhs;
        else static assert(0, "Operator "~op~" not implemented");
        return result;
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(2, 2, 0, 0, 500, 500);
        surface.m_zd[] = 50;
        auto result = surface + 10;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 60);
            }
        
        result = surface - 20;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 30);
            }

        result = surface * 2.5;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 125);
            }

        result = surface / 5;
        foreach (i; 0 .. surface.nx)
            foreach (j; 0 .. surface.ny) {
                assert(surface.z[i][j] == 50);
                assert(result.z[i][j] == 10);
            }
    }
    
private:
    double[] m_zd;           /// dense representation of Z values of the surface
    double[][] m_z;   /// Z chunks
    double m_xOrigin;
    double m_yOrigin;
    double m_dx;
    double m_dy;
    int m_nx;
    int m_ny;
}

/**
* Samples height map to `surface` using height map from the given `source`
*/
void sampleFromSurface(CartesianSurface surface, CartesianSurface source) {
    foreach (i; 0 .. surface.nx) {
        foreach (j; 0 .. surface.ny) {
            surface.z[i][j] = source.getZ(surface.xOrigin + i * surface.dx, surface.yOrigin + j * surface.dy);
        }
    }
}

/** 
 * Translates the given surface (moves its origin point to the given vector) leaving increments untouched
 * Params:
 *   surface = surface to translate
 *   dx = translation value along X direction
 *   dy = translation value along Y direction
 * Returns: translated surface for more convenient call chaining
 */
CartesianSurface translate(CartesianSurface surface, double dx, double dy) {
    surface.m_xOrigin += dx;
    surface.m_yOrigin += dy;
    return surface;
}

/** 
 * Scales the given surface around its origin point
 * Params:
 *   surface = surface to scale
 *   xf = scale factor along X direction
 *   xf = scale factor value along Y direction
 * Returns: translated surface for more convenient call chaining
 */
CartesianSurface scale(CartesianSurface surface, double xf, double yf) {  //scales around origin point
    //TODO filter negative factors
    surface.m_dx *= xf;
    surface.m_dy *= yf;
    return surface;
}

/** 
 * Normalizes the given surface (minimum value will be 0, maximum value will be 1)
 * Doesn`t alter surface limits and origin point
 * Case of equal min and max is not controlled (division by zero will occur)
 * Params:
 *   surface = surface to normalize
 * Returns: Normalized surface for more convenient call chaining
 */
CartesianSurface normalize(CartesianSurface surface) {
    immutable double zmax = surface.m_zd[surface.m_zd.maxIndex];
    immutable double zmin = surface.m_zd[surface.m_zd.minIndex];
    surface.m_zd[] -= zmin;
    surface.m_zd[] /= (zmax - zmin);
    return surface;
}

unittest {
    import dsurf.io: loadFromFile;
    auto surface = new CartesianSurface;
    surface.loadFromFile("./test/test_rms_sq.cps");
    surface.normalize();
    immutable double zmax = surface.m_zd[surface.m_zd.maxIndex];
    immutable double zmin = surface.m_zd[surface.m_zd.minIndex];
    assert(zmax == 1);
    assert(zmin == 0);
}

//TODO flipAnlogI/flipAlongJ

