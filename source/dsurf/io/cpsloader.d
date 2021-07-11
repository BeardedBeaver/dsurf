module dsurf.io.cpsloader;

import std.conv;
import std.stdio; 
import std.file;
import std.string;
import std.conv;
import std.math;

import dsurf.cartesian;
import dsurf.io.loader;

/**
Class that provides loading of CPS3 ASCII files
*/
class Cps3Loader : CartesianSurfaceLoader 
{
    /// Loads a CPS3 ASCII surface from a file in a given path
    override CartesianSurface load(string fileName) {
        if (!exists(fileName))
            throw new Exception("File " ~ fileName ~ " doesn't exist");
        File file = File(fileName, "r");
        auto surface = new CartesianSurface;
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
                if (surface.nx == 0 || 
                    surface.ny == 0 || 
                    surface.dx == 0 || 
                    surface.dy == 0)
                    throw new Exception("Invalid header");
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
        if (surface.nx == 0 || 
            surface.ny == 0 || 
            surface.dx == 0 || 
            surface.dy == 0)
            throw new Exception("Invalid header");
        return surface;
    }
}