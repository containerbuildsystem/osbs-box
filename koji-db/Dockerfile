FROM postgres:9.4
MAINTAINER Luiz Carvalho <lucarval@redhat.com>

# Location for init scripts executed only during DB
# initialization. Scripts will be executed in
# alphabetical order
COPY sql-init/ /docker-entrypoint-initdb.d/

ADD https://pagure.io/koji/raw/master/f/docs/schema.sql \
    /docker-entrypoint-initdb.d/00-schema.sql

RUN chmod o+r /docker-entrypoint-initdb.d/00-schema.sql
