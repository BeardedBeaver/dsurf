module dsurf.cartesian;

import std.range;
import std.stdio; 
import std.string;
import std.algorithm;
import std.file;
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
    * Default constructor, doesn't allocate memory for height map
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
        m_z = m_zd.chunks(m_ny);
    }

    unittest {
        auto s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        s1.m_zd[] = 50;
        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                assert(s1.z[i][j] == 50);
    }

    /// Copy constructor, returns the exact copy of the given surface
    this(CartesianSurface surface) pure {
        this.setHeader(surface.nx, surface.ny, surface.xOrigin, surface.yOrigin, surface.dx, surface.dy);
        this.m_zd[] = surface.m_zd[];
    }

    unittest {
        auto s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                s1.z[i][j] = 50;

        auto s2 = new CartesianSurface(s1);
        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                assert(s2.z[i][j] == 50);

        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                s2.z[i][j] = 10;

        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                assert(s2.z[i][j] == 10);

        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                assert(s1.z[i][j] == 50);
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


    /**
    Method to access height map.
    Returns: `Slice!(double*, 2)` containing surface's height map with dimensions nx * ny
    Example:
    ---
    for (int i = 0; i < surface.nx; i++) {
        for (int j = 0; j < surface.ny; j++) {
            surface.z[i][j] = 0;
        }
    }
    ---
    */ 
    @property Chunks!(double[]) z() { return m_z; } 

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
        auto surface = new CartesianSurface;
        surface.loadFromCps3Ascii("./test/test_pet_rect_blank.cps");
        assert(isNaN(surface.getZ(5600, 250)));
        assert(!isNaN(surface.getZ(5600, 800)));
        assert(isNaN(surface.getZ(5700, 600)));
        assert(isNaN(surface.getZ(5600, 250)));
        assert(isNaN(surface.getZ(5850, 250)));
    }

    unittest {
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
                else static assert(0, "Operator "~op~" not implemented");
            }
        }
        return this;
    }

    unittest {
        auto s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                s1.z[i][j] = 50;

        auto s2 = new CartesianSurface(s1);
        for (int i = 0; i < s1.nx; i++)
            for (int j = 0; j < s1.ny; j++)
                s2.m_zd [] = 10;

        s1 /= s2;
        for (int i = 0; i < s1.nx; i++) 
            for (int j = 0; j < s1.ny; j++) 
                assert(s1.z[i][j] == 5);

        s1 += s2;
        for (int i = 0; i < s1.nx; i++) 
            for (int j = 0; j < s1.ny; j++) 
                assert(s1.z[i][j] == 15);

        s1 *= s2;
        for (int i = 0; i < s1.nx; i++) 
            for (int j = 0; j < s1.ny; j++) 
                assert(s1.z[i][j] == 150);

        s1 -= s2;
        for (int i = 0; i < s1.nx; i++) 
            for (int j = 0; j < s1.ny; j++) 
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
            result *= result;
        else static if (op == "/")
            result /= rhs;
        else static assert(0, "Operator "~op~" not implemented");
        return result;
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
            result *= result;
        else static if (op == "/")
            result /= rhs;
        else static assert(0, "Operator "~op~" not implemented");
        return result;
    }

    unittest {
        auto surface = new CartesianSurface;
        surface.setHeader(2, 2, 0, 0, 500, 500);
        surface.m_zd[] = 50;
        surface += 10;
        for (int i = 0; i < surface.nx; i++)
            for (int j = 0; j < surface.ny; j++)
                assert(surface.z[i][j] == 60);
        
        surface -= 20;
        for (int i = 0; i < surface.nx; i++)
            for (int j = 0; j < surface.ny; j++)
                assert(surface.z[i][j] == 40);

        surface *= 2.5;
        for (int i = 0; i < surface.nx; i++)
            for (int j = 0; j < surface.ny; j++)
                assert(surface.z[i][j] == 100);

        surface /= 10;
        for (int i = 0; i < surface.nx; i++)
            for (int j = 0; j < surface.ny; j++)
                assert(surface.z[i][j] == 10);
    }
    
private:
    double[] m_zd;           /// dense representation of Z values of the surface
    Chunks!(double[]) m_z;   /// Z chunks
    double m_xOrigin;
    double m_yOrigin;
    double m_dx;
    double m_dy;
    int m_nx;
    int m_ny;
}

