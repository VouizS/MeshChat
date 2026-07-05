package com.sw.meshchat

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.ConnectionsStatusCodes
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

private const val APP_VERSION = "v0.3.0"
private const val SERVICE_ID = "com.sw.meshchat.NEARBY_SERVICE"

data class Conversation(
    val id: Int,
    val name: String,
    val lastMessage: String,
    val time: String,
    val status: String,
    val unread: Int = 0
)

data class ChatMessage(
    val id: Int,
    val text: String,
    val mine: Boolean,
    val time: String
)

data class NearbyPeer(
    val id: String,
    val name: String,
    val status: String
)

data class NearbyTextMessage(
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

data class MeshContactMessage(
    val text: String,
    val mine: Boolean,
    val time: String
)

enum class MeshTab(
    val label: String,
    val icon: ImageVector
) {
    Conversations("Conversas", Icons.Filled.Chat),
    Nearby("Próximos", Icons.Filled.Bluetooth),
    Network("Rede", Icons.Filled.Info),
    Settings("Config", Icons.Filled.Settings)
}


fun meshConnectionVisualStatus(status: String): String {
    val normalized = status.lowercase(Locale.getDefault())

    return when {
        normalized.contains("conexão mantida") ||
            normalized.contains("conexao mantida") ||
            normalized.contains("scanner instável") ||
            normalized.contains("scanner instavel") -> "🟠 Conexão mantida"

        normalized.contains("conectado") &&
            !normalized.contains("desconectado") -> "🟢 Conectado"

        normalized.contains("aceitando") ||
            normalized.contains("solicitando") ||
            normalized.contains("conectando") -> "🟡 Conectando"

        normalized.contains("encontrado") -> "🟡 Encontrado"

        normalized.contains("falha") ||
            normalized.contains("erro") -> "🔴 Falha"

        normalized.contains("perdido") ||
            normalized.contains("fora de alcance") -> "⚫ Fora de alcance"

        normalized.contains("offline") ||
            normalized.contains("desconectado") ||
            normalized.contains("parado") -> "⚫ Salvos"

        else -> status
    }
}

fun meshConnectionVisualHint(status: String): String {
    val normalized = status.lowercase(Locale.getDefault())

    return when {
        normalized.contains("conectado") &&
            !normalized.contains("desconectado") -> "Sala Nearby ativo para troca de mensagens."

        normalized.contains("conexão mantida") ||
            normalized.contains("conexao mantida") -> "O scanner oscilou, mas o canal ativo foi preservado."

        normalized.contains("encontrado") -> "Dispositivo visto pelo scanner. Aguarde a conexão."

        normalized.contains("falha") ||
            normalized.contains("erro") -> "Falha temporária. Pare e inicie offline nos dois aparelhos se persistir."

        normalized.contains("offline") ||
            normalized.contains("desconectado") ||
            normalized.contains("parado") -> "Sem canal ativo neste momento."

        else -> "Estado Nearby local."
    }
}


fun meshContactProfessionalSubtitle(contact: MeshSavedContact): String {
    val status = meshConnectionVisualStatus(contact.status)
    return "$status • Último contato: ${contact.lastSeen}"
}

fun meshContactActionLabel(status: String): String {
    val normalized = status.lowercase(Locale.getDefault())
    return when {
        normalized.contains("conectado") -> "Abrir conversa"
        normalized.contains("conexão mantida") || normalized.contains("conexao mantida") -> "Continuar"
        normalized.contains("encontrado") -> "Preparar conversa"
        normalized.contains("falha") || normalized.contains("erro") -> "Revisar"
        else -> "Conversar"
    }
}

fun meshContactTrustLabel(status: String): String {
    val normalized = status.lowercase(Locale.getDefault())
    return when {
        normalized.contains("conectado") -> "Contato validado nesta sessão"
        normalized.contains("conexão mantida") || normalized.contains("conexao mantida") -> "Grupo mantido apesar da oscilação do scanner"
        normalized.contains("encontrado") -> "Dispositivo visto pelo scanner local"
        normalized.contains("fora") || normalized.contains("offline") || normalized.contains("desconectado") -> "Contato salvo para uso futuro"
        else -> "Contato Mesh salvo neste aparelho"
    }
}



class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MeshChatTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MeshChatApp()
                }
            }
        }
    }
}

