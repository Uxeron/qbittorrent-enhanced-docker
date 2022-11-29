FROM alpine:3.16 AS Build

# Build instructions used from https://github.com/qbittorrent/qBittorrent/wiki/Compilation:-Alpine-Linux
# Install build dependencies
RUN apk add \
   autoconf \
   automake \
   build-base \
   cmake \
   curl \
   git \
   libtool \
   linux-headers \
   perl \
   pkgconf \
   python3 \
   python3-dev \
   re2c \
   tar \
   icu-dev \
   libexecinfo-dev \
   openssl-dev \
   qt5-qtbase-dev \
   qt5-qttools-dev \
   zlib-dev \
   qt5-qtsvg-dev

# Ninja build
RUN git clone --shallow-submodules --recurse-submodules https://github.com/ninja-build/ninja.git ~/ninja && cd ~/ninja && \
   git checkout "$(git tag -l --sort=-v:refname "v*" | head -n 1)" && \
   cmake -Wno-dev -B build \
	   -D CMAKE_CXX_STANDARD=17 \
	   -D CMAKE_INSTALL_PREFIX="/usr/local" && \
   cmake --build build && \
   cmake --install build

# Download Boost
RUN curl -sNLk https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz -o "$HOME/boost_1_76_0.tar.gz" && \
   tar xf "$HOME/boost_1_76_0.tar.gz" -C "$HOME"

# Build and install Libtorrent
RUN git clone --shallow-submodules --recurse-submodules https://github.com/arvidn/libtorrent.git ~/libtorrent && cd ~/libtorrent && \
   git checkout "$(git tag -l --sort=-v:refname "v1*" | head -n 1)" && \
   cmake -Wno-dev -G Ninja -B build \
      -D CMAKE_BUILD_TYPE="Release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="$HOME/boost_1_76_0/" \
      -D CMAKE_INSTALL_LIBDIR="lib" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" && \
   cmake --build build && \
   cmake --install build

# Build qBittorrent
RUN git clone --shallow-submodules --recurse-submodules https://github.com/c0re100/qBittorrent-Enhanced-Edition.git ~/qbittorrent && cd ~/qbittorrent && \
   git checkout "$(git tag -l --sort=-v:refname | head -n 1)"  && \
   cmake -Wno-dev -G Ninja -B build \
      -D CMAKE_BUILD_TYPE="release" \
      -D CMAKE_CXX_STANDARD=17 \
      -D BOOST_INCLUDEDIR="$HOME/boost_1_76_0/" \
      -D CMAKE_CXX_STANDARD_LIBRARIES="/usr/lib/libexecinfo.so" \
      -D CMAKE_INSTALL_PREFIX="/usr/local" \
      -D GUI=OFF && \
   cmake --build build


FROM alpine:3.16

# All config files go to /config instead of multiple separate folders
ENV HOME="/config" \
   XDG_CONFIG_HOME="/config" \
   XDG_DATA_HOME="/config"

# Install application dependencies
RUN apk add \
   cmake \
   icu \
   libexecinfo \
   openssl \
   qt5-qtbase-sqlite \
   qt5-qtsvg \
   python3 \
   re2c \
   libtool \
   zlib

# Copy files required for installation from build step
COPY --from=Build /root/libtorrent/build /root/libtorrent/build
COPY --from=Build /root/libtorrent/cmake /root/libtorrent/cmake
COPY --from=Build /root/libtorrent/examples /root/libtorrent/examples
COPY --from=Build /root/qbittorrent/build /root/qbittorrent/build
COPY --from=Build /root/qbittorrent/doc /root/qbittorrent/doc

# Install libtorrent and qbittorrent
RUN cmake --install /root/libtorrent/build
RUN cmake --install /root/qbittorrent/build

# Cleanup build folders
RUN rm -rf /root/qbittorrent && \
   rm -rf /root/libtorrent

# Copy the default qbittorrent config
COPY qBittorrent.conf /default/qBittorrent.conf
COPY entrypoint.sh /

# Expose WebUI and listening ports
EXPOSE 8080
EXPOSE 6881

# Bind config and downloads folders
VOLUME /config
VOLUME /downloads

ENTRYPOINT [ "/bin/sh", "entrypoint.sh" ]