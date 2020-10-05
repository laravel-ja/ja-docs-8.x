# データベース：シーディング

- [イントロダクション](#introduction)
- [シーダクラス定義](#writing-seeders)
    - [モデルファクトリの使用](#using-model-factories)
    - [追加のシーダ呼び出し](#calling-additional-seeders)
- [シーダの実行](#running-seeders)

<a name="introduction"></a>
## イントロダクション

シーダ（初期値設定）クラスを使用し、テストデーターをデーターベースに設定するシンプルな方法もLaravelには備わっています。全シーダクラスは`database/seeders`に保存します。シーダクラスには好きな名前を付けられます。しかし`UserSeeder`などのような分かりやすい規則に従ったほうが良いでしょう。デフォルトとして`DatabaseSeeder`クラスが定義されています。このクラスから`call`メソッドを使い他の初期値設定クラスを呼び出すことで、シーディングの順番をコントロールできます。

<a name="writing-seeders"></a>
## シーダクラス定義

シーダを生成するには、`make:seeder` [Artisanコマンド](/docs/{{version}}/artisan)を実行します。フレームワークが生成するシーダはすべて`database/seeders`ディレクトリに設置されます。

    php artisan make:seeder UserSeeder

シーダクラスはデフォルトで`run`メソッドだけを含んでいます。このメソッドは`db:seed` [Artisanコマンド](/docs/{{version}}/artisan)が実行された時に呼びだされます。`run`メソッドの中でデータベースに何でも好きなデーターを挿入できます。[クエリビルダ](/docs/{{version}}/queries)でデータを挿入することも、もしくは[Eloquentモデルファクトリ](/docs/{{version}}/database-testing#writing-factories)を使うこともできます。

> {tip} データベースシーディング時、[複数代入の保護](/docs/{{version}}/eloquent#mass-assignment)は自動的に無効になります。

例として、Laravelのインストール時にデフォルトで用意されている`DatabaseSeeder`クラスを変更してみましょう。`run`メソッドにデータベースINSERT文を追加します。

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

> {tip} `run`メソッドの引数として、タイプヒントにより必要な依存を指定できます。それらはLaravelの[サービスコンテナ](/docs/{{version}}/container)により、自動的に依存解決されます。

<a name="using-model-factories"></a>
### モデルファクトリの利用

当然それぞれのモデルシーダで属性をいちいち指定するのは面倒です。代わりに大量のデータベースレコードを生成するのに便利な[モデルファクトリ](/docs/{{version}}/database-testing#writing-factories)が使用できます。最初に[モデルファクトリのドキュメント](/docs/{{version}}/database-testing#writing-factories)を読んで、どのように定義するのかを学んでください。

例として50件のレコードを生成し、それぞれのユーザーへリレーションを付加してみましょう。

    use App\Models\User;

    /**
     * データベースに対するデータ設定の実行
     *
     * @return void
     */
    public function run()
    {
        User::factory()
                ->times(50)
                ->hasPosts(1)
                ->create();
    }

<a name="calling-additional-seeders"></a>
### 追加のシーダ呼び出し

`DatabaseSeeder`クラスの中で追加のシーダクラスを呼び出す`call`メソッドが使えます。`call`メソッドを使うことで、圧倒されるぐらい大きな１ファイルを使う代わりに、データベースシーディングを複数のファイルへ分割できます。実行したいシーダクラス名を渡します。

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

データベースへ初期値を設定するために`db:seed` Artisanコマンドを使用します。デフォルトで`db:seed`コマンドは、他のシーダクラスを呼び出す`DatabaseSeeder`クラスを実行します。しかし特定のファイルを個別に実行したい場合は、`--class`オプションを使いシーダを指定してください。

    php artisan db:seed

    php artisan db:seed --class=UserSeeder

もしくはテーブルをすべてドロップし、マイグレーションを再実行する`migrate:fresh`コマンドを使っても、データベースに初期値を設定できます。このコマンドはデータベースを完全に作成し直したい場合に便利です。

    php artisan migrate:fresh --seed

<a name="forcing-seeding-production"></a>
#### 実働環境でのシーダの強制実行

シーディング操作ではデータが変更されたり、失われる場合があります。実働環境のデータベースに対してシーディングコマンドが実行されるのを防ぐために、シーダを実行する前に確認のプロンプトが表示されます。プロンプトを出さずにシーダを強行する場合は、`--force`フラグを使います。

    php artisan db:seed --force
