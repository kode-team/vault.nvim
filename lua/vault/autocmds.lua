local create = vim.api.nvim_create_augroup
local define = vim.api.nvim_create_autocmd

local M = {}

create("vault_autocmds", { clear = true })

function M.setup()
  define({ "BufWriteCmd" }, {
    group = "vault_autocmds",
    pattern = { "vault://*" },
    callback = function()
      require("vault").save_buffer()
    end,
  })
end

return M
