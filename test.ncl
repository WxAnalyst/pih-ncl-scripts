; Generic template for producing WRF graphics.
; Read CSV file of cities with "City","Lat","Lon"
; Plot WRF variable
;	Plot cities on map
;	Plot value under city

begin
; First, let's set some variables. This will dictate how our image files
; are named. 
	domain = "d01_"
	domname = "pih_"
	prod = "Test"

; Now, let's load some NetCDF files from our WRF.
	dir = "/wrf/uems/runs/pih/"
	dir2 = "/wrf/uems/runs/pih/wrfprd/"
	fils = systemfunc("ls "+dir)
	  if(ismissing(getvardimnames(fils))) then
	   delete(fils)
	   fils = systemfunc("ls "+dir2+"wrfout_"+domain+"*")
	end if
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
  	mpres@mpOutlineBoundarySets       = "USStates"
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
   gsn_define_colormap(wks,"temp1")

; What data are we putting on the map?   
   T = wrf_user_getvar(a,"T2",it)   ; 2m temp
   Tc = T - 273.15  ; Convert K to C
   Tf = (Tc*9/5)+32 ; Convert C to F

; Set resources for this variable.
    Tf@description = "Surface Temperature"
    Tf@units = "degrees F"

; Want the domain max/min values at the top?
    res@SubFieldTitle = "   Max: "+toint(max(Tf))+"     Min: "+toint(min(Tf))

; Moving label values closer to the color bar.
    res@lbLabelOffsetF = 0.05

; Plotting options for SFC Temp 
    opts = res                         
    opts@cnFillOn = True
    opts@Footer = False
    opts@lbBottomMarginF  = -0.2
    opts@ContourParameters = (/ -10., 110., 4./)
    opts@gsnSpreadColorEnd = -3  ; End third from the last color in color map

; Create a contour plot based on vaiables we've defined
    contour_T = wrf_contour(a[it],wks,Tf,opts)
    delete(opts)  ; delete opts before adding another contour.
			

; Time to overlay your plots onto the map.
    plot = wrf_map_overlays(a[it],wks,(/contour_T/),pltres,mpres)

; Now we can plot cities on the map.
    places = dimsizes(cities)   	; How many cities in our cities.txt file?
    text = new(places,float)	; Now we sample some data and put it under
    do ci = 0,places-1		;   the cities plotted on the map.
     text(ci) = Tf(la(ci),lo(ci)) ; 
    end do

; Now set resources for the text
    txres = True
    txres@txFontHeightF = 0.008

; define an offset based on the domain

    if (domain .eq. "d01_") then
	offset = 0.1
    else
	offset = 0.05
    end if

    gsn_text(wks,plot,city,lon,lat+offset,txres)  ; Plot the city with a slight offset.
    gsn_text(wks,plot,".",lon,lat,txres)	    ; Plots a dot at the city location.
    gsn_text(wks,plot,toint(text),lon,lat-offset,txres) ; Plots the value below

;draw(plot)
    frame(wks)

    system("convert -trim "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")
    system("convert -border 10 -bordercolor white "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")

  end do        ; END OF TIME LOOP

end
