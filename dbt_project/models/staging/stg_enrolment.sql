WITH source AS (
    SELECT *
    FROM {{ source('lanus_operations', 'matricula')}}
),

renamed_columns AS (
    
    SELECT
    
    CAST(src.cueanexo AS STRING) AS school_id,
    CAST(src.cui AS STRING) AS school_infrastructure_id,
    SAFE_CAST(src.fecha_dato AS DATE) AS record_date,
    SAFE_CAST(src.TOTAL_Matricula AS INTEGER) AS enrolment,
    SAFE_CAST(src.TOTAL_docentes AS INTEGER) AS teachers,
    SAFE_CAST(src.TOTAL_auxiliares AS INTEGER) AS non_teachers,
    

    /* Column grouped_destination relabels destination as to create groups for final analyis.
        It is not the most efficient way of doing it and should be deprecated.                */

    FROM source AS src
    WHERE src.cueanexo IS NOT NULL
)

SELECT * FROM renamed_columns

