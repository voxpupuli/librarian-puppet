require 'librarian/dsl'
require 'librarian/dsl/target'
require 'librarian/puppet/source'
require 'librarian/puppet/dependency'

module Librarian
  module Puppet
    class Dsl < Librarian::Dsl
      FORGE_URL = 'https://forgeapi.puppet.com'

      dependency :mod

      source forge: Source::Forge
      source git: Source::Git
      source path: Source::Path
      source github_tarball: Source::GitHubTarball

      def default_specfile
        proc do
          forge FORGE_URL
          metadata
        end
      end

      def self.dependency_type
        Librarian::Puppet::Dependency
      end

      def post_process_target(target)
        # save the default forge defined
        default_forge = target.sources.select { |s| s.is_a? Librarian::Puppet::Source::Forge }.first
        Librarian::Puppet::Source::Forge.default = default_forge || Librarian::Puppet::Source::Forge.from_lock_options(
          environment, remote: FORGE_URL
        )
      end

      def receiver(target)
        Receiver.new(target)
      end

      def run(specfile = nil, sources = [])
        if specfile.is_a?(Array) && sources.empty?
          sources = specfile
          specfile = nil
        end

        Target.new(self).tap do |target|
          target.precache_sources(sources)
          debug_named_source_cache('Pre-Cached Sources', target)

          specfile ||= Proc.new if block_given?

          if specfile.is_a?(Pathname) and !File.exist?(specfile)
            debug { "Specfile #{specfile} not found, using defaults" } unless specfile.nil?
            receiver(target).run(specfile, &default_specfile)
          else
            receiver(target).run(specfile)
          end

          post_process_target(target)

          debug_named_source_cache('Post-Cached Sources', target)
        end.to_spec
      end

      class Target < Librarian::Dsl::Target
        def dependency(name, *args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          source = source_from_options(options) || @source
          dep = dependency_type.new(name, args, source, 'Puppetfile')
          @dependencies << dep
        end
      end

      class Receiver < Librarian::Dsl::Receiver
        attr_reader :specfile, :working_path

        # save the specfile and call librarian
        def run(specfile = nil)
          @working_path = specfile.is_a?(Pathname) ? specfile.parent : Pathname.new(Dir.pwd)
          @specfile = specfile
          super
        end

        # implement the 'metadata' syntax for Puppetfile
        def metadata
          f = working_path.join('metadata.json')
          raise Error, "Metadata file does not exist: #{f}" unless File.exist?(f)

          begin
            json = JSON.parse(File.read(f))
          rescue JSON::ParserError => e
            raise Error, "Unable to parse json file #{f}: #{e}"
          end
          dependencyList = json['dependencies']
          dependencyList.each do |d|
            mod(d['name'], d['version_requirement'])
          end
        end
      end
    end
  end
end
