# Bundler::Fixture

A simple fixture to generate a for-realz Gemfile.lock with completely fake data.

Bundler has wonderful [fixture tooling](https://github.com/bundler/bundler/blob/master/spec/support/builders.rb) for testing itself, but it's pretty elaborate and hard (for a knucklehead like me) to re-use. I cobbled this together and wanted to re-use it elsewhere and decided to package it up separately.

[![Build Status](https://travis-ci.org/chrismo/bundler-fixture.svg?branch=master)](https://travis-ci.org/chrismo/bundler-fixture)

Works with Bundler 1.7+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bundler-fixture'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bundler-fixture

## Usage

    require 'bundler/fixture'

    bf = BundlerFixture.new(dir: Dir.tmpdir)
    bf.create_lockfile(gem_dependencies: bf.create_dependency('foo', '1.4.5'))

`BundlerFixture` takes the gem specs and builds an index with the contents, and sets up other dependencies so a `Gemfile.lock` can be built reflecting the dependency tree in all of the passed specs with `Bundler::Definition`. This ensures `Bundler::LockfileParser` will be able to parse the file successfully, handy for testing your own code that's working programatically with its output.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chrismo/bundler-fixture.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

