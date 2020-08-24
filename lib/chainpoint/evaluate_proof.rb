module Chainpoint
  class EvaluateProof
    include ::Chainpoint::Utils::Helpers
    include ::Chainpoint::Utils::Network
    include ::Chainpoint::Utils::Proofs

    attr_reader :flat_proofs

    def initialize(proofs = [])
      @proofs      = proofs || []
      @flat_proofs = nil
    end

    def perform
      evaluate_proof

      self
    end

    private

    def evaluate_proof
      normalized_proofs = normalize_proofs(@proofs)
      parsed_proofs     = parse_proofs(normalized_proofs)
      @flat_proofs      = flatten_proofs(parsed_proofs)
    end

  end
end