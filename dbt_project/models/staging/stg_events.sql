WITH source AS (
    SELECT *
    FROM {{ source('lanus_planning', 'eventos_agenda')}}
),

renamed_columns AS (
    SELECT

        CAST(src.ID_Evento AS STRING) AS event_id,
        SAFE_CAST(src.Timestamp AS TIMESTAMP) AS event_creation_timestamp,
        CAST(src.Linea_Accion AS STRING) AS event_line_of_action,
        TRIM(CAST(src.Nombre_Evento AS STRING)) AS event_name,
        SAFE_CAST(src.Fecha AS DATE) AS event_date,
        TRIM(CAST(src.Horario AS STRING)) AS event_schedule,
        TRIM(CAST(src.Lugar AS STRING)) AS event_location,
        CAST(src.Estado AS STRING) AS event_status,
        CAST(src.Creador AS STRING) AS event_creator,
        SAFE.PARSE_JSON(src.Escuelas_JSON) AS event_schools_json,
        SAFE.PARSE_JSON(src.Checklist_JSON) AS event_checklist_json,
        SAFE.PARSE_JSON(src.Bitacora_JSON) AS event_log_json,
        SAFE.PARSE_JSON(src.Alertas_JSON) AS event_alerts_json


    FROM source AS src
    WHERE src.ID_Evento IS NOT NULL
)

SELECT * FROM renamed_columns
