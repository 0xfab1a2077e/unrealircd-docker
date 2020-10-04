FROM alpine:3.9 AS build-env
ENV UNREAL_VERSION="5.0.6" \
    ANOPE_VERSION="2.0.7" \
    TERM="vt100" \
    LC_ALL=C

# install latest updates and configure alpine
RUN apk update
RUN apk upgrade
RUN apk add --no-cache git make curl wget gnupg gcc g++ build-base openssl openssl-dev expect cmake supervisor

RUN addgroup -S ircd && adduser -S ircd -G ircd 

COPY anope-make.expect /home/ircd/anope-make.expect

USER ircd
WORKDIR /home/ircd
ENV HOME /home/ircd
RUN wget https://www.unrealircd.org/downloads/unrealircd-$UNREAL_VERSION.tar.gz https://www.unrealircd.org/downloads/unrealircd-$UNREAL_VERSION.tar.gz.asc && gpg --keyserver keys.gnupg.net --recv-keys 0xA7A21B0A108FF4A9 && gpg --verify unrealircd-$UNREAL_VERSION.tar.gz.asc unrealircd-$UNREAL_VERSION.tar.gz
RUN tar zxvf unrealircd-$UNREAL_VERSION.tar.gz && cd unrealircd-$UNREAL_VERSION && ./Config && make && make install

WORKDIR /home/ircd
RUN wget -O anope-$ANOPE_VERSION-source.tar.gz https://github.com/anope/anope/releases/download/$ANOPE_VERSION/anope-$ANOPE_VERSION-source.tar.gz && tar zxvf anope-$ANOPE_VERSION-source.tar.gz 
WORKDIR /home/ircd/anope-$ANOPE_VERSION-source 
RUN ln -sf extra/m_ssl_openssl.cpp modules/m_ssl_openssl.cpp && /usr/bin/expect /home/ircd/anope-make.expect && cd build && make && make install

USER root
COPY supervisor_services.conf /etc/supervisor/conf.d/services.conf
COPY unrealircd-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]
