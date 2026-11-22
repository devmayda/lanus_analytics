# Municipal Secretariat of Education Analytics Pipeline (dbt + BigQuery)

End-to-end ELT pipeline built for the **Municipal Secretariat of Education of Lanús**. It transforms operational records sourced from daily-use Google Sheets and internal web tools into a unified, georeferenced analytical layer in BigQuery that powers **Looker Studio** executive dashboards.

---

## 1. Business Context & Problem Statement

Different operational areas within the Secretariat (Events & Planning, School Transportation, and Procurement/Infrastructure) tracked their daily activities in isolated spreadsheets with incompatible structures and granularities. Leadership lacked a unified view to monitor progress on these lines of action.

### Core Solution: The "Intervention" Data Contract
To bridge operational silos into a single source of truth, a strict **data contract** was established defining an **intervention** as *any discrete action executed or managed by the Secretariat with measurable impact on a school or the district population*.

This unified grain brings together three distinct workflows into one fact table (`fct_interventions`):
* **Events:** Community and school events logged via an Apps Script web app (originally stored as nested JSON arrays).
* **School Bus Trips:** Transportation requests fulfilled for schools, deaggregated to the school-trip level.
* **Procurement & Civil Works:** Purchases of goods, services, and infrastructure projects mapped to beneficiary schools and reconciled with purchase orders.

---

## 2. Architecture & Data Flow

```mermaid
flowchart LR
    A[Operational Sources<br/>Google Sheets & Apps Script] -->|BigQuery External Table (Google Sheets)| B[(BigQuery Raw<br/>lanus_operations / lanus_bases / lanus_planning)]
    B --> C[dbt Staging<br/>stg_* views]
    C --> D[dbt Intermediate<br/>int_* transformations]
    D --> E[(BigQuery Marts<br/>fct_interventions & dim_schools)]
    E --> F[BI Layer<br/>Looker Studio Dashboards]
```

### Modeling Strategy
* **Staging (`models/staging/`):** 1-to-1 source standardization, type casting, string normalization, and JSON parsing (`stg_events`, `stg_buses`, `stg_enrolment`, `stg_schools`).
* **Intermediate (`models/intermediate/`):** Complex business logic isolated into modular steps:
  * *JSON Unnesting:* Exploding event-school arrays while preserving order (`int_events_unnested`).
  * *Fan-Out Prevention:* Pre-aggregating financial totals and deduplicating cancellation records before joining (`int_procurement_interventions`, `int_procurement_timetable`).
  * *Temporal Enrolment Carry-Forward:* Window-based SCD Type 2-style interval mapping (`record_year` to `valid_to_year`) so interventions inherit the latest known student/staff headcount (`int_enrolment_by_year`).
  * *Entity-Calendar Reporting Spine:* A cross-join scaffold (`int_school_by_year_reporting_spine`) combined via `FULL OUTER JOIN` in the final mart to retain public schools with **zero interventions** (`unreached`) per year.
* **Marts (`models/marts/`):**
  * `fct_interventions`: Designed as a **One Big Table (OBT)** to eliminate expensive runtime joins/blending in Looker Studio and guarantee fast dashboard responsiveness.
  * `dim_schools`: Master dimensional directory for public schools (`padron_cue`).

---

## 3. Dashboard KPIs Supported

The final analytical layer is designed to feed territorial and budget monitoring dashboards, enabling stakeholders to track:
* **Territorial Coverage Rate (%):** Ratio of reached vs. `unreached` public schools per calendar year (powered by the reporting spine).
* **Total Investment by School & Line of Action:** Executed procurement and estimated transportation spending reconciled against purchase orders.
* **Population Impact:** Estimated `affected_students` and `affected_adults` per intervention, line of action, and school level.
* **Operational Execution Mix:** Breakdown of interventions by type (`Evento`, `Bus trip`, procurement categories), program, and status (`executed` vs. `not executed`).
* **Geospatial Distribution:** School-level mapping using corrected coordinates (`school_coordinates`) to identify underserved zones.

---

## 4. Data Quality & Testing

Reliability is enforced through a combination of dbt generic tests and custom singular SQL tests:
* **Schema & Grain Integrity:** `unique`, `not_null`, conditional `not_null` (e.g., public schools must have a `school_id`), `accepted_values`, and `relationships` warnings for unregistered private schools.
* **Financial Reconciliation (`tests/procurement_financial_total.sql`):** Validates that total awarded investment served to the dashboard matches raw purchase order sums (`adjudicacion`) with zero drift.
* **Anti-Fan-Out & Completeness Checks (`tests/procurement_granularity_test.sql`, `tests/event_id_unnesting_granularity_check.sql`):** Ensures no duplicate school-project rows are created during joins and no events are lost during JSON unnesting.

---

## 5. Known Limitations & Technical Debt

* **Public vs. Private Scope:** Reporting focuses on public schools (`Estatal`). Private institutions without registered CUEs appear in `fct_interventions` via the `FULL OUTER JOIN` with incomplete dimensional metadata.
* **Reporting Spine Time Filtering:** The `unreached` school scaffold operates on a calendar-year basis; filtering across non-annual custom date ranges requires care in BI filters.
* **Hardcoded Bus Unit Cost:** Bus trip investment currently uses a fixed unit reference cost until individual trips can be linked directly to procurement orders.
* **Procurement Refactor Pending:** `int_procurement_interventions` and `int_procurement_timetable` currently query `source()` directly; a full staging refactor is scheduled alongside an upcoming upstream database redesign.

---

## 6. Local Setup & Execution

This project runs in a containerized `dbt-bigquery` environment using Docker.

### Prerequisites
1. Copy `dbt_project/profiles.yml.example` to `dbt_project/profiles.yml` and configure your target dataset/location.
2. Place your GCP Service Account JSON key inside a local `./credentials` folder (excluded from version control).
3. Create a `.env` file defining `DBT_GCP_PROJECT=<your-gcp-project-id>`.

### Useful Commands
* **Start container:** `docker compose up -d`
* **Run models & tests:** `dbt build`
* **Generate & serve lineage documentation:** `dbt docs generate && dbt docs serve --port 8080`
