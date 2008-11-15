#!/bin/bash -e

mode=%(mode)r
cd %(rundir)r
[ "$mode" = m ] && ./mpd.sh

echo "$( date ): %(code)s started" >> log
%(pre)s
case "$mode${1:--i}" in
    s-i)   time %(bin)s ;;
    s-g)   gdb  %(bin)s ;;
    s-ddd) ddd  %(bin)s ;;
    m-i)   mpiexec -np %(np)s time %(bin)s ;;
    m-g)   mpiexec -np %(np)s -gdb %(bin)s ;;
    m-ddd) mpiexec -np %(np)s ddd  %(bin)s ;;
esac
%(post)s
echo "$( date ): %(code)s finished" >> log
