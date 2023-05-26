#!/usr/bin/env bash
set -e

# https://pgbackrest.org/user-guide.html#quickstart/create-stanza
pgbackrest --stanza=default --log-level-console=detail stanza-create
