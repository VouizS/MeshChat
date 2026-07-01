#!/data/data/com.termux/files/usr/bin/bash

echo "== Mesh Chat v0.1.0 - criando estrutura =="

mkdir -p app/src/main/java/com/sw/meshchat
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/drawable
mkdir -p .github/workflows

cat > settings.gradle.kts <<'EOT'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MeshChat"
include(":app")
EOT

cat > build.gradle.kts <<'EOT'
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "1.9.25" apply false
}
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
        versionCode = 1
        versionName = "0.1.0"
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

    debugImplementation("androidx.compose.ui:ui-tooling")
}
EOT

cat > app/src/main/AndroidManifest.xml <<'EOT'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher_foreground"
        android:label="@string/app_name"
        android:roundIcon="@drawable/ic_launcher_foreground"
        android:supportsRtl="true"
        android:theme="@style/Theme.MeshChat">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

        </activity>
    </application>

</manifest>
EOT

cat > app/src/main/res/values/strings.xml <<'EOT'
<resources>
    <string name="app_name">Mesh Chat</string>
</resources>
EOT

cat > app/src/main/res/values/styles.xml <<'EOT'
<resources>
    <style name="Theme.MeshChat" parent="@android:style/Theme.Material.NoActionBar">
        <item name="android:windowNoTitle">true</item>
        <item name="android:fontFamily">sans</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:navigationBarColor">#071B18</item>
        <item name="android:statusBarColor">#071B18</item>
    </style>
</resources>
EOT

cat > app/src/main/res/drawable/ic_launcher_foreground.xml <<'EOT'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

    <path
        android:fillColor="#071B18"
        android:pathData="M0,0 L108,0 L108,108 L0,108 Z" />

    <path
        android:fillColor="#00D8B8"
        android:pathData="M24,35 Q24,25 34,25 L74,25 Q84,25 84,35 L84,63 Q84,73 74,73 L55,73 L35,88 L35,73 L34,73 Q24,73 24,63 Z" />

    <path
        android:fillColor="#073C35"
        android:pathData="M38,42 L70,42 L70,49 L38,49 Z" />

    <path
        android:fillColor="#073C35"
        android:pathData="M38,56 L61,56 L61,63 L38,63 Z" />

    <path
        android:fillColor="#E9FFF9"
        android:pathData="M20,30 Q37,15 55,23 Q72,31 88,20 L93,26 Q75,45 55,34 Q39,26 25,37 Z" />
</vector>
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
import androidx.compose.material3.AssistChip
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

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

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MeshChatTheme {
                MeshChatApp()
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
        surfaceVariant = Color(0xFFDCE5E1)
    )

    val darkScheme = darkColorScheme(
        primary = Color(0xFF72D8C7),
        onPrimary = Color(0xFF003731),
        primaryContainer = Color(0xFF005047),
        onPrimaryContainer = Color(0xFF8FF5E2),
        secondary = Color(0xFFB0CCC4),
        background = Color(0xFF0B1512),
        surface = Color(0xFF0B1512),
        surfaceVariant = Color(0xFF3F4945)
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
                time = "v0.1.0",
                status = "Dev"
            )
        )
    }

    var selectedConversationId by rememberSaveable { mutableStateOf<Int?>(null) }
    val selectedConversation = conversations.firstOrNull { it.id == selectedConversationId }

    if (selectedConversation == null) {
        ConversationListScreen(
            conversations = conversations,
            onOpenConversation = { selectedConversationId = it.id }
        )
    } else {
        ChatScreen(
            conversation = selectedConversation,
            onBack = { selectedConversationId = null }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConversationListScreen(
    conversations: List<Conversation>,
    onOpenConversation: (Conversation) -> Unit
) {
    Scaffold(
        topBar = {
            LargeTopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Mesh Chat",
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Mensagens offline em construção",
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
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                HeroStatusCard()
            }

            item {
                Text(
                    text = "Conversas",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
                )
            }

            items(conversations) { conversation ->
                ConversationCard(
                    conversation = conversation,
                    onClick = { onOpenConversation(conversation) }
                )
            }
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
                text = "Material 3 Base",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Text(
                text = "Primeira versão visual do Mesh Chat. Depois vamos ativar permissões e comunicação offline entre celulares próximos.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                AssistChip(
                    onClick = {},
                    label = { Text("v0.1.0") }
                )
                AssistChip(
                    onClick = {},
                    label = { Text("Offline-first") }
                )
            }
        }
    }
}

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
                    modifier = Modifier.size(28.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primary
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = conversation.unread.toString(),
                            color = MaterialTheme.colorScheme.onPrimary,
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun AvatarBubble(name: String) {
    val initial = name.firstOrNull()?.uppercaseChar()?.toString() ?: "M"

    Surface(
        modifier = Modifier.size(52.dp),
        shape = CircleShape,
        color = MaterialTheme.colorScheme.primary
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = initial,
                color = MaterialTheme.colorScheme.onPrimary,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
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
            TopAppBar(
                title = {
                    Column {
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
                    TextButton(onClick = onBack) {
                        Text("Voltar")
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
                OfflineInfoCard()
            }

            items(messages) { message ->
                MessageBubble(message = message)
            }
        }
    }
}

@Composable
fun OfflineInfoCard() {
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
          name: MeshChat-v0.1.0-debug-apk
          path: app/build/outputs/apk/debug/app-debug.apk
EOT

echo "== Arquivos criados com sucesso =="
echo "Agora rode:"
echo "git status"
