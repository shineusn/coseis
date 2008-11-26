#!/usr/bin/env python
"""
Print statistics of 32bit float binary files
"""
import os, sys, numpy

block = 64*1024*1024
try:
    endian = open( 'endian', 'r' ).read()
    dtype = numpy.dtype( numpy.float32 ).newbyteorder( endian )
except:
    dtype = numpy.float32

print '        Min          Max         Mean            N'
for f in sys.argv[1:]:
    fh = file( f, 'r' )
    r = numpy.fromstring( fh.read( block ), dtype=dtype )
    rsum = 0.
    rmin = numpy.inf
    rmax = -numpy.inf
    while r.nbytes:
        rsum += r.sum()
        rmin = min( rmin, r.min() )
        rmax = max( rmax, r.max() )
        r = numpy.fromstring( fh.read( block ), dtype=dtype )
    n = os.path.getsize(f) / r.itemsize
    print '%11g  %11g  %11g  %11d %s' % ( rmin, rmax, rsum/n, n, f )