/** 
 * Loads `surface` from file trying to detect format automatically
 * Params:
 *   surface = `CartesianSurface` to load data to
 *   fileName = Path to file for loading
 * Currently supported formats are CPS3 ASCII and ZMAP+
 */
void loadFromFile(CartesianSurface surface, string fileName) {
    immutable auto format = surfaceFormat(fileName);
    if (format == "cps")
        loadFromCps3Ascii(surface, fileName);
    else if (format == "zmap")
        loadFromZmap(surface, fileName);
    else
        throw new FileException("Unknown surface format");
}

/** 
 * Loads `surface` from file of CPS3 ASCII format
 * Params:
 *   surface = `CartesianSurface` to load data to
 *   fileName = Path to file for loading
 */
void loadFromCps3Ascii(CartesianSurface surface, string fileName) {
    File file = File(fileName, "r");
    bool readingHeader = true;
    int i = -1;
    int j = -1;
    double xOrigin = -1, yOrigin = -1;
    double dx = -1, dy = -1;
    int nx = -1, ny = -1;
    double blank = 1e31;
    while(!file.eof()) {
        string line = file.readln().chomp().replace("\"", "");
        if (!line)
            continue;
        if (readingHeader) {
            auto words = line.split();
            if (words[0] == "FSASCI") {
                blank = words[$ - 1].to!double;
            }
            if (words[0] == "FSLIMI") {
                xOrigin = words[1].to!double;
                yOrigin = words[3].to!double;
            }
            else if (words[0] == "FSNROW") {
                nx = words[2].to!int;
                ny = words[1].to!int;
            }
            else if (words[0] == "FSXINC") {
                dx = words[1].to!double;
                dy = words[2].to!double;
                readingHeader = false;
                surface.setHeader(nx, ny, xOrigin, yOrigin, dx, dy);
                i = 0;
                j = ny - 1;
            }
        }
        else {
            if (i < 0 || j < 0)
                throw new Exception("Invalid index");  //TODO add some information
            auto words = line.split();
            if (words[0].startsWith("->"))  //petrel specific
                continue;
            foreach (word; words) {
                double value = 0;
                try
                    value = to!double(word);
                catch (ConvException e)
                    value = double.nan;
                if (value == blank)
                    surface.z[i][j] = double.nan;
                else
                    surface.z[i][j] = value;
                
                j--;
                if (j < 0) {
                    i++;
                    j = surface.ny() - 1;
                }
            }
        }
    }
    file.close();
}

unittest {
    auto surface = new CartesianSurface;
    surface.loadFromCps3Ascii("./test/test_pet_rect.cps");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);

    surface.loadFromCps3Ascii("./test/test_pet_sq.cps");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);
    //TODO test blank values

    surface.loadFromCps3Ascii("./test/test_rms_sq.cps");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);

    surface.loadFromCps3Ascii("./test/test_rms_rect.cps");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}


/** 
 * Loads `surface` from file of ZMap+ ASCII format
 * Params:
 *   surface = `CartesianSurface` to load data to
 *   fileName = Path to file for loading
 */
void loadFromZmap(CartesianSurface surface, string fileName) {
    File file = File(fileName, "r");
    bool readingHeader = true;
    int i = -1;
    int j = -1;
    double xOrigin = double.nan, yOrigin = double.nan;
    double xMax = double.nan, yMax = double.nan;
    double dx = double.nan, dy = double.nan;
    int nx = -1, ny = -1;
    double blank = double.nan;
    while(!file.eof()) {
        string line = file.readln().chomp().replace("\"", "");
        if (readingHeader) {
        if (line.startsWith("!"))
            continue;
            string [] words = line.replace(",", "").split();
            if (isNaN(blank)) {
                if (line.startsWith("@"))
                    continue;
                blank = words[1].to!double;
            }
            else if (nx < 0) {
                nx = words[1].to!int;
                ny = words[0].to!int;
                xOrigin = words[2].to!double;
                yOrigin = words[4].to!double;
                xMax = words[3].to!double;
                yMax = words[5].to!double;
            }
            else if (isNaN(dx)) {
                dx = words[0].to!double;
                dy = words[1].to!double;
                if (approxEqual(0.0, dx, 0.0) || approxEqual(0.0, dy, 0.0)) {
                    dx = (xMax - xOrigin) / (nx - 1);
                    dy = (yMax - yOrigin) / (ny - 1);
                }
            }
            else if (line.startsWith("@")) {
                surface.setHeader(nx, ny, xOrigin, yOrigin, dx, dy);
                readingHeader = false;
                i = 0;
                j = ny - 1;
            }
        }
        else {
            if (i < 0 || j < 0)
                throw new Exception("Invalid index");  //TODO add some information
            auto words = line.split();
            if (words.empty)
                continue;
            if (words[0].startsWith("+"))  //RMS specific
                continue;
            foreach (word; words) {
                double value = 0;
                try
                    value = to!double(word);
                catch (ConvException e)
                    value = double.nan;
                if (value == blank)
                    surface.z[i][j] = double.nan;
                else
                    surface.z[i][j] = value;
                
                j--;
                if (j < 0) {
                    i++;
                    j = surface.ny() - 1;
                }
            }
        }
    }
}

