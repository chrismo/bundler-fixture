#!/usr/bin/env bash

# This script is primarily used in testing Bundler plugins against older
# versions of Bundler. It effectively removes all other versions of Bundler,
# including default versions installed automatically by RubyGems upgrades or
# downgrades.

# It can be used for your own purposes, but there may be some unintended side
# effects as a result, see the following notes. If everything goes pear-shaped,
# the reset-rubygems-bundler.sh script should get you back operational, with the
# default RubyGems for your version of Ruby and no Bundler installed. If that
# still isn't working, do a `gem update --system` and that should get you back
# operational again.

# NOTE: Downgrading RubyGems to some older version won't work if it's too old
# for the current version of Ruby. You can find the RubyGems version installed
# with Ruby at https://github.com/ruby/ruby/blob/ruby_2_4/lib/rubygems.rb

# NOTE: Installing only Bundler 2.x will likely lead to raised exceptions when
# working in a directory with a lockfile bundled with 1.x. This isn't a bug in
# Bundler, this is a side-effect of this script being very strict about cleaning
# out all other Bundler versions, which is an unnatural use case in real life.

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
  if [[ "$RUBYGEMS_VER" == "latest" ]]
  then
    gem update --system
  else
    gem update --system ${RUBYGEMS_VER}
  fi
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
  # There are two paths here to install the latest, this redundancy is to
  # support readability in scripts calling this script.
  if [[ "$BUNDLER_VER" == "latest" ]]
  then
    gem install bundler --no-document
  else
    gem install bundler -v ${BUNDLER_VER} --no-document
  fi
else
  gem install bundler --no-document
fi

# This may seem redundant, but sometimes is helpful when debugging.
gem list -e bundler -d
which bundle
gem -v
bundle -v
