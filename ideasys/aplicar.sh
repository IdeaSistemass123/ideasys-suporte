#!/usr/bin/env bash
# Personalizacao "Suporte IdeaSoft" sobre o codigo do RustDesk.
# Roda na raiz do repositorio, DEPOIS do checkout com submodulos.
set -euo pipefail

SERVIDOR="suporte.ideasys.com.br"
CHAVE="N27etiLttIIPEwsEFk8SfxzGwBS15xKD8XvCNeD1uY0="
API="https://suporte.ideasys.com.br"
# NOME interno SEM ESPACO: vira servico do Windows, pasta, nome do .exe e esquema de link,
# e o RustDesk monta comandos "sc stop NOME" / "taskkill /IM NOME.exe" sem aspas.
NOME="SuporteIdeaSoft"
NOME_EXIBIDO="Suporte IdeaSoft"
DESCRICAO="Suporte IdeaSoft - Suporte especializado Idea Sistemas"
EMPRESA="Idea Sistemas"

CFG=libs/hbb_common/src/config.rs

# servidor de ID/relay e chave fixos no programa
sed -i "s|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"$SERVIDOR\"];|" "$CFG"
sed -i "s|^pub const RS_PUB_KEY: &str = \".*\";|pub const RS_PUB_KEY: \&str = \"$CHAVE\";|" "$CFG"
# nome do programa (pasta de instalacao, servico, atalhos, titulo)
sed -i "s|APP_NAME: RwLock<String> = RwLock::new(\"RustDesk\".to_owned())|APP_NAME: RwLock<String> = RwLock::new(\"$NOME\".to_owned())|" "$CFG"

# API propria (heartbeat, dados da maquina e auditoria de sessoes -> painel em /painel).
# Sem isso o endereco cai no admin.rustdesk.com e o cliente desliga o envio.
sed -i "s|^    \"https://admin.rustdesk.com\".to_owned()$|    \"$API\".to_owned()|" src/common.rs
grep -q "^    \"$API\".to_owned()$" src/common.rs || { echo "falhou: api"; exit 1; }

grep -q "\"$SERVIDOR\"" "$CFG" || { echo "falhou: servidor"; exit 1; }
grep -q "\"$CHAVE\"" "$CFG" || { echo "falhou: chave"; exit 1; }
grep -q "RwLock::new(\"$NOME\".to_owned())" "$CFG" || { echo "falhou: nome"; exit 1; }

# propriedades do executavel (Windows)
RC=flutter/windows/runner/Runner.rc
sed -i "s|VALUE \"CompanyName\", \".*\" \"\\\\0\"|VALUE \"CompanyName\", \"$EMPRESA\" \"\\\\0\"|" "$RC"
sed -i "s|VALUE \"FileDescription\", \".*\" \"\\\\0\"|VALUE \"FileDescription\", \"$DESCRICAO\" \"\\\\0\"|" "$RC"
sed -i "s|VALUE \"ProductName\", \".*\" \"\\\\0\"|VALUE \"ProductName\", \"$NOME_EXIBIDO\" \"\\\\0\"|" "$RC"
sed -i "s|VALUE \"OriginalFilename\", \".*\" \"\\\\0\"|VALUE \"OriginalFilename\", \"$NOME.exe\" \"\\\\0\"|" "$RC"
grep -q "\"$DESCRICAO\"" "$RC" || { echo "falhou: Runner.rc"; exit 1; }

# propriedades do empacotador portatil e da dll (winres nos Cargo.toml)
for T in Cargo.toml libs/portable/Cargo.toml; do
  sed -i "s|^ProductName = \".*\"|ProductName = \"$NOME_EXIBIDO\"|" "$T"
  sed -i "/^ProductName = /a CompanyName = \"$EMPRESA\"" "$T"
  sed -i "s|^FileDescription = \".*\"|FileDescription = \"$DESCRICAO\"|" "$T"
  sed -i "s|^OriginalFilename = \".*\"|OriginalFilename = \"$NOME.exe\"|" "$T"
  grep -q "^FileDescription = \"$DESCRICAO\"" "$T" || { echo "falhou: $T"; exit 1; }
done

# icones e logo
cp ideasys/icone.ico flutter/windows/runner/resources/app_icon.ico
cp ideasys/icone.ico res/icon.ico
cp ideasys/tray.ico  res/tray-icon.ico
cp ideasys/icone.png res/icon.png
cp ideasys/icone.png flutter/assets/icon.png
cp ideasys/logo.png  flutter/assets/logo.png

echo "Personalizacao $NOME_EXIBIDO aplicada:"
grep -n -E "^pub const RENDEZVOUS_SERVERS|^pub const RS_PUB_KEY|APP_NAME: RwLock" "$CFG"
grep -n -E "CompanyName|FileDescription|ProductName|OriginalFilename" "$RC" Cargo.toml libs/portable/Cargo.toml
# o workflow le o nome do .exe daqui
[ -n "${GITHUB_ENV:-}" ] && echo "APP_EXE=$NOME" >> "$GITHUB_ENV" || true
