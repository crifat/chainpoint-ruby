require "chainpoint/version"

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