class MeshContactStore(private val context: Context) {
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

class MeshMessageStore(private val context: Context) {
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

class MeshNearbyController(private val context: Context) {
    private val client: ConnectionsClient = Nearby.getConnectionsClient(context)
    private val strategy: Strategy = Strategy.P2P_CLUSTER
    private val contactStore = MeshContactStore(context)
    private val messageStore = MeshMessageStore(context)
    private val localId: String = contactStore.localId()
    private val localName: String = "Mesh-${Build.MODEL.take(10)}-${localId.take(4)}"

    private val connectedEndpointIds = mutableSetOf<String>()
    private val peerNames = mutableMapOf<String, String>()

    var savedContacts by mutableStateOf(contactStore.loadContacts())
        private set

    var conversationVersion by mutableStateOf(0)
        private set

    var isAdvertising by mutableStateOf(false)
        private set

    var isDiscovering by mutableStateOf(false)
        private set

    var peers by mutableStateOf<List<NearbyPeer>>(emptyList())
        private set

    var nearbyMessages by mutableStateOf<List<NearbyTextMessage>>(emptyList())
        private set

    var logs by mutableStateOf<List<String>>(emptyList())
        private set

    val isConnected: Boolean
        get() = connectedEndpointIds.isNotEmpty()

    val connectedCount: Int
        get() = connectedEndpointIds.size

    val visibleName: String
        get() = localName

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val text = payload.asBytes()?.toString(Charsets.UTF_8).orEmpty()
                val from = peerNames[endpointId] ?: "Dispositivo"
                nearbyMessages = nearbyMessages + NearbyTextMessage(
                    text = text,
                    mine = false,
                    time = now(),
                    from = from
                )
                saveMeshMessage(from, text, false)
                addLog("Mensagem recebida de $from")
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            // Bytes pequenos não precisam de barra de progresso nesta versão.
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            peerNames[endpointId] = connectionInfo.endpointName
            saveMeshContact(connectionInfo.endpointName, "Solicitando")
            updatePeer(endpointId, connectionInfo.endpointName, "Aceitando conexão")
            addLog("Conexão iniciada com ${connectionInfo.endpointName}")

            client.acceptConnection(endpointId, payloadCallback)
                .addOnSuccessListener {
                    updatePeer(endpointId, connectionInfo.endpointName, "Aceito")
                }
                .addOnFailureListener { error ->
                    updatePeer(endpointId, connectionInfo.endpointName, "Falha ao aceitar")
                    addLog("Erro ao aceitar: ${error.message ?: "sem detalhe"}")
                }
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            val name = peerNames[endpointId] ?: "Dispositivo"

            if (result.status.statusCode == ConnectionsStatusCodes.STATUS_OK) {
                connectedEndpointIds.add(endpointId)
                saveMeshContact(name, "Conectado")
                updatePeer(endpointId, name, "Conectado")
                addLog("Conectado com $name")
            } else {
                updatePeer(endpointId, name, "Conexão recusada/falhou")
                addLog("Conexão falhou com $name: ${result.status.statusMessage ?: result.status.statusCode}")
            }
        }

        override fun onDisconnected(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"
            connectedEndpointIds.remove(endpointId)
            saveMeshContact(name, "Salvos")
            updatePeer(endpointId, name, "Desconectado")
            addLog("$name desconectou")
        }
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            peerNames[endpointId] = info.endpointName

            if (connectedEndpointIds.contains(endpointId)) {
                saveMeshContact(info.endpointName, "Conectado")
                updatePeer(endpointId, info.endpointName, "Conexão mantida")
                addLog("Scanner viu novamente ${info.endpointName}; conexão ativa mantida")
            } else {
                saveMeshContact(info.endpointName, "Encontrado")
                updatePeer(endpointId, info.endpointName, "Encontrado")
                addLog("Encontrado: ${info.endpointName}")
            }

            if (!connectedEndpointIds.contains(endpointId)) {
                client.requestConnection(localName, endpointId, connectionLifecycleCallback)
                    .addOnSuccessListener {
                        updatePeer(endpointId, info.endpointName, "Solicitando conexão")
                    }
                    .addOnFailureListener { error ->
                        updatePeer(endpointId, info.endpointName, "Falha na solicitação")
                        addLog("Erro ao solicitar conexão: ${error.message ?: "sem detalhe"}")
                    }
            }
        }

