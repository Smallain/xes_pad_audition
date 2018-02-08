--xes_pad_audition_stu_info学员信息表，关联xes_pad_audition_finance_info找出在试听之前课程的财务信息
DROP TABLE IF EXISTS test.xes_pad_audition_stu_info_status_sub;
CREATE TABLE IF NOT EXISTS test.xes_pad_audition_stu_info_status_sub AS
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
       audition.create_time,
       finance.fina_class_id,
       finance.fina_student_id,
       finance.fina_reg_class_no,
       finance.fina_create_date
FROM test.xes_pad_audition_stu_info stu
JOIN odata.ods_bn_tb_audition audition ON stu.city_id = audition.city_id
AND stu.student_id = audition.student_id
AND stu.cla_id = audition.class_id
LEFT JOIN test.xes_pad_audition_finance_info finance ON stu.city_id = finance.city_id
AND stu.student_id = finance.fina_student_id 
WHERE finance.fina_create_date IS NULL
 or  (finance.fina_create_date<=audition.create_time);




--将找到的试听开课前的财务信息与之前的试听学员信息表再次关联，体现出全部的学员信息
--再次关联的原因是以下
--WHERE finance.fina_create_date IS NULL
--or  (finance.fina_create_date<=audition.create_time)
--条件如果作用与最终的结果表会筛选掉一些学员信息，顾再次关联，找到全部的学员信息

DROP TABLE IF EXISTS test.xes_pad_audition_stu_info_status;
CREATE TABLE IF NOT EXISTS test.xes_pad_audition_stu_info_status AS
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
       audition.create_time,
       stu_info_sub.fina_class_id,
       stu_info_sub.fina_student_id,
       stu_info_sub.fina_reg_class_no,
       stu_info_sub.fina_create_date
FROM test.xes_pad_audition_stu_info stu
JOIN odata.ods_bn_tb_audition audition ON stu.city_id = audition.city_id
AND stu.student_id = audition.student_id
AND stu.cla_id = audition.class_id
LEFT JOIN test.xes_pad_audition_stu_info_status_sub stu_info_sub ON stu.city_id = stu_info_sub.city_id
AND stu.student_id = stu_info_sub.student_id 
and stu.schl_year = stu_info_sub.schl_year;
 

 

--找到长期班的班级信息

DROP TABLE IF EXISTS test.xes_pad_audition_class_info_status;
CREATE TABLE IF NOT EXISTS test.xes_pad_audition_class_info_status AS
 SELECT city_id ,
         cla_id ,
         total_cuc_cnt ,
         venue_id ,
         venue_name ,
         subj_id ,
         subj_name ,
         class_type
  FROM dw_data.dw_class
  WHERE is_del='0'
   AND is_lvl_can='0'
   AND is_cla_clo='0' 
   --长期班
   AND term_id IN ('1',
                   '2',
                   '3',
                   '4') ;
 
 
 


 --根据之前筛选的全部学员信息xes_pad_audition_stu_info_status关联xes_pad_audition_class_info_status长期班信息，找到新学员老学员状态
 
 DROP TABLE IF EXISTS test.xes_pad_audition_new_old_info_status;
CREATE TABLE IF NOT EXISTS test.xes_pad_audition_new_old_info_status AS
SELECT 
t.city_id,
t.city_name,
t.student_id,
 t.schl_year,
case when t.new_old_status >0 then 'old'
else 'new' end as new_old_status
 FROM (
 SELECT stu_info.city_id,
       stu_info.city_name,
       stu_info.student_id,
       stu_info.schl_year,
       sum(if(class_info.cla_id IS NULL,0,1)) AS new_old_status
FROM test.xes_pad_audition_stu_info_status stu_info
LEFT JOIN test.xes_pad_audition_class_info_status class_info ON stu_info.city_id = class_info.city_id
AND stu_info.fina_class_id = class_info.cla_id
GROUP BY stu_info.city_id,
         stu_info.city_name,
         stu_info.student_id,
         stu_info.schl_year)t ;
 
 
 
 
--将基本学员信息中添加找到的新学员老学员状态信息表 
 DROP TABLE IF EXISTS test.xes_pad_audition_add_new_old_status_info;


