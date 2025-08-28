# frozen_string_literal: true

# Extend Lockfile to normalize module names from acme/mod to acme-mod
module Librarian
  module Puppet
    class Lockfile < Librarian::Lockfile
      # Extend the parser to normalize module names in old .lock files, converting / to -
      class Parser < Librarian::Lockfile::Parser
        include Librarian::Puppet::Util

        def extract_and_parse_sources(lines)
          sources = super
          sources.each do |source|
            source[:manifests] = Hash[source[:manifests].map do |name, manifest|
              [normalize_name(name), manifest]
            end]
          end
          sources
        end

        def extract_and_parse_dependencies(lines, manifests_index)
          # when looking up in manifests_index normalize the name beforehand
          class << manifests_index
            include Librarian::Puppet::Util

            alias_method :old_lookup, :[]
            define_method(:[]) { |k| old_lookup(normalize_name(k)) }
          end
          dependencies = []
          while lines.first =~ %r{^ {2}([\w\-/]+)(?: \((.*)\))?$}
            lines.shift
            name = ::Regexp.last_match(1)
            requirement = ::Regexp.last_match(2).split(/,\s*/)
            dependencies << environment.dsl_class.dependency_type.new(name, requirement, manifests_index[name].source,
                                                                      'lockfile')
          end
          dependencies
        end

        def compile_placeholder_manifests(sources_ast)
          manifests = {}
          sources_ast.each do |source_ast|
            source_type = source_ast[:type]
            source = source_type.from_lock_options(environment, source_ast[:options])
            source_ast[:manifests].each do |manifest_name, manifest_ast|
              manifests[manifest_name] = ManifestPlaceholder.new(
                source,
                manifest_name,
                manifest_ast[:version],
                manifest_ast[:dependencies].map do |k, v|
                  environment.dsl_class.dependency_type.new(k, v, nil, manifest_name)
                end,
              )
            end
          end
          manifests
        end

        def compile(sources_ast)
          manifests = compile_placeholder_manifests(sources_ast)
          manifests = manifests.map do |name, manifest|
            manifest.dependencies.map do |d|
              environment.dsl_class.dependency_type.new(d.name, d.requirement, manifests[d.name].source, name)
            end
            real = Manifest.new(manifest.source, manifest.name)
            real.version = manifest.version
            real.dependencies = manifest.dependencies
            real
          end
          ManifestSet.sort(manifests)
        end
      end

      def load(string)
        Parser.new(environment).parse(string)
      end
    end
  end
end
