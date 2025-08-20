#!/bin/bash

# Do only once: chmod +rwx 08_MeansvAge.sh  # Gives read, write, execute permission for script 



OUTDIR="Means_vs_Age"
FIGDIR="$OUTDIR/Figures"
mkdir -p "$OUTDIR" "$FIGDIR"

IN="$OUTDIR/stats_by_age.txt"

# ---------- Build stats_by_age.txt (0..230) ----------
printf "age mean_cooling sd_cooling mean_dyntopo sd_dyntopo mean_dDT sd_dDT mean_ppt sd_ppt\n" > "$IN"

for age in $(seq 0 230); do
  f="thermochron_master_${age}.xyz"
  if [[ -s "$f" ]]; then
    awk -v AGE="$age" '
    function isnum(s){ return (s ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) }
    BEGIN{ n3=n4=n5=n6=0; s3=s4=s5=s6=0; ss3=ss4=ss5=ss6=0 }
    {
      # require valid cooling (col 3) to keep the row
      if (!isnum($3)) next
      v3=$3; v4=$4; v5=$5; v6=$6
      if (isnum(v3)) { n3++; s3+=v3; ss3+=v3*v3 }
      if (isnum(v4)) { n4++; s4+=v4; ss4+=v4*v4 }
      if (isnum(v5)) { n5++; s5+=v5; ss5+=v5*v5 }
      if (isnum(v6)) { n6++; s6+=v6; ss6+=v6*v6 }
    }
    END{
      m3 = (n3>0)? s3/n3 : "NaN"
      m4 = (n4>0)? s4/n4 : "NaN"
      m5 = (n5>0)? s5/n5 : "NaN"
      m6 = (n6>0)? s6/n6 : "NaN"
      if (n3>1){ v=ss3 - s3*s3/n3; if (v<0) v=0; sd3=sqrt(v/(n3-1)) } else sd3="NaN"
      if (n4>1){ v=ss4 - s4*s4/n4; if (v<0) v=0; sd4=sqrt(v/(n4-1)) } else sd4="NaN"
      if (n5>1){ v=ss5 - s5*s5/n5; if (v<0) v=0; sd5=sqrt(v/(n5-1)) } else sd5="NaN"
      if (n6>1){ v=ss6 - s6*s6/n6; if (v<0) v=0; sd6=sqrt(v/(n6-1)) } else sd6="NaN"
      printf("%d %s %s %s %s %s %s %s %s\n", AGE, m3, sd3, m4, sd4, m5, sd5, m6, sd6)
    }' "$f" >> "$IN"
  else
    printf "%d NaN NaN NaN NaN NaN NaN NaN NaN\n" "$age" >> "$IN"
  fi
done

# ---------- Helpers to get Y ranges from mean±sd ----------
isnum_awk='function isnum(s){return (s ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/)}'
yrange_pm_sd() {
  awk -v m="$1" -v s="$2" '
  '"$isnum_awk"'
  NR==1{next}
  {
    if (isnum($m)) {
      mm=$m; ss=(isnum($s)?$s:0)
      lo=mm-ss; hi=mm+ss
      if (!have || lo<min) min=lo
      if (!have || hi>max) max=hi
      have=1
    }
  }
  END{
    if (!have) {print "0 1"; exit}
    d=max-min; if (d<=0) d=1
    printf("%.15g %.15g\n", min-0.05*d, max+0.05*d)
  }' "$IN"
}

read yCmin yCmax   < <(yrange_pm_sd 2 3)   # cooling
read yDmin yDmax   < <(yrange_pm_sd 4 5)   # dyn topo
read yXmin yXmax   < <(yrange_pm_sd 6 7)   # Δ dyn topo
read yPmin yPmax   < <(yrange_pm_sd 8 9)   # precip

gmt set MAP_FRAME_TYPE=plain FONT_LABEL=12p FONT_ANNOT_PRIMARY=10p MAP_LABEL_OFFSET=8p MAP_TITLE_OFFSET=10p

