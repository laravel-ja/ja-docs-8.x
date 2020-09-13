# インストール

- [インストール](#installation)
    - [サーバ要件](#server-requirements)
    - [Laravelのインストール](#installing-laravel)
    - [設定](#configuration)
- [Webサーバ設定](#web-server-configuration)
    - [ディレクトリ設定](#directory-configuration)
    - [きれいなURL](#pretty-urls)

<a name="installation"></a>
## インストール

<a name="server-requirements"></a>
### サーバ要件

Laravelフレームワークを動作させるには多少のシステム要件があります。[Laravel Homestead](/docs/{{version}}/homestead)仮想マシンでは、要求がすべて満たされています。そのため、Laravelのローカル開発環境としてHomesteadを活用されることを強く推奨します。

しかし、Homesteadを使用しない場合は、以下の要件を満たす必要があります。

<div class="content-list" markdown="1">
- PHP >= 7.3
- BCMath PHP拡張
- Ctype PHP拡張
- Fileinfo PHP extension
- JSON PHP拡張
- Mbstring PHP拡張
- OpenSSL PHP拡張
- PDO PHP拡張
- Tokenizer PHP拡張
- XML PHP拡張
</div>

<a name="installing-laravel"></a>
### Laravelのインストール

Laravelは[Composer](https://getcomposer.org)を依存パッケージの管理に使用しています。ですから、Laravelを始める前に、自分の開発機にComposerを確実にインストールしておいてください。

#### Laravelインストーラ

最初にComposerを使用し、Laravelインストーラをダウンロードします。

    composer global require laravel/installer

皆さんのシステムのどこでlaravel実行ファイルが設置されても動作するように、Composerのシステム全体のvendor/binディレクトリを`$PATH`へ登録してください。このディレクトリはオペレーティングシステムにより場所が異なります。通常は、以下の場所です。

<div class="content-list" markdown="1">
- macOS： `$HOME/.composer/vendor/bin`
- Windows： `%USERPROFILE%\AppData\Roaming\Composer\vendor\bin`
- GNU／Linuxディストリビューション： `$HOME/.config/composer/vendor/bin`もしくは、`$HOME/.composer/vendor/bin`
</div>

グローバルなComposerのインストールパスを見つけるには、`composer global about`を実行し、最初の行を確認してください。

インストールし終えたら、`laravel new`コマンドにより、指定したディレクトリに真新しいLaravelプロジェクトを作成できます。たとえば、`laravel new blog`を実行すると、`blog`という名前のディレクトリへ、必要とするパッケージが全部揃った、真新しいLaravelがインストールされます。

    laravel new blog

#### Composer Create-Project

ターミナルでComposerの`create-project`コマンドを実行し、Laravelをインストールする方法もあります。

    composer create-project --prefer-dist laravel/laravel blog

#### ローカル開発サーバ

PHPがローカルにインストール済みで、PHPの組込み開発サーバをアプリケーションサーバとして使いたい場合は、`serve` Artisanコマンドを使用します。このコマンドは、開発サーバを`http://localhost:8000`として起動します。

    php artisan serve

より堅牢なローカル開発の選択肢として、[Homestead](/docs/{{version}}/homestead)と[Valet](/docs/{{version}}/valet)も利用できます。

<a name="configuration"></a>
### 設定

#### Publicディレクトリ

Laravelをインストールできたら、Webサーバのドキュメント／Webルートが`public`ディレクトリになるように設定してください。このディレクトリの`index.php`は、アプリケーションへ送信された、全HTTPリクエストを始めに処理するフロントコントローラとして動作します。

#### 設定ファイル

フレームワークで使用する設定ファイルは、すべて`config`ディレクトリ下に設置しています。それぞれのオプションにコメントがついていますので、使用可能なオプションを理解するため、ファイル全体に目を通しておくのが良いでしょう。

#### ディレクトリパーミッション

Laravelをインストールした後に、多少のパーミッションの設定が必要です。`storage`下と`bootstrap/cache`ディレクトリをWebサーバから書き込み可能にしてください。設定しないとLaravelは正しく実行されません。[Homestead](/docs/{{version}}/homestead)仮想マシンを使用する場合は、あらかじめ設定されています。

#### アプリケーションキー

次にインストール後に行うべきなのは、アプリケーションキーにランダムな文字列を設定することです。ComposerかLaravelインストーラを使ってインストールしていれば、`php artisan key:generate`コマンドが、あらかじめ設定しています。

通常、この文字列は３２文字にすべきです。キーは`.env`環境ファイルに設定されます。もし、`.env.example`ファイルをまだ`.env`へコピーしていなければ、今すぐ行ってください。**アプリケーションキーが設定されていなければ、ユーザーセッションや他の暗号化済みデーターは安全でありません！**

#### その他の設定

Laravelのその他の設定は、最初に指定する必要がありません。すぐに開発を開始しても大丈夫です！　しかし、`config/app.php`ファイルと、その中の記述を確認しておいたほうが良いでしょう。アプリケーションに合わせ変更したい、`timezone`や`local`のような多くのオプションが含まれています。

以下のようなLaravelのコンポーネントについても、設定しておいたほうが良いでしょう。

<div class="content-list" markdown="1">
- [キャッシュ](/docs/{{version}}/cache#configuration)
- [データベース](/docs/{{version}}/database#configuration)
- [セッション](/docs/{{version}}/session#configuration)
</div>

<a name="web-server-configuration"></a>
## Webサーバ設定

<a name="directory-configuration"></a>
### ディレクトリ設定

Laravelは常にWebサーバで設定した「Webディレクトリ」のルートから提供する必要があります。「Webディレクトリ」のサブディレクトリでLaravelアプリケーションを提供しようと試みてはいけません。そうした試みはアプリケーションの中に存在するセンシティブなファイルを曝してしまう可能性があります。

<a name="pretty-urls"></a>
### きれいなURL

#### Apache

URLパスにフロントコントローラの`index.php`を付けなくても良いように、Laravelは`public/.htaccess`ファイルを用意しています。LaravelをApache上で動作させるときは、確実に`mod_rewrite`モジュールを有効に設定し、そのサーバで`.htaccess`ファイルを動作させます。

Laravelに用意されている`.htaccess`ファイルが、インストールしたApacheで動作しない場合は、以下の代替設定を試してください。

    Options +FollowSymLinks -Indexes
    RewriteEngine On

    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]

#### Nginx

Nginxを使用する場合は、すべてのリクエストが`index.php`フロントコントローラへ集まるように、サイト設定に以下のディレクティブを使用します。

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

[Homestead](/docs/{{version}}/homestead)か[Valet](/docs/{{version}}/valet)を使用する場合は、きれいなURLの設定は自動的に行われます。
