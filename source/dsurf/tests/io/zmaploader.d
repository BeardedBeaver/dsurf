module dsurf.tests.io.zmaploader;

import std.math;

import dsurf.cartesian;
import dsurf.io.zmaploader;

unittest {
    auto loader = new ZmapLoader;

    assert(loader.canLoad("./test/test_pet_rect_blank.zmap"));

    assert(!loader.canLoad("./test/test_pet_rect_blank.cps"));
    assert(!loader.canLoad("./test/test_pet_rect_blank.irap"));
    assert(!loader.canLoad("./test/notexist"));
    
    auto surface = loader.load("./test/test_pet_rect_blank.zmap");
    
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[1][0] == 4);
    assert(surface.z[0][1] == 2);
    assert(surface.z[1][1] == 5);
    assert(isNaN(surface.z[$ - 1][$ - 1]));
    assert(isNaN(surface.z[$ - 1][0]));
}

unittest {
    auto loader = new ZmapLoader;

    assert(loader.canLoad("./test/test_pet_sq.zmap"));

    assert(!loader.canLoad("./test/test_pet_sq.cps"));
    assert(!loader.canLoad("./test/test_pet_sq.irap"));
    assert(!loader.canLoad("./test/notexist"));

    auto surface = loader.load("./test/test_pet_sq.zmap");
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
    auto loader = new ZmapLoader;
    
    assert(loader.canLoad("./test/test_rms_sq.zmap"));

    assert(!loader.canLoad("./test/test_rms_sq.cps"));
    assert(!loader.canLoad("./test/test_rms_sq.irap"));
    assert(!loader.canLoad("./test/notexist"));
    
    auto surface = loader.load("./test/test_rms_sq.zmap");
    
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
    auto loader = new ZmapLoader;
    
    assert(loader.canLoad("./test/test_rms_rect.zmap"));

    assert(!loader.canLoad("./test/test_rms_rect.cps"));
    assert(!loader.canLoad("./test/test_rms_rect.irap"));
    assert(!loader.canLoad("./test/notexist"));
    
    auto surface = loader.load("./test/test_rms_rect.zmap");
    
    assert(surface.nx == 5);
    assert(surface.ny == 3);
    assert(surface.dx == 250);
    assert(surface.dy == 500);
    assert(surface.xOrigin == 5000);
    assert(surface.yOrigin == 0);
    assert(surface.z[0][0] == 1);
    assert(surface.z[$ - 1][$ - 1] == 15);
}