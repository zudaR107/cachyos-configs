# Wrapper for disk usage display via `duf`.
# If the last argument is an existing path, show usage for that path; otherwise show all mounts.
function df
    if test $argv
        set last_arg $argv[-1]
        if test -e "$last_arg"
            duf "$last_arg"
            return
        end
    end

    duf
end
