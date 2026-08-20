# 台帳マージ報告 2026-08-19

`CALIB_MASTER_20260815_1.csv` (216) + `CALIB_ADDITIONS_20260817{,b,c,d}.csv` (36+8+2+3=49)
→ **`CALIB_MASTER_20260819.csv` = 264 行**

重複キー (block, param)：なし

## ブロック別行数

| block | n |
|---|---|
| A1 産出額シェア | 4 |
| A2 面積シェア | 4 |
| A3 輸入依存度 | 5 |
| A4 有機収量比 | 6 |
| A5 N2O排出係数 | 4 |
| A6 有機プレミアム | 4 |
| A7 部門シェア | 2 |
| A8 対外アンカー | 3 |
| A9 SNA | 5 |
| B 構造 | 54 |
| C 集計 | 14 |
| D 対外利回り | 4 |
| E 閉鎖 | 23 |
| F シナリオ | 13 |
| G 結果 | 46 |
| H 文脈 | 9 |
| I 除外 | 14 |
| J 引用文献 | 50 |

## status 別

| status | n |
|---|---|
| OK | 201 |
| VERIFIED (R = Python) | 41 |
| DO NOT REVIVE | 14 |
| RETIRED (superseded) | 5 |
| DECIDED / 実装反映済 (R・Python とも) | 1 |
| RETIRED (superseded by full-text row) | 1 |
| VERIFIED | 1 |

## 適用した操作

| 種別 | 対象 | 内容 |
|---|---|---|
| UPDATE | `B 構造/Fbar` | note に Fbar_kgN への相互参照を追記（handoff §3.1） |
| OVERWRITE | `B 構造/ch4_uplift` | 0.659402 -> 0.8673672646 |
| UPDATE | `B 構造/ch4_uplift_routes` | route A A(Katayanagi,nu_O条件付) 0.6594 [... -> A=0.8674 [0.7575-1.2045] |
| REWRITE | `B 構造/ch4_CN_sensitivity` | nu_O 基準を 0.625→1.1927 に再基準化。handoff §1 で退役した「事実上無条件」を平衡限定に書き換え |
| UPDATE | `B 構造/epsN_gm_counter_check` | epsN_gm=0.00195(Xie実測) 使用時：破断点 0.08432（n... -> 6.68-8.36x |
| UPDATE | `G 結果/ch4_breakeven` | 余裕 11.12x -> 14.63x、反対側チェックの破断点を明記 |
| UPDATE | `G 結果/S1_dGHGnet_2050` | スコープ注記（SOC込みでも不変） |
| REWRITE | `G 結果/S2_dGHGnet_2050` | 103.8072 -> 排出項+139.7799 / SOC込み-139.0465。平衡一致の論証を追記 |
| UPDATE | `I 除外/soil quality SQ feedback` | note に theta=0.15 行への参照を追記（handoff §3.1） |
| DROP | `A: C集計/ch4_uplift` | R1 上書き処理済み。既存行は handoff の言う C集計 ではなく **B構造** にあった（🔴 handoff §3.1 の記述誤り）。B構造行を正本とし重複を落とした |
| RETIRE | `A: J引用/Ma et al. 2023` | d の全文版を正本とし、抄録版は退役として保持 |
| ENRICH | `d: J引用/Ma et al. 2023` | 深度0-30cm・気候帯別最適36 g/kg・N別ギャップ・測定法の留保を note に追記（handoff §7.1） |
| RETIRE | `A: resid_loss` | バッチ内で上位版に置換されたため退役として保持 |
| RETIRE | `A: iota` | バッチ内で上位版に置換されたため退役として保持 |
| RETIRE | `A: dGHG_2050_with_SOC` | バッチ内で上位版に置換されたため退役として保持 |
| RETIRE | `A: dGHG_crossover_annual` | バッチ内で上位版に置換されたため退役として保持 |
| RETIRE | `A: dGHG_crossover_cumulative` | バッチ内で上位版に置換されたため退役として保持 |
| RECOMPUTE | `A: G結果/stock_conc_resolution` | handoff §6.5 最終行。2.1倍 -> 0.104倍。深度不一致の残存を明記 |
| FLAG | `A: F シナリオ/A50_denominator` | 未解決として注記を強化（memory の懸案） |