unittest {
    auto surface = new CartesianSurface;
    surface.loadFromZmap("./test/test_pet_rect.zmap");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);

    //TODO test_pet_rect_blank.zmap
    surface.loadFromZmap("./test/test_pet_sq.zmap");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);

    surface.loadFromZmap("./test/test_rms_sq.zmap");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);

    surface.loadFromZmap("./test/test_rms_rect.zmap");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}

/** 
 * Loads `surface` from file of IRAP Classic ASCII format (aka ROXAR text)
 * Params:
 *   surface = `CartesianSurface` to load data to
 *   fileName = Path to file for loading
 */
void loadFromIrapClassicAscii(CartesianSurface surface, string fileName) {
    File file = File(fileName, "r");
    bool readingHeader = true;
    int i = -1;
    int j = -1;
    double xOrigin = double.nan, yOrigin = double.nan;
    double xMax = double.nan, yMax = double.nan;
    double dx = double.nan, dy = double.nan;
    int nx = -1, ny = -1;
    immutable double blank = 9_999_900;
    while(!file.eof()) {
        string line = file.readln().chomp().replace("\"", "");
        auto words = line.split();
        if (readingHeader) {
            if (isNaN(dx)) {
                if (words.length < 4)
                    throw new Exception("Invalid header, line 1: " ~ line);
                ny = words[1].to!int;
                dx = words[2].to!double;
                dy = words[3].to!double;
            }
            else if (isNaN(xOrigin)) {
                if (words.length < 4)
                    throw new Exception("Invalid header, line 2: " ~ line);
                xOrigin = words[0].to!double;
                xMax = words[1].to!double;
                yOrigin = words[2].to!double;
                yMax = words[3].to!double;
            }
            else if (nx < 0) {
                nx = words[0].to!int;
            }
            else {
                surface.setHeader(nx, ny, xOrigin, yOrigin, dx, dy);
                readingHeader = false;
                i = 0;
                j = 0;
            }
        }
        else {
            if (i < 0 || j < 0)
                throw new Exception("Invalid index");  //TODO add some information
            if (words.empty)
                continue;
            if (words[0].startsWith("+"))  //RMS specific
                continue;
            foreach (word; words) {
                double value = 0;
                try
                    value = to!double(word);
                catch (ConvException e)
                    value = double.nan;
                if (value == blank)
                    surface.z[i][j] = double.nan;
                else
                    surface.z[i][j] = value;
                
                i++;
                if (i >= surface.nx) {
                    j++;
                    i = 0;
                }
            }
        }
    }
}

unittest {
    auto surface = new CartesianSurface;
    surface.loadFromIrapClassicAscii("./test/test_pet_rect_blank.irap");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[1][0] == 4);
    assert(surface.z[0][1] == 2);
    assert(surface.z[1][1] == 5);
    assert(isNaN(surface.z[$ - 1][$ - 1]));
    assert(isNaN(surface.z[$ - 1][0]));

    //TODO test_pet_rect_blank.zmap
    surface.loadFromIrapClassicAscii("./test/test_pet_sq.irap");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);

    surface.loadFromIrapClassicAscii("./test/test_rms_sq.roxt");
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);

    surface.loadFromIrapClassicAscii("./test/test_rms_rect.roxt");
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}

