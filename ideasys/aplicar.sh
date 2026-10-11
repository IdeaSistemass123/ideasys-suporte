#!/usr/bin/env bash
# Personalizacao IdeaSys sobre o codigo do RustDesk.
# Roda na raiz do repositorio, DEPOIS do checkout com submodulos.
set -euo pipefail

SERVIDOR="suporte.ideasysapp.com.br"
CHAVE="N27etiLttIIPEwsEFk8SfxzGwBS15xKD8XvCNeD1uY0="
NOME="IdeaSys"
DESCRICAO="IdeaSys - Suporte especializado Idea Sistemas"
EMPRESA="Idea Sistemas"

CFG=libs/hbb_common/src/config.rs

# servidor de ID/relay e chave fixos no programa
sed -i "s|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"$SERVIDOR\"];|" "$CFG"
sed -i "s|^pub const RS_PUB_KEY: &str = \".*\";|pub const RS_PUB_KEY: \&str = \"$CHAVE\";|" "$CFG"
# nome do programa (pasta de instalacao, servico, atalhos, titulo)
sed -i "s|APP_NAME: RwLock<String> = RwLock::new(\"RustDesk\".to_owned())|APP_NAME: RwLock<String> = RwLock::new(\"$NOME\".to_owned())|" "$CFG"

grep -q "\"$SERVIDOR\"" "$CFG" || { echo "falhou: servidor"; exit 1; }
grep -q "\"$CHAVE\"" "$CFG" || { echo "falhou: chave"; exit 1; }
grep -q "RwLock::new(\"$NOME\".to_owned())" "$CFG" || { echo "falhou: nome"; exit 1; }

# propriedades do executavel (Windows)
RC=flutter/windows/runner/Runner.rc
sed -i "s|VALUE \"CompanyName\", \".*\" \"\\\\0\"|VALUE \"CompanyName\", \"$EMPRESA\" \"\\\\0\"|" "$RC"
sed -i "s|VALUE \"FileDescription\", \".*\" \"\\\\0\"|VALUE \"FileDescription\", \"$DESCRICAO\" \"\\\\0\"|" "$RC"
sed -i "s|VALUE \"ProductName\", \".*\" \"\\\\0\"|VALUE \"ProductName\", \"$NOME\" \"\\\\0\"|" "$RC"
grep -q "\"$DESCRICAO\"" "$RC" || { echo "falhou: Runner.rc"; exit 1; }

# icones e logo
cp ideasys/icone.ico flutter/windows/runner/resources/app_icon.ico
cp ideasys/icone.ico res/icon.ico
cp ideasys/tray.ico  res/tray-icon.ico
cp ideasys/icone.png res/icon.png
cp ideasys/icone.png flutter/assets/icon.png
cp ideasys/logo.png  flutter/assets/logo.png

echo "Personalizacao IdeaSys aplicada:"
grep -n -E "^pub const RENDEZVOUS_SERVERS|^pub const RS_PUB_KEY|APP_NAME: RwLock" "$CFG"
grep -n -E "CompanyName|FileDescription|ProductName" "$RC"
