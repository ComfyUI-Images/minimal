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
    python3.12 python3.12-venv python3-pip \
    git wget libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 ffmpeg \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip
# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
# Create virtual environment to avoid externally-managed-environment error
RUN python -m venv /opt/venv
# Activate venv
ENV PATH="/opt/venv/bin:${PATH}"
# Manual installation of ComfyUI (since comfy install is interactive)
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt
# Change working directory to ComfyUI
WORKDIR /comfyui
# Manual installation of ComfyUI-Manager as custom node
RUN mkdir -p custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager && \
    pip install -r custom_nodes/ComfyUI-Manager/requirements.txt
# Install comfy-cli for custom node installation via CLI
RUN pip install comfy-cli comfyui_manager

RUN comfy --skip-prompt --no-enable-telemetry tracking disable

#
#    Base ComfyUI installation end
#

RUN apt-get update && apt-get install -y curl \
    build-essential cmake libopenblas-dev liblapack-dev libjpeg-dev libpng-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

RUN pip install opencv-python "insightface==0.7.3" onnxruntime

# install nodes
RUN comfy node install --exit-on-fail comfyui_ipadapter_plus@2.0.0
RUN comfy node install --exit-on-fail comfyui-base64-to-image@1.0.0

RUN mkdir -p /comfyui/models/checkpoints /comfyui/models/loras /comfyui/models/ipadapter /comfyui/models/clip_vision

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o /comfyui/models/checkpoints/pornmaster_proSDXLV7.safetensors \
    "https://civitai.com/api/download/models/2043971?type=Model&format=SafeTensor&size=pruned&fp=fp16"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o /comfyui/models/loras/Seductive_Expression_SDXL-000040.safetensors \
    "https://civitai.com/api/download/models/2188184?type=Model&format=SafeTensor"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L -H "Authorization: Bearer ${CVT}" \
    -o /comfyui/models/loras/Seductive_Finger_Lips_Expression_SDXL-000046.safetensors \
    "https://civitai.com/api/download/models/2277333?type=Model&format=SafeTensor"

# === CLIP-VISION MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/clip_vision/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors"

# === SDXL IPADAPTER MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter-plus-face_sdxl_vit-h.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter_sdxl.safetensors \
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter_sdxl.safetensors"

# === FACEID PLUS V2 MODELS ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter-faceid-plusv2_sd15.bin \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15.bin"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/ipadapter/ip-adapter-faceid-plusv2_sdxl.bin \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin"

# === FACEID PLUS V2 LoRAs ===
RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/loras/ip-adapter-faceid-plusv2_sd15_lora.safetensors \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sd15_lora.safetensors"

RUN curl --fail --retry 5 --retry-max-time 0 -C - -L \
    -o /comfyui/models/loras/ip-adapter-faceid-plusv2_sdxl_lora.safetensors \
    "https://huggingface.co/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl_lora.safetensors"

# Экспонирование порта
EXPOSE 8188
# Запуск сервера (с включением Manager; custom nodes can be installed via 'comfy node install NAME' in runtime)
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager"]
