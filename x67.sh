#!/data/data/com.termux/files/usr/bin/bash
# X67 Limpeza Forense
# Android 11+ / Termux
# IMPORTANTE: este projeto não apaga arquivos internos do Android.
# A limpeza usa somente comandos ADB suportados e disponíveis no dispositivo.

set -u
BASE="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[1;32m'; WHITE='\033[1;37m'; DIM='\033[2m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
BOLD='\033[1m'
TABLE="$BASE/packages.txt"

banner() {
  clear
  printf "${GREEN}${BOLD}"
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                 X67 LIMPEZA FORENSE                       ║"
  echo "║                         by x67                             ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  printf "${NC}\n"
}

pause_enter() {
  echo
  read -r -p "Pressione ENTER para voltar ao menu..." _
}

check_android() {
  local v
  v="$(getprop ro.build.version.sdk 2>/dev/null || echo 0)"
  if [ "${v:-0}" -lt 30 ]; then
    printf "${RED}Este projeto é destinado a Android 11+ (API 30+).${NC}\n"
    printf "API detectada: ${v:-desconhecida}\n"
    return 1
  fi
  return 0
}

check_adb() {
  command -v adb >/dev/null 2>&1 || {
    printf "${RED}ADB não encontrado. Execute ./install.sh primeiro.${NC}\n"
    return 1
  }
}

connected() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{found=1} END{exit !found}'
}

pair_device() {
  banner
  printf "${WHITE}${BOLD}0 — PAREAR / CONECTAR DISPOSITIVO${NC}\n\n"
  echo "1) No Android alvo: Configurações → Opções do desenvolvedor →"
  echo "   Depuração sem fio → Parear dispositivo com código de pareamento."
  echo
  read -r -p "Digite IP:PORTA exibido em 'Pareamento' (ex.: 192.168.1.10:37123): " PAIR_ADDR
  read -r -p "Digite o código de pareamento: " PAIR_CODE
  echo
  printf "${YELLOW}Executando adb pair...${NC}\n"
  if adb pair "$PAIR_ADDR" "$PAIR_CODE"; then
    echo
    printf "${GREEN}PAIR concluído.${NC}\n"
  else
    printf "${RED}Falha no pair.${NC}\n"
    pause_enter
    return
  fi
  echo
  read -r -p "Agora digite o IP:PORTA mostrado na tela principal da Depuração sem fio para CONNECT: " CONNECT_ADDR
  printf "${YELLOW}Executando adb connect...${NC}\n"
  if adb connect "$CONNECT_ADDR"; then
    echo
    printf "${GREEN}CONNECT concluído.${NC}\n"
    adb devices
  else
    printf "${RED}Falha no connect.${NC}\n"
  fi
  pause_enter
}

read_packages() {
  [ -f "$TABLE" ] || return 1
  grep -vE '^[[:space:]]*(#|$)' "$TABLE" | sed 's/[[:space:]]*#.*$//' | awk 'NF'
}