# ---------- Plot 1: Cooling (left) & Precip (right) ----------
gmt begin "$FIGDIR/means_cooling_vs_precip" png,pdf
  # Left axis (Cooling) — FULL -J each time in modern mode
  gmt basemap -R0/230/0/$yCmax -JX-16c/8c -BWSen -Bxa50f10+l"Age [Ma]" -Byaf+l"@;dodgerblue4;Cooling Rate [@.C/Ma]@;;"
  gmt plot "$IN" -h1 -i0,1,2 -Sc0.14c -Gdodgerblue4 -W0.25p,black -Ey+w0.1c
  # Right axis (Precip)
  gmt basemap -R0/230/$yPmin/$yPmax -JX-16c/8c -BNE -Byaf+l"@;burlywood3;Paleoprecipitation [m/yr]@;;"
  gmt plot "$IN" -h1 -i0,7,8 -Sc0.14c -Gburlywood3 -W0.25p,black -Ey+w0.1c
gmt end show

# ---------- Plot 2: Cooling (left) & Dynamic Topography (right) ----------
gmt begin "$FIGDIR/means_cooling_vs_dyntopo" png,pdf
  gmt basemap -R0/230/0/$yCmax -JX-16c/8c -BWSen -Bxa50f10+l"Age [Ma]" -Byaf+l"@;dodgerblue4;Cooling Rate [@.C/Ma]@;;"
  gmt plot "$IN" -h1 -i0,1,2 -Sc0.14c -Gdodgerblue4 -W0.25p,black -Ey+w0.1c
  gmt basemap -R0/230/$yDmin/$yDmax -JX-16c/8c -BNE -Byaf+l"@;midnightblue;Dynamic Topography [m]@;;"
  gmt plot "$IN" -h1 -i0,3,4 -Sc0.14c -Gmidnightblue -W0.25p,black -Ey+w0.1c
gmt end show

# ---------- Plot 3: Cooling (left) & Δ Dynamic Topography (right) ----------
gmt begin "$FIGDIR/means_cooling_vs_delta_dyntopo" png,pdf
  gmt basemap -R0/230/0/$yCmax -JX-16c/8c -BWSen -Bxa50f10+l"Age [Ma]" -Byaf+l"@;dodgerblue4;Cooling Rate [@.C/Ma]@;;"
  gmt plot "$IN" -h1 -i0,1,2 -Sc0.14c -Gdodgerblue4 -W0.25p,black -Ey+w0.1c
  gmt basemap -R0/230/$yXmin/$yXmax -JX-16c/8c -BNE -Byaf+l"@;tomato3;@~\104@~ Dynamic Topography [m/Ma]@;;"
  gmt plot "$IN" -h1 -i0,5,6 -Sc0.14c -Gtomato3 -W0.25p,black -Ey+w0.1c
gmt end show





# =========================
# Scatter of per-age MEANS
# =========================

# Helpers: min/max from a single mean column; Pearson r between two mean columns
minmax_col() {
  # $1: column index (1-based) in $IN
  awk -v c="$1" '
  '"$isnum_awk"'
  NR==1{next}
  isnum($c){
    if (!have || $c<min) min=$c
    if (!have || $c>max) max=$c
    have=1
  }
  END{
    if (!have) {print "0 1"; exit}
    d=max-min; if (d<=0) d=1
    printf("%.15g %.15g\n", min-0.05*d, max+0.05*d)
  }' "$IN"
}

pearson_cols() {
  # $1: x column (mean), $2: y column (mean)
  awk -v cx="$1" -v cy="$2" '
  '"$isnum_awk"'
  NR==1{next}
  {
    x=$cx; y=$cy
    if (isnum(x) && isnum(y)) {
      n++; sx+=x; sy+=y; sxx+=x*x; syy+=y*y; sxy+=x*y
    }
  }
  END{
    if (n<2) { print "NaN 0"; exit }
    num = n*sxy - sx*sy
    den = sqrt((n*sxx - sx*sx)*(n*syy - sy*sy))
    if (den==0) { printf("NaN %d\n", n); exit }
    printf("%.6f %d\n", num/den, n)
  }' "$IN"
}

