module dsurf.io;

import dsurf.cartesian;
import std.conv;
import std.stdio; 
import std.file;
import std.string;
import std.conv;
import std.math;

/***********************************
* Set of methods to read and write surfaces to external formats
* Supported import formats:
*  - CPS-3 ASCII
*  - ZMap+
*  - IRAP Classic ASCII (aka ROXAR text)
* Supported export formats:
*  - CPS-3 ASCII
*  - ZMap+
* Authors: Dmitriy Linev
* License: MIT
* Date: 2019-2020
*/

/** 
 * Loads `surface` from file trying to detect format automatically
 * Params:
 *   surface = `CartesianSurface` to load data to
 *   fileName = Path to file for loading
 * Currently supported formats are CPS3 ASCII, ZMap+ and IRAP Classic (aka ROXAR text)
 */
void loadFromFile(CartesianSurface surface, string fileName) {
    immutable auto format = surfaceFormat(fileName);
    if (format == "cps")
        loadFromCps3Ascii(surface, fileName);
    else if (format == "zmap")
        loadFromZmap(surface, fileName);
    else if (format == "irap")
        loadFromIrapClassicAscii(surface, fileName);
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
 * Loads `surface` from file of IRAP Classic ASCII (aka ROXAR text)
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
 *   format = format to save surface to. Currently supported formats for export are: CPS3 ASCII (`cps`) and ZMap+ (`zmap`)
 */
void saveToFile(CartesianSurface surface, string fileName, string format) {
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
                surface.xOrigin, " ", 
                surface.xOrigin + (surface.nx) * surface.dx, " ", 
                surface.yOrigin, " ", 
                surface.yOrigin + (surface.ny) * surface.dy, " ", 
                surface.zMin, " ", 
                surface.zMax);
    file.writeln("FSNROW ", surface.ny, " ", surface.nx);
    file.writeln("FSXINC ", surface.dx, " ", surface.dy);
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

/** 
 * Saves the given surface to ZMap+ text format
 * Params:
 *   surface = surface to save
 *   fileName = path to output file
 */
void saveToZMap(CartesianSurface surface, string fileName) {
    File file = File(fileName, "w");
    immutable double blank = 1e30;
    import std.path: baseName;
    file.writeln("!     dsurf - library for surface handling");
    file.writeln("!     for D programming language");
    file.writeln("!     GRID FILE NAME   : ");
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
    
    foreach (i; 0..surface1.nx) {
        foreach (j; 0..surface1.ny) {
            assert(surface1.z[i][j] == surface2.z[i][j]);
        }
    }

}

/** 
 * Saves the given surface to IRAP Classic ASCII (aka ROXAR text)
 * Params:
 *   surface = surface to save
 *   fileName = path to output file
 */
void saveToIrapClassicAscii(CartesianSurface surface, string fileName) {
    File file = File(fileName, "w");
    file.write(-996, " ", surface.ny, " ", surface.dx, " ", surface.dy, "\n");
    file.write(surface.xOrigin, " ", surface.xOrigin + surface.dx * surface.nx, " ",
               surface.yOrigin, " ", surface.yOrigin + surface.dy * surface.ny, "\n");
    file.write(surface.nx, " ", 0, " ", surface.xOrigin, " ", surface.yOrigin, "\n");
    file.write(0, " ", 0, " ", 0, " ", 
                0, " ", 0, " ", 0, " ", 0, "\n");
    file.write("    ");
    int n = 0;
    foreach (j; 0 .. surface.ny) {
        foreach (i; 0..surface.nx) {
            file.write(surface.z[i][j]);
            n++;
            if (n % 6 == 0)
                file.write("\n    ");
            else
                file.write(" ");
        }
    }
}

unittest {
    auto surface1 = new CartesianSurface;
    surface1.loadFromZmap("./test/test_rms_sq.zmap");
    surface1.saveToIrapClassicAscii("./test/_tmp_test_export.irap");
    assert(surfaceFormat("./test/_tmp_test_export.irap") == "irap");
    auto surface2 = new CartesianSurface;
    surface2.loadFromFile("./test/_tmp_test_export.irap");
    import std.file: remove;
    remove("./test/_tmp_test_export.irap");

    assert(surface1.nx == surface2.nx);
    assert(surface1.ny == surface2.ny);
    assert(surface1.dx == surface2.dx);
    assert(surface1.dy == surface2.dy);

    assert(surface1.xOrigin == surface2.xOrigin);
    assert(surface1.yOrigin == surface2.yOrigin);
    
    foreach (i; 0..surface1.nx) {
        foreach (j; 0 .. surface1.ny) {
            assert(surface1.z[i][j] == surface2.z[i][j]);
        }
    }
}

/** 
 * Tries to detect surface format
 * Params:
 *   fileName = path to file to detect format
 * Returns: string containing surface format. `cps` for CPS3 ASCII; `zmap` for ZMAP+ ASCII; `irap` for IRAP Classic ASCII (aka ROXAR text); `unknown` if format hasn`t been detected.
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
