;
; semi-automated routine figure out how the 2 channels
; map onto each other. finds the mapping that gives
; the minimum error in the least squares sense.
;
; xf = ax + bx * xi + cx * yi
; yf = ay + by * xi + cy * yi
;
; hazen 2/99
;
; modified to use a rough mapping to find possible
; corresponding peaks as we finally gave up on the
; chromatic thing and use a different lens for each
; color. This means that the 2 colors have different
; magnifications and etcetera.
;
; hazen 5/99
;
; modified to use IDLs POLYWARP routine so that we can
; later use IDLs POLY_2D routine to overlay the left
; and right channels
;
; hazen 11/99
;
;cleaned up some of the code, added some code to make some pictures that allow better assesment of the map. Gaussian is still arbitrary.
;this is still a bit of a mess.
; MW 5-10-10
;

loadct, 5

COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

circle = bytarr(11,11)

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

; generate gaussian peaks

g_peaks = fltarr(3,3,7,7)

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

; get file to open

run = "asdf"

print, "C:\Data\"
read, run

film_x = fix(1)
film_y = fix(1)
fr_no  = fix(1)

;;; input film

close, 1          ; make sure unit 1 is closed

dir = "C:\Data\"
openr, 1, dir + run + ".pma"

; figure out size + allocate appropriately

result = FSTAT(1)
readu, 1, film_x
readu, 1, film_y
film_l = UINT(DOUBLE(result.SIZE-4)/(((DOUBLE(film_x)*DOUBLE(film_y))+1)*2))

print, "film x,y,l : ", film_x,film_y,film_l

if film_l gt 30 then film_l = 30

window, 0, xsize=film_x, ysize=film_y
;frame   = bytarr(film_x,film_y) Changed by RZ 05/04/06
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
    for j = 0, film_l - 1 do begin
       if((j mod 5) eq 0) then print, j, film_l
       readu, 1, fr_no
       readu, 1, frame
       ave_arr = ave_arr + frame
    endfor
    close, 1
    ave_arr = ave_arr/float(film_l)
    frame = (ave_arr)

    ; frame = smooth(frame,2,/EDGE_TRUNCATE)
    WRITE_TIFF, dir + run + "_ave.tif", frame, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
    WRITE_TIFF, dir + run + "_ave_normalized.tif",255*(frame-min(frame))/(max(frame)-min(frame)) , RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
endelse

; subtracts background

temp1 = frame
temp1 = smooth(temp1,2,/EDGE_TRUNCATE)

aves = fltarr(film_x/16,film_y/16)

for i = 8, film_x, 16 do begin
    for j = 8, film_y, 16 do begin
       aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7))
    endfor
endfor

aves = rebin(aves,film_x,film_y)
aves = smooth(aves,20,/EDGE_TRUNCATE)

temp1 = frame - (uint(aves) - 10)

; thresholds the image for peak finding purposes

temp2 = temp1
med = float(median(temp1))
stf = moment(temp1)

;std = sqrt(stf(1))
std = 15
;std = 8

for i = 0, film_x - 1 do begin
    for j = 0, film_y - 1 do begin
       if temp2(i,j) lt byte(med + std) then temp2(i,j) = 0
    endfor
endfor

; window, 1, xsize=84, ysize=84, xpos = 720, ypos = 580
wset, 0
;tvscl, temp2
tvscl, temp1

; find the peaks

temp3 = frame
temp4 = temp3
wset, 0

good = fltarr(2,4000)
foob = bytarr(7,7)
diff = fltarr(3,3)

no_good = 0

for i = 10, film_x - 11 do begin
    if i eq 246 then i = 266   ; skip region where channels overlap
    for j = 10, film_y - 11 do begin
       if temp2(i,j) gt 0 then begin

         ; find the nearest maxima

         foob = temp2(i-3:i+3,j-3:j+3)
         z = max(foob,foo)
         y = foo / 7 - 3
         x = foo mod 7 - 3

         ; only analyze peaks in current column,
         ; and not near edge of area analyzed

         if x eq 0 then begin
          if y eq 0 then begin
              y = y + j
              x = x + i

              ; check if its a good peak
              ; i.e. surrounding points below 1 stdev

              quality = 1
              for k = -5, 5 do begin
                 for l = -5, 5 do begin
                   if circle(k+5,l+5) gt 0 then begin
                    if temp1(x+k,y+l) gt byte(med + 0.5 * float(z)) then quality = 0
                   endif
                 endfor
              endfor

              if quality eq 1 then begin

                 ; draw where peak was found on screen

                 for k = -5, 5 do begin
                   for l = -5, 5 do begin
                    if circle(k+5,l+5) gt 0 then begin
                        temp4(x+k,y+l) = 90
                    endif
                   endfor
                 endfor
                 wset, 0
                 tv, temp4

                 ; compute difference between peak and gaussian peak
