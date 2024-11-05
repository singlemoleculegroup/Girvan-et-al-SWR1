pro smi_peak_trace_maker_3color_alex, run, text_ID, color_number_input

	;3-colour emssion blue-red alternating laser excitation
	color_number = 3
	; Custumizing parameters
	spot_diameter = 5				;summing region around spot


	;Program start
	
	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	; generate gaussian peaks

	g_peaks = fltarr(7,7)

	for i = 0, 6 do begin
		for j = 0, 6 do begin
			dist = 0.3 * ((float(i)-3.0)^2 + (float(j)-3.0)^2) ;jayil trial
			g_peaks(i,j) = 2.0*exp(-dist)
		endfor
	endfor

	; input film

	if N_PARAMS() eq 0 then begin
		run = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a .tif file.', /READ, FILTER = '*.tif')
		xdisplayFile, '', TEXT=(run + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
	endif

	if N_PARAMS() eq 1 then begin
		xdisplayFile, '', TEXT=(run + ".tif is selected."), RETURN_ID=display_ID, WTEXT=text_ID
	endif

	if N_PARAMS() eq 2 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".tif is selected."), /APPEND,  /SHOW
	endif
	
	if N_PARAMS() eq 3 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".tif is selected."), /APPEND, /SHOW
		color_number = color_number_input
	endif

	; figure out size + allocate appropriately
	fname= run + ".tif"
  	ok = query_tiff(fname, result)

	film_time_length = UINT(result.num_images)
	fsize = result.dimensions
	film_width = fsize(0)
	film_height = fsize(1)

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW

	; load the locations of the peaks
	
  	openr, 2, run + ".3color_alex_pks"

	GoodLocations_x = intarr(4000)
	GoodLocations_y = intarr(4000)
	Background_blue = dblarr(4000)
	Background_green = dblarr(4000)
	NumberofGoodLocations = 0
	xx = fix(1)
	yy = fix(1)
	back_blue = double(1)
	back_red = double(1)
	color_change_check='n'
	
	while EOF(2) ne 1 do begin
    	readf, 2, indexdummy, xx, yy, back_blue, back_red
    	GoodLocations_x(NumberofGoodLocations) = xx
    	GoodLocations_y(NumberofGoodLocations) = yy
    	Background_blue(NumberofGoodLocations) = back_blue
    	Background_green(NumberofGoodLocations) = back_red
    	NumberofGoodLocations = NumberofGoodLocations + 1
	endwhile
	close, 2
	
	WIDGET_CONTROL, text_ID, SET_VALUE=("Color change? : " + color_change_check), /APPEND, /SHOW
	
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations/color_number) + " peaks were found in file " + run + ".tif"), /APPEND, /SHOW

	; calculate which peak to use for each time trace based on
	; peak position

	; now read values at peak locations into time_tr array

	half_diameter = round((spot_diameter -1)/2)

	if spot_diameter eq 5 then begin
    circle = bytarr(5, 5, /NOZERO)
    circle(*,0) = [ 0,1,1,1,0]
    circle(*,1) = [ 1,1,1,1,1]
    circle(*,2) = [ 1,1,1,1,1]
    circle(*,3) = [ 1,1,1,1,1]
    circle(*,4) = [ 0,1,1,1,0]
  endif
	if spot_diameter eq 7 then begin
		circle = bytarr(7, 7, /NOZERO)
		circle(*,0) = [ 0,0,1,1,1,0,0]
		circle(*,1) = [ 0,1,1,1,1,1,0]
		circle(*,2) = [ 1,1,1,1,1,1,1]
		circle(*,3) = [ 1,1,1,1,1,1,1]
		circle(*,4) = [ 1,1,1,1,1,1,1]
		circle(*,5) = [ 0,1,1,1,1,1,0]
		circle(*,6) = [ 0,0,1,1,1,0,0]
	endif
	if spot_diameter eq 9 then begin
		circle = bytarr(9, 9, /NOZERO)
		circle(*,0) = [ 0,0,0,1,1,1,0,0,0]
		circle(*,1) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,2) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,3) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,4) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,5) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,6) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,7) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,8) = [ 0,0,0,1,1,1,0,0,0]
	endif
	if spot_diameter eq 11 then begin
		circle = bytarr(11, 11, /NOZERO)
		circle(*,0) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,1) = [ 0,0,1,1,1,1,1,1,1,0,0]
		circle(*,2) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,3) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,4) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,5) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,6) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,7) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,8) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,9) = [ 0,0,1,1,1,1,1,1,1,0,0]
		circle(*,10) = [ 0,0,0,0,1,1,1,0,0,0,0]
	endif
	
	frame  = bytarr(film_width, film_height, /NOZERO)
	temp  = dblarr(spot_diameter, spot_diameter)    ; temp storage for analysis
	
	time_trace = intarr(NumberofGoodLocations, film_time_length, /NOZERO)
	
	for t = 0, film_time_length - 1 do begin
		if (t mod 100) eq 0 then begin
			WIDGET_CONTROL, text_ID, SET_VALUE=("Trace Working on : " + STRING(t) + STRING(film_time_length) + "     file : "+ run + ".tif"), /APPEND, /SHOW
		endif
    	frame = read_tiff(fname, image_index = t)
		for j = 0, NumberofGoodLocations - 1 do begin
			if (t mod 2) eq 0 then begin
				temp = double(circle) * (double(frame((GoodLocations_x(j)-half_diameter):(GoodLocations_x(j)+half_diameter), (GoodLocations_y(j)-half_diameter):(GoodLocations_y(j)+half_diameter))) - Background_blue(j) )
			endif else begin
				temp = double(circle) * (double(frame((GoodLocations_x(j)-half_diameter):(GoodLocations_x(j)+half_diameter), (GoodLocations_y(j)-half_diameter):(GoodLocations_y(j)+half_diameter))) - Background_green(j) )
			endelse
			time_trace(j, t) = round(total(temp))
		endfor
	endfor
	close, 1

	openw, 1, run + ".3color_alex_traces"

	writeu, 1, film_time_length
	writeu, 1, NumberofGoodLocations
	writeu, 1, time_trace
	writeu, 1, spot_diameter
	close, 1

	WIDGET_CONTROL, text_ID, SET_VALUE="Trace maker for " + run + ".tif file.", /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE="Done. ", /APPEND, /SHOW
end
