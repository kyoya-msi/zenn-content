---
title: "【FPGA】LED点灯実験応用③"
emoji: "🐷"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [fpga, vivado, verilog]
published: true
---

## はじめに
こんにちは～kyoyaです～  

引き続き「押している間だけ光る」ではなく「1回押すと点灯、もう1回押すと消灯」という実装を進めていきます。  
今回でコード実装から実機での動作確認までを記載します。  

## LED点灯実装~動作確認
前記事で分割した各モジュールの実装とシミュレータ/FPGA実機動作確認をします。  

| 回路名 | モジュール名 | 処理内容 |
| :-- | :-- | :-- |
| 全体回路 | top | BTNCからLED7出力までの全体の信号の流れを配線する |
| シンクロナイザ回路 | synchronizer | 非同期データを同期データに変換する |
| デバウンス回路 | debounce | バウンスデータを除去する |
| エッジ検出回路 | edge_detector | ボタン押下を検出する |
| ロジック回路 | toggle_logic | ボタン押下によるLED状態変化を行う |

### コード実装
* top.v  
```verilog
module top
#(
	parameter DEBOUNCE_TIME      = 21'd2000000,
	parameter DEBOUNCE_BIT_WIDTH = 21
)
(
	input  i_clk,
	input  i_btnc,
	output o_led7
) ;
	/* 配線定義 */
	wire w_sync ;
	wire w_stable ;
	wire w_edge ;
	wire w_togl ;

	/* シンクロナイザ */
	synchronizer sync_inst
	(
		.i_clk    ( i_clk    ),
		.i_async  ( i_btnc   ),
		.o_sync   ( w_sync   )
	) ;

	/* デバウンス */
	debounce
	#(
		.DEBOUNCE_TIME      ( DEBOUNCE_TIME      ),
		.DEBOUNCE_BIT_WIDTH ( DEBOUNCE_BIT_WIDTH )
	)
	deb_inst
	(
		.i_clk    ( i_clk    ),
		.i_sync   ( w_sync   ),
		.o_stable ( w_stable )
	) ;

	/* エッジ検出 */
	edge_detector edge_inst
	(
		.i_clk    ( i_clk    ),
		.i_stable ( w_stable ),
		.o_edge   ( w_edge   )
	) ;

	/* トグル判定 */
	toggle_logic togl_inst
	(
		.i_clk    ( i_clk    ),
		.i_edge   ( w_edge   ),
		.o_togl   ( w_togl   )
	) ;

	/* LED出力 */
	assign o_led7 = w_togl ;

endmodule
```

* synchronizer.v  
```verilog
module synchronizer
(
	input  i_clk,
	input  i_async,
	output o_sync
);
	/* レジスタ定義 */
	reg r_dff1 = 1'b0 ;
	reg r_dff2 = 1'b0 ;

	always @( posedge i_clk ) begin
		r_dff1 <= i_async ;
		r_dff2 <= r_dff1 ;
	end

	assign o_sync = r_dff2 ;

endmodule
```

* debounce.v  
```verilog
module debounce
#(
	parameter DEBOUNCE_TIME      = 21'd2000000,
	parameter DEBOUNCE_BIT_WIDTH = 21
)
(
	input  i_clk,
	input  i_sync,
	output o_stable
);
	/* レジスタ定義 */
	reg [DEBOUNCE_BIT_WIDTH-1:0] r_debounce_cnt = { DEBOUNCE_BIT_WIDTH{1'b0} } ;
	reg r_stable = 1'b0 ;

	always @( posedge i_clk ) begin
		if ( i_sync == r_stable ) begin
			r_debounce_cnt <= { DEBOUNCE_BIT_WIDTH{1'b0} } ;
		end
		else if ( r_debounce_cnt == (DEBOUNCE_TIME - 1) ) begin
			r_stable <= i_sync ;
			r_debounce_cnt <= { DEBOUNCE_BIT_WIDTH{1'b0} } ;
		end
		else begin
			r_debounce_cnt <= r_debounce_cnt + { {(DEBOUNCE_BIT_WIDTH - 1){1'b0}}, {1'b1} } ;
		end
	end

	assign o_stable = r_stable ;

endmodule
```

* edge_detector.v  
```verilog
module edge_detector
(
	input  i_clk,
	input  i_stable,
	output o_edge
);
	/* レジスタ定義 */
	reg r_dff = 1'b0 ;

	always @( posedge i_clk ) begin
		r_dff <= i_stable ;
	end

	assign o_edge = i_stable & ~r_dff ;

endmodule
```

