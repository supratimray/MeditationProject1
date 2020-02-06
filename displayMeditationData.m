% Displays data collected for the meditation project

% ToDo
% 1. Pipeline to find bad trials based on 1) eye data, 2) time domain signal fluctuation, 3) PSDs
% 2. Option to use unipolar or bipolar referencing

function displayMeditationData(subjectName,expDate,folderSourceString,badElectrodeList,plotRawTFFlag)

if ~exist('folderSourceString','var');    folderSourceString=[];        end
if ~exist('badElectrodeList','var');      badElectrodeList=[];          end
if ~exist('plotRawTFFlag','var');         plotRawTFFlag=0;              end

if isempty(folderSourceString)
    folderSourceString = 'C:\Users\Supratim Ray\OneDrive - Indian Institute of Science\Supratim\Projects\MeditationProjects\MeditationProject1';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fixed variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%
gridType = 'EEG';
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M'} {'G2'} {'IAT'} {'EC2'} {'EO2'}];
numProtocols = length(protocolNameList);

electrodeGroupList{1} = [16:18    (32+[14:18 32])]; groupNameList{1} = 'Occipital'; % Occipital
electrodeGroupList{2} = [11:15 19:20 22:23 (32+[11:13 19:22])]; groupNameList{2} = 'Centro-Parietal'; % Centro-Parietal
electrodeGroupList{3} = [6:8 24:25 28:29   (32+[7:9 24:26])]; groupNameList{3} = 'Fronto-Central'; % Fronto-Central
electrodeGroupList{4} = [1:4 30:32 (32+[1:5 28:31])]; groupNameList{4} = 'Frontal'; % Frontal
electrodeGroupList{5} = [5 9:10 21 26:27 (32+[6 10 23 27])]; groupNameList{5} = 'Temporal'; % Temporal

numGroups = length(electrodeGroupList);

%%%%%%%%%%%%%%%%%%%%%%%%%%% Set up plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hTF = getPlotHandles(numGroups,numProtocols,[0.05 0.05 0.75 0.9],0.01,0.01,1);
hPSD  = getPlotHandles(numGroups,1,[0.825 0.05 0.15 0.9],0.01,0.01,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%% Ranges for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colormap jet;
freqRangeHz = [0 60];
colorNames = [{'m'} {'c'} {[0.5 0.5 0.5]} {'g'} {'k'} {'y'} {'b'} {'r'}];

if plotRawTFFlag
    cLims = [-3 3];
else
    cLims = [-1.5 1.5];
end

% Get Data
for g=1:numGroups
    electrodeList = setdiff(electrodeGroupList{g},badElectrodeList);
    disp(['Working on group: ' groupNameList{g}]);
    
    % Get Data
    psdVals = cell(1,numProtocols);
    freqVals = cell(1,numProtocols);
    for i=1:numProtocols
        protocolName = protocolNameList{i};
        [psdVals{i},freqVals{i}] = getData(subjectName,expDate,protocolName,folderSourceString,gridType,electrodeList);
    end
    
    % Plot Data
    for i=1:numProtocols
        if ~isempty(psdVals{i})
            
            if plotRawTFFlag
                pcolor(hTF(g,i),1:size(psdVals{i},2),freqVals{i},log10(psdVals{i})); 
            else
                bl = repmat(mean(log10(psdVals{1}(:,1:100)),2),1,size(psdVals{i},2));
                pcolor(hTF(g,i),1:size(psdVals{i},2),freqVals{i},log10(psdVals{i})-bl);
            end
                
            shading(hTF(g,i),'interp');
            caxis(hTF(g,i),cLims); 
            ylim(hTF(g,i),freqRangeHz);
            
            if plotRawTFFlag
                plot(hPSD(g),freqVals{i},mean(log10(psdVals{i}),2),'color',colorNames{i});
            else
                plot(hPSD(g),freqVals{i},mean(log10(psdVals{i})-bl,2),'color',colorNames{i});
            end
            xlim(hPSD(g),freqRangeHz);
            ylim(hPSD(g),cLims);
            hold(hPSD(g),'on');
        end
        
        if (i==1 && g<numGroups)
            set(hTF(g,i),'XTickLabel',[]); % only remove x label
        elseif (i>1 && g<numGroups)
            set(hTF(g,i),'XTickLabel',[],'YTickLabel',[]);
        elseif (i>1 && g==numGroups)
            set(hTF(g,i),'YTickLabel',[]); % only remove y label
        end
    end
    
    if g<numGroups
            set(hPSD(g),'XTickLabel',[]);
    end
    
    ylabel(hTF(g,1),groupNameList{g});
end

legend(hPSD(numGroups),protocolNameList);
for i=1:numProtocols
    title(hTF(1,i),protocolNameList{i});
    xlabel(hTF(numGroups,i),'TrialNum');
end
end

function [psd,freqVals] = getData(subjectName,expDate,protocolName,folderSourceString,gridType,electrodeList)

timeRange = [0.25 0.75];
tapers = [1 1];
freqRange = [0 100];

folderExtract = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName,'extractedData');
folderSegment = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName,'segmentedData');

if ~exist(folderExtract,'file')
    disp([folderExtract ' does not exist']);
    psd = []; freqVals=[];
else
    numElectrodes = length(electrodeList);
    
    t = load(fullfile(folderSegment,'LFP','lfpInfo.mat'));
    timeVals = t.timeVals;
    Fs = round(1/(timeVals(2)-timeVals(1)));
    goodTimePos = find(timeVals>=timeRange(1),1) + (1:round(Fs*diff(timeRange)));
    
    % Set up multitaper
    params.tapers   = tapers;
    params.pad      = -1;
    params.Fs       = Fs;
    params.fpass    = freqRange;
    params.trialave = 0;
    
    for i=1:numElectrodes
        e = load(fullfile(folderSegment,'LFP',['elec' num2str(electrodeList(i)) '.mat']));
        [psdTMP(i,:,:),freqVals] = mtspectrumc(e.analogData(:,goodTimePos)',params); %#ok<AGROW>
    end
    psd = squeeze(mean(psdTMP,1));
end
end