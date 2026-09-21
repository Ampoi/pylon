# Space ROSで動かす

PyLoNのbridgeと機体制御パッケージを、公式Space ROSのコンテナ内でビルド・実行できます。KSPはホストPCで実行します。

対象はLinux x86_64です。公式の`osrf/space-ros:jazzy-2026.07.0`をdigest付きで固定し、コンテナ内の`/opt/ros/spaceros`にあるROSライブラリを使用します。ホストの`~/ros2_ws`とは別のビルド成果物になります。

## 準備

UbuntuでDockerが未導入の場合:

```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker "$USER"
```

ログアウトして再ログインした後、`docker version`でServer情報が表示されることを確認してください。現在のターミナルだけ更新する場合は`newgrp docker`を実行します。

KSPのMOD導入は[Getting Started](getting-started.md)を参照してください。ソースから同期する場合は次のコマンドを使います。ホストにROSをインストールする必要はありません。

```bash
./sync.sh --skip-ros2-sync --skip-ros2-build
```

## ビルドと起動

リポジトリのルートで実行します。

```bash
./spaceros.sh build
./spaceros.sh test
./spaceros.sh run
```

ビルド対象は`pylon_interfaces`、`pylon_bridge`、`pylon_vehicle_control`です。初回は公式イメージをダウンロードします。ソースを変更した後は`build`を再実行してください。デモやRVizはこのイメージには含めていません。

`run`はUDPポート49010で待ち受け、指令を49011へ返送します。ホスト側のbridgeを停止してから起動してください。Linuxのhost networkを使用するので、KSPの`stateHost`とbridgeの`--command-host`は`127.0.0.1`のままで接続できます。

KSPでセンサー付き機体のFlightを開きます。別ターミナルから確認できます。

```bash
./spaceros.sh exec ros2 topic list --no-daemon
./spaceros.sh exec ros2 topic echo --once /ksp_vessel/lifecycle
./spaceros.sh exec ros2 topic echo --once /ksp_vessel/imu/data_raw
```

任意のSpace ROSコマンドを試すには`./spaceros.sh shell`で新しいシェルを開きます。実行中のbridgeはCtrl+C、または別ターミナルの`./spaceros.sh stop`で停止します。

Bridgeのオプションは`run`の後に渡せます。

```bash
./spaceros.sh run --disable-ground-truth
```

## ホストのROS 2から使う

Space ROS側ではCyclone DDSを使います。既存のJazzyアプリやRVizも、同じ`ROS_DOMAIN_ID`で通信できます。既定値は`0`で、DDS discoveryは`LOCALHOST`です。

```bash
source /opt/ros/jazzy/setup.bash
source ~/ros2_ws/install/setup.bash
export ROS_DOMAIN_ID=0
export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
ros2 topic list --no-daemon
```

ホストでPyLoNの独自メッセージを扱う場合は、同じソースからビルドした`pylon_interfaces`が必要です。ホスト側のワークスペース更新には従来どおり`./sync.sh --skip-ksp-build --skip-ksp-sync`を使えます。

## 検証範囲

2026-09-21に、上記Space ROSイメージで3パッケージのビルドと119件の回帰テストを確認しました。UDP/DDSの結合試験ではIMU、2D/3D LiDAR、分割RGB画像、指令返送、通信タイムアウト時の指令抑止と再接続を検証しています。

実KSPとの接続では開発用ランチャーで月面ローバーを起動し、320×240のRGB画像、3D点群、IMU、12リンクの機体モデルとTFを受信しました。移動指令を送らずに制御権の取得・解放も確認しています。ホストのROS 2 Jazzy / Fast DDSからの購読も検証済みです。

## トラブルシュート

- Docker socketの`permission denied`: Dockerグループへの追加後にログインし直すか、`newgrp docker`を実行します。
- UDPの`Address already in use`: ホストで動いている別のbridgeを停止します。
- `pylon-spaceros`というコンテナ名が使用中: `./spaceros.sh stop`で停止してから再実行します。
- `/pylon/status`しか見えない: KSPをFlightにして、MODの送信先とUDPポートを確認します。
- ホストからTopicが見えない: 両側の`ROS_DOMAIN_ID`とdiscovery設定を合わせ、古いCLI daemonの影響を避けて`ros2 topic list --no-daemon`で確認します。

公式資料: [Space ROS導入案内](https://space-ros.github.io/docs/rolling/Getting-Started.html)、[公式イメージ](https://hub.docker.com/r/osrf/space-ros/tags)、[Docker導入](https://docs.docker.com/engine/install/ubuntu/)。
