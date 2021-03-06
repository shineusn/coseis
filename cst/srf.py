"""
Utilities for Graves Standard Rupture Format (SRF).

SRF is documented at http://epicenter.usc.edu/cmeportal/docs/srf4.pdf
"""
import os
import math
import gzip
import numpy
from . import coord


def read(fh):
    """
    Read SRF file.

    Given file handle fh, return SRF metadata/data pair of dictionaries. The
    first dict 'meta' contains scalars and metadata. The second dict 'data'
    contains NumPy arrays.
    """

    # mks units
    u_km = 1000
    u_cm = 0.01
    u_cm2 = 0.0001

    # header block
    meta = {}
    meta['version'] = next(fh).split()[0]
    s = next(fh).split()
    if s[0] == 'PLANE':
        plane = []
        for i in range(int(s[1])):
            s = next(fh).split() + next(fh).split()
            if len(s) != 11:
                raise Exception('error reading %s' % fh.name)
            j, k = int(s[2]), int(s[3])
            x, y = float(s[4]) * u_km, float(s[5]) * u_km
            seg = {
                'shape': [j, k],
                'length': [x, y],
                'area': x * y,
                'delta': [x / j, y / k],
                'topcenter': [float(s[0]), float(s[1]), float(s[8])],
                'strike': float(s[6]),
                'dip': float(s[7]),
                'hypocenter': [float(s[9]) * u_km, float(s[10]) * u_km],
            }
            plane += [seg]
        meta['plane'] = plane
        s = next(fh).split()
    if s[0] != 'POINTS':
        raise Exception('error reading %s' % fh.name)
    meta['nsource'] = n = int(s[1])

    # data block
    data = {}
    keys_2i = 'nt1', 'nt2', 'nt3'
    keys_2f = (
        'lon', 'lat', 'dep', 'stk', 'dip', 'rake', 'area',
        't0', 'dt', 'slip1', 'slip2', 'slip3',
    )
    for k in keys_2i:
        data[k] = numpy.empty(n, 'i')
    for k in keys_2f:
        data[k] = numpy.empty(n, 'f')
    sv1, sv2, sv3 = [], [], []
    for i in range(n):
        k = next(fh).split() + next(fh).split()
        if len(k) != 15:
            raise Exception('error reading %s %s' % (fh.name, i))
        data['lon'][i] = float(k[0])
        data['lat'][i] = float(k[1])
        data['dep'][i] = float(k[2]) * u_km
        data['stk'][i] = float(k[3])
        data['dip'][i] = float(k[4])
        data['rake'][i] = float(k[8])
        data['area'][i] = float(k[5]) * u_cm2
        data['t0'][i] = float(k[6])
        data['dt'][i] = float(k[7])
        data['slip1'][i] = float(k[9]) * u_cm
        data['slip2'][i] = float(k[11]) * u_cm
        data['slip3'][i] = float(k[13]) * u_cm
        data['nt1'][i] = nt1 = int(k[10])
        data['nt2'][i] = nt2 = int(k[12])
        data['nt3'][i] = nt3 = int(k[14])
        sv = []
        n = numpy.cumsum([nt1, nt2, nt3])
        while len(sv) < n[-1]:
            sv += next(fh).split()
        if len(sv) != n[-1]:
            raise Exception('error reading %s %s' % (fh.name, i))
        sv1 += [float(f) * u_cm for f in sv[:n[0]]]
        sv2 += [float(f) * u_cm for f in sv[n[0]:n[1]]]
        sv3 += [float(f) * u_cm for f in sv[n[1]:]]

    # slip velocity arrays
    data['sv1'] = sv1 = numpy.array(sv1, 'f')
    data['sv2'] = sv2 = numpy.array(sv2, 'f')
    data['sv3'] = sv3 = numpy.array(sv3, 'f')

    # reshape array (only handles a single plane for now)
    if len(meta['plane']) == 1:
        n = meta['plane'][0]['shape']
        for k in keys_2f + keys_2i:
            data[k] = data[k].reshape(n[::-1]).T

    # useful meta data
    i1 = (data['nt1'] > 0).sum()
    i2 = (data['nt2'] > 0).sum()
    i3 = (data['nt3'] > 0).sum()
    meta['nsource_nonzero'] = i1 + i2 + i3
    i = numpy.argmin(data['t0'])
    meta['hypocenter'] = [
        float(data['lon'].flat[i]),
        float(data['lat'].flat[i]),
        float(data['dep'].flat[i]),
    ]
    meta['area'] = a = float(data['area'].sum(dtype='d'))
    meta['potency'] = p = float(numpy.sqrt(
        (data['area'] * data['slip1']).sum(dtype='d') ** 2 +
        (data['area'] * data['slip2']).sum(dtype='d') ** 2 +
        (data['area'] * data['slip3']).sum(dtype='d') ** 2
    ))
    meta['displacement'] = p / a

    return meta, data


