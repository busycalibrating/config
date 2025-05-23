function img2pdf
    if test (count $argv) -ne 1
        echo "Usage: img2pdf <image_file>"
        return 1
    end

    set input $argv[1]
    set base (basename $input .(string split '.' $input)[-1])
    set output "$base.pdf"

    convert "$input" -resize 612x792\> -gravity center -extent 612x792 -units PixelsPerInch -density 72 "$output"
end
