FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="${CARGO_HOME}/bin:/usr/local/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    cmake \
    nasm \
    git \
    curl \
    wget \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ffmpeg \
    x264 \
    mkvtoolnix \
    mediainfo \
    jq \
    libffms2-dev \
    libffms2-5 \
    autoconf \
    automake \
    libtool \
    cython3 \
    bc \
    llvm \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch release-3.0.5 https://github.com/sekrit-twc/zimg.git /tmp/zimg \
    && cd /tmp/zimg \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --prefix=/usr/local \
    && make -j $(nproc) \
    && make install \
    && ldconfig \
    && rm -rf /tmp/zimg

RUN git clone --depth 1 --branch R70 https://github.com/vapoursynth/vapoursynth.git /tmp/vapoursynth \
    && cd /tmp/vapoursynth \
    && ./autogen.sh \
    && ./configure --prefix=/usr/local \
    && make -j $(nproc) \
    && make install \
    && ldconfig \
    && cd /tmp/vapoursynth \
    && pip3 install --break-system-packages . \
    && rm -rf /tmp/vapoursynth

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN pip3 install --break-system-packages \
    vsjetpack numpy rich vstools psutil

RUN git clone https://github.com/5fish/svt-av1-psy /tmp/svt-av1-psy \
    && cd /tmp/svt-av1-psy \
    && mkdir -p Build/linux && cd Build/linux \
    && cmake ../.. -G"Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DSVT_AV1_PGO=ON \
        -DSVT_AV1_LTO=ON \
    && make -j $(nproc) \
    && make install \
    && rm -rf /tmp/svt-av1-psy

RUN cargo install --git https://github.com/rust-av/Av1an.git

RUN cargo install --git https://github.com/gianni-rosato/fssimu2.git

RUN git clone https://github.com/dubhater/vapoursynth-wwxd.git /tmp/wwxd \
    && cd /tmp/wwxd \
    && gcc -o libwwxd.so -fPIC -shared -O3 -Wall -Wextra \
        -I. -I/usr/local/include/vapoursynth src/*.c -lm \
    && mkdir -p /usr/local/lib/vapoursynth \
    && cp libwwxd.so /usr/local/lib/vapoursynth/ \
    && rm -rf /tmp/wwxd

RUN cp /usr/lib/x86_64-linux-gnu/libffms2.so /usr/local/lib/vapoursynth/ 2>/dev/null || \
    find /usr -name "libffms2*.so*" -exec cp {} /usr/local/lib/vapoursynth/ \; 2>/dev/null || true

RUN git clone https://github.com/abdulrahmanx9/Auto-Boost-Av1an-Linux.git /app

COPY encode.sh /app/encode.sh
RUN chmod +x /app/encode.sh && chmod +x /app/*.sh

WORKDIR /app

ENTRYPOINT ["/app/encode.sh"]
