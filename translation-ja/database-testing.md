# データベースのテスト

- [イントロダクション](#introduction)
- [各テスト後のデータベースリセット](#resetting-the-database-after-each-test)
- [ファクトリの生成](#creating-factories)
- [ファクトリの記述](#writing-factories)
    - [ファクトリステート](#factory-states)
    - [ファクトリコールバック](#factory-callbacks)
- [ファクトリの使用](#using-factories)
    - [モデルの生成](#creating-models)
    - [モデルの保存](#persisting-models)
    - [順序](#sequences)
- [ファクトリのリレーション](#factory-relationships)
    - [定義中のリレーション](#relationships-within-definition)
    - [Has Manyリレーション](#has-many-relationships)
    - [Belongs Toリレーション](#belongs-to-relationships)
    - [Many To Manyリレーション](#many-to-many-relationships)
    - [ポリモーフィックリレーション](#polymorphic-relationships)
- [シーダの使用](#using-seeds)
- [使用可能なアサーション](#available-assertions)

<a name="introduction"></a>
## イントロダクション

Laravelでは、データベースを駆動するアプリケーションのテストを簡単にできる、便利で数多くのツールを用意しています。その一つは、指定した抽出条件に一致するデータがデータベース中に存在するかをアサートする、`assertDatabaseHas`ヘルパです。たとえば、`users`テーブルの中に`email`フィールドが`sally@example.com`の値のレコードが存在するかを確認したいとしましょう。次のようにテストできます。

    public function testDatabase()
    {
        // アプリケーションを呼び出す…

        $this->assertDatabaseHas('users', [
            'email' => 'sally@example.com',
        ]);
    }

データベースにデータが存在しないことをアサートする、`assertDatabaseMissing`ヘルパを使うこともできます。

`assertDatabaseHas`メソッドやその他のヘルパは、皆さんが便利に使ってもらうため用意しています。PHPUnitの組み込みアサートメソッドは、機能テストで自由に使用できます。

<a name="resetting-the-database-after-each-test"></a>
## 各テスト後のデータベースリセット

前のテストがその後のテストデータに影響しないように、各テストの後にデータベースをリセットできると便利です。インメモリデータベースを使っていても、トラディショナルなデータベースを使用していても、`RefreshDatabase`トレイトにより、マイグレーションに最適なアプローチが取れます。テストクラスにてこのトレイトを使えば、すべてが処理されます。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        use RefreshDatabase;

        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $response = $this->get('/');

            // …
        }
    }

<a name="creating-factories"></a>
## ファクトリの生成

テスト時は実行前にデータベースへいくつかのレコードを挿入する必要があります。こうしたテストデータを制作する時に各カラムの値を自分で指定する代わりに、Laravelではモデルファクトリを使用し、各[Eloquentモデル](/docs/{{version}}/eloquent)のデフォルト属性セットを定義できます。

ファクトリを生成するには、`make:factory` [Artisanコマンド](/docs/{{version}}/artisan)を使用します。

    php artisan make:factory PostFactory

新しいファクトリは、`database/factories`ディレクトリに設置されます。

`--model`オプションにより、ファクトリが生成するモデルの名前を指定できます。このオプションは、生成するファクトリファイルへ指定モデル名を事前に設定します。

    php artisan make:factory PostFactory --model=Post

<a name="writing-factories"></a>
## ファクトリの記述

To get started, take a look at the `database/factories/UserFactory.php` file in your application. Out of the box, this file contains the following factory definition:開始前にアプリケーション中の`database/factories/UserFactory.php`ファイルをご覧ください。始めから、このファイルは以下のファクトリ定義を含んでいます。

    namespace Database\Factories;

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Factory;
    use Illuminate\Support\Str;

    class UserFactory extends Factory
    {
        /**
         * ファクトリに対応するモデルの名前
         *
         * @var string
         */
        protected $model = User::class;

        /**
         * モデルのデフォルト状態の定義
         *
         * @return array
         */
        public function definition()
        {
            return [
                'name' => $this->faker->name,
                'email' => $this->faker->unique()->safeEmail,
                'email_verified_at' => now(),
                'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
                'remember_token' => Str::random(10),
            ];
        }
    }

ご覧のとおり、もっとも基本的な形式のファクトリはLaravelの基本ファクトリクラスを拡張し、`model`プロパティと`definition`メソッドを定義するクラスです。`definition`メソッドは、ファクトリを使用してモデルを作成するときに適用する必要がある属性値のデフォルトのセットを返します。

`faker`プロパティにより、ファクトリは[Faker](https://github.com/fzaninotto/Faker) PHPライブラリにアクセスできます。これによりテスト用のさまざまな種類のランダムデータを簡単に生成できます。

> {tip} Fakerのローケルは、`config/app.php`設定ファイルの`faker_locale`オプションで指定できます。

<a name="factory-states"></a>
### ファクトリステート

ステート操作メソッドにより、モデルファクトリのどんな組み合わせに対しても適用できる、個別の調整を定義できます。たとえば、`User`モデルは、デフォルト属性値の一つを変更する、`suspended`状態を持つとしましょう。`state`メソッドを使い、状態遷移を定義します。ステートメソッドには好きな名前が付けられます。典型的なPHPメソッドにすぎません。指定する状態操作コールバックは、ファクトリに対し定義した属性そのままの配列を引数に取り、変更する属性の配列を返します。

    /**
     * そのユーザーが資格保留(suspended)されていることを表す
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function suspended()
    {
        return $this->state(function (array $attributes) {
            return [
                'account_status' => 'suspended',
            ];
        });
    }

<a name="factory-callbacks"></a>
### ファクトリコールバック

ファクトリコールバックは`afterMaking`と`afterCreating`メソッドを使用し登録し、モデルを作成、もしくは生成した後の追加タスクを実行できるようにします。これらのコールバックは、ファクトリクラスの`configure`メソッドを定義し登録します。このメソッドはファクトリがインスタンス化される時にLaravelが自動的に呼び出します。

    namespace Database\Factories;

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Factory;
    use Illuminate\Support\Str;

    class UserFactory extends Factory
    {
        /**
         * ファクトリに対応するモデルの名前
         *
         * @var string
         */
        protected $model = User::class;

        /**
         * モデルファクトリの設定
         *
         * @return $this
         */
        public function configure()
        {
            return $this->afterMaking(function (User $user) {
                //
            })->afterCreating(function (User $user) {
                //
            });
        }

        // …
    }

<a name="using-factories"></a>
## ファクトリの使用

<a name="creating-models"></a>
### モデルの生成

ファクトリを定義できたら、モデルのファクトリインスタンスをインスタンス化するため、Eloquentモデル上の`Illuminate\Database\Eloquent\Factories\HasFactory`トレイトが提供している静的`factory`メソッドを使います。

    namespace App\Models;

    use Illuminate\Database\Eloquent\Factories\HasFactory;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        use HasFactory;
    }

モデルの生成例をいくつか見てみましょう。データベースへ保存せずにモデルを生成する`make`メソッドを使ってみましょう。

    use App\Models\User;

    public function testDatabase()
    {
        $user = User::factory()->make();

        // モデルをテストで使用…
    }

You may create a collection of many models using the `count` method:

    // Create three App\Models\User instances...
    $users = User::factory()->count(3)->make();

`HasFactory`トレイトの`factory`メソッドはモデルに対し正しいファクトリなのかを判定するために便利に使えます。具体的には、このメソッドは`Database\Factories`名前空間の中のモデル名と一致するクラス名を持ち、最後に`Factory`が付くファクトリを探します。この命名規則を特定のアプリケーションまたはファクトリで適用しない場合は、ファクトリを直接使用してモデルインスタンスを作成できます。ファクトリクラスを使用して新しいファクトリインスタンスを作成するには、ファクトリで静的な`new`メソッドを呼び出す必要があります

    /**
     * Create a new factory instance for the model.
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    protected static function newFactory()
    {
        return \Database\Factories\Administration\FlightFactory::new();
    }

#### ステートの適用

こうしたモデルに対して[ステート](#factory-states)を適用することもできます。複数の状態遷移を適用したい場合は、シンプルにステートメソッドを直接呼び出します。

    $users = User::factory()->count(5)->suspended()->make();

#### 属性のオーバーライド

モデルのデフォルト値をオーバーライドしたい場合は、`make`メソッドに配列で値を渡してください。指定した値のみ置き換わり、残りの値はファクトリで指定したデフォルト値のまま残ります。

    $user = User::factory()->make([
        'name' => 'Abigail Otwell',
    ]);

もしくは、インラインで状態遷移させるために、ファクトリインスタンスで直接`state`メソッドを呼び出します。

    $user = User::factory()->state([
        'name' => 'Abigail Otwell',
    ])->make();

> {tip} ファクトリを用いモデルを生成する場合は、[複数代入の保護](/docs/{{version}}/eloquent#mass-assignment)を自動的に無効にします。

<a name="persisting-models"></a>
### モデルの保存

`create`メソッドはモデルインスタンスを生成するだけでなく、Eloquentの`save`メソッドを使用しデータベースへ保存します。

    use App\Models\User;

    public function testDatabase()
    {
        // 一つのApp\Models\Userインスタンスを作成
        $user = User::factory()->create();

        // App\Models\Userインスタンスを３つ生成
        $users = User::factory()->count(3)->create();

        // モデルをテストで使用…
    }

`create`メソッドに配列で値を渡すことで、モデルの属性をオーバーライドできます。

    $user = User::factory()->create([
        'name' => 'Abigail',
    ]);

<a name="sequences"></a>
### 順序

作成する各モデルごとに、指定するモデル属性の値を交互に指定したい場合もあります。それには状態遷移を`Sequence`インスタンスとして定義します。たとえば、`User`モデルの`admin`カラムの値をユーザーを生成するごとに`Y`と`N`の交互で切り替えたいとします。

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Sequence;

    $users = User::factory()
                    ->count(10)
                    ->state(new Sequence(
                        ['admin' => 'Y'],
                        ['admin' => 'N'],
                    ))
                    ->create();

この例では、`admin`値が`Y`の５ユーザーと`N`の５ユーザーが生成されます。

<a name="factory-relationships"></a>
## ファクトリのリレーション

<a name="relationships-within-definition"></a>
### 定義中のリレーション

ファクトリ定義の中でモデルへのリレーションを付加できます。例として`Post`作成時に新しい`User`インスタンスを作成したいとしましょう。以下のようになります。

    use App\Models\User;

    /**
     * モデルのデフォルト状態の定義
     *
     * @return array
     */
    public function definition()
    {
        return [
            'user_id' => User::factory(),
            'title' => $this->faker->title,
            'content' => $this->faker->paragraph,
        ];
    }

リレーションのカラムが、それを定義するファクトリに依存している場合、評価済みの属性配列を引数に取るコールバックを指定できます。

    /**
     * モデルのデフォルト状態の定義
     *
     * @return array
     */
    public function definition()
    {
        return [
            'user_id' => User::factory(),
            'user_type' => function (array $attributes) {
                return User::find($attributes['user_id'])->type;
            },
            'title' => $this->faker->title,
            'content' => $this->faker->paragraph,
        ];
    }

<a name="has-many-relationships"></a>
### Has Manyリレーション

次に、Laravelの読み書きしやすいファクトリメソッドを使用して、Eloquentモデルリレーションの構築を説明します。まず、アプリケーションに`User`と`Post`モデルがあると仮定しましょう。その`User`モデルは`Post`に対して`hasMany`リレーションを定義しているとも仮定しましょう。ファクトリが提供する`has`メソッドを使い、３ポストを持つユーザーを１件作ってみます。`has`メソッドはファクトリインスタンスを引数に取ります。

    use App\Models\Post;
    use App\Models\User;

    $user = User::factory()
                ->has(Post::factory()->count(3))
                ->create();

規約により、`Post`モデルを`has`メソッドに渡すとき、Laravelは`User`モデルがリレーションを定義する`posts`メソッドを持っていると想定します。必要に応じ、操作したいリレーションの名前を明示的に指定できます。

    $user = User::factory()
                ->has(Post::factory()->count(3), 'posts')
                ->create();

もちろん、関連するモデルに対し状態操作することもできます。加えて、状態の変更に親モデルへのアクセスが必要であるなら、クロージャベースで状態遷移を渡すこともできます。

    $user = User::factory()
                ->has(
                    Post::factory()
                            ->count(3)
                            ->state(function (array $attributes, User $user) {
                                return ['user_type' => $user->type];
                            })
                )
                ->create();

#### マジックメソッドの使用

リレーションシップを定義するため便利なように、ファクトリのマジックリレーションメソッドを使用できます。たとえば以下の例では、関連するモデルが`User`モデル上の`posts`リレーションメソッドを介して作成されるべきであることを決定するように記法を使用します。

    $user = User::factory()
                ->hasPosts(3)
                ->create();

ファクトリリレーションを作成するためにマジックメソッドを使用する場合は、関連モデルをオーバーライドするために属性の配列を渡せます。

    $user = User::factory()
                ->hasPosts(3, [
                    'published' => false,
                ])
                ->create();

状態の変更で親モデルにアクセスする必要があるなら、クロージャベースの状態遷移を渡せます。

    $user = User::factory()
                ->hasPosts(3, function (array $attributes, User $user) {
                    return ['user_type' => $user->type];
                })
                ->create();

<a name="belongs-to-relationships"></a>
### Belongs Toリレーション

今度はファクトリを使用した"has many"リレーションをどのように構築するか説明します。`for`メソッドは、ファクトリで作成されたモデルが属するモデルを定義するために使われます。たとえば、1人のユーザーに属する３つの`Post`モデルインスタンスを作成できます。

    use App\Models\Post;
    use App\Models\User;

    $posts = Post::factory()
                ->count(3)
                ->for(User::factory()->state([
                    'name' => 'Jessica Archer',
                ]))
                ->create();

#### マジックメソッドの使用

"belongs to"リレーションを定義するのに便利なように、ファクトリのマジックリレーションメソッドを使用できます。たとえば次の例は記法を使用し、３つのポストが`Post`モデルの`user`リレーションに属することを決定します

    $posts = Post::factory()
                ->count(3)
                ->forUser([
                    'name' => 'Jessica Archer',
                ])
                ->create();

<a name="many-to-many-relationships"></a>
### Many To Manyリレーション

[has manyリレーション](#has-many-relationships)と同様に、"many to many"リレーションは`has`メソッドを使用して作成できます。

    use App\Models\Role;
    use App\Models\User;

    $users = User::factory()
                ->has(Role::factory()->count(3))
                ->create();

#### 中間テーブルの属性

モデルにリンクするピボット／中間テーブルへセットする属性を定義する必要がある場合は、`hasAttached`メソッドを使用します。このメソッドは第２引数としてピボットテーブルの属性名と値の配列を引数に取ります。

    use App\Models\Role;
    use App\Models\User;

    $users = User::factory()
                ->hasAttached(
                    Role::factory()->count(3),
                    ['active' => true]
                )
                ->create();

状態変化で関連モデルへアクセスする必要があれば、クロージャベースの状態遷移を指定できます。

    $users = User::factory()
                ->hasAttached(
                    Role::factory()
                        ->count(3)
                        ->state(function (array $attributes, User $user) {
                            return ['name' => $user->name.' Role'];
                        }),
                    ['active' => true]
                )
                ->create();

#### マジックメソッドの使用

ファクトリのマジックリレーションメソッドを使用して、多対多のリレーションを便利に定義できます。たとえば次の例では、関連するモデルが`User`モデル上の`roles`リレーションメソッドを介して作成されるべきだと決めるため記法を使用しています。

    $users = User::factory()
                ->hasRoles(1, [
                    'name' => 'Editor'
                ])
                ->create();

<a name="polymorphic-relationships"></a>
### ポリモーフィックリレーション

[ポリモーフィックリレーション](/docs/{{version}}/eloquent-relationships#polymorphic-relationships)もファクトリを使って作成できます。ポリモーフィックな"morph many"リレーションは、典型的な "has many"リレーションと同じ方法で作成します。たとえば、`Post`モデルが`Comment`モデルと`morphMany`リレーションを持つとします。

    use App\Models\Post;

    $post = Post::factory()->hasComments(3)->create();

#### Morph Toリレーション

マジックメソッドは`morphTo`リレーションを作成するために使用できません。代わりに`for`メソッドを直接使用し、リレーション名を明白に指定する必要があります。たとえば、`Comment`モデルが`morphTo`リレーションを定義する`commentable`メソッドを持っていると想像してください。この状況で、`for`メソッドを直接使用し１つのポストに所属する３コメントを作成してみましょう。

    $comments = Comment::factory()->count(3)->for(
        Post::factory(), 'commentable'
    )->create();

#### Polymorphic Many To Manyリレーション

ポリモーフィック"many to many"リレーションは、ポリモーフィックではない"many to many"と同様に作成できます。

    use App\Models\Tag;
    use App\Models\Video;

    $videos = Video::factory()
                ->hasAttached(
                    Tag::factory()->count(3),
                    ['public' => true]
                )
                ->create();

もちろん、マジック`has`メソッドも、ポリモーフィック"many to many"リレーションを作成するために使用できます。

    $videos = Video::factory()
                ->hasTags(3, ['public' => true])
                ->create();

<a name="using-seeds"></a>
## シーダの使用

機能テストでデータベースへ初期値を設定するために、[データベースシーダ](/docs/{{version}}/seeding)を使いたい場合は、`seed`メソッドを使用してください。デフォルトで`seed`メソッドは、他のシーダを全部実行する`DatabaseSeeder`を返します。もしくは、`seed`メソッドへ特定のシーダクラス名を渡してください。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use OrderStatusSeeder;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        use RefreshDatabase;

        /**
         * 新オーダー生成のテスト
         *
         * @return void
         */
        public function testCreatingANewOrder()
        {
            // DatabaseSeederを実行
            $this->seed();

            // シーダを１つ実行
            $this->seed(OrderStatusSeeder::class);

            // …
        }
    }

もしくは`RefreshDatabase`へ、各テストの直前でデータベースを自動的に初期値設定するよう指示することも可能です。テストクラスへ`$seed`プロパティを定義します。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 各テストの前に、データベースへ初期値設定するかどうかを表す
         *
         * @var bool
         */
        protected $seed = true;

        // ...
    }

<a name="available-assertions"></a>
## 使用可能なアサーション

Laravelは、多くのデータベースアサーションを[PHPUnit](https://phpunit.de/)機能テスト向けに提供しています。

メソッド  | 説明
------------- | ---------------------------------------------------------------------------
`$this->assertDatabaseCount($table, int $count);`  |  データベースのテーブルが、エンティティを指定量含むことをアサート
`$this->assertDatabaseHas($table, array $data);`  |  指定したデータが、テーブルに存在することをアサート
`$this->assertDatabaseMissing($table, array $data);`  |  指定したデータが、テーブルに含まれないことをアサート
`$this->assertDeleted($table, array $data);`  |  指定したレコードが削除されていることをアサート
`$this->assertSoftDeleted($table, array $data);`  |  指定したレコードがソフトデリートされていることをアサート

レコードの削除・ソフト削除のアサートに便利なよう、`assertDeleted`と`assertSoftDeleted`ヘルパへはモデルが渡せるようになっています。その場合、モデルの主キーを利用します。

たとえば、モデルファクトリをテストで使用する場合に、アプリケーションでデータベースからそのレコードが確実に削除されているかをテストするために、これらのヘルパへモデルを渡せます。

    public function testDatabase()
    {
        $user = User::factory()->create();

        // アプリケーションを呼び出す…

        $this->assertDeleted($user);
    }
