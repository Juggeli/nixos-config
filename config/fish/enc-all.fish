function enc-all
  for file in $argv/**/*.{mkv,mp4,asf,wmv,avi,rmvb,td,ts,m2ts}
    echo "Processing file $(path basename $file)"
    set codec (ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $file)
    if test "$codec" != "av1"
      echo "... not av1, encoding"
      if enc-auto $file
        echo "Auto encode success, removing og file"
        rm $file
      else if enc-crf $file
        echo "Crf encode success"
        set og_size (stat -Lc%s $file)
        set new_size (stat -Lc%s $(path change-extension '' $file).svtav1.mkv)
        if test $new_size -lt $og_size
          echo "New file is smaller, removing og file"
          rm $file
        end
      else
        echo "Failed to encode file $(path basename $file)"
      end
    end
  end
end
