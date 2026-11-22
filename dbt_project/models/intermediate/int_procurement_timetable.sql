                /* This table builds a timetable with the dates 
                of key milestone documents in the procurement
                lifecycle. If no date (or no document) exists
                yet, an arbirtrary date is set to allow for 
                comparison and aggregation downstream*/


SELECT
        
        SAFE_CAST(p.pid AS STRING) AS procurement_id,
        COALESCE(MAX(p.sp_Fecha), SAFE_CAST("2000-01-01" AS DATE)) AS sp_date,
        COALESCE(MAX(a.fecha_oc), SAFE_CAST("2000-01-01" AS DATE)) AS oc_date,
        COALESCE(MAX(a.fecha_rc), SAFE_CAST("2000-01-01" AS DATE)) AS rc_date,
        COALESCE(MAX(f.rs_fecha), SAFE_CAST("2000-01-01" AS DATE)) AS rs_date

            
FROM {{ source('lanus_operations', 'pedido')}} AS p
LEFT JOIN {{ source('lanus_operations', 'adjudicacion')}} AS a ON p.pid = a.pid
LEFT JOIN {{ source('lanus_operations', 'facturacion')}} AS f ON p.pid = f.pid
LEFT JOIN {{ source('lanus_operations', 'desafectaciones')}} AS d ON p.pid = d.pid
            
WHERE p.pid IS NOT NULL
GROUP BY p.pid