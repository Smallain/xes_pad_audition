



 --xes_pad_audition_stu_info学员信息表，关联xes_pad_audition_finance_info找出在试听之前课程的财务信息和新老学员(关联所有学员的财务状况)

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
       finance.fina_class_id,
       finance.fina_student_id,
       finance.fina_reg_class_no,
       finance.fina_create_date,
       class_info.cla_id AS class_info_cla_id,
       class_info.cla_term_id AS class_info_cla_term_id,
       CASE
           WHEN (class_info.cla_id IS NOT NULL
                 AND finance.fina_create_date<=audition.create_time) THEN 'old'
           ELSE 'new'
       END AS new_old
FROM test.xes_pad_audition_stu_info stu
LEFT JOIN odata.ods_bn_tb_audition audition ON stu.city_id = audition.city_id
AND stu.student_id = audition.student_id
AND stu.cla_id = audition.class_id
LEFT JOIN test.xes_pad_audition_finance_info finance ON stu.city_id = finance.city_id
AND stu.student_id = finance.fina_student_id
LEFT JOIN odata.ods_bn_tb_class class_info ON finance.fina_class_id= class_info.cla_id
AND finance.city_id=class_info.city_id
AND class_info.cla_term_id IN ('1',
                               '2',
                               '3',
                               '4');

 --筛选出最终呈现结果

DROP TABLE IF EXISTS otemp.xes_pad_audition_status;


CREATE TABLE IF NOT EXISTS otemp.xes_pad_audition_status AS
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
       nvl(audition_statistics_info.new_finance_status_nums,0) AS new_finance_nums,
       nvl(audition_statistics_info.old_finance_status_nums,0) AS old_finance_nums,
       '' AS new_complete_audition_nums,
       '' AS old_complete_audition_nums,
       '' AS new_audition_trans_radio,
       '' AS old_audition_trans_radio,
       '' AS new_finance_trans_radio,
       '' AS old_finance_trans_radio,
       concat(nvl(cast(round(CASE WHEN nvl(audition_statistics_info.new_regist_audition_nums,0) = 0 THEN 0 ELSE audition_statistics_info.new_finance_status_nums/audition_statistics_info.new_regist_audition_nums*100 END ,2) AS string),'0'),'%') AS new_trans_radio,
       concat(nvl(cast(round(CASE WHEN nvl(audition_statistics_info.old_regist_audition_nums,0) = 0 THEN 0 ELSE audition_statistics_info.old_finance_status_nums/audition_statistics_info.old_regist_audition_nums*100 END ,2) AS string),'0'),'%') AS old_trans_radio
