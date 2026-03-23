# ============================================================
# SuperPoint — TensorFlow 1.12 / Python 3.6.1 / CUDA 9.0 環境
#
# ベースイメージ: tensorflow/tensorflow:1.12.0-gpu-py3
#   → Ubuntu 16.04 + CUDA 9.0 + cuDNN 7 + TF 1.12 入り
#   → 同梱 Python は 3.5.1 のため pyenv で 3.6.1 をビルドする
#
# Python 3.6 のインストール方法:
#   Ubuntu 16.04 は EOL 済みで deadsnakes PPA が利用不可のため、
#   pyenv を用いてソースから Python 3.6.1 をビルドする。
# ============================================================
FROM tensorflow/tensorflow:1.12.0-gpu-py3

LABEL maintainer="SuperPoint Docker Environment"
LABEL description="TF1.12 + Python3.6.1 + CUDA9.0 environment for SuperPoint"

ENV DEBIAN_FRONTEND=noninteractive

# ── pyenv のビルド依存パッケージ ─────────────────────────────
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    wget \
    curl \
    git \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    liblzma-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# ── pyenv のインストール ──────────────────────────────────────
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

RUN curl https://pyenv.run | bash \
    && echo 'export PYENV_ROOT="/root/.pyenv"' >> /root/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' >> /root/.bashrc

# ── Python 3.6.1 のビルドとグローバル設定 ────────────────────
# ソースからビルドするため 5〜10 分程度かかる
RUN pyenv install 3.6.1 \
    && pyenv global 3.6.1 \
    && pyenv rehash

# ── pip のインストール（Python 3.6.1 向け）───────────────────
RUN curl https://bootstrap.pypa.io/pip/3.6/get-pip.py -o /tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && rm /tmp/get-pip.py

# ── Python パッケージのインストール ──────────────────────────
# 大容量パッケージのタイムアウトを防ぐため --timeout と --retries を設定し、
# パッケージをレイヤーに分割して Docker キャッシュを活用する。
# 再ビルド時は失敗したレイヤーからのみ再実行される。

# Step 1: numpy / scipy（小さいので先に確定させる）
RUN pip install --no-cache-dir --timeout=300 --retries=5 \
    numpy==1.16.4 \
    scipy==1.2.1

# Step 2: tensorflow-gpu（281 MB・最も重いため単独レイヤー・タイムアウト長め）
RUN pip install --no-cache-dir --timeout=600 --retries=10 \
    tensorflow-gpu==1.12.0

# Step 3: OpenCV（合計約 30 MB）
RUN pip install --no-cache-dir --timeout=300 --retries=5 \
    opencv-python==3.4.2.16 \
    opencv-contrib-python==3.4.2.16

# Step 4: 軽量ユーティリティ類
RUN pip install --no-cache-dir --timeout=300 --retries=5 \
    tqdm \
    pyyaml \
    flake8 \
    jupyter \
    matplotlib

# ── 作業ディレクトリ ─────────────────────────────────────────
WORKDIR /workspace

# ── entrypoint ───────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ── 環境変数 ─────────────────────────────────────────────────
ENV DATA_PATH=/data
ENV EXPER_PATH=/experiments
ENV TMPDIR=/tmp
ENV PYTHONPATH=/workspace

# ── ポート開放 (Jupyter用) ───────────────────────────────────
EXPOSE 8888

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]