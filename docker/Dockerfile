FROM ubuntu:16.04
MAINTAINER jeffxie@iii.org.tw

WORKDIR /home/postgresql

ENV C_INCLUDE_PATH=/usr/local/include/libbson-1.0/:/usr/local/include/libmongoc-1.0:$C_INCLUDE_PATH \
    PKG_CONFIG_PATH=mongo-c-driver/src/:mongo-c-driver/src/libbson/srr \
    ORACLE_HOME=/usr/lib/oracle/12.2/client64/lib \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib \
    TNS_ADMIN=$ORACLE_HOME \
    PATH=$PATH:$ORACLE_HOME/bin

COPY dependencies/ /home/postgresql/

RUN  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
      && echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
      && apt update \
      && apt install -y sudo \
                        locate \
                        vim \
                        ssh \
                        software-properties-common \
                        wget \
                        postgresql-9.6 \
                        postgresql-server-dev-9.6 \
                        postgresql-9.6-cron \
                        build-essential \
                        pkg-config \
                        libtool \
                        autoconf \
                        libaio-dev \
                        alien \
                        libsybdb5 \
                        freetds-dev \
                        freetds-common \
                        libssl-dev \
      && cd /home/postgresql/libbson-1.3.1 \
      && ./autogen.sh \
      && make \
      && make install \
      && cd /home/postgresql/mongo-c-driver-1.3.1 \
      && ./autogen.sh \
      && ./configure --with-libbson=system \
      && make \
      && make install \
      && ldconfig \
      && cd /home/postgresql/mongo_fdw-REL-5_2_1 \
      && ldconfig \
      && ./autogen.sh --with-master \
      && make \
      && make install \
      && cd /home/postgresql \
      && alien -i oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm \
      && alien -i oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm \
      && alien -i oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm \
      && mv /home/postgresql/ld.so.conf /etc/ld.so.conf \
      && ldconfig \
      #&& mv /home/postgresql/profile /etc/profile \
      && cd /home/postgresql/oracle_fdw_2.0.0 \
      && make \
      && make install \
      && cd /home/postgresql/tds_fdw-1.0.8 \
      && make USE_PGXS=1 \
      && make USE_PGXS=1 install 

#RUN  CD /usr/lib/postgresql/9.6/lib/ \ 
#     ln -s /usr/lib/oracle/12.2/client64/lib/libclntshcore.so.12.1 /usr/lib/postgresql/9.6/lib/libclntshcore.so.12.1   

RUN  mv /home/postgresql/pg_hba.conf /etc/postgresql/9.6/main/pg_hba.conf \
     && echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf \
     && echo "shared_preload_libraries = 'pg_cron'" >> /etc/postgresql/9.6/main/postgresql.conf \
     && echo "cron.database_name = 'postgres'" >> /etc/postgresql/9.6/main/postgresql.conf \
     && mkdir -p /var/run/postgresql/9.6-main.pg_stat_tmp \
     && chown postgres.postgres /var/run/postgresql/9.6-main.pg_stat_tmp -R \
     && rm oracle-instantclient12.2* \
     && rm -rf /var/lib/apt/lists/* 
#FIX could not access private key file "/etc/ssl/private/ssl-cert-snakeoil.key": Permission denied
RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private


#RUN useradd -m localadmin && echo "localadmin:openstack" | chpasswd && adduser localadmin sudo
#RUN adduser postgres sudo
#RUN useradd -m localadmin && echo "localadmin:openstack" | chpasswd && adduser localadmin sudo
USER postgres

#RUN /etc/init.d/postgresql start
RUN /etc/init.d/postgresql start \
    && psql --command "ALTER USER postgres WITH PASSWORD 'wjan4219';"

#USER localadmin

VOLUME  ["/var/lib/postgresql"]
EXPOSE 5432 28017 27017 1433 1521
CMD /usr/lib/postgresql/9.6/bin/postgres -D /var/lib/postgresql/9.6/main -c config_file=/etc/postgresql/9.6/main/postgresql.conf
# 測試ＣＭＤ包在[]  
#CMD ["/usr/lib/postgresql/9.6/bin/postgres -D" ,"/var/lib/postgresql/9.6/main -c", "config_file=/etc/postgresql/9.6/main/postgresql.conf"]