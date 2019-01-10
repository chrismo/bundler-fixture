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
gem update --system $2

# Show existing Bundler versions
gem list -e bundler -d

# Move bundler gemspec from default to reg directory so it can be uninstalled.
mv -v ${SPEC_DIR}/default/bundler-*.gemspec ${SPEC_DIR}/

# for dir in $(echo $GEM_PATH | tr ':' ' '); do gem uninstall -i $dir bundler -a -x; done
gem uninstall bundler -a -x --force
gem uninstall -i ${GEMS_DIR} bundler -a -x

# Newer RubyGems updates put Bundler here. Uninstalling isn't removing.
rm -rf ${SITE_DIR}/bundler*

gem install bundler -v $1 --no-document

# This may seem redundant, but sometimes is helpful when debugging.
gem list -e bundler -d
which bundle
gem -v
bundle --version
