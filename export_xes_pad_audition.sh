#!/bin/bash

MYADDR=192.168.11.196
MYPORT=1521
MYDB=xesbi1
MYUSER=haxesbi
MYPWD=IuT7FcLmQa1Z
HDBPATH=/opt/hive/warehouse/dm_newbi.db
my_table_name=xes_pad_audition
hive_table_name=$my_table_name

sqoop eval \
    --connect jdbc:oracle:thin:@$MYADDR:$MYPORT:$MYDB \
    --username $MYUSER \
    --password $MYPWD \
    --query "truncate table "$my_table_name" "

sqoop export  \
    -D mapreduce.job.max.split.locations=50 \
    --connect jdbc:oracle:thin:@$MYADDR:$MYPORT:$MYDB \
    --username $MYUSER \
    --password $MYPWD \
    --table $my_table_name \
    --input-null-string '\\N' \
    --input-null-non-string '\\N' \
    --export-dir $HDBPATH/$hive_table_name \
    --columns city_name,class_type_name,schl_year,term_name,student_type,invite_audition_nums,regist_audition_nums,complete_audition_nums,finance_nums,audition_trans_radio,finance_trans_radio,trans_radio \
    --input-fields-terminated-by '\001' \
    --input-fields-terminated-by '\t'