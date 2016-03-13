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
queueDepth = 10;
index = 1;
dataLength = 10;
imuQueue = zeros(queueDepth,dataLength);
imuQueue(:,1) = (1:queueDepth)';
findMaxMinType = 'MAX';
allData = [];allFilterData =[];
errThreshold = [0, ones(1,3)*0.1, ones(1,3)*300, ones(1,3)*300];

n = length(imuData.timeMS);
figure('Name','标记最值点','NumberTitle','off')
for cnt=1:n
    
    % 将最新采集到的数据压入队列中
    putImuIntoQueue([imuData.timeMS(cnt),...
        imuData.accX(cnt),...
        imuData.accY(cnt),...
        imuData.accZ(cnt),...
        imuData.gyroX(cnt),...
        imuData.gyroY(cnt),...
        imuData.gyroZ(cnt),...
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
    findMaxOrMincolumns = 8;
    %     2: accX
    %     3: accY
    %     4: accZ
    %     5: gyroX
    %     6: gyroY
    %     7: gyroZ
    %     8: roll
    %     9: pitch
    %     10: yaw
    if (cnt > threshold)
        switch findMaxMinType
            case 'MAX'
                tf = maxDataArrived(findMaxOrMincolumns,cnt);
                if (tf == 1)
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
                
        end
    end
    
    updataIndex();
end

plot(allData(:,1),allData(:,findMaxOrMincolumns),'r')
hold on
plot(allFilterData(:,1),allFilterData(:,findMaxOrMincolumns),'b')
grid off

plotData(allFilterData)
end


%% 将数据压入到队列中
function putImuIntoQueue(imuData)

global imuQueue index

imuQueue(index,:) = imuData;

end


%% 取出当前队列中最新的数据
function imuData = getImuFromQueue()

global imuQueue index

imuData = imuQueue(index,:);

end

%% 取出当前队列中最新的数据
function imuData = getImuFromFilterQueue()

global imuFilterQueue index

imuData = imuFilterQueue(index,:);

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
dt = 0.005;     %采样周期
fc = 5;         %截止频率
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
    if (imuFilterQueue(index,i) >= maxImuData(i))
        maxImuData(i) = imuFilterQueue(index,i);
        maxIndex(i) = cnt;
    end
    
    if(imuFilterQueue(index,i) <= minImuData(i))
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
