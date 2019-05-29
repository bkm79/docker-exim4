FROM debian:latest

RUN apt update && apt install -y locales locales-all libcurl4-openssl-dev spamassassin exim4-daemon-heavy sa-exim clamav clamav-daemon python-setuptools python-docutils libmysql++-dev wget less libdbi-perl libdbd-mysql-perl pkg-config dh-autoreconf libestr-dev uuid-dev git systemd libgcrypt-dev flex bison python-pip

RUN cd /opt && git clone https://github.com/rsyslog/libfastjson && cd libfastjson && autoreconf -v --install && ./configure && make && make install && \
    cd /opt && git clone https://github.com/rsyslog/liblogging && cd liblogging && autoreconf -v --install && ./configure --disable-man-pages && make && make install && \
    cd /opt && git clone https://github.com/rsyslog/rsyslog && cd rsyslog && ./autogen.sh --enable-omstdout && make && make install

RUN cd /usr/local/share/ca-certificates && \
    wget https://letsencrypt.org/certs/letsencryptauthorityx1.pem && mv letsencryptauthorityx1.pem letsencryptauthorityx1.crt && \
    wget https://letsencrypt.org/certs/letsencryptauthorityx2.pem && mv letsencryptauthorityx2.pem letsencryptauthorityx2.crt && \
    wget https://letsencrypt.org/certs/letsencryptauthorityx3.pem && mv letsencryptauthorityx3.pem letsencryptauthorityx3.crt && \
    wget https://letsencrypt.org/certs/letsencryptauthorityx4.pem && mv letsencryptauthorityx4.pem letsencryptauthorityx4.crt && \
    wget https://letsencrypt.org/certs/isrgrootx1.pem && mv isrgrootx1.pem isrgrootx1.crt && update-ca-certificates \
    mkdir -p /var/spool/exim && mkdir -p /usr/lib/exim/lookups && ln -sf /dev/stdout /var/log/syslog && \
    rm -rf /var/lib/apt/lists/* && mkdir -p /run/php && mkdir /var/log/supervisor/ && \
    pip install supervisor && pip install supervisor-stdout && \
    cd /etc/mail/spamassassin/ && sed -i "s/.*::TxRep.*/loadplugin Mail::SpamAssassin::Plugin::TxRep/g" v341.pre && \
    mkdir /var/run/clamav && chmod -R 777 /var/run/clamav && sed -i "s/Debian-exim:x:101:/Debian-exim:x:101:clamav/g" /etc/group

ADD sa-exim.conf /etc/exim4/sa-exim.conf

WORKDIR /usr/bin

ADD supervisord.conf /etc/supervisord.conf

ADD rsyslog.conf /etc/rsyslog.conf

ADD freshclam.conf /etc/clamav/

ADD runclamd /opt

ADD spamd /opt

RUN chmod +x /opt/spamd && chmod +x /opt/runclamd

ADD sql.cf /etc/mail/spamassassin/

VOLUME /var/spool/sa-exim

ENV LC_ALL ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU.UTF-8

EXPOSE 25 465 587

CMD ["supervisord","-n","-c","/etc/supervisord.conf"]