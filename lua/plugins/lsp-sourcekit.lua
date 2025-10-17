return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    local function resolve_sourcekit()
      if vim.fn.executable("sourcekit-lsp") == 1 then
        return { "sourcekit-lsp" }
      end

      local found = vim.fn.system({ "xcrun", "--find", "sourcekit-lsp" })
      if vim.v.shell_error ~= 0 then
        return nil
      end

      local resolved = vim.fn.trim(found)
      if resolved ~= "" and vim.fn.executable(resolved) == 1 then
        return { resolved }
      end

      return nil
    end

    local sourcekit_cmd = resolve_sourcekit()
    if not sourcekit_cmd then
      vim.schedule(function()
        vim.notify("sourcekit-lsp not found. Install Xcode Command Line Tools or ensure it is in PATH.", vim.log.levels.WARN)
      end)
    end

    opts.servers = opts.servers or {}
    opts.servers.sourcekit = {
      cmd = sourcekit_cmd,
    }
  end,
}
