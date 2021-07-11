module dsurf.io.zmapsaver;

import std.stdio;
import std.math;

import dsurf.cartesian;
import dsurf.io.saver;
import std.conv;

/// Class provides saving cartesian surfaces to Zmap+ file
class ZmapSaver : CartesianSurfaceSaver
{
    /// Saves a given surface in a file with a given fileName
    override void save(CartesianSurface surface, string fileName) {
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
        foreach(i; 0 .. surface.nx) {
            foreach_reverse(j; 0 .. surface.ny) {
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
}