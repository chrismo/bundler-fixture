#!/usr/bin/env bash

# This script is primarily used in testing Bundler plugins against older
# versions of Bundler. It effectively removes all other versions of Bundler,
# including default versions installed automatically by RubyGems upgrades or
# downgrades.

GEMS_DIR=$(ruby -e 'puts Gem.default_dir')
SPEC_DIR=${GEMS_DIR}/specifications
SITE_DIR=$(ruby -e 'puts RbConfig::CONFIG["sitelibdir"]')

# Newer RubyGems versions will install a default Bundler, this needs to happen
# before uninstalling all Bundler versions.
rm -rf ${SITE_DIR}/bundler*
rm -rf ${SITE_DIR}/rubygems*

# Move bundler gemspec from default to reg directory so it can be uninstalled.
mv -v ${SPEC_DIR}/default/bundler-*.gemspec ${SPEC_DIR}/

# for dir in $(echo $GEM_PATH | tr ':' ' '); do gem uninstall -i $dir bundler -a -x; done
gem uninstall bundler -a -x --force
gem uninstall -i ${GEMS_DIR} bundler -a -x
