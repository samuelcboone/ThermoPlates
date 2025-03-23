#!/bin/bash

# Do only once: chmod +rwx 01_Thermochronology_Assessment.sh  # Gives read, write, execute permission for script 

### Makes a series of 2D and 3D scatter plots to examine potential relationships between cooling rates through time versus defined region or sub-region, and versus longitude or latitude (ED2 in Boone et al., 2025). 
### The code also makes 3D lon-lat-cooling rate figures for each million-year time step (Vid. S1 in Boone et al., 2025) and static 4D lon-lat-time-cooling rate plots (Figs. 1d & 1e in Boone et al., 2025).



gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=10p MAP_FRAME_PEN=thin FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm COLOR_NAN=245@transparency




### Prompt user to provide new directory name base ###

read -p "What would you like to call your new output directory for this script? " directory

directory_name="Thermochronology_Assessment_$directory"

mkdir -v -m777 $directory_name

cd $directory_name || exit 1



# Define map region and projection
region=d # -180/180/-90/90
projection=W30/15c # 30 deg E, 15 wide plot

# Load and make colour palettes to be used for different maps
age_grid_cpt=agegrid_maria_2021.cpt
topo_cpt=ETOPO.cpt

gmt makecpt -Cdevon -T0/1/0.1 -Z -I > thermochron_v1.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cdevon -T0/1/0.1 -Z -I -A+50 > thermochron_interp.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cvik -T-800/800/50 -Z > dynamic_topo.cpt

gmt makecpt -Cvik -T0/10/1 -Z > convergence.cpt

gmt makecpt -Cdavos -T0/6/1 -Z -I > paleoprecip.cpt

gmt makecpt -Ccool -T39/55/0.1 -Z -I > lat.cpt

gmt makecpt -Cmagma -T63/101/0.1 -Z -I > lon.cpt

gmt makecpt -Cturbo -T0/5/0.1 -Z -A60+a > four_d_trans.cpt

gmt makecpt -Cturbo -T0/5/0.1 -Z > four_d.cpt

gmt makecpt -Cearth -T0/7/1 > regions.cpt

gmt makecpt -Cearth -T0/26/1 > subregions.cpt

gmt makecpt -Chaxby -T0/16/1 > tianshanregions.cpt

gmt makecpt -Chaxby -T18/25/1 > altairegions.cpt




# Define thermodata variable based on input cooling histroy data
thermodata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4.csv 
tianshandata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Tian_Shan.csv # Data from Tian Shan region
hamountainsdata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Ha_Mts.csv # Data from Ha-erh-lik'o Mts region
centraluzbekdata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Central_Uzbekistan.csv # Data from Central Uzbekistan region
junggardata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Junggar_Basin.csv # Data from Junggar Basin region
gobihamidata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Gobi-Hami.csv # Data from Gobi-Hami Basins region
altaidata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Altai.csv # Data from Altai region
siberiadata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Siberia.csv # Data from Siberian Plains region

faults_static=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Faults/reconstructed_0.00Ma.gmt
afead_faults_static=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/AFEAD_Faults/AFEAD_v2022/reconstructed_0.00Ma.gmt

#key_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Key_Faults/USGS_Faults/master_shapefile.shp
#key_afead_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Key_Faults/AFEAD_Faults/master_AFEAD_shapefile.shp

# Convert .shp files to .gmt files
ogr2ogr -f "GMT" key_faults.gmt $key_faults
ogr2ogr -f "GMT" key_afead_faults.gmt $key_afead_faults

# Create new file thermodata.xyz which lists all of the sample modern latitudes ($1), modern longitudes ($2), names ($3), ages ($4), paleotemperature ($6), cooling rates ($7), region ($8) and sub-region ($9), 
# then remove first row of data with column headers.

