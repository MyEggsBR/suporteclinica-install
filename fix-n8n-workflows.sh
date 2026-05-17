#!/bin/bash
# =============================================================================
# SuporteClinica — Fix: Importar workflows n8n
# =============================================================================

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' NC='\033[0m' BOLD='\033[1m'

echo -e "${BOLD}[Fix] Importando workflows n8n...${NC}"

WF_DIR="/opt/suporteclinica-setup/n8n-workflows"

if [ ! -d "$WF_DIR" ]; then
  echo -e "${R}[✗]${NC} Diretório não encontrado: $WF_DIR"
  exit 1
fi

WF_COUNT=$(ls -1 "$WF_DIR"/*.json 2>/dev/null | wc -l)
if [ "$WF_COUNT" -eq 0 ]; then
  echo -e "${R}[✗]${NC} Nenhum workflow JSON encontrado em $WF_DIR"
  exit 1
fi
echo -e "${G}[✓]${NC} $WF_COUNT workflows encontrados."

# Buscar user ID do n8n
N8N_USER_ID=$(docker exec clinica_postgres psql -U clinica -d n8n -t -c \
  "SELECT id FROM public.user LIMIT 1;" 2>/dev/null | tr -d ' \n')

if [ -z "$N8N_USER_ID" ]; then
  echo -e "${R}[✗]${NC} Não foi possível obter o user ID do n8n."
  exit 1
fi
echo -e "${G}[✓]${NC} n8n user ID: $N8N_USER_ID"

# Preprocessar JSONs
mkdir -p /tmp/wf_clean

python3 - << 'PYEOF'
import json, os, sys

wf_dir = "/opt/suporteclinica-setup/n8n-workflows"
out_dir = "/tmp/wf_clean"
strip_keys = [
    "projectId", "parentFolderId", "folderId",
    "shared", "tags", "activeVersion", "activeVersionId",
    "versionCounter", "triggerCount", "isArchived"
]

errors = 0
for fname in os.listdir(wf_dir):
    if not fname.endswith(".json"):
        continue
    try:
        with open(os.path.join(wf_dir, fname)) as f:
            wf = json.load(f)
        for k in strip_keys:
            wf.pop(k, None)
        with open(os.path.join(out_dir, fname), "w") as f:
            json.dump(wf, f)
        print(f"  OK: {fname}")
    except Exception as e:
        print(f"  ERRO: {fname}: {e}", file=sys.stderr)
        errors += 1

sys.exit(errors)
PYEOF

if [ $? -ne 0 ]; then
  echo -e "${R}[✗]${NC} Erro ao processar JSONs."
  rm -rf /tmp/wf_clean
  exit 1
fi
echo -e "${G}[✓]${NC} JSONs processados."

# Copiar para o container e importar
docker exec clinica_n8n mkdir -p /tmp/workflows
docker cp /tmp/wf_clean/. clinica_n8n:/tmp/workflows/

echo -e "  Importando..."
WF_OUT=$(docker exec clinica_n8n n8n import:workflow --separate --input=/tmp/workflows/ --userId="$N8N_USER_ID" 2>&1)
echo "$WF_OUT"

if echo "$WF_OUT" | grep -qi "imported\|success\|Done"; then
  echo -e "\n${G}[✓]${NC} Workflows importados com sucesso!"
else
  echo -e "\n${R}[✗]${NC} Importação falhou. Veja o log acima."
  rm -rf /tmp/wf_clean
  exit 1
fi

rm -rf /tmp/wf_clean
