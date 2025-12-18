# Build argument for base image selection
ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# Stage 1: Base image with common dependencies
FROM ${BASE_IMAGE} AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv (latest) using official installer and create isolated venv
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv

# Use the virtual environment for all subsequent commands
ENV PATH="/opt/venv/bin:${PATH}"

# Install comfy-cli + dependencies needed by it to install ComfyUI
RUN uv pip install comfy-cli pip setuptools wheel

# Install ComfyUI non-interactively (echo "n\ny" for tracking and install prompts)
RUN echo -e "n\ny" | comfy --workspace /comfyui install

# Change working directory to ComfyUI
WORKDIR /comfyui

# Установка ComfyUI-Manager через comfy node install
RUN comfy node install ComfyUI-Manager

# Установка custom nodes через comfy node install
RUN comfy node install comfyui_ipadapter_plus
RUN comfy node install comfyui-base64-to-image

# Установка дополнительных библиотек (с headless для OpenCV)
RUN uv pip install opencv-python-headless "insightface==0.7.3" onnxruntime

# Настройка offline-режима для ComfyUI-Manager
RUN mkdir -p user/default/ComfyUI-Manager && \
    echo "[default]" > user/default/ComfyUI-Manager/config.ini && \
    echo "network_mode = offline" >> user/default/ComfyUI-Manager/config.ini

ENV CVT="8894b6af3f93a899ba9d2f268ddc45aa"

# Создание директорий для моделей (из вашего Dockerfile)
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
