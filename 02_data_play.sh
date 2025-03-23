#!/bin/bash

# Do only once: chmod +rwx 02_data_play.sh  # Gives read, write, execute permission for script 

### Makes a series of maps in present-day coordinates that plot the distribution of fast, very fast and extra fast cooling samples 
### (defined by Boone et al., 2025 for the Central Asian dataset as >0.5, >1.0, and >1.5 °C/Ma) relative to faults from an input fault database in a present-day static geography for each million-year time step. 
### It then extracts and makes scatter plots of mean and standard deviation cooling rates for each region at each million-year timestep (Fig. ED3 in Boone et al., 2025).


### Prompt user to provide new directory name base ###

read -p "What would you like to call your new output directory for this script? " directory

directory_name="Data_Play_$directory"

mkdir -v -m777 $directory_name

cd $directory_name || exit 1

mkdir -v -m777 Figures

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=10p MAP_FRAME_PEN=thin,black FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_DEFAULT_PEN=0.25p,black MAP_GRID_PEN=0.25p,black MAP_TICK_PEN=0.25p,black


# Define map region and projection
region= 60/105/37/57
projection=W30/15c # 30 deg E, 15 wide plot

# Load and make colour palettes to be used for different maps
gmt makecpt -Cdevon -T0/3/0.1 -Z -I > thermochron_v1.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cocean -T0/3/0.1 -Z -I > thermochron_v2.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cgebco -T0/3/0.1 -Z -I > thermochron_v3.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cdevon -T0/3/0.1 -Z -I -A+50 > thermochron_interp.cpt # Z is continuous colour scale, I flips/inverts

gmt makecpt -Cvik -T-800/800/50 -Z > dynamic_topo.cpt

gmt makecpt -Cno_green -T-800/800/50 -Z > dynamic_topo2.cpt

gmt makecpt -Croma -T-800/800/50 -I -Z > dynamic_topo3.cpt

gmt makecpt -Cvik -T0/10/1 -Z > convergence.cpt

gmt makecpt -Cdavos -T0/6/1 -Z -I > paleoprecip.cpt

gmt makecpt -Cdrywet -T0/6/1 -Z > paleoprecip2.cpt

gmt makecpt -Ccool -T43/53/0.1 -Z -I > lat.cpt

gmt makecpt -Cmagma -T81/90/0.1 -Z -I > lon.cpt

gmt makecpt -Cturbo -T0/10/0.1 -Z > four_d.cpt

gmt makecpt -Cno_green -T-16/16/0.1 -Z > migration.cpt

gmt makecpt -Cdem3 -T0/8000/500 -Z > topo.cpt

gmt makecpt -Cbroc -T-12000/12000/100 -Z > topo_broc.cpt

gmt makecpt -Cnighttime -T-12000/12000/100 -Z > topo_nighttime.cpt

gmt makecpt -Cinferno -T0/3/0.5 -Z -I > sector_diagram.cpt

gmt makecpt -Cimola -T0/5/0.5 -Z -I > plate_motion_rose.cpt

gmt makecpt -Clajolla -T0/150/1 -Z > conv_migr_rate.cpt

gmt makecpt -Clisbon -T-12000/12000/100 -Z > topo_lisbon.cpt

gmt makecpt -Ccork -T-12000/12000/100 -Z > topo_cork.cpt

gmt makecpt -Cdem2 -T-12000/12000/100 -Z > topo_dem2.cpt

gmt makecpt -Ctopo_dem2.cpt -G0/12000 -T-0/12000/100 -Z -N > topo_dem2_land.cpt



# Create a cooling_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > cooling_master.xyz

# Create a fast_cooling_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > fast_cooling_master.xyz

# Create a very_fast_cooling_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > very_fast_cooling_master.xyz

# Create a extra_fast_cooling_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > extra_fast_cooling_master.xyz

# Create a slow_cooling_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > slow_cooling_master.xyz



# Define thermodata variable based on input cooling history data
thermodata=/Example_data_Central_Asia.csv 
tianshandata=/Example_data_Tian_Shan.csv # Data from Tian Shan region
hamountainsdata=/Example_data_Ha_Mts.csv # Data from Ha-erh-lik'o Mts region
centraluzbekdata=/Example_data_Central_Uzbekistan.csv # Data from Central Uzbekistan region
junggardata=/Example_data_Junggar_Basin.csv # Data from Junggar Basin region
gobihamidata=/Example_data_Gobi-Hami.csv # Data from Gobi-Hami Basins region
altaidata=/Example_data_Altai.csv # Data from Altai region
siberiadata=/Example_data_Siberia.csv # Data from Siberian Plains region

key_faults=/Example_GPlates_Export_Central_Asia/Key_Faults/25km_halfCMa/USGS_Faults/25_half_USGS_master_shapefile.shp
key_afead_faults=/Example_GPlates_Export_Central_Asia/Key_Faults/25km_halfCMa/AFEAD_Faults/25_half_AFEAD_master_shapefile.shp

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


