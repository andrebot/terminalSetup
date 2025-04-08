#!/usr/bin/env bash

set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "💡 Installing dependencies..."
sudo apt install -y zsh git curl wget build-essential libssl-dev libreadline-dev zlib1g-dev \
  libffi-dev libyaml-dev libncurses-dev libgdbm-dev ruby-dev openssh-client

echo "🐚 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "🐚 Oh My Zsh already installed. Skipping."
fi

echo "🌟 Installing Powerlevel10k..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "🌟 Powerlevel10k already installed. Skipping."
fi

echo "✨ Installing zsh-autosuggestions and zsh-syntax-highlighting..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "⚙️ Updating .zshrc..."
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc || true
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc || true

grep -qxF "# Clean all node_modules recursively" ~/.zshrc || cat << 'EOF' >> ~/.zshrc

# Custom Aliases
# Clean all node_modules recursively
alias cleanNodeModules='find . -type d -name "node_modules" -prune -exec rm -rf "{}" +'
EOF

read -rp "Do you want to install Ruby and colorls? (y/n): " install_ruby
if [[ "$install_ruby" =~ ^[Yy]$ ]]; then
  if ! command -v rbenv >/dev/null; then
    echo "💎 Installing rbenv and ruby-build..."
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  else
    echo "💎 rbenv already installed. Skipping."
  fi

  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - zsh)"

  grep -qxF 'export PATH="$HOME/.rbenv/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
  grep -qxF 'eval "$(rbenv init - zsh)"' ~/.zshrc || echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

  if ! rbenv versions | grep -q "3.2.2"; then
    echo "🧱 Installing Ruby 3.2.2..."
    rbenv install 3.2.2
  fi

  rbenv global 3.2.2

  if ! gem list colorls -i > /dev/null; then
    echo "🎨 Installing colorls..."
    gem install colorls
  fi

  grep -qxF "alias ls='colorls'" ~/.zshrc || echo "alias ls='colorls'" >> ~/.zshrc
  grep -qxF "alias ll='colorls -lA'" ~/.zshrc || echo "alias ll='colorls -lA'" >> ~/.zshrc
else
  echo "⏭️ Skipping Ruby and colorls installation."
fi

read -rp "Do you want to generate a new SSH key? (y/n): " generate_ssh
if [[ "$generate_ssh" =~ ^[Yy]$ ]]; then
  read -rp "Enter your email for the SSH key: " ssh_email
  ssh_key_path="$HOME/.ssh/id_ed25519"

  if [ -f "$ssh_key_path" ]; then
    echo "⚠️ SSH key already exists at $ssh_key_path — skipping creation."
  else
    echo "🔐 Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_key_path" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_path"
    echo "📎 Here's your public key:"
    cat "$ssh_key_path.pub"
    echo "💡 Copy it to GitHub/GitLab/Bitbucket."
  fi
else
  echo "⏭️ Skipping SSH key generation."
fi

echo "📦 Installing NVM (Node Version Manager)..."
export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  echo "📦 NVM already installed. Skipping."
fi

grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || cat << 'EOF' >> ~/.zshrc

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOF

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "⚡ Setting Zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
else
  echo "✅ Zsh is already the default shell."
fi

echo "✅ Done! Please restart your terminal or run 'exec zsh'"
