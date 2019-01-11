require 'spec_helper'

RSpec::Matchers.define :have_line do |expected|
  match do |actual|
    actual.split(/\n/).map(&:strip).include?(expected)
  end
  failure_message do |actual|
    "expected line <#{expected}> would be in:\n#{actual}"
  end
end

describe Bundler::Fixture do
  it 'has a version number' do
    expect(Bundler::Fixture::VERSION).not_to be nil
  end

  before do
    @bf = BundlerFixture.new
  end

  after do
    @bf.clean_up
  end

  context 'parameters' do
    it 'should ensure sources for dependencies by default' do
      @bf.create_lockfile(gem_dependencies: @bf.create_dependency('foo'))
    end

    it 'will not ensure sources for dependencies if told, error case' do
      expect { @bf.create_lockfile(
        gem_dependencies: @bf.create_dependency('foo'),
        ensure_sources: false
      ) }.to raise_error(Bundler::GemNotFound)
    end

    it 'will not ensure sources for dependencies if told, manually provided case' do
      @bf.create_lockfile(
        gem_dependencies: @bf.create_dependency('foo'),
        source_specs: @bf.create_spec('foo', '1.0.0'),
        ensure_sources: false
      )
    end
  end

  context 'create lockfile' do
    it 'resolves to most recent available gem' do
      @bf.create_lockfile(gem_dependencies: [
        @bf.create_dependency('foo')
      ], source_specs: [
        @bf.create_spec('foo', '1.0.0', [['bar', '>= 1.0.4']]),
        @bf.create_spec('bar', '1.1.3'),
        @bf.create_spec('bar', '1.1.4'),
        @bf.create_spec('bar', '1.2.4'),
      ])

      parser = Bundler::LockfileParser.new(@bf.lockfile_contents)
      expect(parser.specs).to_not eq []
      expect(parser.specs.detect { |s| s.name == 'bar' }.version.to_s).to eq '1.2.4'
    end

    it 'sticks to version put into lockfile' do
      @bf.create_lockfile(gem_dependencies: [
        @bf.create_dependency('foo')
      ], source_specs: [
        @bf.create_spec('foo', '1.0.0', [['bar', '>= 1.0.4']]),
        @bf.create_spec('bar', '1.1.3'),
      ])

      expect(@bf.parsed_lockfile_spec('bar').version.to_s).to eq '1.1.3'

      # Since we're not cleaning up the fixture in between, this will load the existing
      # lockfile into the Bundler::Definition first, simulating what bundler actually
      # does with an existing lockfile, not upgrading it just because a new version
      # is available.
      @bf.create_lockfile(gem_dependencies: [
        @bf.create_dependency('foo'),
      ], source_specs: [
        @bf.create_spec('foo', '1.0.0', [['bar', '>= 1.0.4']]),
        @bf.create_specs('bar', %w(1.1.3 1.2.4)),
      ])

      expect(@bf.parsed_lockfile_spec('bar').version.to_s).to eq '1.1.3'
    end

    it 'updates only specified gem names and its dependencies' do
      @bf.create_lockfile(
        gem_dependencies: [@bf.create_dependency('foo'), @bf.create_dependency('quux')],
        source_specs: [
          @bf.create_spec('foo', '2.4.0', [['bar', '>= 1.0.4']]),
          @bf.create_spec('bar', '1.1.3'),
          @bf.create_spec('quux', '0.0.4'),
        ], ensure_sources: false)

      @bf.create_lockfile(
        gem_dependencies: [@bf.create_dependency('foo'), @bf.create_dependency('quux')],
        source_specs: [
          @bf.create_spec('foo', '2.4.0', [['bar', '>= 1.0.4']]),
          @bf.create_spec('foo', '2.5.0', [['bar', '>= 1.0.4']]),
          @bf.create_specs('bar', %w(1.1.3 3.2.0)),
          # @bf.create_spec('quux', '0.0.4'), this works even w/o this. it's not even checked because it's not updated.
          @bf.create_spec('quux', '0.2.0'),
        ], ensure_sources: false, update_gems: 'foo')

      # This upgrades bar because it's a dependency of foo, and we requested foo be updated to latest.
      # While there are cases we DON'T want bar updated, if this was a clean install and no existing bar
      # version in a lockfile, these are the versions that would be grabbed. The bundler team's position
      # is if this matters to you, you'll need to override the requirement in your Gemfile. It doesn't
      # matter to the foo gem, it left its requirement on the gem to be wide-open.
      expect(@bf.parsed_lockfile_spec('bar').version.to_s).to eq '3.2.0'
      expect(@bf.parsed_lockfile_spec('foo').version.to_s).to eq '2.5.0'
      expect(@bf.parsed_lockfile_spec('quux').version.to_s).to eq '0.0.4'
    end

    it 'handles custom Gemfile name' do
      @bf.create_lockfile(
        gem_dependencies: [@bf.create_dependency('foo')], source_specs: [@bf.create_spec('foo', '2.4.0')],
        ensure_sources: false, gemfile: 'Custom.gemfile')

      expect(@bf.parsed_lockfile_spec('foo').version.to_s).to eq '2.4.0'

      expect(File.exist?(File.join(@bf.dir, 'Custom.gemfile.lock'))).to be_truthy
    end

    it 'supports ruby version' do
      gem_dependencies = [@bf.create_dependency('foo')]
      @bf.create_lockfile(
        gem_dependencies: gem_dependencies, source_specs: [@bf.create_spec('foo', '2.4.0')],
        ensure_sources: false, ruby_version: RUBY_VERSION)

      @bf.create_gemfile(gem_dependencies: gem_dependencies, ruby_version: RUBY_VERSION)

      dfn = Bundler::Definition.build(@bf.gemfile_filename, @bf.lockfile_filename, nil)
      expect(dfn.ruby_version.to_s).to eq "ruby #{RUBY_VERSION}"

      # Not in lockfile before 1.12
      if BundlerFixture.bundler_version_or_higher('1.12.0')
        expect(@bf.parsed_lockfile.ruby_version).to eq "ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
      end
    end
  end

  context 'create gemfile' do
    it 'supports ruby version' do
      gem_dependencies = [@bf.create_dependency('foo')]

      @bf.create_gemfile(gem_dependencies: gem_dependencies, ruby_version: RUBY_VERSION)

      dfn = Bundler::Definition.build(@bf.gemfile_filename, @bf.lockfile_filename, nil)
      expect(dfn.ruby_version.to_s).to eq "ruby #{RUBY_VERSION}"
    end

    def deps_hash
      {'foo' => '1.2', 'bar' => nil, 'qux' => qux_requirements}
    end

    def qux_requirements
      ['~> 1.0', '>= 1.0.9']
    end

    def expected_qux_requirements
      @bf.requirement_to_s(Gem::Requirement.new(qux_requirements))
    end

    it 'supports simple string gem dependencies' do
      @bf.create_gemfile(gem_dependencies: deps_hash)
      guts = File.read(@bf.gemfile_filename)
      expect(guts).to have_line "gem 'foo', '1.2'"
      expect(guts).to have_line "gem 'bar'"
      expect(guts).to have_line "gem 'qux', #{expected_qux_requirements}"
    end

    it 'supports gem dependency objects' do
      gems = deps_hash
      deps = gems.map { |gem, requirement| @bf.create_dependency(gem, requirement) }
      @bf.create_gemfile(gem_dependencies: deps)
      guts = File.read(@bf.gemfile_filename)
      expect(guts).to have_line "gem 'foo', '1.2'"
      expect(guts).to have_line "gem 'bar'"
      expect(guts).to have_line "gem 'qux', #{expected_qux_requirements}"
    end
  end

  context 'create config' do
    it 'should set path and disabled shared gems' do
      @bf.create_gemfile(gem_dependencies: [])
      @bf.create_config(path: 'yy')
      Bundler.with_clean_env do
        Dir.chdir(@bf.dir) do
          # this squirrelly issue with disable_shared_gems rears its head again.
          ENV['GEM_PATH'] = nil if ENV['GEM_PATH'] == ''
          config_dump = `bundle config`
          expect(config_dump).to match /path\nSet for your local app \(.*\): "yy"/
          expect(config_dump).to match /disable_shared_gems\nSet for your local app \(.*\): .?true.?/
        end
      end
    end
  end
end
