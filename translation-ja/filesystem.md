# ファイルストレージ

- [イントロダクション](#introduction)
- [設定](#configuration)
    - [パブリックディスク](#the-public-disk)
    - [ローカルディスク](#the-local-driver)
    - [ドライバ要件](#driver-prerequisites)
    - [キャッシュ](#caching)
- [ディスクインスタンス取得](#obtaining-disk-instances)
- [ファイル取得](#retrieving-files)
    - [ファイルのダウンロード](#downloading-files)
    - [ファイルURL](#file-urls)
    - [ファイルパス](#file-paths)
    - [ファイルメタ情報](#file-metadata)
- [ファイル保存](#storing-files)
    - [ファイルアップロード](#file-uploads)
    - [ファイル視認性](#file-visibility)
- [ファイル削除](#deleting-files)
- [ディレクトリ](#directories)
- [カスタムファイルシステム](#custom-filesystems)

<a name="introduction"></a>
## イントロダクション

LaravelはFrank de Jongeさんが作成した拝みたいほど素晴らしい、抽象ファイルシステムである[Flysystem](https://github.com/thephpleague/flysystem) PHPパッケージを提供しています。Laravel Flysystem統合は、ローカルのファイルシステムとAmazon S3をシンプルに操作できるドライバを提供しています。さらに素晴らしいことにそれぞれのシステムに対し同じAPIを使用しているため、ストレージをとても簡単に変更できるのです。

<a name="configuration"></a>
## 設定

ファイルシステムの設定ファイルは、`config/filesystems.php`です。このファイルの中に全「ディスク」の設定があります。それぞれのディスクは特定のストレージドライバと保存場所を表します。設定ファイルにはサポート済みのドライバそれぞれの設定例を用意しています。ですからストレージの設定と認証情報を反映するように、設定オプションを簡単に修正できます。

好きなだけディスクを設定できますし、同じドライバに対し複数のディスクを持つことも可能です。

<a name="the-public-disk"></a>
### パブリックディスク

`public`ディスクは一般公開へのアクセスを許すファイルを意味しています。デフォルトの`public`ディスクは、`local`ドライバを使用しており、`storage/app/public`下に存在しているファイルです。Webからのアクセスを許すには、`public/storage`から`storage/app/public`へシンボリックリンクを張る必要があります。この手法により、公開ファイルを一つのディレクトリへ留め、[Envoyer](https://envoyer.io)のようなリリース時のダウンタイムが起きない開発システムを使っている場合、各リリース間でファイルを簡単に共有できます。

シンボリックリンクを張るには、`storage:link` Artisanコマンドを使用します。

    php artisan storage:link

ファイルを保存し、シンボリックリンクを張ったら、`asset`ヘルパを使いファイルへのURLを生成できます。

    echo asset('storage/file.txt');

`filesystems`設定ファイルで追加のシンボリックリンクを設定可能です。各設定リンクは`storage:link`コマンドを実行し、生成可能です。

    'links' => [
        public_path('storage') => storage_path('app/public'),
        public_path('images') => storage_path('app/images'),
    ],

<a name="the-local-driver"></a>
### ローカルディスク

`local`ドライバを使う場合、`filesystems`設定ファイルで指定した`root`ディレクトリからの相対位置で全ファイル操作が行われることに注意してください。デフォルトでこの値は`storage/app`ディレクトリに設定されています。そのため次のメソッドでファイルは`storage/app/file.txt`として保存されます。

    Storage::disk('local')->put('file.txt', 'Contents');

<a name="permissions"></a>
#### パーミッション

`public`下の[パーミッション](#file-visibility)は、ディレクトリへ`0755`、ファイルへ`0664`を設定します。パーミッションは`filesystems`設定ファイルで変更可能です。

    'local' => [
        'driver' => 'local',
        'root' => storage_path('app'),
        'permissions' => [
            'file' => [
                'public' => 0664,
                'private' => 0600,
            ],
            'dir' => [
                'public' => 0775,
                'private' => 0700,
            ],
        ],
    ],

<a name="driver-prerequisites"></a>
### ドライバ要件

<a name="composer-packages"></a>
#### Composerパッケージ

SFTPかS3ドライバを使う前に、Composerで適切なパッケージをインストールしておく必要があります。

- SFTP: `league/flysystem-sftp ~1.0`
- Amazon S3: `league/flysystem-aws-s3-v3 ~1.0`

パフォーマンスを上げるため、絶対に必要なのはキャッシュアダプタです。そのためには、追加のパッケージが必要です。

- CachedAdapter: `league/flysystem-cached-adapter ~1.0`

<a name="s3-driver-configuration"></a>
#### S3ドライバ設定

S3ドライバの設定情報は、`config/filesystems.php`設定ファイルにあります。このファイルはS3ドライバの設定配列のサンプルを含んでいます。この配列を自由に、自分のS3設定と認証情報に合わせて、変更してください。使いやすいように、環境変数はAWSで使用されている命名規約に合わせてあります。

<a name="ftp-driver-configuration"></a>
#### FTPドライバ設定

Laravelのファイルシステム統合はFTPでも動作します。しかし、デフォルトでは、フレームワークの`filesystems.php`設定ファイルに、サンプルの設定を含めていません。FTPファイルシステムを設定する必要がある場合は、以下の設定例を利用してください。

    'ftp' => [
        'driver' => 'ftp',
        'host' => 'ftp.example.com',
        'username' => 'your-username',
        'password' => 'your-password',

        // FTP設定のオプション
        // 'port' => 21,
        // 'root' => '',
        // 'passive' => true,
        // 'ssl' => true,
        // 'timeout' => 30,
    ],

<a name="sftp-driver-configuration"></a>
#### SFTPドライバ設定

Laravelのファイルシステム統合はSFTPできちんと動作します。しかし、デフォルトでは、フレームワークの`filesystems.php`設定ファイルに、サンプルの設定を含めていません。SFTPファイルシステムを設定する必要がある場合は、以下の設定例を利用してください。

    'sftp' => [
        'driver' => 'sftp',
        'host' => 'example.com',
        'username' => 'your-username',
        'password' => 'your-password',

        // SSH keyベースの認証の設定
        // 'privateKey' => '/path/to/privateKey',
        // 'password' => 'encryption-password',

        // FTP設定のオプション
        // 'port' => 22,
        // 'root' => '',
        // 'timeout' => 30,
    ],

<a name="caching"></a>
### キャッシュ

特定のディスクでキャッシュを有効にするには、ディスクの設定オプションに、`cache`ディレクティブを追加してください。`cache`オプションは、`disk`名、`expire`期間を秒数、キャッシュの`prefix`を含むオプションの配列です。

    's3' => [
        'driver' => 's3',

        // 他のディスクの設定…

        'cache' => [
            'store' => 'memcached',
            'expire' => 600,
            'prefix' => 'cache-prefix',
        ],
    ],

<a name="obtaining-disk-instances"></a>
## ディスクインスタンス取得

`Storage`ファサードを使い設定済みのディスクへの操作ができます。たとえばこのファサードの`put`メソッドを使用し、デフォルトディスクにアバターを保存できます。`Storage`ファサードのメソッド呼び出しで最初に`disk`メソッドを呼び出さない場合、そのメソッドの呼び出しは自動的にデフォルトディスクに対し実行されます。

    use Illuminate\Support\Facades\Storage;

    Storage::put('avatars/1', $fileContents);

複数ディスクを使用する場合、`Storage`ファサードの`disk`メソッドを使用し特定のディスクへアクセスできます。

    Storage::disk('s3')->put('avatars/1', $fileContents);

<a name="retrieving-files"></a>
## ファイル取得

`get`メソッドは指定したファイルの内容を取得するために使用します。ファイル内容がそのまま、メソッドより返されます。ファイルパスはすべて、ディスクに設定した「ルート(root)」からの相対位置で指定することを思い出してください。

    $contents = Storage::get('file.jpg');

`exists`メソッドは指定したディスクにファイルが存在しているかを判定するために使用します。

    $exists = Storage::disk('s3')->exists('file.jpg');

`missing`メソッドは、そのディスクにファイルが存在しないことを判定するために使用します。

    $missing = Storage::disk('s3')->missing('file.jpg');

<a name="downloading-files"></a>
### ファイルのダウンロード

`download`メソッドは、指定したパスへファイルをダウンロードするように、ユーザーのブラウザへ強制するレスポンスを生成するために使用します。`download`メソッドはファイル名を第２引数として受け取り、ダウンロード先のファイル名を指定します。最後に第３引数として、HTTPヘッダの配列を渡せます。

    return Storage::download('file.jpg');

    return Storage::download('file.jpg', $name, $headers);

<a name="file-urls"></a>
### ファイルURL

指定したファイルのURLを取得するには、`url`メソッドを使います。`local`ドライバを使用している場合、通常このメソッドは指定したパスの先頭に`/storage`を付け、そのファイルへの相対パスを返します。`s3`ドライバを使用している場合、完全なリモートURLを返します。

    use Illuminate\Support\Facades\Storage;

    $url = Storage::url('file.jpg');

`local`ドライバーを使用する場合、一般に公開するすべてのファイルは`storage/app/public`ディレクトリに配置する必要があります。さらに、`public/storage`から`storage/app/public`ディレクトリへ[シンボリックリンクを張る](#the-public-disk)必要もあります。

> {note} `local`ドライバーを使用する場合、`url`の戻り値はURLエンコードされません。このため、有効なURLを作成する名前を使用してファイルを保存することをお勧めします。

<a name="temporary-urls"></a>
#### 一時的なURL

`s3`ドライバを使用して保存したファイルに対し、指定ファイルの一時的なURLを作成する場合は、`temporaryUrl`メソッドを使用します。このメソッドはパスとURLの有効期限を指定する、`DateTime`インスタンスを引数に取ります。

    $url = Storage::temporaryUrl(
        'file.jpg', now()->addMinutes(5)
    );

追加の[S3リクエストパラメータ](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectGET.html#RESTObjectGET-requests)を指定する必要がある場合は、`temporaryUrl`メソッドの第３引数へリクエストパラメータの配列を渡してください。

    $url = Storage::temporaryUrl(
        'file.jpg',
        now()->addMinutes(5),
        [
            'ResponseContentType' => 'application/octet-stream',
            'ResponseContentDisposition' => 'attachment; filename=file2.jpg',
        ]
    );

<a name="url-host-customization"></a>
#### URLホストカスタマイズ

`Storage`ファサードを使用し生成したファイルURLに対するホストを事前定義したい場合は、ディスク設定配列へ`url`オプションを追加してください。

    'public' => [
        'driver' => 'local',
        'root' => storage_path('app/public'),
        'url' => env('APP_URL').'/storage',
        'visibility' => 'public',
    ],

<a name="file-paths"></a>
### ファイルパス

`path`メソッドを使い、指定ファイルのパスを取得できます。`local`ドライバーを使用している場合、これはファイルの絶対パスを返します。`s3`ドライバーを使用している場合、このメソッドはS3バケット内におけるファイルの相対パスを返します。

    use Illuminate\Support\Facades\Storage;

    $path = Storage::path('file.jpg');

<a name="file-metadata"></a>
### ファイルメタ情報

ファイルの読み書きに加え、Laravelはファイル自体に関する情報も提供します。たとえば、`size`メソッドはファイルサイズをバイトで取得するために、使用します。

    use Illuminate\Support\Facades\Storage;

    $size = Storage::size('file.jpg');

`lastModified`メソッドは最後にファイルが更新された時のUnixタイムスタンプを返します。

    $time = Storage::lastModified('file.jpg');

<a name="storing-files"></a>
## ファイル保存

`put`メソッドはファイル内容をディスクへ保存するために使用します。`put`メソッドにはPHPの`resource`も渡すことができ、Flysystemの裏で動いているストリームサポートを使用します。すべてのファイルパスは、ディスクの"root"として設定した場所からの相対位置で指定する必要があることを忘ないでください。

    use Illuminate\Support\Facades\Storage;

    Storage::put('file.jpg', $contents);

    Storage::put('file.jpg', $resource);

<a name="automatic-streaming"></a>
#### 自動ストリーミング

指定したファイル位置のファイルのストリーミングを自動的にLaravelに管理させたい場合は、`putFile`か`putFileAs`メソッドを使います。このメソッドは、`Illuminate\Http\File`か`Illuminate\Http\UploadedFile`のインスタンスを引数に取り、希望する場所へファイルを自動的にストリームします。

    use Illuminate\Http\File;
    use Illuminate\Support\Facades\Storage;

    // 自動的に一意のIDがファイル名として指定される
    Storage::putFile('photos', new File('/path/to/photo'));

    // ファイル名を指定する
    Storage::putFileAs('photos', new File('/path/to/photo'), 'photo.jpg');

`putFile`メソッドにはいくつか重要な注意点があります。ファイル名ではなく、ディレクトリ名を指定することに注意してください。`putFile`メソッドは一意のIDを保存ファイル名として生成します。ファイルの拡張子は、MIMEタイプの検査により決まります。`putFile`メソッドからファイルへのパスが返されますので、生成されたファイル名も含めたパスをデータベースへ保存できます。

`putFile`と`putFileAs`メソッドはさらに、保存ファイルの「視認性」を指定する引数も受け付けます。これはとくにS3などのクラウドディスクにファイルを保存し、一般公開の視認性を設定したい場合に便利です。

    Storage::putFile('photos', new File('/path/to/photo'), 'public');

<a name="prepending-appending-to-files"></a>
#### ファイルの先頭／末尾への追加

`prepend`と`append`メソッドで、ファイルの初めと終わりに内容を追加できます。

    Storage::prepend('file.log', 'Prepended Text');

    Storage::append('file.log', 'Appended Text');

<a name="copying-moving-files"></a>
#### ファイルコピーと移動

`copy`メソッドは、存在するファイルをディスク上の新しい場所へコピーするために使用します。一方の`move`メソッドはリネームや存在するファイルを新しい場所へ移動するために使用します。

    Storage::copy('old/file.jpg', 'new/file.jpg');

    Storage::move('old/file.jpg', 'new/file.jpg');

<a name="file-uploads"></a>
### ファイルアップロード

Webアプリケーションで、ファイルを保存する一般的なケースは、ユーザーがプロファイル画像や写真、ドキュメントをアップロードする場合でしょう。アップロードファイルインスタンスに`store`メソッドを使えば、アップロードファイルの保存はLaravelで簡単に行なえます。アップロードファイルを保存したいパスを指定し、`store`メソッドを呼び出してください。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;

    class UserAvatarController extends Controller
    {
        /**
         * ユーザーのアバターの更新
         *
         * @param  Request  $request
         * @return Response
         */
        public function update(Request $request)
        {
            $path = $request->file('avatar')->store('avatars');

            return $path;
        }
    }

この例には重要な点が含まれています。ファイル名ではなく、ディレクトリ名を指定している点に注目です。デフォルトで`store`メソッドは、一意のIDをファイル名として生成します。ファイルの拡張子は、MIMEタイプの検査により決まります。`store`メソッドからファイルパスが返されますので、生成されたファイル名を含めた、そのファイルパスをデータベースに保存できます。

上の例と同じ操作を行うため、`Storage`ファサードの`putFile`メソッドを呼び出すこともできます。

    $path = Storage::putFile('avatars', $request->file('avatar'));

<a name="specifying-a-file-name"></a>
#### ファイル名の指定

保存ファイルが自動的に命名されたくなければ、ファイルパスとファイル名、（任意で）ディスクを引数に持つ`storeAs`メソッドを使ってください。

    $path = $request->file('avatar')->storeAs(
        'avatars', $request->user()->id
    );

上記の例と同じファイル操作を行う、`Storage`ファサードの`putFileAs`メソッドも使用できます。

    $path = Storage::putFileAs(
        'avatars', $request->file('avatar'), $request->user()->id
    );

> {note} 印刷できない、または無効なユニコードは自動的にファイルパスから削除されます。そのため、Laravelのファイルストレージメソッドに渡す前に、ファイルパスをサニタライズしましょう。ファイルパスのノーマライズは、`League\Flysystem\Util::normalizePath`メソッドを使います。

<a name="specifying-a-disk"></a>
#### ディスクの指定

デフォルトで、`store`メソッドはデフォルトディスクを使用します。他のディスクを指定したい場合は第２引数として、ディスク名を渡してください。

    $path = $request->file('avatar')->store(
        'avatars/'.$request->user()->id, 's3'
    );

`storeAs`メソッドを使う場合は、ディスク名を第３引数としてメソッドに渡してください。

    $path = $request->file('avatar')->storeAs(
        'avatars',
        $request->user()->id,
        's3'
    );

<a name="other-file-information"></a>
#### 他のファイル情報

アップロードしたファイルの元の名前を知りたい場合は、`getClientOriginalName`メソッドを使います。

    $name = $request->file('avatar')->getClientOriginalName();

アップロードしたファイルの拡張子を知りたい場合は、`extension`メソッドを使います。

    $extension = $request->file('avatar')->extension();

<a name="file-visibility"></a>
### ファイル視認性

LaravelのFlysystem統合では、複数のプラットフォームにおけるファイルパーミッションを「視認性」として抽象化しています。ファイルは`public`か`private`のどちらかとして宣言します。ファイルを`public`として宣言するのは、他からのアクセスを全般的に許可することを表明することです。たとえば、S3ドライバ使用時には、`public`ファイルのURLを取得することになります。

`put`メソッドでファイルをセットする時に、視認性を設定できます。

    use Illuminate\Support\Facades\Storage;

    Storage::put('file.jpg', $contents, 'public');

もし、ファイルがすでに保存済みであるなら、`getVisibility`と`setVisibility`により、視認性を取得／設定できます。

    $visibility = Storage::getVisibility('file.jpg');

    Storage::setVisibility('file.jpg', 'public');

アップロード済みファイルを取り扱うときは、`public`の視認性を付け保存するために、`storePublicly`か`storePubliclyAs`メソッドを使ってください。

    $path = $request->file('avatar')->storePublicly('avatars', 's3');

    $path = $request->file('avatar')->storePubliclyAs(
        'avatars',
        $request->user()->id,
        's3'
    );

<a name="deleting-files"></a>
## ファイル削除

`delete`メソッドはディスクから削除するファイルを単独、もしくは配列で受け付けます。

    use Illuminate\Support\Facades\Storage;

    Storage::delete('file.jpg');

    Storage::delete(['file.jpg', 'file2.jpg']);

必要であれば、削除先のディスクを指定できます。

    use Illuminate\Support\Facades\Storage;

    Storage::disk('s3')->delete('folder_path/file_name.jpg');

<a name="directories"></a>
## ディレクトリ

<a name="get-all-files-within-a-directory"></a>
#### ディレクトリの全ファイル取得

`files`メソッドは指定したディレクトリの全ファイルの配列を返します。指定したディレクトリのサブディレクトリにある全ファイルのリストも取得したい場合は、`allFiles`メソッドを使ってください。

    use Illuminate\Support\Facades\Storage;

    $files = Storage::files($directory);

    $files = Storage::allFiles($directory);

<a name="get-all-directories-within-a-directory"></a>
#### ディレクトリの全ディレクトリ取得

`directories`メソッドは指定したディレクトリの全ディレクトリの配列を返します。指定したディレクトリ下の全ディレクトリと、サブディレクトリ下の全ディレクトリも取得したい場合は、`allDirectories`メソッドを使ってください。

    $directories = Storage::directories($directory);

    // 再帰的
    $directories = Storage::allDirectories($directory);

<a name="create-a-directory"></a>
#### ディレクトリ作成

`makeDirectory`メソッドは必要なサブディレクトリを含め、指定したディレクトリを作成します。

    Storage::makeDirectory($directory);

<a name="delete-a-directory"></a>
#### ディレクトリ削除

最後に、`deleteDirectory`メソッドは、ディレクトリと中に含まれている全ファイルを削除するために使用されます。

    Storage::deleteDirectory($directory);

<a name="custom-filesystems"></a>
## カスタムファイルシステム

LaravelのFlysystem統合には、最初からさまざまな「ドライバ」が含まれています。しかしFlysystemはこれらのドライバに限定されず、他の保存領域システムにも適用できます。皆さんのLaravelアプリケーションに適した保存システムに対するカスタムドライバを作成できます。

カスタムファイルシステムを準備するには、Flysystemアダプタが必要です。プロジェクトへコミュニティによりメンテナンスされているDropboxアダプタを追加してみましょう。

    composer require spatie/flysystem-dropbox

次に、たとえば`DropboxServiceProvider`のような、[サービスプロバイダ](/docs/{{version}}/providers)を用意してください。プロバイダの`boot`メソッドの中で`Storage`ファサードの`extend`メソッドを使い、カスタムドライバを定義できます。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Storage;
    use Illuminate\Support\ServiceProvider;
    use League\Flysystem\Filesystem;
    use Spatie\Dropbox\Client as DropboxClient;
    use Spatie\FlysystemDropbox\DropboxAdapter;

    class DropboxServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * 全アプリケーションサービスの初期起動
         *
         * @return void
         */
        public function boot()
        {
            Storage::extend('dropbox', function ($app, $config) {
                $client = new DropboxClient(
                    $config['authorization_token']
                );

                return new Filesystem(new DropboxAdapter($client));
            });
        }
    }

`extend`メソッドの最初の引数はドライバの名前で、２つ目は`$app`と`$config`変数を受け取るクロージャです。このリゾルバークロージャは`League\Flysystem\Filesystem`のインスタンスを返す必要があります。`$config`変数は`config/filesystems.php`で定義したディスクの値を含んでいます。

次に、`config/app.php`設定ファイルで、サービスプロバイダを登録します。

    'providers' => [
        // ...
        App\Providers\DropboxServiceProvider::class,
    ];

拡張のサービスプロバイダを作成し、登録し終えたら、`config/filesystems.php`設定ファイルで、`dropbox`ドライバを使用します。
