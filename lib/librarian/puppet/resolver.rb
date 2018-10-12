require 'librarian/resolver'

module Librarian
  module Puppet
    class Resolver < Librarian::Resolver

      def sort(manifests)
        manifests = manifests.values if Hash === manifests
        manifests.sort_by(&:name)
      end

    end
  end
end
