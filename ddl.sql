CREATE TABLE IF NOT EXISTS odata.invite_audition_student_beijing (stuid string comment '学员ID')
COMMENT '邀请试听人员表(北京地区)'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE;


load data local inpath '/home/yuhang1.wu/invite_audition_student_beijing.csv' into table odata.invite_audition_student_beijing;