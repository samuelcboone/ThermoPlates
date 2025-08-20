#!/bin/bash

# Do only once: chmod +rwx 07_RvAge.sh  # Gives read, write, execute permission for script 

OUTDIR="R_vs_Age"
FIG="$OUTDIR/R_v_Age_Figures"
DAT="$OUTDIR/Data"
mkdir -p "$FIG" "$DAT"

R1="$DAT/r_cooling_vs_dyntopo.txt"     # age  r
R2="$DAT/r_cooling_vs_dDT.txt"         # age  r
R3="$DAT/r_cooling_vs_ppt.txt"         # age  r
: > "$R1"; : > "$R2"; : > "$R3"

# ---------------------------
# Loop ages and compute r for each pair per age file
# ---------------------------
for age in $(seq 0 230); do
  f="thermochron_master_${age}.xyz"
  if [[ -s "$f" ]]; then
    # One awk pass computes r for (3,4), (3,5), (3,6)
    res=$(awk '
	function isnum(s){
	  # Accept finite decimal/scientific numbers only
	  return (s ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/)
	}
	function finish(sx,sy,sxx,syy,sxy,n,  num,den){
	  if (n < 2) return "NaN"
	  num = n*sxy - sx*sy
	  den = sqrt((n*sxx - sx*sx) * (n*syy - sy*sy))
	  if (den == 0) return "NaN"
	  return num/den
	}
	BEGIN{
	  n1=n2=n3=0
	  sx1=sy1=sxx1=syy1=sxy1=0
	  sx2=sy2=sxx2=syy2=sxy2=0
	  sx3=sy3=sxx3=syy3=sxy3=0
	}
	{
	  # REQUIRE col 3 to be numeric; otherwise skip the row entirely
	  if (!isnum($3)) next
	  x=$3; y1=$4; y2=$5; y3=$6
	
	  if (isnum(y1)) { n1++; sx1+=x; sy1+=y1; sxx1+=x*x; syy1+=y1*y1; sxy1+=x*y1 }
	  if (isnum(y2)) { n2++; sx2+=x; sy2+=y2; sxx2+=x*x; syy2+=y2*y2; sxy2+=x*y2 }
	  if (isnum(y3)) { n3++; sx3+=x; sy3+=y3; sxx3+=x*x; syy3+=y3*y3; sxy3+=x*y3 }
	}
	END{
	  r1 = finish(sx1,sy1,sxx1,syy1,sxy1,n1)  # cooling vs dyn. topo (3,4)
	  r2 = finish(sx2,sy2,sxx2,syy2,sxy2,n2)  # cooling vs Δdyn. topo (3,5)
	  r3 = finish(sx3,sy3,sxx3,syy3,sxy3,n3)  # cooling vs paleoprecip (3,6)
	  printf("%s %s %s\n", r1, r2, r3)
	}' "$f")
    

    read -r r12 r13 r14 <<< "$res"
  else
    r12="NaN"; r13="NaN"; r14="NaN"
    echo "Skipping missing/empty file: $f" >&2
  fi

  printf "%d %s\n" "$age" "$r12" >> "$R1"
  printf "%d %s\n" "$age" "$r13" >> "$R2"
  printf "%d %s\n" "$age" "$r14" >> "$R3"
done

# ---------------------------
# Plot: three panels of r vs age (modern mode)
# ---------------------------
gmt begin "$FIG/pearson_r_vs_age" png,pdf
  gmt gmtset MAP_FRAME_TYPE=plain FONT_LABEL=12p FONT_ANNOT_PRIMARY=10p

  # Common region/projection for all panels
  R="-R0/230/-1/1"
  J="-JX-16c/5c"

  gmt subplot begin 3x1 -Fs16c/5c -M0c/1.5c -A -BWSen

    # Panel 1: r(cooling, dyn. topo)
    gmt subplot set 0
    gmt basemap $R $J -Bxa50f10+l"Age (Ma)" -Bya0.5f0.1+l"Pearson Coefficient (r)" -B+t"Cooling vs Dynamic Topography"
    echo "0 0\n230 0" | gmt plot -W0.75p,gray,-
    gmt plot "$R1" -Sc0.12c -W0.25p,midnightblue

    # Panel 2: r(cooling, Δdyn. topo)
    gmt subplot set 1
    gmt basemap $R $J -Bxa50f10+l"Age (Ma)" -Bya0.5f0.1+l"Pearson Coefficient (r)" -B+t"Cooling vs Change in Dynamic Topography"
    echo "0 0\n230 0" | gmt plot -W0.75p,gray,-
    gmt plot "$R2" -Sc0.12c -W0.25p,tomato3

    # Panel 3: r(cooling, paleoprecip)
    gmt subplot set 2
    gmt basemap $R $J -Bxa50f10+l"Age (Ma)" -Bya0.5f0.1+l"Pearson Coefficient (r)" -B+t"Cooling vs Paleoprecipitation"
    echo "0 0\n230 0" | gmt plot -W0.75p,gray,-
    gmt plot "$R3" -Sc0.12c -W0.25p,burlywood3

  gmt subplot end
gmt end show

echo "Wrote:"
echo "  $R1"
echo "  $R2"
echo "  $R3"
echo "Figures in: $FIG"


exit