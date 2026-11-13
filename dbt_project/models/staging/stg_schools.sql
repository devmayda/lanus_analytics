WITH source AS (
    SELECT *
    FROM {{ source('lanus_bases', 'padron_cue')}}
),

    /*  Source data comes from National School Census, so it contains 97 columns. 
        Most of them are deprecated or unnecesary.
        Only the relevant ones are selected for the time being.                 */


renamed_columns AS (
    
    SELECT

    INITCAP(TRIM(CAST(src.nombre AS STRING))) AS school_name,
    CAST(src.cueanexo AS STRING) AS school_id,
    INITCAP(CAST(src.modalidad AS STRING)) AS school_modality,
    INITCAP(CAST(src.nivel AS STRING)) AS school_level,
    INITCAP(TRIM(CAST(src.calle AS STRING))) AS school_address_street,
    SAFE_CAST(src.nro AS STRING) AS school_address_number,
    INITCAP(CAST(src.localidad AS STRING)) AS school_address_city,
    INITCAP(CAST(src.distrito AS STRING)) AS school_address_district,
    INITCAP(CAST(src.dependencia AS STRING)) AS school_dependency,
    SAFE_CAST(src.nro_telefono AS STRING) AS school_phone_number,
    CAST(src.email AS STRING) AS school_email,
    INITCAP(CAST(src.sector AS STRING)) AS school_sector,
    INITCAP(CAST(src.tipo_organizacion AS STRING)) AS school_organization_type,
    CAST(src.cui AS STRING) AS school_infrastructure_id,
    CAST(src.the_geom AS STRING) AS school_geom,
    TRIM(CAST(src.nombre_corto AS STRING)) AS school_shorthand_name,
    CAST(src.zona_mantenimiento AS STRING) AS school_maintenance_zone,
    TRIM(CAST(src.coordenadas_corregidas AS STRING)) AS school_coordinates,
    INITCAP(TRIM(CAST(src.barrio AS STRING))) AS school_borough
    
    FROM source AS src
    WHERE src.cueanexo IS NOT NULL
)

SELECT * FROM renamed_columns