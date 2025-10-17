-- Make <Esc> hide ToggleTerm split; <leader>t restores last; {N}<leader>t opens terminal N.
return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
  init = function()
    -- If <leader>t was mapped elsewhere, clear it so ours wins
    vim.schedule(function()
      pcall(vim.keymap.del, "n", "<leader>t")
    end)
  end,
  config = function()
    require("toggleterm").setup({
      direction = "horizontal", -- or "vertical"
      start_in_insert = true,
      persist_mode = true,
      persist_size = true,
      shade_terminals = true,
    })

    local TT = require("toggleterm.terminal")
    local Terminal = TT.Terminal
    local last_toggleterm_id = nil
    local aug = vim.api.nvim_create_augroup("TermEscHideSplit", { clear = true })

    -- Buffer-local <Esc> in ToggleTerm to hide (keep job alive)
    vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
      group = aug,
      pattern = "term://*toggleterm#*",
      callback = function(args)
        local num = vim.b[args.buf].toggle_number
        if num then
          last_toggleterm_id = num
        end

        vim.keymap.set("t", "<Esc>", function()
          local id = vim.b.toggle_number
          if id then
            local term = TT.get(id)
            if term then
              term:toggle() -- hide this split, process keeps running
            else
              vim.cmd("stopinsert | hide")
            end
          else
            vim.cmd("stopinsert | hide")
          end
        end, { buffer = args.buf, silent = true, noremap = true, desc = "Hide terminal split (keep running)" })
      end,
    })

    -- Normal mode: <leader>t -> restore last terminal; {N}<leader>t -> toggle terminal N
    vim.keymap.set("n", "<leader>t", function()
      -- use provided count if any; otherwise fallback to last used, then 1
      local id = (vim.v.count ~= 0) and vim.v.count or (last_toggleterm_id or 1)

      -- grab existing terminal by id, or create it
      local term = TT.get(id)
      if not term then
        term = Terminal:new({ count = id, direction = "horizontal" }) -- keep consistent with setup
      end

      -- toggle (open if hidden, hide if visible)
      term:toggle()

      -- if now visible in current win, go to insert
      -- Idiomatic & simple
      if term:is_open() and vim.bo[term.bufnr].buftype == "terminal" then
        vim.cmd("startinsert")
      end

      -- remember as last used
      last_toggleterm_id = id
    end, { silent = true, noremap = true, desc = "ToggleTerm: toggle terminal (count selects ID)" })
  end,
}
