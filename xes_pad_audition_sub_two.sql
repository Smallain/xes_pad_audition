--在下钻一层表的基础上调整数据

DROP TABLE IF EXISTS test.xes_pad_audition_sub_two_info;

CREATE TABLE IF NOT EXISTS test.xes_pad_audition_sub_two_info AS
SELECT one_info.city_id,
       one_info.city_name,
       audition.student_id,
       audition.class_id,
       audition.course_no,
       one_info.schl_year,
       one_info.class_type,
       one_info.class_type_name,
       one_info.term_id,
       one_info.term_name,
       one_info.grd_id,
       one_info.grd_name,
       one_info.subj_id,
       one_info.subj_name,
       one_info.serv_ctr_id,
       one_info.serv_ctr_name,
       one_info.venue_id,
       one_info.venue_name,
       one_info.student_type,
       audition.creator_id,
       audition.create_time
FROM test.xes_pad_audition_sub_one_info one_info
join odata.ods_bn_tb_audition audition
on one_info.city_id = audition.city_id and one_info.student_id = audition.student_id and one_info.cla_id = audition.class_id and one_info.schl_year = audition.year
and one_info.term_id = audition.term and one_info.course_no = audition.course_no;





--最终处理为dm_newbi.xes_pad_audition表的下钻二层表
DROP TABLE IF EXISTS otemp.xes_pad_audition_sub_two;

CREATE TABLE IF NOT EXISTS otemp.xes_pad_audition_sub_two AS
SELECT sub_two.city_id,
       sub_two.city_name,
       sub_two.student_id,
       regexp_replace(stu.stu_name,'[0-9,a-z,A-Z,（,）,(,)]','') AS stu_name,
       sub_two.class_id,
       sub_two.course_no,
       sub_two.schl_year,
       sub_two.class_type,
       sub_two.class_type_name,
       sub_two.term_id,
       sub_two.term_name,
       sub_two.grd_id,
       sub_two.grd_name,
       sub_two.subj_id,
       sub_two.subj_name,
       sub_two.serv_ctr_id,
       sub_two.serv_ctr_name,
       sub_two.venue_id,
       sub_two.venue_name,
       sub_two.student_type,
       sub_two.creator_id,
       regexp_replace(emp.emp_name,'[0-9,a-z,A-Z,（,）,(,)]','') AS emp_name,
       sub_two.create_time,
       curr.cuc_date
FROM test.xes_pad_audition_sub_two_info sub_two
JOIN odata.ods_bn_tb_employee emp ON sub_two.city_id = emp.city_id
AND sub_two.creator_id = emp.emp_id
JOIN odata.ods_bn_tb_student stu ON sub_two.city_id = stu.city_id
AND sub_two.student_id = stu.stu_id
JOIN dw_data.dw_curriculum curr ON sub_two.city_id = curr.city_id
AND sub_two.class_id = curr.cla_id
AND sub_two.course_no = curr.cuc_no;