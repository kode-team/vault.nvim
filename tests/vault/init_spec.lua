local vault = require("vault.init")
local path = require("plenary.path")

describe('init', function()
  describe('setup()', function()
    describe('when specifying key_path and encrypted_file_path', function()
      it('should work correctly', function()
        local key_path = "/tmp/vault.key"
        local encrypted_file_path = "/tmp/vault.json.enc"
        local cipher_algorithm = "aes-128-cbc"
        vault.setup({
          key_path = key_path,
          encrypted_file_path = encrypted_file_path,
          cipher_algorithm = cipher_algorithm
        })

        assert(path:new(key_path):exists())
        assert(path:new(encrypted_file_path):exists())
      end)
    end)
  end)
end)
