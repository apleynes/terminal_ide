#!/bin/bash

# Terminal IDE Installation Script
# Installs modern terminal tools and development environment
# Supports macOS and Linux, user-space only (no sudo required)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default tools to install
DEFAULT_TOOLS="helix,zellij,lsp-ai,gitui,ruff,btop,yazi,fish,ripgrep,bat,hyperfine,delta,fd,eza,dust,starship,aider"

# Parse command line arguments
TOOLS="$DEFAULT_TOOLS"
SKIP_CONFIG=false
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --tools=*)
            TOOLS="${1#*=}"
            shift
            ;;
        --skip-config)
            SKIP_CONFIG=true
            shift
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        -h|--help)
            echo "Terminal IDE Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tools=TOOLS     Comma-separated list of tools to install"
            echo "  --skip-config     Skip configuration setup"
            echo "  --force           Force reinstall even if tools exist"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Default tools: $DEFAULT_TOOLS"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "aarch64"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# Create necessary directories
setup_directories() {
    log_info "Setting up directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
        export PATH="$INSTALL_DIR:$PATH"
        log_info "Added $INSTALL_DIR to PATH"
    fi
}

# Get latest GitHub release version
get_latest_github_release() {
    local repo="$1"
    local version=""
    
    if command_exists curl; then
        version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -o '"tag_name": *"[^"]*' | grep -o '[^"]*$' | sed 's/^v//')
    elif command_exists wget; then
        version=$(wget -qO- "https://api.github.com/repos/$repo/releases/latest" | grep -o '"tag_name": *"[^"]*' | grep -o '[^"]*$' | sed 's/^v//')
    fi
    
    if [[ -z "$version" ]]; then
        log_error "Failed to get latest release version for $repo"
        return 1
    fi
    
    echo "$version"
}

# Download and extract tarball with robust binary finding
download_and_extract() {
    local url="$1"
    local extract_dir="$2"
    local binary_name="$3"
    local temp_file="/tmp/$(basename "$url")"
    
    log_info "Downloading $url..."
    if command_exists curl; then
        curl -fsSL "$url" -o "$temp_file"
    elif command_exists wget; then
        wget -q "$url" -O "$temp_file"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi
    
    mkdir -p "$extract_dir"
    
    # Extract archive
    if [[ "$url" == *.tar.gz ]] || [[ "$url" == *.tgz ]]; then
        tar -xzf "$temp_file" -C "$extract_dir"
    elif [[ "$url" == *.tar.xz ]]; then
        tar -xJf "$temp_file" -C "$extract_dir"
    elif [[ "$url" == *.zip ]]; then
        unzip -q "$temp_file" -d "$extract_dir"
    elif [[ "$url" == *.tbz ]]; then
        tar -xf "$temp_file" -C "$extract_dir"
    else
        log_error "Unsupported archive format: $url"
        rm -f "$temp_file"
        return 1
    fi
    
    # Find the binary in the extracted files
    local binary_path=""
    
    # Try exact name first
    binary_path=$(find "$extract_dir" -name "$binary_name" -type f -executable 2>/dev/null | head -1)
    
    # If not found, try with wildcards
    if [[ -z "$binary_path" ]]; then
        binary_path=$(find "$extract_dir" -name "*${binary_name}*" -type f -executable 2>/dev/null | head -1)
    fi
    
    # If still not found, try any executable file (for single-binary archives)
    if [[ -z "$binary_path" ]]; then
        binary_path=$(find "$extract_dir" -type f -executable 2>/dev/null | head -1)
    fi
    
    if [[ -n "$binary_path" ]]; then
        # Move binary to install directory with correct name
        mv "$binary_path" "$INSTALL_DIR/$binary_name"
        chmod +x "$INSTALL_DIR/$binary_name"
        log_info "Binary installed: $INSTALL_DIR/$binary_name"
    else
        log_error "Could not find executable binary in archive"
        log_info "Archive contents:"
        find "$extract_dir" -type f | head -10
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    rm -rf "$extract_dir"
}

