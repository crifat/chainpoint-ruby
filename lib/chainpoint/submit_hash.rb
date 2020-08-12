module Chainpoint
  class SubmitHash
    include Chainpoint::Utils::Helpers
    include Chainpoint::Utils::Network
    include Chainpoint::Utils::Proofs

    attr_reader :proof_handles

    def initialize(hashes, uris = [])
      @hashes = hashes
      @uris   = uris || []
      @proof_handles = []
    end

    def perform
      validate_hash_args(@hashes)
      validate_uri_args(@uris)

      gateway_uris = []

      if @uris.empty?
        begin
          core_ips     = get_cores(3)
          all_core_ips = get_core_peer_list(core_ips)
          gateways     = get_gateway_list(all_core_ips)
          gateway_uris = gateways.select { |ip| ip != ::Chainpoint::Configuration::PROOF_WHITELIST_IP }
        rescue => e
          puts "getting GatewayIps from network failed, falling back to defaults: #{e.message}"
          gateway_uris = ::Chainpoint::Configuration::DEFAULT_GATEWAY_IPS
        end
        gateway_uris = gateway_uris.map{|uri| "http://#{uri}"}
      else
        uris     = @uris.uniq
        bad_uris = uris.reject { |uri| is_valid_uri?(uri) }
        raise Chainpoint::Error, "uris arg contains invalid URIs : #{bad_uris.join(', ')}" unless bad_uris.empty?
        gateway_uris = uris
      end

      begin
        success_results = fetch_endpoints(gateway_uris, @hashes)
        @proof_handles = map_submit_hashes_resp_to_proof_handles(success_results)
      rescue => e
        puts e
        raise Chainpoint::Error, e
      end

      self
    end

    private

    def fetch_endpoints(gateway_uris, hashes)
      results = []
      gateway_uris.each do |geteway_uri|
        options  = gateway_uri_options(geteway_uri, hashes)
        begin
          response = submit_data(options)
          raise Chainpoint::Error, response.message if response.code.to_i >= 400
          result = JSON.parse(response.read_body)
          result["meta"]["submitted_to"] = options[:base_uri]
          results << {
              uri: options[:base_uri],
              response: result,
              error: nil
          }
        rescue => e

          puts e.message
        end
      end

      results
    end

    def gateway_uri_options(gateway_uri, hashes)
      {
          method:   'POST',
          base_uri: gateway_uri,
          uri:      gateway_uri + '/hashes',
          body:     {
              hashes: hashes
          },
          headers:  {
              'Content-Type': 'application/json',
              Accept:         'application/json'
          },
          timeout:  10000
      }
    end

  end
end
