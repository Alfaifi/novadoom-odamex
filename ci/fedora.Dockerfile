FROM fedora:32

WORKDIR novadoom

COPY . .

# Packages
RUN set -x && \
    dnf -y install git gcc-c++ alsa-lib-devel libcurl-devel libzstd-devel \
                   ninja-build SDL2-devel SDL2_mixer-devel && \
   curl -LO https://github.com/Kitware/CMake/releases/download/v3.30.2/cmake-3.30.2-linux-x86_64.sh && \
   chmod +x ./cmake-3.30.2-linux-x86_64.sh && \
   ./cmake-3.30.2-linux-x86_64.sh --skip-license --prefix=/usr/local

WORKDIR build

# Build commands
RUN cmake .. -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_MINIUPNP=0 \
    -DBUILD_OR_FAIL=1 -DBUILD_CLIENT=1 -DBUILD_SERVER=1 \
    -DBUILD_MASTER=1

CMD ["ninja"]
