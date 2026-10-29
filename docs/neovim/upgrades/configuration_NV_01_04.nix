# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  pkgs,
  ...
}: let
  # Fork Me: these three values personalize the whole system.
  vars = {
    userName = "brian";
    fullName = "frozt"; # display name, indepenent of login name
    hostName = "lati";
  };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  # --  Boot --
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "lati"; # Define your hostname.
  networking.networkmanager.enable = true;

  # -- Locale / Time --
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
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

  nixpkgs.config.allowUnfree = true;

  # -- Programs (system-managed) --
  programs = {
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
          nnoremap <leader>e :Ex<Cr>

          " ---- colors ----
          colorscheme habamax

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

          -- ---- statusline ---- 
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

          vim.lsp.enable({
            "basedpyright", "nixd", "lua_ls", "ruff",
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
            blink-cmp
            friendly-snippets
            gitsigns-nvim
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

    fish.enable = true;

    tmux.enable = true;

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
    description = "Persistent tmux session";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "forking";
      User = vars.userName;
      Group = "users";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t main";
      Restart = "on-failure";
      #RemainAfterExit = true;
    };
  };

  # -- Fonts --
  fonts.packages = with pkgs; [
    nerd-fonts.blex-mono
    nerd-fonts.fira-mono
    nerd-fonts.roboto-mono
  ];

  # -- User --
  users.users.${vars.userName} = {
    isNormalUser = true;
    description = vars.fullName;
    shell = pkgs.fish;
    extraGroups = ["networkmanager" "wheel"];
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

      # Dev Tools
      zoxide
      uv
      gcc
      nodejs

      # Linters / LSP / Formatters
      ruff ## has python package in nixpkgs
      basedpyright
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
