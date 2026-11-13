{{ config(materialized='table') }}

WITH events_unnested AS(
    SELECT
        event_id,
        event_name,
        event_date,
        event_schedule,
        event_location,
        event_line_of_action,
        event_status,
        JSON_VALUE(school_event_metadata.nombre) AS school_name,
        JSON_VALUE(school_event_metadata.cue) AS school_id,
        JSON_VALUE(school_event_metadata.gestion) AS school_sector,
        SAFE_CAST(JSON_VALUE(school_event_metadata.matricula) AS INTEGER) AS number_students,
        SAFE_CAST(JSON_VALUE(school_event_metadata.acompanantes) AS INTEGER) AS number_adult_companions



  FROM  {{ ref( 'stg_events' )}}
  LEFT JOIN UNNEST (JSON_EXTRACT_ARRAY(event_schools_json)) AS school_event_metadata ON TRUE 
),

    unified_interventions AS (

        SELECT
            CONCAT('interventions-EVT-', ROW_NUMBER() OVER()) AS intervention_id,
            event.event_id AS origin_database_id,
            event.school_id AS school_id,
            schools.school_name AS school_name,
            schools.school_shorthand_name AS school_shorthand_name,
            schools.school_level AS school_level,
            schools.school_sector AS school_sector,
            schools.school_coordinates AS school_coordinates,
            'Evento' AS intervention_type,
            event.event_name AS intervention_description,
            event.event_date AS intervention_date,
            event.event_line_of_action AS line_of_action,
            CAST(null AS STRING) AS program,
            CASE WHEN event.event_status = 'Realizado' THEN 'executed' ELSE 'not executed' END AS intervention_status,
            event.number_students AS affected_students,
            event.number_adult_companions AS affected_adults,
            'DG-Planificación' AS intervention_area_in_charge,
            CAST(0 AS NUMERIC) AS investment
        FROM events_unnested AS event
        LEFT JOIN {{ ref('stg_schools') }} AS schools ON event.school_id = schools.school_id

        UNION ALL
        SELECT
            
            CONCAT('interventions-MIC-', ROW_NUMBER() OVER()) AS intervention_id,
            buses.trip_id AS origin_database_id,
            buses.school_id AS school_id,
            COALESCE(schools.school_name, buses.school_name) AS school_name,
            schools.school_shorthand_name AS school_shorthand_name,
            schools.school_level AS school_level,
            schools.school_sector AS school_sector,
            schools.school_coordinates AS school_coordinates,
            'Bus trip' AS intervention_type,
            buses.destination AS intervention_description,
            buses.trip_date AS intervention_date,
            buses.grouped_destination AS line_of_action,
            '' AS program,
            CASE WHEN buses.trip_status = 'Realizado' THEN 'executed' ELSE 'not executed' END AS intervention_status,
            ROUND(SAFE_CAST(buses.number_students AS NUMERIC)/COUNT(buses.trip_id) OVER (PARTITION BY buses.trip_id), 0) as affected_students,
            ROUND(SAFE_CAST(buses.number_adult_companions AS NUMERIC)/COUNT(buses.trip_id) OVER (PARTITION BY buses.trip_id), 0) as affected_adults,
            '' AS intervention_area_in_charge,
                        /* Trip cost is has been hard-coded because
                        we have note yet been able to match indvidiual
                        trips to specific procurement orders */
            COALESCE(ROUND(SAFE_CAST((229239.63 * buses.number_buses)/COUNT(buses.trip_id) OVER (PARTITION BY buses.trip_id) AS NUMERIC), 2), 0) AS investment

        FROM {{ ref('stg_buses') }} AS buses
        LEFT JOIN {{ ref('stg_schools') }} AS schools ON buses.school_id = schools.school_id

        UNION ALL
        SELECT

            procurement_id AS intervention_id,
            origin_database_id,
            school_id,
            school_name,
            school_shorthand_name,
            school_level,
            school_sector,
            school_coordinates,
            procurement_type AS intervention_type,
            procurement_description AS intervention_description,
            procurement_latest_date AS intervention_date,
            procurement_line_of_action AS line_of_action,
            procurement_program AS program,
            CASE WHEN procurement_status = 'afectado' THEN 'executed' ELSE 'not executed' END AS intervention_status,
            affected_enrolment AS affected_students,
            affected_non_students AS affected_adults,
            procurement_area AS intervention_area_in_charge,
            COALESCE(procurement_investment, 0) AS investment

        FROM {{ ref('int_procurement_interventions') }}
),

    schools_over_years AS (
      
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
            FROM unified_interventions) AS interventions
)

SELECT

      COALESCE(interventions.intervention_id, CONCAT('No-Intervention-', ROW_NUMBER() OVER())) AS intervention_id,
      interventions.origin_database_id,
      COALESCE(interventions.school_id,schools_over_years.school_id) AS school_id,
      COALESCE(interventions.school_name,schools_over_years.school_name) AS school_name,
      COALESCE(interventions.school_shorthand_name,schools_over_years.school_shorthand_name) AS school_shorthand_name,
      COALESCE(interventions.school_level,schools_over_years.school_level) AS school_level,
      COALESCE(interventions.school_sector,schools_over_years.school_sector) AS school_sector,
      COALESCE(interventions.school_coordinates,schools_over_years.school_coordinates) AS school_coordinates,
      COALESCE(interventions.intervention_type,'no intervention') AS intervention_type,
      COALESCE(interventions.intervention_description,'No intervention') AS intervention_description,
      COALESCE(interventions.intervention_date,schools_over_years.intervention_date) AS intervention_date,
      interventions.line_of_action,
      interventions.program,
      COALESCE(interventions.affected_students,0) AS affected_students,
      COALESCE(interventions.affected_adults,0) AS affected_adults,
      interventions.intervention_area_in_charge,
      COALESCE(interventions.investment,0) AS investment,
      COALESCE(interventions.intervention_status,'unreached') AS intervention_status


FROM schools_over_years
                        /* Originally meant to be a LEFT JOIN coming clean
                        from the school database. But that left out schools
                        that weren't in the database. There are few cases, 
                        mostly private schools*/
FULL OUTER JOIN unified_interventions AS interventions
ON schools_over_years.school_id = interventions.school_id AND EXTRACT(YEAR FROM DATE(schools_over_years.intervention_date)) = EXTRACT(YEAR FROM DATE(interventions.intervention_date))

