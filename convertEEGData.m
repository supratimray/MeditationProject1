% Convert Data from EEG to .mat format

subjectName = '001VL'; expDate = '010220'; gridType = 'EEG';
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M'} {'G2'} {'IAT'} {'EC2'} {'EO2'}]; 

folderSourceString = 'C:\Users\Supratim Ray\OneDrive - Indian Institute of Science\Supratim\Projects\MeditationProjects\MeditationProject1';

for i=1:length(protocolNameList)
    protocolName = protocolNameList{i};
    folderName = fullfile(folderSourceString,'data','rawData',[subjectName expDate]);
    fileNameIn = [subjectName expDate protocolName '.vhdr'];
    fileNameOut = [subjectName expDate protocolName '.mat'];
    
    if exist(fullfile(folderName,fileNameIn),'file')
        % use EEGLAB plugin "bva-io" to read the file
        disp(['Saving data ' fullfile(folderName,fileNameIn)]);
        eegData = pop_loadbv(folderName,fileNameIn,[],[]);
        save(fullfile(folderName,fileNameOut),'eegData');
    else
        disp([fullfile(folderName,fileNameIn) ' not found']);
    end
end
