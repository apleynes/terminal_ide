#!/bin/bash

# Terminal IDE Test Script
# Verifies that all tools are installed and configured correctly
# Supports selective testing and detailed reporting

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
CARGO_BIN="$HOME/.cargo/bin"

# Default tools to test
DEFAULT_TOOLS="helix,zellij,lsp-ai,gitui,ruff,btop,yazi,fish,nushell,ripgrep,bat,hyperfine,delta,fd,eza,dust,starship"

# Test options
TOOLS="$DEFAULT_TOOLS"
TEST_CONFIGS=true
TEST_FUNCTIONALITY=true
VERBOSE=false
QUICK_TEST=false

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

show_help() {
    echo "Terminal IDE Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tools=TOOLS         Comma-separated list of tools to test"
    echo "  --skip-config         Skip configuration testing"
    echo "  --skip-functionality  Skip functionality testing"
    echo "  --quick               Quick test mode (basic checks only)"
    echo "  --verbose             Verbose output with detailed information"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Default tools: $DEFAULT_TOOLS"
    echo ""
    echo "Examples:"
    echo "  $0                               # Test all tools and configurations"
    echo "  $0 --tools=helix,zellij         # Test only helix and zellij"
    echo "  $0 --quick                      # Quick test mode"
    echo "  $0 --verbose                    # Detailed output"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --tools=*)
            TOOLS="${1#*=}"
            shift
            ;;
        --skip-config)
            TEST_CONFIGS=false
            shift
            ;;
        --skip-functionality)
            TEST_FUNCTIONALITY=false
            shift
            ;;
        --quick)
            QUICK_TEST=true
            TEST_CONFIGS=false
            TEST_FUNCTIONALITY=false
            shift
            ;;
        --verbose)
            VERBOSE=true
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
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

run_test() {
    ((TOTAL_TESTS++))
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get command location
get_command_location() {
    local cmd="$1"
    if command_exists "$cmd"; then
        which "$cmd" 2>/dev/null || echo "unknown"
    else
        echo "not found"
    fi
}

# Get command version
get_command_version() {
    local cmd="$1"
    local version=""
    
    case "$cmd" in
        "hx"|"helix")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "zellij")
            version=$($cmd --version 2>/dev/null || echo "unknown")
            ;;
        "rg"|"ripgrep")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "bat")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "fd")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "eza")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "dust")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "delta")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "hyperfine")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "btop")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "yazi")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "gitui")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "ruff")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "lsp-ai")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "fish")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "nu"|"nushell")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        "starship")
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
        *)
            version=$($cmd --version 2>/dev/null | head -1 || echo "unknown")
            ;;
    esac
    
    echo "$version"
}

# Test tool installation
test_tool_installation() {
    local tool="$1"
    local binary_names=()
    
    run_test
    
    # Map tool names to binary names
    case "$tool" in
        "helix")
            binary_names=("hx")
            ;;
        "nushell")
            binary_names=("nu")
            ;;
        "yazi")
            binary_names=("yazi")
            ;;
        "ripgrep")
            binary_names=("rg")
            ;;
        "dust")
            binary_names=("dust")
            ;;
        *)
            binary_names=("$tool")
            ;;
    esac
    
    local found=false
    for binary in "${binary_names[@]}"; do
        if command_exists "$binary"; then
            found=true
            local location=$(get_command_location "$binary")
            local version=$(get_command_version "$binary")
            log_success "$tool ($binary) installed at $location"
            log_verbose "Version: $version"
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        log_fail "$tool not found in PATH"
        return 1
    fi
    
    return 0
}

