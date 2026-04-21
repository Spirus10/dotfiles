{ pkgs, inputs, ... }:

let
  lavender-nvim = pkgs.callPackage ../../pkgs/lavender-nvim.nix {
    src = inputs.lavender-nvim;
  };
in
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  programs.nixvim = {
    enable        = true;
    defaultEditor = true;

    # Lavender is not a built-in nixvim colorscheme, so bring it in as
    # an extraPlugin and trigger the :colorscheme command explicitly.
    extraPlugins = [ lavender-nvim ];
    colorscheme  = "lavender";

    # --- vim.g.* ---------------------------------------------------
    globals = {
      mapleader          = " ";
      netrw_browse_split = 0;
      netrw_banner       = 0;
      netrw_winsize      = 25;

      # Mirrors the `vim.g.lavender = { ... }` block from the Arch
      # config. nixvim sets globals before the colorscheme runs.
      lavender = {
        transparent = {
          background = true;
          float      = true;
          popup      = true;
          sidebar    = true;
        };
        contrast = true;
        italic = {
          comments  = true;
          functions = true;
          keywords  = false;
          variables = false;
        };
      };
    };

    # --- vim.opt.* -------------------------------------------------
    opts = {
      guicursor      = "";
      number         = true;
      relativenumber = true;
      scrolloff      = 8;

      tabstop        = 4;
      softtabstop    = 4;
      shiftwidth     = 4;
      expandtab      = true;
      smartindent    = true;

      wrap           = false;
      swapfile       = false;
      backup         = false;
      undofile       = true;
      undodir.__raw  = "os.getenv('HOME') .. '/.vim/undodir'";

      hlsearch       = false;
      incsearch      = true;

      termguicolors  = true;
      signcolumn     = "yes";
      updatetime     = 50;
      colorcolumn    = "80";
      timeoutlen     = 250;
    };

    # --- keymaps ---------------------------------------------------
    keymaps = [
      # Core
      { mode = "n"; key = "<leader>pv"; action.__raw = "vim.cmd.Ex"; }
      { mode = "i"; key = "jk";          action = "<Esc>"; options = { noremap = true; silent = true; }; }
      { mode = "v"; key = "J";           action = ":m '>+1<CR>gv=gv"; }
      { mode = "v"; key = "K";           action = ":m '<-2<CR>gv=gv"; }

      # Telescope — action bodies wrap builtin fns in `function() ... end`
      # so nixvim renders them as lua callables.
      { mode = "n"; key = "<leader>pf";  action.__raw = "function() require('telescope.builtin').find_files() end"; options.desc = "Telescope find files"; }
      { mode = "n"; key = "<C-p>";       action.__raw = "function() require('telescope.builtin').git_files() end"; }
      { mode = "n"; key = "<leader>pws"; action.__raw = "function() require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') }) end"; }
      { mode = "n"; key = "<leader>pWs"; action.__raw = "function() require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') }) end"; }
      { mode = "n"; key = "<leader>ps";  action.__raw = "function() require('telescope.builtin').grep_string({ search = vim.fn.input('Grep > ') }) end"; }
      { mode = "n"; key = "<leader>vh";  action.__raw = "function() require('telescope.builtin').help_tags() end"; }

      # Harpoon
      { mode = "n"; key = "<leader>a"; action.__raw = "function() require('harpoon'):list():add() end"; }
      { mode = "n"; key = "<C-e>";     action.__raw = "function() local h = require('harpoon'); h.ui:toggle_quick_menu(h:list()) end"; }
      { mode = "n"; key = "<C-h>";     action.__raw = "function() require('harpoon'):list():select(1) end"; }
      { mode = "n"; key = "<C-t>";     action.__raw = "function() require('harpoon'):list():select(2) end"; }
      { mode = "n"; key = "<C-n>";     action.__raw = "function() require('harpoon'):list():select(3) end"; }
      { mode = "n"; key = "<C-s>";     action.__raw = "function() require('harpoon'):list():select(4) end"; }

      # Fugitive
      { mode = "n"; key = "<leader>gs"; action.__raw = "vim.cmd.Git"; }

      # Undotree
      { mode = "n"; key = "<leader>u";  action.__raw = "vim.cmd.UndotreeToggle"; }

      # Trouble
      { mode = "n"; key = "<leader>tt"; action.__raw = "function() require('trouble').toggle('diagnostics') end"; }
      { mode = "n"; key = "<leader>tn"; action.__raw = "function() require('trouble').next({ skip_groups = true, jump = true }) end"; }
      { mode = "n"; key = "<leader>tp"; action.__raw = "function() require('trouble').previous({ skip_groups = true, jump = true }) end"; }

      # Zen-mode — two variants from the Arch config: wide (90 cols, numbered)
      # and narrow (80 cols, unnumbered, no colorcolumn).
      {
        mode = "n";
        key  = "<leader>zz";
        action.__raw = ''
          function()
            require('zen-mode').setup({ window = { width = 90, options = {} } })
            require('zen-mode').toggle()
            vim.wo.wrap = false
            vim.wo.number = true
            vim.wo.rnu = true
          end
        '';
      }
      {
        mode = "n";
        key  = "<leader>zZ";
        action.__raw = ''
          function()
            require('zen-mode').setup({ window = { width = 80, options = {} } })
            require('zen-mode').toggle()
            vim.wo.wrap = false
            vim.wo.number = false
            vim.wo.rnu = false
            vim.opt.colorcolumn = "0"
          end
        '';
      }
    ];

    # --- plugins ---------------------------------------------------
    plugins = {
      telescope = {
        enable = true;
        settings = { };
      };

      harpoon = {
        enable = true;
        enableTelescope = true;
      };

      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable    = true;
          # Grammars come from nixpkgs via nixvim's grammar packages.
          # No runtime compilation, no tree-sitter CLI required.
          auto_install     = false;
        };
      };

      fugitive.enable  = true;
      undotree.enable  = true;
      zen-mode.enable  = true;
      trouble.enable   = true;

      cloak = {
        enable = true;
        settings = {
          enabled         = true;
          cloak_character = "*";
          highlight_group = "Comment";
          patterns = [
            {
              file_pattern  = [ ".env*" "wrangler.toml" ".dev.vars" ];
              cloak_pattern = "=.+";
            }
          ];
        };
      };

      copilot-lua = {
        enable = true;
        settings = {
          # CopilotChat drives completions via its own flow, so the
          # floating-panel from copilot-lua is redundant.
          suggestion.enabled = false;
          panel.enabled      = false;
        };
      };

      copilot-chat = {
        enable = true;
      };

      # LSP via plugins.lsp (nvim-lspconfig wrapper). Servers resolve
      # from nixpkgs — no Mason, no runtime downloads. Add new ones
      # here as languages come online.
      lsp = {
        enable = true;
        servers = {
          lua_ls.enable        = true;
          nixd.enable          = true;
          rust_analyzer = {
            enable       = true;
            installCargo = false;
            installRustc = false;
          };
          pyright.enable       = true;
          ts_ls.enable         = true;
          bashls.enable        = true;
          clangd.enable        = true;
        };
      };
    };

    # --- raw lua for things the structured attrs don't cover -------
    extraConfigLua = ''
      -- Trim trailing whitespace on save. Lifted from wammu/init.lua.
      local wammu = vim.api.nvim_create_augroup('wammu', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
        group   = wammu,
        pattern = '*',
        command = [[%s/\s\+$//e]],
      })

      -- Yank highlight flash.
      local yank = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
      vim.api.nvim_create_autocmd('TextYankPost', {
        group   = yank,
        pattern = '*',
        callback = function()
          vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 40 })
        end,
      })

      -- Fugitive window-local keymaps. Buffer-scoped, so they can't
      -- live in the declarative keymaps list — they'd apply globally.
      local fug = vim.api.nvim_create_augroup('wammu_fugitive', { clear = true })
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group   = fug,
        pattern = '*',
        callback = function()
          if vim.bo.ft ~= 'fugitive' then return end
          local bufnr = vim.api.nvim_get_current_buf()
          local opts  = { buffer = bufnr, remap = false }
          vim.keymap.set('n', '<leader>p', function() vim.cmd.Git('push') end, opts)
          vim.keymap.set('n', '<leader>P', function() vim.cmd.Git({ 'pull', '--rebase' }) end, opts)
          vim.keymap.set('n', '<leader>t', ':Git push -u origin ', opts)
        end,
      })
    '';
  };
}