        override fun onEndpointLost(endpointId: String) {
            val name = peerNames[endpointId] ?: "Dispositivo"

            if (connectedEndpointIds.contains(endpointId)) {
                saveMeshContact(name, "Conectado")
                updatePeer(endpointId, name, "Conexão mantida")
                addLog("$name saiu do scanner, mas a conexão ativa foi mantida")
            } else {
                saveMeshContact(name, "Fora de alcance")
                updatePeer(endpointId, name, "Perdido")
                addLog("$name saiu do alcance")
            }
        }
    }

    fun startSalvos() {
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

    fun stopSalvos() {
        client.stopAdvertising()
        client.stopDiscovery()
        client.stopAllEndpoints()

        isAdvertising = false
        isDiscovering = false
        connectedEndpointIds.clear()
        peers = peers.map { it.copy(status = "Parado") }

        addLog("Modo offline parado")
    }

    fun clearEvents() {
        logs = emptyList()
    }

    fun clearNearbyMessages() {
        nearbyMessages = emptyList()
        addLog("Mensagens locais limpas")
    }

    private fun startAdvertising() {
        val options = AdvertisingOptions.Builder()
            .setStrategy(strategy)
            .build()

        client.startAdvertising(
            localName,
            SERVICE_ID,
            connectionLifecycleCallback,
            options
        ).addOnSuccessListener {
            isAdvertising = true
            addLog("Visível como $localName")
        }.addOnFailureListener { error ->
            val detail = error.message ?: "sem detalhe"

            if (
                detail.contains("STATUS_ALREADY_ADVERTISING", ignoreCase = true) ||
                detail.contains("8001")
            ) {
                isAdvertising = true
                addLog("Visibilidade já estava ativa")
            } else {
                isAdvertising = false
                addLog("Falha ao ficar visível: ${nearbyErrorHint(detail)}")
            }
        }
    }

    private fun startDiscovery() {
        val options = DiscoveryOptions.Builder()
            .setStrategy(strategy)
            .build()

        client.startDiscovery(
            SERVICE_ID,
            endpointDiscoveryCallback,
            options
        ).addOnSuccessListener {
            isDiscovering = true
            addLog("Scanner iniciado")
        }.addOnFailureListener { error ->
            val detail = error.message ?: "sem detalhe"

            if (
                detail.contains("STATUS_ALREADY_DISCOVERING", ignoreCase = true) ||
                detail.contains("8002")
            ) {
                isDiscovering = true
                addLog("Scanner já estava ativo")
            } else {
                isDiscovering = false
                addLog("Falha no scanner: ${nearbyErrorHint(detail)}")
            }
        }
    }

    fun sendNearbyText(text: String) {
        val clean = text.trim()
        if (clean.isEmpty()) return

        nearbyMessages = nearbyMessages + NearbyTextMessage(
            text = clean,
            mine = true,
            time = now(),
            from = "Você"
        )

        if (connectedEndpointIds.isEmpty()) {
            addLog("Nenhum peer conectado. A mensagem ficou apenas local nesta sessão")
            return
        }

        connectedEndpointIds.forEach { endpointId ->
            client.sendPayload(
                endpointId,
                Payload.fromBytes(clean.toByteArray(Charsets.UTF_8))
            ).addOnSuccessListener {
                addLog("Mensagem enviada")
            }.addOnFailureListener { error ->
                addLog("Falha ao enviar: ${error.message ?: "sem detalhe"}")
            }
        }
    }

    fun messagesFor(contact: MeshSavedContact): List<MeshContactMessage> {
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

    private fun nearbyErrorHint(detail: String): String {
        return when {
            detail.contains("MISSING_PERMISSION_ACCESS_WIFI_STATE", ignoreCase = true) ||
                detail.contains("ACCESS_WIFI_STATE", ignoreCase = true) ||
                detail.contains("8032") -> {
                "Compatibilidade Wi-Fi/Nearby bloqueada. Atualize a APK nos dois aparelhos e confirme permissões de Dispositivos por perto."
            }

            detail.contains("MISSING_PERMISSION", ignoreCase = true) -> {
                "Permissão Nearby ausente ou bloqueada: $detail"
            }

            detail.contains("API_NOT_CONNECTED", ignoreCase = true) -> {
                "Google Play Services/Nearby ainda não está pronto neste aparelho."
            }

            else -> detail
        }
    }

    private fun saveMeshContact(name: String, status: String) {
        contactStore.upsertContact(name, status)
        savedContacts = contactStore.loadContacts()
    }

    fun clearSavedContacts() {
        contactStore.clearContacts()
        savedContacts = emptyList()
        addLog("Contatos Mesh salvos foram limpos")
    }

    private fun updatePeer(endpointId: String, name: String, status: String) {
        val withoutOld = peers.filterNot { it.id == endpointId }
        peers = withoutOld + NearbyPeer(endpointId, name, status)
    }

    private fun addLog(text: String) {
        logs = (listOf("${now()} • $text") + logs).take(12)
    }

    private fun now(): String {
        return SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
    }
}

fun requiredNearbyPermissions(): Array<String> {
    val permissions = mutableListOf<String>()

    /*
     * Runtime permissions by Android version:
     *
     * Android 8/9:
     * - Location permission may be needed for Bluetooth/Nearby discovery.
     *
     * Android 10/11/12:
     * - Fine location is commonly required for discovery behavior.
     *
     * Android 12+:
     * - Bluetooth scan/connect/advertise became runtime permissions.
     *
     * Android 13+:
     * - Nearby Wi-Fi devices is required by newer local device discovery behavior.
     *
     * ACCESS_WIFI_STATE and CHANGE_WIFI_STATE are normal manifest permissions,
     * not runtime permissions, so they are declared in AndroidManifest.xml only.
     */

    if (Build.VERSION.SDK_INT <= 28) {
        permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    if (Build.VERSION.SDK_INT in 29..32) {
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
    }

    if (Build.VERSION.SDK_INT >= 31) {
        permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
        permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        permissions.add(Manifest.permission.BLUETOOTH_SCAN)
    }

    if (Build.VERSION.SDK_INT >= 33) {
        permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
    }

    return permissions.distinct().toTypedArray()
}

fun hasAllNearbyPermissions(context: Context): Boolean {
    return requiredNearbyPermissions().all { permission ->
        if (Build.VERSION.SDK_INT < 23) {
            true
        } else {
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }
    }
}

fun nearbyAndroidCompatibilityLabel(): String {
    return "Android ${Build.VERSION.RELEASE} / API ${Build.VERSION.SDK_INT}"
}

fun nearbyRuntimePermissionSummary(context: Context): String {
    val required = requiredNearbyPermissions()

    if (required.isEmpty()) {
        return "Nenhuma permissão runtime extra exigida nesta versão do Android."
    }

    val missing = required.filter { permission ->
        Build.VERSION.SDK_INT >= 23 &&
            context.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED
    }

    return if (missing.isEmpty()) {
        "Permissões runtime concedidas. Wi-Fi, Bluetooth e Localização/Dispositivos próximos precisam continuar ligados."
    } else {
        "Permissões pendentes: ${missing.joinToString { it.substringAfterLast('.') }}"
    }
}

fun nearbyPermissionStatusLabel(context: Context): String {
    return if (hasAllNearbyPermissions(context)) "OK" else "Pendente"
}


@Composable
fun MeshChatTheme(content: @Composable () -> Unit) {
    val context = LocalContext.current
    val darkTheme = isSystemInDarkTheme()

    val lightScheme = lightColorScheme(
        primary = Color(0xFF006A60),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF8FF5E2),
        onPrimaryContainer = Color(0xFF00201B),
        secondary = Color(0xFF4A635D),
        background = Color(0xFFF4FBF8),
        surface = Color(0xFFF4FBF8),
        surfaceVariant = Color(0xFFDCE5E1),
        outline = Color(0xFF6F7975)
    )

    val darkScheme = darkColorScheme(
        primary = Color(0xFF72D8C7),
        onPrimary = Color(0xFF003731),
        primaryContainer = Color(0xFF005047),
        onPrimaryContainer = Color(0xFF8FF5E2),
        secondary = Color(0xFFB0CCC4),
        background = Color(0xFF061512),
        surface = Color(0xFF061512),
        surfaceVariant = Color(0xFF3F4945),
        outline = Color(0xFF89938F)
    )

    val colorScheme = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && darkTheme -> dynamicDarkColorScheme(context)
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !darkTheme -> dynamicLightColorScheme(context)
        darkTheme -> darkScheme
        else -> lightScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = androidx.compose.material3.Typography(),
        content = content
    )
}

