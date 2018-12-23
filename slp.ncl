; Generic template for producing WRF graphics.
; Read CSV file of cities with "City","Lat","Lon"
; Plot WRF variable
;	Plot cities on map
;	Plot value under city

begin
; First, let's set some variables. This will dictate how our image files
; are named. 
	domain = "d02_"
	domname = "ind_"
	prod = "mslp"

; Now, let's load some NetCDF files from our WRF.
	dir = "/wrf/uems/runs/ind/wrfprd/"
        fils = systemfunc("ls "+dir+"wrfout_"+domain+"*")
	a = addfiles(fils+".nc","r")

; On to reading the "cities1.txt" or "cities2.txt" file to plot cities on the map.
	index = str_get_cols(domain,2,2)
	cities = asciiread("cities"+index+".txt",-1,"string")
	delim = ","
	lat = tofloat(str_get_field(cities,1,delim))
	lon = tofloat(str_get_field(cities,2,delim))
	city = str_get_field(cities,3,delim)

; Import attributes from the netCDF file or bad things will happen
; in the next section.
	locres = True
	locres@MAP_PROJ = a[0]@MAP_PROJ 
	locres@TRUELAT1 = a[0]@TRUELAT1
	locres@TRUELAT2 = a[0]@TRUELAT2
	locres@STAND_LON = a[0]@STAND_LON
	locres@REF_LAT = a[0]@CEN_LAT
	locres@REF_LON = a[0]@CEN_LON
	locres@KNOWNI = a[0]@$"WEST-EAST_GRID_DIMENSION"$/2 
	locres@KNOWNJ = a[0]@$"SOUTH-NORTH_GRID_DIMENSION"$/2
	locres@DX = a[0]@DX
	locres@DY = a[0]@DY

; Convert WRF lat/lon to NCL-friendly coordinates.
	loc = wrf_ll_to_ij(lon,lat,locres)
	lo = toint(loc(0,:))
	la = toint(loc(1,:))

; Define the file format and the image resolution.
	type = "png"
  	type@wkWidth = 1800
	type@wkHeight = 1200

; Set some basic resources
; Title
  	res = True 
  	res@MainTitle = "Pocatello WRF"

  	pltres = True
	pltres@FramePlot = False

; Map resources
  	mpres = True
  	mpres@mpDataBaseVersion           = "Ncarg4_1"
  	mpres@mpOutlineBoundarySets       = "AllBoundaries"
  	mpres@mpGeophysicalLineColor      = "Black"
  	mpres@mpNationalLineColor         = "Black"
  	mpres@mpUSStateLineColor          = "Black"
  	mpres@mpGridLineColor             = "Black"
  	mpres@mpLimbLineColor             = "Black"
  	mpres@mpPerimLineColor            = "Black"
  	mpres@mpCountyLineColor           = "Brown"
  	mpres@mpCountyLineDashPattern     = 0
  	mpres@mpCountyLineThicknessF      = 0.5
  	mpres@mpGeophysicalLineThicknessF = 3.0
  	mpres@mpGridLineThicknessF        = 0.0
  	mpres@mpLimbLineThicknessF        = 2.0
  	mpres@mpNationalLineThicknessF    = 3.0
  	mpres@mpUSStateLineThicknessF     = 3.0

; What times and how many time steps are in the data set?
	times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
	ntimes = dimsizes(times)         ; number of times in the file


; Start the time loop
  	do it = 0,ntimes-1 
	  print("Working on time: " + times(it) )
	  res@TimeLabel = times(it)   ; Set Valid time to use on plots
	  its = sprintf("%02g",it)

; Creating the workstation environment for the plot, define file name
; and select the colormap.
   wks = gsn_open_wks(type,domain+domname+prod+its+"_syn")
;   gsn_merge_colormaps(wks,"cmocean_gray","precip2_17lev") 
;   gsn_define_colormap(wks,"precip2_17lev")

