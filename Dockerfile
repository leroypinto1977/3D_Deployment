# Use Ubuntu as the base image
FROM ubuntu:22.04

# Set non-interactive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Build argument for Google Drive link
ARG GDRIVE_LINK

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    curl \
    unzip \
    wget \
    && apt-get clean

# Symlink python3.11 as default python and pip
RUN ln -s /usr/bin/python3.11 /usr/bin/python && ln -s /usr/bin/pip3 /usr/bin/pip

# Set working directory
WORKDIR /app

# Install Python packages
RUN pip install --upgrade pip
RUN pip install gdown pm2

# Download zip from Google Drive and extract
RUN if [ -z "$GDRIVE_LINK" ]; then echo "GDRIVE_LINK build arg missing!" && exit 1; fi && \
    FILE_ID=$(echo "$GDRIVE_LINK" | cut -d'/' -f6) && \
    echo "Extracted File ID: $FILE_ID" && \
    gdown --id "$FILE_ID" -O project.zip && \
    unzip project.zip -d /app && \
    rm project.zip

# Install project requirements if requirements.txt exists
RUN if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# Create input and output folders
RUN mkdir -p /app/input /app/Blender/output

# Expose Flask port
EXPOSE 5000

# Start using pm2
CMD ["pm2", "start", "docker_api.py", "--interpreter", "python", "--no-daemon"]
