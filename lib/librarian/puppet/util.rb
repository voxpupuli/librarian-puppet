require 'rsync'

module Librarian
  module Puppet

    module Util

      def debug(*args, &block)
        environment.logger.debug(*args, &block)
      end
      def info(*args, &block)
        environment.logger.info(*args, &block)
      end
      def warn(*args, &block)
        environment.logger.warn(*args, &block)
      end

      def rsync?
          environment.config_db.local['rsync'] == 'true'
      end

      # workaround Issue #173 FileUtils.cp_r will fail if there is a symlink that points to a missing file
      # or when the symlink is copied before the target file when preserve is true
      # see also https://tickets.opscode.com/browse/CHEF-833
      #
      # If the rsync configuration parameter is set, use rsync instead of FileUtils
      def cp_r(src, dest)
        if rsync?
          if Gem.win_platform?
            src_clean = "#{src}".gsub(/^([a-z])\:/i,'/cygdrive/\1')
            dest_clean = "#{dest}".gsub(/^([a-z])\:/i,'/cygdrive/\1')
          else
            src_clean = src
            dest_clean = dest
          end
          debug { "Copying #{src_clean}/ to #{dest_clean}/ with rsync -avz --delete" }
          result = Rsync.run(File.join(src_clean, "/"), File.join(dest_clean, "/"), ['-avz', '--delete'])
          if result.success?
            debug { "Rsync from #{src_clean}/ to #{dest_clean}/ successfull" }
          else
            msg = "Failed to rsync from #{src_clean}/ to #{dest_clean}/: " + result.error
            raise Error, msg
          end
        else
          begin
            FileUtils.cp_r(src, dest, :preserve => true)
          rescue Errno::ENOENT, Errno::EACCES
            debug { "Failed to copy from #{src} to #{dest} preserving file types, trying again without preserving them" }
            FileUtils.rm_rf(dest)
            FileUtils.cp_r(src, dest)
          end
        end
      end

      # Remove user and password from a URI object
      def clean_uri(uri)
        new_uri = uri.clone
        new_uri.user = nil
        new_uri.password = nil
        new_uri
      end

      # normalize module name to use organization-module instead of organization/module
      def normalize_name(name)
        name.sub('/','-')
      end

      # get the module name from organization-module
      def module_name(name)
        # module name can't have dashes, so let's assume it is everything after the last dash
        name.rpartition('-').last
      end

      def download_file(url, path)
        File.open(path, 'wb') do |f|
          begin
            debug { "Downloading <#{url}> to <#{f.path}>" }
            open(url,
                 "User-Agent" => "librarian-puppet v#{Librarian::Puppet::VERSION}") do |res|
              while buffer = res.read(8192)
                f.write(buffer)
              end
            end
          rescue OpenURI::HTTPError => e
            raise e, "Error requesting <#{url}>: #{e.to_s}"
          end
        end
      end

      # deprecated
      alias :organization_name :module_name
    end
  end
end
