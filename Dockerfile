# Адаптированный Dockerfile с элементами из официального RunPod worker-comfyui: использование uv для venv, comfy install для ComfyUI, comfy node install для custom nodes и Manager.

FROM nvidia/cuda:13.0.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CVT="8894b6af3f93a899ba9d2f268ddc45aa"

# Установка базовых пакетов, включая libgl1 и libglib2.0-0 из RunPod
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-venv \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    libjpeg-dev \
    libpng-dev \
    pkg-config \
    python3-dev \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Установка uv из RunPod (для быстрой установки pip)
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv

# Активация venv
ENV PATH="/opt/venv/bin:${PATH}"

# Установка comfy-cli через uv
RUN uv pip install comfy-cli pip setuptools wheel

# Установка ComfyUI через comfy-cli (с --nvidia для CUDA)
RUN comfy install --workspace /app/ComfyUI --nvidia

# Переход в директорию ComfyUI (как в RunPod)
WORKDIR /app/ComfyUI

# Установка ComfyUI-Manager через comfy node install
RUN comfy node install ComfyUI-Manager

# Установка custom nodes через comfy node install (без @version, так как они не поддерживаются)
RUN comfy node install ComfyUI_IPAdapter_plus
RUN comfy node install comfyui-base64-to-image

# Установка дополнительных библиотек через uv (с headless для OpenCV)
RUN uv pip install opencv-python-headless "insightface==0.7.3" onnxruntime

# Настройка offline-режима для ComfyUI-Manager
RUN mkdir -p user/default/ComfyUI-Manager && \
    echo "[default]" > user/default/ComfyUI-Manager/config.ini && \
    echo "network_mode = offline" >> user/default/ComfyUI-Manager/config.ini

# Создание директорий для моделей
RUN mkdir -p models/checkpoints models/loras models/ipadapter models/clip_vision

# Скачивание моделей (curl из вашего Dockerfile)
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o models/checkpoints/pornmaster_proSDXLV7.safetensors \
    "https://civitai.com/api/download/models/2043971?type=Model&format=SafeTensor&size=pruned&fp=fp16"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o models/loras/Seductive_Expression_SDXL-000040.safetensors \
    "https://civitai.com/api/download/models/2188184?type=Model&format=SafeTensor"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o models/loras/Seductive_Finger_Lips_Expression_SDXL-000046.safetensors \
    "https://civitai.com/api/download/models/2277333?type=Model&format=SafeTensor"

# === CLIP-VISION MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/clip_vision/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors"

# === SDXL IPADAPTER MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter_sdxl.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl.safetensors"

# === FACEID PLUS V2 MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter-faceid-plusv2_sd15.bin \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15.bin"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/ipadapter/ip-adapter-faceid-plusv2_sdxl.bin \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin"

# === FACEID PLUS V2 LoRAs ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/loras/ip-adapter-faceid-plusv2_sd15_lora.safetensors \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15_lora.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o models/loras/ip-adapter-faceid-plusv2_sdxl_lora.safetensors \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl_lora.safetensors"

# Монтирование persistent storage (RunPod использует /workspace)
VOLUME /workspace

# Экспонирование порта
EXPOSE 8188

# Запуск сервера (с включением Manager)
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager"]