clear_forensic() {
  banner
  printf "${WHITE}${BOLD}1 — LIMPEZA FORENSE${NC}\n\n"
  if ! connected; then
    printf "${RED}Nenhum dispositivo ADB conectado.${NC}\n"
    pause_enter; return
  fi
  if ! [ -s "$TABLE" ]; then
    printf "${YELLOW}packages.txt está vazio.${NC}\n"
    echo "Adicione um pacote por linha e execute novamente."
    pause_enter; return
  fi

  mapfile -t pkgs < <(read_packages)
  echo "Pacotes da tabela: ${#pkgs[@]}"
  echo
  printf "${YELLOW}ATENÇÃO:${NC} a operação tenta remover somente estatísticas de uso"
  echo "do pacote através do serviço usagestats, quando a ROM expõe"
  echo "o comando correspondente. Não remove outros dados do aplicativo."
  echo
  read -r -p "Digite LIMPAR para continuar: " CONF
  [ "$CONF" = "LIMPAR" ] || { echo "Cancelado."; pause_enter; return; }

  local total=${#pkgs[@]} i=0 pkg ok=0
  for pkg in "${pkgs[@]}"; do
    i=$((i+1))
    banner
    printf "${WHITE}${BOLD}1 — LIMPEZA FORENSE${NC}\n\n"
    printf "Processando [%d/%d] %s\n\n" "$i" "$total" "$pkg"
    printf "["
    for _ in $(seq 1 30); do printf "·"; done
    printf "]\n"
    echo
    # Primeiro método: comando documentado no AOSP.
    if adb shell cmd usagestats clear-last-used-timestamps "$pkg" >/dev/null 2>&1; then
      printf "${GREEN}✓ Timestamps limpos: %s${NC}\n" "$pkg"
      ok=$((ok+1))
    # Algumas versões expõem delete-package-data.
    elif adb shell cmd usagestats delete-package-data "$pkg" >/dev/null 2>&1; then
      printf "${GREEN}✓ Dados de UsageStats removidos: %s${NC}\n" "$pkg"
      ok=$((ok+1))
    else
      printf "${YELLOW}! ROM não permitiu a limpeza via usagestats: %s${NC}\n" "$pkg"
    fi
    sleep 0.15
  done
  echo
  printf "${GREEN}Concluído: %d/%d pacotes processados.${NC}\n" "$ok" "$total"
  echo "A disponibilidade desses comandos varia conforme Android/ROM."
  pause_enter
}

status_check() {
  banner
  printf "${WHITE}${BOLD}2 — STATUS / VERIFICAÇÃO${NC}\n\n"
  if ! connected; then
    printf "${RED}Nenhum dispositivo ADB conectado.${NC}\n"
    pause_enter; return
  fi
  [ -s "$TABLE" ] || { echo "packages.txt está vazio."; pause_enter; return; }

  echo "Verificando pacotes da tabela no UsageStats..."
  echo
  local found=0 pkg out
  while IFS= read -r pkg; do
    out="$(adb shell dumpsys usagestats 2>/dev/null | grep -F "$pkg" | head -n 3 || true)"
    if [ -n "$out" ]; then
      printf "${YELLOW}[ENCONTRADO]${NC} %s\n" "$pkg"
      echo "$out" | sed 's/^/  /'
      found=1
    else
      printf "${GREEN}[NÃO ENCONTRADO]${NC} %s\n" "$pkg"
    fi
  done < <(read_packages)
  echo
  if [ "$found" -eq 1 ]; then
    printf "${YELLOW}Há referências encontradas no dump do UsageStats.${NC}\n"
  else
    printf "${GREEN}Nenhuma referência encontrada para a tabela.${NC}\n"
  fi
  echo
  echo "Observação: isso verifica o dump acessível pelo ADB; não é uma"
  echo "garantia de que nenhum outro trecho do bugreport contenha o pacote."
  pause_enter
}

menu() {
  while true; do
    banner
    printf "${WHITE}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  0  ›  PAREAR / CONNECT                                    ║"
    echo "║  1  ›  LIMPEZA FORENSE                                     ║"
    echo "║  2  ›  MOSTRAR STATUS                                      ║"
    echo "║  3  ›  SAIR                                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    printf "${NC}\n"
    printf "${DIM}Dispositivo: ${NC}"
    if connected; then printf "${GREEN}CONECTADO${NC}\n"; else printf "${RED}DESCONECTADO${NC}\n"; fi
    echo
    read -r -p "Selecione uma opção: " op
    case "$op" in
      0) pair_device ;;
      1) clear_forensic ;;
      2) status_check ;;
      3) clear; echo "X67 Limpeza Forense encerrado."; exit 0 ;;
      *) printf "${RED}Opção inválida.${NC}\n"; sleep 1 ;;
    esac
  done
}

check_android || exit 1
check_adb || exit 1
menu
