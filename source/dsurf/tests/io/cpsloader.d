module dsurf.tests.io.cpsloader;

import dsurf.cartesian;
import dsurf.io.cpsloader;

unittest {
    auto loader = new Cps3Loader;
    assert(loader.canLoad("./test/test_pet_rect.cps"));
    
    assert(!loader.canLoad("./test/test_pet_rect.irap"));
    assert(!loader.canLoad("./test/test_pet_rect.zmap"));
    assert(!loader.canLoad("./test/notexist"));

    auto surface = loader.load("./test/test_pet_rect.cps");

    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}

unittest {
    auto loader = new Cps3Loader;
    assert(loader.canLoad("./test/test_pet_sq.cps"));

    assert(!loader.canLoad("./test/test_pet_sq.irap"));
    assert(!loader.canLoad("./test/test_pet_sq.zmap"));
    assert(!loader.canLoad("./test/notexist"));

    auto surface = loader.load("./test/test_pet_sq.cps");
    
    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);
}


unittest {
    auto loader = new Cps3Loader;

    assert(loader.canLoad("./test/test_rms_sq.cps"));
    
    assert(!loader.canLoad("./test/test_rms_sq.roxt"));
    assert(!loader.canLoad("./test/test_rms_sq.irap"));
    assert(!loader.canLoad("./test/notexist"));
    
    auto surface = loader.load("./test/test_rms_sq.cps");

    assert(surface.nx == 3);
    assert(surface.ny == 3);
    assert(surface.dx == 500);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 0);
    assert(surface.z[$ - 1][$ - 1] == 8);
}

unittest {
    auto loader = new Cps3Loader;

    assert(loader.canLoad("./test/test_rms_rect.cps"));

    assert(!loader.canLoad("./test/test_rms_rect.irap"));
    assert(!loader.canLoad("./test/test_rms_rect.zmap"));
    assert(!loader.canLoad("./test/notexist"));
    
    auto surface = loader.load("./test/test_rms_rect.cps");
    
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}