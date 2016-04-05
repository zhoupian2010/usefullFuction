function imuDataPreProcess()
clear all;clc;close all
%% 定义全局变量
global imuQueue imuFilterQueue queueDepth
global index dataLength maxIndex minIndex
global maxImuData minImuData threshold
%% 导入数据
[imuData, ok] = importIMUData();
if ~ok
    return;
end

plotEnbal = 1;          % 0： 不绘图； 1：给图
plotData(imuData,plotEnbal);

%% 初始化变量
threshold = 5;
queueDepth = 20;
index = 1;
dataLength = 11;
imuQueue = zeros(queueDepth,dataLength);
imuQueue(:,1) = (1:queueDepth)';
findMaxMinType = '';
starPosCal = 0;
Vel = zeros(3,threshold);
Pos = zeros(3,threshold);

allData = [];allFilterData =[];
errThreshold = [0, ones(1,3)*1, ones(1,4)*0.5, ones(1,3)*360];

n = length(imuData.timeUS);
figure('Name','标记最值点','NumberTitle','off')
for cnt=1:n
    
    % 将最新采集到的数据压入队列中
    putImuIntoQueue([imuData.timeUS(cnt),...
        imuData.accX(cnt),...
        imuData.accY(cnt),...
        imuData.accZ(cnt),...
        imuData.q0(cnt),...
        imuData.q1(cnt),...
        imuData.q2(cnt),...
        imuData.q3(cnt),...
        imuData.roll(cnt),...
        imuData.pitch(cnt),...
        imuData.yaw(cnt)  ]);
    
    
    % 将采集到的数据进行低通滤波
    putImuIntoFilterQueue(errThreshold);
    
    % imuDate = getImuFromQueue();
    %     disp(imuDate)
    
    % 保存所有的原始数据
    allData = [allData;getImuFromQueue()];
    
    % 保存所有的滤波数据
    allFilterData = [allFilterData;getImuFromFilterQueue()];
    
    % 更新队列中数据的中最大值、最小值
    updateMaxMin(cnt);
    
    % 查找第?列中的最大值 or 最小值
    findMaxOrMincolumns = 9;
    %     2: accX
    %     3: accY
    %     4: accZ
    %     9: roll
    %     10: pitch
    %     11: yaw
    if (cnt > threshold)
        switch findMaxMinType
            case 'MAX'
                tf = maxDataArrived(findMaxOrMincolumns,cnt);
                if (tf == 1)
                    starPosCal = 1;
                    findMaxMinType = 'MIN';
                    % 将最大值放到最小值的“泡”中
                    temp = getImuFromFilterQueue();
                    minImuData(findMaxOrMincolumns) = temp(findMaxOrMincolumns);
                    minIndex(findMaxOrMincolumns) = cnt;
                    fprintf('最大值点在 %d\n',cnt-threshold)
                    %           flag = 1;
                    maxMinPoint = allFilterData(cnt-threshold,[1,findMaxOrMincolumns]);
                    plot(maxMinPoint(1),maxMinPoint(2),'mo','MarkerEdgeColor','k',...
                        'MarkerFaceColor','g','MarkerSize',8)
                    hold on
                end
            case 'MIN'
                tf = minDataArrived(findMaxOrMincolumns,cnt);
                if (tf == 1)
                    starPosCal = 1;
                    findMaxMinType = 'MAX';
                    % 将最小值放到最大值的“泡”中
                    temp = getImuFromFilterQueue();
                    maxImuData(findMaxOrMincolumns) = temp(findMaxOrMincolumns);
                    maxIndex(findMaxOrMincolumns) = cnt;
                    fprintf('最小值点在 %d\n',cnt-threshold)
                    %           flag = 1;
                    maxMinPoint = allFilterData(cnt-threshold,[1,findMaxOrMincolumns]);
                    plot(maxMinPoint(1),maxMinPoint(2),'mo','MarkerEdgeColor','k',...
                        'MarkerFaceColor','r','MarkerSize',8)
                    hold on
                end
            otherwise
                
                if (maxDataArrived(findMaxOrMincolumns,cnt)) 
                    findMaxMinType = 'MIN';
                end               
                
                if (minDataArrived(findMaxOrMincolumns,cnt))
                    findMaxMinType = 'MAX';
                end
                
        end
        
        [Vel(:,cnt),Pos(:,cnt)] =VelPos(starPosCal,getImuFromFilterQueue(-threshold),findMaxMinType,Vel(:,cnt-1),Pos(:,cnt-1));
        
    end
    
    updataIndex();
end

plot(allData(:,1),allData(:,findMaxOrMincolumns),'r')
hold on
plot(allFilterData(:,1),allFilterData(:,findMaxOrMincolumns),'b')
grid off

