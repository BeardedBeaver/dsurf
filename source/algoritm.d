module dsurf.algoritm;


import std.math;
import std.range;
import std.parallelism;

import dsurf.cartesian;

/// Returns surface gradient along X axis in the node with index i and j
double gX(CartesianSurface surface, int i, int j) {
    if (i == 0)
        return (surface.z[i + 1][j] - surface.z[i][j]) / surface.dx;
    if (i == surface.nx - 1)
        return (surface.z[i][j] - surface.z[i - 1][j]) / surface.dx;
    return (surface.z[i + 1][j] - surface.z[i - 1][j]) / (2 * surface.dx);
}

/// Returns surface gradient along Y axis in the node with index i and j
double gY(CartesianSurface surface, int i, int j) {
    if (j == 0)
        return (surface.z[i][j + 1] - surface.z[i][j]) / surface.dy;
    if (j == surface.ny-1)
        return (surface.z[i][j] - surface.z[i][j - 1]) / surface.dy;
    return (surface.z[i][j + 1] - surface.z[i][j - 1]) / (2 * surface.dy);
}

/// Returns CartesianSurface containing gradient map along X axis based on a given surface
CartesianSurface buildGradientXMap(CartesianSurface surface) {
    CartesianSurface gradient = new CartesianSurface(surface);
    foreach (i; taskPool.parallel(iota(surface.nx))) {
        foreach (j; 0..surface.ny) {
            gradient.z[i][j] = surface.gX(i, j);
        }
    }
    return gradient;
}

/// Returns CartesianSurface containing gradient map along Y axis based on a given surface
CartesianSurface buildGradientYMap(CartesianSurface surface) {
    CartesianSurface gradient = new CartesianSurface(surface);
    foreach (i; taskPool.parallel(iota(surface.nx))) {
        foreach (j; 0..surface.ny) {
            gradient.z[i][j] = surface.gY(i, j);
        }
    }
    return gradient;
}

/// Returns dip angle in radians of the surface in the node with index i and j
double dipAngle(CartesianSurface surface, int i, int j) {
    immutable double gx = surface.gX(i, j);
    immutable double gy = surface.gY(i, j);
    if (isNaN(gx) || isNaN(gy))
        return double.nan;
    return atan(sqrt(gx * gx + gy * gy));
}

/// Returns CartesianSurface containing dip angle map in radians based on a given surface
CartesianSurface buildDipAngle(CartesianSurface surface) {
    CartesianSurface result = new CartesianSurface(surface);
    foreach (i; taskPool.parallel(iota(surface.nx))) {
        foreach (j; 0..surface.ny) {
            result.z[i][j] = surface.dipAngle(i, j);
        }
    }
    return result;
}
