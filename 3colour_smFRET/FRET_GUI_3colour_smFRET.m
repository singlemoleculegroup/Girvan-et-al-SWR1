classdef FRET_GUI_3colour_smFRET < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        LoadDataMenu                  matlab.ui.container.Menu
        TabGroup                      matlab.ui.container.TabGroup
        ColourFRETTab                 matlab.ui.container.Tab
        AlphaCorrectionFactorsPanel   matlab.ui.container.Panel
        GreentoRedEditField           matlab.ui.control.NumericEditField
        GreentoRedEditFieldLabel      matlab.ui.control.Label
        BluetoGreenEditField          matlab.ui.control.NumericEditField
        BluetoGreenEditFieldLabel     matlab.ui.control.Label
        FileNameTextArea              matlab.ui.control.TextArea
        FileNameTextAreaLabel         matlab.ui.control.Label
        G_exDisplayPanel              matlab.ui.container.Panel
        Green_RedCheckBox             matlab.ui.control.CheckBox
        Green_GreenCheckBox           matlab.ui.control.CheckBox
        Green_BlueCheckBox            matlab.ui.control.CheckBox
        B_exDisplayPanel              matlab.ui.container.Panel
        Blue_RedCheckBox              matlab.ui.control.CheckBox
        Blue_GreenCheckBox            matlab.ui.control.CheckBox
        Blue_BlueCheckBox             matlab.ui.control.CheckBox
        subtractionButtonGroup_green  matlab.ui.container.ButtonGroup
        SubtractCh3Button_green       matlab.ui.control.Button
        SubtractCh2Button_green       matlab.ui.control.Button
        SubtractCh1Button_green       matlab.ui.control.Button
        subtractionButtonGroup_blue   matlab.ui.container.ButtonGroup
        SubtractCh3Button             matlab.ui.control.Button
        SubtractCh2Button             matlab.ui.control.Button
        SubtractCh1Button             matlab.ui.control.Button
        FRETTypeButtonGroup           matlab.ui.container.ButtonGroup
        G_exGRFRETButton              matlab.ui.control.RadioButton
        B_exBGFRETButton              matlab.ui.control.RadioButton
        Average                       matlab.ui.control.NumericEditField
        AverageptsLabel               matlab.ui.control.Label
        ofEditField                   matlab.ui.control.NumericEditField
        ofEditFieldLabel              matlab.ui.control.Label
        CurrentEditField              matlab.ui.control.NumericEditField
        CurrentTraceLabel             matlab.ui.control.Label
        UpdateHistButton              matlab.ui.control.Button
        SaveTraceButton               matlab.ui.control.Button
        ApplyButton                   matlab.ui.control.Button
        NextTraceButton               matlab.ui.control.Button
        PrevTraceButton               matlab.ui.control.Button
        UIAxesTraceSum                matlab.ui.control.UIAxes
        UIAxesFig_1                   matlab.ui.control.UIAxes
        UIAxesFig_1Z                  matlab.ui.control.UIAxes
        UIAxesFig_2                   matlab.ui.control.UIAxes
        UIAxesFig_2Z                  matlab.ui.control.UIAxes
        UIAxesHist                    matlab.ui.control.UIAxes
        UIAxesFRET                    matlab.ui.control.UIAxes
        UIAxesTraceBlue               matlab.ui.control.UIAxes
        UIAxesTraceRed                matlab.ui.control.UIAxes
        OptionsTab                    matlab.ui.container.Tab
        ExportFIleTickboxesofchosenfiletypestoexportPanel  matlab.ui.container.Panel
        Label                         matlab.ui.control.Label
        DonorandAcceptoronlyLabel     matlab.ui.control.Label
        DonorAcceptorFRETCoLocChannelLabel  matlab.ui.control.Label
        HMMFileCheckBox               matlab.ui.control.CheckBox
        TraceFileCheckBox             matlab.ui.control.CheckBox
    end

    
    properties (Access = private)
        channel1_blue % Blue Channel under blue excitation
        channel2_blue % Green Channel under blue excitation
        channel3_blue % Red Channel under blue excitation
        channel1_red % Blue Channel under red excitation
        channel2_red % Green Channel under red excitation
        channel3_red % Red Channel under red excitation
        CurrenTraceNumber % Current trace number 
        CurrentTraceCh1Blue % Current trace for display in blue excitation plot
        CurrentTraceCh2Blue % Current trace for display in blue excitation plot
        CurrentTraceCh3Blue % Current trace for display in blue excitation plot
        PksList % coordinates of each trace on the average image exported from IDL
        ave_imageFirst % IDL averge image
        ave_imageSecond % IDL averge image
        PksFileName % Description
        NameFile % Description
        CurrentTraceData % Description
        CurrentTraceCh1Red % Current trace for display in red excitation plot
        CurrentTraceCh2Red % Current trace for display in red excitation plot
        CurrentTraceCh3Red % Current trace for display in red excitation plot
        DialogWindow % Description
        trace_xlim %current limits of trace x axis
        FRET_xlim %current limits of FRET x axis
        linkXLim %needed to link the x axis zoom (see startupFcn)
        ch1ch2leak %alpha value for bleadthrough of ch1 fluorescence into ch2
        ch2ch3leak %alpha value for bleadthrough of ch2 fluorescence into ch3
        corrCurrentTraceCh2Blue %alpha corrected ch2 trace 
        corrCurrentTraceCh3Red %alpha corrected ch3 trace 
    end
    
    properties (Access = public)
    end
    
    methods (Access = private)
        
        
        function updateFRET(app)
            
           % blue green FRET
           B_exBGFRET = app.corrCurrentTraceCh2Blue./(app.corrCurrentTraceCh2Blue+app.CurrentTraceCh1Blue);

            %green red FRET
            G_exGRFRET = app.corrCurrentTraceCh3Red./(app.corrCurrentTraceCh3Red+app.CurrentTraceCh2Red);           
            
            %blue green Sum
            B_exSum = app.CurrentTraceCh1Blue+app.corrCurrentTraceCh2Blue;
            %green red Sum
            G_exSum = app.CurrentTraceCh1Red+app.corrCurrentTraceCh3Red;
            
            if app.FRETTypeButtonGroup.SelectedObject == app.B_exBGFRETButton
                plot(app.UIAxesFRET,B_exBGFRET,'k');
                hold(app.UIAxesFRET, 'on');
                %axis([0 inf -0.2 1.2]);
                %tb = axtoolbar({'datacursor','zoomin', 'zoomout', 'pan','restoreview'});
                hold(app.UIAxesFRET, 'off');
                plot(app.UIAxesTraceSum,B_exSum)
            else 
                plot(app.UIAxesFRET,G_exGRFRET,'k');
                hold(app.UIAxesFRET, 'on');
                %axis([0 inf -0.2 1.2]);
                %tb = axtoolbar({'datacursor','zoomin', 'zoomout', 'pan','restoreview'});
                hold(app.UIAxesFRET, 'off');
                plot(app.UIAxesTraceSum,G_exSum)
            end 


            
            
        end
        
        function updateHist(app)
            % blue green FRET
           B_exBGFRET = app.corrCurrentTraceCh2Blue./(app.corrCurrentTraceCh2Blue+app.CurrentTraceCh1Blue);

            %green red FRET
            G_exGRFRET = app.corrCurrentTraceCh3Red./(app.corrCurrentTraceCh3Red+app.CurrentTraceCh2Red);           
                        
            xl = xlim(app.UIAxesFRET);% returns x-limts as vector 
            xl_int = int32(xl);% bins 32 integer 
            if xl_int(1) < 1 % if row 1 column1 < 1 --> make it = 1
                xl_int(1) = 1;
            end 
            if xl_int(2)> length(app.CurrentTraceCh1Blue)
                xl_int(2) = length(app.CurrentTraceCh1Blue);
            end


            if app.FRETTypeButtonGroup.SelectedObject == app.B_exBGFRETButton
                histogram(app.UIAxesHist, B_exBGFRET(xl_int(1):xl_int(2)), 'Normalization','pdf','BinWidth',0.05,'BinLimits',[-0.2,1.2]);
            else 
                histogram(app.UIAxesHist, G_exGRFRET(xl_int(1):xl_int(2)), 'Normalization','pdf','BinWidth',0.05,'BinLimits',[-0.2,1.2]);
            end 
           
        end
        
        function updateTrace(app)
            %%%plot the data from the blue excitation

            if app.Blue_BlueCheckBox.Value
                plot(app.UIAxesTraceBlue,app.CurrentTraceCh1Blue,'b');
                hold(app.UIAxesTraceBlue, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            if app.Blue_GreenCheckBox.Value
                app.corrCurrentTraceCh2Blue = app.CurrentTraceCh2Blue - app.ch1ch2leak*app.CurrentTraceCh1Blue;
                plot(app.UIAxesTraceBlue,app.corrCurrentTraceCh2Blue, 'color', '#00611C');
                hold(app.UIAxesTraceBlue, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            if app.Blue_RedCheckBox.Value
                plot(app.UIAxesTraceBlue,app.CurrentTraceCh3Blue,'r');
                hold(app.UIAxesTraceBlue, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            hold(app.UIAxesTraceBlue, 'off');
            
            %%%plot the data from the red excitation
            if app.Green_BlueCheckBox.Value
                plot(app.UIAxesTraceRed,app.CurrentTraceCh1Red,'b');
                hold(app.UIAxesTraceRed, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            if app.Green_GreenCheckBox.Value
                plot(app.UIAxesTraceRed,app.CurrentTraceCh2Red, 'color', '#00611C');
                hold(app.UIAxesTraceRed, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            if app.Green_RedCheckBox.Value
                app.corrCurrentTraceCh3Red = app.CurrentTraceCh3Red - app.ch2ch3leak*app.CurrentTraceCh2Red;
                plot(app.UIAxesTraceRed,app.corrCurrentTraceCh3Red,'r');
                hold(app.UIAxesTraceRed, 'on'); % hold on must be after the first line is plotted otherwise the previous traces will reamin
            end
            hold(app.UIAxesTraceRed, 'off');
            linkaxes([app.UIAxesTraceBlue app.UIAxesTraceBlue],'x');
                        
            %axis([0 inf -0.2 1.2]);
            smMarker = app.PksList((app.CurrenTraceNumber), 2:3);
            imshow(app.ave_imageFirst, 'parent', app.UIAxesFig_1);
            imshow(app.ave_imageSecond, 'parent', app.UIAxesFig_2);
            hold(app.UIAxesFig_1,'on');
            plot(app.UIAxesFig_1, smMarker(1) + 1, smMarker(2) + 1, 'o', 'color', 'r', 'markersize', 8, 'linewidth', 1.5); %single molecule marker
            hold(app.UIAxesFig_1,'off');
            hold(app.UIAxesFig_2,'on');
            plot(app.UIAxesFig_2, smMarker(1) + 1, smMarker(2) + 1, 'o', 'color', 'r', 'markersize', 8, 'linewidth', 1.5); %single molecule marker
            hold(app.UIAxesFig_2,'off');
            imshow(app.ave_imageFirst(smMarker(2)-4:smMarker(2)+6,smMarker(1)-4:smMarker(1)+6),[], 'parent', app.UIAxesFig_1Z) %area around image is -4 & +6 to account for IDL starting at 0,0 and matlab at 1,1
            imshow(app.ave_imageSecond(smMarker(2)-4:smMarker(2)+6,smMarker(1)-4:smMarker(1)+6),[], 'parent', app.UIAxesFig_2Z)
        end
        
        
        
    end
    
    methods (Access = public)
        
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            zoom(app.UIAxesTraceBlue,'on')
            zoom(app.UIAxesTraceRed,'on')
            zoom(app.UIAxesFRET,'on')
            zoom(app.UIAxesFig_1,'on')
            app.linkXLim = linkprop([app.UIAxesTraceBlue app.UIAxesTraceRed app.UIAxesFRET],'XLim');

            %set alpha values
            app.ch1ch2leak = 0.2716;
            app.ch2ch3leak = 0.0768;
            app.BluetoGreenEditField.Value = app.ch1ch2leak;
            app.GreentoRedEditField.Value = app.ch2ch3leak;
        end

        % Button pushed function: PrevTraceButton
        function PrevTraceButtonPushed(app, event)
            app.CurrenTraceNumber=app.CurrenTraceNumber-1;
            app.CurrentEditField.Value = app.CurrenTraceNumber;
            app.CurrentTraceCh1Blue = app.channel1_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Blue = app.channel2_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Blue = app.channel3_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh1Red = app.channel1_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Red = app.channel2_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Red = app.channel3_red(app.CurrenTraceNumber,:);
            updateTrace(app);
            updateHist(app);
            updateFRET(app);
        end

        % Button pushed function: NextTraceButton
        function NextTraceButtonPushed(app, event)
            app.CurrenTraceNumber=app.CurrenTraceNumber+1;
            app.CurrentEditField.Value = app.CurrenTraceNumber;
            app.CurrentTraceCh1Blue = app.channel1_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Blue = app.channel2_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Blue = app.channel3_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh1Red = app.channel1_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Red = app.channel2_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Red = app.channel3_red(app.CurrenTraceNumber,:);
            updateTrace(app);
            updateHist(app);
            updateFRET(app);
        end

        % Button pushed function: ApplyButton
        function ApplyButtonPushed(app, event)
            app.CurrenTraceNumber = app.CurrentEditField.Value;
            app.CurrentTraceCh1Blue = app.channel1_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Blue = app.channel2_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Blue = app.channel3_blue(app.CurrenTraceNumber,:);
            app.CurrentTraceCh1Red = app.channel1_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Red = app.channel2_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Red = app.channel3_red(app.CurrenTraceNumber,:);
            updateTrace(app);
            updateHist(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh1Button
        function SubtractCh1ButtonPushed(app, event)
            xl = xlim(app.UIAxesTraceBlue);
            xl_int = int32(xl);
            DataTraceLim = app.channel1_blue(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh1Blue = app.channel1_blue(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh2Button
        function SubtractCh2ButtonPushed(app, event)
            xl = xlim(app.UIAxesTraceBlue);
            xl_int = int32(xl);
            DataTraceLim = app.channel2_blue(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh2Blue = app.channel2_blue(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh3Button
        function SubtractCh3ButtonPushed(app, event)
            xl = xlim(app.UIAxesTraceBlue);
            xl_int = int32(xl); 
            DataTraceLim = app.channel3_blue(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh3Blue = app.channel3_blue(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh1Button_green
        function SubtractCh1Button_greenPushed(app, event)
            xl = xlim(app.UIAxesTraceRed);
            xl_int = int32(xl);
            DataTraceLim = app.channel1_red(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh1Red = app.channel1_red(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh2Button_green
        function SubtractCh2Button_greenPushed(app, event)
            xl = xlim(app.UIAxesTraceRed);
            xl_int = int32(xl);
            DataTraceLim = app.channel2_red(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh2Red = app.channel2_red(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SubtractCh3Button_green
        function SubtractCh3Button_greenPushed(app, event)
            xl = xlim(app.UIAxesTraceRed);
            xl_int = int32(xl);
            DataTraceLim = app.channel3_red(app.CurrenTraceNumber,xl_int(1,1):xl_int(1,2));
            corFactor = median(DataTraceLim);
            app.CurrentTraceCh3Red = app.channel3_red(app.CurrenTraceNumber,:)-corFactor;
            updateTrace(app);
            updateFRET(app);
        end

        % Button pushed function: SaveTraceButton
        function SaveTraceButtonPushed(app, event)
            xl = xlim(app.UIAxesFRET);% returns x-limts as vector %%previously 1 was added to xl
            xl_int = int32(xl);% bins 32 integer 
            if xl_int(1,1) < 1 % if row 1 column1 < 1 --> make it = 1
                xl_int(1,1) = 1;
            end 

            % find out if there is a missmatach between the
            % number of frames recorded for each laser
            missmatachTrunc = false;
            minN=min([numel(app.CurrentTraceCh1Blue),numel(app.CurrentTraceCh1Red)]);
            maxN=max([numel(app.CurrentTraceCh1Blue),numel(app.CurrentTraceCh1Red)]);

            if minN~=maxN
                errTxt = "There is a missmatch in the number of frames for the first and second lasers. Truncating by "+(maxN-minN)+" frame(s)";
                uialert(app.UIFigure,errTxt,'Warning');
                missmatachTrunc = true;
            end
            
                
            
            %string1 = strcat(PathName, 'docktime', FileName(1:end-7), '_'); %string1 is the name for the docktime files
            string2 = strcat(app.NameFile(1:end-19),'_traces_'); %string2 is the name for the trace files
            string5 = strcat(app.NameFile(1:end-19), '_HMM_'); % string5 is for vbFRET data 
            %string6 = strcat(app.NameFile(1:end-19), '_summary_'); % exports ch1-3 and both FRET channels 
            

            if app.FRETTypeButtonGroup.SelectedObject == app.B_exBGFRETButton
                % blue green FRET
                B_exBGFRET = app.corrCurrentTraceCh2Blue./(app.corrCurrentTraceCh2Blue+app.CurrentTraceCh1Blue);

                if app.TraceFileCheckBox.Value == true
                    fname2 = [string2, num2str(app.CurrenTraceNumber), '.dat']; 
                    if missmatachTrunc == true
                        output = [app.CurrentTraceCh1Blue(1:minN).' app.corrCurrentTraceCh2Blue(1:minN).' B_exBGFRET(1:minN).' app.corrCurrentTraceCh3Red(1:minN).'];
                    else
                        output = [app.CurrentTraceCh1Blue(:) app.corrCurrentTraceCh2Blue(:) B_exBGFRET(:) app.corrCurrentTraceCh3Red(:)];
                    end
                    save(fname2, 'output', '-ascii') ;
                end 
            
                if app.HMMFileCheckBox.Value == true
                    fname5 = [string5, num2str(app.CurrenTraceNumber), '.dat']; 
                    %if missmatachTrunc == true
                        %output5 = [app.CurrentTraceCh1Blue(1:minN).' app.corrCurrentTraceCh2Blue(1:minN).'];
                    %else
                        output5 = [app.CurrentTraceCh1Blue(xl_int(1):xl_int(2)).' app.corrCurrentTraceCh2Blue(xl_int(1):xl_int(2)).'];
                    %end
                    save(fname5, 'output5', '-ascii') ;
                end 
            
%             elseif app.FRETTypeButtonGroup.SelectedObject == app.G_exGRFRETButton
% 
%                 % green red FRET
%                 G_exGRFRET = app.corrCurrentTraceCh3Red./(app.corrCurrentTraceCh3Red+app.CurrentTraceCh2Red);  
% 
%                 if app.TraceFileCheckBox.Value == true
%                     fname2 = [string2, num2str(app.CurrenTraceNumber), '.dat'];
%                     if missmatachTrunc == true
%                         output = [app.CurrentTraceCh2Red(1:minN).' app.CurrentTraceCh3Red(1:minN).' G_exGRFRET(1:minN).' app.currentTraceCh1Blue(1:minN).'];
%                     else
%                         output = [app.CurrentTraceCh2Red(:) app.CurrentTraceCh3Red(:) G_exGRFRET(:) app.currentTraceCh1Blue(:)];
%                     end
%                     save(fname2, 'output', '-ascii') ;
%                 end 
%             
%                 if app.HMMFileCheckBox.Value == true
%                     fname5 = [string5, num2str(app.CurrenTraceNumber), '.dat']; 
%                     if missmatachTrunc == true
%                         output5 = [app.CurrentTraceCh2Red(1:minN).' app.corrCurrentTraceCh3Red(1:minN).'];
%                     else
%                         output5 = [app.CurrentTraceCh2Red(xl_int(1):xl_int(2)) app.corrCurrentTraceCh3Red(xl_int(1):xl_int(2))];
%                     end
%                     save(fname5, 'output5', '-ascii') ;
%                 end 
            end 
            
                

        end

        % Button pushed function: UpdateHistButton
        function UpdateHistButtonPushed(app, event)

            updateHist(app)

             
        end

        % Menu selected function: LoadDataMenu
        function LoadDataMenuSelected(app, event)
            % Callback for the Open file button
            
            % Variable declaration
            % double framerate fid peaktable len Ntraces raw index Data donor acceptor
            % fret time1 LinDon LinAcc FRET LinFRET CurrenTraceNumber y n xdata ydata
            % HistDon HistAcc Interval
            % string FileName PathName FileName2

            %warning off all

            % Load data from *.traces file
            [FileName,PathName]  =  uigetfile('*.3color_alex_traces','*','Select the traces file');
            if FileName == 0
                return
            end
            app.FileNameTextArea.Value = FileName(1:end-7);
            fid  =  fopen([PathName,FileName],'r', 'ieee-le');
            len  =  fread(fid, 1, 'int16');
            
            app.PksFileName = [PathName,FileName(1:end - 6),'pks'];
            app.PksList = load(app.PksFileName);
            app.PksList = app.PksList([1:3:end],:); %get rid of every 2nd and 3rd row which is the corresponding peak in the other channels
            
            ImgFileNameFirst = [PathName,FileName(1:end - 19),'_com_first.tif'];
            app.ave_imageFirst = imread(ImgFileNameFirst);
            
            ImgFileNameSecond = [PathName,FileName(1:end - 19),'_com_second.tif'];
            app.ave_imageSecond = imread(ImgFileNameSecond);
            
            app.NameFile = [PathName,FileName(1:end - 6),'traces'];
            
            
            Ntraces  =  fread(fid, 1, 'int16'); %total number of traces in all channels
            app.ofEditField.Value = Ntraces/3;
            
            raw = fread(fid,[Ntraces len],'int16');
            spotDiameter = fread(fid, 1, 'int16');
            disp('Finished reading data');
            fclose(fid);
            
            % Manipulate/reorganize data
            index = (1:2:len);
            logindex=ismember(1:len,index); %makes a logical index for every 4th frame
            blueData = raw(:,logindex); %uses the logical index to extract the blue laser excitaion
            greenData= raw(:,~logindex);%uses the opposite of the logical index to extract the green laser excitation
            
            
            app.channel1_blue = blueData(1:3:Ntraces,:);
            app.channel1_red = greenData(1:3:Ntraces,:);
              
            app.channel2_blue = blueData(2:3:Ntraces,:);
            app.channel2_red = greenData(2:3:Ntraces,:);

            app.channel3_blue = blueData(3:3:Ntraces,:);
            app.channel3_red = greenData(3:3:Ntraces,:);
                    
            app.CurrenTraceNumber = 1;
            app.CurrentEditField.Value = app.CurrenTraceNumber;
            app.CurrentTraceCh1Blue = app.channel1_blue(1,:);
            app.CurrentTraceCh2Blue = app.channel2_blue(1,:);
            app.CurrentTraceCh3Blue = app.channel3_blue(1,:);
            app.CurrentTraceCh1Red = app.channel1_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh2Red = app.channel2_red(app.CurrenTraceNumber,:);
            app.CurrentTraceCh3Red = app.channel3_red(app.CurrenTraceNumber,:);

            

            
            
            updateTrace(app);
            updateHist(app);
            updateFRET(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1521 911];
            app.UIFigure.Name = 'UI Figure';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create LoadDataMenu
            app.LoadDataMenu = uimenu(app.FileMenu);
            app.LoadDataMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadDataMenuSelected, true);
            app.LoadDataMenu.Text = 'Load Data';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 7 1512 905];

            % Create ColourFRETTab
            app.ColourFRETTab = uitab(app.TabGroup);
            app.ColourFRETTab.Title = '3 Colour FRET';

            % Create UIAxesTraceRed
            app.UIAxesTraceRed = uiaxes(app.ColourFRETTab);
            title(app.UIAxesTraceRed, 'Red excitation')
            xlabel(app.UIAxesTraceRed, 'Frame')
            ylabel(app.UIAxesTraceRed, 'Intensity')
            app.UIAxesTraceRed.XLimitMethod = 'tight';
            app.UIAxesTraceRed.XTickLabelRotation = 0;
            app.UIAxesTraceRed.YTickLabelRotation = 0;
            app.UIAxesTraceRed.ZTickLabelRotation = 0;
            app.UIAxesTraceRed.XGrid = 'on';
            app.UIAxesTraceRed.YGrid = 'on';
            app.UIAxesTraceRed.Position = [158 286 650 247];

            % Create UIAxesTraceBlue
            app.UIAxesTraceBlue = uiaxes(app.ColourFRETTab);
            title(app.UIAxesTraceBlue, 'Blue excitation')
            xlabel(app.UIAxesTraceBlue, 'Frame')
            ylabel(app.UIAxesTraceBlue, 'Intensity')
            app.UIAxesTraceBlue.XLimitMethod = 'tight';
            app.UIAxesTraceBlue.YLimitMethod = 'padded';
            app.UIAxesTraceBlue.XTickLabelRotation = 0;
            app.UIAxesTraceBlue.YTickLabelRotation = 0;
            app.UIAxesTraceBlue.ZTickLabelRotation = 0;
            app.UIAxesTraceBlue.XGrid = 'on';
            app.UIAxesTraceBlue.YGrid = 'on';
            app.UIAxesTraceBlue.Position = [158 536 650 247];

            % Create UIAxesFRET
            app.UIAxesFRET = uiaxes(app.ColourFRETTab);
            title(app.UIAxesFRET, 'FRET Trace')
            xlabel(app.UIAxesFRET, 'Frame')
            ylabel(app.UIAxesFRET, 'FRET')
            app.UIAxesFRET.YLim = [-0.2 1.2];
            app.UIAxesFRET.XLimitMethod = 'tight';
            app.UIAxesFRET.XTickLabelRotation = 0;
            app.UIAxesFRET.YTickLabelRotation = 0;
            app.UIAxesFRET.ZTickLabelRotation = 0;
            app.UIAxesFRET.XGrid = 'on';
            app.UIAxesFRET.YGrid = 'on';
            app.UIAxesFRET.Position = [158 17 650 247];

            % Create UIAxesHist
            app.UIAxesHist = uiaxes(app.ColourFRETTab);
            title(app.UIAxesHist, 'Histogram')
            xlabel(app.UIAxesHist, 'FRET')
            ylabel(app.UIAxesHist, 'Count')
            app.UIAxesHist.PlotBoxAspectRatio = [1.5 1 1];
            app.UIAxesHist.XTickLabelRotation = 0;
            app.UIAxesHist.YTickLabelRotation = 0;
            app.UIAxesHist.ZTickLabelRotation = 0;
            app.UIAxesHist.XGrid = 'on';
            app.UIAxesHist.YGrid = 'on';
            app.UIAxesHist.Position = [959 1 360 300];

            % Create UIAxesFig_2Z
            app.UIAxesFig_2Z = uiaxes(app.ColourFRETTab);
            app.UIAxesFig_2Z.XTick = [];
            app.UIAxesFig_2Z.XTickLabelRotation = 0;
            app.UIAxesFig_2Z.YTick = [];
            app.UIAxesFig_2Z.YTickLabelRotation = 0;
            app.UIAxesFig_2Z.ZTickLabelRotation = 0;
            app.UIAxesFig_2Z.Position = [1294 518 118 106];

            % Create UIAxesFig_2
            app.UIAxesFig_2 = uiaxes(app.ColourFRETTab);
            app.UIAxesFig_2.XTick = [];
            app.UIAxesFig_2.XTickLabelRotation = 0;
            app.UIAxesFig_2.YTick = [];
            app.UIAxesFig_2.YTickLabelRotation = 0;
            app.UIAxesFig_2.ZTickLabelRotation = 0;
            app.UIAxesFig_2.Position = [1203 577 300 300];

            % Create UIAxesFig_1Z
            app.UIAxesFig_1Z = uiaxes(app.ColourFRETTab);
            app.UIAxesFig_1Z.XTick = [];
            app.UIAxesFig_1Z.XTickLabelRotation = 0;
            app.UIAxesFig_1Z.YTick = [];
            app.UIAxesFig_1Z.YTickLabelRotation = 0;
            app.UIAxesFig_1Z.ZTickLabelRotation = 0;
            app.UIAxesFig_1Z.Position = [935 520 118 106];

            % Create UIAxesFig_1
            app.UIAxesFig_1 = uiaxes(app.ColourFRETTab);
            app.UIAxesFig_1.XColor = [0 0 1];
            app.UIAxesFig_1.XTick = [];
            app.UIAxesFig_1.YColor = [0 0 1];
            app.UIAxesFig_1.YTick = [];
            app.UIAxesFig_1.Box = 'on';
            app.UIAxesFig_1.Position = [844 577 300 300];

            % Create UIAxesTraceSum
            app.UIAxesTraceSum = uiaxes(app.ColourFRETTab);
            title(app.UIAxesTraceSum, 'Sum')
            xlabel(app.UIAxesTraceSum, 'Frame')
            ylabel(app.UIAxesTraceSum, 'D+A Intensity')
            app.UIAxesTraceSum.XLimitMethod = 'tight';
            app.UIAxesTraceSum.XTickLabelRotation = 0;
            app.UIAxesTraceSum.YTickLabelRotation = 0;
            app.UIAxesTraceSum.ZTickLabelRotation = 0;
            app.UIAxesTraceSum.XGrid = 'on';
            app.UIAxesTraceSum.YGrid = 'on';
            app.UIAxesTraceSum.Position = [844 284 650 247];

            % Create PrevTraceButton
            app.PrevTraceButton = uibutton(app.ColourFRETTab, 'push');
            app.PrevTraceButton.ButtonPushedFcn = createCallbackFcn(app, @PrevTraceButtonPushed, true);
            app.PrevTraceButton.Position = [205 802 100 22];
            app.PrevTraceButton.Text = 'Prev. Trace';

            % Create NextTraceButton
            app.NextTraceButton = uibutton(app.ColourFRETTab, 'push');
            app.NextTraceButton.ButtonPushedFcn = createCallbackFcn(app, @NextTraceButtonPushed, true);
            app.NextTraceButton.Position = [315 802 100 22];
            app.NextTraceButton.Text = 'Next Trace';

            % Create ApplyButton
            app.ApplyButton = uibutton(app.ColourFRETTab, 'push');
            app.ApplyButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyButtonPushed, true);
            app.ApplyButton.Position = [600 802 100 22];
            app.ApplyButton.Text = 'Apply';

            % Create SaveTraceButton
            app.SaveTraceButton = uibutton(app.ColourFRETTab, 'push');
            app.SaveTraceButton.ButtonPushedFcn = createCallbackFcn(app, @SaveTraceButtonPushed, true);
            app.SaveTraceButton.Position = [728 802 100 22];
            app.SaveTraceButton.Text = 'Save Trace';

            % Create UpdateHistButton
            app.UpdateHistButton = uibutton(app.ColourFRETTab, 'push');
            app.UpdateHistButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateHistButtonPushed, true);
            app.UpdateHistButton.Position = [1343 17 100 22];
            app.UpdateHistButton.Text = 'Update Hist';

            % Create CurrentTraceLabel
            app.CurrentTraceLabel = uilabel(app.ColourFRETTab);
            app.CurrentTraceLabel.HorizontalAlignment = 'right';
            app.CurrentTraceLabel.Position = [216 836 78 22];
            app.CurrentTraceLabel.Text = 'Current Trace';

            % Create CurrentEditField
            app.CurrentEditField = uieditfield(app.ColourFRETTab, 'numeric');
            app.CurrentEditField.Position = [299 836 31 22];

            % Create ofEditFieldLabel
            app.ofEditFieldLabel = uilabel(app.ColourFRETTab);
            app.ofEditFieldLabel.HorizontalAlignment = 'right';
            app.ofEditFieldLabel.Position = [319 836 25 22];
            app.ofEditFieldLabel.Text = 'of';

            % Create ofEditField
            app.ofEditField = uieditfield(app.ColourFRETTab, 'numeric');
            app.ofEditField.Editable = 'off';
            app.ofEditField.Position = [348 836 34 22];

            % Create AverageptsLabel
            app.AverageptsLabel = uilabel(app.ColourFRETTab);
            app.AverageptsLabel.HorizontalAlignment = 'right';
            app.AverageptsLabel.Position = [459 802 76 22];
            app.AverageptsLabel.Text = 'Average (pts)';

            % Create Average
            app.Average = uieditfield(app.ColourFRETTab, 'numeric');
            app.Average.Limits = [1 Inf];
            app.Average.RoundFractionalValues = 'on';
            app.Average.Position = [550 802 30 22];
            app.Average.Value = 1;

            % Create FRETTypeButtonGroup
            app.FRETTypeButtonGroup = uibuttongroup(app.ColourFRETTab);
            app.FRETTypeButtonGroup.Title = 'FRET Type';
            app.FRETTypeButtonGroup.Position = [35 798 123 73];

            % Create B_exBGFRETButton
            app.B_exBGFRETButton = uiradiobutton(app.FRETTypeButtonGroup);
            app.B_exBGFRETButton.Text = 'B_ex: B-G FRET';
            app.B_exBGFRETButton.Position = [11 27 110 22];
            app.B_exBGFRETButton.Value = true;

            % Create G_exGRFRETButton
            app.G_exGRFRETButton = uiradiobutton(app.FRETTypeButtonGroup);
            app.G_exGRFRETButton.Enable = 'off';
            app.G_exGRFRETButton.Text = 'G_ex: G-R FRET';
            app.G_exGRFRETButton.Position = [11 5 111 22];

            % Create subtractionButtonGroup_blue
            app.subtractionButtonGroup_blue = uibuttongroup(app.ColourFRETTab);
            app.subtractionButtonGroup_blue.Title = 'Blue ex subtraction';
            app.subtractionButtonGroup_blue.Position = [11 564 123 106];

            % Create SubtractCh1Button
            app.SubtractCh1Button = uibutton(app.subtractionButtonGroup_blue, 'push');
            app.SubtractCh1Button.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh1ButtonPushed, true);
            app.SubtractCh1Button.FontColor = [0 0 1];
            app.SubtractCh1Button.Position = [13 61 100 22];
            app.SubtractCh1Button.Text = 'Subtract Ch1';

            % Create SubtractCh2Button
            app.SubtractCh2Button = uibutton(app.subtractionButtonGroup_blue, 'push');
            app.SubtractCh2Button.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh2ButtonPushed, true);
            app.SubtractCh2Button.FontColor = [0.0784 0.5294 0.0784];
            app.SubtractCh2Button.Position = [13 32 100 22];
            app.SubtractCh2Button.Text = 'Subtract Ch2';

            % Create SubtractCh3Button
            app.SubtractCh3Button = uibutton(app.subtractionButtonGroup_blue, 'push');
            app.SubtractCh3Button.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh3ButtonPushed, true);
            app.SubtractCh3Button.FontColor = [0.9098 0.1647 0.1647];
            app.SubtractCh3Button.Position = [13 3 100 22];
            app.SubtractCh3Button.Text = 'Subtract Ch3';

            % Create subtractionButtonGroup_green
            app.subtractionButtonGroup_green = uibuttongroup(app.ColourFRETTab);
            app.subtractionButtonGroup_green.Title = 'Green ex subtraction';
            app.subtractionButtonGroup_green.Position = [11 302 123 106];

            % Create SubtractCh1Button_green
            app.SubtractCh1Button_green = uibutton(app.subtractionButtonGroup_green, 'push');
            app.SubtractCh1Button_green.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh1Button_greenPushed, true);
            app.SubtractCh1Button_green.FontColor = [0 0 1];
            app.SubtractCh1Button_green.Position = [12 59 100 23];
            app.SubtractCh1Button_green.Text = 'Subtract Ch1';

            % Create SubtractCh2Button_green
            app.SubtractCh2Button_green = uibutton(app.subtractionButtonGroup_green, 'push');
            app.SubtractCh2Button_green.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh2Button_greenPushed, true);
            app.SubtractCh2Button_green.FontColor = [0.0784 0.5294 0.0784];
            app.SubtractCh2Button_green.Position = [12 31 100 23];
            app.SubtractCh2Button_green.Text = 'Subtract Ch2';

            % Create SubtractCh3Button_green
            app.SubtractCh3Button_green = uibutton(app.subtractionButtonGroup_green, 'push');
            app.SubtractCh3Button_green.ButtonPushedFcn = createCallbackFcn(app, @SubtractCh3Button_greenPushed, true);
            app.SubtractCh3Button_green.FontColor = [1 0 0];
            app.SubtractCh3Button_green.Position = [12 4 100 23];
            app.SubtractCh3Button_green.Text = 'Subtract Ch3';

            % Create B_exDisplayPanel
            app.B_exDisplayPanel = uipanel(app.ColourFRETTab);
            app.B_exDisplayPanel.Title = 'B_ex: Display';
            app.B_exDisplayPanel.Position = [23 680 100 106];

            % Create Blue_BlueCheckBox
            app.Blue_BlueCheckBox = uicheckbox(app.B_exDisplayPanel);
            app.Blue_BlueCheckBox.Text = 'Blue';
            app.Blue_BlueCheckBox.FontColor = [0 0 1];
            app.Blue_BlueCheckBox.Position = [7 61 46 22];
            app.Blue_BlueCheckBox.Value = true;

            % Create Blue_GreenCheckBox
            app.Blue_GreenCheckBox = uicheckbox(app.B_exDisplayPanel);
            app.Blue_GreenCheckBox.Text = 'Green';
            app.Blue_GreenCheckBox.FontColor = [0.0784 0.5294 0.0784];
            app.Blue_GreenCheckBox.Position = [7 35 55 22];
            app.Blue_GreenCheckBox.Value = true;

            % Create Blue_RedCheckBox
            app.Blue_RedCheckBox = uicheckbox(app.B_exDisplayPanel);
            app.Blue_RedCheckBox.Text = 'Red';
            app.Blue_RedCheckBox.FontColor = [1 0 0];
            app.Blue_RedCheckBox.Position = [7 9 44 22];

            % Create G_exDisplayPanel
            app.G_exDisplayPanel = uipanel(app.ColourFRETTab);
            app.G_exDisplayPanel.Title = 'B_ex: Display';
            app.G_exDisplayPanel.Position = [23 420 100 106];

            % Create Green_BlueCheckBox
            app.Green_BlueCheckBox = uicheckbox(app.G_exDisplayPanel);
            app.Green_BlueCheckBox.Text = 'Blue';
            app.Green_BlueCheckBox.FontColor = [0 0 1];
            app.Green_BlueCheckBox.Position = [7 61 46 22];

            % Create Green_GreenCheckBox
            app.Green_GreenCheckBox = uicheckbox(app.G_exDisplayPanel);
            app.Green_GreenCheckBox.Text = 'Green';
            app.Green_GreenCheckBox.FontColor = [0.0784 0.5294 0.0784];
            app.Green_GreenCheckBox.Position = [7 35 55 22];
            app.Green_GreenCheckBox.Value = true;

            % Create Green_RedCheckBox
            app.Green_RedCheckBox = uicheckbox(app.G_exDisplayPanel);
            app.Green_RedCheckBox.Text = 'Red';
            app.Green_RedCheckBox.FontColor = [1 0 0];
            app.Green_RedCheckBox.Position = [7 9 44 22];
            app.Green_RedCheckBox.Value = true;

            % Create FileNameTextAreaLabel
            app.FileNameTextAreaLabel = uilabel(app.ColourFRETTab);
            app.FileNameTextAreaLabel.HorizontalAlignment = 'right';
            app.FileNameTextAreaLabel.Position = [444 837 56 22];
            app.FileNameTextAreaLabel.Text = 'FileName';

            % Create FileNameTextArea
            app.FileNameTextArea = uitextarea(app.ColourFRETTab);
            app.FileNameTextArea.Editable = 'off';
            app.FileNameTextArea.Position = [515 835 150 26];

            % Create AlphaCorrectionFactorsPanel
            app.AlphaCorrectionFactorsPanel = uipanel(app.ColourFRETTab);
            app.AlphaCorrectionFactorsPanel.Title = 'Alpha Correction Factors:';
            app.AlphaCorrectionFactorsPanel.Position = [11 17 148 102];

            % Create BluetoGreenEditFieldLabel
            app.BluetoGreenEditFieldLabel = uilabel(app.AlphaCorrectionFactorsPanel);
            app.BluetoGreenEditFieldLabel.HorizontalAlignment = 'right';
            app.BluetoGreenEditFieldLabel.Position = [0 49 79 22];
            app.BluetoGreenEditFieldLabel.Text = 'Blue to Green';

            % Create BluetoGreenEditField
            app.BluetoGreenEditField = uieditfield(app.AlphaCorrectionFactorsPanel, 'numeric');
            app.BluetoGreenEditField.Editable = 'off';
            app.BluetoGreenEditField.Position = [92 49 50 21];

            % Create GreentoRedEditFieldLabel
            app.GreentoRedEditFieldLabel = uilabel(app.AlphaCorrectionFactorsPanel);
            app.GreentoRedEditFieldLabel.HorizontalAlignment = 'right';
            app.GreentoRedEditFieldLabel.Position = [0 14 77 22];
            app.GreentoRedEditFieldLabel.Text = 'Green to Red';

            % Create GreentoRedEditField
            app.GreentoRedEditField = uieditfield(app.AlphaCorrectionFactorsPanel, 'numeric');
            app.GreentoRedEditField.Editable = 'off';
            app.GreentoRedEditField.Position = [92 14 50 21];

            % Create OptionsTab
            app.OptionsTab = uitab(app.TabGroup);
            app.OptionsTab.Title = 'Options';

            % Create ExportFIleTickboxesofchosenfiletypestoexportPanel
            app.ExportFIleTickboxesofchosenfiletypestoexportPanel = uipanel(app.OptionsTab);
            app.ExportFIleTickboxesofchosenfiletypestoexportPanel.Title = 'Export FIle - Tick boxes of chosen file types to export';
            app.ExportFIleTickboxesofchosenfiletypestoexportPanel.Position = [486 558 382 221];

            % Create TraceFileCheckBox
            app.TraceFileCheckBox = uicheckbox(app.ExportFIleTickboxesofchosenfiletypestoexportPanel);
            app.TraceFileCheckBox.Text = 'Trace File ';
            app.TraceFileCheckBox.Position = [10 169 76 22];
            app.TraceFileCheckBox.Value = true;

            % Create HMMFileCheckBox
            app.HMMFileCheckBox = uicheckbox(app.ExportFIleTickboxesofchosenfiletypestoexportPanel);
            app.HMMFileCheckBox.Text = 'HMM File';
            app.HMMFileCheckBox.Position = [10 89 74 22];

            % Create DonorAcceptorFRETCoLocChannelLabel
            app.DonorAcceptorFRETCoLocChannelLabel = uilabel(app.ExportFIleTickboxesofchosenfiletypestoexportPanel);
            app.DonorAcceptorFRETCoLocChannelLabel.Position = [84 169 230 22];
            app.DonorAcceptorFRETCoLocChannelLabel.Text = '- Donor, Acceptor, FRET | CoLoc Channel';

            % Create DonorandAcceptoronlyLabel
            app.DonorandAcceptoronlyLabel = uilabel(app.ExportFIleTickboxesofchosenfiletypestoexportPanel);
            app.DonorandAcceptoronlyLabel.Position = [93 89 151 22];
            app.DonorandAcceptoronlyLabel.Text = ' - Donor and Acceptor only';

            % Create Label
            app.Label = uilabel(app.ExportFIleTickboxesofchosenfiletypestoexportPanel);
            app.Label.WordWrap = 'on';
            app.Label.Position = [5 9 372 44];
            app.Label.Text = 'Note: Donor & Acceptor are determined from the ''FRET Type'' selection on the ''3 Colour FRET'' tab. The CoLocolisation Channel is the remaining intensity trace';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FRET_GUI_3colour_smFRET

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end