/** 
 * Saves `surface` to file using specified `format`
 * Params:
 *   surface = surface to save
 *   fileName = path to output file
 *   format = format to save surface to. Currently supported formats for export are: CPS3 ASCII
 */
void saveToFile(CartesianSurface surface, string fileName, string format) {
        saveToCps3Ascii(surface, fileName);
    if (format.startsWith("cps".toLower)) 
        saveToCps3Ascii(surface, fileName);
    else if (format.startsWith("zmap".toLower))
        saveToZMap(surface, fileName);
    else if (format.startsWith("irap".toLower))
        saveToIrapClassicAscii(surface, fileName);
    else 
        throw new FileException(format ~ " cartesian surface format is not supported for export");
}

/** 
 * Saves `surface` to file using CPS3 ASCII format
 * Params:
 *   surface = surface to save
 *   fileName = path to output file
 */
void saveToCps3Ascii(CartesianSurface surface, string fileName) {
    File file = File(fileName, "w");
    immutable double blank = 1e30;
    file.writeln("FSASCI 0 1 COMPUTED 0 ", blank);
    file.writeln("FSATTR 0 0");
    file.writeln("FSLIMI ", 
                surface.m_xOrigin, " ", 
                surface.m_xOrigin + (surface.m_nx) * surface.m_dx, " ", 
                surface.m_yOrigin, " ", 
                surface.m_yOrigin + (surface.m_ny) * surface.m_dy, " ", 
                surface.m_zd[surface.m_zd.minIndex], " ", 
                surface.m_zd[surface.m_zd.maxIndex]);
    file.writeln("FSNROW ", surface.m_ny, " ", surface.m_nx);
    file.writeln("FSXINC ", surface.m_dx, " ", surface.m_dy);
    int n = 0;
    for (int i = 0; i < surface.nx; i++) {
        for (int j = surface.ny - 1; j >= 0; j--) {
            if (isNaN(surface.z[i][j]))
                file.write(blank);
            else
                file.write(surface.z[i][j]);
            n++;
            if (n > 5) {
                n = 0;
                file.write("\n");
            }
            else {
                file.write(" ");
            }
        }
    }
}

void saveToZMap(CartesianSurface surface, string fileName) {
    File file = File(fileName, "w");
    immutable double blank = 1e30;
    import std.path: baseName;
    file.writeln("!     dsurf - library for surface handling");
    file.writeln("!     for D programming language");
    file.writeln("!     GRID FILE NAME   : n");
    file.writeln("!     CREATION DATE    : ");
    file.writeln("!     CREATION TIME    : ");
    file.writeln("!");
    file.writeln("@" ~ baseName(fileName) ~ " HEADER, GRID, 5");  
    // according to https://github.com/OSGeo/gdal/blob/master/gdal/frmts/zmap/zmapdataset.cpp
    // 5 is a number of values per line but both Petrel and RMS saves 5 but ignores it in actual data
    // so do we

    file.write("     " ~ (surface.nx * surface.ny).to!string ~ ", " ~ blank.to!string ~ ", " ~ "," ~ "6, 1\n"); //6 decimals and default 1 (no idea whai it means)
    file.write(surface.ny.to!string ~ ", " ~ surface.nx.to!string ~ ", ");
    file.write("     " ~ surface.xOrigin.to!string ~ ", ");
    file.write((surface.xOrigin + (surface.nx - 1) * surface.dx).to!string ~ ", ");
    file.write(surface.yOrigin.to!string ~ ", ");
    file.write((surface.yOrigin + (surface.ny - 1) * surface.dy).to!string ~ "\n");
    file.writeln("     " ~ "0.00, 0.00, 0.00"); //transform apparently
    file.writeln("@");    //start of an actual data
    int n = 0;
    for (int i = 0; i < surface.nx; i++) {
        for (int j = surface.ny - 1; j >= 0; j--) {
            if (isNaN(surface.z[i][j]))
                file.write(blank);
            else
                file.write(surface.z[i][j]);
            n++;
            if (n > 5) {
                n = 0;
                file.write("\n");
            }
            else {
                file.write(" ");
            }
        }
    }
}

