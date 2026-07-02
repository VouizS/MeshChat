#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== Mesh Chat v0.2.3-r1 - Compatibilidade Android/Nearby =="

cd "$HOME/Projetos/MeshChat"

if ! command -v python >/dev/null 2>&1; then
    echo "Python não encontrado. Instalando python no Termux..."
    pkg install python -y
fi

python <<'PY'
from pathlib import Path
import re

MAIN = Path("app/src/main/java/com/sw/meshchat/MainActivity.kt")
GRADLE = Path("app/build.gradle.kts")
MANIFEST = Path("app/src/main/AndroidManifest.xml")
WORKFLOW = Path(".github/workflows/android-debug.yml")

def write(path, text):
    path.write_text(text)

# =========================
# Gradle version
# =========================
gradle = GRADLE.read_text()
gradle = re.sub(r'versionCode\s*=\s*\d+', 'versionCode = 7', gradle)
gradle = re.sub(r'versionName\s*=\s*"[^"]+"', 'versionName = "0.2.3-r1"', gradle)
write(GRADLE, gradle)

# =========================
# AndroidManifest compat
# =========================
manifest = '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Nearby Connections / Wi-Fi state.
         Do NOT limit these with maxSdkVersion.
         Some Android/Google Play Services versions require them even on newer devices. -->
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />

    <!-- Android 11 and older Bluetooth permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

    <!-- Location used by older Nearby/Bluetooth discovery behavior -->
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="32" />

    <!-- Android 12+ Nearby/Bluetooth runtime permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <!-- Android 13+ Nearby Wi-Fi devices permission.
         Important for newer Android versions, including Android 14/15/16+. -->
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />

    <uses-feature android:name="android.hardware.bluetooth" android:required="false" />
    <uses-feature android:name="android.hardware.wifi" android:required="false" />

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
'''
write(MANIFEST, manifest)

# =========================
# Workflow artifact
# =========================
workflow = WORKFLOW.read_text()
workflow = re.sub(
    r'name:\s*MeshChat-v[0-9A-Za-z.\-]+-debug-apk',
    'name: MeshChat-v0.2.3-r1-debug-apk',
    workflow
)
write(WORKFLOW, workflow)

# =========================
# MainActivity compat patches
# =========================
text = MAIN.read_text()

text = re.sub(
    r'private const val APP_VERSION = "v[^"]+"',
    'private const val APP_VERSION = "v0.2.3-r1"',
    text
)

# Replace runtime permission logic
new_required = '''fun requiredNearbyPermissions(): Array<String> {
    val permissions = mutableListOf<String>()

    /*
     * Runtime permissions change by Android version:
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

fun hasAllNearbyPermissions(context: Context): Boolean'''

text = re.sub(
    r'fun requiredNearbyPermissions\(\): Array<String> \{.*?\n\}\n\nfun hasAllNearbyPermissions',
    new_required,
    text,
    flags=re.S
)

# Add compatibility helper functions after hasAllNearbyPermissions
if "fun nearbyAndroidCompatibilityLabel()" not in text:
    marker = '''fun hasAllNearbyPermissions(context: Context): Boolean {
    return requiredNearbyPermissions().all { permission ->
        if (Build.VERSION.SDK_INT < 23) {
            true
        } else {
            context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        }
    }
}
'''
    insert = marker + '''
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
        "Permissões runtime concedidas. Wi-Fi/Bluetooth precisam continuar ligados para o Nearby funcionar."
    } else {
        "Permissões pendentes: ${missing.joinToString { it.substringAfterLast('.') }}"
    }
}

fun nearbyPermissionStatusLabel(context: Context): String {
    return if (hasAllNearbyPermissions(context)) "OK" else "Pendente"
}
'''
    if marker not in text:
        raise SystemExit("ERRO: não encontrei hasAllNearbyPermissions para inserir diagnóstico")
    text = text.replace(marker, insert)

# Add controller error hint
if "private fun nearbyErrorHint" not in text:
    target = '''    private fun saveMeshContact(name: String, status: String) {
'''
    if target not in text:
        target = '''    private fun updatePeer(endpointId: String, name: String, status: String) {
'''
    helper = '''    private fun nearbyErrorHint(detail: String): String {
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

'''
    if target not in text:
        raise SystemExit("ERRO: não encontrei ponto para inserir nearbyErrorHint")
    text = text.replace(target, helper + target)

# Improve error logs in advertising/discovery failures
text = text.replace(
    'addLog("Falha ao ficar visível: $detail")',
    'addLog("Falha ao ficar visível: ${nearbyErrorHint(detail)}")'
)
text = text.replace(
    'addLog("Falha no scanner: $detail")',
    'addLog("Falha no scanner: ${nearbyErrorHint(detail)}")'
)

# Add UI compatibility cards in NearbyScreen before Controle offline
if "Compatibilidade Android" not in text:
    anchor = '''        item {
            Text(
                text = "Controle offline",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
'''
    compat_cards = '''        item {
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
'''
    if anchor not in text:
        raise SystemExit("ERRO: não encontrei bloco Controle offline")
    text = text.replace(anchor, compat_cards)

# Text updates
text = text.replace("Conversas Mesh v0.2.3", "Compatibilidade v0.2.3-r1")
text = text.replace("Contatos Mesh v0.2.2", "Compatibilidade v0.2.3-r1")
text = text.replace("Nearby v0.2.0", "Compatibilidade v0.2.3-r1")

text = text.replace(
    "Conversas Mesh: contatos salvos agora podem abrir conversas persistentes. Nearby estabilizado:",
    "Compatibilidade Android: permissões e Manifest ajustados para mais aparelhos. Nearby estabilizado:"
)
text = text.replace(
    "Contatos Mesh: dispositivos encontrados agora podem ficar salvos. Nearby estabilizado:",
    "Compatibilidade Android: permissões e Manifest ajustados para mais aparelhos. Nearby estabilizado:"
)

text = text.replace(
    "Conversas persistentes para contatos Mesh ativadas na v0.2.3.",
    "Compatibilidade Nearby ativada na v0.2.3-r1."
)
text = text.replace(
    "Contatos Mesh salvos ativados na v0.2.2.",
    "Compatibilidade Nearby ativada na v0.2.3-r1."
)

text = text.replace("A v0.2.3 usa Nearby Connections", "A v0.2.3-r1 usa Nearby Connections")
text = text.replace("A v0.2.2 usa Nearby Connections", "A v0.2.3-r1 usa Nearby Connections")
text = text.replace('status = "v0.2.3"', 'status = "v0.2.3-r1"')
text = text.replace('status = "v0.2.2"', 'status = "v0.2.3-r1"')

# Update next target if present
text = text.replace(
    '''value = "v0.2.4",
                detail = "Adicionar indicadores coloridos de conexão: boa, média, fraca e offline."''',
    '''value = "v0.2.4",
                detail = "Adicionar indicadores coloridos de conexão: boa, média, fraca e offline."'''
)
text = text.replace(
    '''value = "v0.2.3",
                detail = "Criar conversas persistentes associadas aos contatos Mesh."''',
    '''value = "v0.2.4",
                detail = "Adicionar indicadores coloridos de conexão: boa, média, fraca e offline."'''
)

write(MAIN, text)

print("v0.2.3-r1 compat aplicada com sucesso.")
PY

echo "== v0.2.3-r1 pronta localmente =="
echo "Agora rode: git status"
