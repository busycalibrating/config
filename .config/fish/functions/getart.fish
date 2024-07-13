function getart
    ffmpeg -i $argv -map 0:1 cover.jpg
end
