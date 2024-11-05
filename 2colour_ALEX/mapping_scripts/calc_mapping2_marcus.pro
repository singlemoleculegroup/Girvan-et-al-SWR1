
; calculates mapping from one channel to the other
; for two color images
;
; Hazen 1/99
;

;pro calc_mapping2, run
loadct, 5

;COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

circle = bytarr(11,11)

circle(*,0) = [ 0,0,0,0,1,1,1,0,0,0,0]
circle(*,1) = [ 0,0,1,1,0,0,0,1,1,0,0]
circle(*,2) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,3) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,4) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,5) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,6) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,7) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,8) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,9) = [ 0,0,1,1,0,0,0,1,1,0,0]
circle(*,10)= [ 0,0,0,0,1,1,1,0,0,0,0]

; get file to open

run = "beads1"

print, "C:\Data\"
read, run

dir = "C:\Data\"
openr, 1, dir + run + ".pma"

; figure out size + allocate appropriately

film_x = fix(1)
film_y = fix(1)
fr_no  = fix(1)
result = FSTAT(1)

readu, 1, film_y
readu, 1, film_x

film_l = UINT(DOUBLE(result.SIZE-4)/(((DOUBLE(film_x)*DOUBLE(film_y))+1)*2))
print, "film x,y,l : ", film_x,film_y,film_l

;if film_l gt 30 then
film_l = 30

window, 0, xsize=film_x, ysize=film_y
frame   = uintarr(film_x,film_y)
ave_arr = fltarr(film_x,film_y)

openr, 2, dir + run + "_ave.tif", ERROR = err
if err eq 0 then begin
    close, 1
    close, 2
    frame = read_tiff(dir + run + "_ave.tif")
endif else begin
    close, 2

    ; compute average image and write it our for potential later use

    ; throw out first x seconds

    ;print, "throwing out x seconds"
    ;for j = 0, 50 do begin
    ;  readu, 1, fr_no
    ;  readu, 1, frame
    ;endfor
    for j = 1, film_l  do begin
       if((j mod 5) eq 0) then print, j, film_l
       readu, 1, fr_no
;       print, "fr_no =", fr_no
       readu, 1, frame
;       tv, frame
;       wait, 10
       ave_arr = ave_arr + frame
    endfor
    close, 1
;    tv, ave_arr
    ave_arr = ave_arr/(film_l)

;this block normalizes each channel individually and writes out some pictures to see the effect
    eqnormalL=255*(ave_arr(0:255,0:511)-min(ave_arr(0:255,0:511)))/(max(ave_arr(0:255,0:511))-min(ave_arr(0:255,0:511)))
    eqnormalR=255*(ave_arr(256:511,0:511)-min(ave_arr(256:511,0:511)))/(max(ave_arr(256:511,0:511))-min(ave_arr(256:511,0:511)))
    eqnormal=[eqnormalL,eqnormalR]
    WRITE_TIFF, dir + run + "eqnormalL.tif", eqnormalL, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
    WRITE_TIFF, dir + run + "eqnormalR.tif", eqnormalR, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
    WRITE_TIFF, dir + run + "eqnormal.tif", eqnormal, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;end block

ave_arr=eqnormal

;    ave_arr(0:255,0:511)=ave_arr(0:255,0:511)/1.2; this looks like a empirical channel weighting, the above block normalizes each channel individually.
;    wait, 10000
;    ave_arr = ave_arr/float(30)



    temp5=255*(ave_arr-min(ave_arr))/(max(ave_arr)-min(ave_arr))
    WRITE_TIFF, dir + run + "_ave.tif", temp5, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG ; i think this should be normalized by channel not by the whole image.
    ;the above image is used for peak finding in the nxg_cm module
    frame = ave_arr

    ; frame = smooth(frame,2,/EDGE_TRUNCATE)

endelse
       maxn=max(frame)
       minn=min(frame)
       temp=255*(frame-minn)/(maxn-minn)
tv, temp


; first, have user figure out image corresondence

x_i = fltarr(3)
y_i = fltarr(3)
x_f = fltarr(3)
y_f = fltarr(3)
trans_mat = fltarr(3,3)

A = 'd'

for j = 0, 2 do begin

    x = fix(1)
    y = fix(1)
    print, "click on spot in left image"
    cursor,x,y,3,/device
    x_i(j) = x
    y_i(j) = y
    ;print, "click on spot in right image;
    ;cursor,x,y,3,/device
    x_f(j) = x_i(j) + 256
    y_f(j) = y_i(j) + 0

    print, "use keyboard to tweak, <s> to stop"
    A = 'd'
    while A ne 's' do begin
         temp2=temp
             ; show spots the user picked

       for k = -5, 5 do begin
         for l = -5, 5 do begin
          if circle(k+5,l+5) gt 0 then begin
              temp2(x_i(j)+k,y_i(j)+l) = 255
              temp2(x_f(j)+k,y_f(j)+l) = 255
          endif
         endfor
       endfor
       wset, 0
       tv, temp2

       A = get_kbrd(1)
       case A of
         'r' : y_i(j) = y_i(j)+1
         'f' : x_i(j) = x_i(j)+1
         'c' : y_i(j) = y_i(j)-1
         'd' : x_i(j) = x_i(j)-1
         'y' : y_f(j) = y_f(j)+1
         'h' : x_f(j) = x_f(j)+1
         'b' : y_f(j) = y_f(j)-1
         'g' : x_f(j) = x_f(j)-1
         else : A = A
       endcase
    endwhile
    temp =byte(temp2)
endfor

; set up matrices

trans_mat(0,*) = 1.0
trans_mat(1,*) = x_i
trans_mat(2,*) = y_i

inv_mat = invert(trans_mat)

; calculate coefficients and save coefficients

openw, 1, dir + run + ".coeff"
printf, 1, total(inv_mat(*,0) * x_f)
printf, 1, total(inv_mat(*,1) * x_f)
printf, 1, total(inv_mat(*,2) * x_f)
printf, 1, total(inv_mat(*,0) * y_f)
printf, 1, total(inv_mat(*,1) * y_f)
printf, 1, total(inv_mat(*,2) * y_f)
close, 1

print, total(inv_mat(*,0) * x_f)
print, total(inv_mat(*,1) * x_f)
print, total(inv_mat(*,2) * x_f)
print, total(inv_mat(*,0) * y_f)
print, total(inv_mat(*,1) * y_f)
print, total(inv_mat(*,2) * y_f)

; running nxgn1_cm

; nxgn1_cm

end