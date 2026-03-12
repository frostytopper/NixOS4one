# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable BASH fetures
  programs.bash = {
    blesh.enable = false;
    completion.enable = true;
    ##Aliases
    shellAliases = {
      l = "eza -lahF --color=auto --icons --sort=size --group-directories-first";
      la = "eza -ahF --color=auto --icons --sort=size --group-directories-first";
      ls = "eza -lhF --color=auto --icons --sort=size --group-directories-first";
      lss = "eza -hF --color=auto --icons --sort=size --group-directories-first";
      lst = "eza -lahFT --color=auto --icons --sort=size --group-directories-first";
      lt = "eza -aT --color=auto --icons --sort=size --group-directories-first";
      oscar = "sudo nix-collect-garbage -d";
      nbuild = "sudo nixos-rebuild build";
      nswitch = "sudo nixos-rebuild switch";
      tkill = "tmux kill-session";
      y = "yazi";
      ".." = "cd ..";
    };
    ##Other customizations later

    interactiveShellInit = ''
      #Ble.sh source early, no-attach
      [[ ''${BASH_VERSION-} ]] && source ${pkgs.blesh}/share/blesh/ble.sh --noattach
      #Starship init
      eval "$(starship init bash)"
      #Zoxide init
      eval "$(zoxide init bash)"
      [[ ''${BLE_VERSION-} ]] && ble-attach
    '';
  };

  programs.starship = {
    enable = true;
    #enableBashIntegration = true;
    settings = {
      add_newline = true;

      # Explicit formating
      format = "$directory$git_branch$git_status$cmd_duration$time$character";

      # Directory: Make visible, less truncated, styled
      directory = {
        truncation_length = 5; #shows more info
        truncation_symbol = ".../";
        truncate_to_repo = true; # truncate to git repo root if in one
        style = "bold cyan"; #visible, change as desired
        format = "[ $path ]($style)"; # Wrap in brackets for clarity
        home_symbol = "\~ ❄️"; #Nix snowflake for home symboll
      };

      # Character: Custom arrows
      character = {
        success_symbol = "[->](bold green)";
        error_symbol = "[->](bold red)";
      };
      # Git: Show branch/status in repos (conditional)
      git_branch = {
        symbol = "🌱 "; # Nerd Font branch icon (your font supports)
        style = "bold purple";
        format = "[ $symbol$branch ]($style)"; # Wrap for clarity
      };
      git_status = {
        format = "[$all_status$ahead_behind]($style)"; # Compact status
        style = "bold red";
        conflicted = "🏳";
        ahead = "🏎💨";
        behind = "😰";
        diverged = "😵";
        up_to_date = "✓";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++($count)](green)";
        renamed = "👅";
        deleted = "🗑";
      };

      # Cmd Duration: show after long commands
      cmd_duration = {
        min_time = 5000; # Only if >5s (default 500ms; adjust lower if wanted)
        format = " took [$duration](bold yellow)";
        show_milliseconds = false; # clean
      };

      # Time: nice to have when zoned out
      time = {
        disabled = false;
        format = " at [$time]($style) ";
        time_format = "%H:%M";
        style = "dimmed white";
      };
    };
  };

  # Enable nix-serve local cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/secrets/nixos-private.pem";
  };

  nix.settings = {
    substituters = ["http://localhost:5000/" "https://cache.nixos.org/"];
    trusted-public-keys = ["nixos.local-1:X+ss+l4yzAI6brxtyYHRcjgxwei83KM25Prc37wnXCk="];
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Zram stuff
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable nginx with angie
  services.nginx = {
    enable = true;
    package = pkgs.angie;

    virtualHosts."nixos.local" = {
      root = "/var/www";
      locations."/" = {};
    };
  };

  #systemd.services.nginx.serviceConfig.ExecStart = "";

  # Enable PostgreSQL_17
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = ["psychobiotic_db" "frosty"];
    ensureUsers = [
      {
        name = "frosty";
        ensureDBOwnership = true;
        ensureClauses = {
          superuser = true;
          login = true;
        };
      }
    ];

    authentication = pkgs.lib.mkOverride 10 ''
      local   all             postgres                                peer
      local   all             frosty                                  peer
      local   all             all                                     reject
      host    all             all            127.0.0.1/32             trust
      host    all             all            ::1/128                  trust
    '';
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Ghostty & Bash
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",*-256col*:Tc"
      set -g default-shell ${pkgs.bash}/bin/bash
      set -s escape-time 0

      # Extra bits
      set -g mouse on
      set -g base-index 1
      setw -g pane-base-index 1
      setw -g clock-mode-style 24

      # Plugins via run-shell
      run-shell ${pkgs.tmuxPlugins.sensible}/share/tmux-plugins/sensible
      run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank
      run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect
      run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum
      run-shell ${pkgs.tmuxPlugins.fuzzback}/share/tmux-plugins/fuzzback

      # Prefix: C-Space (easier than C-b; customizable)
      set -g prefix C-Space
      unbind C-b
      bind C-Space send-prefix

      # Reload config: prefix + r
      bind r source-file ~/.tmux.conf \; display "Reloaded!"

      # Nano-friendly splits (prefix + h/j for horizontal/vertical)
      bind h split-window -h -c "#{pane_current_path}"
      bind j split-window -v -c "#{pane_current_path}"

      # Status line with nerd fonts (you have tmux-nerdfonts)
      set -g status-right "#[fg=colour4] %H:%M %d-%b-%y "

      # Resurrect strategy for processes
      set -g @resurrect-capture-pane-contents 'on'
    '';
  };

  environment.etc."xdg/ghostty/config".text = ''
    font-family = "FiraCode Nerd Font"
    font-size = 14
    theme = "dark"
    initial-command = [ "tmux" "attach" "-t" "main" "||" "tmux" "new" "-s" "main" ]
    window-padding-x = 10
    window-padding-y = 10
  '';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.frosty = {
    isNormalUser = true;
    description = "frosty";
    shell = pkgs.bashInteractive;
    extraGroups = ["networkmanager" "wheel" "postgres"];
    packages = with pkgs; [
      bash
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "frosty";

  # Install firefox.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # EXPERIMENTAL package features
  nix.settings.experimental-features = ["nix-command" "flakes"];

  #List packages installed in system profile. To search, run:
  #$ nix search wget
  environment.systemPackages = with pkgs; [
    ##Python avail for quick projects and limiting downloads during shell/env building.
    python313Full

    ##database-options
    #postgresql_17

    # LSPs
    nixd
    pyright

    # Formatters
    alejandra

    ##developer-tools # build out as needed for project.
    devenv
    direnv
    nix-direnv
    python313Packages.jupyterlab
    ##pythonPackages for devenvs
    python313Packages.psycopg2 # PostgreSQL adapter for Python
    #python313Packages.pandas
    #python313Packages.numpy
    #python313Packages.scipy
    vim
    #need decide how to install NVChad
    nodejs_20

    ##terminal-options
    ghostty

    ##multiplexing-options
    tmux
    #github.com/tmux-plugins/tpm # manage plugins with this after getting setup, or build them into the devenv.
    tmuxPlugins.vim-tmux-navigator #lets them talk to eachother better, pair it with vimPlugins.vim-tmux-avigator.
    tmuxPlugins.resurrect #saves and restores sessions across restarts.
    tmuxPlugins.continuum #autosaves sessions continuously.
    tmuxPlugins.sensible #implements best practices, typecraft uses it.
    tmuxPlugins.yank #better system clipboard integration.
    tmuxPlugins.fuzzback # search thru scrollback buffer.
    #tmuxPlugins.

    ##Networking - Replacing nginx with angie
    angie

    ##Git-setup
    gitFull
    #gitmux
    ##tmux-nerdfonts
    #github.com/joshmedeski/tmux-nerd-font-window-name

    #shell-options
    #fish #explore fish specific managers like fisher to establish a setup before declaring in nix. You can create a fish flake later.

    #terminaltools
    aria2 #better curl? going to try it out.
    bat
    blesh
    curl #getting stuff http style.
    eza
    fd
    fzf
    grex
    ripgrep
    starship
    tldr
    xclip #clipboard tool.
    xh #better http tool, similar to aria2 & curl.
    xlsx2csv
    unzip
    yazi #better file navigator.
    zoxide

    ##Fonts
    nerd-fonts.fira-code

    ##compiliers
    gcc

    #browser-options
    chromium
    #helium #another lightweight browser to try, useful for transparent browsers

    ##TorTools
    qbittorrent-enhanced

    ##OfficeTools
    libreoffice-still

    ##XFCE Tools
    xfce.xfce4-screenshooter

    ##graphics
    driversi686Linux.libva-vdpau-driver

    (writeShellScriptBin "tks" ''
      # Attach to session "rks" if it exists, otherwise create it.
      exec tmux new-session -A -s rks "$@"
    '')
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
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
