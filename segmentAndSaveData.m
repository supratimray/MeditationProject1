% Segment the data and

%subjectName = '001VL'; expDate = '010220'; gridType = 'EEG';
%subjectName = '006MVN'; expDate = '030220'; gridType = 'EEG';
%subjectName = '003KB'; expDate = '020220'; gridType = 'EEG';
subjectName = '008KM'; expDate = '030220'; gridType = 'EEG';

protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M'} {'G2'} {'IAT'} {'EC2'} {'EO2'}];
folderSourceString = 'C:\Users\Supratim Ray\OneDrive - Indian Institute of Science\Supratim\Projects\MeditationProjects\MeditationProject1';
timeStartFromBaseLine = -0.848; deltaT = 2.048;

for i=1:length(protocolNameList)
    protocolName = protocolNameList{i};
    
    if strcmp(protocolName(1),'G') % Gamma protocols
        folderExtract = fullfile(folderSourceString,'data',subjectName,gridType,expDate,protocolName,'extractedData');
        [digitalTimeStamps,digitalEvents]=extractDigitalDataBrainProducts(subjectName,expDate,protocolName,folderSourceString,gridType,0);
        saveDigitalData(digitalEvents,digitalTimeStamps,folderExtract);
        
        LLFileExistsFlag = saveLLData(subjectName,expDate,protocolName,folderSourceString,gridType);
        displayTSTEComparison(folderExtract);
        [goodStimNums,goodStimTimes,activeSide]=extractDigitalDataGRFLL(folderExtract,1);
        getDisplayCombinationsGRF(folderExtract,goodStimNums);
    else
        fileName = [subjectName expDate protocolName '.vhdr'];
        folderIn = fullfile(folderSourceString,'data','rawData',[subjectName expDate]);
        eegData = pop_loadbv(folderIn,fileName,[],1);
        times = eegData.times/1000;
        goodStimTimes = ceil(abs(timeStartFromBaseLine)):floor(max(times)-(timeStartFromBaseLine+deltaT)); % Imaginary stimulus onset at 1 second intervals
    end
    getEEGDataBrainProducts(subjectName,expDate,protocolName,folderSourceString,gridType,goodStimTimes,timeStartFromBaseLine,deltaT);
end
