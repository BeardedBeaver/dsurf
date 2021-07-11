module dsurf.tests.cartesian;

import std.math;
import std.exception;
import dsurf.cartesian;

/**
Defaul constructor tests
*/
unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(2, 2, 0, 0, 500, 500);
    surface.assignConstant(50);
    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            assert(surface.z[i][j] == 50);
}

/**
Checks for an attempt to set zero or negative surface size
*/
unittest {
    auto surface = new CartesianSurface;
    assertThrown!Exception(surface.setHeader(0, 5, 0, 0, 25, 25));
    assertThrown!Exception(surface.setHeader(5, 0, 0, 0, 25, 25));
    assertThrown!Exception(surface.setHeader(5, -5, 0, 0, 25, 25));
    assertThrown!Exception(surface.setHeader(-5, 5, 0, 0, 25, 25));
    assertThrown!Exception(surface.setHeader(-5, -5, 0, 0, 25, 25));
}

/**
Unittest for copy construction and assignConstant.
Creates a surface, creates its copy, 
assigns other height values to the copy 
and checks if an original one remains unchanged
*/
unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(2, 2, 0, 0, 500, 500);
    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            surface.z[i][j] = 50;

    auto s2 = new CartesianSurface(surface);
    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            assert(s2.z[i][j] == 50);

    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            s2.z[i][j] = 10;

    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            assert(s2.z[i][j] == 10);

    foreach(i; 0 .. surface.nx)
        foreach(j; 0 .. surface.ny)
            assert(surface.z[i][j] == 50);
}

/**
Tests for cellXIndex and cellYIndex methods
*/
unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(10, 10, 0, 1000, 500, 500);
    assert(surface.cellXIndex(-1000) == -1);
    assert(surface.cellYIndex(-1000) == -1);
    assert(surface.cellXIndex(0) == 0);
    assert(surface.cellYIndex(1000) == 0);
    assert(surface.cellXIndex(550) == 1);
    assert(surface.cellYIndex(1550) == 1);
    assert(surface.cellXIndex(5000) == -1);
    assert(surface.cellYIndex(6000) == -1);
}

/**
Tests for getZ method
*/
unittest {
    import dsurf.io.cpsloader: Cps3Loader;
    
    auto loader = new Cps3Loader;
    auto surface = loader.load("./test/test_pet_rect_blank.cps");
    
    assert(isNaN(surface.getZ(5600, 250)));
    assert(!isNaN(surface.getZ(5600, 800)));
    assert(isNaN(surface.getZ(5700, 600)));
    assert(isNaN(surface.getZ(5600, 250)));
    assert(isNaN(surface.getZ(5850, 250)));
}

unittest {
    import dsurf.io.cpsloader: Cps3Loader;
    
    auto loader = new Cps3Loader;
    auto surface = loader.load("./test/test_pet_sq.cps");

    assert(surface.nx == 3);
    assert(surface.ny == 3);
    surface.z[1][1] = double.nan;
    assert(isNaN(surface.getZ(5320.00, 700.00)));
    assert(isNaN(surface.getZ(5650.00, 715.00)));
    assert(isNaN(surface.getZ(5650.00, 300.00)));
    assert(isNaN(surface.getZ(5315.00, 300.00)));

    assert(isClose(surface.getZ(5120.00, 850.00), 2.42));
    assert(isClose(surface.getZ(5815.00, 850.00), 6.59));
    assert(isClose(surface.getZ(5800.00, 200.00), 5.20));
    assert(isClose(surface.getZ(5200.00, 200.00), 1.60));
}

/**
Tests for assignment operators
*/
unittest {
    auto s1 = new CartesianSurface;
    s1.setHeader(2, 2, 0, 0, 500, 500);
    s1.assignConstant(50);

    auto s2 = new CartesianSurface(s1);
    s2.assignConstant(10);

    s1 /= s2;
    assert(s1.min() == 5);
    assert(s1.max() == 5);

    s1 += s2;
    assert(s1.min() == 15);
    assert(s1.max() == 15);

    s1 *= s2;
    assert(s1.min() == 150);
    assert(s1.max() == 150);
    
    s1 -= s2;
    assert(s1.min() == 140);
    assert(s1.max() == 140);
}

unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(2, 2, 0, 0, 500, 500);
    surface.assignConstant(50);
    auto result = surface + surface;

    assert(surface.min() == 50);
    assert(surface.max() == 50);
    assert(result.min() == 100);
    assert(result.max() == 100);

    result = surface * surface;
    assert(surface.min() == 50);    // make sure that the original surface
    assert(surface.max() == 50);    // didn't change
    assert(result.min() == 2500);
    assert(result.max() == 2500);
    
    result = surface - surface;
    assert(surface.min() == 50);
    assert(surface.max() == 50);
    assert(result.min() == 0);
    assert(result.max() == 0);
    
    result = surface / surface;
    assert(surface.min() == 50);
    assert(surface.max() == 50);
    assert(result.min() == 1);
    assert(result.max() == 1);
}

 unittest {
    auto surface = new CartesianSurface;
    surface.setHeader(2, 2, 0, 0, 500, 500);
    surface.assignConstant(50);
    auto result = surface + 10;
    foreach (i; 0 .. surface.nx)
        foreach (j; 0 .. surface.ny) {
            assert(surface.z[i][j] == 50);
            assert(result.z[i][j] == 60);
        }
    
    result = surface - 20;
    foreach (i; 0 .. surface.nx)
        foreach (j; 0 .. surface.ny) {
            assert(surface.z[i][j] == 50);
            assert(result.z[i][j] == 30);
        }

    result = surface * 2.5;
    foreach (i; 0 .. surface.nx)
        foreach (j; 0 .. surface.ny) {
            assert(surface.z[i][j] == 50);
            assert(result.z[i][j] == 125);
        }

    result = surface / 5;
    foreach (i; 0 .. surface.nx)
        foreach (j; 0 .. surface.ny) {
            assert(surface.z[i][j] == 50);
            assert(result.z[i][j] == 10);
        }
}