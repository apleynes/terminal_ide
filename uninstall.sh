#!/bin/bash

# Terminal IDE Uninstall Script
# Removes tools and configurations installed by the Terminal IDE setup
# Supports selective removal and backup options

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
CARGO_BIN="$HOME/.cargo/bin"
BACKUP_DIR="$HOME/.terminal_ide_backup_$(date +%Y%m%d_%H%M%S)"

# Default tools to uninstall
DEFAULT_TOOLS="helix,zellij,lsp-ai,gitui,ruff,btop,yazi,fish,ripgrep,bat,hyperfine,delta,fd,eza,dust,starship,aider"

# Parse command line arguments
TOOLS="$DEFAULT_TOOLS"
REMOVE_CONFIG=true
REMOVE_HOMEBREW_TOOLS=false
BACKUP_CONFIG=true
FORCE_REMOVE=false
DRY_RUN=false

show_help() {
    echo "Terminal IDE Uninstall Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tools=TOOLS         Comma-separated list of tools to uninstall"
    echo "  --keep-config         Keep configuration files"
    echo "  --no-backup           Don't backup configurations before removal"
    echo "  --remove-homebrew     Also remove homebrew-installed tools"
    echo "  --force               Force removal without confirmation"
    echo "  --dry-run             Show what would be removed without actually removing"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Default tools: $DEFAULT_TOOLS"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Remove all tools and configs (with backup)"
    echo "  $0 --tools=helix,zellij              # Remove only helix and zellij"
    echo "  $0 --keep-config                     # Remove tools but keep configurations"
    echo "  $0 --dry-run                         # See what would be removed"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --tools=*)
            TOOLS="${1#*=}"
            shift
            ;;
        --keep-config)
            REMOVE_CONFIG=false
            shift
            ;;
        --no-backup)
            BACKUP_CONFIG=false
            shift
            ;;
        --remove-homebrew)
            REMOVE_HOMEBREW_TOOLS=true
            shift
            ;;
        --force)
            FORCE_REMOVE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
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

