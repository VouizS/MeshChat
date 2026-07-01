#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== Mesh Chat v0.1.1-r1 - Material 3 completo =="

mkdir -p app/src/main/java/com/sw/meshchat
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p logs

cat > gradle.properties <<'EOT'
android.useAndroidX=true
android.nonTransitiveRClass=true
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOT

cat > app/build.gradle.kts <<'EOT'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.sw.meshchat"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.sw.meshchat"
        minSdk = 26
        targetSdk = 35
        versionCode = 2
        versionName = "0.1.1-r1"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.15"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.09.03"))

    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
EOT

cat > app/src/main/java/com/sw/meshchat/MainActivity.kt <<'EOT'
package com.sw.meshchat

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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

private const val APP_VERSION = "v0.1.1-r1"

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

enum class MeshTab(
    val label: String,
    val icon: ImageVector
) {
    Conversations("Conversas", Icons.Filled.Chat),
    Nearby("Próximos", Icons.Filled.Bluetooth),
    Network("Rede", Icons.Filled.Info),
    Settings("Config", Icons.Filled.Settings)
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
    val conversations = remember {
        listOf(
            Conversation(
                id = 1,
                name = "Rede Local",
                lastMessage = "Base Material 3 pronta para conexão offline.",
                time = "Agora",
                status = "Sistema",
                unread = 2
            ),
            Conversation(
                id = 2,
                name = "Contato Próximo",
                lastMessage = "Usuários próximos aparecerão aqui nas próximas versões.",
                time = "12:40",
                status = "Offline"
            ),
            Conversation(
                id = 3,
                name = "Sala Mesh",
                lastMessage = "Futura sala pública local sem internet.",
                time = "Ontem",
                status = "Canal"
            ),
            Conversation(
                id = 4,
                name = "Diagnóstico",
                lastMessage = "Área futura para permissões, alcance e estado da rede.",
                time = APP_VERSION,
                status = "Dev"
            )
        )
    }

    var selectedTabName by rememberSaveable { mutableStateOf(MeshTab.Conversations.name) }
    val selectedTab = MeshTab.valueOf(selectedTabName)

    var selectedConversationId by rememberSaveable { mutableStateOf<Int?>(null) }
    val selectedConversation = conversations.firstOrNull { it.id == selectedConversationId }

    var showNewChatDialog by rememberSaveable { mutableStateOf(false) }

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
                onOpenConversation = { selectedConversationId = it.id }
            )

            MeshTab.Nearby -> NearbyScreen(
                modifier = Modifier.padding(padding)
            )

            MeshTab.Network -> NetworkScreen(
                modifier = Modifier.padding(padding)
            )

            MeshTab.Settings -> SettingsScreen(
                modifier = Modifier.padding(padding)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeshTopBar(tab: MeshTab) {
    val subtitle = when (tab) {
        MeshTab.Conversations -> "Mensagens offline em construção"
        MeshTab.Nearby -> "Descoberta de dispositivos em preparação"
        MeshTab.Network -> "Diagnóstico da malha local"
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
                text = "Conversas",
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
                text = "Material 3 Kit",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Text(
                text = "Agora com abas, FAB, busca, tela de rede, tela de próximos e componentes Material 3 oficiais preparados para a camada offline.",
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
                    label = { Text("Material You") }
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

@Composable
fun NearbyScreen(modifier: Modifier) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            StatusPanel(
                title = "Dispositivos próximos",
                body = "Esta tela será usada para detectar celulares por Nearby Connections e Bluetooth LE. Nesta versão, ela prepara o layout e a lógica visual.",
                primary = "0 encontrados",
                secondary = "Scanner inativo"
            )
        }

        item {
            Text(
                text = "Preparação",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        item {
            PermissionCard(
                title = "Bluetooth",
                description = "Necessário para descobrir e conectar aparelhos próximos.",
                status = "Pendente"
            )
        }

        item {
            PermissionCard(
                title = "Localização aproximada",
                description = "Algumas APIs de descoberta exigem permissão de localização no Android.",
                status = "Pendente"
            )
        }

        item {
            PermissionCard(
                title = "Dispositivos próximos",
                description = "Permissão usada em versões recentes do Android para recursos Bluetooth/Wi-Fi próximos.",
                status = "Pendente"
            )
        }

        item {
            FilledTonalButton(
                onClick = {},
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp)
            ) {
                Text("Preparar permissões")
            }
        }
    }
}

@Composable
fun NetworkScreen(modifier: Modifier) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            StatusPanel(
                title = "Rede Mesh",
                body = "A malha offline ainda não está ativa. O objetivo futuro é permitir envio direto e relay entre dispositivos próximos.",
                primary = "Offline",
                secondary = "Relay desligado"
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
                        text = "Diagnóstico",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Canal de descoberta",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())

                    Text(
                        text = "Quando a v0.2.0 chegar, esta área mostrará status de scanner, peers, mensagens roteadas e qualidade aproximada da conexão.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        item {
            MeshMetricCard(
                title = "Peers conectados",
                value = "0",
                detail = "Nenhum dispositivo conectado nesta versão."
            )
        }

        item {
            MeshMetricCard(
                title = "Mensagens locais",
                value = "Demo",
                detail = "As mensagens atuais existem apenas na interface local."
            )
        }

        item {
            MeshMetricCard(
                title = "Próximo alvo",
                value = "Nearby",
                detail = "Primeira troca real offline entre dois Androids próximos."
            )
        }
    }
}

@Composable
fun SettingsScreen(modifier: Modifier) {
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
                body = "Preferências iniciais do Mesh Chat. Algumas opções ainda são visuais e serão conectadas às funções reais nas próximas versões.",
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
                title = "Diagnóstico visível",
                description = "Mostrar informações técnicas da rede durante testes.",
                checked = diagnostics,
                onCheckedChange = { diagnostics = it }
            )
        }

        item {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp)
            ) {
                ListItem(
                    headlineContent = {
                        Text(
                            text = "Identidade local",
                            fontWeight = FontWeight.Bold
                        )
                    },
                    supportingContent = {
                        Text("Na fase futura, o app criará uma identidade sem número de telefone.")
                    }
                )
            }
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
            Text("A criação real de contatos entra quando ativarmos Nearby Connections/Bluetooth. Por enquanto, esta ação confirma o fluxo visual Material 3.")
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
fun ChatScreen(
    conversation: Conversation,
    onBack: () -> Unit
) {
    val messages = remember(conversation.id) {
        mutableStateListOf(
            ChatMessage(
                id = 1,
                text = "Essa é a tela de conversa da primeira versão.",
                mine = false,
                time = "12:41"
            ),
            ChatMessage(
                id = 2,
                text = "Visual Material 3 aplicado. Depois vamos ligar isso no sistema offline real.",
                mine = true,
                time = "12:42"
            ),
            ChatMessage(
                id = 3,
                text = "Próxima etapa: permissões e camada de descoberta de dispositivos.",
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
                            text = "Modo offline em preparação",
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
                            text = "Estado da rede",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Sem conexão offline ativa nesta versão. Esta área será usada para Nearby, Bluetooth LE e Mesh Relay.",
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
EOT

cat > .github/workflows/android-debug.yml <<'EOT'
name: Android Debug APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    name: Build Mesh Chat Debug APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
          cache: gradle

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3

      - name: Install Android SDK packages
        run: sdkmanager "platforms;android-35" "build-tools;35.0.0"

      - name: Set up Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.10.2

      - name: Build debug APK
        run: gradle :app:assembleDebug --no-daemon --stacktrace

      - name: Upload debug APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: MeshChat-v0.1.1-r1-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
EOT

cat > scripts/watch_meshchat_build.sh <<'EOT'
#!/data/data/com.termux/files/usr/bin/bash

REPO="VouizS/MeshChat"
PROJECT_DIR="$HOME/Projetos/MeshChat"

LOCAL_LOG_DIR="$PROJECT_DIR/logs"
DOWNLOAD_LOG_DIR="/sdcard/Download/MeshChat_Logs"
DOWNLOAD_APK_DIR="/sdcard/Download/MeshChat_APKs"

mkdir -p "$LOCAL_LOG_DIR"
mkdir -p "$DOWNLOAD_LOG_DIR"
mkdir -p "$DOWNLOAD_APK_DIR"

cd "$PROJECT_DIR" || exit 1

if [ -n "$1" ]; then
    RUN_ID="$1"
else
    RUN_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId --jq '.[0].databaseId')
fi

if [ -z "$RUN_ID" ]; then
    echo "Nenhuma build encontrada."
    exit 1
fi

echo "========================================"
echo "Mesh Chat - Fiscal de Build"
echo "Repositório: $REPO"
echo "Run ID: $RUN_ID"
echo "========================================"

echo ""
echo "Acompanhando build..."
gh run watch "$RUN_ID" --repo "$REPO" || true

STATUS=$(gh run view "$RUN_ID" --repo "$REPO" --json status --jq '.status')
CONCLUSION=$(gh run view "$RUN_ID" --repo "$REPO" --json conclusion --jq '.conclusion')
TITLE=$(gh run view "$RUN_ID" --repo "$REPO" --json displayTitle --jq '.displayTitle')

DATE_TAG=$(date +"%Y-%m-%d_%H-%M-%S")
SAFE_TITLE=$(echo "$TITLE" | sed 's/[^A-Za-z0-9_.-]/_/g')
BASE_NAME="MeshChat_${SAFE_TITLE}_run-${RUN_ID}_${DATE_TAG}"

echo ""
echo "Título: $TITLE"
echo "Status: $STATUS"
echo "Resultado: $CONCLUSION"
echo ""

if [ "$CONCLUSION" = "success" ]; then
    echo "Build verde. Baixando artifacts..."

    TEMP_APK_DIR="$DOWNLOAD_APK_DIR/${BASE_NAME}"
    mkdir -p "$TEMP_APK_DIR"

    gh run download "$RUN_ID" --repo "$REPO" -D "$TEMP_APK_DIR"

    APK_PATH=$(find "$TEMP_APK_DIR" -name "*.apk" -type f | head -n 1)

    if [ -n "$APK_PATH" ] && [ -f "$APK_PATH" ]; then
        FINAL_APK="$DOWNLOAD_APK_DIR/MeshChat_build-${RUN_ID}.apk"
        cp "$APK_PATH" "$FINAL_APK"

        echo ""
        echo "APK salvo com sucesso em:"
        echo "$FINAL_APK"
        echo ""
        echo "Pasta original do artifact:"
        echo "$TEMP_APK_DIR"
    else
        echo ""
        echo "Build passou, mas nenhum APK foi encontrado dentro dos artifacts."
        echo "Verifique esta pasta:"
        echo "$TEMP_APK_DIR"
    fi

elif [ "$CONCLUSION" = "failure" ]; then
    echo "Build falhou. Baixando logs..."

    FULL_LOG="$LOCAL_LOG_DIR/${BASE_NAME}_erro-completo.txt"
    FILTERED_LOG="$LOCAL_LOG_DIR/${BASE_NAME}_erro-resumo.txt"

    gh run view "$RUN_ID" --repo "$REPO" --log-failed > "$FULL_LOG"

    grep -i -E "FAILURE|What went wrong|Execution failed|error:|e: |Could not|Unresolved|Duplicate|Exception|Caused by|A failure occurred" "$FULL_LOG" > "$FILTERED_LOG"

    cp "$FULL_LOG" "$DOWNLOAD_LOG_DIR/"
    cp "$FILTERED_LOG" "$DOWNLOAD_LOG_DIR/"

    echo ""
    echo "Logs salvos no projeto:"
    echo "$FULL_LOG"
    echo "$FILTERED_LOG"
    echo ""
    echo "Logs copiados para:"
    echo "$DOWNLOAD_LOG_DIR/"
    echo ""
    echo "Resumo do erro:"
    echo "----------------------------------------"
    cat "$FILTERED_LOG"
    echo "----------------------------------------"

else
    echo "Build terminou com resultado: $CONCLUSION"
    echo "Nada foi baixado automaticamente."
fi
EOT

chmod +x scripts/watch_meshchat_build.sh

echo "== v0.1.1-r1 aplicada localmente =="
echo "Agora rode: git status"
