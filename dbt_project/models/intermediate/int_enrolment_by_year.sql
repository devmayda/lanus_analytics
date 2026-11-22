                /* This table  brings the latest enrolment data
                for every school, for every school year.*/


WITH consolidated_yearly AS (

    SELECT
        school_id,
        school_infrastructure_id,
        EXTRACT(YEAR FROM DATE(record_date)) AS record_year,
        FIRST_VALUE(enrolment IGNORE NULLS) OVER(school_id_by_year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS enrolment_latest_record,
        FIRST_VALUE(teachers IGNORE NULLS) OVER(school_id_by_year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teachers_latest_record,
        FIRST_VALUE(non_teachers IGNORE NULLS) OVER(school_id_by_year ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS non_teachers_yearly_latest_record

    FROM {{ ref("stg_enrolment") }}
    QUALIFY ROW_NUMBER() OVER(school_id_by_year) = 1
    WINDOW school_id_by_year AS (
        PARTITION BY school_id, EXTRACT(YEAR FROM DATE(record_date))
        ORDER BY record_date DESC
    )

)

SELECT
    school_id,
    school_infrastructure_id,
    record_year,
    COALESCE(
        enrolment_latest_record,
        LAST_VALUE(enrolment_latest_record IGNORE NULLS) OVER(records_by_school_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            ) AS enrolment_latest_record,
    COALESCE(
        teachers_latest_record,
        LAST_VALUE(teachers_latest_record IGNORE NULLS) OVER(records_by_school_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            ) AS teachers_latest_record,
    COALESCE(
        non_teachers_yearly_latest_record,
        LAST_VALUE(non_teachers_yearly_latest_record IGNORE NULLS) OVER(records_by_school_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            ) AS non_teachers_latest_record,
    COALESCE(LEAD(record_year) OVER(records_by_school_id), 9999) AS valid_to_year

FROM consolidated_yearly
WINDOW records_by_school_id AS (PARTITION BY school_id ORDER BY record_year ASC)