# For Central Asia dataset, the regions and sub-regions were defined as:
# REGIONS: 1 - Tian Shan, 2 - Ha-erh-lik'o Mts, 3 - Central Uzbekistand, 4 - Junggar Basin, 5 - Gobi-Hami, 6 - Altai, 7 - Siberian Plain
# SUB-REGIONS: 
# Tian Shan sub-regions: 1 - S. Tian Shan, 2 - C. Tian Shan, 3 - N. Tian Shan, 4 - Song-Kul Lake, 5 - Talas Alatau Range, 6 - Fergana Mts, 7 - Toktogul Reservoir, 8 - Karatau Range, 9 - Chatkal Range, 10 - Turkestan Mts, 12 - Trans Alai Range, 13 - Shu-ile Mts, 14 - Zhongghar Alatau Range, 15 - Borohur-Eren-Bogda-Halik Mts
# Ha-erh-lik'o Mts sub-regions: 16 - Ha-erh-lik'o Mts
# Central Uzbekistan sub-regions: 11 - Central Uzbekistan
# Junggar Basin sub-regions: 17 - Junggar Basin
# Gobi-Hami sub-regions: 18 - Gobi-Hami Basins
# Altai sub-regions: 19 - Mongolian Altai, 20 - West Altai, 21 - Middle Altai, 22 - Yenisey Basin, 23 - Sangilen Highlands, 24 - West Sayan Mts
# Siberian Plain sub-regions: 25 - Siberian Plain


awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $thermodata | sed '1d'> thermodata.xyz 
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $tianshandata | sed '1d'> tianshandata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $hamountainsdata | sed '1d'> hamountainsdata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $centraluzbekdata | sed '1d'> centraluzbekdata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $junggardata | sed '1d'> junggardata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $gobihamidata | sed '1d'> gobihamidata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $altaidata | sed '1d'> altaidata.xyz
awk -F "\"*,\"*" '{print $1, $2, $3, $4, $6, $7, $8, $9}' $siberiadata | sed '1d'> siberiadata.xyz


# Note, columns of new thermodata.xyz file are lat ($1), lon ($2), sample name ($3), time period/age ($4), paleotemperature ($5), cooling rate ($6), region ($7) and sub-region ($8)




### COOLING RATES V TIME PLOTS - ALL DATA ###

### Make plot of cooling rate v time for all data ###

# Create a post script file
psfile=cooling_v_time.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6, $7}' thermodata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Cregions.cpt -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Y6c -K > $psfile

# Add title
echo "Cooling Rate Over Time - All Data" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for sample region
gmt psscale -Cregions.cpt -Dx0c/0c+w10c/0.5c+h -Bxa1+l"Sample Region" -Y-4c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time, coloured by latitude, for all data 

# Create a post script file
psfile=cooling_v_time_by_lat.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $1, $4, $6}' thermodata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -i1,2,0 -Sc2.0p -Clat.cpt -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time by Latitude" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Clat.cpt -Dx0c/0c+w10c/0.5c -Bxa5f1+l"Latitude [@.N]" -X12c -Y-1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time, coloured by longitude, for all data 

# Create a post script file
psfile=cooling_v_time_by_lon.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $2, $4, $6}' thermodata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -i1,2,0 -Sc2.0p -Clon.cpt -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time by Longitude" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Clon.cpt -Dx0c/0c+w10c/0.5c -Bxa5f1+l"Longitude [@.E]" -X12c -Y-1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 




### COOLING RATES V TIME PLOTS - BY REGION AND SUB-REGION ###

### Make plot of cooling rate v time for Tian Shan region - code 1

# Create a post script file
psfile=cooling_v_time_tianshan.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6, $8}' tianshandata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -i0,1,2 -Sc2.0p -Ctianshanregions.cpt -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Tian Shan" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Ctianshanregions.cpt -Dx0c/0c+w10c/0.5c -Bxa1+l"Sample Sub-Region" -X12c -Y-1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Ha-erh-lik'o Mts region - code 2 (this region only has one sub-region)

