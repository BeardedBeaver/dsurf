module dsurf.cartesian;

import std.range;
import std.stdio; 
import std.string;
import std.algorithm;
import std.file;
import std.conv;
import std.math;

import mir.ndslice;

/***********************************
* Class CartesianSurface represents regular rectangular-cell surface
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
    * Sets surface header and allocates memory for height map
    */
    void setHeader(int nx, int ny, double xOrigin, double yOrigin, double dx, double dy) pure  {
        m_nx = nx;
        m_ny = ny;
        m_xOrigin = xOrigin;
        m_yOrigin = yOrigin;
        m_dx = dx;
        m_dy = dy;
        m_z = slice!double(nx, ny);
    }

    unittest {
        CartesianSurface s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        s1.m_z[] = 50;
        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                assert(s1.z[i][j] == 50);
            }
        }
    }

    /// Copy constructor, returns the exact copy of the given surface
    this(CartesianSurface surface) pure {
        this.setHeader(surface.nx, surface.ny, surface.xOrigin, surface.yOrigin, surface.dx, surface.dy);
        this.m_z[] = surface.m_z[];
    }

    unittest {
        CartesianSurface s1 = new CartesianSurface;
        s1.setHeader(2, 2, 0, 0, 500, 500);
        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                s1.z[i][j] = 50;
            }
        }

        CartesianSurface s2 = new CartesianSurface(s1);
        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                assert(s2.z[i][j] == 50);
            }
        }

        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                s2.z[i][j] = 10;
            }
        }

        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                assert(s2.z[i][j] == 10);
            }
        }

        for (int i = 0; i < s1.nx; i++) {
            for (int j = 0; j < s1.ny; j++) {
                assert(s1.z[i][j] == 50);
            }
        }
    }

    /// Returns X coordinate of surface origin
    @property pure double xOrigin() const @safe @nogc { return m_xOrigin; }

    /// Returns Y coordinate of surface origin
    @property pure double yOrigin() const @safe @nogc { return m_yOrigin; }

    /// Returns surface increment along X axis
    @property pure double dx() const @safe @nogc { return m_dx; }

    /// Returns surface increment along Y axis
    @property pure double dy() const @safe @nogc { return m_dy; }

    /// Returns number of nodes along X axis 
    @property pure int nx() const @safe @nogc { return m_nx; }

    /// Returns number of nodes along Y axis 
    @property pure int ny() const @safe @nogc { return m_ny; }


    /**
    Method to access height map.
    Returns: Chunks of double containing surface's height map
    Example:
    ---
    for (int i = 0; i < surface.nx; i++) {
        for (int j = 0; j < surface.ny; j++) {
            surface.z[i][j] = 0;
        }
    }
    ---
    */ 
    @property Slice!(double*, 2) z() { return m_z; }  

    /// Returns true if point with given coordinates is inside surface boundaries, otherwise returns false
    bool isInsideSurface(double x, double y) const @nogc {
        if (x < m_xOrigin || y < m_yOrigin || x > m_xOrigin + m_dx * (m_nx - 1) || y > m_yOrigin + m_dy * (m_ny - 1))
            return false;
        return true;
    }

    /// Returns cell index from a given X coordinate. Maximum number is nx - 1
    /// Returns -1 if a given coordinate is outside the surface
    int cellXIndex(double x) const {
        if (x < m_xOrigin || x > m_xOrigin + m_dx * (m_nx - 1))
            return -1;  //TODO throw?  
        return  ((x - m_xOrigin) / m_dx).to!int;
    }

    /// Returns cell index from a given Y coordinate. Maximum number is ny - 1
    /// Returns -1 if a given coordinate is outside the surface
    int cellYIndex(double y) const {
        if (y < m_yOrigin || y > m_yOrigin + m_dy * (m_ny - 1))
            return -1;   //TODO throw? 
        return ((y - m_yOrigin) / m_dy).to!int;
    }

    unittest {
        CartesianSurface surface = new CartesianSurface;
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
    double getZ(double x, double y) const {
        if (!isInsideSurface(x, y))
            return double.nan;
        immutable int i = cellXIndex(x);
        immutable int j = cellYIndex(y);

        if (i == m_nx - 1 && j == m_ny - 1)  //top right corner
            return m_z[$ - 1][$ - 1];
        else if (i == m_nx - 1) {   //right edge
            return m_z[i][j] + (m_z[i][j + 1] - m_z[i][j]) / m_dy * (y - (m_yOrigin + j * m_dy));
        }
        else if (j == m_ny - 1) {   //top edge
            return m_z[i][j] + (m_z[i + 1][j] - m_z[i][j]) / m_dx * (x - (m_xOrigin + i * m_dx));
        }

        //z: top left, top right, bottom left, bottom right
        immutable double ztl = m_z[i][j + 1];
        immutable double zbl = m_z[i][j];
        immutable double ztr = m_z[i + 1][j + 1];
        immutable double zbr = m_z[i + 1][j];

        //FIXME handle blanks
        immutable double z1 = (m_xOrigin + (i + 1) * m_dx - x) / dx * zbl + 
                          (x - (m_xOrigin + i * m_dx)) / dx * zbr;
        immutable double z2 = (m_xOrigin + (i + 1) * m_dx - x) / dx * ztl + 
                          (x - (m_xOrigin + i * m_dx)) / dx * ztr;
        return (m_yOrigin + (j + 1) * m_dy - y) / m_dy * z1 + 
               (y - (m_yOrigin + j * m_dy)) / m_dy * z2;
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
                static if (op == "+") {
                    m_z[i][j] += rhsz;
                }
                else static if (op == "-") {
                    m_z[i][j] -= rhsz;
                }
                else static if (op == "*") {
                    m_z[i][j] *= rhsz;
                }
                else static if (op == "/") {
                    if (abs(rhsz) < 1e-9)
                        m_z[i][j] = math.nan;
                    else
                        m_z[i][j] -= rhsz;
                }
                else static assert(0, "Operator "~op~" not implemented");
            }
        }
        return this;
    }

    /// Operators +, -, *, / overloading for two surfaces
    CartesianSurface opBinary(string op)(CartesianSurface rhs) {
        CartesianSurface result = new CartesianSurface(this);
        static if (op == "+") {
            result += rhs;
        }
        else static if (op == "-") {
            result -= rhs;
        }
        else static if (op == "*") {
            result *= result;
        }
        else static if (op == "/") {
            result /= rhs;
        }
        else static assert(0, "Operator "~op~" not implemented");
        return result;
    }

    /// Operators +=, -=, *=, /= overloading for a surface and a fixed value
    CartesianSurface opOpAssign(string op)(double rhs) {
        for (int i = 0; i < m_nx; i++) {
            for (int j = 0; j < m_ny; j++) {
                static if (op == "+") {
                    m_z[i][j] += rhs;
                }
                else static if (op == "-") {
                    m_z[i][j] -= rhs;
                }
                else static if (op == "*") {
                    m_z[i][j] *= rhs;
                }
                else static if (op == "/") {
                    m_z[i][j] -= rhs;
                }
                else static assert(0, "Operator "~op~" not implemented");
            }
        }
        return this;
        
    }

    /// Operators +, -, *, / overloading for a surface and a fixed value
    CartesianSurface opBinary(string op)(double rhs) {
        CartesianSurface result = new CartesianSurface(this);
        static if (op == "+") {
            result += rhs;
        }
        else static if (op == "-") {
            result -= rhs;
        }
        else static if (op == "*") {
            result *= result;
        }
        else static if (op == "/") {
            result /= rhs;
        }
        else static assert(0, "Operator "~op~" not implemented");
        return result;
    }
    
