# build stage for compiling novadoom
FROM ubuntu:20.04 AS build
WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive
RUN true \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends tzdata\
    && apt-get install -y -qq --no-install-recommends \
        ca-certificates \
        git \
        gcc g++ \
        cmake \
        make \
        deutex \
        zlib1g-dev \
        libzstd1 libzstd-dev \
        patch \
        > /dev/null

# So we can use bash arrays (default /bin/sh doesn't support this)
SHELL ["/bin/bash","-c"]

ARG REPO_URL
ARG REPO_TAG

# Clone the repository
RUN true \
    && test -n "$REPO_URL" && test -n "$REPO_TAG" \
    && git clone --depth 1 --branch "$REPO_TAG" "$REPO_URL" novadoom

WORKDIR /build/novadoom

# Apply Manual Patches (make sure they are UTF-8 encoded)
RUN mkdir /patches
COPY docker-files/patches /patches
RUN true \
    && shopt -s nullglob \
    && for p in /patches/*.patch; do patch -p1 < $p; done

# Update submodules
RUN true \
    && git submodule init \
    && git submodule update -r

# Setup Build
RUN true \
    && mkdir build

# Build the Wad
# WORKDIR /build/novadoom/wad
# RUN true \
#     && /usr/games/deutex -rgb 0 255 255 -doom2 bootstrap -build wadinfo.txt ../novadoom.wad

# Build NovaDoom
WORKDIR /build/novadoom/build
RUN true \
    && cmake -W no-dev \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_CXX_COMPILER=g++ \
        -D CMAKE_C_COMPILER=gcc \
        -D BUILD_CLIENT=0 \
        -D CMAKE_C_FLAGS="-w" \
        -D CMAKE_CXX_FLAGS="-w" \
        .. \
    && cmake --build . --parallel 4 --target novasrv

# Install NovaDoom
ENV INSTALL_DIR=/usr/local/games/novadoom
COPY docker-files/novadoom-server.sh /usr/local/bin/novadoom-server
RUN true \
    && COPY_PATTERNS=(\
        server/novadoom.wad \
        server/novasrv \
    ) \
    && mkdir -p "$INSTALL_DIR" \
    && cp "${COPY_PATTERNS[@]}" "$INSTALL_DIR/" \
    && bin_path=/usr/local/bin/novadoom-server \
    && chmod a+x $bin_path \
    && sed -i "s|INSTALL_DIR|${INSTALL_DIR}|" $bin_path

# Final stage for running the novadoom server
# Copies over everything /usr/local
FROM ubuntu:20.04
COPY --from=build /usr/local /usr/local/
RUN true \
    && apt-get update -qq \
    && apt-get install -qq --no-install-recommends \
        tini \
        gosu \
        > /dev/null \
    && rm -rf /var/lib/apt/lists/*

# Environment variables used to map host UID/GID to internal
# user used to launch novadoom-server
ENV NOVADOOM_UID= \
    NOVADOOM_GID=

COPY ./docker-files/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "tini", "--", "/entrypoint.sh" ]
