#!/usr/bin/env python
import os
import math
import numpy as np
import cst.sord

# FIXME: prestress not correct

dx = 100.0
dt = dx / 12500.0
nx = 2
ny = int(16500.0 / dx + 21.5)
nz = int(12000.0 / dx + 120.5)
nt = int(8.0 / dt + 1.5)
alpha = math.sin(math.pi / 3.0)

prm = {
    'affine': [
        [1.0, 0.0,   0.0],
        [0.0, alpha, 0.0],
        [0.0, 0.5,   1.0],
    ],
    'shape': [nx, ny, nz, nt],
    'delta': [dx, dx, dx, dt],
    'nproc3': [1, 1, 2],
    'bc1': ['+node', 'free', 'free'],
    'bc2': ['+node', 'pml', 'free'],
    'n1expand': [0, 0, 50],
    'n2expand': [0, 0, 50],
    'hourglass': [1.0, 2.0],
    'rho': [2700.0],
    'vp': [5716.0],
    'vs': [3300.0],
    'faultnormal': '+z',
    'co': [200000.0],
    'dc': [0.5],
    'mud': [0.1],
    'sxx': [([0, ':'], '=<', 'sxx.bin')],
    'syy': [([0, ':'], '=<', 'syy.bin')],
    'szz': [([0, ':'], '=<', 'szz.bin')],
}

# hypocenter
y = 12000.0 / dx
z = nz // 2 - 0.5
prm['hypocenter'] = hypo = [0.0, y, z]

# near-fault volume
k = int(15000.0 / dx + 0.5)
l0 = int(z - 3000.0 / dx + 0.5)
l1 = int(z + 3000.0 / dx + 0.5)
prm['gam'] = [0.2, ([[], [k], [l0, l1]], '==', 0.02)]

# fault parameters
k = int(15000.0 / dx) + 1
prm['mus'] = [10000.0, ([[], [k]], '=', 0.7)]

# nucleation
i = int(1500.0 / dx + 0.5)
k = int(hypo[1])
prm['mus'] = [
    ([[], [k-i, k+i+1]],   '=', 0.62),
    ([[], [k-i-1, k+i+2]], '=', 0.54),
]

# fault time histories
for f in (
    'sux', 'suy', 'suz',
    'svx', 'svy', 'svz',
    'tsx', 'tsy', 'tsz', 'tnm',
):
    prm[f] = []
    for k in 0, 15, 30, 45, 75, 120:
        y = k * 100.0 / dx
        s = 'faultst%03ddp000-%s.bin' % (k, f)
        prm[f] += [([0.0, y, []], '.>', s)]

# body time histories
for k, l in [
    [0, -30],
    [0, -20],
    [0, -10],
    [0,  10],
    [0,  20],
    [0,  30],
    [3, -10],
    [3,  -5],
    [3,   5],
    [3,  10],
]:
    y = k * 100.0 / dx / alpha
    z = l * 100.0 / dx + hypo[2]
    for f in 'u1', 'u2', 'u3', 'v1', 'v2', 'v3':
        s = 'body%03dst000dp%03d-%s.bin' % (l, k, f)
        s = s.replace('body-', 'body-0')
        prm[f] += [([0.0, y, z, []], '.>', s)]

# pre-stress
d = np.arange(ny) * alpha * dx
x = d * 9.8 * -1147.16
y = d * 9.8 * -1700.0
z = d * 9.8 * -594.32
k = int(13800.0 / dx + 1.5)
x[k:] = y[k:]
z[k:] = y[k:]

# run SORD
d = 'repo/TVP12-2D'
os.mkdir(d)
os.chdir(d)
x.astype('f').tofile('sxx.bin')
y.astype('f').tofile('syy.bin')
z.astype('f').tofile('szz.bin')
cst.sord.run(prm)
