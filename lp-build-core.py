#!/usr/bin/python

import os
import time

from datetime import datetime
from launchpadlib.launchpad import Launchpad

# basic data
arches = ['amd64', 'i386', 'armhf', 'arm64', 'ppc64el', 's390x']
series = 'xenial'

# basic paths
results_file = os.getenv('RESULTS_FILE', default='built_architectures.txt')
common = os.getenv('SNAP_COMMON')
workdir = os.path.join(common, 'core-builds')

# we need to store credentials once for cronned builds
cachedir = os.path.join(workdir, 'cache')
creds = os.path.join(workdir, 'credentials')

# log in
launchpad = Launchpad.login_with('Ubuntu Core Builds',
                                 'production', cachedir,
                                 credentials_file=creds,
                                 version='devel')

# get snappy-dev team data and ppa
snappydev = launchpad.people['snappy-dev']
imageppa = snappydev.getPPAByName(name='image')

# get snap
ubuntucore = launchpad.snaps.getByName(name='core',
                                       owner=snappydev)

# get distro info
ubuntu = launchpad.distributions['ubuntu']
release = ubuntu.getSeries(name_or_version=series)

# print a stamp
stamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
print('Trying to trigger builds at: {}'.format(stamp))

# loop over arches and trigger builds
mybuilds = []
for buildarch in arches:
    arch = release.getDistroArchSeries(archtag=buildarch)
    request = ubuntucore.requestBuild(archive=imageppa,
                                      distro_arch_series=arch,
                                      pocket='Proposed')
    buildid = str(request).rsplit('/', 1)[-1]
    mybuilds.append(buildid)
    print('Arch: {} is building under: {}'.format(buildarch, request))

# check the status each minute until all builds have finished
failures = []
while len(mybuilds):
    for build in mybuilds:
        try:
            response = ubuntucore.getBuildSummariesForSnapBuildIds(snap_build_ids=[build])
        except Exception as e:
            print('could not get response for {}, error: {})'.format(build, e))
            continue
        status = response[build]['status']
        if status == 'FULLYBUILT':
            mybuilds.remove(build)
            continue
        elif status == 'FAILEDTOBUILD':
            failures.append(build)
            mybuilds.remove(build)
            continue
        elif status == 'CANCELLED':
            mybuilds.remove(build)
            continue
    time.sleep(60)

# create the list with all the architectures
built_arches = arches[:]

# if we had failures, print them and save the results
if len(failures):
    for failure in failures:
        try:
            response = ubuntucore.getBuildSummariesForSnapBuildIds(snap_build_ids=[failure])
        except:
            print('could not get failure data for {} (was there an LP timeout ?)'.format(build))
            continue
        buildlog = response[build]['build_log_url']
        if buildlog != 'None':
            print(buildlog)
            arch = str(buildlog).split('_')[4]
            print('core snap {} build at {} failed for id: {} log: {}'.format(arch, stamp,
                                                                              failure, buildlog))
            built_arches.remove(arch)

# save a file with a line containing all the architectures that were built successfully
# this file is used to keep track of the relation between builds and commits hash for each architecture
# the tracking is needed to be able to test the core snap on edge channel
with open(results_file, 'w') as rf:
    rf.write(' '.join(built_arches))

if len(failures):
    print('finished with errors')
    exit(1)

print('finished successfully')
