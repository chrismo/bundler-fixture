require 'spec_helper'

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

    it 'will not ensure sources for dependencies if told' do
      expect { @bf.create_lockfile(
        gem_dependencies: @bf.create_dependency('foo'),
        ensure_sources: false
      ) }.to raise_error(Bundler::GemNotFound)
    end

    it 'will not ensure sources for dependencies if told' do
      @bf.create_lockfile(
        gem_dependencies: @bf.create_dependency('foo'),
        source_specs: @bf.create_spec('foo', '1.0.0'),
        ensure_sources: false
      )
    end
  end

  context 'bundler behavior' do
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
        @bf.create_spec('bar', '1.1.3'),
        @bf.create_spec('bar', '1.2.4'),
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
          @bf.create_spec('bar', '1.1.3'),
          @bf.create_spec('bar', '3.2.0'),
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
  end
end
