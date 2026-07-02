#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== Mesh Chat v0.2.3 - Conversas persistentes por Contato Mesh =="

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

def must_replace(text, old, new, label):
    if old not in text:
        raise SystemExit(f"ERRO: trecho não encontrado para {label}")
    return text.replace(old, new)

# Gradle
gradle = GRADLE.read_text()
gradle = gradle.replace(
    'versionCode = 5\n        versionName = "0.2.2"',
    'versionCode = 6\n        versionName = "0.2.3"'
)
GRADLE.write_text(gradle)

# Workflow
workflow = WORKFLOW.read_text()
workflow = workflow.replace("MeshChat-v0.2.2-debug-apk", "MeshChat-v0.2.3-debug-apk")
workflow = workflow.replace("MeshChat-v0.2.1-debug-apk", "MeshChat-v0.2.3-debug-apk")
workflow = workflow.replace("MeshChat-v0.2.0-debug-apk", "MeshChat-v0.2.3-debug-apk")
WORKFLOW.write_text(workflow)

text = MAIN.read_text()

# Version
text = text.replace('private const val APP_VERSION = "v0.2.2"', 'private const val APP_VERSION = "v0.2.3"')
text = text.replace('private const val APP_VERSION = "v0.2.1"', 'private const val APP_VERSION = "v0.2.3"')

# Data class for persisted contact messages
if "data class MeshContactMessage" not in text:
    text = must_replace(
        text,
        '''data class MeshSavedContact(
    val key: String,
    val name: String,
    val lastSeen: String,
    val status: String
)
''',
        '''data class MeshSavedContact(
    val key: String,
    val name: String,
    val lastSeen: String,
    val status: String
)

data class MeshContactMessage(
    val text: String,
    val mine: Boolean,
    val time: String
)
''',
        "MeshContactMessage"
    )

# Message store
if "class MeshMessageStore" not in text:
    text = must_replace(
        text,
        "class MeshNearbyController(private val context: Context) {",
        '''class MeshMessageStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("mesh_message_store", Context.MODE_PRIVATE)

    fun loadMessages(contactKey: String): List<MeshContactMessage> {
        val raw = prefs.getString("messages_$contactKey", "[]") ?: "[]"

        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<MeshContactMessage>()

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                result.add(
                    MeshContactMessage(
                        text = item.optString("text"),
                        mine = item.optBoolean("mine"),
                        time = item.optString("time")
                    )
                )
            }

            result
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun addMessage(contactKey: String, text: String, mine: Boolean, time: String) {
        val current = loadMessages(contactKey).takeLast(100).toMutableList()
        current.add(
            MeshContactMessage(
                text = text,
                mine = mine,
                time = time
            )
        )

        val array = JSONArray()
        current.forEach { message ->
            val item = JSONObject()
            item.put("text", message.text)
            item.put("mine", message.mine)
            item.put("time", message.time)
            array.put(item)
        }

        prefs.edit().putString("messages_$contactKey", array.toString()).apply()
    }

    fun clearMessages(contactKey: String) {
        prefs.edit().remove("messages_$contactKey").apply()
    }
}

class MeshNearbyController(private val context: Context) {''',
        "MeshMessageStore"
    )

# Controller message store field
if "private val messageStore = MeshMessageStore(context)" not in text:
    text = must_replace(
        text,
        "    private val contactStore = MeshContactStore(context)\n",
        "    private val contactStore = MeshContactStore(context)\n    private val messageStore = MeshMessageStore(context)\n",
        "messageStore field"
    )

# Conversation version state
if "var conversationVersion by mutableStateOf(0)" not in text:
    text = must_replace(
        text,
        '''    var savedContacts by mutableStateOf(contactStore.loadContacts())
        private set

    var isAdvertising by mutableStateOf(false)
''',
        '''    var savedContacts by mutableStateOf(contactStore.loadContacts())
        private set

    var conversationVersion by mutableStateOf(0)
        private set

    var isAdvertising by mutableStateOf(false)
''',
        "conversationVersion"
    )

# Save incoming messages to contact history
if "saveMeshMessage(from, text, false)" not in text:
    text = must_replace(
        text,
        '''                nearbyMessages = nearbyMessages + NearbyTextMessage(
                    text = text,
                    mine = false,
                    time = now(),
                    from = from
                )
                addLog("Mensagem recebida de $from")
''',
        '''                nearbyMessages = nearbyMessages + NearbyTextMessage(
                    text = text,
                    mine = false,
                    time = now(),
                    from = from
                )
                saveMeshMessage(from, text, false)
                addLog("Mensagem recebida de $from")
''',
        "save incoming message"
    )