log_dry_run() {
    echo -e "${YELLOW}[DRY RUN]${NC} Would remove: $1"
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

# Safe remove function
safe_remove() {
    local item="$1"
    local type="$2" # file or directory
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "$item"
        return 0
    fi
    
    if [[ -e "$item" ]]; then
        if [[ "$type" == "directory" ]]; then
            rm -rf "$item"
            log_info "Removed directory: $item"
        else
            rm -f "$item"
            log_info "Removed file: $item"
        fi
    fi
}

# Backup configurations
backup_configurations() {
    if [[ "$BACKUP_CONFIG" == "false" ]] || [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    log_info "Creating backup at $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup tool configurations
    local configs=("helix" "zellij" "fish" "gitui" "lsp-ai")
    for config in "${configs[@]}"; do
        if [[ -d "$CONFIG_DIR/$config" ]]; then
            cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/"
            log_info "Backed up $config configuration"
        fi
    done
    
    # Backup starship config
    if [[ -f "$CONFIG_DIR/starship.toml" ]]; then
        cp "$CONFIG_DIR/starship.toml" "$BACKUP_DIR/"
        log_info "Backed up starship configuration"
    fi
    
    # Backup shell configs
    local shell_files=(".bashrc" ".zshrc" ".zprofile")
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$HOME/$shell_file" ]]; then
            cp "$HOME/$shell_file" "$BACKUP_DIR/"
            log_info "Backed up $shell_file"
        fi
    done
    
    log_success "Configurations backed up to $BACKUP_DIR"
}

# Remove cargo-installed tools
remove_cargo_tools() {
    if [[ ! -d "$CARGO_BIN" ]]; then
        return 0
    fi
    
    local cargo_tools=("lsp-ai" "gitui" "ruff" "btop" "yazi" "ya" "ripgrep" "rg" "bat" "hyperfine" "delta" "fd" "eza" "dust" "helix" "aider")
    
    for tool in "${cargo_tools[@]}"; do
        if [[ "$TOOLS" == *"${tool%/*}"* ]] || [[ "$TOOLS" == *"$tool"* ]]; then
            if [[ -f "$CARGO_BIN/$tool" ]]; then
                safe_remove "$CARGO_BIN/$tool" "file"
            fi
            
            # Also remove from local bin if symlinked
            if [[ -L "$INSTALL_DIR/$tool" ]]; then
                safe_remove "$INSTALL_DIR/$tool" "file"
            fi
        fi
    done
    
    # Special handling for tools with different binary names
    if [[ "$TOOLS" == *"helix"* ]]; then
        safe_remove "$CARGO_BIN/hx" "file"
        safe_remove "$INSTALL_DIR/hx" "file"
    fi
    
    if [[ "$TOOLS" == *"yazi"* ]]; then
        safe_remove "$CARGO_BIN/ya" "file"
        safe_remove "$INSTALL_DIR/ya" "file"
        safe_remove "$CARGO_BIN/yazi-fm" "file"
        safe_remove "$CARGO_BIN/yazi-cli" "file"
    fi
}

# Remove homebrew-installed tools
remove_homebrew_tools() {
    if [[ "$REMOVE_HOMEBREW_TOOLS" == "false" ]] || ! command_exists brew; then
        return 0
    fi
    
    local os="$(detect_os)"
    if [[ "$os" != "macos" ]]; then
        return 0
    fi
    
    log_info "Removing Homebrew-installed tools..."
    
    local brew_tools=("helix" "zellij" "gitui" "ruff" "btop" "yazi" "ripgrep" "bat" "hyperfine" "git-delta" "fd" "eza" "du-dust" "fish" "starship" "aider")
    
    for tool in "${brew_tools[@]}"; do
        # Map tool names to package names
        local package_name="$tool"
        case "$tool" in
            "git-delta") package_name="delta" ;;
            "du-dust") package_name="dust" ;;
        esac
        
        if [[ "$TOOLS" == *"${package_name}"* ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_dry_run "brew uninstall $tool"
            else
                if brew list "$tool" >/dev/null 2>&1; then
                    brew uninstall "$tool" >/dev/null 2>&1 || true
                    log_info "Removed $tool via Homebrew"
                fi
            fi
        fi
    done
}

# Remove locally installed binaries
remove_local_binaries() {
    local tools_array=(${TOOLS//,/ })
    
    for tool in "${tools_array[@]}"; do
        # Handle tool name variations
        local binary_names=("$tool")
        case "$tool" in
            "helix")
                binary_names=("hx" "helix")
                ;;
            "yazi")
                binary_names=("yazi" "ya")
                ;;
            "ripgrep")
                binary_names=("rg" "ripgrep")
                ;;
            "delta")
                binary_names=("delta" "git-delta")
                ;;
            "dust")
                binary_names=("dust" "du-dust")
                ;;
            "fd")
                binary_names=("fd" "fd-find")
                ;;
            "aider")
                binary_names=("aider")
                ;;
        esac
        
        for binary in "${binary_names[@]}"; do
            safe_remove "$INSTALL_DIR/$binary" "file"
        done
    done
}

# Remove configurations
remove_configurations() {
    if [[ "$REMOVE_CONFIG" == "false" ]]; then
        log_info "Keeping configurations (--keep-config specified)"
        return 0
    fi
    
    log_info "Removing configurations..."
    
    # Remove tool-specific configs
    local configs=("helix" "zellij" "fish" "gitui" "lsp-ai")
    for config in "${configs[@]}"; do
        if [[ "$TOOLS" == *"$config"* ]]; then
            safe_remove "$CONFIG_DIR/$config" "directory"
        fi
    done
    
    # Remove starship config
    if [[ "$TOOLS" == *"starship"* ]]; then
        safe_remove "$CONFIG_DIR/starship.toml" "file"
    fi
}

# Clean up PATH modifications
cleanup_path() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "PATH cleanup in shell config files"
        return 0
    fi
    
    log_info "Cleaning up PATH modifications..."
    
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile")
    
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]]; then
            # Remove lines that add ~/.local/bin to PATH
            if grep -q "$INSTALL_DIR" "$shell_file"; then
                # Create a backup
                cp "$shell_file" "${shell_file}.bak"
                
                # Remove the PATH modification lines
                grep -v "$INSTALL_DIR" "${shell_file}.bak" > "$shell_file"
                log_info "Cleaned PATH modifications from $(basename "$shell_file")"
            fi
            
            # Remove starship initialization
            if [[ "$TOOLS" == *"starship"* ]] && grep -q "starship init" "$shell_file"; then
                cp "$shell_file" "${shell_file}.bak"
                grep -v "starship init" "${shell_file}.bak" > "$shell_file"
                log_info "Removed starship initialization from $(basename "$shell_file")"
            fi
        fi
    done
}

