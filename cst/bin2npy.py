"""
Convert binary files to NumPy .npy format.

Data types will be read from file 'meta.json' if it exists, or specified with
command line options:
"""
import os
import json
import numpy as np


def main(filenames, dtype='f', shape=[]):
    for fn in filenames:
        t = dtype
        n = shape
        p = ['.'] + os.path.split(fn)
        while p:
            f = os.sep.join(p + ['meta.json'])
            g = os.sep.join(p + ['meta', 'meta.json'])
            if os.path.exists(f):
                m = json.load(open(f))
            elif os.path.exists(g):
                m = json.load(open(g))
            else:
                continue
            if 'dtype' in m:
                t = m['dtype']
            if 'shapes' in m and fn in m['shapes']:
                n = m['shape'][fn]
            elif 'shape' in m:
                n = m['shape']
            break
        if fn.endswith('.bin'):
            f = fn[:-4] + '.npy'
        else:
            f = fn + '.npy'
        if os.path.exists(f):
            return
        x = np.fromfile(fn, t)
        if n:
            x = x.reshape(n[::-1]).T
        print('%s: %s %s' % (fn, t, x.shape))
        np.save(g, x)