* toggle_logic.v  
```verilog
module toggle_logic
(
	input  i_clk,
	input  i_edge,
	output o_togl
);
	/* レジスタ定義 */
	reg r_toggle = 1'b0 ;

	/* 配線定義 */
	wire w_edge_n ;
	wire w_toggle_n ;
	wire w_hold_term ;
	wire w_flip_term ;
	wire w_toggle_next ;

	/* プリミティブゲート定義 */
	not ( w_edge_n, i_edge                        ) ;
	not ( w_toggle_n, r_toggle                    ) ;
	and ( w_hold_term, r_toggle, w_edge_n         ) ;
	and ( w_flip_term, w_toggle_n, i_edge         ) ;
	or  ( w_toggle_next, w_hold_term, w_flip_term ) ;

	always @( posedge i_clk ) begin
		r_toggle <= w_toggle_next ;
	end

	assign o_togl = r_toggle ;

endmodule
```

### シミュレータ動作確認
シミュレーションソースとして以下のテストベンチファイルを作成しました。  
テストベンチでは、以下の流れで「チャタリング＋確定入力」を模擬しています。  
1. 100ms待機（アイドル状態）  
2. 100ns間隔でON  /OFF/ONを繰り返し、チャタリングを再現
3. その状態のまま21ms保持（デバウンス時間20msを超えるため、これが正式な入力として確定される想定）  
4. 再び100ns間隔のチャタリングを模擬  
5. 100ms待機  
6. 2〜5を再度繰り返し（1回目のトグルの逆方向の確認）  

* top_tb.v  
```verilog
`timescale 1ns/100ps
module top_tb ;

	/* レジスタ定義 */
	reg  r_clk  = 0 ;
	reg  r_btnc = 0 ;

	/* 配線定義 */
	wire w_led7 ;

	/* 
	 * Basys3基盤の周波数：100MHz
	 * クロック周期：10ns
	 */
	always #(5) begin
		r_clk <= ~r_clk ;
    end

	initial begin
		#0 r_btnc = 0 ;

		// 100ms wait
		#100000000 ;

		// チャタリング
		#100 r_btnc = 1 ;
		#100 r_btnc = 0 ;
		#100 r_btnc = 1 ;

		// 状態変化（点灯、21ms保持して確定させる）
		#21000000 r_btnc = 1 ;

		// チャタリング
		#100 r_btnc = 0 ;
		#100 r_btnc = 1 ;
		#100 r_btnc = 0 ;

		// 100ms wait
		#100000000 ;

		// チャタリング
		#100 r_btnc = 1 ;
		#100 r_btnc = 0 ;
		#100 r_btnc = 1 ;

		// 状態変化（消灯、21ms保持して確定させる）
		#21000000 r_btnc = 1 ;

		// チャタリング
		#100 r_btnc = 0 ;
		#100 r_btnc = 1 ;
		#100 r_btnc = 0 ;

		// 100ms wait
		#100000000 ;

		#100 $finish ;
	end

	top top_inst
	(
		.i_clk  ( r_clk  ),
		.i_btnc ( r_btnc ),
		.o_led7 ( w_led7 )
	) ;

endmodule
```

このテストベンチファイルの動作イメージが以下のようになります。  
![](/images/fpga/005/テストベンチファイル.png)  

* Vivadoシミュレーション波形  
波形を確認すると、デバウンス回路がチャタリング区間を正しく無視し、安定した入力のみをエッジ検出・トグル判定に渡せていることがシミュレーション上で確認できたので、問題なしと判断しました。  
![](/images/fpga/005/画像1.png)  


### FPGA動作確認
Vivadoを使用して動作確認します。  
XDC制約ファイルは以下の通りです。  
* xdc
```xdc
# CLOCK
set_property PACKAGE_PIN W5                  [ get_ports i_clk                 ]
set_property IOSTANDARD LVCMOS33             [ get_ports i_clk                 ]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5}\
                                             [ get_ports i_clk                 ]

# BUTTON
set_property PACKAGE_PIN U18                 [ get_ports i_btnc                ]
set_property IOSTANDARD LVCMOS33             [ get_ports i_btnc                ]

# LED
set_property PACKAGE_PIN V14                 [ get_ports o_led7                ]
set_property IOSTANDARD LVCMOS33             [ get_ports o_led7                ]
```

論理合成・インプリメンテーションを実行し、生成したビットストリームをBasys3に書き込みました。  
実機でBTNCを押してみると、シミュレーションと同様にLED7が点灯／消灯をトグルする動作を確認できました(上記はLED消灯状態に一度ボタン押したときの画像です)。  

![](/images/fpga/005/IMG20260726000704.jpg)  

## まとめ
* 前回確定した回路図をもとに、シンクロナイザ／デバウンス／エッジ検出／ロジックの4モジュールに分割してVerilogで実装  
* チャタリングを模擬したテストベンチを作成し、デバウンス回路がチャタリング区間を無視して安定入力のみをトグル判定に渡せていることをシミュレーションで確認  
* 実機(Basys3)への書き込みでも、ボタン押下ごとにLEDがトグルする動作を確認  

## おわりに
これで、極性・チャタリング・シンクロナイザまで踏まえたトグルLED回路を、設計から実機確認まで一通り通せました。  
次回は、長押し検出や強制リセットなど、もう一段踏み込んだ機能を実装していく予定です～  
アラシタ  
