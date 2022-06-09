Feature: cli/install/git
  Puppet librarian needs to install modules from git repositories

  Scenario: Installing a module from git
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/apache',
        :git => 'https://github.com/puppetlabs/puppetlabs-apache.git', :ref => '1.4.0'

    mod 'puppetlabs/stdlib',
        :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git', :ref => '4.6.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/apache/metadata.json" should match /"name": "puppetlabs-apache"/
    And the file "modules/apache/metadata.json" should match /"version": "1\.4\.0"/
    And the git revision of module "apache" should be "e4ec6d4985fdb23e26c809e0d5786823d0689f90"
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/metadata.json" should match /"version": "4\.6\.0"/
    And the git revision of module "stdlib" should be "73474b00b5ae3cbccec6cd0711311d6450139e51"

  @spaces
  Scenario: Installing a module in a path with spaces
    Given a file named "Puppetfile" with:
    """
    mod 'puppetlabs/stdlib', '4.6.0', :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git', :ref => '4.6.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Installing a module with invalid versions in git
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod "apache",
      :git => "https://github.com/puppetlabs/puppetlabs-apache.git", :ref => "1.4.0"
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/apache/metadata.json" should match /"name": "puppetlabs-apache"/
    And the file "modules/apache/metadata.json" should match /"version": "1\.4\.0"/

  Scenario: Switching a module from forge to git
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/postgresql', '7.4.1'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/
    And the file "modules/postgresql/metadata.json" should match /"version": "7\.4\.1"/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    When I overwrite "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/postgresql',
      :git => 'https://github.com/puppetlabs/puppetlabs-postgresql.git', :ref => 'v7.5.0'
    """
    And I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/
    And the file "modules/postgresql/metadata.json" should match /"version": "7\.5\.0"/
    And the file "modules/postgresql/.git/HEAD" should match /0a2cb69ccbbb0a55d42c5da33d44b0eaf33f9546/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Install a module with dependencies specified in metadata.json
    Given a file named "Puppetfile" with:
    """
    mod 'puppetlabs-apt', :git => 'https://github.com/puppetlabs/puppetlabs-apt.git', :ref => '1.5.2'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/apt/metadata.json" should match /"name": "puppetlabs-apt"/

  Scenario: Install a module with dependencies specified in a Puppetfile
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/with_puppetfile', :git => 'https://github.com/voxpupuli/librarian-puppet.git', :path => 'features/examples/with_puppetfile'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/with_puppetfile/metadata.json" should match /"name": "librarian-with_puppetfile"/
    And the file "modules/test/metadata.json" should match /"name": "librarian-test"/

  Scenario: Install a module with dependencies specified in a Puppetfile and metadata.json
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/with_puppetfile', :git => 'https://github.com/voxpupuli/librarian-puppet.git', :path => 'features/examples/with_puppetfile_and_metadata_json'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/with_puppetfile/metadata.json" should match /"name": "librarian-with_puppetfile_and_metadata_json"/
    And the file "modules/test/metadata.json" should match /"name": "maestrodev-test"/

  Scenario: Running install without metadata.json
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/stdlib', :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git', :ref => '4.6.0'
    """
    When I successfully run `librarian-puppet install`

  Scenario: Running install with metadata.json without dependencies
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/sqlite', :git => 'https://github.com/puppetlabs/puppetlabs-sqlite.git', :ref => '84a0a6'
    """
    When I successfully run `librarian-puppet install`

  Scenario: Install a module using metadata syntax
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/metadata_syntax', :git => 'https://github.com/voxpupuli/librarian-puppet.git', :path => 'features/examples/metadata_syntax'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/metadata_syntax/metadata.json" should match /"name": "librarian-metadata_syntax"/
    And the file "modules/test/metadata.json" should match /"name": "maestrodev-test"/

  Scenario: Install a module from git and using path
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'librarian-test', :git => 'https://github.com/voxpupuli/librarian-puppet.git', :path => 'features/examples/test'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/test/metadata.json" should match /"version": "0\.0\.1"/
    And a file named "modules/stdlib/metadata.json" should exist

  Scenario: Install a module from git without version
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'test', :git => 'https://github.com/voxpupuli/librarian-puppet.git', :path => 'features/examples/dependency_without_version'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/test/metadata.json" should match /"version": "0\.0\.1"/
    And a file named "modules/stdlib/metadata.json" should exist

  Scenario: Install from Puppetfile with duplicated entries
    Given a file named "Puppetfile" with:
    """
    mod 'puppetlabs-stdlib',
      :git => 'git://github.com/puppetlabs/puppetlabs-stdlib.git', :ref => 'main'

    mod 'puppetlabs-stdlib',
      :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git', :ref => 'main'
    """
    When I successfully run `librarian-puppet install`
    And the output should contain "Dependency 'puppetlabs-stdlib' duplicated for module, merging"
