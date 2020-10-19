# データベース：クエリビルダ

- [イントロダクション](#introduction)
- [結果の取得](#retrieving-results)
    - [結果の分割](#chunking-results)
    - [集計](#aggregates)
- [SELECT](#selects)
- [SQL文](#raw-expressions)
- [JOIN](#joins)
- [UNION](#unions)
- [WHERE節](#where-clauses)
    - [パラメータのグループ分け](#parameter-grouping)
    - [Where Exists節](#where-exists-clauses)
    - [Subquery Where Clauses](#subquery-where-clauses)
    - [JSON Where節](#json-where-clauses)
- [順序、グループ分け、制限、オフセット](#ordering-grouping-limit-and-offset)
- [条件節](#conditional-clauses)
- [INSERT](#inserts)
- [UPDATE](#updates)
    - [JSONカラムの更新](#updating-json-columns)
    - [増減分](#increment-and-decrement)
- [DELETE](#deletes)
- [排他的ロック](#pessimistic-locking)
- [デバッグ](#debugging)

<a name="introduction"></a>
## イントロダクション

データベースクエリビルダはスラスラと書ける(fluent)便利なインターフェイスで、クエリを作成し実行するために使用します。アプリケーションで行われるほとんどのデーターベース操作が可能で、サポートしている全データベースシステムに対し使用できます。

LaravelクエリビルダはアプリケーションをSQLインジェクション攻撃から守るために、PDOパラメーターによるバインディングを使用します。バインドする文字列をクリーンにしてから渡す必要はありません。

> {note} PDOはカラム名によるバインドをサポートしていません。そのため、"order by"カラムなどを含め、クエリに直接カラム名を参照するユーザー入力を許してはいけません。クエリに対する特定のカラムの選択をユーザーに許す場合は、許可するカラムのホワイトリストを用意し、常にカラム名を確認してください。

<a name="retrieving-results"></a>
## 結果の取得

#### 全レコードの取得

クエリを書くには`DB`ファサードの`table`メソッドを使います。`table`メソッドは指定したテーブルに対するクエリビルダインスタンスを返します。これを使いクエリに制約を加え、最終的な結果を取得するチェーンを繋げます。次に、最終的な結果を`get`で取得します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\DB;

    class UserController extends Controller
    {
        /**
         * アプリケーションの全ユーザーレコード一覧を表示
         *
         * @return Response
         */
        public function index()
        {
            $users = DB::table('users')->get();

            return view('user.index', ['users' => $users]);
        }
    }

`get`メソッドは、PHPの`stdClass`オブジェクトのインスタンスを結果として含む、`Illuminate\Support\Collection`を返します。各カラムの値は、オブジェクトのプロパティとしてアクセスできます。

    foreach ($users as $user) {
        echo $user->name;
    }

#### テーブルから１カラム／１レコード取得

データベーステーブルから１レコードのみ取得する必要がある場合は、`first`メソッドを使います。このメソッドは`stdClass`オブジェクトを返します。

    $user = DB::table('users')->where('name', 'John')->first();

    echo $user->name;

全カラムは必要ない場合、`value`メソッドにより一つの値のみ取得できます。このメソッドはカラムの値を直接返します。

    $email = DB::table('users')->where('name', 'John')->value('email');

`id`カラム値により１行取得する場合は、`find`メソッドを使用してください。

    $user = DB::table('users')->find(3);

#### カラム値をリストで取得

単一カラムの値をコレクションで取得したい場合は`pluck`メソッドを使います。以下の例では役割名(title)をコレクションで取得しています。

    $titles = DB::table('roles')->pluck('title');

    foreach ($titles as $title) {
        echo $title;
    }

取得コレクションのキーカラムを指定することもできます。

    $roles = DB::table('roles')->pluck('title', 'name');

    foreach ($roles as $name => $title) {
        echo $title;
    }

<a name="chunking-results"></a>
### 結果の分割

数千のデータベースレコードを扱う場合は`chunk`メソッドの使用を考慮してください。このメソッドは一度に小さな「かたまり(chunk)」で結果を取得し、このチャンクは処理のために「クロージャ」へ渡されます。このメソッドは数千のレコードを処理する[Artisanコマンド](/docs/{{version}}/artisan)を書くときに便利です。`users`レコード全体から一度に１００レコードずつチャンクを処理する例を見てください。

    DB::table('users')->orderBy('id')->chunk(100, function ($users) {
        foreach ($users as $user) {
            //
        }
    });

クロージャから`false`を返すとチャンクの処理を中断できます。

    DB::table('users')->orderBy('id')->chunk(100, function ($users) {
        // レコードの処理…

        return false;
    });

結果をチャンクしつつデータベースレコードを更新すると、チャンク結果が意図しない変化を起こす可能性があります。そのため、チャンク結果を更新する場合は、常に代わりの`chunkById`メソッドを使用するのが最善です。このメソッドは自動的にレコードの主キーに基づいて結果を自動的にページ割りします。

    DB::table('users')->where('active', false)
        ->chunkById(100, function ($users) {
            foreach ($users as $user) {
                DB::table('users')
                    ->where('id', $user->id)
                    ->update(['active' => true]);
            }
        });

> {note} chunkのコールバックの中で、レコードを更新／削除することにより主キーや外部キーが変化すると、chunkクエリに影響を及ぼします。分割結果にレコードが含まれない可能性が起きます。

<a name="aggregates"></a>
### 集計

またクエリビルダは`count`、`max`、`min`、`avg`、`sum`など多くの集計メソッドを提供しています。クエリを制約した後にこれらのメソッドを使うことも可能です。

    $users = DB::table('users')->count();

    $price = DB::table('orders')->max('price');

これらのメソッドをクエリを構築するために他の節と組み合わせて使用できます。

    $price = DB::table('orders')
                    ->where('finalized', 1)
                    ->avg('price');

#### レコード存在の判定

クエリの制約にマッチするレコードが存在するかを調べるため、`count`メソッドを使用する代わりに、`exists`や`doesntExist`メソッドを使うこともできます。

    return DB::table('orders')->where('finalized', 1)->exists();

    return DB::table('orders')->where('finalized', 1)->doesntExist();

<a name="selects"></a>
## SELECT

#### SELECT節の指定

常にデータベースレコードの全カラムが必要ではないでしょう。クエリの`select`節を`select`メソッドで指定できます。

    $users = DB::table('users')->select('name', 'email as user_email')->get();

`distinct`メソッドで重複行をまとめた結果を返すように強制できます。

    $users = DB::table('users')->distinct()->get();

すでにクエリビルダインスタンスがあり、select節にカラムを追加したい場合は`addSelect`メソッドを使ってください。

    $query = DB::table('users')->select('name');

    $users = $query->addSelect('age')->get();

<a name="raw-expressions"></a>
## SQL文

ときどき、クエリの中でSQLを直接使用したいことがあります。エスケープなしのSQLを使用する場合は`DB::raw`メソッドを使用します。

    $users = DB::table('users')
                         ->select(DB::raw('count(*) as user_count, status'))
                         ->where('status', '<>', 1)
                         ->groupBy('status')
                         ->get();

> {note} rawメソッドはクエリを文字列として挿入するため、SQLインジェクションの脆弱性を生まないように十分気をつけてください。

<a name="raw-methods"></a>
### rawメソッド

`DB::raw`を使用する代わりに、クエリのさまざまな箇所へSQL文を挿入する、以降のメソッドも使用できます。

#### `selectRaw`

`selectRaw`メソッドは、`addSelect(DB::raw(...))`に置き換えて使用できます。このメソッドは、第２引数へバインド値の配列を指定することも可能です。

    $orders = DB::table('orders')
                    ->selectRaw('price * ? as price_with_tax', [1.0825])
                    ->get();

#### `whereRaw / orWhereRaw`

`whereRaw`と`orWhereRaw`メソッドは、クエリへ`where`節を挿入できます。これらのメソッドは、第２引数にバインド値の配列を指定することもできます。

    $orders = DB::table('orders')
                    ->whereRaw('price > IF(state = "TX", ?, 100)', [200])
                    ->get();

#### `havingRaw / orHavingRaw`

`havingRaw`と`orHavingRaw`メソッドは、文字列を`having`節の値として指定するために使用します。両メソッドは、第２引数にオプションとして、バインドの配列を渡すことができます。

    $orders = DB::table('orders')
                    ->select('department', DB::raw('SUM(price) as total_sales'))
                    ->groupBy('department')
                    ->havingRaw('SUM(price) > ?', [2500])
                    ->get();

#### `orderByRaw`

`orderByRaw`メソッドは、文字列を`order by`節の値として指定するために使用します。

    $orders = DB::table('orders')
                    ->orderByRaw('updated_at - created_at DESC')
                    ->get();

### `groupByRaw`

`groupByRaw`メソッドは、文字列を`group by`節の値として指定するために使用します。

    $orders = DB::table('orders')
                    ->select('city', 'state')
                    ->groupByRaw('city, state')
                    ->get();

<a name="joins"></a>
## JOIN

#### INNER JOIN文

さらにクエリビルダはJOIN文を書くためにも使用できます。基本的な"INNER JOIN"を実行するには、クエリビルダインスタンスに`join`メソッドを使ってください。`join`メソッドの第１引数は結合したいテーブル名、それ以降の引数にはJOIN時のカラムの制約条件を指定します。一つのクエリで複数のテーブルを結合することもできます。

    $users = DB::table('users')
                ->join('contacts', 'users.id', '=', 'contacts.user_id')
                ->join('orders', 'users.id', '=', 'orders.user_id')
                ->select('users.*', 'contacts.phone', 'orders.price')
                ->get();

#### LEFT JOIN／RIGHT JOIN文

"INNER JOIN"の代わりに"LEFT JOIN"か"RIGHT JOIN"を実行したい場合は、`leftJoin`や`rightJoin`メソッドを使います。これらのメソッドの使い方は`join`メソッドと同じです。

    $users = DB::table('users')
                ->leftJoin('posts', 'users.id', '=', 'posts.user_id')
                ->get();

    $users = DB::table('users')
                ->rightJoin('posts', 'users.id', '=', 'posts.user_id')
                ->get();

#### クロスジョイン文

「クロスジョイン」を実行するときは、接合したいテーブル名を指定し、`crossJoin`メソッドを使ってください。クロスジョインにより、最初のテーブルと指定したテーブルとの、デカルト積を生成します。

    $sizes = DB::table('sizes')
                ->crossJoin('colors')
                ->get();

#### 上級のJOIN文

さらに上級なJOIN節を指定することもできます。そのためには`join`メソッドの第２引数に「クロージャ」を指定します。その「クロージャ」は`JOIN`節に制約を指定できるようにする`JoinClause`オブジェクトを受け取ります。

    DB::table('users')
            ->join('contacts', function ($join) {
                $join->on('users.id', '=', 'contacts.user_id')->orOn(...);
            })
            ->get();

JOINに"where"節を使用したい場合はjoinの中で`where`や`orWhere`を使用してください。２つのカラムを比べる代わりに、これらのメソッドは値とカラムを比較します。

    DB::table('users')
            ->join('contacts', function ($join) {
                $join->on('users.id', '=', 'contacts.user_id')
                     ->where('contacts.user_id', '>', 5);
            })
            ->get();

#### サブクエリのJOIN

サブクエリへクエリをJOINするために、`joinSub`、`leftJoinSub`、`rightJoinSub`メソッドを利用できます。各メソッドは３つの引数を取ります。サブクエリ、テーブルのエイリアス、関連するカラムを定義するクロージャです。

    $latestPosts = DB::table('posts')
                       ->select('user_id', DB::raw('MAX(created_at) as last_post_created_at'))
                       ->where('is_published', true)
                       ->groupBy('user_id');

    $users = DB::table('users')
            ->joinSub($latestPosts, 'latest_posts', function ($join) {
                $join->on('users.id', '=', 'latest_posts.user_id');
            })->get();

<a name="unions"></a>
## UNION

クエリビルダは２つのクエリを結合(union)させる手軽な手法を提供します。たとえば最初にクエリを作成し、その後に２つ目のクエリを結合するために`union`メソッドを使います。

    $first = DB::table('users')
                ->whereNull('first_name');

    $users = DB::table('users')
                ->whereNull('last_name')
                ->union($first)
                ->get();

> {tip} `union`と同じ使い方の`unionAll`メソッドも使えます。

<a name="where-clauses"></a>
## WHERE節

#### 単純なWHERE節

`where`節をクエリに追加するには、クエリビルダインスタンスの`where`メソッドを使います。基本的な`where`の呼び出しでは３つの引数を使います。第１引数はカラム名です。第２引数はデータベースがサポートしているオペレーターです。第３引数はカラムに対して比較する値です。

例として、"votes"カラムの値が100と等しいレコードのクエリを見てください。

    $users = DB::table('users')->where('votes', '=', 100)->get();

カラムが指定値と等しいかを比べたい場合は利便性を良くするため、`where`メソッドの第２引数に値をそのまま指定できます。

    $users = DB::table('users')->where('votes', 100)->get();

`where`文を書くときには、その他いろいろなオペレータも使えます。

    $users = DB::table('users')
                    ->where('votes', '>=', 100)
                    ->get();

    $users = DB::table('users')
                    ->where('votes', '<>', 100)
                    ->get();

    $users = DB::table('users')
                    ->where('name', 'like', 'T%')
                    ->get();

`where`に配列で条件を渡すこともできます。

    $users = DB::table('users')->where([
        ['status', '=', '1'],
        ['subscribed', '<>', '1'],
    ])->get();

#### OR節

WHEREの結合にチェーンで`or`節をクエリに追加できます。`orWhere`メソッドは`where`メソッドと同じ引数を受け付けます。

    $users = DB::table('users')
                        ->where('votes', '>', 100)
                        ->orWhere('name', 'John')
                        ->get();

括弧の中で"or"条件をまとめる必要がある場合は、`orWhere`メソッドの最初の引数にクロージャを渡してください。

    $users = DB::table('users')
                ->where('votes', '>', 100)
                ->orWhere(function($query) {
                    $query->where('name', 'Abigail')
                          ->where('votes', '>', 50);
                })
                ->get();

    // SQL: select * from users where votes > 100 or (name = 'Abigail' and votes > 50)

#### その他のWHERE節

**whereBetween / orWhereBetween**

`whereBetween`メソッドはカラムの値が２つの値の間である条件を加えます。

    $users = DB::table('users')
               ->whereBetween('votes', [1, 100])
               ->get();

**whereNotBetween / orWhereNotBetween**

`whereNotBetween`メソッドは、カラムの値が２つの値の間ではない条件を加えます。

    $users = DB::table('users')
                        ->whereNotBetween('votes', [1, 100])
                        ->get();

**whereIn / whereNotIn / orWhereIn / orWhereNotIn**

`whereIn`メソッドは指定した配列の中にカラムの値が含まれている条件を加えます。

    $users = DB::table('users')
                        ->whereIn('id', [1, 2, 3])
                        ->get();

`whereNotIn`メソッドはカラムの値が指定した配列の中に含まれて**いない**条件を加えます。

    $users = DB::table('users')
                        ->whereNotIn('id', [1, 2, 3])
                        ->get();

> {note} 整数の巨大な配列をクエリと結合する場合は、メモリ使用量を大きく減らすために`whereIntegerInRaw`か`whereIntegerNotInRaw`メソッドを使用してください。

**whereNull / whereNotNull / orWhereNull / orWhereNotNull**

`whereNull`メソッドは指定したカラムの値が`NULL`である条件を加えます。

    $users = DB::table('users')
                        ->whereNull('updated_at')
                        ->get();

`whereNotNull`メソッドは指定したカラムの値が`NULL`でない条件を加えます。

    $users = DB::table('users')
                        ->whereNotNull('updated_at')
                        ->get();

**whereDate / whereMonth / whereDay / whereYear / whereTime**

`whereDate`メソッドはカラム値を日付と比較する時に使用します。

    $users = DB::table('users')
                    ->whereDate('created_at', '2016-12-31')
                    ->get();

`whereMonth`メソッドはカラム値と、ある年の指定した月とを比較します。

    $users = DB::table('users')
                    ->whereMonth('created_at', '12')
                    ->get();

`whereDay`メソッドはカラム値と、ある月の指定した日とを比べます。

    $users = DB::table('users')
                    ->whereDay('created_at', '31')
                    ->get();

`whereYear`メソッドはカラム値と、指定した年とを比べます。

    $users = DB::table('users')
                    ->whereYear('created_at', '2016')
                    ->get();

`whereTime`メソッドはカラム値と、指定した時間を比較します。

    $users = DB::table('users')
                    ->whereTime('created_at', '=', '11:20:45')
                    ->get();

**whereColumn / orWhereColumn**

`whereColumn`メソッドは２つのカラムが同値である確認をするのに使います。

    $users = DB::table('users')
                    ->whereColumn('first_name', 'last_name')
                    ->get();

メソッドに比較演算子を追加指定することもできます。

    $users = DB::table('users')
                    ->whereColumn('updated_at', '>', 'created_at')
                    ->get();

`whereColumn`へ配列により複数の条件を渡すこともできます。各条件は`and`オペレータでつなげられます。

    $users = DB::table('users')
                    ->whereColumn([
                        ['first_name', '=', 'last_name'],
                        ['updated_at', '>', 'created_at'],
                    ])->get();

<a name="parameter-grouping"></a>
### パラメータのグループ分け

時には、"WHERE EXISTS"節やグループにまとめたパラーメーターのネストのような、上級のWHERE節を作成する必要が起きます。Laravelクエリビルダはこれらもうまく処理できます。手始めに、カッコで制約をまとめる例を見てください。

    $users = DB::table('users')
               ->where('name', '=', 'John')
               ->where(function ($query) {
                   $query->where('votes', '>', 100)
                         ->orWhere('title', '=', 'Admin');
               })
               ->get();

ご覧の通り、`Where`メソッドに渡している「クロージャ」が、クエリビルダのグルーピングを指示しています。生成するSQLの括弧内で展開される制約を指定できるように、「クロージャ」はクエリビルダのインスタンスを受け取ります。

    select * from users where name = 'John' and (votes > 100 or title = 'Admin')

> {tip} グローバルスコープが適用されるときに、予想外の動作を防ぐために、`orWhere`コールは常にまとめてください。

<a name="where-exists-clauses"></a>
### Where Exists節

`whereExists`メソッドは`WHERE EXISTS`のSQLを書けるように用意しています。`whereExists`メソッドは引数に「クロージャ」を取り、"EXISTS"節の中に置かれるクエリを定義するためのクエリビルダを受け取ります。

    $users = DB::table('users')
               ->whereExists(function ($query) {
                   $query->select(DB::raw(1))
                         ->from('orders')
                         ->whereRaw('orders.user_id = users.id');
               })
               ->get();

上のクエリは以下のSQLを生成します。

    select * from users
    where exists (
        select 1 from orders where orders.user_id = users.id
    )

<a name="subquery-where-clauses"></a>
### サブクエリWHERE節

ときにより、サブクエリの結果と指定値を比較するWHERE節の制約が必要になります。それにはクロージャと値を`where`メソッドに渡してください。例として、以下のクエリでは指定した最新の「メンバーシップ」を持つ全ユーザーを取得しています。

    use App\Models\User;

    $users = User::where(function ($query) {
        $query->select('type')
            ->from('membership')
            ->whereColumn('user_id', 'users.id')
            ->orderByDesc('start_date')
            ->limit(1);
    }, 'Pro')->get();

<a name="json-where-clauses"></a>
### JSON WHERE節

Laravelはデータベース上のJSONタイプをサポートするカラムに対するクエリに対応しています。現在、MySQL5.7とPostgreSQL、SQL Server2016、SQLite3.9.0（[JSON1拡張](https://www.sqlite.org/json1.html)使用時）に対応しています。JSONカラムをクエリするには`->`オペレータを使ってください。

    $users = DB::table('users')
                    ->where('options->language', 'en')
                    ->get();

    $users = DB::table('users')
                    ->where('preferences->dining->meal', 'salad')
                    ->get();

JSON配列をクエリするには、`whereJsonContains`を使います。（SQLiteではサポートされていません）

    $users = DB::table('users')
                    ->whereJsonContains('options->languages', 'en')
                    ->get();

MySQLとPostgreSQLでは、`whereJsonContains`で複数の値をサポートしています。

    $users = DB::table('users')
                    ->whereJsonContains('options->languages', ['en', 'de'])
                    ->get();

JSON配列を長さでクエリするには、`whereJsonLength`を使います。

    $users = DB::table('users')
                    ->whereJsonLength('options->languages', 0)
                    ->get();

    $users = DB::table('users')
                    ->whereJsonLength('options->languages', '>', 1)
                    ->get();

<a name="ordering-grouping-limit-and-offset"></a>
## 順序、グループ分け、制限、オフセット

#### orderBy

`orderBy`メソッドは指定したカラムでクエリ結果をソートします。`orderBy`メソッドの最初の引数はソート対象のカラムで、第２引数はソートの昇順(`asc`)と降順(`desc`)をコントロールします。

    $users = DB::table('users')
                    ->orderBy('name', 'desc')
                    ->get();

複数カラムのソートが必要なら、`orderBy`を必要な回数記述してください。

    $users = DB::table('users')
                    ->orderBy('name', 'desc')
                    ->orderBy('email', 'asc')
                    ->get();

#### latest／oldest

`latest`と`oldest`メソッドにより、データの結果を簡単に整列できます。デフォルトで、結果は`created_at`カラムによりソートされます。ソートキーとしてカラム名を渡すこともできます。

    $user = DB::table('users')
                    ->latest()
                    ->first();

#### inRandomOrder

`inRandomOrder`メソッドはクエリ結果をランダム順にする場合で使用します。たとえば、以下のコードはランダムにユーザーを一人取得します。

    $randomUser = DB::table('users')
                    ->inRandomOrder()
                    ->first();

#### reorder

`reorder`メソッドは、既存のソート順をすべて削除します。オプションとして、新しいソート順を指定できます。例として、既存のソート順をすべて削除してみましょう。

    $query = DB::table('users')->orderBy('name');

    $unorderedUsers = $query->reorder()->get();

既存のソート付をすべて削除し新しく適用するには、カラムとソート方向を引数として指定します。

    $query = DB::table('users')->orderBy('name');

    $usersOrderedByEmail = $query->reorder('email', 'desc')->get();

#### groupBy / having

`groupBy`と`having`メソッドはクエリ結果をグループへまとめるために使用します。`having`メソッドは`where`メソッドと似た使い方です。

    $users = DB::table('users')
                    ->groupBy('account_id')
                    ->having('account_id', '>', 100)
                    ->get();

複数カラムによるグループ化のため、`groupBy`メソッドに複数の引数を指定できます。

    $users = DB::table('users')
                    ->groupBy('first_name', 'status')
                    ->having('account_id', '>', 100)
                    ->get();

より上級な`having`文については、[`havingRaw`](#raw-methods)メソッドを参照してください。

#### skip / take

クエリから限られた(`LIMIT`)数のレコードを受け取ったり、結果から指定した件数を飛ばしたりするには、`skip`と`take`メソッドを使います。

    $users = DB::table('users')->skip(10)->take(5)->get();

別の方法として、`limit`と`offset`メソッドも使用できます。

    $users = DB::table('users')
                    ->offset(10)
                    ->limit(5)
                    ->get();

<a name="conditional-clauses"></a>
## 条件節

ある条件がtrueの場合の時のみ、クエリへ特定の文を適用したい場合があります。たとえば特定の入力値がリクエストに含まれている場合に、`where`文を適用する場合です。`when`メソッドで実現できます。

    $role = $request->input('role');

    $users = DB::table('users')
                    ->when($role, function ($query, $role) {
                        return $query->where('role_id', $role);
                    })
                    ->get();

`when`メソッドは、第１引数が`true`の時のみ、指定されたクロージャを実行します。最初の引数が`false`の場合、クロージャを実行しません。

`when`メソッドの第3引数に別のクロージャを渡せます。このクロージャは、最初の引数の評価が`false`であると実行されます。この機能をどう使うかを確認するため、クエリのデフォルトソートを設定してみましょう。

    $sortBy = null;

    $users = DB::table('users')
                    ->when($sortBy, function ($query, $sortBy) {
                        return $query->orderBy($sortBy);
                    }, function ($query) {
                        return $query->orderBy('name');
                    })
                    ->get();

<a name="inserts"></a>
## INSERT

クエリビルダは、データベーステーブルにレコードを挿入するための`insert`メソッドを提供しています。`insert`メソッドは挿入するカラム名と値の配列を引数に取ります。

    DB::table('users')->insert(
        ['email' => 'john@example.com', 'votes' => 0]
    );

配列の配列を`insert`に渡して呼び出すことで、テーブルにたくさんのレコードを一度にまとめて挿入できます。

    DB::table('users')->insert([
        ['email' => 'taylor@example.com', 'votes' => 0],
        ['email' => 'dayle@example.com', 'votes' => 0],
    ]);

`insertOrIgnore`メソッドは、データベースにレコードを挿入する際、重複レコードエラーを無視します。

    DB::table('users')->insertOrIgnore([
        ['id' => 1, 'email' => 'taylor@example.com'],
        ['id' => 2, 'email' => 'dayle@example.com'],
    ]);

`upsert`メソッドは存在しない場合に行を挿入し、すでに存在する場合はその行を新しい値で更新します。メソッドの最初の引数は挿入か更新する値で構成し、２つ目の引数は関連するテーブルのレコードを一意に識別するカラムのリストです。第３で最後の引数はデータベースに一致するレコードがすでに存在している場合に、更新するカラムの配列を指定します。

    DB::table('flights')->upsert([
        ['departure' => 'Oakland', 'destination' => 'San Diego', 'price' => 99],
        ['departure' => 'Chicago', 'destination' => 'New York', 'price' => 150]
    ], ['departure', 'destination'], ['price']);

> {note} SQL Serverを除くすべてのデータベースでは、`upsert`メソッドの第２引数のカラムへ"primary"か"unique"なインデックスが必要です。

#### 自動増分ID

テーブルが自動増分IDを持っている場合、`insertGetId`メソッドを使うとレコードを挿入し、そのレコードのIDを返してくれます。

    $id = DB::table('users')->insertGetId(
        ['email' => 'john@example.com', 'votes' => 0]
    );

> {note} PostgreSQLで`insertGetId`メソッドを使う場合、自動増分カラム名は`id`である必要があります。他の「シーケンス」からIDを取得したい場合は、`insertGetId`メソッドの第２引数へカラム名を指定してください。

<a name="updates"></a>
## UPDATE

データベースへレコードを挿入するだけでなく、存在しているレコードを`update`メソッドで更新することもできます。`update`メソッドは`insert`メソッドと同様に、更新対象のカラムのカラム名と値の配列を引数に受け取ります。更新するクエリを`where`節を使って制約することもできます。

    $affected = DB::table('users')
                  ->where('id', 1)
                  ->update(['votes' => 1]);

#### UPDATEかINSERT

データベースへ一致するレコードが存在している場合は更新し、一致するレコードがない場合は新規追加したいことも起きます。このようなシナリオでは、`updateOrInsert`メソッドが使えます。`updateOrInsert`メソッドは２つの引数を取ります。見つけようとするレコードの条件の配列と、更新するカラム／値のペアの配列です。

`updateOrInsert`メソッドは最初の引数のカラム／値ペアを使い、一致するデータベースレコードを見つけようとします。レコードが存在していれば、２つ目の引数の値で更新します。レコードが見つからなければ、両引数をマージした結果で新しいレコードを挿入します。

    DB::table('users')
        ->updateOrInsert(
            ['email' => 'john@example.com', 'name' => 'John'],
            ['votes' => '2']
        );

<a name="updating-json-columns"></a>
### JSONカラムの更新

JSONカラムを更新するときは、JSONオブジェクトの適切なキーへアクセスするために、`->`記法を使う必要があります。この操作はMySQL5.7以上と、PostgreSQL9.5以上でサポートしています。

    $affected = DB::table('users')
                  ->where('id', 1)
                  ->update(['options->enabled' => true]);

<a name="increment-and-decrement"></a>
### 増分・減分

クエリビルダは指定したカラムの値を増やしたり、減らしたりするのに便利なメソッドも用意しています。これは短縮記法で、`update`文で書くのに比べるとより記述的であり、簡潔なインターフェイスを提供しています。

両方のメソッドともに、最小１つ、更新したいカラムを引数に取ります。オプションの第２引数はそのカラムの増減値を指定します。

    DB::table('users')->increment('votes');

    DB::table('users')->increment('votes', 5);

    DB::table('users')->decrement('votes');

    DB::table('users')->decrement('votes', 5);

さらに増減操作と一緒に更新する追加のカラムを指定することもできます。

    DB::table('users')->increment('votes', 1, ['name' => 'John']);

> {{note} `increment`と`decrement`メソッドを使用する場合、モデルイベントは発行されません。

<a name="deletes"></a>
## DELETE

クエリビルダは`delete`メソッドで、テーブルからレコードを削除するためにも使用できます。 `delete`メソッドを呼び出す前に`where`節を追加し、`delete`文を制約することもできます。

    DB::table('users')->delete();

    DB::table('users')->where('votes', '>', 100)->delete();

全レコードを削除し、自動増分のIDを0へリセットするためにテーブルをTRUNCATEしたい場合は、`truncate`メソッドを使います。

    DB::table('users')->truncate();

<a name="pessimistic-locking"></a>
## 悲観的ロック

クエリビルダは、`SELECT`文で「悲観的ロック」を行うための機能をいくつか持っています。SELECT文を実行する間「共有ロック」をかけたい場合は、`sharedLock`メソッドをクエリに指定してください。共有ロックはトランザクションがコミットされるまで、SELECTしている行が更新されることを防ぎます。

    DB::table('users')->where('votes', '>', 100)->sharedLock()->get();

もしくは`lockForUpdate`メソッドが使えます。占有ロックをかけることで、レコードを更新したりSELECTするために他の共有ロックが行われるのを防ぎます。

    DB::table('users')->where('votes', '>', 100)->lockForUpdate()->get();

<a name="debugging"></a>
## デバッグ

クエリを組み立てる時に、クエリの結合とSQLをダンプするために、`dd`と`dump`メソッドが使用できます。`dd`メソッドはデバッグ情報を出力し、リクエストの実行を中断します。`dump`メソッドはデバッグ情報を出力しますが、リクエストは継続して実行されます。

    DB::table('users')->where('votes', '>', 100)->dd();

    DB::table('users')->where('votes', '>', 100)->dump();
