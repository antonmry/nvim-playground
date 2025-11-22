-- Minimal standalone config for markdown-oxide experiments

vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.background = "light"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    keys = {
      { "-", function() require("oil").open() end, desc = "Open parent directory in Oil" },
    },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "markdown", "markdown_inline", "lua", "vimdoc" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Telescope: Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Telescope: Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Telescope: Buffers" },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("lspsaga").setup({
        ui = { border = "rounded" },
        lightbulb = { enable = false },
      })

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
      end

      map("n", "gh", "<cmd>Lspsaga finder<CR>", "LSP Finder")
      map("n", "gd", "<cmd>Lspsaga goto_definition<CR>", "Goto Definition")
      map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", "Peek Definition")
      map("n", "<leader>lr", "<cmd>Lspsaga rename<CR>", "Rename Symbol")
      map("n", "<leader>ld", "<cmd>Lspsaga show_line_diagnostics<CR>", "Line Diagnostics")
      map("n", "<leader>lo", "<cmd>Lspsaga outline<CR>", "Symbols Outline")
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
  },
  {
    "hrsh7th/cmp-nvim-lsp",
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        ensure_installed = { "markdown_oxide" },
        automatic_installation = true,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end

      local markdown_capabilities = vim.tbl_deep_extend("force", capabilities, {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      })

      local function on_attach(client, bufnr)
        if client.name == "markdown_oxide" then
          vim.api.nvim_buf_create_user_command(bufnr, "Daily", function(args)
            vim.lsp.buf.execute_command({ command = "jump", arguments = { args.args } })
          end, { desc = "markdown-oxide: Open daily note", nargs = "*" })
        end
      end

      vim.lsp.config("markdown_oxide", {
        capabilities = markdown_capabilities,
        on_attach = on_attach,
      })
      vim.lsp.enable("markdown_oxide")
    end,
  },
  {
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    keys = {
      { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>",  { silent = true, desc = "navigate left or tab"  } },
      { "<c-j>", "<cmd>ZellijNavigateDown<cr>",  { silent = true, desc = "navigate down"  } },
      { "<c-k>", "<cmd>ZellijNavigateUp<cr>",    { silent = true, desc = "navigate up"    } },
      { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "navigate right or tab" } },
    },
    opts = {},
  }
}

require("lazy").setup(plugins, {
  change_detection = { notify = false },
  install = { colorscheme = { "dawnfox" } },
})

pcall(vim.cmd.colorscheme, "dawnfox")

vim.api.nvim_create_autocmd({ "FocusGained" }, {
  command = "silent !zellij action switch-mode locked",
})
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  command = "silent !zellij action switch-mode locked",
})
vim.api.nvim_create_autocmd({ "FocusLost" }, {
  command = "silent !zellij action switch-mode normal",
})
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  command = "silent !zellij action switch-mode normal",
})
