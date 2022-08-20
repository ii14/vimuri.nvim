local api, fn = vim.api, vim.fn

local b_call = api.nvim_buf_call
local b_set_opt = api.nvim_buf_set_option
local b_set_lines = api.nvim_buf_set_lines
local b_get_lines = api.nvim_buf_get_lines

local M = {}

local REGISTERS = {}
for c in ([["0123456789abcdefghijklmnopqrstuvwxyz]]):gmatch('.') do
  REGISTERS[c] = true
end

local OPTIONS = {
  runtimepath = true,
  rtp = 'runtimepath',
  packpath = true,
  pp = 'packpath',
  path = true,
  pa = 'path',
  tags = true,
  tag = 'tags',
  wildignore = true,
  wig = 'wildignore',
}

---Find a buffer
local function findbuf(name)
  -- bufnr() doesn't work because it matches the substring,
  -- and breaks on `tag` -> `tags`. we need to find the buffer
  -- manually and match the name exactly.
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_get_name(bufnr) == name then
      return bufnr
    end
  end
  error('buffer not found')
end

---Rename the buffer
---@param buf integer Renamed buffer
---@param name string New name
---@param file string Previous name
---@return boolean ok `true` on success, `false` when found another buffer
local function rename(buf, name, file)
  local prev = fn.getreg('#')
  -- reset previous buffer if it holds the previous name
  if prev == file then
    prev = ''
  end

  local ok, err = pcall(api.nvim_buf_set_name, buf, name)
  -- E95: Buffer with this name already exists
  if not ok and not err:match('^Vim:E95:') then
    error(err)
  end

  if not ok then
    -- use found buffer
    api.nvim_set_current_buf(findbuf(name))
  end
  -- renaming a buffer puts the old name in the "# register,
  -- creating a new buffer. remove it.
  vim.cmd(('%dbwipe'):format(findbuf(file)))
  fn.setreg('#', prev)
  return ok
end

---Read a buffer
---@param file string File name
---@param buf integer Buffer
---@return nil|string err Error, or `nil` on success
function M.read(file, buf)
  do -- "vim://@" -> "vim://reg/"
    local m = file:match('^vim://@(.*)$')
    if m then
      if not REGISTERS[m] then
        return ('Invalid register: "%s"'):format(m)
      elseif not rename(buf, 'vim://reg/' .. m, file) then
        return
      end
      file = 'vim://reg/' .. m
    end
  end

  do -- "vim://&" -> "vim://opt/"
    local m = file:match('^vim://&(.*)$')
    if m then
      if not OPTIONS[m] then
        return ('Invalid option: "%s"'):format(m)
      elseif type(OPTIONS[m]) == 'string' then
        m = OPTIONS[m]
      end
      if not rename(buf, 'vim://opt/' .. m, file) then
        return
      end
      file = 'vim://opt/' .. m
    end
  end

  do -- "vim://reg/*"
    local m = file:match('^vim://reg/(.*)$')
    if m then
      if not REGISTERS[m] then
        return ('Invalid register: "%s"'):format(m)
      end
      b_call(buf, function()
        b_set_opt(0, 'buftype', 'acwrite')
        b_set_lines(0, 0, -1, false, {})
        fn.setline(1, fn.getreg(m))
        b_set_opt(0, 'filetype', 'vim_reg')
      end)
      return
    end
  end

  do -- "vim://opt/*"
    local m = file:match('^vim://opt/(.*)$')
    if m then
      local r = OPTIONS[m]
      if r == nil then
        return ('Invalid option: "%s"'):format(m)
      elseif type(r) == 'string' then
        if not rename(buf, 'vim://opt/' .. r, file) then
          return
        end
      end

      b_call(buf, function()
        b_set_opt(0, 'buftype', 'acwrite')
        local opt = vim.split(api.nvim_get_option(m), ',', { plain = true })
        b_set_lines(0, 0, -1, false, opt)
        b_set_opt(0, 'filetype', 'vim_opt')
      end)
      return
    end
  end

  return 'Invalid vim file'
end

---Write a buffer
---@param file string File name
---@param buf integer Buffer
---@return nil|string err Error, or `nil` on success
function M.write(file, buf)
  do -- "vim://reg/*"
    local reg = file:match('^vim://reg/(.*)$')
    if reg then
      if not REGISTERS[reg] then
        return ('Invalid register: "%s"'):format(reg)
      end
      b_call(buf, function()
        -- TODO: concat all lines
        fn.setreg(reg, fn.getline(1))
        b_set_opt(0, 'modified', false)
      end)
      return
    end
  end

  do -- "vim://opt/*"
    local m = file:match('^vim://opt/(.*)$')
    if m then
      if OPTIONS[m] == nil then
        return ('Invalid option: "%s"'):format(m)
      end
      b_call(buf, function()
        local opt = table.concat(b_get_lines(0, 0, -1, false), ',')
        api.nvim_set_option(m, opt)
        b_set_opt(0, 'modified', false)
      end)
      return
    end
  end

  return 'Invalid vim file'
end

return M
