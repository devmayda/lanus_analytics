Municipal Secretariat of Education Analytics Pipeline (dbt + BigQuery)

This end-to-end ELT pipeline takes raw data from Google Sheets files that are used daily by different teams of the organization and transforms it into a single georeferenced table that can serve a BI dashboard tool.


Business Context

Since the intent was to transform the business logic of different operational areas into one big table for a BI dashboard, we needed to be clear in the de definition of the grain for that final table. A strict data contract was drafted that defined an "intervention" as a discrete action from the Secretariat that had measurable impact on the district and school population.
This definition allowed us to merge into one table all the data from:
  - Events planned and executed by the Secretariat with the involvement of schools or the general populace.
  - Bus trips provided by the Secretariat to schools per their request.
  - Purchases of good, services and civil works that had schools listed as beneficiaries.

The original grain in those is deaggregated (for the interventions that included more than one school) and transformed to fit the schema of the final fact table.
A reporting spine was introduced to the pipeline to insert schools that had not been affected by any intervention in specific years