## Create cooling rate file that replaces all cooling rates recorded as #N/A to 0
#sed 's/#N\/A/0/g' thermodata.xyz  > thermodata_clean.xyz
#sed 's/#N\/A/0/g' tianshandata.xyz  > tianshandata_clean.xyz
#sed 's/#N\/A/0/g' hamountainsdata.xyz  > hamountainsdata_clean.xyz
#sed 's/#N\/A/0/g' centraluzbekdata.xyz  > centraluzbekdata_clean.xyz
#sed 's/#N\/A/0/g' junggardata.xyz  > junggardata_clean.xyz
#sed 's/#N\/A/0/g' gobihamidata.xyz  > gobihamidata_clean.xyz
#sed 's/#N\/A/0/g' altaidata.xyz | sed 's/#DIV\/0!/0/g' > altaidata_clean.xyz
#sed 's/#N\/A/0/g' siberiadata.xyz  > siberiadata_clean.xyz

# Note, columns of new thermodata.xyz file are lat ($1), lon ($2), sample name ($3), time period/age ($4), paleotemperature ($5), cooling rate ($6), region ($7) and sub-region ($8)


### Run loop through defined time steps (in Myr intervals), e.g., 230-0 Ma, producing new post script (ps) files for each time step ###
age=0
while (( $age <= 230 ))
    do

        # Define variables
        infile=/Example_GPlates_Export_Central_Asia/Thermochron_V4/Thermochron_QGIS_Export_reconstructed_${age}.00Ma.gmt
        terranes=/Example_GPlates_Export_Central_Asia/Terranes/reconstructed_${age}.00Ma.gmt
        terranes_static=/Example_GPlates_Export_Central_Asia/Terranes/reconstructed_0.00Ma.gmt
        plate_boundaries=/Example_GPlates_Export_Central_Asia/Topologies/topology_platepolygons_${age}.00Ma.gmt
        subduction_left=/Example_GPlates_Export_Central_Asia/Topologies/topology_subduction_boundaries_sL_${age}.00Ma.gmt
        subduction_right=/Example_GPlates_Export_Central_Asia/Topologies/topology_subduction_boundaries_sR_${age}.00Ma.gmt
        seafloor_age=/Zahirovic_etal_2022_MantleFrame/Zahirovic_etal_2022_MantleFrame_netCDF/Zahirovic_etal_2022_MantleFrame_AgeGrid-${age}.nc
        mesh=/Velocities_coarseMesh/velocity_${age}.00Ma.xy 
        dynamic_topography="../GMCM9c/InterpolatedDynTopo-gmcm9c/Interpolated_gmcm9c-${age}.nc"
        dynamic_topo_gradient=$( ls /GMCM9c/DynTopoChange-gmcm9c/DynTopoChange-gmcm9c-*-${age}.nc)
        eurasia=/Southern_Margin_Polygons_V4/reconstructed_${age}.00Ma.xy
        precipitation=/Paleoprecipitation/raster_data_Valdes-Scotese-precip-m-per-year_${age}.00Ma.nc
        topography=/Example_GPlates_Export_Central_Asia/Topography_broc/raster_data_etopo_6m_${age}.00Ma.nc
        paleotopography_ice=/Example_GPlates_Export_Central_Asia/Paleotopography/i_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_shallow_marine=/Example_GPlates_Export_Central_Asia/Paleotopography/sm_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_land=/Example_GPlates_Export_Central_Asia/Paleotopography/lm_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_mountains=/Example_GPlates_Export_Central_Asia/Paleotopography/m_402_2/reconstructed_${age}.00Ma.gmt
        faults=/Example_GPlates_Export_Central_Asia/Faults/reconstructed_${age}.00Ma.gmt
        faults_static=/Example_GPlates_Export_Central_Asia/Faults/reconstructed_0.00Ma.gmt
        afead_faults=/Example_GPlates_Export_Central_Asia/AFEAD_Faults/AFEAD_v2022/reconstructed_${age}.00Ma.gmt
        afead_faults_static=/Example_GPlates_Export_Central_Asia/AFEAD_Faults/AFEAD_v2022/reconstructed_0.00Ma.gmt


		active_faults=/Example_GPlates_Export_Central_Asia/Key_Faults/USGS_Faults/static_active_faults_uninterpolated_${age}.shp
		active_afead_faults=/Example_GPlates_Export_Central_Asia/Key_Faults/AFEAD_Faults/static_active_afead_faults_uninterpolated_${age}.shp

		# Convert .shp files to .gmt files
		ogr2ogr -f "GMT" active_faults_${age}.gmt $active_faults
		ogr2ogr -f "GMT" active_afead_faults_${age}.gmt $active_afead_faults

        # Note, thermochron_master_${age}.xyz was generated previously with 02_Thermochron_GPlates_V2_blacktext.sh and copied and pasted into the Data_Play_Test directory. In the future, the portion of the script that generated those files would need to copied and pasted here
        thermochron_master=/Example_GPlates_Export_Central_Asia/$directory_name/thermochron_master_${age}.xyz




