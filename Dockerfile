
FROM python:3.11-slim


WORKDIR /usr/app/dbt



RUN apt-get update && apt-get install git -y
RUN pip install --no-cache-dir dbt-bigquery

