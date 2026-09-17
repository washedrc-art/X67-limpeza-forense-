#!/bin/bash
# Instalador do Bypass X67

clear
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🌸  INSTALADOR BYPASS X67  🌸                           ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Verificar Termux
if [[ "$PREFIX" != *"com.termux"* ]]; then
    echo "⚠️  Este script é otimizado para Termux!"
    echo "Continuando mesmo assim..."
    echo ""
fi

echo "📦 Instalando dependências..."
pkg update -y
pkg install -y android-tools

# Criar diretório
INSTALL_DIR="$HOME/Bypass-X67"
mkdir -p "$INSTALL_DIR"

# Copiar arquivos
echo "📁 Copiando arquivos..."
cp bypass_x67.sh "$INSTALL_DIR/"
cp packages.conf "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/bypass_x67.sh"

# Criar atalho
echo "🔗 Criando atalho..."
echo '#!/bin/bash
cd "$HOME/Bypass-X67" && bash bypass_x67.sh' > "$PREFIX/bin/bypass-x67"
chmod +x "$PREFIX/bin/bypass-x67"

echo ""
echo "✅ Instalação concluída!"
echo ""
echo "🎮 Para iniciar o painel, execute:"
echo "   bypass-x67"
echo ""
echo "   Ou manualmente:"
echo "   cd $INSTALL_DIR && bash bypass_x67.sh"
echo ""