### 1a. Filter data by some cut-off cooling rate and plot on a map (in present day coordinates) with geological map and faults ###
		
		# Bring in cooling rates for samples in present-day, static coordinates
		awk -v age=$age '$4 == age {print $2, $1, $6}' thermodata.xyz > thermodata_static_${age}.xyz
		awk -v age=$age '$4 == age {print $2, $1, $6}' tianshandata.xyz > tianshandata_static_${age}.xyz
		awk -v age=$age '$4 == age {print $2, $1, $6}' altaidata.xyz > altaidata_static_${age}.xyz

		# Note, columns of new ***data_static_${age}.xyz files are lat ($1), lon ($2), cooling rate ($3)


		# Filter data by some cooling rate to select only fast cooling samples
		awk '$3 >= 0.5' thermodata_static_${age}.xyz > fast_cooling_samples_static_${age}.xyz
		awk '$3 >= 0.5' tianshandata_static_${age}.xyz > fast_cooling_tianshan_samples_static_${age}.xyz	
		awk '$3 >= 0.5' altaidata_static_${age}.xyz > fast_cooling_altai_samples_static_${age}.xyz

		awk '$3 >= 1.0' thermodata_static_${age}.xyz > very_fast_cooling_samples_static_${age}.xyz
		awk '$3 >= 1.0' tianshandata_static_${age}.xyz > very_fast_cooling_tianshan_samples_static_${age}.xyz	
		awk '$3 >= 1.0' altaidata_static_${age}.xyz > very_fast_cooling_altai_samples_static_${age}.xyz

		awk '$3 >= 1.5' thermodata_static_${age}.xyz > extra_fast_cooling_samples_static_${age}.xyz
		awk '$3 >= 1.5' tianshandata_static_${age}.xyz > extra_fast_cooling_tianshan_samples_static_${age}.xyz	
		awk '$3 >= 1.5' altaidata_static_${age}.xyz > extra_fast_cooling_altai_samples_static_${age}.xyz


		# ZOOMED IN MAP OF THERMOCHRONOLOGY COOLING RATE DATA OVER TOPO MAP WITH FAULTS IN PRESENT-DAY COORDINATES 
		# Create a post script file
        psfile=cooling_data_static_zoomed_${age}.ps

        # Define basemap using Albers projection centred on the Tian Shan - Altai Region     -R20/120/0/70    -R$frame_long_min/$frame_long_max/$frame_lat_min/$frame_lat_max
        gmt psbasemap -R55/110/30/60 -JB82/45/15/35/10c -Ba -K -Y20c -V4 > $psfile

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes_static -Gnavajowhite4 -K -O >> $psfile

        # Plot topography 
        gmt grd2cpt @earth_relief -R -J -Crelief -Z -K -O >> $psfile
		gmt grdimage @earth_relief -R -J -K -O >> $psfile

		# Plot faults
        gmt psxy -R -J $faults_static -W0.1p,darkgray -K -O >> $psfile
        gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -K -O >> $psfile  
        gmt psxy -R -J key_faults.gmt -W0.2p,black -K -O >> $psfile
        gmt psxy -R -J key_afead_faults.gmt -W0.2p,black -K -O >> $psfile  
        gmt psxy -R -J active_faults_${age}.gmt -W0.3p,firebrick1 -K -O >> $psfile
        gmt psxy -R -J active_afead_faults_${age}.gmt -W0.3p,sienna1 -K -O >> $psfile  

        ## Plot cooling interpolation
        #gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

        # Plot coloured circles for the all cooling rate of each sample
        gmt psxy -R -J thermodata_static_${age}.xyz -Sc1p -W0.1p,black -Gblack -K -O >> $psfile

        # Plot coloured circles for the fast cooling rate of each sample
        gmt psxy -R -J fast_cooling_samples_static_${age}.xyz -Sc1.5p -W0.1p,black -Gdodgerblue1 -K -O >> $psfile

        # Plot coloured circles for the very fast cooling rate of each sample
        gmt psxy -R -J very_fast_cooling_samples_static_${age}.xyz -Sc2p -W0.15p,black -Gspringgreen -K -O >> $psfile

        # Plot coloured circles for the extra fast cooling rate of each sample
        gmt psxy -R -J extra_fast_cooling_samples_static_${age}.xyz -Sc3p -W0.2p,black -Gtomato -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O -Y+1c -X-1c >> $psfile

        # Make scales for cooling rates and for seafloor age grids
        #gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w7c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -Y-2c -X11c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, TG is png transparent, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures
        gmt psconvert $psfile -TG -A -DFigures



