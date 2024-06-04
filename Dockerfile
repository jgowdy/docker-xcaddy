FROM debian:bookworm as build

RUN (\
    sed -i -e 's/deb.debian.org/mirror.cogentco.com/' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git cmake libssl-dev libcurl4-openssl-dev libboost-all-dev \
    )


# Install xcaddy from cloudsmith.io
RUN (\
    DEBIAN_FRONTEND=noninteractive apt install -y debian-keyring debian-archive-keyring apt-transport-https \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg \
    && curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-xcaddy.list \
    && apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y xcaddy \
    )

# Build caddy with plugins
RUN xcaddy build --with github.com/git001/caddyv2-upload --with github.com/caddy-dns/cloudflare

# Install /usr/bin/caddy.custom as /usr/bin/caddy
RUN (\
    dpkg-divert --divert /usr/bin/caddy.default --rename /usr/bin/caddy \
    && mv ./caddy /usr/bin/caddy.custom \
    && update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.default 10 \
    && update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.custom 50 \
    )
