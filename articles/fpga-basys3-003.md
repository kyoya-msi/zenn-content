---
title: "【FPGA】LED点灯実験応用①"
emoji: "😸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [fpga, vivado, verilog]
published: true
---
## はじめに
こんにちは～kyoyaです～  
最近は江戸川乱歩の小説を読み始めました。  
まずは人間椅子からですね～  

前回、ボタンを押したらLEDが光るという一番シンプルな回路をFPGA(Basys3)に書き込んで動かしてみました。  
今回はその応用として、「押している間だけ光る」ではなく「1回押すと点灯、もう1回押すと消灯」という実装を進めていきます。  
加えてボタン極性も考慮します。  
本記事ではそれをまとめてみました。  

> * 参考にさせていただいた動画  
> [【【ゆっくり解説】Verilog Simulation篇【0から始めるFPGA超入門講座#2】】](https://www.youtube.com/watch?v=egiO6opQfcA)  

## LED点灯実装
### ボタン極性
#### 1. ボタン極性について

まず、前回同様お世話になっている[Basys3の回路図](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys-3_sch.pdf)を確認します。  
その中のLED回路図が以下になります。  
![](/images/fpga/003/画像1.png)  

確認すると、プルダウン回路になっているので以下となります。  

| 項目 | 電圧値(LED状態) |
| :-- | :-- |
| アイドル時(未押下) | 0(消灯) |
| 押下時 | 1(点灯) |

ということで、前回ボタン極性を特に何も考えずに実装していましたけど、うまく動作した訳がわかりました。  
これからFPGA学習進めるうえで回路図の裏付けを取ることを覚えておきたいですね。  

### トグル点灯実装
#### 1. タイミングチャートと論理回路を見直す
ボタン極性が分かったところで、今回は単純な「押したら光る」ではなく、1回押すごとにLEDのON/OFFが切り替わるトグル動作に挑戦しました。  
動画を参考にしつつ、「押した瞬間(エッジ)だけを検出して、状態を反転させる」という設計を行います。  
その検出を以下のように行います。  
* タイミングチャート  
![](/images/fpga/003/画像2.png)  

purse_d1とpurse_d2は、ボタン信号を1クロック/2クロックずつ遅らせてコピーしたものになります。  
この"ズレ"を利用してエッジ(変化の瞬間)を検出します。  
ボタン信号(purse_d1/purse_d2)を2段のDフリップフロップ(DFF)で同期させてエッジを検出し、AND/OR/NOTゲートを組み合わせてトグル用のDFFに反映する、という論理回路を組みました。  

* 論理回路図  
![](/images/fpga/003/画像3.png)  


#### 2. コードを書く(本体 + テストベンチ)
作成した論理回路図をもとにVerilogで実装します。  
今回は学習のためにゲートプリミティブでの実装をしました。(三項演算子とか使えばコード記述量を減らせますね)  
```verilog
module top (
	/* クロック信号 */
	input 	i_clk,
	/* Basys3 BTNC */
	input 	i_btnc,
	/* Basys3 LED7 */
	output	o_led7
) ;

	wire    w_edge ;
	reg     r_btnc_d1 ;
	reg     r_btnc_d2 ;
	reg     r_btnc_toggle ;

	wire	w_hold_term ;
	wire	w_flip_term ;
	wire	w_toggle_next ;
	wire	w_edge_n ;
	wire	w_btnc_toggle_n ;

	initial begin
		r_btnc_d1       = 0 ;
		r_btnc_d2       = 0 ;
		r_btnc_toggle   = 0 ;
	end

	assign w_edge = r_btnc_d1 & ~r_btnc_d2 ;

	always @( posedge i_clk ) begin
		r_btnc_d1 <= i_btnc ;
		r_btnc_d2 <= r_btnc_d1 ;

		r_btnc_toggle <= w_toggle_next ;
	end

	not ( w_edge_n, w_edge                        ) ;
	not ( w_btnc_toggle_n, r_btnc_toggle          ) ;
	and ( w_hold_term, r_btnc_toggle, w_edge_n    ) ;
	and ( w_flip_term, w_btnc_toggle_n, w_edge    ) ;
	or  ( w_toggle_next, w_hold_term, w_flip_term ) ;

	assign o_led7 = r_btnc_toggle ;
endmodule
```

また、テストベンチファイルもあわせて作成しました。  
今回はこのテストベンチファイルを用いて、シミュレータ動作確認までとします。  

シミュレータ動作手順としては以下になります。  
1. 電源投入後、100ns経過でボタン押下 → 点灯(1)
2. その後100ns経過でボタンを離す → 点灯のまま(1)
3. その後1000ns経過でボタン押下 → 消灯(0)
4. その後100ns経過でボタンを離す → 消灯のまま(0)

```verilog
`timescale 1ns/100ps
module top_tb ;

	reg     r_clk ;
	reg     r_btnc ;
	wire    w_led7 ;

	initial begin
		r_clk = 0 ;
    end

	always #(5) begin
		r_clk <= ~r_clk ;
    end

	initial begin
		#0          r_btnc = 0 ;
		#100      r_btnc = 1 ;
		#100      r_btnc = 0 ;
		#1000     r_btnc = 1 ;
		#100      r_btnc = 0 ;
		#100      $finish ;
	end

	top top_inst(
		.i_clk		(r_clk		),
		.i_btnc		(r_btnc		),
		.o_led7		(w_led7		)
	) ;

endmodule
```

#### 3. シミュレーションで動作確認

Vivadoのシミュレータで実行すると、r_btncが短く立ち上がったタイミングでw_led7が点灯し、そのまま点灯を維持、次にr_btncが立ち上がったタイミングで消灯に切り替わるという、狙い通りのトグル動作ぽいですね。  

![](/images/fpga/003/画像4.png)  

波形を詳しく見てみると、115ns時点でLEDが点灯状態に切り替わっていています。  
![](/images/fpga/003/画像5.png)  

内部信号(r_btnc_d1, r_btnc_d2, w_edgeなど)を1つずつ追ってみました。  
![](/images/fpga/003/画像6.png)  

波形と実装を照らし合わせて確認してみると「エッジ検出→トグル反転」の流れがちゃんと設計通りに動いていることも確認できました。  
以上で問題なくロジックの実装はできているみたいですね。よかったです。  

## まとめ
今回の内容をまとめると以下になります。
1. 前回の実装は「ボタン=1」という思い込みで動いていたが、実際は回路図からボタンの極性(プルアップ/プルダウン)を確認する必要があった  
2. Basys 3のボタン回路はプルダウン回路であり、押下時に立ち上がりエッジを検出する設計が正しいと確認  
3. 「押している間だけ光る」から「1回押すとON、もう1回押すとOFF」というトグル動作に変更し、2段DFFによるエッジ検出+トグル用DFFという論理回路を設計  
4. テストベンチを作成してシミュレーションで動作を検証し、期待通りにLEDがトグルすることを確認できた  

## おわりに
ただ、今回もまだ考慮できていないことがあります。  
実際のボタンには[チャタリング](https://ja.wikipedia.org/wiki/%E3%83%81%E3%83%A3%E3%82%BF%E3%83%AA%E3%83%B3%E3%82%B0)があり、今の実装だとそれをそのまま拾ってしまう可能性があるため、次の記事ではチャタリング対策として、デバウンス回路の設計を行い、実機動作確認を行います～  