### 1b. Repeat this for Altai and Tian Shan separately ###

		# ZOOMED IN MAP OF THERMOCHRONOLOGY COOLING RATE DATA FOR TIAN SHAN OVER TOPO MAP WITH FAULTS IN PRESENT-DAY COORDINATES 
		# Create a post script file
       psfile=cooling_data_static_tianshan_${age}.ps

       # Define basemap using Albers projection centred on the Tian Shan - Altai Region     -R20/120/0/70    -R$frame_long_min/$frame_long_max/$frame_lat_min/$frame_lat_max
       gmt psbasemap -R62/90/37/47 -JB76/42/15/35/10c -Ba -K -Y20c -V4 > $psfile

       # Plot terranes (coastlines)
       gmt psxy -R -J $terranes_static -Gnavajowhite4 -K -O >> $psfile

       # Plot topography 
       gmt grd2cpt @earth_relief -R -J -Crelief -Z -K -O >> $psfile
		gmt grdimage @earth_relief -R -J -K -O >> $psfile

		# Plot faults
       gmt psxy -R -J $faults_static -W0.1p,darkgray -K -O >> $psfile
       gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -K -O >> $psfile  
       gmt psxy -R -J key_faults.gmt -W0.2p,black -K -O >> $psfile
       gmt psxy -R -J key_afead_faults.gmt -W0.2p,black -K -O >> $psfile  
       gmt psxy -R -J active_faults_${age}.gmt -W0.3p,firebrick1 -K -O >> $psfile
       gmt psxy -R -J active_afead_faults_${age}.gmt -W0.3p,sienna1 -K -O >> $psfile  



       ## Plot cooling interpolation
       #gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

       # Plot coloured circles for the all cooling rate of each sample
       gmt psxy -R -J thermodata_static_${age}.xyz -Sc1p -W0.1p,black -Gblack -K -O >> $psfile

       # Plot coloured circles for the fast cooling rate of each sample
       gmt psxy -R -J fast_cooling_samples_static_${age}.xyz -Sc1.5p -W0.1p,black -Gdodgerblue1 -K -O >> $psfile

       # Plot coloured circles for the very fast cooling rate of each sample
       gmt psxy -R -J very_fast_cooling_samples_static_${age}.xyz -Sc2p -W0.15p,black -Gspringgreen -K -O >> $psfile

       # Plot coloured circles for the extra fast cooling rate of each sample
       gmt psxy -R -J extra_fast_cooling_samples_static_${age}.xyz -Sc3p -W0.2p,black -Gtomato -K -O >> $psfile

       # Add label for age of reconstruction
       echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O -Y+1c -X-1c >> $psfile

       # Make scales for cooling rates and for seafloor age grids
       #gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w7c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -Y-2c -X11c >> $psfile 

       # Convert postscript file to a jpg, pdf, and png
       gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, TG is png transparent, Tf is pdf # -A will clip to bounding box
       gmt psconvert $psfile -Tf -A -DFigures
       gmt psconvert $psfile -TG -A -DFigures





       # ZOOMED IN MAP OF THERMOCHRONOLOGY COOLING RATE DATA FOR ALTAI OVER TOPO MAP WITH FAULTS IN PRESENT-DAY COORDINATES 
		# Create a post script file
       psfile=cooling_data_static_altai_${age}.ps

       # Define basemap using Albers projection centred on the Tian Shan - Altai Region     -R20/120/0/70    -R$frame_long_min/$frame_long_max/$frame_lat_min/$frame_lat_max
       gmt psbasemap -R82/97/45/56 -JB89/50/15/35/10c -Ba -K -Y20c -V4 > $psfile

       # Plot terranes (coastlines)
       gmt psxy -R -J $terranes_static -Gnavajowhite4 -K -O >> $psfile

       # Plot topography 
       gmt grd2cpt @earth_relief -R -J -Crelief -Z -K -O >> $psfile
		gmt grdimage @earth_relief -R -J -K -O >> $psfile

		# Plot faults
       gmt psxy -R -J $faults_static -W0.1p,darkgray -K -O >> $psfile
       gmt psxy -R -J $afead_faults_static -W0.1p,darkgray -K -O >> $psfile  
       gmt psxy -R -J key_faults.gmt -W0.2p,black -K -O >> $psfile
       gmt psxy -R -J key_afead_faults.gmt -W0.2p,black -K -O >> $psfile  
       gmt psxy -R -J active_faults_${age}.gmt -W0.3p,firebrick1 -K -O >> $psfile
       gmt psxy -R -J active_afead_faults_${age}.gmt -W0.3p,sienna1 -K -O >> $psfile  

       ## Plot cooling interpolation
       #gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

       # Plot coloured circles for the all cooling rate of each sample
       gmt psxy -R -J thermodata_static_${age}.xyz -Sc1p -W0.1p,black -Gblack -K -O >> $psfile

       # Plot coloured circles for the fast cooling rate of each sample
       gmt psxy -R -J fast_cooling_samples_static_${age}.xyz -Sc1.5p -W0.1p,black -Gdodgerblue1 -K -O >> $psfile

       # Plot coloured circles for the very fast cooling rate of each sample
       gmt psxy -R -J very_fast_cooling_samples_static_${age}.xyz -Sc2p -W0.15p,black -Gspringgreen -K -O >> $psfile

       # Plot coloured circles for the extra fast cooling rate of each sample
       gmt psxy -R -J extra_fast_cooling_samples_static_${age}.xyz -Sc3p -W0.2p,black -Gtomato -K -O >> $psfile

       # Add label for age of reconstruction
       echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O -Y+1c -X-1c >> $psfile

       # Make scales for cooling rates and for seafloor age grids
       #gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w7c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -Y-2c -X11c >> $psfile 

       # Convert postscript file to a jpg, pdf, and png
       gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, TG is png transparent, Tf is pdf # -A will clip to bounding box
       gmt psconvert $psfile -Tf -A -DFigures
       gmt psconvert $psfile -TG -A -DFigures