def write(fh, srf):

    # mks units
    u_km = 0.001
    u_cm = 100
    u_cm2 = 10000

    # header block
    meta, data = srf
    fh.write('%s\n' % meta['version'])
    if 'plane' in meta:
        for i, seg in enumerate(meta['plane']):
            fh.write('PLANE %s\n%s %s %s %s %s %s\n%s %s %s %s %s\n' % (
                i + 1,
                seg['topcenter'][0],
                seg['topcenter'][1],
                seg['shape'][0],
                seg['shape'][1],
                seg['length'][0] * u_km,
                seg['length'][1] * u_km,
                seg['strike'],
                seg['dip'],
                seg['topcenter'][2],
                seg['hypocenter'][0] * u_km,
                seg['hypocenter'][1] * u_km,
            ))

    # data block
    n = meta['nsource']
    fh.write(('POINTS %s\n' % n))
    i1 = 0
    i2 = 0
    i3 = 0
    for i in range(n):
        fh.write('%s %s %s %s %s %s %s %s\n%s %s %s %s %s %s %s\n' % (
            data['lon'][i],
            data['lat'][i],
            data['dep'][i] * u_km,
            data['stk'][i],
            data['dip'][i],
            data['area'][i] * u_cm2,
            data['t0'][i],
            data['dt'][i],
            data['rake'][i],
            data['slip1'][i] * u_cm,
            data['nt1'][i],
            data['slip2'][i] * u_cm,
            data['nt2'][i],
            data['slip3'][i] * u_cm,
            data['nt3'][i],
        ))
        n1 = data['nt1'][i]
        n2 = data['nt2'][i]
        n3 = data['nt3'][i]
        s1 = data['sv1'][i1:i1+n1] * u_cm
        s2 = data['sv2'][i2:i2+n2] * u_cm
        s3 = data['sv3'][i3:i3+n3] * u_cm
        s = numpy.concatenate([s1, s2, s3])
        i = s.size // 6 * 6
        numpy.savetxt(fh, s[:i].reshape([-1, 6]), '%13.5e', '')
        numpy.savetxt(fh, s[i:].reshape([1, -1]), '%13.5e', '')
        i1 += n1
        i2 += n2
        i3 += n3
    return


def write_sord(path, srf, delta=(1, 1, 1), proj=None, dbytes=4):
    """
    Write SORD potency tensor input files.

    path: file name root
    srf: (meta, data) SRF dictionaries
    delta: grid step size (dx, dy, dz)
    proj: function to project lon/lat to logical model coordinates
    dbytes: 4 or 8
    """

    # setup
    meta, data = srf
    i_ = 'i%s' % dbytes
    f_ = 'f%s' % dbytes

    # time
    i1 = data['nt1'] > 0
    i2 = data['nt2'] > 0
    i3 = data['nt3'] > 0
    f1 = open(path + 'nt.bin', 'wb')
    f2 = open(path + 'dt.bin', 'wb')
    f3 = open(path + 't0.bin', 'wb')
    with f1, f2, f3:
        data['nt1'][i1].astype(i_).tofile(f1)
        data['nt2'][i2].astype(i_).tofile(f1)
        data['nt3'][i3].astype(i_).tofile(f1)
        for i in i1, i2, i3:
            data['dt'][i].astype(f_).tofile(f2)
            data['t0'][i].astype(f_).tofile(f3)

    # coordinates
    x = data['lon']
    y = data['lat']
    z = data['dep']
    if proj:
        rot = coord.rotation(x, y, proj)[1]
        x, y = proj(x, y)
    else:
        rot = 0.0
    x /= delta[0]
    y /= delta[1]
    z /= delta[2]
    f1 = open(path + 'xi1.bin', 'wb')
    f2 = open(path + 'xi2.bin', 'wb')
    f3 = open(path + 'xi3.bin', 'wb')
    with f1, f2, f3:
        for i in i1, i2, i3:
            x[i].astype(f_).tofile(f1)
            y[i].astype(f_).tofile(f2)
            z[i].astype(f_).tofile(f3)
    del(x, y, z)

    # fault local coordinate system
    s1, s2, n = coord.slip_vectors(
        data['stk'] + rot, data['dip'], data['rake']
    )
    p1 = data['area'] * coord.potency_tensor(n, s1)
    p2 = data['area'] * coord.potency_tensor(n, s2)
    p3 = data['area'] * coord.potency_tensor(n, n)
    del(s1, s2, n)

    # tensor components
    f11 = open(path + 'w11.bin', 'wb')
    f22 = open(path + 'w23.bin', 'wb')
    f33 = open(path + 'w33.bin', 'wb')
    with f11, f22, f33:
        for p, i in (p1, i1), (p2, i2), (p3, i3):
            p[0, 0, i].astype(f_).tofile(f11)
            p[0, 1, i].astype(f_).tofile(f22)
            p[0, 2, i].astype(f_).tofile(f33)
    f23 = open(path + 'w23.bin', 'wb')
    f31 = open(path + 'w31.bin', 'wb')
    f12 = open(path + 'w12.bin', 'wb')
    with f23, f31, f12:
        for p, i in (p1, i1), (p2, i2), (p3, i3):
            p[1, 0, i].astype(f_).tofile(f23)
            p[1, 1, i].astype(f_).tofile(f31)
            p[1, 2, i].astype(f_).tofile(f12)
    del(p1, p2, p3)

    # time history
    i1 = 0
    i2 = 0
    i3 = 0
    with open(path + 'history.bin', 'wb') as fh:
        n = meta['nsource']
        for i in range(n):
            n = data['nt1'][i]
            s = data['sv1'][i1:i1+n].cumsum() * data['dt'][i]
            s.astype(f_).tofile(fh)
            i1 += n
        for i in range(n):
            n = data['nt2'][i]
            s = data['sv2'][i2:i2+n].cumsum() * data['dt'][i]
            s.astype(f_).tofile(fh)
            i2 += n
        for i in range(n):
            n = data['nt3'][i]
            s = data['sv3'][i3:i3+n].cumsum() * data['dt'][i]
            s.astype(f_).tofile(fh)
            i3 += n
    return