FROM
 (SELECT audition_info.city_id,
         audition_info.city_name,
         audition_info.schl_year,
         audition_info.term_id,
         audition_info.term_name,
         audition_info.student_type,
         audition_new.new_regist_audition_nums,
         audition_old.old_regist_audition_nums,
         finance_new.new_finance_status_nums,
         finance_old.old_finance_status_nums
  FROM
   (SELECT city_id,
           city_name,
           schl_year,
           term_id,
           term_name,
           student_type
    FROM test.xes_pad_audition_stu_info
    GROUP BY city_id,
             city_name,
             schl_year,
             term_id,
             term_name,
             student_type) audition_info
  LEFT JOIN --试听人员（新用户） 如何判断新用户：新用户试听课的创建时间必须在在成为老用户的最早的“缴费时间”之前

   (SELECT temp.city_id,
           temp.city_name,
           temp.schl_year,
           temp.term_id,
           temp.term_name,
           temp.student_type,
           count(DISTINCT temp.student_id) AS new_regist_audition_nums
    FROM
     (SELECT new_stu.city_id,
             new_stu.city_name,
             new_stu.schl_year,
             new_stu.term_id,
             new_stu.term_name,
             new_stu.student_type,
             new_stu.student_id,
             new_stu.create_time,
             limit_new.min_old_time
      FROM
       (SELECT audition_info.city_id,
               audition_info.city_name,
               audition_info.schl_year,
               audition_info.term_id,
               audition_info.term_name,
               audition_info.student_type,
               audition_info.student_id,
               audition_info.create_time
        FROM test.xes_pad_audition_stu_info_status audition_info
        WHERE audition_info.new_old = 'new') new_stu
      LEFT JOIN
       (SELECT city_id,
               student_id,
               schl_year,
               min(fina_create_date) min_old_time
        FROM test.xes_pad_audition_stu_info_status
        WHERE new_old = 'old'
        GROUP BY city_id,
                 student_id,
                 schl_year) limit_new ON new_stu.city_id = limit_new.city_id
      AND new_stu.schl_year = limit_new.schl_year
      AND new_stu.student_id = limit_new.student_id
      WHERE new_stu.create_time < limit_new.min_old_time
       OR limit_new.min_old_time IS NULL) TEMP
    GROUP BY TEMP.city_id,
                  TEMP.city_name,
                       TEMP.schl_year,
                            TEMP.term_id,
                                 TEMP.term_name,
                                      TEMP.student_type) audition_new ON audition_info.city_id=audition_new.city_id
  AND audition_info.city_name=audition_new.city_name
  AND audition_info.schl_year=audition_new.schl_year
  AND audition_info.term_id=audition_new.term_id
  AND audition_info.term_name=audition_new.term_name
  AND audition_info.student_type=audition_new.student_type
  LEFT JOIN --试听人员（老用户） 如何判断老用户：直接筛选老用户并且去重即可

   (SELECT temp.city_id,
           temp.city_name,
           temp.schl_year,
           temp.term_id,
           temp.term_name,
           temp.student_type,
           count(DISTINCT temp.student_id) AS old_regist_audition_nums
    FROM
     (SELECT audition_info.city_id,
             audition_info.city_name,
             audition_info.schl_year,
             audition_info.term_id,
             audition_info.term_name,
             audition_info.student_type,
             audition_info.student_id
      FROM test.xes_pad_audition_stu_info_status audition_info
      WHERE audition_info.new_old = 'old') TEMP
    GROUP BY TEMP.city_id,
                  TEMP.city_name,
                       TEMP.schl_year,
                            TEMP.term_id,
                                 TEMP.term_name,
                                      TEMP.student_type) audition_old ON audition_info.city_id=audition_old.city_id
  AND audition_info.city_name=audition_old.city_name
  AND audition_info.schl_year=audition_old.schl_year
  AND audition_info.term_id=audition_old.term_id
  AND audition_info.term_name=audition_old.term_name
  AND audition_info.student_type=audition_old.student_type
  LEFT JOIN --缴费人员（新用户） 如何判断缴费人员新用户：缴费新用户必须是试听新学员(缴费时间在最早成为老学员的缴费时间之前)，并且缴费状态为已缴费

   (SELECT temp.city_id,
           temp.city_name,
           temp.schl_year,
           temp.term_id,
           temp.term_name,
           temp.student_type,
           count(DISTINCT temp.student_id) AS new_finance_status_nums
    FROM
     (SELECT *
      FROM
       (SELECT new_stu.city_id,
               new_stu.city_name,
               new_stu.schl_year,
               new_stu.term_id,
               new_stu.term_name,
               new_stu.student_type,
               new_stu.student_id,
               new_stu.create_time,
               new_stu.pay_flag,
               limit_new.min_old_time
        FROM
         (SELECT audition_info.city_id,
                 audition_info.city_name,
                 audition_info.schl_year,
                 audition_info.term_id,
                 audition_info.term_name,
                 audition_info.student_type,
                 audition_info.student_id,
                 audition_info.create_time,
                 fina_create_date,
                 CASE WHEN ((fina_create_date >= cuc_date
                             AND fina_create_date <= audition_pay_end_date)
                            AND (fina_reg_class_no>=course_no)) THEN 'pay' ELSE 'unpay' END AS pay_flag
          FROM test.xes_pad_audition_stu_info_status audition_info
          WHERE audition_info.new_old = 'new') new_stu
        LEFT JOIN
         (SELECT city_id,
                 student_id,
                 schl_year,
                 min(fina_create_date) min_old_time
          FROM test.xes_pad_audition_stu_info_status
          WHERE new_old = 'old'
          GROUP BY city_id,
                   student_id,
                   schl_year) limit_new ON new_stu.city_id = limit_new.city_id
        AND new_stu.schl_year = limit_new.schl_year
        AND new_stu.student_id = limit_new.student_id
        WHERE new_stu.fina_create_date < limit_new.min_old_time
         OR limit_new.min_old_time IS NULL) tt
      WHERE pay_flag = 'pay') TEMP
    GROUP BY TEMP.city_id,
                  TEMP.city_name,
                       TEMP.schl_year,
                            TEMP.term_id,
                                 TEMP.term_name,
                                      TEMP.student_type) finance_new ON audition_info.city_id=finance_new.city_id
  AND audition_info.city_name=finance_new.city_name
  AND audition_info.schl_year=finance_new.schl_year
  AND audition_info.term_id=finance_new.term_id
  AND audition_info.term_name=finance_new.term_name
  AND audition_info.student_type=finance_new.student_type
  LEFT JOIN --缴费人员（老用户） 如何判断缴费人员老用户：缴费老用户的缴费时间必须在最早“报班付费时间之后(任何班级班级)”

   (SELECT temp.city_id,
           temp.city_name,
           temp.schl_year,
           temp.term_id,
           temp.term_name,
           temp.student_type,
           count(DISTINCT temp.student_id) AS old_finance_status_nums
    FROM
     (SELECT pay.city_id,
             pay.city_name,
             pay.schl_year,
             pay.term_id,
             pay.term_name,
             pay.student_type,
             pay.student_id,
             pay.fina_create_date,
             pay.create_time,
             pay.pay_flag,
             pay.new_old
      FROM
       (SELECT pay_status.city_id,
               pay_status.city_name,
               pay_status.schl_year,
               pay_status.term_id,
               pay_status.term_name,
               pay_status.student_type,
               pay_status.student_id,
               pay_status.fina_create_date,
               pay_status.create_time,
               pay_status.pay_flag,
               pay_status.new_old
        FROM
         (SELECT audition_info.city_id,
                 audition_info.city_name,
                 audition_info.schl_year,
                 audition_info.term_id,
                 audition_info.term_name,
                 audition_info.student_type,
                 audition_info.student_id,
                 audition_info.fina_create_date,
                 audition_info.create_time,
                 CASE WHEN ((fina_create_date >= cuc_date
                             AND fina_create_date <= audition_pay_end_date)
                            AND (fina_reg_class_no>=course_no)) THEN 'pay' ELSE 'unpay' END AS pay_flag,
                                                                                               audition_info.new_old
          FROM test.xes_pad_audition_stu_info_status audition_info) pay_status
        WHERE pay_status.pay_flag = 'pay') pay
      LEFT JOIN
       (SELECT new_min.city_id,
               new_min.schl_year,
               new_min.student_id,
               min(new_min.fina_create_date) AS pay_min_time
        FROM
         (SELECT audition_info.city_id,
                 audition_info.city_name,
                 audition_info.schl_year,
                 audition_info.term_id,
                 audition_info.term_name,
                 audition_info.student_type,
                 audition_info.student_id,
                 audition_info.fina_create_date,
                 audition_info.create_time,
                 audition_info.new_old
          FROM test.xes_pad_audition_stu_info_status audition_info
          WHERE audition_info.fina_create_date IS NOT NULL) new_min
        GROUP BY new_min.city_id,
                 new_min.schl_year,
                 new_min.student_id) pay_min ON pay.city_id = pay_min.city_id
      AND pay.schl_year = pay_min.schl_year
      AND pay.student_id = pay_min.student_id
      WHERE pay.fina_create_date > pay_min.pay_min_time) TEMP
    GROUP BY TEMP.city_id,
                  TEMP.city_name,
                       TEMP.schl_year,
                            TEMP.term_id,
                                 TEMP.term_name,
                                      TEMP.student_type) finance_old ON audition_info.city_id=finance_old.city_id
  AND audition_info.city_name=finance_old.city_name
  AND audition_info.schl_year=finance_old.schl_year
  AND audition_info.term_id=finance_old.term_id
  AND audition_info.term_name=finance_old.term_name
  AND audition_info.student_type=finance_old.student_type) audition_statistics_info;