### 2. Histogram of cooling rates above a certain cut-off (0.5, 1) ###

		### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO cooling_master.xyz FILE ###

		# Adding a new line of data to the cooling_master.xyz file for this time step in the loop
        echo $age >> cooling_master.xyz

        # Calculating average and std cooling rates for all of Central Asia, Tian Shan and Altai. First need to extract the relevant data for this time step.
        awk -v age=$age '$4 == age {print $6}' thermodata.xyz > thermodata_${age}.xyz
        awk -v age=$age '$4 == age {print $6}' tianshandata.xyz > tianshandata_${age}.xyz
        awk -v age=$age '$4 == age {print $6}' altaidata.xyz > altaidata_${age}.xyz

        # Central Asia calculations
        mean_cooling=$(gmt math -i0 thermodata_${age}.xyz MEAN -S =)

        echo Mean cooling rate in Central Asia at $age Ma is:
        echo $mean_cooling

        std_cooling=$(gmt math -i0 thermodata_${age}.xyz STD -S =)

        echo Cooling rate standard deviation in Central Asia at $age Ma is:
        echo $std_cooling


        # Tian Shan calculations
        mean_cooling_tianshan=$(gmt math -i0 tianshandata_${age}.xyz MEAN -S =)

        echo Mean cooling rate in Tian Shan at $age Ma is:
        echo $mean_cooling_tianshan

        std_cooling_tianshan=$(gmt math -i0 tianshandata_${age}.xyz STD -S =)

        echo Cooling rate standard deviation in Tian Shan at $age Ma is:
        echo $std_cooling_tianshan


        # Altai calculations
        mean_cooling_altai=$(gmt math -i0 altaidata_${age}.xyz MEAN -S =)

        echo Mean cooling rate in the Altai at $age Ma is:
        echo $mean_cooling_altai

        std_cooling_altai=$(gmt math -i0 altaidata_${age}.xyz STD -S =)

        echo Cooling rate standard deviation in the Altai at $age Ma is:
        echo $std_cooling_altai       


        # Add these values to the cooling_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_cooling=$mean_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_cooling=$std_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_cooling_tianshan=$mean_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling_tianshan
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_cooling_tianshan=$std_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling_tianshan
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_cooling_altai=$mean_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling_altai
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_cooling_altai=$std_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling_altai
            }
            print
        }' cooling_master.xyz > tmp.xyz

        mv tmp.xyz cooling_master.xyz

        # NOTE: cooling_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)


		### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO fast_cooling_master.xyz FILE ###

		# Adding a new line of data to the fast_cooling_master.xyz file for this time step in the loop
        echo $age >> fast_cooling_master.xyz

        # Filter cooling data for this time step by those with rates above a 0.5 C/Ma, considered as fast
		awk '$1 >= 0.5' thermodata_${age}.xyz > fast_thermodata_${age}.xyz
		awk '$1 >= 0.5' tianshandata_${age}.xyz > fast_tianshandata_${age}.xyz
		awk '$1 >= 0.5' altaidata_${age}.xyz > fast_altaidata_${age}.xyz

        # Central Asia calculations
        mean_fast_cooling=$(gmt math -i0 fast_thermodata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 0.5 C/Ma in Central Asia at $age Ma is:
        echo $mean_fast_cooling

        std_fast_cooling=$(gmt math -i0 fast_thermodata_${age}.xyz STD -S =)

        echo Cooling rate above 0.5 C/Ma standard deviation in Central Asia at $age Ma is:
        echo $std_fast_cooling


        # Tian Shan calculations
        mean_fast_cooling_tianshan=$(gmt math -i0 fast_tianshandata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 0.5 C/Ma in Tian Shan at $age Ma is:
        echo $mean_fast_cooling_tianshan

        std_fast_cooling_tianshan=$(gmt math -i0 fast_tianshandata_${age}.xyz STD -S =)

        echo Cooling rate above 0.5 C/Ma standard deviation in Tian Shan at $age Ma is:
        echo $std_fast_cooling_tianshan


        # Altai calculations
        mean_fast_cooling_altai=$(gmt math -i0 fast_altaidata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 0.5 C/Ma in the Altai at $age Ma is:
        echo $mean_fast_cooling_altai

        std_fast_cooling_altai=$(gmt math -i0 fast_altaidata_${age}.xyz STD -S =)

        echo Cooling rate above 0.5 C/Ma standard deviation in the Altai at $age Ma is:
        echo $std_fast_cooling_altai       


        # Add these values to the fast_cooling_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_fast_cooling=$mean_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_fast_cooling
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_fast_cooling=$std_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_fast_cooling
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_fast_cooling_tianshan=$mean_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_fast_cooling_tianshan
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_fast_cooling_tianshan=$std_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_fast_cooling_tianshan
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_fast_cooling_altai=$mean_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_fast_cooling_altai
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_fast_cooling_altai=$std_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_fast_cooling_altai
            }
            print
        }' fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz fast_cooling_master.xyz

        # NOTE: fast_cooling_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)


		### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO very_fast_cooling_master.xyz FILE ###

		# Adding a new line of data to the very_fast_cooling_master.xyz file for this time step in the loop
        echo $age >> very_fast_cooling_master.xyz

        # Filter cooling data for this time step by those with rates above a 1.0 C/Ma, considered as fast
		awk '$1 >= 1.0' thermodata_${age}.xyz > very_fast_thermodata_${age}.xyz
		awk '$1 >= 1.0' tianshandata_${age}.xyz > very_fast_tianshandata_${age}.xyz
		awk '$1 >= 1.0' altaidata_${age}.xyz > very_fast_altaidata_${age}.xyz

        # Central Asia calculations
        mean_very_fast_cooling=$(gmt math -i0 very_fast_thermodata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.0 C/Ma in Central Asia at $age Ma is:
        echo $mean_very_fast_cooling

        std_very_fast_cooling=$(gmt math -i0 very_fast_thermodata_${age}.xyz STD -S =)

        echo Cooling rate above 1.0 C/Ma standard deviation in Central Asia at $age Ma is:
        echo $std_very_fast_cooling


        # Tian Shan calculations
        mean_very_fast_cooling_tianshan=$(gmt math -i0 very_fast_tianshandata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.0 C/Ma in Tian Shan at $age Ma is:
        echo $mean_very_fast_cooling_tianshan

        std_very_fast_cooling_tianshan=$(gmt math -i0 very_fast_tianshandata_${age}.xyz STD -S =)

        echo Cooling rate above 1.0 C/Ma standard deviation in Tian Shan at $age Ma is:
        echo $std_very_fast_cooling_tianshan


        # Altai calculations
        mean_very_fast_cooling_altai=$(gmt math -i0 very_fast_altaidata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.0 C/Ma in the Altai at $age Ma is:
        echo $mean_very_fast_cooling_altai

        std_very_fast_cooling_altai=$(gmt math -i0 very_fast_altaidata_${age}.xyz STD -S =)

        echo Cooling rate above 1.0 C/Ma standard deviation in the Altai at $age Ma is:
        echo $std_very_fast_cooling_altai       


        # Add these values to the very_fast_cooling_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_very_fast_cooling=$mean_very_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_very_fast_cooling
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_very_fast_cooling=$std_very_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_very_fast_cooling
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_very_fast_cooling_tianshan=$mean_very_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_very_fast_cooling_tianshan
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_very_fast_cooling_tianshan=$std_very_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_very_fast_cooling_tianshan
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_very_fast_cooling_altai=$mean_very_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_very_fast_cooling_altai
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_very_fast_cooling_altai=$std_very_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_very_fast_cooling_altai
            }
            print
        }' very_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz very_fast_cooling_master.xyz

        # NOTE: very_fast_cooling_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)


		### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO extra_fast_cooling_master.xyz FILE ###

		# Adding a new line of data to the extra_fast_cooling_master.xyz file for this time step in the loop
        echo $age >> extra_fast_cooling_master.xyz

        # Filter cooling data for this time step by those with rates above a 1.5 C/Ma, considered as fast
		awk '$1 >= 1.5' thermodata_${age}.xyz > extra_fast_thermodata_${age}.xyz
		awk '$1 >= 1.5' tianshandata_${age}.xyz > extra_fast_tianshandata_${age}.xyz
		awk '$1 >= 1.5' altaidata_${age}.xyz > extra_fast_altaidata_${age}.xyz

        # Central Asia calculations
        mean_extra_fast_cooling=$(gmt math -i0 extra_fast_thermodata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.5 C/Ma in Central Asia at $age Ma is:
        echo $mean_extra_fast_cooling

        std_extra_fast_cooling=$(gmt math -i0 extra_fast_thermodata_${age}.xyz STD -S =)

        echo Cooling rate above 1.5 C/Ma standard deviation in Central Asia at $age Ma is:
        echo $std_extra_fast_cooling


        # Tian Shan calculations
        mean_extra_fast_cooling_tianshan=$(gmt math -i0 extra_fast_tianshandata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.5 C/Ma in Tian Shan at $age Ma is:
        echo $mean_extra_fast_cooling_tianshan

        std_extra_fast_cooling_tianshan=$(gmt math -i0 extra_fast_tianshandata_${age}.xyz STD -S =)

        echo Cooling rate above 1.5 C/Ma standard deviation in Tian Shan at $age Ma is:
        echo $std_extra_fast_cooling_tianshan


        # Altai calculations
        mean_extra_fast_cooling_altai=$(gmt math -i0 extra_fast_altaidata_${age}.xyz MEAN -S =)

        echo Mean cooling rate above 1.5 C/Ma in the Altai at $age Ma is:
        echo $mean_extra_fast_cooling_altai

        std_extra_fast_cooling_altai=$(gmt math -i0 extra_fast_altaidata_${age}.xyz STD -S =)

        echo Cooling rate above 1.5 C/Ma standard deviation in the Altai at $age Ma is:
        echo $std_extra_fast_cooling_altai       


        # Add these values to the extra_fast_cooling_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_extra_fast_cooling=$mean_extra_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_extra_fast_cooling
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_extra_fast_cooling=$std_extra_fast_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_extra_fast_cooling
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_extra_fast_cooling_tianshan=$mean_extra_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_extra_fast_cooling_tianshan
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_extra_fast_cooling_tianshan=$std_extra_fast_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_extra_fast_cooling_tianshan
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_extra_fast_cooling_altai=$mean_extra_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_extra_fast_cooling_altai
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_extra_fast_cooling_altai=$std_extra_fast_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_extra_fast_cooling_altai
            }
            print
        }' extra_fast_cooling_master.xyz > tmp.xyz

        mv tmp.xyz extra_fast_cooling_master.xyz

        # NOTE: extra_fast_cooling_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)



		### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO slow_cooling_master.xyz FILE ###

		# Adding a new line of data to the slow_cooling_master.xyz file for this time step in the loop
        echo $age >> slow_cooling_master.xyz

        # Filter cooling data for this time step by those with rates above a 1.5 C/Ma, considered as fast
		awk '$1 < 0.5' thermodata_${age}.xyz > slow_thermodata_${age}.xyz
		awk '$1 < 0.5' tianshandata_${age}.xyz > slow_tianshandata_${age}.xyz
		awk '$1 < 0.5' altaidata_${age}.xyz > slow_altaidata_${age}.xyz

        # Central Asia calculations
        mean_slow_cooling=$(gmt math -i0 slow_thermodata_${age}.xyz MEAN -S =)

        echo Mean cooling rate below 0.5 C/Ma in Central Asia at $age Ma is:
        echo $mean_slow_cooling

        std_slow_cooling=$(gmt math -i0 slow_thermodata_${age}.xyz STD -S =)

        echo Cooling rate below 0.5 C/Ma standard deviation in Central Asia at $age Ma is:
        echo $std_slow_cooling


        # Tian Shan calculations
        mean_slow_cooling_tianshan=$(gmt math -i0 slow_tianshandata_${age}.xyz MEAN -S =)

        echo Mean cooling rate below 0.5 C/Ma in Tian Shan at $age Ma is:
        echo $mean_slow_cooling_tianshan

        std_slow_cooling_tianshan=$(gmt math -i0 slow_tianshandata_${age}.xyz STD -S =)

        echo Cooling rate below 0.5 C/Ma standard deviation in Tian Shan at $age Ma is:
        echo $std_slow_cooling_tianshan


        # Altai calculations
        mean_slow_cooling_altai=$(gmt math -i0 slow_altaidata_${age}.xyz MEAN -S =)

        echo Mean cooling rate below 0.5 C/Ma in the Altai at $age Ma is:
        echo $mean_slow_cooling_altai

        std_slow_cooling_altai=$(gmt math -i0 slow_altaidata_${age}.xyz STD -S =)

        echo Cooling rate below 0.5 C/Ma standard deviation in the Altai at $age Ma is:
        echo $std_slow_cooling_altai       


        # Add these values to the extra_fast_cooling_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_slow_cooling=$mean_slow_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_slow_cooling
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_slow_cooling=$std_slow_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_slow_cooling
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_slow_cooling_tianshan=$mean_slow_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_slow_cooling_tianshan
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_slow_cooling_tianshan=$std_slow_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_slow_cooling_tianshan
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_slow_cooling_altai=$mean_slow_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_slow_cooling_altai
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_slow_cooling_altai=$std_slow_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_slow_cooling_altai
            }
            print
        }' slow_cooling_master.xyz > tmp.xyz

        mv tmp.xyz slow_cooling_master.xyz

        # NOTE: slow_cooling_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)



    age=$(($age + 1))
