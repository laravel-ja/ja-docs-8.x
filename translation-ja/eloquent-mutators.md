# Eloquent：ミューテタ

- [イントロダクション](#introduction)
- [アクセサとミューテタ](#accessors-and-mutators)
    - [アクセサの定義](#defining-an-accessor)
    - [ミューテタの定義](#defining-a-mutator)
- [日付ミューテタ](#date-mutators)
- [属性キャスト](#attribute-casting)
    - [カスタムキャスト](#custom-casts)
    - [配列とJSONのキャスト](#array-and-json-casting)
    - [日付のキャスト](#date-casting)
    - [クエリ時のキャスト](#query-time-casting)

<a name="introduction"></a>
## イントロダクション

アクセサとミューテタはモデルの取得や値を設定するときに、Eloquent属性のフォーマットを可能にします。たとえば[Laravelの暗号化](/docs/{{version}}/encryption)を使いデータベース保存時に値を暗号化し、Eloquentモデルでアクセスする時には自動的にその属性を復元するように設定できます。

カスタムのアクセサやミューテタに加え、Eloquentは日付フールドを自動的に[Carbon](https://github.com/briannesbitt/Carbon)インスタンスにキャストしますし、[テキストフィールドをJSONにキャスト](#attribute-casting)することもできます。

<a name="accessors-and-mutators"></a>
## アクセサとミューテタ

<a name="defining-an-accessor"></a>
### アクセサの定義

アクセサを定義するには、アクセスしたいカラム名が「studlyケース（Upper Camel Case）」で`Foo`の場合、`getFooAttribute`メソッドをモデルに作成します。以下の例では、`first_name`属性のアクセサを定義しています。`first_name`属性の値にアクセスが起きると、Eloquentは自動的にこのアクセサを呼び出します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーのファーストネームを取得
         *
         * @param  string  $value
         * @return string
         */
        public function getFirstNameAttribute($value)
        {
            return ucfirst($value);
        }
    }

ご覧の通り、アクセサにはそのカラムのオリジナルの値が渡されますので、それを加工し値を返します。アクセサの値にアクセスするには、モデルインスタンスの`first_name`属性へアクセスしてください。

    $user = App\Models\User::find(1);

    $firstName = $user->first_name;

既存の属性を元に算出した、新しい値をアクセサを使用し返すことも可能です。

    /**
     * ユーザーのフルネーム取得
     *
     * @return string
     */
    public function getFullNameAttribute()
    {
        return "{$this->first_name} {$this->last_name}";
    }

> {tip} これらの計算済みの値をモデルのarray／JSON表現に追加したい場合は、プロパティに[追加する必要があります](/docs/{{version}}/eloquent-serialization#appending-values-to-json)。

<a name="defining-a-mutator"></a>
### ミューテタの定義

ミューテタを定義するにはアクセスしたいカラム名が`Foo`の場合、モデルに「ローワーキャメルケース」で`setFooAttribute`メソッドを作成します。今回も`first_name`属性を取り上げ、ミューテタを定義しましょう。このミューテタはモデルの`first_name`属性へ値を設定する時に自動的に呼びだされます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーのファーストネームを設定
         *
         * @param  string  $value
         * @return void
         */
        public function setFirstNameAttribute($value)
        {
            $this->attributes['first_name'] = strtolower($value);
        }
    }

ミューテタは属性に設定しようとしている値を受け取りますのでこれを加工し、Eloquentモデルの`$attributes`内部プロパティへ加工済みの値を設定します。では`Sally`を`first_name`属性へ設定してみましょう。

    $user = App\Models\User::find(1);

    $user->first_name = 'Sally';

上記の場合、`setFirstNameAttribute`メソッドが呼び出され、`Sally`の値が渡されます。このミューテタはそれから名前に`strtolower`を適用し、その値を`$attributes`内部配列へ設定します。

<a name="date-mutators"></a>
## 日付ミューテタ

デフォルトでEloquentは`created_at`と`updated_at`カラムを[Carbon](https://github.com/briannesbitt/Carbon)インスタンスへ変換します。CarbonはPHPネイティブの`DateTime`クラスを拡張しており、便利なメソッドを色々と提供しています。モデルの`$dates`プロパティをセットすることにより、データ属性を追加できます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 日付を変形する属性
         *
         * @var array
         */
        protected $dates = [
            'seen_at',
        ];
    }

> {tip} モデルの`$timestamps`プロパティを`false`へセットすることにより、デフォルトの`created_at`と`updated_at`タイムスタンプを無効にできます。

日付だと推定されるカラムで、値はUnixタイムスタンプ、日付文字列(`Y-m-d`)、日付時間文字列、`DateTime`や`Carbon`インスタンスを値としてセットできます。日付の値は自動的に正しく変換され、データベースへ保存されます。

    $user = App\Models\User::find(1);

    $user->deleted_at = now();

    $user->save();

前記の通り`$dates`プロパティにリストした属性を取得する場合、自動的に[Carbon](https://github.com/briannesbitt/Carbon)インスタンスへキャストされますので、その属性でCarbonのメソッドがどれでも使用できます。

    $user = App\Models\User::find(1);

    return $user->deleted_at->getTimestamp();

#### Dateフォーマット

デフォルトのタイムスタンプフォーマットは`'Y-m-d H:i:s'`です。タイムスタンプフォーマットをカスタマイズする必要があるなら、モデルの`$dateFormat`プロパティを設定してください。このプロパティは日付属性がデータベースにどのように保存されるかを決定します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルの日付カラムの保存形式
         *
         * @var string
         */
        protected $dateFormat = 'U';
    }

<a name="attribute-casting"></a>
## 属性キャスト

モデルの`$casts`プロパティは属性を一般的なデータタイプへキャストする便利な手法を提供します。`$casts`プロパティは配列で、キーにはキャストする属性名を指定し、値にはそのカラムに対してキャストしたいタイプを指定します。サポートしているキャストタイプは`integer`、`real`、`float`、`double`、`decimal:<桁数>`、`string`、`boolean`、`object`、`array`、`collection`、`date`、`datetime`、`timestamp`です。`decimal`へキャストする場合は、桁数を`decimal:2`のように定義してください。

属性キャストのデモンストレーションとして、データベースには整数の`0`と`1`で保存されている`is_admin`属性を論理値にキャストしてみましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする属性
         *
         * @var array
         */
        protected $casts = [
            'is_admin' => 'boolean',
        ];
    }

これでデータベースには整数で保存されていても`is_admin`属性にアクセスすれば、いつでも論理値にキャストされます。

    $user = App\Models\User::find(1);

    if ($user->is_admin) {
        //
    }

> {note} `null`の属性はキャストされません。さらに、決して関係と同じ名前のキャスト（もしくは属性）を定義してはいけません。

<a name="custom-casts"></a>
### カスタムキャスト

Laravelには多様な利便性のあるキャストタイプが用意されています。しかし、自分自身でキャストタイプを定義する必要が起きることもまれにあります。これを行うには、`CastsAttributes`インターフェイスを実装したクラスを定義してください。

このインターフェイスを実装するクラスでは、`get`と`set`メソッドを定義します。`get`メソッドはデータベースにある元の値をキャストした値へ変換することに責任を持ちます。一方の`set`メソッドはキャストされている値をデータベースに保存できる元の値に変換します。例として、組み込み済みの`json`キャストタイプをカスタムキャストタイプとして再実装してみましょう。

    <?php

    namespace App\Casts;

    use Illuminate\Contracts\Database\Eloquent\CastsAttributes;

    class Json implements CastsAttributes
    {
        /**
         * 指定された値をキャストする
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
         * 指定された値を保存用に準備
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

カスタムキャストタイプが定義できたら、クラス名を使いモデル属性へ指定します。

    <?php

    namespace App\Models;

    use App\Casts\Json;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする属性
         *
         * @var array
         */
        protected $casts = [
            'options' => Json::class,
        ];
    }

#### 値オブジェクトのキャスト

値のキャストはプリミティブタイプに限定されていません。キャスト値をオブジェクトにすることもできます。値をオブジェクトに変換する定義は、プリミティブタイプへの変換にとても似ています。しかしながら、`set`メソッドはキー／値ペアの配列を返す必要があります。モデルへ保存可能な値として、元の値をセットするために使用されます。

例として複数のモデルの値をひとつの`Address`にキャストする、カスタムキャストクラスを定義してみましょう。`Address`値は`lineOne`と`lineTwo`、２つのパブリックプロパティを持つと仮定しましょう。

    <?php

    namespace App\Casts;

    use App\Models\Address as AddressModel;
    use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
    use InvalidArgumentException;

    class Address implements CastsAttributes
    {
        /**
         * 指定された値をキャストする
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
         * 指定された値を保存用に準備
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

値オブジェクトへのキャスト時は、モデルが保存される前に値オブジェクトへ行われた変更が、自動でモデルへ同期されます。

    $user = App\Models\User::find(1);

    $user->address->lineOne = 'Updated Address Value';

    $user->save();

> {tip} 値オブジェクトを含むEloquentモデルをJSONが配列にシリアライズする場合は、値オブジェクトに`Illuminate\Contracts\Support\Arrayable`および` JsonSerializable`インターフェースを実装する必要があります。

#### インバウンドキャスト

モデルから属性を取得するときには何も実行せずに、モデルに保存するときだけ値を変換するカスタムキャストを書く必要があることも稀にあるでしょう。インバウンドのみのキャストの古典的な例は「ハッシュ」キャストです。インバウンドオンリーのカスタムキャストは`CastsInboundAttributes`インターフェイスを実装し、`set`メソッドを定義する必要だけがあります。

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
         * 新キャストクラスインスタンスの生成
         *
         * @param  string|null  $algorithm
         * @return void
         */
        public function __construct($algorithm = null)
        {
            $this->algorithm = $algorithm;
        }

        /**
         * 指定された値を保存用に準備
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

#### キャストのパラメータ

モデルへカスタムキャストを指定するとき、キャストのパラメータをクラス名と`:`文字で区切り指定できます。カンマで区切り、複数パラメータを渡せます。このパラメータはキャストクラスのコンストラクタへ渡されます。

    /**
     * キャストする属性
     *
     * @var array
     */
    protected $casts = [
        'secret' => Hash::class.':sha256',
    ];

#### Castable

モデルにカスタムキャストを指定する代わりに、`Illuminate\Contracts\Database\Eloquent\Castable`インターフェイスを実装するクラスを指定することも可能です。

    protected $casts = [
        'address' => \App\Models\Address::class,
    ];

`Castable`インターフェイスを実装するオブジェクトは、`castUsing`メソッドを定義する必要があります。このメソッドは、キャストに責任を持つカスタムキャスタクラスのクラス名を返します。

    <?php

    namespace App\Models;

    use Illuminate\Contracts\Database\Eloquent\Castable;
    use App\Casts\Address as AddressCast;

    class Address implements Castable
    {
        /**
         * キャスト対象をキャストするときに使用するキャスタクラス名を取得
         *
         * @return string
         */
        public static function castUsing()
        {
            return AddressCast::class;
        }
    }

`Castable`クラス使用時も、`$casts`定義中で引数を指定可能です。引数はキャスタクラスへ直接渡されます。

    protected $casts = [
        'address' => \App\Models\Address::class.':argument',
    ];

<a name="array-and-json-casting"></a>
### 配列とJSONのキャスト

`array`キャストタイプは、シリアライズされたJSON形式で保存されているカラムを取り扱う場合とくに便利です。たとえば、データベースにシリアライズ済みのJSONを持つ`JSON`か`TEXT`フィールドがある場合です。その属性に`array`キャストを追加すれば、Eloquentモデルにアクセスされた時点で自動的に非シリアライズ化され、PHPの配列へとキャストされます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * キャストする属性
         *
         * @var array
         */
        protected $casts = [
            'options' => 'array',
        ];
    }

キャストを定義後、`options`属性にアクセスすると自動的に非シリアライズされPHP配列になります。`options`属性へ値をセットすると配列は保存のために自動的にJSONへシリアライズされます。

    $user = App\Models\User::find(1);

    $options = $user->options;

    $options['key'] = 'value';

    $user->options = $options;

    $user->save();

より簡潔な構文でJSON属性のフィールドを１つ更新するには、`->`演算子が使用できます。

    $user = App\Models\User::find(1);

    $user->update(['options->key' => 'value']);

<a name="date-casting"></a>
### 日付のキャスト

`date`や`datetime`キャストタイプを使用する場合、日付のフォーマットを指定できます。このフォーマットは、[モデルを配列やJSONへシリアライズする](/docs/{{version}}/eloquent-serialization)場合に使用します。

    /**
     * キャストする属性
     *
     * @var array
     */
    protected $casts = [
        'created_at' => 'datetime:Y-m-d',
    ];

<a name="query-time-casting"></a>
### クエリ時のキャスト

テーブルから元の値でセレクトするときのように、クエリ実行時にキャストを適用する必要が稀に起きます。例として以下のクエリを考えてください。

    use App\Models\Post;
    use App\Models\User;

    $users = User::select([
        'users.*',
        'last_posted_at' => Post::selectRaw('MAX(created_at)')
                ->whereColumn('user_id', 'users.id')
    ])->get();

このクエリ結果上の`last_posted_at`属性は元の文字列です。クエリ実行時にこの属性に対して、`date`キャストを適用できると便利です。そのためには、`withCasts`メソッドを使用します。

    $users = User::select([
        'users.*',
        'last_posted_at' => Post::selectRaw('MAX(created_at)')
                ->whereColumn('user_id', 'users.id')
    ])->withCasts([
        'last_posted_at' => 'datetime'
    ])->get();
