"""
SCEC Community Velocity Model (CVM-H) tools.
"""
import os
import urllib
import tarfile
import numpy
from . import home
from . import data
from . import vm1d
from . import gocad
from . import interp

repository = home + 'repo'
projection = {'proj': 'utm', 'zone': 11, 'datum': 'NAD27', 'ellps': 'clrk66'}
extent = (131000.0, 828000.0), (3431000.0, 4058000.0), (-200000.0, 4900.0)
prop2d = {'topo': '1', 'base': '2', 'moho': '3'}
prop3d = {'vp': '1', 'vs': '3', 'tag': '2'}
versions = ['vx62', 'vx63', '11.2.0', '11.9.0']
voxet3d = {'mantle': 'CVM_CM', 'crust': 'CVM_LR', 'lab': 'CVM_HR'}


def vs30_model(x, y, version='Wills+Wald', method='nearest'):
    if version not in ['Wills', 'Wald', 'Wills+Wald']:
        raise Exception()
    if 'Wald' in version:
        z = data.vs30_wald(x, y, method=method)
    else:
        z = numpy.empty_like(x)
        z.fill(float('nan'))
    if 'Wills' in version:
        delta = 0.000439344930055
        x0 = -121.12460921883338
        y0 = 32.53426695497164
        f = repository + 'Vs30-Wills-CVMH.npy'
        w = numpy.load(f, mmap_mode='c')
        xlim = x0, x0 + delta * (w.shape[0] - 1)
        ylim = y0, y0 + delta * (w.shape[1] - 1)
        extent = xlim, ylim
        interp.interp2(extent, w, (x, y), z, method=method)
    return z


def nafe_drake(f):
    """
    Density derived from V_p via Nafe-Drake curve, Brocher (2005) eqn 1.
    """
    f *= 0.001
    f = f * (
        1.6612 - f * (0.4721 - f * (0.0671 - f * (0.0043 - f * 0.000106))))
    f = numpy.maximum(f, 1.0) * 1000.0
    return f


def brocher_vp(f):
    """
    V_p derived from V_s via Brocher (2005) eqn 9.
    """
    f *= 0.001
    f = 0.9409 + f * (2.0947 - f * (0.8206 - f * (0.2683 - f * 0.0251)))
    f *= 1000.0
    return f


def ely_vp(f):
    """
    V_p derived from V_s via Ely (2012).
    """
    f = 400.0 + 1.4 * f
    return f


