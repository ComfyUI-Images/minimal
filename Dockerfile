FROM nvidia/cuda:13.0.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CVT="8894b6af3f93a899ba9d2f268ddc45aa"

# Установка базовых пакетов (добавлено из вашего Dockerfile)
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

# Обновление pip для фикса ошибки в resolver (AssertionError в weights)
RUN pip3 install --upgrade pip

# Установка PyTorch с CUDA 13.0 (compatible with runtime)
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# Клонирование ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI /app/ComfyUI

WORKDIR /app/ComfyUI

# Установка зависимостей ComfyUI
RUN pip3 install -r requirements.txt

# Установка comfy-cli (для node install)
RUN pip3 install comfy-cli

# Установка ComfyUI-Manager через pip
RUN pip3 install comfyui-manager

# Установка custom nodes через comfy-cli
RUN comfy --here node install comfyui_ipadapter_plus
RUN comfy --here node install comfyui-base64-to-image

# Установка дополнительных библиотек (с headless для OpenCV)
RUN pip3 install --no-cache-dir opencv-python-headless "insightface==0.7.3" onnxruntime

# Настройка offline-режима для ComfyUI-Manager, чтобы избежать фетчей при запуске
RUN mkdir -p user/default/ComfyUI-Manager && \
    echo "[default]" > user/default/ComfyUI-Manager/config.ini && \
    echo "network_mode = offline" >> user/default/ComfyUI-Manager/config.ini

# Создание директорий для моделей
RUN mkdir -p models/checkpoints models/loras models/ipadapter models/clip_vision

# Скачивание моделей (все curl из вашего Dockerfile)
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
