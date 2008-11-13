#!/usr/bin/env python
"""
Remote install and execution
"""

def remote( rsh, dest, command=[] ):
    import os, sys
    cwd = os.getcwd()
    os.chdir( os.path.realpath( os.path.dirname( __file__ ) ) )
    rsync = 'rsync -avR --delete --include=email --exclude-from=.bzrignore -e %r . %r' % ( rsh, dest )
    print dest
    print rsync
    os.system( rsync )
    for cmd in command:
        host = dest.split(':')[0]
        dir = dest.split(':')[1]
        cmd = 'cd %s; %s' % ( dir, cmd )
        cmd = '%s %s "bash --login -c %r"' % ( rsh, host, cmd )
        print cmd
        os.system( cmd )
    os.chdir( cwd )
    return

if __name__ == '__main__':
    import sys
    remote( *sys.argv[1:] )
