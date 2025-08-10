# Multi-stage Dockerfile for ZSH Terminal Installation Script Testing
# This Dockerfile creates a containerized environment for testing the installation script
# across different Linux distributions

# Base stage with common dependencies
FROM ubuntu:22.04 as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color

# Install base dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    sudo \
    locales \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Generate locales
RUN locale-gen en_US.UTF-8

# Create a non-root user for testing
RUN useradd -m -s /bin/bash -G sudo testuser && \
    echo 'testuser:testuser' | chpasswd && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Ubuntu testing stage
FROM base as ubuntu-test

LABEL maintainer="ZSH Terminal Project"
LABEL description="Ubuntu environment for testing ZSH installation script"
LABEL version="1.0"

# Install Ubuntu-specific packages
RUN apt-get update && apt-get install -y \
    zsh \
    bats \
    shellcheck \
    fontconfig \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy the project files
COPY --chown=testuser:testuser . /home/testuser/zsh-terminal/

# Make scripts executable
RUN chmod +x /home/testuser/zsh-terminal/install.sh

# Set working directory
WORKDIR /home/testuser/zsh-terminal

# Default command
CMD ["bash"]

# Fedora testing stage
FROM fedora:38 as fedora-test

LABEL maintainer="ZSH Terminal Project"
LABEL description="Fedora environment for testing ZSH installation script"
LABEL version="1.0"

# Set environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color

# Install Fedora dependencies
RUN dnf update -y && dnf install -y \
    bash \
    curl \
    wget \
    git \
    sudo \
    zsh \
    fontconfig \
    unzip \
    which \
    && dnf clean all

# Install BATS and ShellCheck
RUN dnf install -y \
    bats \
    ShellCheck \
    && dnf clean all

# Create test user
RUN useradd -m -s /bin/bash -G wheel testuser && \
    echo 'testuser:testuser' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy the project files
COPY --chown=testuser:testuser . /home/testuser/zsh-terminal/

# Make scripts executable
RUN chmod +x /home/testuser/zsh-terminal/install.sh

# Set working directory
WORKDIR /home/testuser/zsh-terminal

# Default command
CMD ["bash"]

# Arch Linux testing stage
FROM archlinux:latest as arch-test

LABEL maintainer="ZSH Terminal Project"
LABEL description="Arch Linux environment for testing ZSH installation script"
LABEL version="1.0"

# Set environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color

# Update package database and install dependencies
RUN pacman -Syu --noconfirm && pacman -S --noconfirm \
    bash \
    curl \
    wget \
    git \
    sudo \
    zsh \
    fontconfig \
    unzip \
    which \
    base-devel

# Install AUR helper (yay) for additional packages
RUN pacman -S --noconfirm git base-devel && \
    git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si --noconfirm && \
    rm -rf /tmp/yay

# Install BATS and ShellCheck
RUN pacman -S --noconfirm \
    bats \
    shellcheck

# Create test user
RUN useradd -m -s /bin/bash -G wheel testuser && \
    echo 'testuser:testuser' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy the project files
COPY --chown=testuser:testuser . /home/testuser/zsh-terminal/

# Make scripts executable
RUN chmod +x /home/testuser/zsh-terminal/install.sh

# Set working directory
WORKDIR /home/testuser/zsh-terminal

# Default command
CMD ["bash"]

# Development stage with all tools
FROM ubuntu:22.04 as development

LABEL maintainer="ZSH Terminal Project"
LABEL description="Development environment with all testing tools"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color

# Install comprehensive development dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    sudo \
    zsh \
    bats \
    shellcheck \
    fontconfig \
    unzip \
    python3 \
    python3-pip \
    nodejs \
    npm \
    vim \
    nano \
    tree \
    htop \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools for development
RUN pip3 install \
    pre-commit \
    bandit \
    yamllint

# Install Node.js tools for documentation
RUN npm install -g \
    markdownlint-cli \
    markdown-link-check

# Generate locales
RUN locale-gen en_US.UTF-8

# Create development user
RUN useradd -m -s /bin/bash -G sudo developer && \
    echo 'developer:developer' | chpasswd && \
    echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to development user
USER developer
WORKDIR /home/developer

# Copy the project files
COPY --chown=developer:developer . /home/developer/zsh-terminal/

# Make scripts executable
RUN chmod +x /home/developer/zsh-terminal/install.sh

# Set working directory
WORKDIR /home/developer/zsh-terminal

# Install pre-commit hooks
RUN git init . && \
    pre-commit install || echo "Pre-commit hooks installation skipped"

# Create useful aliases for development
RUN echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -A"' >> ~/.bashrc && \
    echo 'alias l="ls -CF"' >> ~/.bashrc && \
    echo 'alias test-script="bats tests/"' >> ~/.bashrc && \
    echo 'alias lint-script="shellcheck install.sh lib/*.sh"' >> ~/.bashrc && \
    echo 'alias check-all="pre-commit run --all-files"' >> ~/.bashrc

# Default command
CMD ["bash"]

# Production-ready minimal stage
FROM alpine:3.18 as minimal

LABEL maintainer="ZSH Terminal Project"
LABEL description="Minimal Alpine environment for basic testing"
LABEL version="1.0"

# Install minimal dependencies
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    zsh \
    sudo \
    shadow

# Create test user
RUN adduser -D -s /bin/bash testuser && \
    echo 'testuser:testuser' | chpasswd && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy only essential files
COPY --chown=testuser:testuser install.sh /home/testuser/
COPY --chown=testuser:testuser config/ /home/testuser/config/
COPY --chown=testuser:testuser lib/ /home/testuser/lib/

# Make script executable
RUN chmod +x /home/testuser/install.sh

# Default command
CMD ["./install.sh", "--help"]

# Default stage (development)
FROM development as default