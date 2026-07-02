#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== Mesh Chat v0.2.2 - Contatos Mesh salvos =="

cd "$HOME/Projetos/MeshChat"

if ! command -v python >/dev/null 2>&1; then
    echo "Python não encontrado. Instalando python no Termux..."
    pkg install python -y
fi

python <<'PY'
from pathlib import Path

MAIN = Path("app/src/main/java/com/sw/meshchat/MainActivity.kt")
GRADLE = Path("app/build.gradle.kts")
WORKFLOW = Path(".github/workflows/android-debug.yml")

def read(path):
    return path.read_text()

def write(path, text):
    path.write_text(text)

def replace_or_fail(text, old, new, label):
    if old not in text:
        raise SystemExit(f"ERRO: trecho não encontrado para {label}")
    return text.replace(old, new)

# =========================
# Gradle version
# =========================
gradle = read(GRADLE)
gradle = gradle.replace(
    'versionCode = 4\n        versionName = "0.2.1"',
    'versionCode = 5\n        versionName = "0.2.2"'
)
write(GRADLE, gradle)

# =========================
# Workflow artifact
# =========================
workflow = read(WORKFLOW)
workflow = workflow.replace("MeshChat-v0.2.1-debug-apk", "MeshChat-v0.2.2-debug-apk")
workflow = workflow.replace("MeshChat-v0.2.0-debug-apk", "MeshChat-v0.2.2-debug-apk")
write(WORKFLOW, workflow)

# =========================
# MainActivity changes
# =========================
text = read(MAIN)

text = text.replace('private const val APP_VERSION = "v0.2.1"', 'private const val APP_VERSION = "v0.2.2"')
text = text.replace('private const val APP_VERSION = "v0.2.0"', 'private const val APP_VERSION = "v0.2.2"')

# Imports
if "import org.json.JSONArray" not in text:
    text = text.replace(
        "import java.util.Locale\n",
        "import java.util.Locale\nimport java.util.UUID\nimport org.json.JSONArray\nimport org.json.JSONObject\n"
    )

# Add saved contact model
if "data class MeshSavedContact" not in text:
    text = text.replace(
        '''data class NearbyTextMessage(
    val text: String,
    val mine: Boolean,
    val time: String,
    val from: String
)
''',
        '''data class NearbyTextMessage(
    val text: String,
    val mine: Boolean,
    val time: String,
    val from: String
)

data class MeshSavedContact(
    val key: String,
    val name: String,
    val lastSeen: String,
    val status: String
)
'''
    )

# Add contact store before controller
if "class MeshContactStore" not in text:
    text = text.replace(
        "class MeshNearbyController(private val context: Context) {",
        '''class MeshContactStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("mesh_contacts_store", Context.MODE_PRIVATE)

    fun localId(): String {
        val current = prefs.getString("local_id", null)
        if (!current.isNullOrBlank()) return current

        val created = UUID.randomUUID().toString()
        prefs.edit().putString("local_id", created).apply()
        return created
    }

    fun loadContacts(): List<MeshSavedContact> {
        val raw = prefs.getString("contacts_json", "[]") ?: "[]"

        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<MeshSavedContact>()

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                result.add(
                    MeshSavedContact(
                        key = item.optString("key"),
                        name = item.optString("name"),
                        lastSeen = item.optString("lastSeen"),
                        status = item.optString("status")
                    )
                )
            }

            result.filter { it.name.isNotBlank() }
                .distinctBy { it.key }
                .sortedBy { it.name.lowercase(Locale.getDefault()) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun upsertContact(name: String, status: String) {
        val cleanName = name.trim()
        if (cleanName.isBlank()) return

        val key = cleanName.lowercase(Locale.getDefault())
        val now = SimpleDateFormat("dd/MM HH:mm", Locale.getDefault()).format(Date())

        val current = loadContacts().filterNot { it.key == key }.toMutableList()
        current.add(
            MeshSavedContact(
                key = key,
                name = cleanName,
                lastSeen = now,
                status = status
            )
        )

        val array = JSONArray()
        current.sortedBy { it.name.lowercase(Locale.getDefault()) }.forEach { contact ->
            val item = JSONObject()
            item.put("key", contact.key)
            item.put("name", contact.name)
            item.put("lastSeen", contact.lastSeen)
            item.put("status", contact.status)
            array.put(item)
        }

        prefs.edit().putString("contacts_json", array.toString()).apply()
    }

    fun clearContacts() {
        prefs.edit().remove("contacts_json").apply()
    }
}

class MeshNearbyController(private val context: Context) {'''
    )

