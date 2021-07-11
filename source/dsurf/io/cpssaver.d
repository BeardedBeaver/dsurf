module dsurf.io.cpssaver;

import std.stdio;
import std.math;

import dsurf.cartesian;
import dsurf.io.saver;

/// Class provides saving cartesian surfaces to CPS3 ASCII file
class Cps3Saver : CartesianSurfaceSaver
{    
    /// Saves a given surface in a file with a given fileName
    override void save(CartesianSurface surface, string fileName) {
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
}