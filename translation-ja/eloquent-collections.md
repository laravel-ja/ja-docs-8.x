# Eloquent:コレクション

- [イントロダクション](#introduction)
- [利用可能なメソッド](#available-methods)
- [カスタムコレクション](#custom-collections)

<a name="introduction"></a>
## イントロダクション

`get`メソッドで取得した結果や、リレーションによりアクセスした結果など、結果として複数のモデルを返すEloquentメソッドはすべて、`Illuminate\Database\Eloquent\Collection`クラスのインスタンスを返します。EloquentコレクションオブジェクトはLaravelの[基本的なコレクション](/docs/{{version}}/collections)を拡張しているため、基になるEloquentモデルの配列を流暢に操作するため使用する数十のメソッドを自然と継承します。これらの便利な方法についてすべて学ぶために、Laravelコレクションのドキュメントは必ず確認してください！

すべてのコレクションはイテレーターとしても機能し、単純なPHP配列であるかのようにループで使えます。

    use App\Models\User;

    $users = User::where('active', 1)->get();

    foreach ($users as $user) {
        echo $user->name;
    }

ただし、前述のようにコレクションは配列よりもはるかに強力であり、直感的なインターフェイスを使用してチェーンする可能性を持つさまざまなマップ/リデュース操作を用意しています。たとえば、非アクティブなモデルをすべて削除してから、残りのユーザーの名を収集する場面を考えましょう。

    $names = User::all()->reject(function ($user) {
        return $user->active === false;
    })->map(function ($user) {
        return $user->name;
    });

<a name="eloquent-collection-conversion"></a>
#### Eloquentコレクションの変換

ほとんどのEloquentコレクションメソッドはEloquentコレクションの新しいインスタンスを返しますが、`collapse`、`flatten`、`flip`、`keys`、`pluck`、`zip`メソッドは、[基本のコレクション](/docs/{{version}}/collections)インスタンスを返します。同様に、`map`操作がEloquentモデルを含まないコレクションを返す場合、それは基本コレクションインスタンスに変換されます。

<a name="available-methods"></a>
## 利用可能なメソッド

すべてのEloquentコレクションはベースの[Laravelコレクション](/docs/{{version}}/collections#available-methods)オブジェクトを拡張します。したがって、これらは基本コレクションクラスによって提供されるすべての強力なメソッドを継承します。

さらに、`Illuminate\Database\Eloquent\Collection`クラスは、モデルコレクションの管理を支援するメソッドのスーパーセットを提供します。ほとんどのメソッドは`Illuminate\Database\Eloquent\Collection`インスタンスを返します。ただし、`modelKeys`などの一部のメソッドは、`Illuminate\Support\Collection`インスタンスを返します。

<style>
    #collection-method-list > p {
        column-count: 1; -moz-column-count: 1; -webkit-column-count: 1;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    #collection-method-list a {
        display: block;
    }
</style>

<div id="collection-method-list" markdown="1">

[contains](#method-contains)
[diff](#method-diff)
[except](#method-except)
[find](#method-find)
[fresh](#method-fresh)
[intersect](#method-intersect)
[load](#method-load)
[loadMissing](#method-loadMissing)
[modelKeys](#method-modelKeys)
[makeVisible](#method-makeVisible)
[makeHidden](#method-makeHidden)
[only](#method-only)
[toQuery](#method-toquery)
[unique](#method-unique)

</div>

<a name="method-contains"></a>
#### `contains($key, $operator = null, $value = null)`

`contains`メソッドを使い、指定モデルインスタンスがコレクションに含まれているかどうかを判定できます。このメソッドは、主キーまたはモデルインスタンスを引数に取ります。

    $users->contains(1);

    $users->contains(User::find(1));

<a name="method-diff"></a>
#### `diff($items)`

`diff`メソッドは、指定コレクションに存在しないすべてのモデルを返します。

    use App\Models\User;

    $users = $users->diff(User::whereIn('id', [1, 2, 3])->get());

<a name="method-except"></a>
#### `except($keys)`

`except`メソッドは、指定する主キーを持たないすべてのモデルを返します。

    $users = $users->except([1, 2, 3]);

<a name="method-find"></a>
#### `find($key)` {#collection-method .first-collection-method}

`find`メソッドは、指定キーと一致する主キーを持つモデルを返します。`$key`がモデルインスタンスの場合、`find`は主キーに一致するモデルを返そうとします。`$key`がキーの配列である場合、`find`は指定配列の中の主キーを持つすべてのモデルを返します。

    $users = User::all();

    $user = $users->find(1);

<a name="method-fresh"></a>
#### `fresh($with = [])`

`fresh`メソッドは、データベースからコレクション内の各モデルの新しいインスタンスを取得します。さらに、指定したリレーションはすべてEagerロードされます。

    $users = $users->fresh();

    $users = $users->fresh('comments');

<a name="method-intersect"></a>
#### `intersect($items)`

`intersect`メソッドは、指定コレクションにも存在するすべてのモデルを返します。

    use App\Models\User;

    $users = $users->intersect(User::whereIn('id', [1, 2, 3])->get());

<a name="method-load"></a>
#### `load($relations)`

`load`メソッドは、コレクション内のすべてのモデルに対して指定するリレーションをEagerロードします。

    $users->load(['comments', 'posts']);

    $users->load('comments.author');

<a name="method-loadMissing"></a>
#### `loadMissing($relations)`

`loadMissing`メソッドは、関係がまだロードされていない場合、コレクション内のすべてのモデルに対して指定するリレーションをEagerロードします。

    $users->loadMissing(['comments', 'posts']);

    $users->loadMissing('comments.author');

<a name="method-modelKeys"></a>
#### `modelKeys()`

`modelKeys`メソッドは、コレクション内のすべてのモデルの主キーを返します。

    $users->modelKeys();

    // [1, 2, 3, 4, 5]

<a name="method-makeVisible"></a>
#### `makeVisible($attributes)`

`makeVisible`メソッドは、通常コレクション内の各モデルで"hidden"になっている[属性をvisibleにします](/docs/{{version}}/eloquent-serialization#hiding-attributes-from-json)。

    $users = $users->makeVisible(['address', 'phone_number']);

<a name="method-makeHidden"></a>
#### `makeHidden($attributes)`

`makeHidden`メソッドは、通常コレクション内の各モデルで"visible"になっている[属性をhiddenにします](/docs/{{version}}/eloquent-serialization#hiding-attributes-from-json)。

    $users = $users->makeHidden(['address', 'phone_number']);

<a name="method-only"></a>
#### `only($keys)`

`only`メソッドは、指定主キーを持つすべてのモデルを返します。

    $users = $users->only([1, 2, 3]);

<a name="method-toquery"></a>
#### `toQuery()`

`toQuery`メソッドは、コレクションモデルの主キーに対する`whereIn`制約を含むEloquentクエリビルダインスタンスを返します。

    use App\Models\User;

    $users = User::where('status', 'VIP')->get();

    $users->toQuery()->update([
        'status' => 'Administrator',
    ]);

<a name="method-unique"></a>
#### `unique($key = null, $strict = false)`

`unique`メソッドは、コレクション内のすべての一意のモデルを返します。コレクション内の、同じタイプで同じ主キーを持つモデルをすべて削除します。

    $users = $users->unique();

<a name="custom-collections"></a>
## カスタムコレクション

特定のモデルを操作するときにカスタムの`Collection`オブジェクトを使用したい場合は、モデルで`newCollection`メソッドを定義します。

    <?php

    namespace App\Models;

    use App\Support\UserCollection;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 新しいEloquentCollectionインスタンスの作成
         *
         * @param  array  $models
         * @return \Illuminate\Database\Eloquent\Collection
         */
        public function newCollection(array $models = [])
        {
            return new UserCollection($models);
        }
    }

`newCollection`メソッドを一度定義したら、Eloquentが通常`Illuminate\Database\Eloquent\Collection`インスタンスを返すときは、いつでもカスタムコレクションのインスタンスを受け取ります。アプリケーションのすべてのモデルにカスタムコレクションを使用する場合は、アプリケーションのすべてのモデルによって拡張される基本モデルクラスで`newCollection`メソッドを定義する必要があります。
