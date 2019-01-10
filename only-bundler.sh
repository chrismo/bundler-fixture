#!/usr/bin/env bash

# This script is primarily used in testing Bundler plugins against older
# versions of Bundler. It effectively removes all other versions of Bundler,
# including default versions installed automatically by RubyGems upgrades or
# downgrades.

# NOTE: Downgrading RubyGems to some older version won't work if it's too old
# for the current version of Ruby. You can find the RubyGems version installed
# with Ruby at https://github.com/ruby/ruby/blob/ruby_2_4/lib/rubygems.rb

set -x

GEMS_DIR=$(ruby -e 'puts Gem.default_dir')
SPEC_DIR=${GEMS_DIR}/specifications
SITE_DIR=$(ruby -e 'puts RbConfig::CONFIG["sitelibdir"]')
BUNDLER_VER="$1"
RUBYGEMS_VER="$2"

# Newer RubyGems versions will install a default Bundler, this needs to happen
# before uninstalling all Bundler versions.
if [[ -n "$RUBYGEMS_VER" ]]
then
  gem update --system ${RUBYGEMS_VER}
fi

# Show existing Bundler versions
gem list -e bundler -d

# Move bundler gemspec from default to reg directory so it can be uninstalled.
mv -v ${SPEC_DIR}/default/bundler-*.gemspec ${SPEC_DIR}/

for dir in $(echo ${GEM_PATH} | tr ':' ' '); do gem uninstall -i ${dir} bundler -a -x --force; done
gem uninstall bundler -a -x --force
gem uninstall -i ${GEMS_DIR} bundler -a -x --force

# Newer RubyGems updates put Bundler here. Uninstalling isn't removing.
rm -rf ${SITE_DIR}/bundler*

if [[ -n "$BUNDLER_VER" ]]
then
  gem install bundler -v ${BUNDLER_VER} --no-document
else
  gem install bundler --no-document
fi

# This may seem redundant, but sometimes is helpful when debugging.
gem list -e bundler -d
which bundle
gem -v
bundle -v
