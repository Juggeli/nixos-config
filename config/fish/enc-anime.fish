function enc-anime
  set jpn_audio_index (ffprobe -v error -select_streams a -show_entries stream=index:stream_tags=language -of csv=p=0 $argv | grep "jpn" | cut -d "," -f 1)
  set sub_indexes (ffprobe -v error -select_streams s -show_entries stream=index,codec_name -of csv=p=0 $argv | grep "ass" | cut -d "," -f 1)
  echo "jpn audio index is $jpn_audio_index"
  echo "subtitle indexes are $sub_indexes"
  if set -q jpn_audio_index[1] && set -q sub_indexes[1]
    set output_file "$(path change-extension '' $argv).x265.mkv"
    set sub_map
    for i in $sub_indexes
      set -a sub_map "-map" "0:"$i
    end
    ffmpeg -v quiet -stats -i $argv -crf 23 -c:v libx265 -c:a libopus \
      -b:a 128k -vbr on -preset medium \
      -x265-params bframes=8:psy-rd=1:aq-mode=3 \
      -map 0:v:0 \
      -map 0:$jpn_audio_index \
      $sub_map \
      -map "0:t?" \
      $output_file
  else 
    return 1
  end
end
