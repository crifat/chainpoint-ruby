module Chainpoint
  module Utils
    module Network
      def get_cores(num = 1)
        num ||= 1
        raise Chainpoint::Error, "num arg must be an Integer >= 1" unless num.to_i > 0

        Chainpoint::Configuration::CORE_IPS.sample(num)
      end


      # Retrieve an Array of discovered Core URIs.
      #
      # @param {array} seedIps - array of seed IPs to use for peer discovery
      # @returns {string} - Returns an Array of Core IPs.

      def get_core_peer_list(seed_ips)
        seed_ips.shuffle!.each do |target_ip|
          begin
            response = Net::HTTP.get_response(target_ip, '/peers')
            response_data = JSON.parse(response.body)
            return response_data << target_ip
          rescue => e
            puts "Core IP #{target_ip} not responding to peers requests: #{e.message}"
          end
        end

        raise Chainpoint::Error, "Unable to retrieve Core peer list"
      end


      # Retrieve an Array of whitelisted Gateway URIs
      #
      # @param {array} coreIps - array of seed IPs to use for gateway discovery
      # @returns {string} - Returns an Array of Gateway IPs.
      #

      def get_gateway_list(core_ips)
        gateway_ips = []
        core_ips.each do |target_ip|
          begin
            response = Net::HTTP.get_response(target_ip, '/gateways/public')
            raise Chainpoint::Error, "no gateway IPs returned from Core IP #{target_ip}" if response.body.size == 0
            gateway_ips << JSON.parse(response.body)
            gateway_ips.flatten!
            return gateway_ips if gateway_ips.size >= 3
          rescue => e
            puts "Core IP #{target_ip} not responding to gateways requests: #{e.message}"
          end
        end

        raise Chainpoint::Error, "Unable to retrieve Core peer list"
      end

      def is_valid_uri?(uri)
        return false unless uri.is_a? String
        return false unless is_uri?(uri)

        is_valid_ip?(URI(uri).hostname)
      end

      def is_uri?(uri)
        # uri =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
        u = URI.parse(uri)
        u.is_a?(URI::HTTP) && !u.host.nil?
      rescue URI::InvalidURIError
        false
      end

      def is_valid_ip?(ip)
        return false if ip == '0.0.0.0'
        # ip =~ /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/i

        # support IPv4 and IPv6
        ip =~ /((^\s*((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))\s*$)|(^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$))/
      end

      def submit_data(options)
        url = URI(options["uri"])

        http             = Net::HTTP.new(url.host, url.port)
        http.use_ssl     = url.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = case options["method"]
                    when 'POST'
                      Net::HTTP::Post.new(url)
                    when "PUT"
                      Net::HTTP::Put.new(url)
                    else
                      Net::HTTP::Get.new(url)
                  end
        options["headers"].each { |k, v| request[k] = v }
        request.body = (options["body"] || {}).to_json unless request.is_a?(Net::HTTP::Get)

        http.request(request)
      end
    end
  end
end
