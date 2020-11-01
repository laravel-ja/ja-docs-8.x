# Laravel Homestead

- [イントロダクション](#introduction)
- [インストールと設定](#installation-and-setup)
    - [最初の段階](#first-steps)
    - [Homestead設定](#configuring-homestead)
    - [Vagrant Boxの実行](#launching-the-vagrant-box)
    - [プロジェクトごとのインストール](#per-project-installation)
    - [オプション機能のインストール](#installing-optional-features)
    - [エイリアス](#aliases)
- [使用方法](#daily-usage)
    - [Homesteadへのグローバルアクセス](#accessing-homestead-globally)
    - [SSH接続](#connecting-via-ssh)
    - [データベース接続](#connecting-to-databases)
    - [データベースのバックアップ](#database-backups)
    - [データベーススナップショット](#database-snapshots)
    - [サイトの追加](#adding-additional-sites)
    - [環境変数](#environment-variables)
    - [ワイルドカードSSL](#wildcard-ssl)
    - [Cronスケジュール設定](#configuring-cron-schedules)
    - [Mailhogの設定](#configuring-mailhog)
    - [Minioの設定](#configuring-minio)
    - [ポート](#ports)
    - [環境の共有](#sharing-your-environment)
    - [複数のPHPバージョン](#multiple-php-versions)
    - [Webサービス](#web-servers)
    - [メール](#mail)
    - [Laravel Dusk](#laravel-dusk)
- [デバッグとプロファイリング](#debugging-and-profiling)
    - [XdebugによるWebリクエストのデバッグ](#debugging-web-requests)
    - [CLIアプリケーションのデバッグ](#debugging-cli-applications)
    - [Blackfireによるアプリケーションプロファイリング](#profiling-applications-with-blackfire)
- [ネットワークインターフェイス](#network-interfaces)
- [Homesteadの拡張](#extending-homestead)
- [Homesteadの更新](#updating-homestead)
- [プロパイダ固有の設定](#provider-specific-settings)
    - [VirtualBox](#provider-specific-virtualbox)

<a name="introduction"></a>
## イントロダクション

ローカル開発環境を含め、PHP開発全体を愉快なものにしようとLaravelは努力しています。[Vagrant](https://vagrantup.com)は、仮想マシンの管理と事前設定を行う、簡単でエレガントな手段を提供しています。

Laravel Homestead（入植農地、「ホームステード」）はパッケージを事前にインストールしたLaravel公式の"box"です。PHPやWebサーバ、その他のサーバソフトウェアをローカルマシンにインストールする必要なく、素晴らしい開発環境を準備できます。オペレーティングシステムでごちゃごちゃになる心配はもうありません！　Vagrant boxは完全に使い捨てできます。何かの調子が悪くなれば壊して、数分のうちにそのboxを再生成できます！

HomesteadはWindowsやMac、Linuxシステム上で実行でき、NginxやPHP、MySQL、PostgreSQL、Redis、Memcached、Node、他にも素晴らしいLaravelアプリケーションを開発するために必要となるものすべてを含んでいます。

> {note} Windowsを使用している場合は、ハードウェア仮想化(VT-x)を有効にする必要があります。通常、BIOSにより有効にできます。UEFI system上のHyper-Vを使用している場合は、VT-xへアクセスするため、さらにHyper-Vを無効にする必要があります。

<a name="included-software"></a>
### 含まれるソフトウェア

<style>
    #software-list > ul {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 5em; -moz-column-gap: 5em; -webkit-column-gap: 5em;
        line-height: 1.9;
    }
</style>

<div id="software-list" markdown="1">
- Ubuntu 18.04
- Git
- PHP 7.4
- PHP 7.3
- PHP 7.2
- PHP 7.1
- PHP 7.0
- PHP 5.6
- Nginx
- MySQL
- lmmによるMySQLとMariaDBデータベーススナップショット
- Sqlite3
- PostgreSQL (9.6, 10, 11, 12)
- Composer
- Node (Yarn、Bower、Bower、Grunt、Gulpを含む)
- Redis
- Memcached
- Beanstalkd
- Mailhog
- avahi
- ngrok
- Xdebug
- XHProf / Tideways / XHGui
- wp-cli
</div>

<a name="optional-software"></a>
### オプションのソフトウェア

<style>
    #software-list > ul {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 5em; -moz-column-gap: 5em; -webkit-column-gap: 5em;
        line-height: 1.9;
    }
</style>

<div id="software-list" markdown="1">
- Apache
- Blackfire
- Cassandra
- Chronograf
- CouchDB
- Crystal & Lucky Framework
- Docker
- Elasticsearch
- Gearman
- Go
- Grafana
- InfluxDB
- MariaDB
- MinIO
- MongoDB
- MySQL 8
- Neo4j
- Oh My Zsh
- Open Resty
- PM2
- Python
- RabbitMQ
- Solr
- Webdriver & Laravel Duskユーティリティ
</div>

<a name="installation-and-setup"></a>
## インストールと設定

<a name="first-steps"></a>
### 最初の段階

Homestead環境を起動する前に[Vagrant](https://www.vagrantup.com/downloads.html)と共に、[VirtualBox 6.x](https://www.virtualbox.org/wiki/Downloads)か、[VMWare](https://www.vmware.com)、[Parallels](https://www.parallels.com/products/desktop/)、[Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)をインストールする必要があります。全ソフトウェア共に簡単に使用できるビジュアルインストーラが、人気のあるオペレーティングシステムすべてに用意されています。

VMwareプロバイダを使用するには、VMware Fusion/Workstationと[VMware Vagrantプラグイン](https://www.vagrantup.com/vmware)を購入する必要があります。無料ではありませんが、VMwareが提供する共有フォルダは最初からよりスピーディーです。

Parallelsプロバイダを使用するには、[Parallels Vagrantプラグイン](https://github.com/Parallels/vagrant-parallels)をインストールする必要があります。これは無料です。

Because of [Vagrant limitations](https://www.vagrantup.com/docs/hyperv/limitations.html), the Hyper-V provider ignores all networking settings.

<a name="installing-the-homestead-vagrant-box"></a>
#### Homestead Vagrant Boxのインストール

VirtualBox/VMwareとVagrantをインストールし終えたら、`laravel/homestead` boxをVagrantへ追加するため次のコマンドを端末で実行する必要があります。boxをダウンロードし終えるまで、接続速度にもよりますが数分かかるでしょう。

    vagrant box add laravel/homestead

このコマンドが失敗する場合、Vagrantを更新する必要があります。

> {note} Homesteadは定期的に「アルファ版／ベータ版」Boxをテストのためリリースしています。これは`vagrant box add`コマンドと干渉してしまいます。`vagrant box add`の実行で問題が起きたら、`vagrant up`コマンドを実行し、Vagrantが仮想マシンを開始する時点で正しいBoxをダウンロードしてください。

<a name="installing-homestead"></a>
#### Homesteadのインストール

ホストマシンへリポジトリをクローンし、Homesteadをインストールできます。自分の「ホーム」ディレクトリの中の`Homestead`フォルダへリポジトリをクローンするのことは、自分のLaravel（とPHP）の全プロジェクトをホストしておくHomestead Boxを用意するのだと考えてください。

    git clone https://github.com/laravel/homestead.git ~/Homestead

`master`ブランチは常に安定しているわけではないため、バージョンタグがついたHomesteadをチェックアウトすべきでしょう。最新の安定バージョンは、[GitHubのリリースページ](https://github.com/laravel/homestead/releases)で見つかります。もしくは、常に最新の安定バージョンを用意している`release`ブランチをチェックアウトしてください。

    cd ~/Homestead

    git checkout release

Homesteadリポジトリをクローンしたら、`Homestead.yaml`設定ファイルを生成するために、`bash init.sh`コマンドをHomesteadディレクトリで実行します。

    // Mac／Linux
    bash init.sh

    // Windows
    init.bat

<a name="configuring-homestead"></a>
### Homestead設定

<a name="setting-your-provider"></a>
#### プロバイダの設定

`Homestead.yaml`ファイル中の`provider`キーは、Vagrantのプロバイダとして、`virtualbox`、`vmware_fusion`、`vmware_workstation`、`parallels`、`hyperv`のどれを使用するかを指定します。使用するプロバイダの値を指定してください。

    provider: virtualbox

<a name="configuring-shared-folders"></a>
#### 共有フォルダの設定

`Homestead.yaml`ファイルの`folders`プロパティには、Homestead環境と共有したい全フォルダがリストされています。これらのフォルダの中のファイルが変更されると、ローカルマシンとHomestead環境との間で同期されます。必要なだけ共有フォルダを設定してください！

    folders:
        - map: ~/code/project1
          to: /home/vagrant/project1

> {note} Windowsユーザーはパスを`~/`記法を使わず、代わりにたとえば`C:\Users\user\Code\project1`のように、プロジェクトのフルパスを使ってください。

`~/code`フォルダへ常に個別プロジェクトをマップする代わりに、別々にマップすべきでしょう。仮想マシンへあるフォルダをマップすると、そのフォルダ中の**すべて**のファイルによるディスクＩＯをトラックし続けます。これにより、フォルダの中に莫大なファイルが存在する場合に、パフォーマンスの問題が起きます。

    folders:
        - map: ~/code/project1
          to: /home/vagrant/project1

        - map: ~/code/project2
          to: /home/vagrant/project2

> {note} Homesteadを使用する場合、`.`（カレントディレクトリ）をマウントしないでください。そうすると、Vagrantはカレントフォルダを`/vagrant`へマップしない状況が起き、オプションの機能が壊れ、プロビジョン中に予期せぬ結果が起きます。

[NFS](https://www.vagrantup.com/v2/synced-folders/nfs.html)を有効にするには、同期するフォルダにフラグを指定するだけです。

    folders:
        - map: ~/code/project1
          to: /home/vagrant/project1
          type: "nfs"

> {note} Windows上でNFSを使用する場合は、[vagrant-winnfsd](https://github.com/winnfsd/vagrant-winnfsd)プラグインのインストールを考慮してください。このプラグインは、Homestead下のファイルとディレクトリのユーザー／グループパーミッションを正しく維持します。

さらに、Vagrantの[同期フォルダ](https://www.vagrantup.com/docs/synced-folders/basic_usage.html)でサポートされている任意のオプションを、`options`キーの下に列挙して渡すことができます。

    folders:
        - map: ~/code/project1
          to: /home/vagrant/project1
          type: "rsync"
          options:
              rsync__args: ["--verbose", "--archive", "--delete", "-zz"]
              rsync__exclude: ["node_modules"]

<a name="configuring-nginx-sites"></a>
#### Nginxサイトの設定

Nginxには詳しくない？　問題ありません。`sites`プロパティでHomestead環境上のフォルダと「ドメイン」を簡単にマップできます。サイト設定のサンプルは、`Homestead.yaml`ファイルに含まれています。これも必要に応じ、Homestead環境へサイトを好きなだけ追加してください。便利に使えるよう、Homesteadは皆さんが作業するすべてのLaravelプロジェクトの仮想環境を提供します。

    sites:
        - map: homestead.test
          to: /home/vagrant/project1/public

`sites`プロパティをHomestead boxのプロビジョニング後に変更した場合、仮想マシンのNginx設定を更新するため、`vagrant reload --provision`を再実行する必要があります。

> {note} Homesteadのスクリプトは可能な限り冪等性を保つように組まれています。しかしながら、プロビジョニング中に問題が起きたら、`vagrant destroy && vagrant up`によりマシンを壊し、再構築してください。

<a name="enable-disable-services"></a>
#### サービスの有効／無効

Homesteadはデフォルトで多くのサービスを起動します。プロビジョニング時にサービスの有効／無効をカスタマイズ可能です。例として、PostgreSQLを有効にし、MySQLを無効にしてみます。

    services:
        - enabled:
            - "postgresql@12-main"
        - disabled:
            - "mysql"

指定したサービスは、`enabled`と`disabled`ディレクティブ中で指定した順番に従い開始／停止します。

<a name="hostname-resolution"></a>
#### ホスト名の解決

Homesteadでは自動的にホストを解決できるように、`mDNS`によりホスト名を公開しています。`Homestead.yaml`ファイルで、`hostname: homestead`とセットすれば、このホストは`homestead.local`で使用できます。macOS、iOS、Linuxディストリビューションでは`mDNS`がデフォルトでサポートされています。Windowsでは、[Bonjour Print Services for Windows](https://support.apple.com/kb/DL999?viewlocale=en_US&locale=en_US)をインストールする必要があります。

自動ホスト名を一番活用できるのは、Homesteadを「プロジェクトごと」にインストールした場合でしょう。もし、一つのHomesteadインスタンスで複数のサイトをホストしている場合は、`hosts`ファイルにWebサイトの「ドメイン」を追加してください。`hosts`ファイルはHomesteadへのリクエストをHomestead環境へ転送してくれます。MacとLinuxでは、`/etc/hosts`にこのファイルがあります。Windows環境では、`C:\Windows\System32\drivers\etc\hosts`です。次の行のように追加してください。

    192.168.10.10  homestead.test

設定するIPアドレスには`Homestead.yaml`ファイルの中の値を確実に指定してください。ドメインを`hosts`ファイルへ追加したら、Webブラウザでサイトにアクセスできます。

    http://homestead.test

<a name="launching-the-vagrant-box"></a>
### Vagrant Boxの実行

`Homestead.yaml`のリンクを編集終えたら、Homesteadディレクトリで`vagrant up`コマンドを実行してください。Vagrantは仮想マシンを起動し、共有フォルダとNginxサイトを自動的に設定します。

仮想マシンを破壊するには、`vagrant destroy --force`コマンドを使用します。

<a name="per-project-installation"></a>
### プロジェクトごとにインストール

Homesteadをグローバルにインストールし、全プロジェクトで同じHomestead Boxを共有する代わりに、Homesteadインスタンスを管理下のプロジェクトごとに設定することもできます。プロジェクトごとにHomesteadをインストールする利点は、`Vagrantfile`をプロジェクトに用意すれば、プロジェクトに参加している他の人達も、`vagrant up`で仕事にとりかかれることです。

Homesteadをプロジェクトに直接インストールするには、Composerを使います。

    composer require laravel/homestead --dev

Homesteadがインストールできたら、`Vagrantfile`と`Homestead.yaml`ファイルをプロジェクトルートへ生成するために`make`コマンドを使ってください。`make`コマンドは`Homestead.yaml`ファイルの`sites`と`folders`ディレクティブを自動的に設定します。

Mac／Linux：

    php vendor/bin/homestead make

Windows：

    vendor\bin\homestead make

次に`vagrant up`コマンドを端末で実行し、ブラウザで`http://homestead.test`のプロジェクトへアクセスしてください。自動[ホスト名解決](#hostname-resolution)を使わない場合は、`/etc/hosts`ファイルに`homestead.test`か、自分で選んだドメインのエントリーを追加する必要があることを忘れないでください。

<a name="installing-optional-features"></a>
### オプション機能のインストール

オプションのソフトウェアは、Homestead設定ファイルの"features"設定を用い、インストールします。ほとんどの機能は論理値により有効／無効を指定できます。いくつかの機能では複数のオプションができます。

    features:
        - blackfire:
            server_id: "server_id"
            server_token: "server_value"
            client_id: "client_id"
            client_token: "client_value"
        - cassandra: true
        - chronograf: true
        - couchdb: true
        - crystal: true
        - docker: true
        - elasticsearch:
            version: 7.9.0
        - gearman: true
        - golang: true
        - grafana: true
        - influxdb: true
        - mariadb: true
        - minio: true
        - mongodb: true
        - mysql8: true
        - neo4j: true
        - ohmyzsh: true
        - openresty: true
        - pm2: true
        - python: true
        - rabbitmq: true
        - solr: true
        - webdriver: true

<a name="mariadb"></a>
#### MariaDB

MariaDBを有効にすると、MySQLを削除してMariaDBをインストールします。MariaDBはMySQLのそのまま置き換え可能な代替機能として動作します。そのため、アプリケーションのデータベース設定では、`mysql`データベースドライバをそのまま使ってください。

<a name="mongodb"></a>
#### MongoDB

デフォルト状態のMongoDBでは、データベースのユーザー名を`homestead`、パスワードを`secret`に設定します。

<a name="elasticsearch"></a>
#### Elasticsearch

デフォルトのインストールでは、`homestead`という名前のクラスタが作成されます。Elasticsearchにオペレーティングシステムのメモリの半分以上を割り当ててはいけません。つまり、Elasticsearchに割り当てる量の最低でも２倍以上のメモリをHomesteadマシンに割り当てます。

> {tip} 設定のカスタマイズについては、[Elasticsearchのドキュメント](https://www.elastic.co/guide/en/elasticsearch/reference/current)を確認してください。

<a name="neo4j"></a>
#### Neo4j

デフォルト状態のNeo4jでは、データベースのユーザー名を`homestead`、パスワードを`secret`として設定します。Neo4jブラウザにアクセスするには、Webブラウザで`http://homestead.test:7474`にアクセスしてください。Neo4jクライアントのために、`7687` (Bolt)、`7474` (HTTP)、`7473` (HTTPS)ポートが用意されています。

<a name="aliases"></a>
### エイリアス

HomesteadでBashのエイリアスを指定するには、Homesteadディレクトリにある `aliases` ファイルを編集します。

    alias c='clear'
    alias ..='cd ..'

`aliases`ファイルを更新した後に、`vagrant reload --provision`コマンドを使い、Homesteadを再度プロヴィジョニングする必要があります。これにより新しいエイリアスを使うことができます。

<a name="daily-usage"></a>
## 使用方法

<a name="accessing-homestead-globally"></a>
### Homesteadへグローバルにアクセスする

MacとLinuxシステムでは、Bashプロファイルへ簡単なBash関数を追加すれば実現できます。Windowsでは、`PATH`に「バッチ」ファイルを追加すれば、行えます。以下のスクリプトはシステムのどこからでも、どんなVagrantコマンドでも実行できるようにし、自動的にHomesteadをインストール済みのディレクトリで実行します。

<a name="mac-linux"></a>
#### Mac / Linux

    function homestead() {
        ( cd ~/Homestead && vagrant $* )
    }

エイリアス中の`~/Homestead`パスを実際のHomesteadインストール場所を示すように調整してください。関数がインストールできたら、システムのどこからでも`homestead up`や`homestead ssh`のように実行できます。

<a name="windows"></a>
#### Windows

以下の内容の`homestead.bat`バッチファイルを、マシン上に作成してください。

    @echo off

    set cwd=%cd%
    set homesteadVagrant=C:\Homestead

    cd /d %homesteadVagrant% && vagrant %*
    cd /d %cwd%

    set cwd=
    set homesteadVagrant=

スクリプト例中の`C:\Homestead`パスは、実際にHomesteadをインストールした場所を指すように調整してください。ファイルを作成したら、`PATH`へファイルの場所を追加します。これで`homestead up`や`homestead ssh`のようなコマンドをシステムのどこからでも実行できます。

<a name="connecting-via-ssh"></a>
### SSH接続

Homesteadディレクトリで`vagrant ssh`端末コマンドを実行すれば、仮想マシンにSSHで接続できます。

しかし、Homesteadマシンには頻繁にSSHでアクセスする必要があると思いますから、ホストマシンから素早くHomestead boxへSSH接続できるように、上記の「関数」を追加することを検討してください。

<a name="connecting-to-databases"></a>
### データベースへの接続

`homestead`のデータベースは、初めからMySQLとPostgreSQLの両方を設定できます。ホストマシンのデータベースクライアントから、MySQLかPostgreSQLデータベースへ接続するには、`127.0.0.1`のポート`33060`(MySQL)か、ポート`54320`(PostgreSQL)へ接続する必要があります。ユーザー名は`homestead`、パスワードは`secret`です。

> {note} ホストマシンからデータベースへ接続するには、標準的ではないポートだけを使用してください。Laravelのデータベース設定ファイル中では、デフォルトの3306と5432ポートを使用することができます。Laravelは仮想マシンの内部で動作しているからです。

<a name="database-backups"></a>
### データベースのバックアップ

Homesteadでは、Vagrant boxを壊した時点で、自動的にデータベースをバックアップできます。この機能を利用するには、Vagrant2.1.0以上を使用しなくてはなりません。もしくは、古いバージョンのVagrantを使用している場合は、`vagrant-triggers`プラグインをインストールしてください。自動データベースバックアップを有効にするには、`Homestead.yaml`ファイルに以下の行を追加してください。

    backup: true

一度設定すれば、Homesteadは`vagrant destroy`コマンドが実行されると、データベースを`mysql_backup`、`postgres_backup`ディレクトリへエクスポートします。これらのディレクトリは、Homesteadをクローンしたフォルダ中、もしくは[プロジェクトごとのインストール](#per-project-installation)を利用している場合は、プロジェクトルートの中で見つけられます。

<a name="database-snapshots"></a>
### データベーススナップショット

Homesteadでは、MySQLやMariaDBの状態をスナップショットし、[Logical MySQL Manager](https://github.com/Lullabot/lmm)を使いブランチ操作可能です。たとえば、複数のギガバイトデータベースに関わるサイトをイメージしてください。データベースをインポートし、スナップショットを取ります。何か操作し、ローカルにテスト状況を構築した後に、元の状態へ素早くリストアできるのです。

内部では、LVMのコピーオンライト(COW)サポートによる、簡単なスナップショット機能をLMMは使用しています。実践上これが意味するのは、テーブルのある一行を更新すると、その変更はディスクに書き込まれるだけであり、リストア時に大変な時間とディスクスペースを省略できるということです。

`lmm`はLVMを操作するため、`root`で実行する必要があります。実行可能なコマンドを確認するには、Vagrant Box内で`sudo lmm`を実行してください。コマンドのワークフローは次のようになるでしょう。

1. デフォルトの`master` lmmブランチへデータベースをインポートする。
1. 無変更状態のデータベーススナップショットを`sudo lmm branch prod-YYYY-MM-DD`で保存する。
1. データベースを変更する。
1. `sudo lmm merge prod-YYYY-MM-DD`を実行し、すべての変更を元に戻す。
1. `sudo lmm delete <branch>`で、不必要なブランチを削除する。

<a name="adding-additional-sites"></a>
### サイトの追加

Homestead環境をプロビジョニングし、実働した後に、LaravelアプリケーションをNginxサイトへ追加したいこともあるでしょう。希望するだけのLaravelアプリケーションを一つのHomestead環境上で実行できます。新しいサイトを追加するには、`Homestead.yaml`ファイルへ追加します。

    sites:
        - map: homestead.test
          to: /home/vagrant/project1/public
        - map: another.test
          to: /home/vagrant/project2/public

Vagrantが"hosts"ファイルを自動的に管理しない場合は、新しいサイトを追加する必要があります。

    192.168.10.10  homestead.test
    192.168.10.10  another.test

サイトを追加したら、`vagrant reload --provision`コマンドをHomesteadディレクトリで実行します。

<a name="site-types"></a>
#### サイトタイプ

Laravelベースではないプロジェクトも簡単に実行できるようにするため、Homesteadはさまざまなタイプのサイトをサポートしています。たとえば、`symfony2`サイトタイプを使えば、HomesteadにSymfonyアプリケーションを簡単に追加できます。

    sites:
        - map: symfony2.test
          to: /home/vagrant/my-symfony-project/web
          type: "symfony2"

指定できるサイトタイプは`apache`、`apigility`、`expressive`、`laravel`（デフォルト）、`proxy`、`silverstripe`、`statamic`、`symfony2`、`symfony4`、`zf`です。

<a name="site-parameters"></a>
#### サイトパラメータ

`params`サイトディレクティブを使用し、Nginxの`fastcgi_param`値を追加できます。例として、値に`BAR`を持つ`FOO`パラメータを追加してみましょう。

    sites:
        - map: homestead.test
          to: /home/vagrant/project1/public
          params:
              - key: FOO
                value: BAR

<a name="environment-variables"></a>
### 環境変数

グローバルな環境変数は、`Homestead.yaml`ファイルで追加指定できます。

    variables:
        - key: APP_ENV
          value: local
        - key: FOO
          value: bar

`Homestead.yaml`を変更したら、`vagrant reload --provision`を実行し、再プロビジョンするのを忘れないでください。これにより全インストール済みPHPバージョンに対するPHP-FPM設定と、`vagrant`ユーザーの環境も更新されます。

<a name="wildcard-ssl"></a>
### ワイルドカードSSL

Homesteadは`Homestead.yaml`ファイルの`sites:`セクションで定義している各サイトごとに、自己署名したSSL証明書を設定しています。サイトに対しワイルドカードSSL証明書を生成したい場合は、サイトの設定に`wildcard`オプションを追加してください。特定ドメインの証明書の代わりに、デフォルトでワイルドカード証明書を使用します。

    - map: foo.domain.test
      to: /home/vagrant/domain
      wildcard: "yes"

`use_wildcard`オプションが`no`と指定されている場合は、ワイルドカード証明書は生成されますが使用されません。

    - map: foo.domain.test
      to: /home/vagrant/domain
      wildcard: "yes"
      use_wildcard: "no"

<a name="configuring-cron-schedules"></a>
### Cronスケジュール設定

`schedule:run` Artisanコマンドだけを毎分実行することにより、[Cronジョブのスケジュール](/docs/{{version}}/scheduling)を簡単に行う方法をLaravelは提供しています。`schedule:run`コマンドは`App\Console\Kernel`クラスの定義を調べ、どのジョブを実行すべきかを決定します。

Homesteadサイトで`schedule:run`コマンドを実行したい場合は、サイトを定義するときに`schedule`オプションを`true`に設定してください。

    sites:
        - map: homestead.test
          to: /home/vagrant/project1/public
          schedule: true

こうしたサイト用のCronジョブは、仮想マシンの`/etc/cron.d`フォルダの中に定義されます。

<a name="configuring-mailhog"></a>
### Mailhogの設定

Mailhogを使用すると、簡単に送信するメールを捉えることができ、受信者へ実際に届けなくとも内容を調べることができます。これを使用するには、`.env`ファイルのメール設定を以下のように更新します。

    MAIL_MAILER=smtp
    MAIL_HOST=localhost
    MAIL_PORT=1025
    MAIL_USERNAME=null
    MAIL_PASSWORD=null
    MAIL_ENCRYPTION=null

Mailhogを設定したら、ダッシュボードへ`http://localhost:8025`でアクセスできます。

<a name="configuring-minio"></a>
### Minioの設定

MinioはAmazon S3と互換性のあるAPIを持つ、オープンソースなオブジェクトストレージサーバです。Minioをインストールするには、`Homestead.yaml`に[機能](#installing-optional-features)のセクション中から以下の設定オプションを加えてください。

    minio: true

デフォルトのMinioは、9600ポートで使用します。`http://localhost:9600/`を閲覧すると、Minioのコントロールパネルへアクセスできます。デフォルトアクセスキーは`homestead`、デフォルトのシークレットキーは`secretkey`です。Minioへアクセスする場合、常にリージョン`us-east-1`を使用する必要があります。

Minioを使用するために、`config/filesystems.php`設定ファイルの中の、S3ディスク設定を調整する必要があります。ディスク設定へ、`use_path_style_endpoint`オプションを追加し、同時に`url`キーを`endpoint`へ変更する必要があります。

    's3' => [
        'driver' => 's3',
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION'),
        'bucket' => env('AWS_BUCKET'),
        'endpoint' => env('AWS_URL'),
        'use_path_style_endpoint' => true,
    ]

最後に、`.env`ファイルへ以下のオプションを確実に用意してください。

    AWS_ACCESS_KEY_ID=homestead
    AWS_SECRET_ACCESS_KEY=secretkey
    AWS_DEFAULT_REGION=us-east-1
    AWS_URL=http://localhost:9600

バケットをセットアップするには、Homestead設定ファイルに`buckets`ディレクティブを追加してください。

    buckets:
        - name: your-bucket
          policy: public
        - name: your-private-bucket
          policy: none

サポートしている`policy`の値は、`none`、`download`、`upload`、`public`です。

<a name="ports"></a>
### ポート

以下のポートが、Homestead環境へポートフォワードされています。

<div class="content-list" markdown="1">
- **SSH:** 2222 &rarr;  フォワード先 22
- **ngrok UI:** 4040 &rarr; フォワード先 4040
- **HTTP:** 8000 &rarr; フォワード先 80
- **HTTPS:** 44300 &rarr; フォワード先 443
- **MySQL:** 33060 &rarr; フォワード先 3306
- **PostgreSQL:** 54320 &rarr; フォワード先 5432
- **MongoDB:** 27017 &rarr; フォワード先 27017
- **Mailhog:** 8025 &rarr; フォワード先 8025
- **Minio:** 9600 &rarr; フォワード先 9600
</div>

<a name="forwarding-additional-ports"></a>
#### 追加のフォワードポート

ご希望ならば追加のポートをVagrant Boxへフォワードすることもできます。プロトコルを指定することもできます。

    ports:
        - send: 50000
          to: 5000
        - send: 7777
          to: 777
          protocol: udp

<a name="sharing-your-environment"></a>
### 環境の共有

共同作業者やクライアントと、現在作業中の内容を共有したい場合もあるでしょう。Vagrantは`vagrant share`により、これをサポートする方法が組み込み済みです。しかし、この方法は`Homestead.yaml`ファイルに複数サイトを設定している場合には動作しません。

この問題を解決するため、Homesteadは独自の`share`コマンドを持っています。使用を開始するには、`vagrant ssh`によりHomesteadマシンとSSH接続し、`share homestead.test`を実行してください。これにより、`Homestead.yaml`設定ファイルの`homestead.test`サイトが共有されます。`homestead.test`の代わりに他の設定済みサイトを指定できます。

    share homestead.test

コマンド実行後、ログと共有サイトへアクセスするURLを含んだ、Ngrokスクリーンが現れます。カスタムリージョン、サブドメイン、その他のNgrok実行オプションをカスタマイズしたい場合は、`share`コマンドへ追加してください。

    share homestead.test -region=eu -subdomain=laravel

> {note} Vagrantは本質的に安全なものではなく、`share`コマンドによりインターネット上に自分の仮想マシンを晒すことになることを覚えておいてください。

<a name="multiple-php-versions"></a>
### 複数のPHPバージョン

Homestead6から、同一仮想マシン上での複数PHPバージョンをサポートを開始しました。`Homestead.yaml`ファイルで、特定のサイトでどのバージョンのPHPを使用するのかを指定できます。利用できるPHPバージョンは、"5.6"、"7.0"、"7.1"、"7.2"、"7.3"、"7.4（デフォルト）"です。

    sites:
        - map: homestead.test
          to: /home/vagrant/project1/public
          php: "7.1"

さらに、コマンドラインではサポート済みPHPバージョンをすべて利用できます。

    php5.6 artisan list
    php7.0 artisan list
    php7.1 artisan list
    php7.2 artisan list
    php7.3 artisan list
    php7.4 artisan list

Homestead仮想マシンの中で、以下のコマンドを実行することにより、デフォルトCLIバージョンを変更することも可能です。

    php56
    php70
    php71
    php72
    php73
    php74

<a name="web-servers"></a>
### Webサービス

HomesteadはNginxをデフォルトのWebサーバとして利用しています。しかし、サイトタイプとして`apache`が指定されると、Apacheをインストールします。両方のWebサーバを一度にインストールすることもできますが、同時に両方を**実行**することはできません。`flip`シェルコマンドがWebサーバを切り替えるために用意されています。`flip`コマンドはどちらのWebサーバが実行中かを自動的に判断し、シャットダウンし、もう一方のWebサーバを起動します。このコマンドを実行するには、HomesteadへSSH接続し、コマンドをターミナルで実行してください。

    flip

<a name="mail"></a>
### Mail

Homesteadは、デフォルトで`1025`ポートをリッスンする、Postfixメールトランスファーエージェントを用意しています。そのため、`localhost`の`1025`ポートに対して、`smtp`メールドライバーを使用するように、アプリケーションへ指示できます。その結果、すべての送信メールはPostfixにより処理され、Mailhogにより補足されます。送信済みメールを確認するには、Webブラウザで[http://localhost:8025](http://localhost:8025)を開いてください。

<a name="laravel-dusk"></a>
### Laravel Dusk

Homesteadで[Laravel Dusk](/docs/{{version}}/dusk)テストを実行するには、Homesteadの設定で[`webdriver`機能](#installing-optional-features)を有効にします。

      features:
          - webdriver: true

`webdriver`機能を完全にインストールするため、後にHomestead仮想マシンをプロビジョンし忘れないでください。

<a name="debugging-and-profiling"></a>
## デバッグとプロファイリング

<a name="debugging-web-requests"></a>
### XdebugによるWebリクエストのデバッグ

Homesteadは[Xdebug](https://xdebug.org)を使用するステップデバッグをサポートしています。たとえば、ブラウザからWebページをロードし、実行中のコードのインスペクションと変更ができるようにPHPをIDEに接続します。

デフォルトでXdebugは実行されており、接続を待っています。CLIでXdebugを有効にする必要があれば、Vagrant boxの中で`sudo phpenmod xdebug`コマンドを実行してください。次に、IDEのインストラクションにしたがい、デバッギングを有効にします。最後に、ブラウザでXdebugを起動する拡張か、[bookmarklet](https://www.jetbrains.com/phpstorm/marklets/)を設定してください。

> {note} XdebugはPHPの実行を極端に遅くしてしまいます。Xdebugを無効にするには、Vagrant Boxで`sudo phpdismod xdebug`を実行し、FPMサービスを再起動します。

<a name="debugging-cli-applications"></a>
### CLIアプリケーションのデバッグ

PHP CLIアプリケーションをデバッグするには、Vagrant Box内で、`xphp`シェルエイリアスを使用してください。

    xphp path/to/script

<a name="autostarting-xdebug"></a>
#### Xdebugの自動スタート

Webサーバへのリクエストを生成する機能テストのデバッグの場合、デバッグを開始するためにカスタムヘッダやクッキーを付与するようにテストを変更するよりは、自動的に起動するほうが簡単です。Xdebugを自動的に起動するよう強制するには、Vagrant Boxの中で以下のように`/etc/php/7.x/fpm/conf.d/20-xdebug.ini`を変更してください。

    ; Homestead.yamlで別のIPアドレスのサブセットを指定している場合は、このアドレスを合わせてください
    xdebug.remote_host = 192.168.10.1
    xdebug.remote_autostart = 1

<a name="profiling-applications-with-blackfire"></a>
### Blackfireによるアプリケーションプロファイリング

[Blackfire](https://blackfire.io/docs/introduction)はWebリクエストとCLIアプリケーションのプロファイリングと、パフォーマンスアサーションの記述を提供するSaaSサービスです。プロファイルデーターをコールグラフとタイムラインで表示するユーザーインターフェイスを提供しています。エンドユーザーにオーバーヘッドをかけずに、開発／ステージング／実働環境で使用できるように構築されています。コードと`php.ini`に対するパフォーマンスと品質、安全性のチェックを提供しています。

[Blackfire Player](https://blackfire.io/docs/player/index)はBlackfireでプロファイルシナリオを書くために使用する、オープンソースのWebクローリング／テスト／スクラッピングアプリケーションです。

Blackfireを有効にするためには、Homestead設定ファイルの"features"設定を使います。

    features:
        - blackfire:
            server_id: "server_id"
            server_token: "server_value"
            client_id: "client_id"
            client_token: "client_value"

Blackfireサーバ設定項目とクライアント設定項目には、[ユーザーアカウントが必要です](https://blackfire.io/signup)。BlackfireはCLIツールやブラウザ拡張を含んだ、アプリケーションのプロファイルに使用するさまざまなオプションを用意しています。[詳細についてはBlackfireのドキュメント](https://blackfire.io/docs/cookbooks/index)をご覧ください。

<a name="profiling-php-performance-using-xhgui"></a>
### XHGuiを使用した、PHPパフォーマンスのプロファイリング

[XHGui](https://www.github.com/perftools/xhgui)はPHPアプリケーションのパフォーマンスを表示してくれるユーザーインターフェイスです。XHGuiを有効にするには、サイト設定に`xhgui: 'true'`を追加してください。

    sites:
        -
            map: your-site.test
            to: /home/vagrant/your-site/public
            type: "apache"
            xhgui: 'true'

サイトがすでに存在する場合は、設定を更新した後に`vagrant provision`を必ず実行してください。

Webリクエストをプロファイルするには、リクエストのクエリパラメータに`xhgui=on`を付加してください。XHGuiは以降のリクエストでこのクエリリクエスト値を付ける必要がないように、リクエストへ自動的にクッキーを追加します。アプリケーションのプロファイル結果を見るには、`http://your-site.test/xhgui`をブラウザで開いてください。

XHGuiを使用してCLIリクエストのプロファイルを取る場合は、コマンドの前に`XHGUI=on`を付けてください。

    XHGUI=on path/to/script

CLIプロファイル結果は、Webのプロファイル結果と同じ方法で確認できます。

プロファイルはスクリプトの実行を低下させるため、実際のリクエストの２倍ほどの実時間になることへ注意しましょう。そのため、実際の数字ではなく、常に向上パーセンテージで比較してください。また、デバッガで中断している時間も実行時間に含まれることを認識しておきましょう。

パフォーマンスのプロファイルは非常にディスクスペースを喰うため、数日で自動的に削除されます。

<a name="network-interfaces"></a>
## ネットワークインターフェイス

`Homestead.yaml`ファイルの`network`プロパティは、Homestead環境のネットワークインターフェイスを設定します。多くのインターフェイスを必要に応じ設定可能です。

    networks:
        - type: "private_network"
          ip: "192.168.10.20"

[ブリッジ](https://www.vagrantup.com/docs/networking/public_network.html)インターフェイスを有効にするには、`bridge`項目を設定し、ネットワークタイプを`public_network`へ変更します。

    networks:
        - type: "public_network"
          ip: "192.168.10.20"
          bridge: "en1: Wi-Fi (AirPort)"

[DHCP](https://www.vagrantup.com/docs/networking/public_network.html)を有効にするには、設定から`ip`オプションを取り除いてください。

    networks:
        - type: "public_network"
          bridge: "en1: Wi-Fi (AirPort)"

<a name="extending-homestead"></a>
## Homesteadの拡張

Homesteadのルートディレクトリにある、`after.sh`スクリプトを使用し、Homesteadを拡張できます。このファイルの中へ、適切な設定や仮想マシンのカスタマイズに必要なシェルコマンドを追加してください。

Homesteadをカスタマイズすると、Ubuntuはパッケージのオリジナル設定をそのままにするか、それとも新しい設定ファイルでオーバーライドするかを尋ねます。これを停止するには、Homesteadにより事前に記述された設定の上書きをパッケージインストール時に無視するように、以下のコマンドを使用してください。

    sudo apt-get -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        install your-package

<a name="user-customizations"></a>
### ユーザーによるカスタマイズ

チームの設定でHomesteadを使用している場合でも、自分の個人的な開発スタイルに合うようにHomesteadを調整したくなることでしょう。`Homestead.yaml`が含まれるHomesteadのルートディレクトリに、`user-customizations.sh`を作成してください。このファイルの中で、好きなようにカスタマイズを行なってください。ただし、この`user-customizations.sh`はバージョンコントロールに含めてはいけません。

<a name="updating-homestead"></a>
## Homesteadの更新

Homesteadの更新を開始する前に、現在の仮想マシンを削除するために、次のコマンドをHomesteadディレクトリで実行してください。

    vagrant destroy

次に、Homesteadのソースコードを更新する必要があります。リポジトリをクローンしている場合は、リポジトリをクローンした元のディレクトリで、以下のコマンドを実行してください。

    git fetch

    git pull origin release

上記のコマンドにより、最新のHomesteadコードがGitHubリポジトリよりpullされ、最新のタグをフェッチし、タグ付けされた最新のリリースをチェックアウトします。安定リリースバージョンの最新版は、[GitHubリリースページ](https://github.com/laravel/homestead/releases)で見つけてください。

プロジェクトの`composer.json`ファイルによりHomesteadをインストールしている場合は、`composer.json`ファイルに`"laravel/homestead": "^11"`が含まれていることを確認し、依存コンポーネントをアップデートしてください。

    composer update

次に、Vagrantボックスを更新するために、`vagrant box update`コマンドを実行してください。

    vagrant box update

次に追加の設定ファイルを更新するために、Homesteadディレクトリで`bash init.sh`コマンドを実行してください。既存の`Homestead.yaml`、`after.sh`、`aliases`ファイルをオーバーライトするかどうか尋ねます。

    // Mac／Linux
    bash init.sh

    // Windows
    init.bat

最後に、最新のVagrantバージョンを使用するために、Homestead Boxを再生成する必要があります。Homesteadディレクトリで以下のコマンドを実行してください。

    vagrant up

<a name="provider-specific-settings"></a>
## プロパイダ固有の設定

<a name="provider-specific-virtualbox"></a>
### VirtualBox

<a name="natdnshostresolver"></a>
#### `natdnshostresolver`

デフォルトのHomestead設定は、`natdnshostresolver`設定を`on`にしています。これにより、HomesteadはホストのオペレーティングシステムのDNS設定を利用します。この動作をオーバーライドしたい場合は、`Homestead.yaml`へ以下の行を追加してください。

    provider: virtualbox
    natdnshostresolver: 'off'

<a name="symbolic-links-on-windows"></a>
#### Windowsでのシンボリックリンク

Windowsマシンでシンボリックリンクが正しく動かない場合は、`Vagrantfile`に以下のコードブロックを追加する必要があります。

    config.vm.provider "virtualbox" do |v|
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    end
