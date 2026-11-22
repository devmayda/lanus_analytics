                        /* This query wasn't refactored to dbt standards.
                        Database structure changes are being planned and 
                        it was deemed a waste of time and energy to refactor
                        the query using the old, deprecated structure just
                        as we are developing the new structure, with enhanced
                        granularity */

WITH 

                        /* THIS BRINGS THE DATE OF THE LATEST RECORD FOR
                        ALL PROCUREMENT PROJECTS*/

      procurement_records AS (
            SELECT
                  
                  procurement_id,
                  GREATEST(
                        sp_date,
                        oc_date,
                        rc_date,
                        rs_date
                        ) AS procurement_latest_date

            FROM {{ ref("int_procurement_timetable") }}
      ),

                        /* THIS CTE SUMS UP FINANCIAL DATA FROM PURCHASE ORDERS.
                        THEY MUST BE STRING AGGREGATED TO AVOID FAN-OUT
                        (EVERY ROW IS ONE PURCHASE ORDER ) */

    resumen_financiero AS(
      
      SELECT DISTINCT
      adj.pid,
      STRING_AGG(SAFE_CAST(CONCAT(adj.n_oc,"/", EXTRACT(year FROM DATE (adj.fecha_oc))) AS STRING), ", ") OVER (PARTITION BY adj.pid) as numeros_oc,
      SUM(CAST(adj.monto_adjudicado AS NUMERIC)) OVER (PARTITION BY adj.pid) as monto_adjudicado,
      

      FROM {{ source('lanus_operations', 'adjudicacion')}} AS adj
      
      WHERE adj.pid IS NOT NULL

),

/* THIS KEEPS DUPLICATE RECORDS IN THIS TABLE FROM AFFECTING THE QUERY CTE */

      deduplicated_desafectaciones AS(

            SELECT

                  *                  
            
            FROM {{ source('lanus_operations', 'desafectaciones')}}
            WHERE PID IS NOT NULL
            QUALIFY ROW_NUMBER() OVER (PARTITION BY PID) = 1

      )
                        /* FINAL JOIN */

SELECT
      
      CONCAT('GEO-', geo.pid, '-',
            ROW_NUMBER() OVER(PARTITION BY geo.pid ORDER BY geo.cueanexo)
            ) AS procurement_id,
      SAFE_CAST(geo.PID AS STRING) AS origin_database_id,
      SAFE_CAST(geo.cueanexo AS STRING) AS school_id,
      geo.nombre AS school_name,
      pad.nombre_corto AS school_shorthand_name,
      pad.nivel AS school_level,
      pad.sector AS school_sector,
      pad.coordenadas_corregidas AS school_coordinates,
      P.tipo_pedido AS procurement_type,
      P.descripcion_pedido AS procurement_description,
      procurement_records.procurement_latest_date AS procurement_latest_date,
      P.linea_de_accion AS procurement_line_of_action,
      P.proyecto AS procurement_program,
      CASE
            WHEN D.estado_desafectacion IS NULL
            AND D.fecha_solicitud_desafectacion IS NULL
            AND D.nota_desafectacion IS NULL THEN 'afectado'
            ELSE 'desafectado'
            END AS procurement_status,
      SAFE_CAST(enrolment.enrolment_latest_record AS NUMERIC) AS affected_enrolment,
      SAFE_CAST((enrolment.teachers_latest_record + enrolment.non_teachers_latest_record)AS NUMERIC) AS affected_non_students,
      P.area_pedido AS procurement_area,
      SAFE_CAST((fin.monto_adjudicado/COUNT(geo.cueanexo) OVER(PARTITION BY geo.PID)) AS NUMERIC) AS procurement_investment

FROM {{ source('lanus_operations', 'georref')}} AS geo
LEFT JOIN {{ source('lanus_operations', 'pedido')}} AS P
      ON geo.PID = P.PID
LEFT JOIN procurement_records
      ON SAFE_CAST(geo.PID AS STRING) = procurement_records.procurement_id      
LEFT JOIN {{ source('lanus_bases', 'padron_cue')}} AS pad
      ON geo.cueanexo = pad.cueanexo
LEFT JOIN resumen_financiero AS fin
      ON SAFE_CAST(geo.pid AS STRING) = SAFE_CAST(fin.pid AS STRING)
LEFT JOIN {{ ref("int_procurement_timetable") }} AS fechas
      ON SAFE_CAST(geo.pid AS STRING) = fechas.procurement_id
LEFT JOIN {{ ref("int_enrolment_by_year") }} AS enrolment
      ON SAFE_CAST(geo.cueanexo AS STRING) = enrolment.school_id
      AND EXTRACT(YEAR FROM DATE (procurement_records.procurement_latest_date)) >= enrolment.record_year
      AND EXTRACT(YEAR FROM DATE (procurement_records.procurement_latest_date)) < enrolment.valid_to_year
LEFT JOIN deduplicated_desafectaciones AS D
      ON SAFE_CAST(geo.pid AS STRING) = SAFE_CAST(D.PID AS STRING)

WHERE geo.pid IS NOT NULL
ORDER BY procurement_id