def write_awp(
    fh, srf, t, mu, lam=0.0, delta=1.0, proj=None, binary=True, interp='linear'
):
    """
    Write ODC-AWP moment rate input file.

    fh: file handle
    srf: (meta, data) SRF dictionaries
    t: array of time values
    mu, lam: elastic moduli
    delta: grid step size, single value or [dx, dy, dz]
    proj: Function to project lon/lat to logical model coordinates
    binary: If true, write AWP binary format, otherwise text format.
    interp: interpolation method, linear or cubic
    """

    # parameters
    meta, data = srf
    if not isinstance(delta, (tuple, list)):
        delta = delta, delta, delta
    x = data['lon']
    y = data['lat']
    z = data['dep']
    dt = data['dt']
    t0 = data['t0']
    stk = data['stk']
    dip = data['dip']
    rake = data['rake']
    area = data['area']

    # coordinates
    if proj:
        rot = coord.rotation(x, y, proj)[1]
        x, y = proj(x, y)
    else:
        rot = 0.0
    jj = (x / delta[0] + 1.5).astype('i')
    kk = (y / delta[1] + 1.5).astype('i')
    ll = (z / delta[2] + 1.5).astype('i')
    del(x, y, z)

    # moment tensor components
    s1, s2, n = coord.slip_vectors(stk + rot, dip, rake)
    m1 = mu * area * coord.potency_tensor(n, s1) * 2.0
    m2 = mu * area * coord.potency_tensor(n, s2) * 2.0
    m3 = lam * area * coord.potency_tensor(n, n) * 2.0
    del(s1, s2, n)

    # write file
    s = numpy.zeros_like
    i1 = 0
    i2 = 0
    i3 = 0
    for i in range(dt.size):
        n1 = data['nt1'][i]
        n2 = data['nt2'][i]
        n3 = data['nt3'][i]
        s1 = data['sv1'][i1:i1+n1]
        s2 = data['sv2'][i2:i2+n2]
        s3 = data['sv3'][i3:i3+n3]
        t1 = t0[i], t0[i] + dt[i] * (n1 - 1)
        t2 = t0[i], t0[i] + dt[i] * (n2 - 1)
        t3 = t0[i], t0[i] + dt[i] * (n3 - 1)
        s1 = interp.interp1(t1, s1, t, s(t), interp)
        s2 = interp.interp1(t2, s2, t, s(t), interp)
        s3 = interp.interp1(t3, s3, t, s(t), interp)
        ii = numpy.array([[jj[i], kk[i], ll[i]]], 'i')
        mm = numpy.array([
            m1[0, 0, i] * s1 + m2[0, 0, i] * s2 + m3[0, 0, i] * s3,
            m1[0, 1, i] * s1 + m2[0, 1, i] * s2 + m3[0, 1, i] * s3,
            m1[0, 2, i] * s1 + m2[0, 2, i] * s2 + m3[0, 2, i] * s3,
            m1[1, 1, i] * s1 + m2[1, 1, i] * s2 + m3[1, 1, i] * s3,
            m1[1, 0, i] * s1 + m2[1, 0, i] * s2 + m3[1, 0, i] * s3,
            m1[1, 2, i] * s1 + m2[1, 2, i] * s2 + m3[1, 2, i] * s3,
        ])
        if binary:
            mm.astype('f').tofile(fh)
        else:
            numpy.savetxt(fh, ii, '%d')
            numpy.savetxt(fh, mm.T, '%14.6e')
        i1 += n1
        i2 += n2
        i3 += n3
    return


