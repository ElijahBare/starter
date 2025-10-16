-- Terminal Esc behavior command
local function set_term_esc(mode)
  local function map_for(buf, rhs)
    -- Map only in terminal-mode, buffer-local
    vim.keymap.set("t", "<Esc>", rhs, { buffer = buf, silent = true, noremap = true })
  end

  local rhs = nil
  if mode == "prev" then
    rhs = [[<C-\><C-n><C-w>p]] -- leave term & jump to previous window
  elseif mode == "normal" then
    rhs = [[<C-\><C-n>]] -- leave term insert mode only
  elseif mode == "off" then
    rhs = false -- unmap
  else
    vim.notify("TermEsc: choose one of {prev|normal|off}", vim.log.levels.WARN)
    return
  end

  -- Apply to all existing terminal buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      if rhs == false then
        pcall(vim.keymap.del, "t", "<Esc>", { buffer = buf })
      else
        map_for(buf, rhs)
      end
    end
  end

  -- Auto-apply to future terminals
  vim.api.nvim_create_augroup("TermEscGroup", { clear = true })
  if rhs == false then
    -- If turning off, just clear the group
    return
  end
  vim.api.nvim_create_autocmd("TermOpen", {
    group = "TermEscGroup",
    callback = function(args)
      map_for(args.buf, rhs)
    end,
    desc = "Set <Esc> behavior in terminal buffers",
  })
end

vim.api.nvim_create_user_command("TermEsc", function(opts)
  set_term_esc(opts.args)
end, {
  nargs = 1,
  complete = function()
    return { "prev", "normal", "off" }
  end,
  desc = "Set terminal <Esc> behavior: prev|normal|off",
})
