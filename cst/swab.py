"""
Swap byte order.
"""
import os
import sys
import numpy as np


def swab(src, dst, verbose=True, dtype='f', block=64*1024*1024):
    nb = np.dtype(dtype).itemsize
    n = os.path.getsize(src)
    if n == 0 or n % nb != 0:
        return
    n //= nb
    f0 = open(src, 'rb')
    f1 = open(dst, 'wb')
    i = 0
    while i < n:
        b = min(n-i, block)
        r = np.fromfile(f0, dtype=dtype, count=b)
        r.byteswap(True).tofile(f1)
        i += b
        if verbose:
            sys.stdout.write('\r%s %3d%%' % (dst, 100.0 * i / n))
            sys.stdout.flush()
    if verbose:
        print('')
    return


def main(args, *kw):
    for f in args:
        swab(f, f + '.swab', **kw)