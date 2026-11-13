# 1. Start from an official, lightweight base image
FROM python:3.11-slim

# 2. Set the working directory inside the container
WORKDIR /usr/app/dbt


# 4. Install dependencies
RUN apt-get update && apt-get install git -y
RUN pip install --no-cache-dir dbt-bigquery




# 3. Copy package files first to leverage Docker layer caching
#COPY package*.json ./

# 5. Copy the rest of the application source code
#COPY . .

# 6. Document the port the app listens on
#EXPOSE 3000

# 7. Run as a non-root user for better security
#USER node

# 8. Define the command to start the application
#CMD ["node", "index.js"]