# Use Windows Server Core base image with Python (you may adjust tag as per availability)
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Build argument for Google Drive link
ARG GDRIVE_LINK

# Install Chocolatey for package management
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python3 and unzip, curl
RUN choco install python --version=3.11.4 -y; `
    choco install 7zip -y; `
    choco install curl -y; `
    refreshenv

# Add Python to PATH
ENV PATH="C:\\Python311;C:\\Python311\\Scripts;${PATH}"

WORKDIR /app

# Download gdown to download from Google Drive (install via pip)
RUN python -m pip install --upgrade pip
RUN python -m pip install gdown pm2

# Download zip from Google Drive and extract it
RUN powershell -Command `
    $link = '${env:GDRIVE_LINK}'; `
    if (-not $link) { throw 'GDRIVE_LINK build arg missing!'; } `
    $fileId = ($link -split '/')[5]; `
    Write-Host "Extracted File ID: $fileId"; `
    python -m gdown --id $fileId -O project.zip; `
    7z x project.zip -oC:\\app -y; `
    Remove-Item project.zip

# Install project requirements if requirements.txt exists in /app
RUN if (Test-Path .\\requirements.txt) { python -m pip install -r requirements.txt }

# Create input and output folders if not exist
RUN New-Item -ItemType Directory -Path .\\input -ErrorAction SilentlyContinue; `
    New-Item -ItemType Directory -Path .\\Blender\\output -Force

# Expose Flask port
EXPOSE 5000

# Run the docker_api.py using pm2 (pm2 is installed via pip above)
CMD ["pm2", "start", "docker_api.py", "--interpreter", "python", "--no-daemon"]
