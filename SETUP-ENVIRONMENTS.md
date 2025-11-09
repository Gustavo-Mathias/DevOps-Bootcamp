# Configuração de Environments (Homolog e Produção)

Este guia mostra como configurar os environments no GitHub e preparar o cluster Kubernetes.

## 📋 Visão Geral

A pipeline agora está dividida em:
- **CI**: Build, testes e push da imagem Docker
- **CD-Homolog**: Deploy automático no ambiente de homologação
- **CD-producao**: Deploy no ambiente de produção (requer aprovação manual)

Cada environment tem seus próprios secrets isolados, especialmente o `DATABASE_URL`.

---

## 🔧 Passo 1: Criar Namespaces no Kubernetes

Execute o script de setup:

```bash
# Tornar o script executável (Linux/Mac/WSL)
chmod +x scripts/setup-k8s-namespaces.sh

# Executar o script
./scripts/setup-k8s-namespaces.sh
```

Ou crie manualmente:

```bash
# Criar namespace de homologação
kubectl create namespace homolog

# Criar namespace de produção
kubectl create namespace producao

# Verificar namespaces criados
kubectl get namespaces | grep -E "(homolog|producao)"
```

---

## 🌐 Passo 2: Criar Environments no GitHub

### 2.1 - Acessar configurações do repositório

1. Acesse: `https://github.com/Gustavo-Mathias/DevOps-Bootcamp/settings/environments`
2. Ou navegue: **Settings** → **Environments** → **New environment**

### 2.2 - Criar Environment "homolog"

1. Clique em **New environment**
2. Nome: `homolog`
3. Clique em **Configure environment**
4. **NÃO** adicione regras de proteção (deploy será automático)
5. Na seção **Environment secrets**, clique em **Add secret**:

   **Secret 1:**
   - Name: `DATABASE_URL`
   - Value: `postgresql://user:pass@db-homolog.example.com:5432/encontros_tech_homolog`

   **Secret 2:**
   - Name: `KUBE_CONFIG`
   - Value: (cole o conteúdo do seu kubeconfig - mesmo que o atual)

### 2.3 - Criar Environment "producao"

1. Clique em **New environment**
2. Nome: `producao`
3. Clique em **Configure environment**
4. **IMPORTANTE - Adicione proteção**:
   - ✅ Marque **Required reviewers**
   - Adicione você mesmo como revisor
   - Isso exigirá aprovação manual antes do deploy em produção
5. Na seção **Environment secrets**, clique em **Add secret**:

   **Secret 1:**
   - Name: `DATABASE_URL`
   - Value: `postgresql://user:pass@db-prod.example.com:5432/encontros_tech_prod`

   **Secret 2:**
   - Name: `KUBE_CONFIG`
   - Value: (cole o conteúdo do seu kubeconfig - mesmo que o atual)

---

## 🔐 Passo 3: Remover Secret Global DATABASE_URL

Após configurar os environments, você **deve** remover o `DATABASE_URL` dos secrets globais:

1. Acesse: `https://github.com/Gustavo-Mathias/DevOps-Bootcamp/settings/secrets/actions`
2. Encontre `DATABASE_URL` na lista de **Repository secrets**
3. Clique em **Remove** ou no ícone de lixeira
4. Confirme a remoção

**⚠️ ATENÇÃO**:
- **MANTENHA** o `DOCKERHUB_TOKEN` como secret global (usado no job CI)
- **MANTENHA** o `KUBE_CONFIG` global se não quiser duplicar nos environments
- **REMOVA** apenas o `DATABASE_URL` global

---

## 🚀 Passo 4: Testar a Pipeline

### 4.1 - Fazer commit e push

```bash
git add .
git commit -m "Configure environments for homolog and producao"
git push
```

### 4.2 - Acompanhar a execução

1. Acesse: `https://github.com/Gustavo-Mathias/DevOps-Bootcamp/actions`
2. Você verá o fluxo:

```
┌─────────────┐
│     CI      │ ✓ Build e testes
└─────────────┘
       ↓
┌─────────────┐
│ CD-Homolog  │ ✓ Deploy automático (usa DATABASE_URL do env homolog)
└─────────────┘
       ↓
┌─────────────┐
│CD-producao ⏸️ Aguardando aprovação manual
└─────────────┘
```

### 4.3 - Aprovar deploy em produção

1. Na página do workflow, você verá **"CD-producao is waiting"**
2. Clique em **Review deployments**
3. Marque a checkbox **producao**
4. Clique em **Approve and deploy**
5. O deploy em produção será executado usando o `DATABASE_URL` do environment producao

---

## 📊 Estrutura Final

```
GitHub Repository
│
├── Repository Secrets (Globais)
│   ├── DOCKERHUB_TOKEN      ← Usado no CI
│   └── KUBE_CONFIG          ← Opcional (pode estar nos environments)
│
├── Environment: homolog
│   ├── DATABASE_URL         ← Banco de homologação
│   ├── KUBE_CONFIG          ← Kubeconfig (opcional)
│   └── Deployment Rules: Nenhuma (automático)
│
└── Environment: producao
    ├── DATABASE_URL         ← Banco de produção
    ├── KUBE_CONFIG          ← Kubeconfig (opcional)
    └── Deployment Rules: Aprovação manual obrigatória
```

