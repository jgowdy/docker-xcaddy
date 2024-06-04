FROM golang:bookworm as build


# Explicit mirror selection due to slowness
RUN sed -i -e 's/deb.debian.org/debian.csail.mit.edu/' /etc/apt/sources.list.d/debian.sources

# Need apt-get update for initial apt init
# Install initial essential packages
RUN (\
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y curl sudo git \
    )

# Install xcaddy from cloudsmith.io
RUN (\
    DEBIAN_FRONTEND=noninteractive apt-get install -y debian-keyring debian-archive-keyring apt-transport-https \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-xcaddy.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y xcaddy \
    )

# Build caddy with plugins
RUN xcaddy build --with github.com/git001/caddyv2-upload --with github.com/caddy-dns/cloudflare

# Install /usr/bin/caddy.custom as /usr/bin/caddy
#RUN (\
    #dpkg-divert --divert /usr/bin/caddy.default --rename /usr/bin/caddy \
    # && mv ./caddy /usr/bin/caddy.custom \
    # && update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.default 10 \
    #&& update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.custom 50 \
    #)

FROM scratch
ENV XDG_CONFIG_HOME=/config
COPY --from=build /go/caddy /usr/bin/caddy
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# For debugging purposes only
COPY --from=busybox:musl /bin/ /bin/

# It is expected that /etc/caddy/Caddyfile is mounted as a volume
#ENTRYPOINT [ "/usr/bin/caddy", "run", "--config", "/etc/caddy/Caddyfile"]
#CMD ["/usr/bin/caddy", "run", "-config=/etc/caddy/Caddyfile"]
CMD ["/bin/sh"]
