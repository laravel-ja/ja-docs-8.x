# データベースのテスト

- [イントロダクション](#introduction)
- [各テスト後のデータベースリセット](#resetting-the-database-after-each-test)
- [Creating Factories](#creating-factories)
- [ファクトリの記述](#writing-factories)
    - [ファクトリステート](#factory-states)
    - [ファクトリコールバック](#factory-callbacks)
- [ファクトリの使用](#using-factories)
    - [モデルの生成](#creating-models)
    - [モデルの保存](#persisting-models)
    - [Sequences](#sequences)
- [Factory Relationships](#factory-relationships)
    - [Relationships Within Definitions](#relationships-within-definition)
    - [Has Many Relationships](#has-many-relationships)
    - [Belongs To Relationships](#belongs-to-relationships)
    - [Many To Many Relationships](#many-to-many-relationships)
    - [Polymorphic Relationships](#polymorphic-relationships)
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
## Creating Factories

When testing, you may need to insert a few records into your database before executing your test. Instead of manually specifying the value of each column when you create this test data, Laravel allows you to define a default set of attributes for each of your [Eloquent models](/docs/{{version}}/eloquent) using model factories.

ファクトリを生成するには、`make:factory` [Artisanコマンド](/docs/{{version}}/artisan)を使用します。

    php artisan make:factory PostFactory

新しいファクトリは、`database/factories`ディレクトリに設置されます。

`--model`オプションにより、ファクトリが生成するモデルの名前を指定できます。このオプションは、生成するファクトリファイルへ指定モデル名を事前に設定します。

    php artisan make:factory PostFactory --model=Post

<a name="writing-factories"></a>
## ファクトリの記述

To get started, take a look at the `database/factories/UserFactory.php` file in your application. Out of the box, this file contains the following factory definition:

    namespace Database\Factories;

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Factory;
    use Illuminate\Support\Str;

    class UserFactory extends Factory
    {
        /**
         * The name of the factory's corresponding model.
         *
         * @var string
         */
        protected $model = User::class;

        /**
         * Define the model's default state.
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

As you can see, in their most basic form, factories are classes that extend Laravel's base factory class and define a `model` property and `definition` method. The `definition` method returns the default set of attribute values that should be applied when creating a model using the factory.

Via the `faker` property, factories have access to the [Faker](https://github.com/fzaninotto/Faker) PHP library, which allows you to conveniently generate various kinds of random data for testing.

> {tip} Fakerのローケルは、`config/app.php`設定ファイルの`faker_locale`オプションで指定できます。

<a name="factory-states"></a>
### ファクトリステート

State manipulation methods allow you to define discrete modifications that can be applied to your model factories in any combination. For example, your `User` model might have a `suspended` state that modifies one of its default attribute values. You may define your state transformations using the base factory's `state` method. You may name your state method anything you like. After all, it's just a typical PHP method:

    /**
     * Indicate that the user is suspended.
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function suspended()
    {
        return $this->state([
            'account_status' => 'suspended',
        ]);
    }

If your state transformation requires access to the other attributes defined by the factory, you may pass a callback to the `state` method. The callback will receive the array of raw attributes defined for the factory:

    /**
     * Indicate that the user is suspended.
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

Factory callbacks are registered using the `afterMaking` and `afterCreating` methods and allow you to perform additional tasks after making or creating a model. You should register these callbacks by defining a `configure` method on the factory class. This method will automatically be called by Laravel when the factory is instantiated:

    namespace Database\Factories;

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Factory;
    use Illuminate\Support\Str;

    class UserFactory extends Factory
    {
        /**
         * The name of the factory's corresponding model.
         *
         * @var string
         */
        protected $model = User::class;

        /**
         * Configure the model factory.
         *
         * @return void
         */
        public function configure()
        {
            $this->afterMaking(function (User $user) {
                //
            });

            $this->afterCreating(function (User $user) {
                //
            });
        }

        // …
    }

<a name="using-factories"></a>
## ファクトリの使用

<a name="creating-models"></a>
### モデルの生成

Once you have defined your factories, you may use the static `factory` method provided by the `HasFactory` trait on your Eloquent models in order to instantiate a factory instance for that model. Let's take a look at a few examples of creating models. First, we'll use the `make` method to create models without persisting them to the database:

    use App\Models\User;

    public function testDatabase()
    {
        $user = User::factory()->make();

        // モデルをテストで使用…
    }

You may create a collection of many models using the `count` method:

    // Create three App\Models\User instances...
    $users = User::factory()->count(3)->make();

The `HasFactory` trait's `factory` method will use conventions to determine the proper factory for the model. Specifically, the method will look for a factory in the `Database\Factories` namespace that has a class name matching the model name and is suffixed with `Factory`. If these conventions do not apply to your particular application or factory, you may use the factory directly to create model instances. To create a new factory instance using the factory class, you should call the static `new` method on the factory:

    use Database\Factories\UserFactory;

    $users = UserFactory::new()->count(3)->make();

#### ステートの適用

You may also apply any of your [states](#factory-states) to the models. If you would like to apply multiple state transformations to the models, you may simply call state methods directly:

    $users = User::factory()->count(5)->suspended()->make();

#### 属性のオーバーライド

モデルのデフォルト値をオーバーライドしたい場合は、`make`メソッドに配列で値を渡してください。指定した値のみ置き換わり、残りの値はファクトリで指定したデフォルト値のまま残ります。

    $user = User::factory()->make([
        'name' => 'Abigail Otwell',
    ]);

Alternatively, the `state` method may be called directly on the factory instance to perform an inline state transformation:

    $user = User::factory()->state([
        'name' => 'Abigail Otwell',
    ])->make();

> {tip} ファクトリを用いモデルを生成する場合は、[複数代入の保護](/docs/{{version}}/eloquent#mass-assignment)を自動的に無効にします。

<a name="persisting-models"></a>
### モデルの保存

The `create` method creates model instances and persists them to the database using Eloquent's `save` method:

    use App\Models\User;

    public function testDatabase()
    {
        // Create a single App\Models\User instance...
        $user = User::factory()->create();

        // Create three App\Models\User instances...
        $users = User::factory()->count(3)->create();

        // モデルをテストで使用…
    }

You may override attributes on the model by passing an array of attributes to the `create` method:

    $user = User::factory()->create([
        'name' => 'Abigail',
    ]);

<a name="sequences"></a>
### Sequences

Sometimes you may wish to alternate the value of a given model attribute for each created model. You may accomplish this by defining a state transformation as a `Sequence` instance. For example, we may wish to alternate the value of an `admin` column on a `User` model between `Y` and `N` for each created user:

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Sequence;

    $users = User::factory()
                    ->count(10)
                    ->state(new Sequence(
                        ['admin' => 'Y'],
                        ['admin' => 'N'],
                    ))
                    ->create();

In this example, five users will be created with an `admin` value of `Y` and five users will be created with an `admin` value of `N`.

<a name="factory-relationships"></a>
## Factory Relationships

<a name="relationships-within-definition"></a>
### Relationships Within Definitions

You may attach relationships to models in your factory definitions. For example, if you would like to create a new `User` instance when creating a `Post`, you may do the following:

    use App\Models\User;

    /**
     * Define the model's default state.
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

If the relationship's columns depend on the factory that defines it you may provide a callback which accepts the evaluated attribute array:

    /**
     * Define the model's default state.
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
### Has Many Relationships

Next, let's explore building Eloquent model relationships using Laravel's fluent factory methods. First, let's assume our application has a `User` model and a `Post` model. Also, let's assume that the `User` model defines a `hasMany` relationship with `Post`. We can create a user that has three posts using the `has` method provided by the factory. The `has` method accepts a factory instance:

    use App\Models\Post;
    use App\Models\User;

    $users = User::factory()
                ->has(Post::factory()->count(3))
                ->create();

By convention, when passing a `Post` model to the `has` method, Laravel will assume that the `User` model must have a `posts` method that defines the relationship. If necessary, you may explicitly specify the name of the relationship that you would like to manipulate:

    $users = User::factory()
                ->has(Post::factory()->count(3), 'posts')
                ->create();

Of course, you may perform state manipulations on the related models. In addition, you may pass a Closure based state transformation if your state change requires access to the parent model:

    $users = User::factory()
                ->has(
                    Post::factory()
                            ->count(3)
                            ->state(function (array $attributes, User $user) {
                                return ['user_type' => $user->type];
                            })
                )
                ->create();

#### Using Magic Methods

For convenience, you may use the factory's magic relationship methods to define relationships. For example, the following example will use convention to determine that the related models should be created via a `posts` relationship method on the `User` model:

    $users = User::factory()
                ->hasPosts(3)
                ->create();

When using magic methods to create factory relationships, you may pass an array of attributes to override on the related models:

    $users = User::factory()
                ->hasPosts(3, [
                    'published' => false,
                ])
                ->create();

You may provide a Closure based state transformation if your state change requires access to the parent model:

    $users = User::factory()
                ->hasPosts(3, function (array $attributes, User $user) {
                    return ['user_type' => $user->type];
                })
                ->create();

<a name="belongs-to-relationships"></a>
### Belongs To Relationships

Now that we have explored how to build "has many" relationships using factories, let's explore the inverse of the relationship. The `for` method may be used to define the model that factory created models belong to. For example, we can create three `Post` model instances that belong to a single user:

    use App\Models\Post;
    use App\Models\User;

    $posts = Post::factory()
                ->count(3)
                ->for(User::factory()->state([
                    'name' => 'Jessica Archer',
                ]))
                ->create();

#### Using Magic Methods

For convenience, you may use the factory's magic relationship methods to define "belongs to" relationships. For example, the following example will use convention to determine that the three posts should belong to the `user` relationship on the `Post` model:

    $posts = Post::factory()
                ->count(3)
                ->forUser([
                    'name' => 'Jessica Archer',
                ])
                ->create();

<a name="many-to-many-relationships"></a>
### Many To Many Relationships

Like [has many relationships](#has-many-relationships), "many to many" relationships may be created using the `has` method:

    use App\Models\Role;
    use App\Models\User;

    $users = User::factory()
                ->has(Role::factory()->count(3))
                ->create();

#### Pivot Table Attributes

If you need to define attributes that should be set on the pivot / intermediate table linking the models, you may use the `hasAttached` method. This method accepts an array of pivot table attribute names and values as its second argument:

    use App\Models\Role;
    use App\Models\User;

    $users = User::factory()
                ->hasAttached(
                    Role::factory()->count(3),
                    ['active' => true]
                )
                ->create();

You may provide a Closure based state transformation if your state change requires access to the related model:

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

#### Using Magic Methods

For convenience, you may use the factory's magic relationship methods to define many to many relationships. For example, the following example will use convention to determine that the related models should be created via a `roles` relationship method on the `User` model:

    $users = User::factory()
                ->hasRoles(1, [
                    'name' => 'Editor'
                ])
                ->create();

<a name="polymorphic-relationships"></a>
### Polymorphic Relationships

[Polymorphic relationships](/docs/{{version}}/eloquent-relationships#polymorphic-relationships) may also be created using factories. Polymorphic "morph many" relationships are created in the same way as typical "has many" relationships. For example, if a `Post` model has a `morphMany` relationship with a `Comment` model:

    use App\Models\Post;

    $post = Post::factory()->hasComments(3)->create();

#### Morph To Relationships

Magic methods may not be used to create `morphTo` relationships. Instead, the `for` method must be used directly and the name of the relationship must be explicitly provided. For example, imagine that the `Comment` model has a `commentable` method that defines a `morphTo` relationship. In this situation, we may create three comments that belong to a single post using the `for` method directly:

    $comments = Comment::factory()->count(3)->for(
        Post::factory(), 'commentable'
    )->create();

#### Polymorphic Many To Many Relationships

Polymorphic "many to many" relationships may be created just like non-polymorphic "many to many" relationships:

    use App\Models\Tag;
    use App\Models\Video;

    $users = Video::factory()
                ->hasAttached(
                    Tag::factory()->count(3),
                    ['public' => true]
                )
                ->create();

Of course, the magic `has` method may also be used to create polymorphic "many to many" relationships:

    $users = Video::factory()
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
