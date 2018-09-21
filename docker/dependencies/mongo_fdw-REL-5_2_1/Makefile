# mongo_fdw/Makefile
#
# Portions Copyright © 2004-2014, EnterpriseDB Corporation.
#
# Portions Copyright © 2012–2014 Citus Data, Inc.
#

MODULE_big = mongo_fdw

#
# We assume we are running on a POSIX compliant system (Linux, OSX). If you are
# on another platform, change env_posix.os in MONGO_OBJS with the appropriate
# environment object file.
#
MONGO_DRIVER = mongo-c-driver
MONGO_PATH = $(MONGO_DRIVER)/src
MONGO_OBJS = $(MONGO_PATH)/bson.os $(MONGO_PATH)/encoding.os $(MONGO_PATH)/md5.os \
             $(MONGO_PATH)/mongo.os $(MONGO_PATH)/numbers.os $(MONGO_PATH)/env.os
LIBJSON = json-c
LIBJSON_OBJS =	$(LIBJSON)/json_util.o $(LIBJSON)/json_object.o $(LIBJSON)/json_tokener.o \
				$(LIBJSON)/json_object_iterator.o $(LIBJSON)/printbuf.o $(LIBJSON)/linkhash.o \
				$(LIBJSON)/arraylist.o $(LIBJSON)/random_seed.o $(LIBJSON)/debug.o
PG_CPPFLAGS = --std=c99 -I$(MONGO_PATH) -I$(LIBJSON)
OBJS = connection.o option.o  mongo_wrapper.o mongo_fdw.o mongo_query.o $(MONGO_OBJS) $(LIBJSON_OBJS)

EXTENSION = mongo_fdw
DATA = mongo_fdw--1.0.sql  mongo_fdw--1.1.sql mongo_fdw--1.0--1.1.sql

REGRESS = mongo_fdw
REGRESS_OPTS = --load-extension=$(EXTENSION)

$(MONGO_DRIVER)/%.os:
	$(MAKE) -C $(MONGO_DRIVER) $*.os
#$(LIBJSON)/json.o:
#	$(MAKE) -C $(LIBJSON)

#
# Users need to specify their Postgres installation path through pg_config. For
# example: /usr/local/pgsql/bin/pg_config or /usr/lib/postgresql/9.1/bin/pg_config
#

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

ifndef MAJORVERSION
    MAJORVERSION := $(basename $(VERSION))
endif

ifeq (,$(findstring $(MAJORVERSION), 9.3 9.4 9.5 9.6 10.0))
    $(error PostgreSQL 9.3, 9.4, 9.5, 9.6 or 10.0 is required to compile this extension)
endif
