# Laravel Valet

- [イントロダクション](#introduction)
    - [ValetとHomestead](#valet-or-homestead)
- [インストール](#installation)
    - [アップグレード](#upgrading)
- [サイト動作](#serving-sites)
    - ["Park"コマンド](#the-park-command)
    - ["Link"コマンド](#the-link-command)
    - [TLSによる安全なサイト](#securing-sites)
- [サイトの共有](#sharing-sites)
- [サイト限定環境変数](#site-specific-environment-variables)
- [プロキシサーバ](#proxying-services)
- [カスタムValetドライバ](#custom-valet-drivers)
    - [ローカルドライバ](#local-drivers)
- [その他のValetコマンド](#other-valet-commands)
- [Valetのディレクトリとファイル](#valet-directories-and-files)

<a name="introduction"></a>
## イントロダクション

Valet（ベレット：従者）はMacミニマニストのためのLaravel開発環境です。Vagrantも不要、/etc/hostsファイルも不要です。さらに、ローカルトンネルを使って、サイトを公開し、シェアすることもできます。**ええ、私達はこういうのも好きなんですよね。**

Laravel Valetはマシン起動時にバックグランドで[Nginx](https://www.nginx.com/)がいつも実行されるように、Macを設定します。そのため、[DnsMasq](https://en.wikipedia.org/wiki/Dnsmasq)を使用し、Valetは`*.test`ドメインへの全リクエストを、ローカルマシンのインストール済みサイトへ向けるようにプロキシ動作します。

言い換えれば、約7MBのRAMを使うとても早いLaravelの開発環境です。ValetはVagrantやHomesteadを完全に置き換えるものではありませんが柔軟な基礎、とくにスピード重視であるか、RAMが限られているマシンで動作させるのに素晴らしい代替になります。

Valetは以下をサポートしていますが、これらに限定されません。

<style>
    #valet-support > ul {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        line-height: 1.9;
    }
</style>

<div id="valet-support" markdown="1">
- [Laravel](https://laravel.com)
- [Lumen](https://lumen.laravel.com)
- [Bedrock](https://roots.io/bedrock/)
- [CakePHP 3](https://cakephp.org)
- [Concrete5](https://www.concrete5.org/)
- [Contao](https://contao.org/en/)
- [Craft](https://craftcms.com)
- [Drupal](https://www.drupal.org/)
- [ExpressionEngine](https://www.expressionengine.com/)
- [Jigsaw](https://jigsaw.tighten.co)
- [Joomla](https://www.joomla.org/)
- [Katana](https://github.com/themsaid/katana)
- [Kirby](https://getkirby.com/)
- [Magento](https://magento.com/)
- [OctoberCMS](https://octobercms.com/)
- [Sculpin](https://sculpin.io/)
- [Slim](https://www.slimframework.com)
- [Statamic](https://statamic.com)
- Static HTML
- [Symfony](https://symfony.com)
- [WordPress](https://wordpress.org)
- [Zend](https://framework.zend.com)
</div>

独自の[カスタムドライバ](#custom-valet-drivers)でValetを拡張できます。

<a name="valet-or-homestead"></a>
### ValetとHomestead

ご存知のように、ローカルのLaravel開発環境として[Homestead](/docs/{{version}}/homestead)も用意しています。HomesteadとValetは利用者の目的とローカルの開発についてのアプローチが異なります。Homesteadは自動的にNginx設定を行うUbuntuの完全な仮想マシンを提供しています。HomesteadはLinux開発環境の完全な仮想化を行いたい、もしくはWindows／Linux上で動作させたい場合、素晴らしい選択肢になります。

ValetはMac上でのみサポートされ、PHPとデータベースサーバを直接ローカルマシンへインストールする必要があります。[Homebrew](https://brew.sh/)を利用し、`brew install php`と`brew install mysql`のようなコマンドを実行すれば、簡単にインストールできます。Valetは最低限度のリソースを使い、とても早いローカル開発環境を提供します。そのため、PHPとMySQLだけが必要で、完全な仮想開発環境は必要ない場合にぴったりです。

ValetとHomesteadのどちらを選んでも、Laravelの開発環境に向け設定されており、良い選択になるでしょう。どちらを選ぶかは、自分の好みとチームの必要により決まるでしょう。

<a name="installation"></a>
## インストール

**ValetにはMacオペレーティングシステムと[Homebrew](https://brew.sh/)が必要です。インストールする前に、ApacheやNginxのようなローカルマシンの８０番ポートへバインドするプログラムがないことを確認してください。**

<div class="content-list" markdown="1">
- `brew update`で最新バージョンの[Homebrew](https://brew.sh/)をインストール、もしくはアップデートしてください。
- Homebrewを使い、`brew install php`でPHP7.4をインストールしてください。
- [Composer](https://getcomposer.org)をインストールしてください。
- `composer global require laravel/valet`でValetをインストールしてください。`~/.composer/vendor/bin`ディレクトリが実行パスに含まれていることを確認してください。
- `valet install`コマンドを実行してください。これによりValetとDnsMasqがインストール／設定され、システム起動時に起動されるValetのデーモンが登録されます。
</div>

Valetがインストールできたら、`ping foobar.test`のようなコマンドで、ターミナルから`*.test`ドメインに対してpingを実行してください。Valetが正しくインストールされていれば、このドメインは`127.0.0.1`へ対応していることがわかるでしょう。

Valetはマシンが起動されると、毎回デーモンを自動的に起動します。Valetが完全にインストールされていれば、`valet start`や`valet install`を再び実行する必要は永久にありません。

#### データベース

データベースを使いたい場合、コマンドラインで`brew install mysql@5.7`を実行し、MySQLを試してください。MySQLがインストールできたら、`brew services start mysql@5.7`コマンドを使い、起動します。`127.0.0.1`でデータベースに接続し、ユーザー名は`root`、パスワードは空文字列です。

#### PHPバージョン

Valetでは`valet use php@version`コマンドにより、PHPバージョンを変更できます。指定されたPHPバージョンがインストールされていない場合、ValetはBrewによりインストールします。

    valet use php@7.2

    valet use php

> {note} 複数のPHPバージョンをインストールしている場合でも、Valetは一度に一つのPHPバージョンのみを提供します。

#### インストレーションのリセット

Valetインストレーションが正しく動作せずに問題が起きた時は、`composer global update`の後に、`valet install`を実行してください。これによりインストール済みのValetがリセットされ、さまざまな問題が解決されます。稀にValetを「ハードリセット」する必要がある場合もあり、その場合は`valet install`の前に`valet uninstall --force`を実行してください。

<a name="upgrading"></a>
### アップグレード

Valetインストールをアップデートするには、ターミナルで`composer global update`コマンドを実行します。アップグレードできたら、`valet install`コマンドを実行し、必要な設定ファイルの追加アップグレードを行うのは、グッドプラクティスです。

<a name="serving-sites"></a>
## サイト動作

Valetがインストールできたら、サイトを動作させる準備ができました。Laravelサイトを動作させるために役立つ、`park`と`link`の２コマンドを用意しています。

<a name="the-park-command"></a>
#### `park`コマンド

<div class="content-list" markdown="1">
- `mkdir ~/Sites`のように、Mac上に新しいディレクトリを作成ししてください。次に`cd ~/Sites`し、`valet park`を実行します。このコマンドはカレントワーキングディレクトリをValetがサイトを探す親パスとして登録します。
- 次に、このディレクトリ内で、新しいLaravelサイトを作成します。`laravel new blog`
- `http://blog.test`をブラウザで開きます。
</div>

**必要なのはこれだけです。** これで"parked"ディレクトリ内に作成されたLaravelプロジェクトは、`http://フォルダ名.test`規約に従い、自動的に動作します。

<a name="the-link-command"></a>
#### `link`コマンド

`link`コマンドは`park`のように親ディレクトリを指定するのではなく、各ディレクトリ中で一つのサイトを動作させるのに便利です。

<div class="content-list" markdown="1">
- ターミナルでプロジェクトのディレクトリへ移動し、`valet link アプリケーション名`を実行します。Valetはカレントワーキングディレクトリから`~/.config/valet/Sites`内へシンボリックリンクを張ります。
- `link`コマンド実行後、ブラウザで`http://アプリケーション名.test`にアクセスできます。
</div>

リンクされた全ディレクトリをリストするには、`valet links`コマンドを実行してください。シンボリックリンクを外すときは、`valet unlink app-name`を使います。

> {tip} 複数の（サブ）ドメインで同じプロジェクトを動かすために、`valet link`を使用できます。サブドメインや他のドメインをプロジェクトに追加するためには、プロジェクトフォルダから`valet link subdomain.app-name`を実行します。

<a name="securing-sites"></a>
#### TLSを使ったサイト安全化

Valetはデフォルトで通常のHTTP通信で接続します。しかし、HTTP/2を使った暗号化されたTLSで通信したい場合は、`secure`コマンドを使ってください。たとえば、`laravel.test`ドメインでValetによりサイトが動作している場合、以下のコマンドを実行することで安全な通信を行います。

    valet secure laravel

サイトを「安全でない」状態へ戻し、通常のHTTP通信を使いたい場合は、`unsecure`コマンドです。`secure`コマンドと同様に、セキュアな通信を辞めたいホスト名を指定します。

    valet unsecure laravel

<a name="sharing-sites"></a>
## サイトの共有

Valetはローカルサイトをモバイルでテストしたり、チームメンバーや顧客と共有したりするため、世界に公開するコマンドも用意しています。Valetがインストールしてあれば、他のソフトウェアは必要ありません。

### Ngrokを使用した公開

サイトを共有するには、ターミナルでサイトのディレクトリに移動し、`valet share`コマンドを実行します。公開用のURLはクリップボードにコピーされますので、ブラウザに直接ペーストしてください。これだけでブラウザで閲覧したり、チームでシェアできます。

To stop sharing your site, hit `Control + C` to cancel the process.

> {tip} 共有コマンドには、`valet share --region=eu`のようなオプションのパラメータを渡せます。詳しい情報は、[ngrokのドキュメント](https://ngrok.com/docs)をご覧ください。

### Exposeによりサイトを共有する

[Expose](https://beyondco.de/docs/expose)がインストールされている場合は、ターミナルでサイトのディレクトリへ移動し、`expose`コマンドを実行すればサイトを共有できます。サポートされているコマンドラインパラメータは、exposeドキュメントを参照してください。サイトを共有すると、Exposeは他のデバイスやチームメンバー間で使用できる共有可能URLを表示します。

To stop sharing your site, hit `Control + C` to cancel the process.

### ローカルネットワークでのサイト共有

Valetは内部の`127.0.0.1`インターフェイスへ送信されるトラフィックをデフォルトで制限しています。これにより、開発マシンをインターネットからのセキュリティリスクに晒すのを防いでいます。

たとえば、`192.168.1.10/app-name.test`のようにIPアドレスにより、あなたのマシン上のValetサイトへローカルネットワーク上の他のデバイスからのアクセスを許す必要があるとしましょう。８０ポートと４４３ポートへ向けての`127.0.0.1:`プレフィックスを削除することで、`listen`ディレクティブの制限を解除するために、適切なNginx設定ファイルを編集する必要があります、

プロジェクトで`valet secure`を実行していない場合は、`/usr/local/etc/nginx/valet/valet.conf`ファイルを編集し、HTTPSではないサイトへのネットワークアクセスを開けます。あるサイトに対し`valet secure`を実行することで、HTTPSにてプロジェクトサイトを動かしている場合は、`~/.config/valet/Nginx/app-name.test`ファイルを編集する必要があります。

Nginx設定を更新したら、設定の変更を反映するために`valet restart`コマンドを実行してください。

<a name="site-specific-environment-variables"></a>
## サイト限定環境変数

あるアプリケーションでは、サーバ環境変数に依存するフレームワークを使っているが、プロジェクトでそのような変数を設定する手段を提供していないことがあります。Valetでは、プロジェクトのルートに`.valet-env.php`ファイルを追加することで、サイト限定の環境変数を設定できます。

    <?php

    // foo.testサイトのために、$_SERVER['key']へ"value"をセットする
    return [
        'foo' => [
            'key' => 'value',
        ],
    ];

    // 全サイトのために、$_SERVER['key']へ"value"をセットする
    return [
        '*' => [
            'key' => 'value',
        ],
    ];

<a name="proxying-services"></a>
## プロキシサーバ

時にローカルマシンの他のサービスへValetドメインをプロキシ動作させたいこともあるでしょう。たとえば、Valetを実行する一方で、たまにDockerにより別のサイトを実行する必要がある場合です。しかし、ValetとDockerは同時に８０ポートを両方でバインドできません。

これを解決するには、`proxy`コマンドを使いプロキシを生成してください。たとえば、`http://elasticsearch.test`からのトラフィックをすべて`http://127.0.0.1:9200`へ仲介するには、以下のとおりです。

    valet proxy elasticsearch http://127.0.0.1:9200

`unproxy`コマンドでプロキシを削除できます。

    valet unproxy elasticsearch

`proxies`コマンドを使い、プロキシとしてサイト設定している全サイトをリスト表示できます。

    valet proxies

<a name="custom-valet-drivers"></a>
## カスタムValetドライバ

Valetでサポートされていない、他のフレームワークやCMSでPHPアプリケーションを実行するには、独自のValet「ドライバ」を書く必要があります。Valetをインストールすると作成される、`~/.config/valet/Drivers`ディレクトリに`SampleValetDriver.php`ファイルが存在しています。このファイルは、カスタムドライバーをどのように書いたら良いかをデモンストレートするサンプルドライバの実装コードです。ドライバを書くために必要な`serves`、`isStaticFile`、`frontControllerPath`の３メソッドを実装するだけです。

全３メソッドは`$sitePath`、`$siteName`、`$uri`を引数で受け取ります。`$sitePath`は、`/Users/Lisa/Sites/my-project`のように、サイトプロジェクトへのフルパスです。`$siteName`は"ホスト" / "サイト名"記法のドメイン(`my-project`)です。`$uri`はやって来たリクエストのURI(`/foo/bar`)です。

カスタムValetドライバを書き上げたら、`フレームワークValetDriver.php`命名規則をつかい、`~/.config/valet/Drivers`ディレクトリ下に設置してください。たとえば、WordPress用にカスタムValetドライバを書いたら、ファイル名は`WordPressValetDriver.php`になります。

カスタムValetドライバで実装する各メソッドのサンプルコードを見ていきましょう。

#### `serves`メソッド

`serves`メソッドは、そのドライバがやって来たリクエストを処理すべき場合に、`true`を返してください。それ以外の場合は`false`を返してください。そのためには、メソッドの中で、渡された`$sitePath`の内容が、動作させようとするプロジェクトタイプを含んでいるかを判定します。

では擬似サンプルとして、`WordPressValetDriver`を書いてみましょう。`serves`メソッドは以下のようになります。

    /**
     * このドライバでリクエストを処理するか決める
     *
     * @param  string  $sitePath
     * @param  string  $siteName
     * @param  string  $uri
     * @return bool
     */
    public function serves($sitePath, $siteName, $uri)
    {
        return is_dir($sitePath.'/wp-admin');
    }

#### `isStaticFile`メソッド

`isStaticFile`はリクエストが画像やスタイルシートのような「静的」なファイルであるかを判定します。ファイルが静的なものであれば、そのファイルが存在するディスク上のフルパスを返します。リクエストが静的ファイルでない場合は、`false`を返します。

    /**
     * リクエストが静的なファイルであるかを判定する
     *
     * @param  string  $sitePath
     * @param  string  $siteName
     * @param  string  $uri
     * @return string|false
     */
    public function isStaticFile($sitePath, $siteName, $uri)
    {
        if (file_exists($staticFilePath = $sitePath.'/public/'.$uri)) {
            return $staticFilePath;
        }

        return false;
    }

> {note} `isStaticFile`メソッドは、リクエストのURIが`/`ではなく、`serves`メソッドで`true`が返された場合のみ呼びだされます。

#### `frontControllerPath`メソッド

`frontControllerPath`メソッドは、アプリケーションの「フロントコントローラ」への絶対パスを返します。通常は"index.php`ファイルか、似たようなファイルでしょう。

    /**
     * アプリケーションのフロントコントローラへの絶対パスの取得
     *
     * @param  string  $sitePath
     * @param  string  $siteName
     * @param  string  $uri
     * @return string
     */
    public function frontControllerPath($sitePath, $siteName, $uri)
    {
        return $sitePath.'/public/index.php';
    }

<a name="local-drivers"></a>
### ローカルドライバ

一つのアプリケーションに対して、Valetのカスタムドライバを定義する場合は、アプリケーションのルートディレクトリに`LocalValetDriver.php`を作成してください。カスタムドライバは、ベースの`ValetDriver`クラスか、`LaravelValetDriver`のような、既存のアプリケーション専用のドライバを拡張します。

    class LocalValetDriver extends LaravelValetDriver
    {
        /**
         * リクエストに対し、このドライバを動作させるかを決める
         *
         * @param  string  $sitePath
         * @param  string  $siteName
         * @param  string  $uri
         * @return bool
         */
        public function serves($sitePath, $siteName, $uri)
        {
            return true;
        }

        /**
         * アプリケーションのフロントコントローラに対する完全な解決済みパスを取得する
         *
         * @param  string  $sitePath
         * @param  string  $siteName
         * @param  string  $uri
         * @return string
         */
        public function frontControllerPath($sitePath, $siteName, $uri)
        {
            return $sitePath.'/public_html/index.php';
        }
    }

<a name="other-valet-commands"></a>
## その他のValetコマンド

コマンド |  説明
--------------------|-----------------------------------------------------------------------------------
`valet forget` | "park"された（サイト検索の親ディレクトリとして登録されたJ)ディレクトリでこのコマンドを実行し、サイト検索対象のディレクトリリストから外します。
`valet log` | Valetサービスにより書き込まれたログリストの表示
`valet paths` | "park"されたすべてのパスを表示します。
`valet restart` | Valetデーモンをリスタートします。
`valet start` | Valetデーモンをスタートします。
`valet stop` | Valetデーモンを停止します。
`valet trust` | Valetコマンド実行でパスワード入力をしなくて済むように、BrewとValetへsudoersファイルを追加します。
`valet uninstall` | Valetをアンインストールします。手動で削除する場合のインストラクションを表示します。`--force`パラメータを指定した場合は、Valetすべてを強制的に削除します。

<a name="valet-directories-and-files"></a>
## Valetのディレクトリとファイル

Valet環境の問題を追求／解決するときに役立つ、ディレクトリとファイルの一覧です。

ファイル／ディレクトリ | 説明
--------- | -----------
`~/.config/valet/` | Valetの設定すべてが含まれます。このフォルダのバックアップを管理しておきましょう。
`~/.config/valet/dnsmasq.d/` | DNSMasqの設定が含まれます。
`~/.config/valet/Drivers/` | カスタムValetドライバが含まれます。
`~/.config/valet/Extensions/` | カスタムValet拡張／コマンドが含まれます。
`~/.config/valet/Nginx/` | Valetが生成したNginxサイト設定すべてが含まれます。生成済みファイルは`install`、`secure`、`tld`コマンド実行時に再生成されます。
`~/.config/valet/Sites/` | リンク済みプロジェクへのシンボリックリンクすべてが含まれます。
`~/.config/valet/config.json` | Valetの主設定ファイルです。
`~/.config/valet/valet.sock` | ValetのNginx設定で指定されているPHP-FPMソケットです。PHPが正しく実行されているときのみ存在します。
`~/.config/valet/Log/fpm-php.www.log` | PHPエラーのユーザーログです。
`~/.config/valet/Log/nginx-error.log` | Nginxエラーのユーザーログです。
`/usr/local/var/log/php-fpm.log` | PHP-FPMエラーのシステムログです。
`/usr/local/var/log/nginx` | Nginxのアクセスとエラーログが含まれます。
`/usr/local/etc/php/X.X/conf.d` | さまざまなPHP設定に使用される`*.ini`ファイルが含まれます。
`/usr/local/etc/php/X.X/php-fpm.d/valet-fpm.conf` | PHP-FPMプール設定ファイルです。
`~/.composer/vendor/laravel/valet/cli/stubs/secure.valet.conf` | サイト認証を構築するのに使用されるデフォルトNginx設定です。
