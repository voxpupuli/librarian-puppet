Feature: cli/update
  Puppet librarian needs to update modules properly

  Scenario: Updating a module with no Puppetfile and with metadata.json
    Given a file named "metadata.json" with:
    """
    {
      "name": "random name",
      "dependencies": [
        {
          "name": "puppetlabs/stdlib",
          "version_requirement": "3.1.x"
        }
      ]
    }
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I successfully run `librarian-puppet update puppetlabs/stdlib`
    And the file "Puppetfile" should not exist
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module with no Puppetfile and with Modulefile
    Given a file named "Modulefile" with:
    """
    name "random name"
    dependency "puppetlabs/stdlib", "3.1.x"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update puppetlabs/stdlib`
    Then the exit status should be 0
    And the file "Puppetfile" should not exist
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I successfully run `librarian-puppet update puppetlabs-stdlib`
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module using organization/module
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I successfully run `librarian-puppet update --verbose puppetlabs/stdlib`
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module from git with a branch ref
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod "theforeman-dns",
      :git => "https://github.com/theforeman/puppet-dns.git", :ref => "4.1-stable"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs-concat (2.2.1)
          puppetlabs-stdlib (>= 4.2.0, < 5.0.0)
        puppetlabs-stdlib (4.25.1)

    GIT
      remote: https://github.com/theforeman/puppet-dns.git
      ref: 4.1-stable
      sha: 29150008f81c0be6de4d8913f60b9e014c3f398e
      specs:
        theforeman-dns (4.1.0)
          puppetlabs-concat (>= 1.0.0, < 3.0.0)
          puppetlabs-stdlib (>= 4.13.1, < 5.0.0)

    DEPENDENCIES
      theforeman-dns (>= 0)
    """
    When I successfully run `librarian-puppet install`
    And the git revision of module "dns" should be "29150008f81c0be6de4d8913f60b9e014c3f398e"
    When I successfully run `librarian-puppet update`
    And the git revision of module "dns" should be "e530ae8b1f0d85b37a69e779d1de51d054ecc9f1"

  Scenario: Updating a module with invalid versions in git
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod "apache",
      :git => "https://github.com/puppetlabs/puppetlabs-apache.git", :ref => "0.5.0-rc1"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/firewall (0.0.4)
        puppetlabs/stdlib (3.2.0)

    GIT
      remote: https://github.com/puppetlabs/puppetlabs-apache.git
      ref: 0.5.0-rc1
      sha: 94ebca3aaaf2144a7b9ce7ca6a13837ec48a7e2a
      specs:
        apache ()
          puppetlabs/firewall (>= 0.0.4)
          puppetlabs/stdlib (>= 2.2.1)

    DEPENDENCIES
      apache (>= 0)
    """
    When I successfully run `librarian-puppet update apache`
    And the file "Puppetfile.lock" should match /sha: d81999533af54a6fe510575d3b143308184a5005/
    And the file "modules/apache/Modulefile" should match /name *'puppetlabs-apache'/
    And the file "modules/apache/Modulefile" should match /version *'0\.5\.0-rc1'/

  Scenario: Updating a module that is not in the Puppetfile
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update stdlib`
    Then the exit status should be 1
    And the output should contain "Unable to find module stdlib"

  Scenario: Updating a module to a .10 release to ensure versions are correctly ordered
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'maestrodev/test'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        maestrodev/test (1.0.2)

    DEPENDENCIES
      maestrodev/test (>= 0)
    """
    When I successfully run `librarian-puppet update --verbose`
    And the file "Puppetfile.lock" should match /maestrodev.test \(1\.0\.[1-9][0-9]\)/
    And the file "modules/test/Modulefile" should contain "name 'maestrodev-test'"
    And the file "modules/test/Modulefile" should match /version '1\.0\.[1-9][0-9]'/

  Scenario: Updating a forge module with the rsync configuration
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'maestrodev/test'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        maestrodev/test (1.0.2)

    DEPENDENCIES
      maestrodev/test (>= 0)
      """
    And a file named ".librarian/puppet/config" with:
    """
    ---
    LIBRARIAN_PUPPET_RSYNC: 'true'
    """
    When I successfully run `librarian-puppet config`
    And the output should contain "rsync: true"
    When I successfully run `librarian-puppet update --verbose`
    And a directory named "modules/test" should exist
    And the file "modules/test" should have an inode and ctime
    When I successfully run `librarian-puppet update --verbose`
    And a directory named "modules/test" should exist
    And the file "modules/test" should have the same inode and ctime as before

  Scenario: Updating a git module with the rsync configuration
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod "theforeman-dns",
      :git => "https://github.com/theforeman/puppet-dns.git", :ref => "4.1-stable"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forgeapi.puppetlabs.com
      specs:
        puppetlabs-concat (2.2.1)
          puppetlabs-stdlib (>= 4.2.0, < 5.0.0)
        puppetlabs-stdlib (4.25.1)

    GIT
      remote: https://github.com/theforeman/puppet-dns.git
      ref: 4.1-stable
      sha: 29150008f81c0be6de4d8913f60b9e014c3f398e
      specs:
        theforeman-dns (4.1.0)
          puppetlabs-concat (>= 1.0.0, < 3.0.0)
          puppetlabs-stdlib (>= 4.13.1, < 5.0.0)

    DEPENDENCIES
      theforeman-dns (>= 0)
    """
    And a file named ".librarian/puppet/config" with:
    """
    ---
    LIBRARIAN_PUPPET_RSYNC: 'true'
    """
    When I successfully run `librarian-puppet config`
    And the output should contain "rsync: true"
    When I successfully run `librarian-puppet install`
    And the file "Puppetfile.lock" should contain "29150008f81c0be6de4d8913f60b9e014c3f398e"
    And the git revision of module "dns" should be "29150008f81c0be6de4d8913f60b9e014c3f398e"
    And a directory named "modules/dns" should exist
    When I successfully run `librarian-puppet update --verbose`
    And a directory named "modules/dns" should exist
    And the file "modules/dns" should have an inode and ctime
    And the file "Puppetfile.lock" should contain "e530ae8b1f0d85b37a69e779d1de51d054ecc9f1"
    And the git revision of module "dns" should be "e530ae8b1f0d85b37a69e779d1de51d054ecc9f1"
    When I successfully run `librarian-puppet update --verbose`
    And a directory named "modules/dns" should exist
    And the file "modules/dns" should have the same inode and ctime as before
    And the file "Puppetfile.lock" should contain "e530ae8b1f0d85b37a69e779d1de51d054ecc9f1"
    And the git revision of module "dns" should be "e530ae8b1f0d85b37a69e779d1de51d054ecc9f1"
