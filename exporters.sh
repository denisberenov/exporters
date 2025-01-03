#!/bin/bash

# Step 1: Provisioning (from the original provisioning script)

# Namespace functions with provisioning_
# https://raw.githubusercontent.com/ai-dock/stable-diffusion-webui/main/config/provisioning/default.sh

### Edit the following arrays to suit your workflow - values must be quoted and separated by newlines or spaces.
################## DEBUG ONLY
OS_NAME="$(uname)"
if [[ "$OS_NAME" == "Darwin" ]]; then
    # macOS
    WORKSPACE_DIR="$HOME/workspace"
    echo "Operating System: macOS"
else
    # Assume Linux
    WORKSPACE_DIR="/workspace"
    echo "Operating System: Linux"
fi
echo "Workspace directory set to $WORKSPACE_DIR."

# Display current file system status
if [ -d "$WORKSPACE_DIR/stable-diffusion-webui" ]; then
    ls -l "$WORKSPACE_DIR/stable-diffusion-webui" >> "$WORKSPACE_DIR/workspace_contents.txt"
else
    echo "Directory $WORKSPACE_DIR/stable-diffusion-webui does not exist." >> "$WORKSPACE_DIR/workspace_contents.txt"
fi

if [ -d "$WORKSPACE_DIR/stable-diffusion-webui/models" ]; then
    ls -l "$WORKSPACE_DIR/stable-diffusion-webui/models" >> "$WORKSPACE_DIR/workspace_contents.txt"
else
    echo "Directory $WORKSPACE_DIR/stable-diffusion-webui/models does not exist." >> "$WORKSPACE_DIR/workspace_contents.txt"
fi

if [ -d "$WORKSPACE_DIR/stable-diffusion-webui/extensions" ]; then
    ls -l "$WORKSPACE_DIR/stable-diffusion-webui/extensions" >> "$WORKSPACE_DIR/workspace_contents.txt"
else
    echo "Directory $WORKSPACE_DIR/stable-diffusion-webui/extensions does not exist." >> "$WORKSPACE_DIR/workspace_contents.txt"
fi

# Check if the main workspace directory exists and clone the repo if it doesn't (only on macOS)
if [[ "$OS_NAME" == "Darwin" ]] && [ ! -d "$WORKSPACE_DIR/stable-diffusion-webui" ]; then
    git clone git@github.com:AUTOMATIC1111/stable-diffusion-webui.git "$WORKSPACE_DIR/stable-diffusion-webui"
    echo "Cloned AUTOMATIC1111's stable-diffusion-webui repository into $WORKSPACE_DIR/stable-diffusion-webui."
fi
##############################

DISK_GB_REQUIRED=30

MAMBA_PACKAGES=(
    #"package1"
    #"package2=version"
  )

PIP_PACKAGES=(
    "bitsandbytes==0.41.2.post2"
  )

EXTENSIONS=(
    "https://github.com/d8ahazard/sd_dreambooth_extension"
    "https://github.com/deforum-art/sd-webui-deforum"
    "https://github.com/adieyal/sd-dynamic-prompts"
    "https://github.com/ototadana/sd-face-editor"
    "https://github.com/AlUlkesh/stable-diffusion-webui-images-browser"
    "https://github.com/hako-mikan/sd-webui-regional-prompter"
    "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111"
    "https://github.com/Gourieff/sd-webui-reactor"
    "https://github.com/ahgsql/StyleSelectorXL.git"
    "https://github.com/butaixianran/Stable-Diffusion-Webui-Civitai-Helper.git"
    "https://github.com/richrobber2/canvas-zoom.git"    
    "https://github.com/fkunn1326/openpose-editor"
    "https://github.com/vladmandic/sd-extension-steps-animation.git"
    "https://github.com/continue-revolution/sd-webui-animatediff.git"
    "https://github.com/Mikubill/sd-webui-controlnet"
    "https://github.com/harukei-tech/sd-webui-extended-style-saver.git"
    "https://github.com/cheald/sd-webui-loractl.git"
    "https://github.com/Bing-su/adetailer.git"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/moiu2998/mymo/resolve/3c3093fa083909be34a10714c93874ce5c9dabc4/realisticVisionV60B1_v51VAE.safetensors"
    "https://huggingface.co/XpucT/Deliberate/resolve/main/Deliberate_v6%20(SFW).safetensors"
)

