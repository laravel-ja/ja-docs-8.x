# Eloquent: シリアライズ

- [イントロダクション](#introduction)
- [モデルとコレクションのシリアル化](#serializing-models-and-collections)
    - [配列へのシリアル化](#serializing-to-arrays)
    - [JSONへのシリアル化](#serializing-to-json)
- [JSONから属性を隠す](#hiding-attributes-from-json)
- [JSONへ値の追加](#appending-values-to-json)
- [日付のシリアル化](#date-serialization)

<a name="introduction"></a>
## イントロダクション

Laravelを使用してAPIを構築する場合、モデルとリレーションを配列またはJSONに変換する必要が頻繁にあります。Eloquentには、これらの変換を行うための便利な方法と、モデルのシリアル化された表現に含まれる属性を制御するための便利な方法が含まれています。

> {tip} EloquentモデルとコレクションのJSONシリアル化を処理するさらに堅牢な方法については、[Eloquent APIリソース](/docs/{{version}}/eloquent-resources)のドキュメントを確認してください。

<a name="serializing-models-and-collections"></a>
## モデルとコレクションのシリアル化

<a name="serializing-to-arrays"></a>
### 配列へのシリアル化

モデルとそのロードされた[リレーション](/docs/{{version}}/eloquent-relationships)を配列へ変換するには、`toArray`メソッドを使用する必要があります。このメソッドは再帰的であるため、すべての属性とすべてのリレーション(リレーションのリレーションを含む)を配列へ変換します。

    use App\Models\User;

    $user = User::with('roles')->first();

    return $user->toArray();

`attributesToArray`メソッドを使用して、モデルの属性を配列に変換できますが、そのリレーションは変換できません。

    $user = User::first();

    return $user->attributesToArray();

コレクションインスタンスで`toArray`メソッドを呼び出すことにより、モデルの[コレクション](/docs/{{version}}/eloquent-collections)全体を配列へ変換することもできます。

    $users = User::all();

    return $users->toArray();

<a name="serializing-to-json"></a>
### JSONへのシリアル化

モデルをJSONに変換するには、`toJson`メソッドを使用する必要があります。`toArray`と同様に、`toJson`メソッドは再帰的であるため、すべての属性とリレーションはJSONに変換されます。[PHPがサポートしている](https://secure.php.net/manual/en/function.json-encode.php)JSONエンコーディングオプションを指定することもできます。

    use App\Models\User;

    $user = User::find(1);

    return $user->toJson();

    return $user->toJson(JSON_PRETTY_PRINT);

もしくは、モデルまたはコレクションを文字列にキャストすると、モデルまたはコレクションの`toJson`メソッドが自動的に呼び出されます。

    return (string) User::find(1);

モデルとコレクションは文字列にキャストされるとJSONに変換されるため、アプリケーションのルートまたはコントローラから直接Eloquentオブジェクトを返すことができます。Laravelはルートまたはコントローラから返されるときに、EloquentモデルコレクションをJSONへ自動的にシリアル化します。

    Route::get('users', function () {
        return User::all();
    });

<a name="relationships"></a>
#### リレーション

EloquentモデルをJSONに変換すると、ロードずみのリレーションは自動的にJSONオブジェクトの属性として含まれます。また、Eloquentリレーションシップメソッドは「キャメルケース」メソッド名を使用して定義されますが、リレーションシップのJSON属性は「スネークケース」になります。

<a name="hiding-attributes-from-json"></a>
## JSONから属性を隠す

モデルの配列またはJSON表現に含まれるパスワードなどの属性を制限したい場合があります。これには、モデルへ`$hidden`プロパティを追加します。`$hidden`プロパティの配列にリストされている属性は、モデルのシリアル化された表現には含めません。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 配列に対して非表示にする必要がある属性
         *
         * @var array
         */
        protected $hidden = ['password'];
    }

> {tip} リレーションを非表示にするには、リレーションのメソッド名をEloquentモデルの`$hidden`プロパティに追加します。

もしくは、`visible`プロパティを使用して、モデルの配列とJSON表現に含める必要のある属性の「許可リスト」を定義することもできます。モデルが配列またはJSONに変換されると、`$visible`配列に存在しないすべての属性が非表示になります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 配列に表示する属性
         *
         * @var array
         */
        protected $visible = ['first_name', 'last_name'];
    }

<a name="temporarily-modifying-attribute-visibility"></a>
#### 属性の可視性を一時的に変更

特定のモデルインスタンスで通常は非表示になっている属性を表示したい場合は、`makeVisible`メソッドを使用します。`makeVisible`メソッドはモデルインスタンスを返します:

    return $user->makeVisible('attribute')->toArray();

同様に、通常表示される一部の属性を非表示にする場合は、`makeHidden`メソッドを使用します。

    return $user->makeHidden('attribute')->toArray();

<a name="appending-values-to-json"></a>
## JSONへ値の追加

モデルを配列またはJSONに変換するときに、データベースに対応するカラムがない属性を追加したい場合もまれにあります。これを行うには、最初に値の[アクセサ](/docs/{{version}}/eloquent-mutators)を定義します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * ユーザーが管理者であるかどうかを確認
         *
         * @return bool
         */
        public function getIsAdminAttribute()
        {
            return $this->attributes['admin'] === 'yes';
        }
    }

アクセサを作成したら、モデルの`appends`プロパティに属性名を追加します。アクセサのPHPメソッドが「キャメルケース」を使用して定義されている場合でも、属性名は通常、「スネークケース」のシリアル化された表現を使用して参照されることに注意してください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの配列フォームに追加するアクセサ
         *
         * @var array
         */
        protected $appends = ['is_admin'];
    }

属性を`appends`リストへ追加すると、モデルの配列とJSON表現の両方に含まれます。`appends`配列の属性は、モデルで設定された`visible`および`hidden`設定も尊重します。

<a name="appending-at-run-time"></a>
#### 実行時の追加

実行時に、`append`メソッドを使用して追加の属性を追加するようにモデルインスタンスに指示できます。または、`setAppends`メソッドを使用して、特定のモデルインスタンスに追加されたプロパティの配列全体をオーバーライドすることもできます。

    return $user->append('is_admin')->toArray();

    return $user->setAppends(['is_admin'])->toArray();

<a name="date-serialization"></a>
## 日付のシリアル化

<a name="customizing-the-default-date-format"></a>
#### デフォルトの日付形式のカスタマイズ

`serializeDate`メソッドをオーバーライドすることにより、デフォルトのシリアル化形式をカスタマイズできます。この方法は、データベースに保存するために日付をフォーマットする方法には影響しません。

    /**
     * 配列/JSONシリアル化の日付の準備
     *
     * @param  \DateTimeInterface  $date
     * @return string
     */
    protected function serializeDate(DateTimeInterface $date)
    {
        return $date->format('Y-m-d');
    }

<a name="customizing-the-date-format-per-attribute"></a>
#### 属性ごとの日付形式のカスタマイズ

モデルの[キャスト定義](/docs/{{version}}/eloquent-mutators#attribute-casting)で日付形式を指定することにより、個々のEloquent日付属性のシリアル化形式をカスタマイズできます。

    protected $casts = [
        'birthday' => 'date:Y-m-d',
        'joined_at' => 'datetime:Y-m-d H:00',
    ];
