local cipher = require("openssl").cipher
local path = require("plenary.path")

local autocmds = require('vault.autocmds')

local M = {}

math.randomseed(os.time())

local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

function string.random(length)
  local idx = math.random(1, #charset)
  if length > 0 then
    return string.random(length - 1) .. charset:sub(idx, idx)
  else
    return ""
  end
end

local default_conf = {
  encrypted_file_path = "~/.local/share/vault.json.enc",
  key_path = "~/.local/share/vault.key",
  cipher_algorithm = "aes-128-cbc",
  content = nil,
}

M.generate_key = function(key_path)
  local p = path:new(key_path)
  if not p:exists() then
    p:touch({ parents = true })
  end

  local file = io.open(p:expand(), "w")
  local generated_key = string.random(64)
  file:write(generated_key)
  file:close()
end

M.generate_encrypted_file = function(opts)
  local p = path:new(opts.encrypted_file_path)
  local k = path:new(opts.key_path)
  local algorithm = opts.cipher_algorithm

  local default_json = vim.fn.json_encode(opts.content or {
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

local setenv_from_vault = function()
  local cipher_algorithm = vim.g.nvim_vault_cipher_algorithm
  local key_path = vim.g.nvim_vault_key_path
  local encrypted_file_path = vim.g.nvim_encrypted_vault_path

  local key_file = io.open(path:new(key_path):expand(), "r")
  local key = key_file:read()
  key_file:close()

  local encrypted_file = io.open(path:new(encrypted_file_path):expand(), "r")
  local encrypted_content = encrypted_file:read()
  encrypted_file:close()


  local result = cipher.decrypt(cipher_algorithm, encrypted_content, key)
  local json = vim.fn.json_decode(result)

  if json["env"] ~= nil then
    local env = json.env

    for k, v in pairs(env) do
      vim.env[k] = v
    end
  end
end

M.setup = function(opts)
  local encrypted_file_path = opts.encrypted_file_path or default_conf.encrypted_file_path
  local key_path = opts.key_path or default_conf.key_path
  local cipher_algorithm = opts.cipher_algorithm or default_conf.cipher_algorithm
  local content = opts.content or default_conf.content

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
      content = content,
    })
  end

  vim.g.nvim_vault_cipher_algorithm = cipher_algorithm
  vim.g.nvim_vault_key_path = key_path
  vim.g.nvim_encrypted_vault_path = encrypted_file_path

  autocmds.setup()

  setenv_from_vault()
end

M.find_buffer_by_name = function(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if string.find(buf_name, name) then
      return buf
    end
  end
  return -1
end

M.open_vault = function()
  local cipher_algorithm = vim.g.nvim_vault_cipher_algorithm
  local key_path = vim.g.nvim_vault_key_path
  local encrypted_file_path = vim.g.nvim_encrypted_vault_path

  local key_file = io.open(path:new(key_path):expand(), "r")
  local key = key_file:read()
  key_file:close()

  local encrypted_file = io.open(path:new(encrypted_file_path):expand(), "r")
  local encrypted_content = encrypted_file:read()
  encrypted_file:close()

  local content = cipher.decrypt(cipher_algorithm, encrypted_content, key)

  local buf = nil
  local bufnr = 0
  local target_buf_name = "vault://__VAULT__"
  local target_buffer = M.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd("vsplit")
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_name(bufnr, target_buf_name)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "")

  local lines = {}
  for line in content:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = line
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, 0, "true", lines)
end

M.save_buffer = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
  local line = lines[1]

  local cipher_algorithm = vim.g.nvim_vault_cipher_algorithm
  local key_path = vim.g.nvim_vault_key_path
  local encrypted_file_path = vim.g.nvim_encrypted_vault_path

  local key_file = io.open(path:new(key_path):expand(), "r")
  local key = key_file:read()
  key_file:close()

  local encrypted_content = cipher.encrypt(cipher_algorithm, line, key)

  local encrypted_file = io.open(path:new(encrypted_file_path):expand(), "w")
  encrypted_file:write(encrypted_content)
  encrypted_file:close()
end

return M
