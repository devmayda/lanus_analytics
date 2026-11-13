                        /* This query wasn't refactored to dbt standards.
                        Database structure changes are being planned and 
                        it was deemed a waste of time and energy to refactor
                        the query using the old, deprecated structure just
                        as we are developing the new structure, with enhanced
                        granularity */

/* TABLA DE FECHAS PARA CALCULAR ÚLTIMO MOVIMIENTO */

WITH fechas AS (

      SELECT
            p.pid,
            COALESCE(MAX(p.sp_Fecha), SAFE_CAST("2000-01-01" AS DATE)) AS sp_fecha,       --> Hay que poner una fecha alternativa porque la función de comparación no puede comparar una fecha con un número
            COALESCE(MAX(a.fecha_oc), SAFE_CAST("2000-01-01" AS DATE)) AS fecha_oc,
            COALESCE(MAX(a.fecha_rc), SAFE_CAST("2000-01-01" AS DATE)) AS fecha_rc,
            COALESCE(MAX(f.rs_fecha), SAFE_CAST("2000-01-01" AS DATE)) AS fecha_rs

            
      FROM {{ source('lanus_operations', 'pedido')}} AS p
      LEFT JOIN {{ source('lanus_operations', 'adjudicacion')}} AS a ON p.pid = a.pid
      LEFT JOIN {{ source('lanus_operations', 'facturacion')}} AS f ON p.pid = f.pid
      LEFT JOIN {{ source('lanus_operations', 'desafectaciones')}} AS d ON p.pid = d.pid
            
      WHERE p.pid IS NOT NULL
      GROUP BY p.pid  
),

/* TABLA DE FECHAS PARA CALCULAR DATO DE MATRÍCULA */
    matricula AS(
  SELECT DISTINCT
          cueanexo,
          cui,EXTRACT(YEAR FROM DATE(Fecha_dato)) AS anio_dato,
          COALESCE(FIRST_VALUE(TOTAL_Matricula IGNORE NULLS) OVER(cue_anio ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),FIRST_VALUE(TOTAL_Matricula IGNORE NULLS) OVER(solo_cue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS matricula_ultimo_dato,
          COALESCE(FIRST_VALUE(TOTAL_docentes IGNORE NULLS) OVER(cue_anio ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),FIRST_VALUE(TOTAL_docentes IGNORE NULLS) OVER(solo_cue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS docentes_ultimo_dato,
          COALESCE(FIRST_VALUE(TOTAL_auxiliares IGNORE NULLS) OVER(cue_anio ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),FIRST_VALUE(TOTAL_auxiliares IGNORE NULLS) OVER(solo_cue ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS auxiliares_ultimo_dato

  FROM {{ source('lanus_operations', 'matricula')}}
  
  WINDOW  cue_anio AS (PARTITION BY cueanexo,EXTRACT(YEAR FROM DATE(Fecha_dato)) ORDER BY fecha_dato DESC),
          solo_cue AS (PARTITION BY cueanexo ORDER BY fecha_dato ASC)
),

/* THIS CTE SUMS UP FINANCIAL DATA FROM PURCHASE ORDERS.
THEY MUST BE STRING AGGREGATED TO AVOID FAN-OUT (EVERY ROW IS ONE PURCHASE ORDER ) */

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
                        /* JOIN FINAL */

SELECT
      
      CONCAT('GEO-', ROW_NUMBER() OVER()) AS procurement_id,
      SAFE_CAST(geo.PID AS STRING) AS origin_database_id,
      SAFE_CAST(geo.cueanexo AS STRING) AS school_id,
      geo.nombre AS school_name,
      pad.nombre_corto AS school_shorthand_name,
      pad.nivel AS school_level,
      pad.sector AS school_sector,
      pad.coordenadas_corregidas AS school_coordinates,
      P.tipo_pedido AS procurement_type,
      P.descripcion_pedido AS procurement_description,
      GREATEST(fechas.sp_fecha, fechas.fecha_oc, fechas.fecha_rc, fechas.fecha_rs) AS procurement_latest_date,
      P.linea_de_accion AS procurement_line_of_action,
      P.proyecto AS procurement_program,
      CASE WHEN D.estado_desafectacion IS NULL AND D.fecha_solicitud_desafectacion IS NULL AND D.nota_desafectacion IS NULL THEN 'afectado' ELSE 'desafectado' END AS procurement_status,
      SAFE_CAST(matricula.matricula_ultimo_dato AS NUMERIC) AS affected_enrolment,
      SAFE_CAST((matricula.docentes_ultimo_dato + matricula.auxiliares_ultimo_dato) AS NUMERIC) AS affected_non_students,
      P.area_pedido AS procurement_area,
      SAFE_CAST((fin.monto_adjudicado/COUNT(geo.cueanexo) OVER(PARTITION BY geo.PID)) AS NUMERIC) AS procurement_investment

FROM {{ source('lanus_operations', 'georref')}} AS geo
LEFT JOIN {{ source('lanus_operations', 'pedido')}} AS P ON geo.PID = P.PID
LEFT JOIN {{ source('lanus_bases', 'padron_cue')}} AS pad ON geo.cueanexo = pad.cueanexo
LEFT JOIN resumen_financiero AS fin ON geo.pid = fin.pid
LEFT JOIN fechas ON geo.pid = fechas.pid

                                                      -- *************** OJO CON EL JOIN DE ABAJO PORQUE A LA HORA DE AUTOMATIZAR HAY QUE SACAR EL CASE WHEN
LEFT JOIN matricula ON geo.cueanexo = matricula.cueanexo AND CASE WHEN EXTRACT(YEAR FROM DATE(GREATEST(fechas.sp_fecha, fechas.fecha_oc, fechas.fecha_rc, fechas.fecha_rs))) < 2026 THEN EXTRACT(YEAR FROM DATE(GREATEST(fechas.sp_fecha, fechas.fecha_oc, fechas.fecha_rc, fechas.fecha_rs))) ELSE 2025 END = matricula.anio_dato 
                                                      -- *************** OJO CON EL JOIN DE ARRIBA PORQUE A LA HORA DE AUTOMATIZAR HAY QUE SACAR EL CASE WHEN

LEFT JOIN deduplicated_desafectaciones AS D ON geo.pid = D.PID
WHERE geo.pid IS NOT NULL

ORDER BY procurement_id