# Make local identity more stable
text = text.replace(
    '''    private val client: ConnectionsClient = Nearby.getConnectionsClient(context)
    private val strategy: Strategy = Strategy.P2P_CLUSTER
    private val localName: String = "Mesh-${Build.MODEL.take(14)}"
''',
    '''    private val client: ConnectionsClient = Nearby.getConnectionsClient(context)
    private val strategy: Strategy = Strategy.P2P_CLUSTER
    private val contactStore = MeshContactStore(context)
    private val localId: String = contactStore.localId()
    private val localName: String = "Mesh-${Build.MODEL.take(10)}-${localId.take(4)}"
'''
)

# Add savedContacts state
if "var savedContacts by mutableStateOf" not in text:
    text = text.replace(
        '''    private val connectedEndpointIds = mutableSetOf<String>()
    private val peerNames = mutableMapOf<String, String>()

    var isAdvertising by mutableStateOf(false)
''',
        '''    private val connectedEndpointIds = mutableSetOf<String>()
    private val peerNames = mutableMapOf<String, String>()

    var savedContacts by mutableStateOf(contactStore.loadContacts())
        private set

    var isAdvertising by mutableStateOf(false)
'''
    )

# Save contact on connection initiated
text = text.replace(
    '''        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            peerNames[endpointId] = connectionInfo.endpointName
            updatePeer(endpointId, connectionInfo.endpointName, "Aceitando conexão")
            addLog("Conexão iniciada com ${connectionInfo.endpointName}")
''',
    '''        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            peerNames[endpointId] = connectionInfo.endpointName
            saveMeshContact(connectionInfo.endpointName, "Solicitando")
            updatePeer(endpointId, connectionInfo.endpointName, "Aceitando conexão")
            addLog("Conexão iniciada com ${connectionInfo.endpointName}")
'''
)

# Save contact when connected
text = text.replace(
    '''            if (result.status.statusCode == ConnectionsStatusCodes.STATUS_OK) {
                connectedEndpointIds.add(endpointId)
                updatePeer(endpointId, name, "Conectado")
                addLog("Conectado com $name")
''',
    '''            if (result.status.statusCode == ConnectionsStatusCodes.STATUS_OK) {
                connectedEndpointIds.add(endpointId)
                saveMeshContact(name, "Conectado")
                updatePeer(endpointId, name, "Conectado")
                addLog("Conectado com $name")
'''
)

# Save contact when disconnected
text = text.replace(
    '''        override fun onDisconnected(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"
            connectedEndpointIds.remove(endpointId)
            updatePeer(endpointId, name, "Desconectado")
            addLog("$name desconectou")
        }
''',
    '''        override fun onDisconnected(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"
            connectedEndpointIds.remove(endpointId)
            saveMeshContact(name, "Offline")
            updatePeer(endpointId, name, "Desconectado")
            addLog("$name desconectou")
        }
'''
)

# Save contact when found
text = text.replace(
    '''        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            peerNames[endpointId] = info.endpointName
            updatePeer(endpointId, info.endpointName, "Encontrado")
            addLog("Encontrado: ${info.endpointName}")
''',
    '''        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            peerNames[endpointId] = info.endpointName
            saveMeshContact(info.endpointName, "Encontrado")
            updatePeer(endpointId, info.endpointName, "Encontrado")
            addLog("Encontrado: ${info.endpointName}")
'''
)

# Save contact when lost
text = text.replace(
    '''        override fun onEndpointLost(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"
            connectedEndpointIds.remove(endpointId)
            updatePeer(endpointId, name, "Perdido")
            addLog("$name saiu do alcance")
        }
''',
    '''        override fun onEndpointLost(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"
            connectedEndpointIds.remove(endpointId)
            saveMeshContact(name, "Fora de alcance")
            updatePeer(endpointId, name, "Perdido")
            addLog("$name saiu do alcance")
        }
'''
)

# Add save helpers before updatePeer
if "private fun saveMeshContact" not in text:
    text = text.replace(
        '''    private fun updatePeer(endpointId: String, name: String, status: String) {
''',
        '''    private fun saveMeshContact(name: String, status: String) {
        contactStore.upsertContact(name, status)
        savedContacts = contactStore.loadContacts()
    }

    fun clearSavedContacts() {
        contactStore.clearContacts()
        savedContacts = emptyList()
        addLog("Contatos Mesh salvos foram limpos")
    }

    private fun updatePeer(endpointId: String, name: String, status: String) {
'''
    )