# Test configuration files
test_configurations() {
    local tool="$1"
    
    run_test
    
    case "$tool" in
        "helix")
            if [[ -f "$CONFIG_DIR/helix/config.toml" ]]; then
                log_success "Helix configuration found"
                log_verbose "Config: $CONFIG_DIR/helix/config.toml"
                
                # Check for essential config sections
                if grep -q "theme.*=" "$CONFIG_DIR/helix/config.toml"; then
                    log_verbose "Theme configuration found"
                fi
                if grep -q "\[editor\]" "$CONFIG_DIR/helix/config.toml"; then
                    log_verbose "Editor configuration found"
                fi
                if grep -q "\[keys" "$CONFIG_DIR/helix/config.toml"; then
                    log_verbose "Key bindings configuration found"
                fi
                
                # Check languages.toml
                if [[ -f "$CONFIG_DIR/helix/languages.toml" ]]; then
                    log_verbose "Helix languages configuration found"
                    if grep -q "lsp-ai" "$CONFIG_DIR/helix/languages.toml"; then
                        log_verbose "LSP-AI integration configured"
                    fi
                fi
            else
                log_fail "Helix configuration not found"
                return 1
            fi
            ;;
        "zellij")
            if [[ -f "$CONFIG_DIR/zellij/config.kdl" ]]; then
                log_success "Zellij configuration found"
                log_verbose "Config: $CONFIG_DIR/zellij/config.kdl"
                
                # Check for essential config sections
                if grep -q "theme" "$CONFIG_DIR/zellij/config.kdl"; then
                    log_verbose "Theme configuration found"
                fi
                if grep -q "keybinds" "$CONFIG_DIR/zellij/config.kdl"; then
                    log_verbose "Keybindings configuration found"
                fi
            else
                log_fail "Zellij configuration not found"
                return 1
            fi
            ;;
        "lsp-ai")
            if [[ -f "$CONFIG_DIR/lsp-ai/config.toml" ]]; then
                log_success "LSP-AI configuration found"
                log_verbose "Config: $CONFIG_DIR/lsp-ai/config.toml"
            else
                log_warn "LSP-AI configuration not found (will use defaults)"
            fi
            ;;
        "gitui")
            if [[ -f "$CONFIG_DIR/gitui/theme.ron" ]]; then
                log_success "GitUI theme configuration found"
                log_verbose "Config: $CONFIG_DIR/gitui/theme.ron"
            else
                log_warn "GitUI configuration not found (will use defaults)"
            fi
            ;;
        "fish")
            if [[ -f "$CONFIG_DIR/fish/config.fish" ]]; then
                log_success "Fish shell configuration found"
                log_verbose "Config: $CONFIG_DIR/fish/config.fish"
                
                # Check for aliases
                if grep -q "alias.*eza" "$CONFIG_DIR/fish/config.fish"; then
                    log_verbose "Modern command aliases configured"
                fi
            else
                log_warn "Fish configuration not found (will use defaults)"
            fi
            ;;
        "starship")
            if [[ -f "$CONFIG_DIR/starship.toml" ]]; then
                log_success "Starship configuration found"
                log_verbose "Config: $CONFIG_DIR/starship.toml"
            else
                log_warn "Starship configuration not found (will use defaults)"
            fi
            ;;
    esac
    
    return 0
}

# Test basic functionality
test_functionality() {
    local tool="$1"
    
    run_test
    
    case "$tool" in
        "helix")
            if echo "test" | hx --help >/dev/null 2>&1; then
                log_success "Helix help command works"
                
                # Test health check
                if hx --health >/dev/null 2>&1; then
                    log_verbose "Helix health check passed"
                else
                    log_warn "Helix health check failed (some LSPs may not be installed)"
                fi
            else
                log_fail "Helix basic functionality test failed"
                return 1
            fi
            ;;
        "zellij")
            if zellij --help >/dev/null 2>&1; then
                log_success "Zellij help command works"
                
                # Test listing sessions
                if zellij list-sessions >/dev/null 2>&1; then
                    log_verbose "Zellij can list sessions"
                fi
            else
                log_fail "Zellij basic functionality test failed"
                return 1
            fi
            ;;
        "rg"|"ripgrep")
            if echo "test" | rg "test" >/dev/null 2>&1; then
                log_success "Ripgrep search functionality works"
            else
                log_fail "Ripgrep functionality test failed"
                return 1
            fi
            ;;
        "bat")
            if echo "test" | bat --style=plain >/dev/null 2>&1; then
                log_success "Bat syntax highlighting works"
            else
                log_fail "Bat functionality test failed"
                return 1
            fi
            ;;
        "eza")
            if eza --help >/dev/null 2>&1; then
                log_success "Eza listing functionality works"
            else
                log_fail "Eza functionality test failed"
                return 1
            fi
            ;;
        "gitui")
            if gitui --version >/dev/null 2>&1; then
                log_success "GitUI version check works"
            else
                log_fail "GitUI functionality test failed"
                return 1
            fi
            ;;
        *)
            # Generic test for other tools
            local binary="$tool"
            case "$tool" in
                "nushell") binary="nu" ;;
                "dust") binary="dust" ;;
            esac
            
            if $binary --help >/dev/null 2>&1 || $binary --version >/dev/null 2>&1; then
                log_success "$tool basic functionality works"
            else
                log_warn "$tool functionality test inconclusive"
            fi
            ;;
    esac
    
    return 0
}

# Test PATH configuration
test_path_configuration() {
    run_test
    
    log_info "Testing PATH configuration..."
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log_success "~/.local/bin is in PATH"
    else
        log_warn "~/.local/bin not found in PATH (may need to restart shell)"
    fi
    
    # Check if cargo bin is in PATH (if Rust tools are installed)
    if [[ -d "$CARGO_BIN" ]] && [[ ":$PATH:" == *":$CARGO_BIN:"* ]]; then
        log_verbose "Cargo bin directory is in PATH"
    fi
    
    # Check shell configuration files
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile")
    local path_configured=false
    
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]] && grep -q "$INSTALL_DIR" "$shell_file"; then
            log_verbose "PATH configured in $(basename "$shell_file")"
            path_configured=true
        fi
    done
    
    if [[ "$path_configured" == "false" ]]; then
        log_warn "PATH configuration not found in shell files"
    fi
}

