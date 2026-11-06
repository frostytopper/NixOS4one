# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Fork Me: these three values personalize the whole system.
  vars = {
    userName = "brian";
    fullName = "frozt"; # display name, indepenent of login name
    hostName = "lati";
    timeZone = "America/Los_Angeles";
  };

  # Read configured account's home
  user = config.users.users.${vars.userName};

  paths = {
    home = user.home;
    secrets = "${user.home}/secrets";
    userProfileBin = "/etc/profiles/per-user/${vars.userName}/bin";
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  hardware.facter.reportPath = ./facter.json;
  nix.optimise.automatic = true;

  # --  Boot --
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = vars.hostName;
  networking.networkmanager.enable = true;

  # -- Locale / Time --
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = vars.timeZone;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # -- Desktop (KDE Plasma 6)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = true;
  };

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # -- Printing --
  services.printing.enable = true;

  # -- Audio --
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # -- Nix --
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.nixPath = [
    "nixpkgs=${builtins.storePath pkgs.path}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  nixpkgs.config.allowUnfree = true;

  # -- Programs (system-managed) --
  programs = {
    nix-ld = {
      enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure = {
        customRC = ''
          " ---- basics ----
          set number
          set relativenumber
          set mouse=a
          set termguicolors
          set signcolumn=yes
          set ignorecase
          set smartcase
          set scrolloff=8
          set cursorline
          set splitright
          set splitbelow
          set confirm
          set undofile
          set clipboard=unnamedplus

          " indentation
          set expandtab
          set shiftwidth=2
          set tabstop=2
          filetype plugin indent on

          " ---- keymaps ----
          let mapleader = " "

          " ---- colors ----
          colorscheme tokyonight-night

          " ---- system LSP ----
          lua << EOF
          require("telescope").setup({})
          require("gitsigns").setup()

          local builtin = require("telescope.builtin")

          vim.keymap.set("n", "<leader>ff", builtin.find_files, {
            desc = "Find Files",
          })

          vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
            desc = "Search project text",
          })

          vim.keymap.set("n", "<leader>fb", builtin.buffers, {
            desc = "Find buffers",
          })

          vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
            desc = "Search help",
          })

          -- ---- oil setup ----
          require("oil").setup({
            -- Take over directory buffers ('nvim.', ':e src/') from netrw
            default_file_explorer = true,
            columns = { "icon" }, -- rendered by nvim-web-devicons
            -- skip_confirm_for_simple_edits = true,
            restore_win_options = true,
            buf_options = {
              buflisted = false,
              bufhidden = "hide",
            },
            view_options = {
              show_hidden = true,
            },
            float = {
              padding = 2,
              border = "rounded",
              win_options = { winblend = 0 },
            },
            keymaps = {
              -- extra exits on top of the default <C-c>
              ["q"] = "actions.close",
              ["<Esc>"] = "actions.close",
              -- freed up for tmux/window nav; plain '~' and 'gs' still work
              ["<C-h>" ] = false,
              ["<C-l>"] = false,
              ["<C-s>"] = { "actions.select", opts = { vertical = true } },
              ["<C-v>"] = { "actions.select", opts = { horizontal = true } },
            },
          })

          vim.keymap.set("n", "<leader>e", function()
            require("oil").open()
          end, { desc = "Oil: parent directory of file" })

          vim.keymap.set("n", "<leader>E", function()
            require("oil").toggle_float()
          end, { desc = "Oil: floating explorer" })

          -- ---- lua statusline ----
          require("lualine").setup({
            options = { theme = "auto", globalstatus = true },
            sections = {
              lualine_a = { "mode" },
              lualine_b = { "branch", "diff", "diagnostics" },
              lualine_c = { { "filename", path = 1 } },
              lualine_x = { "lsp_status", "encoding", "fileformat", "filetype" },
              lualine_y = { "progress" },
              lualine_z = { "location" },
            },
            extensions = { "oil" },
          })

          local blink = require("blink.cmp")

          blink.setup({
            keymap = {
              preset = "default",
            },

            completion = {
              documentation = {
                auto_show = true,
              },
            },

            sources = {
              default = { "lsp", "path", "snippets", "buffer" },
            },

            -- Keep this first pass independent of native matcher binaries.
            fuzzy = {
              implementation = "lua",
            },
          })

          vim.lsp.config("*", {
            capabilities = blink.get_lsp_capabilities(),
          })

          vim.lsp.config("nixd", {
            cmd = { "${pkgs.nixd}/bin/nixd" },
            settings = {
              nixd = {
                formatting = {
                  command = { "${pkgs.alejandra}/bin/alejandra" },
                },
              },
            },
          })

          -- Python language intelligence and type checking.
          vim.lsp.config("ty", {
            cmd = { "${pkgs.ty}/bin/ty", "server" },
            filetypes = { "python" },
            root_markers = { "pyproject.toml", "ty.toml", ".git" },
          })

          -- Python linting, formatting, and code actions.
          vim.lsp.config("ruff", {
            cmd = { "${pkgs.ruff}/bin/ruff", "server" },
            filetypes = { "python" },
            root_markers = {
              "pyproject.toml",
              "ruff.toml",
              ".ruff.toml",
              ".git",
            },
            on_attach = function(client)
             -- Let ty own hover information.
             client.server_capabilities.hoverProvider = false
            end,
          })


          vim.lsp.config("lua_ls", {
            settings = {
              Lua = {
                runtime = {
                  version = "LuaJIT",
                },
                diagnostics = {
                  globals = { "vim" },
                },
                workspace = {
                  checkThirdParty = false,
                  library = { vim.env.VIMRUNTIME },
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          })

          vim.lsp.enable({
            "nixd",
            "lua_ls",
            "ruff",
            "ty",
          })

          vim.keymap.set("n", "<leader>f", function()
            local preferred = {
              nix = "nixd",
              python = "ruff",
            }

            local server = preferred[vim.bo.filetype]
            if not server then
              vim.notify("No formatter wired for this filetype")
              return
            end

            vim.lsp.buf.format({
              name = server,
              async = false,
              timeout_ms = 5000,
            })
          end, { desc = "Format buffer" })

          vim.keymap.set("n", "<leader>d", function()
            vim.diagnostic.open_float({ scope = "cursor" })
          end, { desc = "Show diagnostic under curson" })

          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup(
              "NixOS4onePythonHighlight",
              { clear = true }
            ),
            pattern = "python",
            callback = function(event)
              vim.treesitter.start(event.buf)
            end,
          })

          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup(
              "NixOS4oneNixTools",
              { clear = true }
            ),
            pattern = "nix",
            callback = function(event)
              vim.treesitter.start(event.buf)
              vim.keymap.set("n", "<leader>nf", function()
                vim.lsp.buf.format({
                  bufnr = event.buf,
                  name = "nixd",
                  async = false,
                  timeout_ms = 5000,
                })
              end, {
                buffer = event.buf,
                desc = "Nix: format with Alejandra",
              })
            end,
          })
          EOF
        '';

        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            nvim-treesitter.withAllGrammars
            nvim-lspconfig
            plenary-nvim
            telescope-nvim
            oil-nvim
            lualine-nvim
            nvim-web-devicons
            vim-obsession
            blink-cmp
            friendly-snippets
            gitsigns-nvim
            nvim-lint
            tokyonight-nvim
          ];
          opt = [];
        };
      };
    };

    git = {
      package = pkgs.gitFull;
      enable = true;
      config = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = true;
      };
    };

    fish = {
      enable = true;

      interactiveShellInit = ''
        ${pkgs.zoxide}/bin/zoxide init fish | source
      '';
    };

    tmux = {
      enable = true;

      extraConfig = ''
        # Neovim workspace resoration requires a saved Session.vim.
        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-processes '"~nvim->nvim"'

        # Automatic workspace snapshots and startup restoration.
        set -g @continuum-save-interval '5'
        set -g @continuum-restore 'on'

        # NixOS owns boot startup, not the plugin.
        set -g @continuum-boot 'off'

        # Continuum's autosave uses the status line.
        set -g status on

        # Load these after other statusline/theme configuration.
        run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
        run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
      '';
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # -- Services --
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--ssh"];
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = ["scratch"];
    ensureUsers = [
      {
        name = vars.userName;
        ensureClauses = {createdb = true;};
      }
    ];
  };

  services.openssh.enable = true;

  # -- Persistent TMUX Session --
  systemd.services.tmux-main = {
    description = "Persistent NeoVim tmux session";
    wantedBy = ["multi-user.target"];

    after = ["user-runtime-dir@1000.service"];
    requires = ["user-runtime-dir@1000.service"];

    environment = {
      HOME = paths.home;

      # Preserve access to wrappers, user packages, and system packages.
      PATH = lib.mkForce "/run/wrappers/bin:${paths.userProfileBin}:/run/current-system/sw/bin";
      TMUX_TMPDIR = "/run/user/1000";
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = vars.userName;
      Group = "users";
      WorkingDirectory = paths.home;
    };

    script = ''
      if ! ${pkgs.tmux}/bin/tmux has-session -t '=editor' 2>/dev/null; then
        ${pkgs.tmux}/bin/tmux new-session -d -s editor -n neovim \
          'exec /run/current-system/sw/bin/nvim' \
          || ${pkgs.tmux}/bin/tmux has-session -t '=editor'
      fi
    '';

    preStop = ''
      ${pkgs.tmux}/bin/tmux kill-session -t '=editor' 2>/dev/null || true
    '';
  };

  # -- Fonts --
  fonts.packages = with pkgs; [
    nerd-fonts.blex-mono
    nerd-fonts.fira-mono
    nerd-fonts.roboto-mono
  ];

  environment.sessionVariables = {
    SOPS_CONFIG = "${paths.secrets}/.sops.yaml";
    CREDENTIALS_FILE = "${paths.secrets}/credentials.yaml";
  };

  ## Due to AI, the requirement to not only stay updated, but
  ## to trust enough where and how you update. Flakes make this
  ## level of granularity simpler to organize, however, Nix
  ## has some solutions to this worth exploring. It still
  ## requires a level of abstration, it's just a different
  ## perspective and approach.
  # -- Local Git Host --
  users.groups.git = {};
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/srv/git";
    createHome = true;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUbpYSJA/cmAtkoqkYbwHYgabTZu4aa4Inxjthuz0il brian@lati"
    ];
  };
  # -- User --
  users.users.${vars.userName} = {
    isNormalUser = true;
    description = vars.fullName;
    shell = pkgs.fish;
    extraGroups = ["networkmanager" "wheel"];
    linger = true;
    packages = with pkgs; [
      # Terminal
      kdePackages.kate
      ghostty

      # Languages
      python314
      lua
      rustc

      # Browsers
      brave
      librewolf

      # Security Basics
      age
      sops

      # Dev Tools
      zoxide
      uv
      gcc
      nodejs

      # Linters / LSP / Formatters
      ruff ## has python package in nixpkgs
      #basedpyright
      mypy ## has python package in nixpkgs
      ty
      nixd
      nil
      alejandra
      luajitPackages.luacheck
      lua-language-server
      stylua
      sqlfluff
      # slowql - next gen static analyzer - 282+ rules, offline, awesome - need to download from gitub later and package into a module

      # Database clients
      mariadb
      sqlite

      # Data & Docs
      miller
      pandoc ## has python package in nixpkgs
      pup

      # Neovim Help
      tree-sitter
    ];
  };

  # Install firefox.
  programs.firefox.enable = false;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    # Maintence & Troubleshooting
    curl
    wget
    less
    file
    tree
    fd
    ripgrep
    pciutils
    usbutils
    htop
    lsof
    wl-clipboard

    # Daily Driver Utilities
    jq
    yq
    xq
    eza
    bat

    # Network
    rustscan

    # Archives
    zip
    unzip
    busybox
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}

