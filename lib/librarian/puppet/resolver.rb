# frozen_string_literal: true

require 'librarian/resolver'

module Librarian
  module Puppet
    class Resolver < Librarian::Resolver
      class Implementation < Librarian::Resolver::Implementation
        def sourced_dependency_for(dependency)
          return dependency if dependency.source

          source = dependency_source_map[dependency.name] || default_source
          dependency.class.new(dependency.name, dependency.requirement, source, dependency.parent)
        end
      end

      def implementation(spec)
        Implementation.new(self, spec, cyclic: cyclic)
      end
    end
  end
end
