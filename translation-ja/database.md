# データベース：利用開始

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [Read／Write接続](#read-and-write-connections)
    - [複数接続の使用](#using-multiple-database-connections)
- [SQLクエリの実行](#running-queries)
- [クエリイベントのリッスン](#listening-for-query-events)
- [データベーストランザクション](#database-transactions)
- [データベースCLIへの接続](#connecting-to-the-database-cli)

<a name="introduction"></a>
## イントロダクション

LaravelはSQLを直接使用する場合でも、[Fluentクエリビルダ](/docs/{{version}}/queries)や[Eloquent ORM](/docs/{{version}}/eloquent)を使う時でも、データベースの取り扱いをとても簡単にしてくれます。現在、Laravelは以下のデータベースシステムを使用しています。

<div class="content-list" markdown="1">
- MySQL 5.6以上 ([バージョンポリシー](https://en.wikipedia.org/wiki/MySQL#Release_history))
- PostgreSQL 9.4以上  ([バージョンポリシー](https://www.postgresql.org/support/versioning/))
- SQLite 3.8.8以上
- SQL Server 2017以上  ([バージョンポリシー](https://support.microsoft.com/en-us/lifecycle/search))
</div>

<a name="configuration"></a>
### 設定

データベース設定ファイルは`config/database.php`です。このファイルで使用するデータベース接続を全部定義すると同時に、デフォルトで使用する接続も指定してください。サポートしているほとんどのデータベースシステムの例がファイルの中に用意しています。

デフォルトでLaravelのサンプル[環境設定](/docs/{{version}}/configuration#environment-configuration)は、ローカルマシン上でLaravelでの開発を行うための便利な仮想マシンである[Laravel Homestead](/docs/{{version}}/homestead)用に設定してあります。ローカルのデータベースに合わせ、自由に変更してくだい。

<a name="sqlite-configuration"></a>
#### SQLite設定

`touch database/database.sqlite`などのコマンドを使い、新しいSQLiteデータベースを作成した後、この新しいデータベースの絶対パスを環境変数へ設定します。

    DB_CONNECTION=sqlite
    DB_DATABASE=/absolute/path/to/database.sqlite

SQLiteで外部キー制約を有効にするには、`DB_FOREIGN_KEYS`環境変数に`true`をセットする必要があります。

    DB_FOREIGN_KEYS=true

<a name="mssql-configuration"></a>
#### Microsoft SQLサーバ設定

Microsoft SQLサーバデータベースを使用するには、`sqlsrv`および`pdo_sqlsrv` PHP拡張機能と、Microsoft SQL ODBCドライバなどの必要な依存関係をすべて確実にインストールしてください。

<a name="configuration-using-urls"></a>
#### URLを使用したデータベース設定

通常、データベース接続は`host`、`database`、`username`、`password`などのような複数の設定値を用いて設定します。これらの各設定値は、対応する環境変数を持っています。つまり、実働サーバ上でデータベース接続情報を設定する場合に、多くの環境変数を管理する必要があります。

Herokuのようなマネージドデータベースのプロバイダでは、一つの文字列の中にデータベースの接続状を全部含めたデータベース"URL"を提供しています。たとえば、サンプルのデータベースURLは次のようになります。

    mysql://root:password@127.0.0.1/forge?charset=UTF-8

こうしたURLは通常、次のような標準的なスキーマ規約に従います。

    driver://username:password@host:port/database?options

これに対応するため、Laravelは複数の接続オプションを使い、データベースの設定を変更可能なURLをサポートしています。（`DATABASE_URL`環境変数に対応している）`url`設定オプションが存在する場合は、データベース接続と接続情報を取り出し、接続に使用します。

<a name="read-and-write-connections"></a>
### Read／Write接続

SELECT文に別のデータベース接続を利用したい場合もあると思います。INSERT、UPDATE、DELETE文では他の接続に切り替えたい場合などです。Laravelでこれを簡単に実現できます。SQLをそのまま使う場合であろうと、クエリビルダやEloquent ORMを利用する場合であろうと、適切な接続が利用されます。

Read/Write接続を理解してもらうため、以下の例をご覧ください。

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

設定配列に`read`と`write`、`sticky`、３つのキーが追加されたことに注目してください。２つのキーとも`host`というキーを一つ持っています。`read`と`write`接続時の残りのデータベースオプションは、メインの`mysql`配列からマージされます。

`read`と`write`の配列には、メインの配列の値をオーバーライドしたいものだけ指定してください。この場合、`192.168.1.1`は"read"接続に利用され、一方`192.168.1.3`が"write"接続に利用されます。メインの`mysql`配列に含まれる、データベース接続情報、プレフィックス、文字セットなどその他のオプションは、両方の接続で共有されます。

<a name="the-sticky-option"></a>
#### `sticky`オプション

`sticky`オプションは**オプショナル**値で、現在のリクエストサイクルでデータベースへ書き込まれたレコードを即時に読み込みます。`sticky`オプションが有効なとき、現在のリクエストサイクルにデータベースに対して「書き込み(write)」処理が実行されると、すべての「読み込み(read)」操作で"write"接続が使われるようになります。これにより、あるリクエストサイクルで書き込んだデータが、同じリクエストでは確実にデータベースから即時読み込まれます。

<a name="using-multiple-database-connections"></a>
### 複数接続の使用

複数の接続を使用する場合は、`DB`ファサードの`connection`メソッドを利用し、各接続にアクセスできます。`connection`メソッドに渡す「名前」は、`config/database.php`設定ファイルの中の`connections`にリストされている名前を指定します。

    $users = DB::connection('foo')->select(...);

裏で動作しているPDOインスタンスに直接アクセスしたい場合は、接続インスタンスに`getPdo`メソッドを使います。

    $pdo = DB::connection()->getPdo();

<a name="running-queries"></a>
## SQLクエリの実行

データベース接続の設定を済ませれば、`DB`ファサードを使用しクエリを実行できます。`DB`ファサードは `select`、`update`、`insert`、`delete`、`statement`のクエリタイプごとにメソッドを用意しています。

<a name="running-a-select-query"></a>
#### SELECTクエリの実行

基本的なクエリを行うには、`DB`ファサードの`select`メソッドを使います。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\DB;

    class UserController extends Controller
    {
        /**
         * アプリケーションの全ユーザーリストを表示
         *
         * @return Response
         */
        public function index()
        {
            $users = DB::select('select * from users where active = ?', [1]);

            return view('user.index', ['users' => $users]);
        }
    }

`select`メソッドの最初の引数はSQLクエリで、２つ目の引数はクエリに結合する必要のあるパラメーターです。通常、パラメーターは`where`節制約の値です。パラメーター結合はSQLインジェクションを防ぐために提供されています。

`select`メソッドはいつも結果の「配列」を返します。結果の値へアクセスできるように、配列に含まれる結果はそれぞれ、PHPの`stdClass`オブジェクトになります。

    foreach ($users as $user) {
        echo $user->name;
    }

<a name="using-named-bindings"></a>
#### 名前付き結合の使用

パラメーター結合に`?`を使う代わりに名前付きの結合でクエリを実行できます。

    $results = DB::select('select * from users where id = :id', ['id' => 1]);

<a name="running-an-insert-statement"></a>
#### INSERT文の実行

`insert`文を実行するには、`DB`ファサードの`insert`メソッドを使います。`select`と同様に、このメソッドは第１引数にSQLクエリそのもの、第２引数に結合を取ります。

    DB::insert('insert into users (id, name) values (?, ?)', [1, 'Dayle']);

<a name="running-an-update-statement"></a>
#### UPDATE文の実行

データベースの既存レコードの更新には、`update`メソッドを使います。このメソッドの返却値は影響を受けたレコード数です。

    $affected = DB::update('update users set votes = 100 where name = ?', ['John']);

<a name="running-a-delete-statement"></a>
#### DELETE文の実行

データベースからレコードを削除するには、`delete`メソッドを使います。`update`と同様に、削除したレコード数が返されます。

    $deleted = DB::delete('delete from users');

<a name="running-a-general-statement"></a>
#### 通常のSQL文を実行する

いつくかのデータベース文は値を返しません。こうしたタイプの操作には、`DB`ファサードの`statement`メソッドを使います。

    DB::statement('drop table users');

<a name="running-an-unprepared-statement"></a>
#### プリペアドステートメントを使用しない実行

値をバインドせずにSQLステートメントを実行したい場合があります。それには`DB`ファサードの`unprepared`メソッドを使用します。

    DB::unprepared('update users set votes = 100 where name = "Dries"');

> {note} unpreparedステートメントはパラメーターをバインドしないため、SQLインジェクションに対して脆弱である可能性を持っています。unpreparedステートメント内でユーザーが制御する値の使用を許してはいけません。

<a name="implicit-commits-in-transactions"></a>
#### 暗黙のコミット

トランザクション内で `DB`ファサードの`statement`および`unprepared`メソッドを使用する場合、[暗黙のコミット](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)を引き起こすステートメントを回避するように注意する必要があります。そうしたステートメントにより、データベースエンジンはトランザクション全体を間接的にコミットし、Laravelはデータベースのトランザクションレベルを認識しなくなります。このようなステートメントの例は、データベーステーブルの作成です。

    DB::unprepared('create table a (col varchar(1) null)');

暗黙的なコミットをトリガーする[すべてのステートメントのリスト](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)は、MySQLのマニュアルを参照してください。

<a name="listening-for-query-events"></a>
## クエリイベントのリッスン

アプリケーションで実行される各SQLクエリを取得したい場合は、`listen`メソッドが使用できます。このメソッドはクエリをログしたり、デバッグしたりするときに便利です。クエリリスナは[サービスプロバイダ](/docs/{{version}}/providers)の中で登録します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * 全アプリケーションサービスの初期起動
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

一連の操作をデータベーストランザクション内で実行するには、`DB`ファサードの`transaction`メソッドを使用してください。トランザクション「クロージャ」の中で例外が投げられると、トランザクションは自動的にロールバックされます。「クロージャ」が正しく実行されると、自動的にコミットされます。`transaction`メソッドを使用すれば、ロールバックやコミットを自分でコードする必要はありません。

    DB::transaction(function () {
        DB::table('users')->update(['votes' => 1]);

        DB::table('posts')->delete();
    });

<a name="handling-deadlocks"></a>
#### デッドロックの処理

`transaction`メソッドは第２引数に、デッドロック発生時のトランザクション再試行回数を指定できます。試行回数を過ぎたら、例外が投げられます。

    DB::transaction(function () {
        DB::table('users')->update(['votes' => 1]);

        DB::table('posts')->delete();
    }, 5);

<a name="manually-using-transactions"></a>
#### 手動トランザクション

トランザクションを自分で開始し、ロールバックとコミットを完全にコントロールしたい場合は、`DB`ファサードの`beginTransaction`メソッドを使います。

    DB::beginTransaction();

`rollBack`メソッドにより、トランザクションをロールバックできます。

    DB::rollBack();

同様に、`commit`メソッドにより、トランザクションをコミットできます。

    DB::commit();

> {tip} `DB`ファサードのトランザクションメソッドは、[クエリビルダ](/docs/{{version}}/queries)と[Eloquent ORM](/docs/{{version}}/eloquent)のトランザクションを両方共にコントロールします。

<a name="connecting-to-the-database-cli"></a>
## データベースCLIへの接続

データベースCLIに接続する場合は、`db` Artisanコマンドを使用します。

    php artisan db

必要に応じ、データベース接続名を指定し、デフォルト以外のデータベースに接続できます。

    php artisan db mysql
