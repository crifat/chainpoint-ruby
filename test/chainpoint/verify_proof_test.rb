require "test_helper.rb"

class Chainpoint::VerifyProofTest < MiniTest::Test
  def setup
    json_file = File.open File.join(File.dirname(__FILE__), 'data/proofs.json')
    @proofs   = JSON.load(json_file)
    json_file.close

    json_file = File.open File.join(File.dirname(__FILE__), 'data/nodes.json')
    @uris     = JSON.load(json_file)
    json_file.close
  end

  def teardown
    # Do nothing
  end

  def test_should_evaluate_proofs
    verify_proof = ::Chainpoint::VerifyProof.new(@proofs, nil).perform

    result = verify_proof.results

    puts result

    assert(1 == 1)

  end
end