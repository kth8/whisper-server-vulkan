FROM ubuntu:24.04 AS builder

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    git \
    glslc \
    libvulkan-dev \
    pkg-config \
    curl \
    libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git

RUN cmake whisper.cpp \
    -B whisper.cpp/build \
    -DGGML_VULKAN=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2" \
    -DCMAKE_CXX_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2"

RUN cmake --build whisper.cpp/build --target whisper-server -j"$(nproc)"

FROM ubuntu:24.04

WORKDIR /app

ARG MODEL

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgomp1 \
    libvulkan1 \
    mesa-vulkan-drivers && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/whisper.cpp/build/bin/whisper-server /usr/local/bin/whisper-server

COPY ${MODEL} .

EXPOSE 8080

CMD ["whisper-server", "-m", "ggml-large-v3-turbo-q8_0.bin", "--host", "0.0.0.0", "--port", "8080", "--inference-path", "/v1/audio/transcriptions"]
