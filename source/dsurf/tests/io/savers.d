module dsurf.tests.io.savers;

import std.file;
import std.math;
import std.algorithm;

import dsurf.cartesian;

import dsurf.io.loader;
import dsurf.io.cpsloader;
import dsurf.io.zmaploader;
import dsurf.io.iraploader;

import dsurf.io.saver;
import dsurf.io.cpssaver;
import dsurf.io.zmapsaver;
import dsurf.io.irapsaver;

unittest {
    CartesianSurfaceLoader [string] loaders;
    loaders["cps"]= new Cps3Loader;
    loaders["zmap"] = new ZmapLoader;
    loaders["irap"] = new IrapLoader;

    CartesianSurfaceSaver [string] savers;
    savers["cps"] = new Cps3Saver;
    savers["zmap"] = new ZmapSaver;
    savers["irap"] = new IrapSaver;

    auto surface = new CartesianSurface;
    surface.setHeader(10, 5, 500, 1000, 100, 200);

    import std.random: uniform;
    import std.random: Random;
    import std.random: unpredictableSeed;

    auto rnd = Random(unpredictableSeed);
    foreach(i; 0 .. surface.nx) {
        foreach(j; 0 .. surface.ny) {
            surface.z[i][j] = uniform(-50.0f, 50.0f, rnd);
        }
    }

    auto path = "./test/tmp/";
    if (!exists(path))
        mkdir(path);

    assert(exists(path));

    foreach (format, saver; savers)
    {
        auto loader = loaders[format];
        auto fileName = path ~ "surface." ~ format;
        saver.save(surface, fileName);

        assert(loader.canLoad(fileName));
        auto loadedSurface = loader.load(fileName);

        assert(surface.nx == loadedSurface.nx);
        assert(surface.ny == loadedSurface.ny);

        assert(isClose(surface.xOrigin, loadedSurface.xOrigin));
        assert(isClose(surface.yOrigin, loadedSurface.yOrigin));

        assert(isClose(surface.dx, loadedSurface.dx));
        assert(isClose(surface.dy, loadedSurface.dy));

        foreach(i; 0 .. surface.nx) {
            foreach(j; 0 .. surface.ny) {
                assert(isClose(surface.z[i][j], loadedSurface.z[i][j], 1e-5)); 
                // TODO we're comparing with the relative diff of a 1e-5
                // Check how it can be improved
            }
        }
    }

    rmdirRecurse(path);    
}