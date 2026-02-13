# Override `cd` to print a directory listing after changing directories.
function cd
    builtin cd $argv
    eza -1 --icons=auto
end