def write_coulomb(path, srf, proj, scut=0):
    """
    Write Coulomb input file.

    path: fine name on disk
    srf: (meta, data) SRF dictionaries
    proj: PyProj map projection instance
    scut: slip-rate below which values are not output
    """

    # slip components
    meta, data = srf
    s1, s2 = data['slip1'], data['slip2']
    s = numpy.sin(math.pi / 180.0 * data['rake'])
    c = numpy.cos(math.pi / 180.0 * data['rake'])
    r1 = -c * s1 + s * s2
    r2 = s * s1 + c * s2

    # coordinates
    x, y, z = data['lon'], data['lat'], data['dep']
    rot = coord.rotation(x, y, proj)[1]
    x, y = proj(x, y)
    x *= 0.001
    y *= 0.001
    z *= 0.001
    delta = 0.0005 * meta['plane'][0]['delta'][0]
    dx = delta * numpy.sin(math.pi / 180.0 * (data['stk'] + rot))
    dy = delta * numpy.cos(math.pi / 180.0 * (data['stk'] + rot))
    dz = delta * numpy.sin(math.pi / 180.0 * data['dip'])
    x1, x2 = x - dx, x + dx
    y1, y2 = y - dy, y + dy
    z1, z2 = z - dz, z + dz

    # source file
    i = (s1 ** 2 + s2 ** 2) > (numpy.sign(scut) * scut**2)
    c = numpy.array([
        x1[i], y1[i],
        x2[i], y2[i],
        r1[i], r2[i],
        data['dip'][i],
        z1[i], z2[i]
    ]).T
    with open(path + 'source.inp', 'w') as fh:
        fh.write(coulomb_header.format(**meta))
        numpy.savetxt(fh, c, coulomb_fmt)
        fh.write(coulomb_footer)

    # receiver file
    s1.fill(0.0)
    c = numpy.array([x1, y1, x2, y2, s1, s1, data['dip'], z1, z2]).T
    with open(path + 'receiver.inp', 'w') as fh:
        fh.write(coulomb_header.format(**meta))
        numpy.savetxt(fh, c, coulomb_fmt)
        fh.write(coulomb_footer)
    return


coulomb_fmt = '  1' + 4*' %10.4f' + ' 100' + 5*' %10.4f' + '    Fault 1'

coulomb_header = """\
header line 1
header line 2
#reg1=  0  #reg2=  0  #fixed=  {nsource}  sym=  1
 PR1=       0.250     PR2=       0.250   DEPTH=      12.209
  E1=     8.000e+005   E2=     8.000e+005
XSYM=       .000     YSYM=       .000
FRIC=          0.400
S1DR=         19.000 S1DP=         -0.010 \
S1IN=        100.000 S1GD=          0.000
S2DR=         89.990 S2DP=         89.990 \
S2IN=         30.000 S2GD=          0.000
S3DR=        109.000 S3DP=         -0.010 \
S3IN=          0.000 S3GD=          0.000

  #   X-start    Y-start     X-fin      Y-fin   Kode  rt.lat  \
  reverse   dip angle     top      bot
xxx xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx xxx xxxxxxxxxx \
xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx
"""

coulomb_footer = """
   Grid Parameters
  1  ----------------------------  Start-x =     -100.0
  2  ----------------------------  Start-y =        0.0
  3  --------------------------   Finish-x =      500.0
  4  --------------------------   Finish-y =      400.0
  5  ------------------------  x-increment =        5.0
  6  ------------------------  y-increment =        5.0
     Size Parameters
  1  --------------------------  Plot size =        2.0
  2  --------------  Shade/Color increment =        1.0
  3  ------  Exaggeration for disp.& dist. =    10000.0

     Cross section default
  1  ----------------------------  Start-x =     -126.4
  2  ----------------------------  Start-y =     -124.6
  3  --------------------------   Finish-x =       40.0
  4  --------------------------   Finish-y =       40.0
  5  ------------------  Distant-increment =        1.0
  6  ----------------------------  Z-depth =       30.0
  7  ------------------------  Z-increment =        1.0
     Map info
  1  ---------------------------- min. lon =     -128.0
  2  ---------------------------- max. lon =     -123.0
  3  ---------------------------- zero lon =     -125.0
  4  ---------------------------- min. lat =       39.5
  5  ---------------------------- max. lat =       42.5
  6  ---------------------------- zero lat =       40.0
"""
