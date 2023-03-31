require 'librarian/dsl'
require 'librarian/dsl/target'
require 'librarian/puppet/source'
require 'librarian/puppet/dependency'

module Librarian
  module Puppet
    class Dsl < Librarian::Dsl

      FORGE_URL = "https://forgeapi.puppetlabs.com"

      dependency :mod

      source :forge => Source::Forge
      source :git => Source::Git
      source :path => Source::Path
      source :github_tarball => Source::GitHubTarball

      def default_specfile
        Proc.new do
          forge FORGE_URL
          metadata
        end
      end

      def self.dependency_type
        Librarian::Puppet::Dependency
      end

      def post_process_target(target)
        # save the default forge defined
        default_forge = target.sources.select {|s| s.is_a? Librarian::Puppet::Source::Forge}.first
        Librarian::Puppet::Source::Forge.default = default_forge || Librarian::Puppet::Source::Forge.from_lock_options(environment, :remote => FORGE_URL)
      end

      def receiver(target)
        Receiver.new(target)
      end

      def run(specfile = nil, sources = [])
        specfile, sources = nil, specfile if specfile.kind_of?(Array) && sources.empty?

        Target.new(self).tap do |target|
          target.precache_sources(sources)
          debug_named_source_cache("Pre-Cached Sources", target)

          specfile ||= Proc.new if block_given?

          if specfile.kind_of?(Pathname) and !File.exist?(specfile)
            debug { "Specfile #{specfile} not found, using defaults" } unless specfile.nil?
            receiver(target).run(specfile, &default_specfile)
          else
            receiver(target).run(specfile)
          end

          post_process_target(target)

          debug_named_source_cache("Post-Cached Sources", target)
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
          @working_path = specfile.kind_of?(Pathname) ? specfile.parent : Pathname.new(Dir.pwd)
          @specfile = specfile
          super
        end

        # implement the 'modulefile' syntax for Puppetfile
        def modulefile
          f = modulefile_path
          raise Error, "Modulefile file does not exist: #{f}" unless File.exist?(f)
          File.read(f).lines.each do |line|
            regexp = /\s*dependency\s+('|")([^'"]+)\1\s*(?:,\s*('|")([^'"]+)\3)?/
            regexp =~ line && mod($2, $4)
          end
        end

        # implement the 'metadata' syntax for Puppetfile
        def metadata
          f = working_path.join('metadata.json')
          unless File.exist?(f)
            msg = "Metadata file does not exist: #{f}"
            # try modulefile, in case we don't have a Puppetfile and we are using the default template
            if File.exist?(modulefile_path)
              modulefile
              return
            else
              raise Error, msg
            end
          end
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

        private

        def modulefile_path
          working_path.join('Modulefile')
        end
      end
    end
  end
end