def cvmh_voxet(prop=None, voxet=None, no_data_value=None, version=None):
    """
    Download and read SCEC CVM-H voxet.

    Parameters:

    prop:
        2d property: 'topo', 'base', or 'moho'
        3d property: 'Vp', 'Vs', or 'tag'
    voxet:
        3d voxet: 'mantle', 'crust', or 'lab'
    no_data_value: None, 'nan', or float value. None = filled from below.
    version: 'vx62', 'vx63', '11.2.0', '11.9.0' or None (default)

    Returns:

    extent: (x0, x1), (y0, y1), (z0, z1)
    data: Array of properties
    """

    if version is None:
        version = versions[-1]
    path = repository + 'CVMH-%s' % version
    if version[:2] == 'vx':
        u = 'http://structure.harvard.edu/cvm-h/download/%s.tar.bz2'
        f = path + '.bztar'
        base = '%s/bin'
    else:
        u = 'http://hypocenter.usc.edu/research/cvmh/11.9.0/cvmh-%s.tar.gz'
        f = path + '.tgz'
        base = 'cvmh-%s/model'
    u %= version
    base %= version

    # download if not found
    if not os.path.exists(path):
        if not os.path.exists(f):
            print('Downloading %s' % u)
            urllib.urlretrieve(u, f)
        print('Extracting %s' % f)
        tar = tarfile.open(f)
        os.mkdir(path)
        with tar as tar:
            for t in tar:
                if not t.name.startswith(base):
                    continue
                if t.name.endswith('.vo') or t.name.endswith('@@'):
                    f = os.path.join(path, os.path.split(t.name)[1])
                    open(f, 'wb').write(tar.extractfile(t).read())

    # fill 3d voxets
    turd = os.path.join(path, 'filled')
    if not os.path.exists(turd):
        for vox in voxet3d:
            print('Filling voxet %s %s' % (version, vox))
            vp, vs, tag = prop3d['vp'], prop3d['vs'], prop3d['tag']
            vid = voxet3d[vox]
            voxfile = os.path.join(path, vid + '.vo')
            vox = gocad.voxet(voxfile, [vp, vs, tag])['1']
            w = vox['AXIS']['W'][2]
            d1 = vox['PROP'][vp]['DATA']
            d2 = vox['PROP'][vs]['DATA']
            d3 = vox['PROP'][tag]['DATA']
            v1 = vox['PROP'][vp]['NO_DATA_VALUE']
            v2 = vox['PROP'][vs]['NO_DATA_VALUE']
            n = d1.shape[2]
            if w > 0.0:
                for i in range(1, n):
                    ii = (d1[:, :, i] == v1) | (d2[:, :, i] == v2)
                    d1[:, :, i][ii] = d1[:, :, i-1][ii]
                    d2[:, :, i][ii] = d2[:, :, i-1][ii]
                    d3[:, :, i][ii] = d3[:, :, i-1][ii]
            else:
                for i in range(n-1, 0, -1):
                    ii = (d1[:, :, i-1] == v1) | (d2[:, :, i-1] == v2)
                    d1[:, :, i-1][ii] = d1[:, :, i][ii]
                    d2[:, :, i-1][ii] = d2[:, :, i][ii]
                    d3[:, :, i-1][ii] = d3[:, :, i][ii]
            f1 = os.path.join(path, vox['PROP'][vp]['FILE'] + '-filled')
            f2 = os.path.join(path, vox['PROP'][vs]['FILE'] + '-filled')
            f3 = os.path.join(path, vox['PROP'][tag]['FILE'] + '-filled')
            d1.T.tofile(f1)
            d2.T.tofile(f2)
            d3.T.tofile(f3)
            open(turd, 'w')

    # voxet ID
    if voxet in voxet3d:
        vid = voxet3d[voxet]
    else:
        vid = 'interfaces'
    voxfile = os.path.join(path, vid + '.vo')

    # load voxet
    if prop is None:
        return gocad.voxet(voxfile)
    prop = prop.lower()
    if prop in prop2d:
        pid = prop2d[prop]
    else:
        pid = prop3d[prop]
    if no_data_value is None and prop in prop3d:
        vox = gocad.voxet(voxfile, [pid], alternate='-filled')['1']
    else:
        vox = gocad.voxet(voxfile, [pid], no_data_value=no_data_value)['1']

    # extent
    x, y, z = vox['AXIS']['O']
    u, v, w = vox['AXIS']['U'][0], vox['AXIS']['V'][1], vox['AXIS']['W'][2]
    extent = (x, x + u), (y, y + v), (z, z + w)

    # property data
    data = vox['PROP'][pid]['DATA']
    return extent, data


class Model():
    """
    SCEC CVM-H model.

    Init parameters:

    prop:
        2d property: 'topo', 'base', 'moho'
        3d property: 'vp', 'vs', or 'tag'
    voxet:
        3d voxet list: ['mantle', 'crust', 'lab']
    no_data_value: None or float value (can be float('nan').
        None = filled from below.
    version: 'vx62', 'vx63', '11.2.0', 11.9.0' or None (default)

    Call parameters:

    x, y, z: Sample coordinate arrays.
    out: Optional output array with same shape as coordinate arrays.
    interpolation: 'nearest', or 'linear'

    Returns property samples at coordinates (x, y, z)
    """
    def __init__(
        self, prop, voxet=['mantle', 'crust'], no_data_value=None, version=None
    ):
        self.prop = prop = prop.lower()
        if prop in prop2d:
            self.voxet = [cvmh_voxet(prop, version=version)]
        else:
            self.voxet = []
            for i in voxet:
                self.voxet += [cvmh_voxet(prop, i, no_data_value, version)]
        return

    def __call__(self, x, y, z=None, out=None, interpolation='nearest'):
        if out is None:
            out = numpy.empty_like(x)
            out.fill(float('nan'))
        for extent, v in self.voxet:
            if z is None:
                v = v.reshape(v.shape[:2])
                interp.interp2(extent[:2], v, (x, y), out, interpolation)
            else:
                interp.interp3(extent, v, (x, y, z), out, interpolation)
        return out


