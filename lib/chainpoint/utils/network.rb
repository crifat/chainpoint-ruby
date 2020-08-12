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
        uri =~ /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
      end

      def is_valid_ip?(ip)
        return false if ip == '0.0.0.0'

        ip =~ /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/i
      end

      def submit_data(options)
        # base_uri = options[:base_uri]
        url = URI(options[:uri])

        http                  = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request               = case options[:method]
                                  when 'POST'
                                    Net::HTTP::Post.new(url)
                                  when "PUT"
                                    Net::HTTP::Put.new(url)
                                end
        options[:headers].each {|k, v| request[k.to_s] = v}
        request.body = (options[:body]|| {}).to_json

        http.request(request)
      end
    end
  end
end