private:
    Slice!(double*, 2) m_z;
    double m_xOrigin;
    double m_yOrigin;
    double m_dx;
    double m_dy;
    int m_nx;
    int m_ny;
}

void loadFromFile(CartesianSurface surface, string fileName) {
    immutable auto format = surfaceFormat(fileName);
    if (format == "cps")
        loadFromCps3Ascii(surface, fileName);
    else if (format == "zmap")
        loadFromZmap(surface, fileName);
    else
        throw new FileException("Unknown surface format");
}

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
                throw new StringException("Invalid index");  //TODO add some information
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

void saveToFile(CartesianSurface surface, string fileName, string format) {
        saveToCps3Ascii(surface, fileName);
    if (format.startsWith("cps".toLower)) 
        saveToCps3Ascii(surface, fileName);
    else 
        throw new FileException(format ~ " cartesian surface format is not supported for export");
}

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
                surface.m_z[surface.m_z.minIndex], " ", 
                surface.m_z[surface.m_z.maxIndex]);
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

void loadFromZmap(CartesianSurface surface, string fileName) {
    File file = File(fileName, "r");
    bool readingHeader = true;
    int i = -1;
    int j = -1;
    double xOrigin = -1, yOrigin = -1;
    double xMax = -1, yMax = -1;
    double dx = -1, dy = -1;
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
            else if (dx < 0) {
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
                throw new StringException("Invalid index");  //TODO add some information
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
    CartesianSurface surface = new CartesianSurface;
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

string surfaceFormat(string fileName) {
    File file = File(fileName, "r");
    string format = "unknown";
    string str = file.readln();
    if (str.startsWith("FSASCI")) {
        format = "cps";
    }
    else {
        if (str.startsWith("!")) {      //probably zmap
            while(str.startsWith("!")) {
                str = file.readln();
            }
            if (str.startsWith("@")) {
                string [] words = str.replace(",", "").split();
                if (words.length >= 4 && icmp(words[2], "grid") == 0)
                    format = "zmap";
            }
        }
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
}

/**
* Samples to surface using height map from the given source surface
*/
void sampleFromSurface(CartesianSurface surface, CartesianSurface source) {
    for (int i = 0; i < surface.nx; i++) {
        for (int j = 0; j < surface.ny; j++) {
            surface.z[i][j] = source.getZ(surface.xOrigin + i * surface.dx, surface.yOrigin + j * surface.dy);
        }
    }
}


CartesianSurface translate(CartesianSurface surface, double dx, double dy) {
    surface.m_xOrigin += dx;
    surface.m_yOrigin += dy;
    return surface;
}

CartesianSurface scale(CartesianSurface surface, double xf, double yf) {  //scales around origin point
    //TODO filter negative factors
    surface.m_dx *= xf;
    surface.m_dy *= yf;
    return surface;
}

CartesianSurface add(CartesianSurface surface, double value) {
    surface.m_z[] += value;
    return surface;
}

CartesianSurface multiply(CartesianSurface surface, double value) {
    surface.m_z[] *= value;
    return surface;
}

CartesianSurface normalize(CartesianSurface surface) {
    immutable double zmax = surface.m_z[surface.m_z.maxIndex];
    immutable double zmin = surface.m_z[surface.m_z.minIndex];
    surface.m_z[] -= zmin;
    surface.m_z[] /= zmax;
    return surface;
}

unittest {
    //TODO implement
}

//TODO flipAnlogI/flipAlongJ

