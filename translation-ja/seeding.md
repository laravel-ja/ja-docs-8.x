# データベース：シーディング

- [イントロダクション](#introduction)
- [シーダクラス定義](#writing-seeders)
    - [モデルファクトリの使用](#using-model-factories)
    - [追加のシーダ呼び出し](#calling-additional-seeders)
- [シーダの実行](#running-seeders)

<a name="introduction"></a>
## イントロダクション

Laravelは、シードクラスを使用してデータベースにテストデータをシード（種をまく、初期値の設定）する機能を持っています。すべてのシードクラスは`database/seeders`ディレクトリに保存します。デフォルトで、`DatabaseSeeder`クラスが定義されています。このクラスから、`call`メソッドを使用して他のシードクラスを実行し、シードの順序を制御できます。

> {tip} [複数代入](/docs/{{version}}/eloquent#mass-assignment)は、データベースのシード中では自動的に無効になります。

<a name="writing-seeders"></a>
## シーダクラス定義

シーダを生成するには、`make:seeder` [Artisanコマンド](/docs/{{version}}/artisan)を実行します。フレームワークが生成するシーダはすべて`database/seeders`ディレクトリに設置します。

    php artisan make:seeder UserSeeder

シーダクラスには、デフォルトで１つのメソッド、`run`のみ存在します。このメソッドは、`db:seed` [Artisanコマンド](/docs/{{version}}/artisan)が実行されるときに呼び出されます。`run`メソッド内で、データベースにデータを好きなように挿入できます。[クエリビルダ](/docs/{{version}}/queries)を使用してデータを手動で挿入するか、[Eloquentモデルファクトリ](/docs/{{version}}/database-testing#defining-model-factories)を使用できます。

例として、デフォルトの`DatabaseSeeder`クラスを変更し、データベース挿入文を`run`メソッドに追加しましょう。

    <?php

    namespace Database\Seeders;

    use Illuminate\Database\Seeder;
    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\Facades\Hash;
    use Illuminate\Support\Str;

    class DatabaseSeeder extends Seeder
    {
        /**
         * データベースに対するデータ設定の実行
         *
         * @return void
         */
        public function run()
        {
            DB::table('users')->insert([
                'name' => Str::random(10),
                'email' => Str::random(10).'@gmail.com',
                'password' => Hash::make('password'),
            ]);
        }
    }

> {tip} `run`メソッドの引数として、タイプヒントにより必要な依存を指定できます。それらはLaravelの[サービスコンテナ](/docs/{{version}}/container)が自動的に依存解決します。

<a name="using-model-factories"></a>
### モデルファクトリの利用

当然それぞれのモデルシーダで属性をいちいち指定するのは面倒です。代わりに大量のデータベースレコードを生成するのに便利な[モデルファクトリ](/docs/{{version}}/database-testing#defining-model-factories)が使用できます。最初に[モデルファクトリのドキュメント](/docs/{{version}}/database-testing#defining-model-factories)を読んで、どのように定義するのかを学んでください。

例として、それぞれに１つの関連する投稿がある５０人のユーザーを作成しましょう。

    use App\Models\User;

    /**
     * データベースに対するデータ設定の実行
     *
     * @return void
     */
    public function run()
    {
        User::factory()
                ->count(50)
                ->hasPosts(1)
                ->create();
    }

<a name="calling-additional-seeders"></a>
### 追加のシーダ呼び出し

`DatabaseSeeder`クラス内で、`call`メソッドを使用して追加のシードクラスを実行できます。`call`メソッドを使用すると、データベースのシードを複数のファイルに分割して、単一のシーダークラスが大きくなりすぎないようにできます。`call`メソッドは、実行する必要のあるシーダークラスの配列を引数に取ります。

    /**
     * データベースに対するデータ設定の実行
     *
     * @return void
     */
    public function run()
    {
        $this->call([
            UserSeeder::class,
            PostSeeder::class,
            CommentSeeder::class,
        ]);
    }

<a name="running-seeders"></a>
## シーダの実行

`db:seed` Artisanコマンドを実行して、データベースに初期値を設定します。デフォルトでは、`db:seed`コマンドは`Database\Seeders\DatabaseSeeder`クラスを実行します。このクラスから他のシードクラスが呼び出される場合があります。ただし、`--class`オプションを使用して、個別に実行する特定のシーダークラスを指定できます。

    php artisan db:seed

    php artisan db:seed --class=UserSeeder

`migrate:fresh`コマンドを`--seed`オプションと組み合わせて使用​​してデータベースをシードすることもできます。これにより、すべてのテーブルが削除され、すべてのマイグレーションが再実行されます。このコマンドは、データベースを完全に再構築するのに役立ちます。

    php artisan migrate:fresh --seed

<a name="forcing-seeding-production"></a>
#### 実働環境でのシーダの強制実行

一部のシード操作により、データが変更または失われる場合があります。本番データベースに対してシードコマンドを実行しないように保護するために、`production`環境でシーダーを実行する前に確認を求めるプロンプトが表示されます。シーダーをプロンプトなしで強制的に実行するには、`--force`フラグを使用します。

    php artisan db:seed --force
