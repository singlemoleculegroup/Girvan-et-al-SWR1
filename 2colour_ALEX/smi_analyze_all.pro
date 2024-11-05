
pro smi_analyze_all

	; Custumizing parameters
	windows_close = 'no'
	path = 'X:\data_folder\'
	mapfile = 'X:\singlemolecules\smfret3color\example\beads.map'
	
	;Program start

	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	path = DIALOG_PICKFILE(PATH='C:\Data\', TITLE='Select Working Directory', /DIRECTORY)
	cd, path

	mapfile = DIALOG_PICKFILE(PATH='C:\Data\', TITLE='Select Mapping File', /READ, FILTER = '*.map')

	filelist = FILE_SEARCH(path, '*.pma', COUNT=file_number, /EXPAND_ENVIRONMENT)

	xdisplayFile, '', TEXT=(STRING(file_number)+ " files are found."), RETURN_ID=display_ID, WTEXT=text_ID

	for j = 0, file_number - 1 do begin
		filelist(j) = strmid(filelist(j), 0, strlen(filelist(j)) - 4)

		if FILE_TEST(filelist(j) + ".pma") eq 1 then begin
			if FILE_TEST(filelist(j) + ".2colour_alex_pks") eq 0 and FILE_TEST(filelist(j) + ".pks") eq 0 then begin	; .pks file doesn't exist.
				WIDGET_CONTROL, text_ID, SET_VALUE=("Working on (" + STRING(j) + ") : " + filelist(j) + ".pma"), /APPEND
				smi_peak_location_maker_2colour_alex, filelist(j), mapfile, text_ID					; .pks file generator
			endif

			if FILE_TEST(filelist(j) + ".2color_2alex_traces") eq 0 then begin							; .traces file doesn't exist.
				smi_peak_trace_maker_2color_alex, filelist(j), text_ID										; .traces file generator
			endif
		endif
	endfor

	WIDGET_CONTROL, text_ID, SET_VALUE="Done. End of ana_all.", /APPEND

	if windows_close eq 'Yes' then begin
		WIDGET_CONTROL, display_ID, /DESTROY
		wdelete, 0
		wdelete, 1
	endif

end
