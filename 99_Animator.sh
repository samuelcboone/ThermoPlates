#!/bin/bash

# Do only once: chmod +rwx 99_Animator.sh  # Gives read, write, execute permission for script 

### Can be placed in a directory of figures from multiple time slices (like those produced in 03_Thermochron_GPlates.sh) to make a combined animation (e.g., Vids. S1-S4 in Boone et al., 2025).

rm out.mp4 test.mpg output.mp4

cnt=0
mkdir ffmpeg
rm ffmpeg/*.jpg

for myfile in `ls -1 *.jpg | sort -r -V `
	do
	cntt=$(printf "%.3d" $cnt)
	echo $cntt
 	cp $myfile ffmpeg/${cntt}.jpg

	echo $myfile
	cnt=$((cnt+1))
done

ffmpeg -framerate 2 -r 2 -pattern_type sequence -i 'ffmpeg/%03d.jpg' -vf scale=1600:-1 -vcodec mpeg4 -b 40000k  out.mp4

ffmpeg -framerate 20 -pattern_type sequence -i 'ffmpeg/%03d.jpg' -vf pad="width=ceil(iw/2)*2:height=ceil(ih/2)*2" -c:v libx264 -preset slow -crf 22 -r 20 output.mp4
ffmpeg -i out.mp4 -pix_fmt yuv422p -r 20 -vb 6000K -minrate 5000K -maxrate 12000K test.mpg

ffmpeg -framerate 8 -pattern_type sequence -i 'ffmpeg/%03d.jpg' -vf pad="width=ceil(iw/2)*2:height=ceil(ih/2)*2" -c:v libx264 -preset slow -crf 22 -r 20 output_slow.mp4

# Make animation
# ffmpeg -framerate 2 -pattern_type sequence -i '%03d.jpg' -r 2 out.mov
