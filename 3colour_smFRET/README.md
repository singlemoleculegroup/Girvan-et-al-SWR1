# SMI Scripts for 3 colour TIRF
Scripts for extraction and visualisation of smFRET data collected using 3 colour imaging (two excitation lasers and three emission channels). LabVIEW was uses for camera and laser synchronisation, IDL(8.4) was used for data extraction and MATLAB (R2022-b) for data visualisation.

## Instrument setup
Fluorescence emission is spectrally separated using a MultiSplit (Cairn Research) giving four different emission channels which are imaged over four quadrants of the sCMOS camera.

Only channels 1, 2 & 3 are used which correspond to Alexa Fluor 488, Alexa Fluor 555, and Atto647N emission respectively.

Data is acquired using alternating laser excitation, switching between 488 nm and 637 nm lasers. The alternation of the lasers and synchronisation with the camera is via a NI-DAQ (USB-6341) and the `sync_laser_and_camera.vi` script in LabVIEW.

## Generating a mapping file
In order to map the three emission channels, a recording (50 - 100 frames is sufficient) of fluorescent beads is recorded. The fluorescent beads should emit in all emission channels. This beads recording can be acquired using direct single excitation, and doesn't require alternating excitation. 

<details><summary>Mapping step by step guide</summary>

1. Open IDL and `mapping_maker.pro`.
2. Compile and run the script.
3. Navigate to and select the recording of the fluorescent beads.
4. IDL will display the beads image and automatically identify fluorescent spots in the three (donor, acceptor and colocalization) emission channels.
5. Use the mouse and left-click to select a single spot in the channel 1 quadrant of the image for which there are corresponding spots in channels 2 and 3. The script will automatically try and select the corresponding spots in channels 2 and 3, but depending on alignment and how crowded the image is this may fail and you will need to select the correct spot in the other channels manually. Once the same spot is selected in the three channels, confirm the selection by right-clicking on the image.
6. Repeat step 5 two more times, to give a total of three spots. Try and spread out the three spots as much as possible, e.g. bottom-left, top-middle and middle-right of the quadrant.
7. The script will automatically pair the rest of the fluorescent spots in the image and output several files to check the mapping was successful, along with a mapping file `mappingFilename.map`.

</details>

## Extracting single-molecule fluorescence intensity trajectories from the raw data

This part requires three scripts, `smi_peak_location_maker_3color_alex.pro`, `smi_preak_trace_maker_3color_alex.pro` and `smi_analyze_all.pro`. In brief the 'location_maker' identifies single molecules within your raw data recordings, the 'trace_maker' extracts intensity trajectories from the identified single molecules, and 'analyze_all' allows the scripts to be run on a folder of many recordings, calling the relevant script in order for each of the recordings in the folder.

<details><summary>Extracting step by step guide</summary>

1. Open IDL and the three files, `smi_peak_location_maker_3color_alex.pro`, `smi_preak_trace_maker_3color_alex.pro` and `smi_analyze_all.pro`.
2. Compile (but do not run) `smi_peak_location_maker_3color_alex.pro` and `smi_preak_trace_maker_3color_alex.pro` first, then compile and run `smi_analyze_all.pro`.
3. Navigate to and select the folder containing the raw recordings.
4. Navigate to and select the mapping file created earlier `mappingFilename.map`.
5. The script will generate new files: average images under first and second laser excitation, '_ave_first.tif' and '_ave_second.tif'; combined donor and acceptor images under first and second laser excitation, '_com_first.tif' and '_com_second.tif'; an image where identified spots are circled, '_peaks_first.tif' and '_peaks_second.tif'; a list of the locations of each identified spot, '.3color_alex_pks' and a file containing the single-molecule fluorescence intensity trajectories for each identified spot, '.3color_alex_traces'.

</details>

## Visualising single-molecule fluorescence intensity trajectories
Visualisation of the extracted data from IDL above is preformed in MATLAB and uses a simple GUI that was written using MATLAB App Designer. In this step you go through all the single-molecules that IDL identified in your raw data above and curate the molecules based on selection criteria depending on your experimental setup (e.g. must have single donor and acceptor photobleaching event etc.).

<details><summary>Visualisation step by step guide</summary>

1. Open MATLAB and run the FRET_GUI_3colour.m script which will load a MATLAB app gui.
2. Use File->Load and open the `.3color_alex_traces` created in the data extraction step above.
3. A simple gui shows the fluorescence intensity under blue (donor) and red (colocalisation) laser excitation. The calculated FRET (blue-green) is shown below. A sum of the donor and acceptor signals is shown at the right. A FRET histogram for the current molecule is shown in the bottom-right. The combined image (created in the data extraction step above) for the blue (donor) and red (colocalization) laser excitation is shown in the top-right along with a zoom-in showing the current molecule being viewed.
4. The correction factor is shown in the bottom-left (Alpha - which corrects for fluorescence bleed through into other channels(blue emission into the green channel, and green emission into the red channel)). This value should be measured for your fluorophores and adjusted in the code before running the script.
5. Navigation buttons at the top can be used to go to the next or previous molecule. Alternatively, the number of a molecule can be typed into the 'Current Trace' field and 'Apply' clicked to go to that molecule number.
6. Zooming into a particular trace can be done by clicking a dragging across the relevant region in either the intensity or FRET plots. To un-zoom, double click on the intensity or FRET plots. Note: the histograms will not update automatically, if you want to update the histogram to reflect the zoomed in region click the 'Update Hist' button.
7. Clicking the 'Save Trace' button will save a .dat file for the single-molecule fluorescence intensity trajectory of the currently displayed molecule. The files that are saved can be selected using the 'Options' tab at the top of the GUI. 'Trace File' contains the following columns: donor and acceptor intensities upon donor excitation, calculated FRET and the fluorescence intensity of the colocalization channel. 'HMM File' contains the donor and acceptor intensities upon donor excitation for the zoomed in region currently displayed.

After curating and extracting the single molecules of interest you can use the .dat files to plot FRET histograms, or further process the data using HMM software for example. 

</details>

## Acknowledgments
These scripts were heavily based on existing scripts within the lab and from the following source [https://github.com/ashleefeng/singlemolecules](https://github.com/ashleefeng/singlemolecules).
