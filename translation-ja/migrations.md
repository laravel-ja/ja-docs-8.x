# マイグレーション

- [イントロダクション](#introduction)
- [マイグレーションの生成](#generating-migrations)
    - [マイグレーションの圧縮](#squashing-migrations)
- [マイグレーションの構造](#migration-structure)
- [マイグレーションの実行](#running-migrations)
    - [マイグレーションのロールバック](#rolling-back-migrations)
- [テーブル](#tables)
    - [テーブルの生成](#creating-tables)
    - [テーブルの更新](#updating-tables)
    - [テーブルのリネーム／削除](#renaming-and-dropping-tables)
- [カラム](#columns)
    - [カラムの生成](#creating-columns)
    - [利用可能なカラムタイプ](#available-column-types)
    - [カラム修飾子](#column-modifiers)
    - [カラムの変更](#modifying-columns)
    - [カラムの削除](#dropping-columns)
- [インデックス](#indexes)
    - [インデックスの生成](#creating-indexes)
    - [インデックスのリネーム](#renaming-indexes)
    - [インデックスの削除](#dropping-indexes)
    - [外部キー制約](#foreign-key-constraints)

<a name="introduction"></a>
## イントロダクション

マイグレーションはデータベースのバージョン管理のようなもので、チームがアプリケーションのデータベーススキーマを定義および共有できるようにします。ソース管理から変更を取得した後に、ローカルデータベーススキーマにカラムを手動で追加するようにチームメートに指示する必要があったことを経験していれば、データベースのマイグレーションにより解決される問題に直面していたのです。

Laravelの`Schema`[ファサード](/docs/{{version}}/facades)は、Laravelがサポートするすべてのデータベースシステムに対し、テーブルを作成、操作するために特定のデータベースに依存しないサポートを提供します。通常、マイグレーションはこのファサードを使用して、データベースのテーブルとカラムを作成および変更します。

<a name="generating-migrations"></a>
## マイグレーションの生成

`make:migration` [Artisanコマンド](/docs/{{version}}/artisan)を使用して、データベースマイグレーションを生成します。新しいマイグレーションは、`database/migrations`ディレクトリに配置されます。各マイグレーションファイル名には、Laravelがマイグレーションの順序を決定できるようにするタイムスタンプを含めています。

    php artisan make:migration create_flights_table

`--table`や`--create`オプションを使用して、テーブルの名前とマイグレーションにより新しいテーブルを作成するかを指定します。これらのオプションは、生成するマイグレーションファイルへ指定したテーブル名をあらかじめ取り込ませます。

    php artisan make:migration create_flights_table --create=flights

    php artisan make:migration add_destination_to_flights_table --table=flights

生成するマイグレーションのカスタムパスを指定する場合は、`make:migration`コマンドを実行するときに`--path`オプションを使用します。指定したパスは、アプリケーションのベースパスを基準にする必要があります。

> {tip} マイグレーションのスタブは[スタブのリソース公開](/docs/{{version}}/artisan#stub-customization)を使用してカスタマイズできます。

<a name="squashing-migrations"></a>
### マイグレーションの圧縮

アプリケーションを構築していくにつれ、時間の経過とともに段々と多くのマイグレーションが蓄積されていく可能性があります。これにより、`database/migrations`ディレクトリが数百のマイグレーションで肥大化する可能性があります。必要に応じて、マイグレーションを単一のSQLファイルに「圧縮」できます。利用するには、`schema:dump`コマンドを実行します。

    php artisan schema:dump

    // 現在のデータベーススキーマをダンプし、既存のすべての移行を削除
    php artisan schema:dump --prune

このコマンドを実行すると、Laravelは「スキーマ」ファイルをアプリケーションの`database/schema`ディレクトリに書き込みます。これ以降、データベースをマイグレーションするときに、まだ他のマイグレーションが実行されていない場合、Laravelは最初にスキーマファイルのSQLステートメントを実行します。スキーマファイルのステートメントを実行した後、Laravelはスキーマダンプのに入っていない残りのマイグレーションを実行します。

チームの新しい開発者がアプリケーションの初期データベース構造をすばやく作成できるようにするため、データベーススキーマファイルはソース管理にコミットすべきでしょう。

> {note} マイグレーションの圧縮は、MySQL、PostgreSQL、SQLiteデータベースでのみ使用できます。ただし、スキーマダンプはSQLiteデータベースのインメモリには、復元されない場合があります。

<a name="migration-structure"></a>
## マイグレーションの構造

移行クラスには、`up`と`down`の2つのメソッドを用意します。`up`メソッドはデータベースに新しいテーブル、カラム、またはインデックスを追加するために使用します。`down`メソッドでは、`up`メソッドによって実行する操作を逆にし、以前の状態へ戻す必要があります。

これらの両方のメソッド内で、Laravelスキーマビルダを使用して、テーブルを明示的に作成および変更できます。`Schema`ビルダで利用可能なすべてのメソッドを学ぶには、[ドキュメントをチェックしてください](#creating-tables)。たとえば、次のマイグレーションでは、`flights`テーブルが作成されます。

    <?php

    use Illuminate\Database\Migrations\Migration;
    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    class CreateFlightsTable extends Migration
    {
        /**
         * マイグレーションの実行
         *
         * @return void
         */
        public function up()
        {
            Schema::create('flights', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('airline');
                $table->timestamps();
            });
        }

        /**
         * マイグレーションを戻す
         *
         * @return void
         */
        public function down()
        {
            Schema::drop('flights');
        }
    }

<a name="running-migrations"></a>
## マイグレーションの実行

未処理のマイグレーションをすべて実行するには、`migrate` Artisanコマンドを実行します。

    php artisan migrate

<a name="forcing-migrations-to-run-in-production"></a>
#### マイグレーションを強制的に本番環境で実行する

一部のマイグレーション操作は破壊的です。つまり、データーが失われる可能性を持っています。本番データベースに対してこれらのコマンドを実行しないように保護するために、コマンドを実行する前に確認を求めるプロンプトが表示されます。プロンプトなしでコマンドを強制的に実行するには、`--force`フラグを使用します。

    php artisan migrate --force

<a name="rolling-back-migrations"></a>
### マイグレーションのロールバック

最新のマイグレーション操作をロールバックするには、`rollback` Artisanコマンドを使用します。このコマンドは、マイグレーションの最後の「バッチ」をロールバックします。これは、複数のマイグレーションファイルを含む場合があります。

    php artisan migrate:rollback

`rollback`コマンドに`step`オプションを提供することにより、限られた数のマイグレーションをロールバックできます。たとえば、次のコマンドは最後の5つのマイグレーションをロールバックします。

    php artisan migrate:rollback --step=5

`migrate：reset`コマンドは、アプリケーションのすべてのマイグレーションをロールバックします。

    php artisan migrate:reset

<a name="roll-back-migrate-using-a-single-command"></a>
#### 単一コマンドでロールバックとマイグレーション実行

`migrate:refresh`コマンドは、すべてのマイグレーションをロールバックしてから、`migrate`コマンドを実行します。このコマンドは、データベース全体を効果的に再作成します。

    php artisan migrate:refresh

    // データベースを更新し、すべてのデータベース初期値設定を実行
    php artisan migrate:refresh --seed

`refresh`コマンドに`step`オプションを指定し、特定の数のマイグレーションをロールバックしてから再マイグレーションできます。たとえば、次のコマンドは、最後の５マイグレーションをロールバックして再マイグレーションします。

    php artisan migrate:refresh --step=5

<a name="drop-all-tables-migrate"></a>
#### すべてのテーブルを削除後にマイグレーション

`migrate:fresh`コマンドは、データベースからすべてのテーブルを削除したあと、`migrate`コマンドを実行します。

    php artisan migrate:fresh

    php artisan migrate:fresh --seed

> {note} `migrate:fresh`コマンドは、プレフィックスに関係なく、すべてのデータベーステーブルを削除します。このコマンドは、他のアプリケーションと共有されているデータベースで開発している場合は注意して使用する必要があります。

<a name="tables"></a>
## テーブル

<a name="creating-tables"></a>
### テーブルの生成

新しいデータベーステーブルを作成するには、`Schema`ファサードで`create`メソッドを使用します。`create`メソッドは２つの引数を取ります。１つ目はテーブルの名前で、２つ目は新しいテーブルを定義するために使用できる`Blueprint`オブジェクトを受け取るクロージャです。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::create('users', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('email');
        $table->timestamps();
    });

テーブルを作成するときは、スキーマビルダの[カラムメソッド](#creating-columns)のいずれかを使用して、テーブルのカラムを定義します。

<a name="checking-for-table-column-existence"></a>
#### テーブル／カラムの存在の確認

`hasTable`および`hasColumn`メソッドを使用して、テーブルまたは列の存在を確認できます。

    if (Schema::hasTable('users')) {
        // "users"テーブルは存在していた
    }

    if (Schema::hasColumn('users', 'email')) {
        // "email"カラムを持つ"users"テーブルが存在していた
    }

<a name="database-connection-table-options"></a>
#### データベース接続とテーブルオプション

アプリケーションのデフォルトではないデータベース接続でスキーマ操作を実行する場合は、`connection`メソッドを使用します。

    Schema::connection('sqlite')->create('users', function (Blueprint $table) {
        $table->id();
    });

さらに、他のプロパティやメソッドを使用して、テーブル作成の他の部分を定義できます。`engine`プロパティはMySQLを使用するときにテーブルのストレージエンジンを指定するために使用します。

    Schema::create('users', function (Blueprint $table) {
        $table->engine = 'InnoDB';

        // ...
    });

`charset`プロパティと`collat​​ion`プロパティはMySQLを使用するときに、作成されたテーブルの文字セットと照合順序を指定するために使用します。

    Schema::create('users', function (Blueprint $table) {
        $table->charset = 'utf8mb4';
        $table->collation = 'utf8mb4_unicode_ci';

        // ...
    });

`temporary`メソッドを使用して、テーブルを「一時的」にする必要があることを示すことができます。一時テーブルは、現在の接続のデータベースセッションにのみ表示され、接続が閉じられると自動的に削除されます。

    Schema::create('calculations', function (Blueprint $table) {
        $table->temporary();

        // ...
    });

<a name="updating-tables"></a>
### テーブルの更新

`Schema`ファサードの`table`メソッドを使用して、既存のテーブルを更新できます。`create`メソッドと同様に、`table`メソッドは２つの引数を取ります。テーブルの名前とテーブルにカラムやインデックスを追加するために使用できる`Blueprint`インスタンスを受け取るクロージャです。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->integer('votes');
    });

<a name="renaming-and-dropping-tables"></a>
### テーブルのリネーム／削除

既存のデータベーステーブルの名前を変更するには、`rename`メソッドを使用します。

    use Illuminate\Support\Facades\Schema;

    Schema::rename($from, $to);

既存のテーブルを削除するには、`drop`または`dropIfExists`メソッドを使用できます。

    Schema::drop('users');

    Schema::dropIfExists('users');

<a name="renaming-tables-with-foreign-keys"></a>
#### 外部キーを使用したテーブルのリネーム

テーブルをリネームする前に、Laravelのテーブル名ベースの命名規約で外部キーを割り当てさせるのではなく、マイグレーションファイルでテーブルの外部キー制約の名前を明示的に指定していることを確認する必要があります。そうでない場合、外部キー制約名は古いテーブル名で参照されることになるでしょう。

<a name="columns"></a>
## カラム

<a name="creating-columns"></a>
### カラムの生成

`Schema`ファサードの`table`メソッドを使用して、既存のテーブルを更新できます。`create`メソッドと同様に、`table`メソッドは２つの引数を取ります。テーブルの名前とテーブルに列を追加するために使用できる`Illuminate\Database\Schema\Blueprint`インスタンスを受け取るクロージャです。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->integer('votes');
    });

<a name="available-column-types"></a>
### 利用可能なカラムタイプ

スキーマビルダのBlueprintは、データベーステーブルに追加できるさまざまなタイプのカラムに対応する、多くのメソッドを提供しています。使用可能な各メソッドを以下に一覧します。

<style>
    #collection-method-list > p {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    #collection-method-list a {
        display: block;
    }
</style>

<div id="collection-method-list" markdown="1">
[bigIncrements](#column-method-bigIncrements)
[bigInteger](#column-method-bigInteger)
[binary](#column-method-binary)
[boolean](#column-method-boolean)
[char](#column-method-char)
[dateTimeTz](#column-method-dateTimeTz)
[dateTime](#column-method-dateTime)
[date](#column-method-date)
[decimal](#column-method-decimal)
[double](#column-method-double)
[enum](#column-method-enum)
[float](#column-method-float)
[foreignId](#column-method-foreignId)
[geometryCollection](#column-method-geometryCollection)
[geometry](#column-method-geometry)
[id](#column-method-id)
[increments](#column-method-increments)
[integer](#column-method-integer)
[ipAddress](#column-method-ipAddress)
[json](#column-method-json)
[jsonb](#column-method-jsonb)
[lineString](#column-method-lineString)
[longText](#column-method-longText)
[macAddress](#column-method-macAddress)
[mediumIncrements](#column-method-mediumIncrements)
[mediumInteger](#column-method-mediumInteger)
[mediumText](#column-method-mediumText)
[morphs](#column-method-morphs)
[multiLineString](#column-method-multiLineString)
[multiPoint](#column-method-multiPoint)
[multiPolygon](#column-method-multiPolygon)
[nullableMorphs](#column-method-nullableMorphs)
[nullableTimestamps](#column-method-nullableTimestamps)
[nullableUuidMorphs](#column-method-nullableUuidMorphs)
[point](#column-method-point)
[polygon](#column-method-polygon)
[rememberToken](#column-method-rememberToken)
[set](#column-method-set)
[smallIncrements](#column-method-smallIncrements)
[smallInteger](#column-method-smallInteger)
[softDeletesTz](#column-method-softDeletesTz)
[softDeletes](#column-method-softDeletes)
[string](#column-method-string)
[text](#column-method-text)
[timeTz](#column-method-timeTz)
[time](#column-method-time)
[timestampTz](#column-method-timestampTz)
[timestamp](#column-method-timestamp)
[timestampsTz](#column-method-timestampsTz)
[timestamps](#column-method-timestamps)
[tinyIncrements](#column-method-tinyIncrements)
[tinyInteger](#column-method-tinyInteger)
[unsignedBigInteger](#column-method-unsignedBigInteger)
[unsignedDecimal](#column-method-unsignedDecimal)
[unsignedInteger](#column-method-unsignedInteger)
[unsignedMediumInteger](#column-method-unsignedMediumInteger)
[unsignedSmallInteger](#column-method-unsignedSmallInteger)
[unsignedTinyInteger](#column-method-unsignedTinyInteger)
[uuidMorphs](#column-method-uuidMorphs)
[uuid](#column-method-uuid)
[year](#column-method-year)
</div>

<a name="column-method-bigIncrements"></a>
#### `bigIncrements()` {#collection-method .first-collection-method}

`bigIncrements`メソッドは、自動増分する`UNSIGNED BIGINT`(主キー)カラムを作成します。

    $table->bigIncrements('id');

<a name="column-method-bigInteger"></a>
#### `bigInteger()` {#collection-method}

`bigInteger`メソッドは`BIGINT`カラムを作成します。

    $table->bigInteger('votes');

<a name="column-method-binary"></a>
#### `binary()` {#collection-method}

`binary`メソッドは`BLOB`カラムを作成します。

    $table->binary('photo');

<a name="column-method-boolean"></a>
#### `boolean()` {#collection-method}

`boolean`メソッドは`BOOLEAN`カラムを作成します。

    $table->boolean('confirmed');

<a name="column-method-char"></a>
#### `char()` {#collection-method}

`char`メソッドは、指定した長さの`CHAR`カラムを作成します。

    $table->char('name', 100);

<a name="column-method-dateTimeTz"></a>
#### `dateTimeTz()` {#collection-method}

`dateTimeTz`メソッドは、オプションの精度(合計桁数)で`DATETIME`(タイムゾーン付き)カラムを作成します。

    $table->dateTimeTz('created_at', $precision = 0);

<a name="column-method-dateTime"></a>
#### `dateTime()` {#collection-method}

`dateTime`メソッドは、オプションの精度(合計桁数)で`DATETIME`カラムを作成します。

    $table->dateTime('created_at', $precision = 0);

<a name="column-method-date"></a>
#### `date()` {#collection-method}

`date`メソッドは`DATE`カラムを作成します。

    $table->date('created_at');

<a name="column-method-decimal"></a>
#### `decimal()` {#collection-method}

`decimal`メソッドは、指定した精度(合計桁数)とスケール(少数桁数)で`DECIMAL`カラムを作成します。

    $table->decimal('amount', $precision = 8, $scale = 2);

<a name="column-method-double"></a>
#### `double()` {#collection-method}

`double`メソッドは、指定した精度(合計桁数)とスケール(少数桁数)で`DOUBLE`カラムを作成します。

    $table->double('amount', 8, 2);

<a name="column-method-enum"></a>
#### `enum()` {#collection-method}

`enum`メソッドは、指定した有効な値で`ENUM`カラムを作成します。

    $table->enum('difficulty', ['easy', 'hard']);

<a name="column-method-float"></a>
#### `float()` {#collection-method}

`float`メソッドは、指定した精度(合計桁数)とスケール(少数桁数)で`FLOAT`カラムを作成します。

    $table->float('amount', 8, 2);

<a name="column-method-foreignId"></a>
#### `foreignId()` {#collection-method}

`foreignId`メソッドは`unsignedBigInteger`メソッドのエイリアスです。

    $table->foreignId('user_id');

<a name="column-method-geometryCollection"></a>
#### `geometryCollection()` {#collection-method}

`geometryCollection`メソッドは`GEOMETRYCOLLECTION`カラムを作成します。

    $table->geometryCollection('positions');

<a name="column-method-geometry"></a>
#### `geometry()` {#collection-method}

`geometry`メソッドは`GEOMETRY`カラムを作成します。

    $table->geometry('positions');

<a name="column-method-id"></a>
#### `id()` {#collection-method}

`id`メソッドは`bigIncrements`メソッドのエイリアスです。デフォルトでは、メソッドは`id`カラムを作成します。ただし、カラムに別の名前を割り当てたい場合は、カラム名を渡すことができます。

    $table->id();

<a name="column-method-increments"></a>
#### `increments()` {#collection-method}

`increments`メソッドは、主キーとして自動増分の`UNSIGNEDINTEGER`カラムを作成します。

    $table->increments('id');

<a name="column-method-integer"></a>
#### `integer()` {#collection-method}

`integer`メソッドは` INTEGER`カラムを作成します。

    $table->integer('votes');

<a name="column-method-ipAddress"></a>
#### `ipAddress()` {#collection-method}

`ipAddress`メソッドは`INTEGER`カラムを作成します。

    $table->ipAddress('visitor');

<a name="column-method-json"></a>
#### `json()` {#collection-method}

`json`メソッドは`JSON`カラムを作成します。

    $table->json('options');

<a name="column-method-jsonb"></a>
#### `jsonb()` {#collection-method}

`jsonb`メソッドは`JSONB`カラムを作成します。

    $table->jsonb('options');

<a name="column-method-lineString"></a>
#### `lineString()` {#collection-method}

`lineString`メソッドは`LINESTRING`カラムを作成します。

    $table->lineString('positions');

<a name="column-method-longText"></a>
#### `longText()` {#collection-method}

`longText`メソッドは`LONGTEXT`カラムを作成します。

    $table->longText('description');

<a name="column-method-macAddress"></a>
#### `macAddress()` {#collection-method}

`macAddress`メソッドは、MACアドレスを保持することを目的としたカラムを作成します。PostgreSQLなどの一部のデータベースシステムには、このタイプのデータ専用のカラムタイプがあります。他のデータベースシステムでは、文字カラムに相当するカラムを使用します。

    $table->macAddress('device');

<a name="column-method-mediumIncrements"></a>
#### `mediumIncrements()` {#collection-method}

`mediumIncrements`メソッドは、主キーが自動増分の`UNSIGNED MEDIUMINT`カラムを作成します。

    $table->mediumIncrements('id');

<a name="column-method-mediumInteger"></a>
#### `mediumInteger()` {#collection-method}

`mediumInteger`メソッドは`MEDIUMINT`カラムを作成します。

    $table->mediumInteger('votes');

<a name="column-method-mediumText"></a>
#### `mediumText()` {#collection-method}

`mediumText`メソッドは`MEDIUMTEXT`カラムを作成します。

    $table->mediumText('description');

<a name="column-method-morphs"></a>
#### `morphs()` {#collection-method}

`morphs`メソッドは、`{column}_id` `UNSIGNED BIGINT`カラムと、`{column}_type` `VARCHAR`カラムを追加する便利なメソッドです。

このメソッドは、ポリモーフィック[Eloquentリレーション](/docs/{{version}}/eloquent-relationships)に必要なカラムを定義するときに使用することを目的としています。次の例では、`taggable_id`カラムと`taggable_type`カラムが作成されます。

    $table->morphs('taggable');

<a name="column-method-multiLineString"></a>
#### `multiLineString()` {#collection-method}

`multiLineString`メソッドは`MULTILINESTRING`カラムを作成します。

    $table->multiLineString('positions');

<a name="column-method-multiPoint"></a>
#### `multiPoint()` {#collection-method}

`multiPoint`メソッドは`MULTIPOINT`カラムを作成します。

    $table->multiPoint('positions');

<a name="column-method-multiPolygon"></a>
#### `multiPolygon()` {#collection-method}

`multiPolygon`メソッドは`MULTIPOLYGON`カラムを作成します。

    $table->multiPolygon('positions');

<a name="column-method-nullableTimestamps"></a>
#### `nullableTimestamps()` {#collection-method}

このメソッドは、[timestamps](#column-method-timestamps)メソッドに似ています。ただし、作成するカラムは"NULLABLE"になります。

    $table->nullableTimestamps(0);

<a name="column-method-nullableMorphs"></a>
#### `nullableMorphs()` {#collection-method}

このメソッドは、[morphs](#column-method-morphs)メソッドに似ています。ただし、作成するカラムは"NULLABLE"になります。

    $table->nullableMorphs('taggable');

<a name="column-method-nullableUuidMorphs"></a>
#### `nullableUuidMorphs()` {#collection-method}

このメソッドは、[uuidMorphs](#column-method-uuidMorphs)メソッドに似ています。ただし、作成するカラムは"NULLABLE"になります。

    $table->nullableUuidMorphs('taggable');

<a name="column-method-point"></a>
#### `point()` {#collection-method}

The `point` method creates an `POINT` equivalent column:
`point`メソッドは`POINT`カラムを作成します。

    $table->point('position');

<a name="column-method-polygon"></a>
#### `polygon()` {#collection-method}

`polygon`メソッドは`POLYGON`カラムを作成します。

    $table->polygon('position');

<a name="column-method-rememberToken"></a>
#### `rememberToken()` {#collection-method}

`rememberToken`メソッドは、現在の「ログイン持続（"remember me"）」[認証トークン](/docs/{{version}}/authentication#remembering-users)を格納することを目的としたNULL許容の`VARCHAR(100)`相当のカラムを作成します。

    $table->rememberToken();

<a name="column-method-set"></a>
#### `set()` {#collection-method}

`set`メソッドは、指定した有効な値のリストを使用して、`SET`カラムを作成します。

    $table->set('flavors', ['strawberry', 'vanilla']);

<a name="column-method-smallIncrements"></a>
#### `smallIncrements()` {#collection-method}

`smallIncrements`メソッドは、主キーとして自動増分の`UNSIGNED SMALLINT`カラムを作成します。

    $table->smallIncrements('id');

<a name="column-method-smallInteger"></a>
#### `smallInteger()` {#collection-method}

`smallInteger`メソッドは`SMALLINT`カラムを作成します。

    $table->smallInteger('votes');

<a name="column-method-softDeletesTz"></a>
#### `softDeletesTz()` {#collection-method}

`softDeletesTz`メソッドは、オプションの精度(合計桁数)でNULL許容の`deleted_at` `TIMESTAMP`(タイムゾーン付き)カラムを追加します。このカラムは、Eloquentの「ソフトデリート」機能に必要な`deleted_at`タイムスタンプを格納するためのものです。

    $table->softDeletesTz($column = 'deleted_at', $precision = 0);

<a name="column-method-softDeletes"></a>
#### `softDeletes()` {#collection-method}

`softDeletes`メソッドは、オプションの精度(合計桁数)でNULL許容の`deleted_at` `TIMESTAMP`カラムを追加します。このカラムは、Eloquentの「ソフトデリート」機能に必要な`deleted_at`タイムスタンプを格納するためのものです。

    $table->softDeletes($column = 'deleted_at', $precision = 0);

<a name="column-method-string"></a>
#### `string()` {#collection-method}

`string`メソッドは、指定された長さの`VARCHAR`カラムを作成します。

    $table->string('name', 100);

<a name="column-method-text"></a>
#### `text()` {#collection-method}

`text`メソッドは`TEXT`カラムを作成します。

    $table->text('description');

<a name="column-method-timeTz"></a>
#### `timeTz()` {#collection-method}

`timeTz`メソッドは、オプションの精度(合計桁数)で`TIME`(タイムゾーン付き)カラムを作成します。

    $table->timeTz('sunrise', $precision = 0);

<a name="column-method-time"></a>
#### `time()` {#collection-method}

`time`メソッドは、オプションの精度（合計桁数）で`TIME`カラムを作成します。

    $table->time('sunrise', $precision = 0);

<a name="column-method-timestampTz"></a>
#### `timestampTz()` {#collection-method}

`timestampTz`メソッドは、オプションの精度(合計桁数)で`TIMESTAMP`(タイムゾーン付き)カラムを作成します。

    $table->timestampTz('added_at', $precision = 0);

<a name="column-method-timestamp"></a>
#### `timestamp()` {#collection-method}

`timestamp`メソッドは、オプションの精度(合計桁数)で`TIMESTAMP`カラムを作成します。

    $table->timestamp('added_at', $precision = 0);

<a name="column-method-timestampsTz"></a>
#### `timestampsTz()` {#collection-method}

`timestampsTz`メソッドは、オプションの精度(合計桁数)で`created_at`および`updated_at`　`TIMESTAMP`(タイムゾーン付き)カラムを作成します。

    $table->timestampsTz($precision = 0);

<a name="column-method-timestamps"></a>
#### `timestamps()` {#collection-method}

`timestamps`メソッドは、オプションの精度(合計桁数)で`created_at`および`updated_at`　`TIMESTAMP`カラムを作成します。

    $table->timestamps($precision = 0);

<a name="column-method-tinyIncrements"></a>
#### `tinyIncrements()` {#collection-method}

`tinyIncrements`メソッドは、主キーとして自動増分の`UNSIGNED TINYINT`カラムを作成します。

    $table->tinyIncrements('id');

<a name="column-method-tinyInteger"></a>
#### `tinyInteger()` {#collection-method}

`tinyInteger`メソッドは`TINYINT`カラムを作成します。

    $table->tinyInteger('votes');

<a name="column-method-unsignedBigInteger"></a>
#### `unsignedBigInteger()` {#collection-method}

`unsignedBigInteger`メソッドは`UNSIGNED BIGINT`カラムを作成します。

    $table->unsignedBigInteger('votes');

<a name="column-method-unsignedDecimal"></a>
#### `unsignedDecimal()` {#collection-method}

`unsignedDecimal`メソッドは、オプションの精度(合計桁数)とスケール(少数桁数)を使用して、`UNSIGNED DECIMAL`カラムを作成します。

    $table->unsignedDecimal('amount', $precision = 8, $scale = 2);

<a name="column-method-unsignedInteger"></a>
#### `unsignedInteger()` {#collection-method}

`unsignedInteger`メソッドは`UNSIGNED INTEGER`カラムを作成します。

    $table->unsignedInteger('votes');

<a name="column-method-unsignedMediumInteger"></a>
#### `unsignedMediumInteger()` {#collection-method}

`unsignedMediumInteger`メソッドは、`UNSIGNED　MEDIUMINT`カラムを作成します。

    $table->unsignedMediumInteger('votes');

<a name="column-method-unsignedSmallInteger"></a>
#### `unsignedSmallInteger()` {#collection-method}

`unsignedSmallInteger`メソッドは`UNSIGNED SMALLINT`カラムを作成します。

    $table->unsignedSmallInteger('votes');

<a name="column-method-unsignedTinyInteger"></a>
#### `unsignedTinyInteger()` {#collection-method}

`unsignedTinyInteger`メソッドは` UNSIGNED　TINYINT`カラムを作成します。

    $table->unsignedTinyInteger('votes');

<a name="column-method-uuidMorphs"></a>
#### `uuidMorphs()` {#collection-method}

`uuidMorphs`メソッドは、`{column}_id` `CHAR(36)`カラムと、`{column}_type` `VARCHAR`カラムを追加する便利なメソッドです。

このメソッドは、UUID識別子を使用するポリモーフィックな[Eloquentリレーション](/docs/{{version}}/eloquent-relationships)に必要なカラムを定義するときに使用します。以下の例では、`taggable_id`カラムと`taggable_type`カラムが作成されます。

    $table->uuidMorphs('taggable');

<a name="column-method-uuid"></a>
#### `uuid()` {#collection-method}

`uuid`メソッドは`UUID`カラムを作成します。

    $table->uuid('id');

<a name="column-method-year"></a>
#### `year()` {#collection-method}

`year`メソッドは`YEAR`カラムを作成します。

    $table->year('birth_year');

<a name="column-modifiers"></a>
### カラム修飾子

上記リストのカラムタイプに加え、データベーステーブルにカラムを追加するときに使用できるカラム「修飾子」もあります。たとえば、カラムを"NULLABLE"へするために、`nullable`メソッドが使用できます。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->string('email')->nullable();
    });

次の表は、使用可能なすべてのカラム修飾子を紹介しています。このリストには[インデックス修飾子](#creating-indexes)は含まれていません。

就職し  |  説明
--------  |  -----------
`->after('column')`  |  カラムを別のカラムの「後に」配置（MySQL）
`->autoIncrement()`  |  INTEGERカラムを自動増分（主キー）として設定
`->charset('utf8mb4')`  |  カラムの文字セットを指定（MySQL）
`->collation('utf8mb4_unicode_ci')`  |  カラムの照合順序を指定（MySQL／PostgreSQL／SQL Server）
`->comment('my comment')`  |  カラムにコメントを追加（MySQL/PostgreSQL）
`->default($value)`  |  カラムの「デフォルト」値を指定
`->first()`  |  テーブルの「最初の」カラムを配置（MySQL）
`->from($integer)`  |  自動増分フィールドの開始値を設定（MySQL / PostgreSQL）
`->nullable($value = true)`  |  NULL値をカラムに保存可能に設定
`->storedAs($expression)`  |  stored generatedカラムを作成（MySQL）
`->unsigned()`  |  INTEGERカラムをUNSIGNEDとして設定（MySQL）
`->useCurrent()`  |  CURRENT_TIMESTAMPをデフォルト値として使用するようにTIMESTAMPカラムを設定
`->useCurrentOnUpdate()`  |  レコードが更新されたときにCURRENT_TIMESTAMPを使用するようにTIMESTAMPカラムを設定
`->virtualAs($expression)`  |  virtual generatedカラムを作成（MySQL）
`->generatedAs($expression)`  |  指定のシーケンスオプションで、識別カラムを生成（PostgreSQL）
`->always()`  |  IDカラムの入力に対するシーケンス値の優先順位を定義（PostgreSQL）

<a name="default-expressions"></a>
#### デフォルト式

`default`修飾子は、値または`Illuminate\Database\Query\Expression`インスタンスを受け入れます。`Expression`インスタンスを使用すると、Laravelが値を引用符で囲むのを防ぎ、データベース固有の関数を使用できるようになります。これがとくに役立つ状況の１つは、JSONカラムにデフォルト値を割り当てる必要がある場合です。

    <?php

    use Illuminate\Support\Facades\Schema;
    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Database\Query\Expression;
    use Illuminate\Database\Migrations\Migration;

    class CreateFlightsTable extends Migration
    {
        /**
         * マイグレーションの実行
         *
         * @return void
         */
        public function up()
        {
            Schema::create('flights', function (Blueprint $table) {
                $table->id();
                $table->json('movies')->default(new Expression('(JSON_ARRAY())'));
                $table->timestamps();
            });
        }
    }

> {note} デフォルト式のサポートは、データベースドライバー、データベースバージョン、およびフィールドタイプによって異なります。データベースのドキュメントを参照してください。

<a name="modifying-columns"></a>
### カラムの変更

<a name="prerequisites"></a>
#### 前提条件

カラムを変更する前に、Composerパッケージマネージャーを使用して`doctrine/dbal`パッケージをインストールする必要があります。DoctrineDBALライブラリは、カラムの現在の状態を判別し、カラムに要求された変更を加えるために必要なSQLクエリを作成するのに使用します。

    composer require doctrine/dbal

<a name="updating-column-attributes"></a>
#### カラム属性の更新

`change`メソッドを使用すると、既存のカラムのタイプと属性を変更できます。たとえば、`string`カラムのサイズを大きくしたい場合があります。`change`メソッドの動作を確認するために、`name`カラムのサイズを25から50に増やしてみましょう。これを実行するには、カラムの新しい状態を定義してから、`change`メソッドを呼び出します。

    Schema::table('users', function (Blueprint $table) {
        $table->string('name', 50)->change();
    });

カラムをNULLABLEへ変更することもできます。

    Schema::table('users', function (Blueprint $table) {
        $table->string('name', 50)->nullable()->change();
    });

> {note} 以降のカラムタイプを変更できます。`bigInteger`、`binary`、`boolean`、`date`、`dateTime`、`dateTimeTz`、`decimal`、`integer`、`json`、`longText`、`mediumText`、`smallInteger`、`string`、`text`、`time`、`unsignedBigInteger`、`unsignedInteger`、`unsignedSmallInteger`、`uuid`。

<a name="renaming-columns"></a>
#### カラムのりネーム

カラムをリネームするには、スキーマビルダBlueprintが提供する`renameColumn`メソッドを使用します。カラムの名前を変更する前に、Composerパッケージマネージャーを介して`doctrine/dbal`ライブラリをインストールしていることを確認してください。

    Schema::table('users', function (Blueprint $table) {
        $table->renameColumn('from', 'to');
    });

> {note} `enum`カラムの名前変更は現在サポートしていません。

<a name="dropping-columns"></a>
### カラムの削除

カラムを削除するには、スキーマビルダのBlueprintで`dropColumn`メソッドを使用します。アプリケーションがSQLiteデータベースを利用している場合、`dropColumn`メソッドを使用する前に、Composerパッケージマネージャーを介して`doctrine/dbal`パッケージをインストールする必要があります。

    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('votes');
    });

カラム名の配列を`dropColumn`メソッドに渡すことにより、テーブルから複数のカラムを削除できます。

    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn(['votes', 'avatar', 'location']);
    });

> {note} SQLiteデータベースの使用時に、１回のマイグレーションで複数のカラムを削除または変更することはサポートしていません。

<a name="available-command-aliases"></a>
#### 使用可能なコマンドエイリアス

Laravelは、一般的なタイプのカラムの削除の便利な方法を提供しています。各メソッドは以下の表で説明します。

コマンド  |  説明
-------  |  -----------
`$table->dropMorphs('morphable');`  |  `morphable_id`カラムと`morphable_type`カラムを削除
`$table->dropRememberToken();`  |  `remember_token`カラムを削除
`$table->dropSoftDeletes();`  |  `deleted_at`カラムを削除
`$table->dropSoftDeletesTz();`  |  `dropSoftDeletes（）`メソッドのエイリアス
`$table->dropTimestamps();`  |  `created_at`カラムと`updated_at`カラムを削除
`$table->dropTimestampsTz();` |  `dropTimestamps（）`メソッドのエイリアス

<a name="indexes"></a>
## インデックス

<a name="creating-indexes"></a>
### インデックスの生成

Laravelスキーマビルダは多くのタイプのインデックスをサポートしています。次の例では、新しい`email`カラムを作成し、その値が一意であることを指定しています。インデックスを作成するには、`unique`メソッドをカラム定義にチェーンします。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->string('email')->unique();
    });

または、カラムを定義した後にインデックスを作成することもできます。これを行うには、スキーマビルダBlueprintで`unique`メソッドを呼び出す必要があります。このメソッドは、一意のインデックスを受け取る必要があるカラムの名前を引数に取ります。

    $table->unique('email');

カラムの配列をindexメソッドに渡して、複合インデックスを作成することもできます。

    $table->index(['account_id', 'created_at']);

インデックスを作成するとき、Laravelはテーブル、カラム名、およびインデックスタイプに基づいてインデックス名を自動的に生成しますが、メソッドに2番目の引数を渡して、インデックス名を自分で指定することもできます。

    $table->unique('email', 'unique_email');

<a name="available-index-types"></a>
#### 利用可能なインデックスタイプ

LaravelのスキーマビルダBlueprintクラスは、Laravelでサポートしている各タイプのインデックスを作成するメソッドを提供しています。各indexメソッドは、オプションの２番目の引数を取り、インデックスの名前を指定します。省略した場合、名前は、インデックスに使用されるテーブルとカラムの名前、およびインデックスタイプから派生します。使用可能な各インデックスメソッドは、以下の表で説明します。

コマンド  |  説明
-------  |  -----------
`$table->primary('id');`  |  主キーを追加
`$table->primary(['id', 'parent_id']);`  |  複合キーを追加
`$table->unique('email');`  |  一意のインデックスを追加
`$table->index('state');`  |  インデックスを追加
`$table->spatialIndex('location');`  |  空間インデックスを追加（SQLiteを除く）

<a name="index-lengths-mysql-mariadb"></a>
#### インデックスの長さとMySQL／MariaDB

デフォルトでは、Laravelは`utf8mb4`文字セットを使用します。5.7.7リリースより古いバージョンのMySQLまたは10.2.2リリースより古いMariaDBを実行している場合、MySQLがそれらのインデックスを作成するために、マイグレーションによって生成されるデフォルトの文字カラム長を手動で設定する必要が起きます。`App\Providers\AppServiceProvider`クラスの`boot`メソッド内で`Schema::defaultStringLength`メソッドを呼び出し、デフォルトの文字カラムの長さを設定できます。

    use Illuminate\Support\Facades\Schema;

    /**
     * 全アプリケーションサービスの初期設定
     *
     * @return void
     */
    public function boot()
    {
        Schema::defaultStringLength(191);
    }

または、データベースの`innodb_large_prefix`オプションを有効にすることもできます。このオプションを適切に有効にする方法については、データベースのドキュメントを参照してください。

<a name="renaming-indexes"></a>
### インデックスのリネーム

インデックスの名前を変更するには、スキーマビルダBlueprintが提供する`renameIndex`メソッドを使用します。このメソッドは、現在のインデックス名を最初の引数として取り、目的の名前を２番目の引数として取ります。

    $table->renameIndex('from', 'to')

<a name="dropping-indexes"></a>
### インデックスの削除

インデックスを削除するには、インデックスの名前を指定する必要があります。デフォルトでは、Laravelはテーブル名、インデックス付きカラムの名前、およびインデックスタイプに基づいてインデックス名を自動的に割り当てます。ここではいくつかの例を示します。

コマンド  |  説明
-------  |  -----------
`$table->dropPrimary('users_id_primary');`  |  "users"テーブルから主キーを削除
`$table->dropUnique('users_email_unique');`  |  "users"テーブルから一意のインデックスを削除
`$table->dropIndex('geo_state_index');`  |  "geo"テーブルから基本インデックスを削除
`$table->dropSpatialIndex('geo_location_spatialindex');`  |  "geo"テーブルから空間インデックスを削除（SQLiteを除く）

インデックスを削除するメソッドにカラムの配列を渡すと、テーブル名、カラム、およびインデックスタイプに基づいてインデックス名が生成されます。

    Schema::table('geo', function (Blueprint $table) {
        $table->dropIndex(['state']); // Drops index 'geo_state_index'
    });

<a name="foreign-key-constraints"></a>
### 外部キー制約

Laravelは、データベースレベルで参照整合性を強制するために使用される外部キー制約の作成もサポートしています。たとえば、`users`テーブルの`id`カラムを参照する`posts`テーブルの`user_id`カラムを定義しましょう。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('posts', function (Blueprint $table) {
        $table->unsignedBigInteger('user_id');

        $table->foreign('user_id')->references('id')->on('users');
    });

この構文はかなり冗長であるため、Laravelは、より良い開発者エクスペリエンスを提供するために規約を使用した追加の簡潔なメソッドを提供します。上記の例は、次のように書き直すことができます。

    Schema::table('posts', function (Blueprint $table) {
        $table->foreignId('user_id')->constrained();
    });

`foreignId`メソッドは`unsignedBigInteger`のエイリアスですが、`constrained`メソッドは規約を使用して参照されるテーブルとカラムの名前を決定します。テーブル名がLaravelの規則と一致しない場合は、引数として`constrained`メソッドに渡すことでテーブル名を指定できます。

    Schema::table('posts', function (Blueprint $table) {
        $table->foreignId('user_id')->constrained('users');
    });


必要なアクションに"on delete"や"on update"の制約プロパティを指定することもできます。

    $table->foreignId('user_id')
          ->constrained()
          ->onUpdate('cascade')
          ->onDelete('cascade');

追加の[カラム修飾子](#column-modifiers)は、`constrained`メソッドの前に呼び出す必要があります。

    $table->foreignId('user_id')
          ->nullable()
          ->constrained();

<a name="dropping-foreign-keys"></a>
#### 外部キーの削除

外部キーを削除するには、`dropForeign`メソッドを使用して、削除する外部キー制約の名前を引数として渡してください。外部キー制約は、インデックスと同じ命名規約を使用しています。つまり、外部キー制約名は、制約内のテーブルとカラムの名前に基づいており、その後に「\_foreign」サフィックスが続きます。

    $table->dropForeign('posts_user_id_foreign');

または、外部キーを保持するカラム名を含む配列を`dropForeign`メソッドに渡すこともできます。配列は、Laravelの制約命名規約を使用して外部キー制約名に変換されます。

    $table->dropForeign(['user_id']);

<a name="toggling-foreign-key-constraints"></a>
#### 外部キー制約の切り替え

次の方法を使用して、マイグレーション内の外部キー制約を有効または無効にできます。

    Schema::enableForeignKeyConstraints();

    Schema::disableForeignKeyConstraints();

> {note} SQLiteは、デフォルトで外部キー制約を無効にします。SQLiteを使用する場合は、マイグレーションでデータベースを作成する前に、データベース設定の[外部キーサポートを有効にする](/docs/{{version}}/database#configuration)を確実に行ってください。さらに、SQLiteはテーブルの作成時にのみ外部キーをサポートし、[テーブルを変更する場合はサポートしません](https://www.sqlite.org/omitted.html)。
