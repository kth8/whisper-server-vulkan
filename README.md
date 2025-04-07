[whisper.cpp server](https://github.com/ggml-org/whisper.cpp/tree/master/examples/server) and [ggml-medium-q8_0.bin](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-medium-q8_0.bin) model bundled together inside a Docker image. Compiled with Vulkan support and without AVX requirement to run on old hardware. Tested using [i3-3220 CPU](https://www.intel.com/content/www/us/en/products/sku/65693/intel-core-i33220-processor-3m-cache-3-30-ghz/specifications.html?q=CM8063701137502) with [RX 470 GPU](https://www.techpowerup.com/gpu-specs/radeon-rx-470.c2861) running Fedora Linux.

```
docker container run \
  --detach \
  --init \
  --device /dev/kfd \
  --device /dev/dri \
  --read-only \
  --tmpfs /root/.cache/mesa_shader_cache \
  --restart always \
  --name whisper \
  --label io.containers.autoupdate=registry \
  --publish 8002:8080 \
  ghcr.io/kth8/whisper-server-vulkan:latest
```
Verify if the server is running by going to http://127.0.0.2:8001 in your web browser.
