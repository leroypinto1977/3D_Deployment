FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Build argument for Google Drive link
ARG GDRIVE_LINK

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    wget \
    unzip \
    git \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    python3-pip \
    && apt-get clean

# Install pyenv to manage multiple Python versions
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN curl https://pyenv.run | bash && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Install Python 3.7.17 and 3.11.4 via pyenv
RUN /bin/bash -c "pyenv install 3.7.17 && pyenv install 3.11.4 && pyenv global 3.11.4"

# Upgrade pip and install uv globally (we’ll use the latest Python interpreter)
RUN python3.11 -m pip install --upgrade pip && \
    pip install uv

# Set working directory
WORKDIR /app

# Install gdown via uv
RUN uv venv && \
    uv pip install gdown pm2

# Download zip from Google Drive and extract
RUN if [ -z "$GDRIVE_LINK" ]; then echo "GDRIVE_LINK build arg missing!" && exit 1; fi && \
    FILE_ID=$(echo "$GDRIVE_LINK" | cut -d'/' -f6) && \
    echo "Extracted File ID: $FILE_ID" && \
    uv pip run gdown --id "$FILE_ID" -O project.zip && \
    unzip project.zip -d /app && \
    rm project.zip

# Install requirements via uv (with resolution across multiple versions)
RUN if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi

# Create input/output folders
RUN mkdir -p /app/input /app/Blender/output

# Expose Flask port
EXPOSE 5000

# Start using pm2
CMD ["pm2", "start", "docker_api.py", "--interpreter", "python", "--no-daemon"]
