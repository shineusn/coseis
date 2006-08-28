! Misc utilities
module m_util
implicit none
contains

subroutine zone( i1, i2, nn, nnoff, ihypo, faultnormal )
integer, intent(inout) :: i1(3), i2(3)
integer, intent(in) :: nn(3), nnoff(3), ihypo(3), faultnormal
integer :: i, nshift(3)
logical :: m0(3), m1(3), m2(3), m3(3), m4(3)
nshift = 0
i = abs( faultnormal )
if ( i /= 0 ) nshift(i) = 1
m0 = i1 == 0 .and. i2 == 0
m1 = i1 == 0 .and. i2 /= 0
m2 = i1 /= 0 .and. i2 == 0
m3 = i1 < 0
m4 = i2 < 0
where ( m0 ) i1 = ihypo - nnoff
where ( m0 ) i2 = ihypo - nnoff
where ( m1 ) i1 = ihypo - nnoff + nshift
where ( m2 ) i2 = ihypo - nnoff
where ( m3 ) i1 = i1 + nn + 1
where ( m4 ) i2 = i2 + nn + 1
i1 = max( i1, 1 )
i2 = min( i2, nn )
i1 = i1 + nnoff
i2 = i2 + nnoff
end subroutine

subroutine cube( s, x, i1, i2, x1, x2, r )
real, intent(inout) :: s(:,:,:)
real, intent(in) :: x(:,:,:,:), x1(3), x2(3), r
integer, intent(in) :: i1(3), i2(3)
integer :: j1, k1, l1, j2, k2, l2
j1 = i1(1); j2 = i2(1)
k1 = i1(2); k2 = i2(2)
l1 = i1(3); l2 = i2(3)
where( x(j1:j2,k1:k2,l1:l2,1) >= x1(1) &
 .and. x(j1:j2,k1:k2,l1:l2,2) >= x1(2) &
 .and. x(j1:j2,k1:k2,l1:l2,3) >= x1(3) &
 .and. x(j1:j2,k1:k2,l1:l2,1) <= x2(1) &
 .and. x(j1:j2,k1:k2,l1:l2,2) <= x2(2) &
 .and. x(j1:j2,k1:k2,l1:l2,3) <= x2(3) ) s = r
end subroutine

subroutine sethalo( f, r, i1, i2 )
real, intent(inout) :: f(:,:,:)
real, intent(in) :: r
integer, intent(in) :: i1(3), i2(3)
if ( size( f, 1 ) > 1 ) then
  f(:i1(1)-1,:,:) = r
  f(i2(1)+1:,:,:) = r
end if
if ( size( f, 2 ) > 1 ) then
  f(:,:i1(2)-1,:) = r
  f(:,i2(2)+1:,:) = r
end if
if ( size( f, 3 ) > 1 ) then
  f(:,:,:i1(3)-1) = r
  f(:,:,i2(3)+1:) = r
end if
end subroutine

! Timer
subroutine timer( i, filename, it )
character(*), intent(in), optional :: filename
integer, intent(in), optional :: i, it
integer, save :: clock0, clockrate, clockmax
integer(8), save :: timers(4)
integer :: clock1
if ( .not. present( i ) ) then
  call system_clock( clock0, clockrate, clockmax )
  timers = 0
else
  call system_clock( clock1 )
  timers = timers - clock0 + clock1
  if ( clock0 > clock1 ) timers = timers + clockmax
  clock0 = clock1
  if ( present( it ) ) then
    call rwrite( 'timer/' // filename, real( timers(i) ) / real( clockrate ), it )
  end if
  timers(:i) = 0
end if
end subroutine

! Write stats 
subroutine stats( rr, ii, filename, it )
real, intent(in) :: rr
character(*), intent(in) :: filename
integer, intent(in) :: ii(3), it
call rwrite( 'stats/' // filename, rr, it )
call iwrite( 'stats/' // filename // '1', ii(1), it )
call iwrite( 'stats/' // filename // '2', ii(2), it )
call iwrite( 'stats/' // filename // '3', ii(3), it )
end subroutine

! Write integer binary timeseries
subroutine iwrite( filename, val, it )
character(*), intent(in) :: filename
integer, intent(in) :: val, it
integer :: i
inquire( iolength=i ) val
if ( it == 1 ) then
  open( 1, file=filename, recl=i, form='unformatted', access='direct', status='replace' )
else
  open( 1, file=filename, recl=i, form='unformatted', access='direct', status='old' )
end if
write( 1, rec=it ) val
close( 1 )
end subroutine

! Write real binary timeseries
subroutine rwrite( filename, val, it )
character(*), intent(in) :: filename
real, intent(in) :: val
integer, intent(in) :: it
integer :: i
inquire( iolength=i ) val
if ( it == 1 ) then
  open( 1, file=filename, recl=i, form='unformatted', access='direct', status='replace' )
else
  open( 1, file=filename, recl=i, form='unformatted', access='direct', status='old' )
end if
write( 1, rec=it ) val
close( 1 )
end subroutine
  
end module
