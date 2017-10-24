#!/usr/bin/python

import os
import time

from datetime import datetime
from launchpadlib.launchpad import Launchpad


class CoreSnapBuilder:
    """ This class is used to build the core snap in the
    supported architectures and report results
    """
    arches = ['amd64', 'i386', 'armhf', 'arm64', 'ppc64el', 's390x']
    series = 'xenial'
    people = 'snappy-dev'
    ppa = 'image'
    snap = 'core'
    distribution = 'ubuntu'
    stamp_format = '%Y-%m-%d %H:%M:%S'

    def __init__(self, workdir):
        self.ubuntucore = None
        self.builds = []
        self.failures = []
        self.start_build_time = None

        # we need to store credentials once for cronned builds
        self.cachedir = os.path.join(workdir, 'cache')
        self.creds = os.path.join(workdir, 'credentials')

    def build(self):
        """ Trigger the building system for the core snap in the defined arches """
        launchpad = Launchpad.login_with('Ubuntu Core Builds',
                                         'production', self.cachedir,
                                         credentials_file=self.creds,
                                         version='devel')

        # get snappy-dev team data and ppa
        snappydev = launchpad.people[self.people]
        imageppa = snappydev.getPPAByName(name=self.ppa)

        # get snap
        self.ubuntucore = launchpad.snaps.getByName(name=self.snap,
                                               owner=snappydev)

        # get distro info
        ubuntu = launchpad.distributions[self.distribution]
        release = ubuntu.getSeries(name_or_version=self.series)

        # print a stamp
        self.start_build_time = datetime.now()
        print('Trying to trigger builds at: {}'.format(
            self.start_build_time.strftime(self.stamp_format)))

        # loop over arches and trigger builds
        for buildarch in self.arches:
            arch = release.getDistroArchSeries(archtag=buildarch)
            request = self.ubuntucore.requestBuild(archive=imageppa,
                                              distro_arch_series=arch,
                                              pocket='Proposed')
            buildid = str(request).rsplit('/', 1)[-1]
            self.builds.append(buildid)
            print('Arch: {} is building under: {}'.format(buildarch, request))

    def check_builds(self, timeout):
        """ check the status each minute until all builds have finished
        :param timeout: used to stop the checks once the timeout it reached
        """

        print('Receiving status for builds')
        while len(self.builds):
            elapsed_build_time = int((datetime.now() - self.start_build_time).total_seconds())
            if timeout < elapsed_build_time:
                print('Timeout reached')
                exit(1)
            else:
                print('Remaining {} seconds to timeout'.format(timeout - elapsed_build_time))

            for build in self.builds:
                try:
                    response = self.ubuntucore.getBuildSummariesForSnapBuildIds(snap_build_ids=[build])
                except Exception as e:
                    print('Could not get response for {}, error: {})'.format(build, e))
                    continue
                status = response[build]['status']
                print('Received response for build {} with status: {}'.format(build, status))

                if status == 'FULLYBUILT':
                    self.builds.remove(build)
                    continue
                elif status == 'FAILEDTOBUILD':
                    self.failures.append(build)
                    self.builds.remove(build)
                    continue
                elif status == 'CANCELLED':
                    self.builds.remove(build)
                    continue
            if self.builds:
                print('Waiting')
                time.sleep(60)

    def save_results(self, results_file):
        """ Save the building results
        :param results_file: path to the file where the results are stored
        """
        built_arches = self.arches[:]

        # if we had failures, print them and save the results
        for failure in self.failures:
            try:
                response = self.ubuntucore.getBuildSummariesForSnapBuildIds(snap_build_ids=[failure])
            except:
                print('could not get failure data for {} (was there an LP timeout ?)'.format(failure))
                continue
            buildlog = response[failure]['build_log_url']
            if buildlog != 'None':
                print(buildlog)
                arch = str(buildlog).split('_')[4]
                print('core snap {} build at {} failed for id: {} log: {}'.format(
                    arch, self.start_build_time.strftime(self.stamp_format), failure, buildlog))
                built_arches.remove(arch)

        # save a file with a line containing all the architectures that were built successfully
        # this file is used to keep track of the relation between builds and commits hash for each architecture
        # the tracking is needed to be able to test the core snap on edge channel
        with open(results_file, 'w') as rf:
            rf.write(' '.join(built_arches))

        if len(self.failures):
            print('finished with errors')
            exit(1)

        print('finished successfully')


if __name__ == '__main__':
    results_file = os.getenv('RESULTS_FILE', default='built_architectures.txt')
    common = os.getenv('SNAP_COMMON')
    timeout = os.getenv('BUILD_TIMEOUT', default=3600)
    workdir = os.path.join(common, 'core-builds')

    builder = CoreSnapBuilder(workdir)
    builder.build()
    builder.check_builds(timeout)
    builder.save_results(results_file)
