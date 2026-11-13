 /*    THIS QUERY CHECKS FINANCIAL TOTALS FOR EVERY PROJECT
 FOR CORRESPONDENCE BETWEEN SOURCE AND RESULTS SERVED TO DASHBOARD     */


WITH    distinct_pid AS (

    SELECT DISTINCT

            geo.pid AS pid

    FROM {{ source('lanus_operations', 'georref') }} AS geo
    LEFT JOIN {{ source('lanus_operations', 'desafectaciones') }} AS d
    ON SAFE_CAST(geo.PID AS STRING) = SAFE_CAST(d.PID AS STRING)
    WHERE geo.PID IS NOT NULL
    AND CASE WHEN d.estado_desafectacion IS NULL AND d.fecha_solicitud_desafectacion IS NULL AND d.nota_desafectacion IS NULL THEN 'afectado' ELSE 'desafectado' END  = 'afectado'
),
        investment_totals_by_pid AS (

    SELECT

        SAFE_CAST(dis.pid AS STRING) AS pid,
        SUM(SAFE_CAST(adj.monto_adjudicado AS NUMERIC)) AS monto_adjudicado

    FROM distinct_pid AS dis
    LEFT JOIN {{ source('lanus_operations', 'adjudicacion')}} AS adj
    ON SAFE_CAST(dis.pid AS STRING) = SAFE_CAST(adj.PID AS STRING)
    GROUP BY dis.pid
),

        aggregated_from_procurement AS (

            SELECT

                origin_database_id,
                SUM(procurement_investment) AS agg_investment

            FROM {{ ref("int_procurement_interventions") }}
            WHERE procurement_status = 'afectado'
            GROUP BY origin_database_id
            

)

    SELECT

            fct.origin_database_id AS pid,
            source.monto_adjudicado AS source_totals,
            fct.agg_investment AS fct_totals

    FROM investment_totals_by_pid AS source
    FULL OUTER JOIN aggregated_from_procurement AS fct
    ON source.pid = fct.origin_database_id
    WHERE ABS(COALESCE(ROUND(source.monto_adjudicado, 2), 0) - COALESCE(ROUND(fct.agg_investment, 2), 0)) > 0