# Add controller functions for contact chat
if "fun messagesFor(contact: MeshSavedContact)" not in text:
    text = must_replace(
        text,
        '''    private fun saveMeshContact(name: String, status: String) {
''',
        '''    fun messagesFor(contact: MeshSavedContact): List<MeshContactMessage> {
        return messageStore.loadMessages(contact.key)
    }

    fun sendToSavedContact(contact: MeshSavedContact, text: String) {
        val clean = text.trim()
        if (clean.isEmpty()) return

        messageStore.addMessage(contact.key, clean, true, now())
        conversationVersion++

        val matchingEndpointIds = peerNames
            .filter { item -> item.value == contact.name && connectedEndpointIds.contains(item.key) }
            .keys

        if (matchingEndpointIds.isEmpty()) {
            addLog("Mensagem salva para ${contact.name}. Contato não está conectado agora")
            return
        }

        matchingEndpointIds.forEach { endpointId ->
            client.sendPayload(
                endpointId,
                Payload.fromBytes(clean.toByteArray(Charsets.UTF_8))
            ).addOnSuccessListener {
                addLog("Mensagem enviada para ${contact.name}")
            }.addOnFailureListener { error ->
                addLog("Falha ao enviar para ${contact.name}: ${error.message ?: "sem detalhe"}")
            }
        }
    }

    fun clearConversation(contact: MeshSavedContact) {
        messageStore.clearMessages(contact.key)
        conversationVersion++
        addLog("Histórico limpo: ${contact.name}")
    }

    private fun saveMeshMessage(contactName: String, text: String, mine: Boolean) {
        val contact = contactStore.loadContacts().firstOrNull { it.name == contactName } ?: return
        messageStore.addMessage(contact.key, text, mine, now())
        conversationVersion++
    }

    private fun saveMeshContact(name: String, status: String) {
''',
        "contact chat functions"
    )

# MeshChatApp selected saved contact state
if "selectedSavedContactKey" not in text:
    text = must_replace(
        text,
        '''    var selectedConversationId by rememberSaveable { mutableStateOf<Int?>(null) }
    val selectedConversation = conversations.firstOrNull { it.id == selectedConversationId }

    var showNewChatDialog by rememberSaveable { mutableStateOf(false) }

    if (selectedConversation != null) {
''',
        '''    var selectedConversationId by rememberSaveable { mutableStateOf<Int?>(null) }
    val selectedConversation = conversations.firstOrNull { it.id == selectedConversationId }

    var selectedSavedContactKey by rememberSaveable { mutableStateOf<String?>(null) }
    val selectedSavedContact = nearbyController.savedContacts.firstOrNull { it.key == selectedSavedContactKey }

    var showNewChatDialog by rememberSaveable { mutableStateOf(false) }

    if (selectedSavedContact != null) {
        ContactMeshChatScreen(
            contact = selectedSavedContact,
            nearbyController = nearbyController,
            onBack = { selectedSavedContactKey = null }
        )
        return
    }

    if (selectedConversation != null) {
''',
        "selected saved contact"
    )

# Clear selected saved contact on tab change
text = text.replace(
    '''                    selectedTabName = it.name
                    selectedConversationId = null
''',
    '''                    selectedTabName = it.name
                    selectedConversationId = null
                    selectedSavedContactKey = null
'''
)

# Pass onOpenSavedContact
text = must_replace(
    text,
    '''            MeshTab.Conversations -> ConversationListScreen(
                modifier = Modifier.padding(padding),
                conversations = conversations,
                savedContacts = nearbyController.savedContacts,
                onOpenConversation = { selectedConversationId = it.id }
            )
''',
    '''            MeshTab.Conversations -> ConversationListScreen(
                modifier = Modifier.padding(padding),
                conversations = conversations,
                savedContacts = nearbyController.savedContacts,
                onOpenSavedContact = { selectedSavedContactKey = it.key },
                onOpenConversation = { selectedConversationId = it.id }
            )
''',
    "ConversationListScreen call"
)

