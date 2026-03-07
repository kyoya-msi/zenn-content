---
title: "【C4モデル図解】SSRとRESTの構造的違い"
emoji: "🔥"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [structurizr, plantuml, spring, ssr, restapi]
published: true
---

## はじめに
どーもKyoyaです。JVMの学習をして記事出したいんですけど、しばらく厳しいですね。。。

今のバックエンドの研修を進める中で、今まで作っていた「画面付きのSpring Bootアプリ」と、新しく登場した「RESTAPI」の違いに戸惑いました。

「Thymeleafで画面を作らなくなったのは分かるけど、システム全体の構造として何がどう変わったの？」

このモヤモヤを解消するために、ソフトウェアアーキテクチャを図解する**C4モデル**を使って、今までの構成（SSR）と新しい構成（REST）の構造的な違いを可視化してみました。

## 1. Container図（システム構成の違い）
まずはC4モデルの「レベル2：コンテナ図」を使って、システム全体のハコ（実行環境）がどう変わったかを見てみます。

### SSR（今までのSpringMVC）

![](/images/understanding-ssr-vs-restapi/structurizr-SSR-ContainerDiagram.png)

これまでは、SpringBootという1つの大きなハコの中で「画面描画処理（HTML生成）」と「データ処理（ビジネスロジック）」の両方を担っていました。
ブラウザからのリクエストに対して、サーバーが完成した画面(HTML)を返却する構造です。

### REST（今回の構成）

![](/images/understanding-ssr-vs-restapi/structurizr-RESTAPI-ContainerDiagram.png)

一方RESTでは、システムが「フロントエンド（Reactなど）」と「バックエンド（SpringBoot）」の2つのハコに完全に分離しています。
バックエンドは画面を作らず、フロントエンドからの要求に対して純粋なデータ(JSONなどなど)だけを返すことに徹しています。

## 2. Component図（Spring Boot内部の違い）
次に、粒度を上げて「レベル3：コンポーネント図」でSpringBootの内部コンポーネントの役割がどう変わったかを見てみます。

### SSR（今までのSpringMVC）

![](/images/understanding-ssr-vs-restapi/structurizr-SSR-ComponentDiagram.png)

### REST（今回の構成）

![](/images/understanding-ssr-vs-restapi/structurizr-RESTAPI-ComponentDiagram.png)

構造が分離したことで、中のコード（特にController層）にも変化が現れます。

### 変わらない部分（Service / Repository）
ビジネスロジックを担当する `@Service` や、データベースとJDBC/SQLでやり取りする `@Repository` の役割はどちらも変わりません。

### 変わった部分（Controller）
一番の違いは「HTTPリクエストを受付する窓口」であるControllerです。
* **SSR（`@Controller`）：** 処理の最後に「どの画面（View名）を表示するか」を返します。
* **REST（`@RestController`）：** 処理の最後に「データそのもの（EntityやDTO）」を返し、裏側で自動的にJSON形式に変換されてフロントエンドへ送られます。

## おわりに
C4モデルで図解してみると、RESTとは単なる技術名ではなく**フロントエンドとバックエンドの役割を分離し、JSONでやり取りするアーキテクチャ**であることが視覚的にスッキリ理解できました。

システムの構造（上澄み）はこれで把握できましたが、では実際にフロントとバックを繋いでいる「HTTPリクエスト」のやり取りは、裏側でどう動いているのでしょうか？

次の記事では、さらに解像度を上げて**UMLのシーケンス図**を使い、RESTの通信の詳細について解剖してみたいと思います！

最後まで読んでいただきありがとうございました！

<!-- EOF -->
