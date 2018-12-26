; Read CSV file of cities with "City","Lat","Lon"
; Plot WRF variable
; Plot cities on map
; Plot value under city
;
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
; First, let's set some variables.
  domain = "d01_"
  domname = "ind_"
  prod = "cape"
  directory = str_get_cols(domname,0,2)

; Now, let's load some NetCDF files from our WRF
  dir = "/wrf/uems/runs/"+directory+"/wrfprd/"
  fils=systemfunc("ls "+dir+"wrfout_"+domain+"*")
  a=addfiles(fils+".nc","r")

  cities=asciiread("cities.txt",-1,"string")
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
  locres@DX = a[0]@DX
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
  pltres                          = True
;  pltres@FramePlot = False

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Which times and how many time steps are in the data set?
  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  ntimes = dimsizes(times)         ; number of times in the file

 do it = 0,ntimes-1             ; TIME LOOP

    print("Working on time: " + times(it) )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots
    its=sprintf("%02g",it)

  cape2d = wrf_user_getvar(a,"cape_2d",it) 
  cape3d = wrf_user_getvar(a,"cape_3d",it) 

; extract the data from the multi-dimensional fields
;  cape  = cape3d(0,:,:,:)
;  cin   = cape3d(1,:,:,:)
  mcape = cape2d(0,:,:)
;		mcape(ind(ismissing(mcape))) = 0
	mcape = where(ismissing(mcape), 0, mcape)
  mcin  = cape2d(1,:,:)
;		mcin(ind(ismissing(mcin))) = 0
	mcin = where(ismissing(mcin), 0 ,mcin)
;  lcl   = cape2d(2,:,:)
;  lfc   = cape2d(3,:,:)


  opts = res                         
  opts@cnFillOn = True  
  opts@cnLineLabelsOn = False
  opts@Footer = False
  opts@lbBottomMarginF = -0.2
 

  opts@FieldTitle = "Most Unstable CAPE"
  opts@SubFieldTitle = "  Max: "+toint(max(mcape))
	wks=gsn_open_wks(type,domain+domname+"mlcape"+its+"_syn")
  opts@ContourParameters = (/ 0., 2000., 100./)
  contour = wrf_contour(a[it],wks,mcape,opts)
  plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
	system("convert -trim "+domain+domname+"mlcape"+its+"_syn.png "+domain+domname+"mlcape"+its+"_syn.png")
  system("convert -border 10 -bordercolor white "+domain+domname+"mlcape"+its+"_syn.png "+domain+domname+"mlcape"+its+"_syn.png")


  opts@FieldTitle = "CIN in most unstable layer"
  opts@SubFieldTitle = "   Min: "+toint(min(mcin))
	wks=gsn_open_wks(type,domain+domname+"cin"+its+"_syn")
  opts@ContourParameters = (/ 0., 125., 25./)
  contour = wrf_contour(a[it],wks,mcin,opts)
  plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
	 system("convert -trim "+domain+domname+"cin"+its+"_syn.png "+domain+domname+"cin"+its+"_syn.png")
  system("convert -border 10 -bordercolor white "+domain+domname+"cin"+its+"_syn.png "+domain+domname+"cin"+its+"_syn.png")



;  opts@FieldTitle = "LFC"
;	wks=gsn_open_wks(type,domain+domname+opts@FieldTitle+its+"_syn")
;  opts@ContourParameters = (/ 200., 3800., 400./)
;  contour = wrf_contour(a[it],wks,lfc,opts)
;  plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
; system("convert -trim "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")
;  system("convert -border 10 -bordercolor white "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")



;  opts@FieldTitle = "LCL"
;	wks=gsn_open_wks(type,domain+domname+opts@FieldTitle+its+"_syn")
;  opts@ContourParameters = (/ 200., 3800., 400./)
;  contour = wrf_contour(a[it],wks,lcl,opts)
;  plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
; system("convert -trim "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")
;  system("convert -border 10 -bordercolor white "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")



;  opts@FieldTitle = "cape"
;	wks=gsn_open_wks(type,domain+domname+opts@FieldTitle+its+"_syn")
;  opts@ContourParameters = (/ 250., 3250., 250./)
;  do il = 0,9                                   ; only interested in the first 10 levels
;    ilev = il + 1
;    opts@PlotLevelID = "level " + ilev
;    contour = wrf_contour(a[it],wks,cape(il,:,:),opts)
;    plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
;  end do
; system("convert -trim "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")
;  system("convert -border 10 -bordercolor white "+domain+domname+opts@FieldTitle+its+"_syn.png "+domain+domname+opts@FieldTitle+its+"_syn.png")



;  opts@FieldTitle = "cin"
;  wks=gsn_open_wks(type,domain+domname+opts@FieldTitle+its+"_syn")
;  opts@ContourParameters = (/ 0., 300., 25./)
;  do il = 0,9                                   ; only interested in the first 10 levels
;    ilev = il + 1
;    opts@PlotLevelID = "level " + ilev
;    contour = wrf_contour(a[it],wks,cin(il,:,:),opts)
;    plot = wrf_map_overlays(a[it],wks,(/contour/),pltres,mpres)
;  end do

;   system("convert -trim "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")
;   system("convert -border 10 -bordercolor white "+domain+domname+prod+its+"_syn.png "+domain+domname+prod+its+"_syn.png")



end do
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end
