! Fault boundary condition
module m_fault
implicit none
contains

subroutine fault
use m_globals
use m_collectiveio
use m_bc
integer :: i1(3), i2(3), i, j1, k1, l1, j2, k2, l2, j3, k3, l3, j4, k4, l4

! If the two sides of the fault are split accross domains, than we must retrieve
! the correct solution from the processor that contains both sides. Corrisponding
! sends are below.
if ( ifn == 0 ) then
  i = abs( faultnormal )
  if ( i /= 0 ) then
     if ( ibc1(i) == 9 .and. ihypo(i) == 0 ) then
       i1 = 1
       i2 = nm
       i1(i) = 1
       i2(i) = 1
       call vectorrecv( w1, i1, i2, -i )
     elseif ( ibc2(i) == 9 .and. ihypo(i) == nm(i) ) then
       i1 = 1
       i2 = nm
       i1(i) = nm(i)
       i2(i) = nm(i)
       call vectorrecv( w1, i1, i2, i )
     end if
  end if
  return
end if

! Indices
i1 = 1
i2 = nm
i1(ifn) = ihypo(ifn)
i2(ifn) = ihypo(ifn)
j1 = i1(1); j2 = i2(1)
k1 = i1(2); k2 = i2(2)
l1 = i1(3); l2 = i2(3)
i1(ifn) = ihypo(ifn) + 1
i2(ifn) = ihypo(ifn) + 1
j3 = i1(1); j4 = i2(1)
k3 = i1(2); k4 = i2(2)
l3 = i1(3); l4 = i2(3)

! Zero slip velocity condition
f1 = dt * area * ( mr(j1:j2,k1:k2,l1:l2) + mr(j3:j4,k3:k4,l3:l4) )
where ( f1 /= 0. ) f1 = 1. / f1
do i = 1, 3
  t3(:,:,:,i) = t0(:,:,:,i) + f1 * &
    ( v(j3:j4,k3:k4,l3:l4,i) + dt * w1(j3:j4,k3:k4,l3:l4,i) &
    - v(j1:j2,k1:k2,l1:l2,i) - dt * w1(j1:j2,k1:k2,l1:l2,i) )
end do

! Decompose traction to normal and shear components
tn = sum( t3 * nhat, 4 )
do i = 1, 3
  t1(:,:,:,i) = tn * nhat(:,:,:,i)
end do
t2 = t3 - t1
ts = sqrt( sum( t2 * t2, 4 ) )

! Slip-weakening friction law
where ( tn > 0. ) tn = 0.
f1 = mud
where ( sl < dc ) f1 = f1 + ( 1. - sl / dc ) * ( mus - mud )
f1 = -tn * f1 + co

! Nucleation
if ( rcrit > 0. .and. vrup > 0. ) then
  f2 = 1.
  if ( trelax > 0. ) f2 = min( ( t - rhypo / vrup ) / trelax, 1. )
  f2 = ( 1. - f2 ) * ts + f2 * ( -tn * mud + co )
  where ( rhypo < min( rcrit, t * vrup ) .and. f2 < f1 ) f1 = f2
end if

! Shear traction bounded by friction
f2 = f1
f1 = 1.
where ( ts > f2 ) f1 = f2 / ts
do i = 1, 3
  t2(:,:,:,i) = f1 * t2(:,:,:,i)
end do

! Total traction
t3 = t1 + t2

! Save for output
tn = sum( t3 * nhat, 4 )
ts = f1 * ts

! Update acceleration
do i = 1, 3
  f1 = area * ( t3(:,:,:,i) - t0(:,:,:,i) )
  w1(j1:j2,k1:k2,l1:l2,i) = w1(j1:j2,k1:k2,l1:l2,i) + f1 * mr(j1:j2,k1:k2,l1:l2)
  w1(j3:j4,k3:k4,l3:l4,i) = w1(j3:j4,k3:k4,l3:l4,i) - f1 * mr(j3:j4,k3:k4,l3:l4)
end do
call vectorbc( w1, ibc1, ibc2, nhalo )

! Work
t1 = u(j3:j4,k3:k4,l3:l4,:) - u(j1:j2,k1:k2,l1:l2,:)
r = .5 * sum( sum( ( t0(j1:j2,k1:k2,l1:l2,:) + t3(j1:j2,k1:k2,l1:l2,:) ) &
  * t1(j1:j2,k1:k2,l1:l2,:), 4 ) * area(j1:j2,k1:k2,l1:l2) )
call psum( work, r, ifn )

! Save slip acceleration for output
t1 = w1(j3:j4,k3:k4,l3:l4,:) - w1(j1:j2,k1:k2,l1:l2,:)
f1 = sqrt( sum( t1 * t1, 4 ) )

! If a neighboring processor contains only one side of the fault, then we must
! send the correct fault wall solution to it.
i = ifn
if ( ibc1(i) == 9 .and. ihypo(i) == 2 * nhalo ) then
  i1 = 1
  i2 = nm
  i1(i) = 2 * nhalo
  i2(i) = 2 * nhalo
  call vectorsend( w1, i1, i2, -i )
elseif ( ibc2(i) == 9 .and. ihypo(i) == nm(i) - 2 * nhalo ) then
  i1 = 1
  i2 = nm
  i1(i) = nm(i) - 2 * nhalo + 1
  i2(i) = nm(i) - 2 * nhalo + 1
  call vectorsend( w1, i1, i2, i )
end if

end subroutine

end module

