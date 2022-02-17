ARG P4C_COMMIT
ARG PROTOBUF_VERSION
ARG MAKEFLAGS=-j2

# 2 stage-build. A first alpine image is used to build protobuf and p4c.
# Finally, the given p4c binaries are copied to a new image with the required
# libraries.

FROM bitnami/minideb:stretch as builder

ARG P4C_COMMIT
ARG PROTOBUF_VERSION
ARG MAKEFLAGS

# Build and install protobuf...
RUN install_packages \
    autoconf \
    automake \
    libtool \
    curl \
    make \
    g++ \
    unzip \
    ca-certificates
ENV PROTOBUF_URL https://github.com/google/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-cpp-$PROTOBUF_VERSION.tar.gz
RUN curl -L -o /tmp/protobuf.tar.gz $PROTOBUF_URL
WORKDIR /tmp/
RUN tar xvzf protobuf.tar.gz
WORKDIR /tmp/protobuf-$PROTOBUF_VERSION
RUN ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make check && \
    make install-strip

# Build and install p4c...
ENV BUILD_DEPS \
    bison \
    build-essential \
    cmake \
    curl \
    flex \
    g++ \
    git \
    libboost1.62-dev \
    libboost-graph1.62-dev \
    libboost-iostreams1.62-dev \
    libfl-dev \
    libgc-dev \
    libgmp-dev \
    pkg-config \
    tcpdump \
    python3
RUN install_packages $BUILD_DEPS
RUN git clone https://github.com/p4lang/p4c.git /tmp/p4c && cd /tmp/p4c && \
    git checkout $P4C_COMMIT && git submodule update --init --recursive
RUN mkdir -p /tmp/p4c/build
WORKDIR /tmp/p4c/build
RUN cmake .. '-DCMAKE_CXX_FLAGS:STRING=-O3' '-DCMAKE_INSTALL_PREFIX=/usr' \
        '-DENABLE_EBPF=OFF' '-DENABLE_P4TEST=FALSE' '-DENABLE_GTESTS=FALSE' \
        '-DENABLE_PROTOBUF_STATIC=OFF'
RUN make VERBOSE=1
# FIXME: ebpf-related tests fail even if we are not building that backend
# RUN make check
RUN make install

# Runtime stage
FROM bitnami/minideb:stretch AS runtime

LABEL maintainer="Carmelo Cascone <carmelo@opennetworking.org>"
LABEL description="Minimal distribution of the P4 compiler with BMv2 simple_switch backend (p4c-bm2-ss)"

ARG P4C_COMMIT
ARG PROTOBUF_VERSION

LABEL protobuf-version="$PROTOBUF_VERSION"
LABEL p4c-commit="$P4C_COMMIT"

# cpp is used by p4c to pre-process P4 sources. graphviz is optional but it's
# nice to have to convert the output of p4c-graphs to pdfs.
ENV RUNTIME_DEPS \
    cpp \
    graphviz \
    libboost-graph1.62.0 \
    libboost-iostreams1.62.0 \
    libgc1c2 \
    libgmp10 \
    libgmpxx4ldbl
RUN install_packages $RUNTIME_DEPS

COPY --from=builder /usr/bin/p4c-bm2-ss /bin/
COPY --from=builder /usr/bin/p4c-graphs /bin/
COPY --from=builder /usr/bin/p4c-dpdk /bin/
COPY --from=builder /usr/lib/libprotobuf.so.*.0.0 /usr/lib/
COPY --from=builder /usr/share/p4c/p4include /usr/share/p4c/p4include
RUN ldconfig

WORKDIR /