# Signature
text = must_replace(
    text,
    '''fun ConversationListScreen(
    modifier: Modifier,
    conversations: List<Conversation>,
    savedContacts: List<MeshSavedContact>,
    onOpenConversation: (Conversation) -> Unit
) {
''',
    '''fun ConversationListScreen(
    modifier: Modifier,
    conversations: List<Conversation>,
    savedContacts: List<MeshSavedContact>,
    onOpenSavedContact: (MeshSavedContact) -> Unit,
    onOpenConversation: (Conversation) -> Unit
) {
''',
    "ConversationListScreen signature"
)

# SavedContactCard call
text = text.replace(
    '''                SavedContactCard(contact = contact)
''',
    '''                SavedContactCard(
                    contact = contact,
                    onClick = { onOpenSavedContact(contact) }
                )
'''
)

# SavedContactCard clickable
text = text.replace(
    '''@Composable
fun SavedContactCard(contact: MeshSavedContact) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
''',
    '''@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedContactCard(
    contact: MeshSavedContact,
    onClick: () -> Unit
) {
    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
'''
)

# Add persistent contact chat screen before ChatScreen
if "fun ContactMeshChatScreen" not in text:
    text = must_replace(
        text,
        '''@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
''',
        '''@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContactMeshChatScreen(
    contact: MeshSavedContact,
    nearbyController: MeshNearbyController,
    onBack: () -> Unit
) {
    val version = nearbyController.conversationVersion
    val messages = remember(version, contact.key) {
        nearbyController.messagesFor(contact)
    }

    var input by rememberSaveable(contact.key) { mutableStateOf("") }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = contact.name,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = "${contact.status} • Último contato: ${contact.lastSeen}",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Filled.ArrowBack,
                            contentDescription = "Voltar"
                        )
                    }
                },
                actions = {
                    if (messages.isNotEmpty()) {
                        TextButton(onClick = { nearbyController.clearConversation(contact) }) {
                            Text("Limpar")
                        }
                    }
                }
            )
        },
        bottomBar = {
            MessageInputBar(
                input = input,
                onInputChange = { input = it },
                onSend = {
                    val text = input.trim()
                    if (text.isNotEmpty()) {
                        nearbyController.sendToSavedContact(contact, text)
                        input = ""
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                StatusPanel(
                    title = "Conversa Mesh salva",
                    body = "Este contato foi criado a partir de uma conexão Nearby. Se ele estiver próximo/conectado, a mensagem tenta sair pelo canal offline. Se não estiver, fica salva localmente.",
                    primary = contact.status,
                    secondary = "Histórico local"
                )
            }

            if (messages.isEmpty()) {
                item {
                    MeshMetricCard(
                        title = "Sem mensagens ainda",
                        value = "0",
                        detail = "Envie uma mensagem para iniciar o histórico deste contato Mesh."
                    )
                }
            } else {
                items(messages) { message ->
                    MeshContactMessageBubble(message = message)
                }
            }
        }
    }
}

@Composable
fun MeshContactMessageBubble(message: MeshContactMessage) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = if (message.mine) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Surface(
            modifier = Modifier.widthIn(max = 330.dp),
            shape = RoundedCornerShape(
                topStart = 24.dp,
                topEnd = 24.dp,
                bottomStart = if (message.mine) 24.dp else 6.dp,
                bottomEnd = if (message.mine) 6.dp else 24.dp
            ),
            color = if (message.mine) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            }
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = message.text,
                    color = if (message.mine) {
                        MaterialTheme.colorScheme.onPrimary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    },
                    style = MaterialTheme.typography.bodyMedium
                )

                Text(
                    text = message.time,
                    color = if (message.mine) {
                        MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.78f)
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    },
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
''',
        "ContactMeshChatScreen"
    )

# Text updates
text = text.replace("Contatos Mesh v0.2.2", "Conversas Mesh v0.2.3")
text = text.replace("Contatos Mesh salvos ativados na v0.2.2.", "Conversas persistentes dos Contatos Mesh ativadas na v0.2.3.")
text = text.replace("A v0.2.2 usa Nearby Connections", "A v0.2.3 usa Nearby Connections")
text = text.replace(
    '''value = "v0.2.3",
                detail = "Criar conversas persistentes associadas aos contatos Mesh."''',
    '''value = "v0.2.4",
                detail = "Adicionar indicadores de qualidade: verde, laranja, vermelho e offline."'''
)

MAIN.write_text(text)
print("v0.2.3 aplicada com sucesso.")
PY

echo "== v0.2.3 pronta localmente =="
echo "Agora rode: git status"
