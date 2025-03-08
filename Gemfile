# frozen_string_literal: true

source 'https://rubygems.org'

# mention puppet here and in the gemspec, so we can provide a specific version in CI

gem 'puppet', ENV.fetch('PUPPET_VERSION', ['>= 7', '< 9'])

gemspec

group :release, optional: true do
  gem 'faraday-retry', '~> 2.1', require: false
  gem 'github_changelog_generator', '~> 1.16.4', require: false
end
