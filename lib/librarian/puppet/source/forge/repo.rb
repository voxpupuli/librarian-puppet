require 'json'
require 'open-uri'
require 'librarian/puppet/util'
require 'librarian/puppet/source/repo'

module Librarian
  module Puppet
    module Source
      class Forge
        class Repo < Librarian::Puppet::Source::Repo
          include Librarian::Puppet::Util

          def versions
            return @versions if @versions
            @versions = get_versions
            if @versions.empty?
              info { "No versions found for module #{name}" }
            else
              debug { "  Module #{name} found versions: #{@versions.join(", ")}" }
            end
            @versions
          end

          # fetch list of versions ordered for newer to older
          def get_versions
            # implement in subclasses
          end

          # return map with dependencies in the form {module_name => version,...}
          # version: Librarian::Manifest::Version
          def dependencies(version)
            # implement in subclasses
          end

          # Download the module to the path specified
          def download(name, version, path)
            # implement in subclasses
          end

          def manifests
            versions.map do |version|
              Manifest.new(source, name, version)
            end
          end

          def install_version!(version, install_path)
            if environment.local? && !vendored?(name, version)
              raise Error, "Could not find a local copy of #{name} at #{version}."
            end

            if environment.vendor?
              vendor_cache(name, version) unless vendored?(name, version)
            end

            cache_version_unpacked! version

            if install_path.exist? && rsync? != true
              install_path.rmtree
            end

            unpacked_path = version_unpacked_cache_path(version).join(module_name(name))

            unless unpacked_path.exist?
              raise Error, "#{unpacked_path} does not exist, something went wrong. Try removing it manually"
            else
              cp_r(unpacked_path, install_path)
            end

          end

          def cache_version_unpacked!(version)
            path = version_unpacked_cache_path(version)
            return if path.directory?

            path.mkpath

            download(name, version, "#{path.to_s}/#{name}-#{version}.tar.gz")

            begin
              Librarian::Posix.run!(%W{tar -xf #{path.to_s}/#{name}-#{version}.tar.gz -C #{path.to_s}})
              FileUtils::mv "#{path.to_s}/#{name}-#{version}", "#{path.to_s}/#{name.split('-')[1]}"
            rescue Posix::CommandFailure => e
              # Rollback the directory if the puppet module had an error
              begin
                path.unlink
              rescue => u
                debug("Unable to rollback path #{path}: #{u}")
              end
              tar = Dir[File.join(path.to_s, "**/*.tar.gz")]
              msg = ""
              if e.message =~ /Unexpected EOF in archive/ and !tar.empty?
                file = tar.first
                msg = " (looks like an incomplete download of #{file})"
              end
              raise Error, "Error extracting module #{msg}."
            end

          end


          def vendor_cache(name, version)
            path = vendored_path(name, version).to_s
            environment.vendor!

            download(name, version, path)

          end

        end
      end
    end
  end
end
