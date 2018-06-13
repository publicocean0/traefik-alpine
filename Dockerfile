FROM alpine:3.6
RUN echo http://mirror.yandex.ru/mirrors/alpine/v3.5/main > /etc/apk/repositories; \
    echo http://mirror.yandex.ru/mirrors/alpine/v3.5/community >> /etc/apk/repositories

RUN apk update 
RUN apk --no-cache add ca-certificates shadow

ENV SERVICE_UID=10002 \
    SERVICE_GROUP=traefik \
    SERVICE_GID=10001 

RUN set -ex; \
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		armhf) arch='arm' ;; \
		aarch64) arch='arm64' ;; \
		x86_64) arch='amd64' ;; \
		*) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
	esac; \
	apk add --no-cache --virtual .fetch-deps libressl &&\  
wget -O /usr/local/bin/traefik "https://github.com/containous/traefik/releases/download/v1.6.3/traefik_linux-$arch"; \
	apk del .fetch-deps; \
	chmod +x /usr/local/bin/traefik   
RUN apk add --no-cache libcap
RUN which setcap 
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik
         
RUN addgroup -g ${SERVICE_GID} ${SERVICE_GROUP} && mkdir /opt ; \
        adduser -g "Traefik user" -D -h /opt/traefik -G ${SERVICE_GROUP} -s /sbin/nologin -u ${SERVICE_UID} traefik ; \
        mkdir /opt/traefik/etc ; \
        touch /opt/traefik/etc/traefik.toml &&  touch /opt/traefik/etc/ecma.json ;\ 
        chown -R traefik:${SERVICE_GROUP} /opt/traefik 

    USER traefik
    WORKDIR /opt/traefik
    COPY entrypoint.sh /
    EXPOSE 80
    ENTRYPOINT ["/entrypoint.sh"]
    CMD ["traefik"]

# Metadata
LABEL org.label-schema.vendor="Containous" \
      org.label-schema.url="https://traefik.io" \
      org.label-schema.name="Traefik" \
      org.label-schema.description="A modern reverse-proxy" \
      org.label-schema.version="v1.6.3" \
      org.label-schema.docker.schema-version="1.0"
