require "test_helper.rb"

class Chainpoint::GetProofTest < MiniTest::Test
  def setup
    json_file           = File.open File.join(File.dirname(__FILE__), 'data/proof-handles.json')
    @proof_handles_data = JSON.load(json_file)
    json_file.close
  end

  def teardown
    # Do nothing
  end

  def test_should_only_accept_an_array_of_valid_proof_handles
    error, message = get_proof([])
    assert(error && message.include?('non-empty Array'), 'Should have thrown with an empty array')

    error, message = get_proof('not an array')
    assert(error && message.include?('an Array'), 'Should have thrown with a non-array arg')

    large_data_set = [].fill(@proof_handles_data.first, 0, 255)
    _, message     = get_proof(large_data_set)
    assert(message.include?('<= 250'), 'Should have thrown with a data set larger than 250 items')

    error, message = get_proof([@proof_handles_data.first.merge({ "uri" => 'invalid-uri' })])
    assert(error && message.include?('invalid URI values'), 'Should have thrown with an invalid uri')

    error, message = get_proof([{ foo: 'bar' }])
    assert(error && message.include?('invalid Objects'), 'Should have thrown with an invalid handle')

    error, message = get_proof([@proof_handles_data.first.merge({ "proof_id" => '123456' })])
    assert(error && message.include?('invalid proof_id'), 'Should have thrown with an invalid proof_id')

  end

  private

  def get_proof(phs)
    error         = false
    error_message = ""
    begin
      ::Chainpoint::GetProof.new(phs).perform
    rescue => e
      error         = true
      error_message = e.message
    end

    [error, error_message]
  end
end