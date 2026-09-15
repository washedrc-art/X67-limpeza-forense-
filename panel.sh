#!/data/data/com.termux/files/usr/bin/bash
set -u
PKGFILE="$HOME/X67-Limpeza-Forense/packages.txt"

green='\033[1;32m'; reset='\033[0m'; cyan='\033[1;36m'; red='\033[1;31m'

while true; do
  clear
  echo -e "${green}╔══════════════════════════════════════╗"
  echo -e "║        X67 LIMPEZA FORENSE          ║"
  echo -e "║              by x67                 ║"
  echo -e "╚══════════════════════════════════════╝${reset}"
  echo
  echo "  [0] Conectar dispositivo via ADB"
  echo "  [1] Verificar pacotes/UsageStats"
  echo "  [2] Gerar relatório de diagnóstico"
  echo "  [3] Sair"
  echo
  read -rp "Escolha: " op

  case "$op" in
    0)
      echo
      echo "No Android 11+, ative Opções do desenvolvedor > Depuração sem fio."
      echo
      read -rp "IP:PORTA para adb pair (ex.: 192.168.1.10:37099): " pairaddr
      read -rp "Código de pareamento: " paircode
      adb pair "$pairaddr" "$paircode" || true
      echo
      read -rp "IP:PORTA para adb connect (ex.: 192.168.1.10:5555): " connaddr
      adb connect "$connaddr" || true
      echo
      adb devices
      read -rp "Pressione Enter para voltar..." _
      ;;
    1)
      clear
      echo -e "${cyan}Verificação de UsageStats${reset}"
      echo
      if ! adb get-state >/dev/null 2>&1; then
        echo -e "${red}[!] Nenhum dispositivo ADB conectado.${reset}"
      else
        while IFS= read -r pkg; do
          [ -z "$pkg" ] && continue
          if adb shell dumpsys usagestats 2>/dev/null | grep -Fq "$pkg"; then
            echo "[ENCONTRADO] $pkg"
          else
            echo "[não encontrado] $pkg"
          fi
        done < "$PKGFILE"
      fi
      echo
      read -rp "Pressione Enter para voltar..." _
      ;;
    2)
      clear
      report="$HOME/X67-Limpeza-Forense/relatorio-$(date +%Y%m%d-%H%M%S).txt"
      {
        echo "X67 LIMPEZA FORENSE - RELATÓRIO DE DIAGNÓSTICO"
        echo "Data: $(date)"
        echo
        echo "Dispositivo:"
        adb devices 2>&1 || true
        echo
        echo "Pacotes consultados:"
        cat "$PKGFILE"
        echo
        echo "UsageStats:"
        adb shell dumpsys usagestats 2>&1 || true
      } > "$report"
      echo "Relatório salvo em:"
      echo "$report"
      read -rp "Pressione Enter para voltar..." _
      ;;
    3) exit 0 ;;
    *) echo "Opção inválida"; sleep 1 ;;
  esac
done