; What data are we putting on the map?   
   slp = wrf_user_getvar(a,"slp",it)   ; MSLP
   hgt = wrf_user_getvar(a,"ter",it)   ; Terrain
   terrain=hgt*3.281		       ; Convert to ft.
   rainnc = wrf_user_getvar(a,"RAINNC",it); Precip
   rainc = wrf_user_getvar(a,"RAINC",it) ; Some other precip variable
   precip = rainnc + rainc
   if(it .gt. 0) then
    rainnc_old=wrf_user_getvar(a,"RAINNC",it-1)
    rainc_old=wrf_user_getvar(a,"RAINC",it-1)
    precip := precip-rainnc_old-rainc_old
   end if
   pcp = precip*0.0393701 		; Convert to inches   
   u10 = wrf_user_getvar(a,"U10",-1)	; 10m u wind
   v10 = wrf_user_getvar(a,"V10",-1)	; 10m v wind
   u10 = u10* 1.94384
   v10 = v10* 1.94384

; Set resources for these variables.
    slp@description = "Sea Level Pressure"
    slp@units = "hPa"
    terrain@description = "Terrain Height"
    terrain@units = "ft"
    pcp@description = "Precipitation"
    pcp@units = "inches"
    u10@description = "10m Wind"
    u10@units = "Knots"


; Moving label values closer to the color bar.
    res@lbLabelOffsetF = 0.05

; Plotting options for Precip
    opts = res
    opts@ContourParameters = (/0., 0.5, 0.01/)
    opts@SubFieldTitle = "   Max: "+decimalPlaces(max(pcp),2,True)
    opts@Footer = False
    opts@cnFillOn = True
    opts@cnFillPalette = "precip2_17lev"
    contour_precip=wrf_contour(a[it],wks,pcp,opts)
    delete(opts)

; Plotting options for Terrain
    opts = res
    opts@cnFillOn = True
    opts@ContourParameters = (/3000., 13000., 500./)
    opts@cnFillPalette = "MPL_Greys"
    opts@lbLabelsOn = False
    opts@lbLabelBarOn = False
    opts@Footer = False
    contour_terrain=wrf_contour(a[it],wks,terrain,opts)
    delete(opts)

; Plotting options for SLP 
    opts = res                         
    opts@cnLineColor = "Black"
    opts@cnLineThicknessF = 3.0
    opts@SubFieldTitle = "   Max: "+toint(max(slp))+"    Min: "+toint(min(slp))
    opts@Footer = False
    opts@lbBottomMarginF  = -0.2
    opts@ContourParameters = (/ 1 /)
;    opts@gsnSpreadColorEnd = -3  ; End third from the last color in color map
    wrf_smooth_2d(slp,40)
    contour_slp = wrf_contour(a[it],wks,slp,opts)
    delete(opts)  ; delete opts before adding another contour.

; Plotting options for Wind
    opts = res
    opts@Footer = False
    opts@vcLevelColors = "yellow"
    opts@vcRefLengthF = 0.02
    opts@vcWindBarbLineThicknessF = 2.0 
    vector = wrf_vector(a[it],wks,u10(it,:,:),v10(it,:,:),opts)
    delete(opts)

; Time to overlay your plots onto the map.
    plot = wrf_map_overlays(a[it],wks,(/contour_precip, contour_slp, vector/),pltres,mpres)

; Now we can plot cities on the map.
;    places = dimsizes(cities)   	; How many cities in our cities.txt file?
;    text = new(places,float)	; Now we sample some data and put it under

; Now set resources for the text
 ;   txres = True
 ;   txres@txFontHeightF = 0.008

; define an offset based on the domain

;    if (domain .eq. "d01_") then
;	offset = 0.1
;    else
;	offset = 0.05
;    end if

;    gsn_text(wks,plot,city,lon,lat+offset,txres)  ; Plot the city with a slight offset.
;    gsn_text(wks,plot,".",lon,lat,txres)	    ; Plots a dot at the city location.
;    gsn_text(wks,plot,text,lon,lat-offset,txres) ; Plots the value below

;draw(plot)
    frame(wks)

    system("convert -trim "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")
    system("convert -border 10 -bordercolor white "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")

  end do        ; END OF TIME LOOP

end
