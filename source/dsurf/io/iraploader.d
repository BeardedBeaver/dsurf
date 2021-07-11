module dsurf.io.iraploader;

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
class IrapLoader : CartesianSurfaceLoader 
{
    /// Loads an IRAP Classic ASCII (aka ROXAR text) surface from a file in a given path
    override CartesianSurface load(string fileName) {
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
        if (surface.nx == 0 || 
            surface.ny == 0 || 
            surface.dx == 0 || 
            surface.dy == 0)
            throw new Exception("Invalid header");
        return surface;
    }
}