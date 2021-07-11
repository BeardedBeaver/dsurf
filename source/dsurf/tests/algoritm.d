module dsurf.tests.algoritm;

import dsurf.cartesian;
import dsurf.algoritm;

/*
Test for normalize function
*/
unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(3, 3, 0, 0, 25, 25);
    
    import std.random: uniform;
    import std.random: Random;
    import std.random: unpredictableSeed;

    auto rnd = Random(unpredictableSeed);
    for (int i = 0; i < surface.nx; i++) {
        for (int j = 0; j < surface.ny; j++) {
            surface.z[i][j] = uniform(-50.0f, 50.0f, rnd);
        }
    }

    surface.normalize();
    immutable double zmin = surface.min();
    immutable double zmax = surface.max();
    assert(zmax == 1);
    assert(zmin == 0);
}