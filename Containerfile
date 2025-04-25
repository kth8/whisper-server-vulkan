FROM almalinux:9-minimal AS builder

RUN microdnf -y install vulkan-loader-devel glslc git gcc-c++ cmake make

RUN git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git

RUN cmake whisper.cpp \
    -B whisper.cpp/build \
    -DGGML_VULKAN=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2" \
    -DCMAKE_CXX_FLAGS="-march=sandybridge -mtune=generic -mno-avx -mno-avx2 -mno-bmi -mno-bmi2"

RUN cmake --build whisper.cpp/build -j --target whisper-server

RUN ldd whisper.cpp/build/bin/whisper-server

FROM almalinux:9-minimal

ARG MODEL

RUN microdnf -y install mesa-vulkan-drivers libgomp && \
    microdnf clean all && \
    rm -rf /var/cache/dnf

COPY --from=builder /whisper.cpp/build/bin/whisper-server .
COPY ${MODEL} .

CMD ["/whisper-server", "-m", "ggml-small.en-q8_0.bin", "--host", "0.0.0.0"]
