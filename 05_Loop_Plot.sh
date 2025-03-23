#!/bin/bash

# Do only once: chmod +rwx 05_Loop_Plot.sh  # Gives read, write, execute permission for script 

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT=10p,black MAP_FRAME_PEN=thin,black FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_DEFAULT_PEN=0.25p,black MAP_GRID_PEN=0.25p,black MAP_TICK_PEN=0.25p,black 

### Uses the series of thermochron_master_${age}.xyz files created in 03_Thermochron_GPlates.sh for every modelling time step and creates three different scatter plots of cooling rate versus 
### time coloured by (i) dynamic topography, (ii) change in dynamic topography, and (iii) paleoprecipitaton rate across the entire input thermochronology dataset. ###




### Prompt user to provide new directory name base ###

#read -p "What would you like to call your new output directory for this script? " directory
#
#directory_name="Loop_plot_$directory"
#
#mkdir -v -m777 $directory_name
#
#cd $directory_name || exit 1

mkdir -v -m777 Loop_Figures


gmt makecpt -Cvik -T-800/800/50 -Z > dynamic_topo.cpt
gmt makecpt -Cdavos -T0/6/1 -Z -I > paleoprecip.cpt
gmt makecpt -Cno_green -T-5/5/0.1 -Z -I > dynamic_topo_change.cpt
gmt makecpt -Cdrywet -T0/6/1 -Z > paleoprecip2.cpt



# Test for single iteration through loop
# age=50


### Make plot of cooling rate v time, coloured by dynamic topography, for all data, for all time steps

# Create a post script file
psfile=cooling_v_time_v_dyntopo_loop__test.ps 

# Add title
echo " " | gmt pstext -R -J -F+f10,Helvetica-Bold,white+cTL -N -K > $psfile

# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0
while (( $age <= 230 ))
    do
        # Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
        awk -v age=$age '{print age, $3, $4}' thermochron_master_${age}.xyz | gmt psxy -R0/230/0/15 -JX-10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc2.0p -Cdynamic_topo.cpt -W0.1p,black -K -O >> $psfile
    age=$(($age + 1))
done

# Add title
echo "Cooling Rate Over Time by Dynamic Topography" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Dynamic Topography
gmt psscale -Cdynamic_topo.cpt -Dx2c/1c+w10c/0.5c+efb -Ba250f50:"Dynamic Topography [m]": -O -X10c -Y-2c >> $psfile 

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DLoop_Figures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DLoop_Figures
gmt psconvert $psfile -TG -A -DLoop_Figures



### Make plot of cooling rate v time, coloured by change in dynamic topography, for all data, for all time steps

# Create a post script file
psfile=cooling_v_time_v_dyntopochange_loop__test.ps  

# Add white dummy title to start psfile
echo " " | gmt pstext -R -J -F+f10,Helvetica-Bold,white+cTL -N -K > $psfile

# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0
while (( $age <= 230 ))
    do
        # Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
        awk -v age=$age '{print age, $3, $5}' thermochron_master_${age}.xyz | gmt psxy -R0/230/0/15 -JX-10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc2.0p -Cdynamic_topo_change.cpt -W0.1p,black -K -O >> $psfile
    age=$(($age + 1))
done

# Add title
echo "Cooling Rate Over Time by Change in Dynamic Topography" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Dynamic Topography
gmt psscale -Cdynamic_topo_change.cpt -Dx2c/1c+w10c/0.5c+efb -Ba5f1:"Change in Dynamic Topography [m/Ma]": -O -X10c -Y-2c >> $psfile 

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DLoop_Figures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DLoop_Figures
gmt psconvert $psfile -TG -A -DLoop_Figures




### Make plot of cooling rate v time, coloured by change in dynamic topography, for all data, for all time steps

# Create a post script file
psfile=cooling_v_time_v_paleoprecipitation_loop__test.ps  

# Add white dummy title to start psfile
echo " " | gmt pstext -R -J -F+f10,Helvetica-Bold,white+cTL -N -K > $psfile

# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0
while (( $age <= 230 ))
    do
        # Make a scatter plot, tempdiff vs time for last 230 Ma; For Central Asia dataset, cooling rates range from ~0-45 C/Ma
        awk -v age=$age '{print age, $3, $6}' thermochron_master_${age}.xyz | gmt psxy -R0/230/0/15 -JX-10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc2.0p -Cpaleoprecip2.cpt -W0.1p,black -K -O >> $psfile
    age=$(($age + 1))
done

# Add title
echo "Cooling Rate Over Time versus Paleoprecipitation" | gmt pstext -R -J -F+f16,Helvetica-Bold,black+cTL -N -Y1c -K -O >> $psfile

# Add scale for Dynamic Topography
gmt psscale -Cpaleoprecip2.cpt -Dx2c/1c+w10c/0.5c+ef -Ba250f50:"Paleoprecipitation [m/yr]": -O -X10c -Y-2c >> $psfile 

# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -DLoop_Figures # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -DLoop_Figures
gmt psconvert $psfile -TG -A -DLoop_Figures


exit





