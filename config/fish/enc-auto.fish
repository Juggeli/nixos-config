function enc-auto
  set width (ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 $argv)
  if test $width -eq 3840
    set vmaf_path "/home/juggeli/.config/dotfiles/config/vmaf_4k_v0.6.1.json"
  else
    set vmaf_path "/home/juggeli/.config/dotfiles/config/vmaf_v0.6.1.json"
  end
  
  ab-av1 auto-encode --preset 10 \
    --vmaf model=path=$vmaf_path \
    --acodec libopus --enc b:a=48k --enc vbr=on \
    --enc compression_level=10 --enc frame_duration=60 \
    --enc application=audio \
    --pix-format yuv420p10le \
    -o $(path change-extension '' $argv).av1.mkv \
    -i $argv
end
