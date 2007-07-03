! Collective routines - MPI version
module m_collective
use m_globals, only: nz
implicit none
!integer, private, parameter :: nz = 100
integer, private :: ip, ip3(3), np(3), root3d, root2d(3), comm3d, comm2d(3), filehandles(64+6*nz)
contains

! Initialize
subroutine initialize( np0, master )
use mpi
integer, intent(out) :: np0
logical, intent(out) :: master
integer :: ip0, e
call mpi_init( e )
call mpi_comm_size( mpi_comm_world, np0, e  )
call mpi_comm_rank( mpi_comm_world, ip0, e  )
master = .false.
if ( ip0 == 0 ) master = .true.
end subroutine

! Finalize
subroutine finalize
use mpi
integer :: e
call mpi_finalize( e )
end subroutine

! Process rank
subroutine rank( ipout, ip3out, npin )
use mpi
integer, intent(out) :: ipout, ip3out(3)
integer, intent(in) :: npin(3)
integer :: e
logical :: period(3) = .false.
np = npin
call mpi_cart_create( mpi_comm_world, 3, np, period, .true., comm3d, e )
if ( comm3d == mpi_comm_null ) then
  write( 0, * ) 'Unused process:', ip
  call mpi_finalize( e )
  stop
end if
call mpi_comm_rank( comm3d, ip, e  )
call mpi_cart_coords( comm3d, ip, 3, ip3, e )
ipout = ip
ip3out = ip3
filehandles = mpi_undefined
end subroutine

! Set root process and creat 2D communicators
subroutine setroot( ip3root )
use mpi
integer, intent(in) :: ip3root(3)
integer :: ip2root(2), e, i
logical :: hat(3)
call mpi_cart_rank( comm3d, ip3root, root3d, e )
root2d = 0
comm2d = mpi_comm_self
do i = 1, 3
if ( product( (/ np(:i-1), np(i+1:) /) ) > 1 ) then
  hat = .true.
  hat(i) = .false.
  call mpi_cart_sub( comm3d, hat, comm2d(i), e )
  ip2root = (/ ip3root(:i-1), ip3root(i+1:) /)
  call mpi_cart_rank( comm2d(i), ip2root, root2d(i), e )
end if
end do
end subroutine

! Broadcast real 1d
subroutine rbroadcast1( r )
use mpi
real, intent(inout) :: r(:)
integer :: i, e
i = size(r)
call mpi_bcast( r, i, mpi_real, root3d, comm3d, e )
end subroutine

! Barrier
subroutine barrier
use mpi
integer :: e
call mpi_barrier( comm3d, e )
end subroutine

! Reduce integer
subroutine ireduce( ii, i, op, i2d )
use mpi
integer, intent(out) :: ii
integer, intent(in) :: i, i2d
character(*), intent(in) :: op
integer :: iop, comm, root, e
select case( op )
case( 'min', 'allmin' ); iop = mpi_min
case( 'max', 'allmax' ); iop = mpi_max
case( 'sum', 'allsum' ); iop = mpi_sum
case default; stop
end select
comm = comm3d
root = root3d
if ( i2d /= 0 ) then
  comm = comm2d(i2d)
  root = root2d(i2d)
end if
if ( op(1:3) == 'all' ) then
  call mpi_allreduce( i, ii, 1, mpi_integer, iop, comm, e )
else
  call mpi_reduce( i, ii, 1, mpi_integer, iop, root, comm, e )
end if
end subroutine

! Reduce real
subroutine rreduce( rr, r, op, i2d )
use mpi
real, intent(out) :: rr
real, intent(in) :: r
integer, intent(in) :: i2d
character(*), intent(in) :: op
integer :: iop, comm, root, e
select case( op )
case( 'min', 'allmin' ); iop = mpi_min
case( 'max', 'allmax' ); iop = mpi_max
case( 'sum', 'allsum' ); iop = mpi_sum
case default; stop
end select
comm = comm3d
root = root3d
if ( i2d /= 0 ) then
  comm = comm2d(i2d)
  root = root2d(i2d)
