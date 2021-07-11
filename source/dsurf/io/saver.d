module dsurf.io.saver;

import dsurf.cartesian;

/**
An interface for Cartesian surface saver classes
*/
interface CartesianSurfaceSaver{
    
    /// Saves a given surface in a file with a given fileName
    void save(CartesianSurface surface, string fileName);
}