#!/bin/bash
# =============================================================================
# SuporteClinica — Instalador Bootstrap
# =============================================================================

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' BOLD='\033[1m' NC='\033[0m'

clear
echo -e "${BOLD}${B}"
cat << 'EOF'
  ╔══════════════════════════════════════════════════════╗
  ║       SuporteClinica — Instalação do Sistema         ║
  ║   Bot WhatsApp + Agenda + Atendimento Integrado      ║
  ╚══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo -e "  Este instalador irá baixar e configurar todo o sistema."
echo -e "  ${Y}Pré-requisito:${NC} você precisa de um token de acesso fornecido"
echo -e "  pelo suporte SuporteClinica para continuar."
echo ""
echo -e "  ${C}────────────────────────────────────────────────────────${NC}"
echo ""

# ── Solicitar token ──────────────────────────────────────────────────────────
echo -e "  Cole o token de acesso abaixo e pressione ENTER:"
echo -e "  ${Y}(O token não ficará visível enquanto você digita)${NC}"
echo ""
printf "  Token: "
read -rs ACCESS_TOKEN
echo ""

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "\n  ${R}[✗]${NC} Token não informado. Encerrando."
  exit 1
fi

echo ""
echo -e "  ${G}[✓]${NC} Token recebido. Verificando acesso..."

# ── Verificar token ──────────────────────────────────────────────────────────
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $ACCESS_TOKEN" \
  "https://api.github.com/repos/MyEggsBR/Chatbot-Clinica-Medica" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" != "200" ]; then
  echo -e "  ${R}[✗]${NC} Token inválido ou sem acesso ao repositório (código: $HTTP_CODE)."
  echo -e "  Entre em contato com o suporte SuporteClinica para obter um token válido."
  exit 1
fi

echo -e "  ${G}[✓]${NC} Acesso confirmado!"
echo ""

# ── Verificar dependências mínimas ───────────────────────────────────────────
command -v git &>/dev/null || { apt-get install -y -qq git 2>/dev/null || { echo -e "  ${R}[✗]${NC} git não encontrado. Instale com: apt-get install git"; exit 1; }; }

# ── Clonar repositório ───────────────────────────────────────────────────────
INSTALL_DIR="/opt/suporteclinica-setup"

echo -e "  ${G}[✓]${NC} Baixando arquivos de instalação..."

if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
fi

git clone --quiet --branch feature/whitelabel-superadmin \
  "https://$ACCESS_TOKEN@github.com/MyEggsBR/Chatbot-Clinica-Medica.git" \
  "$INSTALL_DIR" 2>/dev/null

if [ ! -f "$INSTALL_DIR/install.sh" ]; then
  echo -e "  ${R}[✗]${NC} Falha ao baixar os arquivos. Verifique sua conexão e tente novamente."
  exit 1
fi

echo -e "  ${G}[✓]${NC} Arquivos baixados com sucesso!"
echo ""
echo -e "  ${C}────────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}Iniciando instalação completa do sistema...${NC}"
echo -e "  ${C}────────────────────────────────────────────────────────${NC}"
echo ""
sleep 2

# ── Executar instalador principal ────────────────────────────────────────────
chmod +x "$INSTALL_DIR/install.sh"
exec bash "$INSTALL_DIR/install.sh"