end if
if ( op(1:3) == 'all' ) then
  call mpi_allreduce( r, rr, 1, mpi_real, iop, comm, e )
else
  call mpi_reduce( r, rr, 1, mpi_real, iop, root, comm, e )
end if
end subroutine

! Reduce real 1d
subroutine rreduce1( rr, r, op, i2d )
use mpi
real, intent(out) :: rr(:)
real, intent(in) :: r(:)
integer, intent(in) :: i2d
character(*), intent(in) :: op
integer :: iop, root, comm, e, i
select case( op )
case( 'min', 'allmin' ); iop = mpi_min
case( 'max', 'allmax' ); iop = mpi_max
case( 'sum', 'allsum' ); iop = mpi_sum
case default; stop
end select
comm = comm3d
root = root3d
if ( i2d /= 0 ) then
  comm = comm2d(i2d)
  root = root2d(i2d)
end if
i = size(r)
if ( op(1:3) == 'all' ) then
  call mpi_allreduce( r(1), rr(1), i, mpi_real, iop, comm, e )
else
  call mpi_reduce( r(1), rr(1), i, mpi_real, iop, root, comm, e )
end if
end subroutine

! Reduce real 2d
subroutine rreduce2( rr, r, op, i2d )
use mpi
real, intent(out) :: rr(:,:)
real, intent(in) :: r(:,:)
integer, intent(in) :: i2d
character(*), intent(in) :: op
integer :: iop, comm, root, e, i
select case( op )
case( 'min', 'allmin' ); iop = mpi_min
case( 'max', 'allmax' ); iop = mpi_max
case( 'sum', 'allsum' ); iop = mpi_sum
case default; stop
end select
comm = comm3d
root = root3d
if ( i2d /= 0 ) then
  comm = comm2d(i2d)
  root = root2d(i2d)
end if
i = size(r)
if ( op(1:3) == 'all' ) then
  call mpi_allreduce( r(1,1), rr(1,1), i, mpi_real, iop, comm, e )
else
  call mpi_reduce( r(1,1), rr(1,1), i, mpi_real, iop, root, comm, e )
end if
end subroutine

! Reduce extrema location, real 3d
subroutine reduceloc( rr, ii, r, op, n, noff, i2d )
use mpi
double precision :: local(2), global(2)
real, intent(out) :: rr
real, intent(in) :: r(:,:,:)
integer, intent(out) :: ii(3)
integer, intent(in) :: n(3), noff(3), i2d
character(*), intent(in) :: op
integer(8) :: nn(3), i
integer :: iop, comm, root, e
select case( op )
case( 'min', 'allmin' ); ii = minloc( r ); iop = mpi_minloc
case( 'max', 'allmax' ); ii = maxloc( r ); iop = mpi_maxloc
case default; stop
end select
comm = comm3d
root = root3d
if ( i2d /= 0 ) then
  comm = comm2d(i2d)
  root = root2d(i2d)
end if
rr = r(ii(1),ii(2),ii(3))
ii = ii - 1 + noff
i = ii(1) + n(1) * ( ii(2) + n(2) * ii(3) )
local(1) = rr
local(2) = i
if ( op(1:3) == 'all' ) then
  call mpi_allreduce( local, global, 1, mpi_2double_precision, iop, comm, e )
else
  call mpi_reduce( local, global, 1, mpi_2double_precision, iop, root, comm, e )
end if
rr = global(1)
i = global(2)
nn = n
ii(3) = i / ( n(1) * n(2) )
ii(2) = modulo( i / nn(1), nn(2) )
ii(1) = modulo( i, nn(1) )
ii = ii + 1 - noff
end subroutine

