#!/bin/bash

# Do only once: chmod +rwx 06_Correlation_Analysis.sh  # Gives read, write, execute permission for script 

#set -euo pipefail

### Prompt user to provide new directory name base ###

#read -p "What would you like to call your new output directory for this script? " directory
#
#directory_name="Correlation_Analysis_$directory"
#
#mkdir -v -m777 $directory_name
#
#cd $directory_name || exit 1

mkdir -v -m777 Figures

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A0 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=10p MAP_FRAME_PEN=thin,black FONT_LABEL=14p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_DEFAULT_PEN=0.25p,black MAP_GRID_PEN=0.25p,black MAP_TICK_PEN=0.25p,black


gmt makecpt -Crainbow -T0/230/10 -Z -N -D > age.cpt




# NOTE: thermochron_master_${age}.xyz now has structure of long ($1), lat ($2), cooling rate ($3), dynamic topography ($4), change in dynamic topography ($5), paleoprecipitation rate ($6)



# Create a post script and other file
PS=cooling_v_dyntopo_correlation.ps 
TMP=scatter_input.txt
LINE=bestfit_line.txt
STATS=stats.txt
: > "$TMP"


# Draw base frame FIRST (correct -R and -JX; no EPSG confusion)
# X: Dynamic Topography (m) ~ -800..0; Y: Cooling rate (°C/Ma) ~ 0..50
gmt psbasemap -R-800/0/0/25 -JX10c/10c -BWSen \
  -Bxa200f50+l"Dynamic Topography [m]" -Bya5f1+l"Cooling Rate [@.C/Ma]" -K > "$PS"


# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0

while (( age <= 230 )); do
  f="thermochron_master_${age}.xyz"
  if [[ -s "$f" ]]; then
    # x=DT (col4), y=CR (col3), z=age for colour
    awk -v a="$age" '{print $4, $3, a}' "$f" | tee -a "$TMP" | \
      gmt psxy -R -J -Sc2.0p -Cage.cpt -W0.1p,black -K -O >> "$PS"
  else
    >&2 echo "Skipping missing/empty file: $f"
  fi
  ((age++))
done

# Compute best-fit line and Pearson r from all points
awk -v stats="$STATS" '
BEGIN{n=0; sx=sy=sxx=syy=sxy=0; xmin=1e308; xmax=-1e308}
{ x=$1; y=$2; if(x==""||y=="") next;
  n++; sx+=x; sy+=y; sxx+=x*x; syy+=y*y; sxy+=x*y;
  if (x<xmin) xmin=x; if (x>xmax) xmax=x
}
END{
  if(n<2){ print "Not enough data for fit."; exit 1 }
  denx = n*sxx - sx*sx; if(denx==0){ print "Zero X variance."; exit 1 }
  m = (n*sxy - sx*sy)/denx
  b = (sy - m*sx)/n
  num = n*sxy - sx*sy
  den = sqrt((n*sxx - sx*sx)*(n*syy - sy*sy))
  r = (den==0 ? 0 : num/den)

  y1 = m*xmin + b
  y2 = m*xmax + b

  # 2-point line to stdout (goes to $LINE via > redirection)
  printf("%.15g %.15g\n%.15g %.15g\n", xmin, y1, xmax, y2)

  # Save r and n for labeling
  printf("%.6f %d\n", r, n) > stats
}' "$TMP" > "$LINE"

# Plot best-fit line
gmt psxy "$LINE" -R -J -W1.5p,black -K -O >> "$PS"

# Label Pearson r (normalized 0–1 box just below the title)
read R N < "$STATS"
printf "0.02 0.98 r = %+.3f (n = %d)\n" "$R" "$N" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f12p,Helvetica,black+jTL -N -K -O >> "$PS"

# Title (normalized 0–1 box to avoid coord headaches)
echo "0.02 1.03 Cooling versus Dynamic Topography" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f16p,Helvetica-Bold,black+jTL -N -Y1c -K -O >> "$PS"

# Colorbar for age
gmt psscale -Cage.cpt -Dx2c/1c+w10c/0.5c+efb -Bxa50f10+l"Age (Ma)" -Y-2c -X9c -O >> "$PS"


# Export
gmt psconvert "$PS" -Tj -A -DFigures
gmt psconvert "$PS" -Tf -A -DFigures
gmt psconvert "$PS" -TG -A -DFigures






# Create a post script and other file
PS=cooling_v_dyntopochange_correlation.ps 
TMP=scatter_input.txt
LINE=bestfit_line.txt
STATS=stats.txt
: > "$TMP"


# Draw base frame FIRST (correct -R and -JX; no EPSG confusion)
# X: Dynamic Topography (m) ~ -5..5; Y: Cooling rate (°C/Ma) ~ 0..50
gmt psbasemap -R-5/5/0/25 -JX10c/10c -BWSen \
  -Bxa1f0.1+l"@~\104@~ Dynamic Topography [m/Ma]" -Bya5f1+l"Cooling Rate [@.C/Ma]" -K > "$PS"

# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0

while (( age <= 230 )); do
  f="thermochron_master_${age}.xyz"
  if [[ -s "$f" ]]; then
    # x=DT (col4), y=CR (col3), z=age for colour
    awk -v a="$age" '{print $5, $3, a}' "$f" | tee -a "$TMP" | \
      gmt psxy -R -J -Sc2.0p -Cage.cpt -W0.1p,black -K -O >> "$PS"
  else
    >&2 echo "Skipping missing/empty file: $f"
  fi
  ((age++))
done


