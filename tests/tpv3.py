#!/usr/bin/env python
"""
TPV3 - SCEC validation problem version 3
"""

import sord

debug = 0
np = 1, 1, 32
np = 1, 1, 2
np = 1, 1, 1
_reg = 1
_dx = 50., 100., 200.
_dx = ( 100., )
vrup = -1.
faultnormal = 3	
hourglass = 1., 2.

for dx in _dx:
    dt = dx / 12500.
    nt = int( 12. / dt + 1.5 )
    nn = ( 
        int( 17500. / dx + 1.5 ),
        int( 10000. / dx + 1.5 ),
        int(  6400. / dx + 0.5 ),
    )
    bc1     =    10,    10, 10
    bc2     = -_reg,  _reg, -2
    ihypo   = -_reg, -_reg, -2
    fixhypo = -_reg

    _j, _k, _l = ihypo
    _jj = -int( 15000. / dx + 1.5 ),        -1
    _kk = -int(  7500. / dx + 1.5 ),        -1
    _ll = -int(  4000. / dx + 1.5 ),        -1
    _oo = -int(  1500. / dx + 1.5 ),        -1
    _xx = -int(  1500. / dx - 0.5 ) - _reg, -1

    fieldio = [
        ( '=',  'rho',  [],                2670.    ),
        ( '=',  'vp',   [],                6000.    ),
        ( '=',  'vs',   [],                3464.    ),
        ( '=',  'gam',  [],                0.2      ),
        ( '=',  'gam',  [_jj,_kk,_ll,0],   0.02     ),
       #( '=c', 'gam',  [],                0.677 (-15001.,-7501.,-4000.), (15001.,7501.,4000.) ),
        ( '=',  'dc',   [],                0.4      ),
        ( '=',  'mud',  [],                0.525    ),
        ( '=',  'mus',  [],                1.0e4    ),
        ( '=',  'mus',  [_jj,_kk,_l, 0],   0.677    ),
       #( '=c', 'mus',  [],                0.677 (-15001.,-7501.,-1.), (15001.,7501.,1.) ),
        ( '=',  'tn',   [],               -120e6    ),
        ( '=',  'ts',   [],                 70e6    ),
        ( '=',  'ts',   [_oo,_oo,_l, 0],  72.9e6    ),
        ( '=',  'ts',   [_xx,_oo,_l, 0],  75.8e6    ),
        ( '=',  'ts',   [_oo,_xx,_l, 0],  75.8e6    ),
        ( '=',  'ts',   [_xx,_xx,_l, 0],  81.6e6    ),
       #( '=c', 'ts',   [],               72.9e6 (-1501.,-1501.,-1.), (1501.,1501.,1.) ),
       #( '=c', 'ts',   [],               75.8e6 (-1501.,-1499.,-1.), (1501.,1499.,1.) ),
       #( '=c', 'ts',   [],               75.8e6 (-1499.,-1501.,-1.), (1499.,1501.,1.) ),
       #( '=c', 'ts',   [],               81.6e6 (-1499.,-1499.,-1.), (1499.,1499.,1.) ),
        ( '=w', 'x1',   [_jj,_kk,_l, 0], 'flt_x1'   ),
        ( '=w', 'x2',   [_jj,_kk,_l, 0], 'flt_x2'   ),
        ( '=w', 'tsm',  [_jj,_kk,_l, 1], 'flt_tsm0' ),
        ( '=w', 'tsm',  [_jj,_kk,_l,-1], 'flt_tsm'  ),
        ( '=w', 'su1',  [_jj,_kk,_l,-1], 'flt_su1'  ),
        ( '=w', 'su2',  [_jj,_kk,_l,-1], 'flt_su2'  ),
        ( '=w', 'psv',  [_jj,_kk,_l,-1], 'flt_psv'  ),
        ( '=w', 'trup', [_jj,_kk,_l,-1], 'flt_trup' ),
        ( '=w', 'tnm',  [_jj,_k, _l, 0], 'xt_tnm'   ),
        ( '=w', 'tsm',  [_jj,_k, _l, 0], 'xt_tsm'   ),
        ( '=w', 'sam',  [_jj,_k, _l, 0], 'xt_sam'   ),
        ( '=w', 'svm',  [_jj,_k, _l, 0], 'xt_svm'   ),
        ( '=w', 'sl',   [_jj,_k, _l, 0], 'xt_sl'    ),
    ]

    for _f in 'su1', 'su2', 'sv1', 'sv2', 'ts1', 'ts2':
        fieldio += [
            ( '=wx', _f, [], 'P1a_'+_f, (-7499., -1.,0.) ),
            ( '=wx', _f, [], 'P1b_'+_f, (-7451.,-49.,0.) ),
            ( '=wx', _f, [], 'P2a_'+_f, ( -1.,-5999.,0.) ),
            ( '=wx', _f, [], 'P2b_'+_f, (-49.,-5951.,0.) ),
        ]

    sord.run( locals() )