@Composable
fun MeshChatApp() {
    val context = LocalContext.current
    val nearbyController = remember { MeshNearbyController(context) }

    val conversations = remember {
        listOf(
            Conversation(
                id = 1,
                name = "Rede Local Nearby",
                lastMessage = "Canal local validado para mensagens sem internet externa.",
                time = "Agora",
                status = "Rede",
                unread = 2
            ),
            Conversation(
                id = 2,
                name = "Contatos Mesh",
                lastMessage = "Contatos próximos viram base para salas e grupos offline.",
                time = "Teste",
                status = "Salvos"
            ),
            Conversation(
                id = 3,
                name = "Sala Mesh Local",
                lastMessage = "Sala experimental para conversar com vários dispositivos próximos conectados.",
                time = "Futuro",
                status = "Grupo"
            ),
            Conversation(
                id = 4,
                name = "Diagnóstico Mesh",
                lastMessage = "Acompanhe scanner, pares, mensagens e estabilidade da sala local.",
                time = APP_VERSION,
                status = "Rede"
            )
        )
    }

    var selectedTabName by rememberSaveable { mutableStateOf(MeshTab.Conversations.name) }
    val selectedTab = MeshTab.valueOf(selectedTabName)

    var selectedConversationId by rememberSaveable { mutableStateOf<Int?>(null) }
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
        ChatScreen(
            conversation = selectedConversation,
            onBack = { selectedConversationId = null }
        )
        return
    }

    if (showNewChatDialog) {
        NewConversationDialog(
            onDismiss = { showNewChatDialog = false }
        )
    }

    Scaffold(
        topBar = {
            MeshTopBar(tab = selectedTab)
        },
        bottomBar = {
            MeshNavigationBar(
                selectedTab = selectedTab,
                onTabSelected = {
                    selectedTabName = it.name
                    selectedConversationId = null
                    selectedSavedContactKey = null
                }
            )
        },
        floatingActionButton = {
            if (selectedTab == MeshTab.Conversations) {
                FloatingActionButton(
                    onClick = { showNewChatDialog = true }
                ) {
                    Icon(
                        imageVector = Icons.Filled.Add,
                        contentDescription = "Nova conversa"
                    )
                }
            }
        }
    ) { padding ->
        when (selectedTab) {
            MeshTab.Conversations -> ConversationListScreen(
                modifier = Modifier.padding(padding),
                conversations = conversations,
                savedContacts = nearbyController.savedContacts,
                onOpenSavedContact = { selectedSavedContactKey = it.key },
                onOpenConversation = { selectedConversationId = it.id }
            )

            MeshTab.Nearby -> NearbyScreen(
                modifier = Modifier.padding(padding),
                nearbyController = nearbyController
            )

            MeshTab.Network -> NetworkScreen(
                modifier = Modifier.padding(padding),
                nearbyController = nearbyController
            )

            MeshTab.Settings -> SettingsScreen(
                modifier = Modifier.padding(padding),
                nearbyController = nearbyController
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeshTopBar(tab: MeshTab) {
    val subtitle = when (tab) {
        MeshTab.Conversations -> "Mensagens offline em construção"
        MeshTab.Nearby -> "Nearby Connections / grupos"
        MeshTab.Network -> "Diagnóstico Mesh da malha local"
        MeshTab.Settings -> "Preferências do aplicativo"
    }

    LargeTopAppBar(
        title = {
            Column {
                Text(
                    text = when (tab) {
                        MeshTab.Conversations -> "Mesh Chat"
                        MeshTab.Nearby -> "Próximos"
                        MeshTab.Network -> "Rede Mesh"
                        MeshTab.Settings -> "Configurações"
                    },
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        colors = TopAppBarDefaults.largeTopAppBarColors(
            containerColor = MaterialTheme.colorScheme.background
        )
    )
}

@Composable
fun MeshNavigationBar(
    selectedTab: MeshTab,
    onTabSelected: (MeshTab) -> Unit
) {
    NavigationBar {
        MeshTab.values().forEach { tab ->
            NavigationBarItem(
                selected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
                icon = {
                    Icon(
                        imageVector = tab.icon,
                        contentDescription = tab.label
                    )
                },
                label = {
                    Text(tab.label)
                }
            )
        }
    }
}

@Composable
fun ConversationListScreen(
    modifier: Modifier,
    conversations: List<Conversation>,
    savedContacts: List<MeshSavedContact>,
    onOpenSavedContact: (MeshSavedContact) -> Unit,
    onOpenConversation: (Conversation) -> Unit
) {
    var search by rememberSaveable { mutableStateOf("") }

    val filtered = remember(search, conversations) {
        if (search.isBlank()) {
            conversations
        } else {
            conversations.filter {
                it.name.contains(search, ignoreCase = true) ||
                    it.lastMessage.contains(search, ignoreCase = true) ||
                    it.status.contains(search, ignoreCase = true)
            }
        }
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            HeroStatusCard()
        }

        item {
            OutlinedTextField(
                value = search,
                onValueChange = { search = it },
                modifier = Modifier.fillMaxWidth(),
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Filled.Search,
                        contentDescription = "Buscar"
                    )
                },
                placeholder = { Text("Buscar conversas") },
                shape = RoundedCornerShape(24.dp),
                singleLine = true
            )
        }

        item {
            Text(
                text = "Grupos Mesh",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
        }

        items(filtered) { conversation ->
            ConversationCard(
                conversation = conversation,
                onClick = { onOpenConversation(conversation) }
            )
        }
    }
}

@Composable
fun HeroStatusCard() {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Grupos Mesh",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Text(
                text = "Primeira etapa de grupos offline locais: sala experimental, contatos próximos e envio para múltiplos dispositivos conectados.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                AssistChip(
                    onClick = {},
                    label = { Text(APP_VERSION) }
                )
                AssistChip(
                    onClick = {},
                    label = { Text("Nearby") }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConversationCard(
    conversation: Conversation,
    onClick: () -> Unit
) {
    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AvatarBubble(name = conversation.name)

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = conversation.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Text(
                        text = conversation.time,
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Text(
                    text = conversation.lastMessage,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Text(
                    text = conversation.status,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (conversation.unread > 0) {
                Spacer(modifier = Modifier.width(8.dp))
                Surface(
                    modifier = Modifier.size(36.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = conversation.unread.toString(),
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedContactCard(
    contact: MeshSavedContact,
    onClick: () -> Unit
) {
    ElevatedCard(
        onClick = onClick,
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
                label = { Text(meshConnectionVisualStatus(contact.status)) }
            )
        }
    }
}

@Composable
fun NearbyScreen(
    modifier: Modifier,
    nearbyController: MeshNearbyController
) {
    val context = LocalContext.current
    var permissionsGranted by remember { mutableStateOf(hasAllNearbyPermissions(context)) }
    var nearbyInput by rememberSaveable { mutableStateOf("Mensagem para dispositivos conectados") }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) {
        permissionsGranted = hasAllNearbyPermissions(context)
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            StatusPanel(
                title = "Dispositivos próximos",
                body = "Teste inicial do Nearby Connections. Em dois celulares, conceda permissões e toque em Iniciar offline nos dois aparelhos.",
                primary = "${nearbyController.peers.size} encontrados",
                secondary = if (nearbyController.isConnected) "Conectado" else "Scanner/visível"
            )
        }

        item {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Meu nome local",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = nearbyController.visibleName,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Use dois aparelhos próximos com Mesh Chat aberto para validar o envio offline.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        item {
            PermissionCard(
                title = "Compatibilidade Android",
                description = nearbyAndroidCompatibilityLabel(),
                status = "Compat"
            )
        }

        item {
            PermissionCard(
                title = "Permissões runtime",
                description = nearbyRuntimePermissionSummary(context),
                status = nearbyPermissionStatusLabel(context)
            )
        }

        item {
            Text(
                text = "Controle offline",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        item {
            if (!permissionsGranted) {
                FilledTonalButton(
                    onClick = {
                        permissionLauncher.launch(requiredNearbyPermissions())
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Text("Permitir recursos offline")
                }
            } else {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    FilledTonalButton(
                        onClick = { nearbyController.startSalvos() },
                        enabled = !(nearbyController.isAdvertising && nearbyController.isDiscovering),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text(
                            if (nearbyController.isAdvertising || nearbyController.isDiscovering) {
                                "Salvos ativo"
                            } else {
                                "Iniciar offline"
                            }
                        )
                    }

                    FilledTonalButton(
                        onClick = { nearbyController.stopSalvos() },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(20.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant,
                            contentColor = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    ) {
                        Text("Parar")
                    }
                }
            }
        }

        item {
            PermissionCard(
                title = "Permissões",
                description = if (permissionsGranted) {
                    "Permissões necessárias concedidas neste aparelho."
                } else {
                    "Conceda as permissões para anunciar, descobrir e conectar dispositivos próximos."
                },
                status = if (permissionsGranted) "OK" else "Pendente"
            )
        }

        item {
            PermissionCard(
                title = "Visibilidade",
                description = "Advertising: este celular fica visível para outros Mesh Chat próximos.",
                status = if (nearbyController.isAdvertising) "Ativo" else "Inativo"
            )
        }

        item {
            PermissionCard(
                title = "Scanner",
                description = "Discovery: este celular procura outros Mesh Chat próximos.",
                status = if (nearbyController.isDiscovering) "Ativo" else "Inativo"
            )
        }

        item {
            Text(
                text = "Dispositivos na sala local",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        if (nearbyController.peers.isEmpty()) {
            item {
                MeshMetricCard(
                    title = "Nenhum dispositivo ainda",
                    value = "0",
                    detail = "Abra o APK em outro Android, conceda permissões e toque em Iniciar offline nos dois."
                )
            }
        } else {
            items(nearbyController.peers) { peer ->
                PeerCard(peer = peer)
            }
        }

        item {
            Text(
                text = "Mensagem para sala local",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.Bottom
            ) {
                OutlinedTextField(
                    value = nearbyInput,
                    onValueChange = { nearbyInput = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Mensagem offline") },
                    shape = RoundedCornerShape(24.dp),
                    maxLines = 3
                )

                FilledTonalButton(
                    onClick = {
                        nearbyController.sendNearbyText(nearbyInput)
                    },
                    shape = RoundedCornerShape(22.dp),
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Send,
                        contentDescription = "Enviar"
                    )
                }
            }
        }

        items(nearbyController.nearbyMessages) { message ->
            NearbyMessageBubble(message = message)
        }

        item {
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
            item {
                Text(
                    text = "Sem eventos ainda.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            items(nearbyController.logs) { log ->
                Text(
                    text = log,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun PeerCard(peer: NearbyPeer) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        ListItem(
            headlineContent = {
                Text(
                    text = peer.name,
                    fontWeight = FontWeight.Bold
                )
            },
            supportingContent = {
                Text("ID local: ${peer.id.take(10)}")
            },
            trailingContent = {
                AssistChip(
                    onClick = {},
                    label = { Text(meshConnectionVisualStatus(peer.status)) }
                )
            }
        )
    }
}

@Composable
fun NearbyMessageBubble(message: NearbyTextMessage) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = if (message.mine) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Surface(
            modifier = Modifier.widthIn(max = 330.dp),
            shape = RoundedCornerShape(22.dp),
            color = if (message.mine) {
                MaterialTheme.colorScheme.primaryContainer
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            }
        ) {
            Column(
                modifier = Modifier.padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = message.from,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = message.text,
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = message.time,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}

@Composable
fun NetworkScreen(
    modifier: Modifier,
    nearbyController: MeshNearbyController
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            StatusPanel(
                title = "Rede Mesh",
                body = "A v0.3.0 usa Nearby Connections para validar descoberta, conexão e envio de texto offline entre aparelhos próximos.",
                primary = if (nearbyController.isConnected) "Conectado" else "Salvos",
                secondary = "Peers: ${nearbyController.connectedCount}"
            )
        }

        item {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp)
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = "Diagnóstico Mesh",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Grupo Nearby",
                        style = MaterialTheme.typography.bodyMedium
                    )

                    LinearProgressIndicator(
                        progress = if (nearbyController.isAdvertising || nearbyController.isDiscovering) 0.75f else 0.15f,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Text(
                        text = "Advertising: ${if (nearbyController.isAdvertising) "ativo" else "inativo"} • Discovery: ${if (nearbyController.isDiscovering) "ativo" else "inativo"}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        item {
            MeshMetricCard(
                title = "Peers conectados",
                value = nearbyController.connectedCount.toString(),
                detail = "Quantidade de dispositivos conectados via Nearby nesta sessão."
            )
        }

        item {
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
                detail = "Dispositivos na sala local que já viraram contatos Mesh."
            )
        }

        item {
            MeshMetricCard(
                title = "Próximo alvo",
                value = "v0.3.1",
                detail = "Adicionar indicadores de qualidade: verde, laranja, vermelho e offline."
            )
        }
    }
}

@Composable
fun SettingsScreen(
    modifier: Modifier,
    nearbyController: MeshNearbyController
) {
    var compactMode by rememberSaveable { mutableStateOf(false) }
    var relayFuture by rememberSaveable { mutableStateOf(false) }
    var diagnostics by rememberSaveable { mutableStateOf(true) }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            StatusPanel(
                title = "Configurações",
                body = "Preferências iniciais do Mesh Chat. Grupos offline locais iniciados na v0.3.0.",
                primary = APP_VERSION,
                secondary = "Debug build"
            )
        }

        item {
            SettingsSwitchCard(
                title = "Modo compacto",
                description = "Reduzir espaçamentos em telas pequenas.",
                checked = compactMode,
                onCheckedChange = { compactMode = it }
            )
        }

        item {
            SettingsSwitchCard(
                title = "Relay mesh futuro",
                description = "Preparação para encaminhar mensagens por outros aparelhos.",
                checked = relayFuture,
                onCheckedChange = { relayFuture = it }
            )
        }

        item {
            SettingsSwitchCard(
                title = "Diagnóstico Mesh visível",
                description = "Mostrar informações técnicas da rede durante testes.",
                checked = diagnostics,
                onCheckedChange = { diagnostics = it }
            )
        }

        item {
            PermissionCard(
                title = "Nome local",
                description = nearbyController.visibleName,
                status = "Sessão"
            )
        }

        item {
            PermissionCard(
                title = "Banco de contatos Mesh",
                description = "Contatos salvos neste aparelho: ${nearbyController.savedContacts.size}",
                status = "v0.3.0"
            )
        }

        item {
            PermissionCard(
                title = "Identidade local",
                description = "Na fase futura, o app criará uma identidade persistente sem número de telefone.",
                status = "Futuro"
            )
        }
    }
}

@Composable
fun StatusPanel(
    title: String,
    body: String,
    primary: String,
    secondary: String
) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )

            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                AssistChip(
                    onClick = {},
                    label = { Text(primary) }
                )
                AssistChip(
                    onClick = {},
                    label = { Text(secondary) }
                )
            }
        }
    }
}

@Composable
fun PermissionCard(
    title: String,
    description: String,
    status: String
) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        ListItem(
            headlineContent = {
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold
                )
            },
            supportingContent = {
                Text(description)
            },
            trailingContent = {
                AssistChip(
                    onClick = {},
                    label = { Text(status) }
                )
            }
        )
    }
}

@Composable
fun MeshMetricCard(
    title: String,
    value: String,
    detail: String
) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        Row(
            modifier = Modifier.padding(18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = detail,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Text(
                text = value,
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun SettingsSwitchCard(
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp)
    ) {
        ListItem(
            headlineContent = {
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold
                )
            },
            supportingContent = {
                Text(description)
            },
            trailingContent = {
                Switch(
                    checked = checked,
                    onCheckedChange = onCheckedChange
                )
            }
        )
    }
}

@Composable
fun AvatarBubble(name: String) {
    val initial = name.firstOrNull()?.uppercaseChar()?.toString() ?: "M"

    Surface(
        modifier = Modifier.size(52.dp),
        shape = CircleShape,
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = initial,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun NewConversationDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Nova conversa")
        },
        text = {
            Text("A criação real de contatos entra depois que validarmos a conexão Nearby entre dois aparelhos.")
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Entendi")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Fechar")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
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
    conversation: Conversation,
    onBack: () -> Unit
) {
    val messages = remember(conversation.id) {
        mutableStateListOf(
            ChatMessage(
                id = 1,
                text = "Essa é a tela de conversa local.",
                mine = false,
                time = "12:41"
            ),
            ChatMessage(
                id = 2,
                text = "A integração direta da conversa com Nearby entra depois dos contatos/grupos.",
                mine = true,
                time = "12:42"
            ),
            ChatMessage(
                id = 3,
                text = "Próximo passo: conectar esta conversa ao contato Mesh salvo.",
                mine = false,
                time = "12:43"
            )
        )
    }

    var input by rememberSaveable { mutableStateOf("") }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = conversation.name,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = "Conversa local / Nearby em integração",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
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
                        messages.add(
                            ChatMessage(
                                id = messages.size + 1,
                                text = text,
                                mine = true,
                                time = "agora"
                            )
                        )
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
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(22.dp),
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "Estado da conversa",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Histórico local do contato. O envio Nearby real continua validado na aba Próximos.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            items(messages) { message ->
                MessageBubble(message = message)
            }
        }
    }
}

@Composable
fun MessageBubble(message: ChatMessage) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = if (message.mine) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Surface(
            modifier = Modifier.widthIn(max = 310.dp),
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

@Composable
fun MessageInputBar(
    input: String,
    onInputChange: (String) -> Unit,
    onSend: () -> Unit
) {
    Surface(
        tonalElevation = 6.dp,
        shadowElevation = 6.dp,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .imePadding()
                .padding(12.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = input,
                onValueChange = onInputChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Mensagem") },
                shape = RoundedCornerShape(24.dp),
                maxLines = 4
            )

            FilledTonalButton(
                onClick = onSend,
                shape = RoundedCornerShape(22.dp),
                contentPadding = PaddingValues(horizontal = 18.dp, vertical = 16.dp),
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    contentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            ) {
                Text("Enviar", fontWeight = FontWeight.Bold)
            }
        }
    }
}
