return {
  {
    -- Use the fork with copy local plugin dir to remote feature
    "arntanguy/remote-nvim.nvim",
    branch = "main", -- the fork doesn’t publish releases, so don’t use `version="*"`
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = true, -- calls require("remote-nvim").setup() with defaults
  },
}
