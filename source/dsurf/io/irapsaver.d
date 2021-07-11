module dsurf.io.irapsaver;

import std.stdio;
import std.math;

import dsurf.cartesian;
import dsurf.io.saver;

/// Class provides saving cartesian surfaces to CPS3 ASCII file
class IrapSaver : CartesianSurfaceSaver
{
    /// Saves a given surface in a file with a given fileName
    override void save(CartesianSurface surface, string fileName) {
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
}