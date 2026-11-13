
        /*    THIS QUERY LETS US KNOW THAT THERE ARE NOT MORE THAN ONE
        OCCURRENCE OF A SCHOOL ID WITHIN A SPECIFIC INVESTMENT PROJECT.
        FAILING THIS TESTS MAY BE DUE TO DUPLICATION IN THE QUERY OR
        DATA INPUT ERRORS (LOGGING ONE RELATIONSHIP MORE THAN ONCE)     */
SELECT

      origin_database_id,
      school_id,
      COUNT(*) AS occurrence

FROM {{ ref('int_procurement_interventions') }}
GROUP BY origin_database_id, school_id
HAVING COUNT(*) >1


