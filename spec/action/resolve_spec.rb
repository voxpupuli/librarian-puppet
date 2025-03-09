# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/librarian/puppet/action/resolve'
require 'librarian/ui'
require 'thor'

describe 'Librarian::Puppet::Action::Resolve' do
  let(:path) { File.expand_path('../../features/examples/test', __dir__) }
  let(:environment) { Librarian::Puppet::Environment.new(project_path: path) }

  before do
    # run with DEBUG=true envvar to get debug output
    environment.ui = Librarian::UI::Shell.new(Thor::Shell::Basic.new)
  end

  after do
    File.delete('features/examples/test/Puppetfile.lock')
  end

  describe '#run' do
    it 'resolves dependencies' do
      Librarian::Puppet::Action::Resolve.new(environment, force: true).run
      resolution = environment.lock.manifests.map do |m|
        { name: m.name, version: m.version.to_s, source: m.source.to_s }
      end
      expect(resolution.size).to eq(1)
      expect(resolution.first[:name]).to eq('puppetlabs-stdlib')
      expect(resolution.first[:source]).to eq('https://forgeapi.puppet.com')
      expect(resolution.first[:version]).to match(/\d+\.\d+\.\d+/)
    end
  end
end
