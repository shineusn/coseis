"""
TACC Ranger: Sun Constellation

.bashrc:
export PATH=/share/home/00967/gely/local/python/bin:${PATH}
export PATH=${HOME}/coseis/bin:${PATH}
export PYTHONPATH=${HOME}/coseis

.profile_user:
module unload mvapich pgi
module load intel mvapich
module load git
"""

# MPI
nthread = 1
ppn_range = [1, 2, 4, 8, 12, 15, 16]
build_flags = '-warn -O2 -xW'
launch = 'ibrun -n {nproc} -o 0 {command}'
launch = 'ibrun {command}'

# MPI + OpenMP
nthread = 16
ppn_range = [1]
build_flags = '-warn -O2 -xW -openmp'
launch = 'ibrun -n {nproc} -o 0 {command}'
launch = 'ibrun {command}'

# compiler options
f2py_flags = '--fcompiler=intelem'
build_cc = 'mpicc'
build_fc = 'mpif90 -u -std03'
build_ld = 'mpif90'
build_prof = '-g -pg'
build_debug = '-g -CB -traceback'
build_real8 = '-r8'

# job submission
submit = 'qsub "{name}.sh"'
submit2 = 'qsub -hold_jid "{depend}" "{name}.sh"'

# machine properties
maxcores = 16
maxram = 32768
rate = 12e5
queue_opts = [
    ('development', {'maxnodes': 16,   'maxtime':  120}),
    ('normal',      {'maxnodes': 256,  'maxtime': 1440}),
    ('large',       {'maxnodes': 1024, 'maxtime': 1440}),
    ('long',        {'maxnodes': 256,  'maxtime': 2880}),
    ('serial',      {'maxnodes': 1,    'maxtime':  120}),
    ('vis',         {'maxnodes': 2,    'maxtime': 1440}),
    ('request', {}),
]

