! acceleration calculation
module acceleration
implicit none
contains

subroutine step_accel
use globals
use diff_cn_op
use hourglass_op
use kinematic_source
use boundary_cond
use dynamic_rupture
use utilities
use input_output
use statistics
use process
integer :: i1(3), i2(3), i, j, k, l, ic, iid, id, iq, p

! init
call set_halo(s1, 0.0, i1node, i2node)

! loop over component and derivative direction
doic: do ic  = 1, 3
doid: do iid = 1, 3; id = modulo(ic + iid - 2, 3) + 1

! elastic region
! f_i = w_ij,j
i1 = i1node
i2 = i2node
if (ic == id) then
    call diff_cn(s1, w1, ic, id, i1, i2, xx, dx)
else
    i = 6 - ic - id
    call diff_cn(s1, w2, i, id, i1, i2, xx, dx)
end if

! pml region
! p'_ij + d_j*p_ij = w_ij,j (no summation convention)
! f_i = sum_j(p_ij')
select case (id)
case (1)
    do j = i1(1), min(i2(1), i1pml(1))
        i = j - i1(1) + 1
        p = j + nnoff(1)
        do l = i1(3), i2(3)
        do k = i1(2), i2(2)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p1(i,k,l,ic)
            p1(i,k,l,ic) = p1(i,k,l,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
    do j = max(i1(1), i2pml(1)), i2(1)
        i = i2(1) - j + 1
        p = nn(1) - j - nnoff(1) + 1
        do l = i1(3), i2(3)
        do k = i1(2), i2(2)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p4(i,k,l,ic)
            p4(i,k,l,ic) = p4(i,k,l,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
case (2)
    do k = i1(2), min(i2(2), i1pml(2))
        i = k - i1(2) + 1
        p = k + nnoff(2)
        do l = i1(3), i2(3)
        do j = i1(1), i2(1)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p2(j,i,l,ic)
            p2(j,i,l,ic) = p2(j,i,l,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
    do k = max(i1(2), i2pml(2)), i2(2)
        i = i2(2) - k + 1
        p = nn(2) - k - nnoff(2) + 1
        do l = i1(3), i2(3)
        do j = i1(1), i2(1)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p5(j,i,l,ic)
            p5(j,i,l,ic) = p5(j,i,l,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
case (3)
    do l = i1(3), min(i2(3), i1pml(3))
        i = l - i1(3) + 1
        p = l + nnoff(3)
        do k = i1(2), i2(2)
        do j = i1(1), i2(1)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p3(j,k,i,ic)
            p3(j,k,i,ic) = p3(j,k,i,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
    do l = max(i1(3), i2pml(3)), i2(3)
        i = i2(3) - l + 1
        p = nn(3) - l - nnoff(3) + 1
        do k = i1(2), i2(2)
        do j = i1(1), i2(1)
            s1(j,k,l) = dn2(p) * s1(j,k,l) + dn1(p) * p6(j,k,i,ic)
            p6(j,k,i,ic) = p6(j,k,i,ic) + dt * s1(j,k,l)
        end do
        end do
    end do
end select

! add contribution to force vector
if (ic == id) then
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        w1(j,k,l,ic) = s1(j,k,l)
    end do
    end do
    end do
    !$omp end parallel do
else
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        w1(j,k,l,ic) = w1(j,k,l,ic) + s1(j,k,l)
    end do
    end do
    end do
    !$omp end parallel do
end if

end do doid
end do doic

! hourglass control. only viscous in pml
if (any(hourglass > 0.0)) then
call set_halo(s1, 0.0, i1cell, i2cell)
call set_halo(s2, 0.0, i1node, i2node)
do i = 1, 3
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        w2(j,k,l,i) = hourglass(1) * uu(j,k,l,i) + dt * hourglass(2) * vv(j,k,l,i)
    end do
    end do
    end do
    !$omp end parallel do
end do
do iq = 1, 4
do ic = 1, 3
    i1 = max(i1pml,     i1cell)
    i2 = min(i2pml - 1, i2cell)
    call hourglass_nc(s1, w2, iq, ic, i1, i2)
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        s1(j,k,l) = s1(j,k,l) * yy(j,k,l)
    end do
    end do
    end do
    !$omp end parallel do
    i1 = max(i1pml + 1, i1node)
    i2 = min(i2pml - 1, i2node)
    call hourglass_cn(s2, s1, iq, i1, i2)
    if (hourglass(2) > 0.0 .and. npml > 0) then
        do i = 1, 3
            i1 = i1cell
            i2 = i2cell
            i2(i) = min(i2(i), i1pml(i))
            call hourglass_nc(s1, vv, iq, ic, i1, i2)
            do l = i1(3), i2(3)
            do k = i1(2), i2(2)
            do j = i1(1), i2(1)
                s1(j,k,l) = dt * hourglass(2) * yy(j,k,l) * s1(j,k,l)
            end do
            end do
            end do
            i1 = i1cell
            i2 = i2cell
            i1(i) = max(i1(i), i2pml(i) - 1)
            call hourglass_nc(s1, vv, iq, ic, i1, i2)
            do l = i1(3), i2(3)
            do k = i1(2), i2(2)
            do j = i1(1), i2(1)
                s1(j,k,l) = dt * hourglass(2) * yy(j,k,l) * s1(j,k,l)
            end do
            end do
            end do
        end do
        do i = 1, 3
            i1 = i1node
            i2 = i2node
            i2(i) = min(i2(i), i1pml(i))
            call hourglass_cn(s2, s1, iq, i1, i2)
            i1 = i1node
            i2 = i2node
            i1(i) = max(i1(i), i2pml(i))
            call hourglass_cn(s2, s1, iq, i1, i2)
        end do
    end if
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        w1(j,k,l,ic) = w1(j,k,l,ic) - s2(j,k,l)
    end do
    end do
    end do
    !$omp end parallel do
end do
end do
end if

! add source to force
if (source == 'force') then
    call finite_source
end if

! nodal force input
call field_io('<', 'fx', w1(:,:,:,1))
call field_io('<', 'fy', w1(:,:,:,2))
call field_io('<', 'fz', w1(:,:,:,3))

! boundary conditions
call vector_bc(w1, bc1, bc2, i1bc, i2bc)

! spontaneous rupture
call step_rupture

! swap halo
if (sync) call barrier
timers(1) = clock()
call vector_swap_halo(w1, nhalo)
timers(1) = clock() - timers(1)

! nodal force output
call field_io('>', 'fx', w1(:,:,:,1))
call field_io('>', 'fy', w1(:,:,:,2))
call field_io('>', 'fz', w1(:,:,:,3))

! Newton's law: a_i = f_i / m
do i = 1, 3
    !$omp parallel do schedule(static) private(j, k, l)
    do l = 1, nm(3)
    do k = 1, nm(2)
    do j = 1, nm(1)
        w1(j,k,l,i) = w1(j,k,l,i) * mr(j,k,l)
    end do
    end do
    end do
    !$omp end parallel do
end do

! acceleration I/O
call field_io('<>', 'ax', w1(:,:,:,1))
call field_io('<>', 'ay', w1(:,:,:,2))
call field_io('<>', 'az', w1(:,:,:,3))
if (modulo(it, itstats) == 0) then
    call vector_norm(s1, w1, i1core, i2core, (/1, 1, 1/))
    call set_halo(s1, -1.0, i1core, i2core)
    amaxloc = maxloc(s1)
    amax = s1(amaxloc(1),amaxloc(2),amaxloc(3))
end if
call field_io('>', 'am2', s1)

end subroutine

end module

