"""
NICS Kraken

EPD version: rh3-x86_64
Compute nodes require statically-compiled Python.
See extras/intall/python-install-cnl.sh

/lustre/scratch/$USER
module
showusage
qsub -l debugging
showbf
alias showme='showq | sed -n "/JOBID/p; /--/p; /^ /p; /$USER/p"'

vim .bashrc

Home directories have a 2 GB quota.
CrayPAT (Cray Performance Analysis Tools) is useful for profiling and
collecting hardware performance data

account: TG-MCA03S012
"""
login = 'kraken-pwd.nics.utk.edu'
hosts = 'kraken-pwd3', 'kraken-pwd4'
maxcores = 12
maxram = 15000
maxnodes = 8256
maxtime = 24, 00
rate = 1e6 # just a guess
launch = {
    's_exec':  '%(command)s',
    's_debug': 'gdb %(command)s',
    'submit':  'qsub "%(name)s.sh"',
    'submit2': 'qsub -W depend="afterok:%(depend)s" "%(name)s.sh"',
}
python = '/lustre/scratch/proj/yt_common/trunk/bin/python'
fortran_serial = 'ftn',
fortran_mpi = 'ftn',
fortran_flags = {
    'f': ('-Mdclchk',),
    'g': ('-Ktrap=fp', '-Mbounds', '-Mchkptr', '-g'),
    't': ('-Ktrap=fp', '-Mbounds'),
    'p': ('-pg', '-Mprof=func'),
    'O': ('-fast',),
    '8': ('-Mr8',),
}
cvm_ = dict(
    fortran_flags = {
        'g': ('-Ktrap=fp', '-Mbounds', '-Mchkptr', '-g'),
        'O': ('-fast',),
    },
)

