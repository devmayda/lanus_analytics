WITH source AS (
    SELECT *
    FROM {{ source('lanus_operations', 'registro_micros')}}
),

renamed_columns AS (
    
    SELECT
    
    CAST(src.id AS STRING) AS trip_id,
    INITCAP(TRIM(CAST(src.escuela AS STRING))) AS school_name,
    CAST(src.cue AS STRING) AS school_id,
    SAFE_CAST(src.fecha_salida AS DATE) AS trip_date,
    TRIM(CAST(src.destino AS STRING)) AS destination,
    SAFE_CAST(src.alumnos AS INTEGER) AS number_students,
    SAFE_CAST(src.acompaniantes AS INTEGER) AS number_adult_companions,
    SAFE_CAST(src.micros AS INTEGER) AS number_buses,
    CAST(src.estado AS STRING) AS trip_status,
    TRIM(CAST(src.horario AS STRING)) AS trip_schedule,
    CAST(src.completo_planilla AS STRING) AS form_submitted,
    CAST(src.distancia AS STRING) AS trip_type,
    TRIM(CAST(src.contacto_directivo AS STRING)) AS school_contact_info,
    TRIM(CAST(src.observaciones AS STRING)) AS trip_remarks,
    TRIM(CAST(src.empresa AS STRING)) AS transport_provider,
    CAST(src.destino_corregido AS STRING) AS grouped_destination

    /* Column grouped_destination relabels destination as to create groups for final analyis.
        It is not the most efficient way of doing it and should be deprecated.                */

    FROM source AS src
    WHERE src.id IS NOT NULL
)

SELECT * FROM renamed_columns


