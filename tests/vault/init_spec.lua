local vault = require("vault.init")
local cipher = require("openssl").cipher
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

    describe('when specifying default content for encrypted file', function()
      it('should be written correctly', function()
        local key_path = "/tmp/another-vault.key"
        local encrypted_file_path = "/tmp/another-vault.json.enc"
        local cipher_algorithm = "aes-128-cbc"
        vault.setup({
          key_path = key_path,
          encrypted_file_path = encrypted_file_path,
          cipher_algorithm = cipher_algorithm,
          content = {
            env = {
              OPENAI_API_KEY = "HELLO_WORLD"
            }
          }
        })

        local key_file = io.open(path:new(key_path):expand(), "r")
        local key = key_file:read()
        key_file:close()

        local encrypted_file = io.open(path:new(encrypted_file_path):expand(), "r")
        local encrypted_content = encrypted_file:read()
        encrypted_file:close()

        local content = cipher.decrypt(cipher_algorithm, encrypted_content, key)
        local json = vim.fn.json_decode(content)
        local env = json["env"]

        assert(env["OPENAI_API_KEY"] == "HELLO_WORLD")
      end)
    end)
  end)
end)
