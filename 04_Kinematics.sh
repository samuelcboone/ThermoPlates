#!/bin/bash

# Do only once: chmod +rwx 04_Kinematics.sh  # Gives read, write, execute permission for script 

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT=10p,black MAP_FRAME_PEN=thin,black FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_DEFAULT_PEN=0.25p,black MAP_GRID_PEN=0.25p,black MAP_TICK_PEN=0.25p,black 

### Uses the kinematics_master.xyz file generated with the 02_Thermochron_GPlates.sh and generates a series of scatter plots to compare trends in cooling histories 
### through time with the results from the plate tectonic and subduction kinematics (Figs. 6b-6d, ED4 & ED5b-ED5d in Boone et al., 2025) and fault analysis (Figs. 5b-5c in Boone et al., 2025)



### Prompt user to provide new directory name base ###

read -p "What would you like to call your new output directory for this script? " directory

directory_name="Kinematics_$directory"

mkdir -v -m777 $directory_name




# Define variables
kinematics_master=kinematics_master.xyz

# NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
# mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
# mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
# mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28), mean fault azimuth ($29)



### Extracting cooling histories for each region and making new .xyz files
# Overall Central Asia cooling
awk '{print $1, $2, $3}' $kinematics_master > central_asia.xyz
# Tian Shan cooling
awk '{print $1, $4, $5}' $kinematics_master > tian_shan.xyz
# Altai cooling
awk '{print $1, $6, $7}' $kinematics_master > altai.xyz

### Extracting convergence and migration rates and making new .xyz files
# Orthogonal convergence rate
awk '($20 < 15) {print $1, $20, $21}' $kinematics_master > ortho_convergence.xyz
# Orthogonal migration rate
awk '{print $1, $18, $19}' $kinematics_master > ortho_migration.xyz
# Convergence rate
awk '($8 >= 0) {print $1, $8, $9}' $kinematics_master > convergence.xyz
# Migration rate
awk '{print $1, $12, $13}' $kinematics_master > migration.xyz

# Convergence obliquity
awk '{print $1, $10, $11}' $kinematics_master > convergence_obliquity.xyz
# Mean convergence azimuth
awk '{print $1, $28}' $kinematics_master > convergence_azimuth.xyz
# Migration obliquity
awk '{print $1, $14, $15}' $kinematics_master > migration_obliquity.xyz
# Mean migration azimuth
awk '{print $1, $27}' $kinematics_master > migration_azimuth.xyz



### Make a 1x3 series of plots showing the relationship between crustal cooling, convergence and convergence obliquity

# Create a post script file
psfile=cooling_vs_convergence.ps

# !!!!!! Need to add a key for each plot

# Plot showing Convergence Obliquity and Convergence Azimuth v time
# NOTE: Trench convergence obliquity is relative to the orthogonal convergence azimuth of the underriding plate

# Plot convergence obliquity - Add -Ey+w1p to add error bars
gmt psxy convergence_obliquity.xyz -R0/230/-180/180 -JX-10c/10c -Ba20f5:"Time [Ma]":/a30f10:"Convergence Obliquity [@.]":WS -Sc2p -Ey+w1p -Gred4 -W0.05p,snow3 -K > $psfile 

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d convergence_obliquity.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R -J -W1p,tomato3 -K -O >> $psfile
#gmt psxy convergence_obliquity.xyz -R -J -Sc1.5p -Gred4 -K -O >> $psfile


# New plot above the last one showing Convergence and Orthogonal Convergence Rates v time

# Plot mode orthogonal convergence - Add -Ey+w1p to add error bars
gmt psxy ortho_convergence.xyz -R0/230/0/15 -JX-10c/10c -Ba20f5:"Time [Ma]":S -Sc2p -Gcoral1 -W0.05p,snow3 -Y12c -K -O >> $psfile # -Ey+w1p
# Plot mode convergence
gmt psxy convergence.xyz -R -J -Ba5f1:"Convergence Rate [cm/yr]":E --FONT_LABEL=dodgerblue1 -Sc2p -Gdodgerblue1 -W0.05p,snow3 -K -O >> $psfile # -Ey+w1p

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d ortho_convergence.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R -J  -Ba5f1:"Orthogonal Convergence Rate [cm/yr]":W --FONT_LABEL=darkred -W1p,firebrick -K -O >> $psfile
gmt psxy ortho_convergence.xyz -R -J -Sc2p -Gcoral1 -Ba5f1:"Orthogonal Convergence Rate [cm/yr]":W --FONT_LABEL=coral1 -K -O >> $psfile

#gmt trend1d convergence.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R -J -W1p,springgreen1 -K -O >> $psfile
#gmt psxy convergence.xyz -R -J -Sc1.5p -Gspringgreen4 -K -O >> $psfile


