module Chainpoint
  module Utils
    module Helpers
      def validate_hash_args(hashes)
        hashes = test_array_args(hashes)
        raise Chainpoint::Error, '1st arg must be an Array with <= 250 elements' unless hashes.size <= 250

        rejects = hashes.reject { |h| is_hex? h }
        raise Chainpoint::Error, "arg contains invalid items : #{rejects.join(', ')}" unless rejects.empty?
      end

      def validate_uri_args(uris)
        raise Chainpoint::Error, 'uris arg must be an Array of String URIs' unless uris.is_a? Array
        raise Chainpoint::Error, 'uris arg must be an Array with <= 5 elements' unless uris.size <= 5
      end

      def is_hex?(hash)
        hash =~ /^[0-9a-f]{2,}$/i && hash.length.even?
      end

      def test_array_args(arg)
        raise Chainpoint::Error, '1st arg must be an Array' unless arg.is_a? Array
        arg.flatten!
        raise Chainpoint::Error, '1st arg must be a non-empty Array' if arg.empty?

        arg
      end
    end
  end
end
