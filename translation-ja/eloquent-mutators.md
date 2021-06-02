# Eloquent：ミューテタ／キャスト

- [イントロダクション](#introduction)
- [アクセサ／ミューテタ](#accessors-and-mutators)
    - [アクセサの定義](#defining-an-accessor)
    - [ミューテタの定義](#defining-a-mutator)
- [属性のキャスト](#attribute-casting)
    - [配列とJSONのキャスト](#array-and-json-casting)
    - [日付のキャスト](#date-casting)
    - [クエリ時のキャスト](#query-time-casting)
- [カスタムキャスト](#custom-casts)
    - [値オブジェクトのキャスト](#value-object-casting)
    - [配列／JSONのシリアル化](#array-json-serialization)
    - [インバウンドのキャスト](#inbound-casting)
    - [キャストのパラメータ](#cast-parameters)
    - [Castables](#castables)

<a name="introduction"></a>
## イントロダクション

アクセサ、ミューテタ、および属性キャストを使用すると、Eloquentモデルインスタンスで属性値を取得または設定するときに、それらの属性値を変換できます。たとえば、[Laravel暗号化](/docs/{{version}}/encoding)を使用して、データベースに保存されている値を暗号化し、Eloquentモデル上でそれにアクセスしたときに属性を自動的に復号できます。他に、Eloquentモデルを介してアクセスするときに、データベースに格納されているJSON文字列を配列に変換することもできます。

<a name="accessors-and-mutators"></a>
## アクセサ／ミューテタ

<a name="defining-an-accessor"></a>
### アクセサの定義

アクセサは、アクセス時にEloquent属性値を変換します。アクセサを定義するには、モデルに`get{Attribute}Attribute`メソッドを作成します。`{Attribute}`は、アクセスするカラムのアッパーキャメルケース（studly case）の名前です。

この例では、`first_name`属性のアクセサを定義します。アクセサは、`first_name`属性の値を取得しようとすると、Eloquentによって自動的に呼び出されます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーの名前の取得
         *
         * @param  string  $value
         * @return string
         */
        public function getFirstNameAttribute($value)
        {
            return ucfirst($value);
        }
    }

ご覧のとおり、カラムの元の値がアクセサに渡され、値を操作でき、結果値を返します。アクセサの値へアクセスするには、モデルインスタンスの`first_name`属性にアクセスするだけです。

    use App\Models\User;

    $user = User::find(1);

    $firstName = $user->first_name;

アクセサは単一の属性の操作に限定されません。アクセサを使用して、既存の属性から新しい計算値を返すこともできます。

    /**
     * ユーザーのフルネームの取得
     *
     * @return string
     */
    public function getFullNameAttribute()
    {
        return "{$this->first_name} {$this->last_name}";
    }

> {tip} こうした計算値をモデルの配列／JSON表現に追加したい場合は、[手動で追加する必要があります](/docs/{{version}}/eloquent-serialization#appending-values-to-json)。

<a name="defining-a-mutator"></a>
### ミューテタの定義

ミューテタは、設定時にEloquent属性値を変換します。ミューテタを定義するには、モデルで`set{Attribute}Attribute`メソッドを定義します。`{Attribute}`は、アクセスするカラム名のアッパーキャメルケース（studly case）です。

`first_name`属性のミューテタを定義しましょう。このミューテタは、モデルへ`first_name`属性の値を設定しようとすると自動的に呼び出されます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーの名前を設定
         *
         * @param  string  $value
         * @return void
         */
        public function setFirstNameAttribute($value)
        {
            $this->attributes['first_name'] = strtolower($value);
        }
    }

ミューテタは属性へ設定する値を受け取り、値を操作でき、操作した値をEloquentモデルの内部の`$attributes`プロパティに設定します。ミューテタを使用するには、Eloquentモデルに対し、`first_name`属性を設定するだけです。

    use App\Models\User;

    $user = User::find(1);

    $user->first_name = 'Sally';

この例で、`setFirstNameAttribute`関数は`Sally`値で呼び出されます。次に、ミューテタは名前に`strtolower`関数を適用し、その結果の値を内部の`$attributes`配列へ設定します。

<a name="attribute-casting"></a>
## 属性のキャスト

属性キャストは、モデルで追加のメソッドを定義することなく、アクセサやミューテタと同様の機能を提供します。定義する代わりに、モデルの`$casts`プロパティにより属性を一般的なデータ型に変換する便利な方法を提供します。

`$casts`プロパティは、キーがキャストする属性の名前であり、値がそのカラムをキャストするタイプである配列である必要があります。サポートしているキャストタイプは以下のとおりです。

<div class="content-list" markdown="1">
- `array`
- `boolean`
- `collection`
- `date`
- `datetime`
- `decimal:<digits>`
- `double`
- `encrypted`
- `encrypted:array`
- `encrypted:collection`
- `encrypted:object`
- `float`
- `integer`
- `object`
- `real`
- `string`
- `timestamp`
</div>

属性のキャストをデモンストレートするため、データベースに整数(`0`または`1`)として格納している`is_admin`属性をブール値にキャストしてみましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする必要のある属性
         *
         * @var array
         */
        protected $casts = [
            'is_admin' => 'boolean',
        ];
    }

キャストを定義した後、基になる値が整数としてデータベースに格納されていても、アクセス時`is_admin`属性は常にブール値にキャストされます。

    $user = App\Models\User::find(1);

    if ($user->is_admin) {
        //
    }

実行時に新しく一時的なキャストを追加する必要がある場合は、`mergeCasts`メソッドを使用します。こうしたキャストの定義は、モデルで既に定義しているキャストのいずれかに追加されます。

    $user->mergeCasts([
        'is_admin' => 'integer',
        'options' => 'object',
    ]);

> {note} `null`である属性はキャストしません。また、リレーションと同じ名前のキャスト(または属性)を定義しないでください。

<a name="array-and-json-casting"></a>
### 配列とJSONのキャスト

`array`キャストは、シリアル化されたJSONとして保存されているカラムを操作するときに特に役立ちます。たとえば、データベースにシリアル化されたJSONを含む`JSON`または`TEXT`フィールドタイプがある場合、その属性へ`array`キャストを追加すると、Eloquentモデル上でアクセス時に、属性がPHP配列へ自動的に逆シリアル化されます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする必要のある属性
         *
         * @var array
         */
        protected $casts = [
            'options' => 'array',
        ];
    }

このキャストを定義すると、`options`属性にアクセスでき、JSONからPHP配列に自動的に逆シリアル化されます。`options`属性の値を設定すると、指定する配列が自動的にシリアル化されてJSONに戻されて保存されます。

    use App\Models\User;

    $user = User::find(1);

    $options = $user->options;

    $options['key'] = 'value';

    $user->options = $options;

    $user->save();

JSON属性の単一のフィールドをより簡潔な構文で更新するには、`update`メソッドを呼び出すときに`->`演算子を使用します。

    $user = User::find(1);

    $user->update(['options->key' => 'value']);

<a name="array-object-and-collection-casting"></a>
#### 配列オブジェクトとコレクションのキャスト

多くのアプリケーションには標準の`array`キャストで十分ですが、いくつかの欠点を持ちます。`array`キャストはプリミティブ型を返すので、配列のオフセットを直接変更することはできません。たとえば、次のコードはPHPエラーを起こします。

    $user = User::find(1);

    $user->options['key'] = $value;

これを解決するために、Laravelは、JSON属性を[ArrayObject](https://www.php.net/manual/en/class.arrayobject.php)クラスにキャストする`asArrayObject`キャストを提供します。この機能はLaravelの[カスタムキャスト](#custom-cast)の実装を使用しており、Laravelがインテリジェントにキャッシュし、PHPエラーを引き起こすことなく、個々のオフセットを変更できるように、ミューテートしたオブジェクトを変換することができます。AsArrayObject`のキャストを使用するには、単純に属性に割り当てるだけです。

    use Illuminate\Database\Eloquent\Casts\AsArrayObject;

    /**
     * キャストする属性
     *
     * @var array
     */
    protected $casts = [
        'options' => AsArrayObject::class,
    ];

同様に、LaravelはJSON属性をLaravel[コレクション](/docs/{{version}}/collections)へキャストする`ASCollection`キャストを提供しています

    use Illuminate\Database\Eloquent\Casts\AsCollection;

    /**
     * キャストする属性
     *
     * @var array
     */
    protected $casts = [
        'options' => AsCollection::class,
    ];

<a name="date-casting"></a>
### 日付のキャスト

デフォルトでは、Eloquentは`created_at`カラムと`updated_at`カラムを[Carbon](https://github.com/briannesbitt/Carbon)のインスタンスへキャストします。これによりPHPの`DateTime`クラスを拡張した、多くの便利なメソッドが提供されます。モデルの`$cast`プロパティ配列内で日付キャストを追加定義すれば、他の日付属性をキャストできます。通常、日付は`datetime`キャストを使用してキャストする必要があります。

`date`または`datetime`キャストを定義するときに、日付の形式を指定することもできます。この形式は、[モデルが配列またはJSONにシリアル化される](/docs/{{version}}/eloquent-serialization)場合に使用されます。

    /**
     * キャストする必要のある属性
     *
     * @var array
     */
    protected $casts = [
        'created_at' => 'datetime:Y-m-d',
    ];

カラムが日付としてキャストされる場合、その値をUNIXタイムスタンプ、日付文字列(`Y-m-d`)、日時文字列、または`DateTime`/`Carbon`インスタンスに設定できます。日付の値は正しく変換され、データベースに保存されます。

モデルに`serializeDate`メソッドを定義することで、モデルのすべての日付のデフォルトのシリアル化形式をカスタマイズできます。この方法は、データベースへ保存するために日付をフォーマットする方法には影響しません。

    /**
     * 配列/JSONシリアル化の日付を準備
     *
     * @param  \DateTimeInterface  $date
     * @return string
     */
    protected function serializeDate(DateTimeInterface $date)
    {
        return $date->format('Y-m-d');
    }

データベース内にモデルの日付を実際に保存するときに使用する形式を指定するには、モデルに`$dateFormat`プロパティを定義する必要があります。

    /**
     * モデルの日付カラムのストレージ形式
     *
     * @var string
     */
    protected $dateFormat = 'U';

<a name="query-time-casting"></a>
### クエリ時のキャスト

テーブルから元の値でセレクトするときなど、クエリの実行中にキャストを適用する必要が起きる場合があります。たとえば、次のクエリを考えてみましょう。

    use App\Models\Post;
    use App\Models\User;

    $users = User::select([
        'users.*',
        'last_posted_at' => Post::selectRaw('MAX(created_at)')
                ->whereColumn('user_id', 'users.id')
    ])->get();

このクエリ結果の`last_posted_at`属性は単純な文字列になります。クエリを実行するときに、この属性に「datetime」キャストを適用できれば素晴らしいと思うでしょう。幸運なことに、`withCasts`メソッドを使用してこれができます。

    $users = User::select([
        'users.*',
        'last_posted_at' => Post::selectRaw('MAX(created_at)')
                ->whereColumn('user_id', 'users.id')
    ])->withCasts([
        'last_posted_at' => 'datetime'
    ])->get();

<a name="custom-casts"></a>
## カスタムキャスト

Laravelには、さまざまな組み込みの便利なキャストタイプがあります。それでも、独自のキャストタイプを定義する必要が起きる場合があります。これは、`CastsAttributes`インターフェイスを実装するクラスを定義することで実現できます。

このインターフェイスを実装するクラスは、`get`および`set`メソッドを定義する必要があります。`get`メソッドはデータベースからの素の値をキャスト値に変換する役割を果たしますが、`set`メソッドはキャスト値をデータベースに保存できる素の値に変換する必要があります。例として、組み込みの`json`キャストタイプをカスタムキャストタイプとして再実装します。

    <?php

    namespace App\Casts;

    use Illuminate\Contracts\Database\Eloquent\CastsAttributes;

    class Json implements CastsAttributes
    {
        /**
         * 指定値をキャスト
         *
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @param  string  $key
         * @param  mixed  $value
         * @param  array  $attributes
         * @return array
         */
        public function get($model, $key, $value, $attributes)
        {
            return json_decode($value, true);
        }

        /**
         * 指定値をストレージ用に準備
         *
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @param  string  $key
         * @param  array  $value
         * @param  array  $attributes
         * @return string
         */
        public function set($model, $key, $value, $attributes)
        {
            return json_encode($value);
        }
    }

カスタムキャストタイプを定義したら、そのクラス名をモデル属性へ指定できます。

    <?php

    namespace App\Models;

    use App\Casts\Json;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする必要のある属性
         *
         * @var array
         */
        protected $casts = [
            'options' => Json::class,
        ];
    }

<a name="value-object-casting"></a>
### 値オブジェクトのキャスト

値をプリミティブ型にキャストすることに限定されません。オブジェクトへ値をキャストすることもできます。オブジェクトへ値をキャストするカスタムキャストの定義は、プリミティブ型へのキャストと非常によく似ています。ただし、`set`メソッドは、モデルに素の保存可能な値を設定するために使用するキー／値のペアの配列を返す必要があります。

例として、複数のモデル値を単一の`Address`値オブジェクトにキャストするカスタムキャストクラスを定義します。`Address`値には、`lineOne`と`lineTwo`の２つのパブリックプロパティがあると想定します。

    <?php

    namespace App\Casts;

    use App\Models\Address as AddressModel;
    use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
    use InvalidArgumentException;

    class Address implements CastsAttributes
    {
        /**
         * 指定値をキャスト
         *
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @param  string  $key
         * @param  mixed  $value
         * @param  array  $attributes
         * @return \App\Models\Address
         */
        public function get($model, $key, $value, $attributes)
        {
            return new AddressModel(
                $attributes['address_line_one'],
                $attributes['address_line_two']
            );
        }

        /**
         * 指定値をストレージ用に準備
         *
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @param  string  $key
         * @param  \App\Models\Address  $value
         * @param  array  $attributes
         * @return array
         */
        public function set($model, $key, $value, $attributes)
        {
            if (! $value instanceof AddressModel) {
                throw new InvalidArgumentException('The given value is not an Address instance.');
            }

            return [
                'address_line_one' => $value->lineOne,
                'address_line_two' => $value->lineTwo,
            ];
        }
    }

値オブジェクトにキャストする場合、値オブジェクトに加えられた変更は、モデルが保存される前に自動的にモデルに同期されます。

    use App\Models\User;

    $user = User::find(1);

    $user->address->lineOne = 'Updated Address Value';

    $user->save();

> {tip} 値オブジェクトを含むEloquentモデルをJSONまたは配列にシリアル化する場合は、値オブジェクトに`Illuminate\Contracts\Support\Arrayable`および`JsonSerializable`インターフェイスを実装する必要があります。

<a name="array-json-serialization"></a>
### 配列／JSONのシリアル化

Eloquentモデルを`toArray`および`toJson`メソッドを使用して配列やJSONへ変換する場合、カスタムキャスト値オブジェクトは通常、`Illuminate\Contracts\Support\Arrayable`および`JsonSerializable`インターフェイスを実装している限りシリアル化されます。しかし、サードパーティライブラリによって提供される値オブジェクトを使用する場合、これらのインターフェイスをオブジェクトに追加できない場合があります。

したがって、カスタムキャストクラスが値オブジェクトのシリアル化を担当するように指定できます。そのためには、カスタムクラスキャストで`Illuminate\Contracts\Database\Eloquent\SerializesCastableAttributes`インターフェイスを実装する必要があります。このインターフェイスは、クラスに「serialize」メソッドが含まれている必要があることを示しています。このメソッドは、値オブジェクトのシリアル化された形式を返す必要があります。

    /**
     * 値をシリアル化した表現の取得
     *
     * @param  \Illuminate\Database\Eloquent\Model  $model
     * @param  string  $key
     * @param  mixed  $value
     * @param  array  $attributes
     * @return mixed
     */
    public function serialize($model, string $key, $value, array $attributes)
    {
        return (string) $value;
    }

<a name="inbound-casting"></a>
### インバウンドのキャスト

場合によっては、モデルに値を設定するときのみ変換し、モデルから属性を取得するときは操作をしないカスタムキャストを作成する必要があります。インバウンドのみのキャストの典型的な例は、「ハッシュ（hashing）」キャストです。インバウンドのみのカスタムキャストは、`CastsInboundAttributes`インターフェイスを実装する必要があります。これには`set`メソッドの定義のみが必要です。

    <?php

    namespace App\Casts;

    use Illuminate\Contracts\Database\Eloquent\CastsInboundAttributes;

    class Hash implements CastsInboundAttributes
    {
        /**
         * ハッシュアルゴリズム
         *
         * @var string
         */
        protected $algorithm;

        /**
         * 新しいキャストクラスインスタンスの生成
         *
         * @param  string|null  $algorithm
         * @return void
         */
        public function __construct($algorithm = null)
        {
            $this->algorithm = $algorithm;
        }

        /**
         * 指定値をストレージ用に準備
         *
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @param  string  $key
         * @param  array  $value
         * @param  array  $attributes
         * @return string
         */
        public function set($model, $key, $value, $attributes)
        {
            return is_null($this->algorithm)
                        ? bcrypt($value)
                        : hash($this->algorithm, $value);
        }
    }

<a name="cast-parameters"></a>
### キャストのパラメータ

カスタムキャストをモデルへ指定する場合、`:`文字を使用してクラス名から分離し、複数のパラメータをコンマで区切ることでキャストパラメータを指定できます。パラメータは、キャストクラスのコンストラクタへ渡されます。

    /**
     * キャストする必要のある属性
     *
     * @var array
     */
    protected $casts = [
        'secret' => Hash::class.':sha256',
    ];

<a name="castables"></a>
### Castables

アプリケーションの値オブジェクトが独自のカスタムキャストクラスを定義できるようにすることができます。カスタムキャストクラスをモデルにアタッチする代わりに、`Illuminate\Contracts\Database\Eloquent\Castable`インターフェイスを実装する値オブジェクトクラスをアタッチすることもできます。

    use App\Models\Address;

    protected $casts = [
        'address' => Address::class,
    ];

`Castable`インターフェイスを実装するオブジェクトは、`Castable`クラスにキャストする／される責務を受け持つ、カスタムキャスタークラスのクラス名を返す`castUsing`メソッドを定義する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Contracts\Database\Eloquent\Castable;
    use App\Casts\Address as AddressCast;

    class Address implements Castable
    {
        /**
         * このキャストターゲットにキャストする／されるときに使用するキャスタークラスの名前を取得
         *
         * @param  array  $arguments
         * @return string
         */
        public static function castUsing(array $arguments)
        {
            return AddressCast::class;
        }
    }

`Castable`クラスを使用する場合でも、`$casts`定義に引数を指定できます。引数は`castUsing`メソッドに渡されます。

    use App\Models\Address;

    protected $casts = [
        'address' => Address::class.':argument',
    ];

<a name="anonymous-cast-classes"></a>
#### Castableと匿名キャストクラス

"Castable"をPHPの[匿名クラス](https://www.php.net/manual/en/language.oop5.anonymous.php)と組み合わせることで、値オブジェクトとそのキャストロジックを単一のCastableオブジェクトとして定義できます。これを実現するには、値オブジェクトの`castUsing`メソッドから匿名クラスを返します。匿名クラスは`CastsAttributes`インターフェイスを実装する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Contracts\Database\Eloquent\Castable;
    use Illuminate\Contracts\Database\Eloquent\CastsAttributes;

    class Address implements Castable
    {
        // ...

        /**
         * このキャストターゲットにキャストする／されるときに使用するキャスタークラスの名前を取得
         *
         * @param  array  $arguments
         * @return object|string
         */
        public static function castUsing(array $arguments)
        {
            return new class implements CastsAttributes
            {
                public function get($model, $key, $value, $attributes)
                {
                    return new Address(
                        $attributes['address_line_one'],
                        $attributes['address_line_two']
                    );
                }

                public function set($model, $key, $value, $attributes)
                {
                    return [
                        'address_line_one' => $value->lineOne,
                        'address_line_two' => $value->lineTwo,
                    ];
                }
            };
        }
    }
