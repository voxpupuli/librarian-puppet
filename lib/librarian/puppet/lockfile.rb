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
            source[:manifests] = Hash[source[:manifests].map do |name,manifest|
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
            define_method(:[]) { |k| self.old_lookup(normalize_name(k)) }
          end
          super(lines, manifests_index)
        end

        def compile(sources_ast)
          manifests = compile_placeholder_manifests(sources_ast)
          manifests = manifests.map do |name, manifest|
            dependencies = manifest.dependencies.map do |d|
              environment.dsl_class.dependency_type.new(d.name, d.requirement, manifests[d.name].source)
            end
            real = Manifest.new(manifest.source, manifest.name)
            real.version = manifest.version
            real.dependencies = manifest.dependencies
            real
          end
          manifests.sort_by(&:name)
        end

      end

      def load(string)
        Parser.new(environment).parse(string)
      end

    end
  end
end
