# dsurf

Library for D programming language that provides tools to work with surfaces (2D grids)
-----------

Simple library for D to deal with surfaces (2D grids). Regular cartesian-cell 2D grids currently are supported. 

## Information

Documentation is available [here](https://dsurf.dpldocs.info/dsurf.html) 

Author: Dmitriy Linev

License: MIT

## Features

  - Import 2D grids from popular formats
  - Perform arithmetic calculations with 2D grids
  - Export to popular formats to be able to open it in special software (like Golden Software Surfer or Schlumberger Petrel)

## Supported import formats

  - CPS-3 ASCII
  - ZMap+
  - IRAP Classic ASCII (aka ROXAR text)

## Supported export formats

  - CPS-3 ASCII
  - ZMap+
  - IRAP Classic ASCII (aka ROXAR text)

## Example

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

## Installation

dsurf is available in dub. If you're using dub run `dub add dsurf` in your project folder and dub will add dependency and fetch the latest version.