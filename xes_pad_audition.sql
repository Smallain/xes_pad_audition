
--关联dw_data.dw_cfg_city表获取分校名称信息
--关联dw_data.dw_class表获取班级及课次信息
--关联dw_data.dw_curriculum获取课次信息包括课次开课时间等
--关联odata.invite_audition_student_beijing获取那些人是在邀请名单中的那些人是来访人员

DROP TABLE IF EXISTS test.xes_pad_audition_stu_info;


CREATE TABLE IF NOT EXISTS test.xes_pad_audition_stu_info AS
SELECT city.city_id,
       city.city_name,
       audition.student_id,
       class.cla_id,
       class.class_type,
       CASE
           WHEN class.class_type='1' THEN '在线'
           WHEN class.class_type='2' THEN '双师'
           WHEN class.class_type='4' THEN '面授'
           WHEN class.class_type='8' THEN '直播'
           ELSE '其他'
       END AS class_type_name,
       class.schl_year,
       class.term_id,
       class.term_name,
       audition.course_no,
       curriculum.cuc_date,
       date_add(curriculum.cuc_date,30) AS audition_pay_end_date,
       invite.stuid,
       CASE
           WHEN invite.stuid IS NULL THEN '2'
           ELSE '1'
       END AS student_type
FROM odata.ods_bn_tb_audition audition
JOIN dw_data.dw_cfg_city city ON audition.city_id = city.city_id
JOIN dw_data.dw_class CLASS ON audition.city_id = CLASS.city_id
AND audition.class_id = CLASS.cla_id
JOIN dw_data.dw_curriculum curriculum ON audition.city_id = curriculum.city_id
AND audition.class_id = curriculum.cla_id
AND audition.course_no = curriculum.cuc_no
LEFT JOIN odata.invite_audition_student_beijing invite ON audition.student_id = invite.stuid
WHERE audition.deleted = '0'
AND audition.city_id!='02501';






--财务表，以fina_class_id,fina_student_id,fina_reg_class_no,city_id分区并且取每个课次的最早时间的一次记录信息

DROP TABLE IF EXISTS test.xes_pad_audition_finance_info;

CREATE TABLE IF NOT EXISTS test.xes_pad_audition_finance_info AS
SELECT city_id,
       fina_class_id,
       fina_student_id,
       fina_reg_class_no,
       min(fina_create_date) AS fina_create_date
FROM odata.ods_bn_tb_finance
WHERE fina_entity_metavalue = '0' --收支类型   ：报名
AND fina_type = '0' --收支类型 ： 收入
AND fina_deleted='0' --是否删除(0：未删除；1：已删除；
AND fina_bi_test = '0' --不是测试数据
GROUP BY fina_class_id,
         fina_student_id,
         fina_reg_class_no,
         city_id;




--关联xes_pad_audition_finance_info finance表，找出大于或等于试听报班课次号的课次。一般情况下只会有一条，
--因为不会有人第一次课次交钱，第二次课次又交钱了的情况

DROP TABLE IF EXISTS test.xes_pad_audition_info;

CREATE TABLE IF NOT EXISTS test.xes_pad_audition_info AS
SELECT stu.city_id,
       stu.city_name,
       stu.student_id,
       stu.cla_id,
       stu.class_type,
       stu.class_type_name,
       stu.schl_year,
       stu.term_id,
       stu.term_name,
       stu.course_no,
       stu.cuc_date,
       stu.audition_pay_end_date,
       stu.stuid,
       stu.student_type,
       finance.fina_class_id,
       finance.fina_student_id,
       finance.fina_reg_class_no,
       finance.fina_create_date
FROM test.xes_pad_audition_stu_info stu
LEFT JOIN test.xes_pad_audition_finance_info finance ON stu.city_id = finance.city_id
AND stu.student_id = finance.fina_student_id
AND stu.cla_id = finance.fina_class_id
WHERE finance.fina_reg_class_no IS NULL
 OR (finance.fina_reg_class_no>=stu.course_no);
 
 
 
 
 

--展现最后的筛选计算逻辑


DROP TABLE IF EXISTS dm_newbi.xes_pad_audition;


CREATE TABLE IF NOT EXISTS dm_newbi.xes_pad_audition AS
SELECT audition_statistics_info.city_id,
       audition_statistics_info.city_name,
       audition_statistics_info.class_type,
       audition_statistics_info.class_type_name,
       audition_statistics_info.schl_year,
       audition_statistics_info.term_id,
       audition_statistics_info.term_name,
       audition_statistics_info.student_type,
       CASE
           WHEN audition_statistics_info.student_type = '1' THEN invite.invite_audition_nums
           ELSE ''
       END AS invite_audition_nums,
       nvl(audition_statistics_info.regist_audition_nums,0) as regist_audition_nums,
       '' AS complete_audition_nums,
       nvl(audition_statistics_info.finance_nums,0) as finance_nums,
       '' AS audition_trans_radio,
       '' AS finance_trans_radio,
       concat(cast(round(
       case when nvl(audition_statistics_info.regist_audition_nums,0) = 0 then 0
       else audition_statistics_info.finance_nums/audition_statistics_info.regist_audition_nums*100 end
       ,2) AS string),'%') AS trans_radio
FROM
 (SELECT audition_info.city_id,
         audition_info.city_name,
         audition_info.class_type,
         audition_info.class_type_name,
         audition_info.schl_year,
         audition_info.term_id,
         audition_info.term_name,
         audition_info.student_type,
         count(*) AS regist_audition_nums,
         sum(if(fina_student_id IS NULL,0,1)) AS finance_nums
  FROM test.xes_pad_audition_info audition_info
  GROUP BY audition_info.city_id,
           audition_info.city_name,
           audition_info.class_type,
           audition_info.class_type_name,
           audition_info.schl_year,
           audition_info.term_id,
           audition_info.term_name,
           audition_info.student_type) audition_statistics_info
JOIN
 (SELECT count(*) AS invite_audition_nums
  FROM odata.invite_audition_student_beijing) invite ON 1=1;