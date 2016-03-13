function imuDataPreProcess()
clear all;clc;close all
%% ����ȫ�ֱ���
global imuQueue imuFilterQueue queueDepth
global index dataLength maxIndex minIndex
global maxImuData minImuData threshold
%% ��������
[imuData, ok] = importIMUData();
if ~ok
    return;
end

plotEnbal = 1;          % 0�� ����ͼ�� 1����ͼ
plotData(imuData,plotEnbal);

%% ��ʼ������
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
figure('Name','�����ֵ��','NumberTitle','off')
for cnt=1:n
    
    % �����²ɼ���������ѹ�������
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
    
    
    % ���ɼ��������ݽ��е�ͨ�˲�
    putImuIntoFilterQueue(errThreshold);
    
    % imuDate = getImuFromQueue();
    %     disp(imuDate)
    
    % �������е�ԭʼ����
    allData = [allData;getImuFromQueue()];
    
    % �������е��˲�����
    allFilterData = [allFilterData;getImuFromFilterQueue()];
    
    % ���¶��������ݵ������ֵ����Сֵ
    updateMaxMin(cnt);
    
    % ���ҵ�?���е����ֵ or ��Сֵ
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
                    % �����ֵ�ŵ���Сֵ�ġ��ݡ���
                    temp = getImuFromFilterQueue();
                    minImuData(findMaxOrMincolumns) = temp(findMaxOrMincolumns);
                    minIndex(findMaxOrMincolumns) = cnt;
                    fprintf('���ֵ���� %d\n',cnt-threshold)
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
                    % ����Сֵ�ŵ����ֵ�ġ��ݡ���
                    temp = getImuFromFilterQueue();
                    maxImuData(findMaxOrMincolumns) = temp(findMaxOrMincolumns);
                    maxIndex(findMaxOrMincolumns) = cnt;
                    fprintf('��Сֵ���� %d\n',cnt-threshold)
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


%% ������ѹ�뵽������
function putImuIntoQueue(imuData)

global imuQueue index

imuQueue(index,:) = imuData;

end


%% ȡ����ǰ���������µ�����
function imuData = getImuFromQueue()

global imuQueue index

imuData = imuQueue(index,:);

end

%% ȡ����ǰ���������µ�����
function imuData = getImuFromFilterQueue()

global imuFilterQueue index

imuData = imuFilterQueue(index,:);

end

%% ��ȡ��ǰ���е�������������Ӧ������
function currentIndex = getCurrentQueueIndex()
global  index
currentIndex = index;
end

% �����ݽ����˲��������뵽�˲����ݵĶ�����
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


%% ��ȡ��ͨ�˲�ϵ��
function co = getFilterCo()
dt = 0.005;     %��������
fc = 5;         %��ֹƵ��
rc = 1/(2*pi*fc);
co = 1 - dt/(dt + rc);

end

%% �����˲������е������Сֵ
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


%% �ж����ֵ�Ƿ��Ѿ�������
function b = maxDataArrived(dataIndex, cnt)

global maxIndex threshold

a = cnt - maxIndex(dataIndex);

if((a >= threshold) && (maxIndex(dataIndex)~= 1))
    b = 1;
else
    b = 0;
end

end


%% �ж����ֵ����Сֵ�Ƿ��Ѿ�������
function b = minDataArrived(dataIndex, cnt)

global minIndex threshold

a = cnt - minIndex(dataIndex);

if((a > threshold) && (minIndex(dataIndex)~= 1))
    b = 1;
else
    b = 0;
end

end

%% ���¶��е�index
function updataIndex()
global index queueDepth
index = index + 1;
if (index>queueDepth)
    index = 1;
end
end
