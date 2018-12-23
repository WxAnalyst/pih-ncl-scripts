
;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels
;   In this example we get all data first, the interpolate to a
;   series of pressure levels before plotting the data

begin
;
;  First, let's set some variables. This will dictate how our image files
; are named.

	domain = "d01_"
	domname = "pih_"
	dir = "/wrf/uems/runs/pih/wrfprd/"

; Now, let's load some NetCDF files from our WRF
	fils = systemfunc("ls "+dir+"wrfout_"+domain+"*")
	a = addfiles(fils+".nc","r")


; We generate plots, but what kind do we prefer?
	type = "png"
	type@wkWidth	= 1800
	type@wkHeight	= 1200


; Set some Basic Plot options
  res = True
  res@MainTitle                   = "Pocatello WRF"
  res@Footer = False

 pltres = True
 
 mpres = True
   mpres@mpGeophysicalLineColor      = "Black"
   mpres@mpNationalLineColor         = "Black"
   mpres@mpUSStateLineColor          = "Black"
   mpres@mpGridLineColor             = "Black"
   mpres@mpLimbLineColor             = "Black"
   mpres@mpPerimLineColor            = "Black"
   mpres@mpGeophysicalLineThicknessF = 3.0
   mpres@mpGridLineThicknessF        = 2.0
   mpres@mpLimbLineThicknessF        = 2.0
   mpres@mpNationalLineThicknessF    = 3.0
   mpres@mpUSStateLineThicknessF     = 3.0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; What times and how many time steps are in the data set?
  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  ntimes = dimsizes(times)         ; number of times in the file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First get the variables we will need        

    tc = wrf_user_getvar(a,"tc",-1)        ; T in C
    u  = wrf_user_getvar(a,"ua",-1)        ; u averaged to mass points
    v  = wrf_user_getvar(a,"va",-1)        ; v averaged to mass points
    p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
    z  = wrf_user_getvar(a, "z",-1)        ; grid point height
    rh = wrf_user_getvar(a,"rh",-1)        ; relative humidity
;   vort = wrf_user_getvar(a,"avo",-1)	

; The specific pressure levels that we want the data interpolated to.
; Interpolate to these levels
  pressure_levels = (/ 850., 700., 500., 250./)   ; pressure levels to plot
  nlevels         = dimsizes(pressure_levels)     ; number of pressure levels
	opts = True
	opts@extrapolate = True
	tc_plane = wrf_user_vert_interp(a,tc,"pressure",pressure_levels,opts)
	z_plane = wrf_user_vert_interp(a,z,"pressure",pressure_levels,opts)
	rh_plane = wrf_user_vert_interp(a,rh,"pressure",pressure_levels,opts)
	u_plane = wrf_user_vert_interp(a,u,"pressure",pressure_levels,opts)
	v_plane = wrf_user_vert_interp(a,v,"pressure",pressure_levels,opts)
;	vort_plane = wrf_user_vert_interp(a,vort,"pressure",pressure_levels,opts)
delete(opts)

  spd     = (u_plane*u_plane + v_plane*v_plane)^(0.5) ; m/sec
    spd@description = "Wind Speed"
    spd@units = "m/s"
  u_plane = u_plane*1.94386     ; kts
  v_plane = v_plane*1.94386     ; kts
    u_plane@units = "kts"
    v_plane@units = "kts"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  do it = 0,ntimes-1,1             ; TIME LOOP
		
print("Working on time: " + times(it) )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots
    its=sprintf("%02g",it)

    do level = 0,nlevels-1                 ; LOOP OVER LEVELS

      pressure = pressure_levels(level)
	wks = gsn_open_wks(type,domain+domname+pressure+its+"_syn")
      ; Add some level info to the plot
        res@PlotLevelID = pressure + " hPa"
          
; Plotting options for Vort
;        opts = res
;        opts@cnLineColor = "Red"
;	 opts@ContourParameters = (/ 5.0 /)
;        opts@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
;        opts@gsnContourLineThicknessesScale = 1.0
;	 opts@cnLineDashPattern = 1
;        contour_vort = wrf_contour(a[it],wks,vort_plane(it,level,:,:),opts)
;        delete(opts)