# ---------- Plot A: mean Cooling vs mean Dynamic Topography ----------
read xMin xMax < <(minmax_col 4)   # mean dyn topo
read yMin yMax < <(minmax_col 2)   # mean cooling  
read rA nA   < <(pearson_cols 4 2)
lx=$(awk -v a="$xMin" -v b="$xMax" 'BEGIN{print a+0.05*(b-a)}')
ly=$(awk -v a="$yMin" -v b="$yMax" 'BEGIN{print b-0.05*(b-a)}')
if [[ "$rA" == "NaN" || -z "$rA" ]]; then lblA="r = n/a (n = $nA)"; else printf -v lblA "r = %+0.3f (n = %d)" "$rA" "$nA"; fi

gmt begin "$FIGDIR/scatter_mean_cooling_vs_mean_dyntopo" png,pdf
  gmt basemap -R-650/-350/0/1.5 -JX12c/10c -BWSen \
              -Bxa+l"Mean Dynamic Topography [m]" -Bya+l"Mean Cooling Rate [@.C/Ma]"
  gmt plot "$IN" -h1 -i3,1 -Sc0.14c -Gmidnightblue -W0.25p,black
  echo "$lx $ly $lblA" | gmt text -R-650/-350/0/1.5 -JX12c/10c -F+f12p,Helvetica,black+jTL -Y3c -N
gmt end show

# ---------- Plot B: mean Cooling vs mean Δ Dynamic Topography ----------
read xMin xMax < <(minmax_col 6)   # mean Δ dyn topo
read yMin yMax < <(minmax_col 2)   # mean cooling
read rB nB   < <(pearson_cols 6 2)
lx=$(awk -v a="$xMin" -v b="$xMax" 'BEGIN{print a+0.05*(b-a)}')
ly=$(awk -v a="$yMin" -v b="$yMax" 'BEGIN{print b-0.05*(b-a)}')
if [[ "$rB" == "NaN" || -z "$rB" ]]; then lblB="r = n/a (n = $nB)"; else printf -v lblB "r = %+0.3f (n = %d)" "$rB" "$nB"; fi

gmt begin "$FIGDIR/scatter_mean_cooling_vs_mean_delta_dyntopo" png,pdf
  gmt basemap -R-20/15/0/1.5 -JX12c/10c -BWSen \
              -Bxa+l"Mean @~\104@~ Dynamic Topography [m/Ma]" -Bya+l"Mean Cooling Rate [@.C/Ma]"
  gmt plot "$IN" -h1 -i5,1 -Sc0.14c -Gseagreen -W0.25p,black
  echo "$lx $ly $lblB" | gmt text -R-20/15/0/3 -JX12c/10c -F+f12p,Helvetica,black+jTL -Y6c -N
gmt end show

# ---------- Plot C: mean Cooling vs mean Paleoprecipitation ----------
read xMin xMax < <(minmax_col 8)   # mean ppt
read yMin yMax < <(minmax_col 2)   # mean cooling
read rC nC   < <(pearson_cols 8 2)
lx=$(awk -v a="$xMin" -v b="$xMax" 'BEGIN{print a+0.05*(b-a)}')
ly=$(awk -v a="$yMin" -v b="$yMax" 'BEGIN{print b-0.05*(b-a)}')
if [[ "$rC" == "NaN" || -z "$rC" ]]; then lblC="r = n/a (n = $nC)"; else printf -v lblC "r = %+0.3f (n = %d)" "$rC" "$nC"; fi

gmt begin "$FIGDIR/scatter_mean_cooling_vs_mean_ppt" png,pdf
  gmt basemap -R0.2/1/0/1.5 -JX12c/10c -BWSen \
              -Bxa+l"Mean Paleoprecipitation [m/yr]" -Bya+l"Mean Cooling Rate [@.C/Ma]"
  gmt plot "$IN" -h1 -i7,1 -Sc0.14c -Gburlywood3 -W0.25p,black
  echo "$lx $ly $lblC" | gmt text -R0.2/1/0/1.5 -JX12c/10c -F+f12p,Helvetica,black+jTL -Y3c -N
gmt end show


echo "Done. Figures in: $FIGDIR"
