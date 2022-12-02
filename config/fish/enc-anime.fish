function enc-anime
  ab-av1 encode --crf 23 -e libx265 --acodec libopus \
    --enc b:a=128k --enc vbr=on \
    --enc x265-params=bframes=8:psy-rd=1:aq-mode=3:preset=slow \
    -i $argv
end
