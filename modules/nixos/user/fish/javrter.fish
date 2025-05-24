function javrter
    set -g base_dir ~/tank/sorted/jav/sorted

    set -g dirs (fd -t d -d 1 . $base_dir | shuf)
    set -g delete_dirs

    for dir in $dirs
        echo "Checking $dir"
        if not test -f $dir/.keep
            fd -e mkv -e mp4 . "$dir" | mpv --really-quiet --playlist=-
            set choice ( gum choose "keep" "delete" "quit" )
            switch $choice
                case keep
                    echo "Keeping $dir"
                    touch $dir/.keep
                case delete
                    echo "Deleting $dir"
                    set delete_dirs $delete_dirs $dir
                case quit
                    echo "Quitting..."
                    break
            end
        end
    end


    if test -n "$delete_dirs"
        echo "Files to be deleted:"
        for dir in $delete_dirs
            echo $dir
        end
        if gum confirm "Delete files?"
            echo "Deleting files..."
            for dir in $delete_dirs
                echo "Deleting $dir"
                rm -rf "$dir"
            end
        end
    end
end