unittest {
    auto surface1 = new CartesianSurface;
    surface1.loadFromZmap("./test/test_rms_sq.zmap");
    surface1.saveToZMap("./test/_tmp_test_export.zmap");
    assert(surfaceFormat("./test/_tmp_test_export.zmap") == "zmap");
    auto surface2 = new CartesianSurface;
    surface2.loadFromZmap("./test/_tmp_test_export.zmap");
    import std.file: remove;
    remove("./test/_tmp_test_export.zmap");

    assert(surface1.nx == surface2.nx);
    assert(surface1.ny == surface2.ny);
    assert(surface1.dx == surface2.dx);
    assert(surface1.dy == surface2.dy);

    assert(surface1.xOrigin == surface2.xOrigin);
    assert(surface1.yOrigin == surface2.yOrigin);
    
    for (int i = 0; i < surface1.nx; i++) {
        for (int j = 0; j < surface1.ny; j++) {
            assert(surface1.z[i][j] == surface2.z[i][j]);
        }
    }

}

void saveToIrapClassicAscii(CartesianSurface surface, string fileName) {

}

/** 
 * Tries to detect surface format
 * Params:
 *   fileName = 
 * Returns: string containing surface format. `cps` for CPS3 ASCII; 'zmap' for ZMAP+ ASCII; 'irap' for IRAP Classic ASCII (aka ROXAR text); 'unknown' if format hasn't been detected.
 */
string surfaceFormat(string fileName) {
    File file = File(fileName, "r");
    string format = "unknown";
    string str = file.readln();
    string [] words = str.split();
    if (str.startsWith("FSASCI")) {
        format = "cps";
    }
    else if (str.startsWith("!")) {      //probably zmap
        while(str.startsWith("!")) {
            str = file.readln();
        }
        if (str.startsWith("@")) {
            words = str.replace(",", "").split();
            if (words.length >= 4 && icmp(words[2], "grid") == 0)
                format = "zmap";
        }
    }
    else if (words.length == 4 && words[0].to!int == -996) {
        format = "irap";
    }
    file.close();
    return format;
}

unittest {
    assert(surfaceFormat("./test/test_pet_rect.cps") == "cps");
    assert(surfaceFormat("./test/test_pet_rect_blank.cps") == "cps");
    assert(surfaceFormat("./test/test_pet_sq.cps") == "cps");
    assert(surfaceFormat("./test/test_rms_rect.cps") == "cps");
    assert(surfaceFormat("./test/test_rms_rect_blank.cps") == "cps");
    assert(surfaceFormat("./test/test_rms_sq.cps") == "cps");

    assert(surfaceFormat("./test/test_pet_rect.zmap") == "zmap");
    assert(surfaceFormat("./test/test_pet_rect_blank.zmap") == "zmap");
    assert(surfaceFormat("./test/test_pet_sq.zmap") == "zmap");
    assert(surfaceFormat("./test/test_rms_rect.zmap") == "zmap");
    assert(surfaceFormat("./test/test_rms_rect_blank.zmap") == "zmap");
    assert(surfaceFormat("./test/test_rms_sq.zmap") == "zmap");

    assert(surfaceFormat("./test/test_pet_rect_blank.irap") == "irap");
    assert(surfaceFormat("./test/test_pet_sq.irap") == "irap");

    assert(surfaceFormat("./test/test_rms_rect.roxt") == "irap");
    assert(surfaceFormat("./test/test_rms_rect_blank.roxt") == "irap");
    assert(surfaceFormat("./test/test_rms_sq.roxt") == "irap");
}

/**
* Samples height map to `surface` using height map from the given `source`
*/
void sampleFromSurface(CartesianSurface surface, CartesianSurface source) {
    for (int i = 0; i < surface.nx; i++) {
        for (int j = 0; j < surface.ny; j++) {
            surface.z[i][j] = source.getZ(surface.xOrigin + i * surface.dx, surface.yOrigin + j * surface.dy);
        }
    }
}

/** 
 * Translates the given surface
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

CartesianSurface normalize(CartesianSurface surface) {
    immutable double zmax = surface.m_zd[surface.m_zd.maxIndex];
    immutable double zmin = surface.m_zd[surface.m_zd.minIndex];
    surface.m_zd[] -= zmin;
    surface.m_zd[] /= zmax;
    return surface;
}

unittest {
    //TODO implement
}

//TODO flipAnlogI/flipAlongJ

