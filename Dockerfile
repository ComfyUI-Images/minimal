# Build argument for base image selection
ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# Base image
FROM ${BASE_IMAGE}

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Manual installation of ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI /comfyui && \
    cd /comfyui && \
    pip install -r requirements.txt

# Change working directory to ComfyUI
WORKDIR /comfyui

# Manual installation of ComfyUI-Manager as custom node (for CLI support with comfy node install)
RUN mkdir -p custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager && \
    pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# Install comfy-cli for custom node management via CLI
RUN pip install comfy-cli

# Экспонирование порта
EXPOSE 8188

# Запуск сервера (с включением Manager; custom nodes can be installed via 'comfy node install NAME' in runtime)
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager"]