CREATE TABLE IF NOT EXISTS test.xes_pad_audition_add_new_old_status_info AS
SELECT audition_info.city_id,
       audition_info.city_name,
       audition_info.student_id,
       audition_info.cla_id,
       audition_info.class_type,
       audition_info.class_type_name,
       audition_info.schl_year,
       audition_info.term_id,
       audition_info.term_name,
       audition_info.course_no,
       audition_info.cuc_date,
       audition_info.audition_pay_end_date,
       audition_info.stuid,
       audition_info.student_type,
       audition_info.fina_class_id,
       audition_info.fina_student_id,
       audition_info.fina_reg_class_no,
       audition_info.fina_create_date,
       new_old.new_old_status
FROM test.xes_pad_audition_info audition_info
LEFT JOIN test.xes_pad_audition_new_old_info_status new_old ON audition_info.city_id = new_old.city_id
AND audition_info.student_id = new_old.student_id
AND audition_info.schl_year = new_old.schl_year ;




--筛选出最终呈现结果


DROP TABLE IF EXISTS dm_newbi.xes_pad_audition_status;

CREATE TABLE IF NOT EXISTS dm_newbi.xes_pad_audition_status AS
SELECT audition_statistics_info.city_id,
       audition_statistics_info.city_name,
       audition_statistics_info.schl_year,
       audition_statistics_info.term_id,
       audition_statistics_info.term_name,
       audition_statistics_info.student_type,
       nvl(audition_statistics_info.new_regist_audition_nums,0) AS new_regist_audition_nums,
       nvl(audition_statistics_info.old_regist_audition_nums,0) AS old_regist_audition_nums,
       '' AS new_audition_nums,
       '' AS old_audition_nums,
       nvl(audition_statistics_info.new_finance_nums,0) AS new_finance_nums,
       nvl(audition_statistics_info.old_finance_nums,0) AS old_finance_nums,
       '' AS new_complete_audition_nums,
       '' AS old_complete_audition_nums,
       '' AS new_audition_trans_radio,
       '' AS old_audition_trans_radio,
       '' AS new_finance_trans_radio,
       '' AS old_finance_trans_radio,
       concat(cast(round( CASE WHEN nvl(audition_statistics_info.new_regist_audition_nums,0) = 0 THEN 0 ELSE audition_statistics_info.new_finance_nums/audition_statistics_info.new_regist_audition_nums*100 END ,2) AS string),'%') AS new_trans_radio,
       concat(cast(round( CASE WHEN nvl(audition_statistics_info.old_regist_audition_nums,0) = 0 THEN 0 ELSE audition_statistics_info.old_finance_nums/audition_statistics_info.old_regist_audition_nums*100 END ,2) AS string),'%') AS old_trans_radio
FROM
 (SELECT new.city_id,
         new.city_name,
         new.schl_year,
         new.term_id,
         new.term_name,
         new.student_type,
         new.new_regist_audition_nums,
         old.old_regist_audition_nums,
         new.new_finance_nums,
         old.old_finance_nums
  FROM --new

   (SELECT audition_info.city_id,
           audition_info.city_name,
           audition_info.schl_year,
           audition_info.term_id,
           audition_info.term_name,
           audition_info.student_type,
           count(*) AS new_regist_audition_nums,
           sum(if(fina_student_id IS NULL,0,1)) AS new_finance_nums
    FROM test.xes_pad_audition_add_new_old_status_info audition_info
    WHERE audition_info.new_old_status = 'new'
    GROUP BY audition_info.city_id,
             audition_info.city_name,
             audition_info.schl_year,
             audition_info.term_id,
             audition_info.term_name,
             audition_info.student_type) NEW
  LEFT JOIN --old

   (SELECT audition_info.city_id,
           audition_info.city_name,
           audition_info.schl_year,
           audition_info.term_id,
           audition_info.term_name,
           audition_info.student_type,
           count(*) AS old_regist_audition_nums,
           sum(if(fina_student_id IS NULL,0,1)) AS old_finance_nums
    FROM test.xes_pad_audition_add_new_old_status_info audition_info
    WHERE audition_info.new_old_status = 'old'
    GROUP BY audition_info.city_id,
             audition_info.city_name,
             audition_info.schl_year,
             audition_info.term_id,
             audition_info.term_name,
             audition_info.student_type) OLD ON new.city_id = old.city_id
  AND new.schl_year=old.schl_year
  AND new.term_id = old.term_id
  AND new.student_type = old.student_type) audition_statistics_info;