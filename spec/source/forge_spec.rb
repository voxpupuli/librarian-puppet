require 'librarian/puppet/source/forge'
require 'librarian/puppet/environment'
require 'librarian/puppet/extension'

include Librarian::Puppet::Source

describe Forge do
  subject { Forge.new(environment, uri) }

  let(:environment) { Librarian::Puppet::Environment.new }
  let(:uri) { 'https://forgeapi.puppet.com' }

  describe '#manifests' do
    let(:manifests) { [] }

    before do
      expect_any_instance_of(Librarian::Puppet::Source::Forge::RepoV3).to receive(:get_versions).at_least(:once) {
        manifests
      }
    end

    it 'returns the manifests' do
      expect(subject.manifests('x')).to eq(manifests)
    end
  end
end
