require 'uri'
require 'librarian/puppet/util'
require 'librarian/puppet/source/forge/repo_v1'
require 'librarian/puppet/source/forge/repo_v3'

module Librarian
  module Puppet
    module Source
      class Forge
        include Librarian::Puppet::Util

        class << self
          LOCK_NAME = 'FORGE'

          def default=(source)
            @@default = source
          end

          def default
            @@default
          end

          def lock_name
            LOCK_NAME
          end

          def from_lock_options(environment, options)
            new(environment, options[:remote], options.reject { |k, v| k == :remote })
          end

          def from_spec_args(environment, uri, options)
            recognised_options = []
            unrecognised_options = options.keys - recognised_options
            unless unrecognised_options.empty?
              raise Error, "unrecognised options: #{unrecognised_options.join(", ")}"
            end

            new(environment, uri, options)
          end

        end

        attr_accessor :environment
        private :environment=
        attr_reader :uri

        def initialize(environment, uri, options = {})
          self.environment = environment

          @uri = URI::parse(uri)
          @cache_path = nil
        end

        def to_s
          clean_uri(uri).to_s
        end

        def ==(other)
          other &&
          self.class == other.class &&
          self.uri == other.uri
        end

        alias :eql? :==

        def hash
          self.to_s.hash
        end

        def to_spec_args
          [clean_uri(uri).to_s, {}]
        end

        def to_lock_options
          {:remote => clean_uri(uri).to_s}
        end

        def pinned?
          false
        end

        def unpin!
        end

        def install!(manifest)
          manifest.source == self or raise ArgumentError

          debug { "Installing #{manifest}" }

          name = manifest.name
          version = manifest.version
          install_path = install_path(name)
          repo = repo(name)

          repo.install_version! version, install_path
        end

        def manifest(name, version, dependencies)
          manifest = Manifest.new(self, name)
          manifest.version = version
          manifest.dependencies = dependencies
          manifest
        end

        def cache_path
          @cache_path ||= begin
            dir = "#{uri.host}#{uri.path}".gsub(/[^0-9a-z\-_]/i, '_')
            environment.cache_path.join("source/puppet/forge/#{dir}")
          end
        end

        def install_path(name)
          environment.install_path.join(module_name(name))
        end

        def fetch_version(name, version_uri)
          versions = repo(name).versions
          if versions.include? version_uri
            version_uri
          else
            versions.first
          end
        end

        def fetch_dependencies(name, version, version_uri)
          repo(name).dependencies(version).map do |k, v|
            v = Librarian::Dependency::Requirement.new(v).to_gem_requirement
            Dependency.new(k, v, nil)
          end
        end

        def manifests(name)
          repo(name).manifests
        end

      private

        def repo(name)
          @repo ||= {}

          unless @repo[name]
            use_version_3 = true
            # Use v3 of the api unless the url is the old one or v1 is explicitly set
            if uri.hostname =~ /forge\.puppetlabs\.com$/ || environment.use_v1_api
              use_version_3 = false
            end

            #Override the above if they have specified the forgeapi (v3) endpoint
            if uri.hostname =~ /forgeapi\.puppetlabs\.com$/
              use_version_3 = true
            end

            if use_version_3
              @repo[name] = RepoV3.new(self, name)
            else
              @repo[name] = RepoV1.new(self, name)
            end
          end
          @repo[name]
        end
      end
    end
  end
end
