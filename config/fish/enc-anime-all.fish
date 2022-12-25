function enc-anime-all
  for file in $argv/**/*.{mkv,mp4,asf,wmv,avi,rmvb,td,ts,m2ts}
    echo "Processing file $(path basename $file)"
    set video_codec (ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $file)
    set audio_codec (ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 $file)
    if test "$video_codec" != "h265" && test "$audio_codec" != "opus"
      echo "... not h265 and opus, encoding"
      if enc-auto $file
        echo "Auto encode success, removing og file"
        rm $file
      else if enc-crf $file
        echo "Crf encode success, removing og file"
        set og_size (stat -Lc%s $file)
        set new_size (stat -Lc%s $(path change-extension '' $file).svtav1.mkv)
        if test $new_size -lt $og_size
          rm $file
        end
      else
        echo "Failed to encode file $(path basename $file)"
      end
    end
  end
end

