; This program is designed for smFRET data aquired using a 2-colour ALEX scheme
; origianl code was adapted from the lab of TJ Ha.
; this script only finds spots under donor excitation, therefore will not find acceptor only molecules.
; P.Girvan 2023 p.girvan@imperial.ac.uk

pro smi_peak_location_maker_2colour_alex, run, mapfile, text_ID

	; Custumizing parameters
	film_time_start = 0			;usually 0, start frame to average
	average_length = 100		;usually 50~100, average frame number
	binwidth = 32				;background bin width
	margin = 10					;median, viriance edge remove, 512 image-> 10, 256 image-> 6
	spot_diameter = 5			;single spot check, 512 image-> 7 , 256 image-> 5
	width = 3					;local maximum range, 512 image-> 3, 256 image-> 2
	edge = 10					;edge pixel number to ignore, 512 image-> 10, 256 image-> 6
	cutoff_num = 0.5			;single spot check, usually 0.55
	quality_num = 3				;single spot check, 512 image-> 3, 256 image-> 3 or 7
	occupy_num = 4				;is it noise?, 512 image-> 7, 256 image-> 4 or 1
	check_ch = 1        	    ;which channel will be criteria for laser order check


	;for the combined images, what ratio of each channel (1, 2 ie donor and acceptor) do you want to combine for the first and second lasers
	ch1_ratio_first = 0.5
	ch2_ratio_first = 0.5
	
	ch1_ratio_second = 0
    ch2_ratio_second = 1
 
  	
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
		run = DIALOG_PICKFILE(PATH='C:\Data', TITLE='Select a .pma file.', /READ, FILTER = '*.pma')
		xdisplayFile, '', TEXT=(run + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
		mapfile = DIALOG_PICKFILE(PATH='C:\Data', TITLE='Select a mapping file', /READ, FILTER = '*.map')
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif

	if N_PARAMS() eq 1 then begin
		mapfile = DIALOG_PICKFILE(PATH='C:\Data', TITLE='Select a mapping file', /READ, FILTER = '*.map')
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

	; initialize variables
	film_width = fix(1)
	film_height = fix(1)
	fr_no  = fix(1)
	
	; figure out size + allocate appropriately
	close, 1          ; make sure unit 1 is closed
    openr, 1, run + ".pma"
    result = FSTAT(1)
    readu, 1, film_width
    readu, 1, film_height

	film_time_length = UINT(DOUBLE(result.SIZE-4)/(DOUBLE(film_width)*DOUBLE(film_height)*2))

	film_width_half = film_width/2

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW

	frame  = uintarr(film_width, film_height, /NOZERO)
	frame_average_first = fltarr(film_width, film_height)
	frame_average_second = fltarr(film_width, film_height)

	film_time_end = film_time_start + average_length
	if film_time_end gt floor(film_time_length/2) then film_time_end = floor(film_time_length/2)

	print, 'current position : '
	POINT_LUN, -1, POS
	HELP, POS
	print, 'target position : ',  film_time_start
	POINT_LUN, 1, 4 + long(film_time_start)*film_width*film_height*2
	POINT_LUN, -1, POS
	HELP, POS

	for j = film_time_start, (film_time_end - 1) do begin
	  readu, 1, fr_no
	  readu, 1, frame
	  frame_average_first = temporary(frame_average_first) + frame
	  readu, 1, fr_no
	  readu, 1, frame
	  frame_average_second = temporary(frame_average_second) + frame
	endfor
	
	close, 1

  frame_average_first = temporary(frame_average_first)/float((film_time_end - film_time_start)*1/2)
	frame_average_second = temporary(frame_average_second)/float((film_time_end - film_time_start)*1/2)


  color_check_first = mean(frame_average_first(film_width_half:film_width-1,0:film_height-1))
  color_check_second = mean(frame_average_second(film_width_half:film_width-1,0:film_height-1))

	if color_check_first gt color_check_second then begin  ;; Green then Red excitation order
	  color_change_check = 'n'
	endif else begin ;; Red then Green excitation order
      color_change_check = 'y'
      frame = frame_average_first
      frame_average_first = frame_average_second
      frame_average_second = frame
    endelse

	WIDGET_CONTROL, text_ID, SET_VALUE=("Color change? : " + color_change_check), /APPEND, /SHOW

	
    window, 0, xsize = film_width, ysize = film_height, title = 'frame_average_first'
    tvscl, frame_average_first

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
  P = fltarr(4,4)
  Q = fltarr(4,4)


  openr, 1, mapfile
  readf, 1, P
  readf, 1, Q
  close, 1

; and map the right half of the screen onto the left half of the screen
  ch1_first = modified_frame_first(0:(film_width_half-1),0:(film_height-1))
  ch2_first = modified_frame_first(film_width_half:(film_width-1),0:(film_height-1))

  ch1_second = modified_frame_second(0:(film_width_half-1),0:(film_height-1))
  ch2_second = modified_frame_second(film_width_half:(film_width-1),0:(film_height-1))

  ch2_first = POLY_2D(ch2_first, P, Q, 2)
  ch2_second = POLY_2D(ch2_second, P, Q, 2)

  combined_frame_first = float(ch1_first)*ch1_ratio_first + float(ch2_first)*ch2_ratio_first
  combined_frame_second = float(ch1_second)*ch1_ratio_second + float(ch2_second)*ch2_ratio_second

  window, 18, xsize = film_width_half, ysize = film_height, title = 'combined_frame_first'
  tv, combined_frame_first
  window, 19, xsize = film_width_half, ysize = film_height, title = 'combined_frame_second'
  tv, combined_frame_second

;write out the combined images
combined_frame_first_norm = 255*(combined_frame_first-min(combined_frame_first))/(max(combined_frame_first)-min(combined_frame_first))	
WRITE_TIFF, run + "_com_first.tif", combined_frame_first_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2

combined_frame_second_norm = 255*(combined_frame_second-min(combined_frame_second))/(max(combined_frame_second)-min(combined_frame_second))	
WRITE_TIFF, run + "_com_second.tif", combined_frame_second_norm, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2


  medianofFrame_first = float(median(combined_frame_first(margin:(film_width_half-1-margin),margin:(film_height-1-margin))))
  varianceofFrame_first = variance(combined_frame_first(margin:(film_width_half-1-margin),margin:(film_height-1-margin)))
  medianofFrame_second = float(median(combined_frame_second(margin:(film_width_half-1-margin),margin:(film_height-1-margin))))
  varianceofFrame_second = variance(combined_frame_second(margin:(film_width_half-1-margin),margin:(film_height-1-margin)))

  deviation_first = sqrt(varianceofFrame_first)
  deviation_second = sqrt(varianceofFrame_second)

;deviation = 20

  cutoff_first = byte(medianofFrame_first + deviation_first)
  truncated_frame_first = float(combined_frame_first gt cutoff_first)*combined_frame_first
  cutoff_second = byte(medianofFrame_second + deviation_second)
  truncated_frame_second = float(combined_frame_second gt cutoff_second)*combined_frame_second

  window, 21, xsize = film_width_half, ysize = film_height, title = 'truncated_frame_first'
  tv, truncated_frame_first
  window, 22, xsize = film_width_half, ysize = film_height, title = 'truncated_frame_second'
  tv, truncated_frame_second

  WIDGET_CONTROL, text_ID, SET_VALUE=("median :" + STRING(medianofFrame)), /APPEND, /SHOW
  WIDGET_CONTROL, text_ID, SET_VALUE=("deviation, cutoff :" + STRING(deviation)+ STRING(float(cutoff))), /APPEND, /SHOW

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


	truncated_frame = truncated_frame_first
	modified_frame = modified_frame_first
	combined_frame = combined_frame_first
	temp = modified_frame_first
	temp_emphasized = truncated_frame_first
	minimum_intensity_matrix = minimum_intensity_matrix_first

	NumberofGoodLocations = 0
	NumberofBadLocations = 0

	for j = edge, film_height - edge -1 do begin
    	for i = edge, film_width_half - edge -1 do begin
			if truncated_frame_first(i,j) gt 0 then begin

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
								float_x_2 = float_x_2 + P(k,l) * float(float_x_1^l) * float(float_y_1^k)
								float_y_2 = float_y_2 + Q(k,l) * float(float_x_1^l) * float(float_y_1^k)
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


							wset, 21 ; window21 should be truncated_frame_first
							tv, temp_emphasized
							wset, 15 ;window15 should be modified_frame_first
							tv, temp

							GoodLocations_x(NumberofGoodLocations) = Max_location_x
							GoodLocations_y(NumberofGoodLocations) = Max_location_y
							Background_first(NumberofGoodLocations) = minimum_intensity_matrix_first(Max_location_x, Max_location_y)
							Background_second(NumberofGoodLocations) = minimum_intensity_matrix_second(Max_location_x, Max_location_y)
							NumberofGoodLocations++
							GoodLocations_x(NumberofGoodLocations) = x_2
							GoodLocations_y(NumberofGoodLocations) = y_2
							Background_first(NumberofGoodLocations) = minimum_intensity_matrix_first(x_2, y_2)
							Background_second(NumberofGoodLocations) = minimum_intensity_matrix_second(Max_location_x_2, Max_location_y_2)
							NumberofGoodLocations++
						endelse
					endif else begin
						NumberofBadLocations++
					endelse
				endif
			endif
		endfor
	endfor

  	window, 24, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_first'
  	tv, temp_first>0
	window, 25, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_second'
	tv, temp_second>0
	window, 27, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_first'

    WRITE_TIFF, run + "_peaks_first.tif", temp_first>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2
	WRITE_TIFF, run + "_peaks_second.tif", temp_second>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2

  	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations) + " good peaks circled for first laser."), /APPEND, /SHOW
  	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations) + " bad peaks."), /APPEND, /SHOW

	openw, 1, run + ".2colour_alex_pks"
	for i = 0, NumberofGoodLocations - 1 do begin
    	printf, 1, i+1, GoodLocations_x(i), GoodLocations_y(i),Background_first(i),Background_second(i)
	endfor
	if color_change_check eq 'y' then begin ;XOR ((film_time_start MOD 2) eq 0)) then begin
		printf, 1, 'y'
	endif else begin
		printf, 1, 'n'
	endelse
	close, 1

	WIDGET_CONTROL, text_ID, SET_VALUE="Done. Byebye~", /APPEND, /SHOW

end