# Plot mean overall cooling rates - Add -Ey+w1p to add error bars
#gmt psxy central_asia.xyz -R70/100/0/3.5 -JX10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc1p -Gdodgerblue4 -Ey+w1p -W0.05p,snow3 -K > $psfile
# Plot mean Tian Shan cooling rates
#gmt psxy tian_shan.xyz -R -J -Sc1p -Gcadetblue -Ey+w1p -W0.05p,snow3 -K -O >> $psfile
# Plot mean Altai cooling rates
#gmt psxy altai.xyz -R -J -Sc1p -Gseagreen -Ey+w1p -W0.05p,snow3 -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d central_asia.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y12c -K -O >> $psfile
gmt psxy central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -D$directory_name # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -D$directory_name
gmt psconvert $psfile -TG -A -D$directory_name





### Make a 1x3 series of plots showing the relationship between crustal cooling, migration and migration obliquity

# Create a post script file
psfile=cooling_vs_migration.ps

# !!!!!! Need to add a key for each plot

# Plot showing Migration Obliquity and Migration Azimuth v time
# NOTE: Trench migration obliquity is relative to the orthogonal convergence azimuth of the underriding plate

# Plot migration obliquity - Add -Ey+w1p to add error bars
gmt psxy migration_obliquity.xyz -R0/230/-180/180 -J -Ba20f5:"Time [Ma]":/a30f10:"Trench Migration Obliquity [@.]":WS -Sc2p -Ey+w1p -Gred4 -W0.05p,snow3 -K > $psfile 

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d migration_obliquity.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,tomato3 -K -O >> $psfile
#gmt psxy migration_obliquity.xyz -R -J -Sc1.5p -Gred4 -K -O >> $psfile


# New plot above the last one showing Migration and Orthogonal Migration Rates v time

# Plot mode orthogonal migration - Add -Ey+w1p to add error bars
gmt psxy ortho_migration.xyz -R0/230/-12/12 -JX-10c/10c -Ba20f5:"Time [Ma]":S -Sc2p -Gfirebrick -Ey+w1p -W0.05p,snow3 -Y12c -K -O >> $psfile
# Plot mode migration
gmt psxy migration.xyz -R -J -Ba5f1:"Trench Retreat [cm/yr]":E --FONT_LABEL=springgreen4 -Sc2p -Gspringgreen4 -Ey+w1p -W0.05p,snow3 -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d ortho_migration.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -Ba5f1:"Orthogonal Trench Retreat [cm/yr]":W --FONT_LABEL=darkred -W1p,firebrick -K -O >> $psfile
gmt psxy ortho_migration.xyz -R -J  -Sc2p -Gfirebrick -Ba5f1:"Orthogonal Trench Retreat [cm/yr]":W --FONT_LABEL=firebrick -K -O >> $psfile

#gmt trend1d migration.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,springgreen1 -K -O >> $psfile
#gmt psxy migration.xyz -R -J -Sc1.5p -Gspringgreen4 -K -O >> $psfile



# Plot mean overall cooling rates - Add -Ey+w1p to add error bars
#gmt psxy central_asia.xyz -R70/100/0/3.5 -JX10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc1p -Gdodgerblue4 -Ey+w1p -W0.05p,snow3 -K > $psfile
# Plot mean Tian Shan cooling rates
#gmt psxy tian_shan.xyz -R -J -Sc1p -Gcadetblue -Ey+w1p -W0.05p,snow3 -K -O >> $psfile
# Plot mean Altai cooling rates
#gmt psxy altai.xyz -R -J -Sc1p -Gseagreen -Ey+w1p -W0.05p,snow3 -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d central_asia.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y12c -K -O >> $psfile
gmt psxy central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -D$directory_name # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -D$directory_name
gmt psconvert $psfile -TG -A -D$directory_name




### Make a 1x3 series of plots showing the relationship between crustal cooling, 'reactivated' faults, plate motion azimuth and velocity, and arc azimuth 

# NOTE: kinematics_master.xyz now has structure of age ($1), mean overall (Central Asia) cooling rate ($2), std overall (Central Asia) cooling rate ($3), mean Tian Shan cooling rate ($4), std Tian Shan cooling rate ($5), mean Altai cooling rate ($6), std Altai cooling rate ($7)
# mode convergence rate ($8), convergence rate std ($9), mode convergence obliquity ($10), convergence obliquity std ($11), mode migration rate ($12), migration rate std ($13), mode migration obliquity ($14), migration obliquity std ($15), 
# mean distance to continent ($16), distance to continent std ($17), mode orthogonal migration rate ($18), orthogonal migration rate std ($19), mode orthogonal convergence rate ($20), orthogonal convergence rate std ($21), total arc length in m ($22), 
# mean plate velocity ($23), std plate velocity ($24), mean plate velocity azimuth ($25), mean arc azimuth ($26), mean arc migration azimuth ($27), mean convergence azimuth ($28), mean fault azimuth ($29)



### Extracting relevant data from $kinematics_master
# 'Reactivated' fault azimuths
awk '($29 != NaN) {print $1, $29}' $kinematics_master > reactivated_faults.xyz
# Plate motion
awk '($23 < 12) {print $1, $23, $24}' $kinematics_master > plate_velocities.xyz
# Plate motion azimuths
awk '{print $1, $25}' $kinematics_master > plate_velocities_azimuths.xyz
# Arc azimuths
awk '{print $1, $26}' $kinematics_master > arc_azimuths.xyz



# Create a post script file
psfile=cooling_vs_faults.ps

