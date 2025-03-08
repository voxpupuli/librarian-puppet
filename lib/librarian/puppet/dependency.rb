# frozen_string_literal: true

module Librarian
  module Puppet
    class Dependency < Librarian::Dependency
      include Librarian::Puppet::Util

      attr_accessor :parent
      private :parent=

      def initialize(name, requirement, source, parent = nil)
        # Issue #235 fail if forge source is not defined
        raise Error, 'forge entry is not defined in Puppetfile' if source.instance_of?(Array) && source.empty?

        self.parent = parent
        super(normalize_name(name), requirement, source)
      end

      def to_s
        "#{name} (#{requirement}) <#{source}> (from #{parent.nil? ? '<nil>' : parent})"
      end
    end
  end
end
