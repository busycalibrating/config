function flac2aiff
    argparse 'y/yes' 'd/directory=' 'o/output=' -- $argv
    or return

    set dir $_flag_directory
    if test -z "$dir"
        set dir "."
    end

    set outdir $_flag_output
    if test -z "$outdir"
        set outdir "$dir"
    end

    # Ensure the output directory exists
    mkdir -p "$outdir"

    set ffmpeg_opts "-n"
    if set -q _flag_yes
        set ffmpeg_opts "-y"
    end

    for file in $dir/*.flac
        set basename (basename $file .flac)
        ffmpeg $ffmpeg_opts -i $file -write_id3v2 1 -c:v copy "$outdir/$basename.aiff"
    end
end
# function flac2aiff
#     argparse 'y/yes' 'd/directory=' -- $argv
#     or return
# 
#     set dir $_flag_directory
#     if test -z "$dir"
#         set dir "."
#     end
# 
#     set ffmpeg_opts "-n"
#     if set -q _flag_yes
#         set ffmpeg_opts "-y"
#     end
# 
#     for file in $dir/*.flac
#         set basename (basename $file .flac)
#         ffmpeg $ffmpeg_opts -i $file  -write_id3v2 1 -c:v copy "$dir/$basename.aiff"
#     end
# end
# function flac2wav
#     argparse 'y/yes' 'n/no' 'd/directory=' -- $argv
#     or return
# 
#     set dir $_flag_directory
#     if test -z "$dir"
#         set dir "."
#     end
# 
#     set ffmpeg_opts ""
#     if set -q _flag_yes
#         set ffmpeg_opts "-y"
#     else if set -q _flag_no
#         set ffmpeg_opts "-n"
#     end
# 
#     for file in $dir/*.flac
#         set basename (basename $file .flac)
#         echo ffmpeg $ffmpeg_opts -i $file "$dir/$basename.wav"
#         ffmpeg $ffmpeg_opts -i $file "$dir/$basename.wav"
#     end
# end