; Plotting options for T                
        opts = res                          
        opts@cnLineColor = "Red"
        opts@ContourParameters = (/ 5.0 /)
        opts@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
        opts@gsnContourLineThicknessesScale = 2.0
        contour_tc = wrf_contour(a[it],wks,tc_plane(it,level,:,:),opts)
        delete(opts)

      ; Plotting options for RH                
        opts = res                          
        opts@cnFillOn = True  
        opts@pmLabelBarOrthogonalPosF = -0.1
        opts@ContourParameters = (/ 10., 90., 10./)
        opts@cnFillColors = (/"White","White","White", \
                              "White","Chartreuse","Green",\
                              "Green3","Green4", \
                              "ForestGreen","PaleGreen4"/)
        contour_rh = wrf_contour(a[it],wks,rh_plane(it,level,:,:),opts)
        delete(opts)


      ; Plotting options for Wind Speed                
        opts = res                          
        opts@cnLineColor = "MediumSeaGreen"
        opts@ContourParameters = (/ 10. /)
        opts@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
        opts@gsnContourLineThicknessesScale = 3.0
        contour_spd = wrf_contour(a[it],wks,spd(it,level,:,:),opts)
        delete(opts)


      ; Plotting options for Wind Vectors                 
        opts = res          
        opts@FieldTitle = "Wind"   ; overwrite Field Title
        opts@NumVectors = 25       ; wind barb density
	opts@vcWindBarbTickLengthF   = 0.4 
        vector = wrf_vector(a[it],wks,u_plane(it,level,:,:),v_plane(it,level,:,:),opts)
        delete(opts)


      ; Plotting options for Geopotential Height
        opts_z = res                          
        opts_z@cnLineColor = "Blue"
        opts_z@gsnContourLineThicknessesScale = 3.0


      ; MAKE PLOTS                                       

        if ( pressure .eq. 850 ) then   ; plot temp, rh, height, wind barbs
          opts_z@ContourParameters = (/ 20.0 /)
;         contour_height = wrf_contour(a[it],wks,z_plane(it,level,:,:),opts_z)
          plot = wrf_map_overlays(a[it],wks,(/contour_rh,contour_tc,vector/),pltres,mpres)
; Trim Whitespace and add a 10px border
	system("convert -trim "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
	system("convert -border 10 -bordercolor white "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")

        end if

        if ( pressure .eq. 700 ) then   ; plot temp, height, wind barbs
          opts_z@ContourParameters = (/ 30.0 /)
          contour_height = wrf_contour(a[it],wks, z_plane(it,level,:,:),opts_z)
          plot = wrf_map_overlays(a[it],wks,(/contour_tc, contour_height, contour_rh, vector/),pltres,mpres)
; Trim Whitespace and add a 10px border
       system("convert -trim "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
       system("convert -border 10 -bordercolor white "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
        end if

        if ( pressure .eq. 500 ) then   ; plot temp, height, wind barbs
          opts_z@ContourParameters = (/ 60.0 /)
          contour_height = wrf_contour(a[it],wks, z_plane(it,level,:,:),opts_z)
          plot = wrf_map_overlays(a[it],wks,(/contour_tc,contour_height, contour_rh, \
                                    vector/),pltres,mpres)
; Trim Whitespace and add a 10px border
       system("convert -trim "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
       system("convert -border 10 -bordercolor white "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
        end if

        if ( pressure .eq. 250 ) then   ; plot windspeed, height, wind barbs
          opts_z@ContourParameters = (/ 60.0 /)
          contour_height = wrf_contour(a[it],wks, z_plane(it,level,:,:),opts_z)
          plot = wrf_map_overlays(a[it],wks,(/contour_spd,contour_height, \
                                    vector/),pltres,mpres)
; Trim Whitespace and add a 10px border
       system("convert -trim "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
       system("convert -border 10 -bordercolor white "+domain+domname+pressure+its+"_syn.png "+domain+domname+pressure+its+"_syn.png")
        end if
        delete(opts_z)

    end do      ; END OF LEVEL LOOP

  end do        ; END OF TIME LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end
