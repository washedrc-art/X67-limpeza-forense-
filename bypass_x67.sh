#!/bin/bash
# Bypass X67 - Painel de Limpeza ADB
# Criado para Termux
# Versão: 1.0.0

# ╔══════════════════════════════════════════════════════════════╗
# ║                    🌸 BYPASS X67 🌸                          ║
# ║              Bypass forense for x67 👑🔑🔨                   ║
# ╚══════════════════════════════════════════════════════════════╝

# Cores e estilos
RESET='\033[0m'
PINK='\033[38;5;213m'
PURPLE='\033[38;5;141m'
CYAN='\033[38;5;81m'
GREEN='\033[38;5;82m'
YELLOW='\033[38;5;227m'
RED='\033[38;5;196m'
WHITE='\033[38;5;255m'
BOLD='\033[1m'

# Carregar packages
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.conf"

if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo -e "${RED}❌ Arquivo packages.conf não encontrado!${RESET}"
    exit 1
fi

mapfile -t PACKAGES < "$PACKAGES_FILE"

# Funções de UI
print_banner() {
    clear
    echo -e "${PURPLE}"
    echo "    ╔═══════════════════════════════════════════════════════════╗"
    echo "    ║                                                           ║"
    echo "    ║   🌸  ${PINK}${BOLD}B Y P A S S   X 6 7${RESET}${PURPLE}  🌸                          ║"
    echo "    ║                                                           ║"
    echo "    ║   ${CYAN}Painel Bypass forense for proxy${PURPLE}                          ║"
    echo "    ║   ${YELLOW}✨ Remova packages proxy life✨${PURPLE}                      ║"
    echo "    ║                                                           ║"
    echo "    ╚═══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_separator() {
    echo -e "${PURPLE}    ───────────────────────────────────────────────────────────${RESET}"
}

print_success() {
    echo -e "${GREEN}    ✅ $1${RESET}"
}

print_error() {
    echo -e "${RED}    ❌ $1${RESET}"
}

print_info() {
    echo -e "${CYAN}    ℹ️  $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}    ⚠️  $1${RESET}"
}

# Funções de ADB
check_adb() {
    print_separator
    echo -e "${PINK}${BOLD}    🔍 Verificando conexão ADB...${RESET}"
    print_separator
    
    if ! command -v adb &> /dev/null; then
        print_error "ADB não está instalado!"
        print_info "Instale com: pkg install android-tools"
        return 1
    fi
    
    local devices=$(adb devices | grep -E "^[0-9]+" | wc -l)
    
    if [[ $devices -eq 0 ]]; then
        print_error "Nenhum dispositivo conectado!"
        print_info "Execute primeiro: adb pair localhost:PORTA"
        print_info "Depois: adb connect localhost:PORTA"
        return 1
    fi
    
    local device_info=$(adb shell getprop ro.product.model 2>/dev/null || echo "Desconhecido")
    local android_ver=$(adb shell getprop ro.build.version.release 2>/dev/null || echo "?")
    
    print_success "Dispositivo conectado! 📱"
    print_info "Modelo: $device_info"
    print_info "Android: $android_ver"
    print_info "Dispositivos: $devices"
    
    return 0
}

check_packages() {
    print_separator
    echo -e "${PINK}${BOLD}    📦 Verificando packages instalados...${RESET}"
    print_separator
    
    local found_count=0
    local installed_packages=$(adb shell pm list packages 2>/dev/null)
    
    echo ""
    echo -e "${CYAN}    📋 Packages na lista de verificação:${RESET}"
    print_separator
    
    for pkg in "${PACKAGES[@]}"; do
        [[ -z "$pkg" ]] && continue
        
        if echo "$installed_packages" | grep -q "$pkg"; then
            echo -e "${RED}    ❌ ENCONTRADO: ${WHITE}$pkg${RESET}"
            ((found_count++))
        else
            echo -e "${GREEN}    ✅ Limpo: ${WHITE}$pkg${RESET}"
        fi
    done
    
    print_separator
    if [[ $found_count -gt 0 ]]; then
        print_warning "Foram encontrados $found_count packages suspeitos!"
        print_info "Use a Opção 2 para iniciar o bypass"
    else
        print_success "Nenhum package suspeito encontrado! 🎉"
    fi
    
    echo ""
    read -p "$(echo -e ${CYAN}    Pressione ENTER para continuar...${RESET})"
}

