#!/bin/bash

# Do only once: chmod +rwx 03_Thermochron_GPlates.sh  # Gives read, write, execute permission for script 

### This comprises the core of the ThermoPlates workflow, combining thermal (or exhumation) history datasets with the plate tectonic, mantle dynamic, paleoclimate, and paleotopography simulations and fault databases. 
### Using an input fault database, the script also identifies faults in proximity to fast cooling/denuding samples and performs structural analysis of their geometries. 
### It also performs calculations to produce the kinematics_master.xyz and thermochron_master_${age}.xyz files that are used in the subsequent 04_Kinematics.sh and 05_Loop_Plot.sh scripts. 
### The 03_Thermochron_GPlates.sh script runs a loop through the modelling time range and creates the following figures for each time step:

    # Regional map of cooling rates through time
    # Global map of an evolving plate tectonic reconstruction with thermochronology-derived cooling rates through time and seafloor ages
    # Global map of an evolving plate tectonic reconstruction with thermochronology-derived cooling rates through time atop predicted dynamic topography
    # Global and regional maps of an evolving plate tectonic reconstruction with convergence rates along subduction zones and thermochronology-derived cooling rates through time
    # Global and regional maps of an evolving plate tectonic reconstruction with trench migration rates and thermochronology-derived cooling rates through time
    # Regional maps of samples cooling above a certain, user-defined cut-off rate and faults within some user-defined proximity range of the fast cooling samples
    # Rose diagrams of plate velocity and azimuth near thermochronology samples, arc azimuths, suubduction rate azimuths, arc migration azimuths, faults in proximity to quickly cooling/exhuming samples
    # Global and regional maps of an evolving plate tectonic reconstruction with paleoprecipitation rates and thermochronology-derived cooling rates through time
    # Global and regional maps of an evolving plate tectonic reconstruction with a paleotopography model and thermochronology-derived cooling rates through time
    # Three different scatter plots of cooling rate versus dynamic topography, change in dynamic topography, and paleoprecipitation rate for each time step



### Prompt user to provide new directory name base ###

read -p "What would you like to call your new output directory for this script? " directory

directory_name="Thermochron_GPlates_$directory"

mkdir -v -m777 $directory_name

cd $directory_name || exit 1

mkdir -v -m777 Figures

mkdir -v -m777 Shapefiles

mkdir -v -m777 Shapefiles/USGS_Faults

mkdir -v -m777 Shapefiles/AFEAD_Faults



gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=10p MAP_FRAME_PEN=thin,black FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_DEFAULT_PEN=0.25p,black MAP_GRID_PEN=0.25p,black MAP_TICK_PEN=0.25p,black


# Define map region and projection
region=d # -180/180/-90/90
projection=W30/15c # 30 deg E, 15 wide plot

# Load and make colour palettes to be used for different maps
age_grid_cpt=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/agegrid_maria_2021.cpt
topo_cpt=/Volumes/T7/Work/Central_Asia_Work/Thermochron_GPlates/ETOPO.cpt

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



# Create a kinematics_master.xyz file which will have data added to it with each time step in the subsequent loop
echo -n > kinematics_master.xyz



# Define thermodata variable based on input cooling history data
thermodata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4.csv 
tianshandata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Tian_Shan.csv # Data from Tian Shan region
hamountainsdata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Ha_Mts.csv # Data from Ha-erh-lik'o Mts region
centraluzbekdata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Central_Uzbekistan.csv # Data from Central Uzbekistan region
junggardata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Junggar_Basin.csv # Data from Junggar Basin region
gobihamidata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Gobi-Hami.csv # Data from Gobi-Hami Basins region
altaidata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Altai.csv # Data from Altai region
siberiadata=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/data_V4_Siberia.csv # Data from Siberian Plains region

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

# Define kinematics variable
kinematics_input=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/Kinematics/SubductionVolumesAreaTable_clean_0_230Ma_4.csv

static_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Faults/reconstructed_0.00Ma.gmt
static_afead_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/AFEAD_Faults/AFEAD_v2022/reconstructed_0.00Ma.gmt




### Reduce the $static_faults and $static_afead_faults table sizes to include only faults that are within 1,000 km (value after +d) of samples ###

# First, make a xyz file of the locations of all thermochron samples in their present-day coordinates

present_day_thermochron=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Thermochron_V4/Thermochron_QGIS_Export_reconstructed_0.00Ma.gmt

awk -F "|" '{
    if ($1 =="# @D0")
        print "> -Z"$11;
else
    print $0;
}' $present_day_thermochron | awk '($1 !="#") {print $0}' > present_day_thermochron.dat

# Create .xyz file with lat, long, cooling rate for each sample point for a given time step
awk -FZ '($1 !~ ">") {print $0, a}{a=$2}' present_day_thermochron.dat > present_day_thermochron.xyz  


# Now shrink size of $static_faults file to own faults within a given range (value after +d) of the thermochron data (static_thermochron.dat)
gmt select $static_faults -Cpresent_day_thermochron.xyz+d1000k -fg > static_faults_central_asia.gmt        

# Calculate lengths of faults
gmt mapproject static_faults_central_asia.gmt -G+a+uk > static_fault_data.gmt

# Select faults that are longer than a certain amount (value after -D) and adds a header to each series of fault nodes with the third column ($3) being a fault ID number and the fourth column ($4) being "-I" followed by the fault ID
gmt split -D10k static_fault_data.gmt -V3  -fg > static_long_faults.gmt

# Use awk to add an underscore "_" behind each fault ID in the list
cat static_long_faults.gmt | awk '{
    if ($1 ==">")
        print $1, $2, $3, $4 "_";
else
    print $0;
}' > static_long_faults_app.gmt      

# Interpolate nodes every 5 km for each fault
gmt sample1d static_long_faults_app.gmt -Af -N2 -I5k -V -fg > static_long_faults_resampled.gmt  

# Calculate azimuths of each interpolated fault - new file structure: long, lat, length, alternative length 
gmt mapproject static_long_faults_resampled.gmt -Ao > static_long_faults_resampled_data.gmt



# Finally, do the same for the AFEAD dataset
# Shrink size of $static_afead_faults file to own faults within a given range (value after +d) of the thermochron data (static_thermochron.dat)
gmt select $static_afead_faults -Cpresent_day_thermochron.xyz+d1000k -fg > static_afead_faults_central_asia.gmt        

# Calculate lengths of faults
gmt mapproject static_afead_faults_central_asia.gmt -G+a+uk > static_afead_fault_data.gmt

# Select faults that are longer than a certain amount (value after -D) and adds a header to each series of fault nodes with the third column ($3) being a fault ID number and the fourth column ($4) being "-I" followed by the fault ID
gmt split -D10k static_afead_fault_data.gmt -V3  -fg > static_long_afead_faults.gmt

# Use awk to add an underscore "_" behind each fault ID in the list
cat static_long_afead_faults.gmt | awk '{
    if ($1 ==">")
        print $1, $2, $3, $4 "_";
else
    print $0;
}' > static_long_afead_faults_app.gmt      

# Interpolate nodes every 5 km for each fault
gmt sample1d static_long_afead_faults_app.gmt -Af -N2 -I5k -V -fg > static_long_afead_faults_resampled.gmt  

# Calculate azimuths of each interpolated fault - new file structure: long, lat, length, alternative length 
gmt mapproject static_long_afead_faults_resampled.gmt -Ao > static_long_afead_faults_resampled_data.gmt





