# Makefile for SQL-based manage_user_permissions extension
EXTENSION = manage_user_permissions
DATA = manage_user_permissions--1.3.sql
PG_CONFIG = /usr/pgsql-16/bin/pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

