# データベース：準備

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [読み／書き接続](#read-and-write-connections)
- [SQLクエリの実行](#running-queries)
    - [複数データベース接続の使用](#using-multiple-database-connections)
    - [クエリイベントのリッスン](#listening-for-query-events)
- [データベーストランザクション](#database-transactions)
- [データベースCLIへの接続](#connecting-to-the-database-cli)

<a name="introduction"></a>
## イントロダクション

最近のほとんどすべてのWebアプリケーションは、データベースとやり取りします。Laravelでは、素のSQL、[fluent（流暢な）クエリビルダ](/docs/{{version}}/queries)、および[Eloquent ORM](/docs/{{version}}/eloquent)を使用して、サポートしているさまざまなでデータベースとのやり取りを非常に簡単にしています。現在、Laravelは４つのデータベースをファーストパーティサポートしています。

<div class="content-list" markdown="1">
- MySQL5.7以上 ([バージョンポリシー](https://en.wikipedia.org/wiki/MySQL#Release_history))
- PostgreSQL9.6以上 ([バージョンポリシー](https://www.postgresql.org/support/versioning/))
- SQLite3.8.8以上
- SQL Server2017以上 ([バージョンポリシー](https://support.microsoft.com/en-us/lifecycle/search))
</div>

<a name="configuration"></a>
### 設定

Laravelのデータベースサービスの設定は、アプリケーションの`config/database.php`設定ファイルにあります。このファイルは、全データベース接続を定義し、デフォルトで使用する接続を指定できます。このファイル内のほとんどの設定オプションは、アプリケーションの環境変数の値によって決まります。Laravelがサポートしているデータベースシステムのほとんどの設定例をこのファイルに用意しています。

デフォルトのLaravelのサンプル[環境設定](/docs/{{version}}/configuration#environment-configuration)は、[Laravel Sail](/docs/{{version}}/sail)で使用できるようになっています。SailはローカルマシンでLaravelアプリケーションを開発するためのDocker環境です。しかし、ローカルデータベースの必要に応じ、データベース設定を自由に変更してください。

<a name="sqlite-configuration"></a>
#### SQLite設定

SQLiteデータベースは、ファイルシステム上の単一ファイルに含まれます。ターミナルで`touch`コマンドを使用して新しいSQLiteデータベースを作成できます。（`touch database/database.sqlite`）データベースを作成したあと、データベースへの絶対パスを`DB_DATABASE`環境変数で指定することにより、このデータベースを使用するよう簡単に設定できます。

    DB_CONNECTION=sqlite
    DB_DATABASE=/absolute/path/to/database.sqlite

SQLite接続の外部キー制約を有効にするには、`DB_FOREIGN_KEYS`環境変数を`true`に設定する必要があります。

    DB_FOREIGN_KEYS=true

<a name="mssql-configuration"></a>
#### Microsoft SQLサーバ設定

Microsoft　SQL Serverデータベースを使用するには、`sqlsrv`、`pdo_sqlsrv`PHP拡張機能と、Microsoft SQL ODBCドライバーなど必要な依存関係パッケージを確実にインストールしてください。

<a name="configuration-using-urls"></a>
#### URLを使用した設定

通常、データベース接続は、`host`、`database`、`username`、`password`などの複数の設定値により構成します。こうした設定値には、それぞれ対応する環境変数があります。これは、運用サーバでデータベース接続情報を設定するときに、複数の環境変数を管理する必要があることを意味します。

AWSやHerokuなどの一部のマネージドデータベースプロバイダは、データベースのすべての接続情報を単一の文字カラムで含む単一のデータベース「URL」を提供しています。データベースURLの例は、次のようになります。

```html
mysql://root:password@127.0.0.1/forge?charset=UTF-8
```

こうしたURLは通常、標準のスキーマ規約に従います。

```html
driver://username:password@host:port/database?options
```

利便性のため、Laravelは複数の設定オプションを使用してデータベースを構成する代わりに、こうしたURLをサポートしています。`url`(または対応する`DATABASE_URL`環境変数)設定オプションが存在する場合は、データベース接続と接続情報を抽出するためにそれを使用します。

<a name="read-and-write-connections"></a>
### 読み／書き接続

SELECTステートメントに１つのデータベース接続を使用し、INSERT、UPDATE、およびDELETEステートメントに別のデータベース接続を使用したい場合があるでしょう。Laravelでは簡単に、素のクエリ、クエリビルダ、もしくはEloquent ORMのいずれを使用していても常に適切な接続が使用されます。

読み取り/書き込み接続を設定する方法を確認するため、以下の例を見てみましょう。

    'mysql' => [
        'read' => [
            'host' => [
                '192.168.1.1',
                '196.168.1.2',
            ],
        ],
        'write' => [
            'host' => [
                '196.168.1.3',
            ],
        ],
        'sticky' => true,
        'driver' => 'mysql',
        'database' => 'database',
        'username' => 'root',
        'password' => '',
        'charset' => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix' => '',
    ],

設定配列には、`read`、`write`、`sticky`の３キーが追加されていることに注目してください。`read`キーと`write`キーには、単一のキーとして`host`を含む配列値があります。`read`および` write`接続の残りのデータベースオプションは、メインの`mysql`設定配列からマージされます。

メインの`mysql`配列の値をオーバーライドする場合にのみ、`read`配列と`write`配列へ項目を配置する必要があります。したがって、この場合、`192.168.1.1`は「読み取り」接続のホストとして使用し、`192.168.1.3`は「書き込み」接続に使用します。データベースの接続情報、プレフィックス、文字セット、およびメインの`mysql`配列内の他のすべてのオプションは、両方の接続で共有されます。`host`設定配列に複数の値が存在する場合、リクエストごとランダムにデータベースホストを選択します。

<a name="the-sticky-option"></a>
#### `sticky`オプション

`sticky`オプションは、現在のリクエストサイクル中にデータベースへ書き込まれたレコードをすぐに読み取るため使用する**オプション**値です。`sticky`オプションが有効になっており、現在のリクエストサイクル中にデータベースへ対し「書き込み」操作が実行された場合、それ以降の「読み取り」操作では「書き込み」接続が使用されます。これにより、要求サイクル中に書き込まれたデータを、同じ要求中にデータベースからすぐに読み戻すことができます。これがアプリケーションにとって望ましい動作であるかどうかを判断するのは使用者の皆さん次第です。

<a name="running-queries"></a>
## SQLクエリの実行

データベース接続を設定したら、`DB`ファサードを使用してクエリが実行できます。`DB`ファサードは、クエリのタイプごとに`select`、`update`、`insert`、`delete`、` statement`メソッドを提供しています。

<a name="running-a-select-query"></a>
#### SELECTクエリの実行

基本的なSELECTクエリを実行するには、`DB`ファサードで`select`メソッドを使用します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\DB;

    class UserController extends Controller
    {
        /**
         * アプリケーションの全ユーザーのリストを表示
         *
         * @return \Illuminate\Http\Response
         */
        public function index()
        {
            $users = DB::select('select * from users where active = ?', [1]);

            return view('user.index', ['users' => $users]);
        }
    }

`select`メソッドの最初の引数はSQLクエリであり、２番目の引数はクエリにバインドする必要のあるパラメータバインディングです。通常、これらは `where`句の制約の値です。パラメータバインディングは、SQLインジェクションに対する保護を提供します。

`select`メソッドは常に結果の`配列`を返します。配列内の各結果は、データベースのレコードを表すPHPの`stdClass`オブジェクトになります。

    use Illuminate\Support\Facades\DB;

    $users = DB::select('select * from users');

    foreach ($users as $user) {
        echo $user->name;
    }

<a name="using-named-bindings"></a>
#### 名前付きバインディングの使用

パラメータバインディングを表すために`?`を使用する代わりに、名前付きバインディングを使用してクエリを実行できます。

    $results = DB::select('select * from users where id = :id', ['id' => 1]);

<a name="running-an-insert-statement"></a>
#### INSERT文の実行

`insert`ステートメントを実行するには、`DB`ファサードで`insert`メソッドを使用します。`select`と同様に、このメソッドはSQLクエリを最初の引数に取り、バインディングを２番目の引数に取ります。

    use Illuminate\Support\Facades\DB;

    DB::insert('insert into users (id, name) values (?, ?)', [1, 'Marc']);

<a name="running-an-update-statement"></a>
#### 更新文の実行

データベース内の既存のレコードを更新するには、`update`メソッドを使用する必要があります。メソッドは実行の影響を受けた行数を返します。

    use Illuminate\Support\Facades\DB;

    $affected = DB::update(
        'update users set votes = 100 where name = ?',
        ['Anita']
    );

<a name="running-a-delete-statement"></a>
#### DELETE文の実行

データベースからレコードを削除するには、`delete`メソッドを使用する必要があります。`update`と同様に、メソッドは影響を受けた行数を返します。

    use Illuminate\Support\Facades\DB;

    $deleted = DB::delete('delete from users');

<a name="running-a-general-statement"></a>
#### 一般的な文の実行

一部のデータベース操作文は値を返しません。こうしたタイプの操作では、`DB`ファサードで`statement`メソッドを使用します。

    DB::statement('drop table users');

<a name="running-an-unprepared-statement"></a>
#### プリペアドではない文の実行

値をバインドせずSQL文を実行したい場合があります。それには、`DB`ファサードの`unprepared`メソッドを使用します。

    DB::unprepared('update users set votes = 100 where name = "Dries"');

> {note} プリペアドではない文はパラメーターをバインドしないため、SQLインジェクションに対して脆弱である可能性があります。プリペアドではない文内では、ユーザーの値のコントロールを許可しないでください。

<a name="implicit-commits-in-transactions"></a>
#### 暗黙のコミット

トランザクション内で`DB`ファサードの`statement`および`unprepared`メソッドを使用する場合、[暗黙のコミット](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)を引き起こすステートメントを回避するように注意する必要があります。これらのステートメントにより、データベースエンジンはトランザクション全体を間接的にコミットし、Laravelはデータベースのトランザクションレベルを認識しなくなります。このようなステートメントの例は、データベーステーブルの作成です。

    DB::unprepared('create table a (col varchar(1) null)');

暗黙的なコミットを引き起こす、[すべてのステートメントのリスト](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)は、MySQLのマニュアルを参照してください。

<a name="using-multiple-database-connections"></a>
### 複数データベース接続の使用

アプリケーションが`config/database.php`設定ファイルで複数の接続を定義している場合、`DB`ファサードが提供する`connection`メソッドを介して各接続にアクセスできます。`connection`メソッドに渡される接続名は、`config/database.php`設定ファイルにリストしている接続、または実行時に`config`ヘルパを使用して設定した接続の１つに対応している必要があります。

    use Illuminate\Support\Facades\DB;

    $users = DB::connection('sqlite')->select(...);

接続インスタンスで`getPdo`メソッドを使用して、接続の基になる素のPDOインスタンスにアクセスできます。

    $pdo = DB::connection()->getPdo();

<a name="listening-for-query-events"></a>
### クエリイベントのリッスン

アプリケーションが実行すｒSQLクエリごとに呼び出すクロージャを指定する場合は、`DB`ファサードの`listen`メソッドを使用します。このメソッドは、クエリのログ記録やデバッグに役立ちます。クエリリスナクロージャは、[サービスプロバイダ](/docs/{{version}}/providers)の`boot`メソッドで登録します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションの全サービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * アプリケーションの全サービスの起動初期処理
         *
         * @return void
         */
        public function boot()
        {
            DB::listen(function ($query) {
                // $query->sql
                // $query->bindings
                // $query->time
            });
        }
    }

<a name="database-transactions"></a>
## データベーストランザクション

`DB`ファサードが提供する`transaction`メソッドを使用して、データベーストランザクション内で一連の操作を実行できます。トランザクションクロージャ内で例外が投げられた場合、トランザクションを自動的にロールバックします。クロージャが正常に実行されると、トランザクションを自動的にコミットします。`transaction`メソッドの使用中にロールバックやコミットを手動で実行する心配はありません。

    use Illuminate\Support\Facades\DB;

    DB::transaction(function () {
        DB::update('update users set votes = 1');

        DB::delete('delete from posts');
    });

<a name="handling-deadlocks"></a>
#### デッドロックの処理

`transaction`メソッドは、デッドロックが発生したときにトランザクションを再試行する回数をオプションとして、２番目の引数に取ります。試行回数が終了したばあいは、例外を投げます。

    use Illuminate\Support\Facades\DB;

    DB::transaction(function () {
        DB::update('update users set votes = 1');

        DB::delete('delete from posts');
    }, 5);

<a name="manually-using-transactions"></a>
#### トランザクションを手動で使用

トランザクションを手動で開始し、ロールバックとコミットを自分で完全にコントロールしたい場合は、`DB`ファサードが提供する`beginTransaction`メソッドを使用します。

    use Illuminate\Support\Facades\DB;

    DB::beginTransaction();

`rollBack`メソッドにより、トランザクションをロールバックできます。

    DB::rollBack();

`commit`メソッドにより、トランザクションをコミットできます。

    DB::commit();

> {tip} `DB`ファサードのトランザクションメソッドは、[クエリビルダ](/docs/{{version}}/queries)と[Eloquent ORM](/docs/{{version}}/eloquent)の両方のトランザクションを制御します。

<a name="connecting-to-the-database-cli"></a>
## データベースCLIへの接続

データベースのCLIに接続する場合は、`db` Artisanコマンドを使用します。

    php artisan db

必要に応じて、データベース接続名を指定して、デフォルト接続以外のデータベースへ接続できます。

    php artisan db mysql
