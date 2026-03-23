#!/bin/bash
# ============================================================
# エントリポイント: superpoint パッケージを editable モードでインストール後、
# 指定されたコマンドを実行する
# ============================================================
set -e

# settings.py を自動生成（環境変数から）
SETTINGS_FILE="/workspace/superpoint/settings.py"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "DATA_PATH = '${DATA_PATH}'" > "$SETTINGS_FILE"
    echo "EXPER_PATH = '${EXPER_PATH}'" >> "$SETTINGS_FILE"
    echo "[entrypoint] Generated $SETTINGS_FILE"
fi

# superpoint パッケージをインストール（未インストールの場合のみ）
if ! python -c "import superpoint" 2>/dev/null; then
    echo "[entrypoint] Installing superpoint in editable mode..."
    cd /workspace && pip install -e . -q
fi

exec "$@"