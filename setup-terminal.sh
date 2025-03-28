#!/usr/bin/env bash

set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "💡 Installing dependencies..."
sudo apt install -y zsh git curl wget build-essential libssl-dev libreadline-dev zlib1g-dev \
  libffi-dev libyaml-dev libncurses-dev libgdbm-dev ruby-dev openssh-client

echo "🐚 Installing Oh My Zsh..."
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "🌟 Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

echo "✨ Installing zsh-autosuggestions and zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

echo "💎 Installing rbenv and ruby-build..."
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc

echo "🧱 Installing Ruby 3.2.2..."
rbenv install 3.2.2
rbenv global 3.2.2

echo "🎨 Installing colorls..."
gem install colorls

echo "⚙️ Updating .zshrc..."

# Replace theme
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Add plugins (remove default and add yours)
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Add aliases
cat << 'EOF' >> ~/.zshrc

# Custom Aliases
alias ls='colorls'
alias ll='colorls -lA'

# Clean all node_modules recursively
alias cleanNodeModules='find . -type d -name "node_modules" -prune -exec rm -rf "{}" +'
EOF

echo "🔐 Generating a new SSH key..."
read -rp "Enter your email for the SSH key: " ssh_email
ssh_key_path="$HOME/.ssh/id_ed25519"

if [ -f "$ssh_key_path" ]; then
  echo "⚠️ SSH key already exists at $ssh_key_path — skipping creation."
else
  ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_key_path" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$ssh_key_path"
  echo "📎 Here's your public key:"
  cat "$ssh_key_path.pub"
  echo "💡 Copy it to GitHub/GitLab/Bitbucket."
fi

echo "⚡ Setting Zsh as default shell..."
chsh -s "$(which zsh)"

echo "✅ Done! Please restart your terminal or run 'exec zsh'"

