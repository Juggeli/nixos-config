function enc-anime
  set jpn_audio_index (ffprobe -v error -select_streams a -show_entries stream=index:stream_tags=language -of csv=p=0 $argv | grep "jpn" | cut -d "," -f 1)
  set sub_indexes (ffprobe -v error -select_streams s -show_entries stream=index,codec_name -of csv=p=0 $argv | grep "ass" | cut -d "," -f 1)
  if set -q jpn_audio_index[1] && set -q sub_indexes[1]
    echo "jpn audio index is $jpn_audio_index"
    echo "subtitle indexes are $sub_indexes"
    ab-av1 encode --crf 23 -e libx265 --acodec libopus \
      --enc b:a=128k --enc vbr=on \
      --enc x265-params=bframes=8:psy-rd=1:aq-mode=3:preset=slow \
      --enc map=0:a:$jpn_audio_index \
      "--enc map=0:s:"$sub_indexes \
      -i $argv
  end
end