# Compute best-fit line and Pearson r from all points
awk -v stats="$STATS" '
BEGIN{n=0; sx=sy=sxx=syy=sxy=0; xmin=1e308; xmax=-1e308}
{ x=$1; y=$2; if(x==""||y=="") next;
  n++; sx+=x; sy+=y; sxx+=x*x; syy+=y*y; sxy+=x*y;
  if (x<xmin) xmin=x; if (x>xmax) xmax=x
}
END{
  if(n<2){ print "Not enough data for fit."; exit 1 }
  denx = n*sxx - sx*sx; if(denx==0){ print "Zero X variance."; exit 1 }
  m = (n*sxy - sx*sy)/denx
  b = (sy - m*sx)/n
  num = n*sxy - sx*sy
  den = sqrt((n*sxx - sx*sx)*(n*syy - sy*sy))
  r = (den==0 ? 0 : num/den)

  y1 = m*xmin + b
  y2 = m*xmax + b

  # 2-point line to stdout (goes to $LINE via > redirection)
  printf("%.15g %.15g\n%.15g %.15g\n", xmin, y1, xmax, y2)

  # Save r and n for labeling
  printf("%.6f %d\n", r, n) > stats
}' "$TMP" > "$LINE"

# Plot best-fit line
gmt psxy "$LINE" -R -J -W1.5p,black -K -O >> "$PS"

# Label Pearson r (normalized 0–1 box just below the title)
read R N < "$STATS"
printf "0.02 0.98 r = %+.3f (n = %d)\n" "$R" "$N" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f12p,Helvetica,black+jTL -N -K -O >> "$PS"

# Title (normalized 0–1 box to avoid coord headaches)
echo "0.02 1.03 Cooling versus @~\104@~ Dynamic Topography" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f16p,Helvetica-Bold,black+jTL -N -Y1c -K -O >> "$PS"

# Colorbar for age
gmt psscale -Cage.cpt -Dx2c/1c+w10c/0.5c+efb -Bxa50f10+l"Age (Ma)" -Y-2c -X9c -O >> "$PS"


# Export
gmt psconvert "$PS" -Tj -A -DFigures
gmt psconvert "$PS" -Tf -A -DFigures
gmt psconvert "$PS" -TG -A -DFigures







# Create a post script and other file
PS=cooling_v_precip_correlation.ps 
TMP=scatter_input.txt
LINE=bestfit_line.txt
STATS=stats.txt
: > "$TMP"


# Draw base frame FIRST (correct -R and -JX; no EPSG confusion)
# X: Dynamic Topography (m) ~ -800..0; Y: Cooling rate (°C/Ma) ~ 0..50
gmt psbasemap -R0/2/0/25 -JX10c/10c -BWSen \
  -Bxa1f0.1+l"Paleoprecipitation [m/yr]" -Bya5f1+l"Cooling Rate [@.C/Ma]" -K > "$PS"


# Run loop through defined time steps (in Myr intervals), plotting data for each time step #
age=0

while (( age <= 230 )); do
  f="thermochron_master_${age}.xyz"
  if [[ -s "$f" ]]; then
    # x=DT (col4), y=CR (col3), z=age for colour
    awk -v a="$age" '{print $6, $3, a}' "$f" | tee -a "$TMP" | \
      gmt psxy -R -J -Sc2.0p -Cage.cpt -W0.1p,black -K -O >> "$PS"
  else
    >&2 echo "Skipping missing/empty file: $f"
  fi
  ((age++))
done


# Compute best-fit line and Pearson r from all points
awk -v stats="$STATS" '
BEGIN{n=0; sx=sy=sxx=syy=sxy=0; xmin=1e308; xmax=-1e308}
{ x=$1; y=$2; if(x==""||y=="") next;
  n++; sx+=x; sy+=y; sxx+=x*x; syy+=y*y; sxy+=x*y;
  if (x<xmin) xmin=x; if (x>xmax) xmax=x
}
END{
  if(n<2){ print "Not enough data for fit."; exit 1 }
  denx = n*sxx - sx*sx; if(denx==0){ print "Zero X variance."; exit 1 }
  m = (n*sxy - sx*sy)/denx
  b = (sy - m*sx)/n
  num = n*sxy - sx*sy
  den = sqrt((n*sxx - sx*sx)*(n*syy - sy*sy))
  r = (den==0 ? 0 : num/den)

  y1 = m*xmin + b
  y2 = m*xmax + b

  # 2-point line to stdout (goes to $LINE via > redirection)
  printf("%.15g %.15g\n%.15g %.15g\n", xmin, y1, xmax, y2)

  # Save r and n for labeling
  printf("%.6f %d\n", r, n) > stats
}' "$TMP" > "$LINE"

# Plot best-fit line
gmt psxy "$LINE" -R -J -W1.5p,black -K -O >> "$PS"

# Label Pearson r (normalized 0–1 box just below the title)
read R N < "$STATS"
printf "0.02 0.98 r = %+.3f (n = %d)\n" "$R" "$N" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f12p,Helvetica,black+jTL -N -K -O >> "$PS"

# Title (normalized 0–1 box to avoid coord headaches)
echo "0.02 1.03 Cooling versus Paleoprecipitation" | \
  gmt pstext -R0/1/0/1 -JX10c/10c -F+f16p,Helvetica-Bold,black+jTL -N -Y1c -K -O >> "$PS"

# Colorbar for age
gmt psscale -Cage.cpt -Dx2c/1c+w10c/0.5c+efb -Bxa50f10+l"Age (Ma)" -Y-2c -X9c -O >> "$PS"


# Export
gmt psconvert "$PS" -Tj -A -DFigures
gmt psconvert "$PS" -Tf -A -DFigures
gmt psconvert "$PS" -TG -A -DFigures

exit