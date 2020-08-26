require "openssl"
require 'time'
require 'uri'
require 'net/http'
require 'json'
require 'base64'
require 'zlib'
require 'msgpack'
require 'json-schema'
require 'securerandom'
require 'digest'
require 'sha3'

require "chainpoint/version"
require "chainpoint/configuration"
require 'chainpoint/chp_schema/v4'
require 'chainpoint/utils'
require 'chainpoint/utils/helpers'
require 'chainpoint/utils/network'
require 'chainpoint/utils/parser'
require 'chainpoint/utils/proofs'
require "chainpoint/submit_hash"
require "chainpoint/submit_file_hash"
require "chainpoint/get_proof"
require "chainpoint/verify_proof"
require "chainpoint/evaluate_proof"

module Chainpoint
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= ::Chainpoint::Configuration.new
  end

  def self.reset
    @configuration = ::Chainpoint::Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Error < StandardError; end
end

