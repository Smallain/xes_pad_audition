--关联dw_data.dw_class class表，找出年级，服务中心，教学点。

DROP TABLE IF EXISTS test.xes_pad_audition_sub_one_info;

CREATE TABLE IF NOT EXISTS test.xes_pad_audition_sub_one_info AS
SELECT audition_info.city_id,
       audition_info.city_name,
       audition_info.student_id,
       audition_info.cla_id,
       audition_info.class_type,
       audition_info.class_type_name,
       audition_info.schl_year,
       audition_info.term_id,
       audition_info.term_name,
       class.grd_id,
       class.grd_name,
       class.subj_id,
       class.subj_name,
       class.serv_ctr_id,
       class.serv_ctr_name,
       class.venue_id,
       class.venue_name,
       audition_info.course_no,
       audition_info.cuc_date,
       audition_info.student_type
FROM (
SELECT DISTINCT city_id,
        city_name,
        student_id,
        cla_id,
        class_type,
        class_type_name,
        schl_year,
        term_id,
        term_name,
        course_no,
        cuc_date,
        student_type
FROM test.xes_pad_audition_info
) audition_info
JOIN dw_data.dw_class class ON audition_info.city_id = class.city_id
AND audition_info.cla_id = class.cla_id;



--最终处理为dm_newbi.xes_pad_audition表的下钻一层表

DROP TABLE IF EXISTS otemp.xes_pad_audition_sub_one;

CREATE TABLE IF NOT EXISTS otemp.xes_pad_audition_sub_one AS
SELECT one_info.city_id,
       one_info.city_name,
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
       count(*) as student_nums,
       audition.creator_id,
       audition.create_time
FROM test.xes_pad_audition_sub_one_info one_info
join odata.ods_bn_tb_audition audition
on one_info.city_id = audition.city_id and one_info.student_id = audition.student_id and one_info.cla_id = audition.class_id and one_info.schl_year = audition.year
and one_info.term_id = audition.term and one_info.course_no = audition.course_no
GROUP BY one_info.city_id,
         one_info.city_name,
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
          ;