# pgbacked

[PostgreSQL](https://hub.docker.com/_/postgres) with batteries included ⚡

- [pgBackRest](https://pgbackrest.org) — Backup & Restore
- [plpython](https://www.postgresql.org/docs/current/plpython.html) — Run anything from within postgres
- [pg_cron](https://github.com/citusdata/pg_cron) — Schedule sql jobs
- [locales-all](https://packages.debian.org/sid/locales-all) — All locales precompiled

## Table of Contents

- [pgbacked](#pgbacked)
  - [Table of Contents](#table-of-contents)
  - [Changelog](#changelog)
    - [`2.0.0`](#200)
    - [`1.1.0`](#110)
    - [`1.0.0`](#100)
  - [Default paths](#default-paths)
    - [PostgreSQL](#postgresql)
    - [pgBackRest](#pgbackrest)
  - [Usage](#usage)
    - [Configuring pgBackRest](#configuring-pgbackrest)
    - [Configuring PostgreSQL](#configuring-postgresql)
    - [Calling pgBackRest using plpython](#calling-pgbackrest-using-plpython)
    - [Scheduling a backup using pg\_cron](#scheduling-a-backup-using-pg_cron)
    - [Restoring from backup](#restoring-from-backup)


## Changelog

### `2.0.0`

- Run as user `postgres` ([#2](https://github.com/factisresearch/pgbacked/pull/2))

### `1.1.0`

- Make sure we don't start up with an incompletely initialized database ([#1](https://github.com/factisresearch/pgbacked/pull/1))

### `1.0.0`

Initial release

## Default paths

### PostgreSQL

- Configuration: `/etc/postgresql/postgresql.conf`
- Data: `/var/lib/postgresql/data`
- Logs: `/var/log/postgresql` (must be enabled first)

### pgBackRest

- Configuration: `/etc/pgbackrest/pgbackrest.conf`
- Data: `/var/lib/pgbackrest`
- Logs: `/var/log/pgbackrest`

## Usage

The pgBackRest stanza `default` will be created on database initialization.

### Configuring pgBackRest

```ini
[default]
pg1-path=/var/lib/postgresql/data

[global]
repo1-path=/var/lib/pgbackrest
```

### Configuring PostgreSQL

```ini
listen_addresses = '*'

archive_mode = on
archive_command = 'pgbackrest archive-push --stanza=default %p'

shared_preload_libraries = 'pg_cron'
```

### Calling pgBackRest using plpython

```sql
CREATE SCHEMA IF NOT EXISTS pgbackrest;

CREATE OR REPLACE FUNCTION pgbackrest.backup() RETURNS void AS $$
    import subprocess

    subprocess.run(["pgbackrest", "backup", "--stanza=default"], check=True)
$$ LANGUAGE plpython3u;
```

### Scheduling a backup using pg_cron

```sql
SELECT cron.schedule('0 0 * * *', 'SELECT pgbackrest.backup()');
```

### Restoring from backup

Example using [Docker Compose](https://docs.docker.com/compose/).

```
docker compose stop SERVICE_NAME
docker compose run SERVICE_NAME find /var/lib/postgresql/data -mindepth 1 -delete
docker compose run SERVICE_NAME pgbackrest restore --stanza=default
docker compose start SERVICE_NAME
```

Refer to the [pgBackRest User Guide](https://pgbackrest.org/user-guide.html#quickstart/perform-restore).
