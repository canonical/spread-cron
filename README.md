[![Build Status][travis-image]][travis-url]

spread-cron helps to make sure that snapd keeps working after certain external resources change.

We are using spread for snapd development, with each pull request we are able to run a suite of checks that exercise the product in a lot of different ways, so that we can be confident that the new changes won't break the existing features. However, given the intrinsic distributed nature and complexity of the snapd environment, there are additional changes that can make the whole thing fail: what happens if the packaging of a new core snap doesn't play well with the rest of the system? will snapd keep working after a rollout of a store endpoint? will an ubuntu-core image made available before publishing work as expected?

# Workflow

spread-cron was developed to watch specific external resources (currently only web-based) and trigger customized test executions when changes on those are detected. It follows a pull-based model, in which from a central point, where the spread-cron snap is deployed, the various predefined resources are polled and, when changes are detected, snapd's source code is cloned, the required customizations are done and the suite execution is triggered.

## Predefined resources definition

spread-cron relies heavily on git infrastructure for handling its config and state storage, not only on the versioned files themselves but on git-specific features too. For each watched resource a git branch is defined, and the files for checking the external resource and customizing the test execution are added to that branch. This way we can have separate branches for checking core snap versions on the different channels, store endpoints or SRU bugs being filed, the spread-cron agent just need to checkout each of them and apply the same set of actions to the specific files for each resource.

## Changes detection

The way spread-cron detects and stores changes is defined in the branch-specific `options` file. It is a plain shell file with two variables, `pattern_extractor` and `message`. `pattern_extractor` contains a shell command that scrapes an external resource and returns a meaningful value about the resource's status. For instance, in the core snap case this variable could contain a curl command that asks the store's search endpoint for the snap details and extracts from the returned JSON the `revision` field.

After retrieving the state value from the external resource spread-cron compares it with the previous stored state. The state is stored as a commit in the resource branch history. The commit text is compossed of the `message` entry in the `options` file, plus the current state scrapped from the external resource. So, for knowing if there have been actual changes in the resource, spread-cron iterates through the commit history in the branch until it finds a commit message that matches "`message` (old_value)", then compares the new value with old_value and, if they are different, a new commit is issued with a message like "`message` (new_value)".

For example, say we are tracking changes of core's snap revision on the beta channel. We could use an `options` file like this:

    pattern_extractor="curl -s -H \"X-Ubuntu-Architecture: amd64\" https://search.apps.ubuntu.com/api/v1/package/core/beta | sed -e 's|.*\"revision\": \(.*\), \"status\".*|\1|'"
    message="New OS snap in beta channel"

When spread-cron checks this branch, suppose that from the pattern extractor it gets a revision number of 550. Then it checks the log of commits from this branch, if `git log --pretty=oneline` looks like:

    9c8bb698f2c7982cd31138f9451858f9d834a034 fix channel name [skip ci]
    e2dbbd66ad250df912384f90367505d0f4e4211e New OS snap in beta channel (549)
    53ea12890884e73e2705e2621ada9997fafc9bc3 new run-checks file [skip ci]
    12cdb134b31e31ad4cd004089f5c9c935dea9ff5 New OS snap in beta channel (548)

then spread-cron will iterate through the commit list until it finds the first entry which matches `$message` from the options file and extract the old version from there, in this case 549. Since the two versions are different, it will add a new empty commit in the current branch with the message `New OS snap in beta channel (550)`.

## Execution triggering

spread-cron is wired with travis trough the `.travis.yml` file, once a change is detected and a new commit is performed, travis takes over and triggers the subequent sequence of commands: get snapd soource, customize it and launch spread.

## snapd's cloning

After a new change is detected the full snapd repo is cloned from master into the `target` directory. spread will be executed from that directory after the suite customization.

## Suite customization

There are currently two ways of customizing the spread execution, through environment variables (defined in the `custom/env.sh` file of each resource branch) and overwriting files of snapd's source tree (done using the `actions.sh` file and customized versions of snapd's files under the `custom` directory). Both methods have pros and cons, with environment variables we don't need to maintain additional files on spread-cron but we need to make snapd'd suite be aware of these env vars, the overwrite method gives us full flexibility but we need to keep the diverged files up to date.

# Packaging and deployment

spread-cron is distributed as a snap, see the [snapcraft.yaml file](https://github.com/snapcore/spread-cron/blob/master/snapcraft.yaml) for its definition. It embeds curl and a git client. The authentication for github can be set up using a configuration hook once the snap is installed:

    snap set spread-cron username=<username> password=<password>

with valid credentials of an user with push privileges for github's `snapd/spread-cron` repo.

# Watched resources

Resource | Value Fetched | Branch | Options File
-------- | ------------- | ------ | -------------
core snap, edge channel, amd64 arch | revision | snapd-core-edge | [options](https://github.com/snapcore/spread-cron/blob/snapd-core-edge/options)
core snap, beta channel, amd64 arch | revision | snapd-core-beta | [options](https://github.com/snapcore/spread-cron/blob/snapd-core-beta/options)
core snap, candidate channel, amd64 arch | revision | snapd-core-candidate | [options](https://github.com/snapcore/spread-cron/blob/snapd-core-candidate/options)
core snap, stable channel, amd64 arch | revision | snapd-core-stable | [options](https://github.com/snapcore/spread-cron/blob/snapd-core-stable/options)
production store, CPI endpoint | X-Bzr-Revision-Number | snapd-production-store-cpi | [options](https://github.com/snapcore/spread-cron/blob/snapd-production-store-cpi/options)
production store, SAS endpoint | X-Vcs-Revision | snapd-production-store-sas | [options](https://github.com/snapcore/spread-cron/blob/snapd-production-store-sas/options)
production store, SCA endpoint | X-Bzr-Revision-Number | snapd-production-store-sca | [options](https://github.com/snapcore/spread-cron/blob/snapd-production-store-sca/options)
production store, SSO endpoint | X-Bzr-Revision-Number | snapd-production-store-sso | [options](https://github.com/snapcore/spread-cron/blob/snapd-production-store-sso/options)
staging store, SAS endpoint | X-Vcs-Revision | snapd-staging-store-sas | [options](https://github.com/snapcore/spread-cron/blob/snapd-staging-store-sas/options)

[travis-image]: https://travis-ci.org/snapcore/spread-cron.svg?branch=master
[travis-url]: https://travis-ci.org/snapcore/spread-cron?branch=master
