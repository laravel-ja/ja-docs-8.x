# Eloquent:リレーション

- [イントロダクション](#introduction)
- [リレーションの定義](#defining-relationships)
    - [１対１](#one-to-one)
    - [１対多](#one-to-many)
    - [１対多（逆）／所属](#one-to-many-inverse)
    - [Has One Through](#has-one-through)
    - [Has Many Through](#has-many-through)
- [多対多リレーション](#many-to-many)
    - [中間テーブルカラムの取得](#retrieving-intermediate-table-columns)
    - [中間テーブルのカラムを使った関係のフィルタリング](#filtering-queries-via-intermediate-table-columns)
    - [カスタム中間テーブルモデルの定義](#defining-custom-intermediate-table-models)
- [ポリモーフィックリレーション](#polymorphic-relationships)
    - [１対１](#one-to-one-polymorphic-relations)
    - [１対多](#one-to-many-polymorphic-relations)
    - [多対多](#many-to-many-polymorphic-relations)
    - [カスタムポリモーフィックタイプ](#custom-polymorphic-types)
- [動的リレーション](#dynamic-relationships)
- [リレーションのクエリ](#querying-relations)
    - [リレーションメソッド 対 動的プロパティ](#relationship-methods-vs-dynamic-properties)
    - [リレーションの存在のクエリ](#querying-relationship-existence)
    - [存在しないリレーションのクエリ](#querying-relationship-absence)
    - [Morph Toリレーションのクエリ](#querying-morph-to-relationships)
- [関連するモデルの集計](#aggregating-related-models)
    - [関連モデルのカウント](#counting-related-models)
    - [その他の集計関数](#other-aggregate-functions)
    - [Morph Toリレーションの関連モデルのカウント](#counting-related-models-on-morph-to-relationships)
- [Eagerロード](#eager-loading)
    - [Eagerロードの制約](#constraining-eager-loads)
    - [遅延Eagerロード](#lazy-eager-loading)
- [関連モデルの挿入と更新](#inserting-and-updating-related-models)
    - [`save`メソッド](#the-save-method)
    - [`create`メソッド](#the-create-method)
    - [Belongs Toリレーション](#updating-belongs-to-relationships)
    - [多対多リレーション](#updating-many-to-many-relationships)
- [親のタイムスタンプの更新](#touching-parent-timestamps)

<a name="introduction"></a>
## イントロダクション

多くの場合、データベーステーブルは相互に関連（リレーション）しています。たとえば、ブログ投稿に多くのコメントが含まれている場合や、注文がそれを行ったユーザーと関連している場合があります。Eloquentはこれらの関係の管理と操作を容易にし、さまざまな一般的な関係をサポートします。

<div class="content-list" markdown="1">
- [１対１](#one-to-one)
- [１対多](#one-to-many)
- [多対多](#many-to-many)
- [Has One Through](#has-one-through)
- [Has Many Through](#has-many-through)
- [１対１（ポリモーフィック）](#one-to-one-polymorphic-relations)
- [１対多（ポリモーフィック）](#one-to-many-polymorphic-relations)
- [多対多（ポリモーフィック）](#many-to-many-polymorphic-relations)
</div>

<a name="defining-relationships"></a>
## リレーションの定義

Eloquentリレーションは、Eloquentモデルクラスのメソッドとして定義します。リレーションは強力な[クエリビルダ](/docs/{{version}}/querys)としても機能するため、リレーションをメソッドとして定義すると、強力なメソッドチェーンとクエリ機能が使用できます。たとえば以下のように、`posts`リレーションに追加のクエリ制約をチェーンできます。

    $user->posts()->where('active', 1)->get();

ただし、リレーションの使用について深く掘り下げる前に、Eloquentがサポートしている各タイプのリレーションを定義する方法を学びましょう。

<a name="one-to-one"></a>
### １対１

１対１の関係はもっとも基本的なタイプのデータベースリレーションです。たとえば、`User`モデルが1つの`Phone`モデルに関連付けられている場合があります。この関係を定義するために、`User`モデルに`phone`メソッドを配置します。`phone`メソッドは`hasOne`メソッドを呼び出し、その結果を返す必要があります。`hasOne`メソッドは、モデルの`Illuminate\Database\Eloquent\Model`基本クラスを介してモデルで使用可能です。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーに関連している電話の取得
         */
        public function phone()
        {
            return $this->hasOne(Phone::class);
        }
    }

`hasOne`メソッドに渡される最初の引数は、関連するモデルクラスの名前です。関係を定義すると、Eloquentの動的プロパティを使用して関連レコードを取得できます。動的プロパティを使用すると、モデル上で定義しているプロパティのように、リレーションメソッドへアクセスできます。

    $phone = User::find(1)->phone;

Eloquentは、親モデル名に基づきリレーションの外部キーを決定します。この場合、`Phone`モデルは自動的に`user_id`外部キーを持っているとみなします。この規約をオーバーライドしたい場合は、`hasOne`メソッドに２番目の引数を渡します。

    return $this->hasOne(Phone::class, 'foreign_key');

さらに、Eloquentは、外部キーの値が親の主キーカラムに一致すると想定しています。つまり、Eloquentは、`Phone`レコードの`user_id`カラムでユーザーの`id`カラムの値を検索します。リレーションで`id`またはモデルの`$primaryKey`プロパティ以外の主キー値を使用する場合は、３番目の引数を`hasOne`メソッドに渡してください。

    return $this->hasOne(Phone::class, 'foreign_key', 'local_key');

<a name="one-to-one-defining-the-inverse-of-the-relationship"></a>
#### 逆の関係の定義

`User`モデルから`Phone`モデルへアクセスできるようになりました。次に、電話の所有ユーザーへアクセスできるようにする`Phone`モデルの関係を定義しましょう。`belongsTo`メソッドを使用して`hasOne`関係の逆を定義できます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Phone extends Model
    {
        /**
         * この電話を所有しているユーザーの取得
         */
        public function user()
        {
            return $this->belongsTo(User::class);
        }
    }

`user`メソッドを呼び出し時に、Eloquentは`Phone`モデルの`user_id`カラムと一致する`id`を持つ`User`モデルを見つけようとします。

Eloquentは、リレーションメソッドの名前を調べ、メソッド名の末尾に`_id`を付けることにより、外部キー名を決定します。したがって、この場合、Eloquentは`Phone`モデルに`user_id`カラムがあると想定します。ただし、`Phone`モデルの外部キーが`user_id`でない場合は、カスタムキー名を`belongsTo`メソッドの２番目の引数として渡してください。

    /**
     * この電話を所有しているユーザーの取得
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'foreign_key');
    }

親モデルが主キーとして`id`を使用しない場合、または別のカラムを使用して関連モデルを検索する場合は、`belongsTo`メソッドへ親テーブルのカスタムキーを指定する３番目の引数を渡してください。

    /**
     * この電話を所有しているユーザーの取得
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'foreign_key', 'owner_key');
    }

<a name="one-to-many"></a>
### １対多

１対多の関係は、単一のモデルが1つ以上の子モデルの親である関係を定義するために使用されます。たとえば、ブログ投稿はいくつもコメントを持つ場合があります。他のすべてのEloquent関係と同様に、１対多の関係はEloquentモデルでメソッドを定義することにより定義します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Post extends Model
    {
        /**
         * ブログポストのコメントを取得
         */
        public function comments()
        {
            return $this->hasMany(Comment::class);
        }
    }

Eloquentは、`Comment`モデルの適切な外部キーカラムを自動的に決定することを覚えておいてください。規約により、Eloquentは親モデルの「スネークケース」名に「_id」という接尾辞を付けます。したがって、この例では、Eloquentは`Comment`モデルの外部キーカラムが`post_id`であると想定します。

リレーションメソッドを定義したら、`comments`プロパティにアクセスして、関連するコメントの[コレクション](/docs/{{version}}/eloquent-collections)にアクセスできます。Eloquentは「動的リレーションプロパティ」を提供するため、モデルのプロパティとして定義されているかのようにリレーションメソッドにアクセスできることを思い出してください。

    use App\Models\Post;

    $comments = Post::find(1)->comments;

    foreach ($comments as $comment) {
        //
    }

すべての関係はクエリビルダとしても機能するため、`comments`メソッドを呼び出し、クエリに条件をチェーンし続けて、リレーションのクエリへさらに制約を追加できます。

    $comment = Post::find(1)->comments()
                        ->where('title', 'foo')
                        ->first();

`hasOne`メソッドと同様に、`hasMany`メソッドに追加の引数を渡すことにより、外部キーとローカルキーをオーバーライドすることもできます。

    return $this->hasMany(Comment::class, 'foreign_key');

    return $this->hasMany(Comment::class, 'foreign_key', 'local_key');

<a name="one-to-many-inverse"></a>
### １対多（逆）／所属

投稿のすべてのコメントへアクセスできるようになったので、今度はコメントからその親投稿へアクセスできるようにする関係を定義しましょう。`hasMany`関係の逆を定義するには、`belongsTo`メソッドを呼び出す子モデルで関係メソッドを定義します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Comment extends Model
    {
        /**
         * コメントを所有している投稿を取得
         */
        public function post()
        {
            return $this->belongsTo(Post::class);
        }
    }

リレーションを定義したら、`post`の「動的リレーションプロパティ」にアクセスして、コメントの親投稿を取得できます。

    use App\Models\Comment;

    $comment = Comment::find(1);

    return $comment->post->title;

上記の例でEloquentは、`Comment`モデルの`post_id`カラムと一致する`id`を持つ`Post`モデルを見つけようとします。

Eloquentはリレーションメソッドの名前を調べ、メソッド名の末尾に"_"を付けてから、親モデルの主キーカラムの名前を付けることにより、デフォルトの外部キー名を決定します。したがって、この例では、Eloquentは`comments`テーブルの`Post`モデルへの外部キーが`post_id`であると想定します。

ただし、リレーションの外部キーがこの規約に従わない場合は、カスタム外部キー名を`belongsTo`メソッドの２番目の引数へ指定できます。

    /**
     * コメントを所有している投稿を取得
     */
    public function post()
    {
        return $this->belongsTo(Post::class, 'foreign_key');
    }

親モデルが主キーとして`id`を使用していない場合、または別のカラムを使用して関連モデルを検索する場合は、`belongsTo`メソッドへ親テーブルのカスタムキーを指定する３番目の引数を渡せます。

    /**
     * コメントを所有している投稿を取得
     */
    public function post()
    {
        return $this->belongsTo(Post::class, 'foreign_key', 'owner_key');
    }

<a name="default-models"></a>
#### デフォルトモデル

`belongsTo`、`hasOne`、`hasOneThrough`、`morphOne`リレーションを使用する場合、指定する関係が`null`の場合に返すデフォルトモデルを定義できます。このパターンは、[Nullオブジェクトパターン](https://en.wikipedia.org/wiki/Null_Object_pattern)と呼ばれることが多く、コード内の条件付きチェックを省略するのに役立ちます。以下の例では、`Post`モデルにユーザーがアタッチされていない場合、`user`リレーションは空の`App\Models\User`モデルを返します。

    /**
     * 投稿の作成者を取得
     */
    public function user()
    {
        return $this->belongsTo(User::class)->withDefault();
    }

デフォルトモデルに属性を設定するには、配列またはクロージャを`withDefault`メソッドに渡します。

    /**
     * 投稿の作成者を取得
     */
    public function user()
    {
        return $this->belongsTo(User::class)->withDefault([
            'name' => 'Guest Author',
        ]);
    }

    /**
     * 投稿の作成者を取得
     */
    public function user()
    {
        return $this->belongsTo(User::class)->withDefault(function ($user, $post) {
            $user->name = 'Guest Author';
        });
    }

<a name="has-one-through"></a>
### Has One Through

"has-one-through"リレーションは、別のモデルとの１対１の関係を定義します。ただし、この関係は、３番目のモデルを仲介（**through**）に使うことで、宣言するモデルと別のモデルの１インスタンスとマッチさせることを意味します。

たとえば、自動車修理工場のアプリケーションでは、各「整備士（`Mechanic`）」モデルを１つの「自動車（`Car`）」モデルに関連付け、各「自動車」モデルを１つの「所有者（`Owner`）」モデルに関連付けることができます。整備士と所有者はデータベース内で直接の関係はありませんが、整備士は「車」モデルを介して所有者にアクセスできます。この関係を定義するために必要なテーブルを見てみましょう。

    mechanics
        id - integer
        name - string

    cars
        id - integer
        model - string
        mechanic_id - integer

    owners
        id - integer
        name - string
        car_id - integer

リレーションのテーブル構造を調べたので、`Mechanic`モデルで関係を定義しましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Mechanic extends Model
    {
        /**
         * 車の所有者を取得
         */
        public function carOwner()
        {
            return $this->hasOneThrough(Owner::class, Car::class);
        }
    }

`hasOneThrough`メソッドに渡す、最初の引数はアクセスする最終モデルの名前であり、２番目の引数は中間モデルの名前です。

<a name="has-one-through-key-conventions"></a>
#### キーの規約

リレーションのクエリ実行時は、一般的にEloquent外部キー規約を使用します。リレーションのキーをカスタマイズする場合は、それらを３番目と４番目の引数として`hasOneThrough`メソッドに渡してください。３番目の引数は、中間モデルの外部キーの名前です。４番目の引数は、最終モデルの外部キーの名前です。５番目の引数はローカルキーであり、６番目の引数は中間モデルのローカルキーです。

    class Mechanic extends Model
    {
        /**
         * 車の所有者を取得
         */
        public function carOwner()
        {
            return $this->hasOneThrough(
                Owner::class,
                Car::class,
                'mechanic_id', // carsテーブルの外部キー
                'car_id', // ownersテーブルの外部キー
                'id', // mechanicsテーブルのローカルキー
                'id' // carsテーブルのローカルキー
            );
        }
    }

<a name="has-many-through"></a>
### Has Many Through

"has-many-through"関係は、中間関係を介して離れた関係へアクセスするための便利な方法を提供します。たとえば、[Laravel Vapor](https://vapor.laravel.com)のようなデプロイメントプラットフォームを構築していると仮定しましょう。`Project`モデルは、中間の環境（`Environment`）モデルを介して多くの`Deployment`モデルにアクセスする可能性があります。この例では、特定の環境のすべてのデプロイメントを簡単に収集できます。この関係を定義するために必要なテーブルを見てみましょう。

    projects
        id - integer
        name - string

    environments
        id - integer
        project_id - integer
        name - string

    deployments
        id - integer
        environment_id - integer
        commit_hash - string

リレーションのテーブル構造を調べたので、`Project`モデルでリレーションを定義しましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Project extends Model
    {
        /**
         * プロジェクトのすべてのデプロイメントを取得
         */
        public function deployments()
        {
            return $this->hasManyThrough(Deployment::class, Environment::class);
        }
    }

`hasManyThrough`メソッドへ渡たす、最初の引数はアクセスする最終モデルの名前であり、２番目の引数は中間モデルの名前です。

`Deployment`モデルのテーブルは`project_id`カラムを含んでいませんが、`hasManyThrough`リレーションは、`$project->deployments`を介してプロジェクトのデプロイメントへのアクセスを提供します。これらのモデルを取得するために、Eloquentは中間の`Environment`モデルのテーブルの`project_id`カラムを検査します。関連した環境IDを見つけ、それらを使用して`Deployment`モデルのテーブルをクエリします。

<a name="has-many-through-key-conventions"></a>
#### キーの規約

リレーションのクエリを実行するときは、Eloquent外部キー規約を一般的に使用します。リレーションのキーをカスタマイズする場合は、それらを３番目と４番目の引数として`hasManyThrough`メソッドに渡たしてください。３番目の引数は、中間モデルの外部キーの名前です。４番目の引数は、最終モデルの外部キーの名前です。５番目の引数はローカルキーであり、６番目の引数は中間モデルのローカルキーです。

    class Project extends Model
    {
        public function deployments()
        {
            return $this->hasManyThrough(
                Deployment::class,
                Environment::class,
                'project_id', // environmentsテーブルの外部キー
                'environment_id', // deploymentsテーブルの外部キー
                'id', // projectsテーブルのローカルキー
                'id' // environmentsテーブルのローカルキー
            );
        }
    }

<a name="many-to-many"></a>
## 多対多リレーション

多対多の関係は、`hasOne`および`hasMany`の関係よりも少し複雑です。多対多の関係の一例は、多くの役割を持つユーザーであり、役割はアプリケーション内の他のユーザーと共有している場合です。たとえば、あるユーザーに「作成者（Author）」と「編集者（Editor）」の役割を割り当てることができます。ただし、これらの役割は他のユーザーにも割り当てる場合があります。したがって、あるユーザーには多くの役割があり、ある役割には多くのユーザーがいます。

<a name="many-to-many-table-structure"></a>
#### テーブル構造

この関係を定義するには、`users`、`roles`、および`role_user`の３つのデータベーステーブルが必要です。`role_user`テーブルは、関連モデル名のアルファベット順を由来としており、`user_id`カラムと`role_id`カラムを含みます。このテーブルは、ユーザーと役割をリンクする中間テーブルとして使用します。

役割は多くのユーザーに属することができるため、単に`user_id`カラムを`roles`テーブルに配置することはできません。そうすることは、役割が１人のユーザーにのみ属することができることを意味します。複数のユーザーに割り当てられている役割（`role`）をサポートするには、`role_user`テーブルが必要です。リレーションのテーブル構造は次のように要約できます。

    users
        id - integer
        name - string

    roles
        id - integer
        name - string

    role_user
        user_id - integer
        role_id - integer

<a name="many-to-many-model-structure"></a>
#### モデル構造

多対多の関係は、`belongsToMany`メソッドの結果を返すメソッドを作成して定義します。`belongsToMany`メソッドは、アプリケーションのすべてのEloquentモデルで使用している`Illuminate\Database\Eloquent\Model`基本クラスが提供しています。例として、`User`モデル上の`roles`メソッドを定義してみましょう。このメソッドへ渡す最初の引数は、関連するモデルクラスの名前です。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * このユーザーに属する役割
         */
        public function roles()
        {
            return $this->belongsToMany(Role::class);
        }
    }

リレーションを定義したら、`roles`動的リレーションプロパティを使用してユーザーの役割へアクセスできます。

    use App\Models\User;

    $user = User::find(1);

    foreach ($user->roles as $role) {
        //
    }

すべてのリレーションはクエリビルダとしても機能するため、`roles`メソッドを呼び出し、クエリに条件をチェーンによりつなげることで、リレーションのクエリへさらに制約を追加できます。

    $roles = User::find(1)->roles()->orderBy('name')->get();

リレーションの中間テーブルのテーブル名を決定するために、Eloquentは２つの関連するモデル名をアルファベット順に結合します。ただし、この規約は自由に上書きできます。その場合、２番目の引数を`belongsToMany`メソッドに渡します。

    return $this->belongsToMany(Role::class, 'role_user');

中間テーブルの名前をカスタマイズすることに加えて、`belongsToMany`メソッドへ追加の引数を渡し、テーブルのキーのカラム名をカスタマイズすることもできます。３番目の引数は、関係を定義しているモデルの外部キー名であり、４番目の引数は、関連付けるモデルの外部キー名です。

    return $this->belongsToMany(Role::class, 'role_user', 'user_id', 'role_id');

<a name="many-to-many-defining-the-inverse-of-the-relationship"></a>
#### 逆の関係の定義

多対多の関係の「逆」を定義するには、関連モデルでメソッドを定義する必要があります。このメソッドは、`belongsToMany`メソッドの結果も返します。ユーザー／ロールの例を完成させるために、`Role`モデルで`users`メソッドを定義しましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Role extends Model
    {
        /**
         * この役割に属するユーザー
         */
        public function users()
        {
            return $this->belongsToMany(User::class);
        }
    }

ご覧のとおり。関係は、`App\Models\User`モデルを参照することを除いて、対応する`User`モデルとまったく同じように定義されています。`belongsToMany`メソッドを再利用しているため、多対多の関係の「逆」を定義するときにも、通常のテーブルとキーのカスタマイズオプションをすべて使用できます。

<a name="retrieving-intermediate-table-columns"></a>
### 中間テーブルカラムの取得

すでに学んだように、多対多の関係を扱うには、中間テーブルの存在が必要です。Eloquentは、このテーブルを操作するのに役立つ手段をいくつか提供しています。たとえば、`User`モデルに関連する`Role`モデルがたくさんあるとしましょう。この関係にアクセスした後、モデルの`pivot`属性を使用して中間テーブルにアクセスできます。

    use App\Models\User;

    $user = User::find(1);

    foreach ($user->roles as $role) {
        echo $role->pivot->created_at;
    }

取得する各`Role`モデルには自動的に`pivot`属性が割り当てられることに注意してください。この属性には、中間テーブルを表すモデルが含まれています。

デフォルトでは、モデルキーのみが`pivot`モデルに存在します。中間テーブルに追加の属性を含めている場合は、関係を定義するときにそうした属性を指定する必要があります。

    return $this->belongsToMany(Role::class)->withPivot('active', 'created_by');

中間テーブルへEloquentが自動的に維持する`created_at`および`updated_at`タイムスタンプを持たせたい場合は、関係を定義するときに`withTimestamps`メソッドを呼び出します。

    return $this->belongsToMany(Role::class)->withTimestamps();

> {note} Eloquentが自動で維持するタイムスタンプを利用する中間テーブルには、`created_at`と`updated_at`両方のタイムスタンプカラムが必要です。

<a name="customizing-the-pivot-attribute-name"></a>
#### `pivot`属性名のカスタマイズ

前述のように、中間テーブルの属性はモデルの`pivot`属性を介してアクセスできます。この属性の名前は、アプリケーション内での目的をより適切に反映するため、自由にカスタマイズできます。

たとえば、アプリケーションにポッドキャストを購読する可能性のあるユーザーが含まれている場合、ユーザーとポッドキャストの間には多対多の関係があるでしょう。この場合、中間テーブル属性の名前を`pivot`ではなく`subscription`に変更することを推奨します。リレーションを定義するときに`as`メソッドを使用して指定できます。

    return $this->belongsToMany(Podcast::class)
                    ->as('subscription')
                    ->withTimestamps();

カスタム中間テーブル属性を指定し終えると、カスタマイズした名前を使用して中間テーブルのデータへアクセスできます。

    $users = User::with('podcasts')->get();

    foreach ($users->flatMap->podcasts as $podcast) {
        echo $podcast->subscription->created_at;
    }

<a name="filtering-queries-via-intermediate-table-columns"></a>
### 中間テーブルのカラムを使った関係のフィルタリング

リレーションを定義するときに、`wherePivot`、`wherePivotIn`、`wherePivotNotIn`メソッドを使用し、`belongsToMany`関係クエリによって返される結果をフィルタリングすることもできます。

    return $this->belongsToMany(Role::class)
                    ->wherePivot('approved', 1);

    return $this->belongsToMany(Role::class)
                    ->wherePivotIn('priority', [1, 2]);

    return $this->belongsToMany(Role::class)
                    ->wherePivotNotIn('priority', [1, 2]);

<a name="defining-custom-intermediate-table-models"></a>
### カスタム中間テーブルモデルの定義

多対多の関係の中間（ピボット）テーブルを表すカスタムモデルを定義する場合は、関係定義時に`using`メソッドを呼び出してください。カスタムピボットモデルを使用すると、ピボットモデルに追加のメソッドを定義できます。

カスタムの多対多ピボットモデルは`Illuminate\Database\Eloquent\Relationships\Pivot`クラス、カスタムのポリモーフィック多対多ピボットモデルは`Illuminate\Database\Eloquent\Relationships\MorphPivot`クラスを拡張する必要があります。たとえば、カスタムの`RoleUser`ピボットモデルを使用する`Role`モデルを定義してみましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Role extends Model
    {
        /**
         * この役割に属するユーザー
         */
        public function users()
        {
            return $this->belongsToMany(User::class)->using(RoleUser::class);
        }
    }

`RoleUser`モデルを定義するときは、`Illuminate\Database\Eloquent\Relationships\Pivot`クラスを拡張する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Relations\Pivot;

    class RoleUser extends Pivot
    {
        //
    }

> {note} ピボットモデルは`SoftDeletes`トレイトを使用できません。ピボットレコードをソフト削除する必要がある場合は、ピボットモデルを実際のEloquentモデルに変換することを検討してください。

<a name="custom-pivot-models-and-incrementing-ids"></a>
#### カスタムピボットモデルと増分ID

カスタムピボットモデルを使用する多対多の関係を定義し、そのピボットモデルに自動増分の主キーがある場合は、カスタムピボットモデルクラスで`incrementing`プロパティを確実に`true`に設定指定してください。

    /**
     * IDの自動増分を指定する
     *
     * @var bool
     */
    public $incrementing = true;

<a name="polymorphic-relationships"></a>
## ポリモーフィックリレーション

ポリモーフィックリレーションにより、子モデルは単一の関連を使用して複数タイプのモデルに属せます。たとえば、ユーザーがブログの投稿やビデオを共有できるようにするアプリケーションを構築しているとします。このようなアプリケーションで、`Comment`モデルは`Post`モデルと`Video`モデルの両方に属する可能性があります。

<a name="one-to-one-polymorphic-relations"></a>
### １対１（ポリモーフィック）

<a name="one-to-one-polymorphic-table-structure"></a>
#### テーブル構造

１対１のポリモーフィックリレーションは、一般的な１対１の関係に似ています。ただし、子モデルは単一の関連付けを使用して複数タイプのモデルへ所属できます。たとえば、ブログの`Post`と`User`は、`Image`モデルとポリモーフィックな関係を共有することがあります。１対１のポリモーフィックな関係を使用すると、投稿やユーザーに関連するひとつの画像の単一のテーブルを作成できます。まず、テーブルの構造を調べてみましょう。

    posts
        id - integer
        name - string

    users
        id - integer
        name - string

    images
        id - integer
        url - string
        imageable_id - integer
        imageable_type - string

`images`テーブルの`imageable_id`カラムと`imageable_type`カラムに注意してください。`imageable_id`カラムには投稿またはユーザーのID値が含まれ、`imageable_type`カラムには親モデルのクラス名が含まれます。`imageable_type`カラムは、`imageable`リレーションへのアクセス時に返す親モデルの「タイプ」を決めるため、Eloquentが使用します。この場合、カラムには`App\Models\Post`か`App\Models\User`のどちらかが入ります。

<a name="one-to-one-polymorphic-model-structure"></a>
#### モデル構造

次に、この関係を構築するために必要なモデルの定義を見てみましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Image extends Model
    {
        /**
         * 親のimageableなモデル（ユーザー／投稿）の取得
         */
        public function imageable()
        {
            return $this->morphTo();
        }
    }

    class Post extends Model
    {
        /**
         * 投稿の画像を取得
         */
        public function image()
        {
            return $this->morphOne(Image::class, 'imageable');
        }
    }

    class User extends Model
    {
        /**
         * ユーザーの画像を取得
         */
        public function image()
        {
            return $this->morphOne(Image::class, 'imageable');
        }
    }

<a name="one-to-one-polymorphic-retrieving-the-relationship"></a>
#### リレーションの取得

データベーステーブルとモデルを定義すると、モデルを介してリレーションへアクセスできます。たとえば、投稿の画像を取得するには、`image`動的リレーションプロパティにアクセスします。

    use App\Models\Post;

    $post = Post::find(1);

    $image = $post->image;

`morphTo`の呼び出しを実行するメソッドの名前にアクセスすることで、ポリモーフィックモデルの親を取得できます。この場合、`Image`モデルの`imageable`メソッドです。つまり、動的なリレーションプロパティとしてこのメソッドにアクセスします。

    use App\Models\Image;

    $image = Image::find(1);

    $imageable = $image->imageable;

`Image`モデルの`imageable`リレーションは、どのタイプのモデルがその画像を所有しているかに応じて、`Post`または`User`インスタンスを返します。

<a name="morph-one-to-one-key-conventions"></a>
#### キーの規約

必要に応じて、ポリモーフィックの子モデルで使用する"id"カラムと"type"カラムの名前をカスタマイズできます。その場合は、最初の引数として常にリレーション名を`morphTo`メソッドに渡してください。通常、この値はメソッド名と一致する必要があるため、PHPの`__FUNCTION__`定数を使用できます。

    /**
     * 画像が属するモデルを取得
     */
    public function imageable()
    {
        return $this->morphTo(__FUNCTION__, 'imageable_type', 'imageable_id');
    }

<a name="one-to-many-polymorphic-relations"></a>
### １対多（ポリモーフィック）

<a name="one-to-many-polymorphic-table-structure"></a>
#### テーブル構造

１対多のポリモーフィックリレーションは、一般的な１対多の関係に似ています。ただし、子モデルは単一のリレーションを使用して複数タイプのモデルに所属できます。たとえば、アプリケーションのユーザーが投稿やビデオに「コメント」できると想像してみてください。ポリモーフィックリレーションを使えば、投稿とビデオの両方のコメントを含めるため、`comments`テーブル一つだけの使用ですみます。まず、この関係を構築するために必要なテーブル構造を調べてみましょう。

    posts
        id - integer
        title - string
        body - text

    videos
        id - integer
        title - string
        url - string

    comments
        id - integer
        body - text
        commentable_id - integer
        commentable_type - string

<a name="one-to-many-polymorphic-model-structure"></a>
#### モデル構造

次に、この関係を構築するために必要なモデル定義を確認しましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Comment extends Model
    {
        /**
         * commentableな親モデルの取得（投稿かビデオ）
         */
        public function commentable()
        {
            return $this->morphTo();
        }
    }

    class Post extends Model
    {
        /**
         * このポストの全コメント取得
         */
        public function comments()
        {
            return $this->morphMany(Comment::class, 'commentable');
        }
    }

    class Video extends Model
    {
        /**
         * このビデオの全コメント取得
         */
        public function comments()
        {
            return $this->morphMany(Comment::class, 'commentable');
        }
    }

<a name="one-to-many-polymorphic-retrieving-the-relationship"></a>
#### リレーションの取得

データベーステーブルとモデルを定義したら、モデルの動的リレーションプロパティを介して関係へアクセスできます。たとえば、その投稿のすべてのコメントにアクセスするには、`comments`動的プロパティを使用できます。

    use App\Models\Post;

    $post = Post::find(1);

    foreach ($post->comments as $comment) {
        //
    }

`morphTo`を呼び出し実行するメソッドの名前にアクセスすることで、ポリモーフィックな子モデルの親を取得することもできます。この場合、それは`Comment`モデルの`commentable`メソッドです。では、コメントの親モデルへアクセスするために、動的リレーションプロパティとしてこのメソッドにアクセスしてみましょう。

    use App\Models\Comment;

    $comment = Comment::find(1);

    $commentable = $comment->commentable;

`Comment`モデルの`commentable`リレーションは、コメントの親であるモデルのタイプに応じて、`Post`または`Video`インスタンスのいずれかを返します。

<a name="many-to-many-polymorphic-relations"></a>
### 多対多（ポリモーフィック）

<a name="many-to-many-polymorphic-table-structure"></a>
#### テーブル構造

多対多のポリモーフィックリレーションは、"morph one"と"morph manyリレーションよりも少し複雑です。たとえば、`Post`モデルと`Video`モデルは、`Tag`モデルとポリモーフィックな関係を共有できます。この状況で多対多のポリモーフィックリレーションを使用すると、アプリケーションで一意のタグのテーブルを一つ用意するだけで、投稿やビデオにそうしたタグを関係づけられます。まず、この関係を構築するために必要なテーブル構造を見てみましょう。

    posts
        id - integer
        name - string

    videos
        id - integer
        name - string

    tags
        id - integer
        name - string

    taggables
        tag_id - integer
        taggable_id - integer
        taggable_type - string

> {tip} ポリモーフィックな多対多のリレーションへに飛び込む前に、典型的な[多対多の関係](#many-to-many)に関するドキュメントを読むとよいでしょう。

<a name="many-to-many-polymorphic-model-structure"></a>
#### モデル構造

これで、モデルの関係を定義する準備ができました。`Post`モデルと`Video`モデルの両方に、基本のEloquentモデルクラスによって提供される`morphToMany`メソッドを呼び出す`tags`メソッドを定義します。

`morphToMany`メソッドは、関連モデルの名前と「リレーション名」を引数に取ります。中間テーブル名へ割り当てた名前とそれが持つキーに基づき、"taggable"と言う名前のリレーションで参照します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Post extends Model
    {
        /**
         * 投稿のすべてのタグを取得
         */
        public function tags()
        {
            return $this->morphToMany(Tag::class, 'taggable');
        }
    }

<a name="many-to-many-polymorphic-defining-the-inverse-of-the-relationship"></a>
#### 逆の関係の定義

次に、`Tag`モデルで、親になる可能性があるモデルごとにメソッドを定義する必要があります。したがって、この例では`posts`メソッドと`videos`メソッドを定義します。これらのメソッドは両方とも、`morphedByMany`メソッドの結果を返す必要があります。

`morphedByMany`メソッドは、関連モデルの名前と「リレーション名」を引数に取ります。中間テーブル名へ付けた名前とそれが持つキーに基づいて、"taggable"と言う名前のリレーションで参照します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Tag extends Model
    {
        /**
         * このタグを割り当てているすべての投稿を取得
         */
        public function posts()
        {
            return $this->morphedByMany(Post::class, 'taggable');
        }

        /**
         * このタグを割り当てているすべての動画を取得
         */
        public function videos()
        {
            return $this->morphedByMany(Video::class, 'taggable');
        }
    }

<a name="many-to-many-polymorphic-retrieving-the-relationship"></a>
#### リレーションの取得

データベーステーブルとモデルを定義したら、モデルを介してリレーションへアクセスできます。たとえば、ある投稿のすべてのタグにアクセスするには、`tags`動的リレーションプロパティを使用します。

    use App\Models\Post;

    $post = Post::find(1);

    foreach ($post->tags as $tag) {
        //
    }

`morphedByMany`を呼び出し実行するメソッドの名前へアクセスすることで、ポリモーフィックな子モデルからポリモーフィックリレーションの親を取得できます。今回の場合、`Tag`モデルの`posts`と`videos`メソッドです。

    use App\Models\Tag;

    $tag = Tag::find(1);

    foreach ($tag->posts as $post) {
        //
    }

    foreach ($tag->videos as $video) {
        //
    }

<a name="custom-polymorphic-types"></a>
### カスタムポリモーフィックタイプ

デフォルトでLaravelは、完全修飾クラス名を使用して関連モデルの"type"を格納します。たとえば、`Comment`モデルが`Post`または`Video`モデルに属する可能性がある前記の１対多関係の例では、デフォルトの`commentable_type`は`App\Models\Post`か`App\Models\Video`のいずれかになります。ただし、これらの値をアプリケーションの内部構造から切り離したい場合も起きるでしょう。

たとえば、モデル名を"type"として使用する代わりに、`post`や`video`などの単純な文字列を使用したい場合もあります。これにより、モデル名が変更されても、データベース内のポリモーフィックな「タイプ」カラムの値は有効なままになります。

    use Illuminate\Database\Eloquent\Relations\Relation;

    Relation::morphMap([
        'post' => 'App\Models\Post',
        'video' => 'App\Models\Video',
    ]);

必要に応じ、`App\Providers\AppServiceProvider`クラスの`boot`関数で`morphMap`を登録するか、別のサービスプロバイダを作成することも可能です。

モデルの`getMorphClass`メソッドを使用して、実行時に指定したモデルのポリモーフィックのエイリアスを取得できます。逆に、`Relation::getMorphedModel`メソッドを使用して、ポリモーフィックのエイリアスへ関連付けた完全修飾クラス名を取得もできます。

    use Illuminate\Database\Eloquent\Relations\Relation;

    $alias = $post->getMorphClass();

    $class = Relation::getMorphedModel($alias);

> {note} 既存のアプリケーションに「ポリモーフィックのマップ」を適用する場合、ポリモーフィックリレーションで使用していたそれまでの、完全修飾クラスを含むデータベース内の`*_type`カラム値はすべて、「マップ」名に変換する必要が起きます。

<a name="dynamic-relationships"></a>
### 動的リレーション

`resolveRelationUsing`メソッドを使用して、実行時にEloquentモデル間のリレーションを定義できます。通常のアプリケーション開発には推奨しませんが、Laravelパッケージの開発時には役立つでしょう。

`resolveRelationUsing`メソッドは、最初の引数に付けたいリレーション名を引数に取ります。メソッドの２番目の引数は、モデルインスタンスを引数に取り、有効なEloquenリレーションの定義を返すクロージャです。通常、[サービスプロバイダ](/docs/{{version}}/provider)のbootメソッド内で動的リレーションを設定する必要があります。

    use App\Models\Order;
    use App\Models\Customer;

    Order::resolveRelationUsing('customer', function ($orderModel) {
        return $orderModel->belongsTo(Customer::class, 'customer_id');
    });

> {note} 動的リレーションを定義するときは、常に明示的にキー名引数をEloquentリレーションメソッドの引数に渡してください。

<a name="querying-relations"></a>
## リレーションのクエリ

すべてのEloquentリレーションはメソッドを使い定義するので、関連モデルをロードするクエリを実際に実行しなくても、リレーションのインスタンスを取得するための、こうしたメソッドを呼び出しできます。さらに、すべてのタイプのEloquentリレーションは、[クエリビルダ](/docs/{{version}}/querys)としても機能するため、データベースに対してSQLクエリを最終的に実行する前に、リレーションクエリに制約を連続してチェーンできます。

たとえば、`User`モデルに多くの`Post`モデルが関連付けられているブログアプリケーションを想像してみてください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーのすべての投稿を取得
         */
        public function posts()
        {
            return $this->hasMany(Post::class);
        }
    }

`posts`リレーションをクエリし、次のように関係に制約を追加できます。

    use App\Models\User;

    $user = User::find(1);

    $user->posts()->where('active', 1)->get();

リレーションではLaravel[クエリビルダ](/docs/{{version}}/queryes)メソッドのどれでも使用できるので、クエリビルダのドキュメントを調べ、使用可能な全メソッドを習んでください。

<a name="chaining-orwhere-clauses-after-relationships"></a>
#### リレーションの後へ`orWhere`句をチェーン

上記の例で示したように、リレーションを照会するときは、その関係に制約を自由に追加できます。ただし、`orWhere`句をリレーションにチェーンする場合には注意が必要です。これは、`orWhere`句がリレーション制約と同じレベルで論理的にグループ化されるためです。

    $user->posts()
            ->where('active', 1)
            ->orWhere('votes', '>=', 100)
            ->get();

上記の例は、以下のSQLを生成します。ご覧のとおり、`or`句は、100票を超える**全**ユーザーを返すようにクエリに指示します。クエリは特定のユーザーに制約されなくなりました。

```sql
select *
from posts
where user_id = ? and active = 1 or votes >= 100
```

ほとんどの場合、[論理グループ](/docs/{{version}}/queries#logical-grouping)を使用して、括弧内の条件付きチェックをグループ化する必要があります。

    use Illuminate\Database\Eloquent\Builder;

    $user->posts()
            ->where(function (Builder $query) {
                return $query->where('active', 1)
                             ->orWhere('votes', '>=', 100);
            })
            ->get();

上記の例は、以下のSQLを生成します。論理グループ化によって制約が適切にグループ化され、クエリは特定のユーザーを制約したままであることに注意してください。

```sql
select *
from posts
where user_id = ? and (active = 1 or votes >= 100)
```

<a name="relationship-methods-vs-dynamic-properties"></a>
### リレーションメソッド対動的プロパティ

Eloquentリレーションクエリへ制約を追加する必要がない場合は、プロパティであるかのようにリレーションにアクセスできます。たとえば、`User`と`Post`のサンプルモデルを引き続き使用すると、次のようにユーザーのすべての投稿にアクセスできます。

    use App\Models\User;

    $user = User::find(1);

    foreach ($user->posts as $post) {
        //
    }

動的リレーションプロパティは「遅延読み込み」を実行します。つまり、実際にアクセスしたときにのみリレーションデータが読み込まれます。このため、開発者は[Eagerロード](#eager-loading)を使用して、モデルのロード後にアクセスすることがわかっているリレーションを事前ロードすることがよくあります。Eagerロードにより、モデルのリレーションを読み込むために実行する必要のあるSQLクエリが大幅に削減されます。

<a name="querying-relationship-existence"></a>
### リレーションの存在のクエリ

モデルレコードを取得するときは、リレーションのありなしに基づいて結果を制約したい場合もあるでしょう。たとえば、コメントが少なくとも１つあるすべてのブログ投稿を取得するとします。これを行うには、関係の名前を`has`メソッドと`orHas`メソッドに渡すことができます。

    use App\Models\Post;

    // コメントが少なくとも1つあるすべての投稿を取得
    $posts = Post::has('comments')->get();

演算子とカウント数を指定して、クエリをさらにカスタマイズすることもできます。

    // コメントが３つ以上あるすべての投稿を取得
    $posts = Post::has('comments', '>=', 3)->get();

ネストした`has`ステートメントは、「ドット」表記を使用して作成できます。たとえば、少なくとも1つの画像を持つコメントが、少なくとも1つあるすべての投稿を取得できます。

    // 画像付きのコメントが少なくとも1つある投稿を取得
    $posts = Post::has('comments.images')->get();

さらに強力な機能が必要な場合は、`whereHas`メソッドと`orWhereHas`メソッドを使用して、コメントの内容の検査など、`has`クエリに追加のクエリ制約を定義できます。

    use Illuminate\Database\Eloquent\Builder;

    // code％と似ている単語を含むコメントが少なくとも１つある投稿を取得
    $posts = Post::whereHas('comments', function (Builder $query) {
        $query->where('content', 'like', 'code%');
    })->get();

    // code％と似ている単語を含むコメントが１０件以上ある投稿を取得
    $posts = Post::whereHas('comments', function (Builder $query) {
        $query->where('content', 'like', 'code%');
    }, '>=', 10)->get();

> {note} Eloquentは現在、データベース間をまたぐリレーションの存在のクエリをサポートしていません。リレーションは同じデータベース内に存在する必要があります。

<a name="querying-relationship-absence"></a>
### 存在しないリレーションのクエリ

モデルレコードを取得するときに、リレーションがないことに基づいて結果を制限したい場合もあるでしょう。たとえば、コメントが**ない**すべてのブログ投稿を取得する場合です。この場合は、リレーション名前を`doesntHave`メソッドや`orDoesntHave`メソッドに渡します。

    use App\Models\Post;

    $posts = Post::doesntHave('comments')->get();

さらに強力な機能が必要な場合は、`whereDoesntHave`メソッドと`orWhereDoesntHave`メソッドを使用して、コメントの内容の検査など、クエリ制約を`doesntHave`クエリへ追加できます。

    use Illuminate\Database\Eloquent\Builder;

    $posts = Post::whereDoesntHave('comments', function (Builder $query) {
        $query->where('content', 'like', 'code%');
    })->get();

「ドット」表記を使用して、ネストしたリレーションに対しクエリを実行できます。たとえば、次のクエリはコメントが無いすべての投稿を取得します。ただし、バンされていない著者からのコメントがある投稿は結果に含みます。

    use Illuminate\Database\Eloquent\Builder;

    $posts = Post::whereDoesntHave('comments.author', function (Builder $query) {
        $query->where('banned', 0);
    })->get();

<a name="querying-morph-to-relationships"></a>
### Morph Toリレーションのクエリ

"morph to"リレーションの存在をクエリするには、`whereHasMorph`メソッドと`whereDoesntHaveMorph`メソッドを使用します。これらのメソッドは、リレーション名を最初の引数に取ります。次にこのメソッドは、クエリに含める関連モデルの名前を引数に取ります。最後の引数は、リレーションクエリをカスタマイズするクロージャを指定します。

    use App\Models\Comment;
    use App\Models\Post;
    use App\Models\Video;
    use Illuminate\Database\Eloquent\Builder;

    // code%と似たタイトルの投稿や動画へ関連付けられたコメントを取得
    $comments = Comment::whereHasMorph(
        'commentable',
        [Post::class, Video::class],
        function (Builder $query) {
            $query->where('title', 'like', 'code%');
        }
    )->get();

    // code%と似ていないタイトルの投稿と関連付けられたコメントを取得
    $comments = Comment::whereDoesntHaveMorph(
        'commentable',
        Post::class,
        function (Builder $query) {
            $query->where('title', 'like', 'code%');
        }
    )->get();

関連するポリモーフィックモデルの「タイプ」に基づいて、クエリ制約を追加したい場合もあるでしょう。`whereHasMorph`メソッドに渡したクロージャは、２番目の引数として`$type`値を受け取ります。この引数を使用すると、作成中のクエリの「タイプ」を調べることができます。

    use Illuminate\Database\Eloquent\Builder;

    $comments = Comment::whereHasMorph(
        'commentable',
        [Post::class, Video::class],
        function (Builder $query, $type) {
            $column = $type === Post::class ? 'content' : 'title';

            $query->where($column, 'like', 'code%');
        }
    )->get();

<a name="querying-all-morph-to-related-models"></a>
#### 関連するすべてのモデルのクエリ

指定可能なポリモーフィックモデルの配列を渡す代わりに、ワイルドカード値として`*`を指定できます。これによりLaravelへ、データベースから取得可能なすべてのポリモーフィックタイプを取得するように指示できます。Laravelは、この操作を実行するために追加のクエリを実行します。

    use Illuminate\Database\Eloquent\Builder;

    $comments = Comment::whereHasMorph('commentable', '*', function (Builder $query) {
        $query->where('title', 'like', 'foo%');
    })->get();

<a name="aggregating-related-models"></a>
## 関連するモデルの集計

<a name="counting-related-models"></a>
### 関連モデルのカウント

実際にモデルをロードせずに、指定したリレーションの関連モデルの数をカウントしたい場合があります。このためには、`withCount`メソッドを使用します。`withCount`メソッドは結果のモデル上へ`{リレーション}_count`属性を作ります。

    use App\Models\Post;

    $posts = Post::withCount('comments')->get();

    foreach ($posts as $post) {
        echo $post->comments_count;
    }

配列を`withCount`メソッドに渡すことで、複数のリレーションの「カウント」を追加したり、クエリに制約を追加したりできます。

    use Illuminate\Database\Eloquent\Builder;

    $posts = Post::withCount(['votes', 'comments' => function (Builder $query) {
        $query->where('content', 'like', 'code%');
    }])->get();

    echo $posts[0]->votes_count;
    echo $posts[0]->comments_count;

リレーションカウントの結果に別名を付け、同じリレーションの複数の集計もできます。

    use Illuminate\Database\Eloquent\Builder;

    $posts = Post::withCount([
        'comments',
        'comments as pending_comments_count' => function (Builder $query) {
            $query->where('approved', false);
        },
    ])->get();

    echo $posts[0]->comments_count;
    echo $posts[0]->pending_comments_count;

<a name="deferred-count-loading"></a>
#### 遅延カウントロード

`loadCount`メソッドを使用すると、親モデルがすでに取得された後にリレーションのカウントをロードできます。

    $book = Book::first();

    $book->loadCount('genres');

カウントクエリへクエリ制約を追加設定する必要がある場合は、カウントしたいリレーションをキーにした配列を渡すことができます。配列の値は、クエリビルダインスタンスを受け取るクロージャである必要があります。

    $book->loadCount(['reviews' => function ($query) {
        $query->where('rating', 5);
    }])

<a name="relationship-counting-and-custom-select-statements"></a>
#### リレーションのカウントとカスタムSELECT文

`withCount`を`select`ステートメントと組み合わせる場合は、`select`メソッドの後に`withCount`を呼び出してください。

    $posts = Post::select(['title', 'body'])
                    ->withCount('comments')
                    ->get();

<a name="other-aggregate-functions"></a>
### その他の集計関数

Eloquentは、`withCount`メソッドに加えて、`withMin`、`withMax`、`withAvg`、`withSum`メソッドも提供しています。これらのメソッドは、結果のモデルに`{リレーション}_{集計機能}_{column}`属性を配置します。

    use App\Models\Post;

    $posts = Post::withSum('comments', 'votes')->get();

    foreach ($posts as $post) {
        echo $post->comments_sum_votes;
    }

`loadCount`メソッドと同様に、これらのメソッドの遅延バージョンも利用できます。こうした集計関数は、すでに取得しているEloquentモデルで実行します。

    $post = Post::first();

    $post->loadSum('comments', 'votes');

<a name="counting-related-models-on-morph-to-relationships"></a>
### Morph Toリレーションの関連モデルのカウント

"morph to"リレーションとそのリレーションが返す可能性のあるさまざまなエンティティの関連モデル数をEagerロードしたい場合は、`with`メソッドを`morphTo`リレーションの`morphWithCount`メソッドと組み合わせて使用​​します。

今回の例では、`Photo`モデルと`Post`モデルが`ActivityFeed`モデルを作成していると想定します。`ActivityFeed`モデルは、特定の`ActivityFeed`インスタンスの親`Photo`または`Post`モデルを取得できるようにする`parentable`という名前の"morph to"リレーションを定義すると想定します。さらに、`Photo`モデルには「多くの（have many）」`Tag`モデルがあり、`Post`モデルも「多くの（have many）」`Comment`モデルがあると仮定しましょう。

では、`ActivityFeed`インスタンスを取得し、各`ActivityFeed`インスタンスの`parentable`親モデルをEagerロードしましょう。さらに、各親の写真に関連付いているタグの数と、各親の投稿に関連付いているコメントの数を取得しましょう。

    use Illuminate\Database\Eloquent\Relations\MorphTo;

    $activities = ActivityFeed::with([
        'parentable' => function (MorphTo $morphTo) {
            $morphTo->morphWithCount([
                Photo::class => ['tags'],
                Post::class => ['comments'],
            ]);
        }])->get();

<a name="morph-to-deferred-count-loading"></a>
#### 遅延カウントロード

すでに`ActivityFeed`モデルを取得していて、アクティビティフィードに関連付いているさまざまな`parentable`モデルのネストしたリレーションのカウントをロードしたいとします。これを実現するには、`loadMorphCount`メソッドを使用します。

    $activities = ActivityFeed::with('parentable')->get();

    $activities->loadMorphCount('parentable', [
        Photo::class => ['tags'],
        Post::class => ['comments'],
    ]);

<a name="eager-loading"></a>
## Eagerロード

プロパティとしてEloquentリレーションへアクセスすると、関連するモデルは「遅延読み込み」されます。つまりこれは、最初にプロパティへアクセスするまで、リレーションデータが実際にロードされないことを意味します。ただし、Eloquentは、親モデルにクエリを実行するときに、関係を「Eager（積極的）ロード」できます。Eagerロードにより、「N＋１」クエリの問題が軽減されます。N＋１クエリの問題を説明するために、`Author`モデルに「属する（belongs to）」`Book`モデルについて考えてみます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Book extends Model
    {
        /**
         * その本を書いた著者を取得
         */
        public function author()
        {
            return $this->belongsTo(Author::class);
        }
    }

では、すべての本とその著者を取得しましょう。

    use App\Models\Book;

    $books = Book::all();

    foreach ($books as $book) {
        echo $book->author->name;
    }

このループは、データベーステーブル内のすべての本を取得するために１つのクエリを実行し、次に本の著者を取得するために各本に対して別のクエリを実行します。したがって、２５冊の本がある場合、上記のコードは２６のクエリを実行します。１回はもとの本の取得のため、それと各本の著者を取得するための２５回の追加クエリです。

ありがたいことに、Eagerロードを使用し、この操作を２つのクエリに減らすことができます。クエリを作成するときに、`with`メソッドを使用してどの関係をEagerロードするかを指定します。

    $books = Book::with('author')->get();

    foreach ($books as $book) {
        echo $book->author->name;
    }

この操作では、２クエリのみ実行します。１回はすべての本を取得するクエリで、もう１回はすべての本のすべての著者を取得するクエリです。

```sql
select * from books

select * from authors where id in (1, 2, 3, 4, 5, ...)
```

<a name="eager-loading-multiple-relationships"></a>
#### 複数リレーションのEagerロード

状況により、いくつか異なるリレーションをEagerロードする必要がおきます。これには、関係の配列を`with`メソッドに渡すだけです。

    $books = Book::with(['author', 'publisher'])->get();

<a name="nested-eager-loading"></a>
#### ネストしたEagerロード

リレーションのリレーションをEagerロードするために、「ドット」構文が使えます。たとえば、本のすべての著者とすべての著者の個人的な連絡先をEagerロードしましょう。

    $books = Book::with('author.contacts')->get();

<a name="nested-eager-loading-morphto-relationships"></a>
#### `morphTo`リレーションのネストしたEagerロード

`morphTo`リレーション、およびそのリレーションが返す可能性のあるさまざまなエンティティのネストしたリレーションをEagerロードしたい場合は、`with`メソッドを`morphTo`リレーションの`morphWith`メソッドと組み合わせて使用​​します。この方法を説明するために、次のモデルについて考えてみましょう。

    <?php

    use Illuminate\Database\Eloquent\Model;

    class ActivityFeed extends Model
    {
        /**
         * アクティビティフィードレコードの親を取得
         */
        public function parentable()
        {
            return $this->morphTo();
        }
    }

この例では、`Event`、`Photo`、および`Post`モデルが`ActivityFeed`モデルを作成すると想定します。さらに、`Event`モデルが「`Calendar`モデルに属し、`Photo`モデルが`Tag`モデルへ関連付けられ、`Post`モデルが`Author`モデルに属していると想定します。

これらのモデル定義とリレーションを使用して、`ActivityFeed`モデルインスタンスを取得し、すべての`parentable`モデルとそれぞれのネストしたリレーションをEagerロードできます。

    use Illuminate\Database\Eloquent\Relations\MorphTo;

    $activities = ActivityFeed::query()
        ->with(['parentable' => function (MorphTo $morphTo) {
            $morphTo->morphWith([
                Event::class => ['calendar'],
                Photo::class => ['tags'],
                Post::class => ['author'],
            ]);
        }])->get();

<a name="eager-loading-specific-columns"></a>
#### 特定のカラムのEagerロード

取得するリレーションのすべてのカラムが常に必要だとは限りません。このため、Eloquentはリレーションでどのカラムを取得するかを指定できます。

    $books = Book::with('author:id,name')->get();

> {note} この機能を使用するときは、取得するカラムのリストで常に`id`カラムと関連する外部キーカラムを含める必要があります。

<a name="eager-loading-by-default"></a>
#### デフォルトのEagerロード

モデルを取得するときに、常にいくつかのリレーションをロードしたい場合があります。実現するには、モデルに`$with`プロパティを定義します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Book extends Model
    {
        /**
         * 常にロードする必要があるリレーション
         *
         * @var array
         */
        protected $with = ['author'];

        /**
         * この本を書いた著者を入手
         */
        public function author()
        {
            return $this->belongsTo(Author::class);
        }
    }

一度のクエリで`$with`プロパティからのアイテムを削除する場合は、`without`メソッドを使用します。

    $books = Book::without('author')->get();

<a name="constraining-eager-loads"></a>
### Eagerロードの制約

リレーションをEagerロードするだけでなく、Eagerロードクエリへクエリ条件を追加指定したい場合もあります。そのためには、リレーションの配列を`with`メソッドへ渡します。ここでの配列キーはリレーション名であり、配列値はEagerロードクエリへ制約を追加するクロージャです。

    use App\Models\User;

    $users = User::with(['posts' => function ($query) {
        $query->where('title', 'like', '%code%');
    }])->get();

この例では、Eloquentは、投稿の`title`カラムに`code`という単語を含んでいる投稿のみをEagerロードします。他の[クエリビルダ](/docs/{{version}}/queryies)メソッドを呼び出して、Eagerロード操作をさらにカスタマイズすることもできます。

    $users = User::with(['posts' => function ($query) {
        $query->orderBy('created_at', 'desc');
    }])->get();

> {note} Eagerロードを制限する場合は、`limit`および`take`クエリビルダメソッドは使用できません。

<a name="constraining-eager-loading-of-morph-to-relationships"></a>
#### `morphTo`リレーションのEagerロードの制約

`morphTo`リレーションをEagerロードする場合、Eloquentは複数のクエリを実行して各タイプの関連モデルをフェッチします。`MorphTo`リレーションの`constrain`メソッドを使用して、これらの各クエリに制約を追加できます。

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Relations\MorphTo;

    $comments = Comment::with(['commentable' => function (MorphTo $morphTo) {
        $morphTo->constrain([
            Post::class => function (Builder $query) {
                $query->whereNull('hidden_at');
            },
            Video::class => function (Builder $query) {
                $query->where('type', 'educational');
            },
        ]);
    }])->get();

この例でEloquentは、非表示にされていない投稿と`type`値が"educational"な動画のみをEagerロードします。

<a name="lazy-eager-loading"></a>
### 遅延Eagerロード

親モデルを取得した後に、リレーションをEagerロードしたい場合があります。たとえば、これは関連モデルをロードするかを動的に決定する必要がある場合で役立ちます。

    use App\Models\Book;

    $books = Book::all();

    if ($someCondition) {
        $books->load('author', 'publisher');
    }

Eagerロードクエリにクエリ制約を追加設定する必要がある場合は、ロードしたいリレーションをキーにした配列を渡します。配列の値は、クエリインスタンスを引数に受けるクロージャインスタンスの必要があります。

    $author->load(['books' => function ($query) {
        $query->orderBy('published_date', 'asc');
    }]);

未ロードの場合にのみリレーションシップを読み込むには、`loadMissing`メソッドを使用します。

    $book->loadMissing('author');

<a name="nested-lazy-eager-loading-morphto"></a>
#### ネストした遅延Eagerロードと`morphTo`

`morphTo`リレーション、およびそのリレーションが返す可能性のあるさまざまなエンティティのネストした関係をEagerロードしたい場合は、`loadMorph`メソッドを使用できます。

このメソッドは、最初の引数として`morphTo`リレーション名を取り、２番目の引数としてモデル／リレーションペアの配列を受けます。このメソッドを説明するために、次のモデルについて考えてみましょう。

    <?php

    use Illuminate\Database\Eloquent\Model;

    class ActivityFeed extends Model
    {
        /**
         * アクティビティフィードレコードの親を取得
         */
        public function parentable()
        {
            return $this->morphTo();
        }
    }

この例では、`Event`、`Photo`、`Post`モデルが`ActivityFeed`モデルを作成すると想定します。さらに、`Event`モデルが`Calendar`モデルに属し、`Photo`モデルが`Tag`モデルに関連付けられ、`Post`モデルが `Author`モデルに属していると想定します。

これらのモデル定義とリレーションを使用して、`ActivityFeed`モデルインスタンスを取得し、すべての`parentable`モデルとそれぞれのネストしたリレーションをEagerロードしてみます。

    $activities = ActivityFeed::with('parentable')
        ->get()
        ->loadMorph('parentable', [
            Event::class => ['calendar'],
            Photo::class => ['tags'],
            Post::class => ['author'],
        ]);

<a name="inserting-and-updating-related-models"></a>
## 関連モデルの挿入と更新

<a name="the-save-method"></a>
### `save`メソッド

Eloquentは、リレーションへ新しいモデルを追加する便利な手法を提供しています。たとえば、投稿に新しいコメントを追加する必要があるかもしれません。`Comment`モデルで`post_id`属性を手動で設定する代わりに、リレーションの`save`メソッドを使用してもコメントを追加できます。

    use App\Models\Comment;
    use App\Models\Post;

    $comment = new Comment(['message' => 'A new comment.']);

    $post = Post::find(1);

    $post->comments()->save($comment);

動的プロパティとして`comments`関係へアクセスしなかったことに注意してください。代わりに、リレーションのインスタンスを取得するために`comments`メソッドを呼び出しました。`save`メソッドは、適切な`post_id`値を新しい`Comment`モデルへ自動的に追加します。

複数の関連モデルを保存する必要がある場合は、`saveMany`メソッドを使用します。

    $post = Post::find(1);

    $post->comments()->saveMany([
        new Comment(['message' => 'A new comment.']),
        new Comment(['message' => 'Another new comment.']),
    ]);

`save`メソッドと`saveMany`メソッドは、親モデルへすでにロードしているメモリ内のリレーションには新しいモデルを追加しません。`save`と`saveMany`メソッドを使用した後にリレーションへアクセスしようと考えている場合は、`refresh`メソッドを使用してモデルとそのリレーションを再ロードするのを推奨します。

    $post->comments()->save($comment);

    $post->refresh();

    // 新しく保存されたコメントを含むすべてのコメント
    $post->comments;

<a name="the-push-method"></a>
#### モデルと関係の再帰的保存

モデルとそれに関連するすべてのリレーションを`save`したい場合は、`push`メソッドを使用します。下記例では、`Post`モデルが、そのコメントとコメントの作成者とともに保存されます。

    $post = Post::find(1);

    $post->comments[0]->message = 'Message';
    $post->comments[0]->author->name = 'Author Name';

    $post->push();

<a name="the-create-method"></a>
### `create`メソッド

`save`メソッドと`saveMany`メソッドに加え、属性の配列を受け取り、モデルを作成してデータベースに挿入する`create`メソッドも使用できます。`save`と`create`の違いは、`save`は完全なEloquentモデルインスタンスを受け入れるのに対し、`create`はプレーンなPHPの`array`を引数に取ることです。`create`メソッドは、新しく作成したモデルを返します。

    use App\Models\Post;

    $post = Post::find(1);

    $comment = $post->comments()->create([
        'message' => 'A new comment.',
    ]);

`createMany`メソッドを使用して、複数の関連モデルを作成できます。

    $post = Post::find(1);

    $post->comments()->createMany([
        ['message' => 'A new comment.'],
        ['message' => 'Another new comment.'],
    ]);

`findOrNew`、`firstOrNew`、`firstOrCreate`、`updateOrCreate`メソッドを使用して[関係のモデルを作成および更新](https://laravel.com/docs/{{version}}/eloquent#upserts)することもできます。

> {tip} `create`メソッドを使用する前に、必ず[複数代入](/docs/{{version}}/eloquent#mass-assignment)のドキュメントを確認してください。

<a name="updating-belongs-to-relationships"></a>
### Belongs Toリレーション

子モデルを新しい親モデルに割り当てたい場合は、`associate`メソッドを使用します。下記例で、`User`モデルは`Account`モデルに対する`belongsTo`リレーションを定義してへます。この`associate`メソッドは、子モデルへ外部キーを設定します。

    use App\Models\Account;

    $account = Account::find(10);

    $user->account()->associate($account);

    $user->save();

子モデルから親モデルを削除するには、`dissociate`メソッドを使用できます。このメソッドは、リレーションの外部キーを`null`に設定します。

    $user->account()->dissociate();

    $user->save();

<a name="updating-many-to-many-relationships"></a>
### 多対多リレーション

<a name="attaching-detaching"></a>
#### 関連付け／関連解除

Eloquentは、多対多リレーションの作業をとても便利にする方法も提供しています。たとえば、ユーザーが多くの役割を持つことができ、役割が多くのユーザーを持つことができると想定してみましょう。`attach`メソッドを使用してリレーションの中間テーブルへレコードを挿入することで、ユーザーに役割を関連付けできます。

    use App\Models\User;

    $user = User::find(1);

    $user->roles()->attach($roleId);

モデルにリレーションを関連付けるときに、中間テーブルへ挿入する追加データの配列を渡すこともできます。

    $user->roles()->attach($roleId, ['expires' => $expires]);

ユーザーから役割を削除する必要も起きるでしょう。多対多の関係レコードを削除するには、`detach`メソッドを使用します。`detach`メソッドは、中間テーブルから適切なレコードを削除します。ただし、両方のモデルはデータベースに残ります。

    // ユーザーから一つの役割を関連解除
    $user->roles()->detach($roleId);

    // ユーザーからすべての役割を関連解除
    $user->roles()->detach();

使いやすいように、`attach`と`detach`はIDの配列も引数に取れます。

    $user = User::find(1);

    $user->roles()->detach([1, 2, 3]);

    $user->roles()->attach([
        1 => ['expires' => $expires],
        2 => ['expires' => $expires],
    ]);

<a name="syncing-associations"></a>
#### 関連の同期

`sync`メソッドを使用して、多対多の関連付けを構築することもできます。`sync`メソッドは、中間テーブルに配置するIDの配列を引数に取ります。指定した配列にないIDは、中間テーブルから削除されます。したがってこの操作が完了すると、指定した配列のIDのみが中間テーブルに残ります。

    $user->roles()->sync([1, 2, 3]);

IDを使用して追加の中間テーブル値を渡すこともできます。

    $user->roles()->sync([1 => ['expires' => true], 2, 3]);

指定した配列から欠落している既存のIDを切り離したくない場合は、`syncWithoutDetaching`メソッドを使用します。

    $user->roles()->syncWithoutDetaching([1, 2, 3]);

<a name="toggling-associations"></a>
#### 関連の切り替え

多対多リレーションは、指定した関連モデルIDの接続状態を「切り替える」、`toggle`メソッドも提供します。指定されたIDが現在関連づいている場合、そのIDを関連解除します。同様に現在関連していない場合は、関連付けます。

    $user->roles()->toggle([1, 2, 3]);

<a name="updating-a-record-on-the-intermediate-table"></a>
#### 中間テーブルのレコード更新

リレーションの中間テーブルの既存のカラムを更新する必要がある場合は、`updateExistingPivot`メソッドを使用します。このメソッドは、更新する中間レコードの外部キーと属性の配列を引数に取ります。

    $user = User::find(1);

    $user->roles()->updateExistingPivot($roleId, [
        'active' => false,
    ]);

<a name="touching-parent-timestamps"></a>
## 親のタイムスタンプの更新

`Post`に属する`Comment` など、モデルが別のモデルとの`belongsTo`または`belongsToMany`の関係を定義している場合、子モデルのが更新時に親のタイムスタンプも更新できると役立つ場合があります。

たとえば、`Comment`モデルが更新されたときに、所有している`Post`の`updated_at`タイムスタンプを自動的に「更新」して、現在の日時を設定したい場合があるでしょう。これを行うには、子モデルの更新時に`updated_at`タイムスタンプを更新する必要があるリレーションの名前を含む`touches`プロパティを子モデルに追加します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Comment extends Model
    {
        /**
         * 更新日時を更新すべき全リレーション
         *
         * @var array
         */
        protected $touches = ['post'];

        /**
         * コメントが属する投稿の取得
         */
        public function post()
        {
            return $this->belongsTo(Post::class);
        }
    }

> {note} 親モデルのタイムスタンプは、Eloquentの`save`メソッドを使用して子モデルを更新した場合にのみ更新されます。
