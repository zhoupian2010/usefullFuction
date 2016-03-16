%% 对采集的数据进行绘图
% first input   : the data used to plot
% second input  : enable plot ,plot when equal 1
%%
function plotData(varargin)

nVarargs = length(varargin);

if nVarargs==0
    errordlg('没有可用的数据')
    return;
end

if nVarargs == 1
    data = varargin{1};
    ifplot = 1;
end

if nVarargs == 2
    data = varargin{1};
    ifplot = varargin{2};
end


if nVarargs >2
    errordlg('输入的变量过多')
    return;
end
    
% 
% if ~isstruct(data)
%     temp = data;
%     data = [];
%     data.timeMS = temp(:, 1);
%     data.accX = temp(:, 2);
%     data.accY = temp(:, 3);
%     data.accZ = temp(:, 4);
%     data.gyroX = temp(:, 5);
%     data.gyroY = temp(:, 6);
%     data.gyroZ = temp(:, 7);
%     data.roll = temp(:, 8);
%     data.pitch = temp(:, 9);
%     data.yaw = temp(:, 10);
% end
% 
% if ifplot
%     
%     figure('Name','数据曲线','NumberTitle','off')
%     
%     time = data.timeMS/1000;
%     
%     subplot(3,1,1)
%     plot(time,data.accX,time,data.accY,time,data.accZ)
%     legend('accX','accY','accZ')
%     xlabel('time/s')
%     ylabel('g')
%     grid on
%     
%     subplot(3,1,2)
%     plot(time,data.gyroX,time,data.gyroY,time,data.gyroZ)
%     legend('gyroX','gyroY','gyroZ')
%     xlabel('time/s')
%     ylabel('deg/s')
%     grid on
%     
%     subplot(3,1,3)
%     plot(time,data.roll,time,data.pitch,time,data.yaw)
%     legend('roll','pitch','yaw')
%     xlabel('time/s')
%     ylabel('deg')
%     grid on



if ~isstruct(data)
    temp = data;
    data = [];
    data.timeUS = temp(:, 1);
    data.accX = temp(:, 2);
    data.accY = temp(:, 3);
    data.accZ = temp(:, 4);
    
    data.roll = temp(:, 9);
    data.pitch = temp(:, 10);
    data.yaw = temp(:, 11);
end

if ifplot
    
    figure('Name','数据曲线','NumberTitle','off')
    
    time = data.timeUS/1e6;
    
    subplot(2,1,1)
    plot(time,data.accX,time,data.accY,time,data.accZ)
    legend('accX','accY','accZ')
    xlabel('time/s')
    ylabel('g')
    grid on
   
    subplot(2,1,2)
    plot(time,data.roll,time,data.pitch,time,data.yaw)
    legend('roll','pitch','yaw')
    xlabel('time/s')
    ylabel('deg')
    grid on
end


