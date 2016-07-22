require "librarian/puppet/source/forge"
require "librarian/puppet/environment"
require 'librarian/puppet/extension'

include Librarian::Puppet::Source

describe Forge do

  let(:environment) { Librarian::Puppet::Environment.new }
  #need a valid url that is not a puppet forge url
  let(:uri) { "http://google.com" }
  subject { Forge.new(environment, uri) }

  describe "#manifests" do
    let(:manifests) { [] }
    before do
      expect_any_instance_of(Librarian::Puppet::Source::Forge::RepoV3).to receive(:get_versions).at_least(:once) { manifests }
    end
    it "should return the manifests using v3 api" do
      environment.stub(:use_v1_api) { false }
      expect(subject.manifests("x")).to eq(manifests)
    end
  end

end
