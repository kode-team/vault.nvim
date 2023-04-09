local cipher = require('openssl').cipher

describe('utils', function()
  it("encryption is successful", function()
	local original = {
	  env = { OPEN_API_KEY = "blahblahblah" }
	}
	local cipher_algorithm = "aes-128-cbc"
	local json_encoded = vim.fn.json_encode(original)
	local encryption_key = "aaabbb111"
	local encrypted_content = cipher.encrypt(cipher_algorithm, json_encoded, encryption_key)
	local decrypted_content = cipher.decrypt(cipher_algorithm, encrypted_content, encryption_key)
	assert(json_encoded == decrypted_content)
  end)
end)


