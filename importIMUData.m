function [imu, status] = importIMUData()

[FileName,PathName,FilterIndex] = uigetfile('*.log;*.txt;*.dat','选择数据文件');

status = 0;
imu = [];
if (0 == FilterIndex)
    return;
end

[~,~,ext] = fileparts(FileName);
if ~(strcmp('.log' , ext)|| strcmp('.txt' , ext) || strcmp('.dat' , ext) )
    errordlg('文件格式错误','File Error');
    return;
end

%% 
h = waitbar(0.0,'Importing data, Please wait...');



waitbar(0.1)




%% Initialize variables.
filename = [PathName,FileName];
delimiter = ' ';

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);
waitbar(0.3)
%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = [dataArray{:,1:end-1}];
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end

waitbar(0.5)
%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
imu.timeUS = cell2mat(raw(:, 1));
imu.accX = cell2mat(raw(:, 2));
imu.accY = cell2mat(raw(:, 3));
imu.accZ = cell2mat(raw(:, 4));
imu.q0 = cell2mat(raw(:, 5));
imu.q1 = cell2mat(raw(:, 6));
imu.q2 = cell2mat(raw(:, 7));
imu.q3 = cell2mat(raw(:, 8));
imu.roll = cell2mat(raw(:, 9));
imu.pitch = cell2mat(raw(:, 10));
imu.yaw = cell2mat(raw(:, 11));

waitbar(1)

status = 1;
close(h) 
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans raw numericData col rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me R;