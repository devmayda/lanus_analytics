
/*   Test query to check that we don't lose any record after unnesting    */

SELECT

    stg.event_id

FROM {{ ref('stg_events') }} AS stg
LEFT JOIN {{ ref('fct_interventions') }} AS fct
    ON stg.event_id = fct.origin_database_id
    AND fct.intervention_type = 'Evento'
WHERE fct.origin_database_id IS NULL