# !!!!!! Need to add a key for each plot


# New plot above the last one showing plate motion azimuth and velocity

# Plot mean plate velocity - Add -Ey+w1p to add error bars
gmt psxy plate_velocities.xyz -R0/230/0/12 -JX-10c/10c -Ba20f5:"Time [Ma]":S -Sc2p -Gdarkred -W0.05p,snow3 -K > $psfile # -Ey+w1p 
# Plot plate velocity azimuth
gmt psxy plate_velocities_azimuths.xyz -R0/230/0/360 -JX-10c/10c -Ba30f10:"Plate Motion Azimuth [@.]":E --FONT_LABEL=lightmagenta -Sc2p -Gdeeppink1 -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
#gmt trend1d plate_velocities.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R0/230/0/10 -JX-10c/10c -Ba1f0.1:"Plate Velocity [cm/yr]":W --FONT_LABEL=darkred -W1p,firebrick -K -O >> $psfile
gmt psxy plate_velocities.xyz -R0/230/0/12 -J  -Sc2p -Ba1f0.1:"Plate Velocity [cm/yr]":W --FONT_LABEL=darkred -Gdarkred -K -O >> $psfile

#gmt trend1d plate_velocities_azimuths.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R0/230/0/360 -JX-10c/10c -W1p,lightmagenta -K -O >> $psfile
#gmt psxy plate_velocities_azimuths.xyz -R -J -Sc1.5p -Gdeeppink1 -K -O >> $psfile



# Plot showing fault and arc azimuths v time

# Plot 'reactivated' faults
#gmt trend1d reactivated_faults.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R0/230/0/360 -JX-10c/10c -Ba20f5:"Time [Ma]":S -W1p,tomato3 -Y12c -K -O >> $psfile
gmt psxy reactivated_faults.xyz -R0/230/0/360 -JX-10c/10c -Ba30f10:"Fault Azimuths [@.]":W --FONT_LABEL=tomato3 -Sc2p -Gred4 -Y12c -K -O >> $psfile
gmt psxy reactivated_faults.xyz -R -J -Ba20f5:"Time [Ma]":S -Sc2p -Gred4 -K -O >> $psfile

# Plot arc azimuth
#gmt trend1d arc_azimuths.xyz -Fxm -Np10 -I0.05 -V | gmt psxy -R0/230/0/360 -JX-10c/10c -Ba30f10:"Arc Azimuth [@.]":E --FONT_LABEL=springgreen1 -W1p,springgreen1 -K -O >> $psfile
gmt psxy arc_azimuths.xyz -R -J -Sc1.5p -Ba30f10:"Arc Azimuth [@.]":E --FONT_LABEL=springgreen4 -Gspringgreen4 -K -O >> $psfile



# Plot mean overall cooling rates - Add -Ey+w1p to add error bars
#gmt psxy central_asia.xyz -R70/100/0/3.5 -JX10c/10c -Ba50f10:"Time [Ma]":/a5f1:"Cooling Rate [@.C/Ma]":WSne -Sc1p -Gdodgerblue4 -Ey+w1p -W0.05p,snow3 -K > $psfile
# Plot mean Tian Shan cooling rates
#gmt psxy tian_shan.xyz -R -J -Sc1p -Gcadetblue -Ey+w1p -W0.05p,snow3 -K -O >> $psfile
# Plot mean Altai cooling rates
#gmt psxy altai.xyz -R -J -Sc1p -Gseagreen -Ey+w1p -W0.05p,snow3 -K -O >> $psfile

# Now plotting trendlines and replotting points (without error bars) to be on top of error bars
gmt trend1d central_asia.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R0/230/0/5 -JX-10c/10c -Ba20f5:"Time [Ma]":/a1f0.1:"Cooling Rate [@.C/Ma]":WS  -W1p,dodgerblue1 -Y12c -K -O >> $psfile
gmt psxy central_asia.xyz -R -J  -Sc2p -Gdodgerblue4 -K -O >> $psfile

gmt trend1d tian_shan.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,cadetblue2 -K -O >> $psfile
gmt psxy tian_shan.xyz -R -J -Sc2p -Gcadetblue -K -O >> $psfile

gmt trend1d altai.xyz -Fxm -Np11 -I0.05 -V | gmt psxy -R -J -W1p,darkseagreen -K -O >> $psfile
gmt psxy altai.xyz -R -J -Sc2p -Gseagreen -K -O >> $psfile

gmt pstext -R -J -F+f14p,Helvetica,seagreen+cTC+tAltai -Y-8p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,dodgerblue4+cTC+tAll\ of\ Central\ Asia -Y-16p -K -O >> $psfile
gmt pstext -R -J -F+f14p,Helvetica,cadetblue+cTC+tTian\ Shan -Y-16p -O >> $psfile


# Convert postscript file to a jpg, pdf, and png
gmt psconvert $psfile -Tj -A -D$directory_name # Tj is JPG, Tg is png, Tf is pdf # -A will clip to bounding box
gmt psconvert $psfile -Tf -A -D$directory_name
gmt psconvert $psfile -TG -A -D$directory_name


exit