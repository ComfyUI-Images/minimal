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
RUN pip install comfy-cli

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

# Экспонирование порта
EXPOSE 8188
# Запуск сервера (с включением Manager; custom nodes can be installed via 'comfy node install NAME' in runtime)
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager"]
