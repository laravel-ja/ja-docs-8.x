# インストール

- [Laravelとの出会い](#meet-laravel)
    - [なぜLaravelなのか？](#why-laravel)
- [最初のLaravelプロジェクト](#your-first-laravel-project)
    - [macOSで始める](#getting-started-on-macos)
    - [Windowsで始める](#getting-started-on-windows)
    - [Linuxで始める](#getting-started-on-linux)
    - [Sailサービスの選択](#choosing-your-sail-services)
    - [Composerでのインストール](#installation-via-composer)
- [初期設定](#initial-configuration)
    - [環境ベースの設定](#environment-based-configuration)
    - [ディレクトリ設定](#directory-configuration)
- [次のステップ](#next-steps)
    - [Laravelフルスタックフレームワーク](#laravel-the-fullstack-framework)
    - [Laravel APIバックエンド](#laravel-the-api-backend)

<a name="meet-laravel"></a>
## Laravelとの出会い

Laravelは、表現力豊かでエレガントな構文を備えたWebアプリケーションフレームワークです。Webフレームワークは、アプリケーションを作成するための構造と開始点を提供します。これにより、細部に気を配りながら、すばらしいものの作成に集中できます。

Laravelは、すばらしい開発者エクスペリエンスの提供に努めています。同時に完全な依存注入、表現力豊かなデータベース抽象化レイヤー、キューとジョブのスケジュール、ユニットと統合テストなど、強力な機能もLaravelは提供しています。

PHPやWebフレームワークをはじめて使用する場合でも、長年の経験がある場合でも、Laravelは一緒に成長できるフレームワークです。私たちは皆さんがWeb開発者として最初の一歩を踏み出すのを支援したり、専門知識を次のレベルに引き上げる後押しをしたりしています。あなたが何を作り上げるのか楽しみにしています。

<a name="why-laravel"></a>
### なぜLaravelなのか？

Webアプリケーションを構築するときに利用できるさまざまなツールとフレームワークがあります。そうした状況でも、Laravelは最新のフルスタックWebアプリケーションを構築するために最良の選択であると私たちは信じています。

#### 前進するフレームワーク

私たちはLaravelを「前進する」フレームワークと呼んでいます。つまり、Laravelはあなたと一緒に成長するという意味です。Web開発の最初の一歩を踏み出したばかりの場合は、Laravelの膨大なドキュメント、ガイド、および[ビデオチュートリアル](https://laracasts.com)のライブラリで、圧倒されずにコツを学ぶのに役立ちます。

上級開発者でしたら、Laravelの[依存注入](/docs/{{version}}/container)、[単体テスト](/docs/{{version}}/testing)、[キュー](/docs/{{version}}/queues)、[リアルタイムイベント](/docs/{{version}}/broadcasting)などへの堅牢なツールが役立つでしょいう。Laravelは、プロフェッショナルなWebアプリケーションを構築するために調整されており、エンタープライズにおける作業負荷を処理する準備ができています。

#### スケーラブルなフレームワーク

Laravelは素晴らしくスケーラブルです。PHPのスケーリングに適した性質と、Redisのような高速な分散キャッシュシステムに対するLaravelの組み込み済みサポートにより、Laravelを使用した水平スケーリングは簡単です。実際、Laravelアプリケーションは、月あたり数億のリクエストを処理するよう簡単に拡張できます。

極端なスケーリングが必要ですか？ [Laravel Vapor](https://vapor.laravel.com)のようなプラットフォームを使用すると、AWSの最新のサーバレステクノロジーでほぼ無制限の規模でLaravelアプリケーションを実行できます。

#### コミュニティによるフレームワーク

LaravelはPHPエコシステムで最高のパッケージを組み合わせ、もっとも堅牢で開発者に優しいフレームワークとして使用できるように提供しています。さらに、世界中の何千人もの才能ある開発者が[フレームワークに貢献](https://github.com/laravel/framework)しています。多分あなたもLaravelの貢献者になるかもしれませんね。

<a name="your-first-laravel-project"></a>
## 最初のLaravelプロジェクト

私たちはできるだけLaravelを簡単に使い始められるようにしたいと思っています。自分のコンピューター上でLaravelプロジェクトを開発して実行するためのさまざまな選択肢があります。後でこうしたオプションを検討することもできますが、Laravelは[Docker](https://www.docker.com)を利用する、Laravelプロジェクトを実行できる組み込みソルーションである[Sail](/docs/{{version}}/sail)を提供しています。

Dockerは、ローカルコンピューターにインストールされているソフトウェアや構成に干渉しない、小型で軽量の「コンテナー」でアプリケーションとサービスを実行するためのツールです。これはつまり、パーソナルコンピュータ上のWebサーバやデータベースなどの複雑な開発ツールの構成や準備について心配する必要はないことを意味します。開発を開始するには、[Docker Desktop](https://www.docker.com/products/docker-desktop)をインストールするだけです。

Laravel Sailは、LaravelのデフォルトのDocker構成と、操作するための軽量のコマンドラインインターフェイスです。 Sailは、Dockerの経験がなくても、PHP、MySQL、Redisを使用してLaravelアプリケーションを構築するために良い出発点を提供しています。

> {tip} すでにDockerのエキスパートですか？心配しないでください！Laravelに含まれている `docker-compose.yml`ファイルを使用して、Sailに関するすべてをカスタマイズできます。

<a name="getting-started-on-macos"></a>
### macOSで始める

Macで開発していて、[Docker Desktop](https://www.docker.com/products/docker-desktop)がすでにインストールされているならば、簡単なターミナルコマンドを使用して新しいLaravelプロジェクトを作成できます。たとえば、「example-app」という名前のディレクトリに新しいLaravelアプリケーションを作成するには、ターミナルで以下のコマンドを実行します。

```nothing
curl -s "https://laravel.build/example-app" | bash
```

もちろん、このURLの"example-app"は好きなように変更できます。Laravelアプリケーションのディレクトリは、コマンドを実行したディレクトリ内に作成されます。

プロジェクトを作成したら、アプリケーションディレクトリに移動してLaravel Sailを起動できます。Laravel Sailは、LaravelのデフォルトのDocker構成と操作するためのシンプルなコマンドラインインターフェイスを提供します。

```nothing
cd example-app

./vendor/bin/sail up
```

Sailの`up`コマンドをはじめて実行すると、Sailのアプリケーションコンテナがマシン上に構築されます。これには数分かかるでしょう。**心配しないでください。これ以降のSailの開始・起動は、はるかに高速になります。**

アプリケーションのDockerコンテナーを開始したら、Webブラウザでアプリケーションのhttp://localhostにアクセスできます。

> {tip} Laravel Sailの詳細は、[完全なドキュメント](/docs/{{version}}/sail)で確認してください。

<a name="getting-started-on-windows"></a>
### Windowsで始める

Windowsマシンに新しいLaravelアプリケーションを作成する前に、必ず[Docker Desktop](https://www.docker.com/products/docker-desktop)をインストールしてください。次に、Windows Subsystem for Linux 2（WSL2）がインストールされ、有効になっていることを確認する必要があります。 WSLを使用すると、Linuxバイナリ実行可能ファイルをWindows 10でネイティブに実行できます。WSL2をインストールして有効にする方法については、Microsoftの[開発者環境ドキュメント](https://docs.microsoft.com/en-us/windows/wsl/install-win10)を参照してください。

> {tip} WSL2をインストールして有効にした後、Dockerデスクトップが[WSL2バックエンドを使用するように構成されている](https://docs.docker.com/docker-for-windows/wsl/)ことを確認する必要があります。

これで、最初のLaravelプロジェクトを作成する準備が整いました。[Windowsターミナル](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?rtc=1&activetab=pivot:overviewtab)を起動し、WSL2 Linuxオペレーティングシステムの新しいターミナルセッションを開始します。次に、簡単なターミナルコマンドを使用して新しいLaravelプロジェクトを作成してみましょう。たとえば、"example-app"という名前のディレクトリに新しいLaravelアプリケーションを作成するには、ターミナルで以下のコマンドを実行します。

```nothing
curl -s https://laravel.build/example-app | bash
```

もちろん、このURLの「example-app」は好きなように変更できます。Laravelアプリケーションのディレクトリは、コマンドを実行したディレクトリ内に作成されます。

プロジェクトを作成したら、アプリケーションディレクトリに移動してLaravel Sailを起動できます。Laravel Sailは、LaravelのデフォルトのDocker構成と操作するためのシンプルなコマンドラインインターフェイスを提供します。

```nothing
cd example-app

./vendor/bin/sail up
```

Sailの`up`コマンドをはじめて実行すると、Sailのアプリケーションコンテナがマシン上に構築されます。これには数分かかるでしょう。**心配しないでください。これ以降のSailの開始・起動は、はるかに高速になります。**

アプリケーションのDockerコンテナーを開始したら、Webブラウザでアプリケーションのhttp://localhostにアクセスできます。

> {tip} Laravel Sailの詳細は、[完全なドキュメント](/docs/{{version}}/sail)で確認してください。

#### WSL2内での開発

もちろん、WSL2インストール内で作成されたLaravelアプリケーションファイルを変更する必要があります。これを実現するには、Microsoftの[Visual Studio Code](https://code.visualstudio.com)エディターと[リモート開発](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)用のファーストパーティ拡張機能を使用することをお勧めします。

これらのツールをインストールしたら、Windowsターミナルを使用してアプリケーションのルートディレクトリから `code .`コマンドを実行することで、任意のLaravelプロジェクトを開けます。

<a name="getting-started-on-linux"></a>
### Linuxで始める

Linuxで開発しており、[Docker](https://www.docker.com)がインストール済みの場合は、簡単なターミナルコマンドを使用して新しいLaravelプロジェクトを作成できます。たとえば、"example-app"という名前のディレクトリに新しいLaravelアプリケーションを作成するには、ターミナルで次のコマンドを実行します。

```nothing
curl -s https://laravel.build/example-app | bash
```

もちろん、このURL中の”example-app”は好きなものに変更できます。Laravelアプリケーションのディレクトリは、コマンドを実行したディレクトリ内に作成されます。

プロジェクトを作成できたら、アプリケーションディレクトリに移動してLaravel Sailを起動できます。Laravel Sailは、LaravelのデフォルトのDocker構成と操作のためのシンプルなコマンドラインインターフェイスを提供しています。

```nothing
cd example-app

./vendor/bin/sail up
```

Sailの`up`コマンドをはじめて実行すると、Sailのアプリケーションコンテナがマシン上に構築されます。これには数分かかるでしょう。**心配しないでください。これ以降のSailの開始・起動は、はるかに高速になります。**

アプリケーションのDockerコンテナーを開始したら、Webブラウザでアプリケーションのhttp://localhostにアクセスできます。

> {tip} Laravel Sailの詳細は、[完全なドキュメント](/docs/{{version}}/sail)で確認してください。

<a name="choosing-your-sail-services"></a>
### Sailサービスの選択

Sailで新しいLaravelアプリケーションを作成する際に、`with`というクエリ文字列変数を使って、新しいアプリケーションの`docker-compose.yml`ファイルで設定するサービスを選択することができます。利用可能なサービスは、`mysql`、`pgsql`、`redis`、`memcached`、`meilisearch`、`selenium`、`mailhog`です。

```nothing
curl -s "https://laravel.build/example-app?with=mysql,redis" | bash
```

設定したいサービスを指定しない場合は、`mysql`、`redis`、`meilisearch`、`mailhog`、`selenium`のデフォルトのスタックが設定されます。

<a name="installation-via-composer"></a>
### Composerでのインストール

コンピューターにすでにPHPとComposerがインストールされていれば、Composerを直接使用して新しいLaravelプロジェクトを作成できます。アプリケーションを作成したら、Artisan CLIの`serve`コマンドを使用して、Laravelのローカル開発サーバを起動できます。

    composer create-project laravel/laravel example-app

    cd example-app

    php artisan serve

<a name="the-laravel-installer"></a>
#### Laravelインストーラ

または、LaravelインストーラをグローバルなComposerのパッケージとしてインストールすることもできます。

```nothing
composer global require laravel/installer

laravel new example-app

cd example-app

php artisan serve
```

Composerのシステム全体のvendor/binディレクトリを`$PATH`に配置して、システムで`laravel`実行可能ファイルが見つかるようにしてください。このディレクトリは、オペレーティングシステムに基づいてさまざまな場所に存在します。ただし、一般的には以下の場所にあります。

<div class="content-list" markdown="1">
- macOS: `$HOME/.composer/vendor/bin`
- Windows: `%USERPROFILE%\AppData\Roaming\Composer\vendor\bin`
- GNU／Linuxディストリビューション: `$HOME/.config/composer/vendor/bin`もしくは`$HOME/.composer/vendor/bin`
</div>

利便性のため、Laravelインストーラはあなたの新しいプロジェクトのためにGitリポジトリを作成することもできます。Gitリポジトリを作成することを指示するには、新しいプロジェクトを作成するときに`--git`フラグを渡します。

```bash
laravel new example-app --git
```

このコマンドはプロジェクトの新しいGitリポジトリを初期化し、基本的なLaravelのスケルトンを自動的にコミットします。`git`フラグは正しくインストールされ、設定したGitを持っていると仮定しています。`--branch`フラグを使用して最初の分岐名を設定することもできます。

```bash
laravel new example-app --git --branch="main"
```

`--git`フラグを使用する代わりに、`--github`フラグを使用してGitリポジトリを作成し、GitHubで対応するプライベートリポジトリを作成することもできます。

```bash
laravel new example-app --github
```

作成されたリポジトリは`https://github.com/<your-account>/my-app.com`で入手できます。`github`フラグは、[`gh` CLIツール](https://cli.github.com)を正しくインストールし、GitHubで認証されていると仮定しています。さらに、`git`がインストールされ、正しく設定されている必要があります。必要に応じて、GitHub CLIでサポートされている追加のフラグを渡せます。

```bash
laravel new example-app --github="--public"
```

`--organization`フラグを使用して、特定のGitHub組織の下へリポジトリを作成できます。

```bash
laravel new example-app --github="--public" --organization="laravel"
```

<a name="initial-configuration"></a>
## 初期設定

Laravelフレームワークのすべての設定ファイルは、`config`ディレクトリに保存されます。各オプションはコメントで説明してますので、ファイルを調べて使用可能なオプションをよく理解してください。

Laravelは最初から、追加の設定をほぼ必要としません。あなたは自由に開発を始めることができます！ただし、`config/app.php`ファイルとコメントを確認されることを推奨します。`timezone`や`locale`などのいくつかのオプションが含まれており、アプリケーションに合わせて変更したいはずです。

<a name="environment-based-configuration"></a>
### 環境ベースの設定

Laravelの設定オプション値の多くは、アプリケーションがローカルコンピューターで実行されているか、本番Webサーバで実行されているかにより別の値にする場合があるため、多くの重要な設定値をアプリケーションのルートにある`.env`ファイルを使用して定義しています。

アプリケーションを使用する開発者／サーバごとに異なる環境設定が必要になる可能性があるため、`.env`ファイルをアプリケーションのソース管理へコミットしないでください。さらに、機密性の高い資格情報が公開されるため、侵入者がソース管理リポジトリにアクセスした場合のセキュリティリスクになります。

> {tip} `.env`ファイルと環境ベースの設定の詳細については、完全な[設定ドキュメント](/docs/{{version}}/configuration#environment-configuration)で確認してください。

<a name="directory-configuration"></a>
### ディレクトリ設定

Laravelは常に、Webサーバで設定した「Webディレクトリ」のルートから提供するべきです。WebディレクトリのサブディレクトリからLaravelアプリケーションを提供しないでください。そうしてしまうと、アプリケーション内に存在する機密ファイルが漏洩する可能性があります。

<a name="next-steps"></a>
## 次のステップ

Laravelプロジェクトを設定し終えて、次に何を学ぶべきか迷っているかもしれません。まず、以下のドキュメントを読み、Laravelの仕組みを理解することを強く推奨いたします。

<div class="content-list" markdown="1">
- [リクエストのライフサイクル](/docs/{{version}}/lifecycle)
- [設定](/docs/{{version}}/configuration)
- [ディレクトリ構成](/docs/{{version}}/structure)
- [サービスコンテナ](/docs/{{version}}/container)
- [ファサード](/docs/{{version}}/facades)
</div>

Laravelをどのように使用するかにより、旅の次の行き先も決まります。Laravelを使用するにはさまざまな方法があります。以下では、フレームワークの２つの主要なユースケースについて説明します。

<a name="laravel-the-fullstack-framework"></a>
### Laravelフルスタックフレームワーク

Laravelはフルスタックフレームワークとして機能します。「フルスタック」フレームワークとは、Laravelを使用してリクエストをアプリケーションにルーティングし、[Bladeテンプレート](/docs/{{version}}/blade)を介して、もしくは[Inertia.js](https://inertiajs.com)のようなシングルページアプリケーションハイブリッド技術を使用してフロントエンドをレンダーすることを意味します。これは、Laravelフレームワークが利用される、最も一般的な方法です。

Laravelをこの方法で使用しようと計画している場合は、[ルーティング](/docs/{{version}}/routing)、[ビュー](/docs/{{version}}/views) 、または[Eloquent ORM](/docs/{{version}}/eloquent)に関するドキュメントを確認するのが良いでしょう。さらに、[Livewire](https://laravel-livewire.com)や[Inertia.js](https://inertiajs.com)などのコミュニティパッケージについて学ぶこともできます。これらのパッケージを使用すると、Laravelをフルスタックフレームワークとして使用しながら、単一ページのJavaScriptアプリケーションによって提供されるUIの利点の多くを享受できます。

Laravelをフルスタックフレームワークとして使用する場合は、[Laravel Mix](/docs/{{version}}/mix)を使用してアプリケーションのCSSとJavaScriptをコンパイルする方法を学ぶことも強くおすすめします。

> {tip} アプリケーションの構築をすぐに始めたい場合は、公式の[アプリケーションスターターキット](/docs/{{version}}/starter-kits)の１つをチェックしてください。

<a name="laravel-the-api-backend"></a>
### Laravel APIバックエンド

Laravelは、JavaScriptシングルページアプリケーションまたはモバイルアプリケーションへのAPIバックエンドとしても機能させることもあります。たとえば、[Next.js](https://nextjs.org)アプリケーションのAPIバックエンドとしてLaravelを使用できます。こうした使い方では、Laravelでアプリケーションに[認証](/docs/{{version}}/sanctum)とデータの保存/取得を提供すると同時に、キュー、メール、通知などのLaravelの強力なサービスを利用できます。

この方法でLaravelの使用を計画している場合は、[ルーティング](/docs/{{version}}/routing)、[Laravel Sanctum](/docs/{{version}}/sanctum)、[Eloquent ORM](/docs/{{version}}/eloquent)に関するドキュメントを確認することをお勧めします。

