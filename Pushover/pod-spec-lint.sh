#!/bin/bash
# The pod lint command doesn't properly resolve private repo sources (it should read
# sources from the Podfile, but doesn't); this script simply lists the required sources
# on the command line.
# Note that this shouldn't be necessary once Q and SCFFLD are published to the standard
# CocoaPods repo.
pod spec lint Pushover.podspec --sources='ssh://git@git.innerfunction.com:22222/julian/if-podspecs.git,https://github.com/CocoaPods/Specs.git'
