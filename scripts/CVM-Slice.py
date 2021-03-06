#!/usr/bin/env python
"""
Plot a depth plane extracted from the SCEC Community Velocity Model.
"""
import math
import numpy as np
import matplotlib.pyplot as plt
import cst.data
import cst.cvms
import cst.cvmh

# parameters
prop = 'rho'
prop = 'Vs'
label = 'S-wave velocity (m/s)'
depth = 500.0
vmin, vmax = 300, 3200
delta = 0.5 / 60.0
lon, lat = (-120.0, -114.5), (32.5, 35.0)
cmap = cst.plt.colormap('rgb')

# create mesh
x = np.arange(lon[0], lon[1] + 0.5 * delta, delta)
y = np.arange(lat[0], lat[1] + 0.5 * delta, delta)
x, y = np.meshgrid(x, y)
z = np.empty_like(x)
z.fill(depth)

# CVM extractions
vss = cst.cvms.extract(x, y, z, prop)[0]
vsh = cst.cvmh.extract(x, y, z, prop)[0]

# map data
x, y = cst.data.mapdata('coastlines', 'high', (lon, lat), 100.0)

# plot
for vs, tag in [
    (vss, 'S'),
    (vsh, 'H'),
]:
    fig = plt.figure(figsize=(6.4, 4.8))
    ax = plt.gca()
    im = ax.imshow(
        vs, extent=lon+lat, cmap=cmap, vmin=vmin, vmax=vmax, origin='lower',
        interpolation='nearest'
    )
    fig.colorbar(im, orientation='horizontal').set_label(label)
    ax.plot(x - 360, y, 'k-')
    ax.set_aspect(1.0 / math.cos(33.75 / 180.0 * math.pi))
    ax.set_title('CVM%s %.0f m depth' % (tag, depth))
    ax.axis(lon + lat)
    f = 'CVM-Slice-%s-%s.png' % (prop, tag)
    print(f)
    fig.savefig(f)
