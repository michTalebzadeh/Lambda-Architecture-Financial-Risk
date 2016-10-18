#!/bin/ksh
#--------------------------------------------------------------------------------
#
# Procedure:   send_messages_to_Kafka.ksh
#
# Description:  Sends test prices to Kafka ever 2 seconds
#
# Parameters:   none
#
#--------------------------------------------------------------------------------
# Vers|  Date  | Who | DA | Description
#-----+--------+-----+----+-----------------------------------------------------
# 1.0 |23/02/15|  MT |    | Initial Version
#--------------------------------------------------------------------------------
# 2.0 |23/02/15|  SR |    | Added a few comments
#--------------------------------------------------------------------------------
#
function genrandom
{
        l=$1
        [ "$l" == "" ] && l=50
        tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}
#
function genrandomnumber {
## create an aray of 20 dummy tickers
##echo `date` " ""======= Sending messages from `hostname`" > ${IN_FILE}
ticker[0]="S00"
ticker[1]="S01"
ticker[2]="S02"
ticker[3]="S03"
ticker[4]="S04"
ticker[5]="S05"
ticker[6]="S06"
ticker[7]="S07"
ticker[8]="S08"
ticker[9]="S09"
ticker[10]="S10"
ticker[11]="S11"
ticker[12]="S12"
ticker[13]="S13"
ticker[14]="S14"
ticker[15]="S15"
ticker[16]="S16"
ticker[17]="S17"
ticker[18]="S18"
ticker[19]="S19"
ticker[20]="S20"
integer ROWCOUNT=1
integer ROWS=20
while ((ROWCOUNT <= ROWS))
do
   ## Easch line consists of UUID, Ticker, Timecreated, price
   NUMBER=`echo $(( RANDOM % ("${#ticker[*]}"  - 0 + 1 ) + 0 ))`   ## gernerater integer between 0-20
   UUID=$(uuidgen)
   NOW="`date +%Y-%m-%d`T`date +%H:%M:%S`"
   SIGNAL=`echo "sqrt($((RANDOM%10000+0)))" |bc -l`   ##  price between 1 and 100
   TICKER=${ticker[${ROWCOUNT}]}
   echo "${UUID},${TICKER},${NOW},${SIGNAL}"  >> ${IN_FILE}
   ((ROWCOUNT = ROWCOUNT + 1))
done
}
function readTextFile {
echo `date` " ""======= Sending messages from `hostname`" >> ${IN_FILE}
cat /var/tmp/ASE15UpgradeGuide.txt >> ${IN_FILE}
echo `date` " ""=======  message sent from `hostname` complete" >> ${IN_FILE}
}
#
# Main Section
#
ENVFILE=/home/hduser/.kshrc

if [[ -f $ENVFILE ]]
then
        . $ENVFILE
else
        echo "Abort: $0 failed. No environment file ( $ENVFILE ) found"
        exit 1
fi

NOW="`date +%Y%m%d`"
#
LOGDIR="/var/tmp"
#
FILE_NAME=`basename $0 .ksh`
LOCK_FILE="${LOGDIR}/${FILE_NAME}.lock"
#
### Check to see if the LOCK_FILE file exists.
#
if [[ -f ${LOCK_FILE} ]]
then
        if [[ -s ${LOCK_FILE} ]]
        then
                # script already running
                exit 1
        fi
else
        print "$0 started at `date` " >${LOCK_FILE}
        # Set traps for removal of lock file on exit and on quit signals
        trap "rm ${LOCK_FILE}" 0
        trap "send_alert Abort: $0 killed by a signal; rm ${LOCK_FILE}"  1 2 3 15
fi
#
while true
do
  IN_FILE="${LOGDIR}/${FILE_NAME}.txt"
  [ -f ${IN_FILE} ] && rm -f ${IN_FILE}
  LOG_FILE="${LOGDIR}/${FILE_NAME}.log"
  [ -f ${LOG_FILE} ] && rm -f ${LOG_FILE}
  genrandomnumber
  ## Push the source file as Producer into Kafka. The topic is called Market Data or md
  cat ${IN_FILE} | ${KAFKA_HOME}/bin/kafka-console-producer.sh --broker-list rhes564:9092 --topic md
  if [ $? != 0 ]
  then
	echo `date` " Abort: $0 failed. Could not send message to rhes564:9092" > ${IN_FILE}
        exit 1
  fi
  sleep 2   ## wait 2 seconds and loop

done
#
exit 0
