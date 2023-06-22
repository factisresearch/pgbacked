FROM debian:bullseye as build

# https://pgbackrest.org/user-guide.html#build
RUN apt-get update
RUN apt-get install -y \
    gcc \
    libbz2-dev \
    liblz4-dev \
    libpq-dev \
    libssl-dev \
    libxml2-dev \
    libyaml-dev \
    libz-dev \
    libzstd-dev \
    make \
    pkg-config \
    wget

RUN mkdir build
RUN wget -q -O - https://github.com/pgbackrest/pgbackrest/archive/release/2.45.tar.gz | tar zx -C build

RUN cd /build/pgbackrest-release-2.45/src && ./configure && make

FROM postgres:15-bullseye as patch

# https://github.com/docker-library/postgres/issues/159
RUN apt-get update
RUN apt-get install -y \
    patch

COPY safe-initdb.docker-entrypoint.sh.diff .
RUN patch /usr/local/bin/docker-entrypoint.sh < safe-initdb.docker-entrypoint.sh.diff

FROM postgres:15-bullseye as install

# https://pgbackrest.org/user-guide.html#installation
RUN apt-get update
RUN apt-get install -y \
    libxml2 \
    postgresql-client

COPY --from=build /build/pgbackrest-release-2.45/src/pgbackrest /usr/bin
RUN chmod 755 /usr/bin/pgbackrest

RUN mkdir -p -m 770 /var/log/pgbackrest
RUN chown postgres:postgres /var/log/pgbackrest
RUN mkdir -p /etc/pgbackrest
RUN mkdir -p /etc/pgbackrest/conf.d
RUN touch /etc/pgbackrest/pgbackrest.conf
RUN chmod 640 /etc/pgbackrest/pgbackrest.conf
RUN chown postgres:postgres /etc/pgbackrest/pgbackrest.conf

# https://github.com/citusdata/pg_cron#installing-pg_cron
RUN apt-get install -y \
    postgresql-15-cron

# plpython
RUN apt-get install -y \
    postgresql-plpython3-15

# locales
RUN apt-get install -y \
    locales-all
RUN apt-get clean -y

FROM install as setup

# https://pgbackrest.org/user-guide.html#quickstart/create-repository
RUN mkdir -p /var/lib/pgbackrest
RUN chmod 750 /var/lib/pgbackrest
RUN chown postgres:postgres /var/lib/pgbackrest

# https://github.com/docker-library/docs/blob/master/postgres/README.md#initialization-scripts
COPY pgbackrest-init.sh /docker-entrypoint-initdb.d/
COPY pg_cron.sql /docker-entrypoint-initdb.d/
COPY plpython3u.sql /docker-entrypoint-initdb.d/

COPY --from=patch /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

FROM setup as run

USER postgres

CMD ["postgres", "--config_file=/etc/postgresql/postgresql.conf"]
