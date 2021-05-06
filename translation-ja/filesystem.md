# ファイルストレージ

- [イントロダクション](#introduction)
- [設定](#configuration)
    - [ローカルドライバ](#the-local-driver)
    - [公開ディスク](#the-public-disk)
    - [ドライバの動作要件](#driver-prerequisites)
    - [キャッシュ](#caching)
- [ディスクインスタンスの取得](#obtaining-disk-instances)
- [ファイルの取得](#retrieving-files)
    - [ファイルのダウンロード](#downloading-files)
    - [ファイルのURL](#file-urls)
    - [ファイルメタデータ](#file-metadata)
- [ファイルの保存](#storing-files)
    - [ファイルのアップロード](#file-uploads)
    - [ファイルの可視性](#file-visibility)
- [ファイルの削除](#deleting-files)
- [ディレクトリ](#directories)
- [カスタムファイルシステム](#custom-filesystems)

<a name="introduction"></a>
## イントロダクション

Laravelは、Frankde Jongeによる素晴らしい[Flysystem](https://github.com/thephpleague/flysystem) PHPパッケージのおかげで、ファイルシステムの強力な抽象化を提供しています。Laravel Flysystem統合は、ローカルファイルシステム、SFTP、およびAmazonS3を操作するためのシンプルなドライバを提供します。さらに良いことに、APIは各システムで同じままであるため、ローカル開発マシンと本番サーバの間でこれらのストレージオプションを切り替えるのは驚くほど簡単です。

<a name="configuration"></a>
## 設定

Laravelのファイルシステム設定ファイルは`config/filesystems.php`にあります。このファイル内で、すべてのファイルシステム「ディスク」を設定できます。各ディスクは、特定のストレージドライバーとストレージの場所を表します。サポートしている各ドライバーの設定例を設定ファイルに用意しているので、ストレージ設定と資格情報を反映するように設定を変更してください。

`local`ドライバーは、Laravelアプリケーションを実行しているサーバでローカルに保存されているファイルを操作し、`s3`ドライバーはAmazonのS3クラウドストレージサービスへの書き込みに使用します。

> {tip} 必要な数のディスクを構成でき、同じドライバーを使用する複数のディスクを使用することもできます。

<a name="the-local-driver"></a>
### ローカルドライバ

`local`ドライバーを使用する場合、すべてのファイル操作は、`filesystems`設定ファイルで定義した`root`ディレクトリからの相対位置です。デフォルトでは、この値は`storage/app`ディレクトリに設定されています。したがって、次のメソッドは`storage/app/example.txt`に書き込みます。

    use Illuminate\Support\Facades\Storage;

    Storage::disk('local')->put('example.txt', 'Contents');

<a name="the-public-disk"></a>
### 公開ディスク

アプリケーションの`filesystems`設定ファイルに含まれている`public`ディスクは、パブリックに公開してアクセスできるようにするファイルを対象としています。デフォルトでは、`public`ディスクは`local`ドライバーを使用し、そのファイルを`storage/app/public`に保存します。

これらのファイルにWebからアクセスできるようにするには、`public/storage`から`storage/app/public`へのシンボリックリンクを作成する必要があります。このフォルダ規約を利用すると、[Envoyer](https://envoyer.io)のようなダウンタイムゼロのデプロイメントシステムを使用する場合に、パブリックにアクセス可能なファイルを1つのディレクトリに保持し、デプロイメント間で簡単に共有できます。

シンボリックリンクを作成するには、`storage:link` Artisanコマンドを使用できます。

    php artisan storage:link

ファイルを保存し、シンボリックリンクを作成したら、`asset`ヘルパを使用してファイルへのURLを作成できます。

    echo asset('storage/file.txt');

`filesystems`設定ファイルで追加のシンボリックリンクを設定できます。`storage:link`コマンドを実行すると、設定された各リンクが作成されます。

    'links' => [
        public_path('storage') => storage_path('app/public'),
        public_path('images') => storage_path('app/images'),
    ],

<a name="driver-prerequisites"></a>
### ドライバの動作要件

<a name="composer-packages"></a>
#### Composerパッケージ

S3やSFTPドライバーを使用するときは、事前にComposerパッケージマネージャーを介して適切なパッケージをインストールする必要があります。

- Amazon S3: `composer require league/flysystem-aws-s3-v3 "~1.0"`
- SFTP: `composer require league/flysystem-sftp "~1.0"`

パフォーマンスを向上させるために、メタデータをキャッシュするアダプタを追加インストールすることもできます。

- CachedAdapter: `composer require league/flysystem-cached-adapter "~1.0"`

<a name="s3-driver-configuration"></a>
#### S3ドライバー設定

S3ドライバーの設定情報は、`config/filesystems.php`設定ファイルにあります。このファイルには、S3ドライバーの設定配列の例が含まれています。この配列は、皆さんのS3設定と認証情報を使用するため自由に変更できます。利便性のため、これらの環境変数はAWS　CLIが使用する命名規則と一致させています。

<a name="ftp-driver-configuration"></a>
#### FTPドライバーの設定

LaravelのFlysystem統合はFTPでもうまく機能します。ただし、サンプル設定がフレームワークのデフォルトの`filesystems.php`設定ファイルに含まれていません。FTPファイルシステムを設定する必要がある場合は、以下の設定例を参照してください。

    'ftp' => [
        'driver' => 'ftp',
        'host' => 'ftp.example.com',
        'username' => 'your-username',
        'password' => 'your-password',

        // オプションのFTP設定
        // 'port' => 21,
        // 'root' => '',
        // 'passive' => true,
        // 'ssl' => true,
        // 'timeout' => 30,
    ],

<a name="sftp-driver-configuration"></a>
#### SFTPドライバーの設定

LaravelのFlysystem統合はSFTPでも最適に機能します。ただし、サンプル設定がフレームワークのデフォルトの`fileSystems.php`設定ファイルに含まれていません。SFTPファイルシステムを設定する必要がある場合は、以下の設定例を参照してください。

    'sftp' => [
        'driver' => 'sftp',
        'host' => 'example.com',
        'username' => 'your-username',
        'password' => 'your-password',

        // SSHキーベースの認証の設定
        'privateKey' => '/path/to/privateKey',
        'password' => 'encryption-password',

        // オプションのSFTP設定
        // 'port' => 22,
        // 'root' => '',
        // 'timeout' => 30,
    ],

<a name="caching"></a>
### キャッシュ

特定のディスクのキャッシュを有効にするには、ディスクの設定オプションに`cache`ディレクティブを追加します。`cache`オプションは、`disk`名、秒単位の`expire`時間、およびキャッシュ`prefix`を含むキャッシュオプションの配列である必要があります。

    's3' => [
        'driver' => 's3',

        // その他のディスクオプション

        'cache' => [
            'store' => 'memcached',
            'expire' => 600,
            'prefix' => 'cache-prefix',
        ],
    ],

<a name="obtaining-disk-instances"></a>
## ディスクインスタンスの取得

`Storage`ファサードは、設定済みのディスクと対話するために使用できます。たとえば、ファサードで`put`メソッドを使用して、アバターをデフォルトのディスクに保存できます。最初に`disk`メソッドを呼び出さずに`Storage`ファサードのメソッドを呼び出すと、メソッドは自動的にデフォルトのディスクに渡されます。

    use Illuminate\Support\Facades\Storage;

    Storage::put('avatars/1', $content);

アプリケーションが複数のディスクを操作する場合は、`Storage`ファサードで`disk`メソッドを使用し、特定のディスク上のファイルを操作できます。

    Storage::disk('s3')->put('avatars/1', $content);

<a name="retrieving-files"></a>
## ファイルの取得

`get`メソッドを使用して、ファイルの内容を取得できます。ファイルの素の文字列の内容は、メソッドによって返されます。すべてのファイルパスは、ディスクの「ルート」の場所を基準にして指定する必要があることに注意してください。

    $contents = Storage::get('file.jpg');

`exists`メソッドを使用して、ファイルがディスクに存在するかどうかを判定できます。

    if (Storage::disk('s3')->exists('file.jpg')) {
        // ...
    }

`missing`メソッドを使用して、ファイルがディスク存在していないことを判定できます。

    if (Storage::disk('s3')->missing('file.jpg')) {
        // ...
    }

<a name="downloading-files"></a>
### ファイルのダウンロード

`download`メソッドを使用して、ユーザーのブラウザに指定したパスでファイルをダウンロードするように強制するレスポンスを生成できます。`download`メソッドは、メソッドの２番目の引数としてファイル名を受け入れます。これにより、ユーザーがファイルをダウンロードするときに表示されるファイル名が決まります。最後に、HTTPヘッダの配列をメソッドの３番目の引数として渡すことができます。

    return Storage::download('file.jpg');

    return Storage::download('file.jpg', $name, $headers);

<a name="file-urls"></a>
### ファイルのURL

`url`メソッドを使用し、特定のファイルのURLを取得できます。`local`ドライバーを使用している場合、これは通常、指定されたパスの前に`/storage`を追加し、ファイルへの相対URLを返します。`s3`ドライバーを使用している場合は、完全修飾リモートURLが返されます。

    use Illuminate\Support\Facades\Storage;

    $url = Storage::url('file.jpg');

`local`ドライバーを使用する場合、パブリックにアクセス可能である必要があるすべてのファイルは、`storage/app/public`ディレクトリに配置する必要があります。さらに、`storage/app/public`ディレクトリを指す`public/storage`に[シンボリックリンクを作成](#the-public-disk)する必要があります。

> {note} `local`ドライバーを使用する場合、`url`の戻り値はURLエンコードされません。このため、常に有効なURLを作成する名前を使用してファイルを保存することをお勧めします。

<a name="temporary-urls"></a>
#### 一時的なURL

`temporaryUrl`メソッドを使用すると、`s3`ドライバーを使用して保存されたファイルへの一時URLを作成できます。このメソッドは、パスと、URLの有効期限を指定する`DateTime`インスタンスを受け入れます。

    use Illuminate\Support\Facades\Storage;

    $url = Storage::temporaryUrl(
        'file.jpg', now()->addMinutes(5)
    );

追加の[S3リクエストパラメーター](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectGET.html#RESTObjectGET-requests)を指定する必要がある場合は、リクエストパラメーターの配列を`temporaryUrl`メソッドの引数の３番目として渡すことができます。

    $url = Storage::temporaryUrl(
        'file.jpg',
        now()->addMinutes(5),
        [
            'ResponseContentType' => 'application/octet-stream',
            'ResponseContentDisposition' => 'attachment; filename=file2.jpg',
        ]
    );

<a name="url-host-customization"></a>
#### URLホストのカスタマイズ

`Storage`ファサードを使用して生成するURLのホストを事前に定義したい場合は、ディスクの設定配列に`url`オプションを追加できます。

    'public' => [
        'driver' => 'local',
        'root' => storage_path('app/public'),
        'url' => env('APP_URL').'/storage',
        'visibility' => 'public',
    ],

<a name="file-metadata"></a>
### ファイルメタデータ

Laravelは、ファイルの読み取りと書き込みに加えて、ファイル自体に関する情報も提供できます。たとえば、`size`メソッドを使用して、ファイルのサイズをバイト単位で取得できます。

    use Illuminate\Support\Facades\Storage;

    $size = Storage::size('file.jpg');

`lastModified`メソッドは、ファイルが最後に変更されたときのUNIXタイムスタンプを返します。

    $time = Storage::lastModified('file.jpg');

<a name="file-paths"></a>
#### ファイルパス

`path`メソッドを使用して、特定のファイルのパスを取得できます。`local`ドライバーを使用している場合、これはファイルへの絶対パスを返します。`s3`ドライバーを使用している場合、このメソッドはS3バケット内のファイルへの相対パスを返します。

    use Illuminate\Support\Facades\Storage;

    $path = Storage::path('file.jpg');

<a name="storing-files"></a>
## ファイルの保存

`put`メソッドは、ファイルの内容をディスクに保存するために使用します。PHPの`resource`を`put`メソッドに渡すこともできます。このメソッドは、Flysystemの基盤となるストリームサポートを使用します。すべてのファイルパスは、ディスク用に設定された「ルート」の場所を基準にして指定する必要があることに注意してください。

    use Illuminate\Support\Facades\Storage;

    Storage::put('file.jpg', $contents);

    Storage::put('file.jpg', $resource);

<a name="automatic-streaming"></a>
#### 自動ストリーミング

ファイルをストレージにストリーミングすると、メモリ使用量が大幅に削減されます。Laravelが特定のファイルの保存場所へのストリーミングを自動的に管理するようにしたい場合は、`putFile`または`putFileAs`メソッドを使用できます。このメソッドは、`Illuminate\Http\File`または`Illuminate\Http\UploadedFile`インスタンスのいずれかを受け入れ、ファイルを目的の場所に自動的にストリーミングします。

    use Illuminate\Http\File;
    use Illuminate\Support\Facades\Storage;

    // ファイル名の一意のIDを自動的に生成
    $path = Storage::putFile('photos', new File('/path/to/photo'));

    // ファイル名を手動で指定します
    $path = Storage::putFileAs('photos', new File('/path/to/photo'), 'photo.jpg');

`putFile`メソッドには注意すべき重要な点がいくつかあります。ファイル名ではなく、ディレクトリ名のみを指定することに注意してください。デフォルトでは、`putFile`メソッドはファイル名として機能する一意のIDを生成します。ファイルの拡張子は、ファイルのMIMEタイプを調べることによって決定されます。ファイルへのパスは`putFile`メソッドによって返されるため、生成されたファイル名を含むパスをデータベースに保存できます。

`putFile`メソッドと`putFileAs`メソッドは、保存するファイルの「可視性」を指定する引数も取ります。これは、AmazonS3などのクラウドディスクにファイルを保存していて、生成されたURLを介してファイルにパブリックアクセスできるようにする場合に特に便利です。

    Storage::putFile('photos', new File('/path/to/photo'), 'public');

<a name="prepending-appending-to-files"></a>
#### ファイルの先頭追加と後方追加

`prepend`および`append`メソッドを使用すると、ファイルの最初または最後に書き込むことができます。

    Storage::prepend('file.log', 'Prepended Text');

    Storage::append('file.log', 'Appended Text');

<a name="copying-moving-files"></a>
#### ファイルのコピーと移動

`copy`メソッドを使用して、既存のファイルをディスク上の新しい場所にコピーできます。また、`move`メソッドを使用して、既存のファイルの名前を変更したり、新しい場所に移動したりできます。

    Storage::copy('old/file.jpg', 'new/file.jpg');

    Storage::move('old/file.jpg', 'new/file.jpg');

<a name="file-uploads"></a>
### ファイルのアップロード

Webアプリケーションでは、ファイルを保存するための最も一般的な使用例の1つは、写真やドキュメントなどのユーザーがアップロードしたファイルを保存することです。Laravelを使用すると、アップロードされたファイルインスタンスに`store`メソッドを使用し、ファイルを非常に簡単に保存できます。アップロード済みファイルを保存するパスを指定して`store`メソッドを呼び出します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;

    class UserAvatarController extends Controller
    {
        /**
         * ユーザーのアバターを更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function update(Request $request)
        {
            $path = $request->file('avatar')->store('avatars');

            return $path;
        }
    }

この例で注意すべき重要なことがあります。ファイル名ではなく、ディレクトリ名のみを指定したことに注意してください。デフォルトでは、`store`メソッドはファイル名として機能する一意のIDを生成します。ファイルの拡張子は、ファイルのMIMEタイプを調べることによって決定されます。ファイルへのパスは`store`メソッドによって返されるため、生成されたファイル名を含むパスをデータベースに保存できます。

`Storage`ファサードで`putFile`メソッドを呼び出して、上記の例と同じファイルストレージ操作を実行することもできます。

    $path = Storage::putFile('avatars', $request->file('avatar'));

<a name="specifying-a-file-name"></a>
#### ファイル名の指定

保存されたファイルにファイル名を自動的に割り当てたくない場合は、引数としてパス、ファイル名、および(オプションの)ディスクを受け取る`storeAs`メソッドを使用します。

    $path = $request->file('avatar')->storeAs(
        'avatars', $request->user()->id
    );

`Storage`ファサードで`putFileAs`メソッドを使用することもできます。これにより、上記の例と同じファイルストレージ操作が実行されます。

    $path = Storage::putFileAs(
        'avatars', $request->file('avatar'), $request->user()->id
    );

> {note} 印刷できない無効なUnicode文字はファイルパスから自動的に削除されます。したがって、Laravelのファイルストレージメソッドに渡す前に、ファイルパスをサニタイズすることをお勧めします。ファイルパスは、`League\Flysystem\Util::normalizePath`メソッドを使用して正規化されます。

<a name="specifying-a-disk"></a>
#### ディスクの指定

デフォルトでは、このアップロード済みファイルの`store`メソッドはデフォルトのディスクを使用します。別のディスクを指定する場合は、ディスク名を２番目の引数として`store`メソッドに渡します。

    $path = $request->file('avatar')->store(
        'avatars/'.$request->user()->id, 's3'
    );

`storeAs`メソッドを使用している場合は、ディスク名を３番目の引数としてメソッドに渡すことができます。

    $path = $request->file('avatar')->storeAs(
        'avatars',
        $request->user()->id,
        's3'
    );

<a name="other-uploaded-file-information"></a>
#### アップロード済みファイルのその他の情報

アップロード済みファイルの元の名前を取得したい場合は、`getClientOriginalName`メソッドを使用して取得できます。

    $name = $request->file('avatar')->getClientOriginalName();

`extension`メソッドを使用して、アップロード済みファイルのファイル拡張子を取得できます。

    $extension = $request->file('avatar')->extension();

<a name="file-visibility"></a>
### ファイルの可視性

LaravelのFlysystem統合では、「可視性」は複数のプラットフォームにわたるファイル権限の抽象化です。ファイルは`public`または`private`として宣言できます。ファイルが`public`と宣言されている場合、そのファイルは一般的に他のユーザーがアクセスできる必要があることを示しています。たとえば、S3ドライバーを使用する場合、`public`ファイルのURLを取得できます。

`put`メソッドを介してファイルを書き込むとき、可視性を設定できます。

    use Illuminate\Support\Facades\Storage;

    Storage::put('file.jpg', $contents, 'public');

ファイルがすでに保存されている場合、その可視性は、`getVisibility`および`setVisibility`メソッドにより取得および設定できます。

    $visibility = Storage::getVisibility('file.jpg');

    Storage::setVisibility('file.jpg', 'public');

アップロード済みファイルを操作するときは、`storePublicly`メソッドと`storePubliclyAs`メソッドを使用して、アップロード済みファイルを`public`の可視性で保存できます。

    $path = $request->file('avatar')->storePublicly('avatars', 's3');

    $path = $request->file('avatar')->storePubliclyAs(
        'avatars',
        $request->user()->id,
        's3'
    );

<a name="local-files-and-visibility"></a>
#### ローカルファイルと可視性

`local`ドライバーを使用する場合、`public`の[可視性](#file-visibility)は、ディレクトリの`0755`パーミッションとファイルの`0644`パーミッションに変換されます。アプリケーションの`filesystems`設定ファイルでパーミッションマッピングを変更できます。

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

<a name="deleting-files"></a>
## ファイルの削除

`delete`メソッドは、削除する単一のファイル名またはファイルの配列を受け入れます。

    use Illuminate\Support\Facades\Storage;

    Storage::delete('file.jpg');

    Storage::delete(['file.jpg', 'file2.jpg']);

必要に応じて、ファイルを削除するディスクを指定できます。

    use Illuminate\Support\Facades\Storage;

    Storage::disk('s3')->delete('path/file.jpg');

<a name="directories"></a>
## ディレクトリ

<a name="get-all-files-within-a-directory"></a>
#### ディレクトリ内のすべてのファイルを取得

`files`メソッドは、指定されたディレクトリ内のすべてのファイルの配列を返します。すべてのサブディレクトリを含む、特定のディレクトリ内のすべてのファイルのリストを取得する場合は、`allFiles`メソッドを使用できます。

    use Illuminate\Support\Facades\Storage;

    $files = Storage::files($directory);

    $files = Storage::allFiles($directory);

<a name="get-all-directories-within-a-directory"></a>
#### ディレクトリ内のすべてのディレクトリを取得

`directories`メソッドは、指定されたディレクトリ内のすべてのディレクトリの配列を返します。さらに、`allDirectories`メソッドを使用して、特定のディレクトリ内のすべてのディレクトリとそのすべてのサブディレクトリのリストを取得できます。

    $directories = Storage::directories($directory);

    $directories = Storage::allDirectories($directory);

<a name="create-a-directory"></a>
#### ディレクトリを作成する

`makeDirectory`メソッドは、必要なサブディレクトリを含む、指定したディレクトリを作成します。

    Storage::makeDirectory($directory);

<a name="delete-a-directory"></a>
#### ディレクトリを削除する

最後に、`deleteDirectory`メソッドを使用して、ディレクトリとそのすべてのファイルを削除できます。

    Storage::deleteDirectory($directory);

<a name="custom-filesystems"></a>
## カスタムファイルシステム

LaravelのFlysystem統合は、最初からすぐに使える「ドライバ」をいくつかサポートしています。ただし、Flysystemはこれらに限定されず、他の多くのストレージシステム用のアダプターを備えています。Laravelアプリケーションでこれらの追加アダプターの１つを使用する場合は、カスタムドライバーを作成できます。

カスタムファイルシステムを定義するには、Flysystemアダプターが必要です。コミュニティが管理するDropboxアダプターをプロジェクトに追加してみましょう。

    composer require spatie/flysystem-dropbox

次に、アプリケーションの[サービスプロバイダ](/docs/{{version}}/provider)の1つの`boot`メソッド内にドライバーを登録します。これには、`Storage`ファサードの`extend`メソッドを使用します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Storage;
    use Illuminate\Support\ServiceProvider;
    use League\Flysystem\Filesystem;
    use Spatie\Dropbox\Client as DropboxClient;
    use Spatie\FlysystemDropbox\DropboxAdapter;

    class AppServiceProvider extends ServiceProvider
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
         * 全アプリケーションサービスの初期起動処理
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

`extend`メソッドの最初の引数はドライバーの名前であり、２番目の引数は`$app`変数と`$config`変数を受け取るクロージャです。クロージャは`League\Flysystem\Filesystem`のインスタンスを返す必要があります。`$config`変数には、`config/filesystems.php`で定義した指定ディスクの値が含まれます。

拡張機能のサービスプロバイダを作成・登録したら、`config/filesystems.php`設定ファイルで`dropbox`ドライバーを使用できます。
