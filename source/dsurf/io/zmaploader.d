module dsurf.io.zmaploader;

import std.conv;
import std.stdio; 
import std.file;
import std.string;
import std.conv;
import std.math;

import dsurf.cartesian;
import dsurf.io.loader;

/**
Class that provides loading of IRAP Classic ASCII (aka ROXAR text) files
*/
class ZmapLoader : CartesianSurfaceLoader {

    /// Loads an Zmap+ surface from a file in a given path
    override CartesianSurface load(string fileName)
    {
        if (!exists(fileName))
            throw new Exception("File " ~ fileName ~ " doesn't exist");
        File file = File(fileName, "r");
        auto surface = new CartesianSurface;
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
                    if (dx == 0 || dy == 0) {
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
        if (surface.nx == 0 || 
            surface.ny == 0 || 
            surface.dx == 0 || 
            surface.dy == 0)
            throw new Exception("Invalid header");
        return surface;
    }
}