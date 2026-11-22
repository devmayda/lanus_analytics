

SELECT
            CONCAT( 'INT-',
                    event.event_id,
                    '-',
                    COALESCE(event.array_order + 1, 1)
                    ) AS intervention_id,
            event.event_id AS origin_database_id,
            event.school_id AS school_id,
            COALESCE(schools.school_name, event.school_name) AS school_name,
            schools.school_shorthand_name AS school_shorthand_name,
            schools.school_level AS school_level,
            COALESCE(schools.school_sector, event.school_sector) AS school_sector,
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
        FROM {{ ref('int_events_unnested') }} AS event
        LEFT JOIN {{ ref('stg_schools') }} AS schools ON event.school_id = schools.school_id

        UNION ALL
        SELECT
            
            CONCAT('INT-MIC-', buses.trip_id, '-', buses.trip_school_tally) AS intervention_id,
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