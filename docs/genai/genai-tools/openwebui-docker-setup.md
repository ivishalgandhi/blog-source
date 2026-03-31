---
sidebar_position: 1
title: Setting Up Open WebUI with Docker
---

# Setting Up Open WebUI with Docker

This step-by-step guide will walk you through setting up Open WebUI with Docker and configuring it to work with locally running Ollama models, with data persistence for both services.

## Prerequisites

Before you begin, make sure you have:

- Docker and Docker Compose installed on your system
- Basic understanding of Docker concepts
- At least 10GB of free disk space (varies based on which models you'll use)

## Step 1: Understand the Components

1. **Open WebUI**: An open-source chat interface for AI models
   - Provides a user-friendly interface similar to ChatGPT
   - Can connect to local LLM solutions like Ollama
   - [Official GitHub Repository](https://github.com/open-webui/open-webui)

2. **Ollama**: A framework for running large language models locally
   - Provides a simple API to interact with models
   - Handles model management and optimization
   - [Official Website](https://ollama.com/)

## Step 2: Create the Docker Compose File

1. Create a new directory for your project:
   ```bash
   mkdir openwebui-ollama
   cd openwebui-ollama
   ```

2. Create a `docker-compose.yml` file with the following configuration:
   ```yaml
   version: '3'

   services:
     openwebui:
       image: ghcr.io/open-webui/open-webui:main
       restart: always
       ports:
         - "3000:8080"
       volumes:
         - ./openwebui_data:/app/backend/data

     ollama:
       image: ollama/ollama:latest
       ports:
         - "11434:11434"
       volumes:
         - ./ollama_data:/root/.ollama
   ```

3. Understanding the configuration:
   - **Open WebUI Service**:
     - Uses the official Docker image from GitHub Container Registry
     - Maps port 3000 on your host to port 8080 in the container
     - Persists data in a local `./openwebui_data` directory
     - Set to automatically restart if it crashes

   - **Ollama Service**:
     - Uses the official Ollama Docker image
     - Exposes port 11434 for API access
     - Stores models and configuration in `./ollama_data` directory

## Step 3: Launch the Services

1. Start the services by running:
   ```bash
   docker-compose up -d
   ```

2. Verify both containers are running:
   ```bash
   docker-compose ps
   ```

3. Wait for the containers to download and start (this may take a few minutes depending on your internet connection).

## Step 4: Access Open WebUI

1. Open a web browser and navigate to:
   ```
   http://localhost:3000
   ```

2. You should see the Open WebUI interface.

## Step 5: Connect Open WebUI to Ollama

1. In the Open WebUI interface, go to Settings > LLM Providers

2. Select Ollama as your provider

3. Set the API endpoint to `http://ollama:11434` (this uses Docker's internal DNS)

4. Click "Test Connection" to verify it works

5. Save your settings

## Step 6: Install AI Models

### Example Model: Mistral 7B

For this tutorial, we'll use Mistral 7B as our example model. It's an excellent choice for local deployment because:

- **Balanced size and performance**: At 7 billion parameters, it offers good performance while being manageable on consumer hardware
- **Efficient resource usage**: Requires approximately 4-6GB of VRAM when running
- **Good capabilities**: Handles reasoning, code generation, and general text tasks well
- **Fast responses**: Generates text at reasonable speeds even on consumer hardware

### Option A: Using the Ollama CLI

1. Access the Ollama container:
   ```bash
   docker exec -it $(docker ps -q --filter name=ollama) /bin/bash
   ```

2. Pull the Mistral 7B model:
   ```bash
   ollama pull mistral
   ```
   This will download approximately 4.1GB of data

3. You can verify the model was installed correctly:
   ```bash
   ollama list
   ```

4. Exit the container:
   ```bash
   exit
   ```

### Option B: Using Open WebUI Interface

1. Navigate to the Models section in Open WebUI

2. Find "mistral" in the available models list and click Download

3. Wait for the download to complete (about 4.1GB)

4. After installation, the model will appear in your available models list

## Step 7: Start Chatting

1. Select your downloaded model from the model dropdown

2. Start a new conversation

3. Enter prompts and interact with the AI

## Step 8: Understand Data Persistence

1. Your data is stored in two locations:
   - `./openwebui_data` - for conversations, settings, and Open WebUI configurations
   - `./ollama_data` - for AI models and Ollama configurations

2. These directories will persist your data even if you restart or rebuild the containers.

## Troubleshooting

### Connection Issues

If Open WebUI can't connect to Ollama:

1. Verify both containers are running:
   ```bash
   docker-compose ps
   ```

2. Check if the Ollama API endpoint is set correctly in Open WebUI settings

3. Ensure there are no firewall rules blocking the connections

### Model Download Failures

If model downloads fail:

1. Check your internet connection

2. Ensure you have enough disk space

3. Try downloading a smaller model first to test

## Upgrading

To upgrade to newer versions:

1. Pull the latest images:
   ```bash
   docker-compose pull
   ```

2. Restart the services with the new images:
   ```bash
   docker-compose up -d
   ```

## Step 9: Backup and Restore

### Backing Up Your Data

1. Stop the running containers (this ensures data integrity during backup):
   ```bash
   docker-compose down
   ```

2. Create a compressed backup of your data directories:
   ```bash
   tar -czvf openwebui-backup-$(date +%Y%m%d).tar.gz openwebui_data ollama_data
   ```

3. Verify the backup was created successfully:
   ```bash
   ls -la openwebui-backup-*.tar.gz
   ```

4. Store the backup file in a secure location (cloud storage, external drive, etc.)

5. Restart your services:
   ```bash
   docker-compose up -d
   ```

### Restoring on Another Machine

1. Install Docker and Docker Compose on the new machine

2. Create a new directory for your OpenWebUI setup:
   ```bash
   mkdir openwebui-ollama
   cd openwebui-ollama
   ```

3. Copy your `docker-compose.yml` file to this directory

4. Copy your backup file to this directory and extract it:
   ```bash
   tar -xzvf openwebui-backup-YYYYMMDD.tar.gz
   ```

5. Verify the data directories were restored correctly:
   ```bash
   ls -la openwebui_data ollama_data
   ```

6. Start the services:
   ```bash
   docker-compose up -d
   ```

7. Verify everything is working by accessing Open WebUI at `http://localhost:3000`

### Important Notes on Backups

1. **Schedule Regular Backups**: For important data, consider setting up a cron job to automate backups

2. **Large Model Files**: Be aware that Ollama model files can be several gigabytes in size. If you have limited bandwidth or storage:
   - Consider backing up only the OpenWebUI data: `tar -czvf openwebui-config-backup.tar.gz openwebui_data`
   - Re-download models on the new machine instead of transferring them

3. **Version Compatibility**: When restoring, ensure you're using compatible versions of OpenWebUI and Ollama

## Advanced Configuration

For more advanced setups, you can modify the Docker Compose file to:
- Change ports
- Add environment variables
- Implement custom networking
- Add authentication

Check the official documentation for [Open WebUI](https://github.com/open-webui/open-webui) and [Ollama](https://github.com/ollama/ollama) for more configuration options.
