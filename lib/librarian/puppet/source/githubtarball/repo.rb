require 'uri'
require 'net/https'
require 'open-uri'
require 'json'

require 'librarian/puppet/version'
require 'librarian/puppet/source/repo'

module Librarian
  module Puppet
    module Source
      class GitHubTarball
        class Repo < Librarian::Puppet::Source::Repo
          include Librarian::Puppet::Util

          TOKEN_KEY = 'GITHUB_API_TOKEN'

          def versions
            return @versions if @versions

            data = api_call("/repos/#{source.uri}/tags")
            raise Error, "Unable to find module '#{source.uri}' on https://github.com" if data.nil?

            all_versions = data.map { |r| r['name'].gsub(/^v/, '') }.sort.reverse

            all_versions.delete_if do |version|
              version !~ /\A\d+\.\d+(\.\d+.*)?\z/
            end

            @versions = all_versions.compact
            debug { "  Module #{name} found versions: #{@versions.join(', ')}" }
            @versions
          end

          def manifests
            versions.map do |version|
              Manifest.new(source, name, version)
            end
          end

          def install_version!(version, install_path)
            if environment.local? && !vendored?(vendored_name, version)
              raise Error, "Could not find a local copy of #{source.uri} at #{version}."
            end

            vendor_cache(source.uri.to_s, version) unless vendored?(vendored_name, version)

            cache_version_unpacked! version

            install_path.rmtree if install_path.exist? && rsync? != true

            unpacked_path = version_unpacked_cache_path(version).children.first
            cp_r(unpacked_path, install_path)
          end

          def cache_version_unpacked!(version)
            path = version_unpacked_cache_path(version)
            return if path.directory?

            path.mkpath

            target = vendored?(vendored_name, version) ? vendored_path(vendored_name, version) : name

            Librarian::Posix.run!(%W[tar xzf #{target} -C #{path}])
          end

          def vendor_cache(name, version)
            clean_up_old_cached_versions(vendored_name(name))

            url = "https://api.github.com/repos/#{name}/tarball/#{version}"
            add_api_token_to_url(url)

            environment.vendor!
            File.open(vendored_path(vendored_name(name), version).to_s, 'wb') do |f|
              debug { "Downloading <#{url}> to <#{f.path}>" }
              URI.open(url,
                       'User-Agent' => "librarian-puppet v#{Librarian::Puppet::VERSION}") do |res|
                while buffer = res.read(8192)
                  f.write(buffer)
                end
              end
            rescue OpenURI::HTTPError => e
              raise e, "Error requesting <#{url}>: #{e}"
            end
          end

          def clean_up_old_cached_versions(name)
            Dir["#{environment.vendor_cache}/#{name}*.tar.gz"].each do |old_version|
              FileUtils.rm old_version
            end
          end

          def token_key_value
            ENV.fetch(TOKEN_KEY, nil)
          end

          def token_key_nil?
            token_key_value.nil? || token_key_value.empty?
          end

          def add_api_token_to_url(url)
            if token_key_nil?
              debug { "#{TOKEN_KEY} environment value is empty or missing" }
            elsif url.include? '?'
              url << "&access_token=#{ENV.fetch(TOKEN_KEY, nil)}"
            else
              url << "?access_token=#{ENV.fetch(TOKEN_KEY, nil)}"
            end
            url
          end

          private

          def api_call(path)
            tags = []
            url = "https://api.github.com#{path}?page=1&per_page=100"
            while true
              debug { "  Module #{name} getting tags at: #{url}" }
              add_api_token_to_url(url)
              response = http_get(url, headers: {
                                    'User-Agent' => "librarian-puppet v#{Librarian::Puppet::VERSION}",
                                  })

              code = response.code.to_i
              data = response.body

              if code == 200
                tags.concat JSON.parse(data)
              else
                begin
                  message = JSON.parse(data)['message']
                  if code == 403 && message && message.include?('API rate limit exceeded')
                    raise Error, message + " -- increase limit by authenticating via #{TOKEN_KEY}=your-token"
                  elsif message
                    raise Error, "Error fetching #{url}: [#{code}] #{message}"
                  end
                rescue JSON::ParserError
                  # response does not return json
                end
                raise Error, "Error fetching #{url}: [#{code}] #{response.body}"
              end

              # next page
              break if response['link'].nil?

              next_link = response['link'].split(',').select { |l| l.match(/rel=.*next.*/) }
              break if next_link.empty?

              url = next_link.first.match(/<(.*)>/)[1]
            end
            tags
          end

          def http_get(url, options)
            uri = URI.parse(url)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            request = Net::HTTP::Get.new(uri.request_uri)
            options[:headers].each { |k, v| request.add_field k, v }
            http.request(request)
          end

          def vendored_name(name = source.uri.to_s)
            name.sub('/', '-')
          end
        end
      end
    end
  end
end
