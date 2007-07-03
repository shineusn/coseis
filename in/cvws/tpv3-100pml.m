% TPV3
  np       = [   1   1   2 ];
  np       = [   1   1  16 ];
  nn       = [ 171  96  96 ];
  ihypo    = [  -1  -1  -2 ];
  n1expand = [   0   0   0 ];
  n2expand = [   0   0   0 ];
  bc1      = [  10  10  10 ];
  bc2      = [  -1   1  -2 ];
  fixhypo  =    -1;
  affine   = [ 1. 0. 0.   0. 1. 0.   0. 0. 1. ];
  nt  = 1500;
  dx  = 100;
  dt  = .008;

  vp  = 6000.;
  vs  = 3464.;
  rho = 2670.;
  gam = .1;
  hourglass = [ 1. .7 ];

  faultnormal = 3;
  vrup = -1.;
  dc  = 0.4;
  mud = .525;
  mus = 10000.;
  mus = { .677    'cube' -15001. -7501. -1.  15001. 7501. 1. };
  tn  = -120e6;
  ts1 = -70e6;
  ts1 = { -81.6e6 'cube'  -1501. -1501. -1.   1501. 1501. 1. };

  out = { 'x'    1   1 1 0  0   -1 -1  0  0 };
  out = { 'su'   1   1 1 0 -1   -1 -1  0 -1 };
  out = { 'psv'  1   1 1 0 -1   -1 -1  0 -1 };
  out = { 'trup' 1   1 1 0 -1   -1 -1  0 -1 };
  timeseries = { 'su' -7501.     0. 0. };
  timeseries = { 'sv' -7501.     0. 0. };
  timeseries = { 'ts' -7501.     0. 0. };
  timeseries = { 'su'  7501.     0. 0. };
  timeseries = { 'sv'  7501.     0. 0. };
  timeseries = { 'ts'  7501.     0. 0. };
  timeseries = { 'su'     0. -6001. 0. };
  timeseries = { 'sv'     0. -6001. 0. };
  timeseries = { 'ts'     0. -6001. 0. };
  timeseries = { 'su'     0.  6001. 0. };
  timeseries = { 'sv'     0.  6001. 0. };
  timeseries = { 'ts'     0.  6001. 0. };
