module Chainpoint
  module Utils
    module Parser
      include Chainpoint::Utils::Helpers
      include Chainpoint::ChpSchema::V4

      def parse(cp_object)
        # // if the supplied is a Buffer, Hex, or Base64 string, convert to JS object
        if cp_object.is_a?(String) # || Buffer.isBuffer(cp_object)) # @TODO Buffer alternative
          cp_object = binary_to_object_sync(cp_object)

          schema_check = validate_v4_schema!(cp_object)
          raise Chainpoint::Error, schema_check["error"] unless schema_check["valid"]

          # // initialize the result object
          # // identify this result set with the basic information on the hash
          # // acquire all anchor points and calcaulte expected values for all branches, recursively
          {
              "hash"          => cp_object["hash"],
              "proof_id"      => cp_object["proof_id"],
              "hash_received" => cp_object["hash_received"],
              "branches"      => parse_branches(cp_object["hash"], cp_object["branches"]),
          }
        end
      end

      def parse_branches(start_hash, branch_array)
        branches           = []
        current_hash_value = start_hash.dup
        branch_array.each do |branch|
          # // initialize anchors array for this branch
          anchors = []
          # // iterate through all operations in the operations array for this branch
          branch_ops = branch["ops"]

          branch_ops.each do |branch_op|
            if !branch_op["r"].nil?
              current_hash_value << (is_hex?(branch_op["r"]) ? branch_op["r"] : utf8_to_hex(branch_op["r"]))
            elsif !branch_op["l"].nil?
              current_hash_value << (is_hex?(branch_op["l"]) ? branch_op["l"] : utf8_to_hex(branch_op["l"]))
            elsif !branch_op["op"].nil?
              current_hash_value = case branch_op["op"]
                                     when 'sha-224'
                                       Digest::SHA2.new(224).hexdigest(current_hash_value)
                                     when 'sha-256'
                                       Digest::SHA2.new(256).hexdigest(current_hash_value)
                                     when 'sha-384'
                                       Digest::SHA2.new(384).hexdigest(current_hash_value)
                                     when 'sha-512'
                                       Digest::SHA2.new(512).hexdigest(current_hash_value)

                                     when 'sha3-224'
                                       SHA3::Digest::SHA224.hexdigest(current_hash_value)
                                     when 'sha3-256'
                                       SHA3::Digest::SHA256.hexdigest(current_hash_value)
                                     when 'sha3-384'
                                       SHA3::Digest::SHA384.hexdigest(current_hash_value)
                                     when 'sha3-512'
                                       SHA3::Digest::SHA512.hexdigest(current_hash_value)

                                     when 'sha-256-x2'
                                       hash_value = Digest::SHA2.new(256).hexdigest(current_hash_value)
                                       Digest::SHA2.new(256).hexdigest(hash_value)
                                   end

            elsif !branch_op["anchors"].nil?
              anchors.concat(parse_anchors(current_hash_value, branch_op["anchors"]))
            end
          end

          branch_obj             = {
              "label"   => branch["label"] || nil,
              "anchors" => anchors
          }

          branch_obj["branches"] = parse_branches(current_hash_value, branch["branches"]) if !branch["branches"].nil?

          # if this branch is a standard Chaipoint BTC anchor branch,
          # output the OP_RETURN value and the BTC transaction id
          branch_obj.merge!(get_btc_anchor_info(start_hash, branch_ops)) if branch_obj["label"] == 'btc_anchor_branch'

          branches << branch_obj
        end

        branches
      end


      def get_btc_anchor_info(start_hash, ops)
        #   // This calculation depends on the branch using the standard format
        #   // for btc_anchor_branch type branches created by Chainpoint services
        current_hash_value = start_hash.dup
        has_256x2          = false
        is_first_256x2     = false
        raw_tx             = ''

        op_result_table = ops.map do |op|
          if !op["r"].nil?
            current_hash_value << (is_hex?(op["r"]) ? op["r"] : utf8_to_hex(op["r"]))
          elsif !op["l"].nil?
            current_hash_value << (is_hex?(op["l"]) ? op["l"] : utf8_to_hex(op["l"]))
          elsif !op["op"].nil?
            current_hash_value = case op["op"]
                                   when 'sha-224'
                                     Digest::SHA2.new(224).hexdigest(current_hash_value)
                                   when 'sha-256'
                                     Digest::SHA2.new(256).hexdigest(current_hash_value)
                                   when 'sha-384'
                                     Digest::SHA2.new(384).hexdigest(current_hash_value)
                                   when 'sha-512'
                                     Digest::SHA2.new(512).hexdigest(current_hash_value)

                                   when 'sha3-224'
                                     SHA3::Digest::SHA224.hexdigest(current_hash_value)
                                   when 'sha3-256'
                                     SHA3::Digest::SHA256.hexdigest(current_hash_value)
                                   when 'sha3-384'
                                     SHA3::Digest::SHA384.hexdigest(current_hash_value)
                                   when 'sha3-512'
                                     SHA3::Digest::SHA512.hexdigest(current_hash_value)

                                   when 'sha-256-x2'
                                     # if this is the first double sha256, then the currentHashValue is the rawTx
                                     # on the public Bitcoin blockchain
                                     raw_tx = current_hash_value unless has_256x2

                                     hash_value = Digest::SHA2.new(256).hexdigest(current_hash_value)
                                     hash_value = Digest::SHA2.new(256).hexdigest(hash_value)

                                     if !has_256x2
                                       is_first_256x2 = true
                                       has_256x2      = true
                                     else
                                       is_first_256x2 = false
                                     end

                                     hash_value
                                 end
          end

          { "op_result" => current_hash_value, "op" => op, "is_first_256x2" => is_first_256x2 }
        end

        btc_tx_id_op_index = op_result_table.find_index { |r| r["is_first_256x2"] == true }
        op_return_op_index = btc_tx_id_op_index - 3

        {
            "op_return_value" => op_result_table[op_return_op_index]["op_result"],
            "btc_tx_id"       => op_result_table[btc_tx_id_op_index]["op_result"].scan(/../).reverse.join(''),
            "raw_tx"          => raw_tx
        }

      end

      def parse_anchors(current_hash_value, anchors_array)
        anchors = []
        anchors_array.each do |anchor|
          expected_value = current_hash_value.dup
          # BTC merkle root values is in little endian byte order
          # All hashes and calculations in a Chainpoint proof are in big endian byte order
          # If we are determining the expected value for a BTC anchor, the expected value
          # result byte order must be reversed to match the BTC merkle root byte order
          # before making any comparisons
          expected_value = expected_value.scan(/../).reverse.join('') if %w[btc tbtc].include?(anchor["type"])

          anchors << {
              "type"           => anchor["type"],
              "anchor_id"      => anchor["anchor_id"],
              "uris"           => anchor["uris"] || nil,
              "expected_value" => expected_value
          }
        end

        anchors
      end

      def binary_to_object_sync(proof)
        raise Chainpoint::Error, 'No binary proof arg provided' if proof.nil? || proof.empty?
        begin
          #  // Handle a Hexadecimal String arg in addition to a Buffer
          # proof = is_hex?(proof) ? hex_to_bin(proof) : ::Base64.decode64(proof)
          proof = is_hex?(proof) ? proof : ::Base64.strict_decode64(proof)

          unpacked_proof = msg_decode(zlib_inflate(proof))
          raise Chainpoint::Error, 'Chainpoint v4 schema validation error' unless is_valid_v4_schema?(unpacked_proof)

          unpacked_proof
        rescue => e
          raise Chainpoint::Error, 'Could not parse Chainpoint v4 binary'
        end
      end

      def hex_to_bin(s)
        s.scan(/../).map { |x| x.hex }.pack('c*')
      end

      def bin_to_hex(binary_string)
        binary_string.unpack('H*').first
      end

      def utf8_to_hex(string)
        string.unpack('H*').first
      end

      def zlib_inflate(value)
        Zlib::Inflate.inflate(value)
      end

      def msg_decode(msg)
        MessagePack.unpack(msg)
      end

    end
  end
end

