-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("SnacksAutoClose", { clear = true }),
  callback = function()
    -- Only act when we're in a real file buffer
    local bt = vim.bo.buftype
    local name = vim.api.nvim_buf_get_name(0)
    if bt ~= "" or name == "" then
      return
    end

    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype or ""

        local is_explorer = false

        if ft == "snacks_picker_list" then
          is_explorer = true
        end

        if not is_explorer then
          local ok_kind, kind = pcall(vim.api.nvim_buf_get_var, buf, "snacks_kind")
          if ok_kind and kind == "explorer" then
            is_explorer = true
          end
        end

        if is_explorer then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end)
  end,
})
