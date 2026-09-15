#!/data/data/com.termux/files/usr/bin/bash
set -e
clear
printf '\033[1;32mX67 LIMPEZA FORENSE\033[0m\n'
printf '\033[1;32mby x67\033[0m\n\n'

echo "[*] Atualizando repositórios..."
pkg update -y
echo "[*] Instalando dependências..."
pkg install -y android-tools coreutils grep sed awk unzip

if ! command -v adb >/dev/null 2>&1; then
  echo "[!] ADB não foi instalado corretamente."
  exit 1
fi

echo
echo "[OK] Dependências instaladas."
echo "[*] Iniciando o painel..."
chmod +x "$HOME/X67-Limpeza-Forense/panel.sh"
exec "$HOME/X67-Limpeza-Forense/panel.sh"
