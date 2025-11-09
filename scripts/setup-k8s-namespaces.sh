#!/bin/bash

# Script para configurar namespaces no Kubernetes para homolog e producao
# Uso: ./scripts/setup-k8s-namespaces.sh

set -e

echo "🚀 Configurando namespaces no Kubernetes..."
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Criar namespace de homologação
echo -e "${YELLOW}Criando namespace 'homolog'...${NC}"
if kubectl get namespace homolog &> /dev/null; then
    echo -e "${GREEN}✓ Namespace 'homolog' já existe${NC}"
else
    kubectl create namespace homolog
    echo -e "${GREEN}✓ Namespace 'homolog' criado com sucesso${NC}"
fi

echo ""

# Criar namespace de produção
echo -e "${YELLOW}Criando namespace 'proproducaoduction'...${NC}"
if kubectl get namespace producao &> /dev/null; then
    echo -e "${GREEN}✓ Namespace 'producao' já existe${NC}"
else
    kubectl create namespace producao
    echo -e "${GREEN}✓ Namespace 'producao' criado com sucesso${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ Namespaces configurados com sucesso!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar todos os namespaces
echo "📋 Namespaces disponíveis:"
kubectl get namespaces

echo ""
echo "📝 Próximos passos:"
echo "1. Configure os environments no GitHub:"
echo "   https://github.com/Gustavo-Mathias/DevOps-Bootcamp/settings/environments"
echo ""
echo "2. Adicione os secrets em cada environment:"
echo "   - DATABASE_URL (diferente para homolog e producao)"
echo "   - KUBE_CONFIG (pode ser o mesmo)"
echo ""
echo "3. Configure aprovação manual para o environment 'producao'"
echo ""
echo "4. Faça commit e push para testar a pipeline"
echo ""
