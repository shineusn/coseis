! SORD - main program
program sord

! Modules
use m_inread
use m_setup
use m_arrays
use m_checkpoint
use m_gridgen
use m_material
use m_output_subs
use m_output_init
use m_output
use m_pml
use m_stress
use m_momentsource
use m_acceleration
use m_fault_init
use m_fault
use m_locknodes
use m_timestep

! Initialization
call clock
call initialize( ip, np0, master )
call inread
call setup
if ( master ) write( 0, * ) 'SORD - Support Operator Rupture Dynamics'
call arrays            ; if ( master ) call clock( '0ini', 1 )
call gridgen           ; if ( master ) call clock( '0ini', 2 )
call material          ; if ( master ) call clock( '0ini', 3 )
call pml
call momentsource_init
call fault_init        ; if ( master ) call clock( '0ini', 4 )
call output_init       ; if ( master ) call clock( '0ini', 5 )
call readcheckpoint    ; if ( master ) call clock( '0ini', 6 )

! Main loop
if ( master ) write( 0, * ) 'Main loop'
do while ( it < nt )
  call clock
  call timestep        ; if ( master ) call clock( '1tst', it )
  call stress          ; if ( master ) call clock( '2str', it )
  call momentsource
  call output( 1 )     ; if ( master ) call clock( '3out', it )
  call acceleration    ; if ( master ) call clock( '4acc', it )
  call fault           ; if ( master ) call clock( '5flt', it )
  call locknodes
  call output( 2 )     ; if ( master ) call clock( '6out', it )
  call writecheckpoint ; if ( master ) call clock( '7ckp', it )
  if ( master ) then
    write( 0, '(a)', advance='no' ) '.'
    if ( it == nt .or. mod( it, 50 ) == 0 ) write( 0, '(i6)' ) it
  end if
end do

! Finish up
if ( master ) write( 0, * ) 'Finished!'
call finalize

end program