done





### Make a 1x4 series of plots showing the plotting trend in cooling rates with different minimum cooling rate cutoffs

# Extracting cooling histories for each region from cooling_master.xyz files and making new .xyz files

# All Cooling Rates
# Overall Central Asia cooling
awk '{print $1, $2, $3}' cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > altai.xyz

# Slow Cooling Rates (below 0.5 C/Ma)
# Overall Central Asia cooling
awk '{print $1, $2, $3}' slow_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > slow_central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' slow_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > slow_tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' slow_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > slow_altai.xyz

# Fast Cooling Rates (above 0.5 C/Ma)
# Overall Central Asia cooling
awk '{print $1, $2, $3}' fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > fast_central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > fast_tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > fast_altai.xyz

# Very Fast Cooling Rates (above 1.0 C/Ma)
# Overall Central Asia cooling
awk '{print $1, $2, $3}' very_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > very_fast_central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' very_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > very_fast_tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' very_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > very_fast_altai.xyz

# Extra Fast Cooling Rates (above 1.5 C/Ma)
# Overall Central Asia cooling
awk '{print $1, $2, $3}' extra_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > extra_fast_central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' extra_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > extra_fast_tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' extra_fast_cooling_master.xyz | sed 's/  / NaN /g; s/^ NaN /NaN /g; s/ NaN $/ NaN/g' > extra_fast_altai.xyz