### Run loop through defined time steps (in Myr intervals), e.g., 230-0 Ma, producing new post script (ps) files for each time step ###
age=0
while (( $age <= 230 ))
    do

        # Define variables
        infile=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Thermochron_V4/Thermochron_QGIS_Export_reconstructed_${age}.00Ma.gmt
        terranes=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Terranes/reconstructed_${age}.00Ma.gmt
        plate_boundaries=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Topologies/topology_platepolygons_${age}.00Ma.gmt
        subduction_left=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Topologies/topology_subduction_boundaries_sL_${age}.00Ma.gmt
        subduction_right=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Topologies/topology_subduction_boundaries_sR_${age}.00Ma.gmt
        seafloor_age=/Volumes/T7/Central_Asia_Work/Zahirovic_etal_2022_Asia_Exhumation/Zahirovic_etal_2022_MantleFrame/Zahirovic_etal_2022_MantleFrame_netCDF/Zahirovic_etal_2022_MantleFrame_AgeGrid-${age}.nc
        mesh=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/Velocities_coarseMesh/velocity_${age}.00Ma.xy 
        dynamic_topography="../GMCM9c/InterpolatedDynTopo-gmcm9c/Interpolated_gmcm9c-${age}.nc"
        dynamic_topo_gradient=$( ls /Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GMCM9c/DynTopoChange-gmcm9c/DynTopoChange-gmcm9c-*-${age}.nc)
        eurasia=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/Southern_Margin_Polygons_V4/reconstructed_${age}.00Ma.xy
        precipitation=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/Paleoprecipitation/raster_data_Valdes-Scotese-precip-m-per-year_${age}.00Ma.nc
        topography=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Topography_broc/raster_data_etopo_6m_${age}.00Ma.nc
        paleotopography_ice=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Paleotopography/i_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_shallow_marine=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Paleotopography/sm_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_land=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Paleotopography/lm_402_2/reconstructed_${age}.00Ma.gmt
        paleotopography_mountains=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Paleotopography/m_402_2/reconstructed_${age}.00Ma.gmt
        faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/Faults/reconstructed_${age}.00Ma.gmt
        afead_faults=/Volumes/T7/Central_Asia_Work/Thermochron_GPlates/GPlates_Export/AFEAD_Faults/AFEAD_v2022/reconstructed_${age}.00Ma.gmt



        # Two step process to remove time-temperature history cooling rates from reconstructed thermochronology data
        # 1) Replacing part of the header so that you get -Zvalue on which to colour
        # 2) Removing the OGR-GMT lines starting with # symbol (header)

        awk -F "|" '{
            if ($1 =="# @D0")
             print "> -Z"$11;
        else
            print $0;
        }' $infile | awk '($1 !="#") {print $0}' > thermochron.dat



        # Now, make a new gmt file 

        ## DEBUG
        # awk -FZ '($1 != ">") {print $0, a}{a=$2}' thermochron.dat

        # Create .xyz file with lat, long, cooling rate for each sample point for a given time step
        awk -FZ '($1 !~ ">") {print $0, a}{a=$2}' thermochron.dat > thermochron_${age}.xyz    

        # Create temporary file that replaces all cooling rates recorded as #N/A to 0
        sed 's/#N\/A/0/g' thermochron_${age}.xyz > thermochron_clean_${age}.xyz
        

        # Creating a Master .xyz file with lat, long, cooling rate for each sample point for a given time step, with added values for dynamic topography, change in dynamic topography and paleoprecipitation rate, respectively, for each sample location by adding the appropriate value to the thermochron.xyz file for a given time step
        gmt grdtrack thermochron_clean_${age}.xyz -G$dynamic_topography -G$dynamic_topo_gradient -G$precipitation > thermochron_master_${age}.xyz


        # NOTE: thermochron_master_${age}.xyz now has structure of long ($1), lat ($2), cooling rate ($3), dynamic topography ($4), change in dynamic topography ($5), paleoprecipitation rate ($6)




        # Repeat similar process to make a xyz file recording present-day lat and longs and cooling rate for the current time step to be used later
        awk -F "|" '{
            if ($1 =="# @D0")
             print $6, $5, $11;
        }' $infile > static_thermochron_${age}.xyz




        # Repeat two step process, this time to remove paleotemperatures from reconstructed thermochronology data
        # 1) Replacing part of the header so that you get -Zvalue on which to colour
        # 2) Removing the OGR-GMT lines starting with # symbol (header)

        awk -F "|" '{
            if ($1 =="# @D0")
             print "> -Z"$10;
        else
            print $0;
        }' $infile | awk '($1 !="#") {print $0}' > paleotemp.dat

        ## DEBUG
        # awk -FZ '($1 != ">") {print $0, a}{a=$2}' paleotemp.dat

        # Create .xyz file with lat, long, cooling rate for each sample point for a given time step
        awk -FZ '($1 !~ ">") {print $0, a}{a=$2}' paleotemp.dat > paleotemp_${age}.xyz





        ### ADDING AGE AND REGIONAL AVG COOLING RATE DATA TO kinematics_master.xys FILE ###

        # Adding a new line of data to the kinematics_master.xyz file for this time step in the loop
        echo $age >> kinematics_master.xyz

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


        # Add these values to the kinematics_master.xyz file for this time step by using awk to process the input file and modify it in place
        # Add mean Central Asia cooling
        awk -v age=$age -v mean_cooling=$mean_cooling '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # Add std Central Asia cooling
        awk -v age=$age -v std_cooling=$std_cooling '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # Add mean Tian Shan cooling
        awk -v age=$age -v mean_cooling_tianshan=$mean_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling_tianshan
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # Add std Tian Shan cooling
        awk -v age=$age -v std_cooling_tianshan=$std_cooling_tianshan '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling_tianshan
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # Add mean Altai cooling
        awk -v age=$age -v mean_cooling_altai=$mean_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS mean_cooling_altai
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # Add std Altai cooling
        awk -v age=$age -v std_cooling_altai=$std_cooling_altai '{
            if ($1 == age) {
                $0 = $0 OFS std_cooling_altai
            }
            print
        }' kinematics_master.xyz > tmp.xyz

        mv tmp.xyz kinematics_master.xyz

        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)




        ### Define mask lat and long ranges based on position of thermochronology points for this time step
        # long_min=$(gmt math -i0 thermochron_${age}.xyz MIN -S =)

        long_min=$(awk 'NR == 1 || $1 < min { min = $1 } END { print min }' thermochron_${age}.xyz)
        echo Minimum longitude for thermochronology data at $age Ma is:
        echo $long_min    

        mask_long_min=$(echo "$long_min - 1" | bc)
        echo Minimum longitude for mask at $age Ma is:
        echo $mask_long_min    


        #long_max=$(gmt math -i0 thermochron_${age}.xyz MAX -S =)
        long_max=$(awk 'NR == 1 || $1 > max { max = $1 } END { print max }' thermochron_${age}.xyz)
        echo Maximum longitude for thermochronology data at $age Ma is:
        echo $long_max   

        mask_long_max=$(echo "$long_max + 1" | bc)
        echo Maximum longitude for mask at $age Ma is:
        echo $mask_long_max  


        #lat_min=$(gmt math -i1 thermochron_${age}.xyz MIN -S =)
        lat_min=$(awk 'NR == 1 || $2 < min { min = $2 } END { print min }' thermochron_${age}.xyz)
        echo Minimum latitude for thermochronology data at $age Ma is:
        echo $lat_min  

        mask_lat_min=$(echo "$lat_min - 1" | bc)
        echo Minimum latitude for mask at $age Ma is:
        echo $mask_lat_min 


        #lat_max=$(gmt math -i1 thermochron_${age}.xyz MAX -S =)
        lat_max=$(awk 'NR == 1 || $2 > max { max = $2 } END { print max }' thermochron_${age}.xyz)
        echo Maximum latitude for thermochronology data at $age Ma is:
        echo $lat_max   

        mask_lat_max=$(echo "$lat_max + 1" | bc)
        echo Maximum latitude for mask at $age Ma is:
        echo $mask_lat_max




        ### Define zoomed-in map frame based on distribution of samples for each time step
        frame_long_min=$(echo "$long_min - 15" | bc) 

        frame_long_max=$(echo "$long_max + 15" | bc)

        frame_lat_min=$(echo "$lat_min - 15" | bc)

        frame_lat_max=$(echo "$lat_max + 15" | bc)



        ### Make cooling rate interpolation for time step 
        gmt surface thermochron_${age}.xyz -R20/120/0/70 -I0.1k/0.1k -Ll0 -Gcooling_interpolation_${age}.nc -T0.5 -Vl # -M500k 

        # Use grdcut to mask cooling_interpolation_${age}.nc to the defined region
        gmt grdcut cooling_interpolation_${age}.nc -R$mask_long_min/$mask_long_max/$mask_lat_min/$mask_lat_max -Gcooling_interpolation_masked_${age}.nc







        ### ZOOMED IN MAP OF THERMOCHRONOLOGY COOLING RATE DATA OVER TOPO MAP ###

        # Create a post script file
        psfile=cooling_data_zoomed_${age}.ps

        # Define basemap using Albers projection centred on the Tian Shan - Altai Region     -R20/120/0/70    -R$frame_long_min/$frame_long_max/$frame_lat_min/$frame_lat_max
        gmt psbasemap -R20/120/0/70 -JB70/25/15/35/10c -Ba -K -Y20c -V4 > $psfile

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile

        # Plot topography 
        gmt grdimage -R -J $topography -Ctopo_dem2_land.cpt -K -O >> $psfile

        # Plot cooling interpolation
        gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc2p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O -X-1c >> $psfile

        # Make scales for cooling rates and for seafloor age grids
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w7c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -Y-1c -X10c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, TG is png transparent, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures
        gmt psconvert $psfile -TG -A -DFigures





        ### GLOBAL MAP OF THERMOCHRONOLOGY COOLING RATE, SEAFLOOR AGE AND PLATE VELOCITIES ###

        # Create a post script file
        psfile=cooling_seafloorage_global_${age}.ps
        
        ## Make a new map in a spherical projection    -Gdarkslateblue
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -SDarkTurquoise -K -Y20c -V4 > $psfile 

        # !!!!! Need to somehow crop out the ocean from the topography layer, either by using a mask or by adjusting the .cpt file so that all pixels with a z value below 0 are NaN
        # Plot topography 
        #gmt grdimage -R -J $topography -Ctopo_dem2_land.cpt -K -O >> $psfile

        # Plot seafloor age grid
        gmt grdimage -R -J $seafloor_age -C$age_grid_cpt -K -O >> $psfile
        
        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W1.0p $plate_boundaries -K -O -N -V >> $psfile

        # Plot subduction zones
        gmt psxy -R -J -W1.5p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W1.5p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot cooling interpolation
        gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Plot plate velocities
        awk '{print $1, $2, $3, $4/10}' $mesh | gmt psxy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile

        # Make scales for cooling rates and for seafloor age grids
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X9c >> $psfile 
        gmt psscale -C$age_grid_cpt -Dx2c/1c+w8c/0.5c+ef -Ba50f10:"Seafloor Age [Ma]": -O -X3c >> $psfile 


        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures
        gmt psconvert $psfile -TG -A -DFigures





        ### GLOBAL MAP OF THERMOCHRONOLOGY COOLING RATE AND DYNAMIC TOPOGRAPHY ###

        # Create a post script file
        psfile=cooling_dynamictopo_global_${age}.ps   

        ## Make a new map. Note for GMT 5.4, the command -K is required for the base layer in the psfile. The final, uppermost layer in the psfile stack requires the command -O, while all intermediate layers requiring commands -K and -O.
        #gmt psbasemap -R$region -J$projection -Ba20We -K -Y20c -V4 > $psfile

        ## Make a new map in a spherical projection    -Gdarkslateblue
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -SDarkTurquoise -K -Y20c -V4 > $psfile 
        
        # Plot dynamic topography 
        gmt grdimage -R -J $dynamic_topography -Cdynamic_topo.cpt -K -O >> $psfile

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -W0.3p,black -K -O >> $psfile

        # Plot faults
        #gmt psxy -R -J $faults -W0.3p,black -K -O >> $psfile        

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v3.cpt -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile
        
        # Make scale for cooling rates and dyanmic topography
        gmt psscale -Cthermochron_v3.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X9c >> $psfile 
        gmt psscale -Cdynamic_topo.cpt -Dx2c/1c+w8c/0.5c+efb -Ba250f50:"Dynamic Topography [m]": -O -X3c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 






        ### KINEMATICS ###

        ### Global Map of Thermochronology Cooling Rates and Orthogonal Convergence Rate at Subduction Zones ###

        # Structure of $kinematics_input
        # Relevant columns: lon, lat, conv_rate, conv_obliq, migr_rate, migr_obliq, arc_length, arc_azimuth, DistanceToContinent, ortho_migr_rate, ortho_conv_rate, arc_length_m, migr_azimuth, conv_azimuth, time
        # Relevant columns: 3  ,   4,    5     ,     6     ,     7    ,     8     ,     9     ,     10     ,         16         ,        17      ,      18        ,      19     ,      28     ,      30     ,  13
   
        awk -F, -v age=$age '($13 == age) {print $3, $4, $18}' $kinematics_input > kinematics_${age}.xyz

        # Make kinematics .xyz file with all of the relevant kinematics fields for the data locations within the Eurasia polygon
        awk -F, -v age=$age '($13 == age) {print $3, $4, $5, $6, $7, $8 + 90, $9, $10, $16, $17, $18, $19, $10 + $8, $10 + $6}' $kinematics_input | gmt select -F$eurasia > full_eurasia_kinematics_${age}.xyz

        # NOTE: Structure of full_eurasia_kinematics_${age}.xyz file is: 
        # New columns: lon, lat, conv_rate, conv_obliq, migr_rate, migr_obliq, arc_length, arc_azimuth, DistanceToContinent, ortho_migr_rate, ortho_conv_rate, arc_length_m, migr_azimuth, conv_azimuth
        # New columns: 1  ,   2,    3     ,     4     ,     5    ,     6     ,     7     ,     8      ,         9          ,        10      ,      11        ,      12     ,      13     ,      14     




        # Calculate mode and standard deviation convergence rate for time step
        mode_conv_rate=$(gmt math -i2 full_eurasia_kinematics_${age}.xyz MODE -S =)

        echo Mode convergence rate at $age Ma is:
        echo $mode_conv_rate

        std_conv_rate=$(gmt math -i2 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Convergence rate Std at $age Ma is:
        echo $std_conv_rate

        # Add $mode_conv_rate to our kinematics_master.xyz file
        awk -v age=$age -v mode_conv_rate=$mode_conv_rate '{
            if ($1 == age) {
                $0 = $0 OFS mode_conv_rate
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_conv_rate to our kinematics_master.xyz file
        awk -v age=$age -v std_conv_rate=$std_conv_rate '{
            if ($1 == age) {
                $0 = $0 OFS std_conv_rate
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate mode and standard deviation of convergence obliquity for time step
        mode_conv_obliq=$(gmt math -i3 full_eurasia_kinematics_${age}.xyz MODE -S =)

        echo Mode convergence obliquity at $age Ma is:
        echo $mode_conv_obliq

        std_conv_obliq=$(gmt math -i3 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Convergence obliquity Std at $age Ma is:
        echo $std_conv_obliq

        # Add $mode_conv_obliq to our kinematics_master.xyz file
        awk -v age=$age -v mode_conv_obliq=$mode_conv_obliq '{
            if ($1 == age) {
                $0 = $0 OFS mode_conv_obliq
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_conv_obliq to our kinematics_master.xyz file
        awk -v age=$age -v std_conv_obliq=$std_conv_obliq '{
            if ($1 == age) {
                $0 = $0 OFS std_conv_obliq
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate mode and standard deviation of migration rate for time step
        mode_migr_rate=$(gmt math -i4 full_eurasia_kinematics_${age}.xyz MODE -S =)

        echo Mode trench retreat rate at $age Ma is:
        echo $mode_migr_rate

        std_migr_rate=$(gmt math -i4 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Trench retreat rate Std at $age Ma is:
        echo $std_migr_rate

        # Add $mode_migr_rate to our kinematics_master.xyz file
        awk -v age=$age -v mode_migr_rate=$mode_migr_rate '{
            if ($1 == age) {
                $0 = $0 OFS mode_migr_rate
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_migr_rate to our kinematics_master.xyz file
        awk -v age=$age -v std_migr_rate=$std_migr_rate '{
            if ($1 == age) {
                $0 = $0 OFS std_migr_rate
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate mode and standard deviation of migration obliquity for time step
        mode_migr_obliq=$(gmt math -i5 full_eurasia_kinematics_${age}.xyz MODE -S =)

        echo Mode trench retreat obliquity at $age Ma is:
        echo $mode_migr_obliq

        std_migr_obliq=$(gmt math -i5 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Trench retreat obliquity Std at $age Ma is:
        echo $std_migr_obliq

        # Add $mode_migr_obliq to our kinematics_master.xyz file
        awk -v age=$age -v mode_migr_obliq=$mode_migr_obliq '{
            if ($1 == age) {
                $0 = $0 OFS mode_migr_obliq
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_migr_obliq to our kinematics_master.xyz file
        awk -v age=$age -v std_migr_obliq=$std_migr_obliq '{
            if ($1 == age) {
                $0 = $0 OFS std_migr_obliq
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate mean and standard deviation of Distance from Continent for time step
        mean_dist_continent=$(gmt math -i8 full_eurasia_kinematics_${age}.xyz MEAN -S =)

        echo Mean distance to continent at $age Ma is:
        echo $mean_dist_continent

        std_dist_continent=$(gmt math -i8 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Distance to continent Std at $age Ma is:
        echo $std_dist_continent

        # Add $mean_dist_continent to our kinematics_master.xyz file
        awk -v age=$age -v mean_dist_continent=$mean_dist_continent '{
            if ($1 == age) {
                $0 = $0 OFS mean_dist_continent
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_dist_continent to our kinematics_master.xyz file
        awk -v age=$age -v std_dist_continent=$std_dist_continent '{
            if ($1 == age) {
                $0 = $0 OFS std_dist_continent
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate mode and standard deviation orthogonal migration rate for time step
        mode_migration=$(gmt math -i9 full_eurasia_kinematics_${age}.xyz MODE -S =)  

        echo Mode orthogonal trench retreat rate at $age Ma is:
        echo $mode_migration

        std_migration=$(gmt math -i9 full_eurasia_kinematics_${age}.xyz STD -S =)   

        echo Orthogonal trench retreat rate standard deviation at $age Ma is:
        echo $std_migration

        # Add $mode_migration to our kinematics_master.xyz file
        awk -v age=$age -v mode_migration=$mode_migration '{
            if ($1 == age) {
                $0 = $0 OFS mode_migration
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz


        # Add $std_migration to our kinematics_master.xyz file
        awk -v age=$age -v std_migration=$std_migration '{
            if ($1 == age) {
                $0 = $0 OFS std_migration
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz




        # Calculate mode and standard deviation orthogonal convergence rate for time step
        mode_convergence=$(gmt math -i10 full_eurasia_kinematics_${age}.xyz MODE -S =)

        echo Mode orthogonal convergence at $age Ma is:
        echo $mode_convergence

        std_convergence=$(gmt math -i10 full_eurasia_kinematics_${age}.xyz STD -S =)

        echo Orthogonal convergence standard deviation at $age Ma is:
        echo $std_convergence


        # Add $mode_convergence to our kinematics_master.xyz file
        awk -v age=$age -v mode_convergence=$mode_convergence '{
            if ($1 == age) {
                $0 = $0 OFS mode_convergence
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_convergence to our kinematics_master.xyz file
        awk -v age=$age -v std_convergence=$std_convergence '{
            if ($1 == age) {
                $0 = $0 OFS std_convergence
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Calculate total arc length in m for time step
        sum_arc_length_m=$(gmt math -i11 full_eurasia_kinematics_${age}.xyz SUM -Sl =)

        echo Total arc length in metres at $age Ma is:
        echo $sum_arc_length_m

        # Add $sum_arc_length_m to our kinematics_master.xyz file
        awk -v age=$age -v sum_arc_length_m=$sum_arc_length_m '{
            if ($1 == age) {
                $0 = $0 OFS sum_arc_length_m
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22)




        # Create a post script file
        psfile=cooling_convergence_rates_global_${age}.ps        
   

        #gmt psbasemap -R$region -J$projection -Ba20We -K -Y20c -V4 > $psfile

        ## Make a new map in a spherical projection    -Gdarkslateblue
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -SDarkTurquoise -Gpaleturquoise -t40 -K -Y20c -V4 > $psfile 
   
        # Plot seafloor age grid
        # gmt grdimage -R -J $seafloor_age -C$age_grid_cpt -K -O >> $psfile
        
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W1.5p $plate_boundaries -K -O -N -V >> $psfile
   
        # Plot subduction zones (can look a little sloppy under convergence rates)
        # gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        # gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot cooling interpolation
        gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

        # Plot cooling rates
        gmt psxy -R -J thermochron_${age}.xyz -Sc2p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Plot convergence rates
        gmt psxy -R -J kinematics_${age}.xyz -Sc3p -Cconvergence.cpt -K -O >> $psfile
   
        # Plot velocities
        awk '{print $1, $2, $3, $4/10}' $mesh | gmt psxy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile        

        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X9c >> $psfile     
        gmt psscale -Cconvergence.cpt -Dx2c/1c+w8c/0.5c+ef -Ba2f1:"Orthogonal Convergence [cm/yr]": -O -X3c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 





        ### Eurasian-scale Map of Thermochronology Cooling Rates and Orthogonal Convergence Rate Along Southern Eurasian Margin ###


        # Create a post script file
        psfile=cooling_convergence_rates_eurasia_${age}.ps      

        # Albers projection
        gmt psbasemap -R20/120/0/70 -JB70/25/15/35/10c -Ggray100 -t25 -Ba -K -Y20c -V4 > $psfile

        # Selecting southern Eurasian margin convergence rates
   
        # Plot seafloor age grid
        # gmt grdimage -R -J $seafloor_age -C$age_grid_cpt -K -O >> $psfile
        
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W2.0p $plate_boundaries -K -O -N -V >> $psfile
   
        # Plot subduction zones
        gmt psxy -R -J -W1.5p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W1.5p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot faults
        gmt psxy -R -J $faults -W0.3p,black -t40 -K -O >> $psfile  
   
        # Attempt to make nearest neighbour interpolation
        # gmt nearneighbor thermochron_${age}.xyz -R-180/180/-90/90 -I1 -Lg -Gthermo_interp-${age}.nc -S1000k -N4
        # gmt grdimage -R -J thermo_interp-${age}.nc -Cthermochron_v1.cpt -Q -K -O >> $psfile

        # Plot cooling interpolation
        #gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile
   
        # Plot cooling rates
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile
   
        # Plot convergence rates
        gmt select -F$eurasia kinematics_${age}.xyz | gmt psxy -R -J -Sc5p -Cconvergence.cpt -K -O >> $psfile
 
        # Plot velocities
        # awk '{print $1, $2, $3, $4/10}' $mesh | gmt psxy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile
 
        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

        # Scales
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w10c/0.5ch+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -Y-4c -X-2c >> $psfile  
        gmt psscale -Cconvergence.cpt -Dx2c/1c+w10c/0.5ch+ef -Ba2f1:"Orthogonal Convergence [cm/yr]": -K -O -X12c >> $psfile 

        # Plot histogram of convergence rates along southern Eurasian margins
        # Note gmt phistogram expects only one column of values
        gmt select -F$eurasia kinematics_${age}.xyz | awk '{print $3}' | gmt pshistogram -JX8c/5c -Ba5f1:"Convergence rate [cm/Ma]":/5:"Frequency (%)":WS -Z1 -V -W1 -T0 -R0/20/0/50 -O -Cconvergence.cpt -X3c -Y4c >> $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 





        ### Global Map of Thermochronology Cooling Rates and Orthogonal Trench Migration Rates ###

        # Extract trench migration rates
        # Relevant columns: lon, lat, arc_azimuth, ortho_migr_rate, ortho_conv_rate, time
        # Relevant columns: 3  ,   4,   10       ,     17         ,      18        , 13

        awk -F, -v age=$age '($13 == age) {print $3, $4, $17}' $kinematics_input > migration_${age}.xyz

        # NOTE: ortho_migr_rate is better thought of as tranch retreat rate, as negative values mean trench advance while positive values mean trench retreat 

        # Create a post script file
        psfile=cooling_trench_migration_global_${age}.ps        
   
        #gmt psbasemap -R$region -J$projection -Ba20We -K -Y20c -V4 > $psfile

        ## Make a new map in a spherical projection    -Gdarkslateblue
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -Gpaleturquoise -t40 -SDarkTurquoise -K -Y20c -V4 > $psfile 
   
        # Plot seafloor age grid
        # gmt grdimage -R -J $seafloor_age -C$age_grid_cpt -K -O >> $psfile
        
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W1.0p $plate_boundaries -K -O -N -V >> $psfile
   
        # Plot subduction zones (can look a little sloppy under convergence rates)
        # gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        # gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot cooling interpolation
        gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile

        # Plot cooling rates
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile
   
        # Plot migration rates
        gmt psxy -R -J migration_${age}.xyz -Sc3p -Cmigration.cpt -K -O >> $psfile
   
        # Plot velocities
        awk '{print $1, $2, $3, $4/10}' $mesh | gmt psxy -R -J -W0.3p,black  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile

        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X9c >> $psfile     
        gmt psscale -Cmigration.cpt -Dx2c/1c+w8c/0.5c+e -Ba4f1:"Orthogonal Trench Retreat [cm/yr]": -O -X3c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 








        ### Eurasian-scale Map of Thermochronology Cooling Rates and Orthogonal Trench Migration Rate Along Southern Eurasian Margin ###

        # Create a post script file
        psfile=cooling_trench_migration_eurasia_${age}.ps      

        # Albers projection
        gmt psbasemap -R20/120/0/70 -JB70/25/15/35/10c -Ggray100 -t25 -Ba -K -Y20c -V4 > $psfile

        # Selecting southern Eurasian margin convergence rates
   
        # Plot seafloor age grid
        # gmt grdimage -R -J $seafloor_age -C$age_grid_cpt -K -O >> $psfile
        
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W2.0p $plate_boundaries -K -O -V >> $psfile
   
        # Plot subduction zones
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot faults
        gmt psxy -R -J $faults -W0.3p,black -t40 -K -O >> $psfile  

        # Plot cooling interpolation
        #gmt grdimage -R -J cooling_interpolation_masked_${age}.nc -Cthermochron_interp.cpt -t40 -Q -K -O >> $psfile
   
        # Plot cooling rates
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile
   
        # Plot migration rates  
        gmt select -F$eurasia migration_${age}.xyz | gmt psxy -R -J -Sc5p -Cmigration.cpt -K -O >> $psfile
   
        # Plot velocities
        # awk '{print $1, $2, $3, $4/10}' $mesh | gmt psxy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile
   
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w10c/0.5ch+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -Y-4c -X-2c >> $psfile 
        gmt psscale -Cmigration.cpt -Dx2c/1c+w10c/0.5ch+e -Ba4f1:"Orthogonal Trench Retreat [cm/yr]": -K -O -X12c >> $psfile 

        # Plot histogram of trench migration rates along southern Eurasian margins
        # Note gmt phistogram expects only one column of values
        gmt select -F$eurasia migration_${age}.xyz | awk '{print $3}' | gmt pshistogram -JX8c/5c -Ba5f1:"Orthogonal Trench Retreat [cm/yr]":/5:"Frequency (%)":WS -Z1 -V -W1 -T0 -R-16/16/0/50 -O -Cmigration.cpt -X3c -Y4c >> $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 







        ### EXPLORATION OF SPATIAL/GEOMETRIC RELATIONSHIPS BETWEEN FAULTS, THERMOCHRONOLOGY DATA, AND PLATE KINEMATICS IN A PLATE RECONSTRUCTION CONTEXT ###

        cutoff_rate=1.0

        ### First with the USGS Fault database

        # Select thermochronology data points that are experiencing cooling at rates greater than some amount (adjust this value in if statement)

        awk -v cutoff_rate=$cutoff_rate '$3 >= cutoff_rate' thermochron_${age}.xyz > fast_cooling_samples_${age}.xyz

        # !!!!!! This is an exerpt from one of Sabin's code. N3 should be the fourth column. 
        # gmt sample1d -Af -N3 -I5k -V -fg > aaa

        # Reducing the $faults table size to include faults that are within 1,000 km (value after +d) of samples before interpolating new nodes
        gmt select $faults -Cthermochron_${age}.xyz+d1000k -fg > faults_central_asia_${age}.00Ma.gmt        

        # Calculate lengths of faults
        gmt mapproject faults_central_asia_${age}.00Ma.gmt -G+a+uk > fault_data_${age}.00Ma.gmt

        # Select faults that are longer than a certain amount (value after -D) and adds a header to each series of fault nodes with the third column ($3) being a fault ID number and the fourth column ($4) being "-I" followed by the fault ID
        gmt split -D10k fault_data_${age}.00Ma.gmt -V3  -fg > long_faults_${age}.00Ma.gmt

        # Use awk to add an underscore "_" behind each fault ID in the list
        cat long_faults_${age}.00Ma.gmt | awk '{
            if ($1 ==">")
             print $1, $2, $3, $4 "_";
        else
            print $0;
        }' > long_faults_app_${age}.00Ma.gmt      

        # Try to use an adapted version of Sabin's code to interpolate nodes every 5 km for each fault
        gmt sample1d long_faults_app_${age}.00Ma.gmt -Af -N2 -I5k -V -fg > long_faults_resampled_${age}.00Ma.gmt  

        # Calculate azimuths of each interpolated fault - new file structure: long, lat, length, alternative length 
        gmt mapproject long_faults_resampled_${age}.00Ma.gmt -Ao > long_faults_resampled_data_${age}.00Ma.gmt


        # Select fault nodes that are within a given distance (adjust by changing number after +d, 'k' specifies the distance is kilometres) of thermochronology samples that are cooling at a certain rate or above. gmt select only returns the individual fault nodes tht are within range of cooling samples, not the whole faults they belong to. 
        gmt select long_faults_resampled_data_${age}.00Ma.gmt -Cfast_cooling_samples_${age}.xyz+d25k -fg > faults_subset.gmt 


        # Creates a search list, search_list.txt, of all the unique fault ID numbers of the faults that are within range of the fast cooling samples
        awk '($1 == ">") {print $4}' faults_subset.gmt | sort | uniq > search_list.txt

        # Makes new file, active_faults_${age}.gmt, of all the long faults (long_faults_app_${age}.00Ma.gmt) that have the fault ID numbers which match those of the search list (search_list.txt)
        gmt convert long_faults_resampled_data_${age}.00Ma.gmt -S+fsearch_list.txt > active_faults_${age}.gmt

        # !!!!!!!! Will need to figure out how to first calculate an average azimuth across all of the segments for each fault


        ### Azimuth stuff - need to work with fault data prior to interpolating new nodes, so as to preserve the azimuth data of the longer fault segments

        # Narrow down list of uninterpolated long faults that match the search list and are therefore within range of fast cooling samples
        gmt convert long_faults_app_${age}.00Ma.gmt -S+fsearch_list.txt > active_faults_uninterpolated_${age}.gmt


        # Calculate azimuths of each of the narrowed down, uninterpolated fault - new file structure: long, lat, length, alternative length (not sure why there's a difference, some mystery value, azimuth
        gmt mapproject active_faults_uninterpolated_${age}.gmt -Ao > long_faults_uninterpolated_data_${age}.00Ma.gmt

        # Extract just the last data record for each segment in the filtered faults data, which we will then use for extracting the length and azimuth for each fault
        gmt convert long_faults_uninterpolated_data_${age}.00Ma.gmt -El > long_faults_uninterpolated_extract_${age}.00Ma.gmt

        # Create a list of length, azimuth pairs for the faults from tmp.gmt
        awk '($1 != ">") {print $3, $6}' long_faults_uninterpolated_extract_${age}.00Ma.gmt > fault_azimuths.txt




        ### Second with the AFEAD fault database

        # Reducing the $faults table size to include faults that are within 1,000 km (value after +d) of samples before interpolating new nodes
        gmt select $afead_faults -Cthermochron_${age}.xyz+d1000k -fg > afead_faults_central_asia_${age}.00Ma.gmt        

        # Calculate lengths of faults
        gmt mapproject afead_faults_central_asia_${age}.00Ma.gmt -G+a+uk > afead_fault_data_${age}.00Ma.gmt

        # Select faults that are longer than a certain amount, 50k in this case (value after -D), and adds a header to each series of fault nodes with the third column ($3) being a fault ID number and the fourth column ($4) being "-I" followed by the fault ID
        gmt split -D10k afead_fault_data_${age}.00Ma.gmt -V3  -fg > long_afead_faults_${age}.00Ma.gmt

        # Use awk to add an underscore "_" behind each fault ID in the list
        cat long_afead_faults_${age}.00Ma.gmt | awk '{
            if ($1 ==">")
             print $1, $2, $3, $4 "_";
        else
            print $0;
        }' > long_afead_faults_app_${age}.00Ma.gmt      

        # Try to use an adapted version of Sabin's code to interpolate nodes every 5 km for each fault
        gmt sample1d long_afead_faults_app_${age}.00Ma.gmt -Af -N2 -I5k -V -fg > long_afead_faults_resampled_${age}.00Ma.gmt  

        # Calculate azimuths of each interpolated fault - new file structure: long, lat, length, alternative length (not sure why there's a difference, some mystery value, azimuth
        gmt mapproject long_afead_faults_resampled_${age}.00Ma.gmt -Ao > long_afead_faults_resampled_data_${age}.00Ma.gmt


        # Select fault nodes that are within a given distance (adjust by changing number after +d, 'k' specifies the distance is kilometres) of thermochronology samples that are cooling at a certain rate or above. gmt select only returns the individual fault nodes tht are within range of cooling samples, not the whole faults they belong to. 
        gmt select long_afead_faults_resampled_data_${age}.00Ma.gmt -Cfast_cooling_samples_${age}.xyz+d25k -fg > afead_faults_subset.gmt 


        # Creates a search list, search_list.txt, of all the unique fault ID numbers of the faults that are within range of the fast cooling samples
        awk '($1 == ">") {print $4}' afead_faults_subset.gmt | sort | uniq > afead_search_list.txt

        # Makes new file, active_faults_${age}.gmt, of all the long faults (long_faults_app_${age}.00Ma.gmt) that have the fault ID numbers which match those of the search list (search_list.txt)
        gmt convert long_afead_faults_resampled_data_${age}.00Ma.gmt -S+fafead_search_list.txt > active_afead_faults_${age}.gmt

        # !!!!!!!! Will need to figure out how to first calculate an average azimuth across all of the segments for each fault


        ### Azimuth stuff - need to work with fault data prior to interpolating new nodes, so as to preserve the azimuth data of the longer fault segments

        # Narrow down list of uninterpolated long faults that match the search list and are therefore within range of fast cooling samples
        gmt convert long_afead_faults_app_${age}.00Ma.gmt -S+fafead_search_list.txt > active_afead_faults_uninterpolated_${age}.gmt

        # Calculate azimuths of each of the narrowed doen, uninterpolated fault - new file structure: long, lat, length, alternative length (not sure why there's a difference, some mystery value, azimuth
        gmt mapproject active_afead_faults_uninterpolated_${age}.gmt -Ao > long_afead_faults_uninterpolated_data_${age}.00Ma.gmt

        # Extract just the last data record for each segment in the filtered faults data, which we will then use for extracting the length and azimuth for each fault
        gmt convert long_afead_faults_uninterpolated_data_${age}.00Ma.gmt -El > long_afead_faults_uninterpolated_extract_${age}.00Ma.gmt

        # Create a list of length, azimuth pairs for the faults from tmp.gmt
        awk '($1 != ">") {print $3, $6}' long_afead_faults_uninterpolated_extract_${age}.00Ma.gmt > afead_fault_azimuths.txt





        ### MAKE SHAPEFILES OF POTENTIAL REACTIVATED FAULS IN PRESENT-DAY COORDINATES ###

        # First, select thermochronology data points that are experiencing cooling at rates greater than some amount (adjust this value in if statement)

        awk -v cutoff_rate=$cutoff_rate '$3 >= cutoff_rate' static_thermochron_${age}.xyz > static_fast_cooling_samples_${age}.xyz

        # Second, find subset of $faults in present-day location that are in proximity to fast cooling samples for this time-step in present-day coordinates
        gmt select static_long_faults_resampled_data.gmt -Cstatic_fast_cooling_samples_${age}.xyz+d25k -fg > static_faults_subset.gmt 

        # Creates a search list, search_list.txt, of all the unique fault ID numbers of the faults that are within range of the fast cooling samples
        awk '($1 == ">") {print $4}' static_faults_subset.gmt | sort | uniq > static_search_list.txt

        # Makes new file, active_faults_${age}.gmt, of all the long faults (long_faults_app_${age}.00Ma.gmt) that have the fault ID numbers which match those of the search list (search_list.txt)
        gmt convert static_long_faults_resampled_data.gmt -S+fstatic_search_list.txt > static_active_faults_${age}.gmt

        # Narrow down list of uninterpolated long faults that match the search list and are therefore within range of fast cooling samples
        gmt convert static_long_faults_app.gmt -S+fstatic_search_list.txt > static_active_faults_uninterpolated_${age}.gmt

        # Then, convert .gmt file to .shp
        ogr2ogr -f "ESRI Shapefile" Shapefiles/USGS_Faults/static_active_faults_uninterpolated_${age}.shp static_active_faults_uninterpolated_${age}.gmt 



        # Do it all again for the afead_fault database
        # Find subset of $afead_faults in present-day location that are in proximity to fast cooling samples for this time-step in present-day coordinates
        gmt select static_long_afead_faults_resampled_data.gmt -Cstatic_fast_cooling_samples_${age}.xyz+d25k -fg > static_afead_faults_subset.gmt 

        # Creates a search list, search_list.txt, of all the unique fault ID numbers of the faults that are within range of the fast cooling samples
        awk '($1 == ">") {print $4}' static_afead_faults_subset.gmt | sort | uniq > static_afead_search_list.txt

        # Makes new file, active_faults_${age}.gmt, of all the long faults (long_faults_app_${age}.00Ma.gmt) that have the fault ID numbers which match those of the search list (search_list.txt)
        gmt convert static_long_afead_faults_resampled_data.gmt -S+fstatic_afead_search_list.txt > static_active_afead_faults_${age}.gmt

        # Narrow down list of uninterpolated long faults that match the search list and are therefore within range of fast cooling samples
        gmt convert static_long_afead_faults_app.gmt -S+fstatic_afead_search_list.txt > static_active_afead_faults_uninterpolated_${age}.gmt

        # Then, convert .gmt file to .shp
        ogr2ogr -f "ESRI Shapefile" Shapefiles/AFEAD_Faults/static_active_afead_faults_uninterpolated_${age}.shp static_active_afead_faults_uninterpolated_${age}.gmt 





        ### Calculate plate velocity statistics within a user-defined range of the "reactivated" faults

        # Extract the plate velocities nearest the "reactivated" faults

        awk '{print $1, $2, $3, $4}' $mesh | gmt select -Cfast_cooling_samples_${age}.xyz+d750k -fg > plate_velocities_local_${age}.00Ma.xy

        # Make new, clean .xyz file from plate_velocities_local_${age}.00Ma.xy
        awk '($1 != ">") {print $0}' plate_velocities_local_${age}.00Ma.xy > plate_velocities_local_${age}.00Ma.xyz

        # Calculate mean and std of plate velocity from plate_velocities_local_${age}.00Ma.xy and store in kinematics_master.xyz for this time period
        mean_plate_velocity=$(gmt math -i3 plate_velocities_local_${age}.00Ma.xyz MEAN -S =)

        echo Mean plate velocity at $age Ma is:
        echo $mean_plate_velocity

        std_plate_velocity=$(gmt math -i3 plate_velocities_local_${age}.00Ma.xyz STD -S =)

        echo Plate velocity standard deviation at $age Ma is:
        echo $std_plate_velocity


        # Add $mean_plate_velocity to our kinematics_master.xyz file
        awk -v age=$age -v mean_plate_velocity=$mean_plate_velocity '{
            if ($1 == age) {
                $0 = $0 OFS mean_plate_velocity
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # Add $std_plate_velocity to our kinematics_master.xyz file
        awk -v age=$age -v std_plate_velocity=$std_plate_velocity '{
            if ($1 == age) {
                $0 = $0 OFS std_plate_velocity
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
        # mean plate velocity ($23), std plate velocity ($24)

      

        # Make a rose diagram of plate velocites and calculate their mean azimuth and velocity, which are stored all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.
        # !!!!!! There is an issue here; the mean plate velocity value calculated by the "-Em" command is a scaled mean velocity, rather than a mean. For age=74 Ma and plate velocities are searched for within 750 km of fast_cooling_samples, the mean velocity and azimuth should be 2.751 m/yr towards 221.111 degrees. Need to fix. 
        awk '($1 != ">") {print $4, $3}' plate_velocities_local_${age}.00Ma.xy > tmp.xy
        psfile=rose_plate_motion_${age}.ps 
        gmt psrose tmp.xy -R0/75/0/360 -JX10c -Bxg5 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -Q0.5 -Em+wplate_motion_principal_directions_${age}.txt -B+t"Plate motion at $age Ma" -W0.5p -Wv0.5p,black -Cplate_motion_rose.cpt -K > $psfile

        gmt psscale -Cplate_motion_rose.cpt -Dx2c/1c+w10c/0.5c+ef -Ba0.5f0.1:"Plate Velocity [cm/yr]": -O -X11c -Y-1c >> $psfile 
        
        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 



        # Pull out mean azimuth ($1) from plate_motion_principal_directions_${age}.txt and add it to the kinematics_master.xyz file
        mean_plate_velo_azimuth=$(awk '{print $1}' plate_motion_principal_directions_${age}.txt =)

        echo Mean plate velocity azimuth at $age Ma is:
        echo $mean_plate_velo_azimuth

        # Add $mean_plate_velo_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_plate_velo_azimuth=$mean_plate_velo_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_plate_velo_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
        # mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25)





        ### Plot (rose diagram) and calculate average azimuths of arcs, convergence and migration along nearby sudbuction zone(s)

        # Structure of kinematics input file. Note, convergence azimuth and migration azimuth were calculated in excel and added to the kinematics file that GPlates exported
        # Relevant columns: lon, lat, arc_azimuth, conv_rate, migr_rate, ortho_migr_rate, ortho_conv_rate, arc_length_m, migr_azimuth, conv_azimuth, time
        # Relevant columns: 3  ,   4,   10       ,     5    ,     7    ,     17         ,      18        ,      19     ,      28     ,      30     ,  13

        # !!!!!!!!! Need to check that calculated convergence azimuth and migration azimuth are correct. 
   

        # Make .xyz file for arc_azimuths
        awk -F, -v age=$age '($13 == age) {print $3, $4, $10 + 90}' $kinematics_input > arc_azimuths_${age}.xyz

        # Narrow down arc azimuth data to just those along southern Eurasian margin and make file that stores only the arc azimuths
        gmt select -F$eurasia arc_azimuths_${age}.xyz | awk '{print $3}' > arc_azimuths_only_${age}.xyz

        # Make a rose diagram of southern Eurasian margin arc azimuths and calculate the mean azimuth, which are stored all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.
        psfile=rose_arc_azimuths_${age}.ps 
        gmt psrose arc_azimuths_only_${age}.xyz -i0 -T -R0/70/0/360 -JX10c -Bxg10 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -Q0.5 -Em+warc_azimuth_principal_directions_${age}.txt -B+t"Southern Eurasian arc orientations @^ at $age Ma" -W0.5p -Wv0.5p -Csector_diagram.cpt > $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 



        # Pull out mean arc azimuth ($1) from arc_azimuth_principal_directions_${age}.txt and add it to the kinematics_master.xyz file
        mean_arc_azimuth=$(awk '{print $1}' arc_azimuth_principal_directions_${age}.txt =)

        # Add 180 degrees to all mean arc azimuths equal to or less than 180, so that arcs with azimuths of, for example, 90 and 270 plot together. 
        if (( $(echo "$mean_arc_azimuth <= 180" | bc -l) )); then
                mean_arc_azimuth=$(echo "$mean_arc_azimuth + 180" | bc -l)
        fi

        echo Mean arc azimuth at $age Ma is:
        echo $mean_arc_azimuth

        # Add $mean_arc_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_arc_azimuth=$mean_arc_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_arc_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz






        # Make .xyz file for migr_azimuths - note, need to add 180 degrees to migr_azimuths so that it plots in the correct orientation in the rose diagram
        awk -F, -v age=$age '($13 == age) {print $3, $4, $7, $10 + $8 + 180}' $kinematics_input > migr_azimuths_rose_${age}.xyz

        # !!!!!!!!!!!!!! Need to check with Sabin that the calculated migr_azimuths make sense. 

        # Narrow down migration azimuth data to just those along southern Eurasian margin and make file that stores only the migration rates and azimuths
        gmt select -F$eurasia migr_azimuths_rose_${age}.xyz | awk '{print $3, $4}' > migr_azimuths_rose_only_${age}.xyz

        # Make a rose diagram of arc migration azimuths 
        psfile=rose_migr_azimuths_${age}.ps 
        gmt psrose migr_azimuths_rose_only_${age}.xyz -R0/800/0/360 -JX10c -Bxg50 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -B+t"Tethyan subduction zone migration @^ at $age Ma" -Cmigration.cpt -W0.5p -Wv0.5p -K > $psfile 

        # Make another rose diagram of arc migration azimuths to calculate their mean azimuth and velocity, but without adding it to the psfile. The outputs are stored all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.
        gmt psrose migr_azimuths_rose_only_${age}.xyz -R0/200/0/360 -JX10c -Bxg10 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -E+wmigr_azimuths_principal_directions_${age}.txt -Q0.5 -B+t"Tethyan subduction zone migration @^ at $age Ma" -Cmigration.cpt -W0.5p -Wv0.5p 

        gmt psscale -Cmigration.cpt -Dx2c/1c+w10c/0.5c+e -Ba4f1:"Trench Retreat Rate [cm/yr]": -O -X11c -Y-1c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 

        # Pull out mean migration azimuth ($1) from $kinematics_input - We need to do this again, this time without adding 180 degrees as we did above for the rose diagram
        #awk -F, -v age=$age '($13 == age) {print $3, $4, $7, $10 + $8}' $kinematics_input > migr_azimuths_${age}.xyz
        #gmt select -F$eurasia migr_azimuths_${age}.xyz | awk '{print $3, $4}' > migr_azimuths_only_${age}.xyz
        #gmt psrose migr_azimuths_only_${age}.xyz -R0/200/0/360 -JX10c -Bxg10 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -E+wmigr_azimuths_principal_directions_${age}.txt -Q0.5 -B+t"Tethyan subduction zone migration @^ at $age Ma" -Cmigration.cpt -W0.5p -Wv0.5p 
        
        mean_migr_azimuth=$(awk '{print $1}' migr_azimuths_principal_directions_${age}.txt =)

        echo Mean arc migration azimuth at $age Ma is:
        echo $mean_migr_azimuth

        # Add $mean_migr_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_migr_azimuth=$mean_migr_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_migr_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz



        # Make .xyz file for conv_azimuths
        awk -F, -v age=$age '($13 == age) {print $3, $4, $5, $10 + $6}' $kinematics_input > conv_azimuths_${age}.xyz    

        # Narrow down convergence azimuth data to just those along southern Eurasian margin and make file that stores only the convergence rates and azimuths
        gmt select -F$eurasia conv_azimuths_${age}.xyz | awk '{print $3, $4}' > conv_azimuths_only_${age}.xyz

        # Make a rose diagram of plate velocites and calculate their mean azimuth and velocity, which are stored all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.            
        psfile=rose_conv_azimuths_${age}.ps 
        gmt psrose conv_azimuths_only_${age}.xyz -R0/1000/0/360 -JX10c -Bxg100 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -Q0.5 -Em+wconv_azimuths_principal_directions_${age}.txt -B+t"Tethyan subduction zone convergence @^ at $age Ma" -Cconvergence.cpt -W0.5p -Wv0.5p+gorange -K > $psfile

        gmt psscale -Cconvergence.cpt -Dx2c/1c+w10c/0.5c+ef -Ba2f1:"Convergence Rate [cm/yr]": -O -X11c -Y-1c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 

        # Pull out conv migration azimuth ($1) from conv_azimuths_principal_directions_${age}.txt and add it to the kinematics_master.xyz file
        mean_conv_azimuth=$(awk '{print $1}' conv_azimuths_principal_directions_${age}.txt =)

        echo Mean convergence azimuth at $age Ma is:
        echo $mean_conv_azimuth

        # Add $mean_conv_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_conv_azimuth=$mean_conv_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_conv_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz


        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
        # mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28)





        ### Plot subset of USGS faults on map that are within a given range of quickly cooling samples

        # Create a post script file
        psfile=faults_near_cooling_${age}.ps     

        # Albers projection
        gmt psbasemap -R$mask_long_min/$mask_long_max/$mask_lat_min/$mask_lat_max -JB70/25/15/35/10c -Ba -K -Y20c -V4 > $psfile   

        # Plot terranes
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile

        # Plot topography 
        gmt grdimage -R -J $topography -Ctopo_dem2_land.cpt -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W2.0p $plate_boundaries -K -O -N -V >> $psfile
    
        # Plot subduction zones
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot all long faults to compare with subset of faults
        #gmt psxy -R -J long_faults_${age}.00Ma.gmt -W0.3p,red -K -O >> $psfile         
    
        # Plot faults near rapidly cooling samples on map, with all other faults in background
        gmt psxy -R -J $faults -W0.1p,black -K -O >> $psfile   
        gmt psxy -R -J active_faults_${age}.gmt -W0.3p,firebrick1 -K -O >> $psfile    

        # Plot all thermochron samples for comparison
        #gmt psxy -R -J thermochron_${age}.xyz -Sc1p -Cblack -K -O >> $psfile

        # Plot cooling rates of fast cooling samples, with all other samples in background
        gmt psxy -R -J thermochron_${age}.xyz -Sc1p -W0.1p,black -Gblack -K -O >> $psfile
        gmt psxy -R -J fast_cooling_samples_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile
        
        # Plot convergence rates on southern Eurasian margin
        gmt select -F$eurasia kinematics_${age}.xyz | gmt psxy -R -J -Sc5p -Cconvergence.cpt -K -O >> $psfile

        # Plot proximal velocities - 
        #gmt psxy plate_velocities_local_${age}.00Ma.xy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

        # Plot scale
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w6c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -X10c -Y-1c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 




        ### Plot subset of AFEAD faults on map that are within a given range of quickly cooling samples

        # Create a post script file
        psfile=afead_faults_near_cooling_${age}.ps     

        # Albers projection
        gmt psbasemap -R$mask_long_min/$mask_long_max/$mask_lat_min/$mask_lat_max -JB70/25/15/35/10c -Ba -K -Y20c -V4 > $psfile   

        # Plot terranes
        gmt psxy -R -J $terranes -Gnavajowhite4 -K -O >> $psfile

        # Plot topography 
        gmt grdimage -R -J $topography -Ctopo_dem2_land.cpt -K -O >> $psfile
        
        # Plots plate topology outlines
        gmt psxy -R -J -W2.0p $plate_boundaries -K -O -N -V >> $psfile
    
        # Plot subduction zones
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W2.0p,magenta -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot all long faults to compare with subset of faults
        #gmt psxy -R -J long_faults_${age}.00Ma.gmt -W0.3p,red -K -O >> $psfile         
    
        # Plot faults near rapidly cooling samples on map, with all other faults in background
        gmt psxy -R -J $afead_faults -W0.1p,black -K -O >> $psfile   
        gmt psxy -R -J active_afead_faults_${age}.gmt -W0.3p,firebrick1 -K -O >> $psfile    

        # Plot all thermochron samples for comparison
        #gmt psxy -R -J thermochron_${age}.xyz -Sc1p -Cblack -K -O >> $psfile

        # Plot cooling rates of fast cooling samples, with all other samples in background
        gmt psxy -R -J thermochron_${age}.xyz -Sc1p -W0.1p,black -Gblack -K -O >> $psfile
        gmt psxy -R -J fast_cooling_samples_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile
        
        # Plot convergence rates on southern Eurasian margin
        gmt select -F$eurasia kinematics_${age}.xyz | gmt psxy -R -J -Sc5p -Cconvergence.cpt -K -O >> $psfile

        # Plot proximal velocities - 
        #gmt psxy plate_velocities_local_${age}.00Ma.xy -R -J -W0.3p  -SV0.2c+e+g -G0 -K -O -V >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

        # Plot scale
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w6c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -X10c -Y-1c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 





        # Plot Rose diagram of USGS fault azimuths, calculate principal direction statistics, plot the mean azimuth and store all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.
        psfile=rose_faults_${age}.ps 
        gmt psrose fault_azimuths.txt -R0/5000/0/360 -T -JX10c -Bxg500 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -Q0.05 -Em+wfault_principal_directions_${age}.txt -B+t"'Reactivated' fault orientations at $age Ma" -W0.5p  -Wv1p -Csector_diagram.cpt > $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 



        # Plot Rose diagram of AFEAD fault azimuths, calculate principal direction statistics, plot the mean azimuth and store all the mean statitsics in a .txt file with the form mean_az, mean_r, mean_resultant, max_r, scaled_mean_r, length_sum, n, sign@alpha, where the last term is 0 or 1 depending on whether the mean resultant is significant at the level of confidence set via -Q.
        psfile=rose_afead_faults_${age}.ps 
        gmt psrose afead_fault_azimuths.txt -R0/5000/0/360 -T -JX10c -Bxg500 -Byg30 -A10 -M0.5c+e+gsteelblue4+n1c -Q0.05 -Em+wafead_fault_principal_directions_${age}.txt -B+t"'Reactivated' fault orientations at $age Ma" -W0.5p  -Wv1p -Csector_diagram.cpt > $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 




        # Pull out mean USGS fault azimuth ($1) from fault_principal_directions_${age}.txt and add it to the kinematics_master.xyz file
        mean_fault_azimuth=$(awk '{print $1}' fault_principal_directions_${age}.txt =)

        # Add 180 degrees to all mean fault azimuths equal to or less than 180, so that arcs with azimuths of, for example, 90 and 270 plot together. 
        if (( $(echo "$mean_fault_azimuth <= 180" | bc -l) )); then
            mean_fault_azimuth=$(echo "$mean_fault_azimuth + 180" | bc -l)
        fi

        echo Mean fault azimuth at $age Ma is:
        echo $mean_fault_azimuth

        # Add $mean_fault_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_fault_azimuth=$mean_fault_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_fault_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
        # mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28), mean fault azimuth ($29)


        # Pull out mean AFEAD fault azimuth ($1) from fault_principal_directions_${age}.txt and add it to the kinematics_master.xyz file
        mean_afead_fault_azimuth=$(awk '{print $1}' afead_fault_principal_directions_${age}.txt =)

        # Add 180 degrees to all mean fault azimuths equal to or less than 180, so that arcs with azimuths of, for example, 90 and 270 plot together. 
        if (( $(echo "$mean_afead_fault_azimuth <= 180" | bc -l) )); then
                mean_afead_fault_azimuth=$(echo "$mean_afead_fault_azimuth + 180" | bc -l)
        fi

        echo Mean AFEAD fault azimuth at $age Ma is:
        echo $mean_afead_fault_azimuth

        # Add $mean_fault_azimuth to our kinematics_master.xyz file
        awk -v age=$age -v mean_afead_fault_azimuth=$mean_afead_fault_azimuth '{
            if ($1 == age) {
                $0 = $0 OFS mean_afead_fault_azimuth
            }
            print
        }' kinematics_master.xyz > tmp.xyz
        mv tmp.xyz kinematics_master.xyz

        # NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
        # mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
        # mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
        # mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28), mean fault azimuth ($29), mean AFEAD fault azimuth ($30)




        ### GLOBAL MAP OF THERMOCHRONOLOGY COOLING RATE AND PALEOPRECIPITATION ###

        # Create a post script file
        psfile=cooling_paleoprecip_global_${age}.ps

        ## Plot paleoprecipitation
        ## Make a new map and place it below (-Y command) the first map
        gmt psbasemap -R$region -J$projection -Ba20We -K -Y20c > $psfile
        
        # Plot paleoprecipitation
        gmt grdimage -R -J $precipitation -Cpaleoprecip2.cpt -K -O >> $psfile

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -W0.3p,black -K -O >> $psfile

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile
        
        # Make scale for paleoprecipitation
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w12c/0.5ch+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X-1c -Y-2c >> $psfile 
        gmt psscale -Cpaleoprecip2.cpt -Dx2c/1c+w12c/0.5ch+efb -Ba2f1:"Paleoprecipitation [m/yr]": -O -Y-2c >> $psfile 

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 




        ### SPHERICAL PROJECTION OF COOLING RATE VERSUS PALEOPRECIPITATION ###

        # Create a post script file
        psfile=cooling_paleoprecip_sphere_${age}.ps

        ## Make a new map and place it below (-Y command) the first map
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -Gwhite -SDarkTurquoise -K -Y20c -V4 > $psfile
        
        # Plot paleoprecipitation
        gmt grdimage -R -J $precipitation -Ba20g10/a30g20 -Cpaleoprecip2.cpt -K -O >> $psfile # -Ba20g10/a30g20 

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -W0.3p,black -K -O >> $psfile

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile
        
        # Make scale for paleoprecipitation
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -K -O -X9c >> $psfile         
        gmt psscale -Cpaleoprecip2.cpt -Dx2c/1c+w8c/0.5c+ef -Ba2f1:"Paleoprecipitation [m/yr]": -O -X3c >> $psfile 


        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 





        ### SPHERICAL PROJECTION OF COOLING RATE VERSUS PALEOTOPOGRAPHY ###

        # Create a post script file
        psfile=cooling_paleotopo_sphere_${age}.ps

        ## Make a new map and place it below (-Y command) the first map
        gmt psbasemap -R$region -JG73/37/10c -Ba360 -Gdarkslateblue -SDarkTurquoise -K -Y20c -V4 > $psfile
        
        # Plot topography
        #gmt grdimage -R -J $topography -C$topo_cpt -K -O >> $psfile

        # Plot paleotopography
        gmt psxy -R -J $paleotopography_shallow_marine -Gpaleturquoise -K -O >> $psfile
        gmt psxy -R -J $paleotopography_land -Gdarkolivegreen -K -O >> $psfile
        gmt psxy -R -J $paleotopography_mountains -Gsaddlebrown -K -O >> $psfile
        gmt psxy -R -J $paleotopography_ice -Gsnow -K -O >> $psfile

        # Plot terranes (coastlines)
        gmt psxy -R -J $terranes -W0.3p,black -K -O >> $psfile

        # Plots plate topology outlines
        gmt psxy -R -J -W0.5p $plate_boundaries -K -O -N -V >> $psfile

        # Plot subduction zones
        gmt psxy -R -J -W1.5p,firebrick1 -Sf8p/1.5plt -K -O ${subduction_left} -V -N >> $psfile
        gmt psxy -R -J -W1.5p,firebrick1 -Sf8p/1.5prt -K -O ${subduction_right} -V -N >> $psfile

        # Plot coloured circles for the cooling rate of each sample
        gmt psxy -R -J thermochron_${age}.xyz -Sc3p -W0.1p,black -Cthermochron_v1.cpt -K -O >> $psfile

        # Add label for age of reconstruction
        echo "$age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -K -O >> $psfile
        
        # Make scale for thermochronology
        gmt psscale -Cthermochron_v1.cpt -Dx2c/1c+w8c/0.5c+ef -Ba0.5f0.1:"Cooling Rate [@.C/Ma]": -O -X9c >> $psfile         
        
        # !!!! Need to make legend

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 






        # Creating .xyz files for dynamic topography and change in dynamic topography, respectively, for each sample location by adding the appropriate value to the thermochron.xyz file for a given time step
        gmt grdtrack thermochron_clean_${age}.xyz -G$dynamic_topography > thermochron_dynTopo_${age}.xyz
        gmt grdtrack thermochron_clean_${age}.xyz -G$dynamic_topo_gradient > thermochron_dynTopoChange_${age}.xyz
        gmt grdtrack thermochron_clean_${age}.xyz -G$precipitation > thermochron_precip_${age}.xyz

        # Remove data points with #N/A for cooling rates
        awk '($4 != "#N/A") {print $0}' thermochron_dynTopo_${age}.xyz > thermochron_dynTopo_clean_${age}.xyz
        awk '($4 != "#N/A") {print $0}' thermochron_dynTopoChange_${age}.xyz > thermochron_dynTopoChange_clean_${age}.xyz
        awk '($4 != "#N/A") {print $0}' thermochron_precip_${age}.xyz > thermochron_precip_clean_${age}.xyz


        ### SCATTER PLOT OF COOLING RATE VERSUS DYNAMIC TOPOGRAPHY ###

        # Create a post script file
        psfile=cooling_v_dynTopo_plot_${age}.ps

        # Make a scatter plot, tempdiff vs dynamic topo
        awk '{print $3, $4}' thermochron_dynTopo_clean_${age}.xyz | gmt psxy -R0/5/-800/800 -JX10c/10c -Sc2.0p -Gsalmon -W0.1p,black -Ba1:"Cooling Rate [@.C/Ma]":/a200:"Dynamic Topo [m]":WS -K > $psfile  # -Ggreen
        #gmt psxy thermochron_dynTopo_clean_${age}.xyz -i2,3 -R0/5/-800/800 -JX10c/10c -Ba1:"Cooling Rate [@.C/Ma]":/a200:"Dynamic Topo [m]":WS -Sc2.0p -Gred -K -V > $psfile # -P 

        # Add label for age of reconstruction
        echo "  $age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O >> $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 


        ### SCATTER PLOT OF COOLING RATE VERSUS CHANGE IN DYNAMIC TOPOGRAPHY ###

        # Create a post script file
        psfile=cooling_v_dynTopoChange_plot_${age}.ps

        # Make a scatter plot, tempdiff vs change in dynamic topo
        awk '{print $3, $4}' thermochron_dynTopoChange_clean_${age}.xyz | gmt psxy -R0/5/-20/20 -JX10c/10c -Sc2.0p -Gspringgreen1 -W0.1p,black -Ba1:"Cooling Rate [@.C/Ma]":/a5:"Dynamic Topo Change [m/Ma]":WS -K > $psfile # -Ggreen

        # Add label for age of reconstruction
        echo "  $age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O >> $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 




        ### SCATTER PLOT OF COOLING RATE VERSUS PALEOPRECIPITATION ###

        # Create a post script file
        psfile=cooling_v_paleoprecip_plot_${age}.ps

        # Make a scatter plot, cooling rate vs paleoprecipitaion
        awk '{print $3, $4}' thermochron_precip_clean_${age}.xyz | gmt psxy -R0/5/0/5 -JX10c/10c -Sc2.0p -Gcyan1 -W0.1p,black -Ba1:"Cooling Rate [@.C/Ma]":/a1:"Paleoprecipitation [m/yr]":WS -K > $psfile # 

        # Add label for age of reconstruction
        echo "  $age Ma" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -O >> $psfile

        # Convert postscript file to a jpg, pdf, and png
        gmt psconvert $psfile -Tj -A -DFigures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
        gmt psconvert $psfile -Tf -A -DFigures 
        gmt psconvert $psfile -TG -A -DFigures 

    age=$(($age + 1))
done

# NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
# mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
# mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
# mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28), mean fault azimuth ($29), mean AFEAD fault azimuth ($30)

# NOTE: thermochron_master_${age}.xyz now has structure of long ($1), lat ($2), cooling rate ($3), dynamic topography ($4), change in dynamic topography ($5), paleoprecipitation rate ($6)

exit