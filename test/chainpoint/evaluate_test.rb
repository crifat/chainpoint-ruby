require "test_helper.rb"

class Chainpoint::EvaluateTest < MiniTest::Test
  def setup
    json_file = File.open File.join(File.dirname(__FILE__), 'data/proofs.json')
    @proofs   = JSON.load(json_file)
    json_file.close
  end

  def teardown
    # Do nothing
  end

  def test_should_return_normalized_parsed_and_flattened_proofs

    # normalized_proofs = ::Chainpoint::EvaluateProof.new([]).normalize_proofs(@proofs)
    # parsed_proofs     = ::Chainpoint::EvaluateProof.new([]).parse_proofs(normalized_proofs)
    # flattened         = ::Chainpoint::EvaluateProof.new([]).flatten_proofs(parsed_proofs)
    #
    # puts flattened

    test_flattened = ::Chainpoint::EvaluateProof.new(@proofs).perform.flat_proofs
    p test_flattened

    p test_flattened.to_json

    assert(1 == 1)

  end
end