class Extraction():
    """
    CVM-H extraction with geotechnical layer (GTL)

    Init parameters:

    x, y: Coordinates arrays
    vm: 'vp', 'vs', 'tag', or Model object.
    vs30: 'Wills', 'Wald', 'Wills+Wald', None, or Model object.
    topo: 'topo' or Model object.
    interpolation: 'nearest', or 'linear'.
    geographic: X Y coordinate type, True for geographic, False for UTM.
    **kwargs: Keyword arguments passed to Model()

    Call parameters

    z: Vertical coordinate array.
    out: Optional output array, same shape as coordinate arrays.
    min_depth: Minimum depth in Z array, optional but provides speed-up.
    by_depth: Z coordinate type, True for depth, False for elevation.

    Returns property samples at coordinates (x, y, z)
    """

    def __init__(
        self, x, y, vm,
        vs30='Wills+Wald',
        topo='topo',
        interpolation='nearest',
        geographic=True,
        **kwargs
    ):
        x = numpy.asarray(x)
        y = numpy.asarray(y)
        if isinstance(vm, str):
            vm = Model(vm, **kwargs)
        if vm.prop in prop2d:
            raise Exception('Cannot extract 2D model')
        elif vm.prop == 'tag':
            vs30 = None
        if isinstance(topo, str):
            topo = Model(topo, **kwargs)
        if geographic:
            import pyproj
            lon, lat = x, y
            proj = pyproj.Proj(**projection)
            x, y = proj(lon, lat)
            x = x.astype(lon.dtype)
            y = y.astype(lat.dtype)
        z0 = topo(x, y, interpolation='linear')
        if vs30 is None:
            zt = None
        else:
            zt = 350.0
            if not geographic:
                import pyproj
                proj = pyproj.Proj(**projection)
                lon, lat = proj(x, y, inverse=True)
                lon = lon.astype(x.dtype)
                lat = lat.astype(y.dtype)
            v0 = vs30_model(lon, lat, vs30)
            if vm.prop == 'vp':
                v0 = ely_vp(v0)
            vt = vm(x, y, z0 - zt, interpolation=interpolation)
            v0 = numpy.minimum(vt, v0)  # XXX new feature
            if numpy.isnan(vt).any():
                print('WARNING: NaNs in GTL')
            self.gtl = v0, vt
        self.x, self.y, self.z0, self.zt = x, y, z0, zt
        self.vm, self.interpolation = vm, interpolation
        return

    def __call__(self, z, out=None, min_depth=None, by_depth=True):
        x, y, z0, zt = self.x, self.y, self.z0, self.zt
        vm, interpolation = self.vm, self.interpolation
        z = numpy.asarray(z)
        if out is None:
            out = numpy.empty_like(z)
            out.fill(float('nan'))
        if by_depth is False:
            vm(x, y, z, out, interpolation)
            z = z0 - z
        else:
            vm(x, y, z0 - z, out, interpolation)
        if zt:
            if min_depth is None:
                min_depth = z.min()
            if min_depth < zt:
                v0, vt = self.gtl
                i = z < zt
                out[i] = vm1d.v30gtl(v0, vt, z, zt)[i]
        return out


def extract(x, y, z, vm=['rho', 'vp', 'vs'], by_depth=True, **kwargs):
    """
    Simple CVM-H extraction.

    x, y, z: Coordinates arrays
    vm: 'rho', 'vp', 'vs', 'tag', or Model object.
    by_depth: Z coordinate type, True for depth, False for elevation.
    **kwargs: Keyword arguments passed to Extraction()

    Returns property samples at coordinates (x, y, z)
    """
    x = numpy.asarray(x)
    y = numpy.asarray(y)
    if not isinstance(vm, (list, tuple)):
        vm = [vm]
    out = []
    f = None
    for v in vm:
        prop = v = v.lower()
        if v == 'rho':
            prop = 'vp'
        if not out or prop != f.vm.prop:
            f = Extraction(x, y, prop, **kwargs)
        if v == 'rho':
            out += [nafe_drake(f(z, by_depth=by_depth))]
        else:
            out += [f(z, by_depth=by_depth)]
    return numpy.array(out)
