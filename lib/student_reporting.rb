require 'rubygems'
require 'mysql'


class StudentReporting
  
  def query sql
    my = Mysql::new("localhost", "root", "", "nova_production")
    res = my.query(sql)
    puts res.fetch_fields.collect{|f| f.name}.join("\t")
    res.each do |row|
      puts row.join("\t")
    end
    puts "#{res.num_rows}"
    
  end
  
  def active_students
    %Q{
      SELECT last_name, first_name, id, COALESCE(district_grade, '') AS district_grade, date_active,date_inactive, COALESCE(credits.total,0) AS credits FROM users
      LEFT JOIN (SELECT user_id, ROUND(SUM(credit_hours), 2) AS total FROM credit_assignments  WHERE user_id IS NOT NULL AND parent_credit_assignment_id IS NULL GROUP BY user_id) AS credits ON credits.user_id = users.id
      WHERE status = 1 AND privilege =1,       ORDER BY last_name, first_name
    }
  end
  
  
  def subject_area_enrollments(school_year, category_id, active = nil)
    conditions = nil
    if active
      conditions = "WHERE enrollments.status = 1 OR (enrollments.status >= 2 AND enrollments.completion_status = 2)"
    else
      conditions = nil
    end
    
    %Q{
      select users.last_name, users.first_name, coalesce(users.district_grade, 'unspecified') as district_grade, contracts.name, terms.name, CASE enrollments.enrollment_status WHEN 1 THEN "enrolled" WHEN 2 THEN "closed" WHEN 3 THEN "finalized" END AS status, CASE enrollments.completion_status WHEN 0 THEN "in process" WHEN 1 THEN "canceled" WHEN 2 THEN "fulfilled" END AS completion_status from users
      inner join enrollments on users.id = enrollments.participant_id and enrollments.role =0,       inner join contracts on enrollments.contract_id = contracts.id and contracts.category_id = #{category_id}
      inner join terms on contracts.term_id = terms.id and terms.school_year = #{school_year}
      #{conditions}
      order by users.last_name, users.first_name
    }
  end
  
  def math_enrollment_counts
    %Q{
      select count(enrollments.id), users.last_name, users.first_name, coalesce(users.district_grade, 'unspecified') as district_grade
      from users
      inner join enrollments on users.id = enrollments.participant_id and enrollments.role =0,       inner join contracts on enrollments.contract_id = contracts.id and contracts.category_id =6,       inner join terms on contracts.term_id = terms.id and terms.school_year =2008,       group by users.id
      order by users.last_name, users.first_name
    }
  end

  def users_still_enrolled_in_math
    %Q{
        select count(distinct users.id) from users
        inner join enrollments on users.id = enrollments.participant_id and enrollments.role =0,         inner join contracts on enrollments.contract_id = contracts.id and contracts.category_id =6,         inner join terms on contracts.term_id = terms.id and terms.school_year =2008,         where enrollments.enrollment_status =1,       }
    end

    def current_counts_by_class
      %Q{
        select users.last_name, contracts.name, count(enrollments.id) as count from enrollments
        inner join contracts on enrollments.contract_id = contracts.id and contracts.category_id =6,         inner join users on contracts.facilitator_id = users.id
        inner join terms on contracts.term_id = terms.id and terms.school_year =2008,         where enrollments.enrollment_status = 1 and enrollments.role =0,         group by contracts.id
        order by last_name, contracts.name
      }
    end
    
    def subject_area_enrollments_for_year(school_year, category_id)
      %Q{
        (
          SELECT participant_id, COUNT(enrollments.id) AS total_count FROM enrollments
          INNER JOIN contracts ON enrollments.contract_id = contracts.id AND contracts.category_id = #{category_id}
          INNER JOIN terms ON terms.id = contracts.term_id AND terms.school_year = #{school_year}
          GROUP BY participant_id
        )
      }
    end
    
    def completed_subject_area_enrollments_for_year(school_year, category_id)
      %Q{
        (
          SELECT users.id, terms.school_year, round(sum(ca.credit_hours), 3) as credits, count(enrollments.id) as enrollments from users
          INNER JOIN enrollments on enrollments.participant_id = users.id and enrollments.role = 0 AND enrollments.enrollment_status >= 2 AND enrollments.completion_status =2,           
          INNER JOIN contracts on enrollments.contract_id = contracts.id AND contracts.category_id =6,           
          INNER JOIN credit_assignments ca on enrollments.id = ca.enrollment_id AND ca.credit_hours >0,           
          INNER JOIN terms on contracts.term_id = terms.id AND terms.school_year = #{school_year}
          WHERE credit_assignments.enrollment_id IS NOT NULL
          GROUP BY users.id, terms.school_year
        )
      }
    end

    def total_participation_in_subject_area(school_year, category_id)
      
      date_start = "#{school_year}-9-1"
      date_end = "#{school_year+1}-8-30"
      
      %Q{
        SELECT '#{school_year}' AS school_year, users.last_name, users.first_name, users.date_active, users.date_inactive, COALESCE(users.district_grade,'-') AS district_grade, COALESCE(enrollments.total_count,0), COALESCE(completions.enrollments,0) AS enrollments_completed, COALESCE(completions.credits,0) AS credits_completed FROM users
        
        LEFT JOIN #{subject_area_enrollments_for_year(school_year, category_id)} AS enrollments ON users.id = enrollments.participant_id

        LEFT JOIN #{completed_subject_area_enrollments_for_year(school_year, category_id)} AS completions ON completions.id = users.id
        
        WHERE users.privilege = 1 AND (users.date_active <= '#{date_end}' AND (users.date_inactive IS NULL OR users.date_inactive > '#{date_start}'))
        
        GROUP BY users.id
        
        ORDER BY users.last_name, users.first_name
      }
    end
  
    def enrollee_participation_in_subject_area(school_year, category_id)
      
      date_start = year_start(school_year)
      date_end = year_end(school_year)
      
      %Q{
        SELECT '#{school_year}' AS school_year, users.last_name, users.first_name, users.date_active, users.date_inactive, COALESCE(users.district_grade,'-') AS district_grade, COALESCE(enrollments.total_count,0), COALESCE(completions.enrollments,0) AS enrollments_completed, COALESCE(completions.credits,0) AS credits_completed FROM users
        
        INNER JOIN #{subject_area_enrollments_for_year(school_year, category_id)} AS enrollments ON users.id = enrollments.participant_id

        LEFT JOIN #{completed_subject_area_enrollments_for_year(school_year, category_id)} AS completions ON completions.id = users.id
        
        WHERE users.privilege = 1 AND (users.date_active <= '#{date_end}' AND (users.date_inactive IS NULL OR users.date_inactive > '#{date_start}'))
        
        GROUP BY users.id
        
        ORDER BY users.last_name, users.first_name
      }
    end
    
    def year_start(school_year)
      "#{school_year}-9-1"
    end
    
    def year_end(school_year)
      "#{school_year+1}-8-30"
    end
    
    def sql_date(date)
      date.strftime("%Y-%m-%d")
    end
    
    def credits_earned_in_subject(students, subject)
      
      raise "requires creditable_type update"

      start_06 = year_start(2006)
      end_06 = year_end(2006)
      start_07 = year_start(2007)
      end_07 = year_end(2007)
      start_08 = year_start(2008)
      end_08 = year_end(2008)
      
      %Q{
        SELECT users.last_name, users.first_name, users.district_grade, users.date_active, COALESCE(users.date_inactive, '-') AS date_inactive, enrollments.total_count AS math_enrollments_08, ROUND(credits_06.total,2) AS credits_06, ROUND(credits_07.total,2) AS credits_07, ROUND(credits_08.total,2) AS credits_08
        FROM users
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN enrollments ON enrollments.id = credit_assignments.enrollment_id INNER JOIN contracts ON contracts.id = enrollments.contract_id AND contracts.category_id = #{subject} INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' WHERE credit_assignments.enrollment_finalized_on >= '#{start_06}' AND credit_assignments.enrollment_finalized_on <= '#{end_06}' GROUP BY credit_assignments.creditable_id) AS credits_06 ON users.id = credits_06.creditable_id
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN enrollments ON enrollments.id = credit_assignments.enrollment_id INNER JOIN contracts ON contracts.id = enrollments.contract_id AND contracts.category_id = #{subject} INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' WHERE credit_assignments.enrollment_finalized_on >= '#{start_07}' AND credit_assignments.enrollment_finalized_on <= '#{end_07}' GROUP BY credit_assignments.creditable_id) AS credits_07 ON users.id = credits_07.creditable_id
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN enrollments ON enrollments.id = credit_assignments.enrollment_id INNER JOIN contracts ON contracts.id = enrollments.contract_id AND contracts.category_id = #{subject} INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' WHERE credit_assignments.enrollment_finalized_on >= '#{start_08}' AND credit_assignments.enrollment_finalized_on <= '#{end_08}' GROUP BY credit_assignments.creditable_id) AS credits_08 ON users.id = credits_08.creditable_id
        LEFT JOIN #{subject_area_enrollments_for_year(2008, 6)} AS enrollments ON enrollments.participant_id = users.id
        WHERE users.id IN (#{students.join(',')})
        ORDER BY last_name, first_name
      }
    end

    def credits_earned(students)

      raise "requires creditable_type update"
      start_06 = year_start(2006)
      end_06 = year_end(2006)
      start_07 = year_start(2007)
      end_07 = year_end(2007)
      start_08 = year_start(2008)
      end_08 = year_end(2008)
      
      %Q{
        SELECT users.last_name, users.first_name, users.district_grade, users.date_active, COALESCE(users.date_inactive, '-') AS date_inactive, enrollments.total_count AS math_enrollments_08, ROUND(credits_06.total,2) AS credits_06, ROUND(credits_07.total,2) AS credits_07, ROUND(credits_08.total,2) AS credits_08
        FROM users
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' AND credit_assignments.parent_credit_assignment_id IS NULL WHERE credit_assignments.enrollment_finalized_on >= '#{start_06}' AND credit_assignments.enrollment_finalized_on <= '#{end_06}' GROUP BY credit_assignments.creditable_id) AS credits_06 ON users.id = credits_06.creditable_id
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' AND credit_assignments.parent_credit_assignment_id IS NULL WHERE credit_assignments.enrollment_finalized_on >= '#{start_07}' AND credit_assignments.enrollment_finalized_on <= '#{end_07}' GROUP BY credit_assignments.creditable_id) AS credits_07 ON users.id = credits_07.creditable_id
        LEFT JOIN (SELECT credit_assignments.creditable_id, SUM(credit_assignments.credit_hours) AS total FROM credit_assignments INNER JOIN users ON users.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'User' AND credit_assignments.parent_credit_assignment_id IS NULL WHERE credit_assignments.enrollment_finalized_on >= '#{start_08}' AND credit_assignments.enrollment_finalized_on <= '#{end_08}' GROUP BY credit_assignments.creditable_id) AS credits_08 ON users.id = credits_08.creditable_id
        LEFT JOIN #{subject_area_enrollments_for_year(2008, 6)} AS enrollments ON enrollments.participant_id = users.id
        WHERE users.id IN (#{students.join(',')})
        ORDER BY last_name, first_name
      }
    end
    
    def end_of_term_credits_report(start_date, end_date, active_term_ids)
      raise "requires creditable_type update"
      %Q{
        SELECT 
          users.last_name, users.first_name, 
          coor.last_name AS coordinator,
          COALESCE(users.district_grade, 'unknown') AS district_grade, 
          COALESCE(earned_credits.credit_hours,0) AS earned_credits, 
          COALESCE(active_credits.credit_hours,0) AS active_credits, 
          COALESCE(old_credits.credit_hours,0) AS old_credits, 
          COALESCE(unbatched_credits.count, 0) AS unbatched_count, 
          COALESCE(unbatched_credits.total, 0) AS unbatched_total, 
          COALESCE(unbatched_credits.average, 0) AS unbatched_average 
        FROM users
        LEFT JOIN 
        (
                SELECT user_id, ROUND(SUM(credit_hours),2) AS credit_hours FROM 
                (
                  (
                  	SELECT users.id  AS user_id, credit_assignments.credit_hours
                  	FROM credit_assignments
                  	INNER JOIN users ON credit_assignments.creditable_id  = users.id
                  	WHERE creditable_type = 'User' AND credit_assignments.enrollment_finalized_on >= '#{sql_date(start_date)}' AND credit_assignments.enrollment_finalized_on < '#{sql_date(end_date)}' AND credit_assignments.parent_credit_assignment_id IS NULL
                  )
                UNION
                  (
                  	SELECT users.id AS user_id, credit_assignments.credit_hours
                  	FROM credit_assignments
                  	INNER JOIN enrollments ON enrollments.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'Enrollment'
                  	INNER JOIN users ON enrollments.participant_id = users.id
                  	WHERE creditable_type = 'Enrollment' AND enrollments.finalized_on >= '#{sql_date(start_date)}' AND enrollments. finalized_on < '#{sql_date(end_date)}'
                  ) 
                ) AS credits
                GROUP BY user_id
        ) AS earned_credits ON earned_credits.user_id = users.id
        LEFT JOIN
        (
                  SELECT users.id AS user_id, ROUND(SUM(credit_hours),2) AS credit_hours FROM credit_assignments
                  INNER JOIN enrollments ON enrollments.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'Enrollment'
                  INNER JOIN users ON enrollments.participant_id = users.id
                  INNER JOIN contracts ON enrollments.contract_id = contracts.id
                  WHERE creditable_type = 'Enrollment' AND enrollments.enrollment_status = 1 AND users.status = 1 AND contracts.term_id in (#{active_term_ids.join(',')})
                  GROUP BY users.id
        ) AS active_credits ON active_credits.user_id = users.id
        LEFT JOIN
        (
                  SELECT users.id AS user_id, ROUND(SUM(credit_hours),2) AS credit_hours FROM credit_assignments
                  INNER JOIN enrollments ON enrollments.id = credit_assignments.creditable_id AND credit_assignments.creditable_type = 'Enrollment'
                  INNER JOIN users ON enrollments.participant_id = users.id
                  INNER JOIN contracts ON enrollments.contract_id = contracts.id
                  INNER JOIN terms ON contracts.term_id = terms.id
                  WHERE creditable_type = 'Enrollment' AND enrollments.enrollment_status = 1 AND users.status = 1 AND NOT (contracts.term_id in (#{active_term_ids.join(',')}))
                  GROUP BY users.id
        ) AS old_credits ON old_credits.user_id = users.id
        LEFT JOIN 
        (
              	SELECT creditable_id AS user_id, COUNT(id) AS count, ROUND(SUM(credit_hours),2) AS total, ROUND(AVG(credit_hours),2) AS average
              	FROM credit_assignments
              	WHERE creditable_type = 'User' AND credit_transmittal_batch_id IS NULL AND parent_credit_assignment_id IS NULL AND credit_hours > 0
              	GROUP BY creditable_id
        ) AS unbatched_credits ON unbatched_credits.user_id = users.id
        LEFT JOIN users coor ON users.coordinator_id = coor.id
        WHERE users.status = 1 AND users.privilege = 1
        ORDER BY last_name, first_name
      }
    end
    
end

# cohort = [ 32, 35,  64,  70,  317,  71,  77,  78,  86,  87,  88,  91,  95,  97,  101,  116,  121,  320,  125,  133,  134,  136,  257,  137,  139,  141,  144,  321,  322,  167,  169,  171,  173,  323,  189,  191,  211,  220,  235,  236,  238,  324,  241,  242,  246,  247,  248,  327,  266,  267,  271,  278,  283,  292,  298,  329,  302,  303,  312]

r = StudentReporting.new
r.query r.end_of_term_credits_report(Date.new(2008,9,1), Date.new(2009,2,10), [24,25,26])