! Scalar swap halo
subroutine scalarswaphalo( f, nh )
use mpi
real, intent(inout) :: f(:,:,:)
integer, intent(in) :: nh(3)
integer :: i, e, prev, next, nm(3), n(3), isend(3), irecv(3), tsend, trecv, comm
nm = (/ size(f,1), size(f,2), size(f,3) /)
do i = 1, 3
if ( np(i) > 1 .and. nm(i) > 1 ) then
  comm = comm3d
  call mpi_cart_shift( comm, i-1, 1, prev, next, e )
  n = nm
  n(i) = nh(i)
  isend = 0
  irecv = 0
  isend(i) = nm(i) - 2 * nh(i)
  call mpi_type_create_subarray( 3, nm, n, isend, mpi_order_fortran, mpi_real, tsend, e )
  call mpi_type_create_subarray( 3, nm, n, irecv, mpi_order_fortran, mpi_real, trecv, e )
  call mpi_type_commit( tsend, e )
  call mpi_type_commit( trecv, e )
  call mpi_sendrecv( f(1,1,1), 1, tsend, next, 0, f(1,1,1), 1, trecv, prev, 0, comm, mpi_status_ignore, e )
  call mpi_type_free( tsend, e )
  call mpi_type_free( trecv, e )
  isend(i) = nh(i)
  irecv(i) = nm(i) - nh(i)
  call mpi_type_create_subarray( 3, nm, n, isend, mpi_order_fortran, mpi_real, tsend, e )
  call mpi_type_create_subarray( 3, nm, n, irecv, mpi_order_fortran, mpi_real, trecv, e )
  call mpi_type_commit( tsend, e )
  call mpi_type_commit( trecv, e )
  call mpi_sendrecv( f(1,1,1), 1, tsend, prev, 1, f(1,1,1), 1, trecv, next, 1, comm, mpi_status_ignore, e )
  call mpi_type_free( tsend, e )
  call mpi_type_free( trecv, e )
end if
end do
end subroutine

! Vector swap halo
subroutine vectorswaphalo( f, nh )
use mpi
real, intent(inout) :: f(:,:,:,:)
integer, intent(in) :: nh(3)
integer :: i, e, prev, next, nm(4), n(4), isend(4), irecv(4), tsend, trecv, comm
nm = (/ size(f,1), size(f,2), size(f,3), size(f,4) /)
do i = 1, 3
if ( np(i) > 1 .and. nm(i) > 1 ) then
  comm = comm3d
  call mpi_cart_shift( comm, i-1, 1, prev, next, e )
  n = nm
  n(i) = nh(i)
  isend = 0
  irecv = 0
  isend(i) = nm(i) - 2 * nh(i)
  call mpi_type_create_subarray( 4, nm, n, isend, mpi_order_fortran, mpi_real, tsend, e )
  call mpi_type_create_subarray( 4, nm, n, irecv, mpi_order_fortran, mpi_real, trecv, e )
  call mpi_type_commit( tsend, e )
  call mpi_type_commit( trecv, e )
  call mpi_sendrecv( f(1,1,1,1), 1, tsend, next, 0, f(1,1,1,1), 1, trecv, prev, 0, comm, mpi_status_ignore, e )
  call mpi_type_free( tsend, e )
  call mpi_type_free( trecv, e )
  isend(i) = nh(i)
  irecv(i) = nm(i) - nh(i)
  call mpi_type_create_subarray( 4, nm, n, isend, mpi_order_fortran, mpi_real, tsend, e )
  call mpi_type_create_subarray( 4, nm, n, irecv, mpi_order_fortran, mpi_real, trecv, e )
  call mpi_type_commit( tsend, e )
  call mpi_type_commit( trecv, e )
  call mpi_sendrecv( f(1,1,1,1), 1, tsend, prev, 1, f(1,1,1,1), 1, trecv, next, 1, comm, mpi_status_ignore, e )
  call mpi_type_free( tsend, e )
  call mpi_type_free( trecv, e )
end if
end do
end subroutine

! Timer series input/output
subroutine rio1( id, mpio, str, ft, ir, nr )
use m_util
use mpi
real, intent(inout) :: ft(:)
integer, intent(in) :: id, mpio, ir, nr
character(*), intent(in) :: str
integer :: i, nl(1), n(1), i0(1), ftype, fh, e
integer(kind=mpi_offset_kind) :: ir0 = 0
nl = size( ft )
if ( id == 0 .or. nl(1) == 0 ) return
if ( ir < nl(1) .or. ir > nr ) stop 'error in rio1'
if ( mpio == 0 ) then
  call frio1( id, str, ft, ir )
  return
