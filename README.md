# dsurf
=======

Library for D programming language that provides tools to work with surfaces (2D grids)
-----------

## Features

  - Regular cartesian 2D grids are currently suported 
  - Import 2D grids from popular formats
  - Perform arithmetic calculations with 2D grids
  - Export to popular formats to be able to open it in special software (like Golden Software Surfer or Schlumberger Petrel)

## Supported import formats

  - CPS-3 ASCII
  - ZMap+

## Supported export formats

  - CPS-3 ASCII

[Documentation](https://dsurf.dpldocs.info/dsurf.html) 

Author: Dmitriy Linev

License: MIT

Example:

```D
auto surface = new CartesianSurface;
surface.loadFromFile("./data/surface.cps");
// perform some serious calculation
for (int i = 0; i < surface.nx; i++) {
    for (int j = 0; j < surface.ny; j++) {
        surface.z[i][j] = someSeriousCalculation();
    }
}

// inverse Z axis polarity for export
surface *= -1;
surface.saveToFile("./data/calculated.cps", "cps");
```

## Package content

| Directory     | Contents                       |
|---------------|--------------------------------|
| `./source`    | Source code.                   |
| `./test`      | Unittest data.                 |
