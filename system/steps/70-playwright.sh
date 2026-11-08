# Libraries and fonts that Playwright's Chromium needs on Debian 13 (the
# browser itself downloads on first use).

packages=(
  libasound2t64
  libatk-bridge2.0-0t64
  libatk1.0-0t64
  libatspi2.0-0t64
  libcairo2
  libcups2t64
  libdbus-1-3
  libdrm2
  libfontconfig1
  libfreetype6
  libgbm1
  libglib2.0-0t64
  libnspr4
  libnss3
  libpango-1.0-0
  libx11-6
  libxcb1
  libxcomposite1
  libxdamage1
  libxext6
  libxfixes3
  libxkbcommon0
  libxrandr2
  fonts-liberation
  fonts-noto-color-emoji
)

apt_install "${packages[@]}"

verify_installed "${packages[@]}"
