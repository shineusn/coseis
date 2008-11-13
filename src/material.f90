! Material model
module m_material
implicit none
contains

subroutine material
use m_globals
use m_collective
use m_util
use m_fieldio
real :: stats(8), gstats(8), r, rr(3), rho_, vp_, vs_, gam_, courant
integer :: i1(3), i2(3)

if ( master ) write( 0, * ) 'Material model'

! Init
mr = 0.
s1 = 0.
s2 = 0.
gam = 0.

! Inputs
call fieldio( '<', 'rho', mr  )
call fieldio( '<', 'vp',  s1  )
call fieldio( '<', 'vs',  s2  )
call fieldio( '<', 'gam', gam )

! Test for endian problems
if ( any( mr  /= mr  ) .or. maxval( mr  ) > huge( r ) ) stop 'NaN/Inf in rho'
if ( any( s1  /= s1  ) .or. maxval( s1  ) > huge( r ) ) stop 'NaN/Inf in vp'
if ( any( s2  /= s2  ) .or. maxval( s2  ) > huge( r ) ) stop 'NaN/Inf in vs'
if ( any( gam /= gam ) .or. maxval( gam ) > huge( r ) ) stop 'NaN/Inf in gam'

! Limits
if ( rho1 > 0. ) mr = max( mr, rho1 )
if ( rho2 > 0. ) mr = min( mr, rho2 )
if ( vp1  > 0. ) s1 = max( s1, vp1 )
if ( vp2  > 0. ) s1 = min( s1, vp2 )
if ( vs1  > 0. ) s2 = max( s2, vs1 )
if ( vs2  > 0. ) s2 = min( s2, vs2 )

! Velocity dependent viscosity
if ( vdamp > 0. ) then
  gam = s2
  call invert( gam )
  gam = gam * vdamp
end if

! Limits
if ( gam1 > 0. ) gam = max( gam, gam1 )
if ( gam2 > 0. ) gam = min( gam, gam2 )

! Averages
stats = 0.
i1 = max( i1core, i1bc )
i2 = min( i2core, i2bc - 1 )
call scalar_set_halo( mr,  0., i1, i2 )
call scalar_set_halo( s1,  0., i1, i2 )
call scalar_set_halo( s2,  0., i1, i2 )
call scalar_set_halo( gam, 0., i1, i2 )
stats(1) = sum( mr  )
stats(2) = sum( s1  )
stats(3) = sum( s2  )
stats(4) = sum( gam )
call rreduce1( gstats, stats, 'sum', 0 )
rr = nn - 1
r = 1. / product( nn - 1 ) 
rho_ = r * gstats(1)
vp_  = r * gstats(2)
vs_  = r * gstats(3)
gam_ = r * gstats(4)

! Fill halo
call scalar_swap_halo( mr,  nhalo )
call scalar_swap_halo( s1,  nhalo )
call scalar_swap_halo( s2,  nhalo )
call scalar_swap_halo( gam, nhalo )

! Extrema
call scalar_set_halo( mr,  huge(r), i1cell, i2cell )
call scalar_set_halo( s1,  huge(r), i1cell, i2cell )
call scalar_set_halo( s2,  huge(r), i1cell, i2cell )
call scalar_set_halo( gam, huge(r), i1cell, i2cell )
stats(1) = -minval( mr  )
stats(2) = -minval( s1  )
stats(3) = -minval( s2  )
stats(4) = -minval( gam )
call scalar_set_halo( mr,  0., i1cell, i2cell )
call scalar_set_halo( s1,  0., i1cell, i2cell )
call scalar_set_halo( s2,  0., i1cell, i2cell )
call scalar_set_halo( gam, 0., i1cell, i2cell )
stats(5) = maxval( mr  )
stats(6) = maxval( s1  )
stats(7) = maxval( s2  )
stats(8) = maxval( gam )
call rreduce1( gstats, stats, 'allmax', 0 )
rho1 = -gstats(1)
vp1  = -gstats(2)
vs1  = -gstats(3)
gam1 = -gstats(4)
rho2 =  gstats(5)
vp2  =  gstats(6)
vs2  =  gstats(7)
gam2 =  gstats(8)

! Stats
if ( master ) then
  courant = dt * vp2 * sqrt( 3. ) / abs( dx )
  open( 1, file='stats/material.py', status='replace' )
  write( 1, "( 'courant = ',g15.7 )" ) courant
  write( 1, "( 'rho_    = ',g15.7 )" ) rho_
  write( 1, "( 'rho1    = ',g15.7 )" ) rho1
  write( 1, "( 'rho2    = ',g15.7 )" ) rho2
  write( 1, "( 'vp_     = ',g15.7 )" ) vp_
  write( 1, "( 'vp1     = ',g15.7 )" ) vp1
  write( 1, "( 'vp2     = ',g15.7 )" ) vp2
  write( 1, "( 'vs_     = ',g15.7 )" ) vs_
  write( 1, "( 'vs1     = ',g15.7 )" ) vs1
  write( 1, "( 'vs2     = ',g15.7 )" ) vs2
  write( 1, "( 'gam_    = ',g15.7 )" ) gam_
  write( 1, "( 'gam1    = ',g15.7 )" ) gam1
  write( 1, "( 'gam2    = ',g15.7 )" ) gam2
  close( 1 )
end if

! Lame' parameters
mu  = mr * s2 * s2
lam = mr * ( s1 * s1 ) - 2. * mu

! Hourglass constant
yy = 12. * ( lam + 2. * mu )
call invert( yy )
yy = yy * dx * mu * ( lam + mu )
!yy = .3 / 16. * ( lam + 2. * mu ) * dx ! like Ma & Liu, 2006

! Output
call fieldio( '>', 'rho', mr  )
call fieldio( '>', 'vp',  s1  )
call fieldio( '>', 'vs',  s2  )
call fieldio( '>', 'gam', gam )
call fieldio( '>', 'mu',  mu  )
call fieldio( '>', 'lam', lam )

end subroutine

!------------------------------------------------------------------------------!

! Calculate PML damping parameters
subroutine pml
use m_globals
integer :: i
real :: hmean, tune, c1, c2, c3, damp, dampn, dampc, pmlp

if ( npml < 1 ) return
c1 =  8. / 15.
c2 = -3. / 100.
c3 =  1. / 1500.
tune = 3.5
pmlp = 2.
!hmean = 2. * vp1 * vp2 / ( vp1 + vp2 )
hmean = 2. * vs1 * vs2 / ( vs1 + vs2 )
damp = tune * hmean / dx * ( c1 + ( c2 + c3 * npml ) * npml ) / npml ** pmlp
do i = 1, npml
  dampn = damp *   i ** pmlp
  dampc = damp * ( i ** pmlp + ( i - 1 ) ** pmlp ) / 2.
  dn1(npml-i+1) = - 2. * dampn        / ( 2. + dt * dampn )
  dc1(npml-i+1) = ( 2. - dt * dampc ) / ( 2. + dt * dampc )
  dn2(npml-i+1) =   2.                / ( 2. + dt * dampn )
  dc2(npml-i+1) =   2. * dt           / ( 2. + dt * dampc )
end do

end subroutine

end module
