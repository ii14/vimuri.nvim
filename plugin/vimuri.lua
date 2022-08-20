if vim.g.loaded_vimuri ~= nil then
  return
end
vim.g.loaded_vimuri = true

local api = vim.api

local augroup = api.nvim_create_augroup('vimuri', { clear = true })

api.nvim_create_autocmd('BufReadCmd', {
  pattern = 'vim://*',
  group = augroup,
  callback = function(ctx)
    local err = require('vimuri').read(ctx.file, ctx.buf)
    if err then api.nvim_err_writeln(err) end
  end,
  nested = true,
  desc = 'vimuri',
})

api.nvim_create_autocmd('BufWriteCmd', {
  pattern = 'vim://*',
  group = augroup,
  callback = function(ctx)
    local err = require('vimuri').write(ctx.file, ctx.buf)
    if err then api.nvim_err_writeln(err) end
  end,
  nested = true,
  desc = 'vimuri',
})