;block to account for the case where best_x and best_y are not assigned. If that happens, it probably means that the average file is incorrect(intensities are wrapping
; around in the colour map, or something else that is nonstandard. There should be some error checking here and in many places in the programs, but would be alot of work.
                      best_x = 1
                        best_y = 1
                        ;endblock

                 cur_best = 10000.0
                 for k = 0, 2 do begin
                   for l = 0, 2 do begin
                    diff(k,l) = total(abs((float(z) - aves(x,y)) * g_peaks(k,l,*,*) - (float(temp1(x-3:x+3,y-3:y+3)) - aves(x,y))))
                    if diff(k,l) lt cur_best then begin
                        best_x = k
                        best_y = l
                        cur_best = diff(k,l)
                    endif
                   endfor
                 endfor

                 good(0,no_good) = float(x) - 0.5*float(best_x-1)
                 good(1,no_good) = float(y) - 0.5*float(best_y-1)
                 no_good = no_good + 1
                 temp3 = temp4
              endif
          endif
         endif
       endif
    endfor
endfor

print, "there were ", no_good, "good peaks"

; now sift through for the peaks that appear in both channels

pxl = fix(1)
pyl = fix(1)
pxr = fix(1)
pyr = fix(1)

diff_x = 254
diff_y = 1

x_i = intarr(1,1000) ; all were (1,600); DR: June 2004
y_i = intarr(1,1000)
x_f = intarr(1,1000)
y_f = intarr(1,1000)

no_pairs = 0

; load coefficients for rough map

trans_x = fltarr(3)
trans_y = fltarr(3)
foo = float(1)


print, "using " + dir + run + ".coeff"
openr, 1, dir + run + ".coeff"

;openr, 1, "rough.coeff"
for j = 0, 2 do begin
    readf, 1, foo
    trans_x(j) = foo
endfor
for j = 0, 2 do begin
    readf, 1, foo
    trans_y(j) = foo
endfor
close, 1

; find peaks that have approximately this spacing
 temp5=255*(temp4-min(temp4))/(max(temp4)-min(temp4))
for i = 0, no_good - 1 do begin
    if good(0,i) lt 256 then begin

       ; calculate location of pair

       xf = trans_x(0) + trans_x(1)*float(good(0,i)) + trans_x(2)*float(good(1,i))
       yf = trans_y(0) + trans_y(1)*float(good(0,i)) + trans_y(2)*float(good(1,i))
       for j = i + 1, no_good - 1 do begin
         if abs(good(0,j) - xf) lt 3 then begin
          if abs(good(1,j) - yf) lt 3 then begin

              ; temp4 = temp3

              ; circle the two peaks

              for k = -5, 5 do begin
                 for l = -5, 5 do begin
                   if circle(k+5,l+5) gt 0 then begin
                    temp5(good(0,i)+k,good(1,i)+l) = 255
                    temp5(good(0,j)+k,good(1,j)+l) = 255
                   endif
                 endfor
              endfor

              tv, temp5

              x_i(no_pairs) = good(0,i)
              y_i(no_pairs) = good(1,i)
              x_f(no_pairs) = good(0,j) - 256
              y_f(no_pairs) = good(1,j)
              no_pairs = no_pairs + 1

          endif
         endif
       endfor
    endif
endfor

if no_pairs gt 16 then begin

    print, "found ", no_pairs, " pairs"

    POLYWARP, x_f, y_f, x_i, y_i, 3, P, Q

    openw, 1, dir + run + ".map"

    for i = 0, 15 do begin
       printf, 1, P(i)
    endfor
    for i = 0, 15 do begin
       printf, 1, Q(i)
    endfor
    close, 1

endif else begin
    print, "not enough matches"
endelse

print, P
print, Q

;this block added to print out better images for assement of the map, MW 5-6-10
;there are alot of ways and places you can look at how well the map is doing it's job. The ones I have found the most useful are the ones that are not commented out
;the rest are left there for people to see and perhaps experiment with. There may still be some problems here, but seems to work reasonably well.

left  = frame(0:255,0:511)
right = frame(256:511,0:511)

right = POLY_2D(right, P, Q, 2)
;combined = left/2 + right/2


leftmarc = frame(0:255,0:511)
rightmarc = frame(256:511,0:511)
rightmarcw = POLY_2D(rightmarc, P, Q, 2)
;combinedmarcw = leftmarc/2 +rightmarcw/2
;combinedmarc = leftmarc/2 +rightmarc/2
;combinedmarc2 = 255*(combinedmarc-min(combinedmarc))/(max(combinedmarc)-min(combinedmarc))



leftmarc = 255*(leftmarc-min(leftmarc))/(max(leftmarc)-min(leftmarc))
;rightmarc = 255*(rightmarc-min(rightmarc))/(max(rightmarc)-min(rightmarc))
rightmarcw = 255*(rightmarcw-min(rightmarcw))/(max(rightmarcw)-min(rightmarcw))


;combinedmarclr= leftmarc +rightmarc
;combinedmarclr3 = 255*(combinedmarclr-min(combinedmarclr))/(max(combinedmarclr)-min(combinedmarclr))


combinedmarcw = (leftmarc-rightmarcw)/2+255
combinedmarcw2 = 255*(combinedmarcw-min(combinedmarcw))/(max(combinedmarcw)-min(combinedmarcw))

;combinedmarcwa = leftmarc+rightmarcw
;combinedmarcwa2 = 255*(combinedmarcwa-min(combinedmarcwa))/(max(combinedmarcwa)-min(combinedmarcwa))

WRITE_TIFF, dir + run + "marcleft.tif", leftmarc, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, dir + run + "marcright.tif", rightmarc, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
WRITE_TIFF, dir + run + "marcrightwarped.tif", rightmarcw, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, dir + run + "combinedmarc_oldcolour.tif", combinedmarcw2, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, run + "combinedmarcw.tif", combinedmarcw, 1

;this block creates a colour table that goes from red to blue, this sort of procedure can flexibly create color tables with many differnt profiles
;this is used to create an image (combined_redtoblue.tif) that emphasizes the places where the two channels don't overlap, ie the intensity data is mostly thrown out and
;the excess of one channel over is displayed, this may not be working perfectly.
steps = 255
   greenVector = REPLICATE(0, steps) ;creates a 0 to 255 vector of 0
   scaleFactor = FINDGEN(steps) / (steps - 1) ;creates a floating point vector 0 to 255 with the values equal to indexes, then normalizes them to lie between
   ;0 and 1, this may be off by one, but don't want to track it down now; it's close to what it should be.
   beginNum = 255
   endNum = 0
   redVector = beginNum + (endNum - beginNum) * scaleFactor ;this creates a red vector, 255 to 0 in steps of 1
   blueVector = endNum + (beginNum - endNum) * scaleFactor ; this creates a blue vector, 0 to 255 in steps of 1

TVLCT, redVector, greenVector, blueVector ;loads the vectors as a colour table
zeroarray=fltarr(256,512) ;creates an 256X512 array of 0

WRITE_TIFF, dir + run + "combined_redtoblue.tif", combinedmarcw2, 1, RED = redVector, GREEN = greenVector, BLUE = blueVector ;write a pseudo colour (8 bit) image

;write out true colour (24 bit) images of the combined channels, normalized each channel independently
;the below line outputs a red/green image, where the overlap is yellow
write_tiff, dir + run + "truecolorleft_right110.tif", Red=255*(left-min(left))/(max(left)-min(left)), Green=255*(right-min(right))/(max(right)-min(right)), Blue=zeroarray, PLANARCONFIG=2

;The two lines below output overlapped images in green/blue and red/blue
;write_tiff, dir + run + "truecolorleft_right011.tif", Red=zeroarray, Green=255*(left-min(left))/(max(left)-min(left)), Blue=255*(right-min(right))/(max(right)-min(right)), PLANARCONFIG=2
;write_tiff, dir + run + "truecolorleft_right101.tif", Red=255*(left-min(left))/(max(left)-min(left)), Green=zeroarray, Blue=255*(right-min(right))/(max(right)-min(right)), PLANARCONFIG=2




;this block will print out quite a few images to give a feel for what IDL's internal colour tables are like.
;for ii=0, 40 do begin
;loadct,ii
;WRITE_TIFF, run + "combined_colortable_warped_subtracted" + string(ii) + ".tif", combinedmarcw2, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, run + "combined_colortable_warped_added" + string(ii) + ".tif", combinedmarcwa2, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, run + "combined_colortable_nowarp" + string(ii) + ".tif", combinedmarc2, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;WRITE_TIFF, run + "combined_colortable_nowarp_normalizedbefaddn" + string(ii) + ".tif", combinedmarclr3, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;endfor

loadct,5 ; back to original colour table

;the block below will output some smoothed images if you care to see what the smoothing function can do.

;leftmarcsm=smooth (leftmarc,7)
;rightmarcsm=smooth (rightmarc,7)
;combinedmarcsm=smooth (combinedmarc,7)
;rightmarcwsm=smooth (rightmarcw,7)
;combinedmarcwsm=smooth (combinedmarcw,7)

;WRITE_TIFF, run + "marcleftsm.tif", leftmarcsm, 1
;WRITE_TIFF, run + "marcrightsm.tif", rightmarcsm, 1
;WRITE_TIFF, run + "marcrightwsm.tif", rightmarcwsm, 1
;WRITE_TIFF, run + "combinedmarcsm.tif", combinedmarcsm, 1
;WRITE_TIFF, run + "combinedmarcwsm.tif", combinedmarcwsm, 1


end