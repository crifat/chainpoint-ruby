module Chainpoint
  class GetProof
    include ::Chainpoint::Utils::Helpers
    include ::Chainpoint::Utils::Network
    include ::Chainpoint::Utils::Proofs

    attr_reader :proofs

    def initialize(proof_handlers = [])
      @proof_handlers = proof_handlers || []
      @proofs         = nil
    end

    def perform
      validate_proof_handlers
      get_proofs

      self
    end

    private

    def get_proofs
      uuids_by_gateway = {}
      begin
        #     // Collect together all proof UUIDs destined for a single Gateway
        #     // so they can be submitted to the Gateway in a single request.
        @proof_handlers.each do |ph|
          uuids_by_gateway[ph['uri']] ||= []
          uuids_by_gateway[ph['uri']] << ph['proof_id']
        end

        gateways_with_get_opts_data = gateways_with_get_opts(uuids_by_gateway)

        @proofs = fetch_endpoints(gateways_with_get_opts_data)
      rescue => e
        puts e.message
        raise ::Chainpoint::Error, e.message
      end

    end

    def fetch_endpoints(gateway_uris_opts)
      results = []
      gateway_uris_opts.each do |options|
        begin
          response = submit_data(options)
          raise ::Chainpoint::Error, response.message if response.code.to_i >= 400
          result                     = JSON.parse(response.read_body)
          result.map! { |r| r["anchors_complete"] ||= []; r }
          results << result
        rescue => e
          puts e.message
        end
      end

      results.flatten
    end

    #     // For each Gateway construct a set of GET options including
    #     // the `proofIds` header with a list of all hash ID's to retrieve
    #     // proofs for from that Gateway.
    def gateways_with_get_opts(uuids_by_gateway)
      uuids_by_gateway.map do |gateway_uri, proof_ids|
        {
            "method"  => 'GET',
            "uri"     => gateway_uri + '/proofs',
            "body"    => {},
            "headers" => {
                'accept'       => 'application/json',
                'content-type' => 'application/json',
                'proofIds' => proof_ids.join(',')
            },
            'timeout' => 10000
        }
      end
    end

    def validate_proof_handlers
      # Validate all proofHandles provided
      test_array_args(@proof_handlers)
      raise ::Chainpoint::Error, 'proofHandles Array contains invalid Objects' if @proof_handlers.any? { |handler| !is_valid_proof_handle(handler) }
      raise ::Chainpoint::Error, 'proofHandles arg must be an Array with <= 250 elements' if @proof_handlers.size > 250

      # Validate that *all* URI's provided are valid or throw
      bad_handle_uris = @proof_handlers.reject { |ph| is_valid_uri?(ph['uri']) }

      raise ::Chainpoint::Error, "some proof handles contain invalid URI values : #{bad_handle_uris.map { |h| h['uri'] }.join(', ')}" unless bad_handle_uris.empty?

      # Validate that *all* proofIds provided are valid or throw
      bad_handle_uuids = @proof_handlers.reject { |ph| is_valid_v1_uuid?(ph['proof_id']) }
      raise ::Chainpoint::Error, "some proof handles contain invalid proof_id UUID values : #{bad_handle_uuids.map { |h| h['proof_id'] }.join(', ')}" unless bad_handle_uuids.empty?
    end

  end
end