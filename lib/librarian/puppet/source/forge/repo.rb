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
              debug { "  Module #{name} found versions: #{@versions.join(', ')}" }
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

          # return the url for a specific version tarball
          # version: Librarian::Manifest::Version
          def url(name, version)
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

            vendor_cache(name, version) if environment.vendor? && !vendored?(name, version)

            cache_version_unpacked! version

            install_path.rmtree if install_path.exist? && rsync? != true

            unpacked_path = version_unpacked_cache_path(version).join(module_name(name))

            unless unpacked_path.exist?
              raise Error, "#{unpacked_path} does not exist, something went wrong. Try removing it manually"
            end

            cp_r(unpacked_path, install_path)
          end

          def cache_version_unpacked!(version)
            path = version_unpacked_cache_path(version)
            return if path.directory?

            path.mkpath

            target = vendored?(name, version) ? vendored_path(name, version).to_s : name

            module_repository = source.uri.to_s

            command = %W[puppet module install --version #{version} --target-dir]
            command.push(path.to_s, '--module_repository', module_repository, '--modulepath', path.to_s,
                         '--module_working_dir', path.to_s, '--ignore-dependencies', target)
            debug do
              "Executing puppet module install for #{name} #{version}: #{command.join(' ').gsub(module_repository,
                                                                                                source.to_s)}"
            end

            begin
              Librarian::Posix.run!(command)
            rescue Posix::CommandFailure => e
              # Rollback the directory if the puppet module had an error
              begin
                path.unlink
              rescue StandardError => u
                debug("Unable to rollback path #{path}: #{u}")
              end
              tar = Dir[File.join(path.to_s, '**/*.tar.gz')]
              msg = ''
              if e.message =~ /Unexpected EOF in archive/ and !tar.empty?
                file = tar.first
                msg = " (looks like an incomplete download of #{file})"
              end
              raise Error,
                    "Error executing puppet module install#{msg}. Check that this command succeeds:\n#{command.join(' ')}\nError:\n#{e.message}"
            end
          end

          def vendor_cache(name, version)
            url = url(name, version)
            path = vendored_path(name, version).to_s
            debug { "Downloading #{url} into #{path}" }
            environment.vendor!
            File.open(path, 'wb') do |f|
              URI.open(url, 'rb') do |input|
                f.write(input.read)
              end
            end
          end
        end
      end
    end
  end
end