bypass_cleanup() {
    print_separator
    echo -e "${PINK}${BOLD}    🧹 Iniciando Bypass - Limpeza Completa...${RESET}"
    print_separator
    
    if ! check_adb_silent; then
        return 1
    fi
    
    local removed=0
    local failed=0
    
    echo ""
    print_info "Desinstalando packages da lista..."
    print_separator
    
    for pkg in "${PACKAGES[@]}"; do
        [[ -z "$pkg" ]] && continue
        
        echo -ne "${YELLOW}    Processando: ${WHITE}$pkg... ${RESET}"
        
        # Tentar desinstalar para o usuário atual
        local result=$(adb shell pm uninstall --user 0 "$pkg" 2>&1)
        
        if [[ $? -eq 0 ]] || [[ "$result" == *"Success"* ]]; then
            echo -e "${GREEN}REMOVIDO ✓${RESET}"
            ((removed++))
        else
            # Tentar desinstalar completamente
            result=$(adb shell pm uninstall "$pkg" 2>&1)
            if [[ $? -eq 0 ]] || [[ "$result" == *"Success"* ]]; then
                echo -e "${GREEN}REMOVIDO ✓${RESET}"
                ((removed++))
            else
                echo -e "${RED}FALHOU ✗${RESET}"
                ((failed++))
            fi
        fi
        
        # Limpar dados independentemente
        adb shell pm clear "$pkg" &>/dev/null
    done
    
    print_separator
    print_success "Limpeza concluída!"
    print_info "Removidos: $removed | Falhas: $failed"
    
    echo ""
    print_info "Limpando cache do sistema..."
    adb shell pm trim-caches 2G &>/dev/null
    
    print_success "Cache limpo!"
    
    echo ""
    read -p "$(echo -e ${CYAN}    Pressione ENTER para continuar...${RESET})"
}

check_adb_silent() {
    if ! command -v adb &> /dev/null; then
        return 1
    fi
    
    local devices=$(adb devices | grep -E "^[0-9]+" | wc -l)
    [[ $devices -gt 0 ]] && return 0 || return 1
}

connect_adb() {
    print_separator
    echo -e "${PINK}${BOLD}    🔌 Conectar ADB${RESET}"
    print_separator
    
    echo ""
    print_info "Digite a porta de emparelhamento:"
    echo -ne "${CYAN}    Porta: ${RESET}"
    read porta
    
    if [[ -z "$porta" ]]; then
        print_error "Porta inválida!"
        return 1
    fi
    
    print_info "Emparelhando com localhost:$porta..."
    adb pair localhost:$porta
    
    print_info "Conectando..."
    adb connect localhost:$porta
    
    if check_adb_silent; then
        print_success "Conectado com sucesso! 🎉"
    else
        print_error "Falha na conexão!"
    fi
    
    echo ""
    read -p "$(echo -e ${CYAN}    Pressione ENTER para continuar...${RESET})"
}

# Menu principal
show_menu() {
    print_banner
    print_separator
    echo -e "${CYAN}${BOLD}    📱 MENU PRINCIPAL${RESET}"
    print_separator
    echo ""
    echo -e "${PINK}    [1] 🔍 Verificar ADB${RESET}          - Ver se está conectado"
    echo -e "${PINK}    [2] 🔌 Conectar ADB${RESET}          - Pair e Connect"
    echo -e "${PINK}    [3] 📦 Verificar Packages${RESET}    - Checar packages suspeitos"
    echo -e "${PINK}    [4] 🧹 Iniciar Bypass${RESET}        - Limpar todos os packages"
    echo -e "${PINK}    [5] 📋 Lista de Packages${RESET}    - Ver packages configurados"
    echo -e "${PINK}    [0] 🚪 Sair${RESET}                  - Fechar o painel"
    echo ""
    print_separator
    echo ""
}

show_packages_list() {
    print_separator
    echo -e "${PINK}${BOLD}    📋 Packages Configurados${RESET}"
    print_separator
    echo ""
    
    local count=1
    for pkg in "${PACKAGES[@]}"; do
        [[ -z "$pkg" ]] && continue
        printf "${CYAN}    %2d.${RESET} %s\n" "$count" "$pkg"
        ((count++))
    done
    
    echo ""
    print_info "Total: $((count-1)) packages na lista"
    echo ""
    read -p "$(echo -e ${CYAN}    Pressione ENTER para continuar...${RESET})"
}

# Loop principal
main() {
    while true; do
        show_menu
        
        echo -ne "${YELLOW}    Escolha uma opção: ${RESET}"
        read opcao
        
        case $opcao in
            1)
                check_adb
                ;;
            2)
                connect_adb
                ;;
            3)
                check_packages
                ;;
            4)
                bypass_cleanup
                ;;
            5)
                show_packages_list
                ;;
            0)
                print_separator
                echo -e "${GREEN}${BOLD}    👋 Obrigado por usar o Bypass X67!${RESET}"
                echo -e "${PINK}    🌸 Até a próxima! 🌸${RESET}"
                print_separator
                echo ""
                exit 0
                ;;
            *)
                print_error "Opção inválida!"
                sleep 1
                ;;
        esac
    done
}

# Iniciar
main