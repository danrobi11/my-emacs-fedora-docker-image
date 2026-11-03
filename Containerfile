# Emacs from master on Fedora 45 (dynamic, terminal-only, pdumper)
# Based on the build flags from https://github.com/danrobi11/emacs-fedora-dynamic
#
# Build:
#   podman build -t emacs-fedora-master:latest .
#
# Or multi-stage from your bootc image later.

FROM fedora:45

# Install build dependencies (same as the GH Actions workflow)
RUN dnf -y install \
    gcc make autoconf automake libtool pkgconfig texinfo \
    ncurses-devel gnutls-devel libxml2-devel jansson-devel \
    pcre2-devel sqlite-devel zlib-devel libcap-devel \
    libffi-devel xz-devel libidn2-devel libtasn1-devel \
    nettle-devel libunistring-devel libgpg-error-devel \
    libgcrypt-devel openssl-devel git wget file xclip \
    && dnf clean all

# Clone Emacs master
WORKDIR /tmp
RUN git clone --depth 1 --branch master https://github.com/emacs-mirror/emacs.git emacs-src

WORKDIR /tmp/emacs-src

# Configure exactly as in the workflow (terminal-only, no modules, no native-comp, pdumper)
RUN ./autogen.sh && \
    autoreconf -fi && \
    ./configure \
        --build=x86_64-pc-linux-gnu \
        --host=x86_64-pc-linux-gnu \
        --prefix=/usr/local \
        --without-x \
        --without-xpm \
        --without-jpeg \
        --without-png \
        --without-gif \
        --without-tiff \
        --without-toolkit-scroll-bars \
        --without-x-toolkit \
        --with-x-toolkit=no \
        --without-gsettings \
        --without-dbus \
        --without-gconf \
        --without-selinux \
        --without-sound \
        --without-imagemagick \
        --without-xwidgets \
        --with-gnutls \
        --without-modules \
        --without-compress-install \
        --without-native-compilation \
        --without-lcms2 \
        --with-pdumper=yes \
        CFLAGS="-O2 -g -fno-omit-frame-pointer" && \
    make bootstrap -j$(nproc) && \
    make -j$(nproc) && \
    make install && \
    # cleanup build tree to keep image smaller
    rm -rf /tmp/emacs-src && \
    dnf clean all

# Verify
RUN emacs --version && \
    readelf -d /usr/local/bin/emacs | grep NEEDED || true

# Default command
CMD ["emacs", "-nw"]

# Label
LABEL org.opencontainers.image.source="https://github.com/danrobi11/emacs-fedora-dynamic" \
      org.opencontainers.image.description="Emacs master built dynamically on Fedora 45 (terminal, pdumper)" \
      org.opencontainers.image.licenses="GPL-3.0"
