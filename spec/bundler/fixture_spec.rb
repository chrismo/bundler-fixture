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
      expect{@bf.create_lockfile(
        gem_dependencies: @bf.create_dependency('foo'),
        ensure_sources: false
      )}.to raise_error(Bundler::GemNotFound)
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

      parser = Bundler::LockfileParser.new(@bf.lockfile_contents)
      expect(parser.specs.detect { |s| s.name == 'bar' }.version.to_s).to eq '1.1.3'

      # Since we're not cleaning up the fixture in between, this will load the existing
      # lockfile into the Bundler::Definition first, simulating what bundler actually
      # does with an existing lockfile, not upgrading it just because a new version
      # is available.
      @bf = BundlerFixture.new
      @bf.create_lockfile(gem_dependencies: [
        @bf.create_dependency('foo'),
      ], source_specs: [
        @bf.create_spec('foo', '1.0.0', [['bar', '>= 1.0.4']]),
        @bf.create_spec('bar', '1.1.3'),
        @bf.create_spec('bar', '1.2.4'),
      ])

      parser = Bundler::LockfileParser.new(@bf.lockfile_contents)
      expect(parser.specs.detect { |s| s.name == 'bar' }.version.to_s).to eq '1.1.3'
    end
  end
end
