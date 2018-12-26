# pih-ncl-scripts
NCL scripts to create WRF graphics.
The scripts herein are for post-processed WRF graphics. You will need to modify the NCL scripts
to reflect the location of your WRF NetCDF output files and domain, etc.

- cities1.txt : Lat, Lon, City Name -- that is, if you want to plot cities on your maps
- cities2.txt: Same as above, but for inner domain (if you have one)
- temp.ncl : Script will produce surface temperature graphics from WRF output.
- slp.ncl : MSLP/Precip Wind plots. 
- pressure.ncl : Height/Winds/RH at various pressure levels.
- snow.ncl : Snow from ACSNOW * SLR -- use with caution
- radar.ncl : Model Composite reflectivity
- cape.ncl : Model CAPE and CIN output
