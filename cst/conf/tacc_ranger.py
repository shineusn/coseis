"""
TACC Ranger: Sun Constellation Linux Cluster

ranger.tacc.utexas.edu
http://www.tacc.utexas.edu/services/userguides/ranger/

EPD version: rh3-x86_64
mvapich2 supports MPI2, but not recommended for more than 2048 tasks.

.profile_user:
module unload mvapich pgi
module load intel mvapich
module load git

.bashrc:
export PATH=/share/home/00967/gely/local/python/bin:${PATH}
export PATH=${HOME}/coseis/bin:${PATH}
export PYTHONPATH=${HOME}/coseis
alias qme='showq -u'
alias qdev='idev -minutes 120'

useful:
gsiftp://gridftp.ranger.tacc.teragrid.org:2811/
cat /share/sge/default/tacc/sge_esub_control
qconf -sql
lfs quota -u $USER $HOME
lfs quota -u $USER $WORK
lfs quota -u $USER $SCRATCH

needed?
module load gotoblas scalapack mkl
export F77=ifort
export F90=ifort
export F77=pgf95
export F90=pgf95
"""

core_range = [1, 2, 4, 8, 12, 15, 16]
maxram = 32768
#rate = 21e5
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

f2py_flags = '--fcompiler=intelem'
compiler_c = 'mpicc'
compiler_f = 'mpif90'
compiler_opts = {
    'pgi': {
        'f': '-Mdclchk',
        'g': '-Ktrap=fp -Mbounds -g',
        't': '-Ktrap=fp -Mbounds',
        'p': '-fast -tp barcelona-64 -Mprof=func',
        'O': '-fast -tp barcelona-64',
        '8': '-Mr8',
    },
     'intel': {
        'f': '-u -std03 -warn',
        'g': '-CB -traceback -g',
        't': '-CB -traceback',
        'p': '-O -pg',
        'O': '-O2 -xW',
        '8': '-r8',
    },
    'sun': {
        'f': '-u',
        'g': '-C -ftrap=common -w4 -g',
        't': '-C -ftrap=common',
        'p': '-O -pg',
        'O': '-fast -fns',
    },  
}

launch = {
    's_exec':  '{command}',
    's_debug': 'gdb {command}',
    'm_exec':  'ibrun {command}',
    'm_iexec': 'ibrun -n {nproc} -o 0 {command}',
    'm_debug': 'ddt -start -once -n {nproc} -- {command}',
    'submit':  'qsub "{name}.sh"',
    'submit2': 'qsub -hold_jid "{depend}" "{name}.sh"',
}