# Create a post script file
psfile=cooling_v_time_ha_mts.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6}' hamountainsdata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Gdodgerblue4 -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Ha-erh-lik'o Mountains" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Central Uzbekistan region - code 3 (this region only has one sub-region)

# Create a post script file
psfile=cooling_v_time_central_uzbekistan.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6}' centraluzbekdata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Gseagreen4 -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Central Uzbekistan" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Junggar Basin region - code 4 (this region only has one sub-region)

# Create a post script file
psfile=cooling_v_time_junggar.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6}' junggardata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Gfirebrick -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Junggar Basin Region" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Gobi-Hami Basin region - code 5 (this region only has one sub-region)

# Create a post script file
psfile=cooling_v_time_gobi-hami.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6}' gobihamidata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Gdarkslategray -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Gobi-Hami Basins Region" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Altai region - code 6

# Create a post script file
psfile=cooling_v_time_altai.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6, $8}' altaidata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -i0,1,2 -Sc2.0p -Caltairegions.cpt -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Altai" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Caltairegions.cpt -Dx0c/0c+w10c/0.5c -Bxa1+l"Sample Sub-Region" -X12c -Y-1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make plot of cooling rate v time for Siberian Plains region - code 7 (this region only has one sub-region)

# Create a post script file
psfile=cooling_v_time_siberia.ps 

# Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
awk '{print $4, $6}' siberiadata.xyz | gmt psxy -R0/230/0/15 -JX10c/10c -Sc2.0p -Gmediumpurple4 -W0.1p,black -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -K > $psfile

# Add title
echo "Cooling Rate Over Time, Siberian Plains" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 




### 3D COOLING RATES V TIME V {ATTRIBUTE] PLOTS ###

### Make 3D plot of cooling rate v time for all data by latitude###

# Create a post script file
psfile=cooling_v_time_v_lat.ps 


# Make a 3D histogram of cooling rate versus time versus latitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, and modern sample latitudes range from ~39-55 degrees N
awk '{print $4, $1, $6}' thermodata.xyz | gmt psxyz -Bxa50f10+l"Time [Ma]" -Bya1+l"Latitude [@.N]" -Bza5f1+l"Cooling Rate [@.C/Ma]" -R0/230/36/58/0/15 -JX10c/10c -JZ10c -p315/45 -So1u/0.1u -P -Wthinnest -Cfour_d.cpt -i0:2,2 -K > $psfile

# Add scale for Cooling Rate
gmt psscale -Cfour_d.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c+ef -Bxa5f1+l"Cooling Rate [@.C/Ma]" -Y-1c -X14c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make 3D plot of cooling rate v time for all data by longitude###

# Create a post script file
psfile=cooling_v_time_v_lon.ps 

# Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, and modern sample longitudes range from ~63-101 degrees E
awk '{print $2, $4, $6}' thermodata.xyz | gmt psxyz -Bya50f10+l"Time [Ma]" -Bxa5f1+l"Longitude [@.E]" -Bza5f1+l"Cooling Rate [@.C/Ma]" -R60/104/0/230/0/15 -JX10c/10c -JZ10c -p230/45 -So0.1u/1u -P -Wthinnest -Cfour_d.cpt -i0:2,2 -K > $psfile

# Add scale for Cooling Rate
gmt psscale -Cfour_d.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c+ef -Bxa5f1+l"Cooling Rate [@.C/Ma]" -Y-3c -X14c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make 3D plot of cooling rate v time for Tian Shan sub-regions ###

# Create a post script file
psfile=cooling_v_time_tianshan_subregions.ps 

# Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, and modern sample longitudes range from ~63-101 degrees E
awk '{print $8, $4, $6}' tianshandata.xyz | gmt psxyz -Bya50f10+l"Time [Ma]" -Bxa1+l"Sub-Region" -Bza5f1+l"Cooling Rate [@.C/Ma]" -R0/16/0/230/0/15 -JX15c/15c -JZ15c -p230/45 -So0.1u/1u -P -Wthinnest -Ctianshanregions.cpt -i0:2,0 -K > $psfile

