require "test_helper"

class Chainpoint::SubmitHashTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Chainpoint::VERSION
  end

  def test_it_rejects_invalid_args
    error, _ = submit_hash([])

    assert(error, true)
  end

  def test_it_rejects_nil_hash
    _, error_message = submit_hash(nil)

    assert(error_message, "1st arg must be an Array")
  end

  def test_it_rejects_invalid_hash
    _, error_message = submit_hash(["hdkajhdkjahdskajhdskajhsdkajshd"])

    assert(error_message, "arg contains invalid items : hdkajhdkjahdskajhdskajhsdkajshd")
  end

  def test_it_accepts_valid_hash
    error, _ = submit_hash(["A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6009", "A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6008"])

    assert error == false
  end

  def test_it_should_have_valid_proof_handles
    hashes = ["A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6009", "A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6008"]
    result = ::Chainpoint::SubmitHash.new(hashes).perform

    assert !result.proof_handles.empty?
  end

  def test_it_rejects_invalid_uris
    error, message = submit_hash(["A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6009", "A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6008"], [1, 2, 3, 4, 5, 6])
    assert error == true
    assert message == "uris arg must be an Array with <= 5 elements"

    error, message = submit_hash(["A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6009", "A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6008"], "http://fail")
    assert error == true
    assert message == "uris arg must be an Array of String URIs"

    error, message = submit_hash(["A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6009", "A6F7B874EA69329372AD75353314D7BCACD8C0BE365023DAB195BCAC015D6008"], ["http://fail"])
    assert error == true
    assert message.include?("uris arg contains invalid URIs")
  end

  private

  def submit_hash(hashes, uris = nil)
    error = false
    error_message = ""
    begin
      ::Chainpoint::SubmitHash.new(hashes, uris).perform

    rescue => e
      error = true
      error_message = e.message
    end

    [error, error_message]
  end
end
