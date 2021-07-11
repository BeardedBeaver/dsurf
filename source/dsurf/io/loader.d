module dsurf.io.loader;

import dsurf.cartesian;

/**
An interface for Cartesian surface loader classes
*/
abstract class CartesianSurfaceLoader
{
    /// Loads a surface by a given fileName
    CartesianSurface load(string fileName);

    /// Returns true if a file in a given fileName
    /// can be loaded by this loader
    bool canLoad(string fileName)
    {
        try 
            this.load(fileName);
        catch(Exception e)
            return false;
        return true;
    }
}