LORA_MODELS=(
    "https://huggingface.co/XpucT/Loras/resolve/main/LowRA_v2.safetensors"
)

VAE_MODELS=(
    #"https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
)

ESRGAN_MODELS=(
    #"https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth?download=true"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    source /opt/ai-dock/etc/environment.sh
    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_mamba_packages
    provisioning_get_pip_packages
    provisioning_get_extensions
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
     
    PLATFORM_FLAGS=""
    if [[ $XPU_TARGET = "CPU" ]]; then
        PLATFORM_FLAGS="--use-cpu all --skip-torch-cuda-test --no-half"
    fi
    PROVISIONING_FLAGS="--skip-python-version-check --no-download-sd-model --do-not-download-clip --port 11404 --exit"
    FLAGS_COMBINED="${PLATFORM_FLAGS} $(cat /etc/a1111_webui_flags.conf) ${PROVISIONING_FLAGS}"
    
    # Start and exit because webui will probably require a restart
    cd /opt/stable-diffusion-webui && \
    micromamba run -n webui -e LD_PRELOAD=libtcmalloc.so python launch.py \
        ${FLAGS_COMBINED}
    provisioning_print_end
}

function provisioning_get_mamba_packages() {
    if [[ -n $MAMBA_PACKAGES ]]; then
        $MAMBA_INSTALL -n webui ${MAMBA_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
        micromamba run -n webui $PIP_INSTALL ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_extensions() {
    for repo in "${EXTENSIONS[@]}"; do
        dir="${repo##*/}"
        path="/opt/stable-diffusion-webui/extensions/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} == "true" ]]; then
                printf "Updating extension: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    micromamba -n webui run ${PIP_INSTALL} -r "$requirements"
                fi
            fi
        else
            printf "Downloading extension: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                micromamba -n webui run ${PIP_INSTALL} -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi
    
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for model in "${arr[@]}"; do
        modelname="${model##*/}"
        modelname="${modelname%?*}"
        local tmpname="${dir}/${modelname}"
        if [[ ! -f $tmpname ]]; then
            echo "Downloading model: $model"
            curl -fsSL "$model" -o "$tmpname" &
        else
            printf "File %s already exists, skipping...\n" "${model}"
        fi
    done
}

function provisioning_print_header() {
    echo "Starting provisioning..."
    echo "Workspace: $WORKSPACE"
    echo "Disk Space Available: ${DISK_GB_ALLOCATED}GB (Required: ${DISK_GB_REQUIRED}GB)"
}

function provisioning_print_end() {
    echo "Provisioning finished."
}

provisioning_start

# Step 2: Start Node Exporter
echo "Starting Node Exporter..."
/usr/local/bin/node_exporter --web.listen-address=":9100" > /workspace/node_exporter.log 2>&1 &
NODE_EXPORTER_PID=$!

# Step 3: Start Blackbox Exporter
echo "Starting Blackbox Exporter..."
cat <<EOF > /workspace/blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 5s
EOF
/usr/local/bin/blackbox_exporter --config.file=/workspace/blackbox.yml --web.listen-address=":9115" > /workspace/blackbox_exporter.log 2>&1 &
BLACKBOX_EXPORTER_PID=$!

# Step 4: Start Prometheus Aggregate Exporter
echo "Starting Prometheus Aggregate Exporter..."
/usr/local/bin/prometheus-aggregate-exporter \
  -targets http://localhost:9100/metrics,http://localhost:9115/metrics \
  -server.bind ":9095" > /workspace/prometheus_aggregate_exporter.log 2>&1 &
AGGREGATE_EXPORTER_PID=$!

# Wait for all processes
echo "Monitoring services are starting. Waiting for processes to stay active..."
wait $NODE_EXPORTER_PID $BLACKBOX_EXPORTER_PID $AGGREGATE_EXPORTER_PID