---

## 🔍 Verificar Deployments

### Homologação
```bash
# Ver todos os recursos
kubectl get all -n homolog

# Ver pods
kubectl get pods -n homolog

# Ver logs
kubectl logs -l app=encontros-tech -n homolog --tail=50

# Ver qual imagem está rodando
kubectl get deployment encontros-tech -n homolog -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Produção
```bash
# Ver todos os recursos
kubectl get all -n producao

# Ver pods
kubectl get pods -n producao

# Ver logs
kubectl logs -l app=encontros-tech -n producao --tail=50

# Ver qual imagem está rodando
kubectl get deployment encontros-tech -n producao -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

## 💡 Dicas Importantes

### 1. URLs dos Environments

Atualize as URLs no arquivo `.github/workflows/main.yml` para os endereços reais:

**Homolog** (linha 49):
```yaml
environment:
  name: homolog
  url: http://seu-ip-homolog  # ou domínio
```

**producao** (linha 84):
```yaml
environment:
  name: producao
  url: http://129.212.196.133  # já configurado
```

### 2. Diferentes Bancos de Dados

**Exemplo de DATABASE_URL para homolog:**
```
postgresql://appuser:dev_password@10.0.1.50:5432/encontros_tech_dev
```

**Exemplo de DATABASE_URL para producao:**
```
postgresql://appuser:strong_prod_password@10.0.2.100:5432/encontros_tech_prod
```

### 3. Migrar Deployment Atual

Se você já tem deployment rodando no namespace `default`, escolha:

**Opção A: Migrar para os novos namespaces**
```bash
# Deploy vai criar automaticamente nos novos namespaces
# Depois delete do default:
kubectl delete deployment encontros-tech -n default
kubectl delete svc encontros-tech -n default
kubectl delete secret encontros-tech-secrets -n default
```

**Opção B: Usar default como producao**
Altere o namespace `producao` para `default` na pipeline (linha 64, 68, 74, 77).

---

## ✅ Checklist de Configuração

- [ ] Namespaces `homolog` e `producao` criados no Kubernetes
- [ ] Environment `homolog` criado no GitHub
- [ ] Environment `producao` criado no GitHub
- [ ] Secret `DATABASE_URL` adicionado ao environment `homolog`
- [ ] Secret `DATABASE_URL` adicionado ao environment `producao`
- [ ] Secret `KUBE_CONFIG` configurado (globalmente ou por environment)
- [ ] Regra de aprovação configurada no environment `producao`
- [ ] Secret global `DATABASE_URL` REMOVIDO do repositório
- [ ] Teste de deploy realizado com sucesso
- [ ] Deploy em homolog funcionando
- [ ] Deploy em produção aprovado e funcionando

---

## 🆘 Troubleshooting

### Erro: namespace "homolog" not found
```bash
kubectl create namespace homolog
```

### Erro: secret "DATABASE_URL" not found
Verifique se:
1. O secret está configurado no **environment** correto (não como secret global)
2. O nome do secret é exatamente `DATABASE_URL` (case-sensitive)
3. Você salvou o secret após criá-lo

### Deploy não pede aprovação
Verifique se:
1. Marcou **Required reviewers** no environment `producao`
2. Adicionou pelo menos um revisor (você mesmo)
3. Salvou as configurações

### Pipeline falha com "couldn't find environment"
1. Verifique se o nome do environment é exatamente `homolog` e `producao` (case-sensitive)
2. Aguarde alguns segundos - GitHub pode levar um tempo para propagar a criação

### KUBE_CONFIG não encontrado
Você pode:
1. Adicionar `KUBE_CONFIG` em cada environment, OU
2. Manter como secret global do repositório (funciona para ambos environments)

---

## ⚠️ Configuração Atual de Réplicas

Devido ao **limite de conexões do banco de dados compartilhado**, as réplicas foram ajustadas:

- **Homolog**: 1 réplica
- **producao**: 2 réplicas
- **Total**: 3 pods conectando ao banco

**Configurado no manifest**: `replicas: 2`

### Como aumentar as réplicas no futuro

**Opção 1: Configurar bancos separados (RECOMENDADO)**
1. Criar banco de dados separado para cada ambiente
2. Configurar `DATABASE_URL` diferente em cada environment do GitHub:
   - Homolog: banco de desenvolvimento/staging
   - producao: banco de produção
3. Atualizar `replicas: 3` no manifest.yaml
4. Fazer novo deploy

**Opção 2: Upgrade do plano do banco**
1. Aumentar o limite de conexões no DigitalOcean
2. Atualizar `replicas: 3` no manifest.yaml
3. Fazer novo deploy

---

## 🎯 Próximos Passos (Opcional)

1. **Bancos separados**: Criar banco de dados exclusivo para produção (RECOMENDADO)
2. **Configurar domínios**: Apontar DNS para os IPs dos LoadBalancers
3. **HTTPS**: Adicionar certificados SSL com cert-manager
4. **Monitoramento**: Configurar Prometheus/Grafana
5. **Alertas**: Configurar notificações de deploy
6. **Branch protection**: Configurar proteção da branch main
