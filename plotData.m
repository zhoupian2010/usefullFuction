%% �Բɼ������ݽ��л�ͼ
% first input   : the data used to plot
% second input  : enable plot ,plot when equal 1
%%
function plotData(varargin)

nVarargs = length(varargin);

if nVarargs==0
    errordlg('û�п��õ�����')
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
    errordlg('����ı�������')
    return;
end
    

if ifplot
    
    figure('Name','ԭʼ��������','NumberTitle','off')
    
    time = data.timeMS/1000;
    
    subplot(3,1,1)
    plot(time,data.accX,time,data.accY,time,data.accZ)
    legend('accX','accY','accZ')
    xlabel('time/s')
    ylabel('g')
    grid on
    
    subplot(3,1,2)
    plot(time,data.gyroX,time,data.gyroY,time,data.gyroZ)
    legend('gyroX','gyroY','gyroZ')
    xlabel('time/s')
    ylabel('deg/s')
    grid on
    
    subplot(3,1,3)
    plot(time,data.roll,time,data.pitch,time,data.yaw)
    legend('roll','pitch','yaw')
    xlabel('time/s')
    ylabel('deg')
    grid on
end


