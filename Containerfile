FROM debian:latest AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y libvulkan-dev glslc cmake git build-essential

RUN git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git

WORKDIR /whisper.cpp

RUN cmake -B build \
    -DGGML_VULKAN=1 \
    -DCMAKE_C_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2" \
    -DCMAKE_CXX_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2"

RUN cmake --build build -j --config whisper-server

RUN ldd /whisper.cpp/build/bin/whisper-server

FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt update && \
    apt install -y mesa-vulkan-drivers libgomp1 --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /whisper.cpp/build/bin/whisper-server .
COPY --from=builder /whisper.cpp/build/src/libwhisper.so.1 .
COPY --from=builder /whisper.cpp/build/ggml/src/libggml.so .
COPY --from=builder /whisper.cpp/build/ggml/src/libggml-base.so .
COPY --from=builder /whisper.cpp/build/ggml/src/libggml-cpu.so .
COPY --from=builder /whisper.cpp/build/ggml/src/ggml-vulkan/libggml-vulkan.so .

COPY ggml-medium-q8_0.bin .

CMD ["/app/whisper-server", "-m", "ggml-medium-q8_0.bin", "--host", "0.0.0.0"]
