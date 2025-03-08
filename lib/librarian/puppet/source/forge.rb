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
            new(environment, options[:remote], options.reject { |k, _v| k == :remote })
          end

          def from_spec_args(environment, uri, options)
            recognised_options = []
            unrecognised_options = options.keys - recognised_options
            raise Error, "unrecognised options: #{unrecognised_options.join(', ')}" unless unrecognised_options.empty?

            new(environment, uri, options)
          end
        end

        attr_accessor :environment
        private :environment=
        attr_reader :uri

        def initialize(environment, uri, _options = {})
          self.environment = environment

          @uri = URI.parse(uri)
          @cache_path = nil
        end

        def to_s
          clean_uri(uri).to_s
        end

        def ==(other)
          other &&
            self.class == other.class &&
            uri == other.uri
        end

        alias eql? ==

        def hash
          to_s.hash
        end

        def to_spec_args
          [clean_uri(uri).to_s, {}]
        end

        def to_lock_options
          { remote: uri.to_s }
        end

        def pinned?
          false
        end

        def unpin!; end

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

        def fetch_dependencies(name, version, _version_uri)
          repo(name).dependencies(version).map do |k, v|
            v = Librarian::Dependency::Requirement.new(v).to_gem_requirement
            Dependency.new(k, v, nil, name)
          end
        end

        def manifests(name)
          repo(name).manifests
        end

        private

        def repo(name)
          @repo ||= {}

          unless @repo[name]
            # If we are using the official Forge then use API v3, otherwise use the preferred api
            # as defined by the CLI option use_v1_api
            @repo[name] = if environment.use_v1_api
                            RepoV1.new(self, name)
                          else
                            RepoV3.new(self, name)
                          end
          end
          @repo[name]
        end
      end
    end
  end
end
