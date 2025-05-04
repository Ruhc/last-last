@echo off
echo Stopping all services...

REM Stop HDFS
echo Stopping HDFS...
/opt/hadoop/sbin/stop-dfs.sh

REM Stop Kafka
echo Stopping Kafka...
/opt/kafka/bin/kafka-server-stop.sh

REM Stop Zookeeper
echo Stopping Zookeeper...
/opt/kafka/bin/zookeeper-server-stop.sh

REM Stop Cassandra
echo Stopping Cassandra...
taskkill /F /IM cassandra.exe

REM Stop Python processes
echo Stopping Python processes...
taskkill /F /IM python.exe

echo All services stopped successfully! 