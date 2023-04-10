local cipher = require("openssl").cipher
local path = require("plenary.path")

local M = {}

local default_conf = {
  encrypted_file_path = "~/.local/share/vault.json.enc",
  key_path = "~/.local/share/vault.key",
  cipher_algorithm = "aes-128-cbc",
}

M.generate_key = function(key_path)
  local p = path:new(key_path)
  if not p:exists() then
    p:touch({ parents = true })
  end

  local file = io.open(p:expand(), "w")
  local generated_key = "random_string"
  file:write(generated_key)
  file:close()
end

M.generate_encrypted_file = function(opts)
  local p = path:new(opts.encrypted_file_path)
  local k = path:new(opts.key_path)
  local algorithm = opts.cipher_algorithm

  local default_json = vim.fn.json_encode({
    env = {
      FOO = "BAR"
    }
  })

  if not p:exists() then
    p:touch({ parents = true })
  end

  local key_file = io.open(k:expand(), "r")
  local key = key_file:read()
  key_file:close()

  local content = cipher.encrypt(algorithm, default_json, key)

  local file = io.open(p:expand(), "w")
  file:write(content)
  file:close()
end

M.setup = function(opts)
  local encrypted_file_path = opts.encrypted_file_path or default_conf.encrypted_file_path
  local key_path = opts.key_path or default_conf.key_path
  local cipher_algorithm = opts.cipher_algorithm or default_conf.cipher_algorithm

  local k = path:new(key_path)
  if not k:exists() then
    M.generate_key(key_path)
  end

  local f = path:new(encrypted_file_path)
  if not f:exists() then
    M.generate_encrypted_file({
      cipher_algorithm = cipher_algorithm,
      key_path = key_path,
      encrypted_file_path = encrypted_file_path,
    })
  end
end

return M
