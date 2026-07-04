---
title: "【FPGA】LED点灯実験してみた！"
emoji: "😸"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [fpga, vivado, verilog]
published: false
---
## はじめに
こんにちは～kyoyaです～  
人間椅子の還暦ツアー後半の発表はいつかなーと思いつつ過ごす日々ですね・・・  

今回はLED点灯実験をしてみたのでそれをまとめます。  
内容は特定のボタンを押したらLEDが点灯するというプログラムを実装してみるというものです。  
ハードウェアの確認 → コード記述 → コンパイル → 実機動作確認、という手順でやっています。  
本記事ではそれをまとめてみました。  

> * 参考にさせていただいた動画  
> [【ゆっくり解説】FPGA実機実装をはじめよう！【0から始めるFPGA超入門講座#5】](https://www.youtube.com/watch?v=1DftG1EjmVY)  

## fpga書き込み動作確認
### 1. ハードウェアの回路を見てみる
いきなりコードを書く前に、[Basys3の回路図](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys-3_sch.pdf)を見て、どのピンがLEDやボタンに繋がっているのかを確認しました。  
一番時間がかかったプロセスになりますね。  
ハードウェア情報まとめると、以下になりました。  
* FPGA型番  
XC7A35T-1CPG236C  

* ボタン  
| BTN  | Pin | BANK |
| :-- | :-- | :-- |
| BTNL | W19 | 14   |
| BTNR | T17 | 14   |
| BTNU | T18 | 14   |
| BTND | U17 | 14   |
| BTNC | U18 | 14   |

* LED  
| LED | Pin | BANK |
| :-- | :-- | :-- |
| LD0 | U16 | 14 |
| LD1 | E19 | - (CONFIG) |
| LD2 | U19 | - (CONFIG) |
| LD3 | V19 | - (CONFIG) |
| LD4 | W18 | - (CONFIG) |
| LD5 | U15 | 14 |
| LD6 | U14 | 14 |
| LD7 | V14 | 14 |
| LD8 | V13 | 14 |
| LD9 | V3 | 34 |
| LD10 | W3 | 34 |
| LD11 | U3 | 34 |
| LD12 | P3 | 35 |
| LD13 | N3 | 35 |
| LD14 | P1 | 35 |
| LD15 | L1 | 35 |

* 電源  
| BANK | 供給電圧 |
| :-- | :-- |
| 0    | 3.3V |
| 14   | 3.3V |
| 16   | 3.3V |
| 34   | 3.3V |
| 35   | 3.3V |

この中で今回は適当に`BTNC`と`LD7`をつなげるものを作成しようとなりました。  

### 2. コードを書く(Verilog + 制約ファイル)
ボタン(BTNC)を押している間だけLED(LD7)を光らせる」ということで、`BTNC`と`LD7`をつなげる実装のみ書きました。  

Verilog本体はこれだけ。  
```verilog
verilogmodule top (
    input  BTNC,
    output LD7
);
    assign LD7 = BTNC;
endmodule
```

Verilogの信号(BTNC/LD7)を実際の物理ピンに結びつけるための制約ファイル(XDC)も書きました。  
```xdc
# BUTTON
set_property PACKAGE_PIN U18 [get_ports {BTNC}]
set_property IOSTANDARD LVCMOS33 [get_ports {BTNC}]

# LED
set_property PACKAGE_PIN V14 [get_ports {LD7}]
set_property IOSTANDARD LVCMOS33 [get_ports {LD7}]
```

### 3. コンパイルする(synthesis → implementation → bitstream)
vivadoでプロジェクトを作成し、ソースと制約ファイルを追加、対象デバイスをxc7a35tcpg236-1に設定してコンパイルします。  

* 論理合成(synthesis)  
RunSynthesisを実行すると以下のような回路図ができあがりました。  
意図通りにできてるぽいですね。  
![](/images/fpga/002/synthesis.png)  

* 配置配線(Implementation)  
RunImplementationを実行すると以下のような配線になってました。  
これも意図通りにできてました。  
  * 全体  
    ![](/images/fpga/002/implementation1.png)  
  * BTNC  
    ![](/images/fpga/002/implementation2.png)  
  * LD7  
    ![](/images/fpga/002/implementation3.png)  

* 書き込みファイル生成(generate bitstream)  
GenerateBitstreamを実行すると.bitファイルを生成できました。  
(特に載せる画像がないため省略します～)  

### 4. 実機に書き込んで動かす
Hardware ManagerでPCとボードを接続し、生成したbitstreamを書き込みました。  
書き込み後、実際にBTNC(中央のボタン)を押してみると…

* 押していないとき: LEDは消灯  
  ![](/images/fpga/002/実行結果1.jpg)
* 押しているとき: LEDが点灯  
  手が入っちゃってますけど気にしないでいただきたいです・・・  
  ![](/images/fpga/002/実行結果2.jpg)

ちゃんと動いた瞬間はやっぱり嬉しかったですね！  
ソフトウェアのHello Worldとはまた違う、「物理的なボタンとLEDが自分の書いたコードで繋がった」という感覚がありました！  

## まとめ
今回の内容をまとめると以下になります。  
1. Basys3の回路図を見て、使うピン(BTNC/LD7)のアサインを確認  
2. Verilogで「ボタン入力をLED出力にそのまま繋ぐ」だけの最小構成を実装  
3. 制約ファイルで論理信号と物理ピンを結びつけ  
4. synthesis → implementation → bitstream生成という3工程でコンパイル  
5. ボタンを押すとLEDが光ることを確認  

## おわりに
特定のボタンを押したらLEDが点灯するというプログラムを実装してみました。  
次回以降はまだ何をしていくかが決まってないですけど、最終的なゴールとしてCPU実装を掲げているのでそれに向けて少しずつ進めていきます～  
