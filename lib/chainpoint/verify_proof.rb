module Chainpoint
  class VerifyProof
    include ::Chainpoint::Utils::Helpers
    include ::Chainpoint::Utils::Network
    include ::Chainpoint::Utils::Proofs

    attr_reader :results

    def initialize(proofs, uri)
      @proofs  = proofs || []
      @uri     = uri || ''
      @results = []
    end

    def perform
      evaluated_proofs           = ::Chainpoint::EvaluateProof.new(@proofs).perform.flat_proofs
      gateway_uri                = validate_gateway_uri
      single_gateway_flat_proofs = evaluated_proofs.map do |proof|
        proof = proof.dup
        old_proof_uri = URI.parse(proof["uri"])
        proof["uri"]  = URI.join(gateway_uri, old_proof_uri.path).to_s
        proof
      end

      flat_proofs = single_gateway_flat_proofs.uniq do |p|
        [
            p["hash"],
            p["proof_id"],
            p["hash_received"],
            p["branch"],
            p["uri"],
            p["type"],
            p["anchor_id"],
            p["expected_value"]
        ]
      end

      uniq_anchor_uris = flat_proofs.map { |p| p["uri"] }.uniq

      gateways_with_get_opts = uniq_anchor_uris.map do |anchor_uri|
        {
            "method"  => 'GET',
            "uri"     => anchor_uri,
            "body"    => {},
            "headers" => {
                'Content-Type' => 'application/json',
                'Accept'       => 'application/json'
            },
            "timeout" => 10000
        }
      end

      fetch_results = fetch_endpoints(gateways_with_get_opts)

      get_responses = []
      fetch_results.each do |res|
        res["error"].nil? ? (get_responses << res["response"]) : (puts res["error"])
      end

      flat_parsed_body = get_responses.flatten
      hashes_found     = {}
      gateways_with_get_opts.each_with_index do |opt, i|
        unless flat_parsed_body[i].nil?
          uri_segments               = opt["uri"].split('/')
          block_height               = uri_segments[uri_segments.length - 2]
          hashes_found[block_height] = flat_parsed_body[i]
        end
      end

      raise Chainpoint::Error, "No hashes were found" if hashes_found.empty?

      flat_proofs.each do |proof|
        uri_segments = proof["uri"].split('/')
        block_height = uri_segments[uri_segments.length - 2]
        if proof["expected_value"] == hashes_found[block_height]
          proof["verified"]    = true
          proof["verified_at"] = Time.now.utc.iso8601
        else
          proof["verified"]    = false
          proof["verified_at"] = nil
        end

        @results << proof
      end

      self
    end

    private

    def validate_gateway_uri
      #   // Validate and return an Array with a single Gateway URI
      if @uri.empty?
        gateway_uri = ::Chainpoint::Configuration::GATEWAY_URI
      else
        raise Chainpoint::Error, 'uri arg must be a String' unless @uri.is_a?(String)
        raise Chainpoint::Error, "uri arg contains invalid Gateway URI : #{@uri}" unless is_valid_uri?(@uri)
        gateway_uri = @uri
      end
      gateway_uri
    end
  end
end