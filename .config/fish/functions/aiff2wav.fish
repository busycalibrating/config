# function flac2wav
#     set dir $argv[1]
#     if test -z "$dir"
#         set dir "."
#     end
#     for file in $dir/*.flac
#         set basename (basename $file .flac)
#         ffmpeg -i $file "$dir/$basename.wav"
#     end
# end
function aiff2wav
    argparse 'y/yes' 'd/directory=' -- $argv
    or return

    set dir $_flag_directory
    if test -z "$dir"
        set dir "."
    end

    set ffmpeg_opts "-n"
    if set -q _flag_yes
        set ffmpeg_opts "-y"
    end

    for file in $dir/*.aiff
        set basename (basename $file .aiff)
        ffmpeg $ffmpeg_opts -i $file "$dir/$basename.wav"
    end
end
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
