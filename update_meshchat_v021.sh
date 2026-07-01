#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== Mesh Chat v0.2.1 - estabilização Nearby =="

cd "$HOME/Projetos/MeshChat"

if ! command -v python >/dev/null 2>&1; then
    echo "Python não encontrado. Instalando python no Termux..."
    pkg install python -y
fi

python <<'PY'
from pathlib import Path

def replace_or_fail(path_str, old, new, label):
    path = Path(path_str)
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"ERRO: trecho não encontrado para {label} em {path_str}")
    path.write_text(text.replace(old, new))

# Versão Gradle
replace_or_fail(
    "app/build.gradle.kts",
    'versionCode = 3\n        versionName = "0.2.0"',
    'versionCode = 4\n        versionName = "0.2.1"',
    "versão do app"
)

# Versão no app
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    'private const val APP_VERSION = "v0.2.0"',
    'private const val APP_VERSION = "v0.2.1"',
    "APP_VERSION"
)

# Evitar iniciar offline repetido
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''    fun startOffline() {
        startAdvertising()
        startDiscovery()
    }
''',
    '''    fun startOffline() {
        if (isAdvertising && isDiscovering) {
            addLog("Modo offline já está ativo")
            return
        }

        if (!isAdvertising) {
            startAdvertising()
        } else {
            addLog("Visibilidade já ativa")
        }

        if (!isDiscovering) {
            startDiscovery()
        } else {
            addLog("Scanner já ativo")
        }
    }
''',
    "startOffline"
)

# Adicionar limpar eventos e mensagens
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''        addLog("Modo offline parado")
    }

    private fun startAdvertising() {
''',
    '''        addLog("Modo offline parado")
    }

    fun clearEvents() {
        logs = emptyList()
    }

    fun clearNearbyMessages() {
        nearbyMessages = emptyList()
        addLog("Mensagens locais limpas")
    }

    private fun startAdvertising() {
''',
    "funções clear"
)

# Tratar STATUS_ALREADY_ADVERTISING como estado ativo
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''        }.addOnFailureListener { error ->
            isAdvertising = false
            addLog("Falha ao ficar visível: ${error.message ?: "sem detalhe"}")
        }
''',
    '''        }.addOnFailureListener { error ->
            val detail = error.message ?: "sem detalhe"

            if (
                detail.contains("STATUS_ALREADY_ADVERTISING", ignoreCase = true) ||
                detail.contains("8001")
            ) {
                isAdvertising = true
                addLog("Visibilidade já estava ativa")
            } else {
                isAdvertising = false
                addLog("Falha ao ficar visível: $detail")
            }
        }
''',
    "already advertising"
)

# Tratar STATUS_ALREADY_DISCOVERING como estado ativo
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''        }.addOnFailureListener { error ->
            isDiscovering = false
            addLog("Falha no scanner: ${error.message ?: "sem detalhe"}")
        }
''',
    '''        }.addOnFailureListener { error ->
            val detail = error.message ?: "sem detalhe"

            if (
                detail.contains("STATUS_ALREADY_DISCOVERING", ignoreCase = true) ||
                detail.contains("8002")
            ) {
                isDiscovering = true
                addLog("Scanner já estava ativo")
            } else {
                isDiscovering = false
                addLog("Falha no scanner: $detail")
            }
        }
''',
    "already discovering"
)

# Melhorar aviso de mensagem sem peer
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''        if (connectedEndpointIds.isEmpty()) {
            addLog("Mensagem criada, mas nenhum peer está conectado")
            return
        }
''',
    '''        if (connectedEndpointIds.isEmpty()) {
            addLog("Nenhum peer conectado. A mensagem ficou apenas local nesta sessão")
            return
        }
''',
    "mensagem sem peer"
)

# Botão iniciar offline com estado correto
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''                    FilledTonalButton(
                        onClick = { nearbyController.startOffline() },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text("Iniciar offline")
                    }
''',
    '''                    FilledTonalButton(
                        onClick = { nearbyController.startOffline() },
                        enabled = !(nearbyController.isAdvertising && nearbyController.isDiscovering),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text(
                            if (nearbyController.isAdvertising || nearbyController.isDiscovering) {
                                "Offline ativo"
                            } else {
                                "Iniciar offline"
                            }
                        )
                    }
''',
    "botão offline ativo"
)

# Botão limpar eventos
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''        item {
            Text(
                text = "Eventos",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        if (nearbyController.logs.isEmpty()) {
''',
    '''        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Eventos",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )

                if (nearbyController.logs.isNotEmpty()) {
                    TextButton(onClick = { nearbyController.clearEvents() }) {
                        Text("Limpar")
                    }
                }
            }
        }

        if (nearbyController.logs.isEmpty()) {
''',
    "botão limpar eventos"
)

# Atualizar card principal
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''                text = "Primeira camada offline real: permissões, descoberta, visibilidade, conexão e envio de texto curto entre Androids próximos.",
''',
    '''                text = "Nearby estabilizado: permissões, descoberta, visibilidade, conexão, envio rápido e estados mais claros para testes offline.",
''',
    "texto card principal"
)

# Atualizar próximo alvo
replace_or_fail(
    "app/src/main/java/com/sw/meshchat/MainActivity.kt",
    '''                value = "v0.2.1",
                detail = "Melhorar conexão, reconexão e experiência entre dois aparelhos."
''',
    '''                value = "v0.2.2",
                detail = "Salvar dispositivos encontrados como contatos Mesh persistentes."
''',
    "próximo alvo"
)

# Workflow artifact
replace_or_fail(
    ".github/workflows/android-debug.yml",
    "MeshChat-v0.2.0-debug-apk",
    "MeshChat-v0.2.1-debug-apk",
    "artifact v0.2.1"
)

print("v0.2.1 aplicada com sucesso.")
PY

echo "== v0.2.1 pronta localmente =="
echo "Agora rode: git status"
