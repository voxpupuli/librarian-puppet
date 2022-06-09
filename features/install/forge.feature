Feature: cli/install/forge
  Puppet librarian needs to install modules from the Puppet Forge

  Scenario: Installing a module and its dependencies
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/ntp'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/ntp/metadata.json" should match /"name": "puppetlabs-ntp"/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Running install with no Puppetfile and metadata.json
    Given there is no Puppetfile
    And a file named "metadata.json" with:
    """
    {
      "name": "random name",
      "dependencies": [
        {
          "name": "puppetlabs/stdlib",
          "version_requirement": "4.1.0"
        }
      ]
    }
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Running install with no Puppetfile and Modulefile
    Given there is no Puppetfile
    And a file named "Modulefile" with:
    """
    name "random name"
    dependency "puppetlabs/stdlib", "4.1.0"
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Installing a module without forge
    Given a file named "Puppetfile" with:
    """
    mod 'puppetlabs/stdlib', '4.1.0'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 1
    And the output should contain "forge entry is not defined in Puppetfile"

  Scenario: Installing an exact version of a module
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/apt', '0.0.4'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "modules/apt/Modulefile" should match /version *'0\.0\.4'/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  # Puppet Module tool does not support spaces
  # https://github.com/rodjek/librarian-puppet/issues/201
  # https://tickets.puppetlabs.com/browse/PUP-2278
  @spaces
  Scenario: Installing a module in a path with spaces
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"
    mod 'puppetlabs/stdlib', '4.1.0'
    """
    When PENDING I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Installing a module with invalid versions in the forge
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/apache', '7.0.0' # compatible with stdlib 8
    mod 'puppetlabs/postgresql', '7.4.0' # incompatible with stdlib 8

    """
    # Default timeout is 15 seconds but this is too short in most cases
    When I successfully run `librarian-puppet install --verbose` for up to 30 seconds
    And the file "modules/apache/metadata.json" should match /"name": "puppetlabs-apache"/
    And the file "modules/apache/metadata.json" should match /"version": "7\.0\.0"/
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/
    And the file "modules/postgresql/metadata.json" should match /"version": "7\.4\.0"/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/metadata.json" should match /"version": "7\.1\.0"/

  Scenario: Installing a module with several constraints
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/apt', '>=1.0.0', '<1.0.1'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/apt/Modulefile" should match /name *'puppetlabs-apt'/
    And the file "modules/apt/Modulefile" should match /version *'1\.0\.0'/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Changing the path
    Given a directory named "puppet"
    And a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/ntp', '3.0.3'
    """
    When I run `librarian-puppet install --path puppet/modules`
    And I run `librarian-puppet config`
    Then the exit status should be 0
    And the output from "librarian-puppet config" should contain "path: puppet/modules"
    And the file "puppet/modules/ntp/Modulefile" should match /name *'puppetlabs-ntp'/
    And the file "puppet/modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Handle range version numbers
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/postgresql', '7.4.1'
    mod 'puppetlabs/apt', '< 8.4.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/
    And the file "modules/postgresql/metadata.json" should match /"version": "7\.4\.1"/
    And the file "modules/apt/metadata.json" should match /"name": "puppetlabs-apt"/
    And the file "modules/apt/metadata.json" should match /"version": "8\.3\.0"/

    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/postgresql', :git => 'https://github.com/puppetlabs/puppet-postgresql', :ref => 'v7.5.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/
    And the file "modules/postgresql/metadata.json" should match /"version": "7\.5\.0"/
    And the file "modules/apt/metadata.json" should match /"name": "puppetlabs-apt"/
    And the file "modules/apt/metadata.json" should not match /"version": "8\.3\.0"/

  Scenario: Installing a module that does not exist
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/xxxxx'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 1
    And the output should match:
      """
      Unable to find module 'puppetlabs-xxxxx' on https://forgeapi.puppetlabs.com
      """

  Scenario: Install a module with conflicts
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/apache', '0.6.0'
    mod 'puppetlabs/stdlib', '<2.2.1'
    """
    When I run `librarian-puppet install`
    Then the exit status should be 1
    And the output should contain "Could not resolve the dependencies"

  Scenario: Install a module from the Forge with dependencies without version
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'sbadia/gitlab', '0.1.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/gitlab/Modulefile" should match /version *'0\.1\.0'/

  Scenario: Source dependencies from Modulefile
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    modulefile
    """
    And a file named "Modulefile" with:
    """
    name "random name"
    dependency "puppetlabs/postgresql", "4.0.0"
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/

  Scenario: Source dependencies from metadata.json
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    metadata
    """
    And a file named "metadata.json" with:
    """
    {
      "name": "random name",
      "dependencies": [
        {
          "name": "puppetlabs/postgresql",
          "version_requirement": "4.0.0"
        }
      ]
    }
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/

  Scenario: Source dependencies from Modulefile using dash instead of slash
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    modulefile
    """
    And a file named "Modulefile" with:
    """
    name "random name"
    dependency "puppetlabs-postgresql", "4.0.0"
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "modules/postgresql/metadata.json" should match /"name": "puppetlabs-postgresql"/

  Scenario: Installing a module with duplicated dependencies
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'pdxcat/collectd', '2.1.0'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/collectd/Modulefile" should match /name *'pdxcat-collectd'/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/

  Scenario: Installing two modules with same name, alphabetical order wins
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'theforeman-dhcp', '4.0.0'
    mod 'puppet-dhcp', '2.0.0'
    """
    When I successfully run `librarian-puppet install --verbose`
    And the file "modules/dhcp/metadata.json" should match /"name": "theforeman-dhcp"/
    And the output should contain "Dependency on module 'dhcp' is fullfilled by multiple modules and only one will be used"

  @other-forge
  Scenario: Installing from another forge with local reference should not try to download anything from the official forge
    Given a file named "Puppetfile" with:
    """
    forge "http://127.0.0.1"

    mod 'tester/tester', :path => './tester-tester'
    """
    And a file named "tester-tester/metadata.json" with:
    """
    {
        "name": "tester-tester",
        "version": "0.1.0",
        "author": "Basilio Vera",
        "summary": "Just our own test",
        "license": "MIT",
        "dependencies": [
            { "name": "puppetlabs/inifile" },
            { "name": "tester/tester_dependency1" }
        ]
    }
    """

    When I run `librarian-puppet install --verbose`
    And the output should not contain "forgeapi.puppetlabs.com"
    And the output should contain "Querying Forge API for module puppetlabs-inifile: http://127.0.0.1/api/v1/releases.json?module=puppetlabs/inifile"
