# Terminal IDE

A comprehensive, portable terminal-based development environment installable with a single command. This setup includes modern command-line tools, text editors, and development utilities designed for maximum productivity.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/terminal_ide/main/install.sh | bash
```

Or for a local installation (user space only, no sudo required):

```bash
git clone https://github.com/YOUR_USERNAME/terminal_ide.git
cd terminal_ide
./install.sh
```

## What's Included

### Core Development Tools

- **[Helix](https://helix-editor.com/)** - Post-modern modal text editor
- **[Zellij](https://zellij.dev/)** - Terminal workspace and multiplexer
- **[LSP-AI](https://github.com/SilasMarvin/lsp-ai)** - AI-powered language server
- **[GitUI](https://github.com/extrawurst/gitui)** - Terminal-based Git interface
- **[Ruff](https://github.com/astral-sh/ruff)** - Fast Python linter and formatter
- **[Aider](https://aider.chat/)** - AI pair programming in your terminal

### Modern Command Line Tools

- **[btop](https://github.com/aristocratos/btop)** - Resource monitor and system information
- **[yazi](https://github.com/sxyazi/yazi)** - Terminal file manager
- **[fish](https://fishshell.com/)** - Smart and user-friendly shell
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast search tool
- **[bat](https://github.com/sharkdp/bat)** - Cat clone with syntax highlighting
- **[hyperfine](https://github.com/sharkdp/hyperfine)** - Command-line benchmarking tool
- **[delta](https://github.com/dandavison/delta)** - Syntax-highlighting pager for git
- **[fd](https://github.com/sharkdp/fd)** - Simple, fast alternative to find
- **[eza](https://github.com/eza-community/eza)** - Modern replacement for ls
- **[du-dust](https://github.com/bootandy/dust)** - Intuitive version of du
- **[starship](https://starship.rs/)** - Cross-shell prompt

### System Requirements

- macOS 10.15+ (Intel or Apple Silicon)
- Linux (x86_64 or ARM64)
- Git
- Internet connection for installation

### User Space Installation

This setup is designed to work entirely in user space without requiring `sudo` permissions. All tools are installed to `~/.local/bin` and configurations are stored in appropriate user directories.

## Installation Options

### Option 1: One-liner Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/terminal_ide/main/install.sh | bash
```

### Option 2: Clone and Install

```bash
git clone https://github.com/YOUR_USERNAME/terminal_ide.git
cd terminal_ide
chmod +x install.sh
./install.sh
```

### Option 3: Custom Installation

```bash
git clone https://github.com/YOUR_USERNAME/terminal_ide.git
cd terminal_ide
./install.sh --tools="helix,zellij,gitui,aider" --skip-config
```

**Available tools:** `helix`, `zellij`, `lsp-ai`, `gitui`, `ruff`, `btop`, `yazi`, `fish`, `ripgrep`, `bat`, `hyperfine`, `delta`, `fd`, `eza`, `dust`, `starship`, `aider`

## Configuration

All configurations are stored as separate files in the `configs/` directory for easy customization:

- `configs/helix/` - Helix editor configuration
- `configs/zellij/` - Zellij terminal multiplexer setup
- `configs/fish/` - Fish shell configuration
- `configs/gitui/` - GitUI theme and keybindings
- `configs/starship.toml` - Starship prompt configuration

### Customizing Configurations

1. Clone this repository
2. Modify files in the `configs/` directory
3. Run `./install.sh` to apply changes

## Usage Guide

### Getting Started

After installation, start your terminal IDE:

```bash
zellij
```

### Essential Keybindings

#### Zellij (Terminal Multiplexer)
- `Ctrl + p` followed by `c` - New pane
- `Ctrl + p` followed by `x` - Close pane
- `Ctrl + p` followed by `n` - New tab
- `Alt + h/j/k/l` - Navigate between panes

#### Helix Editor
- `Space` - Command palette
- `Space f` - File picker
- `Space b` - Buffer picker
- `Space /` - Global search
- `:w` - Save file
- `:q` - Quit

#### GitUI
- `1-5` - Navigate between tabs
- `j/k` - Navigate lists
- `Enter` - Select/Open
- `c` - Commit
- `P` - Push

### Modern Command Alternatives

| Traditional | Modern Alternative | Description |
|-------------|-------------------|-------------|
| `ls` | `eza` | Enhanced directory listing |
| `cat` | `bat` | Syntax highlighting and paging |
| `find` | `fd` | Faster and more intuitive |
| `grep` | `ripgrep` | Faster search with better defaults |
| `du` | `dust` | Visual disk usage |
| `diff` | `delta` | Better git diffs |
| `top/htop` | `btop` | Beautiful system monitor |
| `ranger` | `yazi` | Fast terminal file manager |

## Tool Documentation

### Helix Editor

Helix is a modal editor inspired by Kakoune with built-in LSP support.

**Key Features:**
- Multiple selections
- Tree-sitter syntax highlighting
- Built-in LSP client
- No configuration required to get started

**Basic Usage:**
```bash
hx file.py          # Open a file
hx .                # Open current directory
```

### Zellij Terminal Multiplexer

Modern alternative to tmux with a focus on usability.

**Key Features:**
- Plugin system
- Session resurrection
- Mouse support
- Floating panes

**Basic Usage:**
```bash
zellij              # Start new session
zellij ls           # List sessions
zellij a main       # Attach to 'main' session
```

### LSP-AI Integration

AI-powered code completion and assistance.

**Supported Features:**
- Code completion
- In-editor chat
- Custom actions
- Multiple LLM backends

**Configuration:**
Edit `~/.config/lsp-ai/config.toml` to configure your preferred AI backend.

### GitUI

Terminal-based Git interface.

**Key Features:**
- Staging hunks
- Interactive rebase
- Stash management
- Branch visualization

### Aider AI Pair Programming

AI-powered coding assistant that works directly in your terminal.

**Key Features:**
- Chat with GPT-4/Claude about your codebase
- Make edits to multiple files at once
- Automatic git integration
- Context-aware suggestions

**Basic Usage:**
```bash
aider                # Start chat in current directory
aider file1.py file2.py  # Add specific files to chat
aider --model gpt-4  # Use specific model
```

### Modern Shell Setup

The installation configures Fish shell with useful aliases and functions.

**Aliases Added:**
```bash
ll='eza -l --icons'
la='eza -la --icons'
lt='eza --tree --level=2 --icons'
cat='bat'
find='fd'
grep='rg'
```

## Troubleshooting

### Installation Issues

1. **Permission denied**: Ensure you're not using `sudo`. This is a user-space installation.
2. **Command not found**: Restart your shell or run `source ~/.bashrc` (or equivalent).
3. **Network issues**: Check your internet connection and proxy settings.

### Tool-Specific Issues

#### Helix
- **LSP not working**: Check if language servers are installed (`hx --health`)
- **Theme issues**: Verify terminal supports true color

#### Zellij
- **Session not starting**: Check if tmux is running (conflicts possible)
- **Key bindings**: Refer to status bar for current mode

#### LSP-AI
- **No completions**: Verify configuration in `~/.config/lsp-ai/config.toml`
- **Performance issues**: Consider using local models for faster responses

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test on a clean system
5. Submit a pull request

### Adding New Tools

1. Add installation logic to `install.sh`
2. Create configuration files in `configs/`
3. Update README documentation
4. Test on macOS and Linux

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Thanks to all the maintainers of the excellent tools included in this setup:

- The Helix team for the amazing editor
- Zellij contributors for the terminal multiplexer
- The Rust ecosystem for many of these fast, reliable tools
- The open source community for making this possible 