# Pass saved contacts to conversation screen
text = text.replace(
    '''            MeshTab.Conversations -> ConversationListScreen(
                modifier = Modifier.padding(padding),
                conversations = conversations,
                onOpenConversation = { selectedConversationId = it.id }
            )
''',
    '''            MeshTab.Conversations -> ConversationListScreen(
                modifier = Modifier.padding(padding),
                conversations = conversations,
                savedContacts = nearbyController.savedContacts,
                onOpenConversation = { selectedConversationId = it.id }
            )
'''
)

# Update ConversationListScreen signature
text = text.replace(
    '''fun ConversationListScreen(
    modifier: Modifier,
    conversations: List<Conversation>,
    onOpenConversation: (Conversation) -> Unit
) {
''',
    '''fun ConversationListScreen(
    modifier: Modifier,
    conversations: List<Conversation>,
    savedContacts: List<MeshSavedContact>,
    onOpenConversation: (Conversation) -> Unit
) {
'''
)

# Insert saved contacts section after search field item
if "Contatos Mesh salvos" not in text:
    text = text.replace(
        '''        item {
            Text(
                text = "Conversas",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
        }
''',
        '''        if (savedContacts.isNotEmpty()) {
            item {
                Text(
                    text = "Contatos Mesh salvos",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
                )
            }

            items(savedContacts) { contact ->
                SavedContactCard(contact = contact)
            }
        }

        item {
            Text(
                text = "Conversas",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
        }
'''
    )

# Add SavedContactCard before NearbyScreen
if "fun SavedContactCard" not in text:
    text = text.replace(
        '''@Composable
fun NearbyScreen(
''',
        '''@Composable
fun SavedContactCard(contact: MeshSavedContact) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AvatarBubble(name = contact.name)

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = contact.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                Text(
                    text = "Último contato: ${contact.lastSeen}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Text(
                    text = "Contato salvo por conexão Mesh",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.SemiBold
                )
            }

            AssistChip(
                onClick = {},
                label = { Text(contact.status) }
            )
        }
    }
}

@Composable
fun NearbyScreen(
'''
    )

# Network contacts metric
if "Contatos salvos" not in text:
    text = text.replace(
        '''        item {
            MeshMetricCard(
                title = "Mensagens Nearby",
                value = nearbyController.nearbyMessages.size.toString(),
                detail = "Mensagens enviadas/recebidas pela tela Próximos."
            )
        }

        item {
            MeshMetricCard(
                title = "Próximo alvo",
''',
        '''        item {
            MeshMetricCard(
                title = "Mensagens Nearby",
                value = nearbyController.nearbyMessages.size.toString(),
                detail = "Mensagens enviadas/recebidas pela tela Próximos."
            )
        }

        item {
            MeshMetricCard(
                title = "Contatos salvos",
                value = nearbyController.savedContacts.size.toString(),
                detail = "Dispositivos encontrados/conectados que já viraram contatos Mesh."
            )
        }

        item {
            MeshMetricCard(
                title = "Próximo alvo",
'''
    )

# Settings contact count card
if "Banco de contatos Mesh" not in text:
    text = text.replace(
        '''        item {
            PermissionCard(
                title = "Identidade local",
                description = "Na fase futura, o app criará uma identidade persistente sem número de telefone.",
                status = "Futuro"
            )
        }
''',
        '''        item {
            PermissionCard(
                title = "Banco de contatos Mesh",
                description = "Contatos salvos neste aparelho: ${nearbyController.savedContacts.size}",
                status = "v0.2.2"
            )
        }

        item {
            PermissionCard(
                title = "Identidade local",
                description = "Na fase futura, o app criará uma identidade persistente sem número de telefone.",
                status = "Futuro"
            )
        }
'''
    )

# Text updates
text = text.replace("Nearby v0.2.0", "Contatos Mesh v0.2.2")
text = text.replace("Nearby estabilizado:", "Contatos Mesh: dispositivos encontrados agora podem ficar salvos. Nearby estabilizado:")
text = text.replace("Nearby básico ativado na v0.2.0.", "Contatos Mesh salvos ativados na v0.2.2.")
text = text.replace("A v0.2.0 usa Nearby Connections", "A v0.2.2 usa Nearby Connections")
text = text.replace(
    '''value = "v0.2.2",
                detail = "Salvar dispositivos encontrados como contatos Mesh persistentes."''',
    '''value = "v0.2.3",
                detail = "Criar conversas persistentes associadas aos contatos Mesh."'''
)

write(MAIN, text)

print("v0.2.2 aplicada com sucesso.")
PY

echo "== v0.2.2 pronta localmente =="
echo "Agora rode: git status"
