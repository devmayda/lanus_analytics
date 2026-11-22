
SELECT

      COALESCE(interventions.intervention_id,
        CONCAT('NO-INT-',
                COALESCE(schools_over_years.school_id,''),
                '-',
                EXTRACT(YEAR FROM DATE(schools_over_years.intervention_date))
                )
            ) AS intervention_id,
      interventions.origin_database_id,
      COALESCE( interventions.school_id,
                schools_over_years.school_id
                ) AS school_id,
      COALESCE( interventions.school_name,
                schools_over_years.school_name
                ) AS school_name,
      COALESCE( interventions.school_shorthand_name,
                schools_over_years.school_shorthand_name
                ) AS school_shorthand_name,
      COALESCE( interventions.school_level,
                schools_over_years.school_level
                ) AS school_level,
      COALESCE( interventions.school_sector,
                schools_over_years.school_sector
                ) AS school_sector,
      COALESCE( interventions.school_coordinates,
                schools_over_years.school_coordinates
                ) AS school_coordinates,
      COALESCE( interventions.intervention_type,
                'no intervention'
                ) AS intervention_type,
      COALESCE( interventions.intervention_description,
                'No intervention'
                ) AS intervention_description,
      COALESCE( interventions.intervention_date,
                schools_over_years.intervention_date
                ) AS intervention_date,
      interventions.line_of_action,
      interventions.program,
      COALESCE(interventions.affected_students,0) AS affected_students,
      COALESCE(interventions.affected_adults,0) AS affected_adults,
      interventions.intervention_area_in_charge,
      COALESCE(interventions.investment,0) AS investment,
      COALESCE(interventions.intervention_status,'unreached') AS intervention_status


FROM {{ ref("int_school_by_year_reporting_spine") }} AS schools_over_years
                        /* Originally meant to be a LEFT JOIN coming clean
                        from the school database. But that left out schools
                        that weren't in the database. There are few cases, 
                        mostly private schools*/
FULL OUTER JOIN {{ ref('int_union_all_interventions') }} AS interventions
    ON schools_over_years.school_id = interventions.school_id
    AND EXTRACT(YEAR FROM DATE(schools_over_years.intervention_date)) = EXTRACT(YEAR FROM DATE(interventions.intervention_date))

