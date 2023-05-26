# pgbacked

[PostgreSQL](https://hub.docker.com/_/postgres) with batteries included ⚡

- [pgBackRest](https://pgbackrest.org) — Backup & Restore
- [plpython](https://www.postgresql.org/docs/current/plpython.html) — Run anything from within postgres
- [pg_cron](https://github.com/citusdata/pg_cron) — Schedule sql jobs

## Default paths

### PostgreSQL

- `/etc/postgresql/postgresql.conf`
- `/var/lib/postgresql/data`
- `/var/log/postgresql`

### pgBackRest

- `/etc/pgbackrest/pgbackrest.conf`
- `/var/lib/pgbackrest`
- `/var/log/pgbackrest`

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
