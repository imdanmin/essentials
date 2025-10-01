# https://superuser.com/questions/692990/use-ffmpeg-copy-codec-to-combine-ts-files-into-a-single-mp4

ffmpeg -f concat -i mylist.txt -c copy all.ts && ffmpeg -i all.ts -acodec copy -vcodec copy all.mp4
