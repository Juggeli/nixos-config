function enc-crf
    ab-av1 encode -e libsvtav1 --preset 8 \
        --acodec libopus --enc b:a=48k --enc vbr=on \
        --enc compression_level=10 --enc frame_duration=60 \
        --enc application=audio --crf 30 \
        --pix-format yuv420p10le \
        -o $(path change-extension '' $argv).av1.mkv \
        -i $argv
end