# Remove Rust toolchain (optional)
remove_rust() {
    if [[ "$TOOLS" != *"rust"* ]]; then
        return 0
    fi
    
    if ! command_exists rustup; then
        return 0
    fi
    
    if [[ "$FORCE_REMOVE" == "false" ]]; then
        echo ""
        read -p "Do you want to remove the Rust toolchain? This will affect other Rust projects. (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping Rust toolchain"
            return 0
        fi
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Rust toolchain and ~/.cargo directory"
        return 0
    fi
    
    log_info "Removing Rust toolchain..."
    rustup self uninstall -y >/dev/null 2>&1 || true
    safe_remove "$HOME/.cargo" "directory"
    safe_remove "$HOME/.rustup" "directory"
    log_success "Rust toolchain removed"
}

# Verify removal
verify_removal() {
    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    log_info "Verifying removal..."
    
    local tools_array=(${TOOLS//,/ })
    local remaining_tools=()
    
    for tool in "${tools_array[@]}"; do
        local binary_names=("$tool")
        case "$tool" in
            "helix") binary_names=("hx") ;;
            "yazi") binary_names=("yazi" "ya") ;;
            "ripgrep") binary_names=("rg") ;;
            "aider") binary_names=("aider") ;;
        esac
        
        for binary in "${binary_names[@]}"; do
            if command_exists "$binary"; then
                remaining_tools+=("$binary")
            fi
        done
    done
    
    if [[ ${#remaining_tools[@]} -eq 0 ]]; then
        log_success "All specified tools have been removed successfully!"
    else
        log_warn "Some tools are still accessible (possibly system-installed): ${remaining_tools[*]}"
        log_info "Use --remove-homebrew flag to remove Homebrew-installed tools"
    fi
}

# Confirmation prompt
confirm_removal() {
    if [[ "$FORCE_REMOVE" == "true" ]] || [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    echo ""
    echo "🗑️  Terminal IDE Uninstall"
    echo "=========================="
    echo ""
    echo "This will remove the following:"
    echo "• Tools: $TOOLS"
    if [[ "$REMOVE_CONFIG" == "true" ]]; then
        echo "• Configuration files"
    fi
    if [[ "$BACKUP_CONFIG" == "true" ]]; then
        echo "• Backup will be created at: $BACKUP_DIR"
    fi
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
}

# Main uninstall function
main() {
    echo "🗑️  Terminal IDE Uninstall"
    echo "=========================="
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No files will be actually removed"
        echo ""
    fi
    
    log_info "Tools to remove: $TOOLS"
    echo ""
    
    # Confirmation
    confirm_removal
    
    # Backup before removal
    if [[ "$REMOVE_CONFIG" == "true" ]]; then
        backup_configurations
    fi
    
    # Remove tools
    log_info "Removing tools..."
    remove_cargo_tools
    remove_homebrew_tools
    remove_local_binaries
    
    # Remove configurations
    remove_configurations
    
    # Clean up shell configurations
    cleanup_path
    
    # Optional: Remove Rust toolchain
    remove_rust
    
    # Verify removal
    verify_removal
    
    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        log_success "Terminal IDE uninstall completed!"
        
        if [[ "$BACKUP_CONFIG" == "true" ]] && [[ -d "$BACKUP_DIR" ]]; then
            echo ""
            echo "📁 Your configurations have been backed up to:"
            echo "   $BACKUP_DIR"
        fi
        
        echo ""
        echo "To complete the removal:"
        echo "1. Restart your terminal or run: source ~/.bashrc"
        echo "2. Check if $INSTALL_DIR can be removed (if empty)"
        
        if [[ "$REMOVE_HOMEBREW_TOOLS" == "false" ]]; then
            echo "3. Run with --remove-homebrew to remove Homebrew-installed tools"
        fi
    fi
}

# Run main function
main "$@" 
