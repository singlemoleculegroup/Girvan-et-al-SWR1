# 2colour_ALEX

Scripts for extraction and visualisation of smFRET data collected using 2 colour Alternating Laser EXcitation (ALEX). IDL(8.4) was used for data extraction and MATLAB (R2022-b) for data visualisation.

## Instrumentation setup
Switching on and off of the excitation lasers was achieved using two mechanical shutters (LS3 3mm, Uniblitz, Vincent Associates). Alternation of the opening and closing of the shutters used a JK flip-flop circuit, which was driven by the 'Fire output' of the camera (iXon Ultra 897, ANDOR) which synchronised the laser alternation with the camera exposure. Fluorescence emssision is spectrally separated using an OptoSplit II (Cairn Research) and projected side-by-side on the camera sensor. Our setup has the donor fluorescence emission on the left half of the camera and the acceptor fluorescence emission on the right half.

## Generating a mapping file
In order to map the two emission channels, a recording (50 - 100 frames is sufficient) of fluorescent beads is recorded. The fluorescent beads should emit in both emission channels. This beads recording can be acquired using direct single excitation, and doesn't require ALEX.
<details><summary>Mapping step by step guide</summary>

1. Open IDL and `mapping_maker.pro` 
2. Compile and run the script.
3. Navigate to and select the recording of the fluorescent beads
4. IDL will display the beads image and automatically identify fluorescent spots in both the donor and acceptor emission channels.
5. Use the mouse and left-click to select a single spot in the left hand side of the image for which there is the corresponding spot in the right half of the image. The script will automatically try and select the corresponding spot in the right half of the image, but depending on alignment and how crowded the image is this may fail and you will need to select the correct spot in the right half manually. Once the same spot is selected in both channels confirm the selection by right-clicking on the image.
6. Repeat step 5 two more times, to give a total of three pairs of spots. Try and spread out the three pairs as much as possible, e.g. bottom-left, top-middle and middle-right of the image.
7. The script will automatically pair the rest of the fluorescent spots in the image and output several files to check the mapping was successful, along with a mapping file `beadsFilename.map`.

</details>

## Extracting the raw data into single-molecule fluorescence intensity trajectories
The part requires three scripts, `smi_peak_location_maker_2colour_alex.pro`, `smi_preak_trace_maker_2colour_alex.pro` and `smi_analyze_all.pro`. In brief the 'location_maker' identifies single molecules within your raw data recordings, the 'trace_maker' extracts intensity trajectories from the identified single molecules, and 'analyze_all' allows the scripts to be run on a folder of many recordings, calling the relevant script in order for each of the recordings in the folder.

<details><summary>Extraction step by step guide</summary>

1. Open IDL and the three files, `smi_peak_location_maker_2colour_alex.pro`, `smi_preak_trace_maker_2colour_alex.pro` and `smi_analyze_all.pro`.
2. Complile (but do not run) `smi_peak_location_maker_2colour_alex.pro` and `smi_preak_trace_maker_2colour_alex.pro` first, then compile and run `smi_analyze_all.pro`.
3. Navigate to and select the folder containing the raw recordings.
4. Navigate to and select the mapping file created earlier `beadsFilename.map`.
5. The script will generate new files: average images under first and second laser excitation, '_ave_first.tif' and '_ave_second.tif'; combined donor and acceptor images under first and second laser excitation, '_com_first.tif' and '_com_second.tif'; an image where identified spots are circled, '_peaks_first.tif' and '_peaks_second.tif'; a list of the locations of each identified spot, '.2color_alex_pks' and a file containing the single-molecule fluorescence intensity trajectories for each identified spot, '.2color_alex_traces'.

</details>

## Visualising single-molecule fluorescence intensity trajectories
Visualisation of the extracted data from IDL above is preformed in MATLAB and uses a simple GUI that was written using MATLAB App Designer. In this step you go through all the single-molecules that IDL identified in your raw data above and curate the molecules based on selection criteria depending on your experimental setup (e.g. must have single donor and acceptor photobleaching event etc.).

<details><summary>Visualisation step by step guide</summary>

1. Open MATLAB and run the `FRET_ALEX_gui.m` script which will load a MATLAB app gui.
2. Use File->Load and open the `.2colour_alex_traces` created in the data extraction step above.
3. A simple gui shows the fluorescence intensity under first and second laser excitation. The calculated FRET and Stoichiometry plots are shown below. A FRET histogram, and an E−S histogram for the current molecule are shown in the bottom-right. The combined image (created in the data extraction step above) for the first and second laser excitation is shown in the top-right along with a zoom-in showing the current molecule being viewed.
4. The correction factor is shown in the bottom-left (Alpha - which corrects for donor fluorescence that is observed in the acceptor channel). This value should be measured for your FRET pair and adjusted in the code before running the script.
5. Navigation buttons at the bottom can be used to go to the next or previous molecule. Alternatively, the number of a molecule can be typed into the 'Trace' field and 'Go' clicked to go to that molecule number.
6. Zooming into a particular trace can be done by clicking a dragging across the relevant region in either the intensity or FRET plots. To un-zoom, double click on the intensity or FRET plots. Note: the histograms will not update automatically, if you want to update the histogram to reflect the zoomed in region click the 'Update Hist' button.
7. Clicking the 'Export' button will save a .txt file for the single-molecule fluorescence intensity trajectory of the currently displayed file, '_traces_mol#.txt'. This file contains the following columns: donor emission on donor excitation, acceptor emission on donor excitation, and acceptor emission on acceptor excitation. Note: if you have zoomed in on the trace an additional file '_zoom_mol#.txt' will also be saved showing just the donor emission on donor excitation and acceptor emission on donor excitation for the zoomed in region.

Note: currently the background subtraction buttons (Sub D etc.) don't do anything. So, make sure the background subtraction during data extraction in IDL works well.

After curating and extracting the single molecules of interest you can use the .txt files to plot FRET histograms, or further process the data using HMM software for example.

</details>

## Acknowledgments
These scripts were heavily based on existing scripts within the lab and from the following source [https://github.com/ashleefeng/singlemolecules](https://github.com/ashleefeng/singlemolecules).
