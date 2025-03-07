# frozen_string_literal: true

source 'https://rubygems.org'

# mention puppet here and in the gemspec, so we can provide a specific version in CI

gem 'openvox', ENV.fetch('OPENVOX_VERSION', ['>= 8.22', '< 9'])

gemspec

group :release, optional: true do
  gem 'faraday-retry', '~> 2.1', require: false
  gem 'github_changelog_generator', '~> 1.16.4', require: false
end

# https://github.com/OpenVoxProject/puppet/issues/90
gem 'syslog', '>= 0.2', '< 1' if RUBY_VERSION >= '3.4'
