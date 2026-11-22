
SELECT
            schools.school_id,
            schools.school_name,
            schools.school_shorthand_name,
            schools.school_level,
            schools.school_sector,
            schools.school_coordinates,
            DATE(interventions.years, 1, 1) AS intervention_date

      FROM {{ ref('stg_schools') }} AS schools
      CROSS JOIN (SELECT DISTINCT       
            EXTRACT(YEAR FROM DATE (intervention_date)) as years
            FROM {{ ref("int_union_all_interventions") }}) AS interventions