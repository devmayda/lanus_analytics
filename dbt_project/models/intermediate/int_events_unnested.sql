
SELECT
        event_id,
        array_order,
        event_name,
        event_date,
        event_schedule,
        event_location,
        event_line_of_action,
        event_status,
        NULLIF(TRIM(JSON_VALUE(school_event_metadata.nombre)), '') AS school_name,
        NULLIF(TRIM(JSON_VALUE(school_event_metadata.cue)), '') AS school_id,
        NULLIF(TRIM(JSON_VALUE(school_event_metadata.gestion)), '') AS school_sector,
        SAFE_CAST(JSON_VALUE(school_event_metadata.matricula) AS INTEGER) AS number_students,
        SAFE_CAST(JSON_VALUE(school_event_metadata.acompanantes) AS INTEGER) AS number_adult_companions
        



  FROM  {{ ref( 'stg_events' )}}
  LEFT JOIN UNNEST (JSON_EXTRACT_ARRAY(event_schools_json)) AS school_event_metadata
                  WITH OFFSET AS array_order
      ON TRUE