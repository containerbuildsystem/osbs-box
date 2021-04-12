FROM docker.io/postgres:12

EXPOSE 5432

ENV POSTGRES_DB="koji" \
    POSTGRES_USER="koji" \
    POSTGRES_PASSWORD="mypassword"

# Add database initialization scripts
# They will be executed automatically, in alphabetical order
COPY sql-init/ /docker-entrypoint-initdb.d/

# The base schema is taken from koji-base and injected during build by openshift
RUN mv /docker-entrypoint-initdb.d/schema.sql \
       /docker-entrypoint-initdb.d/00-schema.sql
