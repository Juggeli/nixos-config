function sorter
    # Define base directory
    set -g base_dir /mnt/pool/downloads/random/

    # Define destination directories
    set -g jav_dir /mnt/pool/sorted/jav/unsorted/
    set -g muut_dir /mnt/pool/sorted/muut/
    set -g uncen_dir /mnt/pool/sorted/uncen/
    set -g to_upscale_dir /mnt/pool/sorted/to-be-upscaled/

    set -l junk_exts ".html" ".htm" ".url" ".jpg" ".jpeg" ".png" ".webp"
    set -l video_exts ".mkv" ".mp4" ".avi" ".mov" ".wmv" ".flv" ".webm" ".m4v" ".mpeg" ".m2v" ".m4v" ".ts" ".vob" ".3gp" ".3g2" ".mpg"
    set -g delete_files

    set video_files
    function print_color -a color text
        set_color $color
        echo -e $text
        set_color normal
    end

    function process_file -a video_file
        while true
            echo -e "Playing $video_file"
            mpv --really-quiet $video_file

            set_color yellow
            echo -e "d. Delete"
            echo -e "j. Move to JAV"
            echo -e "m. Move to Muut"
            echo -e "u. Move to Uncen"
            echo -e "t. Move to upscale"
            echo -e "r. Play again"
            echo -e "q. Quit"
            set_color normal
            read -n 1 -P "Enter choice: " choice

            switch $choice
                case d
                    set -g delete_files $delete_files $video_file
                    return
                case j
                    print_color green "Moving $video_file to $jav_dir"
                    mv "$video_file" "$jav_dir"
                    return
                case m
                    print_color green "Moving $video_file to $muut_dir"
                    mv "$video_file" "$muut_dir"
                    return
                case u
                    print_color green "Moving $video_file to $uncen_dir"
                    mv "$video_file" "$uncen_dir"
                    return
                case t
                    print_color green "Moving $video_file to $to_upscale_dir"
                    mv "$video_file" "$to_upscale_dir"
                    return
                case r
                    process_file $video_file
                    return
                case q
                    return 1
            end
        end
    end

    for video_ext in $video_exts
        set video_files $video_files (find "$base_dir" -type f -name "*$video_ext")
    end

    for video_file in $video_files
        if not process_file $video_file
            break
        end
    end

    if test -n "$delete_files"
        print_color yellow "Files to be deleted:"
        for delete_file in $delete_files
            echo $delete_file
        end
        read -P "Delete files? (y/n): " delete_choice
        if test $delete_choice = y
            print_color red "Deleting files..."
            # Delete files in delete list
            for delete_file in $delete_files
                rm $delete_file
            end
        end
    end

    # Recursively delete all junk files
    print_color red "Deleting junk files..."
    for junk_ext in $junk_exts
        find "$base_dir" -type f -name "*$junk_ext" -print -delete
    end

    # Recursively find all empty directories and delete them
    print_color red "Deleting empty directories..."
    find "$base_dir" -type d -empty -delete -print
end
