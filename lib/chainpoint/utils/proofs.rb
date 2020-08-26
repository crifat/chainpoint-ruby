require_relative 'helpers'

module Chainpoint
  module Utils
    module Proofs
      def map_submit_hashes_resp_to_proof_handles(responses = [])
        responses = test_array_args(responses)
        proof_handles = []
        # UUID is a v4 UUID
        group_id_list = responses.first[:response]["hashes"].map{SecureRandom.uuid} rescue []
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

    end
  end
end