# Create a post script file
psfile=cooling_rates.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d central_asia.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -K > $psfile
gmt psxy central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d slow_central_asia.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y15c -K -O >> $psfile
gmt psxy slow_central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d slow_tian_shan.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy slow_tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d slow_altai.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy slow_altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,black+cTC+tFast\ Cooling\ Samples\ '<'0.5\ C/Ma -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -K -O >> $psfile


# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d fast_central_asia.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y15c -K -O >> $psfile
gmt psxy fast_central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d fast_tian_shan.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy fast_tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d fast_altai.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy fast_altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,black+cTC+tFast\ Cooling\ Samples\ '>'0.5\ C/Ma -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -K -O >> $psfile


# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d very_fast_central_asia.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y15c -K -O >> $psfile
gmt psxy very_fast_central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d very_fast_tian_shan.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy very_fast_tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d very_fast_altai.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy very_fast_altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,black+cTC+tVery\ Fast\ Cooling\ Samples\ '>'1.0\ C/Ma -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -K -O >> $psfile


# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d extra_fast_central_asia.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y15c -K -O >> $psfile
gmt psxy extra_fast_central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d extra_fast_tian_shan.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy extra_fast_tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d extra_fast_altai.xyz -Fxm -NP0,P2,f3 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy extra_fast_altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,black+cTC+tExtra\ Fast\ Cooling\ Samples\ '>'1.5\ C/Ma -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures




# Create a post script file
psfile=cooling_rates_tian_shan_very_fast_iso.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d very_fast_tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,cadetblue2 -K > $psfile
gmt psxy very_fast_tian_shan.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Gcadetblue -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-8p -O >> $psfile  # -Y-16p

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures




# Create a post script file
psfile=cooling_rates_altai_very_fast_iso.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d very_fast_altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,darkseagreen -K > $psfile
gmt psxy very_fast_altai.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Gseagreen -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures

# Create a post script file
psfile=cooling_rates_tian_shan_fast_iso.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d fast_tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,cadetblue2 -K > $psfile
gmt psxy fast_tian_shan.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Gcadetblue -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-8p -O >> $psfile  # -Y-16p

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures




# Create a post script file
psfile=cooling_rates_altai_fast_iso.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d fast_altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,darkseagreen -K > $psfile
gmt psxy fast_altai.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Gseagreen -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures





# Create a post script file
psfile=cooling_rates_tian_shan_very_fast_iso_w_uncert.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d very_fast_tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,cadetblue2 -K > $psfile
gmt psxy very_fast_tian_shan.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Ey+w0.5p -Gcadetblue -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-8p -O >> $psfile  # -Y-16p

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures




# Create a post script file
psfile=cooling_rates_altai_very_fast_iso_w_uncert.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d very_fast_altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,darkseagreen -K > $psfile
gmt psxy very_fast_altai.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Ey+w0.5p -Gseagreen -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures

# Create a post script file
psfile=cooling_rates_tian_shan_fast_iso_w_uncert.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d fast_tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,cadetblue2 -K > $psfile
gmt psxy fast_tian_shan.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Ey+w0.5p -Gcadetblue -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-8p -O >> $psfile  # -Y-16p

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures




# Create a post script file
psfile=cooling_rates_altai_fast_iso_w_uncert.ps

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d fast_altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -W1p,darkseagreen -K > $psfile
gmt psxy fast_altai.xyz -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS -Sc3p -Ey+w0.5p -Gseagreen -K > $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DFigures
gmt psconvert $psfile -TG -A -DFigures

exit
