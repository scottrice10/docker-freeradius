FROM ubuntu:precise

RUN apt-get update -y && apt-get -y install \
    wget build-essential net-tools tcpdump lsb-base \
    libc6 libgdbm3 libltdl7 libpam0g libperl5.14 libpython2.7 \
    libssl1.0.0 ssl-cert ca-certificates adduser libmhash-dev libtalloc-dev \
    libperl-dev libssl-dev libpam-dev libgdb-dev libgdbm-dev git-core

WORKDIR /opt
RUN git clone --depth 1 https://github.com/FreeRADIUS/freeradius-server.git

WORKDIR /opt/freeradius-server
RUN ./configure && make && make install
RUN ldconfig
RUN useradd radius
RUN install -d -g radius -o radius /var/log/radius
RUN install -d -g radius -o radius /usr/local/etc/raddb
RUN install -d -g radius -o radius /var/run/radiusd
RUN touch /var/log/radius/radius.log

# Until heartbleed patch makes it into repo, ignore checking
RUN sed -i 's/allow_vulnerable_openssl.*/allow_vulnerable_openssl = yes/g' \
    /usr/local/etc/raddb/radiusd.conf

ADD ./src/clients.conf /usr/local/etc/raddb/clients.conf
ADD ./src/users /usr/local/etc/raddb/users

# Set up postgres
ENV PG_VERSION 9.3
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} \
 && rm -rf /var/lib/postgresql \
 && rm -rf /var/lib/apt/lists/* # 20150504
 
ADD start /start
RUN chmod 755 /start

EXPOSE 1812/udp
EXPOSE 1813/udp
EXPOSE 1814/udp
EXPOSE 18120/udp
EXPOSE 5432

VOLUME ["/var/lib/postgresql"]
VOLUME ["/run/postgresql"]

CMD /usr/local/sbin/radiusd -xx -l /var/log/radius/radius.log -f
CMD ["/start"]