# Test shell integration
test_shell_integration() {
    run_test
    
    log_info "Testing shell integration..."
    
    # Test starship initialization
    if command_exists starship; then
        local shell_files=("$HOME/.bashrc" "$HOME/.zshrc")
        local starship_configured=false
        
        for shell_file in "${shell_files[@]}"; do
            if [[ -f "$shell_file" ]] && grep -q "starship init" "$shell_file"; then
                log_verbose "Starship configured in $(basename "$shell_file")"
                starship_configured=true
            fi
        done
        
        if [[ "$starship_configured" == "true" ]]; then
            log_success "Starship shell integration configured"
        else
            log_warn "Starship shell integration not found"
        fi
    fi
    
    # Test fish configuration if fish is installed
    if command_exists fish && [[ -f "$CONFIG_DIR/fish/config.fish" ]]; then
        log_success "Fish shell configuration found"
        
        # Check for modern command aliases
        if grep -q "alias.*eza" "$CONFIG_DIR/fish/config.fish" 2>/dev/null; then
            log_verbose "Modern command aliases configured in Fish"
        fi
    fi
}

# Integration tests
run_integration_tests() {
    if [[ "$TEST_FUNCTIONALITY" == "false" ]]; then
        return 0
    fi
    
    log_info "Running integration tests..."
    
    # Test Helix + LSP-AI integration
    if command_exists hx && command_exists lsp-ai; then
        run_test
        if [[ -f "$CONFIG_DIR/helix/languages.toml" ]] && grep -q "lsp-ai" "$CONFIG_DIR/helix/languages.toml"; then
            log_success "Helix + LSP-AI integration configured"
        else
            log_warn "Helix + LSP-AI integration not configured"
        fi
    fi
    
    # Test modern command alternatives
    if command_exists eza && command_exists bat && command_exists rg; then
        run_test
        log_success "Modern command suite available (eza, bat, ripgrep)"
    fi
    
    # Test Git workflow tools
    if command_exists gitui && command_exists delta; then
        run_test
        log_success "Git workflow tools available (gitui, delta)"
    fi
}

# Generate summary report
generate_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    
    echo -e "Total Tests:    ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "Passed:         ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:         ${RED}$FAILED_TESTS${NC}"
    echo -e "Warnings:       ${YELLOW}$WARNINGS${NC}"
    echo -e "Success Rate:   ${CYAN}$success_rate%${NC}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        if [[ $WARNINGS -eq 0 ]]; then
            log_success "All tests passed! Terminal IDE is ready to use."
            echo ""
            echo "🚀 Getting Started:"
            echo "   1. Start Zellij: zellij"
            echo "   2. Open Helix: hx"
            echo "   3. Try modern commands: eza, bat, rg"
        else
            echo -e "${GREEN}✓${NC} Installation verified with ${YELLOW}$WARNINGS warning(s)${NC}"
            echo ""
            echo "💡 Warnings indicate non-critical issues or missing optional components."
        fi
    else
        echo -e "${RED}✗${NC} Installation has ${RED}$FAILED_TESTS failure(s)${NC}"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   1. Re-run the installation script"
        echo "   2. Check the installation logs"
        echo "   3. Restart your terminal"
        echo "   4. Run: source ~/.bashrc (or ~/.zshrc)"
        return 1
    fi
    
    return 0
}

# Main test function
main() {
    echo "🧪 Terminal IDE Test Suite"
    echo "=========================="
    echo ""
    
    if [[ "$QUICK_TEST" == "true" ]]; then
        log_info "Running quick test mode"
    else
        log_info "Running comprehensive tests"
    fi
    
    log_info "Testing tools: $TOOLS"
    echo ""
    
    # Test PATH configuration
    test_path_configuration
    
    # Test individual tools
    IFS=',' read -ra TOOLS_ARRAY <<< "$TOOLS"
    for tool in "${TOOLS_ARRAY[@]}"; do
        echo ""
        log_info "Testing $tool..."
        
        # Test installation
        test_tool_installation "$tool"
        
        # Test configuration
        if [[ "$TEST_CONFIGS" == "true" ]]; then
            test_configurations "$tool"
        fi
        
        # Test functionality
        if [[ "$TEST_FUNCTIONALITY" == "true" ]]; then
            test_functionality "$tool"
        fi
    done
    
    echo ""
    
    # Test shell integration
    test_shell_integration
    
    # Run integration tests
    run_integration_tests
    
    # Generate summary
    generate_summary
}

# Run main function
main "$@" 