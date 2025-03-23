#!/bin/bash

# Do only once: chmod +rwx 00_Thermochronology_Data_Characteristics.sh  # Gives read, write, execute permission for script 

### Determines the longitude-latitude ranges of samples in the dataset, the age range constrained by the thermal history model data, the range in paleotemperatures, and the range of cooling rates. It also generates a histogram of cooling rates across the dataset (Fig. ED1 in Boone et al., 2025).


gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=10p MAP_FRAME_PEN=thin FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm COLOR_NAN=245@transparency



# Prompt user to provide new directory name base

read -p "What would you like to call your new output directory for this script? " directory

directory_name="Thermochronology_Data_Characterisation_$directory"

mkdir -v -m777 $directory_name

cd $directory_name || exit 1



# Define thermodata variable based on input cooling histroy data
thermodata=../data_V4.csv 

# Create new file thermodata.xyz which lists all of the sample modern latitudes ($1), modern longitudes ($2), names ($3), ages ($4), paleotemperature ($6) and cooling rates ($7), then remove first row of data with column headers
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7}' $thermodata | sed '1d'> thermodata.xyz

# Note, columns of new thermodata.xyz file are lat ($1), lon ($2), sample name ($3), time period/age ($4), paleotemperature ($5), and cooling rate ($6)


## Make a colour palette for colouring by samples ###      STILL A WORK IN PROGRESS
# Create new file thermosamples.xyz which lists all of the sample names, then remove first row of data with column header
awk -F "\"*,\"*" '{print $3}' $thermodata | sed '1d' > thermosamples.xyz

# Remove duplicate sample names and remove any blank lines, and sequentially add numbers to each line of data
uniq thermosamples.xyz | sed '/^$/d' | awk '{print $0, NR}' > uniqsamples.txt

# calculate number of unique sample names
echo Number of Samples
no_samples= wc -l < uniqsamples.txt

# Make a colour palette for the thermochronology samples
#gmt makecpt -Csealand uniqsamples.txt -i1 -Z -E > thermosamples.cpt

echo Minimum latitude is 
gmt math -i0 thermodata.xyz LOWER -Sf = $lat_min
echo $lat_min

echo Maximum latitude is 
gmt math -i0 thermodata.xyz UPPER -Sf = $lat_max
echo $lat_max

echo Minimum longitude is
gmt math -i1 thermodata.xyz LOWER -Sf = $lon_min
echo $lon_min

echo Maximum longitude is 
gmt math -i1 thermodata.xyz UPPER -Sf = $lon_max
echo $lon_max

echo Minimum age/time period is
gmt math -i3 thermodata.xyz LOWER -Sf = $age_min
echo $age_min

echo Maximum age/time period is 
gmt math -i3 thermodata.xyz UPPER -Sf = $age_max
echo $age_max

echo Minimum paleotemperature is
gmt math -i4 thermodata.xyz LOWER -Sf = $temp_min
echo $temp_min

echo Maximum paleotemperature is 
gmt math -i4 thermodata.xyz UPPER -Sf = $temp_max
echo $temp_max

echo Minimum cooling Rate is
gmt math -i5 thermodata.xyz LOWER -Sf = $cool_min
echo $cool_min

echo Maximum cooling rate is 
gmt math -i5 thermodata.xyz UPPER -Sf = $cool_max
echo $cool_max


#### Plot histogram of cooling rates ###

# Create a post script file
psfile=cooling_rate_histogram.ps     

# Make histogram of cooling rates 
awk '{print $6}' thermodata.xyz | gmt pshistogram -JX10c/5c -Ba5f1:"Cooling Rate [@.C/Ma]":/5:"Frequency (%)":WS -Z1 -V -W0.5 -T0 -R0/20/0/50 -Gblack -K > $psfile

# Calculate minimum and maximum cooling rates
cool_min=$(gmt math -i5 thermodata.xyz LOWER -Sf =)
cool_max=$(gmt math -i5 thermodata.xyz UPPER -Sf =)

# Add statistics
echo "Maximum Cooling Rate: $cool_max [@.C/Ma]" | gmt pstext -R -J -F+f10,Helvetica-Bold,black+cTR -N -K -O >> $psfile

# Add statistics
echo "Minimum Cooling Rate: $cool_min [@.C/Ma]" | gmt pstext -R -J -F+f10,Helvetica-Bold,black+cTR -N -Y-1c -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf, Ts is svg # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A

exit