# Add scale for Cooling Rate
gmt psscale -Ctianshanregions.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c -Bxa1+l"Sub-Region" -Y2c -X20c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Make 3D plot of cooling rate v time for Altai sub-regions ###

# Create a post script file
psfile=cooling_v_time_altai_subregions.ps 

# Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, and modern sample longitudes range from ~63-101 degrees E
awk '{print $8, $4, $6}' altaidata.xyz | gmt psxyz -Bya50f10+l"Time [Ma]" -Bxa1+l"Sub-Region" -Bza5f1+l"Cooling Rate [@.C/Ma]" -R18/25/0/230/0/15 -JX15c/15c -JZ15c -p230/45 -So0.1u/1u -P -Wthinnest -Caltairegions.cpt -i0:2,0 -K > $psfile

# Add scale for Cooling Rate
gmt psscale -Caltairegions.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c -Bxa1+l"Sub-Region" -Y2c -X20c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 




### 4D COOLING RATES V TIME PLOTS ###

### Make 4D plot of sample coordinates (x,y) versus time (z) versus cooling rate (colour) for all data ###

# Create a post script file
psfile=cooling_v_time_v_coordinates.ps 

# Plot topography 
gmt grd2cpt @earth_relief_15s -R60/104/36/58 -Crelief -Z # -JM10c
gmt grdimage @earth_relief_15s -R -J -p125/45 -K > $psfile #-JZ15c -Bxa5f1 -Bya5f1 -Bza50f10+l"Time [Ma]" -BSEnwZ+b -Crelief
#gmt grdimage @earth_relief -R -J -K > $psfile

# Plot faults
gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -p125/45 -K -O >> $psfile  
gmt psxy -R -J $faults_static -W0.2p,black -p125/45 -K -O >> $psfile

## Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
#awk '{print $2, $1, -$4, $6}' thermodata.xyz | gmt plot3d -R60/104/36/58/-230/0 -JZ15c -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza50f10+l"Time [Ma]" -p125/45 -K -O >> $psfile  

# Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
awk '{print $2, $1, -$4, $6}' thermodata.xyz | gmt psxyz -R60/104/36/58/-230/0 -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza50f10+l"Time [Ma]" -BSEnwZ+b -JM10c -JZ12c -p125/45 -Sp3p -P -W0.1p,black -Cfour_d_trans.cpt -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Cfour_d.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c+ef -Bxa5f1+l"Cooling Rate [@.C/Ma]" -Y2c -X16c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 




### Make 4D plot of sample coordinates (x,y) versus time (z) versus cooling rate (colour) for all data from SE-facing perspective ###

# Create a post script file
psfile=cooling_v_time_v_coordinates_SE.ps 

# Plot topography 
gmt grd2cpt @earth_relief_15s -R60/104/36/58 -Crelief -Z # -JM10c
gmt grdimage @earth_relief_15s -R -J -p305/45 -K > $psfile #-JZ15c -Bxa5f1 -Bya5f1 -Bza50f10+l"Time [Ma]" -BSEnwZ+b -Crelief
#gmt grdimage @earth_relief -R -J -K > $psfile

# Plot faults
gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -p305/45 -K -O >> $psfile  
gmt psxy -R -J $faults_static -W0.2p,black -p305/45 -K -O >> $psfile

## Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
#awk '{print $2, $1, -$4, $6}' thermodata.xyz | gmt plot3d -R60/104/36/58/-230/0 -JZ15c -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza50f10+l"Time [Ma]" -p125/45 -K -O >> $psfile  

# Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
awk '{print $2, $1, -$4, $6}' thermodata.xyz | gmt psxyz -R60/104/36/58/-230/0 -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza50f10+l"Time [Ma]" -BseNWZ+b -JM10c -JZ12c -p305/45 -Sp3p -P -W0.1p,black -Cfour_d_trans.cpt -K -O >> $psfile

