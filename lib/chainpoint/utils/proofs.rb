# require_relative 'helpers'

module Chainpoint
  module Utils
    module Proofs
      include Chainpoint::Utils::Helpers
      include Chainpoint::Utils::Parser

      def map_submit_hashes_resp_to_proof_handles(responses = [])
        responses     = test_array_args(responses)
        proof_handles = []
        # UUID is a v4 UUID
        group_id_list = responses.first[:response]["hashes"].map { SecureRandom.uuid } rescue []
        responses.each do |res|
          res[:response]["hashes"].each_with_index do |hash, idx|
            proof_handles << {
                uri:      res[:response]["meta"]["submitted_to"],
                hash:     hash["hash"],
                proof_id: hash["proof_id"],
                group_id: group_id_list[idx]
            }
          end
        end

        proof_handles
      end

      # Checks if a proof handle Object has valid params.
      #
      # @param {Object} handle - The proof handle to check
      # @returns {bool} true if handle is valid Object with expected params, otherwise false
      def is_valid_proof_handle(handle)
        !handle.empty? && handle.is_a?(Hash) && handle.key?('uri') && handle.key?('proof_id')
      end

      # validate and normalize proofs for actions such as parsing
      # @param {Array} proofs - An Array of String, or Object proofs from getProofs(), to be verified. Proofs can be in any of the supported JSON-LD or Binary formats.
      # @return {Array<Object>} - An Array of Objects, one for each proof submitted.
      def normalize_proofs(proofs)
        # Validate proofs arg
        test_array_args(proofs)

        # If any entry in the proofs Array is an Object, process
        # it assuming the same form as the output of getProofs().
        normalized = []
        proofs.each do |proof|
          if proof.is_a?(Hash) && proof.key?('proof') && proof['proof'].is_a?(String)
            # // Probably result of `submitProofs()` call. Extract proof String
            normalized << proof['proof']
          elsif proof.is_a?(Hash) && proof.key?('type') && proof['type'] === 'Chainpoint'
            # // Probably a JS Object Proof
            normalized << proof
          elsif proof.is_a?(String) && (is_json?(proof) || is_base64?(proof))
            # // Probably a JSON String or Base64 encoded binary proof
            normalized << proof
          elsif proof.is_a?(Hash) && !proof['proof'].nil? && proof.key?('proof_id')
            puts "no proof for proofId #{proof['proof_id']}"
          else
            puts 'proofs arg Array has elements that are not Objects or Strings'
          end
        end

        normalized
      end

      # * Parse an Array of proofs, each of which can be in any supported format.
      # *
      # * @param {Array} proofs - An Array of proofs in any supported form
      # * @returns {Array} An Array of parsed proofs
      def parse_proofs(proofs)
        # Validate proofs arg
        test_array_args(proofs)

        parsed_proofs = []
        proofs.each do |proof|
          if proof.is_a?(Hash)
            parsed_proofs << parse(proof)
          elsif is_json?(proof)
            # JSON-LD
            parsed_proofs << parse(JSON.parse(proof))
          elsif is_base64?(proof) || is_hex?(proof)
            parsed_proofs << parse(proof)
          else
            raise Chainpoint::Error, 'unknown proof format'
          end
        end

        parsed_proofs
      end

      # /**
      #  * Flatten an Array of parsed proofs where each proof anchor is
      #  * represented as an Object with all relevant proof data.
      #  *
      #  * @param {Array} parsedProofs - An Array of previously parsed proofs
      #  * @returns {Array} An Array of flattened proof objects
      #  */
      def flatten_proofs(parsed_proofs)
        test_array_args(parsed_proofs)

        flat_proof_anchors = []
        parsed_proofs.each do |parsed_proof|
          proof_anchors = flatten_proof_branches(parsed_proof["branches"])

          proof_anchors.each do |proof_anchor|
            flat_proof_anchors << {
                "hash"           => parsed_proof["hash"],
                "proof_id"       => parsed_proof["proof_id"],
                "hash_received"  => parsed_proof["hash_received"],
                "branch"         => proof_anchor["branch"],
                "uri"            => proof_anchor["uri"],
                "type"           => proof_anchor["type"],
                "anchor_id"      => proof_anchor["anchor_id"],
                "expected_value" => proof_anchor["expected_value"],
            }
          end
        end

        flat_proof_anchors
      end

      def flatten_proof_branches(proof_branch_array)
        test_array_args(proof_branch_array)
        flat_proof_anchors = []

        proof_branch_array.each do |proof_branch|
          anchors = proof_branch["anchors"]
          anchors.each do |anchor|
            flat_proof_anchors << {
                "branch"         => proof_branch["label"] || nil,
                "uri"            => anchor["uris"].first,
                "type"           => anchor["type"],
                "anchor_id"      => anchor["anchor_id"],
                "expected_value" => anchor["expected_value"]
            }
          end
          if !proof_branch["branches"].nil? && !proof_branch["branches"].empty?
            flat_proof_anchors.concat(flatten_proof_branches(proof_branch["branches"]))
          end
        end

        flat_proof_anchors
      end

      #  * Get raw btc transactions for each proof_id
      #  * @param {Array} proofs - array of previously parsed proofs
      #  * @return {Obect[]} - an array of objects with proof_id and raw btc tx
      def flatten_btc_branches(proof_branch_array)
        test_array_args(proof_branch_array)

        flattened_branches = []

        proof_branch_array.each do |proof_branch|
          btc_anchor = { "proof_id" => proof_branch["proof_id"] }

          if !proof_branch["branches"].nil? && !proof_branch["branches"].empty?
            proof_branch["branches"].each do |branch|
              # sub branches indicate other anchors
              # we want to find the sub-branch that anchors to btc
              if !branch["branches"].nil? && !branch["branches"].empty?
                # get the raw tx from the btc_anchor_branch
                btc_branch               = branch["branches"].find { |element| element["label"] == 'btc_anchor_branch' }
                btc_anchor["raw_btc_tx"] = btc_branch["raw_tx"]
                # get the btc anchor
                anchor = btc_branch["anchors"].find { |anchor| %w[btc tbtc].include?(anchor["type"]) }
                # add expected_value (i.e. the merkle root of anchored block)
                btc_anchor["expected_value"] = anchor["expected_value"]
                # add anchor_id (i.e. the anchored block height)
                btc_anchor["anchor_id"] = anchor["anchor_id"]
              end
            end
          end

          flattened_branches << btc_anchor
        end

        flattened_branches
      end

    end
  end
end
