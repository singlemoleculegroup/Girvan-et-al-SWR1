; This program is designed for 3-colour emission with 2 laser alternating excitation
; adapted from https://github.com/ashleefeng/singlemolecules to work with our 4 channel MultiSplit and tiff files - PG 2023

pro smi_peak_location_maker_3color_alex, run, mapfile, text_ID


	color_number = 3
	alex_number = 2
	; Custumizing parameters
	film_time_start = 0			;usually 0, start frame to average
	average_length = 100			;usually 50~100, average frame number
	binwidth = 32						;background bin width
	margin = 10							;number of pixels to ignore from edge when calculating median and variance
	spot_diameter = 5				;single spot check
	width = 3								;local maximum range, 512 image-> 3, 256 image-> 2
	edge = 10								;number of pixels to ignore from edge when finding spots
	cutoff_num = 0.5				;single spot check, usually 0.55
	quality_num = 3					;single spot check, 512 image-> 3, 256 image-> 3 or 7
	occupy_num = 4					;is it noise?, 512 image-> 7, 256 image-> 4 or 1
	


	;for the combined images, what ratio of each channel (1, 2 and 3) do you want to combine for the first and second lasers when locating spots
	ch1_ratio_first = 1
	ch2_ratio_first = 0
	ch3_ratio_first = 0

	ch1_ratio_second = 0
  ch2_ratio_second = 0
  ch3_ratio_second = 1
  	
    ;Program start
	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	; generate gaussian peaks

	g_peaks = fltarr(3,3,7,7)   ;creates a floating-point vector or array of the specified dimensions.

	for k = 0, 2 do begin
    	for l = 0, 2 do begin
			offx = 0.5*float(k-1)
			offy = 0.5*float(l-1)
			for i = 0, 6 do begin
				for j = 0, 6 do begin
					dist = 0.4 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
					g_peaks(k,l,i,j) = exp(-dist)
				endfor
			endfor
		endfor
	endfor

	; input film

	if N_PARAMS() eq 0 then begin
		run = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a .tif file.', /READ, FILTER = '*.tif')
		xdisplayFile, '', TEXT=(run + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
		mapfile = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a mapping file', /READ, FILTER = '*.map')
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif

	if N_PARAMS() eq 1 then begin
		mapfile = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a mapping file', /READ, FILTER = '*.map')
		xdisplayFile, '', TEXT=(mapfile + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
	endif

	if N_PARAMS() eq 2 then begin
		xdisplayFile, '', TEXT=(run + ".pma is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif

	if N_PARAMS() eq 3 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".pma is selected."), /APPEND,  /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif



	; figure out size + allocate appropriately
	fname= run + ".tif"
  	ok = query_tiff(fname, result)

	film_time_length = UINT(result.num_images)
	fsize = result.dimensions
	film_width = fsize(0)
	film_height = fsize(1)

	film_width_half = film_width/2
	film_height_half = film_height/2
	film_width_quarter = film_width/4
	film_height_quarter = film_height/4
	film_width_tri = round(film_width/3)
	film_height_tri = round(film_height/3)

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW

	frame  = bytarr(film_width, film_height, /NOZERO)
	frame_average_first = fltarr(film_width, film_height)
	frame_average_second = fltarr(film_width, film_height)

	film_time_end = film_time_start + average_length

	if film_time_end gt floor(film_time_length/alex_number) then film_time_end = floor(film_time_length/alex_number)

	for j = film_time_start, film_time_end - 1, 2 do begin
		frame = read_tiff(fname, image_index = j)
		frame_average_first = temporary(frame_average_first) + frame
		frame = read_tiff(fname, image_index = j+1)
		frame_average_second = temporary(frame_average_second) + frame
	endfor

  frame_average_first = temporary(frame_average_first)/float((film_time_end - film_time_start)*1/2)
	frame_average_second = temporary(frame_average_second)/float((film_time_end - film_time_start)*1/2)
	
	;frame = byte(frame_average_first)
    window, 0, xsize = film_width, ysize = film_height, title = 'frame_average_first'
    tvscl, frame_average_first

	;frame = byte(frame_average_second)
	window, 1, xsize = film_width, ysize = film_height, title = 'frame_average_second'
	tvscl, frame_average_second


	if FILE_TEST(run + "_ave_first.tif") eq 0 then begin       ; _ave.tif file doesn't exist.
		frame_average_first_norm = 255*(frame_average_first-min(frame_average_first))/(max(frame_average_first)-min(frame_average_first))	
    	WRITE_TIFF, run + "_ave_first.tif", frame_average_first_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2
    endif
	if FILE_TEST(run + "_ave_second.tif") eq 0 then begin				; _ave.tif file doesn't exist.
		frame_average_second_norm = 255*(frame_average_second-min(frame_average_second))/(max(frame_average_second)-min(frame_average_second))	
		WRITE_TIFF, run + "_ave_second.tif", frame_average_second_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2
	endif



; subtracts background
; works by binning the image and using the median value from these bins, unbinning the image and then smoothing. Works well for low density of spots. Can have a weird disconnect between the channels in the image. Need to look into this.

	temp_first = fltarr(film_width, film_height)
	temp_second = fltarr(film_width, film_height)
    
    temp_first = frame_average_first
    temp_second = frame_average_second

	halfbinwidth = fix(binwidth/2)
	halfbinwidth_1 = halfbinwidth - 1

	minimum_intensity_matrix_first = fltarr(film_width/binwidth, film_height/binwidth, /NOZERO)
	minimum_intensity_matrix_second = fltarr(film_width/binwidth, film_height/binwidth, /NOZERO)


	for i = halfbinwidth, film_width, binwidth do begin
		for j = halfbinwidth, film_height, binwidth do begin
			minimum_intensity_matrix_first((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = median(temp_first(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1))
			minimum_intensity_matrix_second((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = median(temp_second(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1))
		endfor
	endfor
  minimum_intensity_matrix_first = rebin(minimum_intensity_matrix_first, film_width, film_height)
	minimum_intensity_matrix_second = rebin(minimum_intensity_matrix_second, film_width, film_height)
	minimum_intensity_matrix_first = smooth(minimum_intensity_matrix_first, 20, /EDGE_TRUNCATE)
	minimum_intensity_matrix_second = smooth(minimum_intensity_matrix_second, 20, /EDGE_TRUNCATE)

  window, 12, xsize = film_width, ysize = film_height, title = 'background_first'
  tv, (minimum_intensity_matrix_first*255/max(minimum_intensity_matrix_first))>0
	window, 13, xsize = film_width, ysize = film_height, title = 'background_second'
	tv, (minimum_intensity_matrix_second*255/max(minimum_intensity_matrix_second))>0

  modified_frame_first = frame_average_first - minimum_intensity_matrix_first
	modified_frame_second = frame_average_second - minimum_intensity_matrix_second

  modified_frame_first=modified_frame_first*255/max(modified_frame_first)
	modified_frame_second=modified_frame_second*255/max(modified_frame_second)

	window, 15, xsize = film_width, ysize = film_height, title = 'modified_frame_first'
	tv, (modified_frame_first>0)
	window, 16, xsize = film_width, ysize = film_height, title = 'modified_frame_second'
	tv, (modified_frame_second>0)

	; open file that contains how the channels map onto each second
  P12 = fltarr(4,4)
  Q12 = fltarr(4,4)
  P13 = fltarr(4,4)
  Q13 = fltarr(4,4)
  P23 = fltarr(4,4)
  Q23 = fltarr(4,4)

  openr, 1, mapfile
  readf, 1, P12
  readf, 1, Q12
  readf, 1, P13
  readf, 1, Q13
  readf, 1, P23
  readf, 1, Q23
  close, 1

; and map channels two and three onto channel one
  ch1_first = modified_frame_first(0:(film_width_half-1),0:(film_height_half-1))
  ch2_first = modified_frame_first(film_width_half:(film_width-1),0:(film_height_half-1))
  ch3_first = modified_frame_first(0:(film_width_half-1),film_height_half:(film_height-1))

  ch1_second = modified_frame_second(0:(film_width_half-1),0:(film_height_half-1))
  ch2_second = modified_frame_second(film_width_half:(film_width-1),0:(film_height_half-1))
  ch3_second = modified_frame_second(0:(film_width_half-1),film_height_half:(film_height-1))

  ch2_first = POLY_2D(ch2_first, P12, Q12, 2)
  ch3_first = POLY_2D(ch3_first, P13, Q13, 2)

  ch2_second = POLY_2D(ch2_second, P12, Q12, 2)
  ch3_second = POLY_2D(ch3_second, P13, Q13, 2)

  combined_frame_first = float(ch1_first)*ch1_ratio_first + float(ch2_first)*ch2_ratio_first + float(ch3_first)*ch3_ratio_first
  combined_frame_second = float(ch1_second)*ch1_ratio_second + float(ch2_second)*ch2_ratio_second + float(ch3_second)*ch3_ratio_second

  window, 18, xsize = film_width_half, ysize = film_height_half, title = 'combined_frame_first'
  tv, combined_frame_first
  window, 19, xsize = film_width_half, ysize = film_height_half, title = 'combined_frame_second'
  tv, combined_frame_second

;write out the combined images
combined_frame_first_norm = 255*(combined_frame_first-min(combined_frame_first))/(max(combined_frame_first)-min(combined_frame_first))	
WRITE_TIFF, run + "_com_first.tif", combined_frame_first_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2

combined_frame_second_norm = 255*(combined_frame_second-min(combined_frame_second))/(max(combined_frame_second)-min(combined_frame_second))	
WRITE_TIFF, run + "_com_second.tif", combined_frame_second_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2


  medianofFrame_first = float(median(combined_frame_first(margin:(film_width_half-1-margin),margin:(film_height_half-1-margin))))
  varianceofFrame_first = variance(combined_frame_first(margin:(film_width_half-1-margin),margin:(film_height_half-1-margin)))
  medianofFrame_second = float(median(combined_frame_second(margin:(film_width_half-1-margin),margin:(film_height_half-1-margin))))
  varianceofFrame_second = variance(combined_frame_second(margin:(film_width_half-1-margin),margin:(film_height_half-1-margin)))

  deviation_first = sqrt(varianceofFrame_first)
  deviation_second = sqrt(varianceofFrame_second)

  cutoff_first = byte(medianofFrame_first + deviation_first)
  truncated_frame_first = float(combined_frame_first gt cutoff_first)*combined_frame_first
  cutoff_second = byte(medianofFrame_second + deviation_second)
  truncated_frame_second = float(combined_frame_second gt cutoff_second)*combined_frame_second

  window, 21, xsize = film_width_half, ysize = film_height_half, title = 'truncated_frame_first'
  tv, truncated_frame_first
  window, 22, xsize = film_width_half, ysize = film_height_half, title = 'truncated_frame_second'
  tv, truncated_frame_second

	; find the peaks

	circle = bytarr(11, 11, /NOZERO)  ;make matrix

	if spot_diameter eq 9 then begin
		circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,1) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,2) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,3) = [ 0,0,1,0,0,0,0,0,1,0,0]
		circle(*,4) = [ 0,1,0,0,0,0,0,0,0,1,0]
		circle(*,5) = [ 0,1,0,0,0,0,0,0,0,1,0]
		circle(*,6) = [ 0,1,0,0,0,0,0,0,0,1,0]
		circle(*,7) = [ 0,0,1,0,0,0,0,0,1,0,0]
		circle(*,8) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,9) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]
	endif
	if spot_diameter eq 7 then begin
		circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,2) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,3) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,4) = [ 0,0,1,0,0,0,0,0,1,0,0]
		circle(*,5) = [ 0,0,1,0,0,0,0,0,1,0,0]
		circle(*,6) = [ 0,0,1,0,0,0,0,0,1,0,0]
		circle(*,7) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,8) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]
	endif
	if spot_diameter eq 5 then begin
		circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,2) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,3) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,4) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,5) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,6) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,7) = [ 0,0,0,0,1,1,1,0,0,0,0]
  		circle(*,8) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]
	endif

	toosmall = bytarr(11, 11, /NOZERO)
	toosmall(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,2) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,3) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,4) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,5) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,6) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,7) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,8) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

  GoodLocations_x_first = intarr(10000)
  GoodLocations_y_first = intarr(10000)
	GoodLocations_x_second = intarr(10000)
	GoodLocations_y_second = intarr(10000)
	GoodLocations_x_all = intarr(10000)
	GoodLocations_y_all = intarr(10000)
	GoodLocations_x = intarr(10000)
	GoodLocations_y = intarr(10000)
	Background_first = dblarr(10000)
	Background_second = dblarr(10000)
	Background_first_all = dblarr(10000)
	Background_second_all = dblarr(10000)
	Background = dblarr(10000)

	NumberofGoodLocations_first = 0
  NumberofBadLocations_first = 0
	NumberofGoodLocations_second = 0
	NumberofBadLocations_second = 0
	NumberofGoodLocations_all = 0
	NumberofBadLocations_all = 0
	NumberofGoodLocations = 0
	NumberofBadLocations = 0
	temp_all_first = modified_frame_first
  temp_all_second = modified_frame_second

	; will find peaks that appear in either the first or second lasers and combine. This results in more molecules being identified, but depending on the experiment it will double count a molecule if it appears under both laser excitations, take care to remove duplicates during subsequent analysis steps.
	for c=0, 1 do begin
		if c eq 0 then begin
			truncated_frame = truncated_frame_first
			modified_frame = modified_frame_first
			combined_frame = combined_frame_first
			temp = modified_frame_first
			temp_emphasized = truncated_frame_first
			minimum_intensity_matrix = minimum_intensity_matrix_first
		endif
		if c eq 1 then begin
			truncated_frame = truncated_frame_second
			modified_frame = modified_frame_second
			combined_frame = combined_frame_second
			temp = modified_frame_second
			temp_emphasized = truncated_frame_second
			minimum_intensity_matrix = minimum_intensity_matrix_second
		endif

		NumberofGoodLocations = 0
		NumberofBadLocations = 0

		for j = edge, film_height_half - edge -1 do begin
	    	for i = edge, film_width_half - edge -1 do begin
				if truncated_frame(i,j) gt 0 then begin

					; find the nearest maxima

					MaxIntensity_local = max(truncated_frame(i-width:i+width,j-width:j+width), Max_location)
					Max_location_x_y = ARRAY_INDICES(modified_frame(i-width:i+width,j-width:j+width), Max_location)
					Max_location_x = Max_location_x_y[0] - width
					Max_location_y = Max_location_x_y[1] - width
					; only analyze peaks in current column,
					; and not near edge of area analyzed

					if (Max_location_x eq 0) and (Max_location_y eq 0) then begin

						Max_location_x=i
						Max_location_y=j

						; check if its a good peak
						; i.e. surrounding points below 1 stdev

						aroundMax_left = Max_location_x - 5
						aroundMax_right = Max_location_x + 5
						aroundMax_bottom = Max_location_y - 5
						aroundMax_top = Max_location_y + 5

						cutoff=byte(cutoff_num * float(MaxIntensity_local))
						quality=total( (combined_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) gt cutoff) * (circle eq 1) )
						occupy=total( (truncated_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) gt 0) * toosmall  )

	                    if (quality lt quality_num) and (occupy gt occupy_num) then begin

							; draw where peak was found on screen

							temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = float(truncated_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top))/MaxIntensity_local*255
							temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

							temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0

              ; filter for spots that have all three colors - XF
							all_check = 'n'
							if c eq 1 then begin
								;for g = 0, NumberofGoodLocations_second - 1 do begin
								  ;if (abs(GoodLocations_x_second(g)-Max_location_x) le 2)and(abs(GoodLocations_y_second(g)-Max_location_y) le 2) then begin
								    for h = 0, NumberofGoodLocations_first - 1 do begin
								      if (abs(GoodLocations_x_first(h)-Max_location_x) le 2) and (abs(GoodLocations_y_first(h)-Max_location_y) le 2) then begin
                                        all_check = 'y'
                                      endif
                                    endfor
                                  ;endif
                                ;endfor
                            endif
              all_check = 'y' ; this overides the 'all_check' because I only want to find the peaks in the 2nd channel. -PG
							if all_check eq 'y' then begin
							  temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
								temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
							endif

							;wset, 1
							;tv, temp_emphasized

							; compute difference between peak and gaussian peak

							best = 10000.0
							for k = 0, 2 do begin
								for l = 0, 2 do begin
									difference = total(abs(float(MaxIntensity_local) * g_peaks(k,l,*,*) - modified_frame((Max_location_x-3):(Max_location_x+3), (Max_location_y-3):(Max_location_y+3))))
									if difference lt best then begin
										best_x = k
										best_y = l
										best = difference
									endif
								endfor
							endfor

							float_x_1 = float(Max_location_x) - 0.5*float(best_x-1)
							float_y_1 = float(Max_location_y) - 0.5*float(best_y-1)

	                 		; calculate and draw location of companion peak

							float_x_2 = film_width_half
							float_y_2 = 0.0
							for k = 0, 3 do begin
								for l = 0, 3 do begin
									float_x_2 = float_x_2 + P12(k,l) * float(float_x_1^l) * float(float_y_1^k)
									float_y_2 = float_y_2 + Q12(k,l) * float(float_x_1^l) * float(float_y_1^k)
								endfor
							endfor

							x_2 = round(float_x_2)
							y_2 = round(float_y_2)

							aroundMax_left = x_2 - 5
							aroundMax_right = x_2 + 5
							aroundMax_bottom = y_2 - 5
							aroundMax_top = y_2 + 5
							if (aroundMax_left le 1) or (aroundMax_bottom le 1) or (aroundMax_right ge (film_width-1)) or (aroundMax_top ge (film_height-1)) then begin
								NumberofBadLocations++
							endif else begin
								temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

                if all_check eq 'y' then begin
                  temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                  temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                endif

								float_x_3 = 0.0
								float_y_3 = film_height_half
								for k = 0, 3 do begin
                  for l = 0, 3 do begin
                    float_x_3 = float_x_3 + P13(k,l) * float(float_x_1^l) * float(float_y_1^k)
                    float_y_3 = float_y_3 + Q13(k,l) * float(float_x_1^l) * float(float_y_1^k)
                  endfor
                endfor

                x_3 = round(float_x_3)
                y_3 = round(float_y_3)
                aroundMax_left = x_3 - 5
                aroundMax_right = x_3 + 5
                aroundMax_bottom = y_3 - 5
                aroundMax_top = y_3 + 5
                if (aroundMax_left le 1) or (aroundMax_bottom le 1) or (aroundMax_right ge (film_width-1)) or (aroundMax_top ge (film_height-1)) then begin
                  NumberofBadLocations++
                endif else begin
                  temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

                  if all_check eq 'y' then begin
                    temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                  endif

                ;wset, 0
								;tv, temp>0

								  GoodLocations_x(NumberofGoodLocations) = Max_location_x
                  GoodLocations_y(NumberofGoodLocations) = Max_location_y
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(Max_location_x, Max_location_y)
                  NumberofGoodLocations++
                  GoodLocations_x(NumberofGoodLocations) = x_2
                  GoodLocations_y(NumberofGoodLocations) = y_2
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(x_2, y_2)
                  NumberofGoodLocations++
                  GoodLocations_x(NumberofGoodLocations) = x_3
                  GoodLocations_y(NumberofGoodLocations) = y_3
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(x_3, y_3)
                  NumberofGoodLocations++

                  if all_check eq 'y' then begin
                    temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0

									  GoodLocations_x_all(NumberofGoodLocations_all) = Max_location_x
                    GoodLocations_y_all(NumberofGoodLocations_all) = Max_location_y
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(Max_location_x, Max_location_y)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(Max_location_x, Max_location_y)
                    NumberofGoodLocations_all++
                    GoodLocations_x_all(NumberofGoodLocations_all) = x_2
                    GoodLocations_y_all(NumberofGoodLocations_all) = y_2
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(x_2, y_2)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(x_2, y_2)
                    NumberofGoodLocations_all++
                    GoodLocations_x_all(NumberofGoodLocations_all) = x_3
                    GoodLocations_y_all(NumberofGoodLocations_all) = y_3
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(x_3, y_3)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(x_3, y_3)
                    NumberofGoodLocations_all++
                  endif
                endelse
              endelse
						endif else begin
							NumberofBadLocations++
						endelse
					endif
				endif
			endfor
		endfor

		if c eq 0 then begin
			NumberofGoodLocations_first = NumberofGoodLocations
			NumberofBadLocations_first = NumberofBadLocations
			temp_first = temp
			Background_first = Background
			GoodLocations_x_first = GoodLocations_x
			GoodLocations_y_first = GoodLocations_y
		endif
		if c eq 1 then begin
			NumberofGoodLocations_second = NumberofGoodLocations
			NumberofBadLocations_second = NumberofBadLocations
			temp_second = temp
			Background_second = Background
			GoodLocations_x_second = GoodLocations_x
			GoodLocations_y_second = GoodLocations_y
		endif
	endfor

  window, 24, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_first'
  tv, temp_first>0
	window, 25, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_second'
	tv, temp_second>0
	window, 27, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_first'
  tv, temp_all_first>0
	window, 28, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_second'
	tv, temp_all_second>0

  WRITE_TIFF, run + "_peaks_first.tif", temp_first>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2
	WRITE_TIFF, run + "_peaks_second.tif", temp_second>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2

  WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_first) + " good peaks circled for first laser."), /APPEND, /SHOW
  WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations_first) + " bad peaks."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_second) + " good peaks circled for second laser."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations_second) + " bad peaks."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_all/color_number) + " good molecules circled for all lasers."), /APPEND, /SHOW

	openw, 1, run + ".3color_alex_pks"
	;printf, 1, NumberofGoodLocations_second
	for i = 0, NumberofGoodLocations_all - 1 do begin
    	printf, 1, i+1, GoodLocations_x_all(i), GoodLocations_y_all(i),Background_first_all(i),Background_second_all(i)
	endfor
	close, 1

	WIDGET_CONTROL, text_ID, SET_VALUE="Done. Byebye~", /APPEND, /SHOW

end