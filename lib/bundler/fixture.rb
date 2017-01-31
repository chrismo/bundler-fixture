require 'bundler/fixture/version'
require 'bundler'
require 'tmpdir'

class BundlerFixture
  attr_reader :dir

  def initialize(dir: File.join(Dir.tmpdir, 'fake_project_root'))
    @dir = dir
    FileUtils.makedirs @dir

    @sources = Bundler::SourceList.new
    @sources.add_rubygems_remote('https://rubygems.org')
  end

  def clean_up
    FileUtils.rmtree @dir
  end

  # @param [Gem::Specification] gem_dependencies This simulates gem requirements in Gemfile.
  # @param [Gem::Specification] source_specs This simulates gems in the source index.
  # @param [boolean] ensure_sources Default is true, makes sure a source exists for each gem_dependency.
  #                                 Set this to false to require sending in sources in @param source_specs.
  # @param [Array boolean] update_gems An array of gem names to update to latest, or `true` to update all.
  #                                    Default is empty Array.
  def create_lockfile(gem_dependencies:,
                      source_specs: [],
                      ensure_sources: true,
                      update_gems: [])
    defn = create_definition(gem_dependencies: gem_dependencies,
                             source_specs: source_specs,
                             ensure_sources: ensure_sources,
                             update_gems: update_gems)
    defn.lock(lockfile_filename)
  end

  def create_definition(gem_dependencies:, source_specs:, ensure_sources:, update_gems:)
    index = Bundler::Index.new
    Array(source_specs).flatten.each { |s| index << s }
    if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new('1.14.0')
      index << Gem::Specification.new("ruby\0", Bundler::RubyVersion.system.to_gem_version_with_patchlevel)
      index << Gem::Specification.new("rubygems\0", Gem::VERSION)
    end

    Array(gem_dependencies).each do |dep|
      index << create_spec(dep.name, dep.requirement.requirements.first.last)
    end if ensure_sources

    update_hash = update_gems === true ? true : {gems: Array(update_gems)}
    defn = Bundler::Definition.new(lockfile_filename, Array(gem_dependencies), @sources, update_hash)
    defn.instance_variable_set('@index', index)
    # reading an existing lockfile in will overwrite the hacked up sources with detected
    # ones from lockfile, so this needs to go here after the constructor is called.
    source.instance_variable_set('@specs', index)
    defn
  end

  def lockfile_filename
    File.join(@dir, 'Gemfile.lock')
  end

  def lockfile_contents
    File.read(lockfile_filename)
  end

  def parsed_lockfile
    Bundler::LockfileParser.new(lockfile_contents)
  end

  def parsed_lockfile_spec(gem_name)
    parsed_lockfile.specs.detect { |s| s.name == gem_name }
  end

  def create_dependency(name, *requirements)
    Bundler::Dependency.new(name, requirements, {'source' => source})
  end

  def source
    @sources.all_sources.first
  end

  def create_spec(name, version, dependencies={})
    Gem::Specification.new do |s|
      s.name = name
      s.version = Gem::Version.new(version)
      s.platform = 'ruby'
      s.source = source
      dependencies.each do |name, requirement|
        s.add_dependency name, requirement
      end
    end
  end

  def create_specs(name, versions, dependencies={})
    versions.map do |version|
      create_spec(name, version, dependencies)
    end
  end
end