plotData(allFilterData,0)
figure(5)
plot(Pos');
figure(6)
plot(Vel');
save Pos Vel
end


function [V,P]=VelPos(starPosCal,imuData,flag,vn_0,pos_0)
persistent lastFlag turnaround
if isempty(lastFlag)
    lastFlag = 'MAX';
    turnaround = 0;
end
V=[0;0;0];
P=[0;0;0];
ts = 0.01;
if starPosCal==0
    return;
end
q=imuData(5:8)';
acc_b=imuData(2:4)';
%计算Cbn
C_bn(1,1)=1-2*(q(3)^2+q(4)^2);
C_bn(1,2)=2*q(2)*q(3)-q(1)*q(4);
C_bn(1,3)=2*q(2)*q(4)+q(1)*q(3);
C_bn(2,1)=2*q(2)*q(3)+q(1)*q(4);
C_bn(2,2)=1-2*(q(2)^2+q(4)^2);
C_bn(2,3)=2*q(3)*q(4)-q(1)*q(2);
C_bn(3,1)=2*q(2)*q(4)-q(1)*q(3);
C_bn(3,2)=2*q(3)*q(4)+q(1)*q(2);
C_bn(3,3)=1-2*(q(2)^2+q(3)^2);

%计算线加速度
gn=[0;0;1];
g0=9.78;
an=C_bn*acc_b-gn;

%计算速度
V=vn_0+an*g0*ts; %because sample rate is 100Hz

%计算位移
P=pos_0 +(V+vn_0)*0.5*ts;

if(~strcmp(lastFlag,flag))
    turnaround = turnaround + 1;
    if (turnaround == 2)
        V=[0;0;0];
        P=[0;0;0];
        turnaround = 0;
    end
end

lastFlag = flag;


end



%% 将数据压入到队列中
function putImuIntoQueue(imuData)

global imuQueue index

imuQueue(index,:) = imuData;

end


%% 取出当前队列中的数据
function imuData = getImuFromQueue(varargin)

global imuQueue index queueDepth

nVarargs = length(varargin);

if ~nVarargs
    imuData = imuQueue(index,:);
else
    temp = mod(index+varargin{1},queueDepth);
    if ~temp
        temp = queueDepth;
    end
    imuData = imuQueue(temp,:);
end

end

%% 取出当前队列中的数据
function imuData = getImuFromFilterQueue(varargin)

global imuFilterQueue index queueDepth

nVarargs = length(varargin);

if ~nVarargs
    imuData = imuFilterQueue(index,:);
else
    temp = mod(index+varargin{1},queueDepth);
    if ~temp
        temp = queueDepth;
    end
    imuData = imuFilterQueue(temp,:);
end

end

%% 获取当前队列的最新数据所对应的索引
function currentIndex = getCurrentQueueIndex()
global  index
currentIndex = index;
end

% 对数据进行滤波，并放入到滤波数据的队列中
function putImuIntoFilterQueue(errThreshold)

global queueDepth index imuFilterQueue dataLength

if isempty(imuFilterQueue)
    imuFilterQueue(1,:) = getImuFromQueue();
    return;
end

k = getFilterCo();

newIMUdata = getImuFromQueue();
imuFilterQueue(index,1) = newIMUdata(1);

if (index == 1)
    lastfilterIMUdata = imuFilterQueue(queueDepth,:);
else
    lastfilterIMUdata = imuFilterQueue(index-1,:);
end

for i = 2:dataLength
    if(abs(newIMUdata(i)-lastfilterIMUdata(i)) > errThreshold(i))
        newIMUdata(i) = lastfilterIMUdata(i);
    end
end

if(index == 1)
    imuFilterQueue(index,2:end) = imuFilterQueue(queueDepth,2:end)*k + newIMUdata(2:end)*(1-k);
else
    imuFilterQueue(index,2:end) = imuFilterQueue(index-1,2:end)*k + newIMUdata(2:end)*(1-k);
end


end


%% 获取低通滤波系数
function co = getFilterCo()
dt = 0.01;     %采样周期
fc = 20;         %截止频率
rc = 1/(2*pi*fc);
co = 1 - dt/(dt + rc);

end

%% 更新滤波队列中的最大最小值
function updateMaxMin(cnt)

global dataLength imuFilterQueue index
global maxImuData minImuData maxIndex minIndex


if isempty(maxImuData)
    maxImuData = imuFilterQueue(1,:);
    minImuData = imuFilterQueue(1,:);
end


for i = 2:dataLength
    if (imuFilterQueue(index,i) > maxImuData(i))
        maxImuData(i) = imuFilterQueue(index,i);
        maxIndex(i) = cnt;
    end
    
    if(imuFilterQueue(index,i) < minImuData(i))
        minImuData(i) = imuFilterQueue(index,i);
        minIndex(i) = cnt;
    end
    
end

end


%% 判断最大值是否已经出现了
function b = maxDataArrived(dataIndex, cnt)

global maxIndex threshold

a = cnt - maxIndex(dataIndex);

if((a >= threshold) && (maxIndex(dataIndex)~= 1))
    b = 1;
else
    b = 0;
end

end


%% 判断最大值、最小值是否已经出现了
function b = minDataArrived(dataIndex, cnt)

global minIndex threshold

a = cnt - minIndex(dataIndex);

if((a > threshold) && (minIndex(dataIndex)~= 1))
    b = 1;
else
    b = 0;
end

end

%% 更新队列的index
function updataIndex()
global index queueDepth
index = index + 1;
if (index>queueDepth)
    index = 1;
end
end