end if
i = abs( id )
fh = filehandles(i)
if ( fh == mpi_undefined ) then
  if ( id < 0 ) then
    i = mpi_mode_rdonly
  elseif ( ir == nl(1) ) then
    i = mpi_mode_wronly + mpi_mode_create
  else
    i = mpi_mode_wronly
  end if
  i0 = ir - nl
  n  = nr
  write( 0, '(a,i7,2a)' ) ' Opening 1D file on proc', ip, ': ', trim(str)
  call mpi_file_set_errhandler( mpi_file_null, mpi_errors_are_fatal, e )
  call mpi_file_open( mpi_comm_self, str, i, mpi_info_null, fh, e )
  call mpi_type_create_subarray( 1, n, nl, i0, mpi_order_fortran, mpi_real, ftype, e )
  call mpi_type_commit( ftype, e )
  call mpi_file_set_view( fh, ir0, mpi_real, ftype, 'native', mpi_info_null, e )
  i = abs( id )
  filehandles(i) = fh
end if
if ( id < 0 ) then
  call mpi_file_read( fh, ft(1), nl(1), mpi_real, mpi_status_ignore, e )
else
  call mpi_file_write( fh, ft(1), nl(1), mpi_real, mpi_status_ignore, e )
end if
if ( ir == nr ) then
  i = abs( id )
  filehandles(i) = mpi_undefined
  call mpi_file_close( fh, e )
end if
end subroutine

! Scalar field component input/output
subroutine rio3( id, mpio, r, str, s1, i1, i2, i3, i4, ir, nr )
use m_util
use mpi
real, intent(inout) :: r, s1(:,:,:)
integer, intent(in) :: id, mpio, i1(3), i2(3), i3(3), i4(3), ir, nr
character(*), intent(in) :: str
integer :: i, fh, mtype, nl(3), n(3), i0(3), e
if ( id == 0 ) return
if ( id > 0 .and. all( i1 == i2 ) ) then
  r = s1(i1(1),i1(2),i1(3))
  return
end if
if ( mpio == 0 ) then
  call frio3( id, str, s1, i3, i4, ir )
  return
end if
i = abs( id )
fh = filehandles(i)
if ( fh == mpi_undefined ) then
  call mpopen( fh, id, mpio, str, i1, i2, i3, i4, ir, nr )
  if ( any( i3 > i4 ) ) return
  filehandles(i) = fh
end if
if ( any( i3 > i4 ) ) stop 'error in rio3'
i0 = i3 - 1
nl = i4 - i3 + 1
n = (/ size(s1,1), size(s1,2), size(s1,3) /)
call mpi_type_create_subarray( 3, n, nl, i0, mpi_order_fortran, mpi_real, mtype, e )
call mpi_type_commit( mtype, e )
if ( id < 0 ) then
  call mpi_file_read_all( fh, s1(1,1,1), 1, mtype, mpi_status_ignore, e )
else
  call mpi_file_write_all( fh, s1(1,1,1), 1, mtype, mpi_status_ignore, e )
end if
if ( ir == nr ) then
  i = abs( id )
  filehandles(i) = mpi_undefined
  call mpi_file_close( fh, e )
end if
call mpi_type_free( mtype, e )
end subroutine

! Vector field component input/output
subroutine rio4( id, mpio, r, str, w1, ic, i1, i2, i3, i4, ir, nr )
use m_util
use mpi
real, intent(inout) :: r, w1(:,:,:,:)
integer, intent(in) :: id, mpio, ic, i1(3), i2(3), i3(3), i4(3), ir, nr
character(*), intent(in) :: str
integer :: i, fh, mtype, nl(3), n(3), i0(3), e
if ( id == 0 ) return
if ( id > 0 .and. all( i1 == i2 ) ) then
  r = w1(i1(1),i1(2),i1(3),ic)
  return
end if
if ( mpio == 0 ) then
  call frio4( id, str, w1, ic, i3, i4, ir )
  return