# Download a direct binary file
download_binary() {
    local url="$1"
    local binary_name="$2"
    local temp_file="/tmp/$(basename "$url")"
    
    log_info "Downloading $url..."
    if command_exists curl; then
        curl -fsSL "$url" -o "$temp_file"
    elif command_exists wget; then
        wget -q "$url" -O "$temp_file"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi
    
    mv "$temp_file" "$INSTALL_DIR/$binary_name"
    chmod +x "$INSTALL_DIR/$binary_name"
    log_info "Binary installed: $INSTALL_DIR/$binary_name"
}

# Install Rust if not present (needed for some tools)
install_rust() {
    if ! command_exists cargo; then
        log_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env"
        log_success "Rust installed"
    else
        log_info "Rust already installed"
    fi
}

# Install Homebrew on macOS (user space)
install_homebrew() {
    if [[ "$(detect_os)" == "macos" ]] && ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
        
        log_success "Homebrew installed"
    fi
}

# Install tools using appropriate package manager
install_with_package_manager() {
    local tool="$1"
    local os="$(detect_os)"
    
    case "$os" in
        macos)
            if command_exists brew; then
                brew install "$tool" 2>/dev/null || return 1
            else
                return 1
            fi
            ;;
        linux)
            # Try common package managers without sudo first
            if command_exists apt-get; then
                apt-get update >/dev/null 2>&1 || true
                apt-get install -y "$tool" >/dev/null 2>&1 && return 0
                # If user install fails, try with sudo
                echo "Need sudo permissions to install:"
                sudo apt-get update >/dev/null 2>&1 || true
                sudo apt-get install -y "$tool" >/dev/null 2>&1 || return 1
            elif command_exists dnf; then
                dnf install -y "$tool" >/dev/null 2>&1 && return 0
                # If user install fails, try with sudo
                echo "Need sudo permissions to install:"
                sudo dnf install -y "$tool" >/dev/null 2>&1 || return 1
            elif command_exists pacman; then
                pacman -S --noconfirm "$tool" >/dev/null 2>&1 && return 0
                # If user install fails, try with sudo
                echo "Need sudo permissions to install:"
                sudo pacman -S --noconfirm "$tool" >/dev/null 2>&1 || return 1
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Install Helix editor
install_helix() {
    if command_exists hx && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "Helix already installed"
        return 0
    fi
    
    log_info "Installing Helix..."
    
    if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
        brew install helix
    else
        local os="$(detect_os)"
        local arch="$(detect_arch)"
        local version
        
        # Try to get the latest version
        version=$(get_latest_github_release "helix-editor/helix")
        if [[ -z "$version" ]]; then
            version="23.10"  # Fallback to known version
        fi
        
        local url=""
        if [[ "$os" == "linux" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-x86_64-linux.tar.xz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-aarch64-linux.tar.xz"
            fi
        elif [[ "$os" == "macos" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-x86_64-macos.tar.xz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-aarch64-macos.tar.xz"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            local temp_dir="/tmp/helix-install"
            download_and_extract "$url" "$temp_dir" "hx"
            
            # Copy runtime files if they exist
            local runtime_dir="$temp_dir/helix-${version}/runtime"
            if [[ -d "$runtime_dir" ]]; then
                mkdir -p "$CONFIG_DIR/helix/runtime"
                cp -r "$runtime_dir"/* "$CONFIG_DIR/helix/runtime/"
                log_info "Helix runtime files installed to $CONFIG_DIR/helix/runtime/"
            fi
        else
            log_warn "No prebuilt binary available for your system. Falling back to cargo install."
            # Install from source using cargo
            if ! command_exists cargo; then
                install_rust
            fi
            cargo install --locked helix-term --rename helix
            ln -sf "$HOME/.cargo/bin/helix" "$INSTALL_DIR/hx"
        fi
    fi
    
    log_success "Helix installed"
}

# Install Zellij
install_zellij() {
    if command_exists zellij && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "Zellij already installed"
        return 0
    fi
    
    log_info "Installing Zellij..."
    
    if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
        brew install zellij
    else
        local os="$(detect_os)"
        local arch="$(detect_arch)"
        local version
        
        # Try to get the latest version
        version=$(get_latest_github_release "zellij-org/zellij")
        if [[ -z "$version" ]]; then
            # Use GitHub API to get latest release URL directly
            if [[ "$os" == "linux" ]]; then
                if [[ "$arch" == "x86_64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
                elif [[ "$arch" == "aarch64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz"
                fi
            elif [[ "$os" == "macos" ]]; then
                if [[ "$arch" == "x86_64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-apple-darwin.tar.gz"
                elif [[ "$arch" == "aarch64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-apple-darwin.tar.gz"
                fi
            fi
        else
            if [[ "$os" == "linux" ]]; then
                if [[ "$arch" == "x86_64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-x86_64-unknown-linux-musl.tar.gz"
                elif [[ "$arch" == "aarch64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-aarch64-unknown-linux-musl.tar.gz"
                fi
            elif [[ "$os" == "macos" ]]; then
                if [[ "$arch" == "x86_64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-x86_64-apple-darwin.tar.gz"
                elif [[ "$arch" == "aarch64" ]]; then
                    url="https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-aarch64-apple-darwin.tar.gz"
                fi
            fi
        fi
        
        local temp_dir="/tmp/zellij-install"
        download_and_extract "$url" "$temp_dir" "zellij"
    fi
    
    log_success "Zellij installed"
}

# Install LSP-AI
install_lsp_ai() {
    if command_exists lsp-ai && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "LSP-AI already installed"
        return 0
    fi
    
    log_info "Installing LSP-AI..."
    
    local os="$(detect_os)"
    local arch="$(detect_arch)"
    local version
    
    # Try to get the latest version
    version=$(get_latest_github_release "afnanenayet/lsp-ai")
    if [[ -z "$version" ]]; then
        log_warn "Could not determine latest LSP-AI version. Falling back to cargo install."
        if ! command_exists cargo; then
            install_rust
        fi
        
        cargo install --locked lsp-ai
        ln -sf "$HOME/.cargo/bin/lsp-ai" "$INSTALL_DIR/"
    else
        local url=""
        if [[ "$os" == "linux" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/afnanenayet/lsp-ai/releases/download/v${version}/lsp-ai-x86_64-unknown-linux-gnu.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/afnanenayet/lsp-ai/releases/download/v${version}/lsp-ai-aarch64-unknown-linux-gnu.tar.gz"
            fi
        elif [[ "$os" == "macos" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/afnanenayet/lsp-ai/releases/download/v${version}/lsp-ai-x86_64-apple-darwin.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/afnanenayet/lsp-ai/releases/download/v${version}/lsp-ai-aarch64-apple-darwin.tar.gz"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            local temp_dir="/tmp/lsp-ai-install"
            download_and_extract "$url" "$temp_dir" "lsp-ai"
        else
            log_warn "No prebuilt binary available for your system. Falling back to cargo install."
            if ! command_exists cargo; then
                install_rust
            fi
            cargo install --locked lsp-ai
            ln -sf "$HOME/.cargo/bin/lsp-ai" "$INSTALL_DIR/"
        fi
    fi
    
    log_success "LSP-AI installed"
}

# Install GitUI
install_gitui() {
    if command_exists gitui && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "GitUI already installed"
        return 0
    fi
    
    log_info "Installing GitUI..."
    
    if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
        brew install gitui
    else
        local os="$(detect_os)"
        local arch="$(detect_arch)"
        local version
        
        # Try to get the latest version
        version=$(get_latest_github_release "gitui-org/gitui")
        if [[ -z "$version" ]]; then
            version="0.27.0"  # Fallback to known version
        fi
        
        local url=""
        if [[ "$os" == "linux" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-linux-x86_64.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-linux-aarch64.tar.gz"
            fi
        elif [[ "$os" == "macos" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-mac-x86_64.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-mac-aarch64.tar.gz"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            local temp_dir="/tmp/gitui-install"
            download_and_extract "$url" "$temp_dir" "gitui"
        else
            log_warn "No prebuilt binary available for your system. Falling back to cargo install."
            if ! command_exists cargo; then
                install_rust
            fi
            cargo install gitui
            ln -sf "$HOME/.cargo/bin/gitui" "$INSTALL_DIR/"
        fi
    fi
    
    log_success "GitUI installed"
}

# Install Ruff
install_ruff() {
    if command_exists ruff && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "Ruff already installed"
        return 0
    fi
    
    log_info "Installing Ruff..."
    
    if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
        brew install ruff
    else
        local os="$(detect_os)"
        local arch="$(detect_arch)"
        local version
        
        # Try to get the latest version
        version=$(get_latest_github_release "astral-sh/ruff")
        if [[ -z "$version" ]]; then
            version="0.3.0"  # Fallback to known version
        fi
        
        local url=""
        if [[ "$os" == "linux" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/astral-sh/ruff/releases/download/${version}/ruff-x86_64-unknown-linux-gnu.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/astral-sh/ruff/releases/download/${version}/ruff-aarch64-unknown-linux-gnu.tar.gz"
            fi
        elif [[ "$os" == "macos" ]]; then
            if [[ "$arch" == "x86_64" ]]; then
                url="https://github.com/astral-sh/ruff/releases/download/${version}/ruff-x86_64-apple-darwin.tar.gz"
            elif [[ "$arch" == "aarch64" ]]; then
                url="https://github.com/astral-sh/ruff/releases/download/${version}/ruff-aarch64-apple-darwin.tar.gz"
            fi
        fi
        
        if [[ -n "$url" ]]; then
            local temp_dir="/tmp/ruff-install"
            download_and_extract "$url" "$temp_dir" "ruff"
        else
            log_warn "No prebuilt binary available for your system. Falling back to cargo install."
            if ! command_exists cargo; then
                install_rust
            fi
            cargo install ruff
            ln -sf "$HOME/.cargo/bin/ruff" "$INSTALL_DIR/"
        fi
    fi
    
    log_success "Ruff installed"
}

# Install modern CLI tools
install_modern_tools() {
    local tools=("btop" "yazi" "ripgrep" "bat" "hyperfine" "delta" "fd" "eza" "dust")
    
    for tool in "${tools[@]}"; do
        if [[ "$TOOLS" != *"$tool"* ]]; then
            continue
        fi
        
        if command_exists "$tool" && [[ "$FORCE_INSTALL" == "false" ]]; then
            log_info "$tool already installed"
            continue
        fi
        
        log_info "Installing $tool..."
        
        if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
            # Special handling for some tools
            case "$tool" in
                "eza")
                    brew install eza
                    ;;
                "dust")
                    brew install du-dust
                    ;;
                "ripgrep")
                    brew install ripgrep
                    ;;
                *)
                    brew install "$tool"
                    ;;
            esac
        else
            local os="$(detect_os)"
            local arch="$(detect_arch)"
            local version=""
            local url=""
            local temp_dir="/tmp/${tool}-install"
            local binary_name="$tool"
            local use_cargo=false
            
            case "$tool" in
                "btop")
                    version=$(get_latest_github_release "aristocratos/btop")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/aristocratos/btop/releases/download/v${version}/btop-x86_64-linux-musl.tbz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/aristocratos/btop/releases/download/v${version}/btop-aarch64-linux-musl.tbz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            url="https://github.com/aristocratos/btop/releases/download/v${version}/btop-macos-universal.tbz"
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "yazi")
                    version=$(get_latest_github_release "sxyazi/yazi")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-x86_64-unknown-linux-gnu.zip"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-aarch64-unknown-linux-gnu.zip"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-x86_64-apple-darwin.zip"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-aarch64-apple-darwin.zip"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "ripgrep")
                    version=$(get_latest_github_release "BurntSushi/ripgrep")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-aarch64-unknown-linux-musl.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                        binary_name="rg"
                    else
                        use_cargo=true
                    fi
                    ;;
                "bat")
                    version=$(get_latest_github_release "sharkdp/bat")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "hyperfine")
                    version=$(get_latest_github_release "sharkdp/hyperfine")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/hyperfine/releases/download/v${version}/hyperfine-v${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/hyperfine/releases/download/v${version}/hyperfine-v${version}-aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/hyperfine/releases/download/v${version}/hyperfine-v${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/hyperfine/releases/download/v${version}/hyperfine-v${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "delta")
                    version=$(get_latest_github_release "dandavison/delta")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "fd")
                    version=$(get_latest_github_release "sharkdp/fd")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "eza")
                    version=$(get_latest_github_release "eza-community/eza")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/eza-community/eza/releases/download/v${version}/eza_x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/eza-community/eza/releases/download/v${version}/eza_aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/eza-community/eza/releases/download/v${version}/eza_x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/eza-community/eza/releases/download/v${version}/eza_aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
                "dust")
                    version=$(get_latest_github_release "bootandy/dust")
                    if [[ -n "$version" ]]; then
                        if [[ "$os" == "linux" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/bootandy/dust/releases/download/v${version}/dust-v${version}-x86_64-unknown-linux-musl.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/bootandy/dust/releases/download/v${version}/dust-v${version}-aarch64-unknown-linux-gnu.tar.gz"
                            fi
                        elif [[ "$os" == "macos" ]]; then
                            if [[ "$arch" == "x86_64" ]]; then
                                url="https://github.com/bootandy/dust/releases/download/v${version}/dust-v${version}-x86_64-apple-darwin.tar.gz"
                            elif [[ "$arch" == "aarch64" ]]; then
                                url="https://github.com/bootandy/dust/releases/download/v${version}/dust-v${version}-aarch64-apple-darwin.tar.gz"
                            fi
                        fi
                    else
                        use_cargo=true
                    fi
                    ;;
            esac
            
            if [[ -n "$url" ]] && [[ "$use_cargo" == "false" ]]; then
                download_and_extract "$url" "$temp_dir" "$binary_name"
            else
                log_warn "No prebuilt binary available for $tool. Falling back to cargo install."
                # Install from cargo for Linux
                if ! command_exists cargo; then
                    install_rust
                fi
                
                case "$tool" in
                    "btop")
                        cargo install btop
                        ;;
                    "yazi")
                        cargo install --locked yazi-fm yazi-cli
                        ;;
                    "ripgrep")
                        cargo install ripgrep
                        ;;
                    "bat")
                        cargo install bat
                        ;;
                    "hyperfine")
                        cargo install hyperfine
                        ;;
                    "delta")
                        cargo install git-delta
                        ;;
                    "fd")
                        cargo install fd-find
                        ;;
                    "eza")
                        cargo install eza
                        ;;
                    "dust")
                        cargo install du-dust
                        ;;
                esac
                
                # Create symlinks in install dir
                if [[ -f "$HOME/.cargo/bin/$tool" ]]; then
                    ln -sf "$HOME/.cargo/bin/$tool" "$INSTALL_DIR/"
                fi
            fi
        fi
        
        log_success "$tool installed"
    done
}

# Install shells
install_shells() {
    # Fish shell
    if [[ "$TOOLS" == *"fish"* ]]; then
        if command_exists fish && [[ "$FORCE_INSTALL" == "false" ]]; then
            log_info "Fish shell already installed"
        else
            log_info "Installing Fish shell..."
            
            if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
                brew install fish
            else
                # Download and install fish manually for Linux
                local os="$(detect_os)"
                local arch="$(detect_arch)"
                
                if [[ "$os" == "linux" ]]; then
                    local temp_dir="/tmp/fish-install"
                    mkdir -p "$temp_dir"
                    
                    # Try package manager first
                    if install_with_package_manager fish; then
                        log_success "Fish installed via package manager"
                    else
                        log_warn "Could not install fish via package manager. Please install manually."
                    fi
                fi
            fi
            
            log_success "Fish shell installed"
        fi
    fi
    
    # Nushell
    if [[ "$TOOLS" == *"nushell"* ]]; then
        if command_exists nu && [[ "$FORCE_INSTALL" == "false" ]]; then
            log_info "Nushell already installed"
        else
            log_info "Installing Nushell..."
            
            if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
                brew install nushell
            else
                if ! command_exists cargo; then
                    install_rust
                fi
                cargo install nu
                ln -sf "$HOME/.cargo/bin/nu" "$INSTALL_DIR/"
            fi
            
            log_success "Nushell installed"
        fi
    fi
}

# Install Starship prompt
install_starship() {
    if [[ "$TOOLS" != *"starship"* ]]; then
        return 0
    fi
    
    if command_exists starship && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "Starship already installed"
        return 0
    fi
    
    log_info "Installing Starship..."
    
    if [[ "$(detect_os)" == "macos" ]] && command_exists brew; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$INSTALL_DIR" -y
    fi
    
    log_success "Starship installed"
}

# Install Aider AI chat
install_aider() {
    if [[ "$TOOLS" != *"aider"* ]]; then
        return 0
    fi
    
    if command_exists aider && [[ "$FORCE_INSTALL" == "false" ]]; then
        log_info "Aider AI chat already installed"
        return 0
    fi
    
    log_info "Installing Aider AI chat..."
    
    if command_exists curl; then
        curl -LsSf https://aider.chat/install.sh | sh
    elif command_exists wget; then
        wget -qO- https://aider.chat/install.sh | sh
    else
        log_error "Neither curl nor wget found. Cannot install Aider."
        return 1
    fi
    
    # Create symlink if needed
    if [[ -f "$HOME/.local/bin/aider" ]]; then
        ln -sf "$HOME/.local/bin/aider" "$INSTALL_DIR/"
    fi
    
    log_success "Aider AI chat installed"
}

# Setup configurations
setup_configurations() {
    if [[ "$SKIP_CONFIG" == "true" ]]; then
        log_info "Skipping configuration setup"
        return 0
    fi
    
    log_info "Setting up configurations..."
    
    # Check if we have config files in the repo
    if [[ -d "$SCRIPT_DIR/configs" ]]; then
        # Copy configurations from repo
        cp -r "$SCRIPT_DIR/configs/"* "$CONFIG_DIR/" 2>/dev/null || true
        log_info "Configurations copied from repository"
    else
        # Create basic configurations
        create_default_configs
    fi
    
    log_success "Configurations set up"
}

# Create default configurations
create_default_configs() {
    # Helix config
    if command_exists hx; then
        mkdir -p "$CONFIG_DIR/helix"
        cat > "$CONFIG_DIR/helix/config.toml" << 'EOF'
theme = "onedark"

[editor]
line-number = "relative"
mouse = true
completion-trigger-len = 2
auto-completion = true
auto-format = true
auto-save = true
idle-timeout = 50

[editor.statusline]
left = ["mode", "spinner", "file-name"]
center = []
right = ["diagnostics", "selections", "position", "file-encoding", "file-line-ending", "file-type"]
separator = "│"

[editor.lsp]
enable = true
display-messages = true

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[keys.normal]
space = { f = "file_picker", b = "buffer_picker", "/" = "global_search" }
EOF
        
        # Languages configuration for LSP-AI
        cat > "$CONFIG_DIR/helix/languages.toml" << 'EOF'
[[language]]
name = "python"
language-servers = ["pylsp", "lsp-ai"]

[[language]]
name = "rust"
language-servers = ["rust-analyzer", "lsp-ai"]

[[language]]
name = "javascript"
language-servers = ["typescript-language-server", "lsp-ai"]

[[language]]
name = "typescript"
language-servers = ["typescript-language-server", "lsp-ai"]

[language-server.lsp-ai]
command = "lsp-ai"
EOF
        
        log_info "Helix configuration created"
    fi
    
    # Zellij config
    if command_exists zellij; then
        mkdir -p "$CONFIG_DIR/zellij"
        cat > "$CONFIG_DIR/zellij/config.kdl" << 'EOF'
theme "catppuccin-mocha"
default_layout "compact"
pane_frames false
mouse_mode true
scroll_buffer_size 10000
copy_on_select true

keybinds {
    normal {
        bind "Ctrl p" { SwitchToMode "Pane"; }
        bind "Ctrl t" { SwitchToMode "Tab"; }
        bind "Ctrl n" { NewPane; }
        bind "Ctrl x" { CloseFocus; SwitchToMode "Normal"; }
        bind "Alt h" { MoveFocus "Left"; }
        bind "Alt l" { MoveFocus "Right"; }
        bind "Alt j" { MoveFocus "Down"; }
        bind "Alt k" { MoveFocus "Up"; }
    }
    pane {
        bind "h" "Left" { MoveFocus "Left"; }
        bind "l" "Right" { MoveFocus "Right"; }
        bind "j" "Down" { MoveFocus "Down"; }
        bind "k" "Up" { MoveFocus "Up"; }
        bind "p" { SwitchToMode "Normal"; }
        bind "n" { NewPane; SwitchToMode "Normal"; }
        bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "x" { CloseFocus; SwitchToMode "Normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
        bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
        bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
        bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
    }
    tab {
        bind "h" "Left" "Up" "k" { GoToPreviousTab; }
        bind "l" "Right" "Down" "j" { GoToNextTab; }
        bind "n" { NewTab; SwitchToMode "Normal"; }
        bind "x" { CloseTab; SwitchToMode "Normal"; }
        bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
        bind "1" { GoToTab 1; SwitchToMode "Normal"; }
        bind "2" { GoToTab 2; SwitchToMode "Normal"; }
        bind "3" { GoToTab 3; SwitchToMode "Normal"; }
        bind "4" { GoToTab 4; SwitchToMode "Normal"; }
        bind "5" { GoToTab 5; SwitchToMode "Normal"; }
        bind "6" { GoToTab 6; SwitchToMode "Normal"; }
        bind "7" { GoToTab 7; SwitchToMode "Normal"; }
        bind "8" { GoToTab 8; SwitchToMode "Normal"; }
        bind "9" { GoToTab 9; SwitchToMode "Normal"; }
        bind "Tab" { ToggleTab; }
    }
}
EOF
        log_info "Zellij configuration created"
    fi
    
    # LSP-AI config
    if command_exists lsp-ai; then
        mkdir -p "$CONFIG_DIR/lsp-ai"
        cat > "$CONFIG_DIR/lsp-ai/config.toml" << 'EOF'
[memory]
file_store = {}

[models.model1]
type = "openai"
chat_endpoint = "https://api.openai.com/v1/chat/completions"
model = "gpt-4"
auth_token_env_var = "OPENAI_API_KEY"

[completion]
model = "model1"
trigger_characters = ["."]
enable = true

[chat]
model = "model1"
enable = true

[[actions]]
name = "Explain Code"
model = "model1"
prompt = "Explain the following code:\n\n{SELECTED_TEXT}"

[[actions]]
name = "Refactor"
model = "model1"
prompt = "Refactor the following code to be more efficient and readable:\n\n{SELECTED_TEXT}"
EOF
        log_info "LSP-AI configuration created"
    fi
    
    # GitUI config
    if command_exists gitui; then
        mkdir -p "$CONFIG_DIR/gitui"
        cat > "$CONFIG_DIR/gitui/theme.ron" << 'EOF'
(
    selected_tab: Some(Reset),
    command_fg: Some(Rgb(255, 255, 255)),
    selection_bg: Some(Rgb(42, 42, 42)),
    selection_fg: Some(Rgb(255, 255, 255)),
    cmdbar_bg: Some(Rgb(32, 32, 32)),
    cmdbar_extra_lines_bg: Some(Rgb(32, 32, 32)),
    disabled_fg: Some(Rgb(128, 128, 128)),
    diff_line_add: Some(Rgb(0, 255, 0)),
    diff_line_delete: Some(Rgb(255, 0, 0)),
    diff_file_added: Some(LightGreen),
    diff_file_removed: Some(LightRed),
    diff_file_moved: Some(LightMagenta),
    diff_file_modified: Some(Yellow),
    commit_hash: Some(Magenta),
    commit_time: Some(LightCyan),
    commit_author: Some(Green),
    danger_fg: Some(Red),
    push_gauge_bg: Some(Blue),
    push_gauge_fg: Some(Reset),
    tag_fg: Some(LightMagenta),
    branch_fg: Some(LightYellow),
)
EOF
        log_info "GitUI configuration created"
    fi
    
    # Shell configurations
    setup_shell_configs
}

# Setup shell configurations
setup_shell_configs() {
    # Fish shell configuration
    if command_exists fish; then
        mkdir -p "$CONFIG_DIR/fish"
        cat > "$CONFIG_DIR/fish/config.fish" << 'EOF'
# Terminal IDE Fish Configuration

# Aliases for modern tools
if command -v eza >/dev/null
    alias ls='eza --icons'
    alias ll='eza -l --icons'
    alias la='eza -la --icons'
    alias lt='eza --tree --level=2 --icons'
end

if command -v bat >/dev/null
    alias cat='bat'
end

if command -v fd >/dev/null
    alias find='fd'
end

if command -v rg >/dev/null
    alias grep='rg'
end

if command -v dust >/dev/null
    alias du='dust'
end

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Development aliases
alias hx='helix'
alias lg='lazygit'

# Initialize starship if available
if command -v starship >/dev/null
    starship init fish | source
end

# Add local bin to PATH
fish_add_path ~/.local/bin
EOF
        log_info "Fish configuration created"
    fi
    
    # Starship configuration
    if command_exists starship; then
        cat > "$CONFIG_DIR/starship.toml" << 'EOF'
# Terminal IDE Starship Configuration

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$git_metrics\
$package\
$nodejs\
$python\
$rust\
$golang\
$java\
$kotlin\
$haskell\
$swift\
$terraform\
$docker_context\
$conda\
$memory_usage\
$aws\
$gcloud\
$openstack\
$azure\
$env_var\
$crystal\
$custom\
$sudo\
$cmd_duration\
$line_break\
$jobs\
$battery\
$time\
$status\
$shell\
$character"""

[directory]
style = "blue"
read_only = " 🔒"
read_only_style = "red"
truncation_length = 4
truncate_to_repo = true

[character]
success_symbol = "[❯](purple)"
error_symbol = "[❯](red)"
vicmd_symbol = "[❮](green)"

[git_branch]
symbol = "🌱 "
truncation_length = 4
truncation_symbol = ""

[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
style = "cyan"

[nodejs]
symbol = " "

[python]
symbol = " "

[rust]
symbol = " "

[package]
symbol = "📦 "

[memory_usage]
disabled = false
threshold = 70
style = "bold dimmed green"

[time]
disabled = false
format = '🕙[\[ $time \]]($style) '
time_format = "%T"
utc_time_offset = "local"
time_range = "10:00:00-14:00:00"
EOF
        log_info "Starship configuration created"
    fi
    
    # Add shell initialization to bashrc/zshrc
    if command_exists starship; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc" 2>/dev/null || true
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc" 2>/dev/null || true
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local tools_array=(${TOOLS//,/ })
    local failed_tools=()
    
    for tool in "${tools_array[@]}"; do
        case "$tool" in
            "helix")
                command_exists hx || failed_tools+=("helix")
                ;;
            "du-dust"|"dust")
                command_exists dust || failed_tools+=("dust")
                ;;
            "lsp-ai")
                command_exists lsp-ai || failed_tools+=("lsp-ai")
                ;;
            *)
                command_exists "$tool" || failed_tools+=("$tool")
                ;;
        esac
    done
    
    if [[ ${#failed_tools[@]} -eq 0 ]]; then
        log_success "All tools installed successfully!"
        echo ""
        echo "🎉 Terminal IDE setup complete!"
        echo ""
        echo "To get started:"
        echo "1. Restart your terminal or run: source ~/.bashrc"
        echo "2. Start Zellij: zellij"
        echo "3. Open Helix editor: hx"
        echo ""
        echo "For more information, see: https://github.com/YOUR_USERNAME/terminal_ide"
    else
        log_error "Some tools failed to install: ${failed_tools[*]}"
        echo "Please check the error messages above and try again."
        return 1
    fi
}

# Main installation function
main() {
    echo "🚀 Terminal IDE Installation"
    echo "================================"
    echo ""
    
    local os="$(detect_os)"
    local arch="$(detect_arch)"
    
    if [[ "$os" == "unsupported" ]]; then
        log_error "Unsupported operating system: $(uname -s)"
        exit 1
    fi
    
    if [[ "$arch" == "unsupported" ]]; then
        log_error "Unsupported architecture: $(uname -m)"
        exit 1
    fi
    
    log_info "Detected OS: $os ($arch)"
    log_info "Installing tools: $TOOLS"
    echo ""
    
    # Setup
    setup_directories
    
    # Install package managers if needed
    if [[ "$os" == "macos" ]]; then
        install_homebrew
    fi
    
    # Parse tools and install
    IFS=',' read -ra TOOLS_ARRAY <<< "$TOOLS"
    
    for tool in "${TOOLS_ARRAY[@]}"; do
        case "$tool" in
            "helix")
                install_helix
                ;;
            "zellij")
                install_zellij
                ;;
            "lsp-ai")
                install_lsp_ai
                ;;
            "gitui")
                install_gitui
                ;;
            "ruff")
                install_ruff
                ;;
            "fish"|"nushell")
                install_shells
                ;;
            "starship")
                install_starship
                ;;
            "aider")
                install_aider
                ;;
            "btop"|"yazi"|"ripgrep"|"bat"|"hyperfine"|"delta"|"fd"|"eza"|"dust")
                # These are handled by install_modern_tools
                ;;
        esac
    done
    
    # Install modern CLI tools
    install_modern_tools
    
    # Setup configurations
    setup_configurations
    
    # Verify installation
    verify_installation
}

# Run main function
main "$@"