# Add scale for Cooling Rate
gmt psscale -Cfour_d.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c+ef -Bxa5f1+l"Cooling Rate [@.C/Ma]" -Y2c -X16c -O >> $psfile

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A 
gmt psconvert $psfile -Tg -A 



### Run loop through defined time steps (in Myr intervals), e.g., 230-0 Ma, producing new post script (ps) files for each time step ###
age=0
while (( $age <= 230 ))
    do

        ### 4D COOLING RATES V TIME PLOTS ###
        
        ### Make 4D plot of sample coordinates (x,y) versus time (z) versus cooling rate (colour) for all data ###

        # Generate .xyz file of cooling lat, long and cooling rates for time step
        awk -v age=$age '$4 == age {print $2, $1, $6, $6}' thermodata.xyz > thermochronology_${age}.xyz

        # Make files for active faults for this time step
        active_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Key_Faults/USGS_Faults/static_active_faults_uninterpolated_${age}.shp
        active_afead_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Key_Faults/AFEAD_Faults/static_active_afead_faults_uninterpolated_${age}.shp

        # Convert .shp files to .gmt files
        ogr2ogr -f "GMT" active_faults_${age}.gmt $active_faults
        ogr2ogr -f "GMT" active_afead_faults_${age}.gmt $active_afead_faults
        
        # Create a post script file
        psfile=3Dcooling_v_coordinates_${age}.ps 
        
        # Plot topography 
        gmt grd2cpt @earth_relief -R60/104/36/58 -JM15c -Crelief -Z -K -O
        gmt grdimage @earth_relief -R -J -p125/40 -K > $psfile #-JZ15c -Bxa5f1 -Bya5f1 -Bza50f10+l"Time [Ma]" -BSEnwZ+b -Crelief
        #gmt grdimage @earth_relief -R -J -K > $psfile
        
        # Plot faults
        #gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -p -K -O >> $psfile  
        #gmt psxy -R -J $faults_static -W0.2p,black -p -K -O >> $psfile


        gmt psxy -R -J $faults_static -W0.1p,darkgray -p -K -O >> $psfile
        gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -p -K -O >> $psfile  
        gmt psxy -R -J key_faults.gmt -W0.2p,black -p -K -O >> $psfile
        gmt psxy -R -J key_afead_faults.gmt -W0.2p,black -p -K -O >> $psfile  
        gmt psxy -R -J active_faults_${age}.gmt -W0.5p,yellow1 -p -K -O >> $psfile
        gmt psxy -R -J active_afead_faults_${age}.gmt -W0.5p,red1 -p -K -O >> $psfile  
        
        ## Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
        #awk '{print $2, $1, -$4, $6}' thermodata.xyz | gmt plot3d -R60/104/36/58/-230/0 -JZ15c -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza50f10+l"Time [Ma]" -p -K -O >> $psfile  
        
        # Make a 3D histogram of cooling rate versus time versus longitude; For Central Asia dataset, cooling rates range from ~0-45 C/Ma, modern sample longitudes range from ~63-101 degrees E, and modern sample longitudes range from ~81-90 degrees E
        gmt psxyz thermochronology_${age}.xyz -R60/104/36/58/0/5 -Bxa5f1+l"Longitude [@.E]" -Bya5f1+l"Latitude [@.N]" -Bza1f0.1+l"Cooling Rate [@.C/Ma]" -BSEnwZ -JM15c -JZ10c -p -SO2p -P -W0.1p,black -Cfour_d.cpt -K -O >> $psfile
        
        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O -X0.1c -Y4c >> $psfile

        # Add scale for Cooling Rate
        gmt psscale -Cfour_d.cpt -Dx2c/1c+JRM+o0/2c+w10c/0.5c+ef -Bxa5f1+l"Cooling Rate [@.C/Ma]" -X16c -Y-2c -O >> $psfile
        
        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A 
        gmt psconvert $psfile -Tg -A 




    age=$(($age + 1))
done



exit





