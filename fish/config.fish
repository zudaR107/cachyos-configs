# Fish shell configuration.
# Location: ~/.config/fish/config.fish

# Source the vendor CachyOS Fish configuration if present.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# Override the default greeting behavior.
function fish_greeting
    # Invoke a custom greeting function if it exists.
    if functions -q hello
        hello
    end
end

# Source HyDE configuration (if installed).
if test -f ~/.config/fish/hyde_config.fish
    source ~/.config/fish/hyde_config.fish
end

# Initialize Starship prompt (XDG-aware).
if type -q starship
    set -gx STARSHIP_CACHE  "$XDG_CACHE_HOME/starship"
    set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"
    starship init fish | source
end

# Initialize fzf key bindings and completions.
if type -q fzf
    fzf --fish | source
end

# Pager and suggestion styling.
set fish_pager_color_prefix cyan
set fish_color_autosuggestion brblack

# Ensure GPG pinentry can access the correct TTY.
set -gx GPG_TTY (tty)

# Remove pre-defined alias functions to avoid conflicts.
for fn in l ls ll ld lt vc
    functions -e $fn 2>/dev/null
end

# Aliases.
alias l='eza -lh  --icons=auto'
alias ls='eza -1   --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias vc='code'

# Abbreviations.
abbr -a ..  'cd ..'
abbr -a ... 'cd ../..'
abbr -a .3  'cd ../../..'
abbr -a .4  'cd ../../../..'
abbr -a .5  'cd ../../../../..'
abbr -a mkdir 'mkdir -p'

abbr -a p  'python'
abbr -a j  'JLinkExe -nogui 1 -commandfile'
abbr -a jf 'JLinkExe -nogui 1 -commandfile flash/flash.jlink'
abbr -a je 'JLinkExe -nogui 1 -commandfile flash/erase.jlink'
abbr -a of 'openocd -f flash/script.cfg -f flash/flash.ocd'
abbr -a oe 'openocd -f flash/script.cfg -f flash/erase.ocd'
abbr -a m  'make -j8'
abbr -a mc 'make clean'
abbr -a lg 'lazygit'
abbr -a g  'git'

# Start ssh-agent if no agent socket is available.
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
end
