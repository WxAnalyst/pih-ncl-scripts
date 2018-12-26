; Read CSV file of cities with "City","Lat","Lon"
;	Plot cities on map
;
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
; First, let's set some variables.
	domain = "d01_"
	domname = "ind_"
	prod = "radar"
	directory = str_get_cols(domname,0,2)

; Now, let's load some NetCDF files from our WRF
	dir = "/wrf/uems/runs/"+directory+"/wrfprd/"
	fils=systemfunc("ls "+dir+"wrfout_"+domain+"*")
	a=addfiles(fils+".nc","r")
 
	cities=asciiread("cities2.txt",-1,"string")
	delim = ","
	lat = tofloat(str_get_field(cities,1,delim))
	lon = tofloat(str_get_field(cities,2,delim))
	city = str_get_field(cities,3,delim)

	
	locres = True
	locres@MAP_PROJ = a[0]@MAP_PROJ 
	locres@TRUELAT1 = a[0]@TRUELAT1
	locres@TRUELAT2 = a[0]@TRUELAT2
	locres@STAND_LON = a[0]@STAND_LON
	locres@REF_LAT = a[0]@CEN_LAT
	locres@REF_LON = a[0]@CEN_LON
	locres@KNOWNI = a[0]@$"WEST-EAST_GRID_DIMENSION"$/2 
	locres@KNOWNJ = a[0]@$"SOUTH-NORTH_GRID_DIMENSION"$/2
	locres@DX	= a[0]@DX
	locres@DY = a[0]@DY

	loc = wrf_ll_to_ij(lon,lat,locres)
	lo = toint(loc(0,:))
	la = toint(loc(1,:))

	type = "png"
  type@wkWidth=1800
  type@wkHeight=1200

; Set some basic resources
  res = True 
  res@MainTitle                   = "Pocatello WRF"
  pltres 													= True
	pltres@FramePlot = False

  mpres = True
  mpres@mpDataBaseVersion	    = "Ncarg4_1"
  mpres@mpOutlineBoundarySets	    = "AllBoundaries"
  mpres@mpGeophysicalLineColor      = "Black"
  mpres@mpNationalLineColor         = "Black"
  mpres@mpUSStateLineColor          = "Black"
  mpres@mpGridLineColor             = "Black"
  mpres@mpLimbLineColor             = "Black"
  mpres@mpPerimLineColor            = "Black"
  mpres@mpCountyLineColor           = "Red"
  mpres@mpCountyLineDashPattern	    = 0 
  mpres@mpCountyLineThicknessF	    = 1.0
  mpres@mpCountyLineDashSegLenF	    = 0.3 
  mpres@mpGeophysicalLineThicknessF = 3.0
  mpres@mpGridLineThicknessF        = 0.0
  mpres@mpLimbLineThicknessF        = 2.0
  mpres@mpNationalLineThicknessF    = 3.0
  mpres@mpUSStateLineThicknessF     = 3.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; What times and how many time steps are in the data set?
  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  ntimes = dimsizes(times)         ; number of times in the file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  do it = 0,ntimes-1             ; TIME LOOP

    print("Working on time: " + times(it) )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots
    its=sprintf("%02g",it)

		wks=gsn_open_wks(type,domain+domname+prod+its+"_syn")
;		gsn_define_colormap(wks,"radar")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First get the variables we will need        

    refl = wrf_user_getvar(a,"mdbz",it)   ; Reflectivity 
		refl@description = "Composite Reflectivity"
		refl@units="dBz"
;		u  = wrf_user_getvar(a,"ua",it)      ; 3D U at mass points
;		v  = wrf_user_getvar(a,"va",it)      ; 3D V at mass points
		u10 = wrf_user_getvar(a,"U10",it)    ; u at 10 m, mass point
    v10 = wrf_user_getvar(a,"V10",it)    ; v at 10 m, mass point
		u10 = u10*1.94386                    ; Turn wind into knots
    v10 = v10*1.94386
      u10@units = "kts"
      v10@units = "kts"



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Plotting options for Reflectivity 
      opts = res                         
      opts@cnFillOn = True
      opts@Footer = False
      cmap = read_colormap_file("radar")
      cmap(0,:) = (/0,0,0,0/)
      opts@cnFillPalette = cmap
      opts@SubFieldTitle = "  Max: "+toint(max(refl))
      opts@ContourParameters = (/ 0., 95., 5./)
;      opts@gsnSpreadColorEnd = -3  ; End third from the last color in color map
      contour_refl = wrf_contour(a[it],wks,refl,opts)
      delete(opts)
			
; Plotting options for Wind Vectors
      opts = res
      opts@vcWindBarbLineThicknessF = 2.0
      opts@Footer = False
      opts@FieldTitle = "Wind"       ; overwrite Field Title
      opts@NumVectors = 30           ; density of wind barbs
      vector = wrf_vector(a[it],wks,u10,v10,opts)
      delete(opts)

    ; MAKE PLOTS                                       
      plot = wrf_map_overlays(a[it],wks,(/contour_refl,vector/),pltres,mpres)

; Plot cities

			txres = True
			txres@txFont = 22
			txres@txFontHeightF = 0.009
			txres@txFontThicknessF = 1.5
;			gsn_text(wks,plot,city,lon,lat+0.07,txres)
;			gsn_text(wks,plot,".",lon,lat,txres)
frame(wks)


			system("convert -trim "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")
      system("convert -border 10 -bordercolor white "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  end do        ; END OF TIME LOOP

end