end if
i = abs( id )
fh = filehandles(i)
if ( fh == mpi_undefined ) then
  call mpopen( fh, id, mpio, str, i1, i2, i3, i4, ir, nr )
  if ( any( i3 > i4 ) ) return
  filehandles(i) = fh
end if
if ( any( i3 > i4 ) ) stop 'error in rio4'
i0 = i3 - 1
nl = i4 - i3 + 1
n = (/ size(w1,1), size(w1,2), size(w1,3) /)
call mpi_type_create_subarray( 3, n, nl, i0, mpi_order_fortran, mpi_real, mtype, e )
call mpi_type_commit( mtype, e )
if ( id < 0 ) then
  call mpi_file_read_all( fh, w1(1,1,1,ic), 1, mtype, mpi_status_ignore, e )
else
  call mpi_file_write_all( fh, w1(1,1,1,ic), 1, mtype, mpi_status_ignore, e )
end if
if ( ir == nr ) then
  i = abs( id )
  filehandles(i) = mpi_undefined
  call mpi_file_close( fh, e )
end if
call mpi_type_free( mtype, e )
end subroutine

! Open file with MPIIO
subroutine mpopen( fh, id, mpio, str, i1, i2, i3, i4, ir, nr )
use mpi
integer, intent(in) :: id, mpio, i1(3), i2(3), i3(3), i4(3), ir, nr
integer, intent(out) :: fh
character(*), intent(in) :: str
integer :: i, iio, nio, ndims, ftype, nl(4), n(4), i0(4), comm0, comm, e
integer(kind=mpi_offset_kind) :: ir0 = 0
i = abs( mpio )
comm0 = comm3d
if ( i < 4 ) comm0 = comm2d(i)
if ( any( i3 > i4 ) ) then
  call mpi_comm_split( comm0, mpi_undefined, 0, comm, e )
  fh = mpi_file_null
  return
end if
i = abs( id )
call mpi_comm_split( comm0, i, 0, comm, e )
call mpi_comm_rank( comm, iio, e  )
call mpi_comm_size( comm, nio, e  )
if ( id < 0 ) then
  i = mpi_mode_rdonly
elseif ( ir == 1 ) then
  i = mpi_mode_wronly + mpi_mode_create
else
  i = mpi_mode_wronly
end if
call mpi_file_set_errhandler( mpi_file_null, mpi_errors_are_fatal, e )
call mpi_file_open( comm, str, i, mpi_info_null, fh, e )
i0 = (/ i3 - i1    , ir - 1  /)
n  = (/ i2 - i1 + 1, nr /)
nl = (/ i4 - i3 + 1, nr - ir + 1 /)
ndims = 4
do i = ndims, 1, -1 ! squeeze singleton dimentions
if ( n(i) == 1 ) then
  ndims = ndims - 1
  i0(i:) = (/ i0(i+1:), 0 /)
  n(i:)  = (/ n(i+1:),  1 /)
  nl(i:) = (/ nl(i+1:), 1 /)
end if
end do
if ( iio == 0 ) write( 0, '(a,i2,a,i6,2a)' ) &
  ' Opening', ndims, 'D file on', nio, ' procs: ', trim(str)
if ( mpio > 0 ) then ! collapes dimension if all on one proc
  do i = 1, ndims-1
  if ( n(i) == nl(i) ) then
    ndims = ndims - 1
    i0(i:) = (/ i0(i)+n(i)*i0(i+1), i0(i+2:), 0 /)
    n(i:)  = (/ n(i)*n(i+1),        n(i+2:),  1 /)
    nl(i:) = (/ nl(i)*nl(i+1),      nl(i+2:), 1 /)
    exit ! only do this once to prevent 32 bit overrun
  end if
  end do
end if
if ( ndims < 1 ) ndims = 1
call mpi_type_create_subarray( ndims, n, nl, i0, mpi_order_fortran, mpi_real, ftype, e )
call mpi_type_commit( ftype, e )
call mpi_file_set_view( fh, ir0, mpi_real, ftype, 'native', mpi_info_null, e )
end subroutine

end module

