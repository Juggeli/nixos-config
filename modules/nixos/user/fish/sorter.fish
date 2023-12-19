# This is a script to sort video files

# Define base directory
set base_dir "/mnt/pool/downloads/random/"

# Define destination directories
set jav_dir "/mnt/pool/sorted/jav/unsorted/"
set muut_dir "/mnt/pool/sorted/muut/"
set uncen_dir "/mnt/pool/sorted/uncen/"

# List of junk file extensions, .html, .html, .url
set -l junk_exts ".html" ".htm" ".url" ".jpg" ".jpeg" ".png" ".webp"

# Get a list of video files from the base directory
set video_files (find "$base_dir" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.webm" -o -name "*.m4v" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.m2v" -o -name "*.m4v" -o -name "*.ts" -o -name "*.vob" -o -name "*.3gp" -o -name "*.3g2" \))

# List variable for files to be deleted
set delete_files

# Loop through each video file
for video_file in $video_files
    # Open video file in mpv
    echo -e "Playing $video_file"
    mpv --quiet $video_file

    # Ask user for choice
    set_color yellow
    echo -e "d. Delete"
    echo -e "j. Move to JAV"
    echo -e "m. Move to Muut"
    echo -e "u. Move to Uncen"
    echo -e "r. Play again"
    echo -e "q. Quit"
    set_color normal
    read -n 1 -P "Enter choice: " choice

    # Delete file if user chooses d
    if test $choice = "d"
        # Add file to delete list
        set delete_files $delete_files $video_file
    end

    # Move file to JAV directory if user chooses j
    if test $choice = "j"
        set_color green
        echo -e "Moving $video_file to $jav_dir"
        set_color normal
        mv $video_file $jav_dir
    end

    # Move file to Muut directory if user chooses m
    if test $choice = "m"
        set_color green
        echo -e "Moving $video_file to $muut_dir"
        set_color normal
        mv $video_file $muut_dir
    end

    # Move file to Uncen directory if user chooses u
    if test $choice = "u"
        set_color green
        echo -e "Moving $video_file to $uncen_dir"
        set_color normal
        mv $video_file $uncen_dir
    end

    # Play file again if user chooses r
    if test $choice = "r"
        # Open video file in mpv
        echo -e "Playing $video_file"
        mpv $video_file
    end

    # Quit if user chooses q
    if test $choice = "q"
        break
    end
end

# Print delete list
set_color yellow
echo -e "Files to be deleted:"
set_color normal
for delete_file in $delete_files
    echo $delete_file
end

# If there is files to be deleted, ask user if they want to delete files
if test -n "$delete_files"
    read -P "Delete files? (y/n): " delete_choice
end

# Delete files if user chooses y
if test $delete_choice = "y"
    set_color red
    echo -e "Deleting files..."
    set_color normal
    # Delete files in delete list
    for delete_file in $delete_files
        rm $delete_file
    end
end

# Recursively delete all junk files
set_color red
echo -e "Deleting junk files..."
set_color normal
for junk_ext in $junk_exts
    find "$base_dir" -type f -name "*$junk_ext" -print -delete
end

# Recursively find all empty directories and delete them
set_color red
echo -e "Deleting empty directories..."
set_color normal
find "$base_dir" -type d -empty -delete -print
