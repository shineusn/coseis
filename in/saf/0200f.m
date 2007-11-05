% SAF 200 m - fault
% np(2) = 1:43, 56, 76, 80, 94, 108, 116, 126, 188, 301, 376, 501, 751, 1502
  datadir = 'saf/cvm3/0200';
  datadir = 'saf/cvm4/0200';
  itio = 500; itcheck = 0; itstats = 10;
  nt =  7500;
  nt = 15000;
  np = [ 1 501 4 ] % DS 251/265
  np = [ 1 376 4 ] % DS 188/265
  np = [ 1  94 4 ] % TG 188/256
  np = [ 1 126 4 ] % TG 252/256
  x1    = { 'read' 'zone' 1 1 1   -1 -1 1 };
  x2    = { 'read' 'zone' 1 1 1   -1 -1 1 };
% x3    = 'read';
  rho   = 'read';
  vp    = 'read'; vp1  = 1500.;
  vs    = 'read'; vs1  = 500.;
  vdamp = 400.;   gam2 = 0.8;
  bc1   = [ 10 10 10 ];
  bc2   = [ 10 10  0 ];
  fixhypo = 1; faultnormal = 2; slipvector = [ 1. 0. 0. ];
  mus = 1000.;
  mud = 0.5;
  dc  = 0.5;
  tn  = -20e6;
  ts1 = 'read';
  rcrit = 3000.; vrup = 2300.;

  dx = 200.; dt = 0.012; trelax = 0.12;
  nn    = [ 3001 1502 401 ];
  ihypo = [ 1362  997 -26 ];
  ihypo = [ 2266  997 -26 ];
  mus = [ 1.10 'zone'  1317   0 -81        2311   0 -1      ];
  out = { 'x'      1   1317 997 -81    0   2311 997 -1    0 };
  out = { 'rho'    1   1317   0 -81    0   2311   0 -1    0 };
  out = { 'vp'     1   1317   0 -81    0   2311   0 -1    0 };
  out = { 'vs'     1   1317   0 -81    0   2311   0 -1    0 };
  out = { 'gam'    1   1317   0 -81    0   2311   0 -1    0 };
  out = { 'gamt'   1   1317   0 -81    0   2311   0 -1    0 };
  out = { 'tn'    10   1317   0 -81    0   2311   0 -1 7500 };
  out = { 'tsm'   10   1317   0 -81    0   2311   0 -1 7500 };
  out = { 'sl'    10   1317   0 -81    0   2311   0 -1 7500 };
  out = { 'svm'   10   1317   0 -81    0   2311   0 -1 7500 };
  out = { 'psv'   10   1317   0 -81    0   2311   0 -1 7500 };
  out = { 'trup'   1   1317   0 -81 7500   2311   0 -1 7500 };
  out = { 'x'      1      1   1  -1    0     -1  -1 -1    0 };
  out = { 'rho'    1      1   1  -2    0     -1  -1 -1    0 };
  out = { 'vp'     1      1   1  -2    0     -1  -1 -1    0 };
  out = { 'vs'     1      1   1  -2    0     -1  -1 -1    0 };
  out = { 'pv2' 2500      1   1  -1 7500     -1  -1 -1   -1 };
  out = { 'pv2'    1      1   1  -1 7500     -1  -1 -1 7500 };
  out = { 'v' 1    408  966 -1 0    408  966 -1 -1 }; % Bakersfield
  out = { 'v' 1    498  346 -1 0    498  346 -1 -1 }; % Santa Barbara
  out = { 'v' 1    761  407 -1 0    761  407 -1 -1 }; % Oxnard
  out = { 'v' 1    951  961 -1 0    951  961 -1 -1 }; % Lancaster
  out = { 'v' 1   1079  589 -1 0   1079  589 -1 -1 }; % Westwood
  out = { 'v' 1   1142  642 -1 0   1142  642 -1 -1 }; % Los Angeles
  out = { 'v' 1   1205  668 -1 0   1205  668 -1 -1 }; % Montebello
  out = { 'v' 1   1262  532 -1 0   1262  532 -1 -1 }; % Long Beach
  out = { 'v' 1   1278 1341 -1 0   1278 1341 -1 -1 }; % Barstow
  out = { 'v' 1   1307 1141 -1 0   1307 1141 -1 -1 }; % Victorville
  out = { 'v' 1   1345  840 -1 0   1345  840 -1 -1 }; % Ontario
  out = { 'v' 1   1384  620 -1 0   1384  620 -1 -1 }; % Santa Ana
  out = { 'v' 1   1457  960 -1 0   1457  960 -1 -1 }; % San Bernardino
  out = { 'v' 1   1476  852 -1 0   1476  852 -1 -1 }; % Riverside
  out = { 'v' 1   1763  469 -1 0   1763  469 -1 -1 }; % Oceanside
  out = { 'v' 1   1842  940 -1 0   1842  940 -1 -1 }; % Palm Springs
  out = { 'v' 1   2028  979 -1 0   2028  979 -1 -1 }; % Coachella
  out = { 'v' 1   2015  324 -1 0   2015  324 -1 -1 }; % San Diego
  out = { 'v' 1   2510  151 -1 0   2510  151 -1 -1 }; % Ensenada
  out = { 'v' 1   2642  813 -1 0   2642  813 -1 -1 }; % Mexicali
  out = { 'v' 1   2910 1121 -1 0   2910 1121 -1 -1 }; % Yuma
