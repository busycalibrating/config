function convertflac
    argparse 'y/yes' 'd/directory=' -- $argv
    or return

    set dir $_flag_directory
    if test -z "$dir"
        set dir "."
    end

    for subdir in $dir/*/
        set subdir_name (basename $subdir)
        set aiff_dir "$dir/$subdir_name AIFF"

        # Find FLAC files in the current subdirectory
        set flac_files (ls $subdir/*.flac 2>/dev/null)

        echo ----------------------------------------------------------------------------------------------------
        echo
        echo $subdir_name
        echo $flac_files
        echo (count $flac_files)
        echo
        echo ----------------------------------------------------------------------------------------------------

        # Only proceed if there are FLAC files
        if test (count $flac_files) -gt 0
            # Create the AIFF directory
            mkdir -p $aiff_dir

            # Convert FLAC files to AIFF
            flac2aiff -d "$subdir" -o "$aiff_dir" $argv

            # Copy only image files (JPGs, PNGs) to the AIFF directory
            for file in $subdir/*.{jpg,png}
                if test -f "$file"
                    cp "$file" "$aiff_dir/"
                end
            end
        set -e flac_files 
        end
    end
end
#     argparse 'y/yes' 'd/directory=' -- $argv
#     or return
# 
#     set dir $_flag_directory
#     if test -z "$dir"
#         set dir "."
#     end
# 
#     for subdir in $dir/*/
#         set subdir_name (basename $subdir)
#         set aiff_dir "$dir/$subdir_name AIFF"
# 
#         # Find FLAC files in the current subdirectory
#         set flac_files (ls $subdir/*.flac 2>/dev/null)
# 
#         # Only proceed if there are FLAC files
#         if test (count $flac_files) -gt 0
#             # Create the AIFF directory
#             mkdir -p $aiff_dir
# 
#             # Convert FLAC files to AIFF
#             flac2aiff -d "$subdir" -o "$aiff_dir" $argv
# 
#             # Copy only image files (JPGs, PNGs) to the AIFF directory
#             for file in $subdir/*.{jpg,png}
#                 if test -f "$file"
#                     cp "$file" "$aiff_dir/"
#                 end
#             end
#         end
#     end
# end
