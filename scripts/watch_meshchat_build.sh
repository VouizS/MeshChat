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
