classdef FRET_ALEX_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        FileMenu                matlab.ui.container.Menu
        LoadMenu                matlab.ui.container.Menu
        CorrFactorsPanel        matlab.ui.container.Panel
        EditField               matlab.ui.control.NumericEditField
        EditFieldLabel          matlab.ui.control.Label
        AlphaEditField          matlab.ui.control.NumericEditField
        AlphaEditFieldLabel     matlab.ui.control.Label
        PathNameTextArea        matlab.ui.control.EditField
        PathNameEditFieldLabel  matlab.ui.control.Label
        FileNameTextArea        matlab.ui.control.EditField
        FileNameEditFieldLabel  matlab.ui.control.Label
        ExportButton            matlab.ui.control.Button
        UpdateHistButton        matlab.ui.control.Button
        EditFieldTraceMax       matlab.ui.control.NumericEditField
        ofEditFieldLabel        matlab.ui.control.Label
        EditFieldTrace          matlab.ui.control.NumericEditField
        SubButton               matlab.ui.control.Button
        SubAButton              matlab.ui.control.Button
        SubDButton              matlab.ui.control.Button
        TraceEditFieldLabel     matlab.ui.control.Label
        GoButton                matlab.ui.control.Button
        NextButton              matlab.ui.control.Button
        PreviousButton          matlab.ui.control.Button
        UIAxesSpotSecond_Z      matlab.ui.control.UIAxes
        UIAxesSpotFirst_Z       matlab.ui.control.UIAxes
        UIAxesSpotSecond        matlab.ui.control.UIAxes
        UIAxesSpotFirst         matlab.ui.control.UIAxes
        UIAxesHist2             matlab.ui.control.UIAxes
        UIAxesHist              matlab.ui.control.UIAxes
        UIAxes_4                matlab.ui.control.UIAxes
        UIAxesFRET              matlab.ui.control.UIAxes
        UIAxesTrace2nd          matlab.ui.control.UIAxes
        UIAxesTrace             matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        laserFirstDonorAll % Description
        laserFirstAcceptorAll % Description
        laserSecondAcceptorAll % Description
        linkXLim %needed to link the x axis zoom (see startupFcn)
        com_imageFirst
        com_imageSecond
        PksList
    end
    
    methods (Access = private)
        
        function updateTrace(app, traceNo)
            alphaLeak = app.AlphaEditField.Value;
            donor = app.laserFirstDonorAll(traceNo,:);
            acceptor = app.laserFirstAcceptorAll(traceNo,:)-app.laserFirstDonorAll(traceNo,:)*alphaLeak;
            acceptor2nd = app.laserSecondAcceptorAll(traceNo,:);
            plot(app.UIAxesTrace,donor, 'color', '#00611C');
            hold(app.UIAxesTrace, 'on');
            plot(app.UIAxesTrace,acceptor, 'r');
            hold(app.UIAxesTrace, 'off');

            plot(app.UIAxesTrace2nd,acceptor2nd, 'r');

            updateFRET(app, donor, acceptor)
            updateStoichiometry(app, donor, acceptor, acceptor2nd)
        end
        
        
        function updateFRET(app, donor, acceptor)
            FRET = acceptor ./ (donor + acceptor);
            plot(app.UIAxesFRET, FRET, 'black');   

            xl = xlim(app.UIAxesFRET);% returns x-limts as vector 
            xl_int = int32(xl);% bins 32 integer 
            if xl_int(1) < 1 % if row 1 column1 < 1 --> make it = 1
                xl_int(1) = 1;
            end 
            if xl_int(2) > length(FRET)
                xl_int(2) = length(FRET);
            end
            histogram(app.UIAxesHist, FRET(xl_int(1):xl_int(2)), 'Normalization','pdf','BinWidth',0.05,'BinLimits',[-0.2,1.2]);

        end
        
        function updateStoichiometry(app, donor, acceptor, acceptor2nd)
            stoichiometry = (acceptor+donor)./(acceptor2nd+acceptor+donor);
            plot(app.UIAxes_4,stoichiometry);

            FRET = acceptor ./ (donor + acceptor);
            xl = xlim(app.UIAxesFRET);% returns x-limts as vector 
            xl_int = int32(xl);% bins 32 integer 
            if xl_int(1) < 1 % if row 1 column1 < 1 --> make it = 1
                xl_int(1) = 1;
            end 
            if xl_int(2) > length(FRET)
                xl_int(2) = length(FRET);
            end
            histogram2(app.UIAxesHist2, FRET(xl_int(1):xl_int(2)), stoichiometry(xl_int(1):xl_int(2)),[20,20],'YBinLimits',[-0.2,1.2], 'XBinLimits',[-0.2,1.2],'DisplayStyle','tile','ShowEmptyBins','off')

        end
        
        function updateImages(app, traceNo)
            PksListPos = traceNo*2-1; %the PksList is in groups of three for each emission channel
            smMarker = app.PksList(PksListPos:PksListPos+1, 2:3);
            imshow(app.com_imageFirst, 'parent', app.UIAxesSpotFirst);
            imshow(app.com_imageSecond, 'parent', app.UIAxesSpotSecond);
            hold(app.UIAxesSpotFirst,'on');
            plot(app.UIAxesSpotFirst, smMarker(1,1) + 1, smMarker(1,2) + 1, 'o', 'color', 'r', 'markersize', 8, 'linewidth', 1.5); %single molecule marker
            hold(app.UIAxesSpotFirst,'off');
            hold(app.UIAxesSpotSecond,'on');
            plot(app.UIAxesSpotSecond, smMarker(1,1) + 1, smMarker(1,2) + 1, 'o', 'color', 'r', 'markersize', 8, 'linewidth', 1.5); %single molecule marker
            hold(app.UIAxesSpotSecond,'off');
            imshow(app.com_imageFirst(smMarker(1,2)-4:smMarker(1,2)+6,smMarker(1,1)-4:smMarker(1,1)+6),[], 'parent', app.UIAxesSpotFirst_Z) %area around image is -4 & +6 to account for IDL starting at 0,0 and matlab at 1,1
            imshow(app.com_imageSecond(smMarker(1,2)-4:smMarker(1,2)+6,smMarker(1,1)-4:smMarker(1,1)+6),[], 'parent', app.UIAxesSpotSecond_Z)      
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)


            %app.UIAxesTrace.PositionConstraint = 'outerposition';
            %app.UIAxesTrace2nd.PositionConstraint = 'outerposition';
            %app.UIAxesFRET.PositionConstraint = 'outerposition';
            %app.UIAxes_4.PositionConstraint = "outerposition";

            zoom(app.UIAxesTrace,'on')
            zoom(app.UIAxesTrace2nd,'on')
            zoom(app.UIAxesFRET,'on')
            app.linkXLim = linkprop([app.UIAxesTrace app.UIAxesTrace2nd app.UIAxesFRET app.UIAxes_4],'XLim');

        end

        % Menu selected function: LoadMenu
        function LoadMenuSelected(app, event)
            % Load data from *.traces file
        [FileName,PathName]  =  uigetfile('*.2color_alex_traces','*','Select the traces file');
        if FileName == 0
            return
        end
        app.FileNameTextArea.Value = FileName(1:end-19);
        app.PathNameTextArea.Value = PathName;
        fid  =  fopen([PathName,FileName],'r', 'ieee-le');
        len  =  fread(fid, 1, 'int16');

        Ntraces  =  fread(fid, 1, 'int16'); %total number of traces in all channels
        app.EditFieldTraceMax.Value = Ntraces/2;

        raw = fread(fid,[Ntraces len],'int16');% 
        spotDiameter = fread(fid, 1, 'int16');
        disp('Finished reading data');
        fclose(fid);

        PksFileName = [PathName,FileName(1:end - 6),'pks'];
        peakslist = importdata(PksFileName); %list of peak coordinates in groups of 2 for each of the two emission channels
        peakslist(1)=[]; %remove first element of array which is the total number of peaks
        peakslist = reshape(peakslist,[5,numel(peakslist)/5]); %turn single column back into array of original file
        app.PksList = peakslist';
            

        ImgFileNameFirst = [PathName,FileName(1:end - 19),'_com_first.tif'];
        app.com_imageFirst = imread(ImgFileNameFirst);
        ImgFileNameSecond = [PathName,FileName(1:end - 19),'_com_second.tif'];
        app.com_imageSecond = imread(ImgFileNameSecond);
        imshow(app.com_imageFirst, 'parent', app.UIAxesSpotFirst);
        imshow(app.com_imageSecond, 'parent', app.UIAxesSpotSecond);

        
        % Manipulate/reorganize data
        index = (1:2:len);
        logindex=ismember(1:len,index); %makes a logical index for every 2nd frame
        laserFirst = raw(:,logindex); %uses the logical index to extract the first laser excitaion
        laserSecond = raw(:,~logindex);%uses the opposite of the logical index to extract the second laser excitation
        
        app.laserFirstDonorAll = laserFirst([1:2:Ntraces],:);
        app.laserFirstAcceptorAll = laserFirst([2:2:Ntraces+1],:);

        app.laserSecondAcceptorAll = laserSecond([2:2:Ntraces+1],:);

        % find out if there is a missmatach between the
        % number of frames recorded for each laser
        minN=min([numel(app.laserFirstDonorAll(1,:)),numel(app.laserSecondAcceptorAll(1,:))]);
        maxN=max([numel(app.laserFirstDonorAll(1,:)),numel(app.laserSecondAcceptorAll(1,:))]);

        if minN~=maxN
            errTxt = "There is a missmatch in the number of frames for the first and second lasers. Truncating by "+(maxN-minN)+" frame(s)";
            uialert(app.UIFigure,errTxt,'Warning');
            app.laserFirstDonorAll = app.laserFirstDonorAll(:,1:minN);
            app.laserFirstAcceptorAll = app.laserFirstAcceptorAll(:,1:minN);
            app.laserSecondAcceptorAll = app.laserSecondAcceptorAll(:,1:minN);
        end

        traceNo = 1;
        app.EditFieldTrace.Value = traceNo;

        updateTrace(app, traceNo)
        updateImages(app, traceNo)


        end

        % Button pushed function: NextButton
        function NextButtonPushed(app, event)
            traceNo = app.EditFieldTrace.Value;
            traceNo = traceNo+1;
            if traceNo > app.EditFieldTraceMax.Value
                traceNo = app.EditFieldTraceMax.Value;
            end
            app.EditFieldTrace.Value = traceNo;
            updateTrace(app, traceNo)
            updateImages(app, traceNo)
        end

        % Button pushed function: PreviousButton
        function PreviousButtonPushed(app, event)
            traceNo = app.EditFieldTrace.Value;
            traceNo = traceNo-1;
            if traceNo < 1
                traceNo = 1;
            end
            app.EditFieldTrace.Value = traceNo;
            updateTrace(app, traceNo)
            updateImages(app, traceNo)
        end

        % Button pushed function: GoButton
        function GoButtonPushed(app, event)
            traceNo = app.EditFieldTrace.Value;
            if traceNo > app.EditFieldTraceMax
                traceNo = app.EditFieldTraceMax;
            end
            updateTrace(app, traceNo)
            updateImages(app, traceNo)
        end

        % Button pushed function: UpdateHistButton
        function UpdateHistButtonPushed(app, event)
            traceNo = app.EditFieldTrace.Value;
            updateTrace(app,traceNo)
            updateImages(app, traceNo)
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            traceNo = app.EditFieldTrace.Value;
            fileName = app.FileNameTextArea.Value;
            pathName = app.PathNameTextArea.Value;
            donor = app.laserFirstDonorAll(traceNo,:);
            %acceptor = app.laserFirstAcceptorAll(traceNo,:); %this would
            %give the acceptor that has not been alpha corrected
            alphaLeak = app.AlphaEditField.Value;
            acceptor = app.laserFirstAcceptorAll(traceNo,:)-app.laserFirstDonorAll(traceNo,:)*alphaLeak;
            acceptor2nd = app.laserSecondAcceptorAll(traceNo,:);
            stringfileName = strcat(fileName,'_traces_');
            fname = [pathName, stringfileName, num2str(traceNo), '.txt']; 

            output = [donor.' acceptor.' acceptor2nd.'];
            cell_titles = {'D-Dexc-rw' 'A-Dexc-rw' 'A-Aexc-rw'};
            outputCell = [cell_titles; num2cell(output)];
            writecell(outputCell, fname,'Delimiter','tab') ;

            xl = floor(xlim(app.UIAxesFRET))+1;
            if xl(2) > length(donor)

            else
                stringfileName_zoom = strcat(fileName,'_zoom_');
                fname_zoom = [pathName, stringfileName_zoom, num2str(traceNo), '.txt']; 
                output_zoom = [donor(xl(1):xl(2)).' acceptor(xl(1):xl(2)).'];
                save(fname_zoom, 'output_zoom', '-ascii') ;
            end


        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 944 700];
            app.UIFigure.Name = 'MATLAB App';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create LoadMenu
            app.LoadMenu = uimenu(app.FileMenu);
            app.LoadMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadMenuSelected, true);
            app.LoadMenu.Text = 'Load';

            % Create UIAxesTrace
            app.UIAxesTrace = uiaxes(app.UIFigure);
            ylabel(app.UIAxesTrace, 'First Laser Intensity')
            zlabel(app.UIAxesTrace, 'Z')
            app.UIAxesTrace.Position = [114 542 489 159];

            % Create UIAxesTrace2nd
            app.UIAxesTrace2nd = uiaxes(app.UIFigure);
            ylabel(app.UIAxesTrace2nd, 'Second Laser Intensity')
            zlabel(app.UIAxesTrace2nd, 'Z')
            app.UIAxesTrace2nd.Position = [114 384 489 159];

            % Create UIAxesFRET
            app.UIAxesFRET = uiaxes(app.UIFigure);
            ylabel(app.UIAxesFRET, 'FRET')
            zlabel(app.UIAxesFRET, 'Z')
            app.UIAxesFRET.YLim = [-0.1 1.2];
            app.UIAxesFRET.Position = [114 226 489 159];

            % Create UIAxes_4
            app.UIAxes_4 = uiaxes(app.UIFigure);
            xlabel(app.UIAxes_4, 'Frames')
            ylabel(app.UIAxes_4, 'Stoichiometry')
            zlabel(app.UIAxes_4, 'Z')
            app.UIAxes_4.YLim = [-0.2 1.2];
            app.UIAxes_4.Position = [114 68 489 159];

            % Create UIAxesHist
            app.UIAxesHist = uiaxes(app.UIFigure);
            zlabel(app.UIAxesHist, 'Z')
            app.UIAxesHist.XTick = [0 0.25 0.5 0.75 1];
            app.UIAxesHist.XGrid = 'on';
            app.UIAxesHist.Position = [663 226 211 159];

            % Create UIAxesHist2
            app.UIAxesHist2 = uiaxes(app.UIFigure);
            xlabel(app.UIAxesHist2, 'E')
            ylabel(app.UIAxesHist2, 'S')
            zlabel(app.UIAxesHist2, 'Z')
            app.UIAxesHist2.DataAspectRatio = [1 1 1];
            app.UIAxesHist2.XLim = [-0.2 1.2];
            app.UIAxesHist2.YLim = [-0.2 1.2];
            app.UIAxesHist2.XTick = [0 0.25 0.5 0.75 1];
            app.UIAxesHist2.YTick = [-2.77555756156289e-17 0.25 0.5 0.75 1];
            app.UIAxesHist2.XGrid = 'on';
            app.UIAxesHist2.YGrid = 'on';
            app.UIAxesHist2.Position = [629 3 316 224];

            % Create UIAxesSpotFirst
            app.UIAxesSpotFirst = uiaxes(app.UIFigure);
            zlabel(app.UIAxesSpotFirst, 'Z')
            app.UIAxesSpotFirst.Toolbar.Visible = 'off';
            app.UIAxesSpotFirst.DataAspectRatio = [1 2 1];
            app.UIAxesSpotFirst.PlotBoxAspectRatio = [1 2 1];
            app.UIAxesSpotFirst.XTick = [];
            app.UIAxesSpotFirst.YTick = [];
            app.UIAxesSpotFirst.Box = 'on';
            app.UIAxesSpotFirst.Position = [630 452 129 229];

            % Create UIAxesSpotSecond
            app.UIAxesSpotSecond = uiaxes(app.UIFigure);
            zlabel(app.UIAxesSpotSecond, 'Z')
            app.UIAxesSpotSecond.Toolbar.Visible = 'off';
            app.UIAxesSpotSecond.AmbientLightColor = [1 0 0];
            app.UIAxesSpotSecond.DataAspectRatio = [1 2 1];
            app.UIAxesSpotSecond.PlotBoxAspectRatio = [1 2 1];
            app.UIAxesSpotSecond.XTick = [];
            app.UIAxesSpotSecond.YTick = [];
            app.UIAxesSpotSecond.BoxStyle = 'full';
            app.UIAxesSpotSecond.ClippingStyle = 'rectangle';
            app.UIAxesSpotSecond.Box = 'on';
            app.UIAxesSpotSecond.Position = [793 452 129 228];

            % Create UIAxesSpotFirst_Z
            app.UIAxesSpotFirst_Z = uiaxes(app.UIFigure);
            zlabel(app.UIAxesSpotFirst_Z, 'Z')
            app.UIAxesSpotFirst_Z.Toolbar.Visible = 'off';
            app.UIAxesSpotFirst_Z.PlotBoxAspectRatio = [1 1 1];
            app.UIAxesSpotFirst_Z.XTick = [];
            app.UIAxesSpotFirst_Z.XTickLabel = '';
            app.UIAxesSpotFirst_Z.YTick = [];
            app.UIAxesSpotFirst_Z.YTickLabel = '';
            app.UIAxesSpotFirst_Z.Box = 'on';
            app.UIAxesSpotFirst_Z.Position = [645 380 100 100];

            % Create UIAxesSpotSecond_Z
            app.UIAxesSpotSecond_Z = uiaxes(app.UIFigure);
            zlabel(app.UIAxesSpotSecond_Z, 'Z')
            app.UIAxesSpotSecond_Z.Toolbar.Visible = 'off';
            app.UIAxesSpotSecond_Z.PlotBoxAspectRatio = [1 1 1];
            app.UIAxesSpotSecond_Z.XTick = [];
            app.UIAxesSpotSecond_Z.XTickLabel = '';
            app.UIAxesSpotSecond_Z.YTick = [];
            app.UIAxesSpotSecond_Z.YTickLabel = '';
            app.UIAxesSpotSecond_Z.Box = 'on';
            app.UIAxesSpotSecond_Z.Position = [808 380 100 100];

            % Create PreviousButton
            app.PreviousButton = uibutton(app.UIFigure, 'push');
            app.PreviousButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousButtonPushed, true);
            app.PreviousButton.Position = [133 32 100 23];
            app.PreviousButton.Text = 'Previous';

            % Create NextButton
            app.NextButton = uibutton(app.UIFigure, 'push');
            app.NextButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.NextButton.Position = [243 31 100 23];
            app.NextButton.Text = 'Next';

            % Create GoButton
            app.GoButton = uibutton(app.UIFigure, 'push');
            app.GoButton.ButtonPushedFcn = createCallbackFcn(app, @GoButtonPushed, true);
            app.GoButton.Position = [475 31 70 23];
            app.GoButton.Text = 'Go';

            % Create TraceEditFieldLabel
            app.TraceEditFieldLabel = uilabel(app.UIFigure);
            app.TraceEditFieldLabel.HorizontalAlignment = 'right';
            app.TraceEditFieldLabel.Position = [359 32 34 22];
            app.TraceEditFieldLabel.Text = 'Trace';

            % Create SubDButton
            app.SubDButton = uibutton(app.UIFigure, 'push');
            app.SubDButton.FontColor = [0 0.3804 0.1098];
            app.SubDButton.Position = [18 610 57 23];
            app.SubDButton.Text = 'Sub. D';

            % Create SubAButton
            app.SubAButton = uibutton(app.UIFigure, 'push');
            app.SubAButton.FontColor = [1 0 0];
            app.SubAButton.Position = [18 586 57 23];
            app.SubAButton.Text = 'Sub. A';

            % Create SubButton
            app.SubButton = uibutton(app.UIFigure, 'push');
            app.SubButton.FontColor = [1 0 0];
            app.SubButton.Position = [18 452 57 23];
            app.SubButton.Text = 'Sub.';

            % Create EditFieldTrace
            app.EditFieldTrace = uieditfield(app.UIFigure, 'numeric');
            app.EditFieldTrace.Limits = [1 Inf];
            app.EditFieldTrace.RoundFractionalValues = 'on';
            app.EditFieldTrace.Position = [408 32 52 22];
            app.EditFieldTrace.Value = 1;

            % Create ofEditFieldLabel
            app.ofEditFieldLabel = uilabel(app.UIFigure);
            app.ofEditFieldLabel.HorizontalAlignment = 'right';
            app.ofEditFieldLabel.Position = [359 1 22 22];
            app.ofEditFieldLabel.Text = 'of';

            % Create EditFieldTraceMax
            app.EditFieldTraceMax = uieditfield(app.UIFigure, 'numeric');
            app.EditFieldTraceMax.Editable = 'off';
            app.EditFieldTraceMax.Position = [408 3 52 22];

            % Create UpdateHistButton
            app.UpdateHistButton = uibutton(app.UIFigure, 'push');
            app.UpdateHistButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateHistButtonPushed, true);
            app.UpdateHistButton.Position = [565 31 100 23];
            app.UpdateHistButton.Text = 'Update Hist';

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Position = [476 2 69 23];
            app.ExportButton.Text = 'Export';

            % Create FileNameEditFieldLabel
            app.FileNameEditFieldLabel = uilabel(app.UIFigure);
            app.FileNameEditFieldLabel.HorizontalAlignment = 'right';
            app.FileNameEditFieldLabel.Position = [598 679 56 22];
            app.FileNameEditFieldLabel.Text = 'FileName';

            % Create FileNameTextArea
            app.FileNameTextArea = uieditfield(app.UIFigure, 'text');
            app.FileNameTextArea.Editable = 'off';
            app.FileNameTextArea.Position = [669 679 59 22];

            % Create PathNameEditFieldLabel
            app.PathNameEditFieldLabel = uilabel(app.UIFigure);
            app.PathNameEditFieldLabel.HorizontalAlignment = 'right';
            app.PathNameEditFieldLabel.Position = [739 680 62 22];
            app.PathNameEditFieldLabel.Text = 'PathName';

            % Create PathNameTextArea
            app.PathNameTextArea = uieditfield(app.UIFigure, 'text');
            app.PathNameTextArea.Editable = 'off';
            app.PathNameTextArea.Position = [816 680 117 22];

            % Create CorrFactorsPanel
            app.CorrFactorsPanel = uipanel(app.UIFigure);
            app.CorrFactorsPanel.Title = 'Corr. Factors:';
            app.CorrFactorsPanel.Position = [5 3 104 102];

            % Create AlphaEditFieldLabel
            app.AlphaEditFieldLabel = uilabel(app.CorrFactorsPanel);
            app.AlphaEditFieldLabel.HorizontalAlignment = 'right';
            app.AlphaEditFieldLabel.Position = [4 49 36 22];
            app.AlphaEditFieldLabel.Text = 'Alpha';

            % Create AlphaEditField
            app.AlphaEditField = uieditfield(app.CorrFactorsPanel, 'numeric');
            app.AlphaEditField.Editable = 'off';
            app.AlphaEditField.Position = [52 49 50 21];
            app.AlphaEditField.Value = 0.11;

            % Create EditFieldLabel
            app.EditFieldLabel = uilabel(app.CorrFactorsPanel);
            app.EditFieldLabel.HorizontalAlignment = 'right';
            app.EditFieldLabel.Position = [13 14 25 22];
            app.EditFieldLabel.Text = '?';

            % Create EditField
            app.EditField = uieditfield(app.CorrFactorsPanel, 'numeric');
            app.EditField.Editable = 'off';
            app.EditField.Position = [52 14 50 21];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FRET_ALEX_gui

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
