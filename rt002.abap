*&---------------------------------------------------------------------*
*& Report  ZSD0005N
*&
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*2019/01/11 CHRIS   190111  新加一個外部程式CALL P_JOBTPS = 'E'(ZBD40231)
*2019/01/16 CHRIS   190116  Packing ship-to中國要檢查usci Code(Warming)
*2019/03/29 CHRIS   190329  進出口需要把FREE ITEM REMARK出來
*2019/04/25 CHRIS   190425  增加一個packing ship to 的功能
*2019/05/07 NANCYHU 190507  download excel(DWPK)時,check ZBCOD是否有資料
*2019/05/08 NANCYHU 190508  GET_USCI_CODE modify(要抓ship-to)
*2019/05/08 MARVIN  050819  關務要show 完整料號
*2019/05/14 MARVIN  051419  1.Invoice/Packing material desc 先取 table MAKT
*                           2.Credit memo remark add TEXT-0003
*2019/05/21 NANCYHU 190521  get TEXT-0003 bug modify
*2019/05/23 NANCYHU 190523  字串太長顯示不完整 bug modify
*2019/06/05 MARVIN  060519  change bad die rule
*2019/06/18 NANCYHU 190618  Paackage 不列印此remark: 1 Wafer =' PFV_WDIES 'Dies'
*2019/07/03 NANCYHU 190703  Credit 要印出 header text; T04(RMA WaferID)
*2019/07/09 NANCYHU 190708  INV PDF 加密功能
*2019/07/18 CHRIS   190718  關務使用的INVOICE要加報關文件字眼,同時不SHOW CHIPNAME
*2019/07/29 marvin  072919  Packing & Invoice chip name 改用table ZSHIP6
*2019/08/08 MARVIN  080819  DEBUG FOR FREE INVOICE BACKLOG = 0
*2019/08/19 nancyhu 190819  ovt b2b pdf file name bug modify
*2019/08/26 marvin  082619  Prodtype = 'D' ,  以主要好品料的只顯示的remakr : wafer = ~ Dies
*2019/08/27 marvin  082719  packing item sort condition 8" & 12"分開
*2019/09/04 nancyhu 190904  NAS packing&invoice pdf
*2019/09/05 CHRIS   190905  8"的die數改從FDMS抓取,同時修改維護DIE的畫面(特殊RULE要寫出去)
*2019/09/12 CHRIS   190912  LSPF的CHIPNAME抓VBAP,而MEMORY抓ZSHIP6
*2019/09/20 nancyhu 190920  zship6 get zchip bug modify
*2019/09/23 marvin  092319  debug 嘜頭 for KTC
*2019/09/25 nancyhu 092519  add 預收款折讓
*2019/10/14 marvin  101419  修正Prodtype = 'D' ,  以主要好品料號的判斷
*2019/10/15 nancyhu 101519  add package prodtype S
*2019/10/21 CHRIS   191021  寫進ZF32CA時最後一行MADE IN TAIWAN不再加(HSINCHU)
*2019/11/04 marvin  110419  payment term 為TT時, 不check 銀行主檔, 不顯示帳號
*2019/11/07 marvin  110719  12" Credit/debit memo 不取reference unit price
*2019/11/11 nancyhu 111119  OVT 假日出貨
*2019/11/18 nancyhu 111819  移除USCI WARNING
*2019/12/09 marvin  120919  12" pdf與excel 同時寄時title 一致
*2020/02/12 nancyhu 021220  modify for Finance 下載 PDF (P_JOBTPS = 'I')
*2020/02/25 marvin  022520  OVT add remakr for 1 wafer gross dies
*2020/02/25 CHRIS   200225  STRUCTURE ADD NEW COLUMN
*2020/03/17 CHRIS   200317  FREE INVOICE的ITEM順序和PACKING的不一致
*2020/04/29 nancyhu 042920  for CLS alert B2B modify
*2020/05/08 chris   200508  TAX TOTAL的計算,目前是ITEM先乘後加(可能會有尾差),加一段做先加後乘
*2020/05/22 chris   200522  invoice新增remark
*2020/07/10 chris   200710  客戶4083/4197 bonding invoice/Packing remark註記 "B2 按月彙報"
*2020/07/22 chris   200722  客戶4011需要客制化文件內容
*2020/09/07 marvin  090720  debug form modify ZBCOD
*2020/09/10 chris   200910  客戶4011需要客制化文件內容(改名字)
*2020/10/13 marvin  101320  NXP 修改 remark gross die description & add 說明行
*2020/12/01 CHRIS   201201  IMEX的原單價的KPEIN > 1,當它移到PROCESS CHARGE沒把KPEIN帶到SKPEI導致小數位算錯
*2021/02/01 CHRIS   210201  加入New PI邏輯
*2021/03/22 marvin  032221  Longsys shipping mark special rule
*2021/04/22 CHRIS   210422  1.出貨時選擇扣的pi(此pi已check是否印過[zpd1有值],是否active,因此這裡就可以不用再檢查一次了)
*                           2.NEW PI將不再由這支程式寫ZPD1
*                           3.檢查F5與放在ZPDH中的資料金額是否一致
*2021/05/11 marvin  051121  12" skip connect 8" SQL server
*2021/06/18 chris   210618  SP_RULE_FOR_DOC_DISPLAY 中的邏輯是因應display而修改的部份,但裡面的邏輯error導致nxp的item重覆(多筆時)
*                           把部份by客戶的客制移到相關的SP開頭的perform中
*&---------------------------------------------------------------------*

REPORT  ZSD_RT002 MESSAGE-ID ZY.

TABLES: LIKP, LIPS, VBRK, VBRP, KNVK, DD07T, VBAK, VBPA, VBFA, TLINE, KNA1, ADRC, T005T, VEKP, MARA, MCHA, VEPO,
        VBKD, VBAP, MKPF, KONV, MAKT, KOMK, KOMV, TCURX, T880, SSCRFIELDS, VBUK, TVKOT, KNBK, BNKA, USR02,
        ZSDA02, ZSD111, ZF32CA, ZWHRELNO, ZZAUSP, ZSD90, ZMM29, ZSD63, ZSD52, ZVCHAR_VL, ZPD1, ZPD2, ZPD6,
        ZB2BI1, ZMMFTP, ZSDEL, ZSD104, ZEXHD, ZSDA04, ZSDDEST, ZMSBMM, ZMSBMV, ZSD_ONS, ZEXDT, ZSDBKN, ZZVBAK, ZBC15,
        ZSD86, ZHPACK_DN, ZB2BI_OVT, ZSD99, ZCLOTID, ZSDPI_MAPPING, ZHPACK, ZSD170, ZSD170A, ZSD64, ZSD154, ZBCOD,
        ZSDEC_PWD, ZLINK, ZDBCON, ZMWH8H, ZSHIP6, ZSD101, ZPDH, ZPDI.
TYPE-POOLS: SLIS.

DATA: BEGIN OF I_HEAD OCCURS 0,
        ZORDE       TYPE  I,                "(X)排序用
        ZFSET       TYPE  C,                "(X)記錄是否有寄送過(FTP)
        ZMSET       TYPE  C,                "(X)記錄是否有寄送過(MAIL)
        ZCOMP(11)   TYPE  C,                "(X)判斷換頁用(ZTYPE+VBELN)
        ZTYPE       TYPE  C,                "(X)判斷單據類型 P=PACKING I=INVOICE F=FREE INVOICE C=CREDIT MEMO R=PROFORMA
        PFLAG       TYPE  C,                "(X)判斷是否為吃PROFMA的INVOICE
        PBYPC       TYPE  C,                "(X)'X'=以片計價的PI ''=用Rate的PI(只有ZTYPE='R')
        DOCTP       TYPE  C,                "(X)判斷是否印"報關文件"
        REMAK       TYPE  VAL_TEXT,         "REMARK
        VKORG       TYPE  VKORG,            "Sales Org
        VTWEG       TYPE  VTWEG,            "(X)Distribution Channel
        SPART       TYPE  SPART,            "(X)Division
        VBELN       TYPE  VBELN_VF,         "INVOICE / CREDIT MEMO NO.
        KURRF       TYPE  KURRF,            "(X)Exchange Rate給I_ITEM_TO-TBRGE用
        FKART       TYPE  FKART,            "(X)Billing Type
        VGBEL       TYPE  VBELN_VL,         "DN NO. / FREE INVOICE NO.
        AUBEL       TYPE  VBELN_VA,         "SO NO.
        ZMTSO       TYPE  C,                "(X)判斷是否為多筆SO(''=一對一,'X'=一對多)
        ERDAT       TYPE  SYDATUM,          "To Be Ship Date
        SIDAT       TYPE  ZSIDAT,           "INVOICE DATE
        LCNUM(35)   TYPE  C,                "LC NO.
        INCO2       TYPE  INCO2,            "DELIVERY TERMS / TRADE TERMS
        SHVIA(10)   TYPE  C,                "SHIP VIA
        DESTI(20)   TYPE  C,                "DESTINATION
        FRTER(15)   TYPE  C,                "FREIGHT TERMS
        PAYTM(100)  TYPE  C,                "PAYMENT TERMS(VBRK-ZTERM+T052U-TEXT1)
        VFVBL       TYPE  VBELN_VF,         "當ZTYPE = 'P',這裡放所對應的BILLING
        USCIC       TYPE  AD_NAME_CO,       "放出中國的USCI Code
        KUNAG       TYPE  KUNAG,            "(X)SOLD TO[KEY]
        KUNNR       TYPE  KUNWE,            "(X)SHIP TO[KEY]
        BKUNN       TYPE  KUNNR,            "(X)BILL TO[KEY]
        RELNO       TYPE  ZRELNO,           "(X)放行單號          (供ITEM_REMARK使用)
        CDATE       TYPE  ZIXCRELDAT,       "(X)放行日期          (供ITEM_REMARK使用)
        RFBSK       TYPE  RFBSK,            "(X)判斷該BILLING是否已RELEASE (PI使用)
        JBTPS       TYPE  C,                "(X)接外部系統給的值使用              "I140214
        SHTWD       TYPE  C,                "(X)判斷是否要轉換成TWD               "I171018
        STEMP       TYPE  C,                "(X)關務印章判斷是否使用              "I171018
        STMP2       TYPE  C,                "(X)關務大小章判斷是否使用            "I191024
        PRODTYPE    TYPE  ZPRODTYPE,        "(X)Shiping Product type
    END OF I_HEAD.

DATA: BEGIN OF I_HEAD_BI OCCURS 0,          "BILL TO的資料
        VBELN       LIKE  LIKP-VBELN,       "DELIVERY NO. [KEY]
        ZTYPE       TYPE  C,                "(X)單據類型  [KEY]
        KUNAG       LIKE  LIKP-KUNAG,       "CUST NO.     [KEY]
        NAME1       LIKE  KNA1-NAME1,       "公司名1
        NAME2       LIKE  KNA1-NAME2,       "公司名2
        NAME3       LIKE  KNA1-NAME3,       "公司名3
        NAME4       LIKE  KNA1-NAME4,       "公司名4
        STREET      LIKE  ADRC-STREET,      "住址1
        STR_SUPPL1  LIKE  ADRC-STR_SUPPL1,  "住址2
        STR_SUPPL2  LIKE  ADRC-STR_SUPPL2,  "住址3
        STR_SUPPL3  LIKE  ADRC-STR_SUPPL3,  "住址4
        LOCATION    LIKE  ADRC-LOCATION,    "住址5
        ORT02       LIKE  KNA1-ORT02,       "區
        LANDX(25)   TYPE  C,                "國家KNA1-PSTLZ+T005T-LANDX(KNA1-LAND1~T005T-LAND1)
        TELNU(30)   TYPE  C,                "電話(ZGET_CONTACT_DATA  TEL+EXT)
        FAXNO(30)   TYPE  C,                "傳真(ZGET_CONTACT_DATA)
        CONCT(35)   TYPE  C,                "聯絡人(ZGET_CONTACT_DATA)
        SORTL       LIKE  KNA1-SORTL,       "Sort field
        CITY1       LIKE  ADRC-CITY1,       "CITY
        POSTL       LIKE  ADRC-POST_CODE1,  "postal code
        REGIO       LIKE  ADRC-REGION,      "region code
        LAND1       LIKE  ADRC-COUNTRY,     "country
      END OF I_HEAD_BI.
DATA: I_HEAD_SO LIKE I_HEAD_BI OCCURS 0 WITH HEADER LINE,
      I_HEAD_SH LIKE I_HEAD_BI OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF I_ITEM OCCURS 0,
        VBELN       LIKE  VBRP-VBELN,        "(X)單號  [KEY]
        ZTYPE       TYPE  C,                 "(X)單據類型  [KEY]
        KUNAG       LIKE  LIKP-KUNAG,        "(X)CUST NO.
        POSNR       LIKE  VBRP-POSNR,        "(X)ITEM NO.
        PSTYV       LIKE  VBRP-PSTYV,        "(X)ITEM TYPE                          "I140424
        PORDE       TYPE  I,                 "(X)PALLET排列用序號
        CORDE       TYPE  I,                 "(X)CARTON排列用序號
        UEVEL       LIKE  VEKP-UEVEL,        "(X)HIGH LEVEL Internal HU no.
        VENUM       LIKE  VEKP-VENUM,        "(X)Internal HU no
        VGBEL       LIKE  VBRP-VGBEL,        "(X)DELIVERY
        VGPOS       LIKE  VBRP-VGPOS,        "(X)DELIVERY ITEM
        UECHA       TYPE  UECHA,             "(X)gher-Level Item of Batch Split Item
        AUBEL       LIKE  VBRP-AUBEL,        "(X)SO
        AUPOS       TYPE  POSNR_VA,          "(X)SO ITEM
        BSTNK(35)   TYPE  C,                 "(X)Cust PO No. FOR REMARK
        KURKI(04)   TYPE  C,                 "(X)判斷合併筆數的依據使用
        PALNO       TYPE  STRING,            "PALLET NO.
        CTNNO       TYPE  STRING,            "CARTON NO.
        KDMAT       LIKE  LIPS-KDMAT,        "customer material
        DCEMN       LIKE  VBRP-FKIMG,        "DISPLAY shipping qty (chip)#
        DWEMN       LIKE  VBRP-FKIMG,        "DISPLAY shipping qty (wafer)#
        DCODE(15)   TYPE  C,                 "DATECODE
        LOTNO(12)   TYPE  C,                 "LOT NO
        DPNTG       LIKE  VEKP-NTGEW,        "PALLTE net weight
        DNTGE       LIKE  VEKP-NTGEW,        "CARTON net weight
        PDIME(20)   TYPE  C,                 "PALLET DIM
        ITMNO(04)   TYPE  C,                 "ITEM編號
        CASNO(04)   TYPE  C,                 "CASE NO.
        MATNR       LIKE  LIPS-MATNR,        "MATERIAL NUMBER
        ZCHIP       TYPE  ZCHIP,             "CHIP NAME
        CEMEH       LIKE  VEPO-VEMEH,        "unit of measure (chip)
        WEMEH       LIKE  VEPO-VEMEH,        "unit of measure (wafer)
        CHARG       LIKE  LIPS-CHARG,        "KEY NO.
        BSTKD(35)   TYPE  C,                 "Cust PO No. + Item
        DPBRG       LIKE  VEKP-BRGEW,        "PALLTE gross weight
        DBRGE       LIKE  VEKP-BRGEW,        "CARTON gross weight
        GEWEI       LIKE  VEKP-GEWEI,        "(X)重量單位
        CDIME(20)   TYPE  C,                 "CARTON DIM
        MAKTX(100)  TYPE  C,                 "Material Description
        POSEX       LIKE  VBAP-POSEX,        "Cust PO ITEM.
        WAERK       LIKE  VBRK-WAERK,        "CURRENCY
        UNITP       TYPE  NETPR,             "UNIT PRICE#
        KPEIN       TYPE  KPEIN,             "UNIT PRICE BASE
        BRAND       LIKE  VBAP-ZBRAND,       "BRAND
        KWMEN       LIKE  VBRP-FKIMG,        "order qty#
        KWERT       TYPE  KBETR,             "extension#
        MWSK1       LIKE  KOMV-MWSK1,        "CODE
        KBETR       TYPE  KBETR,             "TAX#
        BACKL       LIKE  VBRP-FKIMG,        "open blance qty#
        WERKS       LIKE  VBRP-WERKS,        "PLANT
        BONDI       TYPE  C,                 "BONDING
        KBET1       LIKE  KOMV-KBETR,        "DISC#
        WRKST       LIKE  MARA-WRKST,        "WAFER Description
        REMRK       TYPE  STRING,            "REMARK
        ZPOST       LIKE  VBAP-ZPOSTX,       "TEXT
        SKPEI       TYPE  KPEIN,             "UNIT PRICE BASE(Foundry Service Charge)-IM/EX
        SCUTP       TYPE  NETPR,             "UNIT PRICE#(Foundry Service Charge)-IM/EX
        SCKWE       TYPE  KBETR,             "extension (Foundry Service Charge)-IM/EX
        PKPEI       TYPE  KPEIN,             "UNIT PRICE BASE(Processing Charge)-IM/EX
        PCUTP       TYPE  NETPR,             "UNIT PRICE#(Processing Charge)-IM/EX
        PCKWE       TYPE  KBETR,             "extension (Processing Charge)-IM/EX
        CONSI(01)   TYPE  C,                 "(X)判斷是否為CONSIGN的料(IMEX)
        GDQTY       LIKE  ZMWHG-CHQTY,       "(X) Good die Qty (以die計價時放入)
        BDQTY       LIKE  ZMWHG-CHQTY,       "(X) Good die Qty (以die計價時放入)
        4TH1(75)    TYPE  C,                 "P=Die Info(第4行第1欄位SP Rule) Gross die, wafer ID ...等資訊
        4TH2(30)    TYPE  C,                 "P=PO Item(第4行第2欄位SP Rule) BOM no (Export only)
        9LINE(120)  TYPE  C,                 "P=PO Line(最後1行SP Rule)      NXP informsation
      END OF I_ITEM.


DATA: BEGIN OF I_ITEM_RE OCCURS 0,
        VBELN       LIKE  LIKP-VBELN,        "(X)單號  [KEY]
        ZTYPE       TYPE  C,                 "(X)單據類型  [KEY]
        ZRTYPE(12)  TYPE  C,                 "(X)REMARK類型
        REMRK(300)  TYPE  C,                 "REMARKS
      END OF I_ITEM_RE.

DATA: BEGIN OF I_ITEM_SHRE OCCURS 0,
        VBELN       LIKE  VBRP-VBELN,        "單號  [KEY]
        ZTYPE       TYPE  C,                 "(X)單據類型  [KEY]
        KUNNR       LIKE  VBAK-KUNNR,        "(X)SHIP TO[KEY]
*        NAME1       LIKE  KNA1-NAME1,        "SHIP-TO NAME
        NAME1(50)   TYPE  C,                 "SHIP-TO NAME
        ORT01       LIKE  KNA1-ORT01,        "送貨地點
        PSQUN(30)   TYPE  C,                 "箱數資訊
        LMAKE(25)   TYPE  C,                 "製造地
      END OF I_ITEM_SHRE.

DATA: BEGIN OF I_ITEM_TO OCCURS 0,
        VBELN       LIKE  LIKP-VBELN,        "(X)單號  [KEY]
        ZTYPE       TYPE  C,                 "(X)單據類型  [KEY]
        TCEMN(10)   TYPE  C,                 "Total shipping qty (chip) / INV. SUBTOTAL
        TWEMN(10)   TYPE  C,                 "Total shipping qty (wafer) / ITEM DISC.
        TPNTG(10)   TYPE  C,                 "Total PELLTE net weight / HEADER DISC.
        TPBRG(10)   TYPE  C,                 "Total PELLTE gross weight / INV. TAX AMOUNT
        TNTGE(10)   TYPE  C,                 "Total net weight / INVOICE VAT
        TBRGE(10)   TYPE  C,                 "Total gross weight / FREIGHT(nTW) / Exchange Rate(TW)
        TLAEN(10)   TYPE  C,                 "Total dim / INVOICE AMOUNT
        SUBTO       LIKE KOMV-KBETR,         "Total INV. SUBTOTAL
        IDISK       LIKE KOMV-KBETR,         "Total ITEM DISC.
        HDISK       LIKE KOMV-KBETR,         "Total HEADER DISC.
        TAXAM       LIKE KOMV-KBETR,         "Total INV. TAX AMOUNT
        TOTAL       LIKE KOMV-KBETR,         "Total INVOICE AMOUNT
        WAERK       LIKE VBRK-WAERK,         "CURRENCY
        GDPWO(15)   TYPE P,                  "totle gross die
      END OF I_ITEM_TO.

DATA: BEGIN OF I_ITEM_PIHEAD OCCURS 0,       "PI HEADER
        VBELN       LIKE VBRK-VBELN,         "(X)INVOICE NO.      [KEY]
        ZTYPE       TYPE C,                  "(X)單據類型  [KEY]
        ZSHOW       TYPE C,                  "(X)顯示資訊判斷用
        WAERK       LIKE VBRK-WAERK,         "INVOICE CURRENCY
        FOAMT       LIKE ZPD2-FOAMT,         "PI AMOUNT總計
        KURRF       LIKE VBRK-KURRF,         "EXCHANGE RATE(依現在這張單的EXCHANGE RATE)
        TOTAL       LIKE VBRP-NETWR,         "此billing total AMOUNT
        RESUT       LIKE ZPD2-FOAMT,         "RESULT AMOUNT
        TWAER       LIKE VBRK-WAERK,         "預設為'TWD',為顯示用
        TRESU       LIKE ZPD2-FOAMT,         "原幣AMOUNT
      END OF I_ITEM_PIHEAD.

DATA: BEGIN OF I_ITEM_PIITEM OCCURS 0,                                                            "PI ITEM
        VBELN       TYPE VBELN_VF,           "(X)Billing NO.(I) Proforma No.(R)      [KEY]
        POSNR       TYPE POSNR_VF,           "(X)ITEM NO.
        ZTYPE       TYPE C,                  "(X)單據類型  [KEY]
        AUBEL       TYPE VBELN_VA,           "(X)SO NO.            [KEY]
        ERDAT       TYPE ERDAT,              "(X)單據日期
        ERZET       TYPE ERZET,              "(X)單據時間
        PERFI       TYPE ZPERFI,             "proforma invoice No / 使用該PI的INVOICE
        OPVBE       TYPE VBELN_VF,           "OLD PI NO
        DOWNP       TYPE ZPERFI,             "down payment No
        FOAMT       TYPE KBETR,              "offset amount document currency
        PITAX       TYPE KBETR,              "Tax
        WAERK       TYPE WAERK,              "CURRENCY
      END OF I_ITEM_PIITEM.


DATA: BEGIN OF I_ZSDA02 OCCURS 0.
        INCLUDE STRUCTURE ZSDA02.
DATA:   SELEC     TYPE C,
        STYLE     TYPE LVC_T_STYL,
        DUPCE(13) TYPE P DECIMALS 9,
      END OF I_ZSDA02.
DATA: BEGIN OF S_BKUNN OCCURS 0,
        BKUNN       LIKE  VBAK-KUNNR,       "I=BILL-TO / P = SOLD TO
        KUNNR       LIKE  VBAK-KUNNR,       "I=SOLD-TO / P = SHIP-TO
        ZTYPE       TYPE  C,
      END OF S_BKUNN.
*************************************Reference使用*************************************
*  以Die 計價delivery, 計算wafer qty
DATA: BEGIN OF I_DIEW OCCURS 0,
       VBELN TYPE VBELN_VL,         "DELIVERY/INVOICE
       POSNR TYPE POSNR_VL,         "ITEM NO.
       CHARG TYPE CHARG_D,          "KEN NO
       DCEMN TYPE FKIMG,            "DISPLAY shipping qty (chip)#
   END OF I_DIEW.
*<-D210616
*DATA: BEGIN OF I_WADIE OCCURS 0,
*       VBELN TYPE VBELN_VL,         "DELIVERY/INVOICE
*       CHARG TYPE CHARG_D,          "KEN NO
*       DCEMN TYPE FKIMG,            "DISPLAY shipping qty (chip)#
*   END OF I_WADIE.
*->D210616
*NC CHIP using
DATA: BEGIN OF I_NCP OCCURS 0,
       WNO(02)    TYPE N,
       NCQTY(08)  TYPE P DECIMALS 0,
       TQTY(08)   TYPE P DECIMALS 0,
  END OF I_NCP.

*************************************Reference使用*************************************
**做是否顯示功能鍵用的TABLE
DATA: BEGIN OF FC_TAB OCCURS 0,
        FCODE(05) TYPE C,
      END OF FC_TAB.

DATA: BEGIN OF IMEX_HEAD OCCURS 0,
        CPROG LIKE SY-CPROG,
        SDATE LIKE SY-DATUM,
        EDATE LIKE SY-DATUM,
      END OF IMEX_HEAD.

DATA: BEGIN OF IMEX_ITEM OCCURS 0,
        KUNAG LIKE KNA1-KUNNR,
        NAME1 LIKE KNA1-NAME1,
        VBELN LIKE VBRK-VBELN,
        SDATE LIKE SY-DATUM,
        VGBEL LIKE VBRK-VBELN,
        CDATE LIKE ZWHRELNO-CRELDATE,
        RELNO LIKE ZWHRELNO-RELNO,
        ERNAM LIKE LIKP-ERNAM,
        PRINT TYPE C,
      END OF IMEX_ITEM.

*****************************出入庫申請單使用******************************
DATA: BEGIN OF WM1_I_HEAD OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型(O=出庫申請單, I=入庫申請單)  [KEY]
        LFART       TYPE LFART,         "(X)DN TYPE
        KUNAG       TYPE KUNAG,         "(X)SOLD-TO
        KUNNR       TYPE KUNWE,         "(X)SHIP-TO
        XBLNR       TYPE XBLNR1,        "出庫單號           (MKPF-XABLN)
        MBLNR       TYPE MBLNR,         "MATERIAL DOC. NO   (VBFA-VBELN)
        BWART       TYPE BWART,         "Movement Type      (VBFA-BWART)
        ERDAT       TYPE ERDAT,         "申請日期           (LIKP-ERDAT)
        ODATM       TYPE SYDATUM,       "出庫日期           (LIKP-WADAT_IST)
        DTATM(19)   TYPE C,             "預估時間(格式:MM/DD/YYYY-HH:MM:SS)
        AUBEL       TYPE VBELN_VA,      "Return SO / SO NO.
        OAUBE       TYPE VBELN_VA,      "ORGINIAL SO NO
        OVGBE       TYPE VBELN_VL,      "ORGINIAL DN
        OVBEL       TYPE VBELN_VF,      "(X)ORGINIAL BILLING
        ZPDTP(50)   TYPE C,             "RETUNR的產品狀況
        ZMTSO(01)   TYPE C,             "(X)判斷是否為多筆SO(''=一對一,'X'=一對多)
        ZMOSO(01)   TYPE C,             "(X)判斷是否為多筆原SO(''=一對一,'X'=一對多)-入庫
        ZMODN(01)   TYPE C,             "(X)判斷是否為多筆原DN(''=一對一,'X'=一對多)-入庫
        ZMPDT(01)   TYPE C,             "(X)判斷是否為多筆RETUNR的產品狀況
      END OF WM1_I_HEAD.

DATA: BEGIN OF WM1_I_HEAD_SH OCCURS 0,  "SHIP TO的資料
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型  [KEY]
        KUNAG       TYPE KUNAG,         "CUST NO.     [KEY]
        NAME1       TYPE NAME1_GP,                          "公司名1
        NAME2       TYPE NAME2_GP,                          "公司名2
        NAME3       TYPE NAME3_GP,                          "公司名3
        NAME4       TYPE NAME4_GP,                          "公司名4
        STREET      TYPE AD_STREET,                         "住址1
        STR_SUPPL1  TYPE AD_STRSPP1,                        "住址2
        STR_SUPPL2  TYPE AD_STRSPP2,                        "住址3
        STR_SUPPL3  TYPE AD_STRSPP3,                        "住址4
        LOCATION    TYPE AD_LCTN,                           "住址5
        ORT02       TYPE ORT02_GP,      "區
        LANDX(25)   TYPE C,             "國家KNA1-PSTLZ+T005T-LANDX(KNA1-LAND1~T005T-LAND1)
        TELNU(30)   TYPE C,             "電話(ZGET_CONTACT_DATA  TEL+EXT)
        FAXNO(30)   TYPE C,             "傳真(ZGET_CONTACT_DATA)
        CONCT(35)   TYPE C,             "聯絡人(ZGET_CONTACT_DATA)
        SORTL       TYPE SORTL,         "Sort field
        CITY1       TYPE AD_CITY1,      "CITY
        POSTL       TYPE AD_PSTCD1,     "postal code
        REGIO       TYPE REGIO,         "region code
        LAND1       TYPE LAND1,         "country
      END OF WM1_I_HEAD_SH.

DATA: BEGIN OF WM1_I_HEAD_IN OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "(X)DELIVERY NO.  [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型      [KEY]
        NAME1       TYPE NAME1_GP,      "麥頭
        ANZPK       TYPE ANZPK,         "箱數
        CCOMP       TYPE NAME1_GP,      "提貨公司
        CPERS(10)   TYPE  C,            "提貨人
        CCARS(10)   TYPE  C,            "車號
        DATTM(18)   TYPE  C,            "日期時間
        ZTELE(10)   TYPE  C,            "行動電話
      END OF WM1_I_HEAD_IN.

DATA: BEGIN OF WM1_I_ITEM OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "(X)DELIVERY NO.  [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型      [KEY]
        VGPOS       TYPE POSNR_VL,      "項次
        MATNR       TYPE MATNR,         "料號
        MAKTX       TYPE MAKTX,         "品名型號
        WRKST       TYPE WRKST,         "尺寸
        CHARG       TYPE CHARG_D,       "批號
        VRKME       TYPE VRKME,         "單位
        WERKS       TYPE WERKS_D,       "廠別
        LFIMG       TYPE KCMENG,        "申請數量/實繳數量
        LGPBE       TYPE LGPBE,         "儲位
        LGORT       TYPE LGORT_D,       "倉別
        LICHA       TYPE LICHN,         "DATE CODE
        BSTNK       TYPE BSTNK,         "CUSTOMER PO
        STEXT(50)   TYPE C,             "MARTRIAL SALES TEXT(品名型號下面)
        AUBEL       TYPE VBELN_VA,      "(X)SO Remark使用
        AUPOS       TYPE POSNR_VA,      "(X)SO Item Remark使用
      END OF WM1_I_ITEM.

DATA: BEGIN OF WM1_I_ITEM_RE OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "(X)DELIVERY NO.  [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型      [KEY]
        REMRK(300)  TYPE C,             "REMARKS
      END OF WM1_I_ITEM_RE.

DATA: BEGIN OF WM1_I_ITEM_SG OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "(X)DELIVERY NO.  [KEY]
        ZTYPE(01)   TYPE C,             "(X)單據類型      [KEY]
        ERNA1       TYPE ERNAM,         "申請部門承辦人
        ERNA2       TYPE ERNAM,         "申請部門主管
        ZPEX1       TYPE ZPEXT,         "申請部門承辦人分機
        ERNA3       TYPE ERNAM,         "成品課承辦人
        ERNA4       TYPE ERNAM,         "成品課主管
        ZPEX2       TYPE ZPEXT,         "成品課承辦人分機
      END OF WM1_I_ITEM_SG.
*****************************出入庫申請單使用******************************
********************************出貨檢核表*********************************
DATA: BEGIN OF WM2_I_HEAD OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        LINES(20)   TYPE C,             "多少個CASE NO(參考ZSD01191 V_LINES)
        TCQTY       TYPE ZCHQTY,        "Total Chip Qty
        TWQTY       TYPE LFIMG,         "Total Wafer Qty
        MEINS       TYPE MEINS,         "Unit
        SHBID(01)   TYPE C,             "(X)判斷標題是顯示BOX ID或是KURAKI
      END OF WM2_I_HEAD.

DATA: BEGIN OF WM2_I_ITEM OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        VGPOS       TYPE POSNR_VL,
        EXIDV(3)    TYPE N,
        ITEMS(3)    TYPE N,
        WERKS       TYPE WERKS_D,       "PLANT
        MATNR       TYPE MATNR,         "MATERIAL No.
        CASNO       TYPE ZCASE,         "Case No.
        KURKI(9)    TYPE C,             "Kuraki
        CHARG       TYPE CHARG_D,       "key no
        DCODE(15)   TYPE C,
        BCODE       TYPE ZBCODE1,       "Elpida batch code
        LFIMG       TYPE LFIMG,
        SBQTY       TYPE LFIMG,         "累加
        VRQTY       TYPE LFIMG,         "同料號加總-該筆LFIMG
        MEINS       TYPE MEINS,         "Unit
        CHQTY       TYPE ZCHQTY,        "Good Die數
        WAQTY       TYPE LFIMG,
        WFFLG(1)    TYPE C,             "(X)做為HEADER是否加總數量用
        ENDFG(1)    TYPE C,             "(X)判斷是否為該CASE NO的最後一筆
      END OF WM2_I_ITEM.

DATA: BEGIN OF WM2_I_ITEM_SB OCCURS 0,  "should be picked quantity
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        WERKS       TYPE WERKS_D,
        MATNR       TYPE MATNR,
        LFIMG       TYPE LFIMG,         "all material quantity in this delivery
        KCMEN       TYPE KCMENG,        "Cumulative(累積的) picked quantity
        VRQTY       TYPE LFIMG,         "KCMEN - LFIMG
        MEINS       TYPE MEINS,         "Unit
      END OF WM2_I_ITEM_SB.
DATA: BEGIN OF WM2_I_REMK OCCURS 0,
        VGBEL       TYPE VBELN_VL,      "DN NO.                                   [KEY]
        RECOD       TYPE I,
        ITEXT(120)  TYPE C,
        DLINE       TYPE C,                                 "I200225
      END OF WM2_I_REMK.
DATA: BEGIN OF WM2_I_STOCK OCCURS 0,
        VGBEL TYPE VBELN_VL,      "DN NO.                                   [KEY]
        CASNO TYPE ZCASE,         "Case No.
        MATNR TYPE MATNR,
        KEYNO TYPE ZKEY1,
        KURKI TYPE ZKURAKI,
        DCODE TYPE ZDATECODE1,
        FKIMG TYPE FKIMG,
        MEINS TYPE MEINS,
        BOXID TYPE ZBOXID,
      END OF WM2_I_STOCK.

DATA: WM1_I_HEAD_SO    LIKE WM1_I_HEAD_SH  OCCURS 0 WITH HEADER LINE,
      WM2_I_ITEM_NEXST LIKE WM2_I_ITEM     OCCURS 0 WITH HEADER LINE.            "收集未使用到庫存資料
********************************出貨檢核表*********************************
DATA: I_LIKP            LIKE LIKP         OCCURS 0 WITH HEADER LINE,
      I_LIPS            LIKE LIPS         OCCURS 0 WITH HEADER LINE,
      I_VBRK            LIKE VBRK         OCCURS 0 WITH HEADER LINE,
      I_VBRP            LIKE VBRP         OCCURS 0 WITH HEADER LINE,
      I_ZPDH            LIKE ZPDH         OCCURS 0 WITH HEADER LINE,
      I_ZPDI            LIKE ZPDI         OCCURS 0 WITH HEADER LINE,
      I_VBFA            LIKE VBFA         OCCURS 0 WITH HEADER LINE,
      I_VEKP            LIKE VEKP         OCCURS 0 WITH HEADER LINE,
      I_ZCLOT           LIKE ZCUST_LOTID  OCCURS 0 WITH HEADER LINE,      "收集客戶的LOT ID
      S_HEAD            LIKE I_HEAD       OCCURS 0 WITH HEADER LINE,      "記錄選擇的狀況
      B_HEAD            LIKE I_HEAD       OCCURS 0 WITH HEADER LINE,      "備份S_HEAD
      O_HEAD            LIKE I_HEAD       OCCURS 0 WITH HEADER LINE,      "記錄原始狀況用
**FOR PDF
      I_OTFS            TYPE TSFOTF,
**FOR MAIL & PDF file to AIX using
      TA_CONTENTS_BIN   LIKE SOLISTI1   OCCURS 0 WITH HEADER LINE,      "PDF的BIN資料
      TA_PACKING_LIST   LIKE SOPCKLSTI1 OCCURS 0 WITH HEADER LINE,      "定義PDF做為附件的資訊
      TA_CONTENTS_TXT   LIKE SOLISTI1   OCCURS 0 WITH HEADER LINE.      "MAIL內容




*- range
RANGES: R_KTC FOR LIKP-KUNAG.                                           "sold to no for KTC group

DATA: OK_CODE(06)   TYPE C,
      V_ZSTOP(01)   TYPE C.                                             "判斷是否繼續往下走

***加密文件使用                                                         "I190708
DATA: OT_FILENAME LIKE ZSD_ENC_FILE OCCURS 0 WITH HEADER LINE."I190708
DATA: BEGIN OF ITMPSP OCCURS 0,                             "I190708
        SOLDTO LIKE ZSD_ENC_FILE-SOLDTO,                    "I190708
      END OF ITMPSP.                                        "I190708
DATA: V_ANS(1) TYPE C.                                      "I190708
DATA: P_ENCSTOP(1) TYPE C.                                  "I190708

***以下變數供SCREEN使用
DATA: X_VARTS       TYPE C.                                             "無使用...接值用
CONSTANTS: C_TAB  TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB,
           C_NEWL TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>NEWLINE.
***ALV使用
DATA: I_FIELDCAT_LVC  TYPE LVC_T_FCAT,
      WA_LAYOUT_LVC   TYPE LVC_S_LAYO.
CONTROLS: TC300_BILL  TYPE TABLEVIEW USING SCREEN 300,
          TC300_HEAD  TYPE TABLEVIEW USING SCREEN 300,
          TC300_MAIL  TYPE TABLEVIEW USING SCREEN 300.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT (33) TEXT-H02 FOR FIELD P_VKORG MODIF ID GP1.      "TEXT-H02 = 'Sales Org.'
PARAMETERS  P_VKORG TYPE VKORG MODIF ID GP1.
SELECTION-SCREEN POSITION 45.
SELECTION-SCREEN COMMENT (20) V_VTEXT MODIF ID GP1.
SELECTION-SCREEN END OF LINE.
*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT (30) TEXT-H02 FOR FIELD P_VKORG MODIF ID GP2.      "TEXT-H02 = 'Sales Org.'
*SELECT-OPTIONS S_VKORG FOR LIKP-VKORG MODIF ID GP2.
*SELECTION-SCREEN END OF LINE.


SELECT-OPTIONS: S_VBELN FOR LIKP-VBELN,
                S_ERDAT FOR SY-DATUM,
                S_KUNAG FOR LIKP-KUNAG,                                                           "SOLD-TO
                S_KUNNR FOR LIKP-KUNNR.                                                           "ship-to

PARAMETERS: "P_ABTNR1      LIKE KNVK-ABTNR    OBLIGATORY DEFAULT  '0002',
            "P_ABTNR2      LIKE KNVK-ABTNR    OBLIGATORY DEFAULT  '0002',
            "P_ABTNR3      LIKE KNVK-ABTNR    OBLIGATORY DEFAULT  '0002',
            P_REMARK      LIKE DD07T-DDTEXT,
            P_BONDTP      TYPE N,
            P_OCPROG      LIKE SY-CPROG NO-DISPLAY,       "CALL進來的程式
            P_ZSFEND(03)  TYPE C        NO-DISPLAY,       "出庫單+PACKING/IMEX是否列印印章用
            P_STMP2       TYPE C        NO-DISPLAY,       "IMEX是否要印公司大小章
            P_TWDVL       TYPE C        NO-DISPLAY,       "顯示台幣(IMEX專用)
            P_CUSTM       TYPE C        NO-DISPLAY,       "用來決定是否顯示報關文件
            P_JOBTPS      TYPE C        NO-DISPLAY.
"做為外部程式CALL使用,N=IMEX CALL, P=PRINT, M=MAIL, F=FTP, B=出庫單
"E=關務ZBD40231 Call , '2' =Call from B2B ,'3' =Call from B2B(Ilitek), U=Call from PDF Backup, Q= QOM,
"'T'= send OTF out, I=財務ZSD0288 Call



SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: C_PE AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (51) TEXT-C14.       "TEXT-C14 = '是否顯示Invoice金額?'
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: C_SIGFG AS CHECKBOX.
SELECTION-SCREEN COMMENT (51) TEXT-C16.       "TEXT-C16 = '是否印簽名欄位(Exclude Packing)'
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: C_L2T AS CHECKBOX.
SELECTION-SCREEN COMMENT (70) TEXT-C51.       "TEXT-C51 = Setting L2 Title Space: Service charge, Select: Pricing adjustment.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF BLOCK B2 WITH FRAME TITLE TEXT-T02.       "TEXT-T02 = '請選擇單據類型'
SELECTION-SCREEN BEGIN OF LINE.

PARAMETERS P_PACKS AS CHECKBOX DEFAULT 'X' USER-COMMAND PK.
SELECTION-SCREEN COMMENT (16) TEXT-C09.     "TEXT-C09 = 'Packing'

PARAMETERS P_FINVO AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (16) TEXT-C11.     "TEXT-C11 = 'Free Invoice'

PARAMETERS P_INVOS AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (16) TEXT-C10.     "TEXT-C10 = 'Invoice'

PARAMETERS P_PINVO AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (16) TEXT-C13.     "TEXT-C13 = 'Performa Invoice'

SELECTION-SCREEN END   OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS P_CREMO AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (16) TEXT-C12.     "TEXT-C12 = 'Credit Memo'

PARAMETERS P_DEBMO AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT (16) TEXT-C15.     "TEXT-C15 = 'Debit Memo'

SELECTION-SCREEN END   OF LINE.
SELECTION-SCREEN END OF BLOCK B2.

SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON (20) W_BUTTON USER-COMMAND BUT.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON (20) W_FIBTN USER-COMMAND FINV.
SELECTION-SCREEN END OF LINE.

INITIALIZATION.
*增加字到BUTTON中
  W_BUTTON = 'WAFER-DIE 資訊維護'.
  W_FIBTN =  'Free Inv 保稅別維護'.
  PERFORM GET_DEFALUT_VALUE.

AT SELECTION-SCREEN.
  PERFORM CHECK_INPUT_DATA.
  PERFORM BUTTON_FUNCTION.
  CHECK P_REMARK IS NOT INITIAL.
  MESSAGE I000 WITH 'Each Invoice will be printed: **' P_REMARK.


AT SELECTION-SCREEN OUTPUT.
  PERFORM GET_SALES_ORG_DESC USING    P_VKORG
                             CHANGING V_VTEXT.
  PERFORM SCREEN_MODIFY USING 'FIST'.
  PERFORM AUTH_CHECK USING 'SOUTPUT'.



START-OF-SELECTION.
  PERFORM AUTH_CHECK USING 'EXEC'.
  INCLUDE ZBC0001I.
  PERFORM GET_DATA_BY_CRITERIA CHANGING V_ZSTOP.
  CHECK V_ZSTOP IS INITIAL.
  PERFORM GET_HEAD_DATA.
  PERFORM GET_HEAD_DATA_SHIP        TABLES I_HEAD.
  PERFORM GET_ITEM_DATA             TABLES I_HEAD.
  PERFORM GET_ITEM_REMARK           TABLES I_HEAD.
  PERFORM GET_ITEM_TOTAL            TABLES I_HEAD.
  PERFORM GET_ITEM_PROFORMA         TABLES I_HEAD.

  PERFORM NO_SHOW_PRICE             TABLES I_ITEM.
  PERFORM KEEP_SELECT_DATA          TABLES I_HEAD.
  PERFORM EXEC_FUNCTION.                                                                          "針對外部程式CALL使用
*P_JOBTPS IN ('B', '2', '3', '4', 'U', 'T', '8', '9' ) 不會往下做  "U190708
  PERFORM SAVE_PDF_FILE_TO_SERVER   USING  ''.
  PERFORM WRITE_INFO                TABLES I_HEAD.

END-OF-SELECTION.
  PERFORM SCREEN_MODIFY USING 'G001'.
  SET PF-STATUS 'G001' EXCLUDING FC_TAB.



TOP-OF-PAGE.
  PERFORM WRITE_HEADER_LINE.

AT USER-COMMAND.
  CASE SY-UCOMM.
    WHEN 'SAL'.
      PERFORM SELECTED_TO_PRINT USING 'SALL'.
    WHEN 'DAL'.
      PERFORM SELECTED_TO_PRINT USING 'DALL'.
    WHEN 'PRT'.             "PRINT PERVIEW
      PERFORM SELECTED_TO_PRINT USING 'VIEW'.
      PERFORM CHECK_SELECT_DATA TABLES S_HEAD.
*      PERFORM UPDATE_INFO_TO_TABLE USING 'GEN'.        "D131205

      PERFORM PREPARE_DATA USING 'PRIN'.          "把資料還原進行列印
      PERFORM IMEX_SEND_TO_SMARTFORM USING 'PAG'
                                           ''.
      PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                      ''.
    WHEN 'APF' OR 'PDF'.    "產生PDF
      PERFORM SELECTED_TO_PRINT USING 'VIEW'.
      PERFORM CHECK_SELECT_DATA TABLES S_HEAD.

      PERFORM IMEX_SEND_TO_SMARTFORM USING 'PAG'
                                           SY-UCOMM.
      PERFORM PDF_CREATE_FOR_PERVIEW USING SY-UCOMM.
    WHEN 'EML'.
      PERFORM SELECTED_TO_PRINT USING 'VIEW'.
      PERFORM CHECK_SELECT_DATA TABLES S_HEAD.
      PERFORM GET_TC300_DATA USING ''.
      PERFORM CLEAR_ITABLES.
      CALL SCREEN 300 STARTING AT 05 01 ENDING AT 122 24.
    WHEN 'FTP'.             "手動FTP
      PERFORM SELECTED_TO_PRINT USING 'VIEW'.
      PERFORM CHECK_SELECT_DATA TABLES S_HEAD.
      PERFORM SEND_DOC_TO_OUTSIDE USING 'FTP'
                                        'MANU'
                                        P_JOBTPS.
    WHEN 'DWPK'.            "Download Packing excel
      PERFORM SELECTED_TO_PRINT USING 'VIEW'.
      PERFORM DESELECT_DATA_EXCEL TABLES S_HEAD.
      PERFORM CHECK_SELECT_DATA TABLES S_HEAD.
      PERFORM CHECK_ZBCOD TABLES S_HEAD.                    "I190507
      PERFORM DOWNLOAD_PACKING_DATA TABLES S_HEAD.

    WHEN OTHERS.
  ENDCASE.


*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_INPUT_DATA .
*使用者一定要下範圍

  IF SSCRFIELDS-UCOMM = 'ONLI'.
    IF S_VBELN[] IS INITIAL AND S_ERDAT[] IS INITIAL.
      CLEAR SSCRFIELDS.
      MESSAGE S000 WITH '為防止系統的效能不佳,請輸入範圍!!!!'.
    ENDIF.
  ENDIF.

*檢查BOND欄位不是1或2或空白
  CHECK P_BONDTP <> '1' AND P_BONDTP <> '2' AND P_BONDTP <> ''.
  MESSAGE E000 WITH 'Please input 1 or 2 or space for assigning bond data.'.
ENDFORM.                    " CHECK_INPUT_DATA

*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE EXIT INPUT.
  CASE OK_CODE.
    WHEN 'BACK'.
*      CLEAR: V_RECRD.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " EXIT  INPUT

*&---------------------------------------------------------------------*
*&      Form  GET_DATA_BY_CRITERIA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_DATA_BY_CRITERIA CHANGING PFV_ZSTOP.

  CLEAR: PFV_ZSTOP.
**GET HEADER
  PERFORM GET_HEAD_DATA_LIKP TABLES I_LIKP.
  PERFORM GET_HEAD_DATA_VBRK TABLES I_VBRK.
  PERFORM GET_HEAD_DATA_ZPDH TABLES I_VBRK
                                    I_ZPDH.                 "I210217
**檢查Billing狀態
  PERFORM CHECK_BILL_DATA_STATUS TABLES I_VBRK
                                        I_ZPDH.             "M210217

  PERFORM GET_HEAD_DATA_LIKP_FROM_VBRK TABLES I_VBRK
                                              I_LIKP.
**檢查Delivery狀態
  PERFORM CHECK_LIKP_DATA_STATUS TABLES I_LIKP.

  IF I_LIKP[] IS INITIAL AND
     I_VBRK[] IS INITIAL AND
     I_ZPDH[] IS INITIAL.                                   "I210217
    MESSAGE I000 WITH '輸入的條件找不到相對應的資料,請重新輸入!!'.
    PFV_ZSTOP = 'X'.
    EXIT.
  ENDIF.

**GET ITEM
  PERFORM GET_ITEM_DATA_VBRP TABLES I_VBRK
                                    I_VBRP
                             USING  ''.
  PERFORM GET_ITEM_DATA_ZPDI TABLES I_ZPDH
                                    I_ZPDI.                 "I210217

  PERFORM GET_ITEM_DATA_LIPS TABLES I_LIKP
                                    I_LIPS.

**先把所有的FLOW DATA先抓出來(效能)
  PERFORM GET_FLOW_DATA_VBFA TABLES I_VBRK
                                    I_LIKP
                                    I_VBFA.
**先取得CARTON及PALLET的資料(效能)
  PERFORM GET_HUNIT_DATA TABLES I_VBFA
                                I_VEKP.

ENDFORM.                    " GET_DATA_BY_CRITERIA
*&---------------------------------------------------------------------*
*&      Form  CHECK_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_SELECT_DATA TABLES PF_HEAD_I STRUCTURE I_HEAD.
  CHECK PF_HEAD_I[] IS INITIAL.
  MESSAGE I000 WITH '沒有選擇所要執行的單據,請重新選擇!!'.
  STOP.
ENDFORM.                    " CHECK_DATA
*&---------------------------------------------------------------------*
*&      Form  CHECK_ZBCOD  I190507
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_ZBCOD TABLES PF_HEAD_I STRUCTURE I_HEAD.
  DATA: ZBCOD_FG(1) TYPE C.
  CLEAR ZBCOD_FG.
  LOOP AT PF_HEAD_I.
    SELECT SINGLE * FROM ZBCOD WHERE VBELN = PF_HEAD_I-VBELN.
    IF SY-SUBRC <> 0.
      ZBCOD_FG = 'Y'.
      EXIT.
    ENDIF.
  ENDLOOP.
  CHECK ZBCOD_FG = 'Y'.
  MESSAGE I000 WITH PF_HEAD_I-VBELN '沒有packing data,' '請庫房先列印packing!'.
  STOP.
ENDFORM.                    " CHECK_ZBCOD
*&---------------------------------------------------------------------*
*&      Form  GET_HEADER_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA .
  DATA: PF_HEAD LIKE I_HEAD OCCURS 0 WITH HEADER LINE.
  CLEAR: S_HEAD, S_HEAD[].      "防止程式未完全跳出,記錄這個BACKUP
  PERFORM GET_HEAD_DATA_INVCRD  TABLES I_VBRK
                                       PF_HEAD.
  APPEND LINES OF PF_HEAD TO I_HEAD.
*<-I210217
  PERFORM GET_HEAD_DATA_NEWPI TABLES I_ZPDH
                                     PF_HEAD.
  APPEND LINES OF PF_HEAD TO I_HEAD.
*->I210217
  PERFORM GET_HEAD_DATA_FREE    TABLES I_LIKP
                                       PF_HEAD.
  APPEND LINES OF PF_HEAD TO I_HEAD.
  PERFORM GET_HEAD_DATA_PACKING TABLES I_LIKP
                                       PF_HEAD.
  APPEND LINES OF PF_HEAD TO I_HEAD.

  CHECK I_HEAD[] IS NOT INITIAL.
  LOOP AT I_HEAD.
    PERFORM SP_RULE_FOR_HEAD_P     TABLES   I_LIKP
                                   CHANGING I_HEAD.
    IF I_HEAD-VBELN IS INITIAL.
      I_HEAD-VBELN = I_HEAD-VGBEL.              "表示為P或F
    ENDIF.
    PERFORM GET_BILLING_NO  TABLES   I_VBFA
                            CHANGING I_HEAD.

    CONCATENATE I_HEAD-ZTYPE I_HEAD-VBELN
      INTO I_HEAD-ZCOMP.                        "判斷換頁用(ZTYPE+VBELN)
    I_HEAD-JBTPS = P_JOBTPS.
**GET Prod Type(PRODTYPE)
    PERFORM GET_DOC_PRODUCT_TYPE CHANGING I_HEAD.

    PERFORM IMEX_GET_LOCL_CURR_SHOWFLAG USING     I_HEAD-ZTYPE
                                        CHANGING  I_HEAD-SHTWD."I171018 D190718 I200831

    MODIFY I_HEAD.
  ENDLOOP.
  PERFORM ORDER_BY_HEADER TABLES I_HEAD.
**INCOTERM中含中文...就要加空格,否則產生PDF會有疊在一起
  PERFORM REPLACE_CHINESE_INCOTERM TABLES I_HEAD.
ENDFORM.                    " GET_HEADER_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_HEADER_DATA_PACKING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_PACKING TABLES PF_LIKP_I STRUCTURE LIKP
                                  PF_HEAD_O STRUCTURE I_HEAD.
  DATA: PFV_INCO1 TYPE INCO1,
        PFV_INCO2 TYPE INCO2.

  CLEAR: PF_HEAD_O, PF_HEAD_O[].
  CHECK PF_LIKP_I[] IS NOT INITIAL.
**FREE的有PACKING  !!
  LOOP AT PF_LIKP_I.
    PF_HEAD_O-ZTYPE = 'P'.                                "P = PACKING
    PF_HEAD_O-VKORG = PF_LIKP_I-VKORG.                    "Sales Org
    PF_HEAD_O-VGBEL = PF_LIKP_I-VBELN.                    "DN NO. / FREE INVOICE NO.
**(X)Division / Channel(SPART/VTWEG)
    PERFORM GET_DIVISION USING    PF_LIKP_I-VBELN
                         CHANGING PF_HEAD_O.
**(X)BILL-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'BILL'
                       CHANGING PF_HEAD_O-BKUNN.
**(X)SOLD-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'SOLD'
                       CHANGING PF_HEAD_O-KUNAG.
**(X)SHIP-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'SHIP'
                       CHANGING PF_HEAD_O-KUNNR.
**取得USCI Code(USCIC)
    PERFORM GET_USCI_CODE CHANGING PF_HEAD_O.
**REMARK
    PERFORM GET_HEAD_REMARK CHANGING PF_HEAD_O.
**GET SO NO.(AUBEL / ZMTSO) ZMTSO判斷是否為多筆SO(''=一對一,'X'=一對多)
    PERFORM GET_SO_INFO USING     PF_LIKP_I-VBELN
                        CHANGING  PF_HEAD_O.
**GET TO BE SHIP DATE
    PERFORM GET_TOBE_SHIPDATE TABLES    I_VBFA
                              USING     PF_LIKP_I
                              CHANGING  PF_HEAD_O-ERDAT.  "To Be Shipped Date

*-  Get aucal incor-term
    PERFORM GET_ACTURE_INCOTERM_LIKP USING    PF_LIKP_I
                                     CHANGING PFV_INCO1
                                              PFV_INCO2.
*GET LC / TERMS / SHIP VIA
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL
                                              'LCNO'
                                    CHANGING  PF_HEAD_O-LCNUM.      "LC NO.

    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              PFV_INCO1
                                              PFV_INCO2
                                              PF_HEAD_O-AUBEL
                                              'TERM'
                                    CHANGING  PF_HEAD_O-INCO2.      "DELIVERY TERMS / TRADE TERMS

*<-D140116
*    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN      "DN NO.
*                                              PF_LIKP_I-INCO1
*                                              PF_LIKP_I-INCO2
*                                              PF_HEAD_O-AUBEL
*                                              'SVIA'
*                                    CHANGING  PF_HEAD_O-SHVIA.     "SHIP VIA
*
*    PERFORM GET_SHIPVIA USING    PF_LIKP_I-VBELN
*                                 PF_LIKP_I-KUNNR
*                        CHANGING PF_HEAD_O-SHVIA.                                 "SHIP VIA
*->D140116
*取得放行單號及日期
    PERFORM GET_RELNO_DATE  USING     PF_HEAD_O-VGBEL
                                      'SHIP'
                            CHANGING  PF_HEAD_O-RELNO
                                      PF_HEAD_O-CDATE.

**(X)判斷是否已經有傳送過的記錄(PROFORMA不需要)(ZFSET / ZMSET) ZFSET = FTP, ZMSET = MAIL
    PERFORM GET_SENT_INFO USING     PF_LIKP_I-VBELN
                                    PF_LIKP_I-KUNAG
                          CHANGING  PF_HEAD_O.
    APPEND  PF_HEAD_O.
    CLEAR   PF_HEAD_O.
  ENDLOOP.
ENDFORM.                    " GET_HEADER_DATA_PACKING
*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_DATA_FREEINV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_FREE TABLES PF_LIKP_I STRUCTURE LIKP
                               PF_HEAD_O STRUCTURE I_HEAD.
  DATA: PFV_INCO1 TYPE INCO1,
        PFV_INCO2 TYPE INCO2.

  CLEAR: PF_HEAD_O, PF_HEAD_O[].
  CHECK PF_LIKP_I[] IS NOT INITIAL.
  LOOP AT PF_LIKP_I WHERE LFART = 'ZF'.                   "ZF = FREE INVOICE
    PF_HEAD_O-ZTYPE = 'F'.                                "F = Free Invoice
    PF_HEAD_O-VKORG = PF_LIKP_I-VKORG.                    "Sales Org
    PF_HEAD_O-VGBEL = PF_LIKP_I-VBELN.                    "DN NO. / FREE INVOICE NO.
    PF_HEAD_O-KUNAG = PF_LIKP_I-KUNAG.                    "(X)SOLD-TO
    PF_HEAD_O-KUNNR = PF_LIKP_I-KUNNR.                    "(X)SHIP-TO

**INVOICE DATE
    PF_HEAD_O-SIDAT = PF_LIKP_I-WADAT_IST.
**取得USCI Code(USCIC)
    PERFORM GET_USCI_CODE CHANGING PF_HEAD_O.
**(X)Division / Channel(SPART/VTWEG)
    PERFORM GET_DIVISION USING    PF_LIKP_I-VBELN
                         CHANGING PF_HEAD_O.
**REMARK
    PERFORM GET_HEAD_REMARK CHANGING PF_HEAD_O.
**GET TO BE SHIP DATE
    PERFORM GET_TOBE_SHIPDATE TABLES    I_VBFA
                              USING     PF_LIKP_I
                              CHANGING  PF_HEAD_O-ERDAT.  "To Be Shipped Date
**GET SO NO.(AUBEL / ZMTSO) ZMTSO判斷是否為多筆SO(''=一對一,'X'=一對多)
    PERFORM GET_SO_INFO USING     PF_LIKP_I-VBELN
                        CHANGING  PF_HEAD_O.

*-  Get aucal incor-term
    PERFORM GET_ACTURE_INCOTERM_LIKP USING    PF_LIKP_I
                                     CHANGING PFV_INCO1
                                              PFV_INCO2.

**DELIVERY TERMS / TRADE TERMS
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              PFV_INCO1
                                              PFV_INCO2
                                              PF_HEAD_O-AUBEL
                                              'TERM'
                                    CHANGING  PF_HEAD_O-INCO2.      "DELIVERY TERMS / TRADE TERMS

**DESTINATION
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL
                                              'DEST'
                                    CHANGING  PF_HEAD_O-DESTI.      "DESTINATION
**LC NO.
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL
                                              'LCNO'
                                    CHANGING  PF_HEAD_O-LCNUM.      "LC NO.
**FREIGHT TERMS
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL
                                              'FTER'
                                    CHANGING  PF_HEAD_O-FRTER.      "LC NO.
*<-D140116
***SHIP VIA
*    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_LIKP_I-VBELN      "DN NO.
*                                              PF_LIKP_I-INCO1
*                                              PF_LIKP_I-INCO2
*                                              PF_HEAD_O-AUBEL
*                                              'SVIA'
*                                    CHANGING  PF_HEAD_O-SHVIA.     "SHIP VIA
*->D140116
**(X)BILL-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'BILL'
                       CHANGING PF_HEAD_O-BKUNN.
**(X)SOLD-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'SOLD'
                       CHANGING PF_HEAD_O-KUNAG.
**(X)SHIP-TO
    PERFORM GET_CUST_NO USING   PF_LIKP_I-VBELN
                                PF_LIKP_I-KUNAG
                                PF_LIKP_I-KUNNR
                                PF_HEAD_O-ZTYPE
                                'SHIP'
                       CHANGING PF_HEAD_O-KUNNR.
*取得放行單號及日期
    PERFORM GET_RELNO_DATE  USING     PF_HEAD_O-VGBEL
                                      'SHIP'
                            CHANGING  PF_HEAD_O-RELNO
                                      PF_HEAD_O-CDATE.
**(X)判斷是否已經有傳送過的記錄(PROFORMA不需要)(ZFSET / ZMSET) ZFSET = FTP, ZMSET = MAIL
    PERFORM GET_SENT_INFO USING     PF_LIKP_I-VBELN
                                    PF_LIKP_I-KUNAG
                          CHANGING  PF_HEAD_O.
    APPEND  PF_HEAD_O.
    CLEAR   PF_HEAD_O.
  ENDLOOP.
ENDFORM.                    " GET_HEAD_DATA_FREEINV
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_HEADER01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_HEAD_P  TABLES   PF_LIKP_I      STRUCTURE LIKP
                         CHANGING PFWA_HEAD_IO  STRUCTURE I_HEAD.
  DATA: PFV_ANSWE   TYPE C,
        PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.
  CLEAR: PFV_ANSWE.
  CHECK PFWA_HEAD_IO-ZTYPE = 'P'.     "P = Packing
  CASE PFWA_HEAD_IO-KUNAG.
    WHEN '0000001840' OR              "HIMAX
         '0000001921'.
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  PFWA_HEAD_IO-VBELN
                                   'T01'
                                   'VBBK'.
      READ TABLE PF_LINES INDEX 1.
      IF PF_LINES-TDLINE+0(8) <> '00000000' AND PF_LINES-TDLINE+0(8) <> ''.
        MOVE PF_LINES-TDLINE+0(8) TO PFWA_HEAD_IO-ERDAT.
      ENDIF.
      CHECK PFWA_HEAD_IO-ERDAT = '' OR  PFWA_HEAD_IO-ERDAT = '00000000'.                         "不能用IS INITAL,因為LONG TEXT帶出的就是空的
      READ TABLE PF_LIKP_I WITH KEY VBELN = PFWA_HEAD_IO-VGBEL.
      PFWA_HEAD_IO-ERDAT = PF_LIKP_I-WADAT_IST.
    WHEN  '0000001949'.               "Ilitek
      READ TABLE PF_LIKP_I WITH KEY VBELN = PFWA_HEAD_IO-VGBEL.
      PFWA_HEAD_IO-ERDAT = PF_LIKP_I-WADAT_IST.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " SPECIAL_RULE_FOR_HEADER01
*&---------------------------------------------------------------------*
*&      Form  ASK_QUESTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PF_VBELN  text
*      -->PF_ZTYPE  text
*      <--PF_ANSWE  text
*----------------------------------------------------------------------*
FORM ASK_QUESTION  USING    PFV_VBELN
                            PFV_ZTYPE
                            PFV_METHD
                   CHANGING PFV_ANSWE.
  DATA: PFV_QUEST     TYPE STRING,
        PFV_BUN01(04) TYPE C,
        PFV_BUN02(04) TYPE C.

  CLEAR: PFV_QUEST, PFV_BUN01, PFV_BUN02, PFV_ANSWE.

  CASE PFV_METHD.
    WHEN 'GEN'.
      IF PFV_ZTYPE = 'P'.                                                                          "P = Packing
        CONCATENATE TEXT-Q01 '(' TEXT-T22 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'I'.                                                                          "I = Invoice
        CONCATENATE TEXT-Q01 '(' TEXT-HD4 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'C'.                                                                          "C = Credit Memo
        CONCATENATE TEXT-Q01 '(' TEXT-C12 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'D'.                                                                          "D = Dedit Memo        "I190708
        CONCATENATE TEXT-Q01 '(' TEXT-C15 ':' PFV_VBELN ')' INTO PFV_QUEST."I190708
      ENDIF.                                                "I190708
      IF PFV_ZTYPE = 'R'.                                                                          "R = Performa Invoice  "I190708
        CONCATENATE TEXT-Q01 '(' TEXT-C13 ':' PFV_VBELN ')' INTO PFV_QUEST."I190708
      ENDIF.                                                "I190708
      PFV_BUN01 = '保留'.
      PFV_BUN02 = '置換'.
*<-D141226
*    WHEN 'FTP'.
*      CASE PF_ZTYPE.
*        WHEN 'P'.
*          CONCATENATE TEXT-Q02 '(DELIVERY:' PF_VBELN ')' INTO V_QUEST.
*        WHEN 'I'.
*          CONCATENATE TEXT-Q02 '(BILLING:' PF_VBELN ')' INTO V_QUEST.
*        WHEN 'C'.
*          CONCATENATE TEXT-Q02 '(CREDIT MEMO:' PF_VBELN ')' INTO V_QUEST.
*        WHEN 'F'.
*          CONCATENATE TEXT-Q02 '(FREE INVOICE:' PF_VBELN ')' INTO V_QUEST.
*        WHEN OTHERS.
*      ENDCASE.
*      P_BUN01 = '取消'.
*      P_BUN02 = '傳送'.
*->D141226
    WHEN 'MAIL'.
      IF PFV_ZTYPE = 'P'.                                                                          "P = Packing
        CONCATENATE TEXT-Q03 '(' TEXT-T22 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'I'.                                                                          "I = Invoice
        CONCATENATE TEXT-Q03 '(' TEXT-HD4 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'C'.                                                                          "C = Credit Memo
        CONCATENATE TEXT-Q03 '(' TEXT-C12 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'F'.                                                                          "F = Free Invoice
        CONCATENATE TEXT-Q03 '(' TEXT-C11 ':' PFV_VBELN ')' INTO PFV_QUEST.
      ENDIF.
      IF PFV_ZTYPE = 'D'.                                                                          "D = Dedit Memo        "I190708
        CONCATENATE TEXT-Q03 '(' TEXT-C15 ':' PFV_VBELN ')' INTO PFV_QUEST."I190708
      ENDIF.                                                "I190708
      IF PFV_ZTYPE = 'R'.                                                                          "R = Performa Invoice  "I190708
        CONCATENATE TEXT-Q03 '(' TEXT-C13 ':' PFV_VBELN ')' INTO PFV_QUEST."I190708
      ENDIF.                                                "I190708
      PFV_BUN01 = '取消'.
      PFV_BUN02 = '傳送'.
    WHEN 'DELE'.
      PFV_QUEST = PFV_VBELN.
      PFV_BUN01 = '是'.
      PFV_BUN02 = '否'.
    WHEN OTHERS.
  ENDCASE.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR                    = TEXT-T03                                                      "TEXT-T03 = '詢問目前的狀況處置方式'
*     DIAGNOSE_OBJECT             = ' '
      TEXT_QUESTION               = PFV_QUEST
      TEXT_BUTTON_1               = PFV_BUN01
*     ICON_BUTTON_1               = ' '
      TEXT_BUTTON_2               = PFV_BUN02
*     ICON_BUTTON_2               = ' '
      DEFAULT_BUTTON              = '1'
      DISPLAY_CANCEL_BUTTON       = ' '
*     USERDEFINED_F1_HELP         = ' '
*     START_COLUMN                = 25
*     START_ROW                   = 6
*     POPUP_TYPE                  =
*     IV_QUICKINFO_BUTTON_1       = ' '
*     IV_QUICKINFO_BUTTON_2       = ' '
    IMPORTING
      ANSWER                      = PFV_ANSWE
*   TABLES
*     PARAMETER                   =
*   EXCEPTIONS
*     TEXT_NOT_FOUND              = 1
*     OTHERS                      = 2
            .


ENDFORM.                    " ASK_QUESTION

*&---------------------------------------------------------------------*
*&      Form  GET_SO_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PF_VBELN  text
*      -->PF_ZTYPE  text
*      <--PF_AUBEL  text
*      <--PF_ZMTSO  text
*----------------------------------------------------------------------*
FORM GET_SO_INFO  USING    PFV_VBELN_I
                  CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.

*  DATA: BEGIN OF PF_DN OCCURS 0,
*          VBELN   TYPE VBELN_VL,
*          POSNR   TYPE POSNR_VL,                                                                "保留
*          VGBEL   TYPE VBELN_VA,
*          VGPOS   TYPE POSNR_VA,                                                                "保留
*          WERKS   TYPE WERKS,
*        END OF PF_DN.
  DATA: PFV_AUBEL TYPE VBELN_VA,
        PFV_LINES TYPE I,
        PF_VBRP   LIKE VBRP OCCURS 0 WITH HEADER LINE,
        PF_LIPS   LIKE LIPS OCCURS 0 WITH HEADER LINE.


  CLEAR: PFWA_HEAD_IO-AUBEL, PFWA_HEAD_IO-ZMTSO, PFV_AUBEL, PFV_LINES.

*<-I210217
  CASE PFWA_HEAD_IO-ZTYPE.
    WHEN 'P' OR                       "P = Packing
         'F'.                         "F = Free Invoice
      PERFORM GET_DATA_LIPS TABLES  PF_LIPS
                            USING   PFV_VBELN_I.            "I210217
      SORT PF_LIPS BY VGBEL.
      DELETE ADJACENT DUPLICATES FROM PF_LIPS COMPARING VGBEL.
      DESCRIBE TABLE PF_LIPS LINES PFV_LINES.
      READ TABLE PF_LIPS INDEX 1.
      PFV_AUBEL = PF_LIPS-VGBEL.
    WHEN 'I' OR                       "I = Invoice
         'C' OR                       "C = Credit Memo
         'D' OR                       "D = Debit  Memo
         'R'.                         "R = Proforma
      PERFORM GET_DATA_VBRP TABLES PF_VBRP
                            USING  PFV_VBELN_I.
      SORT PF_VBRP BY AUBEL.
      DELETE ADJACENT DUPLICATES FROM PF_VBRP COMPARING AUBEL.
      DESCRIBE TABLE PF_VBRP LINES PFV_LINES.
      READ TABLE PF_VBRP INDEX 1.
      PFV_AUBEL = PF_VBRP-AUBEL.
    WHEN OTHERS.
  ENDCASE.
**檢查資料筆數
  IF PFV_LINES = 1.
    PFWA_HEAD_IO-AUBEL = PFV_AUBEL.
  ELSE.
    PFWA_HEAD_IO-ZMTSO = 'X'.
  ENDIF.
*->I210217

*<-D210217
*  CASE PFWA_HEAD_IO-ZTYPE.
*    WHEN 'P' OR                       "P = Packing
*         'F'.                         "F = Free Invoice
*      SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_LIPS FROM  LIPS
*                                                          WHERE VBELN = PFV_VBELN
*                                                          AND   UECHA <> ''.
*      LOOP AT PF_LIPS.
*        PF_DN-VBELN = PF_LIPS-VBELN.
*        PF_DN-POSNR = PF_LIPS-POSNR.
*        PF_DN-VGBEL = PF_LIPS-VGBEL.
*        PF_DN-VGPOS = PF_LIPS-VGPOS.
*        APPEND PF_DN.
*        CLEAR  PF_DN.
*      ENDLOOP.
*    WHEN 'I' OR                       "I = Invoice
*         'C' OR                       "C = Credit Memo
*         'D' OR                       "D = Debit  Memo
*         'R'.                         "R = Proforma
*      SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBRP FROM   VBRP
*                                                          WHERE  VBELN = PFV_VBELN.
*      LOOP AT PF_VBRP.
*        PF_DN-VBELN = PF_VBRP-VGBEL.
*        PF_DN-POSNR = PF_VBRP-VGPOS.
*        PF_DN-VGBEL = PF_VBRP-AUBEL.
*        PF_DN-VGPOS = PF_VBRP-AUPOS.
*        APPEND PF_DN.
*        CLEAR  PF_DN.
*      ENDLOOP.
*    WHEN OTHERS.
*  ENDCASE.
*  SORT PF_DN BY VGBEL.
*
*  LOOP AT PF_DN.
*    IF PFV_VGBEL IS INITIAL.
*      PFV_VGBEL = PF_DN-VGBEL.
*    ELSEIF PFV_VGBEL <> PF_DN-VGBEL.
*      PFWA_HEAD_IO-ZMTSO = 'X'.
*      EXIT.
*    ENDIF.
*  ENDLOOP.
*  PFWA_HEAD_IO-AUBEL = PFV_VGBEL.
*->D210217
ENDFORM.                    " GET_SO_INFO
*<-D170126
**&---------------------------------------------------------------------*
**&      Form  GET_FLOW_INFO
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_I_VBFA  text
**      -->P_I_LIKP_VBELN  text
**      -->P_I_LIKP_VBTYP  text
**      -->P_1029   text
**----------------------------------------------------------------------*
*form GET_FLOW_INFO  tables   PF_VBFA_O STRUCTURE VBFA
*                    using    PFV_VBELN
*                             PFV_VBTYP
*                             PFV_VBTYP_N.
*  CLEAR: PF_VBFA_O[], PF_VBFA_O.
*
*  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM   VBFA
*                                                        WHERE  VBELV   = PFV_VBELN
*                                                        AND    VBTYP_N = PFV_VBTYP_N
*                                                        AND    VBTYP_V = PFV_VBTYP.
*endform.                    " GET_FLOW_INFO
*->D170126
*&---------------------------------------------------------------------*
*&      Form  GET_TOBE_SHIPDATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_I_LIKP_VBELN  text
*      -->P_I_LIKP_LFART  text
*      -->P_I_LIKP_KUNAG  text
*      -->P_I_LIKP_WADAT_IST  text
*      <--P_I_HEAD_ERDAT  text
*----------------------------------------------------------------------*
FORM GET_TOBE_SHIPDATE  TABLES    PF_VBFA_I   STRUCTURE VBFA
                        USING     PFWA_LIKP_I STRUCTURE LIKP
                        CHANGING  PFV_ERDAT_O.
  DATA: PFV_VBELN   TYPE VBELN_VF,
        PFWA_VBRK   LIKE VBRK,
        PFWA_ZSD111 LIKE ZSD111,
        PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.

  CLEAR:PFV_VBELN, PFV_ERDAT_O.
  CASE PFWA_LIKP_I-LFART.
    WHEN 'ZZ' OR                                "ZZ:PFV_VBELN_I=VBRK-VBELN
         'ZF'.                                  "ZF:PFV_VBELN_I=LIKP-VBELN
      PFV_VBELN = PFWA_LIKP_I-VBELN.
    WHEN OTHERS.
      READ TABLE PF_VBFA_I WITH KEY VBELV   = PFWA_LIKP_I-VBELN
                                    VBTYP_V = PFWA_LIKP_I-VBTYP     "DN TYPE
                                    VBTYP_N  = 'M'.                 "M = Invoice
      IF SY-SUBRC = 0.
        PERFORM GET_WORKAREA_VBRK USING     PF_VBFA_I-VBELN
                                  CHANGING  PFWA_VBRK.
        IF PFWA_VBRK IS NOT INITIAL AND
           PFWA_VBRK-FKSTO IS INITIAL.
          PFV_VBELN = PFWA_VBRK-VBELN.
        ENDIF.
      ENDIF.
  ENDCASE.

  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VBELN
                               'T01'
                               'VBBK'.
  READ TABLE PF_LINES INDEX 1.
  IF SY-SUBRC = 0.
    MOVE PF_LINES-TDLINE+00(08) TO PFV_ERDAT_O.
  ENDIF.

  CHECK PFV_ERDAT_O IS INITIAL.
  CASE PFWA_LIKP_I-LFART.
    WHEN 'ZF'.
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  PFWA_LIKP_I-VBELN
                                   'Z016'
                                   'VBBK'.
      READ TABLE PF_LINES INDEX 1.
      IF SY-SUBRC = 0.
        MOVE PF_LINES-TDLINE+00(08) TO PFV_ERDAT_O.
      ENDIF.
    WHEN 'ZZ'.
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  PFWA_LIKP_I-KUNAG                "PFV_KUNAG_I暫借用來做LIKP-VBELN
                                   'Z016'
                                   'VBBK'.
      READ TABLE PF_LINES INDEX 1.
      IF SY-SUBRC = 0.
        MOVE PF_LINES-TDLINE+00(08) TO PFV_ERDAT_O.
      ENDIF.
    WHEN OTHERS.
      PERFORM GET_WORKAREA_ZSD111 USING     PFWA_LIKP_I-KUNAG
                                  CHANGING  PFWA_ZSD111.
      IF PFWA_ZSD111 IS NOT INITIAL.
        PFV_ERDAT_O = PFWA_LIKP_I-WADAT_IST.
      ENDIF.
  ENDCASE.

  CHECK PFV_ERDAT_O IS INITIAL.
  PFV_ERDAT_O = SY-DATUM.

ENDFORM.                    " GET_SHIPDATE_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_LONG_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_LINES  text
*      -->P_I_ERDAT_VBELN  text
*      -->P_1492   text
*      -->P_1493   text
*----------------------------------------------------------------------*
FORM GET_LONG_TEXT  TABLES   PF_T_LINES
                    USING    PF_V_VBELN
                             PF_V_ID
                             PF_V_OBJ.

  DATA: PFV_VBELN   LIKE THEAD-TDNAME,
        T_INLINES LIKE TLINE OCCURS 0 WITH HEADER LINE.


  PFV_VBELN = PF_V_VBELN.

  CLEAR: PF_T_LINES, PF_T_LINES[].
  CALL FUNCTION 'READ_TEXT_INLINE'
    EXPORTING
      ID           = PF_V_ID
      INLINE_COUNT = 1
      LANGUAGE     = SY-LANGU
      NAME         = PFV_VBELN
      OBJECT       = PF_V_OBJ
*    IMPORTING
*      HEADER       = THEAD
    TABLES
      INLINES      = T_INLINES
      LINES        = PF_T_LINES
    EXCEPTIONS
      ID           = 1
      LANGUAGE     = 2
      NAME         = 3
      NOT_FOUND    = 4
      OBJECT       = 5
      SAVEMODE     = 6.

ENDFORM.                    " GET_LONG_TEXT

*<-D140116
**&---------------------------------------------------------------------*
**&      Form  GET_SHIPVIA
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_I_LIKP_VBELN  text
**      -->P_I_LIKP_KUNNR  text
**      <--P_I_HEAD_SHVIA  text
**----------------------------------------------------------------------*
*form GET_SHIPVIA  using    PF_VBELN
*                           PF_KUNNR
*                  changing PF_SHVIA.
*
*  CLEAR: KNA1.
*  SELECT SINGLE * FROM  KNA1
*                  WHERE KUNNR = PF_KUNNR.
*  IF SY-SUBRC = 0 AND KNA1-LAND1 <> 'TW'.
*    IF SY-UNAME = 'MAX1WM3'.
*        CONCATENATE PF_SHVIA '*' INTO PF_SHVIA.
*    ENDIF.
*    IF USR02-CLASS = 'MIS' OR USR02-CLASS = 'IM/EX'.
*      SELECT SINGLE * FROM  ZF32CA
*                      WHERE VBELN = PF_VBELN
*                      AND   F32_SERNO = '1'.
*      IF SY-SUBRC = 0 AND ( ZF32CA-SHIP_PLANT = 'PSC1' OR ZF32CA-SHIP_PLANT = 'MAX1' ).
*        CONCATENATE PF_SHVIA '*' INTO PF_SHVIA.
*      ENDIF.
*    ENDIF.
*  ENDIF.
*endform.                    " GET_SHIPVIA
*->D140116

*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_DATA_SHIP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_SHIP TABLES PF_HEAD_I STRUCTURE I_HEAD.
  DATA: PFWA_LIKP LIKE LIKP,
        PFWA_VBRK LIKE VBRK,
        PFV_PARNR LIKE VBRK-ZSPARNR_B,
        PFV_VBELN TYPE VBELN_VF,
        PF_VBFA   LIKE VBFA OCCURS 0 WITH HEADER LINE.

  LOOP AT PF_HEAD_I.
**先取得Billing No.
    IF PF_HEAD_I-ZTYPE = 'P' OR                 "P = Packing
       PF_HEAD_I-ZTYPE = 'F'.                   "F = Free Invoice
      PERFORM GET_WORKAREA_LIKP USING     PF_HEAD_I-VGBEL
                                CHANGING  PFWA_LIKP.
      PERFORM GET_USEFUL_FLOW_DATA TABLES I_VBFA
                                          PF_VBFA
                                   USING  PF_HEAD_I-VGBEL
                                          PFWA_LIKP-VBTYP
                                          'M'.
      SORT PF_VBFA BY VBELN DESCENDING.
      READ TABLE PF_VBFA INDEX 1.
      PFV_VBELN = PF_VBFA-VBELN.
    ELSE.
      PFV_VBELN = PF_HEAD_I-VBELN.
    ENDIF.

    PERFORM GET_WORKAREA_VBRK USING     PFV_VBELN
                              CHANGING  PFWA_VBRK.
*    CHECK PFWA_VBRK IS NOT INITIAL.
*    CHECK PFWA_VBRK-FKSTO IS INITIAL.
**BILL-TO INFO
    PERFORM GET_CUST_SHIP_DATA  USING     PF_HEAD_I-BKUNN
                                          PF_HEAD_I-VKORG
                                          PFWA_VBRK-ZIPARNR_B
                                          PFWA_VBRK-SPART
                                          'BILL'
                                CHANGING  I_HEAD_BI.
    I_HEAD_BI-VBELN = PF_HEAD_I-VBELN.
    I_HEAD_BI-KUNAG = PF_HEAD_I-BKUNN.
    I_HEAD_BI-ZTYPE = PF_HEAD_I-ZTYPE.

**SOLD-TO INFO
    PERFORM GET_PARTNER_NUMBER USING    PF_HEAD_I
                                        PFWA_VBRK-ZSPARNR_B
                                        'SOLD'
                               CHANGING PFV_PARNR.

    PERFORM GET_CUST_SHIP_DATA USING      PF_HEAD_I-KUNAG
                                          PF_HEAD_I-VKORG
                                          PFV_PARNR
                                          PFWA_VBRK-SPART
                                          'SOLD'
                               CHANGING   I_HEAD_SO.
    I_HEAD_SO-VBELN = PF_HEAD_I-VBELN.          "DELIVERY NO.
    I_HEAD_SO-KUNAG = PF_HEAD_I-KUNAG.          "SOLD-TO NO.
    I_HEAD_SO-ZTYPE = PF_HEAD_I-ZTYPE.
**SHIP-TO INFO
    PERFORM GET_PARTNER_NUMBER USING    PF_HEAD_I
                                        PFWA_VBRK-ZSPARNR_B
                                        'SHIP'
                               CHANGING PFV_PARNR.


    PERFORM GET_CUST_SHIP_DATA USING      PF_HEAD_I-KUNNR
                                          PF_HEAD_I-VKORG
                                          PFV_PARNR
                                          PFWA_VBRK-SPART
                                          'SHIP'
                               CHANGING   I_HEAD_SH.
    I_HEAD_SH-VBELN = PF_HEAD_I-VBELN.          "DELIVERY NO.
    I_HEAD_SH-KUNAG = PF_HEAD_I-KUNNR.          "SHIP-TO NO.
    I_HEAD_SH-ZTYPE = PF_HEAD_I-ZTYPE.
    APPEND: I_HEAD_BI, I_HEAD_SH, I_HEAD_SO.
    CLEAR:  I_HEAD_BI, I_HEAD_SH, I_HEAD_SO.
  ENDLOOP.
ENDFORM.                    " GET_HEAD_DATA_SHIP
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_SHIP_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_BI_KUNAG  text
*      -->P_VBRK_ZIPARNR_B  text
*      -->P_VBRK_SPART  text
*      -->P_2001   text
*      <--P_I_HEAD_BI_NAME1  text
*      <--P_I_HEAD_BI_NAME2  text
*      <--P_I_HEAD_BI_NAME3  text
*      <--P_I_HEAD_BI_NAME4  text
*      <--P_I_HEAD_BI_STREET  text
*      <--P_I_HEAD_BI_STR_SUPPL1  text
*      <--P_I_HEAD_BI_STR_SUPPL2  text
*      <--P_I_HEAD_BI_STR_SUPPL3  text
*      <--P_I_HEAD_BI_LOCATION  text
*      <--P_I_HEAD_BI_ORT02  text
*      <--P_I_HEAD_BI_LANDX  text
*      <--P_I_HEAD_BI_TELNU  text
*      <--P_I_HEAD_BI_FAXNO  text
*      <--P_I_HEAD_BI_CONCT  text
*      <--P_I_HEAD_BI_SORTL  text
*----------------------------------------------------------------------*
FORM GET_CUST_SHIP_DATA USING     PFV_KUNAG_I
                                  PFV_VKORG_I
                                  PFV_ZSPARNR
                                  PFV_SPART_I
                                  PFV_TYPE_I
                        CHANGING  PFWA_INFO STRUCTURE I_HEAD_BI.
  DATA: PFWA_T005T  LIKE T005T,
        PFWA_ADRC   LIKE ADRC,
        PFWA_KNA1   LIKE KNA1,
        PFWA_KNVK   LIKE KNVK,
        PFV_PAAT3   TYPE PAAT3,
        PFV_PAFKT   TYPE PAFKT.

  CLEAR: ADRC, T005T, KNVK, PFWA_INFO.
  PERFORM GET_WORKAREA_KNA1 USING     PFV_KUNAG_I
                            CHANGING  PFWA_KNA1.
  CHECK PFWA_KNA1 IS NOT INITIAL.
**NAME1 / NAME2 / NAME3 / NAME4 / ORT02
  MOVE-CORRESPONDING PFWA_KNA1 TO PFWA_INFO.
  IF PFWA_KNA1-SORTL <> '' AND
     PFWA_KNA1-LAND1 = 'TW'.
    PFWA_INFO-SORTL = PFWA_KNA1-SORTL.
  ENDIF.
  PERFORM GET_WORKAREA_ADRC_SYDATUM USING     PFWA_KNA1-ADRNR
                                    CHANGING  PFWA_ADRC.
  IF PFWA_ADRC IS NOT INITIAL.
**STREET / STR_SUPPL1 / STR_SUPPL2 / STR_SUPPL3 / LOCATION / CITY1
    MOVE-CORRESPONDING PFWA_ADRC TO PFWA_INFO.
    PFWA_INFO-POSTL       = PFWA_ADRC-POST_CODE1.
    PFWA_INFO-REGIO       = PFWA_ADRC-REGION.
    PFWA_INFO-LAND1       = PFWA_ADRC-COUNTRY.
  ENDIF.

  PERFORM GET_WORKAREA_T005T USING    PFWA_KNA1-LAND1
                             CHANGING PFWA_T005T.
  IF PFWA_T005T-LANDX IS NOT INITIAL.
    CONCATENATE PFWA_KNA1-PSTLZ PFWA_T005T-LANDX
      INTO PFWA_INFO-LANDX.
  ENDIF.
**8"及12"的聯絡人用KNVK-PARH3區分
  PERFORM GET_CONTANT_PERSON_SEPAR_FLAG USING    PFV_VKORG_I
                                        CHANGING PFV_PAAT3.
  IF PFV_ZSPARNR IS INITIAL.
    CASE PFV_TYPE_I.
      WHEN 'SOLD'.
        PFV_PAFKT = '80'.
      WHEN 'SHIP'.
        PFV_PAFKT = '81'.
      WHEN 'BILL'.
        PFV_PAFKT = '82'.
      WHEN OTHERS.
    ENDCASE.
    PERFORM GET_WORKAREA_KNVK_PAFKT USING     PFV_KUNAG_I
                                              PFV_SPART_I
                                              PFV_PAAT3
                                              PFV_PAFKT
                                    CHANGING  PFWA_KNVK.
**取得聯絡人資訊(TELNU / FAXNO / CONCT)
    PERFORM GET_CONCACT_PERSON USING    PFV_KUNAG_I
                                        PFWA_KNVK-PARNR
                                        PFWA_KNA1-ADRNR
                               CHANGING PFWA_INFO.

  ELSE.
**取得聯絡人資訊(TELNU / FAXNO / CONCT)
    PERFORM GET_CONCACT_PERSON USING    PFV_KUNAG_I
                                        PFV_ZSPARNR
                                        PFWA_KNA1-ADRNR
                               CHANGING PFWA_INFO.
  ENDIF.

ENDFORM.                    " GET_CUST_SHIP_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_CONCACT_PERSON
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_KUNAG  text
*      -->P_KNVK_PARNR  text
*      <--P_PF_TELNU  text
*      <--P_PF_FAXNO  text
*      <--P_PF_CONCT  text
*----------------------------------------------------------------------*
FORM GET_CONCACT_PERSON  USING    PFV_KUNAG_I
                                  PFV_ZSPNR_I
                                  PFV_ADRNR_I
                         CHANGING PFWA_SHIP_IO STRUCTURE I_HEAD_BI.
*                                  PFV_TELNU_O
*                                  PFV_FAXNO_O
*                                  PFV_CONCT_O.
  DATA: PFWA_CONT LIKE ZCONTACT1,
        PFWA_ADRC LIKE ADRC.

  CLEAR: PFWA_SHIP_IO-TELNU, PFWA_SHIP_IO-FAXNO, PFWA_SHIP_IO-CONCT, PFWA_CONT.

  CALL FUNCTION 'ZGET_CONTACT_DATA'
    EXPORTING
      PARNR   = PFV_ZSPNR_I
      KUNNR   = PFV_KUNAG_I
    IMPORTING
      CONTACT = PFWA_CONT.

  PERFORM GET_WORKAREA_ADRC USING     PFV_ADRNR_I
                            CHANGING  PFWA_ADRC.

  IF PFWA_ADRC IS NOT INITIAL.
    IF PFWA_CONT-TEL IS INITIAL.
      PFWA_CONT-TEL = PFWA_ADRC-TEL_NUMBER.
    ENDIF.
    IF PFWA_CONT-FAX IS INITIAL.
      PFWA_CONT-FAX = PFWA_ADRC-FAX_NUMBER.
    ENDIF.
  ENDIF.

  IF PFWA_CONT-TEL IS NOT INITIAL.
    IF PFWA_CONT-EXT IS NOT INITIAL.
      CONCATENATE PFWA_CONT-TEL '#' PFWA_CONT-EXT
        INTO PFWA_SHIP_IO-TELNU.
    ELSE.
      PFWA_SHIP_IO-TELNU = PFWA_CONT-TEL.
    ENDIF.
    CONCATENATE 'TEL:' PFWA_SHIP_IO-TELNU
      INTO PFWA_SHIP_IO-TELNU SEPARATED BY SPACE.
  ENDIF.

  IF PFWA_CONT-FAX IS NOT INITIAL.
    CONCATENATE 'FAX:' PFWA_CONT-FAX
      INTO PFWA_SHIP_IO-FAXNO SEPARATED BY SPACE.
  ENDIF.

  IF PFWA_CONT-PERSON IS NOT INITIAL.
    CONCATENATE 'ATTN:' PFWA_CONT-PERSON
      INTO PFWA_SHIP_IO-CONCT SEPARATED BY SPACE.
  ENDIF.
ENDFORM.                    " GET_CONCACT_PERSON

*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA TABLES PF_HEAD STRUCTURE I_HEAD.
  DATA: PF_ITEM LIKE I_ITEM OCCURS 0 WITH HEADER LINE.
  PERFORM GET_CUST_LOT_LIST TABLES PF_HEAD
                                   I_ZCLOT.

  LOOP AT PF_HEAD.
    PERFORM GET_ITEM_DATA_FREE01 TABLES I_LIPS
                                        PF_ITEM
                                 USING  PF_HEAD.
    APPEND LINES OF PF_ITEM TO I_ITEM.
    PERFORM GET_ITEM_DATA_PACKING01 TABLES I_LIPS
                                           PF_ITEM
                                    USING  PF_HEAD.
    APPEND LINES OF PF_ITEM TO I_ITEM.
    PERFORM GET_ITEM_DATA_INVCRD01 TABLES I_VBRP
                                          PF_ITEM
                                   USING  PF_HEAD.
    APPEND LINES OF PF_ITEM TO I_ITEM.
*<-I210217
    PERFORM GET_ITEM_DATA_NEWPI01 TABLES I_ZPDH
                                         I_ZPDI
                                         PF_ITEM
                                  USING  PF_HEAD.
    APPEND LINES OF PF_ITEM TO I_ITEM.
*->I210217
  ENDLOOP.
  SORT I_ITEM BY VBELN PORDE CORDE POSNR.                   "M082719

**取得其他資訊
  LOOP AT PF_HEAD.
    PERFORM GET_ITEM_DATA_FREE02 TABLES I_ITEM
                                 USING  PF_HEAD.          "重組ITEM..把重覆的合併
    PERFORM GET_ITEM_DATA_PACKING02 TABLES I_ITEM
                                    USING  PF_HEAD.
  ENDLOOP.

**特殊需求
  LOOP AT PF_HEAD.
**把SP_RULE_FOR_ITEM_PACKING_FOR12併入SP_RULE_FOR_ITEM_PACKING
    PERFORM SP_RULE_FOR_ITEM_PACKING TABLES I_ITEM
                                     USING  PF_HEAD.
    PERFORM SP_RULE_FOR_ITEM_INVOICE TABLES I_ITEM
                                     USING  PF_HEAD.
    PERFORM SP_RULE_FOR_ITEM_FREE_INV TABLES I_ITEM
                                      USING  PF_HEAD.
**其它特殊需求 --> 12" or 產品 (非by客戶)
    PERFORM SP_RULE_FOR_ITEM_ALL  TABLES I_ITEM
                                  USING  PF_HEAD.
  ENDLOOP.

  SORT I_ITEM BY VBELN ZTYPE ITMNO.


**12" 保稅和非保稅的料號,不可以開再同一張invoice(Free invoice)上
*  IF P_VKORG = 'PSC1'.
*    LOOP AT PF_HEAD WHERE ZTYPE = 'I' OR ZTYPE = 'F'.
*      PERFORM CHECK_BOND_TYPE TABLES I_ITEM
*                              USING  PF_HEAD.
*    ENDLOOP.
*  ENDIF.


  CHECK P_JOBTPS = 'N' OR               "N = IMEX
        P_JOBTPS = 'E'.
  LOOP AT PF_HEAD.
**針對關務需要顯示加工的費用(保品)
    PERFORM IMEX_GET_FUNDRY_SERVICE_PRICE  TABLES  I_ITEM
                                           USING   PF_HEAD.
**Processing Charge
    PERFORM IMEX_GET_PROCESSING_CHARGE  TABLES  I_ITEM
                                        USING   PF_HEAD.
**取得BOM No. / GOOD BAD DIE unit price
    PERFORM IMEX_GET_OTHER_ITEM_INFO TABLES  I_ITEM
                                     USING   PF_HEAD.
    LOOP AT I_ITEM WHERE VBELN = PF_HEAD-VBELN
                   AND   ZTYPE = PF_HEAD-ZTYPE.
      CLEAR I_ITEM-KURKI.
      MODIFY I_ITEM.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_PACKING01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_PACKING01 TABLES PF_LIPS_I     STRUCTURE LIPS
                                    PF_ITEM_O     STRUCTURE I_ITEM
                             USING  PFWA_HEAD_I   STRUCTURE I_HEAD.
  CLEAR: PF_ITEM_O, PF_ITEM_O[].
  CHECK PFWA_HEAD_I-ZTYPE = 'P'.                "P = Packing

  LOOP AT PF_LIPS_I WHERE VBELN = PFWA_HEAD_I-VBELN.
    PF_ITEM_O-VBELN = PFWA_HEAD_I-VGBEL.        "(X)單號  [KEY]
    PF_ITEM_O-ZTYPE = PFWA_HEAD_I-ZTYPE.        "(X)單據類型  [KEY]
    PF_ITEM_O-KUNAG = PFWA_HEAD_I-KUNAG.        "(X)CUST NO.
    PF_ITEM_O-POSNR = PF_LIPS_I-POSNR.          "(X)ITME NO.
    PF_ITEM_O-AUBEL = PF_LIPS_I-VGBEL.          "(X)SO.
    PF_ITEM_O-AUPOS = PF_LIPS_I-VGPOS.          "(X)SO ITEM
    PF_ITEM_O-UECHA = PF_LIPS_I-UECHA.          "(X)High Level

    PF_ITEM_O-KDMAT = PF_LIPS_I-KDMAT.          "customer material
    PF_ITEM_O-MATNR = PF_LIPS_I-MATNR.          "MATERIAL NUMBER
    PF_ITEM_O-WERKS = PF_LIPS_I-WERKS.          "Plant
    PF_ITEM_O-LOTNO = PF_LIPS_I-CHARG.          "LOTNO
    PF_ITEM_O-CHARG = PF_LIPS_I-CHARG.          "KEY NO.

**Material Description (MAKTX / KURKI)
    PERFORM GET_MATERIAL_DESC USING     PF_LIPS_I
                                        PFWA_HEAD_I         "I072919
                              CHANGING  PF_ITEM_O.

    CLEAR:  PF_ITEM_O-DCEMN, PF_ITEM_O-CEMEH,
            PF_ITEM_O-DWEMN, PF_ITEM_O-WEMEH.
** DISPLAY shipping qty& unit of measure   (chip)
    PERFORM GET_QTY_UNIT  USING     PF_LIPS_I
                                    'CHIP'
                          CHANGING  PF_ITEM_O.
** DISPLAY shipping qty& unit of measure   (WAFER)
    PERFORM GET_QTY_UNIT  USING     PF_LIPS_I
                                    'WAFER'
                          CHANGING  PF_ITEM_O.
**DATECODE(這個PERFORM不可以把USING換成WORKAREA,外部程式有在CALL 20190402已把外部的都換完了)
    PERFORM GET_DATECODE  USING     PF_LIPS_I
                          CHANGING  PF_ITEM_O-DCODE.
**Cust PO No.
    PERFORM GET_CUST_PO_INFO  USING     PF_LIPS_I-VGBEL
                                        PF_LIPS_I-VGPOS
                              CHANGING  PF_ITEM_O-BSTKD   "Cust PO No
                                        PF_ITEM_O-POSEX.  "Cust PO item no
    PF_ITEM_O-BSTNK = PF_ITEM_O-BSTKD.                    "(X)Cust PO No.
**GET CARTON相關資訊( CTNNO / DNTGE / DBRGE / CDIME / CORDE / VENUM / UEVEL )
    PERFORM GET_CARTON_PALLET_INFO TABLES    I_VBFA
                                             I_VEKP
                                   USING     PF_LIPS_I
                                             'CARTON'
                                   CHANGING  PF_ITEM_O.
    IF PF_ITEM_O-UEVEL IS NOT INITIAL.
**GET PALLET相關資訊( PALNO / DPNTG / DPBRG / PDIME / PORDE / VENUM / UEVEL )
      PERFORM GET_CARTON_PALLET_INFO TABLES    I_VBFA
                                               I_VEKP
                                     USING     PF_LIPS_I
                                               'PALLET'
                                     CHANGING  PF_ITEM_O.
    ENDIF.
**GET Cust Lot ID
    PERFORM GET_CUST_LOT_NO TABLES    I_ZCLOT
                            USING     PFWA_HEAD_I
                                      PF_LIPS_I
                            CHANGING  PF_ITEM_O.
**BRAND/CHIPNAMEB( BRAND / ZCHIP )
    PERFORM GET_BRAND_CHIPNAME_INFO USING    PF_LIPS_I-VGBEL
                                             PF_LIPS_I-VGPOS
                                    CHANGING PF_ITEM_O.
**WAFER Description
    PERFORM GET_WAFER_DESC USING    PF_LIPS_I-WERKS
                                    PF_LIPS_I-MATNR
                           CHANGING PF_ITEM_O-WRKST.

** get Good die & Bad die Qty on in die qty(只有在PFWA_HEAD_I-PRODTYPE = 'D'時才會發生)
    PERFORM GET_GOOD_BAD_DIE_QTY  USING    PFWA_HEAD_I-PRODTYPE
                                  CHANGING PF_ITEM_O.

    PF_ITEM_O-GEWEI = 'KG'.
*<-I210616 WEMEH
    PERFORM GET_WAFERQTY_BY_PRODTYPE USING    PFWA_HEAD_I
                                              ''
                                     CHANGING PF_ITEM_O.
**PFWA_HEAD_I-SPART<>'02',可能會因KURKI導致MATNR值更改
    PERFORM GET_MATERIAL_BY_KURKI_12  USING    PFWA_HEAD_I-SPART
                                               PF_ITEM_O-KURKI
                                      CHANGING PF_ITEM_O-MATNR.
*->I210616
    APPEND PF_ITEM_O.
    CLEAR  PF_ITEM_O.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_PACKING01
*&---------------------------------------------------------------------*
*&      Form  GET_MATERIAL_DESC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_MATNR  text
*      -->P_I_LIPS_WERKS  text
*      -->P_I_LIPS_VGBEL  text
*      -->P_I_LIPS_VGPOS  text
*      -->P_I_LIPS_CHARG  text
*      <--P_I_ITEM_MAKTX  text
*----------------------------------------------------------------------*
FORM GET_MATERIAL_DESC  USING    PFWA_LIPS_I STRUCTURE LIPS
                                 PFWA_HEAD_I STRUCTURE I_HEAD
                        CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFWA_ZZAUSP   LIKE ZZAUSP,
        PFWA_MCHA     LIKE MCHA,
        PFWA_MAKT     LIKE MAKT,                            "I051419
        PFV_ZMAKT     TYPE MAKTX,
        PFV_WRKST     TYPE WRKST,
        PFV_VGBTX(16) TYPE C,
        PFV_ZTEXT(22) TYPE C,
        PFV_BTRUE     TYPE C,                             " 判斷是否符合
        PF_LINES      LIKE TLINE  OCCURS 0 WITH HEADER LINE.


  CLEAR: ZZAUSP, MARA, PFV_WRKST, PFV_VGBTX, PFV_ZTEXT, PFV_ZMAKT.

  PERFORM GET_WORKAREA_ZZAUSP USING     PFWA_LIPS_I-WERKS
                                        PFWA_LIPS_I-MATNR
                              CHANGING  PFWA_ZZAUSP.
*  PFV_ZMAKT = PFWA_ZZAUSP-ZDESC.                         "D051419
*051419-->I
  PERFORM GET_WORKAREA_MAKT USING     PFWA_LIPS_I-MATNR
                            CHANGING  PFWA_MAKT.
  PERFORM SP_RULE_FOR_MAKTX USING     PFWA_HEAD_I
                            CHANGING  PFWA_MAKT-MAKTX.      "I200722
  IF PFWA_MAKT IS NOT INITIAL.
    PFV_ZMAKT  = PFWA_MAKT-MAKTX.
  ELSE.
    PFV_ZMAKT = PFWA_ZZAUSP-ZDESC.
  ENDIF.
*051419<--I

*WAFER SIZE
  CALL FUNCTION 'Z_GET_BASIC_MATERIAL'
    EXPORTING
      WERKS = PFWA_LIPS_I-WERKS
      MATNR = PFWA_LIPS_I-MATNR
    IMPORTING
      WRKST = PFV_WRKST.
*Customer production code
  CONCATENATE PFWA_LIPS_I-VGBEL PFWA_LIPS_I-VGPOS
    INTO PFV_VGBTX.
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VGBTX
                               '0007'
                               'VBBP'.
  READ TABLE PF_LINES INDEX 1.
  MOVE PF_LINES-TDLINE TO PFV_ZTEXT.
**取得客戶LOT
  PERFORM GET_WORKAREA_MCHA USING     PFWA_LIPS_I-WERKS
                                      PFWA_LIPS_I-MATNR
                                      PFWA_LIPS_I-CHARG
                            CHANGING  PFWA_MCHA.
*組合MAKTX
  IF PFWA_MCHA-LICHA IS NOT INITIAL.
    PFWA_ITEM_IO-MAKTX = PFWA_MCHA-LICHA.
    PFWA_ITEM_IO-KURKI = PFWA_MCHA-LICHA.
  ENDIF.
*-- 進出口-報關格式不顯示KURIKI
  PERFORM SP_RULE_FOR_ITEM_MATRDESC_IMEX USING    PFWA_HEAD_I
                                         CHANGING PFV_BTRUE.
  IF PFV_BTRUE IS NOT INITIAL.
    CLEAR: PFWA_ITEM_IO-MAKTX.
  ENDIF.

  IF PFV_ZMAKT IS NOT INITIAL.
    IF PFWA_ITEM_IO-MAKTX IS NOT INITIAL.
      CONCATENATE PFWA_ITEM_IO-MAKTX ',' PFV_ZMAKT
        INTO PFWA_ITEM_IO-MAKTX SEPARATED BY SPACE.
    ELSE.
      PFWA_ITEM_IO-MAKTX = PFV_ZMAKT.
    ENDIF.
  ENDIF.

  IF PFV_WRKST IS NOT INITIAL.
    IF PFWA_ITEM_IO-MAKTX IS NOT INITIAL.
      CONCATENATE PFWA_ITEM_IO-MAKTX ',' PFV_WRKST
        INTO PFWA_ITEM_IO-MAKTX SEPARATED BY SPACE.
    ELSE.
      PFWA_ITEM_IO-MAKTX = PFV_WRKST.
    ENDIF.
  ENDIF.

  IF PFV_ZTEXT IS NOT INITIAL.
    IF PFWA_ITEM_IO-MAKTX IS NOT INITIAL.
      CONCATENATE PFWA_ITEM_IO-MAKTX ',' PFV_ZTEXT
        INTO PFWA_ITEM_IO-MAKTX SEPARATED BY SPACE.
    ELSE.
      PFWA_ITEM_IO-MAKTX = PFV_ZTEXT.
    ENDIF.
  ENDIF.

*組合MAKTX
*  CONCATENATE PFWA_MCHA-LICHA ',' PFV_ZMAKT ',' PFV_WRKST ',' PFV_ZTEXT
*    INTO PFV_MAKTX SEPARATED BY SPACE.
*  PFV_MAKTX+45(16) = PFV_WRKST.
*  PFV_MAKTX+60(22) = PFV_ZTEXT.
ENDFORM.                    " GET_MATERIAL_DESC
*&---------------------------------------------------------------------*
*&      Form  GET_QTY_UNIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_VBELN  text
*      -->P_I_LIPS_POSNR  text
*      -->P_2853   text
*      <--P_I_ITEM_DCEMN  text
*      <--P_I_ITEM_CEMEH  text
*----------------------------------------------------------------------*
FORM GET_QTY_UNIT  USING    PFWA_LIPS_I  STRUCTURE LIPS
                            PFV_FNCTS
                   CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFWA_VEPO LIKE VEPO.

*  CLEAR:  PFWA_ITEM_IO-DCEMN, PFWA_ITEM_IO-CEMEH,
*          PFWA_ITEM_IO-DWEMN, PFWA_ITEM_IO-WEMEH.
  PERFORM GET_WORKAREA_VEPO USING     PFWA_LIPS_I-VBELN
                                      PFWA_LIPS_I-POSNR
                            CHANGING  PFWA_VEPO.
  CHECK PFWA_VEPO IS NOT INITIAL.
  CASE PFV_FNCTS.
    WHEN 'CHIP'.
      CHECK PFWA_VEPO-VEMEH <> 'ST'.
      PFWA_ITEM_IO-DCEMN = PFWA_VEPO-VEMNG.
      PFWA_ITEM_IO-CEMEH = PFWA_VEPO-VEMEH.
    WHEN 'WAFER'.
      CHECK PFWA_VEPO-VEMEH = 'ST'.
      PFWA_ITEM_IO-DWEMN = PFWA_VEPO-VEMNG.
      PFWA_ITEM_IO-WEMEH = PFWA_VEPO-VEMEH.
    WHEN 'FREE'.
      PFWA_ITEM_IO-DWEMN = PFWA_VEPO-VEMNG.
      PFWA_ITEM_IO-WEMEH = PFWA_VEPO-VEMEH.
      CHECK PFWA_ITEM_IO-DWEMN IS INITIAL.
      PFWA_ITEM_IO-DWEMN = PFWA_LIPS_I-LFIMG.
      PFWA_ITEM_IO-WEMEH = PFWA_LIPS_I-VRKME.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_QTY_UNIT
*&---------------------------------------------------------------------*
*&      Form  GET_DATECODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_MATNR  text
*      -->P_I_LIPS_CHARG  text
*      -->P_I_LIPS_WERKS  text
*      <--P_I_ITEM_DCODE  text
*----------------------------------------------------------------------*
FORM GET_DATECODE  USING    PFWA_LIPS_I STRUCTURE LIPS
                   CHANGING PFV_DCODE.

  DATA: PFV_AUSP1     TYPE ATWRT,
        PFV_MESSA(70) TYPE C.
  CLEAR: PFV_AUSP1, PFV_MESSA, PFV_DCODE.

  CALL FUNCTION 'Z_MM_GET_BATCH'
    EXPORTING
      TMATNR  = PFWA_LIPS_I-MATNR
      TWERKS  = PFWA_LIPS_I-WERKS
      TCHARG  = PFWA_LIPS_I-CHARG
      TATNAM  = 'DATECODE'
    IMPORTING
      O_AUSP1 = PFV_AUSP1.



  IF PFV_AUSP1 IS INITIAL.
    CONCATENATE PFWA_LIPS_I-MATNR PFWA_LIPS_I-WERKS PFWA_LIPS_I-CHARG '找不到 datecode!!'
        INTO PFV_MESSA SEPARATED BY SPACE.
    MESSAGE S000(ZZ) WITH PFV_MESSA.
  ELSE.
    PFV_DCODE = PFV_AUSP1.
  ENDIF.

ENDFORM.                    " GET_DATECODE
*&---------------------------------------------------------------------*
*&      Form  GET_CARTON_PALLET_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_VBELN  text
*      -->P_I_LIPS_POSNR  text
*      -->P_2904   text
*      <--P_I_ITEM_CTNNO  text
*      <--P_I_ITEM_DNTGE  text
*      <--P_I_ITEM_DBRGE  text
*      <--P_I_ITEM_CDIME  text
*----------------------------------------------------------------------*
FORM GET_CARTON_PALLET_INFO  TABLES   PF_VBFA_I    STRUCTURE VBFA
                                      PF_VEKP_I    STRUCTURE VEKP
                             USING    PFWA_LIPS_I  STRUCTURE LIPS
                                      PFV_TYPES
                             CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PF_VEKP_CURR  LIKE VEKP OCCURS 0 WITH HEADER LINE,
        PFV_EXIDV     TYPE EXIDV,                             "CARTON/PALLET總數
        PFV_EXIDE     TYPE EXIDV.                             "CARTON/PALLET個數

  IF PFV_TYPES = 'CARTON'.
    CLEAR: PFWA_ITEM_IO-CTNNO, PFWA_ITEM_IO-CORDE, PFWA_ITEM_IO-DBRGE, PFWA_ITEM_IO-DNTGE, PFWA_ITEM_IO-CDIME,
           PFWA_ITEM_IO-VENUM, PFWA_ITEM_IO-UEVEL.
  ENDIF.
  IF PFV_TYPES = 'PALLET'.
    CLEAR: PFWA_ITEM_IO-PALNO, PFWA_ITEM_IO-PORDE, PFWA_ITEM_IO-DPBRG, PFWA_ITEM_IO-DPNTG, PFWA_ITEM_IO-PDIME.
  ENDIF.

  PERFORM GET_HANDING_UNIT_VEKP TABLES PF_VEKP_I
                                       PF_VBFA_I
                                       PF_VEKP_CURR
                                USING  PFWA_LIPS_I-VBELN.

  "PALLET需要取得CARTON上一層的HANDING UNIT ID
  PERFORM GET_HIGH_LEVEL_HANDING_UNIT  TABLES PF_VEKP_I
                                              PF_VEKP_CURR
                                       USING  PFV_TYPES.

  SORT PF_VEKP_CURR BY EXIDV DESCENDING.
  READ TABLE PF_VEKP_CURR INDEX 1.
  PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PF_VEKP_CURR-EXIDV.
  PERFORM GET_DENOMINATOR_TTL_UNIT     USING    PF_VEKP_CURR-EXIDV
                                       CHANGING PFV_EXIDV."計算總數
  CHECK PFV_EXIDV IS NOT INITIAL.
  READ TABLE PF_VBFA_I WITH KEY VBELV   = PFWA_LIPS_I-VBELN
                                POSNV   = PFWA_LIPS_I-POSNR
                                VBTYP_N = 'X'.
  READ TABLE PF_VEKP_I WITH KEY VENUM = PF_VBFA_I-VBELN.
  IF SY-SUBRC = 0 AND
     PF_VEKP_I-UEVEL IS NOT INITIAL.
    PFWA_ITEM_IO-UEVEL = PF_VEKP_I-UEVEL.
  ENDIF.
  IF PFV_TYPES = 'PALLET'.
    READ TABLE PF_VEKP_I WITH KEY VENUM = PFWA_ITEM_IO-UEVEL.
  ENDIF.
  PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PF_VEKP_I-EXIDV.
  PERFORM GET_DENOMINATOR_TTL_UNIT     USING    PF_VEKP_I-EXIDV
                                       CHANGING PFV_EXIDE.

  PFWA_ITEM_IO-VENUM = PF_VBFA_I-VBELN.
  IF PFV_TYPES = 'CARTON'.
**取得CARTON序號
    PFWA_ITEM_IO-CORDE = PFV_EXIDE.
**取得M/N箱
    CONCATENATE PFV_EXIDE '/' PFV_EXIDV
      INTO PFWA_ITEM_IO-CTNNO.
    CONDENSE PFWA_ITEM_IO-CTNNO NO-GAPS.
**取得尺寸資訊
    PERFORM GET_DIM_INFO USING    PF_VEKP_I
                         CHANGING PFWA_ITEM_IO-CDIME.
**取得重量
    IF PF_VEKP_I-NTGEW < '0.1'.
      PF_VEKP_I-NTGEW = '0.1'.
    ENDIF.
    PFWA_ITEM_IO-DNTGE = PF_VEKP_I-NTGEW.
    PFWA_ITEM_IO-DBRGE = PF_VEKP_I-BRGEW.
    EXIT.
  ENDIF.

  IF PFV_TYPES = 'PALLET'.
**取得PALLET序號
    PFWA_ITEM_IO-PORDE = PFV_EXIDE.
**取得M/N棧板
    CONCATENATE PFV_EXIDE '/' PFV_EXIDV
      INTO PFWA_ITEM_IO-PALNO.
    CONDENSE PFWA_ITEM_IO-PALNO NO-GAPS.
**取得尺寸資訊
    PERFORM GET_DIM_INFO USING    PF_VEKP_I
                         CHANGING PFWA_ITEM_IO-PDIME.
**取得重量
    IF PF_VEKP_I-NTGEW < '0.1'.
      PF_VEKP_I-NTGEW = '0.1'.
    ENDIF.
    PFWA_ITEM_IO-DPNTG = PF_VEKP_I-NTGEW.
    PFWA_ITEM_IO-DPBRG = PF_VEKP_I-BRGEW.
    EXIT.
  ENDIF.

ENDFORM.                    " GET_CARTON_PALLET_INFO
*&---------------------------------------------------------------------*
*&      Form  SPCEIAL_RULE_FOR_ITEM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_PACKING  TABLES  PF_ITEM_IO   STRUCTURE I_ITEM
                               USING   PFWA_HEAD_I  STRUCTURE I_HEAD.
  DATA: PFWA_VBAP     LIKE VBAP,
        PFWA_LIPS     LIKE LIPS,
        PFV_PRODGSDE  TYPE ZPRODGSDE,
        PFV_NXPENG    TYPE C,
        PFV_CHARG     TYPE CHARG_D.

  CHECK PFWA_HEAD_I-ZTYPE = 'P'.                "P = Packing

  LOOP AT PF_ITEM_IO  WHERE VBELN = PFWA_HEAD_I-VBELN
                      AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
*8吋
    IF PFWA_HEAD_I-VKORG = 'MAX1'.
      CASE PFWA_HEAD_I-KUNAG.
        WHEN '0000001840' OR                    "HIMAX
             '0000001921'.
          PERFORM GET_WORKAREA_VBAP USING     PF_ITEM_IO-AUBEL
                                              PF_ITEM_IO-AUPOS
                                    CHANGING  PFWA_VBAP.
          CHECK PFWA_VBAP IS NOT INITIAL.
          PF_ITEM_IO-MAKTX+60(22) = PFWA_VBAP-ZPOSTX.
        WHEN '0000000385'.                      "Vanguard
          PF_ITEM_IO-KDMAT = PF_ITEM_IO-KDMAT+0(21).
        WHEN '0000000313'.                      "ETRON
          PF_ITEM_IO-KDMAT = PF_ITEM_IO-KDMAT+0(33).
        WHEN '0000001842' OR                    "天鈺
             '0000003055' OR                    "力祥
             '0000001947' OR                    "力智
             '0000003026'.                      "富鼎
          PERFORM GET_WORKAREA_LIPS USING     PF_ITEM_IO-VBELN
                                              PF_ITEM_IO-POSNR
                                    CHANGING  PFWA_LIPS.
          PERFORM GET_WORKAREA_VBAP USING     PFWA_LIPS-VGBEL
                                              PFWA_LIPS-VGPOS
                                    CHANGING  PFWA_VBAP.
          CHECK PFWA_VBAP IS NOT INITIAL.
*    PF_ITEM-POSEX = PFWA_VBAP-POSEX.     "move to cust PO no & item no
        WHEN OTHERS.
          CLEAR: PF_ITEM_IO-DCODE.
      ENDCASE.
    ENDIF.
*12吋
    IF PFWA_HEAD_I-VKORG = 'PSC1'.
*<-D210616  1843為矽創,PSC1沒有在出貨(就不往下移)
**客戶第2個料號 放在第4行第2欄
*      IF PF_ITEM-KUNAG = '0000001840' OR
*         PF_ITEM-KUNAG = '0000001921' OR
*         PF_ITEM-KUNAG = '0000001843'.
*        PERFORM GET_WORKAREA_VBAP USING PF_ITEM-AUBEL
*                                        PF_ITEM-AUPOS
*                              CHANGING  PFWA_VBAP.
*        PF_ITEM-4TH2 = PFWA_VBAP-ZPOSTX.
*      ENDIF.
*->D210616
      CASE PFWA_HEAD_I-KUNAG.
        WHEN '0000001641' OR                              "Solomon
             '0000002526'.                                "晶相
**第4行 total gross die
          PERFORM GET_GROSS_DIE_COUNT_PSC1 USING     PF_ITEM_IO
                                                     PFWA_HEAD_I
                                           CHANGING  PFV_PRODGSDE.
          PERFORM COMPOSE_GROSS_DIE_DESC  USING    PFV_PRODGSDE
                                          CHANGING PF_ITEM_IO.
        WHEN '0000001840' OR
             '0000001921'.                                "Himax
*<-210616
          PERFORM GET_WORKAREA_VBAP USING PF_ITEM_IO-AUBEL
                                          PF_ITEM_IO-AUPOS
                                CHANGING  PFWA_VBAP.
          PF_ITEM_IO-4TH2 = PFWA_VBAP-ZPOSTX.
*->210616
          CLEAR: PF_ITEM_IO-LOTNO, PF_ITEM_IO-DCODE.

        WHEN '0000002249'.                                "Maxim
          PERFORM GET_MAXIM_DATA USING PFWA_HEAD_I
                              CHANGING PF_ITEM_IO.
**這個客戶在SP_RULE_FOR_DOC_DISPLAY時會把LOT及CHARG互換(客戶需求)
        WHEN '0000002570'.                                "NXP
*- Get data in header(CHECK_NXP_ENG直接放入GET_NXP_DAT中)
          PERFORM GET_NXP_DATA USING    PFWA_HEAD_I
                               CHANGING PF_ITEM_IO.
        WHEN '0000002695'.                                "上海思力微 SILEAD
          PF_ITEM_IO-LOTNO = PF_ITEM_IO-CHARG.            "LOT NO 要等於 KEY NO(9碼)
*<-I210616
        WHEN '0000002644' OR '0000002747' OR              "ON-Semi
             '0000002766' OR '0000002768'.                "AIXIESHENG 愛協生
          CLEAR: PF_ITEM_IO-DCODE.
*->I210616
      ENDCASE.
    ENDIF.

**下面是不分8", 12"相同RULE
    CASE PFWA_HEAD_I-KUNAG.
      WHEN '0000001270'.                                  "Lapis
        PF_ITEM_IO-DCODE = PF_ITEM_IO-DCODE+0(7).         "datecode 只取7前碼
      WHEN OTHERS.
    ENDCASE.

    MODIFY PF_ITEM_IO.
    CLEAR  PF_ITEM_IO.
  ENDLOOP.
*<-I210616
  PERFORM SP_RULE_FOR_ITEM_BY_CUSTGP TABLES PF_ITEM_IO
                                     USING  PFWA_HEAD_I.
*->I210616
ENDFORM.                    " SPCEIAL_RULE_FOR_ITEM
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK TABLES PF_HEAD STRUCTURE I_HEAD.
  DATA: PF_PRODINF LIKE ZSD_FDMS OCCURS 0 WITH HEADER LINE.
*<-I190905
  PERFORM GET_PROD_INFO_FROM_FDMS TABLES  I_ITEM
                                          PF_PRODINF.
*->I190905
  LOOP AT PF_HEAD.
    PERFORM GET_ITEM_REMARK_FREE      TABLES  PF_PRODINF    "I190905
                                      USING   PF_HEAD.
    PERFORM GET_ITEM_REMARK_PACKING   TABLES  PF_PRODINF    "I190905
                                      USING   PF_HEAD.
    PERFORM GET_ITEM_REMARK_INVOICE   TABLES  PF_PRODINF    "I190905
                                      USING   PF_HEAD.
    PERFORM GET_ITEM_REMARK_CRDMEMO   USING   PF_HEAD.
    PERFORM GET_ITEM_REMARK_DEDMEMO   USING   PF_HEAD.
    PERFORM GET_ITEM_REMARK_PROFORMA  USING   PF_HEAD.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_REMARK
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_PACKING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK_PACKING  TABLES  PF_PINF_I STRUCTURE ZSD_FDMS
                              USING   PFWA_HEAD STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'P'.                                                                    "P = Packing
***REMARK
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING 'Remark:'
                                     PFWA_HEAD-VGBEL
                                     PFWA_HEAD-ZTYPE
                                     ''.
***SALES ORDER
  PERFORM GET_SO_LIST USING PFWA_HEAD-VGBEL
                            PFWA_HEAD-ZTYPE
                            PFWA_HEAD-ZMTSO.

***特殊需求
  PERFORM SP_RULE_FOR_REMARK01 USING PFWA_HEAD.

***CUST. PO NO.
  PERFORM GET_CUST_PO USING PFWA_HEAD-VGBEL
                            PFWA_HEAD-ZTYPE.

***取得SO中的LONG-TEXT
  PERFORM SP_RULE_FOR_REMARK_OTEXT USING PFWA_HEAD-VGBEL
                                         PFWA_HEAD-ZTYPE
                                         ''.

***取得WAFER ID(小於25片才要顯示)
  PERFORM GET_WAFER_ID USING PFWA_HEAD-VGBEL
                             PFWA_HEAD-ZTYPE
                             PFWA_HEAD-KUNAG
                             PFWA_HEAD-PRODTYPE.

*<-I160622
***取得GROSS DIE的資訊
  PERFORM GET_GROSS_DIE_INFO TABLES I_ITEM
                                    PF_PINF_I               "I190905
                             USING  PFWA_HEAD.

*->I160622
***Die 計價要顯示Good die , Bad die & Wafer 片數(PFWA_HEAD-PRODTYPE = 'D')
  PERFORM GET_DIE_WAFER_QTY USING PFWA_HEAD-PRODTYPE
                                  PFWA_HEAD-VBELN
                                  PFWA_HEAD-ZTYPE.

***Spcial rule by customer in remakr
  PERFORM SP_RULE_IN_REMAKR_CUST USING PFWA_HEAD.

***SHIPPING REMARK
  PERFORM GET_SHIPPING_REMARK USING PFWA_HEAD-VGBEL
                                    PFWA_HEAD-VBELN
                                    PFWA_HEAD-ZTYPE.



***Trade term
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VGBEL
                               PFWA_HEAD-ZTYPE.
***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VGBEL
                              PFWA_HEAD-ZTYPE.

***放行單號及日期
  PERFORM GET_RELEASE_INFO USING  PFWA_HEAD-VGBEL
                                  PFWA_HEAD-ZTYPE
                                  PFWA_HEAD-RELNO
                                  PFWA_HEAD-CDATE.

***關務CALL時才會出現的MESSAGE
  PERFORM IMEX_GET_REMARK_INFO TABLES I_ITEM
                               USING  PFWA_HEAD.

***pallet INFO
  PERFORM GET_PALLET_INFO USING PFWA_HEAD-VGBEL
                                PFWA_HEAD-ZTYPE.

***good/bad die list for each wafer(當PFWA_HEAD-PRODTYPE = 'D'或'W'才會RUN)
  PERFORM GET_WAFER_DIE_LIST USING PFWA_HEAD.

***產生三行空白行
  PERFORM GET_BLANK_ROW USING PFWA_HEAD-VGBEL
                              PFWA_HEAD-ZTYPE
                              3.

***SHIP MARK(另外以一個TABLE處理)
  PERFORM GET_SHIPPING_MARK_INFO USING PFWA_HEAD.

***Special rule for Packing remakr
  PERFORM SP_RULE_FOR_PACKING_RMK TABLES  I_ITEM_RE
                                  USING   PFWA_HEAD.

ENDFORM.                    " GET_ITEM_REMARK_PACKING

*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_PACKING02
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_PACKING02 TABLES  PF_ITEM_IO    STRUCTURE I_ITEM
                             USING   PFWA_HEAD  STRUCTURE I_HEAD.
  DATA: PFV_ITMNO(4)  TYPE N,
        PFV_CASNO(4)  TYPE N,
        PFV_VENUM     TYPE VENUM,
        PFV_UEVEL     TYPE UEVEL.


  CHECK PFWA_HEAD-ZTYPE = 'P'.                  "P = Packing

  CLEAR: PFV_ITMNO, PFV_CASNO.
  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD-VGBEL
                     AND   ZTYPE = PFWA_HEAD-ZTYPE.
    ADD 1 TO PFV_ITMNO.
    PF_ITEM_IO-ITMNO = PFV_ITMNO.
***處理多筆PALLET的資料顯示
    IF PF_ITEM_IO-UEVEL <> ''        AND
       PF_ITEM_IO-UEVEL <> PFV_UEVEL.
      CLEAR: PFV_UEVEL.
      PFV_UEVEL = PF_ITEM_IO-UEVEL.
    ELSE.
      CLEAR: PF_ITEM_IO-PALNO, PF_ITEM_IO-DPBRG, PF_ITEM_IO-DPNTG, PF_ITEM_IO-PDIME.    "只顯示第一筆,其他不顯示
    ENDIF.
***處理多筆CARTON的資料顯示
    IF PF_ITEM_IO-VENUM <> PFV_VENUM.
      ADD 1 TO PFV_CASNO.
      PF_ITEM_IO-CASNO = PFV_CASNO.                                                     "CASE NO.
      CLEAR: PFV_VENUM.
      PFV_VENUM = PF_ITEM_IO-VENUM.
    ELSE.
      CLEAR: PF_ITEM_IO-CTNNO, PF_ITEM_IO-DNTGE, PF_ITEM_IO-DBRGE, PF_ITEM_IO-CDIME.    "只顯示第一筆,其他不顯示
    ENDIF.
    MODIFY PF_ITEM_IO.
    CLEAR: PF_ITEM_IO.
  ENDLOOP.

**以下為決定把第一筆放CARTON的位置改到PALLET,應該不需要使用
*  LOOP AT I_ITEM WHERE DBRGE <> ''.
*    IF I_ITEM-DPBRG = ''.
*      I_ITEM-DPBRG = I_ITEM-DBRGE.
*      I_ITEM-PDIME = I_ITEM-CDIME.
*
*      CLEAR: I_ITEM-DBRGE, I_ITEM-CDIME.
*      MODIFY I_ITEM.
*    ENDIF.
*  ENDLOOP.

ENDFORM.                    " GET_ITEM_DATA_PACKING02
*&---------------------------------------------------------------------*
*&      Form  APPEND_DATA_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_RE  text
*      -->P_3846   text
*      -->P_I_HEAD_VGBEL  text
*----------------------------------------------------------------------*
FORM APPEND_DATA_REMARK  TABLES   PF_ITEM_RK STRUCTURE I_ITEM_RE
                         USING    PFV_REMAK
                                  PFV_VBELN
                                  PFV_ZTYPE
                                  PFV_RMKTYPE.      "remark type

  PF_ITEM_RK-VBELN   = PFV_VBELN.
  PF_ITEM_RK-REMRK   = PFV_REMAK.
  PF_ITEM_RK-ZTYPE   = PFV_ZTYPE.
  PF_ITEM_RK-ZRTYPE  = PFV_RMKTYPE.

  APPEND PF_ITEM_RK.
  CLEAR  PF_ITEM_RK.
ENDFORM.                    " APPEND_DATA_REMARK
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_REMARK01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_REMARK01 USING PFWA_HEAD_I STRUCTURE I_HEAD.

  DATA: BEGIN OF PF_COUNT OCCURS 0,
          POSNR LIKE VBRP-POSNR,
          KDMAT LIKE LIPS-KDMAT,
          UNITP LIKE KOMV-KBETR,
          KWERT LIKE KOMV-KBETR,
          WAERK LIKE VBRK-WAERK,
        END OF PF_COUNT.

  DATA: BEGIN OF PF_UBIQ OCCURS 0,
          CHARG       LIKE LIPS-CHARG,
          WAFER(100)  TYPE C,
        END OF PF_UBIQ.

  DATA: PF_LINES        LIKE TLINE  OCCURS 0 WITH HEADER LINE,
        PFWA_VBRK       LIKE VBRK,
        PFWA_LIKP       LIKE LIKP,
        PFV_REMAK(300)  TYPE C,
        PFV_KURRF(14)   TYPE C,
        PFV_STR01(04)   TYPE C,
        PFV_STR02(99)   TYPE C,
        PFV_UNITP       TYPE ZAMTDEC4,
        PFV_VALUE(13)   TYPE C,
        PFV_CHARG       TYPE CHARG_D,
        PFV_ASNNO(21)   TYPE C.



  CASE PFWA_HEAD_I-KUNAG.
    WHEN '0000003093'.                          "LG
      CHECK PFWA_HEAD_I-ZTYPE = 'I' OR          "I = Invoice
            PFWA_HEAD_I-ZTYPE = 'F'.            "F = Free Invoice
      CLEAR: PF_COUNT, PF_COUNT[].

      LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                     AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
        CHECK ( I_ITEM-ZTYPE = 'I' AND          "I = Invoice
                I_ITEM-PSTYV = 'TANN' ) OR
                I_ITEM-ZTYPE = 'F'.             "F = Free Invoice
        PF_COUNT-POSNR = I_ITEM-POSNR.
        PF_COUNT-KDMAT = I_ITEM-KDMAT.
        PF_COUNT-WAERK = I_ITEM-WAERK.
        CALL FUNCTION 'ZSD_REF_UNITPRICE'
          EXPORTING
            VBELN  = I_ITEM-VBELN
            POSNR  = I_ITEM-POSNR
          IMPORTING
            REF_UP = PFV_UNITP.
        IF PFV_UNITP IS INITIAL.
          PFV_UNITP = I_ITEM-UNITP.
        ENDIF.
        PF_COUNT-UNITP = PFV_UNITP.
        PF_COUNT-KWERT = PFV_UNITP * I_ITEM-DWEMN.
        APPEND PF_COUNT.
        CLEAR: PF_COUNT.
      ENDLOOP.
      LOOP AT PF_COUNT.
        CLEAR: PFV_REMAK, PFV_VALUE.

        AT FIRST.
          PFV_REMAK+2 = '**'.
        ENDAT.
        WRITE PF_COUNT-UNITP CURRENCY PF_COUNT-WAERK TO PFV_VALUE.
        CONCATENATE PF_COUNT-KDMAT ':CUSTOMER REFERENCE VALUE:' PF_COUNT-WAERK PFV_VALUE
          INTO PFV_REMAK+5 SEPARATED BY SPACE.
        CONCATENATE PFV_REMAK '/PC,TOTAL CUSTOMER REFERENCE VALUE:'
          INTO PFV_REMAK.
        CLEAR: PFV_VALUE.
        WRITE PF_COUNT-KWERT CURRENCY PF_COUNT-WAERK TO PFV_VALUE.
        CONCATENATE PFV_REMAK PF_COUNT-WAERK PFV_VALUE INTO PFV_REMAK SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD_I-VBELN
                                            PFWA_HEAD_I-ZTYPE
                                            ''.
      ENDLOOP.
*->I140428
    WHEN '0000002014'.                          "綠星
      PERFORM GET_WORKAREA_VBRK USING     PFWA_HEAD_I-VBELN
                                CHANGING  PFWA_VBRK.
      CHECK PFWA_VBRK IS NOT INITIAL.
      CLEAR: PFV_KURRF.
      PFV_KURRF = PFWA_VBRK-KURRF.
      CONCATENATE 'Exchange rate:' PFV_KURRF
        INTO PFV_REMAK+2.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD_I-VBELN
                                          PFWA_HEAD_I-ZTYPE
                                          ''.

    WHEN '0000000707'.                          "晶豪
      LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                     AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
        PERFORM GET_LONG_TEXT TABLES PF_LINES
                              USING  I_ITEM-AUBEL
                                     'ZQH2'
                                     'VBBK'.
        READ TABLE PF_LINES INDEX 1.
        CHECK SY-SUBRC = 0.
        PFV_STR01 = PF_LINES-TDLINE+0(4).
        TRANSLATE PFV_STR01 TO UPPER CASE.
        CHECK PFV_STR01 = 'GUI:'.
        SPLIT PF_LINES-TDLINE AT ':' INTO PFV_STR01 PFV_STR02.
        CLEAR: PFV_REMAK.
        PFV_REMAK+2 = PFV_STR02.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD_I-VBELN
                                            PFWA_HEAD_I-ZTYPE
                                            ''.

      ENDLOOP.
*    WHEN '0000003574' OR                        "Fairchild
*         '0000003723' OR
*         '0000003724' OR
*         '0000003739' OR
*         '0000003811'.
*      CHECK P_JOBTPS <> 'N'.
*      CLEAR: PFV_REMAK.
*      IF PFWA_HEAD_I-ZTYPE = 'P' OR             "P = Packing
*         PFWA_HEAD_I-ZTYPE = 'I' OR             "I = Invoice
*         PFWA_HEAD_I-ZTYPE = 'F'.               "F = Free Invoice
*        PERFORM GET_ASNNO_FOR_ONSEMI USING    PFWA_HEAD_I-VBELN
*                                     CHANGING PFV_ASNNO.
*        IF PFV_ASNNO IS INITIAL.
*          MESSAGE I000 WITH PFWA_HEAD_I-VBELN '此Packing / Invoice 的ASN No.還沒有產生,請留意!!'.
*        ELSE.
*          CONCATENATE '** ASN No. :' PFV_ASNNO
*            INTO PFV_REMAK+2 SEPARATED BY SPACE.
*          PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
*                                      USING   PFV_REMAK
*                                              PFWA_HEAD_I-VBELN
*                                              PFWA_HEAD_I-ZTYPE
*                                              ''.
*        ENDIF.
*      ENDIF.
*      CLEAR: PFV_REMAK.
*      CHECK PFWA_HEAD_I-ZTYPE = 'I' OR          "I = Invoice
*            PFWA_HEAD_I-ZTYPE = 'F'.            "F = Free Invoice
*      PFV_REMAK+2 = '** Substrate USD＄ 54/PC'.
*      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
*                                  USING   PFV_REMAK
*                                          PFWA_HEAD_I-VBELN
*                                          PFWA_HEAD_I-ZTYPE
*                                          ''.
    WHEN '0000002644'.         "ON-SEMI
      CLEAR: PFV_REMAK.
      CHECK PFWA_HEAD_I-ZTYPE = 'P' OR          "P = Packing
            PFWA_HEAD_I-ZTYPE = 'I'.            "I = Invoice

      PERFORM GET_ASNNO_FOR_ONSEMI USING    PFWA_HEAD_I
                                   CHANGING PFV_ASNNO.
      CHECK PFV_ASNNO IS NOT INITIAL.
      CONCATENATE '** ASN No. :' PFV_ASNNO
        INTO PFV_REMAK+2 SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD_I-VBELN
                                          PFWA_HEAD_I-ZTYPE
                                          ''.
    WHEN '0000003055'.                          "UBIQ
      CHECK PFWA_HEAD_I-ZTYPE = 'P'.            "P = Packing
      LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                     AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
        CLEAR: PF_UBIQ, PFV_CHARG.
        PFV_CHARG = I_ITEM-CHARG+0(06).
        CALL FUNCTION 'ZECMS_GET_UBIQ_DATA'
          EXPORTING
            IV_CHARG = PFV_CHARG
            IV_DBCON = 'ECMS_PRD'
          IMPORTING
            EV_CHARG = PF_UBIQ-CHARG
            EV_WAFER = PF_UBIQ-WAFER.

        CHECK PF_UBIQ-CHARG IS NOT INITIAL AND PF_UBIQ-WAFER IS NOT INITIAL.
        APPEND PF_UBIQ.
      ENDLOOP.

      CHECK PF_UBIQ[] IS NOT INITIAL.

      CLEAR: PFV_REMAK.
      PFV_REMAK+2 = '** 工程LOT :'.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD_I-VBELN
                                          PFWA_HEAD_I-ZTYPE
                                          ''.
      LOOP AT PF_UBIQ.
        CLEAR: PFV_REMAK.
        CONCATENATE  PF_UBIQ-CHARG ':' PF_UBIQ-WAFER
              INTO PFV_REMAK+5 SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD_I-VBELN
                                            PFWA_HEAD_I-ZTYPE
                                            ''.
      ENDLOOP.
    WHEN '0000003620' OR                        "量宏(Invisage)
         '0000003966'.
      CHECK PFWA_HEAD_I-ZTYPE = 'I'.            "I = Invoice
      CLEAR: PFV_REMAK.
      PFV_REMAK+2 = '** Process materials and service'.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD_I-VBELN
                                          PFWA_HEAD_I-ZTYPE
                                          ''.
*<-I200710
    WHEN '0000004083' OR                        "江蘇長晶
         '0000004197'.                          "香港長電
      CLEAR: PFV_REMAK.
      IF PFWA_HEAD_I-ZTYPE = 'I'.
        PERFORM GET_WORKAREA_VBRK USING     PFWA_HEAD_I-VBELN
                                  CHANGING  PFWA_VBRK.
        CHECK PFWA_VBRK-ZBONDTY_B = 'Y'.
      ENDIF.
      IF PFWA_HEAD_I-ZTYPE = 'F' OR
         PFWA_HEAD_I-ZTYPE = 'P'.
        PERFORM GET_WORKAREA_LIKP USING     PFWA_HEAD_I-VBELN
                                  CHANGING  PFWA_LIKP.
        CHECK PFWA_LIKP-ZBONDTY = 'Y'.
      ENDIF.
      PFV_REMAK+2 = '** B2 按月彙報'.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD_I-VBELN
                                          PFWA_HEAD_I-ZTYPE
                                          ''.
*->I200710
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " SPECIAL_RULE_FOR_REMARK01
*&---------------------------------------------------------------------*
*&      Form  GET_SHIPPING_MARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_KUNNR  text
*      <--P_V_NAME1  text
*      <--P_V_ORT01  text
*      <--P_V_PALLE  text
*      <--P_V_CARTO  text
*----------------------------------------------------------------------*
FORM GET_SHIPPING_MARK  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                        CHANGING PFV_NAME1_O
                                 PFV_ORT01_O
                                 PFV_PALLE_O
                                 PFV_CARTO_O.
  DATA: PFWA_KNA1   LIKE KNA1,
        PFWA_VBPA   LIKE VBPA,
        PFWA_ZSD63  LIKE ZSD63,
        PFWA_T005T  LIKE T005T,
        PFV_VGBEL   TYPE VBELN_VL,
        PFV_REVIS   TYPE C,
        N_FIRST(10) TYPE C,
        N_SECON(10) TYPE C,
        PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_NAME1_O, PFV_ORT01_O, PFV_PALLE_O, PFV_CARTO_O, PFV_REVIS, PFV_VGBEL.
  PERFORM GET_WORKAREA_VBPA USING     PFWA_HEAD_I-VBELN
                                      '000000'
                            CHANGING  PFWA_VBPA.

  IF PFWA_VBPA IS NOT INITIAL.
    PERFORM GET_WORKAREA_KNA1 USING     PFWA_VBPA-KUNNR
                              CHANGING  PFWA_KNA1.
  ELSE.
    PERFORM GET_WORKAREA_KNA1 USING     PFWA_HEAD_I-KUNNR
                              CHANGING  PFWA_KNA1.
  ENDIF.
  PFV_NAME1_O = PFWA_KNA1-NAME1.
  PERFORM SP_RULE_FOR_CUSTFULLNAME USING    PFWA_HEAD_I
                                   CHANGING PFV_NAME1_O.
*處理有REVERSE的
  PERFORM GET_WORKAREA_ZSD63 USING    PFWA_HEAD_I-VBELN
                             CHANGING PFWA_ZSD63.
  IF PFWA_ZSD63-REV_NAME1 IS NOT INITIAL.
    PFV_NAME1_O = PFWA_ZSD63-REV_NAME1.
    PFV_REVIS = 'X'.
  ENDIF.

******下面這段是認定DN SHIP-TO是同一個地點,所以取那張SO都是正確的
  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                 AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
    CHECK I_ITEM-VBELN <> PFV_VGBEL.
    PFV_VGBEL = I_ITEM-VBELN.
    PERFORM GET_LONG_TEXT TABLES PF_LINES
                          USING  I_ITEM-AUBEL
                                 '0005'
                                 'VBBK'.
    READ TABLE PF_LINES INDEX 1.
    CHECK PF_LINES-TDLINE IS INITIAL.
    CHECK PFV_REVIS IS INITIAL.
    CASE PFWA_KNA1-LAND1.
      WHEN 'TW'.
        PFV_ORT01_O = PFWA_KNA1-ORT01.
      WHEN OTHERS.
        PERFORM GET_WORKAREA_T005T USING    PFWA_KNA1-LAND1
                                   CHANGING PFWA_T005T.
        CHECK PFWA_T005T IS NOT INITIAL.
        PFV_ORT01_O = PFWA_T005T-LANDX.
    ENDCASE.
  ENDLOOP.

  CLEAR: N_FIRST, N_SECON.
  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                 AND   ZTYPE = PFWA_HEAD_I-ZTYPE
                 AND   PALNO <> ''.
    SPLIT I_ITEM-PALNO AT '/' INTO N_FIRST N_SECON.
  ENDLOOP.

  IF N_SECON <> ''.
    CONCATENATE '1' '-' N_SECON INTO PFV_PALLE_O SEPARATED BY SPACE.
  ENDIF.

  IF PFV_PALLE_O IS INITIAL.
    CLEAR: N_FIRST, N_SECON.

    LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD_I-VBELN
                   AND   ZTYPE = PFWA_HEAD_I-ZTYPE
                   AND CTNNO <> ''.
      SPLIT I_ITEM-CTNNO AT '/' INTO N_FIRST N_SECON.
    ENDLOOP.
  ENDIF.

  IF N_SECON IS NOT INITIAL.
    CONCATENATE '1' '-' N_SECON INTO PFV_CARTO_O SEPARATED BY SPACE.
  ENDIF.

*032221-->I
  PERFORM SP_RULE_FOR_SHIPPING_MARK USING     PFWA_HEAD_I
                                              N_SECON
                                    CHANGING  PFV_CARTO_O.


ENDFORM.                    " GET_SHIPPING_MARK
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_TOTAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_TOTAL TABLES PF_HEAD STRUCTURE I_HEAD.
  LOOP AT PF_HEAD.
    PERFORM GET_ITEM_TOTAL_FREE     USING PF_HEAD.
    PERFORM GET_ITEM_TOTAL_PACKING  USING PF_HEAD.
    PERFORM GET_ITEM_TOTAL_INVCRD   USING PF_HEAD.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_TOTAL
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_TOTAL_PACKING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_TOTAL_PACKING USING PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PFV_TBRGE     LIKE VEKP-BRGEW,                                                            "CARTON GROSS WEIGHT
        PFV_TNTGE     LIKE VEKP-NTGEW,                                                            "CARTON NET WEIGHT
        PFV_TPBRG     LIKE VEKP-BRGEW,                                                            "PALLET GROSS WEIGHT
        PFV_TPNTG     LIKE VEKP-NTGEW,                                                            "PALLET NET WEIGHT
        PFV_TCEMN(10) TYPE C,
        PFV_TWEMN(10) TYPE C,
        PFV_TLAEN(10) TYPE C,
        PFV_PLAEN(10) TYPE C,
        PFV_PBREI(10) TYPE C,
        PFV_PHOEH(10) TYPE C,
        PFV_NUMBE     TYPE P DECIMALS 1,
        PFV_NUMB1     TYPE P DECIMALS 2.
  CHECK PFWA_HEAD-ZTYPE = 'P'.                                                                    "P = Packing

  CLEAR: PFV_TBRGE.
  CLEAR: PFV_TCEMN, PFV_TWEMN, PFV_TPNTG, PFV_TPBRG, PFV_TNTGE, PFV_TBRGE, PFV_TLAEN.
  I_ITEM_TO-VBELN = PFWA_HEAD-VGBEL.
  I_ITEM_TO-ZTYPE = PFWA_HEAD-ZTYPE.
  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD-VGBEL
                 AND   ZTYPE = PFWA_HEAD-ZTYPE.
    PFV_TCEMN = I_ITEM-DCEMN + PFV_TCEMN.
    PFV_TWEMN = I_ITEM-DWEMN + PFV_TWEMN.
    PFV_TPNTG = I_ITEM-DPNTG + PFV_TPNTG.                                                         "PALLET NET WEIGHT
    PFV_TPBRG = I_ITEM-DPBRG + PFV_TPBRG.                                                         "PALLET GROSS WEIGHT
    PFV_TNTGE = I_ITEM-DNTGE + PFV_TNTGE.                                                         "CARTON NET WEIGHT
    PFV_TBRGE = I_ITEM-DBRGE + PFV_TBRGE.                                                         "CARTON GROSS WEIGHT
    CLEAR: PFV_PLAEN, PFV_PBREI, PFV_PHOEH.
    CONDENSE I_ITEM-PDIME NO-GAPS.
    SPLIT I_ITEM-PDIME AT 'X'
      INTO PFV_PLAEN PFV_PBREI PFV_PHOEH.
    PFV_TLAEN = PFV_TLAEN + ( PFV_PLAEN * PFV_PBREI * PFV_PHOEH / 6000 ).                         "計算PALLET的尺寸
  ENDLOOP.

  I_ITEM_TO-TCEMN = PFV_TCEMN.
  I_ITEM_TO-TWEMN = PFV_TWEMN.
*<-I151231
  I_ITEM_TO-TPNTG = PFV_TPNTG.
  I_ITEM_TO-TPBRG = PFV_TPBRG.
  I_ITEM_TO-TNTGE = PFV_TNTGE.
  I_ITEM_TO-TBRGE = PFV_TBRGE.
*->I151231
*<-D151231
*  CLEAR: PFV_NUMBE.
*  PFV_NUMBE = PFV_TPNTG.
*  I_ITEM_TO-TPNTG = PFV_NUMBE.                                                                    "PALLET NET WEIGHT
*  CLEAR: PFV_NUMBE.
*  PFV_NUMBE = PFV_TPBRG.
*  I_ITEM_TO-TPBRG = PFV_NUMBE.                                                                    "PALLET GROSS WEIGHT
*  CLEAR: PFV_NUMBE.
*  PFV_NUMBE = PFV_TNTGE.
*  I_ITEM_TO-TNTGE = PFV_NUMBE.                                                                    "CARTON NET WEIGHT
*  CLEAR: PFV_NUMBE.
*  PFV_NUMBE = PFV_TBRGE.
*  I_ITEM_TO-TBRGE = PFV_NUMBE.                                                                    "CARTON GROSS WEIGHT
*->D151231
  IF PFV_TLAEN = 0. "表示沒有PALLET
    LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD-VGBEL
                   AND   ZTYPE = PFWA_HEAD-ZTYPE.
      CLEAR: PFV_PLAEN, PFV_PBREI, PFV_PHOEH.
      CONDENSE I_ITEM-CDIME NO-GAPS.
      SPLIT I_ITEM-CDIME AT 'X'
        INTO PFV_PLAEN PFV_PBREI PFV_PHOEH.
      PFV_TLAEN = PFV_TLAEN + ( PFV_PLAEN * PFV_PBREI * PFV_PHOEH / 6000 ).
    ENDLOOP.
  ENDIF.
  CLEAR: PFV_NUMB1.
  PFV_NUMB1 = PFV_TLAEN.
  I_ITEM_TO-TLAEN = PFV_NUMB1.
***清空0的欄位
  IF I_ITEM_TO-TCEMN = 0.
    I_ITEM_TO-TCEMN = ''.
  ENDIF.

  IF I_ITEM_TO-TWEMN = 0.
    I_ITEM_TO-TWEMN = ''.
  ENDIF.

  APPEND I_ITEM_TO.
  CLEAR: I_ITEM_TO.
ENDFORM.                    " GET_ITEM_TOTAL_PACKING

*&---------------------------------------------------------------------*
*&      Form  WRITE_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_INFO TABLES PF_HEAD STRUCTURE I_HEAD.
  DATA: PFV_PVBEL TYPE VBELN_VF,
        PFV_CHECK TYPE C.                                                                         "核取方塊

  PFV_CHECK = 'X'.

  CLEAR: O_HEAD, O_HEAD[].
  APPEND LINES OF PF_HEAD TO O_HEAD.
  LOOP AT PF_HEAD.
    PERFORM GET_PINO_TO_WRITE TABLES    I_ITEM_PIITEM
                              USING     PF_HEAD
                              CHANGING  PFV_PVBEL.
    CASE PF_HEAD-ZTYPE.
      WHEN 'P'.                                 "P = Packing
        FORMAT COLOR 5 INTENSIFIED OFF.
      WHEN 'C'.                                 "C = Credit Memo
        FORMAT COLOR 7 INTENSIFIED OFF.
      WHEN 'D'.                                 "D = Debit Memo / L2
        FORMAT COLOR 3 INTENSIFIED OFF.
      WHEN OTHERS.
    ENDCASE.
    IF P_JOBTPS = 'N' OR                        "N = IMEX
       P_JOBTPS = 'I'.                          "I = call by 財務  I021220
      WRITE: / 'X' ,
               (10) PF_HEAD-ZTYPE  CENTERED,
               (10) PF_HEAD-VBELN  LEFT-JUSTIFIED,
               (10) PF_HEAD-BKUNN  LEFT-JUSTIFIED,
               (10) PF_HEAD-KUNAG  LEFT-JUSTIFIED,
               (10) PF_HEAD-KUNNR  LEFT-JUSTIFIED,
               (17) PF_HEAD-ERDAT  LEFT-JUSTIFIED,
               (10) PFV_PVBEL      CENTERED.
    ELSE.
      WRITE: / PFV_CHECK AS CHECKBOX ,
               (10) PF_HEAD-ZTYPE  CENTERED,
               (10) PF_HEAD-VBELN  LEFT-JUSTIFIED,
               (10) PF_HEAD-BKUNN  LEFT-JUSTIFIED,
               (10) PF_HEAD-KUNAG  LEFT-JUSTIFIED,
               (10) PF_HEAD-KUNNR  LEFT-JUSTIFIED,
               (17) PF_HEAD-ERDAT  LEFT-JUSTIFIED,
               (10) PFV_PVBEL      CENTERED.
    ENDIF.
    FORMAT RESET INTENSIFIED ON.
  ENDLOOP.
ENDFORM.                    " WRITE_INFO
*&---------------------------------------------------------------------*
*&      Form  SEND_TO_SMARTFORM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0872   text
*----------------------------------------------------------------------*
FORM SEND_TO_SMARTFORM USING PF_TYPE
                             PF_SFEND.
*Backup dtat using
  DATA: PFBK_HEAD LIKE I_HEAD OCCURS 0 WITH HEADER LINE,
        PFBK_ITEM LIKE I_ITEM OCCURS 0 WITH HEADER LINE.

  DATA: L_FM_NAME             TYPE RS38L_FNAM,
        WA_CONTROL_PARAMETERS TYPE SSFCTRLOP,           "SMARTFORM控制參數
        WA_OUTPUT_OPT         TYPE SSFCOMPOP,           "SMARTFORM打印時的參數
        WA_JOB_OUTPUT_INFO    TYPE SSFCRESCL,           "SMARTFORM傳出資料的值
        P_OTFDATA             TYPE TSFOTF.

*-Backup up data
  CLEAR: PFBK_HEAD, PFBK_HEAD[], PFBK_ITEM, PFBK_ITEM[].
  APPEND LINES OF I_HEAD TO PFBK_HEAD.
  APPEND LINES OF I_ITEM TO PFBK_ITEM.
**針對文件的顯示和存檔時不同時使用(如MAXIM要換LOT及BATCH值)
  PERFORM SP_RULE_FOR_DOC_DISPLAY TABLES I_HEAD
                                         I_ITEM.
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME                 = 'ZSD_SF005'
*     VARIANT                  = ' '
*     DIRECT_CALL              = ' '
    IMPORTING
      FM_NAME                  = L_FM_NAME
*   EXCEPTIONS
*     NO_FORM                  = 1
*     NO_FUNCTION_MODULE       = 2
*     OTHERS                   = 3
            .
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CLEAR: WA_CONTROL_PARAMETERS, WA_OUTPUT_OPT, WA_JOB_OUTPUT_INFO.
  WA_CONTROL_PARAMETERS-PREVIEW   = 'X'.
  WA_CONTROL_PARAMETERS-LANGU     = 'M'.
  WA_CONTROL_PARAMETERS-NO_DIALOG = 'X'.
  WA_OUTPUT_OPT-TDDEST            = 'LOCL'.
  WA_OUTPUT_OPT-TDIMMED           = 'X'.



  CASE PF_TYPE.
    WHEN 'EML' OR 'FTP' OR 'FILE'.
      WA_OUTPUT_OPT-TDDEST            = 'ZPDF'.
      WA_CONTROL_PARAMETERS-PREVIEW   = ''.
      WA_CONTROL_PARAMETERS-GETOTF    = 'X'.
    WHEN 'PDF'.
      WA_OUTPUT_OPT-TDNEWID           = 'X'.
      WA_OUTPUT_OPT-TDIMMED           = ''.
      WA_OUTPUT_OPT-TDDEST            = 'ZPDF'.
      WA_CONTROL_PARAMETERS-PREVIEW   = ''.
      WA_CONTROL_PARAMETERS-GETOTF    = 'X'.
    WHEN OTHERS.
  ENDCASE.

  CASE P_JOBTPS.
    WHEN 'N' OR
         'E'.
      IF IMEX_ITEM[] IS NOT INITIAL.
        WA_CONTROL_PARAMETERS-NO_OPEN   = 'X'.
        WA_CONTROL_PARAMETERS-NO_CLOSE  = ''.
        WA_OUTPUT_OPT-TDNEWID           = ''.
      ENDIF.
    WHEN 'B'.
      PERFORM GET_SSF_PARAMETER USING     PF_SFEND
                                CHANGING  WA_CONTROL_PARAMETERS-NO_CLOSE
                                          WA_CONTROL_PARAMETERS-NO_OPEN
                                          WA_OUTPUT_OPT-TDNEWID.
    WHEN 'Q'.               "Call from QOM
      CLEAR WA_CONTROL_PARAMETERS-PREVIEW.
    WHEN OTHERS.
      CLEAR: I_OTFS, I_OTFS[].
  ENDCASE.


  CALL FUNCTION L_FM_NAME
    EXPORTING
      CONTROL_PARAMETERS = WA_CONTROL_PARAMETERS
      OUTPUT_OPTIONS     = WA_OUTPUT_OPT
      USER_SETTINGS      = ''
      I_CPROG            = SY-CPROG
      I_SINFG            = C_SIGFG              "決定是否要印簽名欄位
      I_L2TIL            = C_L2T
    IMPORTING
      JOB_OUTPUT_INFO    = WA_JOB_OUTPUT_INFO
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.

*-Recovery data
  CLEAR: I_HEAD, I_HEAD[], I_ITEM, I_ITEM[].
  APPEND LINES OF PFBK_HEAD TO I_HEAD.
  APPEND LINES OF PFBK_ITEM TO I_ITEM.
  CASE PF_TYPE.
    WHEN 'GEN'.
    WHEN 'PDF'.
      APPEND LINES OF WA_JOB_OUTPUT_INFO-OTFDATA TO I_OTFS.
      CALL FUNCTION 'SSFCOMP_PDF_PREVIEW'
         EXPORTING
           I_OTF                          = I_OTFS
*        EXCEPTIONS
*          CONVERT_OTF_TO_PDF_ERROR       = 1
*          CNTL_ERROR                     = 2
*          OTHERS                         = 3
                 .
      IF SY-SUBRC <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    WHEN 'FTP' OR 'EML' OR 'FILE'.
      APPEND LINES OF WA_JOB_OUTPUT_INFO-OTFDATA TO P_OTFDATA.

      PERFORM GENERATE_FILES  TABLES P_OTFDATA
                              USING  PF_TYPE.
      CHECK P_JOBTPS = 'E' OR                               "I190111
            P_JOBTPS = 'T'.
      APPEND LINES OF WA_JOB_OUTPUT_INFO-OTFDATA TO I_OTFS. "I190111
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " SEND_TO_SMARTFORM

*&---------------------------------------------------------------------*
*&      Form  GET_LC_TERMS_SHVIA_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIKP_VBELN  text
*      -->P_I_LIKP_INCO1  text
*      -->P_I_LIKP_INCO2  text
*      -->P_I_HEAD_AUBEL  text
*      -->P_1610   text
*      <--P_I_HEAD_LCNUM  text
*----------------------------------------------------------------------*
FORM GET_LC_TERMS_SHVIA_INFO  USING    PFV_VBELN_I
                                       PFV_INCO1_I
                                       PFV_INCO2_I
                                       PFV_AUBEL_I
                                       PFV_TYPES_I
                              CHANGING PFV_RDATA_O.
  DATA: PFV_CODES(04) TYPE C,
        PFV_OBJET     TYPE TDOBJECT,
        PFV_ZVBEL     TYPE VBELN_VL,
        PF_LINES      LIKE TLINE  OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_CODES, PFV_OBJET, PFV_ZVBEL, PFV_RDATA_O.
  PFV_OBJET =  'VBBK'.
  CASE PFV_TYPES_I.
    WHEN 'LCNO'.
      PFV_CODES = 'Z011'.
      PFV_ZVBEL = PFV_AUBEL_I.
    WHEN 'TERM'.
      PFV_CODES = 'Z012'.
      PFV_ZVBEL = PFV_VBELN_I.
    WHEN 'DEST'.
      PFV_CODES = '0005'.
      PFV_ZVBEL = PFV_AUBEL_I.
    WHEN 'FTER'.
      PFV_CODES = '0004'.
      PFV_ZVBEL = PFV_AUBEL_I.
    WHEN OTHERS.
  ENDCASE.

  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_ZVBEL
                               PFV_CODES
                               PFV_OBJET.

  READ TABLE PF_LINES INDEX 1.
  IF SY-SUBRC = 0.
    CASE PFV_TYPES_I.
      WHEN 'LCNO' OR
           'DEST' OR
           'FTER'.
        PFV_RDATA_O =  PF_LINES-TDLINE.
      WHEN 'TERM'.
        MOVE PF_LINES-TDLINE(32) TO PFV_RDATA_O.
      WHEN OTHERS.
    ENDCASE.
    EXIT.
  ENDIF.

  CHECK PFV_TYPES_I = 'TERM'.
  CONCATENATE PFV_INCO1_I PFV_INCO2_I
    INTO PFV_RDATA_O SEPARATED BY SPACE.
ENDFORM.                    " GET_LC_TERMS_SHVIA_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIKP_VBELN  text
*      -->P_I_LIKP_KUNAG  text
*      -->P_I_LIKP_KUNNR  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_1807   text
*      <--P_I_HEAD_BKUNN  text
*----------------------------------------------------------------------*
FORM GET_CUST_NO  USING    PFV_VBELN_I
                           PFV_KUNAG_I
                           PFV_KUNNR_I
                           PFV_ZTYPE_I
                           PFV_FNCTN_I
                  CHANGING PFV_CSTID_O.
  DATA: PFWA_LIKP LIKE LIKP,
        PFWA_LIPS LIKE LIPS,
        PFV_DOCNO TYPE VBELN.

  CLEAR: PFV_DOCNO.

  IF PFV_ZTYPE_I = 'P' OR                       "P = Packing
     PFV_ZTYPE_I = 'F'.                         "F = Free Invoice
*<-I210217
    PERFORM GET_WORKAREA_LIPS USING     PFV_VBELN_I
                                        ''
                              CHANGING  PFWA_LIPS.
    PFV_DOCNO = PFWA_LIPS-VGBEL.
*->I210217
*<-D210217
*    SELECT SINGLE * FROM  LIPS
*                    WHERE VBELN =   PFV_VBELN_I
*                    AND   VGBEL <>  ''.
*    PFV_DOCNO = LIPS-VGBEL.
*->D210217
  ELSE.
    PFV_DOCNO = PFV_VBELN_I.
  ENDIF.

  CASE PFV_FNCTN_I.
    WHEN 'BILL'.
      PERFORM GET_CUST_NO_VBPA USING    PFV_DOCNO
                                        '000000'
                                        'RE'    "不是BP,它會轉換
                               CHANGING PFV_CSTID_O.

    WHEN 'SOLD'.
      PERFORM GET_CUST_NO_VBPA USING    PFV_DOCNO
                                        '000000'
                                        'ZA'
                               CHANGING PFV_CSTID_O.
      CHECK PFV_CSTID_O IS INITIAL.
      PFV_CSTID_O = PFV_KUNAG_I.
    WHEN 'SHIP'.
      IF PFV_ZTYPE_I = 'I'.                     "I = Invoice
        PERFORM GET_WORKAREA_LIKP USING     PFV_VBELN_I
                                  CHANGING  PFWA_LIKP.
        PFV_CSTID_O = PFWA_LIKP-KUNNR.
        EXIT.
      ENDIF.
      IF PFV_ZTYPE_I = 'P' OR                   "P = Packing
         PFV_ZTYPE_I = 'F'.                     "F = Free Invoice
        PFV_CSTID_O = PFV_KUNNR_I.
        EXIT.
      ENDIF.
      CHECK PFV_ZTYPE_I = 'C' OR                "C = Credit Memo
            PFV_ZTYPE_I = 'R' OR                "R = Proforma
            PFV_ZTYPE_I = 'D'.                  "D=DEBIT MEMO / L2
      PERFORM GET_CUST_NO_VBPA USING     PFV_DOCNO
                                         ''
                                         'WE'
                               CHANGING  PFV_CSTID_O.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_CUST_NO
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_FREE01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_FREE01 TABLES PF_LIPS_I    STRUCTURE LIPS
                                 PF_ITEM_O    STRUCTURE I_ITEM
                          USING  PFWA_HEAD_I  STRUCTURE I_HEAD.
  DATA: PFW_ZMWH8H LIKE ZMWH8H.                             "I101419

  CLEAR: PF_ITEM_O, PF_ITEM_O[].
  CHECK PFWA_HEAD_I-ZTYPE = 'F'.                  "F = Free Invoice
  LOOP AT PF_LIPS_I WHERE VBELN = PFWA_HEAD_I-VBELN.
    PF_ITEM_O-VBELN = PFWA_HEAD_I-VGBEL.          "(X)單號  [KEY]
    PF_ITEM_O-ZTYPE = PFWA_HEAD_I-ZTYPE.          "(X)單據類型  [KEY]
    PF_ITEM_O-KUNAG = PFWA_HEAD_I-KUNAG.          "(X)CUST NO.
    PF_ITEM_O-POSNR = PF_LIPS_I-POSNR.            "(X)ITME NO.
    PF_ITEM_O-AUBEL = PF_LIPS_I-VGBEL.            "(X)SO.
    PF_ITEM_O-AUPOS = PF_LIPS_I-VGPOS.            "(X)SO ITEM
    PF_ITEM_O-UECHA = PF_LIPS_I-UECHA.            "(X)High Level

    PF_ITEM_O-ITMNO = PF_LIPS_I-POSNR+2(4).       "ITEM編號
    PF_ITEM_O-MATNR = PF_LIPS_I-MATNR.            "MATERIAL NUMBER
    PF_ITEM_O-MWSK1 = ''.                         "CODE
    PF_ITEM_O-WERKS = PF_LIPS_I-WERKS.            "PLANT
    PF_ITEM_O-KBET1 = '0.00'.                     "DISC
    PF_ITEM_O-CHARG = PF_LIPS_I-CHARG.            "KEY NO.

**Cust PO No. + Item[VBKD-BSTKD]
    PERFORM GET_CUST_PO_INFO  USING     PF_LIPS_I-VGBEL
                                        PF_LIPS_I-VGPOS
                              CHANGING  PF_ITEM_O-BSTKD
                                        PF_ITEM_O-POSEX.  "Cust PO item no
**由SO取得資料(WAERK[Curr] / KWMEN[Qty] / KDMAT)
    PERFORM GET_DATA_VBAP_FROM_DN USING    PF_LIPS_I
                                  CHANGING PF_ITEM_O.

    CLEAR:  PF_ITEM_O-DCEMN, PF_ITEM_O-CEMEH,
            PF_ITEM_O-DWEMN, PF_ITEM_O-WEMEH.
**unit & shipping qty(DWEMN / WEMEH)
    PERFORM GET_QTY_UNIT  USING     PF_LIPS_I
                                    'FREE'
                          CHANGING  PF_ITEM_O.
**UNIT PRICE / extension / TAX (UNITP / KWERT / KBETR)
    PERFORM GET_PRICE_DATA_FREE USING    PF_LIPS_I
                                CHANGING PF_ITEM_O.
**wafer qty of die -->101419 DCEMN / WEMEH M210616
    PERFORM GET_WAFERQTY_BY_PRODTYPE USING    PFWA_HEAD_I
                                              PF_LIPS_I-LFIMG
                                     CHANGING PF_ITEM_O.
*101419<--I M210616
**BRAND/CHIPNAME(BRAND / ZCHIP)
    PERFORM GET_BRAND_CHIPNAME_INFO USING    PF_LIPS_I-VGBEL
                                             PF_LIPS_I-VGPOS
                                    CHANGING PF_ITEM_O.
**REMARK
    PERFORM GET_REMARK_ITEM USING     PF_LIPS_I-VGBEL
                                      PF_LIPS_I-VGPOS
                                      'REMK'
                            CHANGING  PF_ITEM_O-REMRK.
**TEXT
    PERFORM GET_REMARK_ITEM USING     PF_LIPS_I-VGBEL
                                      PF_LIPS_I-VGPOS
                                      'TEXT'
                            CHANGING  PF_ITEM_O-REMRK.
**Material Description(KURKI / MAKTX)
    PERFORM GET_MATERIAL_DESC_INV USING     PF_LIPS_I-MATNR
                                            PF_LIPS_I-WERKS
                                            PF_LIPS_I-CHARG
                                            ''
                                            ''
                                            PFWA_HEAD_I     "I072919
                                  CHANGING  PF_ITEM_O.
**WAFER Description
    PERFORM GET_WAFER_DESC USING    PF_LIPS_I-WERKS
                                    PF_LIPS_I-MATNR
                           CHANGING PF_ITEM_O-WRKST.

**BACKLOG(BACKL)
    PERFORM GET_BACKLOG TABLES    I_VBFA
                        USING     PF_LIPS_I-VBELN
                                  PF_LIPS_I-POSNR
                        CHANGING  PF_ITEM_O.
**BONDING
    PERFORM GET_BONDING USING     PF_LIPS_I-MATNR
                                  PF_LIPS_I-WERKS
                        CHANGING  PF_ITEM_O-BONDI.

** get Good die & Bad die Qty on in die qty(只有在PFWA_HEAD_I-PRODTYPE = 'D'時才會發生)
    PERFORM GET_GOOD_BAD_DIE_QTY  USING    PFWA_HEAD_I-PRODTYPE
                                  CHANGING PF_ITEM_O.

**PFWA_HEAD_I-SPART<>'02',可能會因KURKI導致MATNR值更改
*<-I210616
    PERFORM GET_MATERIAL_BY_KURKI_12  USING    PFWA_HEAD_I-SPART
                                               PF_ITEM_O-KURKI
                                      CHANGING PF_ITEM_O-MATNR.
*->I210616
    APPEND PF_ITEM_O.
    CLEAR  PF_ITEM_O.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_FREE01
*&---------------------------------------------------------------------*
*&      Form  GET_PRICE_DATA_FREE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_VGBEL  text
*      <--P_I_ITEM_UNITP  text
*      <--P_I_ITEM_KWERT  text
*      <--P_I_ITEM_KBETR  text
*----------------------------------------------------------------------*
FORM GET_PRICE_DATA_FREE  USING    PFWA_LIPS_I  STRUCTURE LIPS
                          CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFWA_VBAK LIKE VBAK,
        PFWA_VBAP LIKE VBAP.

  PERFORM GET_WORKAREA_VBAK USING     PFWA_LIPS_I-VGBEL
                            CHANGING  PFWA_VBAK.
  PERFORM GET_WORKAREA_VBAP USING     PFWA_LIPS_I-VGBEL
                                      PFWA_LIPS_I-VGPOS
                            CHANGING  PFWA_VBAP.
  CHECK PFWA_VBAK IS NOT INITIAL AND
        PFWA_VBAP IS NOT INITIAL.

  SELECT SINGLE * FROM  KONV
                  WHERE KNUMV = PFWA_VBAK-KNUMV
                  AND   KPOSN = PFWA_VBAP-POSNR
                  AND   KSCHL = 'PR00'.
  CHECK SY-SUBRC = 0.
  PFWA_ITEM_IO-UNITP = KONV-KBETR / KONV-KPEIN.
  PFWA_ITEM_IO-KWERT = PFWA_ITEM_IO-UNITP * PFWA_ITEM_IO-DWEMN.
  PFWA_ITEM_IO-KBETR = 0.
ENDFORM.                    " GET_PRICE_DATA_FREE
*&---------------------------------------------------------------------*
*&      Form  GET_BACKLOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_KWMEN  text
*      -->P_I_ITEM_WEMEH  text
*      <--P_I_ITEM_BACKL  text
*----------------------------------------------------------------------*
FORM GET_BACKLOG  TABLES   PF_VBFA_I    STRUCTURE VBFA
                  USING    PFV_VGBEL
                           PFV_VGPOS
                  CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFWA_LIKP LIKE LIKP,
        PFV_AUBEL TYPE VBELN_VA,
        PFV_AUPOS TYPE POSNR_VA,
        PFV_KWMEN TYPE KWMENG.

  CLEAR: PFWA_ITEM_IO-BACKL, PFV_KWMEN, PFV_AUBEL, PFV_AUPOS.
  CHECK PFWA_ITEM_IO-ZTYPE <> 'R'.              "Proforma不會有BACKLOG
  PERFORM GET_WORKAREA_LIKP USING     PFV_VGBEL
                            CHANGING  PFWA_LIKP.
  READ TABLE PF_VBFA_I WITH KEY VBELV   = PFV_VGBEL
                                POSNV   = PFV_VGPOS
                                VBTYP_N = 'R'.
  CHECK SY-SUBRC = 0.
  PFV_AUBEL = PFWA_ITEM_IO-AUBEL.
  PFV_AUPOS = PFWA_ITEM_IO-AUPOS.
*  IF PFWA_ITEM_IO-ZTYPE = 'F'.                              "D080819
*    PFV_AUBEL = PFWA_ITEM_IO-VGBEL.                         "D080819
*    PFV_AUPOS = PFWA_ITEM_IO-VGPOS.                         "D080819
*  ENDIF.                                                    "D080819

  CALL FUNCTION 'Z_COUNT_SO_ITEM_BACKLOG'
    EXPORTING
      VBELN  = PFV_AUBEL
      POSNR  = PFV_AUPOS
      BUDAT  = PFWA_LIKP-WADAT_IST
      ERZET  = PF_VBFA_I-ERZET
    IMPORTING
      KWMENG = PFV_KWMEN.

  CHECK SY-SUBRC = 0.
  PFWA_ITEM_IO-BACKL = PFV_KWMEN.
ENDFORM.                    " GET_BACKLOG
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_FREE02
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_FREE02 TABLES  PF_ITEM_IO STRUCTURE I_ITEM
                          USING   PFWA_HEAD  STRUCTURE I_HEAD.

  DATA: PF_ITEM_IO_T     LIKE I_ITEM OCCURS 0 WITH HEADER LINE,
        PFV_POSNR     TYPE POSNR_VL,
        PFV_COUNT     TYPE I,
        PFV_KWERT(15) TYPE P DECIMALS 2.

  CHECK PFWA_HEAD-ZTYPE = 'F'.        "F = Free Invoice
  CLEAR: PF_ITEM_IO_T, PF_ITEM_IO_T[], PFV_COUNT, PFV_POSNR.

  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD-VGBEL
                     AND   ZTYPE = PFWA_HEAD-ZTYPE.
    MOVE-CORRESPONDING PF_ITEM_IO TO PF_ITEM_IO_T.
    APPEND PF_ITEM_IO_T.
  ENDLOOP.
  DESCRIBE TABLE PF_ITEM_IO_T LINES PFV_COUNT.

  CHECK PFV_COUNT > 1.                                                                            "多於一筆才要考慮合併
  SORT PF_ITEM_IO_T BY MATNR KURKI BSTKD WERKS AUBEL AUPOS UNITP.
  DELETE ADJACENT DUPLICATES FROM PF_ITEM_IO_T COMPARING MATNR KURKI BSTKD WERKS AUBEL UNITP.
*  SORT PF_ITEM_IO_T BY BSTKD.         "D201317
  SORT PF_ITEM_IO_T BY POSNR.                               "I200317


  LOOP AT PF_ITEM_IO_T.
    CLEAR: PF_ITEM_IO_T-ITMNO, PF_ITEM_IO_T-DWEMN, PF_ITEM_IO_T-KWERT, PF_ITEM_IO_T-KBET1, PFV_KWERT.
    ADD 1 TO PFV_POSNR.
    LOOP AT PF_ITEM_IO WHERE VBELN = PF_ITEM_IO_T-VBELN
                       AND   ZTYPE = PF_ITEM_IO_T-ZTYPE
                       AND   MATNR = PF_ITEM_IO_T-MATNR
                       AND   KURKI = PF_ITEM_IO_T-KURKI
                       AND   BSTKD = PF_ITEM_IO_T-BSTKD
                       AND   WERKS = PF_ITEM_IO_T-WERKS
                       AND   AUBEL = PF_ITEM_IO_T-AUBEL
                       AND   UNITP = PF_ITEM_IO_T-UNITP.
      PF_ITEM_IO_T-DWEMN = PF_ITEM_IO_T-DWEMN + PF_ITEM_IO-DWEMN.   "SHIP QTY
      PF_ITEM_IO_T-KWERT = PF_ITEM_IO_T-KWERT + PF_ITEM_IO-KWERT.   "EXTENSION
      PF_ITEM_IO_T-KBET1 = PF_ITEM_IO_T-KBET1 + PF_ITEM_IO-KBET1.   "DISC
      DELETE PF_ITEM_IO.
    ENDLOOP.
    PF_ITEM_IO_T-ITMNO = PFV_POSNR+02(04).
    PFV_KWERT = PF_ITEM_IO_T-KWERT.
    CLEAR: PF_ITEM_IO_T-KWERT.
    PF_ITEM_IO_T-KWERT = PFV_KWERT.                                 "轉換成二位小數
    MODIFY PF_ITEM_IO_T.
  ENDLOOP.
  APPEND LINES OF PF_ITEM_IO_T TO PF_ITEM_IO.
*  LOOP AT PF_ITEM_IO_T.
*    MOVE-CORRESPONDING PF_ITEM_IO_T TO PF_ITEM_IO.
*    APPEND PF_ITEM_IO.
*  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_FREE02
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_FREE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK_FREE TABLES  PF_PINF_I STRUCTURE ZSD_FDMS
                          USING   PFWA_HEAD STRUCTURE I_HEAD.

  CHECK PFWA_HEAD-ZTYPE = 'F'.        "F = Free Invoice

  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING 'Remark:'
                                     PFWA_HEAD-VGBEL
                                     PFWA_HEAD-ZTYPE
                                     ''.
***SALES ORDER
  PERFORM GET_SO_LIST USING  PFWA_HEAD-VGBEL
                             PFWA_HEAD-ZTYPE
                             PFWA_HEAD-ZMTSO.
***取得GROSS DIE的資訊
  PERFORM GET_GROSS_DIE_INFO TABLES I_ITEM
                                    PF_PINF_I               "I190905
                             USING  PFWA_HEAD.
***特殊需求
  PERFORM SP_RULE_FOR_REMARK01 USING PFWA_HEAD.
***BRAND
  PERFORM GET_BRAND USING PFWA_HEAD-VGBEL
                          PFWA_HEAD-ZTYPE.

***取得WAFER ID(小於25片才要顯示)
  PERFORM GET_WAFER_ID USING PFWA_HEAD-VGBEL
                             PFWA_HEAD-ZTYPE
                             PFWA_HEAD-KUNAG
                             PFWA_HEAD-PRODTYPE.

***取得ORDER TEXT 資料
  PERFORM SP_RULE_FOR_REMARK_OTEXT USING PFWA_HEAD-VGBEL
                                         PFWA_HEAD-ZTYPE
                                         PFWA_HEAD-KUNAG.

***Die 計價要顯示Good die , Bad die & Wafer 片數(PFWA_HEAD-PRODTYPE = 'D')
  PERFORM GET_DIE_WAFER_QTY USING PFWA_HEAD-PRODTYPE
                                  PFWA_HEAD-VBELN
                                  PFWA_HEAD-ZTYPE.
***Spcial rule by customer in remakr
  PERFORM SP_RULE_IN_REMAKR_CUST USING PFWA_HEAD.

***shipping remark
  PERFORM GET_SHIPPING_REMARK USING PFWA_HEAD-VGBEL
                                    PFWA_HEAD-VBELN
                                    PFWA_HEAD-ZTYPE.
***TRADE TERM
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VGBEL
                               PFWA_HEAD-ZTYPE.
***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VGBEL
                              PFWA_HEAD-ZTYPE.

***取得BOND資訊
  PERFORM GET_BOND_INFO USING PFWA_HEAD-VGBEL
                              PFWA_HEAD-ZTYPE
                              '5'.
***放行單號及日期
  PERFORM GET_RELEASE_INFO USING  PFWA_HEAD-VGBEL
                                  PFWA_HEAD-ZTYPE
                                  PFWA_HEAD-RELNO
                                  PFWA_HEAD-CDATE.
***取得RMA資訊
  PERFORM GET_RMA_INFO USING  PFWA_HEAD-VGBEL
                              PFWA_HEAD-ZTYPE.
***關務CALL時才會出現的MESSAGE
  PERFORM IMEX_GET_REMARK_INFO TABLES I_ITEM
                               USING  PFWA_HEAD.
ENDFORM.                    " GET_ITEM_REMARK_FREE
*&---------------------------------------------------------------------*
*&      Form  GET_WAFER_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_I_ITEM_CHARG  text
*      -->P_I_ITEM_DWEMN  text
*----------------------------------------------------------------------*
FORM GET_WAFER_ID  USING    PFV_VGBEL
                            PFV_ZTYPE
                            PFV_KUNAG
                            PFV_PRODTYPE.

  DATA: BEGIN OF PF_WAFER OCCURS 0,
          WAFER(150) TYPE C,
        END OF PF_WAFER.
  DATA: PF_LIPS         LIKE LIPS OCCURS 0 WITH HEADER LINE,
        PFWA_ZMWH8H     LIKE ZMWH8H,
        PFWA_ZSHIP6     LIKE ZSHIP6,
        PFV_CHARG       TYPE CHARG_D,
        PFV_TEXTS(20)   TYPE C,
        PFV_REMAK(300)  TYPE C.

  CLEAR: PF_WAFER, PF_WAFER[], PF_LIPS, PF_LIPS[].
  CASE PFV_ZTYPE.
    WHEN 'I'.                                                                                     "I = Invoice
      LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                     AND   ZTYPE = PFV_ZTYPE.
        SELECT * APPENDING CORRESPONDING FIELDS OF TABLE PF_LIPS FROM  LIPS
                                                                 WHERE VBELN = I_ITEM-VGBEL
                                                                 AND   ( POSNR = I_ITEM-VGPOS OR
                                                                         UECHA = I_ITEM-VGPOS )
                                                                 AND   CHARG <> ''.

      ENDLOOP.
    WHEN 'P' OR                                                                                   "P = Packing
         'F'.                                                                                     "F = Free Invoice
      SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_LIPS  FROM  LIPS
                                                           WHERE VBELN = PFV_VGBEL
                                                           AND   CHARG <> ''
                                                           AND   LFIMG > 0
                                                           AND   UECHA <> ''.
    WHEN OTHERS.
  ENDCASE.



  CHECK PF_LIPS[] IS NOT INITIAL.
  SORT PF_LIPS BY POSNR.
  LOOP AT PF_LIPS.
    IF PFV_PRODTYPE = 'D'.        "Die
      SELECT SINGLE * INTO PFWA_ZMWH8H FROM ZMWH8H             "取die 的主要料號
       WHERE VBELN = PF_LIPS-VBELN AND KEYNO = PF_LIPS-CHARG
         AND MATNR = PF_LIPS-MATNR AND FGFLAG = 'X'.
      IF SY-SUBRC <> 0.
        CONTINUE.
      ELSE.
        SELECT SINGLE * INTO PFWA_ZSHIP6 FROM ZSHIP6
         WHERE KEYNO = PFWA_ZMWH8H-KEYNO AND ZDATE = PFWA_ZMWH8H-ZDATE
           AND ZTIME = PFWA_ZMWH8H-ZTIME.
        IF SY-SUBRC <> 0.
          CLEAR PFWA_ZMWH8H.
        ENDIF.
      ENDIF.
    ENDIF.

    PERFORM  GET_WAFER_ID_LIST USING      PF_LIPS-CHARG
                                          PF_LIPS-MATNR
                               CHANGING   PF_WAFER-WAFER.
** - table ZB2BI_OVT_RESHIP 由SA維護取代的 wafer list (by delivery & key no )
    PERFORM  GET_WAFER_LIST_FROM_SA USING PF_LIPS-VBELN
                                          PF_LIPS-CHARG
                               CHANGING   PF_WAFER-WAFER.

    IF PF_LIPS-LFIMG < 25 OR
       ( PFV_PRODTYPE = 'D' AND PFWA_ZSHIP6-WAQTY < 25 ).
      PERFORM SP_RULE_FOR_REMARK_WFD01 USING    PFV_KUNAG
                                                PF_LIPS-CHARG
                                       CHANGING PFV_CHARG.
      CONCATENATE PFV_CHARG '#' PF_WAFER-WAFER
        INTO PF_WAFER-WAFER SEPARATED BY SPACE.
      APPEND PF_WAFER.
    ELSE.
      CHECK PFV_ZTYPE = 'I'.                                                                      "I = Invoice
      PERFORM SP_RULE_FOR_REMARK_WFD02 USING    PFV_KUNAG
                                       CHANGING PFV_TEXTS.
      CHECK PFV_TEXTS IS NOT INITIAL.
      CONCATENATE PF_LIPS-CHARG '#' PFV_TEXTS
        INTO PF_WAFER-WAFER SEPARATED BY SPACE.
      APPEND PF_WAFER.
    ENDIF.
  ENDLOOP.

*****刪除重覆的部份
  DELETE ADJACENT DUPLICATES FROM PF_WAFER.
  CHECK PF_WAFER[] IS NOT INITIAL.
  CLEAR: PFV_REMAK.
  PFV_REMAK+2 = '** Wafer ID:'.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFV_VGBEL
                                      PFV_ZTYPE
                                      'WAFERID'.
  LOOP AT PF_WAFER.
    CLEAR: PFV_REMAK.
    PFV_REMAK+5 = PF_WAFER-WAFER.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        'WAFERID'.
  ENDLOOP.

ENDFORM.                    " GET_WAFER_ID
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_REMARK_WFRID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_KUNAG  text
*      <--P_ZMM29_KEYNO  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_REMARK_WFD01  USING    PFV_KUNAG_I
                                        PFV_CHARG_I
                               CHANGING PFV_KEYNO_O.
  CLEAR: PFV_KEYNO_O.
  DATA: PF_ZSD90 LIKE ZSD90 OCCURS 0 WITH HEADER LINE.

  IF PFV_KUNAG_I = '0000001840' OR
     PFV_KUNAG_I = '0000001921'.
    CLEAR: PF_ZSD90, PF_ZSD90[].
    SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_ZSD90 FROM ZSD90.
    READ TABLE PF_ZSD90 WITH KEY KEYNO+0(6) = PFV_CHARG_I+0(6).
    IF SY-SUBRC = 0.
      PFV_KEYNO_O = PFV_CHARG_I+1(7).
    ELSE.
      PFV_KEYNO_O = PFV_CHARG_I.
    ENDIF.
  ELSE.
    PFV_KEYNO_O = PFV_CHARG_I.
  ENDIF.
ENDFORM.                    " SPECIAL_RULE_FOR_REMARK_WFRID
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_REMARK_OTEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_KUNAG  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_REMARK_OTEXT  USING    PFV_VGBEL
                                             PFV_ZTYPE
                                             PFV_KUNAG.
  DATA: BEGIN OF PF_AUBE OCCURS 0,
          AUBEL LIKE VBRP-AUBEL,
        END OF PF_AUBE.

  DATA: BEGIN OF PF_SSTRK OCCURS 0,
          CHARG(11)   TYPE C,
          SSTVN(10)   TYPE C,
          MAXVN(40)   TYPE C,
          LFIMG       LIKE LIPS-LFIMG,
          VRKME       LIKE LIPS-VRKME,
        END OF PF_SSTRK.
*  DATA: BEGIN OF P_REMA OCCURS 0,
*          REMRK(150) TYPE C,
*        END OF P_REMA.


  DATA: PF_LIPS         LIKE LIPS OCCURS 0 WITH HEADER LINE,
        PFWA_VBAP       LIKE VBAP,
        PFV_REMAK(300)  TYPE C,
        PFV_STR01(10)   TYPE C,
        PFV_STR02(20)   TYPE C,
        PFV_LFIMG       TYPE LFIMG,
        PFV_AMOUT(10)   TYPE C.
  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    PF_AUBE-AUBEL = I_ITEM-AUBEL.
    APPEND PF_AUBE.
  ENDLOOP.
  SORT PF_AUBE.
  DELETE ADJACENT DUPLICATES FROM PF_AUBE COMPARING ALL FIELDS.

  CHECK PFV_KUNAG = '0000003131' OR
        PFV_KUNAG = '0000001543'.

  IF PFV_ZTYPE = 'I'.                                                                             "I = Invoice
    LOOP AT I_ITEM WHERE VBELN = I_HEAD-VBELN
                   AND   ZTYPE = I_HEAD-ZTYPE.

      SELECT *
        APPENDING CORRESPONDING FIELDS OF TABLE PF_LIPS FROM  LIPS
                                                        WHERE VBELN = I_ITEM-VGBEL
                                                        AND   UECHA = I_ITEM-VGPOS.
    ENDLOOP.
  ELSE.
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_LIPS FROM   LIPS
                                                 WHERE  VBELN = PFV_VGBEL
                                                 AND    LFIMG > 0
                                                 AND    UECHA <> ''.
  ENDIF.
  LOOP AT PF_LIPS.
    CONCATENATE PF_LIPS-CHARG+1(5) '00.' PF_LIPS-CHARG+6(3) INTO PF_SSTRK-CHARG.
    SPLIT PF_LIPS-KDMAT AT '-' INTO PFV_STR01 PFV_STR02 PF_SSTRK-SSTVN.
    IF PF_SSTRK-SSTVN IS INITIAL.
      SPLIT PF_LIPS-KDMAT AT '-' INTO PFV_STR01 PF_SSTRK-SSTVN.
    ENDIF.
    PF_SSTRK-LFIMG = PF_LIPS-LFIMG.
    PF_SSTRK-VRKME = PF_LIPS-VRKME.
    PERFORM GET_WORKAREA_VBAP USING     PF_LIPS-VGBEL
                                        PF_LIPS-VGPOS
                              CHANGING  PFWA_VBAP.
    PF_SSTRK-MAXVN = PFWA_VBAP-ZPOSTX.
    IF PFV_KUNAG = '0000003131'.
      SPLIT VBAP-ZPOSTX AT '-' INTO PFV_STR01 PFV_STR02 PF_SSTRK-SSTVN PF_SSTRK-MAXVN.
    ENDIF.
    COLLECT PF_SSTRK.
  ENDLOOP.

  CHECK PF_SSTRK[] IS NOT INITIAL.
  SORT PF_SSTRK BY CHARG.
  CLEAR: PFV_LFIMG.
  LOOP AT PF_SSTRK.
    PFV_LFIMG = PF_SSTRK-LFIMG + PFV_LFIMG.
  ENDLOOP.


  CLEAR: PFV_REMAK.
  PFV_REMAK+2 = 'LOT:'.

  LOOP AT PF_SSTRK.
    CONCATENATE PFV_REMAK PF_SSTRK-CHARG
      INTO PFV_REMAK SEPARATED BY SPACE.
  ENDLOOP.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFV_VGBEL
                                     PFV_ZTYPE
                                     ''.
  READ TABLE PF_SSTRK INDEX 1.

  CLEAR: PFV_REMAK.
  CONCATENATE 'Prod rev:' PF_SSTRK-SSTVN
    INTO PFV_REMAK+2.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFV_VGBEL
                                     PFV_ZTYPE
                                     ''.
  CLEAR: PFV_REMAK.
  CONCATENATE 'Mask rev:' PF_SSTRK-MAXVN
    INTO PFV_REMAK+2.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFV_VGBEL
                                     PFV_ZTYPE
                                     ''.

  WRITE PFV_LFIMG UNIT PF_SSTRK-VRKME TO PFV_AMOUT.
  CLEAR: PFV_REMAK.
  CONCATENATE 'Qty:' PFV_AMOUT 'psc'
    INTO PFV_REMAK+2.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFV_VGBEL
                                     PFV_ZTYPE
                                     ''.
ENDFORM.                    " SPECIAL_RULE_FOR_REMARK_OTEXT
*&---------------------------------------------------------------------*
*&      Form  GET_SO_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_I_HEAD_ZMTSO  text
*----------------------------------------------------------------------*
FORM GET_SO_LIST  USING    PFV_VGBEL
                           PFV_ZTYPE
                           PFV_ZMTSO.
  DATA: BEGIN OF PF_SOLS OCCURS 0,
          AUBEL TYPE VBELN_VA,
        END OF PF_SOLS.
  DATA: PFV_REMAK(300)  TYPE C,
        PF_LINES        LIKE TLINE        OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_REMAK, PF_SOLS, PF_SOLS[].
  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    PF_SOLS-AUBEL = I_ITEM-AUBEL.
    APPEND PF_SOLS.
    CLEAR: PF_SOLS.
  ENDLOOP.  "I_ITEM
  SORT PF_SOLS.
  DELETE ADJACENT DUPLICATES FROM PF_SOLS COMPARING ALL FIELDS.
  CHECK PF_SOLS[] IS NOT INITIAL.

  IF PFV_ZMTSO IS NOT INITIAL.                  "是否為多筆訂單(多訂單才需要)
    PFV_REMAK+2 = 'Sales Order No.:'.
    LOOP AT PF_SOLS.
      PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PF_SOLS-AUBEL.
      CONCATENATE PFV_REMAK PF_SOLS-AUBEL INTO PFV_REMAK SEPARATED BY SPACE.
    ENDLOOP.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDIF.
***訂單上long text 0003(Brand / Invoice Note)
*<-180810
  CLEAR: PFV_REMAK.
  LOOP AT PF_SOLS.
    PERFORM GET_LONG_TEXT TABLES PF_LINES
                          USING  PF_SOLS-AUBEL
                                '0003'
                                'VBBK'.
    READ TABLE PF_LINES INDEX 1.
    CHECK SY-SUBRC = 0 AND PF_LINES-TDLINE <> ''.
    LOOP AT PF_LINES.                                       "I190521
      IF PFV_REMAK IS INITIAL.
        CONCATENATE '**' PF_LINES-TDLINE
          INTO PFV_REMAK+2 SEPARATED BY SPACE.
      ELSE.
        CONCATENATE '  ' PF_LINES-TDLINE                    "I190521
          INTO PFV_REMAK+2 SEPARATED BY SPACE.              "I190521
*        CONCATENATE PFV_REMAK PF_LINES-TDLINE              "D190521
*          INTO PFV_REMAK SEPARATED BY SPACE.               "D190521
      ENDIF.
      CHECK PFV_REMAK IS NOT INITIAL.                       "I190521
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE         "I190521
                                  USING   PFV_REMAK         "I190521
                                          PFV_VGBEL         "I190521
                                          PFV_ZTYPE         "I190521
                                          ''.               "I190521
    ENDLOOP.                                                "I190521
  ENDLOOP.
*  CHECK PFV_REMAK IS NOT INITIAL.                     "D190521
*  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE       "D190521
*                              USING   PFV_REMAK       "D190521
*                                      PFV_VGBEL       "D190521
*                                      PFV_ZTYPE       "D190521
*                                      ''.             "D190521
*->180810
ENDFORM.                    " GET_SO_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_SHIPPING_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_SHIPPING_REMARK  USING    PFV_VGBEL
                                   PFV_VBELN
                                   PFV_ZTYPE.
  DATA: PFV_REMAK(300)  TYPE C,
        PFV_DOC LIKE LIKP-VBELN,
        PF_LINES        LIKE TLINE        OCCURS 0 WITH HEADER LINE.
  CLEAR: PFV_REMAK.
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VGBEL
                              'Z019'
                              'VBBK'.
  IF PFV_ZTYPE = 'I'.
    PFV_DOC = PFV_VBELN.            "Billing no
  ELSE.
    PFV_DOC = PFV_VGBEL.
  ENDIF.
* READ TABLE PF_LINES INDEX 1.
  LOOP AT PF_LINES.
    IF PF_LINES-TDLINE <> ''.
      PFV_REMAK+2 = PF_LINES-TDLINE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
*                                         PFV_VGBEL
                                          PFV_DOC
                                          PFV_ZTYPE
                                          ''.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " GET_SHIPPING_REMARK
*&---------------------------------------------------------------------*
*&      Form  GET_FIX_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_FIX_INFO  USING    PF_VGBEL
                            PF_ZTYPE.
  DATA: PFV_REMAK(300)  TYPE C.
  CLEAR: PFV_REMAK.
  CONCATENATE '**' TEXT-I01
    INTO PFV_REMAK+2 SEPARATED BY SPACE.                  "TEXT-I01 = 'VAT.....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  PFV_REMAK+5 = TEXT-I02.                                 "TEXT-I02 = 'and thereaft....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  PFV_REMAK+5 = TEXT-I03.                                 "TEXT-I03 = 'above taxes,....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
*<-I200522
  CHECK PF_ZTYPE = 'I' OR
        PF_ZTYPE = 'F'.
  CLEAR: PFV_REMAK.
  CONCATENATE '**' TEXT-I64
    INTO PFV_REMAK+2 SEPARATED BY SPACE.                  "TEXT-I64 = 'Actual delivery.....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  CONCATENATE '**' TEXT-I65
    INTO PFV_REMAK+2 SEPARATED BY SPACE.                  "TEXT-I65 = 'Except for part.....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  PFV_REMAK+5 = TEXT-I66.                                 "TEXT-I66 = 'conditions set....'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  PFV_REMAK+5 = TEXT-I67.                                 "TEXT-I67 = 'in writing.'
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PF_VGBEL
                                      PF_ZTYPE
                                      ''.
*->I200522
ENDFORM.                    " GET_FIX_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_TRADE_TERM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_TRADE_TERM  USING    PFV_VGBEL
                              PFV_ZTYPE.
  DATA: BEGIN OF PF_INFO OCCURS 0,
          ZTEXT(150) TYPE C,
        END OF PF_INFO.
  DATA: PFWA_VBRK       LIKE VBRK,
        PFV_INCO2(150)  TYPE C,
        PFV_REMAK(300)  TYPE C,
        PF_LINES        LIKE TLINE        OCCURS 0 WITH HEADER LINE.
  CLEAR: PFV_REMAK, PF_INFO[], PF_INFO.

  IF PFV_ZTYPE = 'I'.                                                                              "I = Invoice
    LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                   AND   ZTYPE = PFV_ZTYPE.
      CLEAR: VBRK.
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  I_ITEM-VGBEL
                                   'Z012'
                                   'VBBK'.
      IF SY-SUBRC = 0.
        READ TABLE PF_LINES INDEX 1.
        MOVE PF_LINES-TDLINE(32) TO PF_INFO-ZTEXT.
        PERFORM CHECK_INCLUDE_CHINESE USING     PF_INFO-ZTEXT
                                      CHANGING  PFV_INCO2.
        CHECK PFV_INCO2 IS NOT INITIAL.
        PF_INFO-ZTEXT = PFV_INCO2.
      ELSE.
        PF_INFO-ZTEXT = I_HEAD-INCO2.
*        PERFORM GET_WORKAREA_VBRK USING     I_HEAD-VBELN
*                                  CHANGING  PFWA_VBRK.
*        IF PFWA_VBRK-ZINCO1 IS NOT INITIAL.
*          CONCATENATE PFWA_VBRK-ZINCO1 PFWA_VBRK-ZINCO2
*            INTO PF_INFO-ZTEXT SEPARATED BY SPACE.
*        ELSE.
*          CONCATENATE PFWA_VBRK-INCO1 PFWA_VBRK-INCO2
*            INTO PF_INFO-ZTEXT SEPARATED BY SPACE.
*        ENDIF.
      ENDIF.
      APPEND PF_INFO.
    ENDLOOP.

    SORT PF_INFO.
    DELETE ADJACENT DUPLICATES FROM PF_INFO.
    LOOP AT PF_INFO.
      IF SY-TABIX = 1.
        CONCATENATE '** Trade Term:' PF_INFO-ZTEXT
          INTO PFV_REMAK+2 SEPARATED BY SPACE.
      ELSE.
        PFV_REMAK+14 = PF_INFO-ZTEXT.
      ENDIF.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFV_VGBEL
                                          PFV_ZTYPE
                                          ''.
    ENDLOOP.
  ELSE.
    CHECK I_HEAD-INCO2 IS NOT INITIAL.
    CONCATENATE '** Trade Term:' I_HEAD-INCO2
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDIF.
ENDFORM.                    " GET_TRADE_TERM
*&---------------------------------------------------------------------*
*&      Form  GET_BOND_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_7115   text
*----------------------------------------------------------------------*
FORM GET_BOND_INFO  USING    PFV_VGBEL
                             PFV_ZTYPE
                             PFV_KINDS.
  DATA: PFV_TEXTS(90)   TYPE C,
        PFV_REMAK(300)  TYPE C.


  CLEAR PFV_TEXTS.
  CALL FUNCTION 'ZJUDGE_BOND_VBELN'
    EXPORTING
      VBELN           = PFV_VGBEL
      ZKIND           = PFV_KINDS
    IMPORTING
*     BOND_TYPE       =
*     GUI_TYPE        =
*     BOND_NO         =
*     GUI_NO          =
      REMARK          = PFV_TEXTS.
*     DEL_GUINO       =
*     ZNBFLAG         = .
  CHECK PFV_TEXTS IS NOT INITIAL.
  CLEAR: PFV_REMAK.
  CONCATENATE '**' PFV_TEXTS
    INTO PFV_REMAK+2 SEPARATED BY SPACE.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFV_VGBEL
                                      PFV_ZTYPE
                                      ''.
ENDFORM.                    " GET_BOND_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_RELEASE_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_I_HEAD_RELNO  text
*      -->P_I_HEAD_CDATE  text
*----------------------------------------------------------------------*
FORM GET_RELEASE_INFO  USING    PFV_VGBEL
                                PFV_ZTYPE
                                PFV_RELNO
                                PFV_CDATE.
  DATA: PFV_REMAK(300)  TYPE C,
        PFV_LDATE(10)   TYPE C.


  CLEAR: PFV_REMAK.
  IF PFV_RELNO IS NOT INITIAL.
    CONCATENATE '** Release Permit Form No  :' PFV_RELNO
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDIF.

  CLEAR: PFV_REMAK, PFV_LDATE.
  IF PFV_CDATE IS NOT INITIAL.
    CONCATENATE PFV_CDATE+0(4) '/' PFV_CDATE+4(2) '/' PFV_CDATE+6(2)
      INTO PFV_LDATE.
    CONCATENATE '** Release Permit Form Date:' PFV_LDATE
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDIF.
ENDFORM.                    " GET_RELEASE_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_RMA_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_RMA_INFO  USING    PFV_VGBEL
                            PFV_ZTYPE.
  DATA: BEGIN OF PF_AUEL OCCURS 0,
          AUBEL LIKE VBRP-AUBEL,
        END OF PF_AUEL.
  DATA: BEGIN OF PF_RMAN OCCURS 0,
          BSTNK LIKE VBAK-BSTNK,
        END OF PF_RMAN.
  DATA: PFWA_VBAK       LIKE VBAK,
        PFV_REMAK(300)  TYPE C.

  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    PF_AUEL-AUBEL = I_ITEM-AUBEL.
    APPEND PF_AUEL.
  ENDLOOP.
  DELETE ADJACENT DUPLICATES FROM PF_AUEL COMPARING ALL FIELDS.

  LOOP AT PF_AUEL.
    PERFORM GET_WORKAREA_VBAK USING    PF_AUEL-AUBEL
                              CHANGING PFWA_VBAK.
    CHECK PFWA_VBAK-AUART = 'Z012'.             "RE-SHIP
    PF_RMAN-BSTNK = PFWA_VBAK-BSTNK.
    APPEND PF_RMAN.
  ENDLOOP.

  CHECK PF_RMAN[] IS NOT INITIAL.
  CLEAR: PFV_REMAK.
  PFV_REMAK+2 = '** RMA NO:'.
  LOOP AT PF_RMAN.
    CONCATENATE PFV_REMAK PF_RMAN-BSTNK
      INTO PFV_REMAK SEPARATED BY SPACE.
  ENDLOOP.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFV_VGBEL
                                      PFV_ZTYPE
                                      ''.
ENDFORM.                    " GET_RMA_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_TOTAL_FREE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_TOTAL_FREE USING PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PFWA_VBAP LIKE VBAP,
        PFV_TCEMN TYPE KBETR,
        PFV_TLAEN TYPE KBETR.

  CLEAR: PFV_TCEMN, PFV_TLAEN.
  CHECK PFWA_HEAD-ZTYPE = 'F'.                                                                    "F = Free Invoice

  I_ITEM_TO-VBELN = PFWA_HEAD-VGBEL.
  I_ITEM_TO-ZTYPE = PFWA_HEAD-ZTYPE.
  I_ITEM_TO-TCEMN = '0.00'.
  I_ITEM_TO-TWEMN = '0.00'.
  I_ITEM_TO-TPNTG = '0.00'.
  I_ITEM_TO-TPBRG = '0.00'.
  I_ITEM_TO-TBRGE = '0.00'.
  I_ITEM_TO-TLAEN = '0.00'.

  CLEAR: LIPS, VBAP.
  SELECT SINGLE * FROM  LIPS
                  WHERE VBELN =  PFWA_HEAD-VGBEL
                  AND   VGBEL <> ''
                  AND   VGPOS <> ''.
  IF SY-SUBRC = 0.
    PERFORM GET_WORKAREA_VBAP USING     LIPS-VGBEL
                                        LIPS-VGPOS
                              CHANGING  PFWA_VBAP.

    I_ITEM_TO-WAERK = PFWA_VBAP-WAERK.
  ENDIF.
  IF P_JOBTPS = 'N' OR
     P_JOBTPS = 'E'.
    LOOP AT I_ITEM WHERE VBELN =  PFWA_HEAD-VBELN
                   AND   ZTYPE =  PFWA_HEAD-ZTYPE.
      PFV_TCEMN  = PFV_TCEMN + I_ITEM-KWERT + I_ITEM-SCKWE + I_ITEM-PCKWE.
      PFV_TLAEN  = PFV_TLAEN + I_ITEM-KWERT + I_ITEM-SCKWE + I_ITEM-PCKWE.
    ENDLOOP.
    WRITE: PFV_TCEMN CURRENCY I_ITEM_TO-WAERK TO I_ITEM_TO-TCEMN,
           PFV_TLAEN CURRENCY I_ITEM_TO-WAERK TO I_ITEM_TO-TLAEN.
  ENDIF.
  APPEND I_ITEM_TO.
  CLEAR  I_ITEM_TO.
ENDFORM.                    " GET_ITEM_TOTAL_FREE
*&---------------------------------------------------------------------*
*&      Form  WRITE_HEADER_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_HEADER_LINE .
  FORMAT COLOR 1.
  WRITE: / '',
           (10) '單據類型'        LEFT-JUSTIFIED,
           (10) '單據編號'        LEFT-JUSTIFIED,
           (10) 'BILL-TO'         LEFT-JUSTIFIED,
           (10) 'SOLD-TO'         LEFT-JUSTIFIED,
           (10) 'SHIP-TO'         LEFT-JUSTIFIED,
           (17) 'TO BE SHIP DATE' LEFT-JUSTIFIED,
           (10) 'Use PI'          CENTERED.
  FORMAT COLOR OFF.
  ULINE.
ENDFORM.                    " WRITE_HEADER_LINE
*&---------------------------------------------------------------------*
*&      Form  GET_BRAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_BRAND  USING    PFV_VGBEL
                         PFV_ZTYPE.
  DATA: BEGIN OF PF_BRAN OCCURS 0,
          BRAND(20) TYPE C,
        END OF PF_BRAN.
  DATA: PFV_REMAK(300)  TYPE C.

  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    IF I_ITEM-BRAND = 'NO'.
      PF_BRAN-BRAND = 'NO BRAND'.
    ELSE.
      CLEAR: VBAP.
      SELECT SINGLE * FROM  VBAP
                      WHERE VBELN = I_ITEM-AUBEL
                      AND   POSNR = I_ITEM-AUPOS.
      CONCATENATE I_ITEM-BRAND '=' VBAP-ZBRAND
        INTO PF_BRAN-BRAND.
    ENDIF.
    APPEND PF_BRAN.
    CLEAR  PF_BRAN.
  ENDLOOP.
  SORT PF_BRAN.
  DELETE ADJACENT DUPLICATES FROM PF_BRAN COMPARING ALL FIELDS.
  CHECK PF_BRAN[] IS NOT INITIAL.
  CLEAR: PFV_REMAK.
  PFV_REMAK+2 = '** Brand:'.
  LOOP AT PF_BRAN.
    CONCATENATE PFV_REMAK PF_BRAN-BRAND
      INTO PFV_REMAK SEPARATED BY SPACE.
  ENDLOOP.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFV_VGBEL
                                     PFV_ZTYPE
                                     ''.
ENDFORM.                    " GET_BRAND
*&---------------------------------------------------------------------*
*&      Form  GET_HEADER_DATA_INVCRD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_INVCRD TABLES PF_VBRK_I STRUCTURE VBRK
                                 PF_HEAD_O STRUCTURE I_HEAD.

  DATA: PFWA_LIKP_TMP LIKE LIKP,
        PFV_INCO1     TYPE INCO1,     "ex: DDU,EXT....
        PFV_INCO2     TYPE INCO2.     "INCO1的說明
  CLEAR: PF_HEAD_O, PF_HEAD_O[].

  CHECK PF_VBRK_I[] IS NOT INITIAL.

  LOOP AT PF_VBRK_I.
**取得單據TYPE及日期(ZTYPE / SIDAT / PBYPC以片計價)
    PERFORM GET_DOCTYPE_AND_DATE_VBRK USING     PF_VBRK_I
                                      CHANGING  PF_HEAD_O.

    PF_HEAD_O-VKORG = PF_VBRK_I-VKORG.                              "Sales Org
    PF_HEAD_O-VTWEG = PF_VBRK_I-VTWEG.                              "(X)Distribution Channel
    PF_HEAD_O-VBELN = PF_VBRK_I-VBELN.                              "INVOICE / CREDIT MEMO NO.
    PF_HEAD_O-KUNAG = PF_VBRK_I-KUNAG.                              "(X)SOLD-TO
    PF_HEAD_O-RFBSK = PF_VBRK_I-RFBSK.                              "(X)判斷該BILLING是否已RELEASE
    PF_HEAD_O-FKART = PF_VBRK_I-FKART.                              "(X)Billing Type

**REMARK{I,C,R}(REMAK)
    PERFORM GET_HEAD_REMARK CHANGING PF_HEAD_O.
**GET SO NO.{I,C,R,D}(AUBEL / ZMTSO) ZMTSO判斷是否為多筆SO(''=一對一,'X'=一對多)
    PERFORM GET_SO_INFO USING     PF_VBRK_I-VBELN
                        CHANGING  PF_HEAD_O.
**DN NO.{I}(VGBEL)
    PERFORM GET_1ST_DN_FROM_VBRP USING     PF_VBRK_I-VBELN
                                 CHANGING  PF_HEAD_O.              "DN NO. / FREE INVOICE NO.
**(X)DIVISION(SPART)
    PERFORM GET_DIVISION USING    PF_VBRK_I-VBELN
                         CHANGING PF_HEAD_O.
*<-借用LIKP的STRUCTURE,讓PERFORM可以接值
    CLEAR: PFWA_LIKP_TMP.
    PFWA_LIKP_TMP-VBELN = PF_VBRK_I-VBELN.
    PFWA_LIKP_TMP-LFART = 'ZZ'.
    PFWA_LIKP_TMP-KUNAG = PF_HEAD_O-VGBEL.
*->借用LIKP的STRUCTURE,讓PERFORM可以接值
**GET TO BE SHIP DATE{I}
    PERFORM GET_TOBE_SHIPDATE TABLES    I_VBFA
                              USING     PFWA_LIKP_TMP
                              CHANGING  PF_HEAD_O-ERDAT.            "To Be Shipped Date

*-  Get aucal incor-term
    PERFORM GET_ACTURE_INCOTERM_VBRK USING    PF_VBRK_I
                                     CHANGING PFV_INCO1
                                              PFV_INCO2.

**DELIVERY TERMS / TRADE TERMS{I,C,R}
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_HEAD_O-VGBEL       "DN NO.
                                              PFV_INCO1
                                              PFV_INCO2
                                              PF_HEAD_O-AUBEL
                                              'TERM'
                                    CHANGING  PF_HEAD_O-INCO2.      "DELIVERY TERMS / TRADE TERMS
**DESTINATION{I,C,R}
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_HEAD_O-VGBEL       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL       "SO NO
                                              'DEST'
                                    CHANGING  PF_HEAD_O-DESTI.      "DESTINATION
**LC NO.{I,C,R}
    PERFORM GET_LC_TERMS_SHVIA_INFO USING     PF_HEAD_O-VGBEL       "DN NO.
                                              ''
                                              ''
                                              PF_HEAD_O-AUBEL
                                              'LCNO'
                                    CHANGING  PF_HEAD_O-LCNUM.      "LC NO.
**以下二個畫面還有留
***FREIGHT TERMS{I,C,R}
*    PERFORM GET_LC_TERMS_SHVIA_INFO USING     I_LIKP-VBELN          "DN NO.
*                                              I_LIKP-INCO1
*                                              I_LIKP-INCO2
*                                              I_HEAD-AUBEL
*                                              'FTER'
*                                    CHANGING  I_HEAD-FRTER.         "LC NO.
***SHIP VIA{I,C,R}
*    PERFORM GET_LC_TERMS_SHVIA_INFO USING     I_LIKP-VBELN          "DN NO.
*                                              I_LIKP-INCO1
*                                              I_LIKP-INCO2
*                                              I_HEAD-AUBEL
*                                              'SVIA'
*                                    CHANGING  I_HEAD-SHVIA.         "SHIP VIA
**PAYMENT TERM{I,C,R}(PAYTM)
    PERFORM GET_PAYMENT_TERM_DESC USING      PF_VBRK_I-ZTERM
                                  CHANGING   PF_HEAD_O.

**(X)BILL-TO{I,C,R}
    PERFORM GET_CUST_NO USING   PF_HEAD_O-VBELN
                                ''
                                ''
                                PF_HEAD_O-ZTYPE
                                'BILL'
                       CHANGING PF_HEAD_O-BKUNN.

**(X)SHIP-TO{I,C,R}
    PERFORM GET_CUST_NO USING   PF_HEAD_O-VGBEL
                                ''
                                ''
                                PF_HEAD_O-ZTYPE
                                'SHIP'
                       CHANGING PF_HEAD_O-KUNNR.

**取得USCI Code(USCIC)
    PERFORM GET_USCI_CODE CHANGING PF_HEAD_O.

**(X)判斷是否為吃PI的INVOICE{I}(GET_USING_PI_FLAG這個應該可以拿掉)
    PERFORM GET_USING_PI_FLAG TABLES    I_VBFA
                              USING     PF_VBRK_I
                              CHANGING  PF_HEAD_O-PFLAG.
*<-I210217
    PERFORM GET_USING_PI_FLAG_FROM_ZPD2 USING     PF_VBRK_I
                                        CHANGING  PF_HEAD_O-PFLAG.
*->I210217
**(X)判斷是否已經有傳送過的記錄(ZFSET / ZMSET) ZFSET = FTP, ZMSET = MAIL
    PERFORM GET_SENT_INFO USING     PF_VBRK_I-VBELN
                                    PF_VBRK_I-KUNAG
                          CHANGING  PF_HEAD_O.
**(X)取得相對應DN的放行日期
    PERFORM GET_RELNO_DATE  USING     PF_VBRK_I-VBELN
                                      'BILL'
                            CHANGING  PF_HEAD_O-RELNO
                                      PF_HEAD_O-CDATE.
**Exchange Rate(國內客戶才有值)
    PERFORM GET_EXCAHNEG_RATE USING     PF_VBRK_I
                              CHANGING  PF_HEAD_O-KURRF.
    APPEND PF_HEAD_O.
    CLEAR  PF_HEAD_O.
  ENDLOOP.
ENDFORM.                    " GET_HEADER_DATA_INVCRD
*&---------------------------------------------------------------------*
*&      Form  ORDER_BY_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ORDER_BY_HEADER TABLES PF_HEAD_IO STRUCTURE I_HEAD.
  DATA: BEGIN OF PF_ORDE OCCURS 0,
          ZORDE     TYPE I,
          ZCOMP(11) TYPE C,
          VBELN     LIKE VBRK-VBELN,
          KUNAG     LIKE VBRK-KUNAG,
        END OF PF_ORDE.
  DATA: BEGIN OF PF_KUNA OCCURS 0,
          KUNAG     LIKE VBRK-KUNAG,
        END OF PF_KUNA.


  DATA: PF_VBRP   LIKE VBRP OCCURS 0 WITH HEADER LINE,
        PFV_ZORDE TYPE I VALUE 1.


  CLEAR: PF_ORDE, PF_ORDE[].
  SORT PF_HEAD_IO BY ZTYPE VBELN.
  LOOP AT PF_HEAD_IO.
    IF PF_HEAD_IO-ZTYPE <> 'P'.                    "P = Packing
      PF_ORDE-ZCOMP = PF_HEAD_IO-ZCOMP.
      PF_ORDE-VBELN = PF_HEAD_IO-VBELN.
      APPEND PF_ORDE.
      CLEAR  PF_ORDE.
    ENDIF.
    CASE PF_HEAD_IO-ZTYPE.
      WHEN 'F'.                                 "F = Free Invoice 加一筆,同時加一筆P的
        PF_ORDE-VBELN = PF_HEAD_IO-VBELN.
        CONCATENATE 'P' PF_HEAD_IO-VBELN
          INTO PF_ORDE-ZCOMP.
        APPEND PF_ORDE.
        CLEAR  PF_ORDE.
      WHEN 'I'.                                 "I = Invoice 加一筆,同時取得PACKING
        PERFORM GET_DATA_VBRP TABLES PF_VBRP
                              USING  PF_HEAD_IO-VBELN.
        LOOP AT PF_VBRP.
          PF_ORDE-VBELN = PF_VBRP-VGBEL.
          CONCATENATE 'P' PF_VBRP-VGBEL
            INTO PF_ORDE-ZCOMP.
          APPEND PF_ORDE.
          CLEAR  PF_ORDE.
        ENDLOOP.
      WHEN 'P'.                                 "P = Packing "判斷是否存在,存在就不加
        READ TABLE PF_ORDE WITH KEY VBELN = PF_HEAD_IO-VBELN
                                    ZCOMP = PF_HEAD_IO-ZCOMP.
        IF SY-SUBRC <> 0.
          PF_ORDE-ZCOMP = PF_HEAD_IO-ZCOMP.
          PF_ORDE-VBELN = PF_HEAD_IO-VBELN.
          APPEND PF_ORDE.
          CLEAR  PF_ORDE.
        ENDIF.
      WHEN OTHERS.                              "加一筆 C,R只有獨立的一筆
    ENDCASE.
  ENDLOOP.

  LOOP AT PF_ORDE.
    PF_ORDE-ZORDE = PFV_ZORDE.
    MODIFY PF_ORDE.
    ADD 1 TO PFV_ZORDE.
  ENDLOOP.

  LOOP AT PF_HEAD_IO.
    READ TABLE PF_ORDE WITH KEY VBELN = PF_HEAD_IO-VBELN
                                ZCOMP = PF_HEAD_IO-ZCOMP.
    CHECK SY-SUBRC = 0.
    PF_HEAD_IO-ZORDE = PF_ORDE-ZORDE.
    MODIFY PF_HEAD_IO.
  ENDLOOP.
  SORT PF_HEAD_IO BY ZORDE.

  CHECK P_JOBTPS = 'N' OR                         "N = IMEX 關務需要以客戶做排序
        P_JOBTPS = 'E'.                           "E = 關務程式CALL

  CLEAR: PF_ORDE, PF_ORDE[].
  LOOP AT PF_HEAD_IO.
    PF_KUNA-KUNAG = PF_HEAD_IO-KUNAG.
    APPEND PF_KUNA.
    CLEAR  PF_KUNA.
  ENDLOOP.
  SORT PF_KUNA.
  DELETE ADJACENT DUPLICATES FROM PF_KUNA.

  LOOP AT PF_KUNA.
    LOOP AT PF_HEAD_IO WHERE KUNAG = PF_KUNA-KUNAG.
      MOVE-CORRESPONDING PF_HEAD_IO TO PF_ORDE.
      CLEAR PF_ORDE-ZORDE.
      APPEND PF_ORDE.
    ENDLOOP.
  ENDLOOP.

  PFV_ZORDE = 1.
  LOOP AT PF_ORDE.
    PF_ORDE-ZORDE = PFV_ZORDE.
    MODIFY PF_ORDE.
    ADD 1 TO PFV_ZORDE.
  ENDLOOP.

  LOOP AT PF_HEAD_IO.
    CLEAR: PF_HEAD_IO-ZORDE.
    READ TABLE PF_ORDE WITH KEY VBELN = PF_HEAD_IO-VBELN
                                ZCOMP = PF_HEAD_IO-ZCOMP.
    CHECK SY-SUBRC = 0.
    PF_HEAD_IO-ZORDE = PF_ORDE-ZORDE.
    MODIFY PF_HEAD_IO.
  ENDLOOP.
  SORT PF_HEAD_IO BY ZORDE.
ENDFORM.                    " ORDER_BY_HEADER
*&---------------------------------------------------------------------*
*&      Form  GET_USING_PI_FLAG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK_VBELN  text
*----------------------------------------------------------------------*
FORM GET_USING_PI_FLAG  TABLES   PF_VBFA_I    STRUCTURE VBFA
                        USING    PFWA_VBRK_I  STRUCTURE VBRK
                        CHANGING PFV_PFLAG.
  DATA: PFWA_VBRK_PI  LIKE VBRK,
        PF_VBRP       LIKE VBRP OCCURS 0 WITH HEADER LINE,
        PF_VBFA_TMP   LIKE VBFA OCCURS 0 WITH HEADER LINE.

  CHECK PFWA_VBRK_I-VBTYP = 'M'.                "M = Invoice
  PERFORM GET_DATA_VBRP TABLES PF_VBRP
                        USING  PFWA_VBRK_I-VBELN.
  CHECK PF_VBRP[] IS NOT INITIAL.
**先取出與這張BILLING有關的PI
  LOOP AT PF_VBRP.
    LOOP AT PF_VBFA_I WHERE VBELV   = PF_VBRP-AUBEL
                      AND   VBTYP_N = 'U'.      "U=performa inv..
      MOVE-CORRESPONDING PF_VBFA_I TO PF_VBFA_TMP.
      APPEND PF_VBFA_TMP.
    ENDLOOP.
  ENDLOOP.
  CHECK PF_VBFA_TMP[] IS NOT INITIAL.           "空值表示這張不是用PI的出貨
  SORT PF_VBFA_TMP BY VBELV VBELN.              "VBELV = SO / VBELN = PI
  DELETE ADJACENT DUPLICATES FROM PF_VBFA_TMP COMPARING VBELV VBELN.
**檢查Billing的時間與PI的時間先後(現行假設其中一張PI過就算了)
  LOOP AT PF_VBRP.
    LOOP AT PF_VBFA_TMP WHERE VBELV = PF_VBRP-AUBEL.
      PERFORM GET_WORKAREA_VBRK USING     PF_VBFA_TMP-VBELN         "這是PI單號
                                CHANGING  PFWA_VBRK_PI.
      CHECK PFWA_VBRK_I-FKDAT >= PFWA_VBRK_PI-FKDAT.
      PFV_PFLAG = 'X'.
      EXIT.
    ENDLOOP.
    CHECK PFV_PFLAG IS NOT INITIAL.
    EXIT.
  ENDLOOP.
ENDFORM.                    " GET_USING_PI_FLAG
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_INVCRD01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_INVCRD01 TABLES PF_VBRP_I    STRUCTURE I_VBRP
                                   PF_ITEM_O    STRUCTURE I_ITEM
                            USING  PFWA_HEAD_I  STRUCTURE I_HEAD.
  DATA: PFWA_VBRK LIKE VBRK,
        PFV_ITMNO TYPE POSNR_VF.

  CLEAR: PF_ITEM_O, PF_ITEM_O[].
  CHECK PFWA_HEAD_I-ZTYPE = 'I' OR              "I = Invoice
        PFWA_HEAD_I-ZTYPE = 'C' OR              "C = Credit Memo
        PFWA_HEAD_I-ZTYPE = 'D' OR              "D = Debit Memo
        PFWA_HEAD_I-ZTYPE = 'R'.                "R = Proforma



  LOOP AT PF_VBRP_I WHERE VBELN = PFWA_HEAD_I-VBELN.
    PF_ITEM_O-VBELN = PFWA_HEAD_I-VBELN.        "(X)單號  [KEY]
    PF_ITEM_O-ZTYPE = PFWA_HEAD_I-ZTYPE.        "(X)單據類型  [KEY]
    PF_ITEM_O-KUNAG = PFWA_HEAD_I-KUNAG.        "(X)CUST NO.
    PF_ITEM_O-POSNR = PF_VBRP_I-POSNR.          "(X)ITME NO.
    PF_ITEM_O-PSTYV = PF_VBRP_I-PSTYV.          "(X)ITEM TYPE     "I140424
    PF_ITEM_O-VGBEL = PF_VBRP_I-VGBEL.          "(X)DN.
    PF_ITEM_O-VGPOS = PF_VBRP_I-VGPOS.          "(X)DN ITEM
    PF_ITEM_O-AUBEL = PF_VBRP_I-AUBEL.          "(X)SO.
    PF_ITEM_O-AUPOS = PF_VBRP_I-AUPOS.          "(X)SO ITEM
    PF_ITEM_O-MATNR = PF_VBRP_I-MATNR.          "MATERIAL NUMBER
    PF_ITEM_O-WEMEH = PF_VBRP_I-VRKME.          "UNIT
    PF_ITEM_O-DWEMN = PF_VBRP_I-FKIMG.          "SHIP QTY
    PF_ITEM_O-WERKS = PF_VBRP_I-WERKS.          "PLANT

*<-I210616 DCEMN / WEMEH
    PERFORM GET_WAFERQTY_BY_PRODTYPE USING    PFWA_HEAD_I
                                              PF_VBRP_I-FKIMG
                                     CHANGING PF_ITEM_O.
*->I210616
**Cust PO No. + Item[VBKD-BSTKD]
    PERFORM GET_CUST_PO_INFO  USING     PF_VBRP_I-AUBEL
                                        PF_VBRP_I-AUPOS
                              CHANGING  PF_ITEM_O-BSTKD
                                        PF_ITEM_O-POSEX.  "Cust PO item no
**Cust PO ITEM. / ORDER QTY

**由SO取得資料( KWMEN[Qty] / KDMAT)
    PERFORM GET_DATA_VBAP_FROM_INV  USING    PF_VBRP_I
                                             PFWA_HEAD_I-ZTYPE
                                    CHANGING PF_ITEM_O.
**BRAND / CHIPNAME (BRAND / ZCHIP)
    PERFORM GET_BRAND_CHIPNAME_INFO USING    PF_VBRP_I-AUBEL
                                             PF_VBRP_I-AUPOS
                                    CHANGING PF_ITEM_O.
*CURRENCY
    PERFORM GET_WORKAREA_VBRK USING     PF_VBRP_I-VBELN
                              CHANGING  PFWA_VBRK.
    PF_ITEM_O-WAERK = PFWA_VBRK-WAERK.
**UNIT PRICE / extension / TAX / code / DISC
    PERFORM GET_PRICE_DATA_INV  USING    PFWA_VBRK
                                         PF_VBRP_I
                                CHANGING PF_ITEM_O.
**Material Description()
    PERFORM GET_MATERIAL_DESC_INV USING     PF_VBRP_I-MATNR
                                            PF_VBRP_I-WERKS
                                            PF_VBRP_I-CHARG
                                            PF_VBRP_I-VGBEL
                                            PF_VBRP_I-VGPOS
                                            PFWA_HEAD_I     "I072919
                                  CHANGING  PF_ITEM_O.
**BACKLOG
    PERFORM GET_BACKLOG TABLES    I_VBFA
                        USING     PF_VBRP_I-VGBEL
                                  PF_VBRP_I-VGPOS
                        CHANGING  PF_ITEM_O.
**BONDING
    PERFORM GET_BONDING USING     PF_VBRP_I-MATNR
                                  PF_VBRP_I-WERKS
                        CHANGING  PF_ITEM_O-BONDI.

**WAFER Description
    PERFORM GET_WAFER_DESC USING    PF_VBRP_I-WERKS
                                    PF_VBRP_I-MATNR
                           CHANGING PF_ITEM_O-WRKST.

** get Good die & Bad die Qty on in die qty(只有在PFWA_HEAD_I-PRODTYPE = 'D'時才會發生)
    PERFORM GET_GOOD_BAD_DIE_QTY  USING    PFWA_HEAD_I-PRODTYPE
                                  CHANGING PF_ITEM_O.

**REMARK
    PERFORM GET_REMARK_ITEM USING     PF_VBRP_I-AUBEL
                                      PF_VBRP_I-AUPOS
                                      'REMK'
                            CHANGING  PF_ITEM_O-REMRK.
**TEXT
    PERFORM GET_REMARK_ITEM USING     PF_VBRP_I-AUBEL
                                      PF_VBRP_I-AUPOS
                                      'TEXT'
                            CHANGING  PF_ITEM_O-REMRK.
**PFWA_HEAD_I-SPART<>'02',可能會因KURKI導致MATNR值更改
*<-I210616
    PERFORM GET_MATERIAL_BY_KURKI_12  USING    PFWA_HEAD_I-SPART
                                               PF_ITEM_O-KURKI
                                      CHANGING PF_ITEM_O-MATNR.
*->I210616

    APPEND PF_ITEM_O.
    CLEAR  PF_ITEM_O.

  ENDLOOP.

  SORT PF_ITEM_O BY VBELN POSNR.

  LOOP AT PF_ITEM_O WHERE  VBELN = PFWA_HEAD_I-VBELN
                    AND    ITMNO = ''.
**ITEM NO.
    ADD 1 TO PFV_ITMNO.
    PF_ITEM_O-ITMNO = PFV_ITMNO+02(04).
    MODIFY PF_ITEM_O.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_INVCRD01
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_PO_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRP_AUBEL  text
*      -->P_I_VBRP_AUPOS  text
*      <--P_I_ITEM_BSTKD  text
*----------------------------------------------------------------------*
FORM GET_CUST_PO_INFO  USING    PFV_AUBEL
                                PFV_AUPOS
                       CHANGING PFV_BSTKD_O  "Cust PO no
                                PFV_POSEX_O. "Cust PO item no
  DATA: PFWA_VBKD LIKE VBKD,
        PFWA_VBAK LIKE VBAK,
        PFWA_VBAP LIKE VBAP.

  CLEAR: PFV_BSTKD_O, PFV_POSEX_O.
  PERFORM GET_WORKAREA_VBKD USING     PFV_AUBEL
                                      PFV_AUPOS
                            CHANGING  PFWA_VBKD.
  IF PFWA_VBKD IS INITIAL.
    PERFORM GET_WORKAREA_VBKD USING     PFV_AUBEL
                                        '000000'
                              CHANGING  PFWA_VBKD.
  ENDIF.
  PFV_BSTKD_O = PFWA_VBKD-BSTKD.

*- PO NO in Reship so IS RMA NO
  PERFORM GET_WORKAREA_VBAK USING     PFV_AUBEL
                            CHANGING  PFWA_VBAK.
  IF PFWA_VBAK-AUART  = 'Z012' AND
     PFV_BSTKD_O+0(3) = 'RMA'.
    PFV_BSTKD_O = PFV_BSTKD_O+0(15).         "Receinving no = RMA no + 3
  ENDIF.

*- Cust Po item no
  PERFORM GET_WORKAREA_VBAP USING     PFV_AUBEL
                                      PFV_AUPOS
                            CHANGING  PFWA_VBAP.
  PFV_POSEX_O = PFWA_VBAP-POSEX.
ENDFORM.                    " GET_CUST_PO_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_BRAND_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_VGBEL  text
*      -->P_I_LIPS_VGPOS  text
*      <--P_I_ITEM_BRAND  text
*----------------------------------------------------------------------*
FORM GET_BRAND_CHIPNAME_INFO  USING    PFV_AUBEL
                                       PFV_AUPOS
                              CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFWA_VBAP     LIKE VBAP,
        PFWA_LIPS     LIKE LIPS,                            "I072919
        PF_LINES      LIKE TLINE OCCURS 0 WITH HEADER LINE,
        PFV_VGBPS(16) TYPE C.         "(LIPS-VGBEL + LIPS-VGPOS)


  CLEAR: PFV_VGBPS, PFWA_ITEM_IO-BRAND, PFWA_ITEM_IO-ZCHIP.
  PERFORM GET_WORKAREA_VBAP USING     PFV_AUBEL
                                      PFV_AUPOS
                            CHANGING  PFWA_VBAP.
  PFWA_ITEM_IO-BRAND = PFWA_VBAP-ZBRAND.
*  PFWA_ITEM_IO-ZCHIP = PFWA_VBAP-ZCHIP.                   "D072919
*072919-->I  Get chip name form table ZSHIP6
  CASE PFWA_ITEM_IO-ZTYPE.
    WHEN 'P' OR 'F'.
      PERFORM GET_WORKAREA_LIPS USING     PFWA_ITEM_IO-VBELN
                                          PFWA_ITEM_IO-POSNR
                                CHANGING  PFWA_LIPS.
    WHEN 'I'.
      SELECT SINGLE *
        INTO PFWA_LIPS FROM  LIPS
                       WHERE VBELN = PFWA_ITEM_IO-VGBEL
                       AND   UECHA = PFWA_ITEM_IO-VGPOS     "I190912
                       AND   CHARG <> ''.
  ENDCASE.
  PERFORM GET_ZCHIP_FROM_ZSHIP6 USING     PFWA_LIPS
                                CHANGING  PFWA_ITEM_IO-ZCHIP.
*072919<--I
*因新版QOM寫brand進來會分大小寫...
  TRANSLATE PFWA_ITEM_IO-BRAND TO UPPER CASE.

  CHECK PFWA_ITEM_IO-BRAND IS INITIAL.
  CONCATENATE PFV_AUBEL PFV_AUPOS
    INTO PFV_VGBPS.
  CONDENSE PFV_VGBPS NO-GAPS.
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VGBPS
                               '0002'
                               'VBBP'.
  READ TABLE PF_LINES INDEX 1.
  CHECK SY-SUBRC = 0.
  MOVE PF_LINES-TDLINE+0(2) TO PFWA_ITEM_IO-BRAND.
ENDFORM.                    " GET_BRAND_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_PRICE_INFO_INVO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VBRK_KNUMV  text
*      -->P_I_VBRP_POSNR  text
*      -->P_VBRK_WAERK  text
*      -->P_I_VBRP_MATNR  text
*      -->P_I_VBRP_AUBEL  text
*      -->P_I_VBRP_AUPOS  text
*      <--P_I_ITEM_UNITP  text
*      <--P_I_ITEM_KWERT  text
*      <--P_I_ITEM_MWSK1  text
*      <--P_I_ITEM_KBETR  text
*      <--P_I_ITEM_KBET1  text
*----------------------------------------------------------------------*
FORM GET_PRICE_DATA_INV   USING    PFWA_VBRK_I  STRUCTURE VBRK
                                   PFWA_VBRP_I  STRUCTURE I_VBRP
                          CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PF_KOMV         LIKE KOMV      OCCURS 0 WITH HEADER LINE,
        PFWA_KOMK       LIKE KOMK,
        PFV_ZAEHK       TYPE DZAEHK,
        PFV_UNITP_TMP   TYPE ZAMTDEC4.

  CLEAR: PFWA_KOMK, PFV_ZAEHK, PFWA_ITEM_IO-KWERT, PFWA_ITEM_IO-UNITP, PFWA_ITEM_IO-MWSK1, PFWA_ITEM_IO-KBET1,
         PFWA_ITEM_IO-KPEIN.
  PFWA_KOMK-KNUMV =  PFWA_VBRK_I-KNUMV.
  CALL FUNCTION 'RV_KONV_SELECT'
    EXPORTING
      COMM_HEAD_I                 = PFWA_KOMK
      GENERAL_READ                = 'X'
*     READ_CONDITION_RECORD       = ' '
*   IMPORTING
*     COMM_HEAD_E                 =
    TABLES
      TKOMV                       = PF_KOMV.

  LOOP AT PF_KOMV WHERE KNUMV =  PFWA_VBRK_I-KNUMV
                  AND   KPOSN =  PFWA_VBRP_I-POSNR
                  AND   KSCHL =  'PR00'
                  AND   KINAK <> 'X'.
    CHECK PFV_ZAEHK < PF_KOMV-ZAEHK.
    PFV_ZAEHK = PF_KOMV-ZAEHK.
  ENDLOOP.

  LOOP AT PF_KOMV WHERE KNUMV = PFWA_VBRK_I-KNUMV
                  AND   KPOSN = PFWA_VBRP_I-POSNR.
    CASE PF_KOMV-KSCHL.
      WHEN 'PR00'.
        CHECK PFV_ZAEHK = PF_KOMV-ZAEHK.
        PFWA_ITEM_IO-KWERT = PF_KOMV-KWERT.
        PFWA_ITEM_IO-UNITP = PF_KOMV-KBETR.
*        PFWA_ITEM_IO-UNITP = PFWA_ITEM_IO-UNITP / PF_KOMV-KPEIN.    "換算成單位價格
        PFWA_ITEM_IO-KPEIN = PF_KOMV-KPEIN.
      WHEN 'MWST'.
        CASE PF_KOMV-MWSK1.
          WHEN 'S1'.
            PFWA_ITEM_IO-MWSK1 = '0'.
          WHEN 'S2'.
            PFWA_ITEM_IO-MWSK1 = 'V'.
          WHEN 'S0'.
            PFWA_ITEM_IO-MWSK1 = 'N'.
          WHEN OTHERS.
        ENDCASE.
        PFWA_ITEM_IO-KBETR = PF_KOMV-KBETR / 10.
      WHEN 'RA00' OR
           'RA01'.
        PFWA_ITEM_IO-KBET1 = PF_KOMV-KBETR / 10.
      WHEN 'RB00' OR
           'RC00' OR
           'RD00'.
        SELECT SINGLE * FROM  TCURX
                        WHERE CURRKEY = PF_KOMV-WAERS.
        CASE TCURX-CURRDEC.
          WHEN 0.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT * 100.
          WHEN 1.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT * 10.
          WHEN 2.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT.
          WHEN 3.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT / 10.
          WHEN 4.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT / 100.
          WHEN 5.
            PFWA_ITEM_IO-KBET1 = PF_KOMV-KWERT / 1000.
          WHEN OTHERS.
        ENDCASE.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
*  CHECK PFWA_VBRP_I-PSTYV = 'TANN'.
  IF P_VKORG = 'PSC1' AND ( PFWA_VBRK_I-VBTYP =  'O' OR     "I110719
                            PFWA_VBRK_I-VBTYP =  'P' ).     "I110719
    EXIT.                                                   "I110719
  ENDIF.                                                    "I110719
  CALL FUNCTION 'ZSD_REF_UNITPRICE'
    EXPORTING
      VBELN  = PFWA_VBRP_I-VBELN
      POSNR  = PFWA_VBRP_I-POSNR
    IMPORTING
      REF_UP = PFV_UNITP_TMP.
  IF PFV_UNITP_TMP <> 0.
    PFWA_ITEM_IO-UNITP = PFV_UNITP_TMP.
    PFWA_ITEM_IO-KWERT = PFWA_VBRP_I-FKIMG * PFWA_ITEM_IO-UNITP.
  ENDIF.
ENDFORM.                    " GET_PRICE_INFO_INVO
*&---------------------------------------------------------------------*
*&      Form  GET_DESCRIPTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_MATNR  text
*      -->P_I_LIPS_WERKS  text
*      -->P_I_LIPS_CHARG  text
*      <--P_I_ITEM_KURKI  text
*      <--P_I_ITEM_MAKTX  text
*      <--P_CLEAR  text
*      <--P_ZZAUSP  text
*----------------------------------------------------------------------*
FORM GET_MATERIAL_DESC_INV     USING    PFV_MATNR
                                        PFV_WERKS
                                        PFV_CHARG
                                        PFV_VGBEL
                                        PFV_VGPOS
                                        PFWA_HEAD_I  STRUCTURE I_HEAD
                               CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFWA_MAKT   LIKE MAKT,
        PFWA_MCHA   LIKE MCHA,
        PFWA_ZZAUSP LIKE ZZAUSP,
        PFV_MAKTX_T TYPE MAKTX,
        PFV_CHARG_T TYPE CHARG_D,
        PFV_BTRUE   TYPE C.

  CLEAR: PFWA_ITEM_IO-KURKI, PFWA_ITEM_IO-MAKTX, PFV_CHARG_T, PFV_MAKTX_T.
  PFV_CHARG_T = PFV_CHARG.
  IF PFV_CHARG_T IS INITIAL.
    SELECT SINGLE * FROM    LIPS
                    WHERE   VBELN = PFV_VGBEL
                    AND   ( POSNR = PFV_VGPOS OR
                            UECHA = PFV_VGPOS )
                    AND     CHARG <> ''.
    PFV_CHARG_T = LIPS-CHARG.
  ENDIF.

  PERFORM GET_WORKAREA_MAKT USING     PFV_MATNR
                            CHANGING  PFWA_MAKT.
  PERFORM SP_RULE_FOR_MAKTX USING     PFWA_HEAD_I
                            CHANGING  PFWA_MAKT-MAKTX.      "I200722
  IF PFWA_MAKT IS NOT INITIAL.
    PFV_MAKTX_T = PFWA_MAKT-MAKTX.
  ELSE.
    PERFORM GET_WORKAREA_ZZAUSP USING     PFV_WERKS
                                          PFV_MATNR
                                CHANGING  PFWA_ZZAUSP.
    PFV_MAKTX_T = PFWA_ZZAUSP-ZDESC.
  ENDIF.
  PFWA_ITEM_IO-MAKTX = PFV_MAKTX_T.
  PERFORM GET_WORKAREA_MCHA USING     PFV_WERKS
                                      PFV_MATNR
                                      PFV_CHARG_T
                            CHANGING  PFWA_MCHA.
*-- 進出口-報關格式不顯示KURIKI (sold to KTC)
  CHECK PFWA_MCHA-LICHA IS NOT INITIAL.
*<-D200722
**  IF PFWA_HEAD_I-PRODTYPE = 'P'            AND              "I072919  "D101519
*  IF ( PFWA_HEAD_I-PRODTYPE = 'P' OR PFWA_HEAD_I-PRODTYPE = 'S' ) AND"I101519
*     ( P_JOBTPS = 'E' OR P_JOBTPS = 'N' )  AND              "I072919
*     PFWA_ITEM_IO-KUNAG = '0000002049' AND P_TWDVL = 'X'.   "I072919
*    EXIT.                                                   "I072919
*  ENDIF.                                                    "I072919
*->D200722
  PERFORM SP_RULE_FOR_ITEM_MATRDESC_IMEX USING    PFWA_HEAD_I"I200722
                                         CHANGING PFV_BTRUE.
  CHECK PFV_BTRUE IS INITIAL.
  PFWA_ITEM_IO-KURKI = PFWA_MCHA-LICHA.
  CLEAR: PFWA_ITEM_IO-MAKTX.
  IF PFWA_MCHA-LICHA IS NOT INITIAL.
    PFWA_ITEM_IO-MAKTX = PFWA_MCHA-LICHA.
  ENDIF.
  IF PFV_MAKTX_T IS NOT INITIAL.
    IF PFWA_ITEM_IO-MAKTX IS NOT INITIAL.
      CONCATENATE PFWA_ITEM_IO-MAKTX ',' PFV_MAKTX_T
        INTO PFWA_ITEM_IO-MAKTX SEPARATED BY SPACE.
    ELSE.
      PFWA_ITEM_IO-MAKTX = PFV_MAKTX_T.
    ENDIF.
  ENDIF.

*  CONCATENATE PFWA_MCHA-LICHA ',' PFV_MAKTX_T ',' PFV_WRKST
*    INTO PFWA_ITEM_IO-MAKTX.

ENDFORM.                    " GET_DESCRIPTION
*&---------------------------------------------------------------------*
*&      Form  GET_BONDING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_MATNR  text
*      -->P_I_LIPS_WERKS  text
*      <--P_I_ITEM_BONDI  text
*----------------------------------------------------------------------*
FORM GET_BONDING  USING    PFV_MATNR
                           PFV_WERKS
                  CHANGING PFV_BONDI.
  CLEAR: PFV_BONDI.

  CALL FUNCTION 'ZJUDGE_BOND_MATNR'
    EXPORTING
      MATNR  = PFV_MATNR
      WERKS  = PFV_WERKS
    IMPORTING
      BONDFG = PFV_BONDI.
  CASE PFV_BONDI.
    WHEN '1'.
      PFV_BONDI = 'Y'.
    WHEN '2'.
      PFV_BONDI = 'N'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_BONDING
*&---------------------------------------------------------------------*
*&      Form  GET_WAFER_DESC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_WERKS  text
*      -->P_I_LIPS_MATNR  text
*      <--P_I_ITEM_WRKST  text
*----------------------------------------------------------------------*
FORM GET_WAFER_DESC  USING    PFV_WERKS
                              PFV_MATNR
                     CHANGING PFV_WRKST.

  CALL FUNCTION 'Z_GET_BASIC_MATERIAL'
    EXPORTING
      WERKS = PFV_WERKS
      MATNR = PFV_MATNR
    IMPORTING
      WRKST = PFV_WRKST.
ENDFORM.                    " GET_WAFER_DESC
*&---------------------------------------------------------------------*
*&      Form  GET_REMARK_ITEM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIPS_VGBEL  text
*      -->P_I_LIPS_VGPOS  text
*      <--P_I_ITEM_REMRK  text
*----------------------------------------------------------------------*
FORM GET_REMARK_ITEM  USING    PFV_VGBEL
                               PFV_VGPOS
                               PFV_ZTYPE
                      CHANGING PFV_REMRK.
  DATA: PF_LINES      LIKE TLINE OCCURS 0 WITH HEADER LINE,
        PFV_VGBPS(11) TYPE C,
        PFV_ZTIDS(04) TYPE C.

  CONCATENATE PFV_VGBEL PFV_VGPOS INTO PFV_VGBPS.
  CONDENSE PFV_VGBPS NO-GAPS.

  CLEAR: PFV_REMRK, PFV_ZTIDS, PFV_VGBPS.
  CASE PFV_ZTYPE.
    WHEN 'REMK'.
      PFV_ZTIDS = '0001'.
    WHEN 'TEXT'.
      PFV_ZTIDS = '0007'.
    WHEN OTHERS.
  ENDCASE.

  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VGBPS
                               PFV_ZTIDS
                               'VBBP'.
  READ TABLE PF_LINES INDEX 1.
  CHECK SY-SUBRC = 0.
  MOVE PF_LINES-TDLINE TO PFV_REMRK.

ENDFORM.                    " GET_REMARK_ITEM
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_INVOICE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK_INVOICE  TABLES  PF_PINF_I STRUCTURE ZSD_FDMS
                              USING   PFWA_HEAD STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'I'.                                                                    "I = Invoice
***REMARK
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING TEXT-I12                                                     "TEXT-I12 = Remark:
                                     PFWA_HEAD-VBELN
                                     PFWA_HEAD-ZTYPE
                                     ''.
***SALES ORDER
  PERFORM GET_SO_LIST USING PFWA_HEAD-VBELN
                            PFWA_HEAD-ZTYPE
                            PFWA_HEAD-ZMTSO.
***DELIVERY
  PERFORM GET_DN_LIST USING PFWA_HEAD-VBELN
                            PFWA_HEAD-ZTYPE.

***取得GROSS DIE的資訊
  PERFORM GET_GROSS_DIE_INFO TABLES I_ITEM
                                    PF_PINF_I
                             USING  PFWA_HEAD.
***SPECIAL RULE
  PERFORM SP_RULE_FOR_REMARK01 USING PFWA_HEAD.
***取得ORDER TEXT 資料
  PERFORM SP_RULE_FOR_REMARK_OTEXT USING PFWA_HEAD-VBELN
                                         PFWA_HEAD-ZTYPE
                                         PFWA_HEAD-KUNAG.
***BRAND
  PERFORM GET_BRAND USING PFWA_HEAD-VBELN
                          PFWA_HEAD-ZTYPE.

***SHIPPING REMARK
  PERFORM GET_SHIPPING_REMARK USING PFWA_HEAD-VGBEL
                                    PFWA_HEAD-VBELN
                                    PFWA_HEAD-ZTYPE.

***取得WAFER ID(小於25片才要顯示)
  PERFORM GET_WAFER_ID USING PFWA_HEAD-VBELN
                             PFWA_HEAD-ZTYPE
                             PFWA_HEAD-KUNAG
                             PFWA_HEAD-PRODTYPE.
***TRADE TERM
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VBELN
                               PFWA_HEAD-ZTYPE.

***Die 計價要顯示Good die , Bad die & Wafer 片數(PFWA_HEAD-PRODTYPE = 'D')
  PERFORM GET_DIE_WAFER_QTY USING PFWA_HEAD-PRODTYPE
                                  PFWA_HEAD-VBELN
                                  PFWA_HEAD-ZTYPE.
***Spcial rule by customer in remakr
  PERFORM SP_RULE_IN_REMAKR_CUST USING PFWA_HEAD.

***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE.
***取得BOND資訊
  PERFORM GET_BOND_INFO USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE
                              '4'.

***取得客戶付款BANK資訊
  PERFORM GET_BANK_INFO USING PFWA_HEAD.

***關務CALL時才會出現的MESSAGE(含8"及12")
  PERFORM IMEX_GET_REMARK_INFO  TABLES  I_ITEM
                                USING   PFWA_HEAD.
ENDFORM.                    " GET_ITEM_REMARK_INVOICE
*&---------------------------------------------------------------------*
*&      Form  GET_DN_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_DN_LIST  USING    PFV_VBELN
                           PFV_ZTYPE.
  DATA: BEGIN OF PF_VGBE OCCURS 0,
          VGBEL TYPE VBELN_VL,
        END OF PF_VGBE.
  DATA: PFV_REMAK(300)  TYPE C,
        PFV_CDATE(10) TYPE C.

  CLEAR: PFV_REMAK, PF_VGBE, PF_VGBE[].

  LOOP AT I_ITEM WHERE VBELN = PFV_VBELN
                 AND   ZTYPE = PFV_ZTYPE.
    PF_VGBE-VGBEL = I_ITEM-VGBEL.
    APPEND PF_VGBE.
    CLEAR: PF_VGBE.
  ENDLOOP.  "I_ITEM

  SORT PF_VGBE.
  DELETE ADJACENT DUPLICATES FROM PF_VGBE COMPARING ALL FIELDS.
  CHECK PF_VGBE[] IS NOT INITIAL.
  LOOP AT PF_VGBE.
    CLEAR: ZWHRELNO, ZHPACK, ZHPACK_DN, PFV_REMAK.
    SELECT SINGLE * FROM  ZWHRELNO
                    WHERE VBELN = PF_VGBE-VGBEL.
    SELECT SINGLE * FROM ZHPACK_DN
                    WHERE VBELN = PF_VGBE-VGBEL.
    IF SY-SUBRC = 0.
      SELECT SINGLE * FROM ZHPACK WHERE PACKNO = ZHPACK_DN-PACKNO.
      IF SY-SUBRC <> 0.
        CLEAR ZHPACK.
      ENDIF.
    ENDIF.
    AT FIRST.
      PFV_REMAK+2 = TEXT-I29.                                                                     "TEXT-I29 = 'Delivery Note ID:'
    ENDAT.
    SHIFT PF_VGBE-VGBEL LEFT DELETING LEADING '0'.
    PFV_REMAK+20 = PF_VGBE-VGBEL.

*- Holiday pack no
    IF NOT ZHPACK-PACKNO IS INITIAL.
      CONCATENATE PFV_REMAK '(' TEXT-I63 ZHPACK-PACKNO ')' INTO PFV_REMAK. "SEPARATED BY SPACE.    "TEXT-I63 = 'Ref. Pack No:'              "U190523
    ENDIF.

    IF ZWHRELNO-RELNO IS NOT INITIAL.
      CONCATENATE PFV_REMAK '(' TEXT-I30 ZWHRELNO-RELNO ')' INTO PFV_REMAK. "SEPARATED BY SPACE.    "TEXT-I30 = 'Release Permit Form No:'   "U190523
    ENDIF.
    IF ZWHRELNO-CRELDATE IS NOT INITIAL.
      WRITE ZWHRELNO-CRELDATE TO PFV_CDATE.
      CONCATENATE PFV_REMAK '(' TEXT-I31 PFV_CDATE ')' INTO PFV_REMAK. "SEPARATED BY SPACE.         "TEXT-I31 = 'Release Permit Form Date:' "U190523
    ENDIF.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VBELN
                                        PFV_ZTYPE
                                        ''.
  ENDLOOP.

ENDFORM.                    " GET_DN_LIST

*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_TOTAL_INVCRD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_TOTAL_INVCRD USING PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PFWA_VBRK LIKE VBRK.
  CHECK PFWA_HEAD-ZTYPE = 'I' OR                "I = Invoice
        PFWA_HEAD-ZTYPE = 'C' OR                "C = Credit Memo
        PFWA_HEAD-ZTYPE = 'D' OR                "D = Debit Memo
        PFWA_HEAD-ZTYPE = 'R'.                  "R = Proforma Invoice


  I_ITEM_TO-VBELN = PFWA_HEAD-VBELN.
  I_ITEM_TO-ZTYPE = PFWA_HEAD-ZTYPE.
  PERFORM GET_CURRENCY_FROM_HEADER_DATA TABLES    I_ZPDH
                                        USING     PFWA_HEAD-VBELN
                                        CHANGING  I_ITEM_TO-WAERK.

  LOOP AT I_ITEM WHERE VBELN =  PFWA_HEAD-VBELN
                 AND   ZTYPE =  PFWA_HEAD-ZTYPE
                 AND   PSTYV <> 'TANN'.                     "I140424
    I_ITEM_TO-IDISK = I_ITEM_TO-IDISK + I_ITEM-KBET1.
    I_ITEM_TO-HDISK = I_ITEM_TO-HDISK + I_ITEM-KBET1.
*    I_ITEM_TO-SUBTO = I_ITEM_TO-SUBTO + I_ITEM-KWERT.
    I_ITEM_TO-SUBTO = I_ITEM_TO-SUBTO + I_ITEM-KWERT + I_ITEM-SCKWE + I_ITEM-PCKWE."M170713
*    I_ITEM_TO-TAXAM = ( I_ITEM-KWERT * I_ITEM-KBETR / 100 ) + I_ITEM_TO-TAXAM.
    I_ITEM_TO-TAXAM = ( ( I_ITEM-KWERT + I_ITEM-SCKWE ) * I_ITEM-KBETR / 100 ) + I_ITEM_TO-TAXAM.
  ENDLOOP.
  PERFORM CHANGE_TOTAL_TAX_AMT CHANGING I_ITEM_TO.          "I200508
  IF P_JOBTPS = 'N' OR
     P_JOBTPS = 'E'.
    LOOP AT I_ITEM WHERE VBELN =  PFWA_HEAD-VBELN
                   AND   ZTYPE =  PFWA_HEAD-ZTYPE
                   AND   PSTYV = 'TANN'.
      I_ITEM_TO-IDISK = I_ITEM_TO-IDISK + I_ITEM-KBET1.
      I_ITEM_TO-HDISK = I_ITEM_TO-HDISK + I_ITEM-KBET1.
      I_ITEM_TO-SUBTO = I_ITEM_TO-SUBTO + I_ITEM-KWERT + I_ITEM-SCKWE + I_ITEM-PCKWE.
      I_ITEM_TO-TAXAM = ( ( I_ITEM-KWERT + I_ITEM-SCKWE ) * I_ITEM-KBETR / 100 ) + I_ITEM_TO-TAXAM.
    ENDLOOP.
  ENDIF.
  IF PFWA_HEAD-KURRF > 0.
    I_ITEM_TO-TBRGE = PFWA_HEAD-KURRF.
  ELSE.
    I_ITEM_TO-TBRGE = '0.00'.
  ENDIF.
  I_ITEM_TO-TOTAL = I_ITEM_TO-SUBTO + I_ITEM_TO-TAXAM.
  PERFORM SP_RULE_FOR_ITEM_TOTAL TABLES    I_ITEM
                                 USING     PFWA_HEAD
                                 CHANGING  I_ITEM_TO-GDPWO.
  APPEND I_ITEM_TO.
  CLEAR  I_ITEM_TO.
ENDFORM.                    " GET_ITEM_TOTAL_INVOICE
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_REMARK_WFD02
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_KUNAG  text
*      <--P_P_TEXTS  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_REMARK_WFD02  USING    PFV_KUNAG_I
                               CHANGING PFV_TEXTS_O.
  CLEAR: PFV_TEXTS_O.
  IF PFV_KUNAG_I = '0000001949' OR             "ILITEK
     PFV_KUNAG_I = '0000002597' OR             "nxp austria
     PFV_KUNAG_I = '0000002649' OR             "nxp Netherlands
     PFV_KUNAG_I = '0000002526'.               "solomon
    PFV_TEXTS_O = '01-25'.
  ENDIF.
ENDFORM.                    " SPECIAL_RULE_FOR_REMARK_WFD02
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PROFORMA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_PROFORMA TABLES PF_HEAD_IO STRUCTURE I_HEAD.
  DATA: PF_ZPD2     LIKE ZPD2 OCCURS 0 WITH HEADER LINE,
        PF_ZPD2_CUR LIKE ZPD2 OCCURS 0 WITH HEADER LINE,
        PF_ZPD6     LIKE ZPD6 OCCURS 0 WITH HEADER LINE,
        PF_ZPD6_CUR LIKE ZPD6 OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_ZPD2, PF_ZPD2[], PF_ZPD6, PF_ZPD6[].
  PERFORM GET_NEWPI_INFO_INTO_VBFA TABLES PF_HEAD_IO
                                          I_VBFA.

**收集預收貨款使用狀況
  PERFORM GET_USING_PI_TABLE TABLES PF_HEAD_IO
                                    I_VBFA
                                    I_ZPDH
                                    PF_ZPD2
                                    PF_ZPD6.                "I210217
*<-I170901 D210217(併入GET_USING_PI_TABLE)
*  LOOP AT I_VBFA WHERE VBTYP_N = 'U'.
*    SELECT * APPENDING CORRESPONDING FIELDS OF TABLE PF_ZPD2 FROM   ZPD2
*                                                             WHERE  PERFI = I_VBFA-VBELN.
*    SELECT * APPENDING CORRESPONDING FIELDS OF TABLE PF_ZPD6 FROM   ZPD6
*                                                             WHERE  PERFI = I_VBFA-VBELN.
*  ENDLOOP.
*  SORT PF_ZPD2 BY VBELN PERFI SEQNO.                        "U092519
*  SORT PF_ZPD6 BY VBELN PERFI SEQNO.                        "U092519
*  DELETE ADJACENT DUPLICATES FROM PF_ZPD2.
*  DELETE ADJACENT DUPLICATES FROM PF_ZPD6.
*->I170901 D210217

  LOOP AT PF_HEAD_IO.
    CLEAR: PF_ZPD2_CUR, PF_ZPD2_CUR[], PF_ZPD6_CUR, PF_ZPD6_CUR[].
    IF P_JOBTPS = 'N' OR
       P_JOBTPS = 'E'.                "N = IMEX(關務不需要看到PI資訊)
      CLEAR: PF_HEAD_IO-PFLAG.
      MODIFY PF_HEAD_IO.
    ENDIF.
    CASE PF_HEAD_IO-ZTYPE.
      WHEN 'I'.                                                     "Invoice
        CHECK PF_HEAD_IO-PFLAG IS NOT INITIAL.                      "表示有吃預收貨款
        APPEND LINES OF PF_ZPD2 TO PF_ZPD2_CUR.
        APPEND LINES OF PF_ZPD6 TO PF_ZPD6_CUR.
        DELETE PF_ZPD2_CUR WHERE VBELN <> PF_HEAD_IO-VBELN.         "只留下這張INVOICE的相關PI
        DELETE PF_ZPD6_CUR WHERE VBELN <> PF_HEAD_IO-VBELN.         "只留下這張INVOICE的相關PI
        PERFORM GET_ITEM_PIITEM_DATA TABLES PF_ZPD2_CUR
                                            PF_ZPD6_CUR
                                     USING  PF_HEAD_IO.
        PERFORM GET_ITEM_PIHEAD_DATA USING PF_HEAD_IO.
      WHEN 'R'.                                                     "Proforma Invoice
        PERFORM GET_ITEM_PIITEM_DATA TABLES PF_ZPD2
                                            PF_ZPD6
                                     USING  PF_HEAD_IO.
        PERFORM GET_ITEM_PIHEAD_DATA USING PF_HEAD_IO.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_PROFORMA
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PIHEAD_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_PIHEAD_DATA USING PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PFWA_VBRK     LIKE  VBRK,
        PFWA_T880     LIKE  T880,
        PFV_DENOT(10) TYPE  N,                                                                    "分母
        PFV_MOLER(10) TYPE  N.                                                                    "分子

  CLEAR: VBRK, T880.
  IF PFWA_HEAD-ZTYPE <> 'R'.                                        "Proforma Invoice.
    CHECK I_ITEM_PIITEM[] IS NOT INITIAL.                           "I160722(若沒有ITEM就不要再往下走了)
  ENDIF.


  I_ITEM_PIHEAD-VBELN = PFWA_HEAD-VBELN.                            "(X)INVOICE NO.      [KEY]
  I_ITEM_PIHEAD-ZTYPE = PFWA_HEAD-ZTYPE.                            "(X)判斷單據類型
  PERFORM GET_WORKAREA_VBRK_WITH_NEWPI TABLES   I_ZPDH
                                       USING    PFWA_HEAD-VBELN
                                       CHANGING PFWA_VBRK.          "I210217(把新PI資料也放在PFWA_VBRK)
*  PERFORM GET_WORKAREA_VBRK USING     PFWA_HEAD-VBELN
*                            CHANGING  PFWA_VBRK.                    "D210217
  PERFORM GET_WORKAREA_T880 USING     PFWA_VBRK-BUKRS
                            CHANGING  PFWA_T880.
  I_ITEM_PIHEAD-WAERK = PFWA_VBRK-WAERK.                            "INVOICE CURRENCY
  I_ITEM_PIHEAD-KURRF = PFWA_VBRK-KURRF.                            "EXCHANGE RATE
  I_ITEM_PIHEAD-TWAER = PFWA_T880-CURR.                             "顯示用幣別
  READ TABLE I_ITEM_TO      WITH KEY VBELN = PFWA_HEAD-VBELN
                                     ZTYPE = PFWA_HEAD-ZTYPE.
  I_ITEM_PIHEAD-TOTAL = I_ITEM_TO-TOTAL.                            "TOTAL AMOUNT


  LOOP AT I_ITEM_PIITEM WHERE VBELN = PFWA_HEAD-VBELN
                        AND   ZTYPE = PFWA_HEAD-ZTYPE.
    I_ITEM_PIHEAD-FOAMT = ( I_ITEM_PIITEM-FOAMT + I_ITEM_PIITEM-PITAX ) + I_ITEM_PIHEAD-FOAMT.
  ENDLOOP.

  CASE PFWA_HEAD-ZTYPE.
    WHEN 'I'.                                                                                     "Invoice
      I_ITEM_PIHEAD-RESUT = I_ITEM_PIHEAD-TOTAL - I_ITEM_PIHEAD-FOAMT.
    WHEN 'R'.
*<-I210217
      READ TABLE I_ZPDH WITH KEY PERFI = PFWA_HEAD-VBELN.
      IF SY-SUBRC = 0.
        I_ITEM_PIHEAD-RESUT = I_ITEM_PIHEAD-TOTAL.          "用Total就會含稅
      ELSE.                                                 "Proforma Invoice
        PERFORM GET_PROFORMA_DOWNPAY_AMT USING     PFWA_HEAD
                                                   I_ITEM_PIHEAD-TOTAL
                                         CHANGING  I_ITEM_PIHEAD-RESUT.
      ENDIF.
*->I210217
*<-D210217
*      PERFORM GET_PROFORMA_DOWNPAY_AMT TABLES    I_ZPDH
*                                       USING     PFWA_HEAD
*                                                 I_ITEM_PIHEAD-TOTAL
*                                       CHANGING  I_ITEM_PIHEAD-RESUT.
*->D210217
    WHEN OTHERS.
  ENDCASE.

  I_ITEM_PIHEAD-TRESU = I_ITEM_PIHEAD-RESUT * I_ITEM_PIHEAD-KURRF.

  IF I_ITEM_PIHEAD-KURRF <> 1.        "同幣別是不需要再轉一次db mode
    PERFORM CURRENCY_CONVERT USING    I_ITEM_PIHEAD-TWAER
                             CHANGING I_ITEM_PIHEAD-TRESU.

  ENDIF.


*  IF C_UE IS NOT INITIAL AND                                                                     "D181001
  IF PFWA_HEAD-ZTYPE = 'R'.                                                                       "前端畫面決定是否顯示用proforma only
    READ TABLE I_ITEM_PIITEM WITH KEY VBELN = PFWA_HEAD-VBELN
                                      ZTYPE = PFWA_HEAD-ZTYPE.                                    "如果ITEM沒有值也不要顯示
    IF SY-SUBRC = 0 AND
       I_ITEM_PIITEM-PERFI IS NOT INITIAL.
      I_ITEM_PIHEAD-ZSHOW = 'X'.
    ENDIF.
  ENDIF.

  APPEND I_ITEM_PIHEAD.
  CLEAR  I_ITEM_PIHEAD.
ENDFORM.                    " GET_ITEM_PIHEAD_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PI_SO_CLOSE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_PIHEAD_AUBEL  text
*      -->P_I_ITEM_PIHEAD_VBELN  text
*      -->P_I_ITEM_PIHEAD_POSNR  text
*      <--P_I_ITEM_PIHEAD_GBSTK  text
*----------------------------------------------------------------------*
FORM GET_ITEM_PI_SO_CLOSE  USING    PF_AUBEL
                                    PF_VBELN
                                    PF_POSNR
                           CHANGING PF_GBSTK.
  DATA: P_VBAP LIKE VBAP OCCURS 0 WITH HEADER LINE.
  DATA: BEGIN OF P_BACK OCCURS 0,
          VBELN   LIKE VBAP-VBELN,
          POSNR   LIKE VBAP-POSNR,
          KWMENG  LIKE VBAP-KWMENG,
          CLOSE   TYPE C,
        END OF P_BACK.

  CLEAR: P_VBAP, P_VBAP[], VBRP, LIKP, P_BACK, P_BACK[].

  SELECT * INTO CORRESPONDING FIELDS OF TABLE P_VBAP FROM   VBAP
                                                     WHERE  VBELN = PF_AUBEL.

  SELECT SINGLE * FROM  VBRP
                  WHERE VBELN = PF_VBELN
                  AND   POSNR = PF_POSNR.
*取得POSTING DATE
  SELECT SINGLE * FROM  LIKP
                  WHERE VBELN = VBRP-VGBEL.
*取得POSTING TIME
  SELECT SINGLE * FROM  VBFA
                  WHERE VBELV   = VBRP-VGBEL
                  AND   POSNV   = VBRP-VGPOS
                  AND   VBTYP_N = TEXT-TPR.                          "TEXT-TPR = 'R'

  LOOP AT P_VBAP.
    CALL FUNCTION 'Z_COUNT_SO_ITEM_BACKLOG'
      EXPORTING
        VBELN  = P_VBAP-VBELN
        POSNR  = P_VBAP-POSNR
        BUDAT  = LIKP-WADAT_IST
        ERZET  = VBFA-ERZET
      IMPORTING
        KWMENG = P_BACK-KWMENG.

    P_BACK-VBELN = P_VBAP-VBELN.
    P_BACK-POSNR = P_VBAP-POSNR.
    IF P_BACK-KWMENG = 0.       "沒有BACKLOG就是該ITEM為CLOSE
      P_BACK-CLOSE = 'X'.
    ENDIF.
  ENDLOOP.
  CLEAR: P_BACK.

  SORT P_BACK BY CLOSE.
  READ TABLE P_BACK INDEX 1.
*只要有一個ITEM不是CLOSE,整個SO就沒有CLOSE
  IF P_BACK-CLOSE = ''.
    PF_GBSTK = ''.
  ENDIF.
ENDFORM.                    " GET_ITEM_PI_SO_CLOSE
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PIITEM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_PIITEM_DATA TABLES  PF_ZPD2_IO  STRUCTURE ZPD2
                                  PF_ZPD6_IO  STRUCTURE ZPD6
                          USING   PFWA_HEAD   STRUCTURE I_HEAD.
*<-I170901
  DATA: PFV_UPPD2(01) TYPE C,                                                                     "判斷是否要UPDATE到PF_ZPD2_IO
        PFV_UPPD6(01) TYPE C,                                                                     "判斷是否要UPDATE到PF_ZPD6_IO
        PFV_CHECK(01) TYPE C.                                                                     "判斷是否為非使用預收的item
**預收出貨扣pi資訊
  IF PFWA_HEAD-ZTYPE = 'I'.                               "Invoice
    LOOP AT PF_ZPD2_IO.
      I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.
      I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.              "(X)判斷單據類型
*      I_ITEM_PIITEM-AUBEL = I_ITEM-AUBEL.                 "(X)SO
      I_ITEM_PIITEM-PERFI = PF_ZPD2_IO-PERFI.             "proforma invoice No
      I_ITEM_PIITEM-FOAMT = PF_ZPD2_IO-FOAMT.             "amount
      I_ITEM_PIITEM-WAERK = PF_ZPD2_IO-WAERK.             "Currency
      PERFORM GET_OLD_PI_NO USING     PF_ZPD2_IO-PERFI
                            CHANGING  I_ITEM_PIITEM-OPVBE.
      READ TABLE PF_ZPD6_IO WITH KEY PERFI = PF_ZPD2_IO-PERFI
                                     VBELN = PF_ZPD2_IO-VBELN
                                     SEQNO = PF_ZPD2_IO-SEQNO."I092519
      IF SY-SUBRC = 0.
        I_ITEM_PIITEM-PITAX = PF_ZPD6_IO-FOAMT.           "TAX
      ENDIF.
      APPEND I_ITEM_PIITEM.
      CLEAR: I_ITEM_PIITEM.
    ENDLOOP.

*    LOOP AT I_ITEM WHERE VBELN =  PFWA_HEAD-VBELN
*                   AND   ZTYPE =  PFWA_HEAD-ZTYPE
*                   AND   PSTYV <> 'TANN'.
*      I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.                                                      "(X)Billing NO.(I) Proforma No.(R)      [KEY]
**      I_ITEM_PIITEM-POSNR = I_ITEM-POSNR.                                                         "(X)ITEM NO.
*      I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.                                                      "(X)判斷單據類型
*      I_ITEM_PIITEM-AUBEL = I_ITEM-AUBEL.                                                         "(X)SO
*      PERFORM GET_ITEM_PI_FROM_TABLE TABLES   PF_ZPD2_IO
*                                              PF_ZPD6_IO
*                                     USING    I_ITEM
*                                     CHANGING I_ITEM_PIITEM
*                                              PFV_UPPD2
*                                              PFV_UPPD6
*                                              PFV_CHECK.
*      CHECK PFV_CHECK IS NOT INITIAL.                                                              "I171016 有值就表示它是預收item
*      APPEND I_ITEM_PIITEM.
*      CLEAR: I_ITEM_PIITEM.
*      IF PFV_UPPD2 IS NOT INITIAL.
*        CLEAR: PF_ZPD2_IO.
*        PF_ZPD2_IO-VBELN = I_ITEM_PIITEM-VBELN.
**       PF_ZPD2_IO-POSNR = I_ITEM_PIITEM-POSNR.
*        PF_ZPD2_IO-PERFI = I_ITEM_PIITEM-PERFI.
*        PF_ZPD2_IO-FOAMT = I_ITEM_PIITEM-FOAMT.
*        PF_ZPD2_IO-WAERK = I_ITEM_PIITEM-WAERK.
*        APPEND PF_ZPD2_IO.
*      ENDIF.
*      IF PFV_UPPD6 IS NOT INITIAL.
*        CLEAR: PF_ZPD6_IO.
*        PF_ZPD6_IO-VBELN = I_ITEM_PIITEM-VBELN.
**       PF_ZPD6_IO-POSNR = I_ITEM_PIITEM-POSNR.
*        PF_ZPD6_IO-PERFI = I_ITEM_PIITEM-PERFI.
*        PF_ZPD6_IO-FOAMT = I_ITEM_PIITEM-PITAX.
*        PF_ZPD6_IO-WAERK = I_ITEM_PIITEM-WAERK.
*        APPEND PF_ZPD6_IO.
*      ENDIF.
*    ENDLOOP.
*    SORT I_ITEM_PIITEM.
*    DELETE ADJACENT DUPLICATES FROM I_ITEM_PIITEM COMPARING ALL FIELDS.
  ENDIF.
**pi用在那些invoice
  IF PFWA_HEAD-ZTYPE = 'R'.
    LOOP AT PF_ZPD2_IO WHERE PERFI = PFWA_HEAD-VBELN.
      I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.                                                      "(X)Billing NO.(I) Proforma No.(R)      [KEY]
*     I_ITEM_PIITEM-POSNR = PF_ZPD2_IO-POSNR.                                                     "基本上是沒有用到的
      I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.                                                      "(X)判斷單據類型
      I_ITEM_PIITEM-ERDAT = PF_ZPD2_IO-AEDAT.                                                     "(X)單據日期
      I_ITEM_PIITEM-ERZET = PF_ZPD2_IO-AEZET.                                                     "(X)單據時間
      I_ITEM_PIITEM-PERFI = PF_ZPD2_IO-VBELN.                                                     "有使用這張PI的Billing NO.
      I_ITEM_PIITEM-FOAMT = PF_ZPD2_IO-FOAMT.                                                     "金額
      I_ITEM_PIITEM-WAERK = PF_ZPD2_IO-WAERK.                                                     "Curr.
      READ TABLE PF_ZPD6_IO WITH KEY VBELN = PF_ZPD2_IO-VBELN
*                                    POSNR = PF_ZPD2_IO-POSNR
                                     PERFI = PF_ZPD2_IO-PERFI
                                     SEQNO = PF_ZPD2_IO-SEQNO."I092519
      IF SY-SUBRC = 0.
        I_ITEM_PIITEM-PITAX = PF_ZPD6_IO-FOAMT.
      ENDIF.
      APPEND I_ITEM_PIITEM.
      CLEAR: I_ITEM_PIITEM.
    ENDLOOP.
  ENDIF.
*->I170901

*<-D170901
**<-I160615
*  DATA: PF_VBFA       LIKE VBFA           OCCURS 0 WITH HEADER LINE,
*        PF_PIITEM_T   LIKE I_ITEM_PIITEM  OCCURS 0 WITH HEADER LINE,                              "暫存用(計算多筆使用)
*
*        PFX_ZFLAG     TYPE C,                                                                     "接值用,不使用
*        PFV_NUMB1(10) TYPE N,
*        PFV_NUMB2(10) TYPE N,
*        PFV_FOAMT     LIKE KOMV-KBETR,                                                            "PI ITEM金額加總
*        PFV_PITAX     LIKE KOMV-KBETR,                                                            "PI_TAX加總
*        PFV_WAERK     LIKE VBRK-WAERK,                                                            "PI CURRENCY
*        PFV_COUNT     LIKE KOMV-KBETR.
*
*
***先收集VBFA的資料
*  PERFORM GET_FLOW_DATA TABLES  PF_VBFA
*                        USING   PFWA_HEAD-VBELN
*                                PFWA_HEAD-ZTYPE.
*  CLEAR: I_ITEM_PIITEM.
***取得I_ITEM_PIITEM需要的資料(目前只能針對一個item對應到一張PI,若1對多要重新思考)
*  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD-VBELN
*                 AND   ZTYPE = PFWA_HEAD-ZTYPE
*                 AND   PSTYV <> 'TANN'.                                                           "I160722
*    I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.                                                        "(X)BILLING NO [KEY]
*    I_ITEM_PIITEM-POSNR = I_ITEM-POSNR.                                                           "(X)ITEM NO.
*    I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.                                                        "(X)判斷單據類型
*    I_ITEM_PIITEM-AUBEL = I_ITEM-AUBEL.                                                           "(X)SO
*
*    LOOP AT PF_VBFA WHERE VBELV = I_ITEM-AUBEL.                                                   "PF_VBFA已把CANCEL的PI或Invoice濾掉
**                    AND   POSNV = I_ITEM-AUPOS.
*      "Invoice
*      IF PFWA_HEAD-ZTYPE = 'I'.                                                                   "Invoice
*        I_ITEM_PIITEM-PERFI = PF_VBFA-VBELN.                                                      "proforma invoice No
*        APPEND I_ITEM_PIITEM.
*        CLEAR  I_ITEM_PIITEM-PERFI.
*      ENDIF.
*      "Proforma
*      IF PFWA_HEAD-ZTYPE = 'R'.                                                                   "Proforma
*        I_ITEM_PIITEM-ERDAT = PF_VBFA-ERDAT.                                                      "(X)單據日期
*        I_ITEM_PIITEM-ERZET = PF_VBFA-ERZET.                                                      "(X)單據時間
*        I_ITEM_PIITEM-PERFI = PF_VBFA-VBELN.
*        APPEND I_ITEM_PIITEM.
*        CLEAR: I_ITEM_PIITEM-PERFI, I_ITEM_PIITEM-ERZET, I_ITEM_PIITEM-ERDAT.
*      ENDIF.
*    ENDLOOP.
*  ENDLOOP.
*  CHECK I_ITEM_PIITEM[] IS NOT INITIAL.                                                           "I160722
***刪除重覆SO的筆數
*  SORT I_ITEM_PIITEM BY VBELN ZTYPE AUBEL PERFI.
*  DELETE ADJACENT DUPLICATES FROM I_ITEM_PIITEM COMPARING VBELN POSNR ZTYPE AUBEL PERFI.
****把每一筆的金額都先算出來
*  PERFORM GET_EACH_ITEM_AMOUT_TAX TABLES  PF_PIITEM_T
*                                          I_ITEM_PIITEM
*                                  USING   PFWA_HEAD-VBELN
*                                          PFWA_HEAD-ZTYPE.
**  CLEAR: I_ITEM_PIITEM.
****取得I_ITEM_PIITEM需要的資料(目前只能針對一個item對應到一張PI,若1對多要重新思考)
**  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD-VBELN
**                 AND   ZTYPE = PFWA_HEAD-ZTYPE
**                 AND   PSTYV <> 'TANN'.                                                           "I160722
**    I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.                                                        "(X)BILLING NO [KEY]
**    I_ITEM_PIITEM-POSNR = I_ITEM-POSNR.                                                           "(X)ITEM NO.
**    I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.                                                        "(X)判斷單據類型
**    I_ITEM_PIITEM-AUBEL = I_ITEM-AUBEL.                                                           "(X)SO
**
**    CHECK PF_VBFA[] IS NOT INITIAL.
****針對vbfa中的資料先行檢查
**    LOOP AT PF_VBFA WHERE VBELV = I_ITEM-AUBEL.
**      CASE PFWA_HEAD-ZTYPE.
**        WHEN TEXT-TPI.                                                                            "TEXT-TPI = 'I'    Invoice
**          PERFORM CHECK_PROFORMA_STATUS USING     PF_VBFA-VBELN
**                                                  TEXT-FN2                                        "TEXT-FN2 = 'CANC'
**                                        CHANGING  PFV_CANCL
**                                                  PFX_ZFLAG.
**          IF PFV_CANCL IS NOT INITIAL.
**            DELETE PF_VBFA.
**            CHECK P_JOBTPS <> TEXT-TPN.                                                           "TEXT-TPN = 'N'   "I141015
**            MESSAGE I000 WITH PF_VBFA-VBELN TEXT-E14.                                             "TEXT-E14 = 'This Proforma Invoice is canceled!'
**            CONTINUE.
**          ENDIF.
**          "不跳離就會往下RUN
**          I_ITEM_PIITEM-PERFI = PF_VBFA-VBELN.                                                    "proforma invoice No
**          APPEND I_ITEM_PIITEM.
**          CLEAR  I_ITEM_PIITEM-PERFI.
**        WHEN TEXT-TPR.                                                                            "TEXT-TPR = 'R'    Proforma Invoice
*****處理部份pi是後來有開過INVOICE後才開立的
**          PERFORM CHECK_PROFORMA_BIILLING_ORDER USING     PF_VBFA-ERDAT
**                                                          PF_VBFA-ERZET
**                                                          PFWA_HEAD-VBELN
**                                                CHANGING  PFV_CANCL.
**          IF PFV_CANCL IS NOT INITIAL.
**            DELETE PF_VBFA.
**            CONTINUE.
**          ENDIF.
*****檢查BILLING是否被CANCEL
**          PERFORM CHECK_BILLING_CANCELED USING      PF_VBFA-VBELN
**                                         CHANGING   PFV_CANCL.
**
**          IF PFV_CANCL IS NOT INITIAL.
**            DELETE PF_VBFA.
**            CONTINUE.
**          ENDIF.
**          "不跳離就會往下RUN
**          I_ITEM_PIITEM-ERDAT = PF_VBFA-ERDAT.                                                    "(X)單據日期
**          I_ITEM_PIITEM-ERZET = PF_VBFA-ERZET.                                                    "(X)單據時間
**          I_ITEM_PIITEM-PERFI = PF_VBFA-VBELN.
**          APPEND I_ITEM_PIITEM.
**          CLEAR: I_ITEM_PIITEM-PERFI, I_ITEM_PIITEM-ERZET, I_ITEM_PIITEM-ERDAT.
**        WHEN OTHERS.
**      ENDCASE.
**    ENDLOOP.
**  ENDLOOP.
**  CHECK I_ITEM_PIITEM[] IS NOT INITIAL.                                                           "I160722
****刪除重覆SO的筆數
**  SORT I_ITEM_PIITEM BY VBELN ZTYPE AUBEL PERFI.
**  DELETE ADJACENT DUPLICATES FROM I_ITEM_PIITEM COMPARING VBELN POSNR ZTYPE AUBEL PERFI.
****把每一筆的金額都先算出來
**  PERFORM GET_EACH_ITEM_AMOUT_TAX TABLES  PFT_PIITEM
**                                          I_ITEM_PIITEM
**                                  USING   PFWA_HEAD-VBELN
**                                          PFWA_HEAD-ZTYPE.
*  LOOP AT I_ITEM_PIITEM WHERE VBELN = PFWA_HEAD-VBELN
*                        AND   ZTYPE = PFWA_HEAD-ZTYPE.
*    CASE PFWA_HEAD-ZTYPE.
*      WHEN TEXT-TPI.                                                                              "TEXT-TPI = 'I'    Invoice
*        PERFORM GET_ITEM_PI_DOWNPAYMENT USING     I_ITEM_PIITEM-PERFI
*                                        CHANGING  I_ITEM_PIITEM-DOWNP.
*
*        READ TABLE PF_PIITEM_T WITH KEY VBELN = I_ITEM_PIITEM-VBELN
*                                        POSNR = I_ITEM_PIITEM-POSNR
*                                        ZTYPE = I_ITEM_PIITEM-ZTYPE
*                                        AUBEL = I_ITEM_PIITEM-AUBEL
*                                        PERFI = I_ITEM_PIITEM-PERFI.
*       IF I_ITEM_PIITEM-FOAMT <> PF_PIITEM_T-FOAMT.
*         I_ITEM_PIITEM-FOAMT = PF_PIITEM_T-FOAMT.
*       ENDIF.
*       IF I_ITEM_PIITEM-PITAX <> PF_PIITEM_T-PITAX.
*         I_ITEM_PIITEM-PITAX = PF_PIITEM_T-PITAX.
*       ENDIF.
*       I_ITEM_PIITEM-WAERK = PF_PIITEM_T-WAERK.
*      WHEN TEXT-TPR.                                                                              "TEXT-TPR = 'R'    Proforma Invoice
*        PERFORM GET_BILLING_CONDITIONS USING    I_ITEM_PIITEM-PERFI
*                                                I_ITEM_PIITEM-AUBEL
*                                       CHANGING I_ITEM_PIITEM-FOAMT
*                                                I_ITEM_PIITEM-PITAX
*                                                I_ITEM_PIITEM-WAERK.
*        PERFORM CHECK_PROFORMA_STATUS USING     PFWA_HEAD-VBELN
*                                                TEXT-FN1                                          "TEXT-FN1 = 'RATE'
*                                      CHANGING  PFV_NUMB1
*                                                PFV_NUMB2.
*
*        I_ITEM_PIITEM-FOAMT = I_ITEM_PIITEM-FOAMT * PFV_NUMB2 / PFV_NUMB1.
*        I_ITEM_PIITEM-PITAX = I_ITEM_PIITEM-PITAX * PFV_NUMB2 / PFV_NUMB1.
*      WHEN OTHERS.
*    ENDCASE.
*
*    MODIFY I_ITEM_PIITEM.
*    CLEAR  I_ITEM_PIITEM.
*  ENDLOOP.
*
*
*  CHECK PFWA_HEAD-ZTYPE = 'R'.                                                                    "Proforma Invoice
***針對部份有做"預收貨款折讓"也要計入
*  SELECT * FROM   ZPD2
*           WHERE  PERFI = PFWA_HEAD-VBELN.
*    READ TABLE PF_VBFA WITH KEY VBELN = ZPD2-VBELN.
*    IF SY-SUBRC <> 0.
*      I_ITEM_PIITEM-VBELN = PFWA_HEAD-VBELN.
*      I_ITEM_PIITEM-ZTYPE = PFWA_HEAD-ZTYPE.
*      I_ITEM_PIITEM-ERDAT = ZPD2-AEDAT.
*      I_ITEM_PIITEM-ERZET = ZPD2-AEZET.
*      I_ITEM_PIITEM-PERFI = ZPD2-VBELN.
*      I_ITEM_PIITEM-FOAMT = ZPD2-FOAMT.
*      I_ITEM_PIITEM-WAERK = ZPD2-WAERK.
*      APPEND I_ITEM_PIITEM.
*    ENDIF.
*  ENDSELECT.
*  SORT I_ITEM_PIITEM BY VBELN ZTYPE ERDAT ERZET.
*  PERFORM GET_BILLING_CONDITIONS USING    PFWA_HEAD-VBELN
*                                          PFWA_HEAD-AUBEL                                            "PROFORMA 不會是多筆SO
*                                 CHANGING PFV_FOAMT
*                                          PFV_PITAX
*                                          PFV_WAERK.
*  PFV_FOAMT = PFV_FOAMT + PFV_PITAX.
*  LOOP AT I_ITEM_PIITEM WHERE VBELN = PFWA_HEAD-VBELN
*                        AND   ZTYPE = PFWA_HEAD-ZTYPE.
*    IF PFV_FOAMT = 0.
*      I_ITEM_PIITEM-PITAX = 0.
*      I_ITEM_PIITEM-FOAMT = 0.
*    ELSE.
*      CLEAR: PFV_COUNT.
*      PFV_COUNT = I_ITEM_PIITEM-FOAMT + I_ITEM_PIITEM-PITAX.
*      IF PFV_COUNT > PFV_FOAMT.
*        PFV_COUNT = PFV_FOAMT.
*        I_ITEM_PIITEM-PITAX = PFV_COUNT * I_ITEM_PIITEM-PITAX / I_ITEM_PIITEM-FOAMT.
*        I_ITEM_PIITEM-FOAMT = PFV_COUNT - I_ITEM_PIITEM-PITAX.
*      ELSE.
*        PFV_FOAMT = PFV_FOAMT - PFV_COUNT.
*      ENDIF.
*    ENDIF.
*    MODIFY I_ITEM_PIITEM.
*  ENDLOOP.
**->I160615
*->D170901

ENDFORM.                    " GET_ITEM_PIITEM_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PI_DOWNPAYMENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBELN  text
*      <--P_PF_DOWNP  text
*----------------------------------------------------------------------*
FORM GET_ITEM_PI_DOWNPAYMENT  USING    PPFV_VBELN
                              CHANGING PPFV_DOWNP.
  DATA: PF_LINES LIKE TLINE OCCURS 0 WITH HEADER LINE.
  CLEAR: PPFV_DOWNP.
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PPFV_VBELN
                               '0001'
                               'VBBK'.
  READ TABLE PF_LINES INDEX 1.
  CHECK SY-SUBRC = 0.
  PPFV_DOWNP = PF_LINES-TDLINE.
ENDFORM.                    " GET_ITEM_PI_DOWNPAYMENT
*&---------------------------------------------------------------------*
*&      Form  CHECK_PI_WITH_STD_BILLING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_PROFMA_AUBEL  text
*      -->P_I_PROFMA_VBELN  text
*----------------------------------------------------------------------*
*FORM CHECK_PI_WITH_STD_BILLING USING PPF_AUBEL
*                                     PPF_VBELN.
*  DATA: PI_VBFA       LIKE VBFA OCCURS 0 WITH HEADER LINE,
*         V_ANSWE      TYPE C,
*        V_QUEST(100)  TYPE C.
*  DATA: BEGIN OF I_CBILL OCCURS 0,
*          VBELN LIKE VBRK-VBELN,
*        END OF I_CBILL.
*
*
*  CLEAR: PI_VBFA, PI_VBFA[].
*  SELECT * INTO CORRESPONDING FIELDS OF TABLE PI_VBFA FROM   VBFA
*                                                      WHERE  VBELV   =   PPF_AUBEL
*                                                      AND    VBELN   <>  PPF_VBELN
*                                                      AND    (  VBTYP_N = TEXT-TPM                    "TEXT-TPM = 'M'
*                                                          OR    VBTYP_N = TEXT-TPN ).                 "TEXT-TPN = 'N'
*  LOOP AT PI_VBFA WHERE VBTYP_N = TEXT-TPN.                                                           "TEXT-TPN = 'N'.  " CANCEL BILLING要去和正常BILLING相抵
*    CLEAR: VBRK.
*    SELECT SINGLE * FROM  VBRK
*                    WHERE VBELN = PI_VBFA-VBELN.
*    I_CBILL-VBELN = VBRK-SFAKN.
*    APPEND I_CBILL.
*    DELETE PI_VBFA.
*  ENDLOOP.
*
*  LOOP AT I_CBILL.
*    READ TABLE PI_VBFA WITH KEY VBELN = I_CBILL-VBELN.
*    DELETE PI_VBFA.
*  ENDLOOP.
*
*  LOOP AT PI_VBFA WHERE VBTYP_N = TEXT-TPM.                                                           "TEXT-TPM = 'M'.
*    CLEAR: ZPD2.
*    SELECT SINGLE * FROM  ZPD2
*                    WHERE VBELN = PI_VBFA-VBELN.
*    IF SY-SUBRC = 0.
*      DELETE PI_VBFA.
*    ENDIF.
*  ENDLOOP.
*
*  IF PI_VBFA[] IS NOT INITIAL.
*    CLEAR: V_QUEST.
*    LOOP AT PI_VBFA WHERE VBTYP_N = TEXT-TPM.                                                         "TEXT-TPM = 'M'
*      SHIFT PI_VBFA-VBELN LEFT DELETING LEADING '0'.
*      CONCATENATE V_QUEST PI_VBFA-VBELN INTO V_QUEST SEPARATED BY SPACE.
*    ENDLOOP.
*    IF V_QUEST <> ''.
*      CONCATENATE 'SO:' PPF_AUBEL '已有正常Billing:' V_QUEST '是否仍以預收貸款方式出貨?' INTO V_QUEST.
*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          TITLEBAR                    = TEXT-T03
**         DIAGNOSE_OBJECT             = ' '
*          TEXT_QUESTION               = V_QUEST
*          TEXT_BUTTON_1               = '是'
**         ICON_BUTTON_1               = ' '
*          TEXT_BUTTON_2               = '否'
**         ICON_BUTTON_2               = ' '
*          DEFAULT_BUTTON              = '1'
*          DISPLAY_CANCEL_BUTTON       = ' '
**         USERDEFINED_F1_HELP         = ' '
**         START_COLUMN                = 25
**         START_ROW                   = 6
**         POPUP_TYPE                  =
**         IV_QUICKINFO_BUTTON_1       = ' '
**         IV_QUICKINFO_BUTTON_2       = ' '
*        IMPORTING
*          ANSWER                      = V_ANSWE
**       TABLES
**         PARAMETER                   =
**       EXCEPTIONS
**         TEXT_NOT_FOUND              = 1
**         OTHERS                      = 2
*                .
*      IF V_ANSWE = '2'.
*        LEAVE PROGRAM.
*      ENDIF.
*    ENDIF.
*  ENDIF.
*ENDFORM.                    " CHECK_PI_WITH_STD_BILLING
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_CRDMEMO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK_CRDMEMO USING PFWA_HEAD STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'C'.                                                                    "C = Credit Memo
***REMARK
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING 'Remark:'
                                     PFWA_HEAD-VBELN
                                     PFWA_HEAD-ZTYPE
                                     ''.
***SPECIAL RULE
  PERFORM SP_RULE_FOR_REMARK01 USING PFWA_HEAD.
***取得ORDER TEXT 資料
  PERFORM SP_RULE_FOR_REMARK_OTEXT USING PFWA_HEAD-VBELN
                                         PFWA_HEAD-ZTYPE
                                         PFWA_HEAD-KUNAG.

*I190703 -->
  PERFORM WRITE_RMA_WAFER_ID USING PFWA_HEAD-VBELN
                                   PFWA_HEAD-ZTYPE.
*I190703 <--

*051419-->I
***SALES ORDER
  PERFORM CREDITSO_HEADER_TEXT_REMAKR USING PFWA_HEAD-VBELN
                                            PFWA_HEAD-VGBEL
                                            PFWA_HEAD-ZTYPE.

*051419<--I
***BRAND
  PERFORM GET_BRAND USING PFWA_HEAD-VBELN
                          PFWA_HEAD-ZTYPE.
***TRADE TERM
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VBELN
                               PFWA_HEAD-ZTYPE.
***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE.
***取得BOND資訊
  PERFORM GET_BOND_INFO USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE
                              '4'.


ENDFORM.                    " GET_ITEM_REMARK_CRDMEMO
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_PROFORMA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_ITEM_REMARK_PROFORMA USING PFWA_HEAD STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'R'.                                                                    "R = Proforma
***REMARK
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING 'Remark:'
                                     PFWA_HEAD-VBELN
                                     PFWA_HEAD-ZTYPE
                                     ''.
***SALES ORDER
  PERFORM GET_SO_LIST USING PFWA_HEAD-VBELN
                            PFWA_HEAD-ZTYPE
                            PFWA_HEAD-ZMTSO.
***取得ORDER TEXT 資料
  PERFORM SP_RULE_FOR_REMARK_OTEXT USING PFWA_HEAD-VBELN
                                         PFWA_HEAD-ZTYPE
                                         PFWA_HEAD-KUNAG.
***TRADE TERM
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VBELN
                               PFWA_HEAD-ZTYPE.
***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE.
***取得BOND資訊
  PERFORM GET_BOND_INFO USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE
                              '4'.

ENDFORM.                    " GET_ITEM_REMARK_PROFORMA
*&---------------------------------------------------------------------*
*&      Form  CHECK_PROFORMA_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VBFA_VBELN  text
*      <--P_P_CANCL  text
*----------------------------------------------------------------------*
FORM CHECK_PROFORMA_STATUS  USING    PFV_VBELN
                                     PFV_ZTYPE
                            CHANGING PFV_CANCE                                                    "分母/是否CANCEL
                                     PFV_NUMBE.                                                   "分子
  DATA: PFV_PTYPE(04) TYPE C,                   "判斷是以片計價還是用Rate
        PFV_LINES     TYPE TDLINE,
        PFV_DENOM(10) TYPE N,                   "分母
        PFV_MOLEC(10) TYPE N,                   "分子
        PFV_CALCU     TYPE P DECIMALS 3.
*        P_NUMB2(10) TYPE  N.

  CLEAR: PFV_CANCE, PFV_NUMBE, PFV_CALCU.

  PERFORM GET_PI_RATE_PRICE_DATA USING    PFV_VBELN
                                 CHANGING PFV_PTYPE
                                          PFV_LINES.

**CHECK時做的事情
  IF PFV_ZTYPE = 'CHCK'.
***沒有值表示沒有維護
    IF PFV_LINES IS INITIAL.
      MESSAGE I000 WITH PFV_VBELN
        'This Proforma Invoice Rate value of down payment does not exist (請維護比例或以片計價)'.
      PFV_CANCE = 'X'.
      EXIT.
    ENDIF.
***第一碼是'X'表示Cancel
    IF  PFV_LINES+0(1) = 'X' OR
        PFV_LINES+0(1) = 'x'.
      MESSAGE I000 WITH PFV_VBELN 'This Proforma Invoice is Canceled!!'.
      PFV_CANCE = 'X'.
      EXIT.
    ENDIF.
    CHECK PFV_PTYPE = 'RATE'.         "只有維護Rate才會需要檢查下面的部份,若是PC不檢查
    IF PFV_LINES CS '/'.
      SPLIT PFV_LINES AT '/' INTO PFV_MOLEC PFV_DENOM.
      IF PFV_DENOM = 0.
        MESSAGE I000 WITH PFV_VBELN '分母為0'.
        PFV_CANCE = 'X'.
        EXIT.
      ENDIF.
      PFV_CALCU = PFV_MOLEC / PFV_DENOM.
***比例>1也是ERROR
      IF PFV_CALCU > 1.
        MESSAGE I000 WITH PFV_VBELN 'Rate value greater than 1 -->' PFV_LINES.
        PFV_CANCE = 'X'.
        EXIT.
      ENDIF.
      CLEAR PFV_CANCE.                "外面會檢查它是否有值,就值就認定CANCAL
    ELSE.
***沒有'/'表示格式錯誤
      MESSAGE I000 WITH PFV_VBELN 'Rate value format error -->' PFV_LINES.
      PFV_CANCE = 'X'.
    ENDIF.
    EXIT.
  ENDIF.
**這個都是在抓FLOW DATA(VBFA)時才會用這個參數,所以沒有值及CANCEL都不要放到FLOW中
  IF PFV_ZTYPE = 'CANC'.
***沒有值表示沒有維護
    IF PFV_LINES = ''.
      PFV_CANCE = 'X'.
      EXIT.
    ENDIF.
***第一碼是'X'表示Cancel
    IF  PFV_LINES+0(1) = 'X' OR
        PFV_LINES+0(1) = 'x'.
      PFV_CANCE = 'X'.
    ENDIF.
    EXIT.
  ENDIF.
**只要抓RATE的狀態時
  IF PFV_ZTYPE = 'RATE'.
    SPLIT PFV_LINES AT '/' INTO PFV_NUMBE PFV_CANCE.
    PFV_CALCU = PFV_NUMBE / PFV_CANCE.          "這段好像沒有用
    EXIT.
  ENDIF.
**抓以片計價的金額
  IF PFV_ZTYPE = 'BYPC'.
    PFV_CANCE = PFV_LINES.
  ENDIF.
ENDFORM.                    " CHECK_PROFORMA_STATUS
*&---------------------------------------------------------------------*
*&      Form  GET_BILLING_CONDITIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_PIITEM_PERFI  text
*      <--P_I_ITEM_PIITEM_FOAMT  text
*      <--P_I_ITEM_PIITEM_PITAX  text
*----------------------------------------------------------------------*
FORM GET_BILLING_CONDITIONS  USING    PF_VBELN
                                      PF_AUBEL
                             CHANGING PF_FOAMT.
  DATA: P_VBRP  LIKE  VBRP        OCCURS 0 WITH HEADER LINE.

**檢查各ITEM是否有使用PROFORMA INVOICE
  SELECT * INTO CORRESPONDING FIELDS OF TABLE P_VBRP FROM   VBRP
                                                     WHERE  VBELN = PF_VBELN
                                                     AND    AUBEL = PF_AUBEL.



  CHECK PF_FOAMT IS INITIAL. "為防止預收貨款退回PF_VBELN為中文
  LOOP AT P_VBRP.
    CLEAR: VBRK, KONV.
    SELECT SINGLE * FROM  VBRK
                    WHERE VBELN = PF_VBELN.
    SELECT SINGLE * FROM  KONV
                    WHERE KNUMV = VBRK-KNUMV
                    AND   KPOSN = P_VBRP-POSNR
                    AND   KSCHL = 'PR00'.
    IF SY-SUBRC = 0.
      PF_FOAMT = PF_FOAMT + KONV-KWERT.
*      PF_WAERK = KONV-WAERS.
    ENDIF.

*    CLEAR: KONV.
*    SELECT SINGLE * FROM  KONV
*                    WHERE KNUMV = VBRK-KNUMV
*                    AND   KPOSN = P_VBRP-POSNR
*                    AND   KSCHL = 'MWST'.
*    IF SY-SUBRC = 0.
*      PF_PITAX = PF_PITAX + KONV-KWERT.
*    ENDIF.
  ENDLOOP.
ENDFORM.                    " GET_BILLING_CONDITIONS

*&---------------------------------------------------------------------*
*&      Form  UPDATE_INFO_TO_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_INFO_TO_TABLE USING PFV_WTYPE.
  CASE PFV_WTYPE.
    WHEN 'GEN'.
      PERFORM UPDATE_ZPD1.                                "PROFORMA記錄用(待癈...NEW PI就用不到)
*      PERFORM UPDATE_ZPDX.                               "吃PROFORMA金額的INVOICE要去UPDATE它
    WHEN 'FTP' OR 'MAIL'.
      PERFORM UPDATE_ZB2BI1 USING PFV_WTYPE.
    WHEN 'OUT'.
      PERFORM UPDATE_ZBCOD.
      PERFORM UPDATE_ZF32CA.
      PERFORM UPDATE_ZSD04.
      PERFORM UPDATE_ZSD52.                               "PACKING記錄PALLET及CARTON的數量與DN的關係
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " UPDATE_INFO_TO_TABLE
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZPD1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_ZPD1 .
  DATA: PFWA_ZPD1       LIKE ZPD1,
        PFWA_VBRK       LIKE VBRK.
  LOOP AT I_HEAD WHERE ZTYPE = 'R'.
**要先判斷1.已有值 2.已經出過貨,不然每次執行都會清掉  SFOAMT/SLOAMT
    READ TABLE I_ZPDH WITH KEY PERFI = I_HEAD-VBELN.        "I210422
    CHECK SY-SUBRC <> 0.                                    "I210422

    PERFORM GET_WORKAREA_ZPD1 USING     I_HEAD-VBELN
                              CHANGING  PFWA_ZPD1.
    IF PFWA_ZPD1 IS NOT INITIAL.
      CHECK PFWA_ZPD1-SFOAMT = 0.               "有出過貨就不可以更新資料了
      CLEAR: PFWA_ZPD1.
    ENDIF.
**有值就取代,沒值就APPEND
    READ TABLE I_ITEM_PIHEAD WITH KEY VBELN = I_HEAD-VBELN
                                      ZTYPE = I_HEAD-ZTYPE.
    PERFORM GET_WORKAREA_VBRK USING     I_HEAD-VBELN
                              CHANGING  PFWA_VBRK.
*    PERFORM GET_WORKAREA_VBRK_WITH_NEWPI TABLES   I_ZPDH
*                                         USING    I_HEAD-VBELN
*                                         CHANGING PFWA_VBRK.          "I210217(把新PI資料也放在PFWA_VBRK) D210422
*    PERFORM GET_WORKAREA_VBRK USING     I_HEAD-VBELN
*                              CHANGING  PFWA_VBRK.                    "D210217

    PERFORM GET_PI_TYPE TABLES    I_ZPDH
                        USING     I_HEAD-VBELN
                        CHANGING  PFWA_ZPD1-PITYPE.         "I210217
**<-I190111 D210217(併入GET_PI_TYPE)
*    PERFORM GET_PI_RATE_PRICE_DATA USING    I_HEAD-VBELN
*                                   CHANGING PFV_PTYPE
*                                            PFV_LINES_X.
*    IF PFV_PTYPE = 'PC'.              "以片計價
*      PFWA_ZPD1-PITYPE = 1.
*    ENDIF.
**->I190111 D210217


    PFWA_ZPD1-PERFI  = I_HEAD-VBELN.
    PFWA_ZPD1-ERNAM  = SY-UNAME.
    PFWA_ZPD1-ERDAT  = SY-DATUM.
    PFWA_ZPD1-ERZET  = SY-UZEIT.
    PFWA_ZPD1-WAERK  = PFWA_VBRK-WAERK.
    PFWA_ZPD1-KURRF  = PFWA_VBRK-KURRF.
    PFWA_ZPD1-NETWR  = I_ITEM_PIHEAD-RESUT.
    PFWA_ZPD1-LNETWR = I_ITEM_PIHEAD-TRESU.
    PFWA_ZPD1-LWAERK = I_ITEM_PIHEAD-TWAER.

    MODIFY ZPD1 FROM  PFWA_ZPD1.
    CLEAR PFWA_ZPD1.

*    CLEAR: ZPD1.
*    SELECT SINGLE * FROM  ZPD1
*                    WHERE PERFI = I_HEAD-VBELN.
*    CHECK SY-SUBRC <> 0.
*    CLEAR: ZPD1, VBRK.
*    ZPD1-PERFI = I_HEAD-VBELN.
*    ZPD1-ERNAM = SY-UNAME.
*    ZPD1-ERDAT = SY-DATUM.
*    ZPD1-ERZET = SY-UZEIT.
*    SELECT SINGLE * FROM  VBRK
*                    WHERE VBELN = I_HEAD-VBELN.
*    ZPD1-WAERK = VBRK-WAERK.
*    ZPD1-KURRF = VBRK-KURRF.
*    READ TABLE I_ITEM_PIHEAD WITH KEY VBELN = I_HEAD-VBELN ZTYPE = I_HEAD-ZTYPE.
*    ZPD1-NETWR  = I_ITEM_PIHEAD-TOTAL.
*    ZPD1-LNETWR = I_ITEM_PIHEAD-TRESU.
*    ZPD1-LWAERK = I_ITEM_PIHEAD-TWAER.
*    MODIFY ZPD1.
  ENDLOOP.
ENDFORM.                    " UPDATE_ZPD1
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZSD52
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_ZSD52 .
  DATA: PF_ZSD52 LIKE ZSD52 OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_ZSD52, PF_ZSD52[].

  LOOP AT I_HEAD WHERE ZTYPE = 'P'.
    LOOP AT I_ITEM WHERE VBELN = I_HEAD-VGBEL
                   AND   ZTYPE = I_HEAD-ZTYPE.
      PF_ZSD52-VBELN = I_ITEM-VBELN.
      PF_ZSD52-CTNNO = I_ITEM-CORDE.
      PF_ZSD52-PLTNO = I_ITEM-PORDE.
      APPEND PF_ZSD52.
      CLEAR: PF_ZSD52.
    ENDLOOP.
  ENDLOOP.

  LOOP AT PF_ZSD52.
    CHECK  PF_ZSD52-CTNNO = 0 AND
           PF_ZSD52-PLTNO = 0.
    DELETE PF_ZSD52.
  ENDLOOP.

  SORT PF_ZSD52.
  DELETE ADJACENT DUPLICATES FROM PF_ZSD52.

  LOOP AT PF_ZSD52.
    AT END OF VBELN.
      EXIT.
    ENDAT.
    DELETE PF_ZSD52.
  ENDLOOP.

  MODIFY ZSD52 FROM TABLE PF_ZSD52.
ENDFORM.                    " UPDATE_ZSD52
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZPDX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM UPDATE_ZPDX .
*  DATA: PF_ZPD2       LIKE ZPD2 OCCURS 0 WITH HEADER LINE,
*        PF_ZPD6       LIKE ZPD6 OCCURS 0 WITH HEADER LINE.
*  CLEAR:  PF_ZPD2, PF_ZPD2[], PF_ZPD6, PF_ZPD6[].
***如果是PROFORMA的DOC.不用寫入
*  LOOP AT I_ITEM_PIITEM WHERE ZTYPE = 'I'.
*    READ TABLE I_ITEM_PIHEAD WITH KEY VBELN = I_ITEM_PIITEM-VBELN
*                                      ZTYPE = I_ITEM_PIITEM-ZTYPE.
*    PF_ZPD2-VBELN = I_ITEM_PIITEM-VBELN.
**   PF_ZPD2-POSNR = I_ITEM_PIITEM-POSNR.
*    PF_ZPD2-PERFI = I_ITEM_PIITEM-PERFI.
*    PF_ZPD2-FOAMT = I_ITEM_PIITEM-FOAMT.
*    PF_ZPD2-WAERK = I_ITEM_PIITEM-WAERK.
*    PF_ZPD2-LOAMT = I_ITEM_PIITEM-FOAMT * I_ITEM_PIHEAD-KURRF.
*    PERFORM CURRENCY_CONVERT USING    I_ITEM_PIHEAD-TWAER
*                             CHANGING PF_ZPD2-LOAMT.
*    PF_ZPD2-LWAER = I_ITEM_PIHEAD-TWAER.
*    PF_ZPD2-BALAC = I_ITEM_PIHEAD-RESUT.
**<-M170920
*    PERFORM GET_BILLING_AMOUNT_ICU_TAX USING    I_ITEM_PIITEM-PERFI
*                                       CHANGING PF_ZPD2-NETWR.
**    SELECT SINGLE * FROM  VBRK
**                    WHERE VBELN = I_ITEM_PIITEM-PERFI.
**    IF SY-SUBRC = 0.
**      PF_ZPD2-NETWR = VBRK-NETWR.
**    ENDIF.
**->M170920
*    PF_ZPD2-AENAM = SY-UNAME.
*    PF_ZPD2-AEDAT = SY-DATUM.
*    PF_ZPD2-AEZET = SY-UZEIT.
*    APPEND PF_ZPD2.
*    CHECK I_ITEM_PIITEM-PITAX IS NOT INITIAL.
*    PF_ZPD6-VBELN = I_ITEM_PIITEM-VBELN.
**   PF_ZPD6-POSNR = I_ITEM_PIITEM-POSNR.
*    PF_ZPD6-PERFI = I_ITEM_PIITEM-PERFI.
*    PF_ZPD6-FOAMT = I_ITEM_PIITEM-PITAX.
*    PF_ZPD6-WAERK = I_ITEM_PIITEM-WAERK.
*    PF_ZPD6-LOAMT = I_ITEM_PIITEM-PITAX * I_ITEM_PIHEAD-KURRF.
*    PERFORM CURRENCY_CONVERT USING    I_ITEM_PIHEAD-TWAER
*                             CHANGING PF_ZPD6-LOAMT.
*    PF_ZPD6-LWAER = I_ITEM_PIHEAD-TWAER.
**<-M170920
*    PERFORM GET_BILLING_AMOUNT_ICU_TAX USING    I_ITEM_PIITEM-PERFI
*                                       CHANGING PF_ZPD6-NETWR.
**    PF_ZPD6-NETWR = VBRK-NETWR.
**->M170920
*    PF_ZPD6-AENAM = SY-UNAME.
*    PF_ZPD6-AEDAT = SY-DATUM.
*    PF_ZPD6-AEZET = SY-UZEIT.
*    APPEND PF_ZPD6.
*  ENDLOOP.
***已有值就不用UPDATE
*  LOOP AT PF_ZPD2.
*    SELECT SINGLE * FROM  ZPD2
*                    WHERE VBELN = PF_ZPD2-VBELN
**                   AND   POSNR = PF_ZPD2-POSNR
*                    AND   PERFI = PF_ZPD2-PERFI
*                    AND   FOAMT = PF_ZPD2-FOAMT
*                    AND   WAERK = PF_ZPD2-WAERK
*                    AND   LOAMT = PF_ZPD2-LOAMT
*                    AND   LWAER = PF_ZPD2-LWAER
*                    AND   NETWR = PF_ZPD2-NETWR
*                    AND   BALAC = PF_ZPD2-BALAC.
*    CHECK SY-SUBRC = 0.
*    DELETE PF_ZPD2.
*  ENDLOOP.
*  LOOP AT PF_ZPD6.
*    SELECT SINGLE * FROM  ZPD6
*                    WHERE VBELN = PF_ZPD6-VBELN
**                   AND   POSNR = PF_ZPD6-POSNR
*                    AND   PERFI = PF_ZPD6-PERFI
*                    AND   FOAMT = PF_ZPD6-FOAMT
*                    AND   WAERK = PF_ZPD6-WAERK
*                    AND   LOAMT = PF_ZPD6-LOAMT
*                    AND   LWAER = PF_ZPD6-LWAER
*                    AND   NETWR = PF_ZPD6-NETWR.
*    CHECK SY-SUBRC = 0.
*    DELETE PF_ZPD6.
*  ENDLOOP.
*
*  IF PF_ZPD2[] IS NOT INITIAL.
*    MODIFY ZPD2 FROM TABLE PF_ZPD2.
*  ENDIF.
*  IF PF_ZPD6[] IS NOT INITIAL.
*    MODIFY ZPD6 FROM TABLE PF_ZPD6.
*  ENDIF.
*
*
**<-D170901
**  DATA: BEGIN OF PF_IVPI OCCURS 0,
**          VBELN LIKE VBRK-VBELN,
**          POSNR LIKE VBRP-POSNR,
**          PERFI LIKE VBRK-VBELN,
**        END OF PF_IVPI.
**  DATA: "PF_ZPD2       LIKE ZPD2 OCCURS 0 WITH HEADER LINE,
**        "PF_ZPD6       LIKE ZPD6 OCCURS 0 WITH HEADER LINE,
**        PFV_NUMB1(10) TYPE N,
**        PFV_NUMB2(10) TYPE N,
**        X_NETWT       LIKE VBRP-NETWR,    "無用變數
**        X_WAERK       LIKE VBRK-WAERK.    "無用變數
**
**
**  LOOP AT I_HEAD WHERE ZTYPE = 'I'
**                 AND   PFLAG = 'X'.
**    CLEAR: PF_IVPI, PF_IVPI[], PF_ZPD2, PF_ZPD2[].
**    LOOP AT I_ITEM_PIITEM WHERE VBELN = I_HEAD-VBELN
**                          AND   ZTYPE = I_HEAD-ZTYPE.
**      PF_IVPI-VBELN = I_ITEM_PIITEM-VBELN.
**      PF_IVPI-POSNR = I_ITEM_PIITEM-POSNR.
**      PF_IVPI-PERFI = I_ITEM_PIITEM-PERFI.
**      APPEND  PF_IVPI.
**      CLEAR   PF_IVPI.
**    ENDLOOP.
**
***    CLEAR: PF_ZPD2, PF_ZPD2[].
**    LOOP AT PF_IVPI.
**      CLEAR: ZPD2.
**      READ TABLE I_ITEM_PIITEM WITH KEY VBELN = PF_IVPI-VBELN
**                                        POSNR = PF_IVPI-POSNR
**                                        PERFI = PF_IVPI-PERFI.
**      READ TABLE I_ITEM_PIHEAD WITH KEY VBELN = I_HEAD-VBELN
**                                        ZTYPE = I_HEAD-ZTYPE.
******這段是處理重印的部份(先把ZPD1的值還原,ZPD2先刪)
**      SELECT SINGLE * FROM  ZPD2
**                      WHERE VBELN = PF_IVPI-VBELN
**                      AND   POSNR = PF_IVPI-POSNR
**                      AND   PERFI = PF_IVPI-PERFI.
**      IF SY-SUBRC = 0.  "有值表示重印,先把ZPD1中的值扣掉
**        CLEAR: ZPD1, PF_ZPD6, PF_ZPD6[].
**        SELECT SINGLE * FROM  ZPD1
**                        WHERE PERFI = ZPD2-PERFI.
**        IF SY-SUBRC = 0.
**          ZPD1-SFOAMT = ZPD1-SFOAMT - ZPD2-FOAMT.
**
**          SELECT SINGLE * FROM  ZPD6     "稅
**                          WHERE VBELN = PF_IVPI-VBELN
**                          AND   POSNR = PF_IVPI-POSNR                             "I150312
**                          AND   PERFI = PF_IVPI-PERFI.
**          IF SY-SUBRC = 0.
**            ZPD1-SFOAMT = ZPD1-SFOAMT - ZPD6-FOAMT.
**            MOVE-CORRESPONDING ZPD6 TO PF_ZPD6.
**            APPEND PF_ZPD6.
**            CLEAR  PF_ZPD6.
**            DELETE ZPD6.
**          ENDIF.
**          UPDATE ZPD1.
**          MOVE-CORRESPONDING ZPD2 TO PF_ZPD2.
**          APPEND PF_ZPD2.
**          CLEAR  PF_ZPD2.
**          DELETE ZPD2.
**        ELSE.
**          MESSAGE E000 WITH TEXT-E20.                                             "TEXT-E20 = 'Select table ZPD1 failed'
**        ENDIF.
**      ENDIF.
******這段處理沒有資料在ZPD2的狀況(ZPD1要把值加進去)
**      CLEAR: ZPD2.
**      SELECT SINGLE * FROM  ZPD2
**                      WHERE VBELN = PF_IVPI-VBELN
**                      AND   POSNR = PF_IVPI-POSNR
**                      AND   PERFI = PF_IVPI-PERFI.
**      IF SY-SUBRC <> 0.       "沒有值就要加值進ZPD1
**        CLEAR: ZPD1.
**        SELECT SINGLE * FROM  ZPD1
**                        WHERE PERFI = I_ITEM_PIITEM-PERFI.
**        IF SY-SUBRC = 0.
**          ZPD1-SFOAMT = ZPD1-SFOAMT + I_ITEM_PIITEM-FOAMT + I_ITEM_PIITEM-PITAX.
**          UPDATE ZPD1.
**        ELSE.
**          MESSAGE E000 WITH TEXT-E20.                                             "TEXT-E20 = 'Select table ZPD1 failed'
**        ENDIF.
**        IF I_ITEM_PIITEM-PITAX > 0.   "有稅
**          CLEAR ZPD6.
**          READ TABLE PF_ZPD6 WITH KEY VBELN = I_ITEM_PIITEM-VBELN
**                                      POSNR = I_ITEM_PIITEM-POSNR                 "I150312
**                                      PERFI = I_ITEM_PIITEM-PERFI
**                                      FOAMT = I_ITEM_PIITEM-PITAX.
**          IF SY-SUBRC = 0.
**            MOVE-CORRESPONDING PF_ZPD6 TO ZPD6.
**          ELSE.
**            ZPD6-VBELN = I_ITEM_PIITEM-VBELN.
**            ZPD6-POSNR = I_ITEM_PIITEM-POSNR.                                     "I150312
**            ZPD6-PERFI = I_ITEM_PIITEM-PERFI.
**            ZPD6-FOAMT = I_ITEM_PIITEM-PITAX.
**            ZPD6-WAERK = I_ITEM_PIITEM-WAERK.
**            ZPD6-LWAER = I_ITEM_PIHEAD-TWAER.
**            ZPD6-AENAM = SY-UNAME.
**            ZPD6-AEDAT = SY-DATUM.
**            ZPD6-AEZET = SY-UZEIT.
**            CLEAR:X_NETWT, X_WAERK.
**            PERFORM GET_BILLING_CONDITIONS USING    I_ITEM_PIITEM-PERFI
**                                                    I_ITEM_PIITEM-AUBEL
**                                           CHANGING ZPD6-NETWR.
***<-I160627
**            PERFORM CHECK_PROFORMA_STATUS USING     I_ITEM_PIITEM-PERFI
**                                                    TEXT-FN1                                      "TEXT-FN1 = 'RATE'
**                                          CHANGING  PFV_NUMB1
**                                                    PFV_NUMB2.
**            ZPD6-NETWR = ZPD6-NETWR * PFV_NUMB2 / PFV_NUMB1.
***->I160627
**            ZPD6-LOAMT = I_ITEM_PIITEM-PITAX * I_ITEM_PIHEAD-KURRF.
**            PERFORM CURRENCY_CONVERT USING    I_ITEM_PIHEAD-TWAER
**                                     CHANGING ZPD6-LOAMT.
**          ENDIF.
**          MODIFY ZPD6.
**        ENDIF.
**        CLEAR: ZPD2.
**        READ TABLE PF_ZPD2 WITH KEY VBELN = I_ITEM_PIITEM-VBELN
**                                    POSNR = I_ITEM_PIITEM-POSNR
**                                    PERFI = I_ITEM_PIITEM-PERFI
**                                    FOAMT = I_ITEM_PIITEM-FOAMT.
**        IF SY-SUBRC = 0.
**            MOVE-CORRESPONDING PF_ZPD2 TO ZPD2.
**        ELSE.
**          ZPD2-AENAM = SY-UNAME.
**          ZPD2-AEDAT = SY-DATUM.
**          ZPD2-AEZET = SY-UZEIT.
**          ZPD2-VBELN = I_ITEM_PIITEM-VBELN.
**          ZPD2-POSNR = I_ITEM_PIITEM-POSNR.
**          ZPD2-PERFI = I_ITEM_PIITEM-PERFI.
**          ZPD2-FOAMT = I_ITEM_PIITEM-FOAMT.
**          ZPD2-WAERK = I_ITEM_PIITEM-WAERK.
**          ZPD2-LWAER = I_ITEM_PIHEAD-TWAER.
**          ZPD2-BALAC = I_ITEM_PIHEAD-RESUT.                                                       "I170627
**          CLEAR:X_NETWT, X_WAERK.
**          PERFORM GET_BILLING_CONDITIONS USING    I_ITEM_PIITEM-PERFI
**                                                  I_ITEM_PIITEM-AUBEL
**                                         CHANGING ZPD2-NETWR.
***<-I160627
**          PERFORM CHECK_PROFORMA_STATUS USING     I_ITEM_PIITEM-PERFI
**                                                  'RATE'
**                                        CHANGING  PFV_NUMB1
**                                                  PFV_NUMB2.
**          ZPD2-NETWR = ZPD2-NETWR * PFV_NUMB2 / PFV_NUMB1.
***->I160627
**          ZPD2-LOAMT = I_ITEM_PIITEM-FOAMT * I_ITEM_PIHEAD-KURRF.
**          PERFORM CURRENCY_CONVERT USING    I_ITEM_PIHEAD-TWAER
**                                   CHANGING ZPD2-LOAMT.
**        ENDIF.
**        MODIFY ZPD2.
**      ENDIF.
**    ENDLOOP.
**  ENDLOOP.
**->D170901
*ENDFORM.                    " UPDATE_ZPDX
*&---------------------------------------------------------------------*
*&      Form  CURRENCY_CONVERT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_PIHEAD_TWAER  text
*      <--P_I_ITEM_PIHEAD_TRESU  text
*----------------------------------------------------------------------*
FORM CURRENCY_CONVERT  USING    PFV_TWARE_I
                       CHANGING PFV_TRESU_IO.
  DATA:  PFV_LENTH TYPE I,
         PFV_TRESU TYPE STRING,
         PFV_TRESV LIKE BAPICURR-BAPICURR.

  CHECK PFV_TRESU_IO IS NOT INITIAL.
  PFV_TRESU = PFV_TRESU_IO.
  PFV_TRESV = PFV_TRESU_IO.
  PFV_LENTH = STRLEN( PFV_TRESU ).

  CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_INTERNAL'
    EXPORTING
      CURRENCY             = PFV_TWARE_I
      AMOUNT_EXTERNAL      = PFV_TRESV
      MAX_NUMBER_OF_DIGITS = PFV_LENTH
    IMPORTING
      AMOUNT_INTERNAL      = PFV_TRESU_IO.
*     RETURN                     =
ENDFORM.                    " CURRENCY_CONVERT
*&---------------------------------------------------------------------*
*&      Form  SELECTED_TO_PRINT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELECTED_TO_PRINT USING PF_FUNC.
  DATA: P_RECOS TYPE I .

  P_RECOS = 5.      "從第五行開始看(其他是表頭)

  CASE PF_FUNC.
    WHEN 'VIEW'.
      CLEAR: I_HEAD, I_HEAD[].
**防止使用者按上一頁重選範圍
      APPEND LINES OF O_HEAD TO I_HEAD.
    WHEN OTHERS.
  ENDCASE.


  DO.
    READ LINE P_RECOS.

    IF SY-SUBRC <> 0.
      EXIT.
    ENDIF.

    CASE PF_FUNC.
      WHEN 'VIEW'.
        IF SY-LISEL+0(1) = ' '.
          LOOP AT I_HEAD WHERE  ZTYPE         = SY-LISEL+06(01)
                         AND    VBELN+02(08)  = SY-LISEL+13(08).
            DELETE I_HEAD.
            EXIT.
          ENDLOOP.
        ENDIF.
      WHEN 'SALL'.
        SY-LISEL+0(1) = 'X'.
        IF SY-LISEL+13(08) <> SPACE.
          IF SY-SUBRC = 0.
            MODIFY LINE P_RECOS.
          ENDIF.
        ENDIF.
      WHEN 'DALL'.
        SY-LISEL+0(1) = ''.
        IF SY-LISEL+13(08) <> SPACE.
          IF SY-SUBRC = 0.
            MODIFY LINE P_RECOS.
          ENDIF.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.
    ADD 1 TO P_RECOS.
  ENDDO.

  CLEAR: S_HEAD, S_HEAD[], B_HEAD, B_HEAD[].
  APPEND LINES OF I_HEAD TO S_HEAD.       "S_HEAD記錄選擇的項目用
  APPEND LINES OF I_HEAD TO B_HEAD.

ENDFORM.                    " SELECTED_TO_PRINT

*&---------------------------------------------------------------------*
*&      Form  GET_SENT_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK_VBELN  text
*      -->P_I_VBRK_KUNAG  text
*      <--P_I_HEAD_ZFSET  text
*      <--P_I_HEAD_ZMSET  text
*----------------------------------------------------------------------*
FORM GET_SENT_INFO  USING    PFV_VBELN
                             PFV_KUNAG
                    CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PF_ZB2BI1     LIKE ZB2BI1   OCCURS 0 WITH HEADER LINE,
        PFV_REPID(40) TYPE C,
        PFV_MFORC     LIKE ZB2BI1-FOR_CUST,
        PFV_FFORC     LIKE ZB2BI1-FOR_CUST.

  CLEAR:  PF_ZB2BI1, PF_ZB2BI1[], PFWA_HEAD_IO-ZFSET, PFWA_HEAD_IO-ZMSET, PFV_REPID, PFV_MFORC, PFV_FFORC.
  CONCATENATE SY-REPID '_' PFWA_HEAD_IO-ZTYPE
    INTO PFV_REPID.
  CONCATENATE PFWA_HEAD_IO-ZTYPE '_MAIL'
    INTO PFV_MFORC.
  CONCATENATE PFWA_HEAD_IO-ZTYPE '_FTP'
    INTO PFV_FFORC.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZB2BI1 FROM   ZB2BI1
                                                 WHERE  VBELN   = PFV_VBELN
                                                 AND    KUNAG   = PFV_KUNAG
                                                 AND    REMARK  = PFV_REPID.
  CHECK PF_ZB2BI1[] IS NOT INITIAL.
  LOOP AT PF_ZB2BI1.
    CASE PF_ZB2BI1-FOR_CUST.
      WHEN PFV_FFORC.
        PFWA_HEAD_IO-ZFSET = 'X'.
      WHEN PFV_MFORC.
        PFWA_HEAD_IO-ZMSET = 'X'.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " GET_SENT_INFO
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZB2BI1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_WTYPE  text
*      -->P_PF_VBELN  text
*      -->P_PF_ZTYPE  text
*----------------------------------------------------------------------*
FORM UPDATE_ZB2BI1  USING    PFV_WTYPE_I.

  DATA: PFV_REPID(40) TYPE C,
        PFV_FCUST(20) TYPE C.


  CLEAR: ZB2BI1, PFV_REPID, PFV_FCUST.

  CASE PFV_WTYPE_I.
    WHEN 'FTP'.
      CONCATENATE SY-REPID '_' I_HEAD-ZTYPE
        INTO PFV_REPID.
      ZB2BI1-VBELN    = I_HEAD-VBELN.
      ZB2BI1-KUNAG    = I_HEAD-KUNAG.
      PFV_FCUST       = I_HEAD-ZTYPE.
    WHEN 'MAIL'.
      CONCATENATE SY-CPROG '_' S_HEAD-ZTYPE
        INTO PFV_REPID.
      ZB2BI1-VBELN    = S_HEAD-VBELN.
      ZB2BI1-KUNAG    = S_HEAD-KUNAG.
      PFV_FCUST       = S_HEAD-ZTYPE.
    WHEN OTHERS.
  ENDCASE.

  ZB2BI1-DATUM    = SY-DATUM.
  ZB2BI1-UZEIT    = SY-UZEIT.
  CONCATENATE PFV_FCUST '_' PFV_WTYPE_I
    INTO PFV_FCUST.
  ZB2BI1-FOR_CUST = PFV_FCUST.
  ZB2BI1-ERNAM    = SY-UNAME.
  ZB2BI1-REMARK   = PFV_REPID.

  MODIFY ZB2BI1.
  COMMIT WORK.

ENDFORM.                    " UPDATE_ZB2BI1
*&---------------------------------------------------------------------*
*&      Form  GENERATE_FILES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_OTFDATA  text
*      -->P_PF_TYPE  text
*----------------------------------------------------------------------*
FORM GENERATE_FILES  TABLES   PF_OTFDATA_I
                     USING    PF_TYPES.

  DATA: P_LINES       TYPE TABLE OF TLINE,
        P_NLINE       TYPE          TLINE,
        P_FZIZE       TYPE          I,
        P_POSTE(10)   TYPE          P DECIMALS 0,
        P_LENTH(10)   TYPE          P DECIMALS 0,
        P_CONTENT     LIKE SOLISTI1   OCCURS 0 WITH HEADER LINE,
        PFWA_ZMMFTP   LIKE ZMMFTP,
        PFV_HANDL     TYPE          I,              "連FTP的PROCESS ID
        PFV_FNAME(15) TYPE          C,
        P_TBLIN       TYPE          I,
        P_TBSLN       TYPE          I,              "記錄每筆PDF起始筆數
        PFV_RECOD     TYPE          I,              "計算I_HEAD筆數
        PFV_FILNE     TYPE SO_OBJ_DES.    "附件檔名


  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      FORMAT                      = 'PDF'
      MAX_LINEWIDTH               = 132
*       ARCHIVE_INDEX               = ' '
*       COPYNUMBER                  = 0
*       ASCII_BIDI_VIS2LOG          = ' '
*       PDF_DELETE_OTFTAB           = ' '
*       PDF_USERNAME                = ' '
*       PDF_PREVIEW                 = ' '
*       USE_CASCADING               = ' '
    IMPORTING
      BIN_FILESIZE                = P_FZIZE
*       BIN_FILE                    =
    TABLES
      OTF                         = PF_OTFDATA_I
      LINES                       = P_LINES
*     EXCEPTIONS
*       ERR_MAX_LINEWIDTH           = 1
*       ERR_FORMAT                  = 2
*       ERR_CONV_NOT_POSSIBLE       = 3
*       ERR_BAD_OTF                 = 4
*       OTHERS                      = 5
            .
  IF SY-SUBRC <> 0.
*  MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


  LOOP AT P_LINES INTO P_NLINE.
    P_POSTE = 255 - P_LENTH.
    IF P_POSTE > 134. "LENGTH OF PDF_TABLE
      P_POSTE = 134.
    ENDIF.
    P_CONTENT+P_LENTH = P_NLINE(P_POSTE).
    P_LENTH = P_LENTH + P_POSTE.
    IF P_LENTH = 255. "LENGTH OF OUT (CONTENTS_BIN)
      APPEND P_CONTENT.
      CLEAR: P_CONTENT, P_LENTH.
      IF P_POSTE < 134.
        P_CONTENT = P_NLINE+P_POSTE.
        P_LENTH = 134 - P_POSTE.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF P_LENTH > 0.
    APPEND P_CONTENT.
  ENDIF.

  CASE PF_TYPES.
    WHEN 'FTP'.
      PERFORM GET_FTP_CONNECT_INFO CHANGING PFWA_ZMMFTP.

      CHECK PFWA_ZMMFTP IS NOT INITIAL.
***斷線
      PERFORM CONNECT_DISCONN_TO_FTP  USING    PFWA_ZMMFTP
                                               'CONN'
                                      CHANGING PFV_HANDL.
      PERFORM GET_MAIL_FTP_FILE_NAME USING     I_HEAD
                                               ''           "I190708
                                     CHANGING  PFV_FNAME.

      CALL FUNCTION 'FTP_R3_TO_SERVER'
        EXPORTING
          HANDLE               =  PFV_HANDL
          FNAME                =  PFV_FNAME
          BLOB_LENGTH          =  P_FZIZE
*         CHARACTER_MODE       =
        TABLES
          BLOB                 =  P_CONTENT
*         TEXT                 =
*       EXCEPTIONS
*         TCPIP_ERROR          = 1
*         COMMAND_ERROR        = 2
*         DATA_ERROR           = 3
*         OTHERS               = 4
                .
      IF SY-SUBRC <> 0.
        MESSAGE E000 WITH PFV_FNAME 'FTP傳送失敗!!'.
      ELSE.
        IF SY-UCOMM = 'FTP'.
          MESSAGE I000 WITH PFV_FNAME 'FTP完成!'.
        ENDIF.
      ENDIF.
***斷線
      PERFORM CONNECT_DISCONN_TO_FTP  USING    PFWA_ZMMFTP
                                               'DCONN'
                                      CHANGING PFV_HANDL.
    WHEN 'EML'.

      CLEAR: P_TBLIN, P_TBSLN, PFV_RECOD.
      DESCRIBE TABLE I_HEAD           LINES PFV_RECOD.
      DESCRIBE TABLE P_CONTENT        LINES P_TBLIN.
      DESCRIBE TABLE TA_CONTENTS_BIN  LINES P_TBSLN.
      P_TBSLN = P_TBSLN + 1.
      CLEAR: P_CONTENT.
      READ TABLE P_CONTENT INDEX P_TBLIN.

      IF SY-SUBRC = 0.
        IF PFV_RECOD = 1.
          READ TABLE I_HEAD INDEX 1.
        ENDIF.
        PERFORM GET_MAIL_FTP_FILE_NAME USING     I_HEAD
                                                 ''         "I190708
                                       CHANGING  PFV_FILNE.
        TA_PACKING_LIST-DOC_SIZE    = ( P_TBLIN - 1 ) * 255 + STRLEN( P_CONTENT ).
        TA_PACKING_LIST-TRANSF_BIN  = 'X'.
        TA_PACKING_LIST-HEAD_START  = 1.
        TA_PACKING_LIST-HEAD_NUM    = 0.
        TA_PACKING_LIST-BODY_START  = P_TBSLN.
        TA_PACKING_LIST-BODY_NUM    = P_TBLIN.
        TA_PACKING_LIST-DOC_TYPE    = 'PDF'.
        TA_PACKING_LIST-OBJ_NAME    = 'ATTACHMENT'.
        TA_PACKING_LIST-OBJ_DESCR   = PFV_FILNE.
        APPEND TA_PACKING_LIST.
      ENDIF.

      APPEND LINES OF P_CONTENT TO TA_CONTENTS_BIN.
    WHEN 'FILE'.
      APPEND LINES OF P_CONTENT TO TA_CONTENTS_BIN.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GENERATE_FILES
*&---------------------------------------------------------------------*
*&      Form  CONNECT_TO_FTP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_ZMMFTP_IPADDRESS  text
*      -->P_P_ZMMFTP_USERNAME  text
*      -->P_P_ZMMFTP_PASSWORD  text
*      -->P_P_ZMMFTP_UPATH  text
*      -->P_4322   text
*      <--P_P_HANDL  text
*----------------------------------------------------------------------*
FORM CONNECT_DISCONN_TO_FTP  USING    PFWA_ZMMFTP_I STRUCTURE ZMMFTP
                                      PFV_METHD
                             CHANGING PFV_HANDL.
  DATA: PFV_LENGH     TYPE I,
        PFV_COMMA(80) TYPE C,
        PFV_PASSW(30) TYPE C.

  DATA: BEGIN OF PF_DATAA OCCURS 0,                  "沒有使用,只是找個空間讓它接
           ZWORD(30) TYPE C,
        END OF PF_DATAA.
  CLEAR: PFV_LENGH, PFV_COMMA, PFV_PASSW.

  CASE PFV_METHD.
    WHEN 'CONN'.
*      SET EXTENDED CHECK OFF.
*Scramble password
      PFV_LENGH = STRLEN( PFWA_ZMMFTP_I-PASSWORD ).
      CONCATENATE 'cd' PFWA_ZMMFTP_I-UPATH
        INTO PFV_COMMA SEPARATED BY SPACE.

      CALL FUNCTION 'HTTP_SCRAMBLE'
        EXPORTING
          SOURCE      = PFWA_ZMMFTP_I-PASSWORD
          SOURCELEN   = PFV_LENGH
          KEY         = '26101957'
        IMPORTING
          DESTINATION = PFV_PASSW.

*Connect to FTP server
      CALL FUNCTION 'FTP_CONNECT'
        EXPORTING
          USER            = PFWA_ZMMFTP_I-USERNAME
          PASSWORD        = PFV_PASSW
          HOST            = PFWA_ZMMFTP_I-IPADDRESS
          RFC_DESTINATION = 'SAPFTPA'
        IMPORTING
          HANDLE          = PFV_HANDL
        EXCEPTIONS
          NOT_CONNECTED   = 1
          OTHERS          = 2.

      IF SY-SUBRC = 0.
        CALL FUNCTION 'FTP_COMMAND'
          EXPORTING
            HANDLE        = PFV_HANDL
            COMMAND       = PFV_COMMA
          TABLES
            DATA          = PF_DATAA
          EXCEPTIONS
            TCPIP_ERROR   = 1
            COMMAND_ERROR = 2
            DATA_ERROR    = 3.
        IF SY-SUBRC <> 0.
          MESSAGE E000 WITH '路徑不存在:' PFV_COMMA+3.
        ENDIF.
      ELSE.
        MESSAGE E000 WITH 'FTP尚未連結!(' PFWA_ZMMFTP_I-IPADDRESS ')'.
      ENDIF.
    WHEN 'DCON'.
      CALL FUNCTION 'FTP_DISCONNECT'
        EXPORTING
          HANDLE = PFV_HANDL.

      CALL FUNCTION 'RFC_CONNECTION_CLOSE'
        EXPORTING
          DESTINATION = 'SAPFTP'
        EXCEPTIONS
          OTHERS      = 1.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " CONNECT_TO_FTP
*&---------------------------------------------------------------------*
*&      Form  PREPARE_DATA_TO_SEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PREPARE_DATA USING PF_METHD .
  CLEAR: I_HEAD, I_HEAD[].

  CASE PF_METHD.
    WHEN 'SEND'.            "這個都是產生PDF檔
      LOOP AT O_HEAD WHERE VBELN = S_HEAD-VBELN
                     AND   ZTYPE = S_HEAD-ZTYPE.
        MOVE-CORRESPONDING O_HEAD TO I_HEAD.
        APPEND I_HEAD.
      ENDLOOP.
    WHEN 'PRIN'.
      APPEND LINES OF S_HEAD TO I_HEAD.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " PREPARE_DATA_TO_SEND
*&---------------------------------------------------------------------*
*&      Form  PDF_CREATE_FOR_PERVIEW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_UCOMM  text
*----------------------------------------------------------------------*
FORM PDF_CREATE_FOR_PERVIEW  USING    PFV_UCOMM.
  DATA: PF_HEAD_BK LIKE I_HEAD OCCURS 0 WITH HEADER LINE.
**把所選的都做成一個PDF
  IF PFV_UCOMM = 'APF'.
    CLEAR: PF_HEAD_BK, PF_HEAD_BK[].
    APPEND LINES OF I_HEAD TO PF_HEAD_BK.
    CLEAR: I_HEAD, I_HEAD[].
    APPEND LINES OF S_HEAD TO I_HEAD.
    PERFORM SEND_TO_SMARTFORM USING 'PDF'
                                    ''.
    CLEAR: I_HEAD, I_HEAD[].
    APPEND LINES OF  PF_HEAD_BK TO I_HEAD.
    EXIT.
  ENDIF.
**把所選1筆=1個PDF
  IF PFV_UCOMM = 'PDF'.
    LOOP AT S_HEAD.
      CLEAR: I_HEAD, I_HEAD[].
      MOVE-CORRESPONDING S_HEAD TO I_HEAD.
      APPEND I_HEAD.
*      PERFORM PREPARE_DATA USING 'SEND'.
      PERFORM SEND_TO_SMARTFORM USING 'PDF'
                                      ''.
    ENDLOOP.
    EXIT.
  ENDIF.
ENDFORM.                    " PDF_CREATE_FOR_PERVIEW
*&---------------------------------------------------------------------*
*&      Form  UPDATE_INTERNAL_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_INTERNAL_TABLE USING PF_FUNCT.
  DATA: PFV_REPID(40) TYPE C.

  CASE PF_FUNCT.
    WHEN 'FTP'.
      LOOP AT O_HEAD WHERE VBELN = S_HEAD-VBELN
                     AND   ZTYPE = S_HEAD-ZTYPE.
        CHECK O_HEAD-ZFSET IS INITIAL.
        O_HEAD-ZFSET = 'X'.
        MODIFY O_HEAD.
      ENDLOOP.
    WHEN 'MAIL'.
**再次檢查ZB2BI1是否已經有寫入
      CONCATENATE SY-REPID '_' S_HEAD-ZTYPE
        INTO PFV_REPID.
      CLEAR: ZB2BI1.
      SELECT SINGLE * FROM    ZB2BI1
                      WHERE   VBELN   = S_HEAD-VBELN
                      AND     KUNAG   = S_HEAD-KUNAG
                      AND     REMARK  = PFV_REPID.
      CHECK SY-SUBRC = 0.
      LOOP AT O_HEAD WHERE VBELN = S_HEAD-VBELN
                     AND   ZTYPE = S_HEAD-ZTYPE.
        CHECK O_HEAD-ZMSET IS INITIAL.
        O_HEAD-ZMSET = 'X'.
        MODIFY O_HEAD.
      ENDLOOP.
      LOOP AT B_HEAD WHERE VBELN = S_HEAD-VBELN
                     AND   ZTYPE = S_HEAD-ZTYPE.
        CHECK B_HEAD-ZMSET IS INITIAL.
        B_HEAD-ZMSET = 'X'.
        MODIFY B_HEAD.
      ENDLOOP.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " UPDATE_INTERNAL_TABLE

*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0300 OUTPUT.
  DATA: BEGIN OF MWA_HEAD,
          TITLE(20) TYPE C,           "[顯示用]表單類型
          ZTYPE     TYPE C,           "[計算]SCREEN 300 DOUBLE CLICK 記錄用
          ZCUST(07) TYPE C,           "[顯示用]BILL-TO 或SOLD-TO
          KUNAG     TYPE KUNAG,       "[計算]SCREEN 300 DOUBLE CLICK 記錄用
          NAME1     TYPE NAME1_GP,    "[顯示用]客戶名稱
          KUNNR     TYPE KUNWE,       "[顯示用]SHIP-TO
          NAME2     TYPE NAME1_GP,    "[顯示用]SHIP-TO NAME
          MTITL     TYPE SO_OBJ_DES,  "[顯示用]MAIL主旨
          SELEC(03) TYPE N VALUE 1,   "[判斷]針對有些客戶一單寄一次時使用(上下頁)
          COUNT(03) TYPE N,           "[顯示用]計算筆數
          TCOUN(03) TYPE N,           "[顯示用]計算該客戶的筆數
          MCOUN(04) TYPE N,           "[顯示用]MAIL LIST筆數
          SPART     TYPE SPART,       "[判斷用]DIVISION
        END OF MWA_HEAD.
  DATA: BEGIN OF M_ZSDEL OCCURS 0.
          INCLUDE STRUCTURE ZSDEL.
  DATA:   SELEC TYPE C,
          OTHER TYPE C,               "判斷為SHIP TO用
        END OF M_ZSDEL.

  DATA: MV_NCLEA      TYPE          C,                                        "[判斷]是否清除資料(MAIL LIST)
        M_ZSDEL_DEL   LIKE          M_ZSDEL OCCURS 0 WITH HEADER LINE,        "收集刪除的MAIL LIST
        M_REPID       TYPE          C,
        M_SVBEL       LIKE          VBRK-VBELN,
        M_EVBEL       LIKE          VBRK-VBELN,
        MC_EXCEL(01)  TYPE          C,          "判斷是否要MAIL Excel File
        MC_CMPDF(01)  TYPE          C,          "判斷MAIL附件的PDF是否要合併
        WA_COLS       LIKE LINE OF  TC300_MAIL-COLS.



  SET PF-STATUS 'G300'.
  SET TITLEBAR 'GEN' WITH 'E-Mail TO CUSTOMER'.

**取得此次選的客戶的單號列表
  PERFORM GET_CUST_DOC_LIST TABLES   S_HEAD
                            USING    ''
                            CHANGING MWA_HEAD.
**取得MAIL LIST
  PERFORM GET_MAIL_LIST TABLES   M_ZSDEL
                        USING    MV_NCLEA
                        CHANGING MWA_HEAD.
**取得單據類型
  PERFORM GET_DOC_TITLE_DESC CHANGING MWA_HEAD.


**取得BILL-TO/SOLD-TO客戶名
  PERFORM GET_CUST_NAME1 USING    MWA_HEAD-KUNAG
                         CHANGING MWA_HEAD-NAME1.
**取得SHIP-TO客戶名
  PERFORM GET_CUST_NAME1 USING    MWA_HEAD-KUNNR
                         CHANGING MWA_HEAD-NAME2.
**取得MAIL主旨,資料筆數
  PERFORM GET_MAIL_TITLE CHANGING MWA_HEAD.

  PERFORM SCREEN_MODIFY_MAIL_FUNCTION.

  PERFORM SP_RULE_FOR_SCREEN_DISP USING MWA_HEAD.

  DESCRIBE TABLE S_BKUNN  LINES TC300_BILL-LINES.
  DESCRIBE TABLE M_ZSDEL  LINES TC300_MAIL-LINES.
  DESCRIBE TABLE S_HEAD   LINES TC300_HEAD-LINES.

  CLEAR: OK_CODE.
ENDMODULE.                 " STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  S300_GET_TCDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_TC300_DATA USING PFV_JTYPE.
  DATA: PFWA_ZSD104 LIKE ZSD104.
  CLEAR: S_BKUNN, S_BKUNN[].
**除PACKING以外是收集BILL-TO及SOLD-TO
  LOOP AT S_HEAD WHERE ZTYPE <> 'P'.
    S_BKUNN-BKUNN = S_HEAD-BKUNN.
    S_BKUNN-KUNNR = S_HEAD-KUNAG.
    S_BKUNN-ZTYPE = S_HEAD-ZTYPE.
    APPEND: S_BKUNN.
    CLEAR:  S_BKUNN.
  ENDLOOP.
**PACKING是收集SOLD-TO及SHIP-TO
  LOOP AT S_HEAD WHERE ZTYPE = 'P'.   "PACKING是依SHIP-TO寄信
    S_BKUNN-BKUNN = S_HEAD-KUNAG.
    S_BKUNN-ZTYPE = S_HEAD-ZTYPE.
    PERFORM GET_WORKAREA_ZSD104 USING     S_HEAD-KUNAG
                                CHANGING  PFWA_ZSD104.
    IF PFWA_ZSD104 IS NOT INITIAL AND
       PFV_JTYPE = 'M'.
      S_BKUNN-KUNNR = S_HEAD-KUNNR.
    ENDIF.
    APPEND: S_BKUNN.
    CLEAR:  S_BKUNN.
  ENDLOOP.

  SORT S_BKUNN BY BKUNN ZTYPE KUNNR.
  DELETE ADJACENT DUPLICATES FROM S_BKUNN COMPARING ALL FIELDS.
  SORT S_BKUNN BY ZTYPE BKUNN KUNNR.
ENDFORM.                    " S300_GET_TCDATA

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0300 INPUT.

  CLEAR: MV_NCLEA.

  CASE OK_CODE.
    WHEN 'PICK'.            "由這裡取得S_BKUNN的第?筆
      PERFORM GET_SELECT_DATA_SOLD_ZTYPE CHANGING MWA_HEAD.
    WHEN 'MAIL'.
**檢查MAIL的主旨是否有填
      IF MWA_HEAD-MTITL IS INITIAL.
        MESSAGE I000 WITH 'Please check mail title!!'.
        EXIT.
      ENDIF.
*      PERFORM SEND_DOC_TO_OUTSIDE USING 'MAIL'        "D190708
*                                        ''            "D190708
*                                        P_JOBTPS.     "D190708
*I190708 -->
      IF MWA_HEAD-ZTYPE = 'P' OR                     "Packing
         MWA_HEAD-ZTYPE = 'F'.                       "Free
        PERFORM SEND_DOC_TO_OUTSIDE USING 'MAIL'
                                          ''
                                          P_JOBTPS.
      ENDIF.
      IF MWA_HEAD-ZTYPE = 'I' OR                     "Invoice
         MWA_HEAD-ZTYPE = 'C' OR                     "Credit
         MWA_HEAD-ZTYPE = 'D' OR                     "Debit
         MWA_HEAD-ZTYPE = 'R'.                       "PI


        PERFORM CHECK_SOLDTO TABLES S_HEAD
                             USING  MC_CMPDF
                                    P_ENCSTOP.
        CHECK P_ENCSTOP = ''.

        PERFORM COLLECT_SOLDTO TABLES S_HEAD
                                      ITMPSP.

        LOOP AT ITMPSP.
          PERFORM CHECK_CUST_ENCRYPT USING    ITMPSP-SOLDTO   "sold-to
                                     CHANGING V_ANS.
          IF V_ANS <> 'J'.
            EXIT.
          ENDIF.
        ENDLOOP.

        CHECK V_ANS = 'J'.

        PERFORM SAVE_PDF_FILE_FOR_ENCRYPT USING    P_JOBTPS
                                          CHANGING P_ENCSTOP.
        CHECK P_ENCSTOP = ''.
        MESSAGE I000 WITH 'MAIL寄送完成!!'.
      ENDIF.
*I190708 <--
    WHEN 'MADD'.
      APPEND INITIAL LINE TO M_ZSDEL.
      MV_NCLEA = 'X'.                           "告訴PBO不要清掉原來的MAIL LIST
    WHEN 'MDEL'.
      LOOP AT M_ZSDEL WHERE SELEC = 'X'.
        MOVE-CORRESPONDING M_ZSDEL TO M_ZSDEL_DEL.
        APPEND M_ZSDEL_DEL.
        DELETE M_ZSDEL.
      ENDLOOP.
      MV_NCLEA = 'X'.                           "告訴PBO不要清掉已修改的MAIL LIST
    WHEN 'MSAL'.
      M_ZSDEL-SELEC = 'X'.
      MODIFY M_ZSDEL TRANSPORTING SELEC WHERE SELEC = ''.
      MV_NCLEA = 'X'.
    WHEN 'MDAL'.
      CLEAR: M_ZSDEL-SELEC.
      MODIFY M_ZSDEL TRANSPORTING SELEC WHERE SELEC = 'X'.
      MV_NCLEA = 'X'.
    WHEN 'MSAV'.
      PERFORM SAVE_MAIL_LIST TABLES M_ZSDEL
                                    M_ZSDEL_DEL
                             USING  MWA_HEAD.
    WHEN 'MPRE'.
      CHECK MWA_HEAD-SELEC > 1.
      MWA_HEAD-SELEC = MWA_HEAD-SELEC - 1.
    WHEN 'MNEX'.
      MWA_HEAD-SELEC = MWA_HEAD-SELEC + 1.
    WHEN ''.        "輸完EMAIL後按ENTER
      MV_NCLEA = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0300  INPUT

*&---------------------------------------------------------------------*
*&      Form  GET_DOC_RANGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_M_SVBEL  text
*      -->P_M_EVBEL  text
*----------------------------------------------------------------------*
FORM GET_DOC_RANGE  CHANGING PFV_SVBEL_O
                             PFV_EVBEL_O
                             PFV_COUNT_O.
  DATA: PFV_COUNT TYPE I.

  DESCRIBE TABLE S_HEAD LINES PFV_COUNT.

  READ TABLE S_HEAD INDEX 1.
  WRITE: S_HEAD-VBELN TO PFV_SVBEL_O.
  READ TABLE S_HEAD INDEX PFV_COUNT.
  WRITE: S_HEAD-VBELN TO PFV_EVBEL_O.

  PFV_COUNT_O = PFV_COUNT.
ENDFORM.                    " GET_DOC_RANGE

*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_MAILTITLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_ZTYPE  text
*      -->P_R_BKUNN  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_MAILTITLE  CHANGING PFWA_MHEAD_IO STRUCTURE MWA_HEAD.
  DATA: PFV_VBELN     LIKE VBRK-VBELN,
        PFV_KUNAG     LIKE VBAK-KUNNR,
        PFV_KUNNR     LIKE VBAK-KUNNR,
        PFV_ZDATE(07) TYPE C,
        PFV_STVBL     LIKE VBRK-VBELN,
        PFV_ENVBL     LIKE VBRK-VBELN,
        PFX_COUNT     TYPE N.                         "不使用..只為接資料

  CASE PFWA_MHEAD_IO-KUNAG.
    WHEN '0000001840' OR     "HIMAX
         '0000001921'.
      CHECK PFWA_MHEAD_IO-ZTYPE = 'P'.
      READ TABLE S_HEAD INDEX 1.
      WRITE: PFWA_MHEAD_IO-KUNAG  TO PFV_KUNAG,
             S_HEAD-KUNNR         TO PFV_KUNNR.
      CLEAR: PFWA_MHEAD_IO-MTITL.               "放在外面原本有值會被清掉

      CONCATENATE 'PSMC Packing List-' PFV_KUNAG '-' PFV_KUNNR
        INTO PFWA_MHEAD_IO-MTITL.
    WHEN '0000001947'.        "UPI
      CHECK PFWA_MHEAD_IO-ZTYPE = 'P'.
      CONCATENATE PFWA_MHEAD_IO-MTITL '(UPI)'
        INTO PFWA_MHEAD_IO-MTITL.
    WHEN '0000001949'.        "奕力
      IF PFWA_MHEAD_IO-ZTYPE = 'I' OR
         PFWA_MHEAD_IO-ZTYPE = 'C' OR
         PFWA_MHEAD_IO-ZTYPE = 'F' OR                       "U190708
         PFWA_MHEAD_IO-ZTYPE = 'D'.                         "I190708
        CLEAR: PFWA_MHEAD_IO-MTITL.             "放在外面原本有值會被清掉
        CONCATENATE '[PSMC-B2B]ILITEK Invoice PDF File_' SY-DATUM
          INTO PFWA_MHEAD_IO-MTITL.
      ENDIF.
      IF PFWA_MHEAD_IO-ZTYPE = 'P'.
        CLEAR: PFWA_MHEAD_IO-MTITL.             "放在外面原本有值會被清掉
        CASE PFWA_MHEAD_IO-KUNNR.
          WHEN '0001001185'.  "久元
            CONCATENATE '[PSMC-B2B]ILITEK Packing PDF(久元)-' SY-DATUM
                    INTO PFWA_MHEAD_IO-MTITL.
          WHEN '0001003026'.  "頎邦
            CONCATENATE '[PSMC-B2B]ILITEK Packing PDF(頎邦)-' SY-DATUM
                    INTO PFWA_MHEAD_IO-MTITL.
          WHEN '0001001191'.  "南茂
            CONCATENATE '[PSMC-B2B]ILITEK Packing PDF(南茂)-' SY-DATUM
                    INTO PFWA_MHEAD_IO-MTITL.
          WHEN '0001003126'.  "頎邦研發
            CONCATENATE '[PSMC-B2B]ILITEK Packing PDF(頎邦研發)-' SY-DATUM
                    INTO PFWA_MHEAD_IO-MTITL.
          WHEN OTHERS.
            CONCATENATE '[PSMC-B2B]ILITEK Packing PDF(奕力)-' SY-DATUM
                    INTO PFWA_MHEAD_IO-MTITL.
        ENDCASE.
      ENDIF.
*    WHEN '0000002623' OR
*         '0000003208'.        "MAXIM(8"沒有用)
*      CHECK PFV_ZTYPE_I = 'I' OR
*            PFV_ZTYPE_I = 'C' OR
*            PFV_ZTYPE_I = 'F'.
*     CLEAR: PFV_MTITL_O.             "放在外面原本有值會被清掉
*     READ TABLE S_HEAD INDEX 1.
*     WRITE S_HEAD-VBELN TO PFV_VBELN.
*     CONCATENATE 'PSMC Invoice_' PFV_VBELN
*       INTO PFV_MTITL_O.

    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " SPECIAL_RULE_FOR_MAILTITLE
*&---------------------------------------------------------------------*
*&      Module  PAI300_ENTRY  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE PAI300_ENTRY INPUT.
  IF M_ZSDEL-VKORG IS INITIAL.
*    M_ZSDEL-VKORG = S_VKORG-LOW.
    M_ZSDEL-VKORG = P_VKORG.
  ENDIF.
  MODIFY M_ZSDEL INDEX TC300_MAIL-CURRENT_LINE.
ENDMODULE.                 " PAI300_ENTRY  INPUT
*&---------------------------------------------------------------------*
*&      Form  CLEAR_ITABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CLEAR_ITABLES .
  REFRESH CONTROL 'TC300_BILL' FROM SCREEN '0300'.
  REFRESH CONTROL 'TC300_HEAD' FROM SCREEN '0300'.
  REFRESH CONTROL 'TC300_MAIL' FROM SCREEN '0300'.
  CLEAR: MWA_HEAD-ZTYPE, MWA_HEAD-KUNAG, M_ZSDEL, M_ZSDEL[].
ENDFORM.                    " CLEAR_ITABLES


*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_SCREEN_DISP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_ZTYPE  text
*      -->P_R_BKUNN  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_SCREEN_DISP  USING    PFWA_HEAD_I STRUCTURE MWA_HEAD.
  CLEAR: MC_EXCEL.                              "只有特定客戶可以寄EXCEL清單
  CHECK PFWA_HEAD_I-ZTYPE = 'P'.
  CHECK PFWA_HEAD_I-KUNAG = '0000001840' OR
        PFWA_HEAD_I-KUNAG = '0000001921'.     "HIMAX
  IF P_VKORG = 'MAX1'.                                      "I050619
    MC_EXCEL = 'X'.
  ENDIF.                                                    "I050619
  LOOP AT SCREEN.
    PERFORM CONTROL_SCREEN_INPUT_BY_NAME USING 'MC_EXCEL' 1.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.                    " SPECIAL_RULE_FOR_SCREEN_DISP
*&---------------------------------------------------------------------*
*&      Form  SCREEN_MODIFY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_6345   text
*----------------------------------------------------------------------*
FORM SCREEN_MODIFY  USING    PF_RULES.
  CASE PF_RULES.
    WHEN 'GENE'.
      LOOP AT SCREEN.
        PERFORM CONTROL_SCREEN_ACTIVE_BY_GROUP USING 1 'SEL' 0.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN 'CUST'.                                            "Screen 300
      LOOP AT SCREEN.
**第一筆不能使用上一頁
        IF MWA_HEAD-SELEC = 1.
          PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'MPRE'  0.
        ENDIF.
**最後一筆不能使用下一頁
        IF MWA_HEAD-SELEC = MWA_HEAD-TCOUN.
          PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'MNEX'  0.
        ENDIF.
**只有一筆時就不能使用上下貢
        IF MWA_HEAD-TCOUN = 1.
          PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'MPRE'  0.
          PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'MNEX'  0.
        ENDIF.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN 'FIST'.
*      LOOP AT SCREEN.
***Sales Org不能修改
*        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'P_VKORG'  0.
*        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'S_VKORG-LOW'  0.
*        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'S_VKORG-HIGH'  0.
*        MODIFY SCREEN.
*      ENDLOOP.
**依取得的SQLSE ORG決定畫面顯示
*      LOOP AT SCREEN.
*        IF S_VKORG-HIGH IS INITIAL.
*          PERFORM  CONTROL_SCREEN_INVIS_BY_GROUP   USING 1 'GP2'  1.
*        ELSE.
*          PERFORM  CONTROL_SCREEN_INVIS_BY_GROUP   USING 1 'GP1'  1.
*        ENDIF.
*        MODIFY SCREEN.
*      ENDLOOP.
**若是packing沒有勾,就不能用shipt-to的功能
      LOOP AT SCREEN.
        CHECK P_VKORG = 'MAX1'.
        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'S_KUNNR-LOW'  0.
        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'S_KUNNR-HIGH'  0.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN 'G001'.
      PERFORM AUTH_CHECK USING 'FUNCTION'.
      CLEAR: FC_TAB, FC_TAB[].

**8"不需要FTP的功能
      CASE P_VKORG.
        WHEN 'MAX1'.
          FC_TAB-FCODE = 'FTP'.
          APPEND FC_TAB.
        WHEN 'PSC1'.                   "會計不能 看到mail & 轉PDF
          SELECT SINGLE * FROM USR02 WHERE BNAME = SY-UNAME.
          IF SY-SUBRC = 0 AND USR02-CLASS = 'ACCOUNTING'.
            FC_TAB-FCODE = 'PDF'.    APPEND FC_TAB.
            FC_TAB-FCODE = 'EML'.    APPEND FC_TAB.
            FC_TAB-FCODE = 'FTP'.    APPEND FC_TAB.
            FC_TAB-FCODE = 'APF'.    APPEND FC_TAB.
            FC_TAB-FCODE = 'DWPK'.   APPEND FC_TAB.
          ENDIF.
      ENDCASE.
**財務call時                                        "I021220
      IF P_JOBTPS = 'I'.                                    "I021220
        FC_TAB-FCODE = 'PRT'. APPEND FC_TAB.                "I021220
        FC_TAB-FCODE = 'EML'. APPEND FC_TAB.                "I021220
        FC_TAB-FCODE = 'FTP'. APPEND FC_TAB.                "I021220
        FC_TAB-FCODE = 'DWPK'. APPEND FC_TAB.               "I021220
        FC_TAB-FCODE = 'SAL'. APPEND FC_TAB.                "I021220
        FC_TAB-FCODE = 'DAL'. APPEND FC_TAB.                "I021220
      ENDIF.
**關務call時
      CHECK P_JOBTPS = 'N'.
      FC_TAB-FCODE = 'PDF'.
      APPEND FC_TAB.
      CLEAR: FC_TAB.
      FC_TAB-FCODE = 'EML'.
      APPEND FC_TAB.
      CLEAR: FC_TAB.
      FC_TAB-FCODE = 'FTP'.
      APPEND FC_TAB.
      CLEAR: FC_TAB.
      FC_TAB-FCODE = 'SAL'.
      APPEND FC_TAB.
      CLEAR: FC_TAB.
      FC_TAB-FCODE = 'DAL'.
      APPEND FC_TAB.
      CLEAR: FC_TAB.
      FC_TAB-FCODE = 'DWPK'.
      APPEND FC_TAB.
    WHEN 'ACCT'.
      CLEAR: P_PACKS.
      LOOP AT SCREEN.
**會計不能SHOW PACKING
        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'P_PACKS' 0.
**一定會顯示金額
        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'C_PE' 0.
**不能維護WAFER ID
        PERFORM CONTROL_SCREEN_INPUT_BY_NAME   USING 'W_BUTTON' 0.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " SCREEN_MODIFY
*&---------------------------------------------------------------------*
*&      Form  SEND_MAIL_TO_CUST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEND_MAIL_TO_CUST USING PFV_EXCEL.


  DATA: EX_DOCUMENT_DATA  TYPE SODOCCHGI1,                            "MAIL主旨
        TA_RECEIVERS      LIKE SOMLRECI1  OCCURS 0 WITH HEADER LINE.  "MAIL LIST

  CHECK  PFV_EXCEL IS INITIAL.                  "沒有這個檢查會多送一個空白MAIL
  CLEAR: EX_DOCUMENT_DATA,  TA_RECEIVERS, TA_RECEIVERS[].
**定義主旨
  EX_DOCUMENT_DATA-OBJ_DESCR = MWA_HEAD-MTITL.

  CASE MWA_HEAD-ZTYPE.
    WHEN 'I' OR
         'C' OR
         'F'.
      EX_DOCUMENT_DATA-OBJ_NAME = 'Invoice'.
    WHEN 'P'.
      EX_DOCUMENT_DATA-OBJ_NAME = 'Packing'.
    WHEN OTHERS.
  ENDCASE.
**定義收件人
  LOOP AT M_ZSDEL.
    TA_RECEIVERS-RECEIVER = M_ZSDEL-RECEXTNAM.
    TA_RECEIVERS-REC_TYPE = 'U'.
    APPEND TA_RECEIVERS.
  ENDLOOP.

  CHECK TA_CONTENTS_BIN[] IS NOT INITIAL OR
        TA_RECEIVERS[]    IS NOT INITIAL.
  CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
    EXPORTING
      DOCUMENT_DATA              = EX_DOCUMENT_DATA
      PUT_IN_OUTBOX              = 'X'
      COMMIT_WORK                = 'X'
    TABLES
      PACKING_LIST               = TA_PACKING_LIST
      CONTENTS_BIN               = TA_CONTENTS_BIN
      RECEIVERS                  = TA_RECEIVERS
      CONTENTS_TXT               = TA_CONTENTS_TXT
    EXCEPTIONS
      TOO_MANY_RECEIVERS         = 1
      DOCUMENT_NOT_SENT          = 2
      DOCUMENT_TYPE_NOT_EXIST    = 3
      OPERATION_NO_AUTHORIZATION = 4
      PARAMETER_ERROR            = 5
      X_ERROR                    = 6
      ENQUEUE_ERROR              = 7
      OTHERS                     = 8.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    EXIT.
  ENDIF.
  CHECK SY-BATCH IS INITIAL.   "外部程式CALL時不要產生MESSAGE
  MESSAGE I000 WITH 'MAIL寄送完成!!'.
ENDFORM.                    " SEND_MAIL_TO_CUST
*&---------------------------------------------------------------------*
*&      Form  SEND_MAIL_TO_CUST_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PF_ATTM_I  text
*      -->PF_PACK_I  text
*----------------------------------------------------------------------*
FORM SEND_MAIL_TO_CUST_EXCEL TABLES PF_ATTM_I  STRUCTURE SOLI
                                    PF_PACK_I  STRUCTURE SOXPL.


  DATA: EX_DOCUMENT_DATA  TYPE SODOCCHGI1,                            "MAIL主旨
        PF_RECEV          LIKE SOOS1      OCCURS 0 WITH HEADER LINE.  "MAIL lIST FOR EXCEL


  CLEAR: EX_DOCUMENT_DATA, PF_RECEV, PF_RECEV[].
**定義主旨
  EX_DOCUMENT_DATA-OBJ_DESCR = MWA_HEAD-MTITL.
*<-寄送EXCEL File
  CHECK PF_ATTM_I[] IS NOT INITIAL.
  LOOP AT M_ZSDEL.
    PF_RECEV-RECESC     = 'U'.
    PF_RECEV-RECEXTNAM  = M_ZSDEL-RECEXTNAM.
    PF_RECEV-RECNAM     = M_ZSDEL-RECNAM.
    APPEND PF_RECEV.
  ENDLOOP.
  CALL FUNCTION 'ZSD_SEND_MAIL_ATT'
    EXPORTING
      I_DOCUMENT   = ''
      I_DATE       = SY-DATUM
      I_PRIORITY   = '1'
      I_TEXT1      = EX_DOCUMENT_DATA-OBJ_DESCR
      I_TEXT2      = ''
    TABLES
*      OBJCONT      =
      RECEIVERS    = PF_RECEV
      PACKING_LIST = PF_PACK_I
      ATT_CONT     = PF_ATTM_I
    EXCEPTIONS
      OTHERS       = 1.
  CHECK SY-SUBRC = 0.
  MESSAGE S080 WITH 'Send Mail was successful'.
*->寄送EXCEL File
ENDFORM.                    " SEND_MAIL_TO_CUST

*&---------------------------------------------------------------------*
*&      Form  GET_MAIL_CONTENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_MAIL_CONTENT .
  DATA: PFV_LINES           TYPE I,
        PFV_DATES(10)       TYPE C,
        PFV_TIMES(10)       TYPE C.

*定義信件內容
*  TA_CONTENTS_TXT-LINE = TEXT-M01.
*  APPEND TA_CONTENTS_TXT.
*  TA_CONTENTS_TXT-LINE = TEXT-M02.
*  APPEND TA_CONTENTS_TXT.
  WRITE: SY-DATUM TO PFV_DATES,
         SY-UZEIT TO PFV_TIMES.
  CONCATENATE 'Create on :' PFV_DATES PFV_TIMES
    INTO TA_CONTENTS_TXT-LINE SEPARATED BY SPACE.
  APPEND TA_CONTENTS_TXT.
  TA_CONTENTS_TXT-LINE = 'ATT:'.
  APPEND TA_CONTENTS_TXT.

  DESCRIBE TABLE TA_CONTENTS_TXT LINES PFV_LINES.

  TA_PACKING_LIST-TRANSF_BIN  = ''.
  TA_PACKING_LIST-HEAD_START  = 1.
  TA_PACKING_LIST-HEAD_NUM    = 0.
  TA_PACKING_LIST-BODY_START  = 1.
  TA_PACKING_LIST-BODY_NUM    = PFV_LINES.
  TA_PACKING_LIST-DOC_TYPE    = 'TXT'.
  TA_PACKING_LIST-OBJ_NAME    = ''.
  APPEND TA_PACKING_LIST.

ENDFORM.                    " GET_MAIL_CONTENT


*&---------------------------------------------------------------------*
*&      Form  EXEC_FUNCTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXEC_FUNCTION .
  CASE P_JOBTPS.
    WHEN 'M'.                         "M = MAIL
      PERFORM DEL_SENT_DOC.
      PERFORM SP_RULE_FOR_OTHER_PROG.

      CHECK I_HEAD[] IS NOT INITIAL.
      CLEAR: B_HEAD, B_HEAD[], S_HEAD, S_HEAD[].
      APPEND LINES OF I_HEAD TO S_HEAD.         "取得所選資料
      APPEND LINES OF I_HEAD TO B_HEAD.         "備份取得所選資料
      APPEND LINES OF I_HEAD TO O_HEAD.
      PERFORM GET_TC300_DATA USING P_JOBTPS.    "取得客戶代碼及單據類型

      LOOP AT S_BKUNN.
        CLEAR: MWA_HEAD-ZTYPE , MWA_HEAD-KUNAG, MWA_HEAD-KUNNR.
        MWA_HEAD-ZTYPE = S_BKUNN-ZTYPE.
        MWA_HEAD-KUNAG = S_BKUNN-BKUNN.
        MWA_HEAD-KUNNR = S_BKUNN-KUNNR.
        PERFORM GET_CUST_DOC_LIST TABLES   S_HEAD
                                  USING    P_JOBTPS
                                  CHANGING MWA_HEAD.
        PERFORM GET_MAIL_LIST TABLES   M_ZSDEL
                              USING    ''
                              CHANGING MWA_HEAD.
        PERFORM GET_MAIL_TITLE CHANGING MWA_HEAD.
        PERFORM SEND_DOC_TO_OUTSIDE USING 'MAIL'
                                          ''
                                          P_JOBTPS.
      ENDLOOP.
    WHEN 'P'.                                                       "P = PRINT
      PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                      ''.
    WHEN 'N' OR
         'E'.                         "I190111                      "關務程式CALL時用,不用做動作,讓它直接進選擇畫面
      PERFORM IMEX_MODIFY_HEAD_DATA TABLES I_HEAD
                                    USING  P_CUSTM.
      PERFORM IMEX_MODIFY_ITEM_DATA TABLES I_HEAD
                                           I_ITEM.
      PERFORM IMEX_GET_HEAD_DATA TABLES IMEX_HEAD.
      PERFORM IMEX_GET_ITEM_DATA TABLES I_HEAD
                                        IMEX_ITEM.
      IF P_PACKS IS INITIAL AND
         P_INVOS IS INITIAL.                                        "若傳進來的值是空的,還是要印匯總表
        PERFORM IMEX_SEND_TO_SMARTFORM USING 'ALL'
                                             ''.
      ENDIF.
**清掉Cerate Date
      CLEAR: I_HEAD-ERDAT.
      MODIFY I_HEAD TRANSPORTING ERDAT WHERE ERDAT IS NOT INITIAL.
**加關務印章
      IF P_ZSFEND IS NOT INITIAL.
        I_HEAD-STEMP = 'X'.
        MODIFY I_HEAD TRANSPORTING STEMP WHERE STEMP IS INITIAL.
      ENDIF.
*<-I191024
**加關務的公司大小章
      IF P_STMP2 IS NOT INITIAL.
        I_HEAD-STMP2 = 'X'.
        MODIFY I_HEAD TRANSPORTING STMP2 WHERE STMP2 IS INITIAL
                                         AND   ( ZTYPE = 'I' OR ZTYPE = 'P' OR ZTYPE = 'F' ).
      ENDIF.
*->I191024
      PERFORM IMEX_COVERT_TO_LOCL_CURRY.                            "幣別的轉換 I171018
      PERFORM EXPORT_OTF_TO_MEMORY USING P_JOBTPS.
*      LEAVE PROGRAM.                                                "不能放這裡,因為N需要往下走
*<-D141226
*    WHEN 'F'.
*      PERFORM SEND_DOC_TO_OUTSIDE USING   'FTP'
*                                          'AUTO'
*                                          P_JOBTPS.
*      LEAVE PROGRAM.
*->D141226
    WHEN 'B'.                                                                                     "B = 出庫單CALL
      IMPORT WM1_I_HEAD WM1_I_HEAD_SH WM1_I_HEAD_SO WM1_I_HEAD_IN WM1_I_ITEM WM1_I_ITEM_RE WM1_I_ITEM_SG
             WM2_I_HEAD WM2_I_ITEM WM2_I_ITEM_NEXST WM2_I_ITEM_SB WM2_I_REMK WM2_I_STOCK
        FROM MEMORY ID P_OCPROG.

      PERFORM WM_USER_SELECTION USING P_ZSFEND.
      FREE MEMORY ID P_OCPROG.
      LEAVE PROGRAM.
*save PDF for AIX for B2B calling
    WHEN '2' OR '3' OR '4' OR 'U'.                                  "U190708 add '4'
      PERFORM SAVE_PDF_FILE_TO_SERVER   USING P_JOBTPS.
      LEAVE PROGRAM.         "**** exit program *****
    WHEN 'T'.                                                       "Send OTF to calling programe (Leave programe)
      PERFORM EXPORT_OTF_TO_MEMORY USING P_JOBTPS.                  "裡面有LEAVE
*加密rule inv pdf(mail & b2b)                                       "I190708
    WHEN '8' OR '9'.                                        "I190708
      PERFORM SAVE_PDF_FILE_FOR_ENCRYPT USING    P_JOBTPS   "I190708
                                        CHANGING P_ENCSTOP. "I190708
      LEAVE PROGRAM.         "**** exit program *****               "I190708

    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " EXEC_FUNCTION
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_DOC_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_CUST_DOC_LIST TABLES   PF_HEAD_O    STRUCTURE I_HEAD
                       USING    PFV_JTYPE_I
                       CHANGING PFWA_HEAD_IO STRUCTURE MWA_HEAD.
  DATA: BEGIN OF PF_SHIP OCCURS 0,
          ZNUMB(03) TYPE N,
          KUNNR     TYPE KUNWE,
        END OF PF_SHIP.
  DATA: PFWA_ZSD104   LIKE ZSD104,
        PF_HEAD_BK    LIKE I_HEAD OCCURS 0 WITH HEADER LINE,
        PFV_ZNUMB(03) TYPE N VALUE 1.

  CLEAR: PF_HEAD_O, PF_HEAD_O[], PF_HEAD_BK, PF_HEAD_BK[].

**不管是不是外部CALL的都走下面這段
  IF PFWA_HEAD_IO-ZTYPE <> 'P'.
    APPEND LINES OF B_HEAD TO PF_HEAD_O.
    DELETE PF_HEAD_O WHERE BKUNN <> PFWA_HEAD_IO-KUNAG
                     OR    ZTYPE <> PFWA_HEAD_IO-ZTYPE.
    SORT PF_HEAD_O BY VBELN.
  ENDIF.

**如果外部CALL而且是PACKING走下面這段(不要用CHECK不然會走不到EXIT)
  IF PFV_JTYPE_I = 'M'        AND               "M = Mail
     PFWA_HEAD_IO-ZTYPE = 'P'.
    APPEND LINES OF B_HEAD TO PF_HEAD_O.
    IF PFWA_HEAD_IO-KUNNR IS NOT INITIAL.
      DELETE PF_HEAD_O WHERE KUNAG <> PFWA_HEAD_IO-KUNAG
                       OR    KUNNR <> PFWA_HEAD_IO-KUNNR
                       OR    ZTYPE <> PFWA_HEAD_IO-ZTYPE.
    ELSE.
      DELETE PF_HEAD_O WHERE KUNAG <> PFWA_HEAD_IO-KUNAG
                       OR    ZTYPE <> PFWA_HEAD_IO-ZTYPE.
    ENDIF.
    SORT PF_HEAD_O BY VBELN.
    EXIT.
  ENDIF.



  CHECK  PFWA_HEAD_IO-ZTYPE = 'P'.
  APPEND LINES OF B_HEAD TO PF_HEAD_O.
  DELETE PF_HEAD_O WHERE KUNAG <> PFWA_HEAD_IO-KUNAG
                   OR    ZTYPE <> PFWA_HEAD_IO-ZTYPE.

**取得是否BY SHIP-TO寄MAIL
  PERFORM GET_WORKAREA_ZSD104 USING     PFWA_HEAD_IO-KUNAG
                              CHANGING  PFWA_ZSD104.
  CHECK PFWA_ZSD104 IS NOT INITIAL.
**收集SHIP-TO CODE
  LOOP AT PF_HEAD_O.
    PF_SHIP-KUNNR = PF_HEAD_O-KUNNR.
    APPEND PF_SHIP.
  ENDLOOP.
  SORT PF_SHIP BY KUNNR.
  DELETE ADJACENT DUPLICATES FROM PF_SHIP COMPARING KUNNR.
  LOOP AT PF_SHIP.
    PF_SHIP-ZNUMB = PFV_ZNUMB.
    MODIFY PF_SHIP.
    ADD 1 TO PFV_ZNUMB.
  ENDLOOP.
**重新收集HEAD資料(先備資料)
  APPEND LINES OF PF_HEAD_O TO PF_HEAD_BK.
  CLEAR: PF_HEAD_O, PF_HEAD_O[].
**計算總SHIP-TO筆數
  DESCRIBE TABLE PF_SHIP LINES PFWA_HEAD_IO-TCOUN.
**抓出這次選擇的SHIP-TO編號
  READ TABLE PF_SHIP WITH KEY ZNUMB = PFWA_HEAD_IO-SELEC.
  APPEND LINES OF PF_HEAD_BK TO PF_HEAD_O.
  DELETE PF_HEAD_O WHERE KUNNR <> PF_SHIP-KUNNR.

  PFWA_HEAD_IO-KUNNR = PF_SHIP-KUNNR.
ENDFORM.                    " GET_CUST_DOC_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_MAIL_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_MAIL_LIST  TABLES   PF_ZSDEL_IO  STRUCTURE M_ZSDEL
                    USING    PFV_NOCLR                    "不可以清除的FLAG
                    CHANGING PFWA_HEAD_IO STRUCTURE MWA_HEAD.
  DATA: PFWA_ZSDSM        LIKE ZSDSM,
        PFWA_ZSDML        LIKE ZSDML,
        PFV_ZTYPE(02)     TYPE C,                             "配合ZSDEL-TYPE
*        PFV_KUNNR         LIKE ZSDSM-KUNNR,
        PFV_SHIPCODE(20)  TYPE C,
        PFV_REPID         LIKE ZSDML-REPID.

**[MAIL LIST說明]
**共同的MAIL由ZSDSM中抓取
**BY SHIP-TO不同的可以由ZSDML
  CLEAR: PFWA_HEAD_IO-MCOUN.
  DESCRIBE TABLE PF_ZSDEL_IO LINES PFWA_HEAD_IO-MCOUN.

  CHECK PFV_NOCLR IS INITIAL.                             "表示是重收集MAIL LIST
  CLEAR: PF_ZSDEL_IO, PF_ZSDEL_IO[].
  PFV_ZTYPE = PFWA_HEAD_IO-ZTYPE.
  IF PFWA_HEAD_IO-ZTYPE = 'C' OR
     PFWA_HEAD_IO-ZTYPE = 'D' OR
     PFWA_HEAD_IO-ZTYPE = 'F'.
    PFV_ZTYPE = 'I'.
  ENDIF.
*  READ TABLE S_HEAD INDEX 1.

**用S_VKORG判斷進來的是MAX1 OR PSC1
  IF P_VKORG =  'MAX1'.
* OR P_VKORG IS INITIAL.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_ZSDEL_IO FROM  ZSDEL
                                                            WHERE REPID   =  SY-CPROG
*                                                            AND   VKORG   IN S_VKORG
                                                            AND   VKORG   =  P_VKORG
                                                            AND   KUNAG   =  PFWA_HEAD_IO-KUNAG
                                                            AND   TYPE    =  PFV_ZTYPE
                                                            AND   RECESC  =  'U'.
**外部程式CALL時若沒有MAIL清單會DUMP(做保護),若是原程式沒有值就沒有
    IF SY-SUBRC <> 0 AND P_JOBTPS = 'M'.
      MESSAGE I000 WITH PFWA_HEAD_IO-KUNAG '客戶的寄送MAIL沒有維謢,請維護完再次重送!![ZSDEL]'.
      LEAVE PROGRAM.
    ENDIF.
**如果有SHIP-TO就只留該SHIP-TO及SOLD-TO的LIST
    IF PFWA_HEAD_IO-ZTYPE = 'P'.                            "只有PACKING才會有BY SHIP-TO
      LOOP AT PF_ZSDEL_IO WHERE KUNNR IS NOT INITIAL.
        CHECK PF_ZSDEL_IO-KUNNR <> PFWA_HEAD_IO-KUNNR.
        DELETE PF_ZSDEL_IO.
      ENDLOOP.
      PF_ZSDEL_IO-OTHER = 'X'.
      MODIFY PF_ZSDEL_IO TRANSPORTING OTHER WHERE OTHER = ''
                                            AND   KUNNR IS NOT INITIAL.
    ENDIF.
  ENDIF.

  IF P_VKORG = 'PSC1'.
*    OR P_VKORG IS INITIAL.
*  ELSEIF S_HEAD-VKORG = 'PSC1'.
*    IF PFV_ZTYPE = 'P'.
**-- by sold to
*      PFV_KUNNR = PFWA_HEAD_IO-KUNAG.
*    ELSE.
**---by bill to
*      PFV_KUNNR = S_HEAD-BKUNN.
*    ENDIF.
**PFWA_HEAD_IO-KUNAG ==>P = SOLD-TO I,F,D = Bill-TO
    READ TABLE S_HEAD INDEX 1.
    SELECT * INTO PFWA_ZSDSM FROM  ZSDSM
*                             WHERE KUNNR = PFV_KUNNR
                             WHERE KUNNR = PFWA_HEAD_IO-KUNAG
                             AND   VKORG = S_HEAD-VKORG
                             AND   SPART = S_HEAD-SPART
                             AND   RPTID = PFV_ZTYPE.
      CLEAR PF_ZSDEL_IO.
      MOVE-CORRESPONDING PFWA_ZSDSM TO PF_ZSDEL_IO.
      PF_ZSDEL_IO-TYPE      = PFWA_ZSDSM-RPTID.
      PF_ZSDEL_IO-RECESC    = 'U'.
      PF_ZSDEL_IO-RECEXTNAM = PFWA_ZSDSM-EMAIL.
      APPEND PF_ZSDEL_IO.
    ENDSELECT.

*-- special customer (Packing only/n)
    IF PFV_ZTYPE = 'P' AND
      ( PFWA_HEAD_IO-KUNAG = '0000001840' OR
        PFWA_HEAD_IO-KUNAG = '0000001921' ).    "himax
      CONCATENATE 'ZSD40300' '_' PFWA_HEAD_IO-KUNNR
        INTO PFV_SHIPCODE.               "--ship to
      SELECT * INTO PFWA_ZSDML FROM  ZSDML
                               WHERE REPID = PFV_SHIPCODE.
        PF_ZSDEL_IO-VKORG     = 'PSC1'.
        PF_ZSDEL_IO-KUNAG     = PFWA_HEAD_IO-KUNAG.
        PF_ZSDEL_IO-TYPE      = PFV_ZTYPE .
        PF_ZSDEL_IO-RECESC    = 'U'.
        PF_ZSDEL_IO-RECEXTNAM = PFWA_ZSDML-RECEXTNAM.
        APPEND PF_ZSDEL_IO.
      ENDSELECT.
    ENDIF.

*-- 直接組字串至ZSDML取MAIL LIST
    IF PFV_ZTYPE = 'P'.
      CONCATENATE 'ZSD40490' PFWA_HEAD_IO-KUNAG PFWA_HEAD_IO-KUNNR   "sold to + ship to
        INTO PFV_REPID SEPARATED BY '_'.
    ELSEIF PFV_ZTYPE = 'I'.
      CONCATENATE 'ZSD40491' PFWA_HEAD_IO-KUNNR PFWA_HEAD_IO-KUNAG    "sold to + bill to
        INTO PFV_REPID SEPARATED BY '_'.
    ENDIF.
    SELECT * INTO PFWA_ZSDML FROM  ZSDML
                             WHERE REPID = PFV_REPID
                             AND   TYPE  = 'A'.
      PF_ZSDEL_IO-VKORG     = 'PSC1'.
      PF_ZSDEL_IO-KUNAG     = PFWA_HEAD_IO-KUNAG.
      PF_ZSDEL_IO-TYPE      = PFV_ZTYPE .
      PF_ZSDEL_IO-RECESC    = 'U'.
      PF_ZSDEL_IO-RECEXTNAM = PFWA_ZSDML-RECEXTNAM.
      APPEND PF_ZSDEL_IO.
    ENDSELECT.
  ENDIF.


  CHECK PF_ZSDEL_IO[] IS NOT INITIAL.
  SORT PF_ZSDEL_IO BY ITEM.
**重算MAIL的筆數
  CLEAR: PFWA_HEAD_IO-MCOUN.
  DESCRIBE TABLE PF_ZSDEL_IO LINES PFWA_HEAD_IO-MCOUN.

ENDFORM.                    " GET_MAIL_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_MAIL_TITLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_MAIL_TITLE CHANGING PFWA_HEAD_IO STRUCTURE MWA_HEAD.
  CLEAR: PFWA_HEAD_IO-MTITL, PFWA_HEAD_IO-COUNT, PFWA_HEAD_IO-ZCUST.
  PERFORM GET_DOC_RANGE CHANGING M_SVBEL
                                 M_EVBEL
                                 PFWA_HEAD_IO-COUNT.
  CASE PFWA_HEAD_IO-ZTYPE.
    WHEN 'I' OR
         'C' OR
         'F' OR                                             "U190708
         'D' OR                                             "I190708
         'R'.                                               "I190708
      PFWA_HEAD_IO-MTITL = 'PSMC Invoice-'.
      PFWA_HEAD_IO-ZCUST = 'BILL-TO'.
    WHEN 'P'.
      IF M_SVBEL <> M_EVBEL.
        IF M_SVBEL+0(03) = M_EVBEL+0(03).
          CONCATENATE 'PSMC Packing-' M_SVBEL '~' M_EVBEL+03(05)
            INTO PFWA_HEAD_IO-MTITL.
        ELSE.
          CONCATENATE 'PSMC Packing-' M_SVBEL '~' M_EVBEL
            INTO PFWA_HEAD_IO-MTITL.
        ENDIF.
      ELSE.
        CONCATENATE 'PSMC Packing-' M_SVBEL
          INTO PFWA_HEAD_IO-MTITL.
      ENDIF.
      PFWA_HEAD_IO-ZCUST = 'SOLD-TO'.
    WHEN OTHERS.
  ENDCASE.
  PERFORM SP_RULE_FOR_MAILTITLE CHANGING PFWA_HEAD_IO.
ENDFORM.                    " GET_MAIL_TITLE
*&---------------------------------------------------------------------*
*&      Form  DEL_SENT_DOC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DEL_SENT_DOC .
  DELETE I_HEAD WHERE ZMSET = 'X'.
ENDFORM.                    " DEL_SENT_DOC
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_OTHER_PROG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_OTHER_PROG .

  DELETE I_HEAD WHERE KUNAG = '0000001947'      "UPI
                AND   ZTYPE = 'F'.
*  LOOP AT I_HEAD WHERE KUNAG = '0000001947'
*                 AND   ZTYPE = 'F'.
*    DELETE I_HEAD.
*  ENDLOOP.
ENDFORM.                    " SPECIAL_RULE_FOR_OTHER_PROG
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_REMARK_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM IMEX_GET_REMARK_INFO  TABLES PF_ITEM   STRUCTURE I_ITEM
                           USING  PFWA_HEAD STRUCTURE I_HEAD.

  DATA: PFV_TWVAL       TYPE NETWR,                                                               "Wafer Value
        PFV_TFVAL       TYPE NETWR,                                                               "Foundry service charge
        PFV_TPVAL       TYPE NETWR,                                                               "Processing charge
        PFV_TQVAL       TYPE NETWR,                                                               "Processing charge(CONSIGN)
        PFV_TGVAL       TYPE NETWR,                                                               "Finish Good Value
        PFV_WAERK       TYPE WAERK,                                                               "Currency
        PFV_KURRF       TYPE KURRF,
        PFV_CONSI       TYPE C,                                                                   "判斷該張是否有CONSIGN
        PFV_VALUE(14)   TYPE C,
        PFV_NAME1(70)   TYPE C,
        PFV_REMAK(300)  TYPE C,
        PFV_ITEMS(200)  TYPE C,
        PFV_ITFRE(01)   TYPE C.                                     "判斷是否為FOC的Billing

  CHECK P_JOBTPS = 'N' OR
        P_JOBTPS = 'E'.
**關務註解
  CLEAR: PFV_REMAK,  PFV_ITFRE.
  PFV_REMAK+2 = '** The document is printed out via PUR department and just for customs clearance purpose only.'.
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                              USING  PFV_REMAK
                                     PFWA_HEAD-VBELN
                                     PFWA_HEAD-ZTYPE
                                     ''.
**針對保稅品需要加工費的需要顯示下面的資料
* <-I170511
  PERFORM IMEX_GET_ITEM_CONSIGN_RECORDS TABLES    PF_ITEM
                                        USING     PFWA_HEAD
                                        CHANGING  PFV_ITEMS.        "這個有值表示該INVOICE是有混自購料及客供料
  IF PFV_ITEMS IS NOT INITIAL.
    CLEAR: PFV_REMAK.
    CONCATENATE '** Processing Item No. :' PFV_ITEMS
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                                USING  PFV_REMAK
                                       PFWA_HEAD-VBELN
                                       PFWA_HEAD-ZTYPE
                                       ''.
  ENDIF.

  CLEAR: PFV_TWVAL, PFV_TFVAL, PFV_TGVAL, PFV_CONSI, PFV_TQVAL, PFV_TPVAL, PFV_WAERK.
*<-I171018 M190718 I200831
  IF P_TWDVL IS NOT INITIAL.
    PFV_WAERK = 'TWD'.
    PERFORM GET_INVOICE_EXCHANGE_RATE USING     PFWA_HEAD
                                      CHANGING  PFV_KURRF.
  ELSE.
    PFV_WAERK = 'USD'.
    PFV_KURRF = 1.
  ENDIF.
*->I171018 I200831
  LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
                  AND   ZTYPE = PFWA_HEAD-ZTYPE.

    IF PF_ITEM-CONSI IS NOT INITIAL.
**處理WAFER VALUE加總
*      PFV_TWVAL = PFV_TWVAL + PF_ITEM-KWERT.                                                      "D171018
      PFV_TWVAL = PFV_TWVAL + ( PF_ITEM-KWERT * PFV_KURRF )."I171018
**處理Processing Charge有值的部份
*      PFV_TQVAL = PFV_TQVAL + PF_ITEM-PCKWE.                                                      "I170713 D171018
      PFV_TQVAL = PFV_TQVAL + ( PF_ITEM-PCKWE * PFV_KURRF )."I171018
      PFV_CONSI = 'X'.
    ELSE.
**處理Invoice上的原金額加總
*      PFV_TGVAL = PFV_TGVAL + PF_ITEM-KWERT.                                                      "D171018
      PFV_TGVAL = PFV_TGVAL + ( PF_ITEM-KWERT * PFV_KURRF )."I171018
**處理Processing Charge有值的部份
*      PFV_TPVAL = PFV_TPVAL + PF_ITEM-PCKWE.                                  "I170713 D171018
      PFV_TPVAL = PFV_TPVAL + ( PF_ITEM-PCKWE * PFV_KURRF )."I171018
    ENDIF.
**PF_ITEM-SCUTP有值表示是CONSIGN的產品
*    PFV_TFVAL = PFV_TFVAL + ( PF_ITEM-SCUTP * PF_ITEM-DWEMN ).                "D171018
*    PFV_TFVAL = PFV_TFVAL + ( PF_ITEM-SCUTP * PFV_KURRF * PF_ITEM-DWEMN ).    "I171018
    PFV_TFVAL = PFV_TFVAL + ( PF_ITEM-SCKWE * PFV_KURRF ).  "I190531
    IF PFV_ITFRE IS INITIAL.
      CHECK PF_ITEM-PSTYV = 'TANN'.
      PFV_ITFRE = 'X'.
    ENDIF.
  ENDLOOP.
  PERFORM CURRENCY_CONVERT USING    PFV_WAERK
                           CHANGING PFV_TWVAL.
  PERFORM CURRENCY_CONVERT USING    PFV_WAERK
                           CHANGING PFV_TQVAL.
  PERFORM CURRENCY_CONVERT USING    PFV_WAERK
                           CHANGING PFV_TGVAL.
  PERFORM CURRENCY_CONVERT USING    PFV_WAERK
                           CHANGING PFV_TPVAL.
  PERFORM CURRENCY_CONVERT USING    PFV_WAERK
                           CHANGING PFV_TFVAL.
*<-I170713
  IF PFV_CONSI IS NOT INITIAL.
**只要是Consign時就一定要有的REMARK
    CLEAR: PFV_REMAK.
    PERFORM IMEX_GET_CUSTOMER_NAME USING     PFWA_HEAD-KUNAG
                                             'C'
                                   CHANGING  PFV_NAME1.
    CONCATENATE '** The goods provided by' PFV_NAME1 ';'
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
    CLEAR: PFV_REMAK.
    PERFORM IMEX_GET_CUSTOMER_NAME USING     PFWA_HEAD-KUNAG
                                             'C'
                                   CHANGING  PFV_NAME1.
    CONCATENATE PFV_NAME1 'intrust PSMC to process foundry service.'
       INTO PFV_REMAK+8 SEPARATED BY SPACE.

    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
    CLEAR: PFV_REMAK, PFV_VALUE.
    IF PFV_ITEMS IS NOT INITIAL.
**原始INVOICE的ITEM小計加總
      WRITE PFV_TGVAL CURRENCY PFV_WAERK TO PFV_VALUE.
      PFV_REMAK+5 = 'Subtotal : Finished goods'.
      PFV_REMAK+39 = PFV_VALUE.
      CONCATENATE PFV_REMAK PFV_WAERK                       "M171018
          INTO PFV_REMAK SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
**Processing Charge(N/C)加總(非CONSIGN)
      IF PFV_TPVAL IS NOT INITIAL.
        CLEAR: PFV_REMAK, PFV_VALUE.
        WRITE PFV_TPVAL CURRENCY PFV_WAERK TO PFV_VALUE.    "M171018
        PFV_REMAK+16 = 'Finished goods'.
        CONCATENATE PFV_VALUE PFV_WAERK
          INTO PFV_REMAK+39 SEPARATED BY SPACE.
        CONCATENATE PFV_REMAK '(N/C)'
          INTO PFV_REMAK SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD-VBELN
                                            PFWA_HEAD-ZTYPE
                                            ''.
      ENDIF.
**Consign Raw Wafer參考單價總計
      CLEAR: PFV_REMAK, PFV_VALUE.
      WRITE PFV_TWVAL CURRENCY PFV_WAERK TO PFV_VALUE.      "M171018
      PFV_REMAK+16 = 'Wafer Value'.
      PFV_REMAK+39 = PFV_VALUE.
      CONCATENATE PFV_REMAK PFV_WAERK '(N/C)'
          INTO PFV_REMAK SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
    ELSE.
      IF PFV_TPVAL IS NOT INITIAL.
**Processing Charge(N/C)加總(非CONSIGN)
        CLEAR: PFV_REMAK, PFV_VALUE.
        WRITE PFV_TPVAL CURRENCY PFV_WAERK TO PFV_VALUE.
        PFV_REMAK+5 = 'Subtotal : Finished goods'.
        CONCATENATE PFV_VALUE PFV_WAERK
          INTO PFV_REMAK+39 SEPARATED BY SPACE.
        CONCATENATE PFV_REMAK '(N/C)'
          INTO PFV_REMAK SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
**整張都是Consign的Raw Wafer參考單價總計
        CLEAR: PFV_REMAK, PFV_VALUE.
        WRITE PFV_TWVAL CURRENCY PFV_WAERK TO PFV_VALUE.
        PFV_REMAK+16 = 'Wafer Value'.
        PFV_REMAK+39 = PFV_VALUE.
        CONCATENATE PFV_REMAK PFV_WAERK '(N/C)'
            INTO PFV_REMAK SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD-VBELN
                                            PFWA_HEAD-ZTYPE
                                            ''.
      ELSE.
**整張都是Consign的Raw Wafer參考單價總計
        WRITE PFV_TWVAL CURRENCY PFV_WAERK TO PFV_VALUE.
        PFV_REMAK+5 = 'Subtotal : Wafer Value'.
        PFV_REMAK+39 = PFV_VALUE.
        CONCATENATE PFV_REMAK PFV_WAERK '(N/C)'
          INTO PFV_REMAK SEPARATED BY SPACE.
        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                    USING   PFV_REMAK
                                            PFWA_HEAD-VBELN
                                            PFWA_HEAD-ZTYPE
                                            ''.
      ENDIF.
    ENDIF.
**Invoice上面的加工費加總
    CLEAR: PFV_REMAK, PFV_VALUE.
    WRITE PFV_TFVAL CURRENCY PFV_WAERK TO PFV_VALUE.
    PFV_REMAK+16 = 'Processing Charge'.
    CONCATENATE PFV_VALUE PFV_WAERK
      INTO PFV_REMAK+39 SEPARATED BY SPACE.

    IF PFWA_HEAD-ZTYPE = 'F' OR
       PFV_ITFRE IS NOT INITIAL.
      CONCATENATE PFV_REMAK '(N/C)'
        INTO PFV_REMAK SEPARATED BY SPACE.
    ENDIF.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.

**Processing Charge(N/C)加總(Consign)
    IF PFV_TQVAL IS NOT INITIAL.
      CLEAR: PFV_REMAK, PFV_VALUE.
      WRITE PFV_TQVAL CURRENCY PFV_WAERK TO PFV_VALUE.
      PFV_REMAK+16 = 'Processing Charge'.
      CONCATENATE PFV_VALUE PFV_WAERK
        INTO PFV_REMAK+39 SEPARATED BY SPACE.
      CONCATENATE PFV_REMAK '(N/C)'
        INTO PFV_REMAK SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
    ENDIF.
**加總線
    CLEAR: PFV_REMAK.
    PFV_REMAK+5 = '----------------------------------------------------------'.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
**總計
    CLEAR: PFV_REMAK, PFV_VALUE.
    PFV_REMAK+5 = 'Grand Total :'.
    PFV_TFVAL = PFV_TWVAL + PFV_TFVAL + PFV_TGVAL + PFV_TPVAL + PFV_TQVAL."I170713
    WRITE PFV_TFVAL CURRENCY PFV_WAERK TO PFV_VALUE.        "M171018
    PFV_REMAK+39 = PFV_VALUE.
    CONCATENATE PFV_REMAK PFV_WAERK INTO PFV_REMAK          "M171018
          SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
  ELSE.
*    CHECK PFV_TPVAL IS NOT INITIAL.
    IF PFV_TPVAL IS NOT INITIAL.
**非CONSIGN的顯示方式
      CLEAR: PFV_REMAK, PFV_VALUE.
**原始INVOICE的ITEM小計加總
      WRITE PFV_TGVAL CURRENCY PFV_WAERK TO PFV_VALUE.
      PFV_REMAK+5 = 'Subtotal : Finished goods'.
      PFV_REMAK+39 = PFV_VALUE.
      CONCATENATE PFV_REMAK PFV_WAERK                       "M171018
          INTO PFV_REMAK SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
**Processing Charge(N/C)加總(非CONSIGN)
      CLEAR: PFV_REMAK, PFV_VALUE.
      WRITE PFV_TPVAL CURRENCY PFV_WAERK TO PFV_VALUE.      "M171018
      PFV_REMAK+16 = 'Finished goods'.
      PFV_REMAK+39 = PFV_VALUE.
      CONCATENATE PFV_REMAK PFV_WAERK '(N/C)'
          INTO PFV_REMAK SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
**加總線
      CLEAR: PFV_REMAK.
      PFV_REMAK+5 = '----------------------------------------------------------'.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
**總計
      CLEAR: PFV_REMAK, PFV_VALUE.
      PFV_REMAK+5 = 'Grand Total :'.
      PFV_TFVAL = PFV_TGVAL + PFV_TPVAL.
      WRITE PFV_TFVAL CURRENCY PFV_WAERK TO PFV_VALUE.      "M171018
      PFV_REMAK+39 = PFV_VALUE.
      CONCATENATE PFV_REMAK PFV_WAERK INTO PFV_REMAK        "M171018
            SEPARATED BY SPACE.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFWA_HEAD-VBELN
                                          PFWA_HEAD-ZTYPE
                                          ''.
    ENDIF.
  ENDIF.
*<-I190329
  PERFORM IMEX_GET_NOCHARGE_ITEM_REMARK TABLES PF_ITEM
                                        USING  PFWA_HEAD.
*->I190329
*<-D190329
***取得BAD DIE / GOOD DIE的REMARK資訊
*  PERFORM IMEX_GET_GBDIE_INFO_FOR_REMARK TABLES PF_ITEM
*                                         USING  PFWA_HEAD.
*->D190329
ENDFORM.                    " IMEX_GET_REMARK_INFO

*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_HEAD_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM IMEX_GET_HEAD_DATA TABLES PF_HIMEX_O STRUCTURE IMEX_HEAD.

  CLEAR: PF_HIMEX_O, PF_HIMEX_O[].
  PF_HIMEX_O-SDATE = S_ERDAT-LOW.
  PF_HIMEX_O-EDATE = S_ERDAT-HIGH.
  PF_HIMEX_O-CPROG = SY-CPROG.
  APPEND PF_HIMEX_O.
ENDFORM.                    " IMEX_GET_HEAD_DATA
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_ITEM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM IMEX_GET_ITEM_DATA TABLES  PF_HEAD_I  STRUCTURE I_HEAD
                                PF_IIMEX_O STRUCTURE IMEX_ITEM.
  DATA: PFWA_KNA1 LIKE KNA1,
        PFWA_LIKP LIKE LIKP,
        PFWA_VBRK LIKE VBRK,
        PFV_KUNAG TYPE KUNAG,
        PFV_COUNT TYPE I.
  DATA: BEGIN OF PF_VBRP OCCURS 0,
          VBELN TYPE VBELN_VF,
          VGBEL TYPE VBELN_VL,
        END OF PF_VBRP.

  CLEAR: PFV_KUNAG, PF_IIMEX_O, PF_IIMEX_O[].

  LOOP AT PF_HEAD_I WHERE  ZTYPE = 'I'
                    OR     ZTYPE = 'F'.
    IF PFV_KUNAG <> PF_HEAD_I-KUNAG.
      PF_IIMEX_O-KUNAG = PF_HEAD_I-KUNAG.
      PERFORM GET_WORKAREA_KNA1 USING     PF_HEAD_I-KUNAG
                                CHANGING  PFWA_KNA1.
      PF_IIMEX_O-NAME1 = PFWA_KNA1-NAME1.
    ENDIF.
    PF_IIMEX_O-VBELN = PF_HEAD_I-VBELN.
    CASE PF_HEAD_I-ZTYPE.
      WHEN 'F'.
        PERFORM GET_WORKAREA_LIKP USING     PF_HEAD_I-VBELN
                                  CHANGING  PFWA_LIKP.
        PF_IIMEX_O-SDATE = PFWA_LIKP-WADAT_IST.
        PF_IIMEX_O-ERNAM = PFWA_LIKP-ERNAM.
        PF_IIMEX_O-VGBEL = PF_HEAD_I-VGBEL.
        PF_IIMEX_O-CDATE = PF_HEAD_I-CDATE.
        PF_IIMEX_O-RELNO = PF_HEAD_I-RELNO.
        IF PF_HEAD_I-ERDAT IS INITIAL.
          PF_IIMEX_O-PRINT = 'N'.
        ENDIF.
        APPEND PF_IIMEX_O.
        CLEAR  PF_IIMEX_O.

      WHEN 'I'.
        PERFORM GET_WORKAREA_VBRK USING     PF_HEAD_I-VBELN
                                  CHANGING  PFWA_VBRK.
        PF_IIMEX_O-SDATE = PFWA_VBRK-FKDAT.
        PF_IIMEX_O-ERNAM = PFWA_VBRK-ERNAM.
        CLEAR: PF_VBRP, PF_VBRP[].
        SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBRP FROM   VBRP
                                                            WHERE  VBELN =  PF_HEAD_I-VBELN
                                                            AND    VGBEL <> ''.
        SORT PF_VBRP.
        DELETE ADJACENT DUPLICATES FROM PF_VBRP.
        CLEAR: PFV_COUNT.
        PFV_COUNT = 1.
        LOOP AT PF_VBRP.
          PF_IIMEX_O-VGBEL = PF_VBRP-VGBEL.
          IF PF_HEAD_I-ERDAT IS INITIAL.
            PF_IIMEX_O-PRINT = 'N'.
          ENDIF.
          PERFORM GET_RELNO_DATE  USING     PF_HEAD_I-VGBEL
                                            'SHIP'
                                  CHANGING  PF_IIMEX_O-RELNO
                                            PF_IIMEX_O-CDATE.
          IF PFV_COUNT <> 1.
            CLEAR: PF_IIMEX_O-KUNAG, PF_IIMEX_O-NAME1.
          ENDIF.
          APPEND PF_IIMEX_O.
          CLEAR  PF_IIMEX_O.
          ADD 1 TO PFV_COUNT.
        ENDLOOP.
      WHEN OTHERS.
    ENDCASE.
    PFV_KUNAG = PF_HEAD_I-KUNAG.
  ENDLOOP.

ENDFORM.                    " IMEX_GET_ITEM_DATA
**&---------------------------------------------------------------------*
**&      Form  IMEX_GET_DATA
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM IMEX_GET_DATA.
*  IF P_JOBTPS = TEXT-TPN.                                                "TEXT-TPN = 'N'
*    CLEAR: IMEX_HEAD, IMEX_HEAD[], IMEX_ITEM, IMEX_ITEM[].
*    PERFORM IMEX_GET_HEAD_DATA.
*    PERFORM IMEX_GET_ITEM_DATA.
*  ENDIF.
*ENDFORM.                    " IMEX_GET_DATA
*&---------------------------------------------------------------------*
*&      Form  IMEX_SEND_TO_SMARTFORM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM IMEX_SEND_TO_SMARTFORM USING PFV_FUNCT
                                  PFV_UCOMM.
  DATA: L_FM_NAME             TYPE RS38L_FNAM,
        WA_CONTROL_PARAMETERS TYPE SSFCTRLOP,           "SMARTFORM控制參數
        WA_OUTPUT_OPT         TYPE SSFCOMPOP,           "SMARTFORM打印時的參數
        WA_JOB_OUTPUT_INFO    TYPE SSFCRESCL.           "SMARTFORM傳出資料的值

  CHECK P_JOBTPS = 'N' OR                       "ZSD_RT003 Call
        P_JOBTPS = 'E'.                         "ZBD40231  Call
  CHECK IMEX_ITEM[] IS NOT INITIAL.

  CLEAR: I_OTFS, I_OTFS[].

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME                 = 'ZSD_SF005_ADD'
*     VARIANT                  = ' '
*     DIRECT_CALL              = ' '
    IMPORTING
      FM_NAME                  = L_FM_NAME
*   EXCEPTIONS
*     NO_FORM                  = 1
*     NO_FUNCTION_MODULE       = 2
*     OTHERS                   = 3
            .
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


  CLEAR: WA_CONTROL_PARAMETERS, WA_OUTPUT_OPT, WA_JOB_OUTPUT_INFO.
**這段決定是否後面還有接別的SMARTFORM(PAG是要接別的SMARTFORM)
  CASE PFV_FUNCT.
    WHEN 'PAG'.
      WA_CONTROL_PARAMETERS-NO_CLOSE  = 'X'.
      WA_OUTPUT_OPT-TDNEWID           = 'X'.
    WHEN 'ALL'.
      WA_CONTROL_PARAMETERS-NO_CLOSE  = ''.
      WA_OUTPUT_OPT-TDNEWID           = ''.
    WHEN OTHERS.
  ENDCASE.

  WA_CONTROL_PARAMETERS-PREVIEW   = 'X'.
  WA_CONTROL_PARAMETERS-LANGU     = 'M'.
  WA_CONTROL_PARAMETERS-NO_DIALOG = 'X'.
  WA_OUTPUT_OPT-TDDEST            = 'LOCL'.
  WA_OUTPUT_OPT-TDIMMED           = 'X'.
***若是ZBD40231 Call只要PDF的I_OTF
  IF P_JOBTPS = 'E' OR
    ( P_JOBTPS = 'N' AND PFV_UCOMM = 'APF').    "目前只有開放用全部頁面在同一個PDF中
    WA_OUTPUT_OPT-TDDEST            = 'ZPDF'.
    WA_CONTROL_PARAMETERS-PREVIEW   = ''.
    WA_CONTROL_PARAMETERS-GETOTF    = 'X'.
  ENDIF.




  CALL FUNCTION L_FM_NAME
    EXPORTING
      CONTROL_PARAMETERS = WA_CONTROL_PARAMETERS
      OUTPUT_OPTIONS     = WA_OUTPUT_OPT
      USER_SETTINGS      = ''
    IMPORTING
      JOB_OUTPUT_INFO    = WA_JOB_OUTPUT_INFO
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.

  APPEND LINES OF WA_JOB_OUTPUT_INFO-OTFDATA TO I_OTFS.


ENDFORM.                    " IMEX_SEND_TO_SMARTFORM
*&---------------------------------------------------------------------*
*&      Form  KEEP_SELECT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM KEEP_SELECT_DATA TABLES PF_HEAD STRUCTURE I_HEAD.
  LOOP AT PF_HEAD.
    CASE PF_HEAD-ZTYPE.
      WHEN 'P'.
        CHECK P_PACKS IS INITIAL.
        DELETE PF_HEAD.
      WHEN 'I'.
        CHECK P_INVOS IS INITIAL.
        DELETE PF_HEAD.
      WHEN 'C'.
        CHECK P_CREMO IS INITIAL.
        DELETE PF_HEAD.
      WHEN 'D'.
        CHECK P_DEBMO IS INITIAL.
        DELETE PF_HEAD.
      WHEN 'F'.
        CHECK P_FINVO IS INITIAL.
        DELETE PF_HEAD.
      WHEN 'R'.
        CHECK P_PINVO IS INITIAL.
        DELETE PF_HEAD.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
**不是外部系統CALL及SA的權限下才需要做下面的動作
*  IF V_SDFTP IS NOT INITIAL AND P_JOBTPS IS INITIAL.
*****在開始就先FTP出去,不要放在PRINT PREVIEW
*    PERFORM SEND_DOC_TO_OUTSIDE USING  'FTP'
*                                       'AUTO'
*                                       ''.
*    PERFORM UPDATE_INFO_TO_TABLE USING 'GEN'.   "I131205
*  ENDIF.
*<-D141231
**外部系統CALL才要做以下動作(出庫單)
*  IF P_JOBTPS = 'B'.
*    PERFORM UPDATE_INFO_TO_TABLE USING 'OUT'.
*  ENDIF.
*->D141231
*<-I141231
  CASE P_JOBTPS.
    WHEN 'B'.
      PERFORM UPDATE_INFO_TO_TABLE USING 'OUT'.                                                   "B=出庫單
    WHEN ''.
      PERFORM UPDATE_INFO_TO_TABLE USING 'GEN'.
    WHEN OTHERS.
  ENDCASE.
*->I141231
ENDFORM.                    " KEEP_SELECT_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_RELNO_DATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VGBEL  text
*      <--P_I_HEAD_RELNO  text
*      <--P_I_HEAD_CDATE  text
*----------------------------------------------------------------------*
FORM GET_RELNO_DATE  USING    PFV_VGBEL
                              PFV_DOCTS
                     CHANGING PFV_RELNO
                              PFV_CDATE.
  DATA: BEGIN OF PF_DATE OCCURS 0,
          CDATE TYPE ZIXCRELDAT,
        END OF PF_DATE.
  DATA: PFWA_ZWHRELNO LIKE ZWHRELNO,
        PF_VBRP       LIKE VBRP OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_RELNO, PFV_CDATE.

  CASE PFV_DOCTS.
    WHEN 'SHIP'.
      PERFORM GET_WORKAREA_ZWHRELNO USING     PFV_VGBEL
                                    CHANGING  PFWA_ZWHRELNO.
      CHECK PFWA_ZWHRELNO IS NOT INITIAL.
      PFV_RELNO    = PFWA_ZWHRELNO-RELNO.       "(X)放行單號
      PFV_CDATE    = PFWA_ZWHRELNO-CRELDATE.    "(X)放行單日期
    WHEN 'BILL'.    "多筆只抓最後一筆日期
      PERFORM GET_DATA_VBRP TABLES PF_VBRP
                            USING  PFV_VGBEL.
      CHECK PF_VBRP[] IS NOT INITIAL.
      LOOP AT PF_VBRP.
        PERFORM GET_WORKAREA_ZWHRELNO USING     PF_VBRP-VGBEL
                                      CHANGING  PFWA_ZWHRELNO.
        CHECK PFWA_ZWHRELNO IS NOT INITIAL.
        PF_DATE-CDATE = PFWA_ZWHRELNO-CRELDATE.
        APPEND PF_DATE.
      ENDLOOP.
      SORT  PF_DATE DESCENDING.
      READ TABLE PF_DATE INDEX 1.
      PFV_CDATE = PF_DATE-CDATE.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_RELNO_DATE
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZSDML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_ZSDEL TABLES PF_ZSDEL_I  STRUCTURE M_ZSDEL
                  USING  PFWA_HEAD_I STRUCTURE MWA_HEAD.

  DATA: PF_ZSDEL_UP   LIKE ZSDEL OCCURS 0 WITH HEADER LINE,
        PFV_ZTYPE(02) TYPE C,
        PFV_ZITEM(03) TYPE N.

  CLEAR: PF_ZSDEL_UP, PF_ZSDEL_UP[], PFV_ZTYPE, PFV_ZITEM.
  PFV_ZTYPE = PFWA_HEAD_I-ZTYPE.
  IF PFWA_HEAD_I-ZTYPE = 'C' OR
     PFWA_HEAD_I-ZTYPE = 'D' OR
     PFWA_HEAD_I-ZTYPE = 'F'.
    PFV_ZTYPE = 'I'.
  ENDIF.
**取得ITEM最後一個號碼
  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_ZSDEL_UP FROM  ZSDEL
                                                          WHERE REPID =   SY-CPROG
                                                          AND   KUNAG =   PFWA_HEAD_I-KUNAG.
  SORT PF_ZSDEL_UP BY ITEM DESCENDING.
  READ TABLE PF_ZSDEL_UP INDEX 1.
  PFV_ZITEM = PF_ZSDEL_UP-ITEM + 1.
  CLEAR: PF_ZSDEL_UP, PF_ZSDEL_UP[].

  LOOP AT PF_ZSDEL_I.
    MOVE-CORRESPONDING PF_ZSDEL_I TO PF_ZSDEL_UP.
    IF PF_ZSDEL_I-KUNAG IS INITIAL.             "沒有KUNAG表示為新加的那一筆
      PF_ZSDEL_UP-REPID   = SY-CPROG.
*      PF_ZSDEL_UP-VKORG   = PF_ZSDEL_I-VKORG.
      PF_ZSDEL_UP-KUNAG   = PFWA_HEAD_I-KUNAG.
      PF_ZSDEL_UP-TYPE    = PFV_ZTYPE.
      PF_ZSDEL_UP-ITEM    = PFV_ZITEM.
      PF_ZSDEL_UP-KUNNR   = PFWA_HEAD_I-KUNNR.
      PF_ZSDEL_UP-RECESC  = 'U'.

      ADD 1 TO PFV_ZITEM.
    ENDIF.
    APPEND PF_ZSDEL_UP.
  ENDLOOP.
  MODIFY ZSDEL FROM TABLE PF_ZSDEL_UP.
ENDFORM.                    " UPDATE_ZSDML
**&---------------------------------------------------------------------*
**&      Form  GET_PROFORMA_RATE
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_I_HEAD_VBELN  text
**      <--P_P_PRATE  text
**----------------------------------------------------------------------*
*form GET_PROFORMA_RATE  using    PPF_VBELN
*                        changing PPF_PRATE.
*
*  DATA: PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.
*  CLEAR: PPF_PRATE.
*  PERFORM GET_LONG_TEXT TABLES PF_LINES
*                        USING  PPF_VBELN
*                               'T02'
*                               'VBBK'.
*  READ TABLE PF_LINES INDEX 1.
*  CHECK SY-SUBRC = 0.
*  PPF_PRATE = PF_LINES-TDLINE.
*  CONDENSE PPF_PRATE NO-GAPS.
*endform.                    " GET_PROFORMA_RATE
**&---------------------------------------------------------------------*
*&      Form  WM_SEND_TO_SMARTFORM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_8227   text
*----------------------------------------------------------------------*
FORM WM_SEND_TO_SMARTFORM  USING    PFV_ZDOCS
                                    PFV_SFEND.
  DATA: L_FM_NAME             TYPE RS38L_FNAM,
        WA_CONTROL_PARAMETERS TYPE SSFCTRLOP,           "SMARTFORM控制參數
        WA_OUTPUT_OPT         TYPE SSFCOMPOP,           "SMARTFORM打印時的參數
        WA_JOB_OUTPUT_INFO    TYPE SSFCRESCL,           "SMARTFORM傳出資料的值
        P_OTFDATA             TYPE TSFOTF,
        P_TDSFNAME            TYPE TDSFNAME.



  CASE PFV_ZDOCS.
    WHEN 'OUTD'.  "出庫單
      P_TDSFNAME = 'ZSD_SF005_WM1'.
    WHEN 'CHCK'.  "出庫檢查表
      P_TDSFNAME = 'ZSD_SF005_WM2'.
    WHEN OTHERS.
  ENDCASE.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME                 = P_TDSFNAME
*     VARIANT                  = ' '
*     DIRECT_CALL              = ' '
    IMPORTING
      FM_NAME                  = L_FM_NAME
*   EXCEPTIONS
*     NO_FORM                  = 1
*     NO_FUNCTION_MODULE       = 2
*     OTHERS                   = 3
            .
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CLEAR: WA_CONTROL_PARAMETERS, WA_OUTPUT_OPT, WA_JOB_OUTPUT_INFO.
  WA_CONTROL_PARAMETERS-PREVIEW   = 'X'.
  WA_CONTROL_PARAMETERS-LANGU     = 'M'.
  WA_CONTROL_PARAMETERS-NO_DIALOG = 'X'.
  WA_OUTPUT_OPT-TDDEST            = 'LOCL'.
  WA_OUTPUT_OPT-TDIMMED           = 'X'.


  PERFORM GET_SSF_PARAMETER USING     PFV_SFEND
                            CHANGING  WA_CONTROL_PARAMETERS-NO_CLOSE
                                      WA_CONTROL_PARAMETERS-NO_OPEN
                                      WA_OUTPUT_OPT-TDNEWID.



  CALL FUNCTION L_FM_NAME
    EXPORTING
      CONTROL_PARAMETERS = WA_CONTROL_PARAMETERS
      OUTPUT_OPTIONS     = WA_OUTPUT_OPT
      USER_SETTINGS      = ''
      I_CPROG            = SY-CPROG
    IMPORTING
      JOB_OUTPUT_INFO    = WA_JOB_OUTPUT_INFO
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.

ENDFORM.                    " WM_SEND_TO_SMARTFORM
*&---------------------------------------------------------------------*
*&      Form  WM_USER_SELECTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_OCPROG  text
*----------------------------------------------------------------------*
FORM WM_USER_SELECTION USING PFV_ZDOCS.
  DATA: BEGIN OF PF_DELI OCCURS 0,
          VBELN   TYPE VBELN_VL,
          KUNNR   TYPE KUNAG,         "SHIP-TO
          COUTD   TYPE N,             "出貨單份數
          CPACK   TYPE N,             "Packing份數
          CHECK   TYPE N,             "出庫檢查表份數
        END OF PF_DELI.

  DATA: BEGIN OF PF_OUTD OCCURS 0,
          ZDOCS TYPE C,
          VBELN LIKE LIKP-VBELN,
          ENDFG TYPE C,
        END OF PF_OUTD.

  DATA: PFWA_LIKP       LIKE LIKP,
        PFV_COUNT(04)   TYPE N,
        PFWM1_HEAD_BK   LIKE WM1_I_HEAD OCCURS 0 WITH HEADER LINE,                                    "備份用
        PFWM2_HEAD_BK   LIKE WM2_I_HEAD OCCURS 0 WITH HEADER LINE,                                    "備份用
        PF_HEAD_BK      LIKE I_HEAD     OCCURS 0 WITH HEADER LINE.                                    "備份用

  CLEAR: PF_DELI, PF_DELI[], PF_OUTD, PF_OUTD[].

  LOOP AT I_HEAD.
    PF_DELI-VBELN = I_HEAD-VBELN.
    PF_DELI-KUNNR = I_HEAD-KUNNR.
    PF_DELI-CPACK = 1.
    PF_DELI-COUTD = 1.
    PF_DELI-CHECK = 1.
    APPEND PF_DELI.
    CLEAR  PF_DELI.
  ENDLOOP.

**出入庫-->PACKING
  LOOP AT PF_DELI.
    IF PFV_ZDOCS+0(1) = 'X'.
      DO PF_DELI-COUTD TIMES.
        PF_OUTD-ZDOCS = 'O'.          "出庫單
        PF_OUTD-VBELN = PF_DELI-VBELN.
        APPEND PF_OUTD.
        CLEAR  PF_OUTD.
      ENDDO.
    ENDIF.
    IF PFV_ZDOCS+1(1) = 'X'.
      DO PF_DELI-CHECK TIMES.
        PF_OUTD-ZDOCS = 'Q'.          "出庫檢查表
        PF_OUTD-VBELN = PF_DELI-VBELN.
        APPEND PF_OUTD.
        CLEAR  PF_OUTD.
      ENDDO.
    ENDIF.
    IF PFV_ZDOCS+2(1) = 'X'.
      DO PF_DELI-CPACK TIMES.
        PF_OUTD-ZDOCS = 'X'.          "PACKING
        PF_OUTD-VBELN = PF_DELI-VBELN.
        APPEND PF_OUTD.
        CLEAR  PF_OUTD.
      ENDDO.
    ENDIF.
  ENDLOOP.

  SORT PF_OUTD BY VBELN DESCENDING ZDOCS DESCENDING.
  READ TABLE PF_OUTD INDEX 1.
  PF_OUTD-ENDFG = 'X'.
  MODIFY PF_OUTD INDEX SY-TABIX.
  SORT PF_OUTD BY VBELN ZDOCS ENDFG.   "ZDOC = O->X->Z
  DESCRIBE TABLE PF_OUTD LINES PFV_COUNT.
  READ TABLE PF_OUTD INDEX 1.
  IF PFV_COUNT > 1.
    PF_OUTD-ENDFG = 'F'.
  ELSE.
    PF_OUTD-ENDFG = 'N'.
  ENDIF.
  MODIFY PF_OUTD INDEX SY-TABIX.



  APPEND LINES OF WM1_I_HEAD  TO PFWM1_HEAD_BK.
  APPEND LINES OF WM2_I_HEAD  TO PFWM2_HEAD_BK.
  APPEND LINES OF I_HEAD      TO PF_HEAD_BK.

**PFV_FNCTN的位置意義 X表示列印 O表示不印
**第一碼=出庫單 第二碼=PACKING 第三碼=出庫檢驗

  LOOP AT PF_OUTD.
    CLEAR: WM1_I_HEAD, WM1_I_HEAD[], WM2_I_HEAD, WM2_I_HEAD[], I_HEAD, I_HEAD[].
**出入庫單+Packing+出庫檢驗
    IF PFV_ZDOCS+0(03) = 'XXX'.
      IF PF_OUTD-ZDOCS = 'O'.
        READ TABLE PFWM1_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM1_HEAD_BK TO WM1_I_HEAD.
        APPEND WM1_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'OUTD'         "出入庫申請單
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      IF PF_OUTD-ZDOCS = 'Q'.
        READ TABLE PFWM2_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM2_HEAD_BK TO WM2_I_HEAD.
        APPEND WM2_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'CHCK'         "出庫檢查表
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      IF PF_OUTD-ZDOCS = 'X'.
        READ TABLE PF_HEAD_BK WITH KEY VBELN = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PF_HEAD_BK TO I_HEAD.
        APPEND I_HEAD.
        PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                        PF_OUTD-ENDFG.
      ENDIF.

      CONTINUE.
    ENDIF.
**出入庫單+出庫檢驗
    IF PFV_ZDOCS+0(03) = 'XX '.
      IF PF_OUTD-ZDOCS = 'O'.
        READ TABLE PFWM1_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM1_HEAD_BK TO WM1_I_HEAD.
        APPEND WM1_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'OUTD'         "出入庫申請單
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      IF PF_OUTD-ZDOCS = 'Q'.
        READ TABLE PFWM2_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM2_HEAD_BK TO WM2_I_HEAD.
        APPEND WM2_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'CHCK'         "出庫檢查表
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      CONTINUE.
    ENDIF.
**出入庫單+Packing
    IF PFV_ZDOCS+0(03) = 'X X'.
      IF PF_OUTD-ZDOCS = 'O'.
        READ TABLE PFWM1_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM1_HEAD_BK TO WM1_I_HEAD.
        APPEND WM1_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'OUTD'         "出入庫申請單
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      IF PF_OUTD-ZDOCS = 'X'.
        READ TABLE PF_HEAD_BK WITH KEY VBELN = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PF_HEAD_BK TO I_HEAD.
        APPEND I_HEAD.
        PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                        PF_OUTD-ENDFG.
      ENDIF.
      CONTINUE.
    ENDIF.
**出庫檢驗+Packing
    IF PFV_ZDOCS+0(03) = ' XX'.
      IF PF_OUTD-ZDOCS = 'Q'.
        READ TABLE PFWM2_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM2_HEAD_BK TO WM2_I_HEAD.
        APPEND WM2_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'CHCK'         "出庫檢查表
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      IF PF_OUTD-ZDOCS = 'X'.
        READ TABLE PF_HEAD_BK WITH KEY VBELN = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PF_HEAD_BK TO I_HEAD.
        APPEND I_HEAD.
        PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                        PF_OUTD-ENDFG.
      ENDIF.
      CONTINUE.
    ENDIF.
**出入庫單
    IF PFV_ZDOCS+0(01) = 'X'.
      READ TABLE PFWM1_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
      MOVE-CORRESPONDING PFWM1_HEAD_BK TO WM1_I_HEAD.
      APPEND WM1_I_HEAD.
      PERFORM WM_SEND_TO_SMARTFORM USING 'OUTD'           "出入庫申請單
                                         PF_OUTD-ENDFG.   "判斷是否結束
      CONTINUE.
    ENDIF.
**出庫檢驗
    IF PFV_ZDOCS+1(01) = 'X'.
      IF PF_OUTD-ZDOCS = 'Q'.
        READ TABLE PFWM2_HEAD_BK WITH KEY VGBEL = PF_OUTD-VBELN.
        MOVE-CORRESPONDING PFWM2_HEAD_BK TO WM2_I_HEAD.
        APPEND WM2_I_HEAD.
        PERFORM WM_SEND_TO_SMARTFORM USING 'CHCK'         "出庫檢查表
                                           PF_OUTD-ENDFG. "判斷是否結束
      ENDIF.
      CONTINUE.
    ENDIF.
**Packing
    IF PFV_ZDOCS+2(01) = 'X'.
      READ TABLE PF_HEAD_BK WITH KEY VBELN = PF_OUTD-VBELN.
      MOVE-CORRESPONDING PF_HEAD_BK TO I_HEAD.
      APPEND I_HEAD.
      PERFORM SEND_TO_SMARTFORM USING 'GEN'
                                      PF_OUTD-ENDFG.
      CONTINUE.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " WM_USER_SELECTION
*&---------------------------------------------------------------------*
*&      Form  GET_SSF_PARAMETER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_SFEND  text
*      <--P_WA_CONTROL_PARAMETERS_NO_CLOSE  text
*      <--P_WA_CONTROL_PARAMETERS_NO_OPEN  text
*      <--P_WA_OUTPUT_OPT_TDNEWID  text
*----------------------------------------------------------------------*
FORM GET_SSF_PARAMETER  USING    PF_RECOD
                        CHANGING PF_NO_CLOSE
                                 PF_NO_OPEN
                                 PF_TDNEWID.
  CLEAR: PF_NO_CLOSE, PF_NO_OPEN, PF_TDNEWID.

  CASE PF_RECOD.
    WHEN 'X'.                                                                                     "有多筆的最後一筆
      PF_NO_CLOSE  = ''.
      PF_NO_OPEN   = 'X'.
*      PF_TDNEWID   = ''.
    WHEN 'F'.                                                                                     "有多筆的第一筆
      PF_NO_CLOSE  = 'X'.
      PF_NO_OPEN   = ''.
*      PF_TDNEWID   = 'X'.
    WHEN 'N'.                                                                                     "只有一筆
      PF_NO_CLOSE  = ''.
      PF_NO_OPEN   = ''.
*      PF_TDNEWID   = 'X'.
    WHEN OTHERS.                                                                                  "有多筆的中間筆數
      PF_NO_CLOSE  = 'X'.
      PF_NO_OPEN   = 'X'.
*      PF_TDNEWID   = 'X'.
  ENDCASE.

ENDFORM.                    " GET_SSF_PARAMETER
*&---------------------------------------------------------------------*
*&      Form  GET_PROFORMA_CONDITIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_PERFI  text
*      <--P_O_KWERT  text
*      <--P_O_KBETR  text
*      <--P_O_WAERK  text
*----------------------------------------------------------------------*
FORM GET_PROFORMA_CONDITIONS  USING    PFV_VBELN
                              CHANGING PFV_FOAMT_O
                                       PFV_PITAX_O
                                       PFV_WAERK_O.
  DATA: PFWA_IVRK  LIKE  BAPIVBRKOUT.

  CLEAR: PFWA_IVRK, PFV_FOAMT_O, PFV_PITAX_O, PFV_WAERK_O.
  CALL FUNCTION 'BAPI_BILLINGDOC_GETDETAIL'
    EXPORTING
      BILLINGDOCUMENT       = PFV_VBELN
    IMPORTING
      BILLINGDOCUMENTDETAIL = PFWA_IVRK.
*     RETURN                      =
  CHECK SY-SUBRC = 0.
  PFV_FOAMT_O = PFWA_IVRK-NET_VALUE.
  PFV_PITAX_O = PFWA_IVRK-TAX_VALUE.
  PFV_WAERK_O = PFWA_IVRK-CURRENCY.

ENDFORM.                    " GET_PROFORMA_CONDITIONS
*&---------------------------------------------------------------------*
*&      Form  AUTH_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM AUTH_CHECK USING PF_ZTYPE.
  DATA: PF_US335  LIKE US335 OCCURS 0 WITH HEADER LINE,
        PFV_INPUT TYPE C.
* I190514 -->
  PERFORM GET_AUTH_VALUES TABLES    PF_US335
                          USING     'Z_USRGRP'.
  IF PF_US335[] IS INITIAL.
    MESSAGE E000 WITH '您沒有足夠權限執行程式內容(OBJECT:Z_USRGRP)'.
    EXIT.
  ENDIF.
* I190514 <--

  READ TABLE PF_US335 WITH KEY LOWVAL = 'SALES'.            "I190514
  IF SY-SUBRC = 0.                                          "I190514
    IF PF_ZTYPE = 'EXEC' AND
       P_JOBTPS IS INITIAL.             "只有直接執行才要檢查權限
      AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
               ID 'VKORG' FIELD P_VKORG
               ID 'ACTVT' FIELD '03'.
      IF SY-SUBRC <> 0.
        MESSAGE E000 WITH '您沒有足夠權限執行Org = ' P_VKORG.
      ENDIF.
      EXIT.
    ENDIF.
  ENDIF.                                                    "I190514
* D190514 -->
*  PERFORM GET_AUTH_VALUES TABLES    PF_US335
*                          USING     'Z_USRGRP'.
*  IF PF_US335[] IS INITIAL.
*    MESSAGE E000 WITH '您沒有足夠權限執行程式內容(OBJECT:Z_USRGRP)'.
*    EXIT.
*  ENDIF.
* D190514 <--
  READ TABLE PF_US335 WITH KEY LOWVAL = 'SALES'.
  IF SY-SUBRC = 0.
    EXIT.
  ENDIF.

  READ TABLE PF_US335 WITH KEY LOWVAL = 'ACCOUNTING'.
  CHECK SY-SUBRC = 0.
  CASE PF_ZTYPE.
    WHEN 'SOUTPUT'.
      PERFORM SCREEN_MODIFY USING 'ACCT'.
    WHEN 'FUNCTION'.
      FC_TAB-FCODE = 'EML'.
      APPEND FC_TAB.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " AUTH_CHECK
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZBCOD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_ZBCOD .
  DATA: PFWA_LIKP LIKE LIKP,
        PFWA_LIPS LIKE LIPS,
        PFWA_VBAP LIKE VBAP,
        PFWA_VEKP LIKE VEKP,
        PFWA_VEPO LIKE VEPO,
        PF_ZBCOD LIKE ZBCOD OCCURS 0 WITH HEADER LINE,              "收集ZBCOD資料用
        PFV_TDNAM(16) TYPE C,
        PFV_LAENG(04) TYPE N,
        PFV_BREIT(04) TYPE N,
        PFV_HOEHE(04) TYPE N,
        PFV_CHAR30(30),
        PFWA_ZZAUSP LIKE ZZAUSP,
        PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.

  DATA: BEGIN OF PF_CARQT OCCURS 0,
          VBELN LIKE LIKP-VBELN,
          CORDE TYPE I,
        END OF PF_CARQT.
  DATA: BEGIN OF PF_ZDELNO OCCURS 0,                        "I090720
          VBELN LIKE ZBCOD-VBELN,                           "I090720
    END OF PF_ZDELNO.                                       "I090720

  CLEAR: PF_ZBCOD, PF_ZBCOD[].

  LOOP AT I_ITEM WHERE ZTYPE = 'P'.
    MOVE-CORRESPONDING I_ITEM TO PF_CARQT.
    APPEND  PF_CARQT.
    CLEAR   PF_CARQT.
  ENDLOOP.
  SORT PF_CARQT BY VBELN CORDE DESCENDING.
  DELETE ADJACENT DUPLICATES FROM PF_CARQT COMPARING VBELN.

  LOOP AT I_HEAD WHERE ZTYPE = 'P'.
    LOOP AT I_ITEM WHERE VBELN = I_HEAD-VGBEL
                   AND   ZTYPE = I_HEAD-ZTYPE.

      READ TABLE PF_CARQT WITH KEY VBELN = I_ITEM-VBELN.            "FOR Total Carton Qty
      CLEAR: MCHA.
      PERFORM GET_WORKAREA_LIKP USING     I_ITEM-VBELN
                                CHANGING  PFWA_LIKP.
      PERFORM GET_WORKAREA_LIPS USING     I_ITEM-VBELN
                                          I_ITEM-POSNR
                                CHANGING  PFWA_LIPS.
      PERFORM GET_WORKAREA_VBAP USING     PFWA_LIPS-VGBEL
                                          PFWA_LIPS-VGPOS
                                CHANGING  PFWA_VBAP.
      PERFORM GET_WORKAREA_VEKP USING     I_ITEM-VENUM
                                CHANGING  PFWA_VEKP.
      PERFORM GET_WORKAREA_VEPO USING     I_ITEM-VBELN
                                          I_ITEM-POSNR
                                CHANGING  PFWA_VEPO.
      SELECT SINGLE * FROM  MCHA
                      WHERE MATNR = PFWA_LIPS-MATNR
                      AND   WERKS = PFWA_LIPS-WERKS
                      AND   CHARG = PFWA_LIPS-CHARG.

      PF_ZBCOD-VBELN     = I_ITEM-VBELN.                            "Delivery
      PF_ZBCOD-POSNR     = I_ITEM-ITMNO.                            "Delivery Item
      PF_ZBCOD-ZCARTNO   = I_ITEM-CORDE.                            "Carton No.
      PF_ZBCOD-ZCARTQTY  = PF_CARQT-CORDE.                          "Total Carton Qty
      PF_ZBCOD-WADAT     = PFWA_LIKP-KODAT.                         "Picking Date
      PF_ZBCOD-MATNR     = I_ITEM-MATNR.                            "Material Number
      PF_ZBCOD-ZKURAKI   = MCHA-LICHA(4).                           "Kuraki
      PF_ZBCOD-ZCASENO   = I_ITEM-CORDE.                            "Case No
      PF_ZBCOD-TAVOL     = I_ITEM-DWEMN.                            "Base Quantity Packed in the Handling Unit Item
      PF_ZBCOD-VOLEH     = I_ITEM-WEMEH.                            "Base Unit of Measure of the Quantity to be Packed (VEMNG)
      PF_ZBCOD-BRGEW     = PFWA_VEKP-BRGEW.                         "Total Weight of Handling Unit
      PF_ZBCOD-GEWEI     = PFWA_VEKP-GEWEI.                         "Weight Unit
      PF_ZBCOD-ZDATECODE = I_ITEM-DCODE.                            "Date code
      PF_ZBCOD-BSTNK     = I_ITEM-BSTNK.                            "Customer purchase order number
      PF_ZBCOD-KDMAT     = I_ITEM-KDMAT.                            "Material belonging to the customer

      PF_ZBCOD-KUNAG     = I_ITEM-KUNAG.                            "Sold-to party
      PF_ZBCOD-CHARG     = I_ITEM-CHARG.                            "Batch Number
      PF_ZBCOD-RF_PONO1  = ''.                                      "Purchase order noPurchase order no
      PF_ZBCOD-DNIT      = PFWA_LIPS-UECHA.                         "Delivery Item

      PF_ZBCOD-BCODE     = ''.                                      "Elpida batch code(沒有這家客戶1390)
      PF_ZBCOD-NTGEW     = PFWA_VEKP-NTGEW.                         "Net Weight
*     PF_ZBCOD-EKDMAT    = ''.                                      "End customer material no(1659使用,目前沒交易)
      PF_ZBCOD-DNNO      = ''.                                      "Delivery
      PF_ZBCOD-LOTNO     = I_ITEM-LOTNO.                            "LOT NO (char=15)

      PF_ZBCOD-WERKS     = PFWA_LIPS-WERKS.                         "PLANT
      PF_ZBCOD-WVEMNG    = I_ITEM-DWEMN.                            "Wafer qty for die shipment  "以die計價有寫入Wafer qty
      PF_ZBCOD-EBSTNK    = ''.                                      "Customer purchase order number(LONG TEXT 'ZQC5' 'VBBP')
      PF_ZBCOD-VENUM     = PFWA_VEPO-VENUM.
      PF_ZBCOD-VEPOS     = PFWA_VEPO-VEPOS.
*
      IF I_ITEM-CEMEH <> ''.                "非以Wafer 計價的情況
        PF_ZBCOD-TAVOL     = I_ITEM-DCEMN.                            "Base Quantity
        PF_ZBCOD-VOLEH     = I_ITEM-CEMEH.                            "Base Unit of Measure
      ENDIF.

      CONCATENATE PFWA_LIPS-VGBEL PFWA_LIPS-VGPOS
        INTO PFV_TDNAM.
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  PFV_TDNAM
                                   '0001'
                                   'VBBP'.
      READ TABLE PF_LINES INDEX 1.
      IF SY-SUBRC = 0.
        PF_ZBCOD-ZCKURAKI = PF_LINES-TDLINE+0(04).                  "Customer KURAKI
      ENDIF.
      WRITE PFWA_VBAP-POSEX TO PF_ZBCOD-POSEX.                      "Item Number of the Underlying Purchase Order

*<-D210618 在get item data就換好了
**-- Non fuoundry change mater (Check vi KURIKI), I_HEAD-SPART <> '02'才會RUN
*      PERFORM GET_MATERIAL_BY_KURKI_12  USING    I_HEAD-SPART
*                                                 I_ITEM-KURKI
*                                        CHANGING PF_ZBCOD-MATNR.
*<-這段已放在SP_RULE_FOR_ITEM_BY_CUSTGP中先行處理了
*      IF I_ITEM-KUNAG IN R_KTC.
*        CONCATENATE I_ITEM-AUBEL I_ITEM-AUBEL INTO PFV_TDNAM.
*        CLEAR  PFV_CHAR30.
**Get ship to PN on so item (KCT label using)
*        PERFORM GET_SHIP_TO_PN    USING PFV_TDNAM
*                               CHANGING PF_ZBCOD-EKDMAT.
***- KTC Group Show 14碼 part no
*        PERFORM GET_WORKAREA_ZZAUSP USING I_ITEM-WERKS
*                                          I_ITEM-MATNR
*                                 CHANGING PFWA_ZZAUSP.
**        IF I_ITEM-WERKS = 'PSC4' AND PFWA_ZZAUSP-PRODTYPE <> 'P'.
**          PF_ZBCOD-MATNR = PF_ZBCOD-MATNR+0(14).
**        ENDIF.
*
*      ENDIF.
*->D210618
**取得尺寸資訊
      PF_ZBCOD-LAENG     = PFWA_VEKP-LAENG.                         "Length
      PF_ZBCOD-BREIT     = PFWA_VEKP-BREIT.                         "Width
      PF_ZBCOD-HOEHE     = PFWA_VEKP-HOEHE.                         "Height
      IF  PFWA_VEKP-LAENG IS INITIAL AND
          PFWA_VEKP-BREIT IS INITIAL AND
          PFWA_VEKP-HOEHE IS INITIAL.                               "長寬高都沒有值從MARA抓

        CLEAR: MARA.
        SELECT SINGLE * FROM  MARA
                        WHERE MATNR = PFWA_VEKP-VHILM.

        SPLIT MARA-GROES AT 'X' INTO PFV_LAENG PFV_BREIT PFV_HOEHE.
        PF_ZBCOD-LAENG     = PFV_LAENG.
        PF_ZBCOD-BREIT     = PFV_BREIT.
        PF_ZBCOD-HOEHE     = PFV_HOEHE.
      ENDIF.
      APPEND PF_ZBCOD.
      CLEAR: PF_ZBCOD.
    ENDLOOP.
    PF_ZDELNO-VBELN = I_HEAD-VGBEL.                         "I090720
    COLLECT PF_ZDELNO.                                      "I090720
  ENDLOOP.
  PERFORM SP_RULE_FOR_ZBCOD TABLES PF_ZBCOD.
  CHECK PF_ZBCOD[] IS NOT INITIAL.
*090720-->I
  LOOP AT PF_ZDELNO.
    DELETE FROM ZBCOD WHERE VBELN = PF_ZDELNO-VBELN.
  ENDLOOP.
  INSERT ZBCOD FROM TABLE PF_ZBCOD.
*090720<--I
* MODIFY ZBCOD FROM TABLE PF_ZBCOD.         "D090720
ENDFORM.                    " UPDATE_ZBCOD
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_ZBCOD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ZBCOD TABLES PF_ZBCOD_I STRUCTURE ZBCOD.

  LOOP AT PF_ZBCOD_I WHERE KUNAG = '0000001270'.
    CLEAR: PF_ZBCOD_I-LOTNO.
    PF_ZBCOD_I-LOTNO = PF_ZBCOD_I-ZDATECODE.
    MODIFY PF_ZBCOD_I.
  ENDLOOP.
ENDFORM.                    " SPECIAL_RULE_FOR_ZBCOD
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZF32CA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM UPDATE_ZF32CA .
  DATA: BEGIN OF P_BOXES OCCURS 0,
          VBELN     LIKE VBFA-VBELN,        "Internal HU number
          VHILM     LIKE VEKP-VHILM,        "紙箱的型號
          LAENG     TYPE I, "LIKE VEKP-LAENG,
          BREIT     TYPE I, "LIKE VEKP-BREIT,
          HOEHE     TYPE I, "LIKE VEKP-HOEHE,
          BRGEW     LIKE VEKP-BRGEW,        "Total Weight
          NTGEW     LIKE VEKP-NTGEW,        "Loading weight
          ZTYPE(03) TYPE C,
        END OF P_BOXES.

  DATA: BEGIN OF P_BOXES_S OCCURS 0,
          VHILM     LIKE VEKP-VHILM,        "紙箱的型號
          PACKS     LIKE ZF32CA-F32_PACK,   "箱數
          LAENG     LIKE ZF32CA-F32_LONG,   "紙箱的長
          BREIT     LIKE ZF32CA-F32_WIDE,   "紙箱的寬
          HOEHE     LIKE ZF32CA-F32_HIGH,   "紙箱的高
          ZTYPE(03) TYPE C,
        END OF P_BOXES_S.

  DATA: P_ZF32CA    LIKE ZF32CA   OCCURS 0 WITH HEADER LINE,
        PF_BOX_TMP  LIKE P_BOXES  OCCURS 0 WITH HEADER LINE,
        PF_VBFA     LIKE VBFA     OCCURS 0 WITH HEADER LINE,
        PFWA_VEKP   LIKE VEKP,
        PFWA_KNA1   LIKE KNA1,
        PFWA_T005T  LIKE T005T,
        F_NUMB1(02) TYPE C,
        F_NUMB2(02) TYPE C.

  LOOP AT I_HEAD WHERE ZTYPE = 'P'.
    CLEAR: P_BOXES, P_BOXES[], P_BOXES_S, P_BOXES_S[].
**第一筆資訊START
    P_ZF32CA-VBELN      = I_HEAD-VBELN.                       "DN NO.
    P_ZF32CA-F32_SERNO  = 1.                                  "第一筆
    READ TABLE I_HEAD_SH WITH KEY VBELN = I_HEAD-VBELN
                                  ZTYPE = I_HEAD-ZTYPE.
    P_ZF32CA-F32_MARK   = I_HEAD_SH-NAME1.                    "SHIP-TO NAME
*<-D210422
*    SELECT * FROM  VBFA
*             WHERE VBELV   = I_HEAD-VBELN
*             AND   VBTYP_N = 'X'.
*->D210422
    PERFORM GET_FLOW_DATA_VBFA_HANDINGUNIT TABLES I_VBFA
                                                  PF_VBFA
                                           USING  I_HEAD-VBELN.
    LOOP AT PF_VBFA.
      PERFORM GET_WORKAREA_VEKP_UEVEL USING     PF_VBFA-VBELN
                                      CHANGING  PFWA_VEKP.
      IF PFWA_VEKP IS NOT INITIAL.
        P_BOXES-VBELN = PF_VBFA-VBELN.          "Handling Unit
        P_BOXES-VHILM = PFWA_VEKP-VHILM.
        IF PFWA_VEKP-LAENG <> 0.
          P_BOXES-LAENG = PFWA_VEKP-LAENG.
        ENDIF.
        IF PFWA_VEKP-BREIT <> 0.
          P_BOXES-BREIT = PFWA_VEKP-BREIT.
        ENDIF.
        IF PFWA_VEKP-HOEHE <> 0.
          P_BOXES-HOEHE = PFWA_VEKP-HOEHE.
        ENDIF.
        P_BOXES-BRGEW = PFWA_VEKP-BRGEW.
        P_BOXES-NTGEW = PFWA_VEKP-NTGEW.
        P_BOXES-ZTYPE = 'CTN'.
      ELSE.
        PERFORM GET_WORKAREA_VEKP USING     PF_VBFA-VBELN
                                  CHANGING  PFWA_VEKP.
        P_BOXES-VBELN = PFWA_VEKP-UEVEL.        "Handling Unit
        PERFORM GET_WORKAREA_VEKP USING     P_BOXES-VBELN
                                  CHANGING  PFWA_VEKP.
        P_BOXES-VHILM = PFWA_VEKP-VHILM.
        P_BOXES-LAENG = PFWA_VEKP-LAENG.
        P_BOXES-BREIT = PFWA_VEKP-BREIT.
        P_BOXES-HOEHE = PFWA_VEKP-HOEHE.
        P_BOXES-BRGEW = PFWA_VEKP-BRGEW.
        P_BOXES-NTGEW = PFWA_VEKP-NTGEW.
        P_BOXES-ZTYPE = 'PLT'.
      ENDIF.
      APPEND P_BOXES.
      CLEAR  P_BOXES.
    ENDLOOP.
*    ENDSELECT.             <-D210422
    SORT P_BOXES BY VBELN.  "依箱號排序
    DELETE ADJACENT DUPLICATES FROM P_BOXES COMPARING VBELN.
    DESCRIBE TABLE P_BOXES LINES P_ZF32CA-F30_TNO.              "總箱數(一個Internal HU number就是一箱)
    LOOP AT P_BOXES.
      P_ZF32CA-F30_TOTAL = P_ZF32CA-F30_TOTAL + P_BOXES-BRGEW.  "總重
      P_ZF32CA-F30_NETW  = P_ZF32CA-F30_NETW  + P_BOXES-NTGEW.  "總NET WEIGHT

      MOVE-CORRESPONDING P_BOXES TO P_BOXES_S.
      APPEND P_BOXES_S.
      CLEAR  P_BOXES_S.
    ENDLOOP.

    SORT P_BOXES_S BY VHILM.  "依紙箱型號排序.
    DELETE ADJACENT DUPLICATES FROM P_BOXES_S COMPARING VHILM.
    LOOP AT P_BOXES_S.
      CLEAR: PF_BOX_TMP, PF_BOX_TMP[].
      APPEND LINES OF P_BOXES TO PF_BOX_TMP.
      DELETE PF_BOX_TMP WHERE VHILM <> P_BOXES_S-VHILM.
      DESCRIBE TABLE PF_BOX_TMP LINES P_BOXES_S-PACKS.              "計算這種箱子共幾箱
      PERFORM GET_BOX_LBH_VALUE USING     P_BOXES_S-VHILM
                                CHANGING  P_BOXES_S-LAENG
                                          P_BOXES_S-BREIT
                                          P_BOXES_S-HOEHE.
*<-D210422
*      CLEAR : F_PACKS.
*      LOOP AT P_BOXES WHERE VHILM = P_BOXES_S-VHILM.
*        ADD 1 TO F_PACKS.
*      ENDLOOP.
*      IF P_BOXES_S-LAENG = 0 AND
*         P_BOXES_S-BREIT = 0 AND
*         P_BOXES_S-HOEHE = 0.
*        PERFORM GET_WORKAREA_MARA USING     P_BOXES_S-VHILM         "Material No.
*                                  CHANGING  PFWA_MARA.
*        SPLIT PFWA_MARA-GROES AT 'X'
*          INTO P_BOXES_S-LAENG P_BOXES_S-BREIT P_BOXES_S-HOEHE.
*      ENDIF.
*      P_BOXES_S-PACKS = F_PACKS.
*->D210422
      MODIFY P_BOXES_S.
    ENDLOOP.

    IF P_BOXES_S[] IS NOT INITIAL.
      READ TABLE P_BOXES_S INDEX 1.
      P_ZF32CA-F32_LONG = P_BOXES_S-LAENG.                "這個SIZE紙箱的長
      P_ZF32CA-F32_WIDE = P_BOXES_S-BREIT.                "這個SIZE紙箱的寬
      P_ZF32CA-F32_HIGH = P_BOXES_S-HOEHE.                "這個SIZE紙箱的高
      P_ZF32CA-F32_PACK = P_BOXES_S-PACKS.                "這個SIZE紙箱的數量
      P_ZF32CA-F30_UNIT = P_BOXES_S-ZTYPE.                "箱裝/棧板

      DELETE P_BOXES_S INDEX 1.
    ENDIF.

**取得SHIP PLANT的資訊
    PERFORM GET_SHIPPING_PLANT USING    I_HEAD
                               CHANGING P_ZF32CA-SHIP_PLANT.
    APPEND P_ZF32CA.
    CLEAR  P_ZF32CA.
**第一筆資訊END

**第二筆資訊START
    P_ZF32CA-VBELN      = I_HEAD-VBELN.                         "DN NO.
    P_ZF32CA-F32_SERNO  = 2.                                    "第二筆
    PERFORM GET_WORKAREA_KNA1 USING     I_HEAD_SH-KUNAG
                              CHANGING  PFWA_KNA1.
    IF PFWA_KNA1-LAND1 = 'TW'.
      P_ZF32CA-F32_MARK+0(35) = PFWA_KNA1-ORT01.
    ELSE.
      PERFORM GET_WORKAREA_T005T USING    PFWA_KNA1-LAND1
                                 CHANGING PFWA_T005T.
      P_ZF32CA-F32_MARK+0(35) = PFWA_T005T-LANDX.
    ENDIF.
    WRITE I_HEAD-VBELN TO P_ZF32CA-F32_MARK+35.
    IF P_BOXES_S[] IS NOT INITIAL.
      READ TABLE P_BOXES_S INDEX 1.
      P_ZF32CA-F32_LONG = P_BOXES_S-LAENG.                        "這個SIZE紙箱的長
      P_ZF32CA-F32_WIDE = P_BOXES_S-BREIT.                        "這個SIZE紙箱的寬
      P_ZF32CA-F32_HIGH = P_BOXES_S-HOEHE.                        "這個SIZE紙箱的高
      P_ZF32CA-F32_PACK = P_BOXES_S-PACKS.                        "這個SIZE紙箱的數量
      DELETE P_BOXES_S INDEX 1.
    ENDIF.
    APPEND P_ZF32CA.
    CLEAR  P_ZF32CA.
**第二筆資訊END

**第三筆資訊START
    P_ZF32CA-VBELN      = I_HEAD-VBELN.                         "DN NO.
    P_ZF32CA-F32_SERNO  = 3.                                    "第三筆
    CLEAR: F_NUMB1, F_NUMB2.
    READ TABLE I_ITEM WITH KEY VBELN = I_HEAD-VBELN
                               ZTYPE = I_HEAD-ZTYPE.
    IF I_ITEM-PALNO IS NOT INITIAL.
      SPLIT I_ITEM-PALNO AT '/' INTO F_NUMB1 F_NUMB2.
      CONCATENATE 'P/NO:' F_NUMB1 '-' F_NUMB2 INTO P_ZF32CA-F32_MARK SEPARATED BY SPACE.
    ELSE.
      IF I_ITEM-CTNNO IS NOT INITIAL.
        SPLIT I_ITEM-CTNNO AT '/' INTO F_NUMB1 F_NUMB2.
        CONCATENATE 'C/NO:' F_NUMB1 '-' F_NUMB2 INTO P_ZF32CA-F32_MARK SEPARATED BY SPACE.
      ENDIF.
      PERFORM SP_RULE_FOR_ZF32CA_LINE3 USING    I_HEAD      "I032221
                                                F_NUMB1     "I032221
                                       CHANGING P_ZF32CA-F32_MARK."I032221
    ENDIF.
    IF P_BOXES_S[] IS NOT INITIAL.
      READ TABLE P_BOXES_S INDEX 1.
      P_ZF32CA-F32_LONG = P_BOXES_S-LAENG.                        "這個SIZE紙箱的長
      P_ZF32CA-F32_WIDE = P_BOXES_S-BREIT.                        "這個SIZE紙箱的寬
      P_ZF32CA-F32_HIGH = P_BOXES_S-HOEHE.                        "這個SIZE紙箱的高
      P_ZF32CA-F32_PACK = P_BOXES_S-PACKS.                        "這個SIZE紙箱的數量
      DELETE P_BOXES_S INDEX 1.
    ENDIF.
    APPEND P_ZF32CA.
    CLEAR  P_ZF32CA.
**第三筆資訊END

**第四筆資訊START
    P_ZF32CA-VBELN      = I_HEAD-VBELN.                         "DN NO.
    P_ZF32CA-F32_SERNO  = 4.                                    "第四筆
*<-I191021
    P_ZF32CA-F32_MARK   = 'Made In Taiwan'.
    IF I_HEAD-VKORG = 'PSC1' AND
       I_HEAD-KUNAG IN R_KTC.
      P_ZF32CA-F32_MARK = 'Made In TW'.                         "KTC only
    ENDIF.
*->I191021
    IF P_BOXES_S[] IS NOT INITIAL.
      READ TABLE P_BOXES_S INDEX 1.
      P_ZF32CA-F32_LONG = P_BOXES_S-LAENG.                        "這個SIZE紙箱的長
      P_ZF32CA-F32_WIDE = P_BOXES_S-BREIT.                        "這個SIZE紙箱的寬
      P_ZF32CA-F32_HIGH = P_BOXES_S-HOEHE.                        "這個SIZE紙箱的高
      P_ZF32CA-F32_PACK = P_BOXES_S-PACKS.                        "這個SIZE紙箱的數量
      DELETE P_BOXES_S INDEX 1.
    ENDIF.
    APPEND P_ZF32CA.
    CLEAR  P_ZF32CA.
**第四筆資訊END
  ENDLOOP.  "LOOP I_HEAD
  P_ZF32CA-ERDAT = SY-DATUM.
  P_ZF32CA-ERZET = SY-UZEIT.
  MODIFY P_ZF32CA TRANSPORTING ERDAT ERZET WHERE ERDAT IS INITIAL
                                           AND   ERZET IS INITIAL.

  MODIFY ZF32CA FROM TABLE P_ZF32CA.
ENDFORM.                    " UPDATE_ZF32CA
*&---------------------------------------------------------------------*
*&      Form  SPCEIAL_RULE_FOR_ITEM_INVOICE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_INVOICE TABLES  PF_ITEM_IO   STRUCTURE I_ITEM
                              USING   PFWA_HEAD_I  STRUCTURE I_HEAD.
  DATA: PF_ZBCOD    LIKE ZBCOD  OCCURS 0 WITH HEADER LINE,
        PF_ITEM_NXP LIKE I_ITEM OCCURS 0 WITH HEADER LINE,
        PFWA_3B2    LIKE ZSDNXP3B2,
        PFWA_VBAP   LIKE VBAP.

  CHECK PFWA_HEAD_I-ZTYPE = 'I'.                            "I = Invoice
*<-I210616
  CLEAR: PF_ITEM_NXP, PF_ITEM_NXP[].
  IF PFWA_HEAD_I-KUNAG = '0000002570'.                    "NXP可能會用到...先取
    PERFORM GET_DATA_ZBCOD  TABLES PF_ZBCOD
                          USING  PFWA_HEAD_I-VGBEL.
  ENDIF.

  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD_I-VBELN
                     AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
    CASE PFWA_HEAD_I-KUNAG.
      WHEN '0000003093'.                                   "LG 8"Only
        CHECK PFWA_HEAD_I-VKORG = 'MAX1'.
        CHECK P_JOBTPS IS INITIAL.
        CHECK PF_ITEM_IO-PSTYV = 'TANN'.
        CLEAR: PF_ITEM_IO-UNITP , PF_ITEM_IO-KWERT.
      WHEN '0000002570'.                                   "NXP 12"Only
        CHECK PFWA_HEAD_I-VKORG = 'PSC1'.
*-Get data in header(CHECK_NXP_ENG直接放入GET_NXP_DAT中)
        PERFORM GET_NXP_DATA USING    PFWA_HEAD_I
                             CHANGING PF_ITEM_IO.
*-Invoice wafer list 放在item
        PERFORM GET_NXP_WAFER_LIST USING    PFWA_HEAD_I
                                   CHANGING PF_ITEM_IO.

        PERFORM GET_WORKAREA_VBAP USING     PF_ITEM_IO-AUBEL
                                            PF_ITEM_IO-AUPOS
                                  CHANGING  PFWA_VBAP.
        IF PFWA_VBAP-ZZENGLOT <> 'Y'.
          PERFORM GET_WORKAREA_ZSDNXP3B2 USING    PF_ITEM_IO-VGBEL
                                                  PF_ITEM_IO-VGPOS
                                         CHANGING PFWA_3B2.
          IF PFWA_3B2 IS INITIAL.
            MESSAGE E000 WITH PFWA_HEAD_I-VBELN 'No NXP 3B2 data(1) exist!!'.
          ENDIF.
          READ TABLE PF_ZBCOD WITH KEY CHARG = PFWA_3B2-CHARG.
          MOVE PF_ZBCOD-ZCARTNO TO PF_ITEM_IO-POSNR.
          MOVE-CORRESPONDING PF_ITEM_IO TO PF_ITEM_NXP.
          PF_ITEM_NXP-ITMNO = PF_ITEM_NXP-POSNR+2(4).
          APPEND PF_ITEM_NXP.
          DELETE PF_ITEM_IO.
          CONTINUE.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.
    MODIFY PF_ITEM_IO.
    CLEAR: PF_ITEM_IO.
  ENDLOOP.

  CHECK PF_ITEM_NXP[] IS NOT INITIAL.
  SORT PF_ITEM_NXP.
  APPEND LINES OF PF_ITEM_NXP TO PF_ITEM_IO.

  PERFORM SP_RULE_FOR_ITEM_BY_CUSTGP TABLES PF_ITEM_IO
                                     USING  PFWA_HEAD_I.

*->I210616

*  IF PFWA_HEAD-VKORG = 'MAX1'.                            "8吋
*    CHECK PFWA_HEAD-KUNAG = '0000003093'.                 "LG
*
*    LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
*                    AND   ZTYPE = PFWA_HEAD-ZTYPE.
*      CHECK P_JOBTPS IS INITIAL.
*      CHECK PF_ITEM-PSTYV = 'TANN'.
*
*      CLEAR: PF_ITEM-UNITP , PF_ITEM-KWERT.
*
*      MODIFY PF_ITEM.
*      CLEAR  PF_ITEM.
*    ENDLOOP.
*  ENDIF.
*
*  IF PFWA_HEAD-VKORG = 'PSC1'.                              "12吋
*    CHECK PFWA_HEAD-KUNAG = '0000002570'.                  "NXP
*    LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
*                    AND   ZTYPE = PFWA_HEAD-ZTYPE.
**-Get data in header(CHECK_NXP_ENG直接放入GET_NXP_DAT中)
*      PERFORM GET_NXP_DATA USING    PFWA_HEAD
*                           CHANGING PF_ITEM.
**-Invoice wafer list 放在item
*      PERFORM GET_NXP_WAFER_LIST USING PFWA_HEAD
*                              CHANGING PF_ITEM.
*      MODIFY PF_ITEM.
*      CLEAR  PF_ITEM.
*    ENDLOOP.
*  ENDIF.

ENDFORM.                    " SPCEIAL_RULE_FOR_ITEM_INVOICE
*&---------------------------------------------------------------------*
*&      Form  NO_SHOW_PRICE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM NO_SHOW_PRICE TABLES PF_ITEM_IO STRUCTURE I_ITEM.
**針對INVOICE的金額是否顯示(如果放在GET ITEM就會算不出TOTAL)
  CHECK C_PE IS INITIAL.
  LOOP AT PF_ITEM_IO WHERE ZTYPE = 'I'.         "I = Invoice
    CLEAR: PF_ITEM_IO-UNITP, PF_ITEM_IO-KWERT.
    MODIFY PF_ITEM_IO.
  ENDLOOP.
ENDFORM.                    " NO_SHOW_PRICE
*&---------------------------------------------------------------------*
*&      Form  GET_GROSS_DIE_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_ZTYPE  text
*      -->P_I_ITEM_KUNAG  text
*----------------------------------------------------------------------*
FORM GET_GROSS_DIE_INFO  TABLES   PF_ITEM_I   STRUCTURE I_ITEM
                                  PF_DIES_I   STRUCTURE ZSD_FDMS
                         USING    PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: PF_ITEM_TMP     LIKE I_ITEM OCCURS 0 WITH HEADER LINE,
        PFW_ZMWH8H LIKE ZMWH8H,                             "I101419
        PFV_REMAK(300)  TYPE C,
        PFV_WDIES(10)   TYPE C,
        PFV_KBETR       TYPE KBETR,
        PFV_DELNO       LIKE LIKP-VBELN.                    "I101419

  DATA: BEGIN OF PF_MATNR OCCURS 0,
          MATNR     TYPE MATNR,
          KDMAT     TYPE KDMAT,
          GDPWO     LIKE ZSDA02-GDPWO,
          FKIMG     TYPE FKIMG,
          AMONT(14) TYPE C,
          DUPCE(20) TYPE C,
        END OF PF_MATNR.

  CLEAR: PF_ITEM_TMP, PF_ITEM_TMP[], PF_MATNR, PF_MATNR[].

**收集資料
  APPEND LINES OF PF_ITEM_I TO PF_ITEM_TMP.

  DELETE PF_ITEM_TMP WHERE VBELN <> PFWA_HEAD_I-VBELN
                        OR ZTYPE <> PFWA_HEAD_I-ZTYPE.

  SORT PF_ITEM_TMP BY MATNR.
  DELETE ADJACENT DUPLICATES FROM PF_ITEM_TMP COMPARING MATNR.
  LOOP AT PF_ITEM_TMP.
    CLEAR: PFV_KBETR.
    PF_MATNR-MATNR =  PF_ITEM_TMP-MATNR.
    PF_MATNR-KDMAT =  PF_ITEM_TMP-KDMAT.
    LOOP AT PF_ITEM_I WHERE VBELN = PF_ITEM_TMP-VBELN
                      AND   ZTYPE = PF_ITEM_TMP-ZTYPE
                      AND   MATNR = PF_ITEM_TMP-MATNR.
      PF_MATNR-FKIMG = PF_MATNR-FKIMG + PF_ITEM_I-DWEMN.
*      PFV_KBETR = PFV_KBETR + ( PF_ITEM_I-DWEMN * PF_ITEM_I-UNITP ).  "D030220
*030220-->I
      IF PF_ITEM_I-KPEIN <> 0.
        PFV_KBETR = PFV_KBETR + ( PF_ITEM_I-DWEMN *
                    ( PF_ITEM_I-UNITP / PF_ITEM_I-KPEIN )  ).
      ELSE.
        PFV_KBETR = PFV_KBETR + ( PF_ITEM_I-DWEMN * PF_ITEM_I-UNITP ).
      ENDIF.
*030220<--I
    ENDLOOP.
    WRITE PFV_KBETR CURRENCY PF_ITEM_TMP-WAERK TO PF_MATNR-AMONT.
**取得DIE數
    PERFORM GET_GROSS_DIE_COUNT_PSC1 USING     PF_ITEM_TMP
                                               PFWA_HEAD_I
                                     CHANGING  PF_MATNR-GDPWO.
*<-I190905
    PERFORM GET_GROSS_DIE_COUNT_MAX1 TABLES    PF_DIES_I
                                     USING     PF_ITEM_TMP
                                               PFWA_HEAD_I
                                     CHANGING  PF_MATNR-GDPWO.
*->I190905

*Pordtype = 'D', 要判斷是否為主要好品part no  101919 修正
    IF PFWA_HEAD_I-PRODTYPE = 'D'.                          "M101419
      IF PFWA_HEAD_I-ZTYPE = 'P' OR PFWA_HEAD_I-ZTYPE = 'F'."I101419
        PERFORM GET_WORKAREA_ZMWH8H USING PFW_ZMWH8H
                                          PF_ITEM_I-VBELN
                                          PF_ITEM_I-MATNR
                                          PF_ITEM_I-CHARG.

        IF PFW_ZMWH8H-FGFLAG <> 'X'.
          CLEAR PF_MATNR-GDPWO.                             "I082619
        ENDIF.
      ELSEIF PF_ITEM_TMP-DWEMN = 0.
        CLEAR PF_MATNR-GDPWO.                               "I082619
      ENDIF.                                                "I101419
    ENDIF.                                                  "I082619

*<-D190905  經8" SA確認不用再給DIE的單價
***取得一個DIE的單價
*    IF PFWA_HEAD_I-ZTYPE = 'I' OR
*       PFWA_HEAD_I-ZTYPE = 'F'.
*      CLEAR: ZSDA02.
*      SELECT SINGLE * FROM  ZSDA02
*                      WHERE KDMAT =   PF_ITEM_TMP-MATNR+01(05)
*                      AND   KUNNR =   PF_ITEM_TMP-KUNAG
*                      AND   ZBILL <>  ''.
*      IF ZSDA02-NETPR IS NOT INITIAL.
*        PF_MATNR-DUPCE = ZSDA02-NETPR / ZSDA02-KPEIN.
*      ENDIF.
*    ENDIF.
*->D190905
    APPEND PF_MATNR.
    CLEAR: PF_MATNR.
  ENDLOOP.

  LOOP AT PF_MATNR WHERE GDPWO <> 0.                      "如果Die數沒有值就不去loop這筆
    IF PFWA_HEAD_I-PRODTYPE = 'P' OR          "I190618      "顆粒(Package)不列印此remark
       PFWA_HEAD_I-PRODTYPE = 'S'.                          "I101519
      CONTINUE.                                             "I190618
    ENDIF.                                                  "I190618
    CLEAR: PFV_WDIES, PFV_REMAK.
    WRITE PF_MATNR-GDPWO TO PFV_WDIES.
    CONCATENATE PF_MATNR-KDMAT ': 1 Wafer =' PFV_WDIES 'Dies'
      INTO PFV_REMAK+2 SEPARATED BY SPACE.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD_I-VBELN
                                        PFWA_HEAD_I-ZTYPE
                                        'WAFDIE'.           "M101320
  ENDLOOP.
*<-D190905  經8" SA確認不用再給DIE的單價
*  LOOP AT PF_MATNR WHERE GDPWO <> 0                       "如果Die數沒有值就不去loop這筆
*                   AND   DUPCE <> 0.                      "如果沒有單價就不去loop這筆
*    CLEAR: PFV_WDIES, PFV_REMAK.
*    PF_MATNR-GDPWO = PF_MATNR-GDPWO * PF_MATNR-FKIMG.
*    WRITE PF_MATNR-GDPWO TO PFV_WDIES.
*    CONCATENATE PF_MATNR-KDMAT ':'
*                'QUANTITY ='   PFV_WDIES 'Dies /'
*                'UNIT PRICE =' PF_MATNR-DUPCE '/'
*                'AMOUNT ='     PF_MATNR-AMONT
*      INTO PFV_REMAK+2 SEPARATED BY SPACE.
*
*    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
*                                USING   PFV_REMAK
*                                        PFWA_HEAD_I-VBELN
*                                        PFWA_HEAD_I-ZTYPE
*                                        ''.
*  ENDLOOP.
*->D190905
ENDFORM.                    " GET_GROSS_DIE_INFO
*&---------------------------------------------------------------------*
*&      Form  ALV_DEFINE_HEADER_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_DEFINE_HEADER_LINE USING PFV_BUTON.
  CLEAR: I_FIELDCAT_LVC, I_FIELDCAT_LVC[].
  CHECK PFV_BUTON = 'BUT'.
  PERFORM ALV_DEFINE_HEADER_TEXT USING:
        "欄位名稱 表頭      參考欄位Q 參考欄位C 編輯  不顯示 KEY   EDIT MASK REF_TABLE REF_FIELD CHECKBOX
        'KUNNR'   TEXT-HD1  ''        ''        'X'   ''     'X'   '==ALPHA' ''        ''        '',       "KUNNR(Sold-to)
        'KDMAT'   TEXT-HD2  ''        ''        'X'   ''     'X'   ''        ''        ''        '',       "KDMAT(CHIPBODY)
        'GDPWO'   TEXT-HD3  ''        ''        'X'   ''     ''    ''        ''        ''        '',       "GDPWO(Dies)
        "'DUPCE'   TEXT-HD6  ''        ''        'X'   ''     ''    ''        ''        ''        '',       "DUPCE(Dies Unit Price) D190905
        'ZPACK'   TEXT-HD8  ''        ''        'X'   ''     ''    ''        ''        ''        'X',      "ZPACK(Packing Using)
        'ZBILL'   TEXT-HD4  ''        ''        'X'   ''     ''    ''        ''        ''        'X',      "ZBILL(Billing Using)
        'ZLABL'   TEXT-HD5  ''        ''        'X'   ''     ''    ''        ''        ''        'X'.      "ZLABL(Label Using)

ENDFORM.                    " ALV_DEFINE_HEADER_LINE
*&---------------------------------------------------------------------*
*&      Form  ALV_DEFINE_HEADER_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TEXT_CL1  text
*      -->P_TEXT_HD1  text
*      -->P_1968   text
*      -->P_1969   text
*      -->P_1970   text
*      -->P_1971   text
*      -->P_TEXT_TPX  text
*      -->P_TEXT_CV1  text
*      -->P_TEXT_RT1  text
*      -->P_TEXT_CLZ  text
*      -->P_1976   text
*----------------------------------------------------------------------*
FORM ALV_DEFINE_HEADER_TEXT  USING    PFV_FNAME    "欄位名稱*
                                      PFV_TITLE    "表頭*
                                      PFV_QFNAM    "參考欄位(UNIT)*
                                      PFV_CFNAM    "資料型態 / 參考欄位(CURRENCY)
                                      PFV_ZEDIT    "編輯*
                                      PFV_NOSOW    "不顯示*
                                      PFV_ZKEYS    "KEY*
                                      PFV_EMASK    "EDIT MASK*
                                      PFV_RTABL    "REF_TABLE*
                                      PFV_RFILD    "REF_FILED*
                                      PFV_CHKBX.   "CHECK BOX*
  DATA: WA_FIELDCAT_LVC TYPE  LVC_S_FCAT.

  CLEAR: WA_FIELDCAT_LVC.

  WA_FIELDCAT_LVC-FIELDNAME     = PFV_FNAME.         "欄位名
  WA_FIELDCAT_LVC-SCRTEXT_L     = PFV_TITLE.         "顯示的表頭
  WA_FIELDCAT_LVC-KEY           = PFV_ZKEYS.         "KEY
  WA_FIELDCAT_LVC-EDIT_MASK     = PFV_EMASK.         "EDIT MASK
  WA_FIELDCAT_LVC-REF_TABLE     = PFV_RTABL.         "REF_TABLE
  WA_FIELDCAT_LVC-REF_FIELD     = PFV_RFILD.         "REF_FILED
  WA_FIELDCAT_LVC-QFIELDNAME    = PFV_QFNAM.         "參考欄位(UNIT)
  WA_FIELDCAT_LVC-CHECKBOX      = PFV_CHKBX.
  WA_FIELDCAT_LVC-EDIT          = PFV_ZEDIT.         "編輯
  WA_FIELDCAT_LVC-NO_OUT        = PFV_NOSOW.
  WA_FIELDCAT_LVC-CFIELDNAME    = PFV_CFNAM.

  WA_FIELDCAT_LVC-COLDDICTXT    = 'L'.                                                            "表頭顯示SELTEXT_L的值,而不是顯示REF.的值




  APPEND WA_FIELDCAT_LVC TO I_FIELDCAT_LVC.

ENDFORM.                    " DEFINE_HEADER_TEXT
*&---------------------------------------------------------------------*
*&      Form  ALV_PRINT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_PRINT USING PFV_BUTON.
  DATA: PFWA_GLAY  TYPE LVC_S_GLAY.
**這個決定修改ALV的欄位資料是否寫入TEXT-S01中,未給TEXT-S01會回到原值
  PFWA_GLAY-EDT_CLL_CB = 'X'.
  CHECK  PFV_BUTON = 'BUT'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      I_CALLBACK_PROGRAM       = SY-REPID
      I_CALLBACK_PF_STATUS_SET = 'ALV_PF_STATUS'
      I_CALLBACK_USER_COMMAND  = 'ALV_USER_COMMAND'
      I_GRID_SETTINGS          = PFWA_GLAY
      IS_LAYOUT_LVC            = WA_LAYOUT_LVC
      I_SAVE                   = 'X'                                                     "顯示LAYOUT可以被儲存
      IT_FIELDCAT_LVC          = I_FIELDCAT_LVC[]
    TABLES
      T_OUTTAB                 = I_ZSDA02.


ENDFORM.                    " ALV_PRINT
*&---------------------------------------------------------------------*
*&      Form  ALV_DEFINE_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_DEFINE_LAYOUT .
  CLEAR: WA_LAYOUT_LVC.

  WA_LAYOUT_LVC-CWIDTH_OPT          = 'X'.                                                        "自動調整寬度
  WA_LAYOUT_LVC-BOX_FNAME           = 'SELEC'.
  WA_LAYOUT_LVC-STYLEFNAME          = 'STYLE'.
*  WA_LAYOUT_LVC-CTAB_FNAME          = TEXT-C99.                                                  "TEXT-C99 = 'COLOR'
ENDFORM.                    " ALV_DEFINE_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  ALV_USER_COMMAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->OK_CODE      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM ALV_USER_COMMAND USING OK_CODE     TYPE SY-UCOMM
                            RS_SELFIELD TYPE SLIS_SELFIELD.
  DATA: PFV_COTUM TYPE C.                               "判斷程式是否繼續

  CASE OK_CODE.
    WHEN 'CRET'.
      IF SY-PFKEY = 'ALV001'.
        INSERT INITIAL LINE INTO I_ZSDA02 INDEX 1.
      ENDIF.
    WHEN 'DELE'.
      PERFORM ALV_CHECK_SELECTION   USING    SY-PFKEY
                                    CHANGING PFV_COTUM.
      CHECK PFV_COTUM IS NOT INITIAL.
      PERFORM DELETE_DATA_FOR_SELECTION USING SY-PFKEY.
    WHEN 'SAVE'.
      PERFORM CHECK_RULE_COLUMN USING    SY-PFKEY
                                CHANGING PFV_COTUM.
      CHECK PFV_COTUM IS INITIAL.
      PERFORM SAVE_DATA USING SY-PFKEY.
      PERFORM ALV_FIELD_STYLE_DEFINE USING SY-PFKEY.
*<-I190905 (針對客戶指定的DIE數要送到外部SERVER)
    WHEN OTHERS.
  ENDCASE.

  RS_SELFIELD-REFRESH = 'X'.                                                                      "做動作後才會REFRESH

ENDFORM.                                 "USER_COMMAND
*----------------------------------------------------------------------*
*                      FORM ALV_PF_STATUS                              *
*----------------------------------------------------------------------*
FORM ALV_PF_STATUS USING RT_EXTAB   TYPE  SLIS_T_EXTAB.

  DATA: PFWA_EXTAB LIKE LINE OF RT_EXTAB.
  IF SY-UCOMM = 'BUT'.
    SET PF-STATUS 'ALV001' EXCLUDING RT_EXTAB.
  ENDIF.
  IF SY-UCOMM = 'USC'.
    SET PF-STATUS 'ALV002' EXCLUDING RT_EXTAB.
  ENDIF.

ENDFORM.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  ALV_CHECK_SELECTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PFV_COTUM  text
*----------------------------------------------------------------------*
FORM ALV_CHECK_SELECTION  USING    PFV_PFKEY
                          CHANGING PFV_GOING.
  FIELD-SYMBOLS: <VALUE>.
  DATA: PFV_FNAME(30) TYPE C,
        PFV_CHECK     TYPE C.

  CLEAR: PFV_CHECK, PFV_GOING.

  IF PFV_PFKEY = 'ALV001'.
    LOOP AT I_ZSDA02 WHERE SELEC IS NOT INITIAL.
      PFV_CHECK = 'X'.
      EXIT.
    ENDLOOP.
  ENDIF.

  IF PFV_CHECK IS INITIAL.
    MESSAGE W000 WITH TEXT-E28.                                                                   "TEXT-E28 = '請先選擇至少一筆資料!!'
  ELSE.
    PFV_GOING = 'X'.
  ENDIF.
ENDFORM.                    " ALV_CHECK_SELECTION
*&---------------------------------------------------------------------*
*&      Form  DELETE_DATA_FOR_SELECTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DELETE_DATA_FOR_SELECTION USING PFV_PFKEY.

  DATA: PFV_QUEST     TYPE STRING,
        PFV_ANSWR     TYPE C,
        PF_ZSDA02_D   LIKE ZSDA02   OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_ZSDA02_D, PF_ZSDA02_D[].
  CHECK PFV_PFKEY = 'ALV001'.
  LOOP AT I_ZSDA02 WHERE SELEC IS NOT INITIAL.
    CONCATENATE '是否確認要刪除這筆資料(' I_ZSDA02-KDMAT ')'                                                 "TEXT-Q04 = '是否確認要刪除這筆資料'
      INTO PFV_QUEST.
    PERFORM ASK_QUESTION USING      PFV_QUEST
                                    ''
                                    'DELE'
                         CHANGING   PFV_ANSWR.
    CHECK PFV_ANSWR = 1.
    MOVE-CORRESPONDING I_ZSDA02 TO PF_ZSDA02_D.
    DELETE I_ZSDA02.
    APPEND PF_ZSDA02_D.
  ENDLOOP.

  CHECK PF_ZSDA02_D[] IS NOT INITIAL.
  DELETE ZSDA02 FROM TABLE PF_ZSDA02_D.
*<-I190909
**外部系統的刪除只要留有chipbody的部份
  DELETE PF_ZSDA02_D WHERE KDMAT IS INITIAL.
  CHECK PF_ZSDA02_D[] IS NOT INITIAL.
  SORT PF_ZSDA02_D BY KDMAT.
  DELETE ADJACENT DUPLICATES FROM PF_ZSDA02_D COMPARING KDMAT.

  PERFORM UPDATE_SERVER_EDW8A TABLES PF_ZSDA02_D
                              USING  'D'.                 "D = DELETE
*->I190909
ENDFORM.                    " DELETE_DATA_FOR_SELECTION
*&---------------------------------------------------------------------*
*&      Form  CHECK_RULE_COLUMN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PFV_COTUM  text
*----------------------------------------------------------------------*
FORM CHECK_RULE_COLUMN  USING    PFV_PFKEY
                        CHANGING PFV_NOACT.
  DATA: PFV_CHECK     TYPE C.
  CLEAR: PFV_CHECK, PFV_NOACT.
  CHECK PFV_PFKEY = 'ALV001'.
  LOOP AT I_ZSDA02.
    CHECK I_ZSDA02-KUNNR IS INITIAL.                        "i190905
*    CHECK I_ZSDA02-KUNNR IS INITIAL OR       "D190905
*          I_ZSDA02-KDMAT IS INITIAL.         "D190905
*    PFV_CHECK = 'X'.
    PFV_NOACT = 'X'.
    EXIT.
  ENDLOOP.

*  CHECK PFV_CHECK IS NOT INITIAL.
  CHECK PFV_NOACT IS NOT INITIAL.
**只要有錯就不要做下去
*  PFV_NOACT = 'X'.
*  CHECK PFV_PFKEY = 'ALV001'.
  MESSAGE I000 WITH '資料未填寫完整,請檢查SOLD-TO是否有填寫!!'.
ENDFORM.                    " CHECK_RULE_COLUMN
*&---------------------------------------------------------------------*
*&      Form  ALV_FIELD_STYLE_DEFINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ALV_FIELD_STYLE_DEFINE USING PFV_BUTON.
  FIELD-SYMBOLS: <PF_STYLE>  TYPE LVC_T_STYL.
  DATA: PFWA_SSTYL    TYPE LVC_S_STYL,
        PFWA_TSTYL    TYPE LVC_T_STYL.

  CLEAR: PFWA_SSTYL, PFWA_TSTYL.
  IF PFV_BUTON = 'BUT' OR
     PFV_BUTON = 'ALV001'.
    PFWA_SSTYL-FIELDNAME = 'KUNNR'.
    PFWA_SSTYL-STYLE     = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
    INSERT PFWA_SSTYL INTO TABLE PFWA_TSTYL.
    PFWA_SSTYL-FIELDNAME = 'KDMAT'.
    PFWA_SSTYL-STYLE     = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
    INSERT PFWA_SSTYL INTO TABLE PFWA_TSTYL.

    LOOP AT I_ZSDA02 WHERE KUNNR IS NOT INITIAL AND
                           KDMAT IS NOT INITIAL AND
                           STYLE IS INITIAL.
      ASSIGN COMPONENT 'STYLE'
          OF STRUCTURE I_ZSDA02 TO <PF_STYLE>.
      <PF_STYLE> = PFWA_TSTYL.
      MODIFY I_ZSDA02.
      CLEAR: I_ZSDA02.
    ENDLOOP.
    PFWA_SSTYL-FIELDNAME = 'GDPWO'.
    PFWA_SSTYL-STYLE     = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
    INSERT PFWA_SSTYL INTO TABLE PFWA_TSTYL.
    LOOP AT I_ZSDA02 WHERE KUNNR IS NOT INITIAL AND
                           KDMAT IS INITIAL AND
                           STYLE IS INITIAL.
      ASSIGN COMPONENT 'STYLE'
          OF STRUCTURE I_ZSDA02 TO <PF_STYLE>.
      <PF_STYLE> = PFWA_TSTYL.
      MODIFY I_ZSDA02.
      CLEAR: I_ZSDA02.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " ALV_FIELD_STYLE_DEFINE
*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_DATA USING PFV_PFKEY.
  DATA: PF_ZSDA02 LIKE ZSDA02   OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_ZSDA02, PF_ZSDA02[].
  CHECK PFV_PFKEY = 'ALV001'.
  LOOP AT I_ZSDA02.
    MOVE-CORRESPONDING I_ZSDA02 TO PF_ZSDA02.
*<-I160111
    PERFORM CAL_KPEIN_VALUE USING    I_ZSDA02-DUPCE
                                     I_ZSDA02-WAERK
                            CHANGING PF_ZSDA02-NETPR
                                     PF_ZSDA02-KPEIN.
    PF_ZSDA02-WAERK = 'USD'.
*->I160111

    APPEND PF_ZSDA02.
    CLEAR: PF_ZSDA02.
  ENDLOOP.
  MODIFY ZSDA02 FROM TABLE PF_ZSDA02.
*<-I190909
**外部系統的刪除只要留有chipbody的部份
  DELETE PF_ZSDA02 WHERE KDMAT IS INITIAL.
  CHECK PF_ZSDA02[] IS NOT INITIAL.
  SORT PF_ZSDA02 BY KDMAT.
  DELETE ADJACENT DUPLICATES FROM PF_ZSDA02 COMPARING KDMAT.
  PERFORM UPDATE_SERVER_EDW8A TABLES PF_ZSDA02
                              USING  'U'.                 "U = UPDATE
*->I190909
ENDFORM.                    " SAVE_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_LOT_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_CUST_LOT_LIST TABLES PF_HEAD_I STRUCTURE I_HEAD
                              PF_COLT_O STRUCTURE I_ZCLOT.

  DATA: BEGIN OF PF_SOLTO OCCURS 0,
          KUNAG TYPE KUNAG,
        END OF PF_SOLTO.
  DATA: PF_ZCLOT    LIKE ZCUST_LOTID  OCCURS 0 WITH HEADER LINE,
        PFV_DBCON   TYPE DBCON_NAME,
        PFV_DESTN   TYPE RFCEXEC.

  CLEAR: PF_COLT_O, PF_COLT_O[], PF_SOLTO, PF_SOLTO[], PFV_DBCON, PFV_DESTN.

  LOOP AT PF_HEAD_I.
    PF_SOLTO-KUNAG = PF_HEAD_I-KUNAG.
    APPEND PF_SOLTO.
    CLEAR: PF_SOLTO.
  ENDLOOP.

  CHECK PF_SOLTO[] IS NOT INITIAL.
  SORT PF_SOLTO.
  DELETE ADJACENT DUPLICATES FROM PF_SOLTO.

  CHECK SY-SYSID <> 'DEV'.
  CHECK P_VKORG = 'MAX1'.                                   "I051121

**取得連線資訊
  PERFORM GET_CONNECTION_INFO USING     'A'
                              CHANGING  PFV_DESTN.        "RASAPAP2_WIN
**取得連結DB
  PERFORM GET_CONNECTION_INFO USING     'B'
                              CHANGING  PFV_DBCON.        "MSS_RAPCPS01
**測試WIN AP連線
  CALL FUNCTION 'RFC_PING' DESTINATION PFV_DESTN.
  CHECK SY-SUBRC = 0.

  LOOP AT PF_SOLTO.
    CLEAR: PF_ZCLOT, PF_ZCLOT[].
    CALL FUNCTION 'ZPCP_RFC_GET_CUST_LOTID'
      DESTINATION PFV_DESTN
      EXPORTING
        I_DBCON = PFV_DBCON
        I_KUNAG = PF_SOLTO-KUNAG
      TABLES
        T_CLOT  = PF_ZCLOT.

    CHECK PF_ZCLOT[] IS NOT INITIAL.

    APPEND LINES OF PF_ZCLOT[] TO PF_COLT_O.
  ENDLOOP.
  SORT PF_COLT_O BY KUNAG CHARG.
  DELETE ADJACENT DUPLICATES FROM PF_COLT_O COMPARING KUNAG CHARG.

ENDFORM.                    " GET_CUST_LOT_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_LOT_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_KUNAG  text
*      -->P_I_LIPS_CHARG  text
*      <--P_I_ITEM_LOTNO  text
*----------------------------------------------------------------------*
FORM GET_CUST_LOT_NO  TABLES   PF_ZCLOT_I   STRUCTURE I_ZCLOT
                      USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                               PFWA_LIPS_I  STRUCTURE LIPS
                      CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.


  DATA: PF_LINES          LIKE TLINE OCCURS 0 WITH HEADER LINE,
        PFWA_RET2         LIKE BAPIRET2,
        PFV_BSTKD_TMP(35) TYPE C,
        PFV_LOTNO_TMP(50) TYPE C,
        PFV_TDNAME2(32)   TYPE C.

  CLEAR: PFWA_ITEM_IO-LOTNO.

  CASE PFWA_HEAD_I-VKORG.
    WHEN 'MAX1'.
      CALL FUNCTION 'ZSD_GET_CUST_LOTID'
        EXPORTING
          I_KUNAG  = PFWA_HEAD_I-KUNAG
          I_KUNNR  = PFWA_HEAD_I-KUNNR
          I_CHARG  = PFWA_LIPS_I-CHARG
          I_WERKS  = PFWA_LIPS_I-WERKS
        IMPORTING
          E_LOTNO  = PFV_LOTNO_TMP
          E_CHARG  = PFWA_ITEM_IO-CHARG
          E_BSTKD  = PFV_BSTKD_TMP           "<=目前FM裡面沒有處理這個
          E_RETURN = PFWA_RET2
        TABLES
          T_ZCLOT  = PF_ZCLOT_I.

      IF PFWA_RET2-TYPE = 'E'.
        MESSAGE E999 WITH PFWA_RET2-MESSAGE.
      ENDIF.
      PFWA_ITEM_IO-LOTNO = PFV_LOTNO_TMP.
      CHECK PFV_BSTKD_TMP IS NOT INITIAL.
      CLEAR: PFWA_ITEM_IO-BSTKD.
      PFWA_ITEM_IO-BSTKD = PFV_BSTKD_TMP.

    WHEN 'PSC1'.
      PFV_TDNAME2        = PFWA_LIPS_I-MATNR.
      PFV_TDNAME2+18(4)  = PFWA_LIPS_I-WERKS.
      PFV_TDNAME2+22(10) = PFWA_LIPS_I-CHARG.
*- 要在QAS TESTING
      PERFORM GET_LONG_TEXT TABLES PF_LINES
                            USING  PFV_TDNAME2
                                   'VERM'
                                   'CHARGE'.
      READ TABLE PF_LINES INDEX 1.
      IF PF_LINES-TDLINE+15(15) <> ''.
        MOVE PF_LINES-TDLINE+15(15) TO PFWA_ITEM_IO-LOTNO.
      ENDIF.
*  PERFORM READ_TEXT(ZSD0062) TABLES TLINES
*                             USING 'VERM'
*                                   WA_TDNAME2
*                                   'CHARGE'
*                                   WA_SUBRC.
*  IF WA_SUBRC = 0.
*    READ TABLE TLINES INDEX 1.
*    MOVE TLINES-TDLINE+15(15) TO PFWA_ITEM_IO-LOTNO.
*  ENDIF.
      PERFORM SP_RULE_FOR_CUST_LOTNO USING    PFWA_HEAD_I
                                              PFWA_LIPS_I
                                    CHANGING  PFWA_ITEM_IO.
  ENDCASE.
ENDFORM.                    " GET_CUST_LOT_NO
*&---------------------------------------------------------------------*
*&      Form  GET_WAFER_ID_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_LIPS_CHARG  text
*      -->P_P_LIPS_MATNR  text
*      <--P_I_WAFER_WAFER  text
*----------------------------------------------------------------------*
FORM GET_WAFER_ID_LIST  USING    PFV_CHARG
                                 PFV_MATNR
                        CHANGING PFV_WAFER.
  DATA: PFV_VALUE TYPE STRING.

  CALL FUNCTION 'ZINF_GET_WAFER_ID'
    EXPORTING
      I_CHARG       = PFV_CHARG
      I_MATNR       = PFV_MATNR
*     I_LOSTW       =
    IMPORTING
      E_WAFER       = PFV_VALUE.
  PFV_WAFER = PFV_VALUE.
ENDFORM.                    " GET_WAFER_ID_LIST
*&---------------------------------------------------------------------*
*&      Form  CONVERSION_EXIT_ALPHA_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PF_VEKP_EXIDV  text
*----------------------------------------------------------------------*
FORM CONVERSION_EXIT_ALPHA_OUTPUT  CHANGING PFV_VALUE.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      INPUT  = PFV_VALUE
    IMPORTING
      OUTPUT = PFV_VALUE.
ENDFORM.                    " CONVERSION_EXIT_ALPHA_OUTPUT
*&---------------------------------------------------------------------*
*&      Form  GET_DENOMINATOR_TTL_UNIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VEKP_EXIDV  text
*      <--P_PFV_EXIDV  text
*----------------------------------------------------------------------*
FORM GET_DENOMINATOR_TTL_UNIT  USING    PFV_EXIDV_I
                               CHANGING PFV_EXIDV_O.
  DATA: PFN_EXIDV TYPE I.

  CLEAR: PFV_EXIDV_O, PFN_EXIDV.
  PFN_EXIDV = STRLEN( PFV_EXIDV_I ).
****如果VEKP-EXIDV中的值超過3位數,就只取3位使用,如果沒有就保留原值
  IF PFN_EXIDV > 3.
    PFN_EXIDV   = PFN_EXIDV - 3.
    PFV_EXIDV_O = PFV_EXIDV_I+PFN_EXIDV(03).
  ELSE.
    PFV_EXIDV_O = PFV_EXIDV_I.
  ENDIF.
  PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PFV_EXIDV_O.
ENDFORM.                    " GET_DENOMINATOR_TTL_UNIT
*&---------------------------------------------------------------------*
*&      Form  GET_HIGH_LEVEL_HANDING_UNIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VEKP  text
*----------------------------------------------------------------------*
FORM GET_HIGH_LEVEL_HANDING_UNIT  TABLES  PF_VEKP_ALL STRUCTURE VEKP
                                          PF_VEKP_IO  STRUCTURE VEKP
                                  USING   PFV_PTYPE_I.

  DATA: PF_VEKP_B LIKE VEKP OCCURS 0 WITH HEADER LINE.

  CHECK PFV_PTYPE_I = 'PALLET'.
*先備份
  CLEAR: PF_VEKP_B, PF_VEKP_B[].
  APPEND LINES OF PF_VEKP_IO TO PF_VEKP_B.
  CLEAR: PF_VEKP_IO, PF_VEKP_IO[].
*清進來的TABLE
  SORT PF_VEKP_B BY UEVEL.
  DELETE ADJACENT DUPLICATES FROM PF_VEKP_B COMPARING UEVEL.
  LOOP AT PF_VEKP_B.
    LOOP AT PF_VEKP_ALL WHERE VENUM = PF_VEKP_B-UEVEL.
      MOVE-CORRESPONDING PF_VEKP_ALL TO PF_VEKP_IO.
      APPEND PF_VEKP_IO.
      CLEAR: PF_VEKP_IO.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " GET_HIGH_LEVEL_HANDING_UNIT
*&---------------------------------------------------------------------*
*&      Form  GET_DIM_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VEKP  text
*      <--P_PFV_DIMES_O  text
*----------------------------------------------------------------------*
FORM GET_DIM_INFO  USING    PFWA_VEKP STRUCTURE VEKP
                   CHANGING PFV_ZDIMS.

  DATA: PFN_LAENG     TYPE I,
        PFN_BREIT     TYPE I,
        PFN_HOEHE     TYPE I,
        PFV_LAENG     TYPE STRING,
        PFV_BREIT     TYPE STRING,
        PFV_HOEHE     TYPE STRING.

  CLEAR: PFV_ZDIMS, PFN_LAENG, PFN_BREIT, PFN_HOEHE.
  "長寬高都沒有值從MARA抓
  IF PFWA_VEKP-LAENG IS INITIAL AND
     PFWA_VEKP-BREIT IS INITIAL AND
     PFWA_VEKP-HOEHE IS INITIAL.
    CLEAR: MARA.
    SELECT SINGLE * FROM  MARA
                    WHERE MATNR = PFWA_VEKP-VHILM.
    CHECK SY-SUBRC = 0.
    IF MARA-GROES+0(1) = 'x' OR
       MARA-GROES+0(1) = 'X'.
      MESSAGE E700 WITH TEXT-E05.                                                                 "TEXT-E05 = 'Format of dimension is not correct.'
    ELSE.
      PFV_ZDIMS = MARA-GROES.
    ENDIF.
  ELSE.
    PFN_LAENG = PFWA_VEKP-LAENG.                                                                  "Length
    PFN_BREIT = PFWA_VEKP-BREIT.                                                                  "Breadth
    PFN_HOEHE = PFWA_VEKP-HOEHE.                                                                  "Height
    PFV_LAENG = PFN_LAENG.
    PFV_BREIT = PFN_BREIT.
    PFV_HOEHE = PFN_HOEHE.
    CONCATENATE PFV_LAENG 'X' PFV_BREIT 'X' PFV_HOEHE INTO PFV_ZDIMS
        SEPARATED BY SPACE.
  ENDIF.
ENDFORM.                    " GET_DIM_INFO
*&---------------------------------------------------------------------*
*&      Form  SPCEIAL_RULE_FOR_ITEM_IMEX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*----------------------------------------------------------------------*
FORM IMEX_GET_FUNDRY_SERVICE_PRICE  TABLES  PF_ITEM   STRUCTURE I_ITEM
                                    USING   PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PF_LIPS       LIKE LIPS OCCURS 0 WITH HEADER LINE,
        PFV_WAERS     TYPE WAERS,
        PFV_DMBTR     TYPE DMBTR,
        PFV_COSIG(01) TYPE C,
        PFV_OUNTP     TYPE NETPR,        "記錄原始金額用
        PFV_ONETW     TYPE NETWR,        "記錄原始總價
        PFV_OKPEI     TYPE KPEIN,        "Condition pricing unit
        PFV_UPRIC     LIKE ZMSBMM-DMBTR,
        PFV_CHARG     TYPE CHARG_D,
        PFV_USING(01) TYPE C.
  DATA: BEGIN OF PF_CHUP OCCURS 0,
          CHARG TYPE CHARG_D,
          DMBTR TYPE DMBTR,
        END OF PF_CHUP.
  CHECK PFWA_HEAD-ZTYPE = 'I' OR                "I = Invoic
        PFWA_HEAD-ZTYPE = 'F'.                  "F = Free Invoice
  LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
                  AND   ZTYPE = PFWA_HEAD-ZTYPE.
    PERFORM IMEX_CHECK_OTHER_PRICE_RULE USING     PF_ITEM
                                                  'RAW_WAFER'
                                        CHANGING  PFV_USING.        "空值表示使用BILLING 金額
    CHECK PFV_USING IS NOT INITIAL.

    PERFORM GET_DN_ITEM TABLES  PF_LIPS
                        USING   PF_ITEM.

    CHECK PF_LIPS[] IS NOT INITIAL.
    CLEAR: PF_CHUP, PF_CHUP[].
    LOOP AT PF_LIPS.
      CALL FUNCTION 'Z_MSB_GET_WAFER_PRICE'
        EXPORTING
          LOC_KUNNR   = PFWA_HEAD-KUNAG
          LOC_MATNR   = PF_LIPS-MATNR
          LOC_CHARG   = PF_LIPS-CHARG
          LOC_FKDAT   = PFWA_HEAD-SIDAT
        IMPORTING
          LOC_CONSIGN = PFV_COSIG
          LOC_WAERS   = PFV_WAERS
          LOC_DMBTR   = PFV_DMBTR.
      CHECK PFV_COSIG IS NOT INITIAL.
      PF_CHUP-CHARG = PF_LIPS-CHARG.
      PF_CHUP-DMBTR = PFV_DMBTR.
      APPEND PF_CHUP.
    ENDLOOP.
    PFV_OUNTP = PF_ITEM-UNITP.        "保留原單價
    PFV_ONETW = PF_ITEM-KWERT.        "保留原總價
    PFV_OKPEI = PF_ITEM-KPEIN.        "保留原Condition pricing unit    "I201201
    SORT PF_CHUP BY DMBTR DESCENDING.
    READ TABLE PF_CHUP INDEX 1.

    CLEAR: PF_ITEM-SCUTP, PF_ITEM-UNITP, PF_ITEM-KWERT, PF_ITEM-SCKWE.
    PF_ITEM-UNITP = PF_CHUP-DMBTR.
    PF_ITEM-KPEIN = 1.                                      "I201201
    PF_ITEM-SCUTP = PFV_OUNTP.
    PF_ITEM-SKPEI = PFV_OKPEI.                              "I201201
    PF_ITEM-KWERT = PF_CHUP-DMBTR * PF_ITEM-DWEMN.
*    PF_ITEM-SCKWE = PFV_OUNTP * PF_ITEM-DWEMN.
    PF_ITEM-SCKWE = PFV_ONETW.
    PF_ITEM-CONSI = 'X'.
    MODIFY PF_ITEM.
    CLEAR  PF_ITEM.
  ENDLOOP.
ENDFORM.                    " SPCEIAL_RULE_FOR_ITEM_IMEX

*&---------------------------------------------------------------------*
*&      Form  GET_CUSTOMER_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_KUNAG  text
*      <--P_PFV_NAME1  text
*----------------------------------------------------------------------*
FORM IMEX_GET_CUSTOMER_NAME  USING    PFV_KUNAG
                                      PFV_RECOD
                             CHANGING PFV_NAME1.
*<-I170511
  CASE PFV_RECOD.
    WHEN 'V'.
      SELECT SINGLE * FROM  ZMSBMV
                      WHERE KUNNR = PFV_KUNAG.
      CHECK SY-SUBRC = 0.
      SELECT SINGLE NAME1 INTO PFV_NAME1  FROM  LFA1
                                          WHERE LIFNR = ZMSBMV-LIFNR.
    WHEN 'C'.
      SELECT SINGLE * FROM  KNA1
                      WHERE KUNNR = PFV_KUNAG.
      CHECK SY-SUBRC = 0.
      CONCATENATE KNA1-NAME1 KNA1-NAME2
        INTO PFV_NAME1.
    WHEN OTHERS.
  ENDCASE.
*->I170511
*<-D170511
*  CLEAR: KNA1, PFV_NAME1.
*  SELECT SINGLE * FROM  KNA1
*                  WHERE KUNNR = PFV_KUNAG.
*  CHECK SY-SUBRC = 0.
*
*  CASE PFV_RECOD.
*    WHEN '1'.
*      PFV_NAME1 = KNA1-NAME1.
*    WHEN '2'.
*      PFV_NAME1 = KNA1-NAME2.
*    WHEN OTHERS.
*  ENDCASE.
*->D170511
ENDFORM.                    " GET_CUSTOMER_NAME
*&---------------------------------------------------------------------*
*&      Form  GET_FLOW_DATA_VBFA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_FLOW_DATA_VBFA TABLES PF_VBRK_I STRUCTURE VBRK
                               PF_LIKP_I STRUCTURE LIKP
                               PF_VBFA_O STRUCTURE VBFA.

  DATA: PF_VBRP   LIKE VBRP OCCURS 0 WITH HEADER LINE,
        PFV_CANCL TYPE C.
***PERFORM = GET_SHIPDATE_INFO => VBTYP_N = 'M'
  CLEAR: PF_VBFA_O, PF_VBFA_O[], PF_VBRP, PF_VBRP[].
  IF PF_LIKP_I[] IS NOT INITIAL.                                                                  "若沒有值會全抓
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM    VBFA
                                                   FOR ALL ENTRIES IN  PF_LIKP_I
                                                   WHERE   VBELV   =   PF_LIKP_I-VBELN
                                                   AND     VBTYP_N IN  ('M', 'R', 'X').    "M = Invoice, R = Good Movement, X = Handling Unit
  ENDIF.


***PERFORM = CHECK_DATA => VBTYP_N = 'U' (SO有用到PI的都要抓出來)
***PERFORM = GET_ITEM_PIITEM_DATA => VBTYP_N = 'U' / 'M' (SO所對應的PI及Invoice都要抓出來)
  IF PF_VBRK_I[] IS NOT INITIAL.
    PERFORM GET_ITEM_DATA_VBRP TABLES PF_VBRK_I
                                      PF_VBRP
                               USING  ''.                   "I210217
*<-D210217
*    SELECT *
*      INTO CORRESPONDING FIELDS OF TABLE PF_VBRP FROM VBRP
*                                                 FOR ALL ENTRIES IN PF_VBRK_I
*                                                 WHERE     VBELN = PF_VBRK_I-VBELN.
*->D210217

    SELECT *
      APPENDING CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM    VBFA
                                                        FOR ALL ENTRIES IN  PF_VBRP
                                                        WHERE   VBELV   =   PF_VBRP-AUBEL
                                                        AND     VBTYP_N IN  ('U', 'M').      "U = Proforma, M = Invoice
***PERFORM = GET_HERDER_SH_INFO => VBTYP_N = 'M' (把由BILLING帶出的PACKING,所對應的INVOICE帶出來)
***PERFORM = GET_BACKLOG => VBTYP_N = 'R' (把DN對應的物料單號抓出)
    SELECT *
      APPENDING CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM    VBFA
                                                        FOR ALL ENTRIES IN  PF_VBRP
                                                        WHERE   VBELV   =   PF_VBRP-VGBEL
                                                        AND     VBTYP_N IN  ('M', 'R', 'X'). "M = Invoice, R = Good Movement, X = Handling Unit
  ENDIF.

  CHECK PF_VBFA_O[] IS NOT INITIAL.
  SORT PF_VBFA_O.
  DELETE ADJACENT DUPLICATES FROM PF_VBFA_O COMPARING ALL FIELDS.
***檢查PI是否有被Cancel
  LOOP AT PF_VBFA_O WHERE VBTYP_N = 'U'.
    PERFORM CHECK_PROFORMA_STATUS USING     PF_VBFA_O-VBELN
                                            'CANC'
                                  CHANGING  PFV_CANCL
                                            X_VARTS.
    CHECK PFV_CANCL IS NOT INITIAL.
    DELETE PF_VBFA_O.
  ENDLOOP.
***檢查Billing是否有被Cancel
  LOOP AT PF_VBFA_O WHERE VBTYP_N = 'M'.
    PERFORM CHECK_BILLING_CANCELED USING      PF_VBFA_O-VBELN
                                   CHANGING   PFV_CANCL.
    CHECK PFV_CANCL IS NOT INITIAL.
    DELETE PF_VBFA_O.
  ENDLOOP.
ENDFORM.                    " GET_FLOW_DATA_VBFA
*&---------------------------------------------------------------------*
*&      Form  TRANSFER_TO_DBMODE_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZSDA02_DUPCE  text
*      <--P_PF_ZSDA02_NETPR  text
*      <--P_PF_ZSDA02_KPEIN  text
*----------------------------------------------------------------------*
FORM CAL_KPEIN_VALUE  USING    PFV_UPRCE_I
                               PFV_WEARK_I
                      CHANGING PFV_NETWR_O
                               PFV_KPEIN_O.
  DATA: PFV_VALUE TYPE BAPIKBETR1,
        PFV_DECMS TYPE NUMC5,
        PFV_CUDEC TYPE TCURX-CURRDEC.           "取得幣別的小數位
  CLEAR: PFV_NETWR_O, PFV_KPEIN_O, PFV_VALUE.
  CHECK PFV_UPRCE_I IS NOT INITIAL.
  PFV_VALUE = PFV_UPRCE_I.

  CALL FUNCTION 'ZGET_AMT_DECIMALS'
    EXPORTING
      AMOUNT   = PFV_VALUE
    IMPORTING
      DECIMALS = PFV_DECMS.

  CALL FUNCTION 'G_DECIMAL_PLACES_GET'
    EXPORTING
      CURRENCY       = PFV_WEARK_I
    IMPORTING
      DECIMAL_PLACES = PFV_CUDEC.

*算出來的位數<=該幣別的小數位 ==> KPEIN = 1
  IF PFV_DECMS <= PFV_CUDEC.
    PFV_DECMS = 0.
  ELSE.
    PFV_DECMS = PFV_DECMS - PFV_CUDEC.
  ENDIF.
  PFV_KPEIN_O = 10 ** PFV_DECMS.                            "10的N次方
  PFV_NETWR_O = PFV_UPRCE_I * PFV_KPEIN_O.

*  IF PFV_DECMS = 0.
*    PFV_KPEIN = 1.
*  ELSE.
*    PFV_KPEIN = 10 ** PFV_DECMS.                            "10的N次方
*    PFV_NETWR = PFV_UPRCE * PFV_KPEIN.
*  ENDIF.


ENDFORM.                    " TRANSFER_TO_DBMODE_VALUE
**&---------------------------------------------------------------------*
**&      Form  GET_CORRECT_VALUE_TO_SHOW
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM GET_CORRECT_VALUE_TO_SHOW .
*  LOOP AT I_ZSDA02 WHERE NETPR IS NOT INITIAL.
*    I_ZSDA02-DUPCE = I_ZSDA02-NETPR / I_ZSDA02-KPEIN.
*    MODIFY I_ZSDA02.
*  ENDLOOP.
*ENDFORM.                    " GET_CORRECT_VALUE_TO_SHOW
*&---------------------------------------------------------------------*
*&      Form  GET_FLOW_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA  text
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_FLOW_DATA  TABLES   PF_VBFA_O STRUCTURE VBFA
                    USING    PFV_VBELN_I
                             PFV_ZTYPE_I.
  DATA: PFV_VTYPE TYPE C,
        PFV_CANCL TYPE C.                                                                         "判斷狀態使用

  CLEAR: PF_VBFA_O, PF_VBFA_O[].


  CASE PFV_ZTYPE_I.
    WHEN 'I'.                                                                                     "I = Invoice
      PFV_VTYPE = 'U'.                                                                            "Invoice要去找是否有PI
    WHEN 'R'.                                                                                     "Proforma Invoice
      PFV_VTYPE = 'M'.                                                                            "Proforma要去找是否有用掉的Invoice
    WHEN OTHERS.
  ENDCASE.

  LOOP AT I_ITEM WHERE VBELN = PFV_VBELN_I
                 AND   ZTYPE = PFV_ZTYPE_I.
    LOOP AT I_VBFA WHERE VBELV    = I_ITEM-AUBEL
*                   AND   POSNV    = I_ITEM-AUPOS
                   AND   VBTYP_N  = PFV_VTYPE.
      MOVE-CORRESPONDING I_VBFA TO PF_VBFA_O.
      APPEND PF_VBFA_O.
    ENDLOOP.
  ENDLOOP.



  IF PFV_ZTYPE_I = 'I'.                                                                           "I = Invoice
    SORT PF_VBFA_O.
    DELETE ADJACENT DUPLICATES FROM PF_VBFA_O COMPARING VBELV POSNV VBELN VBTYP_N.
  ENDIF.

  IF PFV_ZTYPE_I = 'R'.                                                                           "R = Proforma Invoice
***處理部份pi是後來有開過INVOICE後才開立的
    LOOP AT PF_VBFA_O.
      READ TABLE I_VBFA WITH KEY VBELV    = PF_VBFA_O-VBELV
                                 POSNV    = PF_VBFA_O-POSNV
                                 VBTYP_N  = 'U'.
      CHECK SY-SUBRC = 0.

      PERFORM CHECK_PROFORMA_BIILLING_ORDER USING     PF_VBFA_O-ERDAT                             "inv.產生日期
                                                      PF_VBFA_O-ERZET                             "inv.產生時間
                                                      I_VBFA-ERDAT                                "PI  產生日期
                                                      I_VBFA-ERZET                                "PI  產生時間
                                                      PFV_VBELN_I
                                            CHANGING  PFV_CANCL.
      CHECK PFV_CANCL IS NOT INITIAL.
      DELETE PF_VBFA_O.
    ENDLOOP.

    SORT PF_VBFA_O.
    DELETE ADJACENT DUPLICATES FROM PF_VBFA_O COMPARING VBELV POSNV VBELN POSNN VBTYP_N.
  ENDIF.


*  RANGES: PFR_AUBEL FOR VBRP-AUBEL.
*  DATA:   PFV_VTYPE TYPE C.
*
*
*  CLEAR: PF_VBFA_O, PF_VBFA_O[], PFR_AUBEL, PFR_AUBEL[], PFV_VTYPE.
*
*  PFR_AUBEL-SIGN    = TEXT-TPI.                                                                   "TEXT-TPI = 'I'
*  PFR_AUBEL-OPTION  = TEXT-OP1.                                                                   "TEXT-OP1 = 'EQ'
*  LOOP AT I_ITEM WHERE VBELN = PFV_VBELN_I
*                 AND   ZTYPE = PFV_ZTYPE_I.
*    PFR_AUBEL-LOW     = I_ITEM-AUBEL.
*    APPEND PFR_AUBEL.
*    CLEAR: PFR_AUBEL-LOW.
*  ENDLOOP.
*  SORT PFR_AUBEL BY LOW.
*  DELETE ADJACENT DUPLICATES FROM PFR_AUBEL COMPARING ALL FIELDS.
*  CASE PFV_ZTYPE_I.
*    WHEN TEXT-TPI.                                                                                "TEXT-TPI = 'I'    Invoice
*      PFV_VTYPE = TEXT-TPU.                                                                       "TEXT-TPU = 'U'
*    WHEN TEXT-TPR.                                                                                "TEXT-TPR = 'R'    Proforma Invoice
*      PFV_VTYPE = TEXT-TPM.                                                                       "TEXT-TPU = 'M'
*    WHEN OTHERS.
*  ENDCASE.
*  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM  VBFA
*                                                        WHERE VBELV     IN  PFR_AUBEL
*                                                        AND   VBTYP_N   =   PFV_VTYPE.
ENDFORM.                    " GET_FLOW_DATA
*&---------------------------------------------------------------------*
*&      Form  CHECK_PROFORMA_BIILLING_ORDER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA_ERDAT  text
*      <--P_PFV_CANCL  text
*----------------------------------------------------------------------*
FORM CHECK_PROFORMA_BIILLING_ORDER  USING    PFV_ERDAT_INV
                                             PFV_ERZET_INV
                                             PFV_ERDAT_PRO
                                             PFV_ERZET_PRO
                                             PFV_VBELN
                                    CHANGING PFV_DELET.
  CLEAR: PFV_DELET.

  IF PFV_ERDAT_INV < PFV_ERDAT_PRO.
    PFV_DELET = 'X'.
    EXIT.
  ENDIF.
  IF PFV_ERDAT_INV = PFV_ERDAT_PRO.
    CHECK PFV_ERZET_INV < PFV_ERZET_PRO.
    PFV_DELET = 'X'.
  ENDIF.
ENDFORM.                    " CHECK_PROFORMA_BIILLING_ORDER
*&---------------------------------------------------------------------*
*&      Form  CHECK_BILLING_CANCELED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA_VBELN  text
*      <--P_PFV_CANCL  text
*----------------------------------------------------------------------*
FORM CHECK_BILLING_CANCELED  USING    PFV_VBELN
                             CHANGING PFV_DELET.
  DATA: PFWA_VBRK LIKE VBRK.
  CLEAR: PFV_DELET.
  PERFORM GET_WORKAREA_VBRK USING     PFV_VBELN
                            CHANGING  PFWA_VBRK.
  CHECK PFWA_VBRK-FKSTO IS NOT INITIAL.
  PFV_DELET = 'X'.
ENDFORM.                    " CHECK_BILLING_CANCELED
*&---------------------------------------------------------------------*
*&      Form  GET_EACH_ITEM_AMOUT_TAX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFT_PIITEM  text
*      -->P_I_HEAD_VBELN  text
*      -->P_I_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
*FORM GET_EACH_ITEM_AMOUT_TAX  TABLES   PF_ITEM_O  STRUCTURE I_ITEM_PIITEM
*                                       PF_ITEM_I  STRUCTURE I_ITEM_PIITEM
*                              USING    PFV_VBELN
*                                       PFV_ZTYPE.
*
*  DATA: PF_VBFA       LIKE  VBFA          OCCURS 0 WITH HEADER LINE,
*        PFV_TABIX     TYPE  SYTABIX,
*        PFV_CANCL     TYPE  C,
*        PFV_NUMB1(10) TYPE  N,
*        PFV_NUMB2(10) TYPE  N,
*        PFV_KWERT     TYPE  KBETR,                                                                "PI ITEM金額加總
*        PFV_KBETR     TYPE  KBETR,                                                                "PI_TAX加總
*        PFV_WAERK     TYPE  WAERK.                                                                "PI CURRENCY
*
*  DATA: BEGIN OF PF_PIINFO OCCURS 0,
*          PERFI   TYPE VBELN,
*          AUBEL   TYPE VBELN,                                                                     "SO
*          PIAMT   TYPE KBETR,                                                                     "PI金額
*          PIBAL   TYPE KBETR,                                                                     "PI餘額
*          WAERK   TYPE WAERK,                                                                     "Currency
*        END OF PF_PIINFO.
*
*
*  CLEAR: PF_ITEM_O, PF_ITEM_O[], PF_PIINFO, PF_PIINFO[], PF_VBFA, PF_VBFA[].
*  CHECK PFV_ZTYPE = 'I'.                                                                          "I = Invoice
*
*
***收集這次的ITEM的LIST
*  LOOP AT PF_ITEM_I WHERE VBELN = PFV_VBELN
*                    AND   ZTYPE = PFV_ZTYPE.
*    MOVE-CORRESPONDING PF_ITEM_I TO PF_ITEM_O.
*    APPEND PF_ITEM_O.
*    CLEAR: PF_ITEM_O.
*  ENDLOOP.
*
*  CHECK PF_ITEM_O[] IS NOT INITIAL.
***取得各ITEM的金額及TAX(未與PI餘額比較)
*  LOOP AT PF_ITEM_O.
*    READ TABLE I_ITEM WITH KEY  VBELN = PF_ITEM_O-VBELN
*                                POSNR = PF_ITEM_O-POSNR
*                                ZTYPE = PF_ITEM_O-ZTYPE
*                                AUBEL = PF_ITEM_O-AUBEL.
*    CHECK SY-SUBRC = 0.
****計算PI付款的百分比
*    PERFORM CHECK_PROFORMA_STATUS USING     PF_ITEM_O-PERFI
*                                            'RATE'
*                                  CHANGING  PFV_NUMB1
*                                            PFV_NUMB2.
*    PF_ITEM_O-FOAMT = I_ITEM-KWERT * PFV_NUMB2 / PFV_NUMB1.
*    PF_ITEM_O-PITAX = ( I_ITEM-KWERT * I_ITEM-KBETR / 100 ) * PFV_NUMB2 / PFV_NUMB1.            "因為I_ITEM-KBETR是百分比
*    PF_ITEM_O-WAERK = I_ITEM-WAERK.
*    MODIFY PF_ITEM_O.
*    MOVE-CORRESPONDING PF_ITEM_O TO PF_PIINFO.
*    APPEND PF_PIINFO.
*    CLEAR: PF_PIINFO.
*  ENDLOOP.
*
***取得每個ITEM對應PI的金額
*  SORT PF_PIINFO BY PERFI AUBEL.
*  DELETE ADJACENT DUPLICATES FROM PF_PIINFO COMPARING PERFI AUBEL.
***取得每個PI的出貨BILLING
*  LOOP AT PF_PIINFO.
*    LOOP AT I_VBFA WHERE VBELV    = PF_PIINFO-AUBEL
*                   AND   VBTYP_N  = 'M'.
*      MOVE-CORRESPONDING I_VBFA TO PF_VBFA.
*      APPEND PF_VBFA.
*    ENDLOOP.
*  ENDLOOP.
*
**  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBFA FROM VBFA
**                                                      FOR ALL ENTRIES IN PF_PIINFO
**                                                      WHERE VBELV   = PF_PIINFO-AUBEL
**                                                      AND   VBTYP_N = TEXT-TPM.                   "TEXT-TPM = 'M'.
****判斷對應的BILLING是否被CANCEL
**  LOOP AT PF_VBFA.
**    PERFORM CHECK_BILLING_CANCELED USING      PF_VBFA-VBELN
**                                   CHANGING   PFV_CANCL.
**    CHECK PFV_CANCL IS NOT INITIAL.
**    DELETE PF_VBFA.
**  ENDLOOP.
*
*  LOOP AT PF_PIINFO.
****取得PI總金額(含TAX)
*    PERFORM GET_PROFORMA_CONDITIONS USING    PF_PIINFO-PERFI
*                                    CHANGING PFV_KWERT
*                                             PFV_KBETR
*                                             PFV_WAERK.
*    PF_PIINFO-PIAMT = PFV_KWERT + PFV_KBETR.
**<-I160627
****檢查vbfa中billing是否是在開pi之前就有的,要刪掉(已出貨部份訂單項目,其餘開PI)
*    PERFORM DELETE_ITEM_BEFORE_PI_DATE TABLES PF_VBFA
*                                       USING  PF_PIINFO-PERFI.
**->I160627
****取得PI餘額(ZPD2 + ZPD6)
*    PERFORM GET_PROFORMA_BALANCE TABLES   PF_VBFA
*                                 USING    PF_PIINFO-PERFI
*                                          PF_PIINFO-WAERK
*                                          PF_PIINFO-PIAMT
*                                          PF_PIINFO-AUBEL
*                                 CHANGING PF_PIINFO-PIBAL.
*
****VBFA中是否有沒有在這次ITEM的BILLING中
*    PERFORM GET_BILLING_EXCLUDE_AMOUNT TABLES   PF_VBFA
*                                                PF_ITEM_O
*                                       USING    PF_PIINFO-AUBEL
*                                       CHANGING PFV_KWERT.
*    PF_PIINFO-PIBAL = PF_PIINFO-PIBAL - PFV_KWERT.
*    MODIFY PF_PIINFO.
*  ENDLOOP.
***計算每筆ITEM所用金額
*  LOOP AT PF_ITEM_O.
****先檢查該筆是否有在zpd2/zpd6中(有就用TABLE值)
*    PERFORM GET_AMOUNT_TAX_FORM_ZPDX USING    PF_ITEM_O
*                                     CHANGING PFV_KWERT
*                                              PFV_KBETR
*                                              PFV_CANCL.                                          "借來判斷是否要離開
*    IF PFV_CANCL IS NOT INITIAL.
*      PF_ITEM_O-FOAMT = PFV_KWERT.
*      PF_ITEM_O-PITAX = PFV_KBETR.
*      MODIFY PF_ITEM_O.
*      CONTINUE.
*    ENDIF.
****不存在TABLE中就往下走做分配
*    CLEAR: PFV_KWERT, PFV_TABIX.
*    READ TABLE PF_PIINFO WITH KEY PERFI = PF_ITEM_O-PERFI
*                                  AUBEL = PF_ITEM_O-AUBEL.
*    CHECK SY-SUBRC = 0.
*    PFV_TABIX = SY-TABIX.
*
*    PFV_KWERT = PF_ITEM_O-FOAMT + PF_ITEM_O-PITAX.
****PI餘額 = 0
*    IF PF_PIINFO-PIBAL = 0.
*      CLEAR: PF_ITEM_O-FOAMT, PF_ITEM_O-PITAX.
*      MODIFY PF_ITEM_O.
*      CONTINUE.
*    ENDIF.
****PI餘額 < 該ITEM出貨金額(需要計算)
*    IF PF_PIINFO-PIBAL < PFV_KWERT.
*      IF PF_ITEM_O-PITAX IS NOT INITIAL.
*        PF_ITEM_O-FOAMT = PF_PIINFO-PIBAL / ( 105 / 100 ).
*        PF_ITEM_O-PITAX = PF_PIINFO-PIBAL - PF_ITEM_O-FOAMT.
*      ELSE.
*        PF_ITEM_O-FOAMT = PF_PIINFO-PIBAL.
*      ENDIF.
*
*      CLEAR PF_PIINFO-PIBAL.
*      MODIFY PF_PIINFO INDEX PFV_TABIX.
*      MODIFY PF_ITEM_O.
*      CONTINUE.
*    ENDIF.
****PI餘額 > 該ITEM出貨金額
*    IF PF_PIINFO-PIBAL >= PFV_KWERT.
*      PF_PIINFO-PIBAL = PF_PIINFO-PIBAL - PFV_KWERT.
*      MODIFY PF_PIINFO INDEX PFV_TABIX.
*      CONTINUE.
*    ENDIF.
*
*  ENDLOOP.
*ENDFORM.                    " GET_EACH_ITEM_AMOUT_TAX
*&---------------------------------------------------------------------*
*&      Form  GET_PROFORMA_BALANCE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_PIINFO_PERFI  text
*      <--P_PF_PIINFO_PIBAL  text
*----------------------------------------------------------------------*
FORM GET_PROFORMA_BALANCE  TABLES   PF_VBFA_IO STRUCTURE VBFA
                           USING    PFV_PVBEL
                                    PFV_WAERK
                                    PFV_AMONT
                                    PFV_AUBEL
                           CHANGING PFV_VALUE.
  DATA: PF_ZPDX LIKE ZPD2 OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_VALUE, PF_ZPDX, PF_ZPDX[].

  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_ZPDX FROM  ZPD2
                                                      WHERE PERFI = PFV_PVBEL.
**把同一張PI的VBFA,它的BILLING有在PF_ZPDX刪掉,留下來的就是還沒寫入ZPD2/ZPD6的(放這裡是因為ZPD6有可能重覆)
  LOOP AT PF_ZPDX.
    LOOP AT PF_VBFA_IO WHERE VBELV = PFV_AUBEL
                       AND   VBELN = PF_ZPDX-VBELN.
*                      AND   POSNN = PF_ZPDX-POSNR.
      DELETE PF_VBFA_IO.
    ENDLOOP.
  ENDLOOP.

  SELECT * APPENDING CORRESPONDING FIELDS OF TABLE PF_ZPDX FROM  ZPD6
                                                           WHERE PERFI = PFV_PVBEL.
*  CHECK PF_ZPDX[] IS NOT INITIAL. "若有這段後面就不會算了~~~重要*****
  LOOP AT PF_ZPDX WHERE WAERK = PFV_WAERK.
    PFV_VALUE = PFV_VALUE + PF_ZPDX-FOAMT.
  ENDLOOP.
  PFV_VALUE = PFV_AMONT - PFV_VALUE.
  CHECK PFV_VALUE < 0.
  PFV_VALUE = 0.
ENDFORM.                    " GET_PROFORMA_BALANCE
*&---------------------------------------------------------------------*
*&      Form  GET_BILLING_EXCLUDE_AMOUNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA  text
*      -->P_PF_PIITEM_O  text
*      <--P_PFV_KWERT  text
*----------------------------------------------------------------------*
FORM GET_BILLING_EXCLUDE_AMOUNT  TABLES   PF_VBFA_IO STRUCTURE VBFA
                                          PF_ITEM_I  STRUCTURE I_ITEM_PIITEM
                                 USING    PFV_AUBEL
                                 CHANGING PFV_VALUE.
  DATA: PFV_DATUM TYPE DATUM,
        PFV_UZEIT TYPE UZEIT,
        PFV_CALCU TYPE C.                                                                          "判斷是否要計算
  CLEAR: PFV_VALUE.
  LOOP AT PF_VBFA_IO WHERE VBELV = PFV_AUBEL.
    READ TABLE PF_ITEM_I WITH KEY VBELN = PF_VBFA_IO-VBELN.
    CHECK SY-SUBRC <> 0.
    PERFORM GET_BILLING_DATE_TIME TABLES   PF_ITEM_I
                                  USING    PFV_AUBEL
                                  CHANGING PFV_DATUM
                                           PFV_UZEIT.
    IF PFV_DATUM > PF_VBFA_IO-ERDAT.
      PFV_CALCU = TEXT-TPX.                                                                        "TEXT-TPX = 'X'
    ELSE.
      IF PFV_DATUM = PF_VBFA_IO-ERDAT.
        IF PFV_UZEIT >  PF_VBFA_IO-ERZET.
          PFV_CALCU = TEXT-TPX.                                                                    "TEXT-TPX = 'X'
        ENDIF.
      ELSE.
        DELETE PF_VBFA_IO.
      ENDIF.
    ENDIF.

    CHECK PFV_CALCU IS NOT INITIAL.
    SELECT SINGLE * FROM   VBRP
                    WHERE  VBELN = PF_VBFA_IO-VBELN
                    AND    POSNR = PF_VBFA_IO-POSNN.
    CHECK SY-SUBRC = 0.
    IF VBRP-TAXM1 = 1.
      PFV_VALUE = PFV_VALUE + ( VBRP-NETWR * 105 / 100 ).
    ELSE.
      PFV_VALUE = PFV_VALUE + VBRP-NETWR.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " GET_BILLING_EXCLUDE_AMOUNT
*&---------------------------------------------------------------------*
*&      Form  GET_BILLING_DATE_TIME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM_I  text
*      -->P_PFV_AUBEL  text
*      <--P_PFV_DATUM  text
*      <--P_PFV_UZEIT  text
*----------------------------------------------------------------------*
FORM GET_BILLING_DATE_TIME  TABLES   PF_PIITEM STRUCTURE I_ITEM_PIITEM
                            USING    PFV_AUBEL
                            CHANGING PFV_DATUM_O
                                     PFV_UZEIT_O.
  DATA: BEGIN OF PF_BILLING OCCURS 0,
          VBELN TYPE VBELN,
          DATUM TYPE DATUM,
          UZEIT TYPE UZEIT,
        END OF PF_BILLING.
  CLEAR: PFV_UZEIT_O, PFV_DATUM_O, PF_BILLING, PF_BILLING[], VBRK.

  LOOP AT PF_PIITEM WHERE AUBEL = PFV_AUBEL.
    SELECT SINGLE * FROM  VBRK
                    WHERE VBELN = PF_PIITEM-VBELN.
    CHECK SY-SUBRC = 0.
    PF_BILLING-VBELN = PF_PIITEM-VBELN.
    PF_BILLING-DATUM = VBRK-ERDAT.
    PF_BILLING-UZEIT = VBRK-ERZET.
    APPEND PF_BILLING.
    CLEAR: PF_BILLING.
  ENDLOOP.
  SORT PF_BILLING BY DATUM UZEIT.
  READ TABLE PF_BILLING INDEX 1.
  PFV_DATUM_O = PF_BILLING-DATUM.
  PFV_UZEIT_O = PF_BILLING-UZEIT.
ENDFORM.                    " GET_BILLING_DATE_TIME
*&---------------------------------------------------------------------*
*&      Form  GET_AMOUNT_TAX_FORM_ZPDX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_PIITEM_O  text
*      <--P_PFV_KWERT  text
*      <--P_PFV_KBETR  text
*      <--P_PFV_CANCL  text
*----------------------------------------------------------------------*
*FORM GET_AMOUNT_TAX_FORM_ZPDX  USING    PFWA_PIITME STRUCTURE I_ITEM_PIITEM
*                               CHANGING PFV_AMONT
*                                        PFV_PITAX
*                                        PFV_ZFLAG.
*  CLEAR: PFV_AMONT, PFV_PITAX, PFV_ZFLAG, ZPD2, ZPD6.
*
*  SELECT SINGLE * FROM  ZPD2
*                  WHERE VBELN = PFWA_PIITME-VBELN
**                 AND   POSNR = PFWA_PIITME-POSNR
*                  AND   PERFI = PFWA_PIITME-PERFI.
*  CHECK SY-SUBRC = 0.
*  PFV_ZFLAG = TEXT-TPX.                                                                           "TEXT-TPX = 'X'
*  PFV_AMONT = ZPD2-FOAMT.
*
*  SELECT SINGLE * FROM  ZPD6
*                  WHERE VBELN = PFWA_PIITME-VBELN
**                 AND   POSNR = PFWA_PIITME-POSNR
*                  AND   PERFI = PFWA_PIITME-PERFI.
*  CHECK SY-SUBRC = 0.
*  PFV_PITAX = ZPD6-FOAMT.
*ENDFORM.                    " GET_AMOUNT_TAX_FORM_ZPDX
*&---------------------------------------------------------------------*
*&      Form  DELETE_ITEM_BEFORE_PI_DATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA  text
*      -->P_PF_PIINFO_PERFI  text
*----------------------------------------------------------------------*
*FORM DELETE_ITEM_BEFORE_PI_DATE  TABLES   PF_VBFA_IO STRUCTURE VBFA
*                                 USING    PFV_PVBEL.
*  DATA: PFWA_VBRK LIKE VBRK.
*  PERFORM GET_WORKAREA_VBRK USING     PFV_PVBEL
*                            CHANGING  PFWA_VBRK.
*  CHECK PFWA_VBRK IS NOT INITIAL.
*  LOOP AT PF_VBFA_IO WHERE ERDAT < PFWA_VBRK-FKDAT.
*    DELETE PF_VBFA_IO.
*  ENDLOOP.
*ENDFORM.                    " DELETE_ITEM_BEFORE_PI_DATE
*&---------------------------------------------------------------------*
*&      Form  CHECK_DATA_INV_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK  text
*----------------------------------------------------------------------*
FORM CHECK_BILL_DATA_STATUS  TABLES   PF_VBRK_IO STRUCTURE VBRK
                                      PF_ZPDH_IO STRUCTURE ZPDH.
  DATA: PFV_CANCL(01) TYPE C,
        PFWA_DD07T    LIKE DD07T,
        PFWA_HEAD_TMP LIKE I_HEAD,
        PFWA_ZPDH     LIKE ZPDH,
        PFV_VARTS_X   TYPE C,         "接值用
*        PFV_NETWR_ORG TYPE NETWR,
        PFV_NETWR_NEW TYPE NETWR.
*處理正常Billing / 原PI / Dabit, Credit Memo
  LOOP AT PF_VBRK_IO.
**1.檢查是否被刪單
    IF PF_VBRK_IO-FKSTO IS NOT INITIAL.
      MESSAGE I000 WITH  PF_VBRK_IO-VBELN 'is canceled !'.
      DELETE PF_VBRK_IO.
      CONTINUE.
    ENDIF.
**2.檢查Billing Release的部份
    IF PF_VBRK_IO-ZBSTATUS <> 'ACTV' AND
       PF_VBRK_IO-ZBSTATUS <> 'RECM' AND
       PF_VBRK_IO-ZBSTATUS IS NOT INITIAL.
*<-I210217
      PERFORM GET_WORAKREA_DD07T USING    PF_VBRK_IO-ZBSTATUS
                                          'ZBLSTAS'
                                 CHANGING PFWA_DD07T.
      IF PFWA_DD07T IS NOT INITIAL.
        MESSAGE I000 WITH PF_VBRK_IO-VBELN 'Billing Status is' PFWA_DD07T-DDTEXT.
      ELSE.
        MESSAGE I000 WITH PF_VBRK_IO-VBELN 'Billing Status is' PF_VBRK_IO-ZBSTATUS.
      ENDIF.
*->I210217
*      MESSAGE I000 WITH PF_VBRK_IO-VBELN 'Billing Status is' PF_VBRK_IO-ZBSTATUS.       "D210217

      DELETE PF_VBRK_IO.
      CONTINUE.
    ENDIF.
**3.[CHECK]檢查是否符合單據類別的條件
    IF PF_VBRK_IO-VBTYP <> 'O' AND              "O = Credit Memo
       PF_VBRK_IO-VBTYP <> 'M' AND              "M = Invoice
       PF_VBRK_IO-VBTYP <> 'P' AND              "M = Debit Memo
       PF_VBRK_IO-VBTYP <> 'U'.                 "U = Proforma
      MESSAGE I000 WITH PF_VBRK_IO-VBELN ':該單號不屬於INVOICE/CREDIT MEMO/PROFORMA INVOICE!'.
      DELETE PF_VBRK_IO.
      CONTINUE.
    ENDIF.
**4.檢查F2 / L2單據
    IF PF_VBRK_IO-VBTYP = 'M' OR PF_VBRK_IO-VBTYP = 'P'.
**4.1檢查所使用的PI是否已經列印過(ZPD1中有值)
      PERFORM CHECK_USEING_PI_PRINTED USING     PF_VBRK_IO
                                      CHANGING  PFV_CANCL.
*<-I210217 D212422
*      PERFORM CHECK_USEING_PI_PRINTED USING     PF_VBRK_IO
*                                                'NEWPI'
*                                      CHANGING  PFV_CANCL.
*->I210217 D212422
      IF PFV_CANCL IS NOT INITIAL.
        DELETE PF_VBRK_IO.
        CONTINUE.
      ENDIF.
**4.2檢查該客戶的銀行主檔是否存在
      PERFORM CHECK_BANK_MASTER_EXIST USING     PF_VBRK_IO
                                      CHANGING  PFV_CANCL.
      IF PFV_CANCL IS NOT INITIAL.
        DELETE PF_VBRK_IO.
        CONTINUE.
      ENDIF.
    ENDIF.
**5.如果是預收(F5)檢查是否被刪單
    IF PF_VBRK_IO-VBTYP = 'U'.
      PERFORM CHECK_PROFORMA_STATUS USING     PF_VBRK_IO-VBELN
                                              'CHCK'
                                    CHANGING  PFV_CANCL
                                              PFV_VARTS_X.
      IF PFV_CANCL IS NOT INITIAL.
        DELETE PF_VBRK_IO.
        CONTINUE.
      ENDIF.
    ENDIF.
**6.檢查預收(F5)與NEW PI TABLE的金額是否一致(比未稅即可)
*<-I210422
    IF PF_VBRK_IO-VBTYP = 'U'.
      CLEAR: PFWA_HEAD_TMP.
*      PFV_NETWR_ORG = PF_VBRK_IO-NETWR + PF_VBRK_IO-MWSBK.  "MWSBK(稅)
***判斷PI是以何種方式計價PBYPC = 'X' =>以片計價
      PERFORM GET_DOCTYPE_AND_DATE_VBRK USING     PF_VBRK_IO
                                        CHANGING  PFWA_HEAD_TMP.
      PFWA_HEAD_TMP-VBELN = PF_VBRK_IO-VBELN.
***取得實際金額(原PI)
      PERFORM GET_PROFORMA_DOWNPAY_AMT USING     PFWA_HEAD_TMP
                                                 PF_VBRK_IO-NETWR
                                       CHANGING  PFV_NETWR_NEW.
***取得NEW PI TABLE 放的舊資料
      PERFORM GET_WORKAREA_ZPDH USING     PF_VBRK_IO-VBELN
                                CHANGING  PFWA_ZPDH.
      CHECK PFWA_ZPDH IS NOT INITIAL.
      CHECK PFV_NETWR_NEW <> PFWA_ZPDH-NETWR.
      MESSAGE I000 WITH PF_VBRK_IO-VBELN ':該單金額與ZPDH的金額不一致!!'.
      DELETE PF_VBRK_IO.
      CONTINUE.
    ENDIF.
*->I210422
  ENDLOOP.
*<-I210217
**New PI Check
  LOOP AT PF_ZPDH_IO.
**檢查PI是否已經被Cancel掉了
    CHECK PF_ZPDH_IO-ZBSTATUS = 'CANC'.
    PERFORM GET_WORAKREA_DD07T USING    PF_ZPDH_IO-ZBSTATUS
                                        'ZBLSTAS'
                               CHANGING PFWA_DD07T.
    MESSAGE I000 WITH PF_ZPDH_IO-PERFI 'PI Status is' PFWA_DD07T-DDTEXT.
    DELETE PF_ZPDH_IO.
    CONTINUE.
  ENDLOOP.
*->I210217
ENDFORM.                    " CHECK_DATA_INV_STATUS
*&---------------------------------------------------------------------*
*&      Form  CHECK_LIKP_DATA_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIKP  text
*----------------------------------------------------------------------*
FORM CHECK_LIKP_DATA_STATUS  TABLES   PF_LIKP_IO STRUCTURE LIKP.
  DATA: PFWA_VBUK     LIKE VBUK,
        PFV_NOEST(01) TYPE C.
  CHECK PF_LIKP_IO[]  IS NOT INITIAL.
**檢查DN是否已完成PGI
  LOOP AT PF_LIKP_IO.
***狀態未完成PGI
*    PERFORM GET_WORKAREA_VBUK USING     PF_LIKP_IO-VBELN
*                              CHANGING  PFWA_VBUK.
*    IF PFWA_VBUK-WBSTK <> 'C'.                     "PGI Not Complate
*      MESSAGE I000 WITH PF_LIKP_IO-VBELN ':has not yet done goods issue !'.
*      DELETE PF_LIKP_IO.
*      CONTINUE.
*    ENDIF.
***PGI Date沒有值
*    IF PF_LIKP_IO-WADAT_IST IS INITIAL.
*      MESSAGE I000 WITH PF_LIKP_IO-VBELN ':Can not find goods issue date!'.
*      DELETE PF_LIKP_IO.
*      CONTINUE.
*    ENDIF.
**判斷USCI Code是否存在
*<-I190116
    PERFORM CHECK_USCI_CODE_EXIST USING     PF_LIKP_IO
                                  CHANGING  PFV_NOEST.
    IF PFV_NOEST IS NOT INITIAL.
*      MESSAGE I000 WITH PF_LIKP_IO-VBELN ':Ship to China, USCI Code does not exist!'.     "D111819
    ENDIF.
*->I190116
  ENDLOOP.

  CHECK P_JOBTPS <> 'B'.                        "B = 出庫單 "I140123
  LOOP AT PF_LIKP_IO WHERE LFART = 'LR'.        "LR = RETURN DN (無法使用此程式)
    MESSAGE I000 WITH PF_LIKP_IO-VBELN 'IS RETURN DELIVERY!'.
    DELETE PF_LIKP_IO.
  ENDLOOP.
ENDFORM.                    " CHECK_LIKP_DATA_STATUS

*&---------------------------------------------------------------------*
*&      Form  GET_DOC_TYPE_DATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK  text
*      <--P_I_HEAD_ZTYPE  text
*      <--P_I_HEAD_SIDAT  text
*----------------------------------------------------------------------*
FORM GET_DOCTYPE_AND_DATE_VBRK  USING    PFWA_VBRK_I  STRUCTURE VBRK
                                CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFV_PTYPE(04) TYPE C,
        PFV_LINES_X   TYPE TDLINE.              "接值用...
  CLEAR: PFWA_HEAD_IO-ZTYPE, PFWA_HEAD_IO-SIDAT.

  CASE PFWA_VBRK_I-VBTYP.
    WHEN 'M'.                                   "M = Invoice
      PFWA_HEAD_IO-ZTYPE = 'I'.
      PFWA_HEAD_IO-SIDAT = PFWA_VBRK_I-ZSIDAT.  "INVOICE DATE
    WHEN 'O'.                                   "O = Credit Memo
      PFWA_HEAD_IO-ZTYPE = 'C'.
      PFWA_HEAD_IO-SIDAT = PFWA_VBRK_I-ZSIDAT.  "INVOICE DATE
    WHEN 'P'.                                   "P = Dredit Memo / L2
      PFWA_HEAD_IO-ZTYPE = 'D'.
      PFWA_HEAD_IO-SIDAT = PFWA_VBRK_I-ZSIDAT.  "INVOICE DATE
    WHEN 'U'.                                   "U = Proforma
      PFWA_HEAD_IO-ZTYPE = 'R'.
      PFWA_HEAD_IO-SIDAT = PFWA_VBRK_I-FKDAT.   "INVOICE DATE
      PERFORM GET_PI_RATE_PRICE_DATA  USING     PFWA_VBRK_I-VBELN
                                      CHANGING  PFV_PTYPE
                                                PFV_LINES_X.
      CHECK PFV_PTYPE = 'PC'.
      PFWA_HEAD_IO-PBYPC = 'X'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_DOC_TYPE_DATE
*&---------------------------------------------------------------------*
*&      Form  GET_DN_SIGNAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_VBELN  text
*      <--P_I_HEAD_VGBEL  text
*----------------------------------------------------------------------*
FORM GET_1ST_DN_FROM_VBRP  USING    PFV_VBELN_I
                           CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PF_VBRP   LIKE VBRP OCCURS 0 WITH HEADER LINE.
*        PFV_RECOD TYPE I.
  CLEAR: PFWA_HEAD_IO-VGBEL.
  PERFORM GET_DATA_VBRP TABLES  PF_VBRP
                        USING   PFV_VBELN_I.
  SORT PF_VBRP BY VGBEL.
  DELETE ADJACENT DUPLICATES FROM PF_VBRP COMPARING VGBEL.
*  DESCRIBE TABLE PF_VBRP LINES PFV_RECOD.
  READ TABLE PF_VBRP INDEX 1.
  PFWA_HEAD_IO-VGBEL = PF_VBRP-VGBEL.
**下面先不用...要修部份蠻多的
*  IF PFV_RECOD > 1.
*    PFV_VGBEL = 'X'.                                                                              "代表一張BILLING對多張DN
*  ELSE.
*    READ TABLE PF_VBRP INDEX 1.
*    PFV_VGBEL = PF_VBRP-VGBEL.
*  ENDIF.
ENDFORM.                    " GET_DELIVERY_NO
*&---------------------------------------------------------------------*
*&      Form  GET_PAYMENT_TERM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_ZTERM  text
*      <--P_I_HEAD_PAYTM  text
*----------------------------------------------------------------------*
FORM GET_PAYMENT_TERM_DESC  USING    PFV_ZTERM_I
                            CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.

  DATA: PF_T052U  LIKE T052U OCCURS 0 WITH HEADER LINE,
        PF_LINES  LIKE TLINE  OCCURS 0 WITH HEADER LINE.


  CLEAR: PFWA_HEAD_IO-PAYTM, PF_T052U, PF_T052U[].
  IF PFV_ZTERM_I <> 'ZZ99'.
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_T052U FROM  T052U
                                                  WHERE ZTERM = PFV_ZTERM_I
                                                  AND   SPRAS = SY-LANGU.
    LOOP AT PF_T052U.
      CONCATENATE PFWA_HEAD_IO-PAYTM PF_T052U-TEXT1
        INTO PFWA_HEAD_IO-PAYTM SEPARATED BY SPACE.
    ENDLOOP.
    CONCATENATE PFV_ZTERM_I ':' PFWA_HEAD_IO-PAYTM
      INTO PFWA_HEAD_IO-PAYTM.                            "PAYMENT TERMS
    EXIT.
  ENDIF.
  PFWA_HEAD_IO-PAYTM = PFV_ZTERM_I.                       "PAYMENT TERMS
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFWA_HEAD_IO-AUBEL
                               '0013'
                               'VBBK'.
  LOOP AT PF_LINES.
    CONCATENATE PFWA_HEAD_IO-PAYTM  PF_LINES-TDLINE
      INTO PFWA_HEAD_IO-PAYTM SEPARATED BY SPACE.
  ENDLOOP.
  CONCATENATE PFV_ZTERM_I  ':' PFWA_HEAD_IO-PAYTM
    INTO PFWA_HEAD_IO-PAYTM.                              "PAYMENT TERMS
ENDFORM.                    " GET_PAYMENT_TERM
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_NO_VBPA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_DOCNO  text
*      -->P_7701   text
*      -->P_7702   text
*      <--P_PFV_CUSNO_I  text
*----------------------------------------------------------------------*
FORM GET_CUST_NO_VBPA  USING    PFV_VBELN
                                PFV_POSNR
                                PFV_ZTYPE
                       CHANGING PFV_CUTNO.
  CLEAR: PFV_CUTNO, VBPA.
  SELECT SINGLE * FROM  VBPA
                  WHERE VBELN = PFV_VBELN
                  AND   POSNR = PFV_POSNR
                  AND   PARVW = PFV_ZTYPE.
  CHECK SY-SUBRC = 0.
  PFV_CUTNO = VBPA-KUNNR.
ENDFORM.                    " GET_CUST_NO_VBPA

*&---------------------------------------------------------------------*
*&      Form  GET_USEFUL_FLOW_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_PF_VBFA  text
*      -->P_I_HEAD_VGBEL  text
*      -->P_LIKP_VBTYP  text
*      -->P_3824   text
*----------------------------------------------------------------------*
FORM GET_USEFUL_FLOW_DATA  TABLES   PF_VBFA_I STRUCTURE VBFA
                                    PF_VBFA_O STRUCTURE VBFA
                           USING    PFV_DOCNO
                                    PFV_VBTYP
                                    PFV_DOCTP.
  CLEAR: PF_VBFA_O, PF_VBFA_O[].
  APPEND LINES OF PF_VBFA_I TO PF_VBFA_O.
  DELETE PF_VBFA_O WHERE VBELV   <> PFV_DOCNO
                   OR    VBTYP_N <> PFV_DOCTP
                   OR    VBTYP_V <> PFV_VBTYP.

*  CLEAR: PF_VBFA_O, PF_VBFA_O[].
*  LOOP AT PF_VBFA_I WHERE VBELV   = PFV_DOCNO
*                    AND   VBTYP_N = PFV_DOCTP
*                    AND   VBTYP_V = PFV_VBTYP.
*    MOVE-CORRESPONDING PF_VBFA_I TO PF_VBFA_O.
*    APPEND PF_VBFA_O.
*  ENDLOOP.
ENDFORM.                    " GET_USEFUL_FLOW_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_PARTNER_NUMBER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_HEAD  text
*      -->P_VBRK_ZSPARNR_B  text
*      <--P_PFV_PARNR  text
*----------------------------------------------------------------------*
FORM GET_PARTNER_NUMBER  USING    PFWA_HEAD STRUCTURE I_HEAD
                                  PFV_ZSPAR
                                  PFV_FNCTN
                         CHANGING PFV_PARTR.
  DATA: PFWA_LIKP LIKE LIKP,
        PFWA_VBAK LIKE VBAK,
        PFV_KUNAG TYPE KUNAG.
  CLEAR: PFV_PARTR, PFV_KUNAG.

  CASE PFV_FNCTN.
    WHEN 'SOLD'.
      PFV_KUNAG = PFWA_HEAD-KUNAG.
      PFV_PARTR = PFV_ZSPAR.
      CHECK PFV_PARTR IS INITIAL.
      PERFORM GET_WORKAREA_VBAK USING     PFWA_HEAD-AUBEL
                                CHANGING  PFWA_VBAK.
      PFV_PARTR = PFWA_VBAK-ZSPARNR.
    WHEN 'SHIP'.
      PFV_KUNAG = PFWA_HEAD-KUNNR.
      PERFORM GET_WORKAREA_LIKP USING     PFWA_HEAD-VGBEL
                                CHANGING  PFWA_LIKP.
      PFV_PARTR = PFWA_LIKP-ZPPARNR1.
      CHECK PFV_PARTR IS INITIAL.
      PERFORM GET_WORKAREA_VBAK USING     PFWA_HEAD-AUBEL
                                CHANGING  PFWA_VBAK.
      IF PFWA_VBAK IS NOT INITIAL.
        PFV_PARTR = PFWA_VBAK-ZSPARNR.
      ELSE.
        PFV_PARTR = PFV_ZSPAR.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.
*-  可能因為客戶主檔的CONTACT PERSON作刪除,導致編碼不同 I161011
  SELECT SINGLE * FROM  KNVK
                  WHERE PARNR = PFV_PARTR
                  AND   KUNNR = PFV_KUNAG.
  CHECK SY-SUBRC <> 0.
  CLEAR: PFV_PARTR.
ENDFORM.                    " GET_PARTNER_NUMBER

*&---------------------------------------------------------------------*
*&      Form  GET_CUST_PO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_VGBE  text
*      -->P_PFWA_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_CUST_PO  USING    PFV_VGBEL
                           PFV_ZTYPE.
  DATA:PFV_REMAK(300)  TYPE C.
  DATA: BEGIN OF PF_BSTK OCCURS 0,
          BSTKD TYPE BSTKD,
        END OF PF_BSTK.

  CLEAR: PFV_REMAK.
  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    PF_BSTK-BSTKD = I_ITEM-BSTNK.
*    PF_BSTK-BSTKD = I_ITEM-BSTKD.
    APPEND PF_BSTK.
    CLEAR: PF_BSTK.
  ENDLOOP.  "I_ITEM
  SORT PF_BSTK.
  DELETE ADJACENT DUPLICATES FROM PF_BSTK.

  CHECK PF_BSTK[] IS NOT INITIAL.
  CONCATENATE '**' TEXT-I20 INTO PFV_REMAK+2 SEPARATED BY SPACE.                                  "TEXT-I20 = 'Customer PO No.:'
  LOOP AT PF_BSTK.
    CONCATENATE PFV_REMAK PF_BSTK-BSTKD INTO PFV_REMAK SEPARATED BY SPACE.
  ENDLOOP.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFV_VGBEL
                                      PFV_ZTYPE
                                      'POLIST'.
ENDFORM.                    " GET_CUST_PO
*&---------------------------------------------------------------------*
*&      Form  GET_BLANK_ROW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_3      text
*----------------------------------------------------------------------*
FORM GET_BLANK_ROW  USING PFV_VGBEL
                          PFV_ZTYPE
                          PFV_VALUE.
  DATA:PFV_REMAK(300)  TYPE C.
  DO PFV_VALUE TIMES.
    CLEAR: PFV_REMAK.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDDO.
ENDFORM.                    " GET_BLANK_ROW
*&---------------------------------------------------------------------*
*&      Form  GET_PALLET_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_VGBEL  text
*      -->P_PFWA_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_PALLET_INFO  USING    PFV_VGBEL
                               PFV_ZTYPE.
  DATA:PFV_REMAK(300)  TYPE C.
  CLEAR: PFV_REMAK.
  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    CHECK I_ITEM-PALNO IS NOT INITIAL AND
          PFV_REMAK IS INITIAL.
    CONCATENATE '**' TEXT-I05 INTO PFV_REMAK+2 SEPARATED BY SPACE.                                "TEXT-I05 = 'This pallet belong to paper pallet.'
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VGBEL
                                        PFV_ZTYPE
                                        ''.
  ENDLOOP.  "I_ITEM
ENDFORM.                    " GET_PALLET_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_SHIPPING_MARK_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD  text
*----------------------------------------------------------------------*
FORM GET_SHIPPING_MARK_INFO  USING    PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: PFV_PALLE(30)    TYPE C,
        PFV_CARTO(30)    TYPE C.

  I_ITEM_SHRE-VBELN = PFWA_HEAD_I-VBELN.
  I_ITEM_SHRE-ZTYPE = PFWA_HEAD_I-ZTYPE.
  I_ITEM_SHRE-KUNNR = PFWA_HEAD_I-KUNNR.
  IF PFWA_HEAD_I-KUNAG IN R_KTC.                 "KTC only  "I092319
    I_ITEM_SHRE-LMAKE = 'Made In TW'.                       "I092319
  ELSE.                                                     "I092319
    I_ITEM_SHRE-LMAKE = 'Made in Taiwan'.
  ENDIF.                                                    "I092319
  PERFORM GET_SHIPPING_MARK USING     PFWA_HEAD_I
                            CHANGING  I_ITEM_SHRE-NAME1
                                      I_ITEM_SHRE-ORT01
                                      PFV_PALLE
                                      PFV_CARTO.
  IF PFV_PALLE <> ''.
    CONCATENATE 'P/NO:' PFV_PALLE
      INTO I_ITEM_SHRE-PSQUN SEPARATED BY SPACE.
  ELSE.
    CONCATENATE 'C/NO:' PFV_CARTO
      INTO I_ITEM_SHRE-PSQUN SEPARATED BY SPACE.
  ENDIF.
  APPEND: I_ITEM_SHRE.
  CLEAR:  I_ITEM_SHRE.

ENDFORM.                    " GET_SHIPPING_MARK_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_DN_FROM_BILLING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK  text
*      -->P_I_LIKP  text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_LIKP_FROM_VBRK  TABLES   PF_VBRK_IO STRUCTURE VBRK         "有可能因為S_KUNNR把BILLING刪了
                                            PF_LIKP_IO STRUCTURE LIKP.
  RANGES: PFR_VBELN FOR VBRK-VBELN.
  DATA: PF_VBRP LIKE VBRP OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_VBRP, PF_VBRP[], PFR_VBELN, PFR_VBELN[].

*<-I210217
  PERFORM GET_ITEM_DATA_VBRP TABLES PF_VBRK_IO
                                    PF_VBRP
                             USING  'F2'.
*->I210217

*<-D210217
*  LOOP AT PF_VBRK_IO WHERE FKART = 'F2'.         "F2 = Invoice, F5 = Proforma, G2 = Credit Memo
*    SELECT *
*      APPENDING CORRESPONDING FIELDS OF TABLE PF_VBRP FROM   VBRP
*                                                      WHERE  VBELN = PF_VBRK_IO-VBELN.
*  ENDLOOP.
*->D210217
  SORT PF_VBRP BY VGBEL.
  DELETE ADJACENT DUPLICATES FROM PF_VBRP COMPARING VGBEL.

  "F2的VGBEL是DN No.   AUBEL是SO No.
  "F5的VGBEL / AUBEL 是SO No.
  "G2的VGBEL / AUBEL 是Credit Memo SO No.
  CHECK PF_VBRP[] IS NOT INITIAL.                                                                 "空白會全抓...要小心
  SELECT *
    APPENDING CORRESPONDING FIELDS OF TABLE PF_LIKP_IO FROM LIKP
                                                       FOR ALL ENTRIES IN PF_VBRP
                                                       WHERE VBELN =  PF_VBRP-VGBEL
                                                       AND   KUNNR IN S_KUNNR."I190425
  SORT PF_LIKP_IO.
  DELETE ADJACENT DUPLICATES FROM PF_LIKP_IO COMPARING ALL FIELDS.
**如果Billing中含有一筆非S_KUNNR中的條件,該Billing就不能出現
*<-I190425
  CHECK S_KUNNR[] IS NOT INITIAL.
  CHECK P_JOBTPS IS INITIAL.
  LOOP AT PF_VBRP.
    READ TABLE PF_LIKP_IO WITH KEY VBELN = PF_VBRP-VGBEL.
    CHECK SY-SUBRC <> 0.
    PFR_VBELN-OPTION  = 'EQ'.
    PFR_VBELN-SIGN    = 'I'.
    PFR_VBELN-LOW     = PF_VBRP-VBELN.
    APPEND PFR_VBELN.
  ENDLOOP.
  CHECK PFR_VBELN[] IS NOT INITIAL.
  DELETE PF_VBRK_IO WHERE VBELN IN PFR_VBELN.
*->I190425
ENDFORM.                    " GET_DN_FROM_BILLING
*&---------------------------------------------------------------------*
*&      Form  GET_ASNNO_FOR_ONSEMI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I_VBELN  text
*      <--P_PFV_ASNNO  text
*----------------------------------------------------------------------*
FORM GET_ASNNO_FOR_ONSEMI  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                           CHANGING PFV_VALUE_O.
  DATA: PF_LIPS       LIKE LIPS OCCURS 0 WITH HEADER LINE,
        PF_VBFA       LIKE VBFA OCCURS 0 WITH HEADER LINE,
        PFWA_VBAP     LIKE VBAP,
        PFWA_VBRK     LIKE VBRK,
        PFV_ENGML(01) TYPE C,                             "判斷是否為Eng料號
        PFV_VBELN     TYPE VBELN_VF.

  CLEAR: PFV_VALUE_O, PF_LIPS, PF_LIPS[], PF_VBFA, PF_VBFA[], PFV_ENGML, PFV_VBELN.
**先判斷是否有工程料號
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_LIPS FROM   LIPS
                                               WHERE  VBELN = PFWA_HEAD_I-VGBEL
                                               AND    CHARG <> ''.
  LOOP AT PF_LIPS.
    PERFORM GET_WORKAREA_VBAP USING     PF_LIPS-VGBEL
                                        PF_LIPS-VGPOS
                              CHANGING  PFWA_VBAP.
    CHECK PFWA_VBAP-ZZENGLOT = 'Y'.
    PFV_ENGML = 'X'.
    EXIT.
  ENDLOOP.

  CHECK PFV_ENGML IS INITIAL.

  IF PFWA_HEAD_I-VKORG = 'MAX1'.
    SELECT SINGLE * FROM  ZSD_ONS
                    WHERE VBELN = PFV_VBELN.
    IF SY-SUBRC = 0.
      PFV_VALUE_O = ZSD_ONS-ASNNO.
    ENDIF.
    CHECK PFV_VALUE_O IS INITIAL.
    SELECT SINGLE * FROM  ZSD_ONS
                    WHERE VGBEL = PFV_VBELN.
    CHECK SY-SUBRC = 0.
    PFV_VALUE_O = ZSD_ONS-ASNNO.
  ENDIF.

  IF PFWA_HEAD_I-VKORG = 'PSC1'.
    PFV_VBELN = PFWA_HEAD_I-VBELN.
    IF PFWA_HEAD_I-ZTYPE = 'P'.
      SELECT *
        INTO CORRESPONDING FIELDS OF TABLE PF_VBFA FROM  VBFA
                                                   WHERE VBELV   =  PFWA_HEAD_I-VGBEL
                                                   AND   VBTYP_N = 'M'.
      LOOP AT PF_VBFA.
        PERFORM GET_WORKAREA_VBRK USING     PF_VBFA-VBELN
                                  CHANGING  PFWA_VBRK.
        CHECK PFWA_VBRK IS NOT INITIAL.
        CHECK PFWA_VBRK-FKSTO IS INITIAL.
        PFV_VBELN = PF_VBFA-VBELN.
        EXIT.
      ENDLOOP.
    ENDIF.
    SELECT SINGLE * FROM  ZSD154
                    WHERE VBELN = PFV_VBELN.
    CHECK SY-SUBRC = 0.
    PFV_VALUE_O = ZSD154-ASNNO.
  ENDIF.

  CHECK PFV_VALUE_O IS INITIAL.
  MESSAGE E000 WITH 'OnSemi ASN No 尚未assign, 請聯絡SA!!'.
ENDFORM.                    " GET_ASNNO_FOR_ONSEMI
*&---------------------------------------------------------------------*
*&      Form  IMEX_CHECK_OTHER_PRICE_RULE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM  text
*      <--P_PFV_USING  text
*----------------------------------------------------------------------*
FORM IMEX_CHECK_OTHER_PRICE_RULE  USING    PFWA_ITEM STRUCTURE I_ITEM
                                           PFV_FUNCT
                                  CHANGING PFV_VALUE.
  DATA: PFV_POSNR TYPE POSNR.

  CLEAR: PFV_VALUE, PFV_POSNR.
  CASE PFWA_ITEM-ZTYPE.
    WHEN 'I'.
      PFV_POSNR = PFWA_ITEM-POSNR.
    WHEN 'F'.
      PFV_POSNR = PFWA_ITEM-UECHA.
    WHEN OTHERS.
  ENDCASE.

**處理是否有帶RAW WAFER單價
  IF PFV_FUNCT = 'RAW_WAFER'.
    SELECT SINGLE * FROM  ZEXDT
                    WHERE VBELN   =  PFWA_ITEM-VBELN
                    AND   POSNR   =  PFV_POSNR
                    AND   CONSIGN <> ''.
    CHECK SY-SUBRC = 0.
    PFV_VALUE = 'X'.
  ENDIF.
**處理是否需要使用最高單價
  IF PFV_FUNCT = 'PROCESS'.
    SELECT SINGLE * FROM  ZEXDT
                    WHERE VBELN   =  PFWA_ITEM-VBELN
                    AND   POSNR   =  PFV_POSNR
                    AND   PCHARGE <> ''.
    CHECK SY-SUBRC = 0.
    PFV_VALUE = ZEXDT-REFPRICE.
  ENDIF.

ENDFORM.                    " IMEX_CHECK_OTHER_PRICE_RULE
*&---------------------------------------------------------------------*
*&      Form  GET_DN_ITEM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIPS  text
*      -->P_PF_ITEM  text
*----------------------------------------------------------------------*
FORM GET_DN_ITEM  TABLES   PF_LIPS_O STRUCTURE LIPS
                  USING    PFWA_ITEM STRUCTURE I_ITEM.
  DATA: PFV_VGBEL TYPE VBELN_VL,
        PFV_VGPOS TYPE POSNR_VL.
  CLEAR: PF_LIPS_O, PF_LIPS_O[], PFV_VGBEL, PFV_VGPOS.

  CASE PFWA_ITEM-ZTYPE.
    WHEN 'I'.
      PFV_VGBEL = PFWA_ITEM-VGBEL.
      PFV_VGPOS = PFWA_ITEM-VGPOS.
    WHEN 'F'.
      PFV_VGBEL = PFWA_ITEM-VBELN.
      PFV_VGPOS = PFWA_ITEM-UECHA.
    WHEN OTHERS.
  ENDCASE.
  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_LIPS_O FROM  LIPS
                                                        WHERE VBELN =   PFV_VGBEL
                                                        AND   UECHA =   PFV_VGPOS
                                                        AND   CHARG <>  ''.
ENDFORM.                    " GET_DN_ITEM
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_ITEM_CONSIGN_RECORDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM  text
*      <--P_PFV_ITEMS  text
*----------------------------------------------------------------------*
FORM IMEX_GET_ITEM_CONSIGN_RECORDS  TABLES   PF_ITEM_I   STRUCTURE I_ITEM
                                    USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                    CHANGING PFV_VALUE.
  DATA: PFV_CFLAG TYPE I,
        PFV_RECOS TYPE I.
  CLEAR: PFV_VALUE, PFV_CFLAG, PFV_RECOS.
  LOOP AT PF_ITEM_I WHERE VBELN = PFWA_HEAD_I-VBELN
                    AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
    ADD 1 TO PFV_RECOS.
    CHECK PF_ITEM_I-CONSI IS NOT INITIAL.
    ADD 1 TO PFV_CFLAG.
  ENDLOOP.

  CHECK PFV_CFLAG <> 0 AND
        PFV_CFLAG <  PFV_RECOS.
  LOOP AT PF_ITEM_I WHERE VBELN =  PFWA_HEAD_I-VBELN
                    AND   ZTYPE =  PFWA_HEAD_I-ZTYPE
                    AND   CONSI <> ''.
    CONCATENATE PFV_VALUE PF_ITEM_I-ITMNO
      INTO PFV_VALUE SEPARATED BY SPACE.
  ENDLOOP.
ENDFORM.                    " IMEX_GET_ITEM_CONSIGN_RECORDS
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_PROCESSING_CHARGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM  text
*      -->P_PF_HEAD  text
*----------------------------------------------------------------------*
FORM IMEX_GET_PROCESSING_CHARGE  TABLES  PF_ITEM   STRUCTURE I_ITEM
                                 USING   PFWA_HEAD STRUCTURE I_HEAD.
  DATA: PFV_PRICE TYPE NETPR.
  CHECK PFWA_HEAD-ZTYPE = 'I'.                  "I = Invoic(只有Invoice會有這種需求)
  LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
                  AND   ZTYPE = PFWA_HEAD-ZTYPE.
    PERFORM IMEX_CHECK_OTHER_PRICE_RULE USING     PF_ITEM
                                                  'PROCESS'
                                        CHANGING  PFV_PRICE.
    CHECK PFV_PRICE IS NOT INITIAL.

    IF PF_ITEM-CONSI IS NOT INITIAL.
*      PF_ITEM-PCUTP = PFV_PRICE - PF_ITEM-SCUTP.                             "D201201
      PF_ITEM-PCUTP = PFV_PRICE - ( PF_ITEM-SCUTP / PF_ITEM-SKPEI )."I201201
    ELSE.
*      PF_ITEM-PCUTP = PFV_PRICE - PF_ITEM-UNITP.                             "D201201
      PF_ITEM-PCUTP = PFV_PRICE - ( PF_ITEM-UNITP / PF_ITEM-KPEIN )."I201201
    ENDIF.
    PF_ITEM-PKPEI = 1.                                      "I201201
    PF_ITEM-PCKWE = PF_ITEM-PCUTP * PF_ITEM-DWEMN.
    MODIFY PF_ITEM.
  ENDLOOP.
ENDFORM.                    " IMEX_GET_PROCESSING_CHARGE
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_PI_FROM_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPD2_IO  text
*      -->P_PF_ZPD6_IO  text
*      <--P_I_ITEM_PIITEM  text
*----------------------------------------------------------------------*
*FORM GET_ITEM_PI_FROM_TABLE  TABLES   PF_ZPD2_I STRUCTURE ZPD2
*                                      PF_ZPD6_I STRUCTURE ZPD6
*                             USING    PFWA_ITEM     STRUCTURE I_ITEM
*                             CHANGING PFWA_ITEM_PI  STRUCTURE I_ITEM_PIITEM
*                                      PFV_UZPD2
*                                      PFV_UZPD6
*                                      PFV_GOING.
*  DATA: BEGIN OF PFWA_PUSE,
*          PVBEL     TYPE VBELN_VF,                                                                "PI No.
*          NETWR     TYPE NETWR,                                                                   "PI 餘額
*          TAXFG(01) TYPE C,
*        END OF PFWA_PUSE.
*  DATA: PFV_DENOT(10) TYPE  N,                                                                    "分母
*        PFV_MOLER(10) TYPE  N.                                                                    "分子
*  CLEAR:  PFWA_ITEM_PI-ERDAT, PFWA_ITEM_PI-ERZET, PFWA_ITEM_PI-PERFI, PFWA_ITEM_PI-DOWNP,
*          PFWA_ITEM_PI-FOAMT, PFWA_ITEM_PI-PITAX, PFWA_ITEM_PI-WAERK,                             "WA只可以清部份...不可以全清
*          PFV_UZPD2, PFV_UZPD6, PFWA_PUSE, PFV_DENOT, PFV_MOLER.
*  PFV_GOING = 'X'.                                                                                "假設進來這筆就是預收item
***在資料庫有值就用資料庫的...沒有再重新計算
*
*  READ TABLE PF_ZPD2_I WITH KEY VBELN = PFWA_ITEM_PI-VBELN.
*  IF SY-SUBRC = 0.
*    PFWA_ITEM_PI-PERFI = PF_ZPD2_I-PERFI.                                                         "proforma invoice No
*    PFWA_ITEM_PI-FOAMT = PF_ZPD2_I-FOAMT.                                                         "amount
*    PFWA_ITEM_PI-WAERK = PF_ZPD2_I-WAERK.                                                         "Currency
*    PERFORM GET_OLD_PI_NO USING     PF_ZPD2_I-PERFI
*                          CHANGING  PFWA_ITEM_PI-OPVBE.
*    READ TABLE PF_ZPD6_I WITH KEY VBELN = PFWA_ITEM_PI-VBELN.
*    IF SY-SUBRC = 0.
*      PFWA_ITEM_PI-PITAX = PF_ZPD6_I-FOAMT.                                                       "TAX
*    ENDIF.
*  ELSE.         "以下這段應該不會發生
*    PFV_UZPD2 = 'X'.
***找出預收單號
*    PERFORM GET_PROFORMA_NO     TABLES    I_VBFA
*                                USING     PFWA_ITEM_PI-AUBEL
*                                CHANGING  PFWA_PUSE-PVBEL.                                        "預收單號
**<-I171016
*    IF PFWA_PUSE-PVBEL IS INITIAL .                                                               "表示該item不使用預收款
*      CLEAR: PFV_GOING.
*      EXIT.
*    ENDIF.
**->I171016
***算出該PI還有多少餘額
*    PERFORM GET_PROFORMA_BALANCE_AMT TABLES   PF_ZPD2_I
*                                              PF_ZPD6_I
*                                     USING    PFWA_PUSE-PVBEL
*                                     CHANGING PFWA_PUSE-NETWR.
***查詢該扣抵的比例
*    PERFORM CHECK_PROFORMA_STATUS USING     PFWA_PUSE-PVBEL
*                                            'RATE'
*                                  CHANGING  PFV_DENOT                                             "分母
*                                            PFV_MOLER.                                            "分子
*
*
*    PFWA_ITEM_PI-PERFI = PFWA_PUSE-PVBEL.
*    PFWA_ITEM_PI-FOAMT = PFWA_ITEM-KWERT * PFV_MOLER / PFV_DENOT.
*    PFWA_ITEM_PI-PITAX = ( PFWA_ITEM-KWERT * PFWA_ITEM-KBETR / 100 ) * PFV_MOLER / PFV_DENOT.     "因為I_ITEM-KBETR是百分比
*    PFWA_ITEM_PI-WAERK = PFWA_ITEM-WAERK.
***如果ITEM金額>餘額的處理
*    IF PFWA_ITEM_PI-FOAMT > PFWA_PUSE-NETWR.
*      PFWA_ITEM_PI-FOAMT = PFWA_PUSE-NETWR.
*      CLEAR: PFWA_PUSE-NETWR, PFWA_ITEM_PI-PITAX.
*    ELSE.
*      PFWA_PUSE-NETWR = PFWA_PUSE-NETWR - PFWA_ITEM_PI-FOAMT.
*      IF PFWA_ITEM_PI-PITAX > PFWA_PUSE-NETWR.
*        PFWA_ITEM_PI-PITAX = PFWA_PUSE-NETWR.
*        CLEAR: PFWA_PUSE-NETWR.
*      ELSE.
*        PFWA_PUSE-NETWR = PFWA_PUSE-NETWR - PFWA_ITEM_PI-PITAX.
*      ENDIF.
*    ENDIF.
***有稅就表示要去維護ZPD6
*    IF PFWA_ITEM_PI-PITAX > 0.
*      PFV_UZPD6 = 'X'.
*    ENDIF.
*  ENDIF.
*  PERFORM GET_ITEM_PI_DOWNPAYMENT USING     PFWA_ITEM_PI-PERFI
*                                  CHANGING  PFWA_ITEM_PI-DOWNP.
*
*ENDFORM.                    " GET_ITEM_PI_FROM_TABLE
*&---------------------------------------------------------------------*
*&      Form  GET_PROFORMA_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_PFWA_ITEM_AUBEL  text
*      <--P_PFWA_PUSE_PVBEL  text
*----------------------------------------------------------------------*
FORM GET_PROFORMA_NO  TABLES   PF_VBFA_I STRUCTURE VBFA
                      USING    PFV_AUBEL
                      CHANGING PFV_PVBEL.
  CLEAR: PFV_PVBEL.
  READ TABLE PF_VBFA_I WITH KEY VBELV    = PFV_AUBEL
                                VBTYP_N  = 'U'.
  CHECK SY-SUBRC = 0.
  PFV_PVBEL = PF_VBFA_I-VBELN.
ENDFORM.                    " GET_PROFORMA_NO
*&---------------------------------------------------------------------*
*&      Form  GET_PROFORMA_BALANCE_AMT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPD2_I  text
*      -->P_PF_ZPD6_I  text
*      -->P_PFWA_PUSE_PVBEL  text
*      <--P_PFWA_PUSE_NETWR  text
*----------------------------------------------------------------------*
*FORM GET_PROFORMA_BALANCE_AMT  TABLES   PF_PD2_I STRUCTURE ZPD2
*                                        PF_PD6_I STRUCTURE ZPD6
*                               USING    PFV_PVBEL_I
*                               CHANGING PFV_NETWR.
*  DATA: PFV_USAMT TYPE NETWR,                                                                     "已使用金額加總
*        PFV_USTAX TYPE NETWR,                                                                     "已使用稅額加總
*        PFV_TTAMT TYPE NETWR.                                                                     "稅+金額的部份
*  CLEAR: PFV_NETWR, PFV_USAMT, PFV_USTAX.
*  PERFORM GET_BILLING_AMOUNT_ICU_TAX USING    PFV_PVBEL_I   "I170920
*                                     CHANGING PFV_TTAMT.
*  CHECK PFV_TTAMT > 0.
*  LOOP AT PF_PD2_I WHERE PERFI = PFV_PVBEL_I.
*    PFV_USAMT = PFV_USAMT + PF_PD2_I-FOAMT.
*  ENDLOOP.
*  LOOP AT PF_PD6_I WHERE PERFI = PFV_PVBEL_I.
*    PFV_USTAX = PFV_USTAX + PF_PD6_I-FOAMT.
*  ENDLOOP.
**  PFV_NETWR = VBRK-NETWR - PFV_USAMT - PFV_USTAX.                                                "D170920
*  PFV_NETWR = PFV_TTAMT - ( PFV_USAMT + PFV_USTAX ).        "I170920
*ENDFORM.                    " GET_PROFORMA_BALANCE_AMT
*&---------------------------------------------------------------------*
*&      Form  GET_BILLING_AMOUNT_ICU_TAX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VBRK_KNUMV  text
*      <--P_PFV_TXAMT  text
*----------------------------------------------------------------------*
FORM GET_BILLING_AMOUNT_ICU_TAX   USING    PFV_VBELN
                                  CHANGING PFV_VALUE.
  DATA: PF_KONV LIKE KONV OCCURS 0 WITH HEADER LINE.
  CLEAR: PFV_VALUE.
**未稅部份
  SELECT SINGLE * FROM  VBRK
                  WHERE VBELN = PFV_VBELN.
  CHECK SY-SUBRC = 0.
  PFV_VALUE = VBRK-NETWR.
**稅金部份
  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_KONV  FROM  KONV
                                                       WHERE KNUMV = VBRK-KNUMV
                                                       AND   KSCHL = 'MWST'.
  CHECK PF_KONV[] IS NOT INITIAL.
  LOOP AT PF_KONV.
    PFV_VALUE = PFV_VALUE + PF_KONV-KWERT.
  ENDLOOP.
ENDFORM.                    " GET_BILLING_TAX_AMOUNT

*&---------------------------------------------------------------------*
*&      Form  IMEX_COVERT_TO_LOCL_CURRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM IMEX_COVERT_TO_LOCL_CURRY .
**單價不轉換成db格式
  DATA: PFV_KURRF TYPE KURRF.

  LOOP AT I_HEAD WHERE SHTWD IS NOT INITIAL.
    PERFORM GET_INVOICE_EXCHANGE_RATE USING     I_HEAD
                                      CHANGING  PFV_KURRF.
    LOOP AT I_ITEM WHERE VBELN = I_HEAD-VBELN
                   AND   ZTYPE = I_HEAD-ZTYPE.
      I_ITEM-WAERK = 'TWD'.
**單價
      PERFORM GET_LOCLCURR_VALUE USING    PFV_KURRF
                                          I_ITEM-WAERK
                                 CHANGING I_ITEM-KPEIN
                                          I_ITEM-UNITP.
*       PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
**                                              'X'           "決定是否轉成db格式(TWD 123==>1.23)
*                                             1
*                                    CHANGING I_ITEM-UNITP.

**小計
      PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
                                            1
                                   CHANGING I_ITEM-KWERT.
**Service Charge
      PERFORM GET_LOCLCURR_VALUE USING    PFV_KURRF
                                          I_ITEM-WAERK
                                 CHANGING I_ITEM-SKPEI
                                          I_ITEM-SCUTP.
*      PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
*                                            I_ITEM-KPEIN
*                                   CHANGING I_ITEM-SCUTP.
**Service Charge小計
      PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
                                            1
                                   CHANGING I_ITEM-SCKWE.
**Processing Charge
      PERFORM GET_LOCLCURR_VALUE USING    PFV_KURRF
                                          I_ITEM-WAERK
                                 CHANGING I_ITEM-PKPEI
                                          I_ITEM-PCUTP.
*      PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
*                                            1
*                                   CHANGING I_ITEM-PCUTP.
**Processing Charge小計
      PERFORM GET_LOCL_CURRY_VALUE USING    PFV_KURRF
                                            1
                                   CHANGING I_ITEM-PCKWE.
*      I_ITEM-KPEIN = 1.                                   "如果轉換成台幣就直接指定1,若有台幣小數位需要重新思考
      MODIFY I_ITEM.
    ENDLOOP.


    LOOP AT I_ITEM_TO WHERE VBELN = I_HEAD-VBELN
                      AND   ZTYPE = I_HEAD-ZTYPE.
      I_ITEM_TO-WAERK = 'TWD'.
      MODIFY I_ITEM_TO.
      CHECK I_ITEM_TO-ZTYPE = 'I'.                       "只有Invoice才需要下面的動作
      CLEAR: I_ITEM_TO-IDISK, I_ITEM_TO-HDISK, I_ITEM_TO-SUBTO,
             I_ITEM_TO-TAXAM, I_ITEM_TO-TBRGE, I_ITEM_TO-TOTAL.
      LOOP AT I_ITEM WHERE VBELN =  I_ITEM_TO-VBELN
                     AND   ZTYPE =  I_ITEM_TO-ZTYPE
                     AND   PSTYV <> 'TANN'.                 "I140424
        I_ITEM_TO-IDISK = I_ITEM_TO-IDISK + I_ITEM-KBET1.
        I_ITEM_TO-HDISK = I_ITEM_TO-HDISK + I_ITEM-KBET1.
        I_ITEM_TO-SUBTO = I_ITEM_TO-SUBTO + I_ITEM-KWERT + I_ITEM-SCKWE + I_ITEM-PCKWE.
        I_ITEM_TO-TAXAM = ( ( I_ITEM-KWERT + I_ITEM-SCKWE ) * I_ITEM-KBETR / 100 ) + I_ITEM_TO-TAXAM.
      ENDLOOP.
      I_ITEM_TO-TBRGE = '0.00'.
      I_ITEM_TO-TOTAL = I_ITEM_TO-SUBTO + I_ITEM_TO-TAXAM.
      MODIFY I_ITEM_TO.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " IMEX_COVERT_TO_LOCL_CURRY
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_LOCL_CURR_SHOWFLAG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD_ZTYPE  text
*      <--P_I_HEAD_SHTWD  text
*----------------------------------------------------------------------*
FORM IMEX_GET_LOCL_CURR_SHOWFLAG  USING    PFV_ZTYPE
                                  CHANGING PFV_VALUE.
  CLEAR: PFV_VALUE.
  CHECK PFV_ZTYPE = 'I' OR
        PFV_ZTYPE = 'F'.
  PFV_VALUE = P_TWDVL.
ENDFORM.                    " IMEX_GET_LOCL_CURR_SHOWFLAG
*&---------------------------------------------------------------------*
*&      Form  GET_INVOICE_EXCHANGE_RATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      <--P_PFV_KURRF  text
*----------------------------------------------------------------------*
FORM GET_INVOICE_EXCHANGE_RATE  USING    PFWA_HEAD STRUCTURE I_HEAD
                                CHANGING PFV_KURRF_O.
  DATA: PFWA_VBRK LIKE VBRK,
        PFWA_LIKP LIKE LIKP,
        PFV_TPRAT TYPE KURST.


  CLEAR: PFV_KURRF_O, PFV_TPRAT.
  CASE PFWA_HEAD-ZTYPE.
    WHEN 'I'.
      PERFORM GET_WORKAREA_VBRK USING     PFWA_HEAD-VBELN
                                CHANGING  PFWA_VBRK.
      CHECK PFWA_VBRK IS NOT INITIAL.
      PFV_KURRF_O = PFWA_VBRK-KURRF.
    WHEN 'F'.
      PERFORM GET_WORKAREA_LIKP USING     PFWA_HEAD-VBELN
                                CHANGING  PFWA_LIKP.
      CHECK PFWA_LIKP IS NOT INITIAL.
      IF PFWA_LIKP-WADAT_IST >=  '20171101' AND
         PFWA_LIKP-ZBONDTY   <>  'Y'.
        PFV_TPRAT = 'S'.
      ELSE.
        PFV_TPRAT = 'C'.
      ENDIF.

      CALL FUNCTION 'READ_EXCHANGE_RATE'
        EXPORTING
*         CLIENT                  = SY-MANDT
          DATE                    = PFWA_LIKP-WADAT_IST
          FOREIGN_CURRENCY        = 'USD'
          LOCAL_CURRENCY          = 'TWD'
          TYPE_OF_RATE            = PFV_TPRAT
*         EXACT_DATE              = ' '
        IMPORTING
          EXCHANGE_RATE           = PFV_KURRF_O
*         FOREIGN_FACTOR          =
*         LOCAL_FACTOR            =
*         VALID_FROM_DATE         =
*         DERIVED_RATE_TYPE       =
*         FIXED_RATE              =
*         OLDEST_RATE_FROM        =
*       EXCEPTIONS
*         NO_RATE_FOUND           = 1
*         NO_FACTORS_FOUND        = 2
*         NO_SPREAD_FOUND         = 3
*         DERIVED_2_TIMES         = 4
*         OVERFLOW                = 5
*         ZERO_RATE               = 6
*         OTHERS                  = 7
                .
      IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_INVOICE_EXCHANGE_RATE
*&---------------------------------------------------------------------*
*&      Form  GET_LOCL_CURRY_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_KURRF  text
*      <--P_I_ITEM_UNITP  text
*----------------------------------------------------------------------*
FORM GET_LOCL_CURRY_VALUE  USING    PFV_KURRF_I
                                    PFV_KPEIN_I
                           CHANGING PFV_VALUE_IO.
  DATA: PFV_KPEIN TYPE KPEIN.

  CLEAR: PFV_KPEIN.
  CHECK PFV_VALUE_IO IS NOT INITIAL.
  PFV_KPEIN = PFV_KPEIN_I.
  IF PFV_KPEIN IS INITIAL.
    PFV_KPEIN = 1.
  ENDIF.
  PFV_VALUE_IO = ( PFV_VALUE_IO / PFV_KPEIN ) * PFV_KURRF_I.
*  CHECK PFV_DBMOD IS NOT INITIAL.
  PERFORM CURRENCY_CONVERT USING    'TWD'
                           CHANGING PFV_VALUE_IO.
ENDFORM.                    " GET_LOCL_CURRY_VALUE
*&---------------------------------------------------------------------*
*&      Form  SPECIAL_RULE_FOR_ITEM_TOTAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM  text
*      -->P_PFWA_HEAD  text
*      <--P_I_ITEM_TO_GDPWO  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_TOTAL  TABLES   PF_ITEM_I STRUCTURE I_ITEM
                             USING    PFWA_HEAD_I STRUCTURE I_HEAD
                             CHANGING PFV_GDPWO.
  CHECK PFWA_HEAD_I-ZTYPE = 'I'.                "I = Invoice

  CHECK PFWA_HEAD_I-KUNAG = '0000003653'.       "上海凱虹
  CLEAR: PFV_GDPWO.
  LOOP AT PF_ITEM_I WHERE VBELN =  PFWA_HEAD_I-VBELN
                    AND   ZTYPE =  PFWA_HEAD_I-ZTYPE.
    CLEAR: ZSDA02.
    SELECT SINGLE * FROM  ZSDA02
                    WHERE KDMAT =   PF_ITEM_I-MATNR+01(05)
                    AND   KUNNR =   PF_ITEM_I-KUNAG
                    AND   ZBILL <>  ''.
    CHECK SY-SUBRC = 0.
    PFV_GDPWO = PFV_GDPWO + ZSDA02-GDPWO * PF_ITEM_I-DWEMN.
  ENDLOOP.
ENDFORM.                    " SPECIAL_RULE_FOR_ITEM_TOTAL
*&---------------------------------------------------------------------*
*&      Form  GET_BILLING_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_HEAD  text
*----------------------------------------------------------------------*
FORM GET_BILLING_NO TABLES   PF_VBFA_I    STRUCTURE VBFA
                    CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFV_CANCL(01) TYPE C.

  CHECK PFWA_HEAD_IO-ZTYPE = 'P'.
  LOOP AT PF_VBFA_I WHERE VBELV    = PFWA_HEAD_IO-VGBEL
                    AND   VBTYP_N  = 'M'.
    PERFORM CHECK_BILLING_CANCELED USING      PF_VBFA_I-VBELN
                                   CHANGING   PFV_CANCL.
    CHECK PFV_CANCL IS INITIAL.
    PFWA_HEAD_IO-VFVBL  = I_VBFA-VBELN.
    EXIT.
  ENDLOOP.
ENDFORM.                    " GET_BILLING_NO
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_LIPS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM_VGBEL  text
*      -->P_PF_ITEM_POSNR  text
*      <--P_PFWA_LIPS  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_LIPS  USING    PFV_VGBEL_I
                                 PFV_VGPOS_I
                        CHANGING PFWA_LIPS_O STRUCTURE LIPS.
  CLEAR: PFWA_LIPS_O.
  IF PFV_VGPOS_I = ''.      "不確定INITIAL是否等於 ''
    SELECT SINGLE *
      INTO CORRESPONDING FIELDS OF PFWA_LIPS_O  FROM  LIPS
                                                WHERE VBELN = PFV_VGBEL_I.
    EXIT.
  ENDIF.

  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_LIPS_O  FROM  LIPS
                                              WHERE VBELN = PFV_VGBEL_I
                                              AND   POSNR = PFV_VGPOS_I.
ENDFORM.                    " GET_WORKAREA_LIPS
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBAP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_LIPS_VGBEL  text
*      -->P_PFWA_LIPS_VGPOS  text
*      <--P_PFWA_VBAP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBAP  USING    PFV_AUBEL_I
                                 PFV_AUPOS_I
                        CHANGING PFWA_VBAP_O STRUCTURE VBAP.
  CLEAR: PFWA_VBAP_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VBAP_O  FROM  VBAP
                                              WHERE VBELN = PFV_AUBEL_I
                                              AND   POSNR = PFV_AUPOS_I.
ENDFORM.                    " GET_WORKAREA_VBAP
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_NAME1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_BKUNN  text
*      <--P_R_NAME1  text
*----------------------------------------------------------------------*
FORM GET_CUST_NAME1  USING    PFV_KUNAG
                     CHANGING PFV_NAME1.
  DATA: PFWA_KNA1 LIKE KNA1.
  CLEAR: PFV_NAME1.
  PERFORM GET_WORKAREA_KNA1 USING     PFV_KUNAG
                            CHANGING  PFWA_KNA1.
  CHECK PFWA_KNA1 IS NOT INITIAL.
  PFV_NAME1 = PFWA_KNA1-NAME1.
ENDFORM.                    " GET_CUST_NAME1
*&---------------------------------------------------------------------*
*&      Form  SCREEN_MODIFY_MAIL_FUNCTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SCREEN_MODIFY_MAIL_FUNCTION .
  DATA: PFV_INPUT TYPE C.

  CLEAR: PFV_INPUT.



**1.還沒有選資料就不要顯示空白格
  IF MWA_HEAD-TITLE IS INITIAL.
    LOOP AT SCREEN.
      PERFORM CONTROL_SCREEN_ACTIVE_BY_GROUP USING 2 'DAT' 0.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
**2.只有Packing及有SHIP-TO值時才要打開相關欄位
**SHIP-TO資料不要顯示
  IF MWA_HEAD-ZTYPE <> 'P' OR
     ( MWA_HEAD-ZTYPE = 'P' AND MWA_HEAD-KUNNR IS INITIAL ).
    LOOP AT SCREEN.
      PERFORM CONTROL_SCREEN_ACTIVE_BY_GROUP USING 1 'SHP' 0.
      MODIFY SCREEN.
    ENDLOOP.
**MAIL的TABLE CONTROL不要出現SHIP欄位
    LOOP AT TC300_MAIL-COLS INTO WA_COLS.
      CHECK WA_COLS-INDEX = 3.
      WA_COLS-INVISIBLE = 1.
      MODIFY TC300_MAIL-COLS FROM WA_COLS.
    ENDLOOP.
  ENDIF.

  IF MWA_HEAD-KUNNR IS NOT INITIAL AND
     MWA_HEAD-ZTYPE = 'P'.
**MAIL的TABLE CONTROL要出現SHIP欄位
    LOOP AT TC300_MAIL-COLS INTO WA_COLS.
      CHECK WA_COLS-INDEX = 3.
      WA_COLS-INVISIBLE = 0.
      MODIFY TC300_MAIL-COLS FROM WA_COLS.
    ENDLOOP.
  ENDIF.
**3.如果不是權限最大的人不要顯示Sales Org欄位
  IF P_VKORG IS NOT INITIAL.
    LOOP AT TC300_MAIL-COLS INTO WA_COLS.
      CHECK  WA_COLS-INDEX = 4.
      WA_COLS-INVISIBLE = 1.
      MODIFY TC300_MAIL-COLS FROM WA_COLS.
    ENDLOOP.
  ENDIF.
**4.沒有MAIL清單,欄位就設成不可以輸入
  IF M_ZSDEL[] IS NOT INITIAL.
    PFV_INPUT = 1.
  ELSE.
    PFV_INPUT = 0.
  ENDIF.
  LOOP AT TC300_MAIL-COLS INTO WA_COLS.
    CHECK  WA_COLS-INDEX = 1 OR
           WA_COLS-INDEX = 2 OR
           WA_COLS-INDEX = 3 OR
           WA_COLS-INDEX = 4.
    WA_COLS-SCREEN-INPUT = PFV_INPUT.
    MODIFY TC300_MAIL-COLS FROM WA_COLS.
  ENDLOOP.
**5.其他欄位的顯示與否BY 單別
  IF MWA_HEAD-ZTYPE = 'P'.
    PERFORM SCREEN_MODIFY_SMAIL_BY_SHIPTO USING  MWA_HEAD-KUNAG.
  ELSE.
    PERFORM SCREEN_MODIFY USING 'GENE'.         "上一頁/下一頁的鍵不顯示
  ENDIF.
ENDFORM.                    " SCREEN_MODIFY_MAIL_FUNCTION
*&---------------------------------------------------------------------*
*&      Form  SEND_DOC_TO_OUTSIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SEND_DOC_TO_OUTSIDE USING  PFV_FUNCT
                                PFV_ZAUTO
                                PFV_JTYPE.                "外部系統CALL的FLAG
  DATA: PF_ATTCH      LIKE SOLI   OCCURS 0 WITH HEADER LINE,          "MAIL附件
        PF_PACKE      LIKE SOXPL  OCCURS 0 WITH HEADER LINE.

  DATA: WA_ZSD133 LIKE ZSD133.
  DATA: BEGIN OF W_EMSG OCCURS 0,
    TYPE(1),
    LINE(80),
   END OF W_EMSG.
  FIELD-SYMBOLS: <VALUE1> TYPE ANY.
  DATA: WV_PRONAME(30).
  RANGES: WR_VBELN FOR LIKP-VBELN.

**處理FTP的部份
  IF PFV_FUNCT = 'FTP'.
**手動時如果有傳送過要POPUP訊息(只有手動送FTP才會進來)/如果是AUTO只留沒有SEND過的
    PERFORM CHECK_FTP_RESEND TABLES S_HEAD
                             USING  PFV_ZAUTO.

    LOOP AT S_HEAD WHERE ZFSET IS INITIAL.
      PERFORM PREPARE_DATA USING 'SEND'.
      PERFORM SEND_TO_SMARTFORM USING 'FTP'
                                      ''.
      PERFORM UPDATE_INFO_TO_TABLE USING 'FTP'.
      PERFORM UPDATE_INTERNAL_TABLE USING 'FTP'.
    ENDLOOP.

  ENDIF.
**處理MAIL的部份
  IF PFV_FUNCT = 'MAIL'.
    PERFORM CHECK_MAIL_RESEND TABLES S_HEAD.

    CLEAR: TA_PACKING_LIST, TA_PACKING_LIST[], TA_CONTENTS_BIN, TA_CONTENTS_BIN[], TA_CONTENTS_TXT, TA_CONTENTS_TXT[].
    READ TABLE S_HEAD WITH KEY ZMSET = ''.
    CHECK SY-SUBRC = 0.

    PERFORM GET_MAIL_CONTENT.
**處理寄pdf的部份
    IF MC_CMPDF IS NOT INITIAL.
      CLEAR: I_HEAD, I_HEAD[].
      APPEND LINES OF S_HEAD TO I_HEAD.
      PERFORM SEND_TO_SMARTFORM USING 'EML'
                                      ''.
      PERFORM SEND_MAIL_TO_CUST USING MC_EXCEL.
    ELSE.
**一個一個的PDF檔(要排除寄EXCEL檔)
      LOOP AT S_HEAD WHERE ZMSET IS INITIAL.
        CHECK MC_EXCEL IS INITIAL.
        CLEAR: I_HEAD, I_HEAD[].
        MOVE-CORRESPONDING  S_HEAD TO I_HEAD.
        APPEND I_HEAD.
        PERFORM SEND_TO_SMARTFORM USING 'EML'
                                        ''.
      ENDLOOP.
      PERFORM SEND_MAIL_TO_CUST USING MC_EXCEL.
    ENDIF.
**處理EXCEL的部份
    IF MC_EXCEL IS NOT INITIAL.
      PERFORM GET_MAIL_ATT_EXCEL  TABLES  S_HEAD
                                          I_ITEM
                                          PF_ATTCH
                                          PF_PACKE.
**寄送MAIL出去
      PERFORM SEND_MAIL_TO_CUST_EXCEL TABLES PF_ATTCH
                                             PF_PACKE.
    ENDIF.


    LOOP AT S_HEAD WHERE ZMSET IS INITIAL.
      PERFORM UPDATE_INFO_TO_TABLE  USING 'MAIL'.
      PERFORM UPDATE_INTERNAL_TABLE USING 'MAIL'.
    ENDLOOP.

** 12 吋 特定客戶寄送Packing excel
    READ TABLE S_HEAD WITH KEY ZTYPE = 'P'.
    CHECK SY-SUBRC = 0.
    CHECK S_HEAD-VKORG = 'PSC1'.

    SELECT SINGLE * INTO WA_ZSD133 FROM ZSD133
     WHERE KUNNR = S_HEAD-KUNAG.
    IF SY-SUBRC = 0 AND WA_ZSD133-CPROG <> ''.
*--collect
      LOOP AT S_HEAD WHERE ZTYPE = 'P'.
        WR_VBELN-SIGN = 'I'.
        WR_VBELN-OPTION = 'EQ'.
        WR_VBELN-LOW = S_HEAD-VBELN.
        APPEND WR_VBELN.
      ENDLOOP.

      EXPORT M_ZSDEL TO MEMORY ID 'ZSD_RT002_SCEXCEL'.
*-- 依客戶submit 不同程式
      IF NOT WR_VBELN[] IS INITIAL.
        WV_PRONAME = WA_ZSD133-CPROG.
        SUBMIT  (WV_PRONAME) WITH S_VBELN IN WR_VBELN
               WITH P_CALLRT EQ 'X'
               WITH P_ACT    EQ 'M'              "Mail excel for customers
               WITH P_MLTL   EQ MWA_HEAD-MTITL   "I120919  mail title
           AND RETURN.

        IMPORT W_EMSG FROM MEMORY ID 'WA_ZSD133_RMSG'.
        FREE MEMORY ID 'WA_ZSD133_RMSG'.
        READ TABLE W_EMSG INDEX 1.
        MESSAGE S000 WITH W_EMSG-LINE.
      ELSE.
        MESSAGE E000 WITH 'Error for send packing !!'.
      ENDIF.
    ENDIF.

  ENDIF.   "end of MAIL


ENDFORM.                    " SEND_DOC_TO_OUTSIDE
*&---------------------------------------------------------------------*
*&      Form  GET_MAIL_ATT_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ATTCH  text
*      -->P_S_HEAD  text
*      -->P_ENDIF  text
*----------------------------------------------------------------------*
FORM GET_MAIL_ATT_EXCEL   TABLES   PF_HEAD_I   STRUCTURE I_HEAD
                                   PF_ITEM_I   STRUCTURE I_ITEM
                                   PF_DATA_IO  STRUCTURE SOLI
                                   PF_PACK_IO  STRUCTURE SOXPL.

  DATA: BEGIN OF PF_XLSX1 OCCURS 0,                                                               "長度有些是依表頭字數決定
          VGBEL(10)   TYPE C,
          ITMNO(06)   TYPE C,
          KUNAG(10)   TYPE C,
          NAME1(35)   TYPE C,
          KUNNR(10)   TYPE C,
          NAME2(35)   TYPE C,
          CTNNO(10)   TYPE C,
          MATNR(18)   TYPE C,
          POSTX(40)   TYPE C,
          KDMAT(35)   TYPE C,
          DWENM(05)   TYPE C,
          CHARG(10)   TYPE C,
          DCODE(15)   TYPE C,
          KURKI(10)   TYPE C,
          LOTNO(10)   TYPE C,
          BSTKD(35)   TYPE C,
          AUBEL(11)   TYPE C,
          WAFER(150)  TYPE C,
        END OF PF_XLSX1.

  DATA: BEGIN OF PF_XLSX2 OCCURS 0,                                                               "長度有些是依表頭字數決定
          VGBEL(10)   TYPE C,
          CASNO(07)   TYPE C,
          BRGEW(18)   TYPE C,
          NTGEW(18)   TYPE C,
          GEWEI(14)   TYPE C,
          LENTH(10)   TYPE C,
          BRATH(10)   TYPE C,
          HIGHT(10)   TYPE C,
          UNITV(14)   TYPE C,
        END OF PF_XLSX2.

  DATA: PF_ATTM         LIKE SOLI  OCCURS 0 WITH HEADER LINE,
        PF_PACK         LIKE SOXPL OCCURS 0 WITH HEADER LINE,
        PFV_VALUE_X     TYPE C,                 "接值用
        PFV_FNAME       TYPE SO_OBJ_NAM,
        PFV_LINES       TYPE I,
        PFV_CTNNO(10)   TYPE C,
        PFV_CASNO(10)   TYPE C,
        PFV_LENTH(10)   TYPE C,
        PFV_BRATH(10)   TYPE C,
        PFV_HIGHT(10)   TYPE C.

  CHECK PF_ITEM_I[] IS NOT INITIAL.
  LOOP AT PF_HEAD_I WHERE ZMSET IS INITIAL.
    CLEAR: PF_XLSX1, PF_XLSX1[], PF_XLSX2, PF_XLSX2[],
           PF_ATTM, PF_ATTM[], PF_PACK, PF_PACK[], PFV_FNAME, PFV_LINES.
**取得表頭
    PF_XLSX1-VGBEL = 'Delivery'.
    PF_XLSX1-ITMNO = 'Item'.
    PF_XLSX1-KUNAG = 'Sold-to'.
    PF_XLSX1-NAME1 = 'Sold-to Name'.
    PF_XLSX1-KUNNR = 'Ship-to'.
    PF_XLSX1-NAME2 = 'Ship-to Name'.
    PF_XLSX1-CTNNO = 'Ctn No'.
    PF_XLSX1-MATNR = 'MAXchip Part no'.
    PF_XLSX1-POSTX = 'Customer Part ID'.
    PF_XLSX1-KDMAT = 'Customer Part ID(2)'.
    PF_XLSX1-DWENM = 'Qty'.
    PF_XLSX1-CHARG = 'Key No'.
    PF_XLSX1-DCODE = 'Date Code'.
    PF_XLSX1-KURKI = 'Kuraki'.
    PF_XLSX1-LOTNO = 'Lot No'.
    PF_XLSX1-BSTKD = 'PO No'.
    PF_XLSX1-AUBEL = 'Sales Order'.
    PF_XLSX1-WAFER = 'Wafer ID'.
    APPEND PF_XLSX1.
    PF_XLSX2-VGBEL = 'Delivery'.
    PF_XLSX2-CASNO = 'Case No'.
    PF_XLSX2-BRGEW = 'Gross Weight'.
    PF_XLSX2-NTGEW = 'Net Weight'.
    PF_XLSX2-GEWEI = 'Unit of Weight'.
    PF_XLSX2-LENTH = 'Length'.
    PF_XLSX2-BRATH = 'Breadth'.
    PF_XLSX2-HIGHT = 'Height'.
    PF_XLSX2-UNITV = 'Unit of Volume'.
    APPEND PF_XLSX2.
    CLEAR: PF_XLSX1, PF_XLSX2.

    LOOP AT PF_ITEM_I WHERE VBELN = PF_HEAD_I-VBELN
                      AND   ZTYPE = PF_HEAD_I-ZTYPE.
      IF PF_ITEM_I-CTNNO IS NOT INITIAL.
        CONCATENATE 'C/NO:' PF_ITEM_I-CTNNO
          INTO PFV_CTNNO.
      ENDIF.

      WRITE: PF_ITEM_I-VBELN TO PF_XLSX1-VGBEL,
             PF_ITEM_I-ITMNO TO PF_XLSX1-ITMNO,
             PF_HEAD_I-KUNAG TO PF_XLSX1-KUNAG,
             PF_HEAD_I-KUNNR TO PF_XLSX1-KUNNR,
             PF_ITEM_I-AUBEL TO PF_XLSX1-AUBEL,
             PF_ITEM_I-DWEMN UNIT PF_ITEM_I-WEMEH TO PF_XLSX1-DWENM.
*      PF_XLSX1-CTNNO = PF_ITEM_I-CTNNO.
      PF_XLSX1-CTNNO = PFV_CTNNO.
      PF_XLSX1-MATNR = PF_ITEM_I-MATNR.
      PF_XLSX1-KDMAT = PF_ITEM_I-KDMAT.
      PF_XLSX1-CHARG = PF_ITEM_I-CHARG.
      PF_XLSX1-DCODE = PF_ITEM_I-DCODE.
      PF_XLSX1-LOTNO = PF_ITEM_I-LOTNO.
      PF_XLSX1-BSTKD = PF_ITEM_I-BSTKD.
      PF_XLSX1-KURKI = ''.


      PERFORM GET_CUST_NAME1 USING    PF_HEAD_I-KUNAG
                             CHANGING PF_XLSX1-NAME1.
      PERFORM GET_CUST_NAME1 USING    PF_HEAD_I-KUNNR
                             CHANGING PF_XLSX1-NAME2.
      PERFORM GET_CUST_MATERIAL_NO USING    PF_ITEM_I-AUBEL
                                            PF_ITEM_I-AUPOS
                                   CHANGING PF_XLSX1-POSTX.
      PERFORM  GET_WAFER_ID_LIST USING      PF_ITEM_I-CHARG
                                            PF_ITEM_I-MATNR
                                 CHANGING   PF_XLSX1-WAFER.
      CONCATENATE 'ID:' PF_XLSX1-WAFER
        INTO PF_XLSX1-WAFER SEPARATED BY SPACE.

      WRITE:  PF_ITEM_I-VBELN TO PF_XLSX2-VGBEL,
              PF_ITEM_I-GEWEI TO PF_XLSX2-GEWEI,
              PF_ITEM_I-DBRGE UNIT PF_ITEM_I-GEWEI TO PF_XLSX2-BRGEW,
              PF_ITEM_I-DNTGE UNIT PF_ITEM_I-GEWEI TO PF_XLSX2-NTGEW.


      IF PF_ITEM_I-CTNNO IS NOT INITIAL.                                                            "第一筆會有值,第二筆會是空值
        SPLIT: PF_ITEM_I-CTNNO AT '/' INTO PF_XLSX2-CASNO PFV_VALUE_X,
               PF_ITEM_I-CDIME AT 'X' INTO PF_XLSX2-LENTH PF_XLSX2-BRATH PF_XLSX2-HIGHT.
        PFV_CASNO = PF_XLSX2-CASNO.
        PFV_LENTH = PF_XLSX2-LENTH.
        PFV_BRATH = PF_XLSX2-BRATH.
        PFV_HIGHT = PF_XLSX2-HIGHT.
      ELSE.
        PF_XLSX2-CASNO = PFV_CASNO.
        PF_XLSX2-LENTH = PFV_LENTH.
        PF_XLSX2-BRATH = PFV_BRATH.
        PF_XLSX2-HIGHT = PFV_HIGHT.
      ENDIF.

      CONDENSE: PF_XLSX2-CASNO, PF_XLSX2-LENTH, PF_XLSX2-BRATH, PF_XLSX2-HIGHT.
      PF_XLSX2-UNITV = 'CM3'.
      APPEND: PF_XLSX1, PF_XLSX2.
      CLEAR:  PF_XLSX1, PF_XLSX2.
    ENDLOOP.


    LOOP AT PF_XLSX1.
      CONCATENATE PF_XLSX1-VGBEL PF_XLSX1-ITMNO PF_XLSX1-KUNAG PF_XLSX1-NAME1 PF_XLSX1-KUNNR PF_XLSX1-NAME2
                  PF_XLSX1-CTNNO PF_XLSX1-MATNR PF_XLSX1-POSTX PF_XLSX1-KDMAT PF_XLSX1-DWENM PF_XLSX1-CHARG
                  PF_XLSX1-DCODE PF_XLSX1-KURKI PF_XLSX1-LOTNO PF_XLSX1-BSTKD PF_XLSX1-AUBEL PF_XLSX1-WAFER
             INTO PF_ATTM SEPARATED BY C_TAB.
      CONCATENATE PF_ATTM C_NEWL
        INTO PF_ATTM.
*      IF SY-TABIX <> 1.
*        CONCATENATE C_NEWL PF_ATTM INTO PF_ATTM.
*      ENDIF.
      APPEND PF_ATTM.
      CLEAR: PF_ATTM.
    ENDLOOP.

    DO 3 TIMES.
      PF_ATTM = C_NEWL.
*      CONCATENATE '' C_NEWL
*        INTO PF_ATTM.
      APPEND PF_ATTM.
      CLEAR: PF_ATTM.
    ENDDO.

    LOOP AT PF_XLSX2.
      CONCATENATE PF_XLSX2-VGBEL PF_XLSX2-CASNO PF_XLSX2-BRGEW PF_XLSX2-NTGEW PF_XLSX2-GEWEI
                  PF_XLSX2-LENTH PF_XLSX2-BRATH PF_XLSX2-HIGHT PF_XLSX2-UNITV
             INTO PF_ATTM SEPARATED BY C_TAB.
      CONCATENATE PF_ATTM C_NEWL
        INTO PF_ATTM.
      APPEND PF_ATTM.
      CLEAR: PF_ATTM.
    ENDLOOP.

    DESCRIBE TABLE PF_ATTM LINES PFV_LINES.
    WRITE PF_HEAD_I-VBELN TO PFV_FNAME.
    CONCATENATE 'PL#' PFV_FNAME
      INTO PFV_FNAME.

    PF_PACK-TRANSF_BIN = ''.                    "若要傳BINARY FORMAT, 需設為'X'
    PF_PACK-BODY_START = 1.                     "附加檔案從第1行開始
    PF_PACK-BODY_NUM   = PFV_LINES.             "共讀取TAB_LIN行
    PF_PACK-OBJTP      = 'xls'.                 "附加檔案類型,如果是TXT檔,一定要用'RAW'
    PF_PACK-OBJNAM     = PFV_FNAME.             "附加檔案檔名
    PF_PACK-OBJLEN     = PFV_LINES * 255.       "因每行最多可為255 CHAR, 故SIZE設為行數*255
    APPEND PF_PACK.

    APPEND LINES OF PF_ATTM TO PF_DATA_IO.
    APPEND LINES OF PF_PACK TO PF_PACK_IO.
  ENDLOOP.

ENDFORM.                    " GET_MAIL_ATT_EXCEL
*&---------------------------------------------------------------------*
*&      Form  GET_CUST_MATERIAL_NO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM_I_AUBEL  text
*      -->P_PF_ITEM_I_AUPOS  text
*      <--P_PF_XLSX1_POSTX  text
*----------------------------------------------------------------------*
FORM GET_CUST_MATERIAL_NO  USING    PFV_AUBEL
                                    PFV_AUPOS
                           CHANGING PFV_POSTX.
  DATA: PFWA_VBAP       LIKE VBAP.
  CLEAR: PFV_POSTX.

  PERFORM GET_WORKAREA_VBAP USING     PFV_AUBEL
                                      PFV_AUPOS
                            CHANGING  PFWA_VBAP.
  CHECK PFWA_VBAP IS NOT INITIAL.
  PFV_POSTX = PFWA_VBAP-ZPOSTX.
ENDFORM.                    " GET_CUST_MATERIAL_NO
*&---------------------------------------------------------------------*
*&      Form  BUTTON_FUNCTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM BUTTON_FUNCTION .
*  CHECK SY-UCOMM = 'BUT'.
  CASE SY-UCOMM.
    WHEN 'BUT'.
      CLEAR: I_ZSDA02, I_ZSDA02[].
      SELECT * INTO CORRESPONDING FIELDS OF TABLE I_ZSDA02 FROM ZSDA02.
*      PERFORM GET_CORRECT_VALUE_TO_SHOW.       "D190905

      PERFORM ALV_FIELD_STYLE_DEFINE USING SY-UCOMM.
      PERFORM ALV_DEFINE_HEADER_LINE USING SY-UCOMM.
      PERFORM ALV_DEFINE_LAYOUT.
      PERFORM ALV_PRINT              USING SY-UCOMM.
    WHEN 'FINV'.
      CALL TRANSACTION 'ZSD0297'.
  ENDCASE.
ENDFORM.                    " BUTTON_FUNCTION
*&---------------------------------------------------------------------*
*&      Form  GET_NT_USERNAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PF_USCI_UNAME  text
*----------------------------------------------------------------------*
FORM GET_NT_USERNAME  CHANGING PFV_UNAME_O.
  CLEAR: PFV_UNAME_O.
  DATA: PFV_NTNME TYPE STRING.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>GET_USER_NAME
    CHANGING
      USER_NAME    = PFV_NTNME
    EXCEPTIONS
      CNTL_ERROR   = 1
      ERROR_NO_GUI = 2
      OTHERS       = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  CALL METHOD CL_GUI_CFW=>UPDATE_VIEW
    EXCEPTIONS
      CNTL_SYSTEM_ERROR = 1
      CNTL_ERROR        = 2
      OTHERS            = 3.
  PFV_UNAME_O = PFV_NTNME.
ENDFORM.                    " GET_NT_USERNAME
*&---------------------------------------------------------------------*
*&      Form  GET_USCI_CODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_HEAD  text
*----------------------------------------------------------------------*
FORM GET_USCI_CODE  CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFWA_KNA1 LIKE KNA1,
        PFWA_ADRC LIKE ADRC.

  CHECK PFWA_HEAD_IO-ZTYPE = 'I' OR
        PFWA_HEAD_IO-ZTYPE = 'P'.
*  PERFORM GET_WORKAREA_KNA1 USING     PFWA_HEAD_IO-KUNAG  "D050819
  PERFORM GET_WORKAREA_KNA1 USING     PFWA_HEAD_IO-KUNNR    "I050819
                            CHANGING  PFWA_KNA1.
  CHECK PFWA_KNA1 IS NOT INITIAL.
  PERFORM GET_WORKAREA_ADRC USING     PFWA_KNA1-ADRNR
                            CHANGING  PFWA_ADRC.
  CHECK PFWA_ADRC IS NOT INITIAL.
  PFWA_HEAD_IO-USCIC = PFWA_ADRC-NAME_CO.

ENDFORM.                    " GET_USCI_CODE
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_KNA1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_IO_KUNAG  text
*      <--P_PFWA_KNA1  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_KNA1  USING    PFV_KUNAG_I
                        CHANGING PFWA_KNA1_O STRUCTURE KNA1.
  CLEAR: PFWA_KNA1_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_KNA1_O FROM   KNA1
                                             WHERE  KUNNR = PFV_KUNAG_I.
ENDFORM.                    " GET_WORKAREA_KNA1
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ADRC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_KNA1_ADRNR  text
*      <--P_PFWA_ADRC  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ADRC  USING    PFV_ADRNR_I
                        CHANGING PFWA_ADRC_O STRUCTURE ADRC.
  CLEAR: PFWA_ADRC_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ADRC_O FROM   ADRC
                                             WHERE  ADDRNUMBER = PFV_ADRNR_I.
ENDFORM.                    " GET_WORKAREA_ADRC

*&---------------------------------------------------------------------*
*&      Form  GET_HEADER_LIKP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIKP  text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_LIKP  TABLES   PF_LIKP_O STRUCTURE LIKP.
  CLEAR: PF_LIKP_O, PF_LIKP_O[].
**只有關務不管SALES ORG....
  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_LIKP_O   FROM   LIKP
                                                          WHERE  VBELN    IN S_VBELN
                                                          AND    ERDAT    IN S_ERDAT      "DOCUMENT DATE
                                                          AND    KUNAG    IN S_KUNAG
                                                          AND    KUNNR    IN S_KUNNR"I190425
                                                          AND    VBTYP    IN ('J', 'T').  "J = [DN] T = [RETURN DN]  M140123
  CHECK P_JOBTPS <> 'N' AND
        P_JOBTPS <> 'E' AND
        P_JOBTPS <> 'I'.                                    "I021220
*  CHECK S_VKORG[] IS NOT INITIAL.
*  DELETE PF_LIKP_O WHERE VKORG NOT IN S_VKORG.      "刪除不需要的SALES ORG.
  DELETE PF_LIKP_O WHERE VKORG <> P_VKORG.      "刪除不需要的SALES ORG.
ENDFORM.                    " GET_HEADER_LIKP
*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_DATA_VBRK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK  text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_VBRK  TABLES   PF_VBRK_O STRUCTURE VBRK.
  CLEAR: PF_VBRK_O, PF_VBRK_O[].
**只有關務不管SALES ORG....
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_VBRK_O FROM   VBRK
                                                 WHERE  VBELN    IN S_VBELN
                                                 AND    ZSIDAT   IN S_ERDAT
                                                 AND    KUNRG    IN S_KUNAG
"                                                 AND    FKSTO    =  ''
                                                 AND    VBTYP    NOT IN  ('N', 'S').

  "N = Billing Cancel, S = Credit Memo Cancel
  CHECK P_JOBTPS <> 'N' AND
        P_JOBTPS <> 'E' AND
        P_JOBTPS <> 'I'.                                    "I021220
*  CHECK P_VKORG IS NOT INITIAL.
*  DELETE PF_VBRK_O WHERE VKORG NOT IN S_VKORG.
  DELETE PF_VBRK_O WHERE VKORG <> P_VKORG.
ENDFORM.                    " GET_HEAD_DATA_VBRK
*&---------------------------------------------------------------------*
*&      Form  CONTROL_SCREEN_ACTIVE_BY_GROUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1      text
*      -->P_4950   text
*      -->P_0      text
*----------------------------------------------------------------------*
FORM CONTROL_SCREEN_ACTIVE_BY_GROUP  USING   PFV_GRUPN
                                             PFV_GPNAM
                                             PFV_ACTON.
  CASE PFV_GRUPN.
    WHEN 1.
      CHECK SCREEN-GROUP1 = PFV_GPNAM.
    WHEN 2.
      CHECK SCREEN-GROUP2 = PFV_GPNAM.
    WHEN 3.
      CHECK SCREEN-GROUP3 = PFV_GPNAM.
    WHEN 4.
      CHECK SCREEN-GROUP4 = PFV_GPNAM.
    WHEN OTHERS.
  ENDCASE.
  SCREEN-ACTIVE = PFV_ACTON.
ENDFORM.                    " CONTROL_SCREEN_ACTIVE_BY_GROUP
*&---------------------------------------------------------------------*
*&      Form  CONTROL_SCREEN_INPUT_BY_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4967   text
*      -->P_0      text
*----------------------------------------------------------------------*
FORM CONTROL_SCREEN_INPUT_BY_NAME  USING    PFV_SNAME
                                            PFV_INPUT.
  CHECK SCREEN-NAME = PFV_SNAME.
  SCREEN-INPUT = PFV_INPUT.
ENDFORM.                    " CONTROL_SCREEN_INPUT_BY_NAME
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_VBRP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBRK  text
*      -->P_I_VBRP  text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_VBRP  TABLES   PF_VBRK_I STRUCTURE VBRK
                                  PF_VBRP_O STRUCTURE VBRP
                         USING    PFV_FKART_I.
*<-I210217
  DATA: PF_VBRK_TMP LIKE VBRK OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_VBRP_O, PF_VBRP_O[], PF_VBRK_TMP, PF_VBRK_TMP[].
  APPEND LINES OF PF_VBRK_I TO PF_VBRK_TMP.
  IF PFV_FKART_I IS NOT INITIAL.
    DELETE PF_VBRK_TMP WHERE FKART <> PFV_FKART_I.
  ENDIF.
  CHECK PF_VBRK_TMP[] IS NOT INITIAL.
  SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_VBRP_O FROM   VBRP
                                                   FOR ALL ENTRIES IN PF_VBRK_TMP
                                                   WHERE  VBELN = PF_VBRK_TMP-VBELN.
*->I210217
*<-D210217
*  CLEAR: PF_VBRP_O, PF_VBRP_O[].
*  CHECK PF_VBRK_I[] IS NOT INITIAL.
*  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VBRP_O FROM   VBRP
*                                                        FOR ALL ENTRIES IN PF_VBRK_I
*                                                        WHERE  VBELN = PF_VBRK_I-VBELN.
*->D210217
ENDFORM.                    " GET_ITEM_DATA_VBRP
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_LIPS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LIKP  text
*      -->P_I_LIPS  text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_LIPS  TABLES   PF_LIKP_I  STRUCTURE LIKP
                                  PF_LIPS_O  STRUCTURE LIPS.
  CLEAR: PF_LIPS_O, PF_LIPS_O[].
  CHECK  PF_LIKP_I[] IS NOT INITIAL.
**不能用FOR ALL ENTRY,因為有些DN可能沒有LOT,所以要用LOOP抓
  LOOP AT PF_LIKP_I.
    SELECT *
      APPENDING CORRESPONDING FIELDS OF TABLE PF_LIPS_O FROM   LIPS
                                                        WHERE  VBELN =  PF_LIKP_I-VBELN
                                                        AND    UECHA <> ''.
    CHECK SY-SUBRC <> 0.
    SELECT *
      APPENDING CORRESPONDING FIELDS OF TABLE PF_LIPS_O FROM   LIPS
                                                        WHERE  VBELN =  PF_LIKP_I-VBELN.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_LIPS
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBUK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIKP_IO_VBELN  text
*      <--P_PFWA_VBUK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBUK  USING    PFV_VBELN_I
                        CHANGING PFWA_VBUK_O STRUCTURE VBUK.
  CLEAR: PFWA_VBUK_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_VBUK_O FROM   VBUK
                                                           WHERE  VBELN = PFV_VBELN_I.
ENDFORM.                    " GET_WORKAREA_VBUK
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBRK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_VBELN  text
*      <--P_PFWA_VBRK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBRK  USING    PFV_VBELN_I
                        CHANGING PFWA_VBRK_O STRUCTURE VBRK.
  CLEAR: PFWA_VBRK_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VBRK_O  FROM  VBRK
                                              WHERE VBELN = PFV_VBELN_I.
ENDFORM.                    " GET_WORKAREA_VBRK
*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PF_HEAD_O  text
*----------------------------------------------------------------------*
FORM GET_HEAD_REMARK  CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
  CLEAR: PFWA_HEAD_IO-REMAK.
  CHECK P_REMARK IS NOT INITIAL.
  CONCATENATE '**' P_REMARK
    INTO PFWA_HEAD_IO-REMAK SEPARATED BY SPACE.                         "
ENDFORM.                    " GET_HEAD_REMARK
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_VBRP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRP  text
*      -->P_PFV_VBELN  text
*----------------------------------------------------------------------*
FORM GET_DATA_VBRP  TABLES   PF_VBRP_O STRUCTURE VBRP
                    USING    PFV_VBELN_I.
  CLEAR: PF_VBRP_O, PF_VBRP_O[].
  CHECK PFV_VBELN_I IS NOT INITIAL.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_VBRP_O FROM  VBRP
                                                 WHERE VBELN = PFV_VBELN_I.
ENDFORM.                    " GET_DATA_VBRP
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_LIKP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_VBELN_I  text
*      <--P_PFWA_LIKP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_LIKP  USING    PFV_VGBEL_I
                        CHANGING PFWA_LIKP_O STRUCTURE LIKP.
  CLEAR: PFWA_LIKP_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_LIKP_O FROM   LIKP
                                             WHERE  VBELN = PFV_VGBEL_I.
ENDFORM.                    " GET_WORKAREA_LIKP
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZWHRELNO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_VGBEL  text
*      <--P_PFWA_ZWHRELNO  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZWHRELNO  USING    PFV_VGBEL_I
                            CHANGING PFWA_ZWHRELNO_O STRUCTURE ZWHRELNO.
  CLEAR: PFWA_ZWHRELNO_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_ZWHRELNO_O FROM   ZWHRELNO
                                                               WHERE  VBELN = PFV_VGBEL_I.
ENDFORM.                    " GET_WORKAREA_ZWHRELNO
*&---------------------------------------------------------------------*
*&      Form  CHECK_USEING_PI_PRINTED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_IO  text
*      <--P_PFV_CANCL  text
*----------------------------------------------------------------------*
FORM CHECK_USEING_PI_PRINTED  USING     PFWA_VBRK_I STRUCTURE VBRK
                              CHANGING  PFV_CANCL_IO.
  DATA: PFV_CANCL     TYPE C,
        PFV_VARTS_X   TYPE C,                               "接值用
        PFWA_ZPD1     LIKE ZPD1,
        PFV_VBELN(10) TYPE C,
        PF_ZPDH       LIKE ZPDH OCCURS 0 WITH HEADER LINE,
        PF_VBFA       LIKE VBFA OCCURS 0 WITH HEADER LINE,
        PF_VBRP       LIKE VBRP OCCURS 0 WITH HEADER LINE.
*<-I210217
  CLEAR: PFV_VBELN.
  CHECK PFV_CANCL_IO IS INITIAL.

  PERFORM GET_DATA_VBRP TABLES PF_VBRP
                        USING  PFWA_VBRK_I-VBELN.
  CHECK PF_VBRP[] IS NOT INITIAL.
  SORT PF_VBRP BY AUBEL.
  DELETE ADJACENT DUPLICATES FROM PF_VBRP COMPARING AUBEL.

  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_VBFA  FROM VBFA
                                                FOR ALL ENTRIES IN PF_VBRP
                                                WHERE VBELV   = PF_VBRP-AUBEL
                                                AND   VBTYP_N = 'U'.
  CHECK PF_VBFA[] IS NOT INITIAL.
  SORT PF_VBFA BY VBELV VBELN.
  DELETE ADJACENT DUPLICATES FROM PF_VBFA COMPARING VBELV VBELN.
  LOOP AT PF_VBFA.
**檢查PI是否Cancel
    PERFORM CHECK_PROFORMA_STATUS USING     PF_VBFA-VBELN
                                            'CANC'
                                  CHANGING  PFV_CANCL
                                            PFV_VARTS_X.
    CHECK PFV_CANCL IS INITIAL.
**只要有一張PI沒有印就ERROR,並跳離
    PERFORM GET_WORKAREA_ZPD1 USING     PF_VBFA-VBELN
                              CHANGING  PFWA_ZPD1.
    CHECK PFWA_ZPD1 IS INITIAL.
    WRITE PFWA_VBRK_I-VBELN TO PFV_VBELN.
    MESSAGE I000 WITH PF_VBFA-VBELN 'This Proforma invoice has not been printed!(' PFV_VBELN ')'.
    PFV_CANCL_IO = 'X'.
    EXIT.
  ENDLOOP.

*<-D210422
*  CASE PFV_PITYP_I.
*    WHEN 'ORGPI'.
*
*    WHEN 'NEWPI'.
*      SELECT *
*        INTO CORRESPONDING FIELDS OF TABLE PF_ZPDH  FROM  ZPDH
*                                                    FOR ALL ENTRIES IN PF_VBRP
*                                                    WHERE VBELN = PF_VBRP-AUBEL
*                                                    AND   ZBSTATUS = 'ACTV'.  "I
*      LOOP AT PF_ZPDH.
*        PERFORM GET_WORKAREA_ZPD1 USING     PF_ZPDH-PERFI
*                                  CHANGING  PFWA_ZPD1.
*        CHECK PFWA_ZPD1 IS INITIAL.
*        MESSAGE I000 WITH PF_VBFA-VBELN 'This Proforma invoice has not been printed!(' PFV_VBELN ')'.
*        PFV_CANCL_IO = 'X'.
*        EXIT.
*      ENDLOOP.
*    WHEN OTHERS.
*  ENDCASE.
*->I210217
*->D210422

*<-D210217
*  CLEAR: PFV_CANCL_O.
*  PERFORM GET_DATA_VBRP TABLES PF_VBRP
*                        USING  PFWA_VBRK_I-VBELN.
*  CHECK PF_VBRP[] IS NOT INITIAL.
*  SORT PF_VBRP BY AUBEL.
*  DELETE ADJACENT DUPLICATES FROM PF_VBRP COMPARING AUBEL.
*  SELECT *
*    INTO CORRESPONDING FIELDS OF TABLE PF_VBFA FROM VBFA
*                                               FOR ALL ENTRIES IN PF_VBRP
*                                               WHERE VBELV   = PF_VBRP-AUBEL
*                                               AND   VBTYP_N = 'U'.
*  CHECK PF_VBFA[] IS NOT INITIAL.
*  SORT PF_VBFA BY VBELV VBELN.
*  DELETE ADJACENT DUPLICATES FROM PF_VBFA COMPARING VBELV VBELN.
*  LOOP AT PF_VBFA.
***檢查PI是否Cancel
*    PERFORM CHECK_PROFORMA_STATUS USING     PF_VBFA-VBELN
*                                            'CANC'
*                                  CHANGING  PFV_CANCL
*                                            PFV_VARTS_X.
*    CHECK PFV_CANCL IS INITIAL.
***只要有一張PI沒有印就ERROR,並跳離
*    PERFORM GET_WORKAREA_ZPD1 USING     PF_VBFA-VBELN
*                              CHANGING  PFWA_ZPD1.
*    CHECK PFWA_ZPD1 IS INITIAL.
*    MESSAGE I000 WITH PF_VBFA-VBELN 'This Proforma invoice has not been printed!(' PFWA_VBRK_I-VBELN ')'.
*    PFV_CANCL_O = 'X'.
*    EXIT.
*  ENDLOOP.
*->D210217
ENDFORM.                    " CHECK_USEING_PI_PRINTED
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZPD1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBFA_VBELN  text
*      <--P_PFWA_ZPD1  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZPD1  USING    PFV_VBELN_I
                        CHANGING PFWA_ZPD1_O STRUCTURE ZPD1.
  CLEAR: PFWA_ZPD1_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZPD1_O  FROM  ZPD1
                                              WHERE PERFI = PFV_VBELN_I.
ENDFORM.                    " GET_WORKAREA_ZPD1
*&---------------------------------------------------------------------*
*&      Form  GET_CONTANT_PERSON_SEPAR_FLAG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PFV_PAAT3  text
*----------------------------------------------------------------------*
FORM GET_CONTANT_PERSON_SEPAR_FLAG USING    PFV_VKORG_I
                                   CHANGING PFV_PAAT3_O.
**12"用P 8"用M
  CLEAR: PFV_PAAT3_O.
  PFV_PAAT3_O = 'P'.
  CHECK PFV_VKORG_I = 'MAX1'.
  PFV_PAAT3_O = 'M'.
ENDFORM.                    " GET_CONTANT_PERSON_SEPAR_FLAG
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBAK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_AUBEL  text
*      <--P_PFWA_VBAK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBAK  USING    PFV_AUBEL_I
                        CHANGING PFWA_VBAK_O STRUCTURE VBAK.
  CLEAR: PFWA_VBAK_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VBAK_O  FROM  VBAK
                                              WHERE VBELN = PFV_AUBEL_I.
ENDFORM.                    " GET_WORKAREA_VBAK
*&---------------------------------------------------------------------*
*&      Form  GET_CONNECTION_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0529   text
*      <--P_PFV_DESTN  text
*----------------------------------------------------------------------*
FORM GET_CONNECTION_INFO  USING    PFV_ITEMS
                          CHANGING PFV_DESTN_O.
  CLEAR: PFV_DESTN_O.
  SELECT SINGLE * FROM  ZSDDEST
                  WHERE REPID = SY-REPID
                  AND   ITEM  = PFV_ITEMS.
  PFV_DESTN_O = ZSDDEST-DEST.
ENDFORM.                    " GET_CONNECTION_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBKD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_AUBEL  text
*      -->P_PFV_AUPOS  text
*      <--P_PFWA_VBKD  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBKD  USING    PFV_AUBEL_I
                                 PFV_AUPOS_I
                        CHANGING PFWA_VBKD_O STRUCTURE VBKD.
  CLEAR: PFWA_VBKD_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_VBKD_O FROM  VBKD
                                                           WHERE VBELN = PFV_AUBEL_I
                                                           AND   POSNR = PFV_AUPOS_I.
ENDFORM.                    " GET_WORKAREA_VBKD
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_VBAP_FROM_DN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIPS_I  text
*      <--P_PF_ITEM_O  text
*----------------------------------------------------------------------*
FORM GET_DATA_VBAP_FROM_DN  USING    PFWA_LIPS_I   STRUCTURE LIPS
                            CHANGING PFWA_ITEM_IO  STRUCTURE I_ITEM.
  DATA: PFWA_VBAP LIKE VBAP.

  CLEAR: PFWA_ITEM_IO-KDMAT, PFWA_ITEM_IO-WAERK, PFWA_ITEM_IO-KWMEN.
  PFWA_ITEM_IO-KDMAT = PFWA_LIPS_I-KDMAT.

  PERFORM GET_WORKAREA_VBAP USING     PFWA_LIPS_I-VGBEL
                                      PFWA_LIPS_I-VGPOS
                            CHANGING  PFWA_VBAP.
  CHECK PFWA_VBAP IS NOT INITIAL.
  PFWA_ITEM_IO-WAERK = PFWA_VBAP-WAERK.
  PFWA_ITEM_IO-KWMEN = PFWA_VBAP-KWMENG.
**若LIPS中沒有值就使用VBAP-KDMAT
  CHECK PFWA_ITEM_IO-KDMAT IS INITIAL.
  PFWA_ITEM_IO-KDMAT = PFWA_VBAP-KDMAT.         "VBAP尚未CLEAR,所以可以直接使用
ENDFORM.                    " GET_DATA_VBAP_FROM_DN
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VEPO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_LIPS_I_VBELN  text
*      -->P_PFWA_LIPS_I_POSNR  text
*      <--P_PFWA_VEPO  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VEPO  USING    PFV_VGBEL_I
                                 PFV_VGPOS_I
                        CHANGING PFWA_VEPO_O.
  CLEAR: PFWA_VEPO_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_VEPO_O FROM   VEPO
                                                           WHERE  VBELN = PFV_VGBEL_I
                                                            AND   POSNR = PFV_VGPOS_I.
ENDFORM.                    " GET_WORKAREA_VEPO
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_MAKT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_MATNR  text
*      <--P_PFWA_MAKT  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_MAKT  USING    PFV_MATNR_I
                        CHANGING PFWA_MAKT_O STRUCTURE MAKT.
  CLEAR: PFWA_MAKT_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_MAKT_O FROM   MAKT
                                             WHERE  MATNR = PFV_MATNR_I
                                             AND    SPRAS = SY-LANGU.
ENDFORM.                    " GET_WORKAREA_MAKT
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZZAUSP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_WERKS  text
*      -->P_PFV_MATNR  text
*      <--P_PFWA_ZZAUSP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZZAUSP  USING    PFV_WERKS_I
                                   PFV_MATNR_I
                          CHANGING PFWA_ZZAUSP_O STRUCTURE ZZAUSP.
  CLEAR: PFWA_ZZAUSP_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_ZZAUSP_O FROM  ZZAUSP
                                                             WHERE WERKS = PFV_WERKS_I
                                                             AND   MATNR = PFV_MATNR_I.
ENDFORM.                    " GET_WORKAREA_ZZAUSP
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VEKP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_VEPO_VENUM  text
*      <--P_PFWA_VEKP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VEKP  USING    PFV_VENUM
                        CHANGING PFWA_VEKP_O STRUCTURE VEKP.
  CLEAR: PFWA_VEKP_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VEKP_O FROM  VEKP
                                             WHERE VENUM = PFV_VENUM.

ENDFORM.                    " GET_WORKAREA_VEKP
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_FROM_VBAP_INV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRP_I  text
*      -->P_PFWA_HEAD_I_ZTYPE  text
*      <--P_PF_ITEM_O  text
*----------------------------------------------------------------------*
FORM GET_DATA_VBAP_FROM_INV  USING    PFWA_VBRP_I  STRUCTURE VBRP
                                      PFV_ZTYPE
                             CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFWA_VBAP LIKE VBAP,
        PFWA_LIPS LIKE LIPS.
  CLEAR: PFWA_ITEM_IO-KWMEN, PFWA_ITEM_IO-KDMAT.

  PERFORM GET_WORKAREA_VBAP USING     PFWA_VBRP_I-AUBEL
                                      PFWA_VBRP_I-AUPOS
                            CHANGING  PFWA_VBAP.
  CHECK PFWA_VBAP IS NOT INITIAL.
*  PFWA_ITEM_IO-POSEX = VBAP-POSEX.
  CASE PFV_ZTYPE.
    WHEN 'I'.                         "I = Invoice
      PFWA_ITEM_IO-KWMEN = PFWA_VBAP-KWMENG.
      PFWA_ITEM_IO-KDMAT = PFWA_VBAP-KDMAT.
**customer material[LIPS-KDMAT VBAP-KDMAT]
      PERFORM GET_WORKAREA_LIPS USING     PFWA_VBRP_I-VGBEL
                                          PFWA_VBRP_I-VGPOS
                                CHANGING  PFWA_LIPS.

      CHECK PFWA_LIPS-KDMAT IS NOT INITIAL.
      CHECK PFWA_LIPS-KDMAT <> PFWA_VBAP-KDMAT.
      PFWA_ITEM_IO-KDMAT = PFWA_LIPS-KDMAT.
**目前這個先沒有用
*    WHEN 'O'.                         "O = 放行單
*      PFWA_ITEM_IO-KWMEN = PFWA_VBAP-ZMENG.
***customer material[VBAP-KDMAT]
*      PFWA_ITEM_IO-KDMAT = PFWA_VBAP-KDMAT.
    WHEN 'D' OR 'C'.                         "D = Debit memo, 'C':credit memo
      PFWA_ITEM_IO-KWMEN = PFWA_VBAP-ZMENG.
**customer material[VBAP-KDMAT]
      PFWA_ITEM_IO-KDMAT = PFWA_VBAP-KDMAT.
    WHEN 'R'.                                                                                     "R = Proforma
      PFWA_ITEM_IO-KWMEN = PFWA_VBAP-KWMENG.
      PFWA_ITEM_IO-KDMAT = PFWA_VBAP-KDMAT.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_DATA_FROM_VBAP_INV
*&---------------------------------------------------------------------*
*&      Form  SCREEN_MODIFY_SMAIL_BY_SHIPTO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_KUNAG  text
*----------------------------------------------------------------------*
FORM SCREEN_MODIFY_SMAIL_BY_SHIPTO  USING    PFV_KUNAG_I.
  DATA: PFWA_ZSD104 LIKE ZSD104.

  PERFORM GET_WORKAREA_ZSD104 USING     PFV_KUNAG_I
                              CHANGING  PFWA_ZSD104.
  IF PFWA_ZSD104 IS NOT INITIAL.
    PERFORM SCREEN_MODIFY USING 'CUST'.
  ELSE.
    PERFORM SCREEN_MODIFY USING 'GENE'.
  ENDIF.
ENDFORM.                    " SCREEN_MODIFY_SMAIL_BY_SHIPTO
*&---------------------------------------------------------------------*
*&      Form  GET_DOC_TITLE_DESC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_MWA_HEAD  text
*----------------------------------------------------------------------*
FORM GET_DOC_TITLE_DESC  CHANGING PFWA_HEAD_IO STRUCTURE MWA_HEAD.
  CLEAR: PFWA_HEAD_IO-TITLE.
  CASE PFWA_HEAD_IO-ZTYPE.
    WHEN 'I'.
      PFWA_HEAD_IO-TITLE = 'Invoice'.
    WHEN 'F'.
      PFWA_HEAD_IO-TITLE = 'Free Invoice'.
    WHEN 'C'.
      PFWA_HEAD_IO-TITLE = 'Credit Memo'.
    WHEN 'P'.
      PFWA_HEAD_IO-TITLE = 'Packing'.
    WHEN 'R'.
      PFWA_HEAD_IO-TITLE = 'Proforma Invoice'.
    WHEN 'D'.                                               "I190708
      PFWA_HEAD_IO-TITLE = 'Debit Memo'.                    "I190708
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " GET_DOC_TITLE_DESC
*&---------------------------------------------------------------------*
*&      Form  SAVE_MAIL_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SAVE_MAIL_LIST TABLES PF_ZSDEL_IO STRUCTURE M_ZSDEL
                           PF_DEL_I    STRUCTURE M_ZSDEL
                    USING  PFWA_HEAD_I STRUCTURE MWA_HEAD.
  IF P_VKORG = 'PSC1'.
    MESSAGE I000 WITH '12吋廠暫不提供存檔功能!!'.
    EXIT.
  ENDIF.


****刪除空白行
  SORT PF_ZSDEL_IO.
  LOOP AT PF_ZSDEL_IO WHERE OTHER = ''.
    CHECK PF_ZSDEL_IO-RECNAM = '' OR
          PF_ZSDEL_IO-RECEXTNAM = ''.
    DELETE PF_ZSDEL_IO.
    CONTINUE.
  ENDLOOP.
**準備資料存入ZSDEL
  PERFORM UPDATE_ZSDEL TABLES PF_ZSDEL_IO
                       USING  PFWA_HEAD_I.

  PERFORM DELETE_ZSDEL TABLES PF_DEL_I.
ENDFORM.                    " SAVE_MAIL_LIST
*&---------------------------------------------------------------------*
*&      Form  DELETE_ZSDEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_DEL_I  text
*----------------------------------------------------------------------*
FORM DELETE_ZSDEL  TABLES   PF_ZSDEL_I STRUCTURE M_ZSDEL.
  DATA: PF_ZSDEL_DEL   LIKE ZSDEL OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_ZSDEL_DEL, PF_ZSDEL_DEL[].
  CHECK PF_ZSDEL_I[] IS NOT INITIAL.
  LOOP AT PF_ZSDEL_I.
    MOVE-CORRESPONDING PF_ZSDEL_I TO PF_ZSDEL_DEL.
    APPEND PF_ZSDEL_DEL.
  ENDLOOP.
  DELETE ZSDEL FROM TABLE PF_ZSDEL_DEL.
ENDFORM.                    " DELETE_ZSDEL
*&---------------------------------------------------------------------*
*&      Form  GET_DEFALUT_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_VKORG  text
*----------------------------------------------------------------------*
FORM GET_DEFALUT_VALUE.
  DATA: PFV_REPID TYPE SYREPID.
*- keep sold to no for KTC Group
  SELECT KUNNR AS LOW INTO CORRESPONDING FIELDS OF TABLE R_KTC FROM ZSD_KTC.
  MOVE: 'I'        TO R_KTC-SIGN,
        'EQ'       TO R_KTC-OPTION.
  MODIFY R_KTC  TRANSPORTING SIGN OPTION WHERE SIGN = ''.

  GET PARAMETER ID 'VKO' FIELD P_VKORG.
*  CLEAR: S_VKORG, S_VKORG[], P_VKORG.
*  S_VKORG-SIGN    = 'I'.
*  S_VKORG-OPTION  = 'EQ'.
*  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
*           ID 'VKORG' FIELD 'MAX1'
*           ID 'ACTVT' FIELD '03'.
*  IF SY-SUBRC = 0.
*    S_VKORG-LOW  = P_VKORG = 'MAX1'.
*    AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
*             ID 'VKORG' FIELD 'PSC1'
*             ID 'ACTVT' FIELD '03'.
*    IF SY-SUBRC = 0.
*      S_VKORG-OPTION  = 'BT'.
*      S_VKORG-HIGH    = 'PSC1'.
*      CLEAR: P_VKORG.
*    ENDIF.
*    APPEND S_VKORG.
*    EXIT.
*  ENDIF.
*  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
*           ID 'VKORG' FIELD 'PSC1'
*           ID 'ACTVT' FIELD '03'.
*  CHECK SY-SUBRC = 0.
*  S_VKORG-LOW     = P_VKORG = 'PSC1'.
*  APPEND S_VKORG.

ENDFORM.                    " GET_DEFALUT_VALUE
*&---------------------------------------------------------------------*
*&      Form  GET_AUTH_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_7576   text
*      <--P_PF_US335  text
*----------------------------------------------------------------------*
FORM GET_AUTH_VALUES    TABLES   PF_US335_O STRUCTURE US335
                        USING    PFV_OBJET_I.
  CALL FUNCTION 'GET_AUTH_VALUES'
    EXPORTING
      OBJECT1                 = PFV_OBJET_I
*     OBJECT2                 = ' '
*     OBJECT3                 = ' '
*     OBJECT4                 = ' '
*     OBJECT5                 = ' '
*     OBJECT6                 = ' '
*     OBJECT7                 = ' '
      USER                    = SY-UNAME
*     TCODE                   = SY-TCODE
    TABLES
      VALUES                  = PF_US335_O
*   EXCEPTIONS
*     USER_DOESNT_EXIST       = 1
*     OTHERS                  = 2
            .
  IF SY-SUBRC <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " GET_AUTH_VALUES
*&---------------------------------------------------------------------*
*&      Form  CONTROL_SCREEN_ACTIVE_BY_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4176   text
*      -->P_0      text
*----------------------------------------------------------------------*
FORM CONTROL_SCREEN_ACTIVE_BY_NAME  USING    PFV_SNAME
                                             PFV_ACTON.
  CHECK SCREEN-NAME = PFV_SNAME.
  SCREEN-ACTIVE = PFV_ACTON.
ENDFORM.                    " CONTROL_SCREEN_ACTIVE_BY_NAME
*&---------------------------------------------------------------------*
*&      Form  GET_SALES_ORG_DESC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_VKORG  text
*      <--P_V_VTEXT  text
*----------------------------------------------------------------------*
FORM GET_SALES_ORG_DESC  USING    PFV_VKORG_I
                         CHANGING PFV_VTEXT_O.
  CLEAR: PFV_VTEXT_O.
  CHECK PFV_VKORG_I IS NOT INITIAL.
  SELECT SINGLE *
    FROM  TVKOT
    WHERE SPRAS = SY-LANGU
    AND   VKORG = PFV_VKORG_I.
  CHECK SY-SUBRC = 0.
  PFV_VTEXT_O = TVKOT-VTEXT.
ENDFORM.                    " GET_SALES_ORG_DESC
*&---------------------------------------------------------------------*
*&      Form  CONTROL_SCREEN_INVIS_BY_GROUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1      text
*      -->P_4233   text
*      -->P_1      text
*----------------------------------------------------------------------*
FORM CONTROL_SCREEN_INVIS_BY_GROUP  USING    PFV_GRUPN
                                             PFV_GPNAM
                                             PFV_ACTON.
  CASE PFV_GRUPN.
    WHEN 1.
      CHECK SCREEN-GROUP1 = PFV_GPNAM.
    WHEN 2.
      CHECK SCREEN-GROUP2 = PFV_GPNAM.
    WHEN 3.
      CHECK SCREEN-GROUP3 = PFV_GPNAM.
    WHEN 4.
      CHECK SCREEN-GROUP4 = PFV_GPNAM.
    WHEN OTHERS.
  ENDCASE.
  SCREEN-INVISIBLE = PFV_ACTON.
ENDFORM.                    " CONTROL_SCREEN_INVIS_BY_GROUP

*&---------------------------------------------------------------------*
*&      Form  GET_PI_RATE_PRICE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_VBELN  text
*      <--P_PFV_LINES  text
*----------------------------------------------------------------------*
FORM GET_PI_RATE_PRICE_DATA  USING    PFV_PVBEL_I
                             CHANGING PFV_PTYPE_O
                                      PFV_LINES_O.
  DATA: PF_LINES      LIKE TLINE OCCURS 0 WITH HEADER LINE.

  CLEAR: PFV_PTYPE_O, PFV_LINES_O.
**取得PI Rate的TEXT(Rate)
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_PVBEL_I
                               'T02'
                               'VBBK'.
  READ TABLE PF_LINES INDEX 1.
**取得PI Rate的TEXT(By PC)
  IF PF_LINES-TDLINE IS INITIAL.
    PERFORM GET_LONG_TEXT TABLES PF_LINES
                          USING  PFV_PVBEL_I
                                 'T03'
                                 'VBBK'.
    READ TABLE PF_LINES INDEX 1.
    IF PF_LINES-TDLINE IS NOT INITIAL.
      PFV_PTYPE_O = 'PC'.
    ENDIF.
  ELSE.
    PFV_PTYPE_O = 'RATE'.
  ENDIF.

  READ TABLE PF_LINES INDEX 1.
  MOVE PF_LINES-TDLINE TO PFV_LINES_O.
  CHECK PFV_LINES_O IS NOT INITIAL.
  CONDENSE PFV_LINES_O NO-GAPS.

ENDFORM.                    " GET_PI_RATE_PRICE_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_T880
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_VBRK_BUKRS  text
*      <--P_PFWA_T880  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_T880  USING    PFV_BUKRS_I
                        CHANGING PFWA_T880_O STRUCTURE T880.
  CLEAR: PFWA_T880_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_T880_O FROM  T880
                                                           WHERE RCOMP = PFV_BUKRS_I.

ENDFORM.                    " GET_WORKAREA_T880
*&---------------------------------------------------------------------*
*&      Form  GET_PROFORMA_DOWNPAY_AMT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD  text
*      -->P_I_ITEM_PIHEAD_TOTAL  text
*      <--P_I_ITEM_PIHEAD_RESUT  text
*----------------------------------------------------------------------*
FORM GET_PROFORMA_DOWNPAY_AMT  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                        PFV_TOTAL_I
                               CHANGING PFV_PIAMT_O.
  DATA: PFV_FKIMG     TYPE FKIMG,   "SUM(I_ITEM-DWEMN)
        PFV_DENOT(10) TYPE N,       "接值:一片?錢/Rate的分子                                  "分母
        PFV_MOLER(10) TYPE N.       "接值:Rate分母
  CLEAR: PFV_PIAMT_O.




**以片計價
  IF PFWA_HEAD_I-PBYPC IS NOT INITIAL.
***先算該PI總片數
    SELECT SUM( FKIMG )
      INTO PFV_FKIMG FROM   VBRP
                     WHERE  VBELN = PFWA_HEAD_I-VBELN.
***取得單片扣多少VBBK-T03(LONG TEXT)
    PERFORM CHECK_PROFORMA_STATUS USING     PFWA_HEAD_I-VBELN"I171114
                                            'BYPC'
                                  CHANGING  PFV_DENOT                                         "分母
                                            PFV_MOLER.    "這個沒用到
***片數*以片計價單價
    PFV_PIAMT_O = PFV_DENOT * PFV_FKIMG.
    EXIT.
  ENDIF.
**以Rate計價
  PERFORM CHECK_PROFORMA_STATUS USING     PFWA_HEAD_I-VBELN "I171114
                                          'RATE'
                                CHANGING  PFV_DENOT                                           "分母
                                          PFV_MOLER.                                          "分子
  PFV_PIAMT_O = PFV_TOTAL_I * PFV_MOLER / PFV_DENOT.
ENDFORM.                    " GET_PROFORMA_DOWNPAY_AMT
*&---------------------------------------------------------------------*
*&      Form  CHECK_USCI_CODE_EXIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIKP_IO  text
*      <--P_PFV_NOEST  text
*----------------------------------------------------------------------*
FORM CHECK_USCI_CODE_EXIST  USING    PFWA_LIKP_I STRUCTURE LIKP
                            CHANGING PFV_NOEST_O.
  DATA: PFWA_KNA1 LIKE KNA1,
        PFWA_ADRC LIKE ADRC.

  CLEAR: PFV_NOEST_O.
  PERFORM GET_WORKAREA_KNA1 USING     PFWA_LIKP_I-KUNNR
                            CHANGING  PFWA_KNA1.
  CHECK PFWA_KNA1-LAND1 = 'CN' OR
        PFWA_KNA1-LAND1 = 'HK'.

  PERFORM GET_WORKAREA_ADRC USING     PFWA_KNA1-ADRNR
                            CHANGING  PFWA_ADRC.
  CHECK PFWA_ADRC-NAME_CO IS INITIAL.
  PFV_NOEST_O = 'X'.
ENDFORM.                    " CHECK_USCI_CODE_EXIST
*&---------------------------------------------------------------------*
*&      Form  CHECK_BANK_MASTER_EXIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_IO  text
*      <--P_PFV_CANCL  text
*----------------------------------------------------------------------*
FORM CHECK_BANK_MASTER_EXIST  USING    PFWA_VBRK_I STRUCTURE VBRK
                              CHANGING PFV_CANCL_O.
  DATA: PFWA_KNBK       LIKE KNBK,
        PFWA_ZSDBKN     LIKE ZSDBKN,
        PFV_MESSG(50)   TYPE C.

  CHECK PFWA_VBRK_I-ZTERM <> 'TT'.                          "I110419
  CLEAR: PFV_CANCL_O, PFV_MESSG.
  WRITE PFWA_VBRK_I-VBELN TO PFV_MESSG.
  PERFORM GET_WORKAREA_ZSDBKN USING     PFWA_VBRK_I-ZWAERS_PAYMT_B
                              CHANGING  PFWA_ZSDBKN.
  IF PFWA_ZSDBKN IS INITIAL.
    CONCATENATE PFWA_VBRK_I-ZWAERS_PAYMT_B '(' PFV_MESSG ')-幣別Accnt name 主檔不存在!!(ZSDBKN)'
      INTO  PFV_MESSG.
    MESSAGE I000 WITH PFV_MESSG.
    PFV_CANCL_O = 'X'.
    EXIT.
  ENDIF.

  PERFORM GET_WORKAREA_KNBK USING     PFWA_VBRK_I-KUNAG
                            CHANGING  PFWA_KNBK.
  IF PFWA_KNBK-BANKS <> 'TW' AND
     PFWA_KNBK-BKREF <> PFWA_VBRK_I-ZWAERS_PAYMT_B.
    CONCATENATE PFWA_VBRK_I-KUNAG '(' PFV_MESSG ')-' PFWA_VBRK_I-ZWAERS_PAYMT_B '-客戶銀行資料未建立'
      INTO PFV_MESSG.
    MESSAGE I000 WITH PFV_MESSG.
    PFV_CANCL_O = 'X'.
    EXIT.
  ENDIF.
  SELECT SINGLE * FROM  BNKA
                  WHERE BANKS = 'TW'
                  AND   BANKL = PFWA_KNBK-BANKL.
  IF SY-SUBRC <> 0.
    CONCATENATE '(' PFV_MESSG ')' PFWA_KNBK-BANKL '-銀行主檔不存在'
      INTO PFV_MESSG.
    MESSAGE I000 WITH PFV_MESSG.
    PFV_CANCL_O = 'X'.
    EXIT.
  ENDIF.
ENDFORM.                    " CHECK_BANK_MASTER_EXIST
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_KNBK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_VBRK_I_KUNAG  text
*      <--P_PFWA_KNBK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_KNBK  USING    PFV_KUNAG_I
                        CHANGING PFWA_KNBK_O STRUCTURE KNBK.
  CLEAR: PFWA_KNBK_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_KNBK_O FROM   KNBK
                                                           WHERE  KUNNR = PFV_KUNAG_I.
ENDFORM.                    " GET_WORKAREA_KNBK
*&---------------------------------------------------------------------*
*&      Form  GET_BANK_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_VBELN  text
*      -->P_PFWA_HEAD_ZTYPE  text
*----------------------------------------------------------------------*
FORM GET_BANK_INFO  USING    PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: PFWA_VBRK       LIKE VBRK,
        PFWA_ZSDBKN     LIKE ZSDBKN,
        PFV_REMAK(300)  TYPE C.

  PERFORM GET_WORKAREA_VBRK USING     PFWA_HEAD_I-VBELN
                            CHANGING  PFWA_VBRK.

  CHECK PFWA_VBRK-ZTERM <> 'TT'.                            "I110419

  PERFORM GET_WORKAREA_ZSDBKN USING     PFWA_VBRK-ZWAERS_PAYMT_B
                              CHANGING  PFWA_ZSDBKN.

  SELECT SINGLE * FROM  KNBK
                  WHERE KUNNR = PFWA_HEAD_I-KUNAG
                  AND   BANKS = 'TW'
                  AND   BKREF = PFWA_VBRK-ZWAERS_PAYMT_B.

  SELECT SINGLE * FROM  BNKA
                  WHERE BANKS = 'TW'
                  AND   BANKL = KNBK-BANKL.

  CLEAR: PFV_REMAK.
  CONCATENATE '** Account Name:' PFWA_ZSDBKN-KOINH
    INTO PFV_REMAK+2 SEPARATED BY SPACE.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFWA_HEAD_I-VBELN
                                      PFWA_HEAD_I-ZTYPE
                                      ''.
  CLEAR: PFV_REMAK.
  CONCATENATE 'Account Number:' KNBK-BANKN
    INTO PFV_REMAK+5 SEPARATED BY SPACE.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFWA_HEAD_I-VBELN
                                      PFWA_HEAD_I-ZTYPE
                                      ''.

  CHECK PFWA_VBRK-ZWAERS_PAYMT_B <> 'TWD'.
  CLEAR: PFV_REMAK.
  CONCATENATE 'Swift code:' BNKA-SWIFT
    INTO PFV_REMAK+5 SEPARATED BY SPACE.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFWA_HEAD_I-VBELN
                                      PFWA_HEAD_I-ZTYPE
                                      ''.
ENDFORM.                    " GET_BANK_INFO
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSDBKN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_VBRK_I_ZWAERS_PAYMT_B  text
*      <--P_PFWA_ZSDBKN  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSDBKN  USING    PFV_WAERK_I
                          CHANGING PFWA_ZSDBKN_O STRUCTURE ZSDBKN.
  CLEAR: PFWA_ZSDBKN_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_ZSDBKN_O FROM  ZSDBKN
                                                             WHERE WAERK = PFV_WAERK_I.
ENDFORM.                    " GET_WORKAREA_ZSDBKN
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZSD04
*&---------------------------------------------------------------------*
FORM UPDATE_ZSD04 .
  DATA: PF_ZSD04 LIKE ZSD04 OCCURS 0 WITH  HEADER LINE,
        PFV_EXIDV LIKE ZSD04-EXIDV,
        PFV_NUM(4) TYPE N.
  DATA: BEGIN OF PF_CARQT OCCURS 0,
          VBELN LIKE LIKP-VBELN,
          CORDE TYPE I,
        END OF PF_CARQT.


  LOOP AT I_ITEM WHERE ZTYPE = 'P'.
    MOVE-CORRESPONDING I_ITEM TO PF_CARQT.
    APPEND  PF_CARQT.
    CLEAR   PF_CARQT.
  ENDLOOP.
  SORT PF_CARQT BY VBELN CORDE DESCENDING.
  DELETE ADJACENT DUPLICATES FROM PF_CARQT COMPARING VBELN.


  LOOP AT I_HEAD WHERE ZTYPE = 'P'.
    LOOP AT I_ITEM WHERE VBELN = I_HEAD-VGBEL
                   AND   ZTYPE = I_HEAD-ZTYPE.
      READ TABLE PF_CARQT WITH KEY VBELN = I_ITEM-VBELN.            "FOR Total Carton Qty

      CLEAR PF_ZSD04.
      MOVE: I_HEAD-VGBEL    TO PF_ZSD04-VBELN,
            SY-UNAME        TO PF_ZSD04-ERNAM,
            SY-DATUM        TO PF_ZSD04-ERDAT,
            SY-UZEIT        TO PF_ZSD04-ERZET,
            I_ITEM-VENUM    TO PF_ZSD04-VENUM,
            I_ITEM-CTNNO    TO PF_ZSD04-EXIDV,                          " ex 1/4, 4/2 ...
            PF_CARQT-CORDE  TO PFV_NUM.
      MOVE: PFV_NUM         TO PF_ZSD04-CASENO.

      APPEND PF_ZSD04.
    ENDLOOP.  "end of I_ITEM
  ENDLOOP.  "end of I_HEAD WHERE ZTYPE = 'P'.

  CHECK PF_ZSD04[] IS NOT INITIAL.
  MODIFY ZSD04 FROM TABLE PF_ZSD04.
ENDFORM.                    " UPDATE_ZSD04
*&---------------------------------------------------------------------*
*&      Form  GET_DOC_PRODUCT_TYPE
*&---------------------------------------------------------------------*
FORM GET_DOC_PRODUCT_TYPE  CHANGING  PFWA_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFWA_LIPS   LIKE LIPS,
        PFWA_ZZAUSP LIKE ZZAUSP,
        PFWA_ZMWHJH LIKE ZMWHJH.
  CHECK PFWA_HEAD_IO-ZTYPE = 'P' OR
        PFWA_HEAD_IO-ZTYPE = 'I' OR
        PFWA_HEAD_IO-ZTYPE = 'F'.
  PERFORM GET_WORKAREA_LIPS USING     PFWA_HEAD_IO-VGBEL
                                      ''
                            CHANGING  PFWA_LIPS.
  PERFORM GET_WORKAREA_ZZAUSP USING     PFWA_LIPS-WERKS
                                        PFWA_LIPS-MATNR
                              CHANGING  PFWA_ZZAUSP.
  PFWA_HEAD_IO-PRODTYPE = PFWA_ZZAUSP-PRODTYPE.
  CHECK PFWA_ZZAUSP-PRODTYPE = 'D'.
  PERFORM GET_WORKAREA_ZMWHJH USING    PFWA_HEAD_IO-VGBEL
                              CHANGING PFWA_ZMWHJH.
  CHECK PFWA_ZMWHJH IS NOT INITIAL.
  PFWA_HEAD_IO-PRODTYPE = 'B'.                   "Blue tape
ENDFORM.                    " GET_DOC_PRODUCT_TYPE
*&---------------------------------------------------------------------*
*&      Form  GET_GOOD_BAD_DIE_QTY
*&---------------------------------------------------------------------*
FORM GET_GOOD_BAD_DIE_QTY USING    PFV_PTYPE_I
                          CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  RANGES: PV_MATNR FOR ZZAUSP-MATNR.                        "I060519

  DATA: PFWA_ZZAUSP LIKE ZZAUSP.
  CHECK PFV_PTYPE_I = 'D'.

  SELECT SINGLE * INTO PFWA_ZZAUSP  FROM  ZZAUSP
                                    WHERE MATNR = PFWA_ITEM_IO-MATNR.
*060519-->I
  REFRESH PV_MATNR.
  MOVE: 'I'      TO PV_MATNR-SIGN,
        'CP'     TO PV_MATNR-OPTION,
        '*-*BD*' TO PV_MATNR-LOW.
  APPEND PV_MATNR.
  IF PFWA_ZZAUSP-MATNR IN PV_MATNR AND PFWA_ZZAUSP-MTART = 'UNBW'.
    PFWA_ITEM_IO-BDQTY = PFWA_ITEM_IO-DCEMN.                           "chip/Bad die qty
  ELSE.
    PFWA_ITEM_IO-GDQTY = PFWA_ITEM_IO-DCEMN.                           "chip/Good die qty
  ENDIF.
*060519<--I
*060519-->D
*  IF PFWA_ITEM_IO-MATNR CS '-GD' OR
*     PFWA_ITEM_IO-MATNR CS '-DN' OR
*     PFWA_ITEM_IO-MATNR CS '-DM' OR
*     PFWA_ITEM_IO-MATNR CS '-DP' OR
*     PFWA_ZZAUSP-PRODGRDE <> 'PF'.
*    PFWA_ITEM_IO-GDQTY = PFWA_ITEM_IO-DCEMN.                           "chip/Good die qty
*  ELSE.
*    PFWA_ITEM_IO-BDQTY = PFWA_ITEM_IO-DCEMN.                           "chip/Bad die qty
*  ENDIF.
*060519<--D
ENDFORM.                    " GET_GOOD_BAD_DIE_QTY
*&---------------------------------------------------------------------*
*&      Form  GET_DIE_WAFER_QTY
*&---------------------------------------------------------------------*
FORM GET_DIE_WAFER_QTY  USING    PFV_PTYPE
                                 PFV_VGBEL
                                 PFV_ZTYPE.

  DATA: PFWA_ZZAUSP LIKE ZZAUSP.
  DATA: BEGIN OF PF_DIEW OCCURS 0,
         PRODDEVC LIKE ZZAUSP-PRODDEVC,
         GDQTY LIKE  ZMWHG-CHQTY,       "(X) Good die Qty
         BDQTY LIKE  ZMWHG-CHQTY,       "(X) Bad die Qty
       END OF PF_DIEW.
  DATA: BEGIN OF PF_MATRMK OCCURS 0,
         REMAK(300),
       END OF PF_MATRMK.
  DATA: WA_ZZAUSP LIKE ZZAUSP.
  DATA: PFV_REMAK(300)  TYPE C,
        PFV_QTY(8)     TYPE P DECIMALS 0,
        PFV_QTY_MAT(8) TYPE P DECIMALS 0,
        PFV_QTYC(08)    TYPE C,
        PFV_GQTY(08),
        PFV_BQTY(08),
        PFV_MQTY(08).
  CHECK PFV_PTYPE = 'D'.              "從外面拉進來判斷
  LOOP AT I_ITEM WHERE VBELN = PFV_VGBEL
                 AND   ZTYPE = PFV_ZTYPE.
    SELECT SINGLE * INTO PFWA_ZZAUSP FROM  ZZAUSP
                                     WHERE MATNR = I_ITEM-MATNR.
    MOVE: PFWA_ZZAUSP-PRODDEVC TO PF_DIEW-PRODDEVC,
          I_ITEM-GDQTY TO PF_DIEW-GDQTY,
          I_ITEM-BDQTY TO PF_DIEW-BDQTY.
    COLLECT PF_DIEW.
  ENDLOOP.

  SORT PF_DIEW.
  LOOP AT PF_DIEW.
    AT END OF PRODDEVC.
      SELECT SINGLE * INTO PFWA_ZZAUSP FROM  ZZAUSP
                                       WHERE PRODDEVC = PF_DIEW-PRODDEVC
                                       AND   MTART    = 'FERT'
                                       AND   PRODGSDE <> 0.
      IF SY-SUBRC <> 0.
        MESSAGE E000 WITH PF_DIEW-PRODDEVC 'no gross die!!'.
      ELSE.
        SUM.
        PFV_QTY_MAT = ( PF_DIEW-GDQTY + PF_DIEW-BDQTY ) / PFWA_ZZAUSP-PRODGSDE.
        PFV_QTY = PFV_QTY + PFV_QTY_MAT.

        IF PFV_ZTYPE = 'I' OR PFV_ZTYPE = 'F' OR  PFV_ZTYPE = 'P'.
          CLEAR PF_MATRMK.
          PF_MATRMK-REMAK = PFWA_ZZAUSP-ZDESC.
          WRITE: PFV_QTY_MAT TO PFV_MQTY DECIMALS 0.

          CONCATENATE '(' PF_MATRMK-REMAK ')' INTO PF_MATRMK-REMAK.
          CONCATENATE PFV_MQTY 'pc of' PF_DIEW-PRODDEVC PF_MATRMK-REMAK
                 INTO PF_MATRMK-REMAK  SEPARATED BY SPACE.
          APPEND PF_MATRMK.
        ENDIF.
      ENDIF.
    ENDAT.
    AT LAST.
      SUM.
      WRITE: PF_DIEW-GDQTY TO PFV_GQTY DECIMALS 0,
             PF_DIEW-BDQTY TO PFV_BQTY DECIMALS 0,
             PFV_QTY       TO PFV_QTYC DECIMALS 0.
      CONCATENATE '  ** ' PFV_GQTY 'pcs of good die +' PFV_BQTY 'pcs of bad die ='
                  PFV_QTYC 'pc of wafer.'  INTO  PFV_REMAK
             SEPARATED BY SPACE.
    ENDAT.
  ENDLOOP.

  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMAK
                                      PFV_VGBEL
                                      PFV_ZTYPE
                                      ''.
*-- Only invoice & free invoice
  IF NOT PF_MATRMK[] IS INITIAL.
    LOOP AT PF_MATRMK.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PF_MATRMK-REMAK
                                          PFV_VGBEL
                                          PFV_ZTYPE
                                          ''.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " GET_DIE_WAFER_QTY
*&---------------------------------------------------------------------*
*&      Form  GET_WAER_DIE_LIST
*&---------------------------------------------------------------------*
FORM GET_WAFER_DIE_LIST  USING   PFWA_HEAD STRUCTURE  I_HEAD.

  DATA: PFWA_PO01 LIKE ZSDPK_T01,   "需顯示GOOD/BAD die list by wafer 的客戶
        PF_ZMWHG  LIKE ZMWHG OCCURS 0 WITH HEADER LINE.

  DATA: BEGIN OF PF_LOT OCCURS 0,
     CNT(4) TYPE N,
     CHARG LIKE LIPS-CHARG,
     WERKS LIKE LIPS-WERKS,
     MATNR LIKE LIPS-MATNR,
    END OF PF_LOT.
  DATA: BEGIN OF PF_RMK OCCURS 0,
     REMARK(300)  TYPE C,
    END OF PF_RMK.
  DATA: BEGIN OF PFWA_WID,
      T1(10)   TYPE N,
      T2(02)   TYPE N,
      T3(10)   TYPE N,
    END OF PFWA_WID.

  DATA: PF_NCP     LIKE I_NCP OCCURS 0 WITH HEADER LINE,
        PFV_PGIDAY TYPE WADAT_IST,              "PGI date
        PFV_GDIE(8) TYPE P DECIMALS 0,
        PFV_WQTY(08) TYPE P DECIMALS 0,
        PFV_GSDIE(8) TYPE P DECIMALS 0,
        PFV_WNO(03).

  CHECK PFWA_HEAD-PRODTYPE = 'D' OR
        PFWA_HEAD-PRODTYPE = 'W'.


  SELECT SINGLE WADAT_IST INTO PFV_PGIDAY  FROM  LIKP
                                           WHERE VBELN = PFWA_HEAD-VGBEL.

  SELECT SINGLE * INTO PFWA_PO01 FROM  ZSDPK_T01
                                 WHERE KUNNR  =  PFWA_HEAD-KUNAG
                                 AND   VALIDF <= PFV_PGIDAY
                                 AND   VALIDT >= PFV_PGIDAY.

  CHECK SY-SUBRC = 0.

  LOOP AT I_ITEM WHERE VBELN = PFWA_HEAD-VGBEL
                 AND   ZTYPE = PFWA_HEAD-ZTYPE.
    CLEAR PF_LOT.
    MOVE: I_ITEM-CORDE  TO PF_LOT-CNT,
          I_ITEM-CHARG  TO PF_LOT-CHARG,
          I_ITEM-WERKS  TO PF_LOT-WERKS,
          I_ITEM-MATNR  TO PF_LOT-MATNR.
    COLLECT PF_LOT.
  ENDLOOP.

  LOOP AT PF_LOT.
    PERFORM GET_ZMWHG_DATA TABLES PF_ZMWHG
                           USING  PFV_PGIDAY
                                  PF_LOT-CHARG.
***- 是否要印NC chip
    IF PFWA_PO01-NCDIE = 'X'.
      PERFORM GET_NCHIP TABLES PF_NCP
                        USING  PF_LOT-CHARG.
    ENDIF.

    SORT PF_ZMWHG BY WAFERID.
    CLEAR: PFV_GDIE, PFV_WQTY.
    LOOP AT PF_ZMWHG.
      ADD: PF_ZMWHG-CHQTY TO PFV_GDIE.     "total Good die qty
    ENDLOOP.
    DESCRIBE TABLE PF_ZMWHG LINES PFV_WQTY. "Wafer qty

    SELECT SINGLE PRODGSDE INTO PFV_GSDIE FROM  ZZAUSP
                                          WHERE WERKS = PF_LOT-WERKS
                                          AND   MATNR = PF_LOT-MATNR.
    PFV_GSDIE = PFV_GSDIE *  PFV_WQTY.

    CLEAR PF_RMK-REMARK.
    PF_RMK-REMARK+5(08)  = PF_LOT-CNT.
    PF_RMK-REMARK+14(10) = PF_LOT-CHARG.
    PF_RMK-REMARK+25(08) = PFV_GDIE.
    PF_RMK-REMARK+34(09) = PFV_WQTY.

    IF PFWA_PO01-GROSS = 'X'.       "印Gross die
      PF_RMK-REMARK+44(09) = PFV_GSDIE.
    ENDIF.
    IF PFWA_PO01-NCDIE = 'X'.
      PF_RMK-REMARK+54(09) = PF_NCP-TQTY.
    ENDIF.
    APPEND PF_RMK.
**List lot good die list
    IF PFWA_PO01-LOTGD = 'X'.
      LOOP AT PF_ZMWHG.
        CLEAR PF_RMK-REMARK.
        SPLIT PF_ZMWHG-WAFERID AT '-' INTO: PFWA_WID-T1 PFWA_WID-T2 PFWA_WID-T3.
        CONCATENATE '#' PFWA_WID-T2
          INTO PFV_WNO.
        PF_RMK-REMARK+15(09) = PFV_WNO.
        PF_RMK-REMARK+25(08) = PF_ZMWHG-CHQTY.
        IF PFWA_PO01-NCDIE = 'X'.
          READ TABLE PF_NCP WITH KEY WNO = PFWA_WID-T2.
          IF SY-SUBRC = 0.
            PF_RMK-REMARK+55(08) = PF_NCP-NCQTY.
          ENDIF.
        ENDIF.
        APPEND PF_RMK.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  CHECK PF_RMK[] IS NOT INITIAL.
  PF_RMK-REMARK+5(08)  = 'Item'.
  PF_RMK-REMARK+14(10) = 'Key no'.
  PF_RMK-REMARK+25(08) = 'Good Die'.
  PF_RMK-REMARK+34(09) = 'Wafer Qty'.
  IF PFWA_PO01-GROSS = 'X'.       "印Gross die
    PF_RMK-REMARK+44(09) = 'Gross Die'.
  ENDIF.
  IF PFWA_PO01-NCDIE = 'X'.
    PF_RMK-REMARK+54(09) = 'NC Chip'.
  ENDIF.
  INSERT PF_RMK INDEX 1.
  PF_RMK-REMARK+5(08)  = SY-ULINE.
  PF_RMK-REMARK+14(10) = SY-ULINE.
  PF_RMK-REMARK+25(08) = SY-ULINE.
  PF_RMK-REMARK+34(09) = SY-ULINE.
  IF PFWA_PO01-GROSS = 'X'.       "印Gross die
    PF_RMK-REMARK+44(09) = SY-ULINE.
  ENDIF.
  IF PFWA_PO01-NCDIE = 'X'.
    PF_RMK-REMARK+54(09) = SY-ULINE.
  ENDIF.
  INSERT PF_RMK INDEX 2.

  LOOP AT PF_RMK.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PF_RMK-REMARK
                                        PFWA_HEAD-VGBEL
                                        PFWA_HEAD-ZTYPE
                                        ''.
  ENDLOOP.
ENDFORM.                    " GET_WAER_DIE_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_ZMWHG_DATA
*&---------------------------------------------------------------------*
FORM GET_ZMWHG_DATA  TABLES   PF_ZMWHG_IO STRUCTURE  ZMWHG
                     USING    PFV_BASED
                              PFV_CHARG.

  DATA: PF_ZMWHG LIKE ZMWHG OCCURS 0 WITH HEADER LINE.

  SELECT * INTO TABLE PF_ZMWHG FROM  ZMWHG
                               WHERE CHARG =  PFV_CHARG
                               AND   ZDATE <= PFV_BASED.

  SORT PF_ZMWHG BY ZDATE DESCENDING ZTIME DESCENDING. "最時間取新的 "M090914
  READ TABLE PF_ZMWHG INDEX 1.
  DELETE PF_ZMWHG WHERE ZTIME <> PF_ZMWHG-ZTIME.

  PF_ZMWHG_IO[] = PF_ZMWHG[].
ENDFORM.                    " GET_ZMWHG_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_NCHIP
*&---------------------------------------------------------------------*
FORM GET_NCHIP   TABLES   PF_NCP_O STRUCTURE I_NCP
                 USING    PFV_CHARG.
  DATA: PF_LNC       LIKE ZSD_NCBIN_DATA_SINOSCHIP OCCURS 0 WITH HEADER LINE,
        PFV_TQTY(08) TYPE P DECIMALS 0.

  CLEAR: PF_NCP_O, PF_NCP_O[], PFV_TQTY.
  MOVE: PFV_CHARG TO PF_LNC-KEY_NO.
  APPEND PF_LNC.

  CALL FUNCTION 'ZRFC_GET_BIN_DATA_4_SINOSCHIP'
    TABLES
      SINOBQ           = PF_LNC
    EXCEPTIONS
      CONNECTION_ERROR = 1
      OTHERS           = 2.

  LOOP AT PF_LNC WHERE BIN_ITEM >= 16
                 AND   BIN_ITEM <= 21.   "Sinochip 定義
    CLEAR PF_NCP_O.
    MOVE: PF_LNC-WAFER_ID+7(2)  TO PF_NCP_O-WNO,
          PF_LNC-BIN_QTY        TO PF_NCP_O-NCQTY.
    COLLECT PF_NCP_O.
    ADD PF_LNC-BIN_QTY  TO PFV_TQTY.   "summary
  ENDLOOP.
  SORT PF_NCP_O.
  READ TABLE PF_NCP_O INDEX 1.
  CHECK SY-SUBRC = 0.
  MOVE PFV_TQTY TO PF_NCP_O-TQTY.
  MODIFY PF_NCP_O INDEX 1 TRANSPORTING TQTY.
ENDFORM.                    " GET_NCHIP
*&---------------------------------------------------------------------*
*&      Form  CUSTOMER_LOT_RULE_FOR12
*&---------------------------------------------------------------------*
* 12" get customer lot id  & customer lot id special rule
* Maxim & NXP 不在此
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_CUST_LOTNO USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                                     PFWA_LIPS_I  STRUCTURE LIPS
                            CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.


***- Special rule
  CASE PFWA_HEAD_I-KUNAG.
    WHEN '0000001840' OR
         '0000001921' OR              "Himax
         '0000002206'.                "Microchip
      CLEAR PFWA_ITEM_IO-LOTNO.
    WHEN '0000002655' OR               "上海思力微 SILEAD
         '0000002644' OR
         '0000002747' OR              "ON-Semi
         '0000002766' OR
         '0000002768'.                "AIXIESHENG 愛協生
      PFWA_ITEM_IO-LOTNO = PFWA_LIPS_I-CHARG.
    WHEN OTHERS.
  ENDCASE.

  SELECT SINGLE * FROM  ZSD99
                  WHERE KUNNR = PFWA_HEAD_I-KUNAG.
  CHECK SY-SUBRC = 0.
  SELECT SINGLE * FROM  ZCLOTID
                  WHERE LOT_ID = PFWA_LIPS_I-CHARG.
  IF SY-SUBRC = 0.
    PFWA_ITEM_IO-LOTNO = ZCLOTID-CLOT_ID.
  ELSEIF ZSD99-CIDLCK = 'X'.
    MESSAGE E999 WITH PFWA_HEAD_I-KUNAG PFWA_LIPS_I-CHARG
                      ':沒有客戶 Lot Id無法出貨,請通知SA處理!!'.
  ENDIF.
***- Special rule
*  CHECK PFWA_HEAD_I-KUNAG = '0000000707' AND
*      ( PFWA_HEAD_I-PRODTYPE = 'D' OR
*        PFWA_HEAD_I-PRODTYPE = 'W' ).
*  CHECK ZCLOTID-CLOT_ID = ''.
*  MESSAGE E398(00) WITH 'ESMT-沒對應到客戶LOT NO:' PFWA_LIPS_I-CHARG.
ENDFORM.                    " CUSTOMER_LOT_RULE_FOR12
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_ITEM_ALL_PACKING
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_ALL         TABLES  PF_ITEM_IO STRUCTURE I_ITEM
                                  USING   PFWA_HEAD  STRUCTURE I_HEAD.
  DATA: PFWA_VBAP     LIKE VBAP,
        PFWA_LIPS     LIKE LIPS,
        PFV_TABIX     LIKE SY-TABIX,
        PFV_PRODGSDE  LIKE ZZAUSP-PRODGSDE,
        PF_DIEW       LIKE I_DIEW OCCURS 0 WITH HEADER LINE.

  CHECK PFWA_HEAD-VKORG = 'PSC1'.
  CHECK PFWA_HEAD-ZTYPE = 'P' OR               "P = Packing
        PFWA_HEAD-ZTYPE = 'I' OR               "I = Invoice
        PFWA_HEAD-ZTYPE = 'F' .                "F = Free invoice

**以Die 計價, 計算wafer qty - collect data
  PERFORM COLLECT_DIE_WAFER_QTY TABLES  PF_ITEM_IO
                                        PF_DIEW
                                USING   PFWA_HEAD.

*- Die only - 計算每個LOT 的WAFER QTY
  PERFORM FILL_WAFER_QTY TABLES PF_ITEM_IO                  "I030419
                         USING  PFWA_HEAD.                  "I030419

ENDFORM.                    " SP_RULE_FOR_ITEM_ALL
*&---------------------------------------------------------------------*
*&      Form  CHANGE_MATNR_FOR12
*&---------------------------------------------------------------------*
FORM GET_MATERIAL_BY_KURKI_12  USING    PFV_SPART_I
                                        PFV_KURKI_I
                               CHANGING PFV_MATNR_IO.

  DATA: PFV_LENGTH    TYPE I,
        PFV_KURBAS(2) TYPE C.
  CHECK PFV_SPART_I <> '02'.
  CHECK PFV_MATNR_IO+0(1) <> 'M'.

  PFV_LENGTH = STRLEN( PFV_MATNR_IO ) - 2.
*  PFV_LENGTH = PFV_LENGTH - 2.
  PFV_KURBAS  = PFV_MATNR_IO+PFV_LENGTH(2).
  CHECK PFV_KURBAS = PFV_KURKI_I+0(2).                          "M030519
  MOVE PFV_MATNR_IO+0(PFV_LENGTH) TO PFV_MATNR_IO.

ENDFORM.                    " CHANGE_MATNR_FOR12
*&---------------------------------------------------------------------*
*&      Form  COLLECT_DIE_WAFER_QTY
*&---------------------------------------------------------------------*
FORM COLLECT_DIE_WAFER_QTY   TABLES PF_ITEM_I  STRUCTURE I_ITEM
                                    PF_DIEW_O  STRUCTURE I_DIEW
                             USING  PFWA_HEAD  STRUCTURE I_HEAD.
  CLEAR: PF_DIEW_O, PF_DIEW_O[].

  LOOP AT PF_ITEM_I WHERE VBELN = PFWA_HEAD-VBELN
                    AND   ZTYPE = PFWA_HEAD-ZTYPE.
    MOVE-CORRESPONDING PF_ITEM_I TO PF_DIEW_O.
    COLLECT PF_DIEW_O.
  ENDLOOP.
ENDFORM.                    " COLLECT_DIE_WAFER_QTY
*&---------------------------------------------------------------------*
*&      Form  GET_GROSS_DIE
*&---------------------------------------------------------------------*
FORM GET_GROSS_DIE_COUNT_PSC1  USING    PFWA_ITEM_I  STRUCTURE I_ITEM
                                        PFWA_HEAD_I  STRUCTURE I_HEAD
                               CHANGING PFV_PRODGSDE_O.
  DATA: PFWA_ZZAUSP LIKE ZZAUSP.
  CLEAR PFV_PRODGSDE_O.
*<-I190905
  CHECK PFWA_HEAD_I-VKORG = 'PSC1'.
  PERFORM GET_WORKAREA_ZZAUSP USING     PFWA_ITEM_I-WERKS
                                        PFWA_ITEM_I-MATNR
                              CHANGING  PFWA_ZZAUSP.
  CHECK PFWA_ZZAUSP IS NOT INITIAL.
  PFV_PRODGSDE_O = PFWA_ZZAUSP-PRODGSDE.
*->I190905
*<-D190905
*  IF PFWA_HEAD_I-VKORG = 'MAX1'.
*    CLEAR: ZSDA02.
*    SELECT SINGLE * FROM  ZSDA02
*                    WHERE KDMAT =   PFWA_ITEM_I-MATNR+01(05)
*                    AND   KUNNR =   PFWA_ITEM_I-KUNAG.
*    CHECK SY-SUBRC = 0.
*    IF PFWA_HEAD_I-ZTYPE = 'P'.
*      CHECK ZSDA02-ZPACK IS NOT INITIAL.
*      PFV_PRODGSDE_O = ZSDA02-GDPWO.
*      EXIT.
*    ENDIF.
*    IF PFWA_HEAD_I-ZTYPE = 'I' OR
*       PFWA_HEAD_I-ZTYPE = 'F'.
*      CHECK ZSDA02-ZBILL IS NOT INITIAL.
*      PFV_PRODGSDE_O = ZSDA02-GDPWO.
*      EXIT.
*    ENDIF.
*  ENDIF.
*
*  IF PFWA_HEAD_I-VKORG = 'PSC1'.
*    PERFORM GET_WORKAREA_ZZAUSP USING     PFWA_ITEM_I-WERKS
*                                          PFWA_ITEM_I-MATNR
*                                CHANGING  PFWA_ZZAUSP.
*    CHECK PFWA_ZZAUSP IS NOT INITIAL.
*    PFV_PRODGSDE_O = PFWA_ZZAUSP-PRODGSDE.
*    EXIT.
*  ENDIF.
*->D190905
ENDFORM.                    " GET_GROSS_DIE
*&---------------------------------------------------------------------*
*&      Form  COMPOSE_GROSS_DIE_DESC
*&---------------------------------------------------------------------*
FORM COMPOSE_GROSS_DIE_DESC  USING    PFV_PRODGSDE
                             CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PFV_GSQTY(10) TYPE N,
        PFV_TSQTY(10) TYPE N.

  PFV_GSQTY = PFV_PRODGSDE.
  SHIFT PFV_GSQTY LEFT DELETING LEADING '0'.

  PFV_TSQTY = PFWA_ITEM_IO-DWEMN *  PFV_PRODGSDE.  "Total gross die
  SHIFT PFV_TSQTY LEFT DELETING LEADING '0'.
**這個應該是SHIP-TO I_HEAD-KUNNR
  CASE PFWA_ITEM_IO-KUNAG.
    WHEN '0000002526'.                       "Solomon
      CONCATENATE 'Gross die:' PFV_TSQTY
        INTO PFWA_ITEM_IO-4TH1.
      CONDENSE PFWA_ITEM_IO-4TH1.
    WHEN '0000001641'.                       "晶相
      CONCATENATE 'Gross die:' PFV_GSQTY  ',' 'Total die:' PFV_TSQTY
        INTO PFWA_ITEM_IO-4TH1 SEPARATED BY SPACE.
  ENDCASE.
ENDFORM.                    " COMPOSE_GROSS_DIE_DESC
*&---------------------------------------------------------------------*
*&      Form  GET_WAFER_LIST_FROM_SA
*&---------------------------------------------------------------------*
FORM GET_WAFER_LIST_FROM_SA  USING    PFV_VBELN
                                      PFV_CHARG
                             CHANGING PFV_WAFER.
  DATA: PFWA_RESHIP LIKE ZB2BI_OVT_RESHIP.

  SELECT SINGLE * INTO PFWA_RESHIP FROM  ZB2BI_OVT_RESHIP
                                   WHERE VBELN = PFV_VBELN
                                   AND   CHARG = PFV_CHARG.
  CHECK SY-SUBRC = 0.
  PFV_WAFER = PFWA_RESHIP-WAFER_ID.
ENDFORM.                    " GET_WAFER_LIST_FROM_SA

*&---------------------------------------------------------------------*
*&      Form  SP_RULE_IN_REMAKR_CUST
*&---------------------------------------------------------------------*
FORM SP_RULE_IN_REMAKR_CUST USING    PFWA_HEAD STRUCTURE I_HEAD.

  DATA: BEGIN OF PF_ZRMK OCCURS 0,
          REMAK(300)  TYPE C,
        END OF PF_ZRMK.

  DATA: PFWA_ZZAUSP LIKE ZZAUSP,
        VBAKX LIKE VBAK.                                    "I032221
  DATA: PFV_VBELN LIKE I_HEAD-VBELN,
        PFV_GSDE(5),
        PFV_TABIX LIKE SY-TABIX.                            "I101320

  CASE PFWA_HEAD-KUNAG.
    WHEN '0000001270'.                "Lapis
*      PERFORM GET_LAPIS_CUSTPN_DIE TABLES I_ITEM              "直接REMARK
*                                   USING  PFWA_HEAD.
      PF_ZRMK-REMAK+2 = '**Wafer Size:12"'.
      APPEND PF_ZRMK.
    WHEN '0000002249'.                "MAXIM
*      PERFORM GET_LAPIS_CUSTPN_DIE TABLES I_ITEM              "直接REMARK
*                                   USING  PFWA_HEAD.
      PF_ZRMK-REMAK+2 = '**MADE IN TAIWAN'.
      APPEND PF_ZRMK.
*032221-->I
    WHEN '0000004091' OR '0000004240'.       "江波龍 Longsys
      SELECT SINGLE * INTO VBAKX FROM VBAK WHERE VBELN = PFWA_HEAD-AUBEL.
      IF VBAKX-VTWEG = '04' AND VBAKX-SPART = '02'.
        PF_ZRMK-REMAK+2 = '*Original : TAIWAN'.
        APPEND PF_ZRMK.
      ENDIF.
*032221<--I
  ENDCASE.

*022520-->I
  CASE PFWA_HEAD-ZTYPE.
    WHEN 'P'.
      SELECT SINGLE * FROM ZB2BI_OVT WHERE KUNNR = PFWA_HEAD-KUNAG. "OVT gross die
      IF SY-SUBRC = 0.
        READ TABLE I_ITEM WITH KEY VBELN = PFWA_HEAD-VBELN      "Jillo 說1張delivery 只會有一種類part no
                                   ZTYPE = PFWA_HEAD-ZTYPE.
        IF SY-SUBRC = 0.
          SELECT SINGLE * INTO PFWA_ZZAUSP FROM  ZZAUSP
                 WHERE MATNR = I_ITEM-MATNR.
          IF SY-SUBRC = 0.
            WRITE PFWA_ZZAUSP-PRODGSDE TO PFV_GSDE NO-GROUPING.
            CONCATENATE '1 wafer Gross die :' PFV_GSDE 'dies'
                   INTO PF_ZRMK-REMAK+2 SEPARATED BY SPACE.
            APPEND PF_ZRMK.
          ENDIF.
        ENDIF.
      ENDIF.
  ENDCASE.
*022520<--I


  LOOP AT PF_ZRMK.

    IF PFWA_HEAD-ZTYPE = 'I'.
      PFV_VBELN = PFWA_HEAD-VBELN.
    ELSEIF PFWA_HEAD-ZTYPE = 'F' OR PFWA_HEAD-ZTYPE = 'P'.
      PFV_VBELN = PFWA_HEAD-VGBEL.
    ENDIF.

    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PF_ZRMK-REMAK
                                        PFV_VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
  ENDLOOP.

*101320-->I NXP 修改gross die description & add 說明行
  IF PFWA_HEAD-KUNAG = '0000002570' OR PFWA_HEAD-KUNAG = '0000002597'.
    IF PFWA_HEAD-ZTYPE = 'I' OR PFWA_HEAD-ZTYPE = 'P' OR
       PFWA_HEAD-ZTYPE = 'F'.
      CLEAR PFV_TABIX.
      LOOP AT I_ITEM_RE WHERE VBELN  = PFWA_HEAD-VBELN
                          AND ZTYPE  = PFWA_HEAD-ZTYPE
                          AND ZRTYPE = 'WAFDIE'.
        PFV_TABIX = SY-TABIX.
        REPLACE FIRST OCCURRENCE OF 'Dies' IN I_ITEM_RE-REMRK WITH 'Gross Dies'.
        MODIFY I_ITEM_RE INDEX PFV_TABIX.
      ENDLOOP.
      IF PFV_TABIX <> 0.
        ADD 1 TO PFV_TABIX.
        I_ITEM_RE-VBELN   = PFWA_HEAD-VBELN.
        I_ITEM_RE-ZTYPE   = PFWA_HEAD-ZTYPE.
        I_ITEM_RE-ZRTYPE = 'WAFDIE'.
        I_ITEM_RE-REMRK = '  This is Non-Probe wafer and gross die is for reference only.'.
        INSERT I_ITEM_RE INDEX PFV_TABIX.
      ENDIF.
    ENDIF.
  ENDIF.
*101320<--I

ENDFORM.                    " SP_RULE_IN_REMAKR_CUST
*&---------------------------------------------------------------------*
*&      Form  GET_LAPIS_CUSTPN_DIE
*&---------------------------------------------------------------------*
FORM GET_LAPIS_CUSTPN_DIE  TABLES PF_ITEM STRUCTURE I_ITEM
                            USING PFWA_HEAD STRUCTURE I_HEAD.

  DATA: BEGIN OF PFWA_DQTY OCCURS 0,
          VBELN       LIKE LIKP-VBELN,
          POSNR       LIKE LIPS-POSNR,
          MATNR       LIKE LIPS-MATNR,
          CUSTPN(30)  TYPE C,                   "customer material
          LSQTY(10)   TYPE N,                   "per wafer gross die qty
        END OF PFWA_DQTY.

  DATA: PFWA_ZZAUSP     LIKE ZZAUSP,
        PFV_REMAK(300)  TYPE C.

  LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
                  AND   ZTYPE = PFWA_HEAD-ZTYPE.
    PERFORM GET_WORKAREA_ZZAUSP USING PF_ITEM-WERKS
                                      PF_ITEM-MATNR
                             CHANGING PFWA_ZZAUSP.
    CHECK PFWA_ZZAUSP-PRODGSDE <> 0.
    CLEAR PFWA_DQTY.
    PFWA_DQTY-VBELN   = PF_ITEM-VBELN.
    PFWA_DQTY-POSNR   = PF_ITEM-UECHA.
    PFWA_DQTY-MATNR   = PF_ITEM-MATNR.
    PFWA_DQTY-CUSTPN  = PF_ITEM-KDMAT.
    PFWA_DQTY-LSQTY   = PFWA_ZZAUSP-PRODGSDE.
    PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PFWA_DQTY-LSQTY.
*    SHIFT PFWA_DQTY-LSQTY LEFT DELETING LEADING '0'.
    APPEND PFWA_DQTY.
  ENDLOOP.
  SORT PFWA_DQTY BY VBELN POSNR.
  DELETE ADJACENT DUPLICATES FROM PFWA_DQTY.

  LOOP AT PFWA_DQTY.
    AT FIRST.
      PFV_REMAK+2 = '**'.
    ENDAT.
    PFV_REMAK+4(40) = PFWA_DQTY-CUSTPN.
    CONCATENATE PFV_REMAK  '=' PFWA_DQTY-LSQTY 'die' INTO PFV_REMAK
         SEPARATED BY SPACE.

    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFWA_HEAD-VBELN
                                        PFWA_HEAD-ZTYPE
                                        ''.
    CLEAR PFV_REMAK.
  ENDLOOP.

ENDFORM.                    " GET_LAPIS_CUSTPN_DIE
*&---------------------------------------------------------------------*
*&      Form  GET_MAXIM_DATA
*&---------------------------------------------------------------------*
FORM GET_MAXIM_DATA  USING      PFWA_HEAD     STRUCTURE I_HEAD
                     CHANGING   PFWA_ITEM_IO  STRUCTURE I_ITEM.

  DATA: BEGIN OF PF_ZMX3 OCCURS 0.
          INCLUDE STRUCTURE ZSDMX03.
  DATA:   ZISTATUS LIKE VBAP-ZISTATUS,
        END OF PF_ZMX3.
  DATA: PFWA_ZMX2 LIKE ZSDMX02,
        PFWA_VBAP LIKE VBAP,
        PFV_TABIX TYPE SYTABIX.

  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZMX3  FROM  ZSDMX03
                                                WHERE CHARG = PFWA_ITEM_IO-CHARG.
  LOOP AT PF_ZMX3.
    PFV_TABIX = SY-TABIX.
    PERFORM GET_WORKAREA_VBAP USING     PF_ZMX3-CFSO
                                        PF_ZMX3-CFITM
                              CHANGING  PFWA_VBAP.
    CHECK PFWA_VBAP IS NOT INITIAL.
    PF_ZMX3-ZISTATUS = PFWA_VBAP-ZISTATUS.
    MODIFY PF_ZMX3 INDEX PFV_TABIX TRANSPORTING ZISTATUS.

*    SELECT SINGLE ZISTATUS INTO PF_ZMX3-ZISTATUS
*      FROM  VBAP
*      WHERE VBELN = PF_ZMX3-CFSO
*      AND   POSNR = PF_ZMX3-CFITM.
*    CHECK SY-SUBRC = 0.
*    MODIFY PF_ZMX3 INDEX PFV_TABIX TRANSPORTING ZISTATUS.
  ENDLOOP.
  CLEAR PF_ZMX3.
  SY-SUBRC = 4.
  LOOP AT PF_ZMX3 WHERE  ZISTATUS <> 'E0006'.   "Cancel
    EXIT.
  ENDLOOP.
  IF SY-SUBRC = 0.
    READ TABLE PF_ZMX3 INDEX 1.
    IF SY-SUBRC <> 0.
      CLEAR PF_ZMX3.
    ELSE.
      PFWA_ITEM_IO-LOTNO = PF_ZMX3-PMCCLT.         "Maxim cust lot id
      PFWA_ITEM_IO-POSEX = PF_ZMX3-MXINO+2(4).     "Maxim po item no
      PFWA_ITEM_IO-BSTNK = PF_ZMX3-MAXPO.          "Maxim po no
      PFWA_ITEM_IO-BSTKD = PF_ZMX3-MAXPO.          "Maxim po no
    ENDIF.
  ENDIF.
  PERFORM GET_WORKAREA_ZSDMX02 USING    PF_ZMX3-MAXPO
                                        PF_ZMX3-MXINO
                               CHANGING PFWA_ZMX2.
*  SELECT SINGLE * INTO PFWA_ZMX2 FROM  ZSDMX02
*                                 WHERE MAXPO = PF_ZMX3-MAXPO
*                                 AND   MXINO = PF_ZMX3-MXINO.
*  IF SY-SUBRC <> 0.
  IF PFWA_ZMX2 IS INITIAL.
    MESSAGE E000 WITH PFWA_ITEM_IO-CHARG 'No Maxim data exist!!'.
  ELSE.
    PFWA_ITEM_IO-KDMAT = PFWA_ZMX2-MXPRT.          "Maxim part no
  ENDIF.
ENDFORM.                    " GET_MAXIM_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_NXP_DATA
*&---------------------------------------------------------------------*
FORM GET_NXP_DATA  USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                  CHANGING  PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFV_NXPENG  TYPE C,                     "判斷是否為ENG
        PFWA_VBAK   LIKE VBAK,
        PFWA_VBAP   LIKE VBAP,
        PFWA_VBKD   LIKE VBKD,
        PFWA_NXP3B2 LIKE ZSDNXP3B2.
**先檢查該ITEM對應的訂單是否為ENG LOT
  PERFORM GET_WORKAREA_VBAP USING     PFWA_ITEM_IO-AUBEL
                                      PFWA_ITEM_IO-AUPOS
                            CHANGING  PFWA_VBAP.
  IF PFWA_VBAP-ZZENGLOT = 'Y'.
    PFV_NXPENG = 'Y'.
  ENDIF.

  PERFORM GET_WORKAREA_VBAK USING     PFWA_ITEM_IO-AUBEL
                            CHANGING  PFWA_VBAK.

  IF PFWA_HEAD_I-ZTYPE = 'P'.           "Packing
**--NXP 12NC (customer part no)
    IF PFV_NXPENG <> 'Y'.
      IF PFWA_VBAK-AUART <> 'Z012'.      "Reship
        CLEAR PFWA_NXP3B2.
        SELECT SINGLE * INTO PFWA_NXP3B2 FROM  ZSDNXP3B2
                                         WHERE VBELN = PFWA_ITEM_IO-VBELN
                                         AND   UECHA = PFWA_ITEM_IO-UECHA.
        IF SY-SUBRC <> 0.
          MESSAGE E000 WITH PFWA_ITEM_IO-CHARG 'No NXP 3B2 data(1) exist!!'.
        ELSE.
          PFWA_ITEM_IO-KDMAT = PFWA_NXP3B2-NXP12NC.
          PFWA_ITEM_IO-BSTKD = PFWA_NXP3B2-NXPPO.
        ENDIF.

*PO line (最後1行)
        SHIFT PFWA_NXP3B2-NXPINO LEFT DELETING LEADING '0'.
        SHIFT PFWA_NXP3B2-SHIPRITNO LEFT DELETING LEADING '0'.
        PFWA_ITEM_IO-9LINE = 'POLine:'.
        PFWA_ITEM_IO-9LINE+8(6)   = PFWA_NXP3B2-NXPINO.
        PFWA_ITEM_IO-9LINE+15(12) = 'Delivery no:'.
        PFWA_ITEM_IO-9LINE+28(10) = PFWA_NXP3B2-SHIPRNO.
        PFWA_ITEM_IO-9LINE+40(1)  = '/'.
        PFWA_ITEM_IO-9LINE+42(6)  = PFWA_NXP3B2-SHIPRITNO.
        PFWA_ITEM_IO-9LINE+56(14) = PFWA_NXP3B2-NXP12NC+0(14).
        PFWA_ITEM_IO-9LINE+70(35) = PFWA_NXP3B2-NXPPROD+0(35).
      ENDIF.
    ENDIF.

*-  nex reship 要顯示 user 在item 維護的PO no (if exist & not RMA NO)
    IF PFWA_VBAK-AUART = 'Z012'.
      PERFORM GET_WORKAREA_VBKD USING    PFWA_ITEM_IO-AUBEL
                                         PFWA_ITEM_IO-AUPOS
                                CHANGING PFWA_VBKD.
      CHECK PFWA_VBKD IS NOT INITIAL      AND
            PFWA_VBKD-BSTKD+0(3) <> 'RAM' AND
            PFWA_VBKD-BSTKD <> ''.
      PFWA_ITEM_IO-BSTNK = PFWA_VBKD-BSTKD.
    ENDIF.
  ENDIF.   "end of packing
*
  IF PFWA_HEAD_I-ZTYPE = 'I'.           "Invoice
    IF PFV_NXPENG <> 'Y'.
      IF PFWA_HEAD_I-FKART = 'F2'.           "Normal billing
        CLEAR PFWA_NXP3B2.
        SELECT SINGLE * INTO PFWA_NXP3B2 FROM  ZSDNXP3B2
                                         WHERE VBELN = PFWA_ITEM_IO-VGBEL     "delivery
                                         AND   UECHA = PFWA_ITEM_IO-VGPOS.
        IF SY-SUBRC <> 0.
          MESSAGE E000 WITH PFWA_ITEM_IO-CHARG 'No NXP 3B2 data(1) exist!!'.
        ELSE.
          PFWA_ITEM_IO-KDMAT = PFWA_NXP3B2-NXP12NC.
        ENDIF.

*PO line (最後1行)
        SHIFT PFWA_NXP3B2-NXPINO LEFT DELETING LEADING '0'.
        SHIFT PFWA_NXP3B2-SHIPRITNO LEFT DELETING LEADING '0'.
        PFWA_ITEM_IO-9LINE = 'LotID:'.
        PFWA_ITEM_IO-9LINE+7(08)   = PFWA_NXP3B2-NXPLOTID.
        PFWA_ITEM_IO-9LINE+16(12) = 'Delivery no:'.
        PFWA_ITEM_IO-9LINE+29(10) = PFWA_NXP3B2-SHIPRNO.
        PFWA_ITEM_IO-9LINE+40(1)  = '/'.
        PFWA_ITEM_IO-9LINE+42(6)  = PFWA_NXP3B2-SHIPRITNO.
        PFWA_ITEM_IO-9LINE+56(14) = PFWA_NXP3B2-NXP12NC+0(14).
        PFWA_ITEM_IO-9LINE+70(35) = PFWA_NXP3B2-NXPPROD+0(35).
      ELSEIF PFWA_HEAD_I-FKART = 'Z003'.
        PERFORM GET_NXP_PO_DATA_RE  USING PFWA_HEAD_I
                                 CHANGING PFWA_ITEM_IO.
      ENDIF.
    ENDIF.
  ENDIF.   "end of invoice

*for NXP Z012: 如果SO ITEM 是 merge PO ITEM 開立, 用退貨LOT去對應3B2 LOT, get NXP PO/ITEM


  IF PFWA_HEAD_I-ZTYPE = 'F'.          "Free invoice
    IF PFWA_HEAD_I-FKART = 'Z012'.

      PERFORM GET_NXP_PO_DATA_RE  USING PFWA_HEAD_I
                               CHANGING PFWA_ITEM_IO.

    ENDIF.  "end of free invoice

  ENDIF.
ENDFORM.                    " GET_NXP_DATA

*&---------------------------------------------------------------------*
*&      Form  SP_RULE_PACKING_RMK
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_PACKING_RMK  TABLES   PF_ITEM_RE_IO STRUCTURE I_ITEM_RE
                              USING    PFWA_HEAD       STRUCTURE I_HEAD.

  DATA: PFWA_VBAK LIKE VBAK,
        PFWA_VBAP LIKE VBAP.

  CHECK PFWA_HEAD-VKORG = 'PSC1'.                           "12 inch
  CASE PFWA_HEAD-KUNAG.
    WHEN '0000002497'.      "AP memory
      LOOP AT PF_ITEM_RE_IO WHERE VBELN  = PFWA_HEAD-VBELN
                             AND ZTYPE  = PFWA_HEAD-ZTYPE
                             AND ZRTYPE = 'WAFERID'.
        REPLACE ALL OCCURRENCES OF '-' IN PF_ITEM_RE_IO-REMRK WITH '~'.
        MODIFY PF_ITEM_RE_IO.
      ENDLOOP.

    WHEN '0000002570'.      "NXP
      READ TABLE I_ITEM WITH KEY VBELN  = PFWA_HEAD-VBELN
                                 ZTYPE  = PFWA_HEAD-ZTYPE.
      PERFORM GET_WORKAREA_VBAP USING     I_ITEM-AUBEL
                                          I_ITEM-AUPOS
                                CHANGING  PFWA_VBAP.
      PERFORM GET_WORKAREA_VBAK USING I_ITEM-AUBEL
                             CHANGING PFWA_VBAK.
      CHECK PFWA_VBAP-ZZENGLOT = 'Y'   OR
            PFWA_VBAK-AUART    = 'Z012'.   "eng po or reship not list po list
      LOOP AT PF_ITEM_RE_IO WHERE VBELN  = PFWA_HEAD-VBELN
                            AND   ZTYPE  = PFWA_HEAD-ZTYPE
                            AND   ZRTYPE = 'POLIST'.
        DELETE PF_ITEM_RE_IO.
      ENDLOOP.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " SP_RULE_PACKING_RMK
*&---------------------------------------------------------------------*
*&      Form  CHECK_FTP_RESEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_HEAD  text
*      -->P_PFV_ZAUTO  text
*----------------------------------------------------------------------*
FORM CHECK_FTP_RESEND  TABLES   PF_HEAD_IO STRUCTURE I_HEAD
                       USING    PFV_ZAUTO_I.
  DATA: PFV_ANSWE     TYPE C.
  IF PFV_ZAUTO_I = 'MANU'.
    LOOP AT PF_HEAD_IO WHERE ZFSET IS NOT INITIAL.
      PERFORM ASK_QUESTION USING    PF_HEAD_IO-VBELN
                                    PF_HEAD_IO-ZTYPE
                                    'FTP'
                           CHANGING PFV_ANSWE.
      CHECK PFV_ANSWE = 2.     "要重送就把FLAG清掉
      CLEAR: PF_HEAD_IO-ZFSET.
      MODIFY PF_HEAD_IO.
    ENDLOOP.
    EXIT.
  ENDIF.

  IF PFV_ZAUTO_I = 'AUTO'.
    CLEAR: PF_HEAD_IO, PF_HEAD_IO[], O_HEAD, O_HEAD[].
**先把所有選擇的做BACKUP
    APPEND LINES OF I_HEAD TO O_HEAD.
    APPEND LINES OF I_HEAD TO PF_HEAD_IO.
**把要執行的放到S_HEAD,因AUTO不送已送過的
    DELETE PF_HEAD_IO WHERE ZFSET IS NOT INITIAL.
    EXIT.
  ENDIF.
ENDFORM.                    " CHECK_FTP_RESEND
*&---------------------------------------------------------------------*
*&      Form  GET_FTP_FILE_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      <--P_PFV_FNAME  text
*----------------------------------------------------------------------*
FORM GET_MAIL_FTP_FILE_NAME  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                      PFV_ENC               "I190708
                             CHANGING PFV_FNAME_O.

  CLEAR: PFV_FNAME_O.
  PFV_FNAME_O = PFWA_HEAD_I-ZTYPE.
  IF PFWA_HEAD_I-ZTYPE = 'F' OR
     PFWA_HEAD_I-ZTYPE = 'D' OR
     PFWA_HEAD_I-ZTYPE = 'C'.
    CLEAR: PFV_FNAME_O.
    PFV_FNAME_O = 'I'.
  ENDIF.

  IF PFV_FNAME_O IS INITIAL AND
     PFWA_HEAD_I-VBELN IS INITIAL.
*    CONCATENATE SY-DATUM SY-UZEIT '.pdf'                   "D190708
    CONCATENATE SY-DATUM SY-UZEIT                           "I190708
      INTO PFV_FNAME_O.
  ENDIF.
  IF PFV_ENC = ''.                                          "I190708
    CONCATENATE PFWA_HEAD_I-VBELN PFV_FNAME_O '.pdf'
           INTO PFV_FNAME_O.
  ELSE.                                                     "I190708
    CONCATENATE PFWA_HEAD_I-VBELN PFV_FNAME_O '_' SY-DATUM SY-UZEIT '.pdf'"I190708
           INTO PFV_FNAME_O.                                "I190708
  ENDIF.                                                    "I190708
ENDFORM.                    " GET_FTP_FILE_NAME
*&---------------------------------------------------------------------*
*&      Form  DESELECT_DATA_EXCEL
*&---------------------------------------------------------------------*
FORM DESELECT_DATA_EXCEL TABLES PF_HEAD_I STRUCTURE I_HEAD.

*-- Delvery only - Packing for excel
  DELETE PF_HEAD_I WHERE ZTYPE <> 'P'.

ENDFORM.                    " DESELECT_DATA_EXCEL
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_PACKING_DATA
*&---------------------------------------------------------------------*
FORM DOWNLOAD_PACKING_DATA TABLES PF_HEAD_I STRUCTURE I_HEAD.

  RANGES: PFR_VGBEL FOR LIKP-VBELN.

  LOOP AT PF_HEAD_I.
    PFR_VGBEL-SIGN = 'I'.
    PFR_VGBEL-OPTION = 'EQ'.
    PFR_VGBEL-LOW = PF_HEAD_I-VBELN.
    APPEND PFR_VGBEL.
  ENDLOOP.

  CHECK PFR_VGBEL[] IS NOT INITIAL.

  SUBMIT ZSD_DEL_PACKING_ALL
            WITH S_VBELN  IN PFR_VGBEL
            WITH P_CALLRT EQ 'X'
            WITH P_ACT    EQ 'D'              "download excel
     AND RETURN.

ENDFORM.                    " DOWNLOAD_PACKING_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_UNIX_PATH
*&---------------------------------------------------------------------*
FORM GET_UNIX_PATH  USING    PFV_ITEM
                    CHANGING PFV_UPATH_O.
  CLEAR: PFV_UPATH_O.
  SELECT SINGLE * FROM  ZBC15
                  WHERE REPID = SY-CPROG
                  AND   ITEM  = PFV_ITEM.
  CHECK SY-SUBRC = 0.
  PFV_UPATH_O = ZBC15-UPATH.
ENDFORM.                    " GET_UNIX_PATH
*&---------------------------------------------------------------------*
*&      Form  SAVE_TO_UNIX
*&---------------------------------------------------------------------*
FORM SAVE_TO_UNIX  TABLES   PF_CONTENT_I STRUCTURE SOLISTI1
                   USING    PFV_FPATH_I.

  OPEN DATASET PFV_FPATH_I FOR OUTPUT IN BINARY MODE.
  IF SY-SUBRC <> 0 .
    MESSAGE E398(00) WITH 'Cannot open unix file for output:' PFV_FPATH_I.
  ENDIF.

  LOOP AT PF_CONTENT_I.
    TRANSFER PF_CONTENT_I TO PFV_FPATH_I.
    CHECK SY-SUBRC <> 0 .
    MESSAGE E398(00) WITH 'Cannot write to unix file:' PFV_FPATH_I.
  ENDLOOP.
  CLOSE DATASET PFV_FPATH_I.
ENDFORM.                    " SAVE_TO_UNIX
*&---------------------------------------------------------------------*
*&      Form  SAVE_PDF_FILE_TO_SERVER                 "U190708
*&---------------------------------------------------------------------*
*       call by P_JOBTPS = ''/'2'/'3'/'4'/'U'
*----------------------------------------------------------------------*
*1. for ftp to epsmc
*2. ((table : ZSD86 設定要儲存PDF的客戶))  --> 取消
*3. call from ilitek b2b
*4. call from SA PDF backup 程式
*----------------------------------------------------------------------*
FORM SAVE_PDF_FILE_TO_SERVER USING PFV_JOBTPS.
  DATA: PF_HEAD_IP LIKE I_HEAD OCCURS 0 WITH HEADER LINE,         "F2 Inv & Pack (for EPSMC)
        PF_HEAD_P LIKE I_HEAD OCCURS 0 WITH HEADER LINE,          "Pack
        PF_HEAD_IPX LIKE I_HEAD OCCURS 0 WITH HEADER LINE,        "M/O/P Inv & Pack (for NAS)
        PF_HEAD_BK  LIKE I_HEAD OCCURS 0 WITH HEADER LINE,
        PFV_EPSMC   TYPE C,
        PFV_SDFTP   TYPE C,                       "決定是否送FTP
        PFV_UPATH   TYPE LOCALFILE,
        PFV_FPATH   TYPE LOCALFILE,
        PFV_FILNE TYPE SO_OBJ_DES.

  CLEAR: PF_HEAD_IP, PF_HEAD_IP[], PF_HEAD_P, PF_HEAD_P[], PF_HEAD_IPX, PF_HEAD_IPX[], PF_HEAD_BK, PF_HEAD_BK[], PFV_SDFTP.
**如果不檢查這個會跑到PERFORM SEND_TO_SMARTFORM USING 'FILE' 會有DUMP
  IF P_JOBTPS = 'N' OR
     P_JOBTPS = 'I'.                                        "I021220
    EXIT.
  ENDIF.

  APPEND LINES OF I_HEAD TO PF_HEAD_BK.           "備份用

  APPEND LINES OF I_HEAD TO PF_HEAD_IP.
  APPEND LINES OF I_HEAD TO PF_HEAD_P.
  APPEND LINES OF I_HEAD TO PF_HEAD_IPX.

  DELETE PF_HEAD_IP WHERE ZTYPE <> 'I' AND ZTYPE <> 'P'.  "只留下Packing及F2 Invoice
  DELETE PF_HEAD_P WHERE ZTYPE <> 'P'.                    "只留下Packing
  DELETE PF_HEAD_IPX WHERE ZTYPE <> 'I' AND ZTYPE <> 'P'  "只留下Packing及F2/Credit/Debit/Free Invoice
                       AND ZTYPE <> 'C' AND ZTYPE <> 'D'
                       AND ZTYPE <> 'F'.
**只有PSC1要留下來
  DELETE PF_HEAD_IP WHERE VKORG <> 'PSC1'.
  DELETE PF_HEAD_P WHERE VKORG <> 'PSC1'.
*  DELETE PF_HEAD_IPX WHERE VKORG <> 'PSC1'.              "D190904

**處理FILE FTP --> EPSMC (inv & packing)
  IF PFV_JOBTPS IS INITIAL OR PFV_JOBTPS = '4'.        "4=Call from Billing Release(submit to approval)
    LOOP AT PF_HEAD_IP.
      READ TABLE I_ITEM WITH KEY VBELN = PF_HEAD_IP-VBELN
                                 ZTYPE = PF_HEAD_IP-ZTYPE.
      PERFORM CHECK_EPSMC_FLAG  USING     I_ITEM
                                CHANGING  PFV_EPSMC.
      IF PFV_EPSMC IS NOT INITIAL.
        IF PFV_SDFTP IS INITIAL.
          PFV_SDFTP = 'X'.
        ENDIF.

        CLEAR: I_HEAD, I_HEAD[].
        MOVE PF_HEAD_IP TO I_HEAD.
        APPEND I_HEAD.
        PERFORM SEND_TO_SMARTFORM USING 'FILE'          "Gengrate PDF data file TA_CONTENTS_BIN
                                      ''.
        CHECK TA_CONTENTS_BIN[] IS NOT INITIAL.

        PERFORM GET_UNIX_PATH USING    'A'              "/user/erpsd/epsmc/
                              CHANGING PFV_UPATH.
        CONCATENATE PFV_UPATH PF_HEAD_IP-VBELN PF_HEAD_IP-ZTYPE '.pdf'
          INTO PFV_FPATH.

        PERFORM SAVE_TO_UNIX TABLES TA_CONTENTS_BIN     "Save PDF file
                             USING  PFV_FPATH.
*  create properties file/complete file
        PERFORM CREATE_PROPERTIES_FILE USING PF_HEAD_IP
                                             PFV_FPATH.

        PERFORM UPDATE_ZSD64 USING PF_HEAD_IP.
      ENDIF.
    ENDLOOP.
  ENDIF.

**處理Call from b2b (only packing)
  IF PFV_JOBTPS = '2' OR PFV_JOBTPS = '3'.
    LOOP AT PF_HEAD_P.
      CLEAR: I_HEAD, I_HEAD[].
      MOVE PF_HEAD_P TO I_HEAD.
      APPEND I_HEAD.
      PERFORM SEND_TO_SMARTFORM USING 'FILE'                        "Gengrate PDF data file TA_CONTENTS_BIN
                                      ''.
      CHECK TA_CONTENTS_BIN[] IS NOT INITIAL.

      IF PFV_JOBTPS = '2'.
        PERFORM GET_UNIX_PATH USING    'C'                            "/user/mis/sapppco/sales/b2b/pdf/packing/
                              CHANGING PFV_UPATH.
      ELSEIF PFV_JOBTPS = '3'.
        PERFORM GET_UNIX_PATH USING    'B'                            "/user/mis/sapppco/sales/b2b/pdf/packing/ILITEK/
                              CHANGING PFV_UPATH.
      ENDIF.

      CONCATENATE PF_HEAD_P-VBELN PF_HEAD_P-ZTYPE '.pdf'
             INTO PFV_FILNE.

      PERFORM GET_FILE_NAME_SPECIAL_RULE  USING PF_HEAD_P           "檔名有特殊RULE
                                          PFV_JOBTPS
                                 CHANGING PFV_FILNE.

      CONCATENATE PFV_UPATH PFV_FILNE
             INTO PFV_FPATH.

      PERFORM SAVE_TO_UNIX TABLES TA_CONTENTS_BIN
                           USING  PFV_FPATH.
    ENDLOOP.
  ENDIF.

**處理每月送至NAS (inv & packing)
  IF PFV_JOBTPS = 'U'.
    LOOP AT PF_HEAD_IPX.
      CLEAR: I_HEAD, I_HEAD[].
      MOVE PF_HEAD_IPX TO I_HEAD.
      APPEND I_HEAD.
      PERFORM SEND_TO_SMARTFORM USING 'FILE'          "Gengrate PDF data file TA_CONTENTS_BIN
                                      ''.
      CHECK TA_CONTENTS_BIN[] IS NOT INITIAL.

      IF PF_HEAD_IPX-ZTYPE = 'P'.
        PERFORM GET_UNIX_PATH USING    'H'
                              CHANGING PFV_UPATH.
        CONCATENATE PFV_UPATH PF_HEAD_IPX-ERDAT+0(4) '_' PF_HEAD_IPX-VBELN '.pdf'"U190904
          INTO PFV_FPATH.
      ELSE.
        PERFORM GET_UNIX_PATH USING    'I'
                              CHANGING PFV_UPATH.
        CONCATENATE PFV_UPATH PF_HEAD_IPX-SIDAT+0(4) '_' PF_HEAD_IPX-VBELN '.pdf'"U190904
          INTO PFV_FPATH.
      ENDIF.

      PERFORM SAVE_TO_UNIX TABLES TA_CONTENTS_BIN
                            USING PFV_FPATH.
    ENDLOOP.
  ENDIF.

** FTP: EPSMC
  CLEAR PFV_SDFTP.                      "I092519 暫時
  IF PFV_SDFTP IS NOT INITIAL.
    PERFORM GET_UNIX_PATH USING    'A'
                          CHANGING PFV_UPATH.
    PERFORM FTP_FILES_TO_SERVER USING PFV_UPATH.
  ENDIF.

* D190904 --> 在ZSD20210N處理
*** FTP: NAS
*  IF PFV_JOBTPS = 'U'.
**  ... (待處理)
*  ENDIF.
* D190904 <--

  CLEAR: I_HEAD, I_HEAD[].
  APPEND LINES OF PF_HEAD_BK TO I_HEAD.

ENDFORM.                    " SAVE_PDF_FILE_TO_SERVER
*&---------------------------------------------------------------------*
*&      Form  CHECK_EPSMC_FLAG
*&---------------------------------------------------------------------*
FORM CHECK_EPSMC_FLAG  USING    PFWA_ITEM_I STRUCTURE I_ITEM
                       CHANGING PFV_EPSMC_O.
  DATA: PFWA_VBAK   LIKE VBAK,
        PFWA_ZZVBAK LIKE ZZVBAK.
  CLEAR: PFV_EPSMC_O.
  PERFORM GET_WORKAREA_VBAK USING    PFWA_ITEM_I-AUBEL
                            CHANGING PFWA_VBAK.
  PERFORM GET_WORKAREA_ZZVBAK USING    PFWA_ITEM_I-AUBEL
                              CHANGING PFWA_ZZVBAK.

  CHECK PFWA_VBAK-SPART = '02' OR
        PFWA_ZZVBAK-ZEPSC IS NOT INITIAL.
  PFV_EPSMC_O = 'X'.
ENDFORM.                    " CHECK_EPSMC_FLAG
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_DOC_AND_SAVEDATA
*&---------------------------------------------------------------------*
*只能在smart form顯示時才能修改的欄位(否則會影響程式判斷), 在這個perform 修改
*ex. KTC 只顯示14碼part no.  Maxim PSMC & customer lot id 交換
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_DOC_DISPLAY  TABLES   PF_HEAD_I  STRUCTURE I_HEAD
                                       PF_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFV_CHARG TYPE CHARG_D.
*MAXIM的CHARG和LOT NO在文件顯示要互換,但寫入ZBCOD又要是正常狀況
  LOOP AT PF_HEAD_I WHERE ZTYPE = 'P'.
    CHECK PF_HEAD_I-KUNAG = '0000002249'.       "MAXIM

    LOOP AT PF_ITEM_IO WHERE VBELN = PF_HEAD_I-VBELN
                       AND   ZTYPE = PF_HEAD_I-ZTYPE.
      CLEAR: PFV_CHARG.
      PFV_CHARG = PF_ITEM_IO-CHARG.
      PF_ITEM_IO-CHARG = PF_ITEM_IO-LOTNO.
      PF_ITEM_IO-LOTNO = PFV_CHARG.
      MODIFY PF_ITEM_IO.
    ENDLOOP.
  ENDLOOP.


*  DATA: WT_ITEM   LIKE I_ITEM OCCURS 0 WITH HEADER LINE.
*  DATA: PF_ZBCOD      LIKE ZBCOD OCCURS 0 WITH HEADER LINE,
*        PF_ITEM_TMP   LIKE I_ITEM OCCURS 0 WITH HEADER LINE.
*
*  DATA: PFWA_ZZAUSP LIKE ZZAUSP,
*        PFWA_VBAP   LIKE VBAP,
*        PFWA_3B2    LIKE ZSDNXP3B2,
*
*        PFV_KURKI(05),
*        PFV_TDNAM(16) TYPE C,
*        PFV_LOTBK(10) TYPE C,
*        PFV_CHAR30(30),
*        PFV_TABIX LIKE SY-TABIX.
*
*  REFRESH: I_WADIE.
*
*
*
**處理PACKING的部份
*LOOP AT PF_HEAD_I WHERE ( ZTYPE = 'I' OR ZTYPE = 'P' OR ZTYPE = 'F').
*    CLEAR: PF_ITEM_TMP, PF_ITEM_TMP[].        "I210616
*    LOOP AT PF_ITEM_IO WHERE VBELN = PF_HEAD_I-VBELN
*                       AND   ZTYPE = PF_HEAD_I-ZTYPE.
*      PFV_TABIX = SY-TABIX.
**- for all
**<-加到PERFORM GET_WAFERQTY_BY_PRODTYPE
*      IF PF_HEAD_I-PRODTYPE = 'D' AND PF_ITEM_IO-DWEMN <> 0.
*        MOVE 'ST' TO PF_ITEM_IO-WEMEH.
*      ENDIF.
**->加到PERFORM GET_WAFERQTY_BY_PRODTYPE
**<-加到GET_MATERIAL_BY_KURKI_12
***-- Non fuoundry change mater (Check vi KURIKI)
*      IF PF_HEAD_I-SPART <> '02'.
*        PERFORM CHANGE_MATNR_FOR12 USING    PF_ITEM_IO-KURKI
*                                   CHANGING PF_ITEM_IO-MATNR.
*      ENDIF.
**->加到GET_MATERIAL_BY_KURKI_12
**->加到SP_RULE_FOR_ITEM_BY_CUSTGP
*      IF PF_ITEM_IO-KUNAG IN R_KTC.
***-Ship TO part no   030519-->I   (ZBCOD-EKDMAT)
*        CONCATENATE PF_ITEM_IO-AUBEL PF_ITEM_IO-AUBEL INTO PFV_TDNAM.
*        CLEAR  PFV_CHAR30.
*        PERFORM GET_SHIP_TO_PN    USING PFV_TDNAM
*                               CHANGING  PFV_CHAR30.
*        IF PFV_CHAR30 <> ''.
*          CONCATENATE 'End Custom P/N:' PFV_CHAR30 INTO PF_ITEM_IO-4TH1.
*        ENDIF.
***- KTC Group Show 14碼 part no
*        PERFORM GET_WORKAREA_ZZAUSP USING PF_ITEM_IO-WERKS
*                                          PF_ITEM_IO-MATNR
*                                 CHANGING PFWA_ZZAUSP.
*        IF P_JOBTPS <> 'E' AND P_JOBTPS <> 'N'.             "I050819
*          IF PF_ITEM_IO-WERKS = 'PSC4' AND PFWA_ZZAUSP-PRODTYPE <> 'P'
*                                       AND PFWA_ZZAUSP-PRODTYPE <> 'S'."I101519
*            PF_ITEM_IO-MATNR = PF_ITEM_IO-MATNR+0(14).
*          ENDIF.
*        ENDIF.                                              "I050819
**<-加到SP_RULE_FOR_ITEM_BY_CUSTGP
*      ENDIF.
*<-放到SP_RULE_FOR_ITEM_PACKING
**-Packing
*      IF PF_HEAD_I-ZTYPE = 'P'.
***-  PSMC & customer lot id 交換
*        IF PF_ITEM_IO-KUNAG = '0000002249' .                          "Maxim
*          PFV_LOTBK        = PF_ITEM_IO-CHARG.
*          PF_ITEM_IO-CHARG = PF_ITEM_IO-LOTNO.
*          PF_ITEM_IO-LOTNO = PFV_LOTBK.
*** -- Clear datecode field
*          CASE PF_ITEM_IO-KUNAG.
*            WHEN '0000002644' OR '0000002747' OR              "ON-Semi
*                 '0000002766' OR '0000002768'.                "AIXIESHENG 愛協生
*              CLEAR PF_ITEM_IO-DCODE.
*          ENDCASE.
*        ENDIF.
*      ENDIF.
*<-放到SP_RULE_FOR_ITEM_PACKING
*      MODIFY PF_ITEM_IO INDEX PFV_TABIX.
*    ENDLOOP. "end of PF_ITEM
*<-搬到SP_RULE_FOR_ITEM_INVOICE
*    IF PF_HEAD_I-KUNAG = '0000002570' AND PF_HEAD_I-ZTYPE = 'I'.
***--先檢查該ITEM對應的訂單是否為ENG LOT
*      PERFORM GET_WORKAREA_VBAP USING     PF_ITEM_IO-AUBEL
*                                          PF_ITEM_IO-AUPOS
*                                CHANGING  PFWA_VBAP.
*      IF PFWA_VBAP-ZZENGLOT <> 'Y'.
*
*        SELECT * INTO TABLE WA_ZBCOD FROM ZBCOD
*                                     WHERE VBELN = PF_HEAD_I-VGBEL.
*
*        LOOP AT PF_ITEM_IO WHERE VBELN = PF_HEAD_I-VBELN
*                             AND ZTYPE = PF_HEAD_I-ZTYPE.
*          PFV_TABIX = SY-TABIX.
*          SELECT SINGLE * INTO PFWA_3B2 FROM ZSDNXP3B2
*           WHERE VBELN = PF_ITEM_IO-VGBEL AND UECHA = PF_ITEM_IO-VGPOS.
*          IF SY-SUBRC <> 0.
*            MESSAGE E000 WITH PF_HEAD_I-VBELN 'No NXP 3B2 data(1) exist!!'.
*          ELSE.
*            READ TABLE WA_ZBCOD WITH KEY CHARG = PFWA_3B2-CHARG.
*            IF SY-SUBRC = 0.
*              MOVE WA_ZBCOD-ZCARTNO TO PF_ITEM_IO-POSNR.
*              MODIFY PF_ITEM_IO INDEX PFV_TABIX TRANSPORTING POSNR.
*            ENDIF.
*          ENDIF.
*        ENDLOOP.
*        LOOP AT PF_ITEM_IO WHERE VBELN = PF_HEAD_I-VBELN
*                             AND ZTYPE = 'I'.
*          CLEAR WT_ITEM.
*          MOVE-CORRESPONDING PF_ITEM_IO TO WT_ITEM.
*          WT_ITEM-ITMNO = WT_ITEM-POSNR+2(4).
*          APPEND WT_ITEM.
*
*          DELETE PF_ITEM_IO.
*        ENDLOOP.
*        SORT WT_ITEM.
*        LOOP AT WT_ITEM.
*          MOVE-CORRESPONDING WT_ITEM TO PF_ITEM_IO.
*          APPEND PF_ITEM_IO.
*        ENDLOOP.
*      ENDIF.
*    ENDIF.  "end of 2570
*->搬到SP_RULE_FOR_ITEM_INVOICE
*  ENDLOOP.  "end of PF_HEAD


ENDFORM.                    " SP_RULE_FOR_DOC_AND_SAVEDATA
*&---------------------------------------------------------------------*
*&      Form  CREATE_PROPERTIES_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_HEAD_TMP  text
*      -->P_PFV_UPATH  text
*----------------------------------------------------------------------*
FORM CREATE_PROPERTIES_FILE  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                      PFV_UPATH_I.

  DATA: BEGIN OF PF_PROF OCCURS 0,
          TEXT(255) TYPE C,
        END OF PF_PROF.
  DATA: PFV_FPATH   TYPE LOCALFILE.

  CLEAR: PF_PROF, PF_PROF[], PFV_FPATH.
  CASE PFWA_HEAD_I-ZTYPE.
    WHEN 'P'.
      PF_PROF-TEXT = 'REPORT_ID=H1-3-PackingList'.
    WHEN 'I'.
      PF_PROF-TEXT = 'REPORT_ID=H1-4-InvoiceList'.
    WHEN OTHERS.
  ENDCASE.
  APPEND PF_PROF.
  CLEAR: PF_PROF.

  CONCATENATE 'CUSTOMER_ID=' PFWA_HEAD_I-KUNAG
    INTO PF_PROF-TEXT.
  CONDENSE PF_PROF.
  APPEND PF_PROF.
  CLEAR: PF_PROF.

  PF_PROF-TEXT        = 'CREATE_TIME='.
  CONCATENATE SY-DATUM+0(4) '-' SY-DATUM+4(2) '-' SY-DATUM+6(2)
         INTO PF_PROF-TEXT+12(10).
  WRITE: SY-UZEIT USING EDIT MASK '__:__:__'
          TO PF_PROF-TEXT+23(8).
  APPEND PF_PROF.
  CLEAR: PF_PROF.
  CONCATENATE PFV_UPATH_I '.properties'
    INTO PFV_FPATH.
  CONDENSE PFV_FPATH.

  OPEN DATASET PFV_FPATH FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  LOOP AT PF_PROF.
    TRANSFER PF_PROF TO PFV_FPATH.
  ENDLOOP.
  CLOSE DATASET PFV_FPATH.

  CLEAR: PFV_FPATH.
  CONCATENATE PFV_UPATH_I '.complete'
    INTO PFV_FPATH.
  CONDENSE PFV_FPATH.
  OPEN DATASET PFV_FPATH FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  CLOSE DATASET PFV_FPATH.

ENDFORM.                    " CREATE_PROPERTIES_FILE
*&---------------------------------------------------------------------*
*&      Form  FTP_FILES_TO_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_UPATH  text
*----------------------------------------------------------------------*
FORM FTP_FILES_TO_SERVER  USING    PFV_UPATH.
  DATA: PFWA_ZMMFTP     LIKE ZMMFTP,
        PFV_HANDL       TYPE I,           "連FTP的PROCESS ID
        PFV_COMMD(100)  TYPE C.
  PERFORM GET_FTP_CONNECT_INFO CHANGING PFWA_ZMMFTP.
  PERFORM CONNECT_DISCONN_TO_FTP  USING    PFWA_ZMMFTP
                                           'CONN'
                                  CHANGING PFV_HANDL.
**本地路徑
  CLEAR: PFV_COMMD.
  CONCATENATE 'lcd ' PFV_UPATH
    INTO PFV_COMMD SEPARATED BY SPACE.
  PERFORM FTP_FILE_TO_SERVER_CMD USING  PFV_HANDL
                                        PFV_COMMD.
**遠端路徑
  CLEAR: PFV_COMMD.
  PFV_COMMD = 'cd Temp_Repository'.
  PERFORM FTP_FILE_TO_SERVER_CMD USING  PFV_HANDL
                                        PFV_COMMD.
**送檔案
  CLEAR: PFV_COMMD.
  PFV_COMMD = 'mput *.pdf*'.
  PERFORM FTP_FILE_TO_SERVER_CMD USING  PFV_HANDL
                                        PFV_COMMD.
**斷ftp
  PERFORM CONNECT_DISCONN_TO_FTP USING    PFWA_ZMMFTP
                                          'DCON'
                                 CHANGING PFV_HANDL.
  PERFORM DELTE_FILES_FROM_LOCL_SERVER USING PFV_UPATH.

ENDFORM.                    " FTP_FILES_TO_SERVER
*&---------------------------------------------------------------------*
*&      Form  GET_FTP_CONNECT_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PFWA_ZMMFTP  text
*----------------------------------------------------------------------*
FORM GET_FTP_CONNECT_INFO  CHANGING PFWA_ZMMFTP_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF  PFWA_ZMMFTP_O FROM   ZMMFTP
                                                              WHERE  REMARK = SY-CPROG.
ENDFORM.                    " GET_FTP_CONNECT_INFO
*&---------------------------------------------------------------------*
*&      Form  FTP_FILE_TO_SERVER_CMD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_HANDL  text
*      -->P_PFV_COMMD  text
*----------------------------------------------------------------------*
FORM FTP_FILE_TO_SERVER_CMD  USING    PFV_HANDL
                                      PFV_UCOMD.
  DATA: BEGIN OF PF_RTUN OCCURS 0,
           ZWORD(30) TYPE C,
        END OF PF_RTUN.
  CALL FUNCTION 'FTP_COMMAND'
    EXPORTING
      HANDLE        = PFV_HANDL
      COMMAND       = PFV_UCOMD
    TABLES
      DATA          = PF_RTUN
    EXCEPTIONS
      TCPIP_ERROR   = 1
      COMMAND_ERROR = 2
      DATA_ERROR    = 3.
ENDFORM.                    " FTP_FILE_TO_SERVER
*&---------------------------------------------------------------------*
*&      Form  DELTE_FILES_FROM_LOCL_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_FPATH  text
*----------------------------------------------------------------------*
FORM DELTE_FILES_FROM_LOCL_SERVER  USING    PFV_UPATH_I.
  DATA: PFV_UXCOM LIKE   RLGRAP-FILENAME.
  DATA: BEGIN OF PF_RETN OCCURS 0,
          LINE(400) TYPE C,
        END OF PF_RETN.
  CLEAR: PFV_UXCOM, PF_RETN, PF_RETN[].
  CONCATENATE PFV_UPATH_I '/*.pdf*'
    INTO PFV_UXCOM.
  CONCATENATE 'rm' PFV_UXCOM
    INTO PFV_UXCOM SEPARATED BY SPACE.
  CALL 'SYSTEM' ID 'COMMAND' FIELD PFV_UXCOM
                ID 'TAB'     FIELD PF_RETN[].
ENDFORM.                    " DELTE_FILES_FROM_LOCL_SERVER
*&---------------------------------------------------------------------*
*&      Form  GET_OLD_PI_NO
*&---------------------------------------------------------------------*
FORM GET_OLD_PI_NO  USING    PFV_PVBEL_I
                    CHANGING PFV_OPVBE_O.
  CLEAR: PFV_OPVBE_O.
  SELECT SINGLE * FROM  ZSDPI_MAPPING
                  WHERE NPVBE = PFV_PVBEL_I.
  CHECK SY-SUBRC = 0.
  PFV_OPVBE_O = ZSDPI_MAPPING-OPVBE.
ENDFORM.                    " GET_OLD_PI_NO
*&---------------------------------------------------------------------*
*&      Form  SAVE_TO_ZSD64
*&---------------------------------------------------------------------*
FORM UPDATE_ZSD64 USING PFWA_HEAD STRUCTURE I_HEAD.

  DATA: PFWA_ZSD64 LIKE ZSD64.
  CLEAR: PFWA_ZSD64.
  SELECT SINGLE * INTO PFWA_ZSD64 FROM  ZSD64
                                  WHERE KUNNR = PFWA_HEAD-KUNAG
                                  AND   VBELN = PFWA_HEAD-VBELN.
  IF SY-SUBRC = 0.
    PFWA_ZSD64-ERDAT = SY-DATUM.
    CONCATENATE PFWA_HEAD-VBELN PFWA_HEAD-ZTYPE '.pdf'
      INTO PFWA_ZSD64-FILEN.
    MODIFY ZSD64 FROM PFWA_ZSD64.
    EXIT.
  ENDIF.

  PFWA_ZSD64-KUNNR = PFWA_HEAD-KUNAG.
  PFWA_ZSD64-VBELN = PFWA_HEAD-VBELN.
  IF PFWA_HEAD-ZTYPE = 'P'.
    PFWA_ZSD64-VBTYP = 'J'.
    PFWA_ZSD64-DELDT = PFWA_HEAD-ERDAT.
  ELSE.
    PFWA_ZSD64-VBTYP = 'M'.
    PFWA_ZSD64-DELDT = PFWA_HEAD-SIDAT.
  ENDIF.

  PFWA_ZSD64-ERDAT = SY-DATUM.
  CONCATENATE PFWA_HEAD-VBELN PFWA_HEAD-ZTYPE '.pdf'
    INTO PFWA_ZSD64-FILEN.
  MODIFY ZSD64 FROM PFWA_ZSD64.
ENDFORM.                    " SAVE_TO_ZSD64
**&---------------------------------------------------------------------*
**&      Form  CHECK_BOND_TYPE
**&---------------------------------------------------------------------*
*FORM CHECK_BOND_TYPE  TABLES   PF_ITEM   STRUCTURE I_ITEM
*                      USING    PFWA_HEAD STRUCTURE I_HEAD.
*
*  DATA: PF_ITEM_DP LIKE I_ITEM OCCURS 0 WITH HEADER LINE.
*  DATA: PFV_RESULT(1).
*
*  PF_ITEM_DP[] = PF_ITEM[].
*  READ TABLE PF_ITEM WITH KEY VBELN = PFWA_HEAD-VBELN
*                              ZTYPE = PFWA_HEAD-ZTYPE.
*  CLEAR PFV_RESULT.
*  LOOP AT PF_ITEM_DP WHERE VBELN =  PFWA_HEAD-VBELN
*                       AND ZTYPE =  PFWA_HEAD-ZTYPE
*                       AND BONDI <> PF_ITEM-BONDI.
*    PFV_RESULT = 'Y'.
*    EXIT.
*  ENDLOOP.
*  IF PFV_RESULT = 'Y'.
*    MESSAGE E000 WITH '保稅和非保稅的料號,不可以開再同一張invoice上'.
*  ENDIF.
*ENDFORM.                    " CHECK_BOND_TYPE
*&---------------------------------------------------------------------*
*&      Form  IMEX_SP_RULE_FOR12
*&---------------------------------------------------------------------*
FORM IMEX_GET_OTHER_ITEM_INFO  TABLES  PF_ITEM      STRUCTURE I_ITEM
                               USING   PFWA_HEAD    STRUCTURE I_HEAD.
  DATA: PFV_BDIE(1) TYPE C.

  CHECK PFWA_HEAD-ZTYPE = 'I' OR                  "I = Invoice
        PFWA_HEAD-ZTYPE = 'F'.                    "F = Free invoice

  LOOP AT PF_ITEM WHERE VBELN = PFWA_HEAD-VBELN
                  AND   ZTYPE = PFWA_HEAD-ZTYPE.
** BOM no (call from 進出口)
    PERFORM IMEX_GET_BOMNO USING    PFWA_HEAD
                           CHANGING PF_ITEM.
**-- 海關文件bad die 單依保稅維護的單價顯示 (data collect)
    PERFORM IMEX_CHECK_GOOD_BAD_DIE USING     PF_ITEM
                                              'UNBW'
                                    CHANGING  PFV_BDIE.
    IF PFV_BDIE IS NOT INITIAL.
**取得DIE的單價(UNITP)
      PERFORM IMEX_GET_UPRICR_BY_GBDIE USING    PFWA_HEAD
                                                'BAD'
                                         CHANGING PF_ITEM.
      MODIFY PF_ITEM.
      CONTINUE.
    ENDIF.

    IF PFV_BDIE IS INITIAL.  "Good die & unit price = 0 (invoice only)
      PERFORM IMEX_GET_UPRICR_BY_GBDIE USING    PFWA_HEAD
                                                'GOOD'
                                         CHANGING PF_ITEM.
      MODIFY PF_ITEM.
      CONTINUE.
    ENDIF.

    MODIFY PF_ITEM.
  ENDLOOP.
ENDFORM.                    " IMEX_SP_RULE_FOR12
*&---------------------------------------------------------------------*
*&      Form  GOOD_BAD_DIE_PART_NO
*&---------------------------------------------------------------------*
FORM IMEX_CHECK_GOOD_BAD_DIE  USING    PFWA_ITEM STRUCTURE I_ITEM
                                       PFV_MTART
                              CHANGING PFV_BDIE.
  DATA: PFWA_ZZAUSP LIKE ZZAUSP.

  CLEAR: PFV_BDIE.
  PERFORM GET_WORKAREA_ZZAUSP USING PFWA_ITEM-WERKS
                                    PFWA_ITEM-MATNR
                           CHANGING PFWA_ZZAUSP.
  CHECK ( PFWA_ZZAUSP-PRODTYPE = 'P' OR
          PFWA_ZZAUSP-PRODTYPE = 'D' OR
          PFWA_ZZAUSP-PRODTYPE = 'S' ) AND                  "I101519
          PFWA_ZZAUSP-MTART = PFV_MTART.
  PFV_BDIE = 'X'.
ENDFORM.                    " GOOD_BAD_DIE_PART_NO
*&---------------------------------------------------------------------*
*&      Form  GET_BOM_NO
*&---------------------------------------------------------------------*
FORM IMEX_GET_BOMNO  USING    PFWA_HEAD_I    STRUCTURE I_HEAD
                     CHANGING PFWA_ITEM_IO   STRUCTURE I_ITEM.

  DATA: PFV_LAPDOC  LIKE ZBS09-APDOC,
        PFV_MSG     LIKE ZMATERIAL-ERROR1.

  CALL FUNCTION 'Z_RFC_CHECK_BOM_NO'
    EXPORTING
      P_MATNR   = PFWA_ITEM_IO-MATNR
      P_PLANT   = PFWA_ITEM_IO-WERKS
      P_VBELN   = PFWA_ITEM_IO-VBELN
    IMPORTING
      P_APDOC   = PFV_LAPDOC
      P_MESSAGE = PFV_MSG.
  CHECK PFV_LAPDOC IS NOT INITIAL AND
        PFV_MSG IS INITIAL.
  CONCATENATE 'BOM No:' PFV_LAPDOC
    INTO PFWA_ITEM_IO-4TH1 SEPARATED BY SPACE.
ENDFORM.                    " GET_BOM_NO
*&---------------------------------------------------------------------*
*&      Form  GET_INCO_TERM_LIKP
*&---------------------------------------------------------------------*
FORM GET_ACTURE_INCOTERM_LIKP  USING    PFWA_LIKP_I STRUCTURE LIKP
                               CHANGING PFV_INCO1_O
                                        PFV_INCO2_O.
  CLEAR: PFV_INCO1_O, PFV_INCO2_O.
  PFV_INCO1_O = PFWA_LIKP_I-INCO1.
  PFV_INCO2_O = PFWA_LIKP_I-INCO2.
  CHECK PFWA_LIKP_I-ZINCO1 IS NOT INITIAL.
  PFV_INCO1_O = PFWA_LIKP_I-ZINCO1.
  PFV_INCO2_O = PFWA_LIKP_I-ZINCO2.
ENDFORM.                    " GET_INCO_TERM_LIKP
*&---------------------------------------------------------------------*
*&      Form  GET_INCO_TERM_VBRK
*&---------------------------------------------------------------------*
FORM GET_ACTURE_INCOTERM_VBRK  USING    PFWA_VBRK_I STRUCTURE VBRK
                               CHANGING PFV_INCO1_O
                                        PFV_INCO2_O.
  CLEAR: PFV_INCO1_O, PFV_INCO2_O.
  PFV_INCO1_O = PFWA_VBRK_I-INCO1.
  PFV_INCO2_O = PFWA_VBRK_I-INCO2.
  CHECK PFWA_VBRK_I-ZINCO1 IS NOT INITIAL.
  PFV_INCO1_O = PFWA_VBRK_I-ZINCO1.
  PFV_INCO2_O = PFWA_VBRK_I-ZINCO2.
ENDFORM.                    " GET_INCO_TERM_VBRK
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_ITEM_FREE_INV
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_FREE_INV TABLES  PF_ITEM_IO STRUCTURE I_ITEM
                               USING   PFWA_HEAD  STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'F'.                  "F = Free Invoice
  CHECK PFWA_HEAD-VKORG = 'PSC1'.                           "12吋
  IF PFWA_HEAD-KUNAG = '0000002570'.         "NXP
    LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD-VBELN
                       AND   ZTYPE = PFWA_HEAD-ZTYPE.
*  - Get data in header(CHECK_NXP_ENG直接放入GET_NXP_DAT中)
      PERFORM GET_NXP_DATA USING    PFWA_HEAD
                           CHANGING PF_ITEM_IO.
      MODIFY PF_ITEM_IO.
      CLEAR  PF_ITEM_IO.
    ENDLOOP.
  ENDIF.
*<-I210616
  PERFORM SP_RULE_FOR_ITEM_BY_CUSTGP TABLES PF_ITEM_IO
                                     USING  PFWA_HEAD.
*->I210616
ENDFORM.                    " SP_RULE_FOR_ITEM_FREE_INV
*&---------------------------------------------------------------------*
*&      Form  GET_NXP_PO_DATA_RE
*&---------------------------------------------------------------------*
FORM GET_NXP_PO_DATA_RE  USING     PFWA_HEAD_I  STRUCTURE I_HEAD
                         CHANGING  PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFWA_VBAK   LIKE VBAK,
        PFWA_VBAP   LIKE VBAP,
        PFWA_VBKD   LIKE VBKD,
        PFWA_NXP3B2 LIKE ZSDNXP3B2.

  DATA: WA_NXP01D LIKE ZSDNXP01D,
        WA_REVBAP LIKE VBAP,
        WA_REVBFA LIKE VBFA,
        WA_RELIPS LIKE LIPS.
  DATA: PFV_NEXPO LIKE VBAK-BSTNK.

  PERFORM GET_WORKAREA_VBAP USING     PFWA_ITEM_IO-AUBEL
                                      PFWA_ITEM_IO-AUPOS
                            CHANGING  PFWA_VBAP.

  PERFORM GET_WORKAREA_VBAK USING     PFWA_ITEM_IO-AUBEL
                            CHANGING  PFWA_VBAK.

  IF PFWA_ITEM_IO-BSTNK+0(4) = 'TW61'.
    PFV_NEXPO = PFWA_ITEM_IO-BSTNK+4(10).
  ELSE.
    PFV_NEXPO = PFWA_ITEM_IO-BSTNK.
  ENDIF.

  SELECT SINGLE * INTO WA_NXP01D FROM ZSDNXP01D
   WHERE NXPPO = PFV_NEXPO  AND NXPINO = PFWA_ITEM_IO-POSEX.

  IF SY-SUBRC = 0.
    PFWA_ITEM_IO-BSTNK = PFV_NEXPO.
  ELSE.
    SELECT SINGLE * INTO WA_REVBAP FROM VBAP WHERE VBELN = PFWA_VBAP-VGBEL    "get re so item
                                               AND POSNR = PFWA_VBAP-VGPOS.
    IF SY-SUBRC = 0.
      SELECT SINGLE * INTO WA_REVBFA FROM VBFA WHERE VBELV = WA_REVBAP-VGBEL  "get re dn
                                                 AND POSNV = WA_REVBAP-VGPOS
                                                 AND VBTYP_N = 'T'
                                                 AND RFMNG > 0.
      IF SY-SUBRC = 0.
        SELECT SINGLE * INTO WA_RELIPS FROM LIPS WHERE VBELN = WA_REVBFA-VBELN   "get re dn lot
                                                   AND POSNR = WA_REVBFA-POSNN.
        IF SY-SUBRC = 0.
          SELECT SINGLE * INTO PFWA_NXP3B2 FROM ZSDNXP3B2
            WHERE CHARG = WA_RELIPS-CHARG.
          IF SY-SUBRC = 0.
            MOVE PFWA_NXP3B2-NXPPO TO PFWA_ITEM_IO-BSTNK.                    "nxp po
            SHIFT PFWA_NXP3B2-NXPINO LEFT DELETING LEADING '0'.
            MOVE: PFWA_NXP3B2-NXPINO TO PFWA_ITEM_IO-POSEX.                  "nxp po item no
          ENDIF.                                            "PFWA_NXP3B2
        ENDIF.                                              "WA_RELIPS
      ENDIF.                                                "WA_REVBFA
    ENDIF.                                                  "WA_REVBAP
  ENDIF.                                                    "ZSDNXP01D

ENDFORM.                    " GET_NXP_PO_ITEM
*&---------------------------------------------------------------------*
*&      Form  GET_NXP_WAFER_LIST
*&---------------------------------------------------------------------*
FORM GET_NXP_WAFER_LIST  USING     PFWA_HEAD_I  STRUCTURE I_HEAD
                         CHANGING  PFWA_ITEM_IO STRUCTURE I_ITEM.

  DATA: PFWA_LIPS LIKE LIPS.

  CHECK PFWA_HEAD_I-ZTYPE = 'I'   AND
        PFWA_HEAD_I-FKART = 'F2'.

  PERFORM GET_WORKAREA_LIPS USING  PFWA_ITEM_IO-VGBEL
                                   PFWA_ITEM_IO-VGPOS
                          CHANGING PFWA_LIPS.
  IF PFWA_LIPS-LFIMG < 25.
    PERFORM  GET_WAFER_ID_LIST USING      PFWA_LIPS-CHARG
                                          PFWA_LIPS-MATNR
                               CHANGING   PFWA_ITEM_IO-4TH1.
    CONCATENATE 'Wafer ID:' PFWA_ITEM_IO-4TH1
      INTO PFWA_ITEM_IO-4TH1.
  ELSE.
    PFWA_ITEM_IO-4TH1 = 'Wafer ID: 01-25'.
  ENDIF.
ENDFORM.                    " GET_NXP_WAFER_LIST
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_REMARK_DEDMEMO
*&---------------------------------------------------------------------*
FORM GET_ITEM_REMARK_DEDMEMO  USING PFWA_HEAD STRUCTURE I_HEAD.
  CHECK PFWA_HEAD-ZTYPE = 'D'.       "D = Debit Memo


***SALES ORDER
  PERFORM GET_SO_LIST USING PFWA_HEAD-VBELN
                            PFWA_HEAD-ZTYPE
                            PFWA_HEAD-ZMTSO.

***REMARK
  PERFORM APPEND_DATA_REMARK  TABLES I_ITEM_RE
                               USING 'Remark:'
                                     PFWA_HEAD-VBELN
                                     PFWA_HEAD-ZTYPE
                                     ''.
***BRAND
  PERFORM GET_BRAND USING PFWA_HEAD-VBELN
                          PFWA_HEAD-ZTYPE.
***TRADE TERM
  PERFORM GET_TRADE_TERM USING PFWA_HEAD-VBELN
                               PFWA_HEAD-ZTYPE.
***固定文字
  PERFORM GET_FIX_INFO  USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE.
***取得BOND資訊
  PERFORM GET_BOND_INFO USING PFWA_HEAD-VBELN
                              PFWA_HEAD-ZTYPE
                              '4'.

***取得客戶付款BANK資訊
  PERFORM GET_BANK_INFO USING PFWA_HEAD.
ENDFORM.                    " GET_ITEM_REMARK_DEDMEMO
*&---------------------------------------------------------------------*
*&      Form  GET_DIVISION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIKP_I_VBELN  text
*      <--P_PF_HEAD_O  text
*----------------------------------------------------------------------*
FORM GET_DIVISION  USING    PFV_VBELN_I
                   CHANGING PFWA_HEAD_IO STRUCTURE I_HEAD.
**這段PERFORM的假設前提是ITEM都是同一個  DIVISION
  DATA: PFWA_LIPS LIKE LIPS,
        PFWA_VBRP LIKE VBRP.
  CLEAR: PFWA_HEAD_IO-SPART.
*<-I210217
**Packing / Free取LIPS第一筆來看
  IF PFWA_HEAD_IO-ZTYPE = 'P' OR
     PFWA_HEAD_IO-ZTYPE = 'F'.
    CLEAR: PFWA_HEAD_IO-VTWEG.
    PERFORM GET_WORKAREA_LIPS USING     PFV_VBELN_I
                                        ''
                              CHANGING  PFWA_LIPS.
    CHECK PFWA_LIPS IS NOT INITIAL.
    PFWA_HEAD_IO-SPART = PFWA_LIPS-SPART.
    PFWA_HEAD_IO-VTWEG = PFWA_LIPS-VTWEG.
    EXIT.
  ENDIF.
**Invoice / Proforma
  IF PFWA_HEAD_IO-ZTYPE = 'I' OR
     PFWA_HEAD_IO-ZTYPE = 'C' OR
     PFWA_HEAD_IO-ZTYPE = 'D' OR
     PFWA_HEAD_IO-ZTYPE = 'R'.
    PERFORM GET_WORKAREA_VBRP USING     PFV_VBELN_I
                                        ''
                              CHANGING  PFWA_VBRP.
    SELECT SINGLE * FROM  VBRP
                    WHERE VBELN = PFV_VBELN_I
                    AND   SPART <> ''.
    CHECK PFWA_VBRP IS NOT INITIAL.
    PFWA_HEAD_IO-SPART = PFWA_VBRP-SPART.
    EXIT.
  ENDIF.
*->I210217
*<-D210217
***Packing / Free取LIPS第一筆來看
*  IF PFWA_HEAD_IO-ZTYPE = 'P' OR
*     PFWA_HEAD_IO-ZTYPE = 'F'.
*    SELECT SINGLE * FROM  LIPS
*                    WHERE VBELN =  PFV_VBELN_I
*                    AND   SPART <> ''.
*    CHECK SY-SUBRC = 0.
*    PFWA_HEAD_IO-SPART = LIPS-SPART.
*    PFWA_HEAD_IO-VTWEG = LIPS-VTWEG.
*    EXIT.
*  ENDIF.
***Invoice / Proforma
*  IF PFWA_HEAD_IO-ZTYPE = 'I' OR
*     PFWA_HEAD_IO-ZTYPE = 'C' OR
*     PFWA_HEAD_IO-ZTYPE = 'D' OR
*     PFWA_HEAD_IO-ZTYPE = 'R'.
*    SELECT SINGLE * FROM  VBRP
*                    WHERE VBELN = PFV_VBELN_I
*                    AND   SPART <> ''.
*    CHECK SY-SUBRC = 0.
*    PFWA_HEAD_IO-SPART = VBRP-SPART.
*    EXIT.
*  ENDIF.
*->D210217
ENDFORM.                    " GET_DIVISION
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_UPRICR_BY_GBDIE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2229   text
*      <--P_PF_ITEM  text
*----------------------------------------------------------------------*
FORM IMEX_GET_UPRICR_BY_GBDIE  USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                                        PFV_FNCTN
                               CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  IF PFV_FNCTN = 'BAD'.
    SELECT SINGLE * FROM  ZSD170
                    WHERE MATNR = PFWA_ITEM_IO-MATNR.
    CHECK SY-SUBRC = 0.
    PFWA_ITEM_IO-UNITP = ZSD170-NP_USD.
    IF PFWA_ITEM_IO-WAERK = 'TWD'.
      CLEAR: PFWA_ITEM_IO-UNITP.
      PFWA_ITEM_IO-UNITP = ZSD170-NP_TWD.
    ENDIF.
    EXIT.
  ENDIF.
  IF PFV_FNCTN = 'GOOD' AND PFWA_HEAD_I-FKART = 'F2'
      AND ( PFWA_HEAD_I-SPART = '01' OR
       ( PFWA_HEAD_I-VTWEG = '02' AND PFWA_HEAD_I-SPART = '02' ) )
     AND PFWA_ITEM_IO-UNITP = 0.

    SELECT SINGLE * FROM  ZSD170A
                    WHERE MATNR =  PFWA_ITEM_IO-MATNR
                    AND   FKDAT <= PFWA_HEAD_I-SIDAT.
    CHECK SY-SUBRC = 0.
    PFWA_ITEM_IO-UNITP = ZSD170A-NP_USD.
    IF PFWA_ITEM_IO-WAERK = 'TWD'.
      CLEAR: PFWA_ITEM_IO-UNITP.
      PFWA_ITEM_IO-UNITP = ZSD170A-NP_TWD.
    ENDIF.
    EXIT.
  ENDIF.
ENDFORM.                    " IMEX_GET_UPRICR_BY_GBDIE
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_GBDIE_INFO_FOR_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM  text
*      -->P_PFWA_HEAD  text
*----------------------------------------------------------------------*
FORM IMEX_GET_GBDIE_INFO_FOR_REMARK  TABLES   PF_ITEM_I   STRUCTURE I_ITEM
                                     USING    PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: BEGIN OF PF_DINFO OCCURS 0,
          MATNR       TYPE MATNR,
          REMAK(300)  TYPE C,
          GBDIE(1)    TYPE C,         "G = GOOD DIE, B = BAD DIE
        END OF PF_DINFO.
  DATA: PFV_BDIE      TYPE C,
        PFV_UTPC(10)  TYPE C.
  CLEAR: PF_DINFO, PF_DINFO[].
**先收集REMARK資料
  LOOP AT PF_ITEM_I WHERE VBELN = PFWA_HEAD_I-VBELN
                    AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
    PF_DINFO-MATNR = PF_ITEM_I-MATNR.

    PERFORM IMEX_CHECK_GOOD_BAD_DIE USING     PF_ITEM_I
                                              'UNBW'
                                    CHANGING  PFV_BDIE.
    IF PFV_BDIE IS NOT INITIAL.
      CLEAR: ZSD170.
      SELECT SINGLE * FROM  ZSD170
                      WHERE MATNR = PF_ITEM_I-MATNR.
      CHECK SY-SUBRC = 0.
      PF_DINFO-GBDIE = 'B'.
      IF PF_ITEM_I-WAERK = 'TWD'.
        WRITE ZSD170-NP_TWD CURRENCY PF_ITEM_I-WAERK TO PFV_UTPC.
      ELSE.
        WRITE ZSD170-NP_USD CURRENCY PF_ITEM_I-WAERK TO PFV_UTPC.
      ENDIF.
      CONCATENATE '** The unit price of' PF_ITEM_I-MATNR
                   'is' PF_ITEM_I-WAERK PFV_UTPC '(only free charge).'
        INTO PF_DINFO-REMAK SEPARATED BY SPACE.
      APPEND PF_DINFO.
    ENDIF.

    IF PFV_BDIE IS INITIAL          AND
       PFWA_HEAD_I-ZTYPE = 'I'      AND
       PFWA_HEAD_I-FKART = 'F2'     AND
       PF_ITEM_I-UNITP = 0          AND                     "I082719
       ( PFWA_HEAD_I-SPART = '01' OR ( PFWA_HEAD_I-VTWEG = '02'   AND
                                       PFWA_HEAD_I-SPART = '02' ) ).     " "Good die  (invoice only)
      CLEAR: ZSD170A.
      SELECT SINGLE * FROM  ZSD170A
                      WHERE MATNR =  PF_ITEM_I-MATNR
                      AND   FKDAT <= PFWA_HEAD_I-SIDAT.
      CHECK SY-SUBRC = 0.
      PF_DINFO-GBDIE = 'G'.
      IF PF_ITEM_I-WAERK = 'TWD'.
        IF PF_ITEM_I-UNITP = ZSD170A-NP_TWD.
          WRITE ZSD170A-NP_TWD CURRENCY PF_ITEM_I-WAERK TO PFV_UTPC.
        ENDIF.
      ELSE.
        IF PF_ITEM_I-UNITP = ZSD170A-NP_USD.
          WRITE ZSD170A-NP_USD CURRENCY PF_ITEM_I-WAERK TO PFV_UTPC.
        ENDIF.
      ENDIF.
      CONCATENATE '** The unit price of' PF_ITEM_I-MATNR
                   'is' PF_ITEM_I-WAERK PFV_UTPC '(only free charge).'
        INTO PF_DINFO-REMAK SEPARATED BY SPACE.
      APPEND PF_DINFO.
    ENDIF.
  ENDLOOP.
  CHECK PF_DINFO[] IS NOT INITIAL.
  SORT PF_DINFO.
  DELETE ADJACENT DUPLICATES FROM PF_DINFO COMPARING ALL FIELDS.
**依收集的結果寫REMARK
**Bad die price
  LOOP AT PF_DINFO WHERE GBDIE = 'B'.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PF_DINFO-REMAK
                                        PFWA_HEAD_I-VBELN
                                        PFWA_HEAD_I-ZTYPE
                                        ''.
  ENDLOOP.
  CHECK PFWA_HEAD_I-ZTYPE = 'I'.
**Good die price
  LOOP AT PF_DINFO WHERE GBDIE = 'G'.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PF_DINFO-REMAK
                                        PFWA_HEAD_I-VBELN
                                        PFWA_HEAD_I-ZTYPE
                                        ''.
  ENDLOOP.
*    IF PFV_BDIE = 'Y'.     "bad die
*      SELECT SINGLE * INTO WA_ZSD170 FROM ZSD170
*       WHERE MATNR = PF_ITEM-MATNR.
*      IF SY-SUBRC = 0.
*        CLEAR I_BDPRICE.
*        MOVE-CORRESPONDING PF_ITEM  TO I_BDPRICE.
*        CASE PF_ITEM-WAERK.
*          WHEN 'USD'.
*            I_BDPRICE-UNITP = WA_ZSD170-NP_USD.
*          WHEN 'TWD'.
*            I_BDPRICE-UNITP = WA_ZSD170-NP_TWD.
*          WHEN OTHERS.
*            I_BDPRICE-UNITP = WA_ZSD170-NP_USD.
*        ENDCASE.
*
*        WRITE I_BDPRICE-UNITP TO PFV_CUP.
*        CONCATENATE 'The unit price of' I_BDPRICE-MATNR
*                    'is' PF_ITEM-WAERK PFV_CUP '(only free charge).'
*           INTO I_BDPRICE-REMAK SEPARATED BY SPACE.
*        APPEND I_BDPRICE.
*      ENDIF.
*    ELSEIF PF_ITEM-UNITP = 0 AND
*           PFWA_HEAD-ZTYPE = 'I' .   "Good die & unit price = 0 (invoice only)
***-- 海關文件free good die item 依SA維護的單價顯示 - commodity only (data collect)
*      PERFORM GET_WORKAREA_VBRK USING PF_ITEM-AUBEL
*                             CHANGING WA_VBRK.
*      IF WA_VBRK-FKART = 'F2' AND
*           ( WA_VBRK-SPART = '01' OR ( WA_VBRK-VTWEG = '02' AND WA_VBRK-SPART = '02' ) ).
*
*        SELECT SINGLE * INTO WA_ZSD170A FROM ZSD170A
*         WHERE MATNR = PF_ITEM-MATNR
*           AND FKDAT <= PFWA_HEAD-SIDAT.
*        CLEAR I_GDPRICE.
*        MOVE-CORRESPONDING PF_ITEM  TO I_GDPRICE.
*        IF SY-SUBRC = 0.
*          CASE PF_ITEM-WAERK.
*            WHEN 'USD'.
*              I_GDPRICE-UNITP = WA_ZSD170A-NP_USD.
*            WHEN 'TWD'.
*              I_GDPRICE-UNITP = WA_ZSD170A-NP_TWD.
*            WHEN OTHERS.
*              I_GDPRICE-UNITP = WA_ZSD170A-NP_USD.
*          ENDCASE.
*
*          WRITE I_GDPRICE-UNITP TO PFV_CUP.
*          CONCATENATE 'The unit price of' I_GDPRICE-MATNR
*                      'is' PF_ITEM-WAERK PFV_CUP '(only free charge).'
*             INTO I_GDPRICE-REMAK SEPARATED BY SPACE.
*
*          APPEND I_GDPRICE.
*        ENDIF.
*      ENDIF.
*    ENDIF.
****  DATA: PFV_REMAK(300)  TYPE C.
****
****  SORT I_GDPRICE.
****  SORT I_BDPRICE.
*****- Bad die price
****  LOOP AT I_BDPRICE WHERE VBELN = PFWA_HEAD-VBELN
****                      AND ZTYPE = PFWA_HEAD-ZTYPE.
****    AT NEW MATNR.
****
****      READ TABLE I_BDPRICE INDEX SY-TABIX.
****
****      PFV_REMAK = I_BDPRICE-REMAK.
****
****      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
****                                  USING   PFV_REMAK
****                                          PFWA_HEAD-VBELN
****                                          PFWA_HEAD-ZTYPE
****                                          ''.
****    ENDAT.
****
****  ENDLOOP.
****
****
*****- Good die price
****  IF PFWA_HEAD-ZTYPE = 'I'.
****    LOOP AT I_GDPRICE WHERE VBELN = PFWA_HEAD-VBELN
****                        AND ZTYPE = PFWA_HEAD-ZTYPE.
****      AT NEW MATNR.
****
****        READ TABLE I_GDPRICE INDEX SY-TABIX.
****
****        PFV_REMAK = I_GDPRICE-REMAK.
****
****        PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
****                                    USING   PFV_REMAK
****                                            PFWA_HEAD-VBELN
****                                            PFWA_HEAD-ZTYPE
****                                            ''.
****      ENDAT.
****
****    ENDLOOP.
****  ENDIF.

ENDFORM.                    " IMEX_GET_GBDIE_INFO_FOR_REMARK
*&---------------------------------------------------------------------*
*&      Form  GET_PINO_TO_WRITE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM_PIITEM  text
*      -->P_PF_HEAD  text
*      <--P_PFV_PVBEL  text
*----------------------------------------------------------------------*
FORM GET_PINO_TO_WRITE  TABLES   PF_PIITEM_I STRUCTURE I_ITEM_PIITEM
                        USING    PFWA_HEAD_I STRUCTURE I_HEAD
                        CHANGING PFV_PVBEL_O.
  CLEAR: PFV_PVBEL_O.
  CHECK PFWA_HEAD_I-PFLAG = 'X'.      "吃PI的INVOICE
  READ TABLE PF_PIITEM_I WITH KEY VBELN = PFWA_HEAD_I-VBELN
                                  ZTYPE = PFWA_HEAD_I-ZTYPE.
  CHECK SY-SUBRC = 0.
  PFV_PVBEL_O = PF_PIITEM_I-PERFI.
ENDFORM.                    " GET_PINO_TO_WRITE
*&---------------------------------------------------------------------*
*&      Form  GET_EXCAHNEG_RATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_I_KUNAG  text
*      <--P_PF_HEAD_O_KURRF  text
*----------------------------------------------------------------------*
FORM GET_EXCAHNEG_RATE  USING    PFWA_VBRK_I STRUCTURE VBRK
                        CHANGING PFV_KURRF_O.
  DATA: PFWA_KNA1 LIKE KNA1.
  CLEAR: PFV_KURRF_O.
  PERFORM GET_WORKAREA_KNA1 USING     PFWA_VBRK_I-KUNAG
                            CHANGING  PFWA_KNA1.
  CHECK PFWA_KNA1 IS NOT INITIAL.
  CHECK PFWA_KNA1-LAND1 = 'TW'.
  PFV_KURRF_O = PFWA_VBRK_I-KURRF.

ENDFORM.                    " GET_EXCAHNEG_RATE
*&---------------------------------------------------------------------*
*&      Form  GET_HUNIT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_I_VEKP  text
*----------------------------------------------------------------------*
FORM GET_HUNIT_DATA  TABLES   PF_VBFA_I STRUCTURE VBFA
                             PF_VEKP_O STRUCTURE VEKP.
  DATA: PF_VBFA_TMP LIKE VBFA OCCURS 0 WITH HEADER LINE,
        PF_VEKP_ORG LIKE VEKP OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_VEKP_O, PF_VEKP_O[], PF_VBFA_TMP, PF_VBFA_TMP[], PF_VEKP_ORG, PF_VEKP_ORG[].

  APPEND LINES OF PF_VBFA_I TO PF_VBFA_TMP.
  DELETE PF_VBFA_TMP WHERE VBTYP_N <> 'X'.
  SORT PF_VBFA_TMP BY VBELN.
  DELETE ADJACENT DUPLICATES FROM PF_VBFA_TMP COMPARING VBELN.
  CHECK PF_VBFA_TMP[] IS NOT INITIAL.
  SELECT * INTO CORRESPONDING FIELDS OF TABLE PF_VEKP_O FROM  VEKP
                                                        FOR ALL ENTRIES IN PF_VBFA_TMP
                                                        WHERE VENUM = PF_VBFA_TMP-VBELN.
  APPEND LINES OF PF_VEKP_O TO PF_VEKP_ORG.
  DELETE PF_VEKP_ORG WHERE UEVEL IS INITIAL.
  CHECK PF_VEKP_ORG[] IS NOT INITIAL.
  SELECT * APPENDING CORRESPONDING FIELDS OF TABLE PF_VEKP_O FROM  VEKP
                                                             FOR ALL ENTRIES IN PF_VEKP_ORG
                                                             WHERE VENUM = PF_VEKP_ORG-UEVEL.
ENDFORM.                    " GET_HUNIT_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_HANDING_UNIT_VEKP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VEKP_I  text
*      -->P_PF_VEKP_CURR  text
*      -->P_PFWA_LIPS_I_VBELN  text
*----------------------------------------------------------------------*
FORM GET_HANDING_UNIT_VEKP  TABLES   PF_VEKP_ALL STRUCTURE VEKP
                                     PF_VBFA_ALL STRUCTURE VBFA
                                     PF_VEKP_O   STRUCTURE VEKP
                            USING    PFV_VGBEL.
  DATA: PFWA_LIKP LIKE LIKP,
        PF_VBFA   LIKE VBFA OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_VEKP_O, PF_VEKP_O[].
  PERFORM GET_WORKAREA_LIKP USING     PFV_VGBEL
                            CHANGING  PFWA_LIKP.

  PERFORM GET_USEFUL_FLOW_DATA TABLES PF_VBFA_ALL
                                      PF_VBFA
                               USING  PFWA_LIKP-VBELN
                                      PFWA_LIKP-VBTYP
                                      'X'.
  SORT PF_VBFA BY VBELN.
  DELETE ADJACENT DUPLICATES FROM PF_VBFA COMPARING VBELN.
  LOOP AT PF_VBFA.
    LOOP AT PF_VEKP_ALL WHERE VENUM = PF_VBFA-VBELN.
      MOVE-CORRESPONDING PF_VEKP_ALL TO PF_VEKP_O.
      APPEND PF_VEKP_O.
      CLEAR: PF_VEKP_O.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " GET_HANDING_UNIT_VEKP
*&---------------------------------------------------------------------*
*&      Form  CHECK_MAIL_RESEND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_HEAD  text
*----------------------------------------------------------------------*
FORM CHECK_MAIL_RESEND  TABLES   PF_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFV_ANSWE     TYPE C.
  LOOP AT PF_HEAD_IO WHERE ZMSET IS NOT INITIAL.
    PERFORM ASK_QUESTION USING    PF_HEAD_IO-VBELN
                                  PF_HEAD_IO-ZTYPE
                                  'MAIL'
                         CHANGING PFV_ANSWE.
    CHECK PFV_ANSWE = 2.
    CLEAR: PF_HEAD_IO-ZMSET.
    MODIFY PF_HEAD_IO.
  ENDLOOP.
ENDFORM.                    " CHECK_MAIL_RESEND
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_MCHA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_WERKS  text
*      -->P_PFV_MATNR  text
*      -->P_PFV_CHARG_T  text
*      <--P_PFWA_MCHA  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_MCHA  USING    PFV_WERKS_I
                                 PFV_MATNR_I
                                 PFV_CHARG_I
                        CHANGING PFWA_MCHA_O.
  CLEAR: PFWA_MCHA_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_MCHA_O FROM  MCHA
                                                           WHERE MATNR = PFV_MATNR_I
                                                           AND   WERKS = PFV_WERKS_I
                                                           AND   CHARG = PFV_CHARG_I.
ENDFORM.                    " GET_WORKAREA_MCHA
*&---------------------------------------------------------------------*
*&      Form  GET_SELECT_DATA_SOLD_ZTYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_MWA_HEAD  text
*----------------------------------------------------------------------*
FORM GET_SELECT_DATA_SOLD_ZTYPE  CHANGING PFWA_SCHD_IO STRUCTURE MWA_HEAD.
  DATA: PFV_LINES TYPE I.
  CLEAR: PFWA_SCHD_IO-ZTYPE, PFWA_SCHD_IO-KUNAG.
  GET CURSOR LINE PFV_LINES.
  PFV_LINES = TC300_BILL-TOP_LINE - 1 + PFV_LINES.        "解決第二頁後的問題
  READ TABLE S_BKUNN INDEX PFV_LINES.
  PFWA_SCHD_IO-ZTYPE = S_BKUNN-ZTYPE.
  PFWA_SCHD_IO-KUNAG = S_BKUNN-BKUNN.
  PFWA_SCHD_IO-KUNNR = S_BKUNN-KUNNR.
  PFWA_SCHD_IO-SELEC = 1.                                 "換客戶時就回歸到原值
ENDFORM.                    " GET_SELECT_DATA_SOLD_ZTYPE
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSD104
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_HEAD_KUNAG  text
*      <--P_PFV_BYSHP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSD104  USING    PFV_KUNAG_I
                          CHANGING PFWA_ZSD104_O STRUCTURE ZSD104.
  CLEAR: PFWA_ZSD104_O.
  SELECT SINGLE * INTO CORRESPONDING FIELDS OF PFWA_ZSD104_O FROM  ZSD104
                                                             WHERE KUNNR = PFV_KUNAG_I.
ENDFORM.                    " CHECK_MAIL_BY_SHIPTO
*&---------------------------------------------------------------------*
*&      Form  GET_SHIP_TO_PN
*&---------------------------------------------------------------------*
FORM GET_SHIP_TO_PN    USING    PFV_TDNAM_I
                       CHANGING PFV_EKDMAT_O.

  DATA:  PF_LINES    LIKE TLINE  OCCURS 0 WITH HEADER LINE.
  CLEAR: PFV_EKDMAT_O.
  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_TDNAM_I
                               'ZQC3'
                               'VBBP'.
  READ TABLE PF_LINES INDEX 1.
  CHECK SY-SUBRC = 0.
  PFV_EKDMAT_O = PF_LINES-TDLINE.                          "End customer material no
ENDFORM.                    " GET_SHIP_TO_PN
*&---------------------------------------------------------------------*
*&      Form  FILL_WAFER_QTY
*&---------------------------------------------------------------------*
FORM FILL_WAFER_QTY  TABLES  PF_ITEM_IO   STRUCTURE I_ITEM
                     USING   PFWA_HEAD    STRUCTURE I_HEAD.

  DATA: BEGIN OF PF_LDIES OCCURS 0,
          CHARG LIKE LIPS-CHARG,
          DCEMN LIKE I_ITEM-DCEMN,   "chip qty
        END OF PF_LDIES.
  DATA: PFWA_ZMWH8H LIKE ZMWH8H,
        PFWA_ZZAUSP LIKE ZZAUSP.
  DATA: PFV_TABIX LIKE SY-TABIX.

  CHECK PFWA_HEAD-PRODTYPE = 'D' AND
        PFWA_HEAD-ZTYPE = 'P'.

  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD-VBELN
                     AND   ZTYPE = PFWA_HEAD-ZTYPE.
    MOVE-CORRESPONDING PF_ITEM_IO TO PF_LDIES.
    COLLECT PF_LDIES.
  ENDLOOP.


  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD-VBELN
                     AND   ZTYPE = PFWA_HEAD-ZTYPE.
    PFV_TABIX = SY-TABIX.
    SELECT SINGLE * INTO PFWA_ZMWH8H FROM  ZMWH8H             "取die 的主要料號
                                     WHERE VBELN = PF_ITEM_IO-VBELN
                                     AND   KEYNO = PF_ITEM_IO-CHARG
                                     AND   MATNR = PF_ITEM_IO-MATNR
                                     AND   FGFLAG = 'X'.
    CHECK SY-SUBRC = 0.
    PERFORM GET_WORKAREA_ZZAUSP USING     PF_ITEM_IO-WERKS
                                          PF_ITEM_IO-MATNR
                                CHANGING  PFWA_ZZAUSP.
    READ TABLE PF_LDIES WITH KEY CHARG =  PF_ITEM_IO-CHARG.
    CHECK SY-SUBRC = 0.
    IF PFWA_ZZAUSP-PRODGSDE <> 0.
      PF_ITEM_IO-DWEMN = PF_LDIES-DCEMN / PFWA_ZZAUSP-PRODGSDE.
      MODIFY PF_ITEM_IO INDEX PFV_TABIX.
    ELSE.
      MESSAGE E000 WITH PF_ITEM_IO-MATNR ' gross die qty = 0 (wafer01)'.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " FILL_WAFER_QTY
*&---------------------------------------------------------------------*
*&      Form  GET_CONTAIN_CHINESE_INCOTERM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      -->P_I_ICO2  text
*----------------------------------------------------------------------*
FORM REPLACE_CHINESE_INCOTERM  TABLES   PF_HEAD_IO STRUCTURE I_HEAD.
  DATA: PFV_INCO2 TYPE INCO2.

  LOOP AT PF_HEAD_IO.
    PERFORM CHECK_INCLUDE_CHINESE USING     PF_HEAD_IO-INCO2
                                  CHANGING  PFV_INCO2.
    CHECK PFV_INCO2 IS NOT INITIAL.
    PF_HEAD_IO-INCO2 = PFV_INCO2.
    MODIFY PF_HEAD_IO.
  ENDLOOP.
ENDFORM.                    " GET_CONTAIN_CHINESE_INCOTERM
*&---------------------------------------------------------------------*
*&      Form  CHECK_INCLUDE_CHINESE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_HEAD_I_INCO2  text
*      <--P_PFV_ICHIN  text
*----------------------------------------------------------------------*
FORM CHECK_INCLUDE_CHINESE  USING    PFV_STING
                            CHANGING PFV_ICHIN_O.
  DATA: BEGIN OF PF_STLEN OCCURS 0,
          ORDER     TYPE I,
          STRLN     TYPE I,
          ZCHAR(02) TYPE C,
        END OF PF_STLEN.
  DATA: PFV_LENTH     TYPE I,             "字串長度
        PFV_DOTIM     TYPE I,
        PFV_NSTOP     TYPE C.
  CLEAR: PFV_ICHIN_O, PFV_LENTH, PFV_DOTIM, PF_STLEN, PF_STLEN[].

  PFV_LENTH = STRLEN( PFV_STING ).

  DO PFV_LENTH TIMES.
    IF PFV_NSTOP IS INITIAL.
      PF_STLEN-STRLN = CHARLEN( PFV_STING+PFV_DOTIM ).
      PF_STLEN-ORDER = PFV_DOTIM.
      PF_STLEN-ZCHAR = PFV_STING+PFV_DOTIM(PF_STLEN-STRLN).
      IF PF_STLEN-ZCHAR IS INITIAL.
        PF_STLEN-ZCHAR = '#'.
      ENDIF.
      IF PF_STLEN-STRLN = 2.
        PFV_NSTOP = 'X'.
      ENDIF.
    ELSE.
      CLEAR: PFV_NSTOP.
    ENDIF.

    ADD 1 TO PFV_DOTIM.
    APPEND PF_STLEN.
    CLEAR: PF_STLEN.
  ENDDO.

  DELETE PF_STLEN WHERE STRLN = 0.
  CHECK PF_STLEN[] IS NOT INITIAL.
  READ TABLE PF_STLEN WITH KEY STRLN = 2.
  CHECK SY-SUBRC = 0.

  SORT PF_STLEN BY ORDER.
  CLEAR: PFV_DOTIM.
  LOOP AT PF_STLEN.
    IF PFV_DOTIM = 0.                 "第一個字元
      PFV_ICHIN_O = PF_STLEN-ZCHAR.
    ENDIF.

    IF PFV_DOTIM = 1.
      CONCATENATE PFV_ICHIN_O PF_STLEN-ZCHAR
        INTO PFV_ICHIN_O.
    ENDIF.
    IF PFV_DOTIM = 2.
      CONCATENATE PFV_ICHIN_O PF_STLEN-ZCHAR
            INTO PFV_ICHIN_O SEPARATED BY SPACE.
    ENDIF.
    PFV_DOTIM = PF_STLEN-STRLN.
  ENDLOOP.
*  OVERLAY PFV_REPLA WITH PFV_ICHIN_O.
  TRANSLATE PFV_ICHIN_O USING '# ' .
ENDFORM.                    " CHECK_INCLUDE_CHINESE
*&---------------------------------------------------------------------*
*&      Form  EXPORT_OTF
*&---------------------------------------------------------------------*
FORM EXPORT_OTF_TO_MEMORY USING PFV_PJOBS.
  DATA: PFV_MEMID(13) TYPE C.

  CHECK PFV_PJOBS = 'E' OR
        PFV_PJOBS = 'T'.
  CLEAR: PFV_MEMID.
  IF PFV_PJOBS = 'E'.              "ZBD40231 CALL
    PERFORM IMEX_SEND_TO_SMARTFORM USING 'PAG'
                                         ''.
    PFV_MEMID = 'ZBD40231'.
  ENDIF.

  IF PFV_PJOBS = 'T'.
    PFV_MEMID = 'ZSD_RT002_OTF'.
  ENDIF.
  PERFORM SEND_TO_SMARTFORM USING 'EML'
                                  ''.
  EXPORT I_OTFS TO MEMORY ID PFV_MEMID.
  LEAVE PROGRAM.
ENDFORM.                    " EXPORT_OTF
*&---------------------------------------------------------------------*
*&      Form  IMEX_GET_NOCHARGE_ITEM_REMARK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM  text
*      -->P_PFWA_HEAD  text
*----------------------------------------------------------------------*
FORM IMEX_GET_NOCHARGE_ITEM_REMARK  TABLES   PF_ITEM_I    STRUCTURE I_ITEM
                                    USING    PFWA_HEAD_I  STRUCTURE I_HEAD.
  DATA: PFV_BDIE       TYPE C,
        PFV_REMRK(300) TYPE C.
  DATA: BEGIN OF PF_DATA OCCURS 0,
          ITMNO(04)   TYPE  C,
        END OF PF_DATA.

  CLEAR: PF_DATA, PF_DATA[], PFV_REMRK.
  LOOP AT PF_ITEM_I WHERE VBELN = PFWA_HEAD_I-VBELN
                    AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
**8"用TANN判斷(未來12"也可能有)
    IF PF_ITEM_I-PSTYV = 'TANN'.
      PF_DATA-ITMNO = PF_ITEM_I-ITMNO.
      APPEND PF_DATA.
      CLEAR: PF_DATA.
      CONTINUE.
    ENDIF.
**整張FREE的也要
    IF PFWA_HEAD_I-ZTYPE = 'F'.
      PF_DATA-ITMNO = PF_ITEM_I-ITMNO.
      APPEND PF_DATA.
      CLEAR: PF_DATA.
      CONTINUE.
    ENDIF.
**12"KTC的GOOD DIE及BAD DIE都是FREE ITEM
***1.Bad Die
    PERFORM IMEX_CHECK_GOOD_BAD_DIE USING     PF_ITEM_I
                                              'UNBW'
                                    CHANGING  PFV_BDIE.
    IF PFV_BDIE IS NOT INITIAL.
      CLEAR: ZSD170.
      SELECT SINGLE * FROM  ZSD170
                      WHERE MATNR = PF_ITEM_I-MATNR.
      CHECK SY-SUBRC = 0.
      PF_DATA-ITMNO = PF_ITEM_I-ITMNO.
      APPEND PF_DATA.
      CLEAR: PF_DATA.
      CONTINUE.
    ENDIF.
***2.Good Die
    CHECK PFWA_HEAD_I-ZTYPE = 'I'      AND
          PFWA_HEAD_I-FKART = 'F2'     AND
          PF_ITEM_I-UNITP = 0          AND                  "I082719
        ( PFWA_HEAD_I-SPART = '01' OR ( PFWA_HEAD_I-VTWEG = '02'   AND
                                       PFWA_HEAD_I-SPART = '02' ) ).     " "Good die  (invoice only)
    CLEAR: ZSD170A.
    SELECT SINGLE * FROM  ZSD170A
                    WHERE MATNR =  PF_ITEM_I-MATNR
                    AND   FKDAT <= PFWA_HEAD_I-SIDAT.
    CHECK SY-SUBRC = 0.
    PF_DATA-ITMNO = PF_ITEM_I-ITMNO.
    APPEND PF_DATA.
    CLEAR: PF_DATA.
  ENDLOOP.
  CHECK PF_DATA[] IS NOT INITIAL.
  PFV_REMRK+2 = '** Item'.
  LOOP AT PF_DATA.
    IF SY-TABIX = 1.
      CONCATENATE PFV_REMRK PF_DATA-ITMNO
        INTO PFV_REMRK SEPARATED BY SPACE.
      CONTINUE.
    ENDIF.
    CONCATENATE PFV_REMRK PF_DATA-ITMNO
      INTO PFV_REMRK SEPARATED BY ','.
  ENDLOOP.
  CONCATENATE PFV_REMRK 'Free of charge, no commercial value, only for customs clearance.'
    INTO PFV_REMRK SEPARATED BY SPACE.
  PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                              USING   PFV_REMRK
                                      PFWA_HEAD_I-VBELN
                                      PFWA_HEAD_I-ZTYPE
                                      ''.
ENDFORM.                    " IMEX_GET_NOCHARGE_ITEM_REMARK
*&---------------------------------------------------------------------*
*&      Form  CREDITSO_HEADER_TEXT_REMAKR
*&---------------------------------------------------------------------*
FORM CREDITSO_HEADER_TEXT_REMAKR  USING    PFV_VBELN
                                           PFV_VGBEL
                                           PFV_ZTYPE.

  DATA: PFV_REMAK(300)  TYPE C,
        PF_LINES        LIKE TLINE        OCCURS 0 WITH HEADER LINE.

***訂單上long text 0003(Brand / Invoice Note)
  CLEAR: PFV_REMAK.

  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VGBEL
                              '0003'
                              'VBBK'.
  READ TABLE PF_LINES INDEX 1.
  IF SY-SUBRC = 0 AND PF_LINES-TDLINE <> ''.
    LOOP AT PF_LINES.
      IF PFV_REMAK IS INITIAL.
        CONCATENATE '**' PF_LINES-TDLINE
          INTO PFV_REMAK+2 SEPARATED BY SPACE.
      ELSE.
        CONCATENATE '  ' PF_LINES-TDLINE
          INTO PFV_REMAK+2 SEPARATED BY SPACE.
      ENDIF.

      CHECK PFV_REMAK IS NOT INITIAL.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFV_VBELN
                                          PFV_ZTYPE
                                          ''.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " CREDITSO_HEADER_TEXT_REMAKR
*&---------------------------------------------------------------------*
*&      Form  WRITE_RMA_WAFER_ID  I190703
*&---------------------------------------------------------------------*
FORM WRITE_RMA_WAFER_ID  USING    PFV_VBELN
                                  PFV_ZTYPE.
  DATA: PFV_REMAK(300)  TYPE C,
        PF_LINES        LIKE TLINE        OCCURS 0 WITH HEADER LINE.

***Billing上header text T04(RMA WaferID)
  CLEAR: PFV_REMAK.

  PERFORM GET_LONG_TEXT TABLES PF_LINES
                        USING  PFV_VBELN
                              'T04'
                              'VBBK'.
  READ TABLE PF_LINES INDEX 1.
  IF SY-SUBRC = 0 AND PF_LINES-TDLINE <> ''.
    PFV_REMAK+2 = '** Wafer ID:'.
    PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                USING   PFV_REMAK
                                        PFV_VBELN
                                        PFV_ZTYPE
                                        ''.
    LOOP AT PF_LINES.
      CLEAR: PFV_REMAK.
      CONCATENATE '  ' PF_LINES-TDLINE
             INTO PFV_REMAK+4 SEPARATED BY SPACE.

      CHECK PFV_REMAK IS NOT INITIAL.
      PERFORM APPEND_DATA_REMARK  TABLES  I_ITEM_RE
                                  USING   PFV_REMAK
                                          PFV_VBELN
                                          PFV_ZTYPE
                                          ''.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " WRITE_RMA_WAFER_ID
*&---------------------------------------------------------------------*
*&      Form  GET_FILE_NAME_SPECIAL_RULE  I190708
*&---------------------------------------------------------------------*
** PFV_JTYPE_I :
**   2: call from b2b sent packing pdf
**   9: call from b2b sent invoice pdf
*----------------------------------------------------------------------*
FORM GET_FILE_NAME_SPECIAL_RULE  USING    S_HEAD_I STRUCTURE I_HEAD
                                          PFV_JTYPE_I
                                 CHANGING PFV_FILNE_O.

  DATA: V_DN(10) TYPE C.                                    "I111119

  IF PFV_JTYPE_I = '2' OR PFV_JTYPE_I = '9'.

* .. ovt (b2b file name 要加上假日packing no.)
    SELECT SINGLE * FROM ZB2BI_OVT WHERE KUNNR = S_HEAD_I-KUNAG.
*    IF SY-SUBRC = 0.                                                      "D042920
    IF SY-SUBRC = 0 OR S_HEAD_I-KUNAG = '0000004192'.                      "I042920  ovt & cls
*      SELECT SINGLE * FROM ZHPACK_DN WHERE VBELN = S_HEAD_I-VGBEL.        "D111119
      SELECT SINGLE * FROM ZSD101 WHERE VBELN = S_HEAD_I-VGBEL."I111119
      IF SY-SUBRC = 0.
        V_DN = ZSD101-VBELN.                                "I111119
        SHIFT V_DN LEFT DELETING LEADING '0'.               "I111119
        IF S_HEAD_I-ZTYPE = 'P'.                         "PFV_JTYPE_I = '2' 時, Packing 不用經過加密rule
          CONCATENATE S_HEAD_I-VBELN S_HEAD_I-ZTYPE '('
*                      S_HEAD_I-ZTYPE ZHPACK_DN-PACKNO ')'   "D190819
*                      ZHPACK_DN-PACKNO ')'                  "I190819  "D111119
                      V_DN ')'                              "I111119
                      '.pdf'
                 INTO PFV_FILNE_O.
        ELSE.
          CONCATENATE S_HEAD_I-VBELN S_HEAD_I-ZTYPE '('
*                      S_HEAD_I-ZTYPE ZHPACK_DN-PACKNO ')_'  "D111119
                      S_HEAD_I-ZTYPE V_DN ')_'              "I111119
                      SY-DATUM SY-UZEIT '.pdf'
                 INTO PFV_FILNE_O.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.   "PFV_JTYPE_I = '2' OR PFV_JTYPE_I = '9'.

*.. ilitek (沒有 ZTYPE)
  IF PFV_JTYPE_I = '3'.
    IF S_HEAD_I-ZTYPE = 'P'.
      CONCATENATE S_HEAD_I-VBELN '.pdf'
             INTO PFV_FILNE_O.
    ENDIF.
  ENDIF.   "PFV_JTYPE_I = '3'

ENDFORM.                    " GET_FILE_NAME_SPECIAL_RULE
*&---------------------------------------------------------------------*
*&      Form  CHECK_CUST_ENCRYPT  I190708
*&---------------------------------------------------------------------*
FORM CHECK_CUST_ENCRYPT  USING    P_KUNNR    "sold-to
                         CHANGING P_ANS.
  DATA: V_TEXTLINE1(50) TYPE C.
  DATA: P_NAME2 LIKE KNA1-NAME1.
  CLEAR: P_ANS, V_TEXTLINE1.

  SELECT SINGLE * FROM ZSDEC_PWD WHERE KUNNR = P_KUNNR.

  IF SY-SUBRC = 0.
    SELECT SINGLE NAME1 INTO P_NAME2 FROM KNA1 WHERE KUNNR = P_KUNNR.
    IF ZSDEC_PWD-ENCRYPT_FG = 'Y' AND ZSDEC_PWD-PWD = ''.
      MESSAGE I000 WITH 'Sold-to:' P_KUNNR '已設為加密傳送, ' '但無設定加密密碼, 無法傳送!!'.
      EXIT.
    ELSE.
      IF ZSDEC_PWD-ENCRYPT_FG = 'Y'.
        CONCATENATE 'Sold-to:' P_KUNNR '的 Inv PDF 為 [加密] '
               INTO V_TEXTLINE1 SEPARATED BY SPACE.
      ELSEIF ZSDEC_PWD-ENCRYPT_FG = 'N'.
        CONCATENATE 'Sold-to:' P_KUNNR '的 Inv PDF 為 [不加密] '
               INTO V_TEXTLINE1 SEPARATED BY SPACE.
      ENDIF.
    ENDIF.
  ELSE.
    MESSAGE I000 WITH 'Sold-to:' P_KUNNR '尚未設定加密主檔, 無法傳送!!'.
    EXIT.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
    EXPORTING
      DEFAULTOPTION = 'Y'
      TEXTLINE1     = V_TEXTLINE1
      TEXTLINE2     = '請確認是否傳送?'
      TITEL         = P_NAME2
    IMPORTING
      ANSWER        = P_ANS.

ENDFORM.                    " CHECK_CUST_ENCRYPT
*&---------------------------------------------------------------------*
*&      Form  CHECK_CREATE_CUST_FOLDER   I190708
*&---------------------------------------------------------------------*
*       Create Csutomer Folder
*----------------------------------------------------------------------*
FORM CHECK_CREATE_CUST_FOLDER  USING    PFV_UPATH_I
                                        PFV_KUNNR_I    "sold-to
                               CHANGING PFV_UPATH_O.

  DATA: L_COM TYPE RLGRAP-FILENAME.
  DATA: DIRECTORY LIKE BTCH0000-TEXT80.

  DIRECTORY = PFV_UPATH_I.
  CONCATENATE PFV_UPATH_I PFV_KUNNR_I '/' INTO DIRECTORY.
  PFV_UPATH_O = DIRECTORY.

  CALL FUNCTION 'PFL_CHECK_DIRECTORY'
    EXPORTING
      DIRECTORY         = DIRECTORY
    EXCEPTIONS
      PFL_DIR_NOT_EXIST = 1.

  IF SY-SUBRC = 1.

    CONCATENATE 'mkdir' DIRECTORY INTO L_COM SEPARATED BY SPACE.

    CALL 'SYSTEM' ID 'COMMAND' FIELD L_COM.

    WAIT UP TO 2 SECONDS.

  ENDIF.

ENDFORM.                    " CHECK_CREATE_CUST_FOLDE

*&---------------------------------------------------------------------*
*&      Form  CHECK_SOLDTO      I190708
*&---------------------------------------------------------------------*
FORM CHECK_SOLDTO  TABLES   S_HEAD_I STRUCTURE I_HEAD
                   USING    MC_CMPDF_I
                            P_ENCSTOP_O.

  DATA: V_SOLDTO LIKE S_HEAD-KUNAG.
  CLEAR: P_ENCSTOP_O.

  READ TABLE S_HEAD_I INDEX 1.
  V_SOLDTO = S_HEAD_I-KUNAG.

  LOOP AT S_HEAD_I.
    IF S_HEAD_I-KUNAG <> V_SOLDTO.
      IF MC_CMPDF_I = 'X'.
        MESSAGE I000 WITH 'Sold-to 不同, 不可合併PDF'.
        P_ENCSTOP_O = 'X'.
        EXIT.
      ELSE.
        MESSAGE I000 WITH 'Sold-to 不同, 將會依Sold-to拆分MAIL寄送'.
        EXIT.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " CHECK_SOLDTO
*&---------------------------------------------------------------------*
*&      Form  PRE_PROCESS_BY_JTYPE  I190708
*&---------------------------------------------------------------------*
FORM PRE_PROCESS_BY_JTYPE  TABLES   TA_RETURN_O STRUCTURE BAPIRET2
                                    I_HEAD_I STRUCTURE I_HEAD
                                    S_HEAD_O STRUCTURE I_HEAD
                           USING    PFV_JTYPE_I
                           CHANGING P_ENCSTOP_O
                                    PFV_XPATH_O
                                    PFV_XTPATH_O.
  CLEAR P_ENCSTOP_O.

*- user manual mail (save local file -> 透過web寄出)
  IF PFV_JTYPE_I = ''.
    PERFORM GET_UNIX_PATH USING    'E'                "/user/erpsd/encrypt/mail/inv/
                          CHANGING PFV_XPATH_O.
    IF PFV_XPATH_O = ''.
      MESSAGE I000 WITH '沒有設定mail pdf file source path, 請聯絡MIS'.
      P_ENCSTOP_O = 'X'.
    ENDIF.

*- sys mail by sap  (save local file -> 透過web寄出)
  ELSEIF PFV_JTYPE_I = '8'.
    PERFORM GET_UNIX_PATH USING    'E'                "/user/erpsd/encrypt/mail/inv/
                          CHANGING PFV_XPATH_O.
    IF PFV_XPATH_O = ''.
      TA_RETURN_O-TYPE = 'E'.
      TA_RETURN_O-MESSAGE = '沒有設定 mail pdf file source path, 請聯絡MIS'.
      APPEND TA_RETURN_O. CLEAR TA_RETURN_O.
      P_ENCSTOP_O = 'X'.
    ENDIF.

    S_HEAD_O[] = I_HEAD_I[].
    S_HEAD_O-ZMSET = ''.                              "sent mail flag (call by other program 的都是要送的)
    MODIFY S_HEAD_O TRANSPORTING ZMSET WHERE ZMSET = 'X'.

*- sys mail by b2b  (save local file -> 透過b2b寄出)
  ELSEIF PFV_JTYPE_I = '9'.
    PERFORM GET_UNIX_PATH USING    'F'                "/user/erpsd/encrypt/b2b/source_inv/
                          CHANGING PFV_XPATH_O.
    PERFORM GET_UNIX_PATH USING    'G'                "/user/erpsd/encrypt/b2b/target_inv/
                          CHANGING PFV_XTPATH_O.

    IF PFV_XPATH_O = '' OR PFV_XTPATH_O = ''.
      TA_RETURN_O-TYPE = 'E'.
      TA_RETURN_O-MESSAGE = '沒有設定 B2B pdf file source/target path'.
      APPEND TA_RETURN_O. CLEAR TA_RETURN_O.
      P_ENCSTOP_O = 'X'.
    ENDIF.

    S_HEAD_O[] = I_HEAD_I[].
    S_HEAD_O-ZMSET = ''.                               "sent mail flag (call by other program 的都是要送的)
    MODIFY S_HEAD_O TRANSPORTING ZMSET WHERE ZMSET = 'X'.

  ENDIF.

ENDFORM.                    " PRE_PROCESS_BY_JTYPE

*&---------------------------------------------------------------------*
*&      Form  SAVE_PDF_FILE_FOR_ENCRYPT  I190708
*&---------------------------------------------------------------------*
FORM SAVE_PDF_FILE_FOR_ENCRYPT USING    PFV_JTYPE
                               CHANGING P_ENCSTOP.

  DATA: TA_RECEIVERS LIKE SOOS1 OCCURS 0 WITH HEADER LINE.  "MAIL LIST
  DATA: TA_RETURN LIKE BAPIRET2 OCCURS 0 WITH HEADER LINE.

  DATA: S_HEAD_SP LIKE S_HEAD OCCURS 0 WITH HEADER LINE.
  DATA: S_HEAD_TMP LIKE S_HEAD OCCURS 0 WITH HEADER LINE.

  CONSTANTS: V_SPLITNO TYPE I VALUE 30.    "一封MAIL的INV數
  DATA:V_SPLITML(1) TYPE C.

  DATA: V_MOD TYPE I,
        PFV_XPATH TYPE LOCALFILE,     "(mail&b2b) pdf file source path
        PFV_XTPATH TYPE LOCALFILE,    "(b2b) pdf file target path
        PFV_RECOD TYPE I,
        PFV_RECOD_SP TYPE I,
        PFV_TABIX TYPE SYTABIX.

  DATA: PFV_MSENDER LIKE ZSDEL-RECEXTNAM,  "mail sender
        PFV_MTITL_NO TYPE INT3.            "mail split no for mail title


  CHECK PFV_JTYPE = ''  OR
        PFV_JTYPE = '8' OR
        PFV_JTYPE = '9'.

  SELECT SINGLE * FROM ZLINK WHERE CLIENT = SY-MANDT
                                 AND BUKRS = 'PSC'.

  CLEAR: TA_RECEIVERS, TA_RECEIVERS[], TA_PACKING_LIST, TA_PACKING_LIST[], TA_CONTENTS_TXT, TA_CONTENTS_TXT[].

  CLEAR: P_ENCSTOP.

* >>> 只有針對 INV : 將 packing(P) & free dn(F) 移除
  DELETE I_HEAD WHERE ZTYPE <> 'I'
                  AND ZTYPE <> 'C'
                  AND ZTYPE <> 'D'
                  AND ZTYPE <> 'R'.

* >>> 前置by PFV_JTYPE: (1) Get file path (2) 若為外部程式CALL, 處理S_EHAD internal table
  PERFORM PRE_PROCESS_BY_JTYPE TABLES   TA_RETURN
                                        I_HEAD
                                        S_HEAD
                               USING    PFV_JTYPE
                               CHANGING P_ENCSTOP
                                        PFV_XPATH
                                        PFV_XTPATH.

  EXPORT TA_RETURN TO MEMORY ID 'ZSD_ENCRETURN'.
  CHECK P_ENCSTOP = ''.
  CHECK S_HEAD[] IS NOT INITIAL.

* >>> user 手動 mail check resend
  IF PFV_JTYPE = ''.
    PERFORM CHECK_MAIL_RESEND TABLES S_HEAD.
    DELETE S_HEAD WHERE ZMSET = 'X'.
    READ TABLE S_HEAD INDEX 1.
    IF SY-SUBRC <> 0.
      P_ENCSTOP = 'X'.
    ENDIF.
    CHECK P_ENCSTOP = ''.
    CHECK S_HEAD[] IS NOT INITIAL.
  ENDIF.

* >>> user 手動 mail get:
  IF PFV_JTYPE = ''.
*------get mail body
    PERFORM GET_MAIL_CONTENT.

*------get 收件人
    LOOP AT M_ZSDEL.
      TA_RECEIVERS-RECEXTNAM = M_ZSDEL-RECEXTNAM.
      TA_RECEIVERS-RECESC = 'U'.
      APPEND TA_RECEIVERS.
    ENDLOOP.
    IF TA_RECEIVERS[] IS INITIAL.
      MESSAGE I000 WITH '請指定收件人'.
      P_ENCSTOP = 'X'.
    ENDIF.
    CHECK P_ENCSTOP = ''.
    TA_RECEIVERS-RECEXTNAM = 'nancyhu@powerchip.com'.     "暫時,等上線穩定後就移除
    TA_RECEIVERS-RECESC = 'U'.
    TA_RECEIVERS-SNDBC = 'X'.
    APPEND TA_RECEIVERS.

*------get 送件人
    CONCATENATE SY-UNAME ZLINK-ZDOMAIN INTO PFV_MSENDER.
    IF SY-UNAME = 'MISMM' OR SY-UNAME = 'APPLEM'.
      CONCATENATE 'MISSD' ZLINK-ZDOMAIN INTO PFV_MSENDER.
    ENDIF.
  ENDIF.


* >>> 拆 Mail 寄 (Mail件數):
*------step1. by 不同的Sold-to 會拆mail寄 (因為ESR HEADER是用SOLDTO為KEY, 所以要區分)
*------step2. by 30筆inv 為一封 mail

  DESCRIBE TABLE S_HEAD LINES PFV_RECOD.

  PERFORM COLLECT_SOLDTO TABLES S_HEAD
                                ITMPSP.
  DESCRIBE TABLE ITMPSP LINES PFV_RECOD_SP.

  CLEAR V_SPLITML.
  IF PFV_RECOD_SP > 1 OR PFV_RECOD > V_SPLITNO.      "要拆MAIL(多個Sold-to or 超過一封限制inv數)
    V_SPLITML = 'X'.
  ENDIF.

  IF ( PFV_JTYPE = '' OR PFV_JTYPE = '8' ) AND V_SPLITML = 'X'.

    CLEAR: S_HEAD_SP, S_HEAD_SP[], S_HEAD_TMP, S_HEAD_TMP[].

    S_HEAD_TMP[] = S_HEAD[].
    CLEAR: S_HEAD, S_HEAD[].

    LOOP AT ITMPSP.
      CLEAR: PFV_MTITL_NO.

      CLEAR: S_HEAD_SP, S_HEAD_SP[].
      LOOP AT S_HEAD_TMP WHERE KUNAG = ITMPSP-SOLDTO.  "step1: 依sold-to拆
        MOVE-CORRESPONDING S_HEAD_TMP TO S_HEAD_SP.
        APPEND S_HEAD_SP. CLEAR S_HEAD_SP.
      ENDLOOP.

      DESCRIBE TABLE S_HEAD_SP LINES PFV_RECOD.

      LOOP AT S_HEAD_SP.                               "step2: 依限制inv筆數拆
        PFV_TABIX = SY-TABIX.
        MOVE-CORRESPONDING S_HEAD_SP TO S_HEAD.
        APPEND S_HEAD. CLEAR S_HEAD.

        V_MOD = PFV_TABIX MOD V_SPLITNO.

        IF V_MOD = 0 OR PFV_TABIX = PFV_RECOD.         "gen one mail

          IF PFV_RECOD > V_SPLITNO.
            PFV_MTITL_NO = PFV_MTITL_NO + 1.           "拆分的mail title 編號(放在mail title後) ex. (1) (2) (3) ..
          ENDIF.

          PERFORM GEN_PDF_ESR_ENCRYPT TABLES   TA_RECEIVERS
                                               S_HEAD
                                      USING    PFV_JTYPE
                                               PFV_XPATH
                                               PFV_XTPATH
                                               PFV_MSENDER
                                               PFV_MTITL_NO
                                      CHANGING P_ENCSTOP.
          CLEAR: S_HEAD, S_HEAD[].
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    S_HEAD[] = S_HEAD_TMP[].                           "避免後面程式會用到S_HEAD, 將S_HEAD恢復成未拆MAIL前的all data
  ELSE.                                                "不用拆MAIL
    PERFORM GEN_PDF_ESR_ENCRYPT TABLES   TA_RECEIVERS
                                         S_HEAD
                                USING    PFV_JTYPE
                                         PFV_XPATH
                                         PFV_XTPATH
                                         PFV_MSENDER
                                         PFV_MTITL_NO
                                CHANGING P_ENCSTOP.
  ENDIF.
ENDFORM.                    " SAVE_PDF_FILE_FOR_ENCRYPT

*&---------------------------------------------------------------------*
*&      Form  GEN_PDF_ESR_ENCRYPT  I190708
*&---------------------------------------------------------------------*
*  1. Gen & Save PDF data to local server
*  2. Record ESR table data for WEB mail inv PDF doc
*&---------------------------------------------------------------------*
FORM GEN_PDF_ESR_ENCRYPT TABLES   TA_RECEIVERS STRUCTURE SOOS1
                                  S_HEAD STRUCTURE I_HEAD
                         USING    PFV_JTYPE
                                  PFV_XPATH
                                  PFV_XTPATH
                                  PFV_MSENDER
                                  PFV_MTITL_NO
                         CHANGING P_ENCSTOP.

  DATA: TA_RETURN LIKE BAPIRET2 OCCURS 0 WITH HEADER LINE.
  DATA: V_TMPCHAR(50) TYPE C,
        PFV_UPATH TYPE LOCALFILE,     "(mail&b2b) pdf file source path <含custid dolder>
        PFV_UTPATH TYPE LOCALFILE,    "(b2b) pdf file target path <含custid dolder>
        PFV_FPATH TYPE LOCALFILE,     "(mail&b2b) pdf file source path <含custid dolder+filename>
        PFV_FILNE TYPE SO_OBJ_DES,
        PFV_TABIX TYPE SYTABIX,
        PFV_RECOD TYPE I.

  CLEAR: TA_CONTENTS_BIN, TA_CONTENTS_BIN[], P_ENCSTOP.

  IF PFV_JTYPE = ''.                         "8 & 9 不可清空
    CLEAR: OT_FILENAME, OT_FILENAME[].
  ENDIF.

  DESCRIBE TABLE S_HEAD LINES PFV_RECOD.

* >>> user手動mail & sap mail & b2b : 處理pdf的部份
  IF MC_CMPDF IS NOT INITIAL AND PFV_RECOD <> 1.             "目前只有user手動mail有combine PDF
*->> 合併的PDF檔
    CLEAR: I_HEAD, I_HEAD[].

    APPEND LINES OF S_HEAD TO I_HEAD.

    PERFORM SEND_TO_SMARTFORM USING 'FILE'
                                    ''.
    CHECK TA_CONTENTS_BIN[] IS NOT INITIAL.

    READ TABLE S_HEAD INDEX 1.
    PERFORM CHECK_CREATE_CUST_FOLDER USING    PFV_XPATH
                                              S_HEAD-KUNAG   "sold-to
                                     CHANGING PFV_UPATH.

    PERFORM GET_MAIL_FTP_FILE_NAME USING     I_HEAD
                                             ''              "檔名要再加年月日
                                   CHANGING  PFV_FILNE.

    CONCATENATE PFV_UPATH PFV_FILNE INTO PFV_FPATH.

    PERFORM SAVE_TO_UNIX TABLES TA_CONTENTS_BIN
                         USING  PFV_FPATH.

*- file name list for oracle record
    OT_FILENAME-SOLDTO = S_HEAD-KUNAG.
    OT_FILENAME-BILLTO = S_HEAD-BKUNN.
    OT_FILENAME-S_FILENAME = PFV_FILNE.
    OT_FILENAME-T_FILENAME = PFV_FILNE.
    LOOP AT S_HEAD.
      IF OT_FILENAME-VBELN = ''.
        OT_FILENAME-VBELN = S_HEAD-VBELN.
      ELSE.
        CONCATENATE OT_FILENAME-VBELN ',' S_HEAD-VBELN
               INTO OT_FILENAME-VBELN.
      ENDIF.
    ENDLOOP.
    OT_FILENAME-MTITL_NO = PFV_MTITL_NO.          "FOR PFV_JTYPE = '8' 用
    APPEND OT_FILENAME. CLEAR OT_FILENAME.
  ELSE.
*->> 一個一個的PDF檔(要排除寄EXCEL檔)
    LOOP AT S_HEAD WHERE ZMSET IS INITIAL.

      CHECK MC_EXCEL IS INITIAL.

      CLEAR: I_HEAD, I_HEAD[].
      MOVE-CORRESPONDING  S_HEAD TO I_HEAD.
      APPEND I_HEAD.

      CLEAR: TA_CONTENTS_BIN, TA_CONTENTS_BIN[].
      PERFORM SEND_TO_SMARTFORM USING 'FILE'
                                      ''.
      CHECK TA_CONTENTS_BIN[] IS NOT INITIAL.

      PERFORM CHECK_CREATE_CUST_FOLDER USING    PFV_XPATH
                                                S_HEAD-KUNAG    "sold-to
                                       CHANGING PFV_UPATH.
      IF PFV_JTYPE = '9'.  "B2B
        PERFORM CHECK_CREATE_CUST_FOLDER USING  PFV_XTPATH      "target folder
                                                S_HEAD-KUNAG    "sold-to
                                       CHANGING PFV_UTPATH.
      ENDIF.

      PERFORM GET_MAIL_FTP_FILE_NAME USING     S_HEAD
                                               'X'              "檔名要再加年月日
                                     CHANGING  PFV_FILNE.

      PERFORM GET_FILE_NAME_SPECIAL_RULE  USING S_HEAD          "檔名有特殊RULE
                                                PFV_JTYPE
                                       CHANGING PFV_FILNE.


      CONCATENATE PFV_UPATH PFV_FILNE INTO PFV_FPATH.

      PERFORM SAVE_TO_UNIX TABLES TA_CONTENTS_BIN
                            USING PFV_FPATH.
*- file name list for oracle record
      OT_FILENAME-SOLDTO = S_HEAD-KUNAG.
      OT_FILENAME-BILLTO = S_HEAD-BKUNN.
      OT_FILENAME-VBELN  = S_HEAD-VBELN.
      OT_FILENAME-S_FILENAME = PFV_FILNE.
      SPLIT PFV_FILNE AT '_' INTO OT_FILENAME-T_FILENAME V_TMPCHAR .
      CONCATENATE OT_FILENAME-T_FILENAME '.pdf'
             INTO OT_FILENAME-T_FILENAME.
      OT_FILENAME-MTITL_NO = PFV_MTITL_NO.          "FOR PFV_JTYPE = '8' 用
      APPEND OT_FILENAME. CLEAR OT_FILENAME.
    ENDLOOP.
  ENDIF.

* >>> 處理 ESR records
  IF OT_FILENAME[] IS INITIAL.
    P_ENCSTOP = 'X'.
  ENDIF.
  CHECK OT_FILENAME[] IS NOT INITIAL.
  IF PFV_JTYPE = ''.

    CALL FUNCTION 'ZRFC_SD_ENCRYPT_DOC'
      EXPORTING
        I_JOBTPS         = PFV_JTYPE
        I_MTITL          = MWA_HEAD-MTITL
        PFV_MTITL_NO     = PFV_MTITL_NO
        I_MSENDER        = PFV_MSENDER
        I_CHK_ONE_SOLDTO = ''
        PFV_XPATH        = PFV_XPATH
      TABLES
        OT_FILENAME      = OT_FILENAME
        TA_CONTENTS_TXT  = TA_CONTENTS_TXT
        TA_RECEIVERS     = TA_RECEIVERS
        TA_RETURN        = TA_RETURN.

  ELSEIF PFV_JTYPE = '8' OR PFV_JTYPE = '9'.

*    EXPORT PFV_XPATH PFV_XTPATH PFV_MTITL_NO TO MEMORY ID 'ZSD_ENCPATH'.
    FREE MEMORY ID 'ZSD_ENCPATH'.
    FREE MEMORY ID 'ZSD_ENCFILE'.
    EXPORT PFV_XPATH PFV_XTPATH TO MEMORY ID 'ZSD_ENCPATH'.
    EXPORT OT_FILENAME TO MEMORY ID 'ZSD_ENCFILE'.

  ENDIF.

* >>> user手動mail: 記錄寄送 log
  IF PFV_JTYPE = ''.

    READ TABLE TA_RETURN WITH KEY TYPE = 'E'.
    IF SY-SUBRC <> 0.
      LOOP AT S_HEAD WHERE ZMSET IS INITIAL.
        PERFORM UPDATE_INFO_TO_TABLE  USING 'MAIL'.
        PERFORM UPDATE_INTERNAL_TABLE USING 'MAIL'.
      ENDLOOP.
    ELSE.
      P_ENCSTOP = 'X'.
      MESSAGE I000 WITH TA_RETURN-MESSAGE.
      EXIT.
    ENDIF.

  ENDIF.

ENDFORM.            "GEN_PDF_ESR_ENCRYPT
*&---------------------------------------------------------------------*
*&      Form  COLLECT_SOLDTO  I190708
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM COLLECT_SOLDTO  TABLES   S_HEAD_I STRUCTURE I_HEAD
                              ITMPSP_O STRUCTURE ITMPSP.
  CLEAR: ITMPSP_O, ITMPSP_O[].
  LOOP AT S_HEAD.
    ITMPSP_O-SOLDTO = S_HEAD-KUNAG.
    COLLECT ITMPSP_O. CLEAR ITMPSP_O.
  ENDLOOP.
ENDFORM.                    " COLLECT_SOLDTO
*&---------------------------------------------------------------------*
*&      Form  IMEX_MODIFY_HEAD_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      -->P_P_TWDVL  text
*----------------------------------------------------------------------*
FORM IMEX_MODIFY_HEAD_DATA  TABLES   PF_HEAD_IO STRUCTURE I_HEAD
                            USING    PFV_DOCTP.
  CHECK PFV_DOCTP IS NOT INITIAL.
  LOOP AT PF_HEAD_IO WHERE ZTYPE = 'I' OR
                           ZTYPE = 'F'.
    PF_HEAD_IO-DOCTP = 'X'.
    MODIFY PF_HEAD_IO.
  ENDLOOP.
ENDFORM.                    " IMEX_MODIFY_HEAD_DATA
*&---------------------------------------------------------------------*
*&      Form  IMEX_MODIFY_ITEM_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      -->P_I_ITEM  text
*----------------------------------------------------------------------*
FORM IMEX_MODIFY_ITEM_DATA  TABLES   PF_HEAD_I  STRUCTURE I_HEAD
                                     PF_ITEM_IO STRUCTURE I_ITEM.
  LOOP AT PF_HEAD_I WHERE DOCTP IS NOT INITIAL.
    LOOP AT PF_ITEM_IO WHERE VBELN = PF_HEAD_I-VBELN
                       AND   ZTYPE = PF_HEAD_I-ZTYPE.
      CLEAR: PF_ITEM_IO-ZCHIP.
      MODIFY PF_ITEM_IO.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " IMEX_MODIFY_ITEM_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_ZHIP_FROM_ZSHIP6
*&---------------------------------------------------------------------*
FORM GET_ZCHIP_FROM_ZSHIP6  USING    PFWA_LIPS_I STRUCTURE LIPS
                           CHANGING PFV_ZCHIP_O.

  DATA: IZSHIP6 LIKE ZSHIP6 OCCURS 0 WITH HEADER LINE.      "I190920

  CLEAR: PFV_ZCHIP_O.

  SELECT SINGLE * FROM  ZMWH8H
                  WHERE VBELN = PFWA_LIPS_I-VBELN
                  AND   KEYNO = PFWA_LIPS_I-CHARG
                  AND   MATNR = PFWA_LIPS_I-MATNR.
  CHECK SY-SUBRC = 0.

  SELECT SINGLE * FROM  ZSHIP6
                  WHERE KEYNO = ZMWH8H-KEYNO
                  AND   ZDATE = ZMWH8H-ZDATE
                  AND   ZTIME = ZMWH8H-ZTIME.
*I190920 -->
  IF SY-SUBRC <> 0.
    CLEAR: IZSHIP6, IZSHIP6[].
    SELECT * INTO CORRESPONDING FIELDS OF TABLE IZSHIP6 FROM ZSHIP6
     WHERE KEYNO = ZMWH8H-KEYNO
       AND ZDATE <= ZMWH8H-ZDATE.

    SORT IZSHIP6 BY ZDATE DESCENDING ZTIME DESCENDING.
    READ TABLE IZSHIP6 INDEX 1.
    IF SY-SUBRC = 0.
      CONCATENATE IZSHIP6-CHIP+0(16) '-' IZSHIP6-CHIP+16(4)
             INTO PFV_ZCHIP_O.
    ENDIF.
  ELSE.
*I190920 <--
*  CHECK SY-SUBRC = 0.                                           "D190920
    CONCATENATE ZSHIP6-CHIP+0(16) '-' ZSHIP6-CHIP+16(4)
           INTO PFV_ZCHIP_O.
  ENDIF.                                                    "I190920
ENDFORM.                    " GET_ZHIP_FROM_ZSHIP6
*&---------------------------------------------------------------------*
*&      Form  GET_PROD_INFO_FROM_FDMS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ITEM  text
*      -->P_PF_PRODINF  text
*----------------------------------------------------------------------*
FORM GET_PROD_INFO_FROM_FDMS  TABLES   PF_ITEM_I  STRUCTURE I_ITEM
                                       PF_PINF_O  STRUCTURE ZSD_FDMS.
  DATA: PFV_DBCON   TYPE DBCON_NAME,
        PFV_DESTN   TYPE RFCEXEC.


  CLEAR: PF_PINF_O, PF_PINF_O[].
  LOOP AT PF_ITEM_I.
    PF_PINF_O-MATNR = PF_ITEM_I-MATNR.
    APPEND PF_PINF_O.
  ENDLOOP.
  SORT PF_PINF_O BY MATNR.
  DELETE ADJACENT DUPLICATES FROM PF_PINF_O COMPARING ALL FIELDS.

  CHECK SY-SYSID <> 'DEV'.
  CHECK P_VKORG = 'MAX1'.                                   "I051121

**取得連線資訊
  PERFORM GET_CONNECTION_INFO USING     'A'
                              CHANGING  PFV_DESTN.        "RASAPAP2_WIN
**取得連結DB
  PERFORM GET_CONNECTION_INFO USING     'C'
                              CHANGING  PFV_DBCON.        "MSS_RATDMS01(RAPDMD01)
**測試WIN AP連線
  CALL FUNCTION 'RFC_PING' DESTINATION PFV_DESTN.
  CHECK SY-SUBRC = 0.
  CALL FUNCTION 'ZWIN_GET_PRODUCT_INFO'
    DESTINATION PFV_DESTN
    EXPORTING
      I_DBCON = PFV_DBCON
    TABLES
      T_PROD  = PF_PINF_O.
ENDFORM.                    " GET_PROD_INFO_FROM_FDMS
*&---------------------------------------------------------------------*
*&      Form  GET_GROSS_DIE_COUNT_MAX1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_DIES_I  text
*      -->P_PF_ITEM_TMP  text
*      -->P_PFWA_HEAD_I  text
*      <--P_PF_MATNR_GDPWO  text
*----------------------------------------------------------------------*
FORM GET_GROSS_DIE_COUNT_MAX1  TABLES   PF_DIES_I    STRUCTURE ZSD_FDMS
                               USING    PFWA_ITEM_I  STRUCTURE I_ITEM
                                        PFWA_HEAD_I  STRUCTURE I_HEAD
                               CHANGING PFV_PRODGSDE_O.
  DATA: PFWA_ZSDA02   LIKE ZSDA02,
        PFV_MATNR(09) TYPE C,
        PFX_SUFFX(04) TYPE C.

  CHECK PFWA_HEAD_I-VKORG = 'MAX1'.
  CLEAR: PFV_PRODGSDE_O, PFV_MATNR, PFX_SUFFX.
  SPLIT PFWA_ITEM_I-MATNR AT '-' INTO PFV_MATNR PFX_SUFFX.
  CONCATENATE PFV_MATNR 'A'
    INTO PFV_MATNR.
  "先抓自訂義GROSS DIE
  PERFORM GET_WORKAREA_ZSDA02 USING     PFWA_ITEM_I-KUNAG
                                        PFV_MATNR
                              CHANGING  PFWA_ZSDA02.
  IF PFWA_ZSDA02 IS INITIAL.
    "再抓是否需要從FDMS取資料
    PERFORM GET_WORKAREA_ZSDA02 USING     PFWA_ITEM_I-KUNAG
                                          ''
                                CHANGING  PFWA_ZSDA02.
    CHECK PFWA_ZSDA02 IS NOT INITIAL.
    READ TABLE PF_DIES_I WITH KEY MATNR = PFWA_ITEM_I-MATNR.
    CHECK SY-SUBRC = 0.
    PFWA_ZSDA02-GDPWO = PF_DIES_I-GRDIE.
  ENDIF.

  IF PFWA_HEAD_I-ZTYPE = 'P'.
    CHECK PFWA_ZSDA02-ZPACK IS NOT INITIAL.
    PFV_PRODGSDE_O = PFWA_ZSDA02-GDPWO.
    EXIT.
  ENDIF.
  IF PFWA_HEAD_I-ZTYPE = 'I' OR
     PFWA_HEAD_I-ZTYPE = 'F'.
    CHECK PFWA_ZSDA02-ZBILL IS NOT INITIAL.
    PFV_PRODGSDE_O = PFWA_ZSDA02-GDPWO.
    EXIT.
  ENDIF.
ENDFORM.                    " GET_GROSS_DIE_COUNT_MAX1
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSDA02
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_ITEM_I_KUNAG  text
*      -->P_PFWA_ITEM_I_MATNR+01(05)  text
*      <--P_PFWA_ZSDA02  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSDA02  USING    PFV_KUNAG_I
                                   PFV_MATNR_I
                          CHANGING PFWA_ZSDA02_O STRUCTURE ZSDA02.
  CLEAR: PFWA_ZSDA02_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZSDA02_O  FROM  ZSDA02
                                                WHERE KDMAT =  PFV_MATNR_I
                                                AND   KUNNR =  PFV_KUNAG_I.

ENDFORM.                    " GET_WORKAREA_ZSDA02
*&---------------------------------------------------------------------*
*&      Form  UPDATE_SERVER_EDW8A
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZSDA02_D  text
*      -->P_1699   text
*----------------------------------------------------------------------*
FORM UPDATE_SERVER_EDW8A  TABLES   PF_ZSDA02_I STRUCTURE ZSDA02
                          USING    PFV_FNCTN.

  DATA: PFV_DBCON   TYPE DBCON_NAME.
**取得連結DB
  PERFORM GET_CONNECTION_INFO USING     'D'
                              CHANGING  PFV_DBCON.        "MSS_RATDMS01(RAPDMD01)
  CALL FUNCTION 'ZCIM_PUT_DIE_INFO_TO_EDW'
    EXPORTING
      I_FNCTN = PFV_FNCTN
      I_DBCON = PFV_DBCON
    TABLES
      T_DATA  = PF_ZSDA02_I.
ENDFORM.                    " UPDATE_SERVER_EDW8A
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZMWH8H
*&---------------------------------------------------------------------*
FORM GET_WORKAREA_ZMWH8H  USING    PFW_ZMWH8H STRUCTURE ZMWH8H
                                   PV_DELNO
                                   PV_MATNR
                                   PV_CHARG.
  CLEAR PFW_ZMWH8H.
  SELECT SINGLE * INTO PFW_ZMWH8H FROM ZMWH8H
   WHERE VBELN = PV_DELNO AND KEYNO = PV_CHARG
     AND MATNR = PV_MATNR.

ENDFORM.                    " GET_WORKAREA_ZMWH8H
*&---------------------------------------------------------------------*
*&      Form  CHANGE_TOTAL_TAX_AMT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD  text
*      <--P_I_ITEM_TO  text
*----------------------------------------------------------------------*
FORM CHANGE_TOTAL_TAX_AMT  CHANGING PFWA_ITEMTO_IO  STRUCTURE I_ITEM_TO.
  DATA: PFV_NETWR TYPE NETWR.
  CLEAR: PFV_NETWR.
  CHECK PFWA_ITEMTO_IO-TAXAM IS NOT INITIAL.
  PFV_NETWR = PFWA_ITEMTO_IO-SUBTO * 5 / 100.
  CHECK PFV_NETWR <> PFWA_ITEMTO_IO-TAXAM.
  PFWA_ITEMTO_IO-TAXAM = PFV_NETWR.
ENDFORM.                    " CHANGE_TOTAL_TAX_AMT
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_ITEM_MATRDESC_IMEX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I  text
*      <--P_PFWA_ITEM_IO  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_MATRDESC_IMEX  USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                                     CHANGING PFV_BTRUE_O.

  CLEAR: PFV_BTRUE_O.
*  IF PFWA_HEAD_I-PRODTYPE = 'P'           AND                                "I072919  "D101519
  CHECK ( PFWA_HEAD_I-PRODTYPE = 'P' OR PFWA_HEAD_I-PRODTYPE = 'S' ) AND      "I101519
        ( P_JOBTPS = 'E' OR P_JOBTPS = 'N' ) AND                              "I072919
        PFWA_HEAD_I-KUNAG = '0000002049' AND
        P_CUSTM = 'X'.                                                        "I072919
*  CLEAR PFWA_ITEM_IO-MAKTX.                                                  "I072919
  PFV_BTRUE_O = 'X'.                                                          "I072919
ENDFORM.                    " SP_RULE_FOR_ITEM_MATRDESC_IMEX
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_MAKTX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I  text
*      <--P_PFWA_MAKT_MAKTX  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_MAKTX  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                        CHANGING PFV_MAKTX_IO.
  CHECK PFWA_HEAD_I-KUNAG = '0000004011'.       "PANASONIC
  CHECK P_JOBTPS <> 'N' AND P_JOBTPS <> 'E'.
  CHECK PFV_MAKTX_IO+0(4) = '0.18'.

  CLEAR PFV_MAKTX_IO.
  PFV_MAKTX_IO = 'SI.FET TRANSISTOR(PD. LESS 1W)'.
ENDFORM.                    " SP_RULE_FOR_MAKTX
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBPA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I_VBELN  text
*      -->P_6564   text
*      <--P_PFWA_VBPA  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBPA  USING    PFV_VBELN_I
                                 PFV_POSNR_I
                        CHANGING PFWA_VBPA_O STRUCTURE VBPA.
  CLEAR: PFWA_VBPA_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VBPA_O FROM  VBPA
                                             WHERE VBELN = PFV_VBELN_I
                                             AND   POSNR = PFV_POSNR_I
                                             AND   PARVW = 'ZF'.
ENDFORM.                    " GET_WORKAREA_VBPA
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSD63
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I_VBELN  text
*      <--P_PFWA_ZSD63  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSD63  USING    PFV_VBELN_I
                         CHANGING PFWA_ZSD63_O STRUCTURE ZSD63.
  CLEAR: PFWA_ZSD63_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZSD63_O FROM  ZSD63
                                              WHERE VBELN = PFV_VBELN_I.
ENDFORM.                    " GET_WORKAREA_ZSD63
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_T005T
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_KNA1_LAND1  text
*      <--P_PFWA_T005T  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_T005T  USING    PFV_LAND1_I
                         CHANGING PFWA_T005T STRUCTURE T005T.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_T005T FROM  T005T
                                            WHERE SPRAS = SY-LANGU
                                            AND   LAND1 = PFV_LAND1_I.
ENDFORM.                    " GET_WORKAREA_T005T
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_CUSTFULLNAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I  text
*      <--P_PFV_NAME1_O  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_CUSTFULLNAME  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                               CHANGING PFV_NAME1_IO.
  CHECK PFWA_HEAD_I-KUNAG = '0000004011'.       "Panasonic
  CLEAR: PFV_NAME1_IO.
*  PFV_NAME1_IO = 'Panasonic Semiconductor Solutions Co.,Ltd.'.  "D200910
  PFV_NAME1_IO = 'Nuvoton Technology Corporation Japan'.    "I200910
ENDFORM.                    " SP_RULE_FOR_CUSTFULLNAME
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ADRC_SYDATUM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_KNA1_ADRNR  text
*      <--P_PFWA_ADRC  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ADRC_SYDATUM  USING    PFV_ADRNR_I
                                CHANGING PFWA_ADRC_O STRUCTURE ADRC.
  CLEAR: PFWA_ADRC_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ADRC_O  FROM  ADRC
                                              WHERE ADDRNUMBER  =   PFV_ADRNR_I
                                              AND   DATE_FROM   <=  SY-DATUM
                                              AND   NATION      =   ' '
                                              AND   DATE_TO     >=  SY-DATUM.
ENDFORM.                    " GET_WORKAREA_ADRC_SYDATUM
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_KNVK_PAFKT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_KUNAG_I  text
*      -->P_PFV_SPART_I  text
*      -->P_PFV_PAAT3  text
*      -->P_PFV_PAFKT  text
*      <--P_PFWA_KNVK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_KNVK_PAFKT  USING    PFV_KUNAG_I
                                       PFV_SPART_I
                                       PFV_PAAT3_I
                                       PFV_PAFKT_I
                              CHANGING PFWA_KNVK_O STRUCTURE KNVK.
  CLEAR: PFWA_KNVK_O.
*        SELECT SINGLE * FROM  KNVK
*                        WHERE KUNNR = PFV_KUNAG
**                        AND   ABTNR = P_ABTNR1
*                        AND   PAFKT = '80'
*                        AND ( PARH2 = PFV_SPART OR PARH2 = '')
*                        AND   PARH3 = PFV_PAAT3.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_KNVK_O FROM   KNVK
                                             WHERE  KUNNR = PFV_KUNAG_I
                                             AND    PAFKT = PFV_PAFKT_I
                                             AND  ( PARH2 = PFV_SPART_I OR PARH2 = '')
                                             AND    PARH3 = PFV_PAAT3_I.
ENDFORM.                    " GET_WORKAREA_KNVK_PAFKT
*&---------------------------------------------------------------------*
*&      Form  GET_LOCLCURR_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_KURRF  text
*      <--P_I_ITEM_KPEIN  text
*      <--P_I_ITEM_UNITP  text
*----------------------------------------------------------------------*
FORM GET_LOCLCURR_VALUE  USING    PFV_KURRF_I
                                  PFV_CUKEY_I
                         CHANGING PFV_KPEIN_O
                                  PFV_VALUE_IO.
  DATA: PFV_DUPCE(13) TYPE P DECIMALS 5.
  CLEAR: PFV_KPEIN_O, PFV_DUPCE.
  PFV_DUPCE = PFV_VALUE_IO * PFV_KURRF_I.
  PERFORM CAL_KPEIN_VALUE USING    PFV_DUPCE
                                   PFV_CUKEY_I
                          CHANGING PFV_VALUE_IO
                                   PFV_KPEIN_O.
  PERFORM CURRENCY_CONVERT USING    PFV_CUKEY_I
                           CHANGING PFV_VALUE_IO.
ENDFORM.                    " GET_LOCLCURR_VALUE
*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_DATA_ZPDH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_O  text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_ZPDH  TABLES   PF_VBRK_I STRUCTURE VBRK
                                  PF_ZPDH_O STRUCTURE ZPDH.

  CLEAR: PF_ZPDH_O, PF_ZPDH_O[].
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZPDH_O  FROM   ZPDH
                                                  WHERE  PERFI    IN S_VBELN
                                                  AND    PIDATE   IN S_ERDAT
                                                  AND    KUNNR    IN S_KUNAG
                                                  AND    VKORG    =  P_VKORG.
  CHECK PF_ZPDH_O[] IS NOT INITIAL.
*檢查ZPDH中是否含舊的PI(只留NEW PI)
  LOOP AT PF_ZPDH_O.
    READ TABLE PF_VBRK_I WITH KEY VBELN = PF_ZPDH_O-PERFI.
    CHECK SY-SUBRC = 0.
    DELETE PF_ZPDH_O.
    CONTINUE.
  ENDLOOP.
ENDFORM.                    " GET_NEWPI_HEADER_INTO_VBRK
*&---------------------------------------------------------------------*
*&      Form  GET_WORAKREA_DD07T
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_IO_ZBSTATUS  text
*      -->P_3553   text
*      <--P_PFV_VTEXT  text
*----------------------------------------------------------------------*
FORM GET_WORAKREA_DD07T  USING    PFV_ZBSTATUS_I
                                  PFV_DOMAIN_I
                         CHANGING PFWA_DD07T_O.
  CLEAR: PFWA_DD07T_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_DD07T_O FROM  DD07T
                                              WHERE DOMNAME     = PFV_DOMAIN_I
                                              AND   DDLANGUAGE  = SY-LANGU
                                              AND   DOMVALUE_L  = PFV_ZBSTATUS_I.

ENDFORM.                    " GET_WORAKREA_DD07T
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_ZPDI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDH  text
*      -->P_I_ZPDI  text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_ZPDI  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                  PF_ZPDI_O STRUCTURE ZPDI.
  CLEAR: PF_ZPDI_O, PF_ZPDI_O[].
  CHECK PF_ZPDH_I[] IS NOT INITIAL.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZPDI_O FROM ZPDI
                                                 FOR ALL ENTRIES IN PF_ZPDH_I
                                                 WHERE PERFI = PF_ZPDH_I-PERFI.
ENDFORM.                    " GET_ITEM_DATA_ZPDI
*&---------------------------------------------------------------------*
*&      Form  GET_HEAD_DATA_NEWPI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDH  text
*      -->P_PF_HEAD  text
*----------------------------------------------------------------------*
FORM GET_HEAD_DATA_NEWPI  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                   PF_HEAD_O STRUCTURE I_HEAD.

  CLEAR: PF_HEAD_O, PF_HEAD_O[].
  CHECK PF_ZPDH_I[] IS NOT INITIAL.

  LOOP AT PF_ZPDH_I.
    PF_HEAD_O-ZTYPE = 'R'.
    PF_HEAD_O-SIDAT = PF_ZPDH_I-PIDATE.                   "INVOICE DATE
    PF_HEAD_O-PBYPC = PF_ZPDH_I-PITYPE.                   "'' = Rate、'1' = 以片計價、'2' = 指定金額
    PF_HEAD_O-VKORG = PF_ZPDH_I-VKORG.                    "Sales Org
    PF_HEAD_O-VTWEG = PF_ZPDH_I-VTWEG.                    "(X)Distribution Channel
    PF_HEAD_O-VBELN = PF_ZPDH_I-PERFI.                    "INVOICE / CREDIT MEMO NO. / PI No.
    PF_HEAD_O-KUNAG = PF_ZPDH_I-KUNNR.                    "(X)SOLD-TO
*    PF_HEAD_O-RFBSK = 'D'.                                "(X)判斷該BILLING是否已RELEASE(原PI都是狀態是D)
*    PF_HEAD_O-FKART = 'L'.                                "(X)Billing Type(原PI都是L)
    PF_HEAD_O-AUBEL = PF_ZPDH_I-VBELN.                    "SO NO.
*    PF_HEAD_O-ZMTSO = ''.                                 "(X)判斷是否為多筆SO(''=一對一,'X'=一對多)一張只會有一張SO
*    PF_HEAD_O-VGBEL = ''.                                 "DN NO. / FREE INVOICE NO.
    PF_HEAD_O-SPART = PF_ZPDH_I-SPART.                    "(X)DIVISION
    PF_HEAD_O-ERDAT = SY-DATUM.                           "To Be Shipped Date
*    PF_HEAD_O-INCO2 = ''.                                 "DELIVERY TERMS / TRADE TERMS
*    PF_HEAD_O-DESTI = ''.                                 "DESTINATION
*    PF_HEAD_O-LCNUM = ''.                                 "LC NO.
    PF_HEAD_O-BKUNN = PF_ZPDH_I-BILLTO.                   "(X)BILL-TO
    PF_HEAD_O-KUNNR = PF_ZPDH_I-SHIPTO.                   "(X)SHIP-TO
*    PF_HEAD_O-USCIC = ''.                                 "USCI Code
*    PF_HEAD_O-PFLAG = ''.                                 "(X)判斷是否為吃PROFMA的INVOICE
*    PF_HEAD_O-RELNO = ''.                                 "(X)放行單號          (供ITEM_REMARK使用)
*    PF_HEAD_O-CDATE = ''.                                 "(X)放行日期          (供ITEM_REMARK使用)
    PF_HEAD_O-KURRF = PF_ZPDH_I-KURRF.                     "(X)Exchange Rate給I_ITEM_TO-TBRGE用
**REMARK{I,C,R}(REMAK)
    PERFORM GET_HEAD_REMARK CHANGING PF_HEAD_O.
**PAYMENT TERM{I,C,R}(PAYTM)
    PERFORM GET_PAYMENT_TERM_DESC USING      PF_ZPDH_I-ZTERM
                                  CHANGING   PF_HEAD_O.
***(X)判斷是否已經有傳送過的記錄(ZFSET / ZMSET) ZFSET = FTP, ZMSET = MAIL
    PERFORM GET_SENT_INFO USING     PF_ZPDH_I-PERFI
                                    PF_ZPDH_I-KUNNR
                          CHANGING  PF_HEAD_O.

    APPEND PF_HEAD_O.
    CLEAR  PF_HEAD_O.
  ENDLOOP.
ENDFORM.                    " GET_HEAD_DATA_NEWPI
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_LIPS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_LIPS  text
*      -->P_PFV_VBELN_I  text
*----------------------------------------------------------------------*
FORM GET_DATA_LIPS  TABLES   PF_LIPS_O STRUCTURE LIPS
                    USING    PFV_VGBEL_I.
  CLEAR: PF_LIPS_O, PF_LIPS_O[].
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_LIPS_O  FROM  LIPS
                                                  WHERE VBELN = PFV_VGBEL_I
                                                  AND   UECHA <> ''.
ENDFORM.                    " GET_DATA_LIPS
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBRP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFV_VBELN_I  text
*      -->P_3537   text
*      <--P_PFWA_VBRP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBRP  USING    PFV_VBELN_I
                                 PFV_POSNR_I
                        CHANGING PFWA_VBRP_O STRUCTURE VBRP.
  CLEAR: PFWA_VBRP_O.
  IF PFV_POSNR_I = ''.      "不確定INITIAL是否等於 ''
    SELECT SINGLE *
      INTO CORRESPONDING FIELDS OF PFWA_VBRP_O  FROM  VBRP
                                                WHERE VBELN = PFV_VBELN_I.
    EXIT.
  ENDIF.

  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VBRP_O  FROM  VBRP
                                              WHERE VBELN = PFV_VBELN_I
                                              AND   POSNR = PFV_POSNR_I.
ENDFORM.                    " GET_WORKAREA_VBRP
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSD111
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_LIKP_I_KUNAG  text
*      <--P_PFWA_ZSD111  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSD111  USING    PFV_KUNAG_I
                          CHANGING PFWA_ZSD111_O STRUCTURE ZSD111.
  CLEAR: PFWA_ZSD111_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZSD111_O  FROM  ZSD111
                                                WHERE KUNNR = PFV_KUNAG_I.
ENDFORM.                    " GET_WORKAREA_ZSD111
*&---------------------------------------------------------------------*
*&      Form  GET_USING_PI_FLAG_FROM_ZPD2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_I  text
*      <--P_PF_HEAD_O_PFLAG  text
*----------------------------------------------------------------------*
FORM GET_USING_PI_FLAG_FROM_ZPD2  USING    PFWA_VBRK_I  STRUCTURE VBRK
                                  CHANGING PFV_PFLAG_IO.
  DATA: PF_ZPD2 LIKE ZPD2 OCCURS 0 WITH HEADER LINE.

  CHECK PFWA_VBRK_I-VBTYP = 'M'.                "M = Invoice
  CHECK PFV_PFLAG_IO IS INITIAL.                "前一個perform就會從vbfa判斷...這裡是為new pi而檢查的
  PERFORM GET_DATA_ZPD2_FROM_VBELN  TABLES PF_ZPD2
                                    USING  PFWA_VBRK_I-VBELN.
  CHECK PF_ZPD2[] IS NOT INITIAL.
  PFV_PFLAG_IO = 'X'.
ENDFORM.                    " GET_USING_PI_FLAG_FROM_ZPD2
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_ZPD2_FROM_VBELN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPD2  text
*      -->P_PFWA_VBRK_I_VBELN  text
*----------------------------------------------------------------------*
FORM GET_DATA_ZPD2_FROM_VBELN  TABLES   PF_ZPD2_O STRUCTURE ZPD2
                               USING    PFV_VBELN_I.
  CLEAR: PF_ZPD2_O, PF_ZPD2_O[].
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZPD2_O  FROM  ZPD2
                                                  WHERE VBELN = PFV_VBELN_I.
ENDFORM.                    " GET_DATA_ZPD2_FROM_VBELN
*&---------------------------------------------------------------------*
*&      Form  GET_ITEM_DATA_NEWPI01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDI  text
*      -->P_PF_ITEM  text
*      -->P_PF_HEAD  text
*----------------------------------------------------------------------*
FORM GET_ITEM_DATA_NEWPI01  TABLES  PF_ZPDH_I   STRUCTURE ZPDH
                                    PF_ZPDI_I   STRUCTURE ZPDI
                                    PF_ITEM_O   STRUCTURE I_ITEM
                            USING   PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: PFWA_MAKT LIKE MAKT,
        PFV_ITMNO TYPE POSNR_VF.

  CLEAR: PF_ITEM_O, PF_ITEM_O[].
  CHECK PFWA_HEAD_I-ZTYPE = 'R'.      "R = Proforma
**檢查是否有NEW PI的資料
  READ TABLE PF_ZPDI_I WITH KEY PERFI = PFWA_HEAD_I-VBELN.
  CHECK SY-SUBRC = 0.

  READ TABLE PF_ZPDH_I WITH KEY PERFI = PFWA_HEAD_I-VBELN.
  LOOP AT PF_ZPDI_I WHERE PERFI = PFWA_HEAD_I-VBELN.
    IF PF_ZPDI_I-KPEIN IS INITIAL.
      PF_ZPDI_I-KPEIN = 1.
    ENDIF.
    PF_ITEM_O-VBELN = PFWA_HEAD_I-VBELN.                                      "(X)單號  [KEY]
    PF_ITEM_O-ZTYPE = PFWA_HEAD_I-ZTYPE.                                      "(X)單據類型  [KEY]
    PF_ITEM_O-KUNAG = PFWA_HEAD_I-KUNAG.                                      "(X)CUST NO.
    PF_ITEM_O-POSNR = PF_ZPDI_I-ITEM.                                         "(X)ITME NO.
    PF_ITEM_O-PSTYV = 'TAN'.                                                  "(X)ITEM TYPE
    PF_ITEM_O-VGBEL = PF_ITEM_O-AUBEL = PF_ZPDI_I-VBELN.                      "(X)DN. / (X)SO.
    PF_ITEM_O-VGPOS = PF_ITEM_O-AUPOS = PF_ZPDI_I-POSNR.                      "(X)DN ITEM / (X)SO ITEM
    PF_ITEM_O-MATNR = PF_ZPDI_I-MATNR.                                        "MATERIAL NUMBER
    PF_ITEM_O-WEMEH = PF_ZPDI_I-VRKME.                                        "UNIT
    PF_ITEM_O-DWEMN = PF_ZPDI_I-FKIMG.                                        "SHIP QTY
    PF_ITEM_O-KWMEN = PF_ZPDI_I-FKIMG.                                        "order qty#
    PF_ITEM_O-KDMAT = PF_ZPDI_I-KDMAT.                                        "customer material
*    PF_ITEM_O-BRAND = ''.                                                     "BRAND
*    PF_ITEM_O-ZCHIP = ''.                                                     "CHIPNAME
    PF_ITEM_O-WAERK = PF_ZPDH_I-WAERK.                                        "CURRENCY
    PF_ITEM_O-BACKL = 0.                                                      "BACKLOG
    PF_ITEM_O-UNITP = PF_ZPDI_I-NETPR.                                        "Unit Price
    PF_ITEM_O-KPEIN = PF_ZPDI_I-KPEIN.                                        "UNIT PRICE BASE
    PF_ITEM_O-MAKTX = PF_ZPDI_I-TXT.                                          "Material Desc.

    IF PF_ZPDI_I-FKIMG IS NOT INITIAL.
      PF_ITEM_O-KWERT = PF_ZPDI_I-NETPR * PF_ZPDI_I-FKIMG / PF_ZPDI_I-KPEIN.  "extension
    ELSE.
      PF_ITEM_O-KWERT = PF_ZPDI_I-NETPR / PF_ZPDI_I-KPEIN.
    ENDIF.
    PF_ITEM_O-KBET1 = 0.                                                      "DISC
**Plant
    PERFORM GET_PLANT_BY_SO USING     PF_ZPDI_I-VBELN
                                      PF_ZPDI_I-POSNR
                            CHANGING  PF_ITEM_O-WERKS.

**Cust PO No. + Item[VBKD-BSTKD]
    PERFORM GET_CUST_PO_INFO  USING     PF_ZPDI_I-VBELN
                                        PF_ZPDI_I-POSNR
                              CHANGING  PF_ITEM_O-BSTKD
                                        PF_ITEM_O-POSEX.  "Cust PO item no
**Material Description
    PERFORM GET_WORKAREA_MAKT USING     PF_ZPDI_I-MATNR
                              CHANGING  PFWA_MAKT.
    IF PFWA_MAKT IS NOT INITIAL.
      PF_ITEM_O-MAKTX = PFWA_MAKT-MAKTX.
    ENDIF.
**BONDING
    PERFORM GET_BONDING USING     PF_ZPDI_I-MATNR
                                  PF_ITEM_O-WERKS
                        CHANGING  PF_ITEM_O-BONDI.
**WAFER Description
    PERFORM GET_WAFER_DESC USING    PF_ITEM_O-WERKS
                                    PF_ZPDI_I-MATNR
                           CHANGING PF_ITEM_O-WRKST.
**Tax/ Code
    PERFORM GET_TAX_VALUE USING     PF_ZPDH_I-PIDATE
                                    PF_ZPDH_I-TAXK1
                          CHANGING  PF_ITEM_O.

    APPEND PF_ITEM_O.
    CLEAR  PF_ITEM_O.
  ENDLOOP.
  SORT PF_ITEM_O BY VBELN POSNR.
  LOOP AT PF_ITEM_O WHERE  VBELN = PFWA_HEAD_I-VBELN
                    AND    ITMNO = ''.
**ITEM NO.
    ADD 1 TO PFV_ITMNO.
    PF_ITEM_O-ITMNO = PFV_ITMNO+02(04).
    MODIFY PF_ITEM_O.
  ENDLOOP.
ENDFORM.                    " GET_ITEM_DATA_NEWPI01
*&---------------------------------------------------------------------*
*&      Form  GET_PLANT_BY_SO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPDI_I_VBELN  text
*      -->P_PF_ZPDI_I_POSNR  text
*      <--P_PF_ITEM_O_WERKS  text
*----------------------------------------------------------------------*
FORM GET_PLANT_BY_SO  USING    PFV_AUBEL_I
                               PFV_AUPOS_I
                      CHANGING PFV_WERKS_O.
  DATA: PFWA_VBAP LIKE VBAP.
  CLEAR: PFV_WERKS_O.
  PERFORM GET_WORKAREA_VBAP USING     PFV_AUBEL_I
                                      PFV_AUPOS_I
                            CHANGING  PFWA_VBAP.
  CHECK PFWA_VBAP IS NOT INITIAL.
  PFV_WERKS_O = PFWA_VBAP-WERKS.
ENDFORM.                    " GET_PLANT_BY_SO
*&---------------------------------------------------------------------*
*&      Form  GET_TAX_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPDI_I_TAXK1  text
*      <--P_PF_ITEM_O_KBETR  text
*----------------------------------------------------------------------*
FORM GET_TAX_VALUE  USING    PFV_DATAB_I
                             PFV_TAXK1_I
                    CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  DATA: PF_FTAXP  LIKE FTAXP OCCURS 0 WITH HEADER LINE,
        PFV_MWSKZ TYPE MWSKZ.

  CLEAR: PFWA_ITEM_IO-KBETR, PFWA_ITEM_IO-MWSK1, PFV_MWSKZ.
  CASE PFV_TAXK1_I.
    WHEN '1'.
      PFV_MWSKZ = 'S2'.
      PFWA_ITEM_IO-MWSK1 = 'V'.
    WHEN '2'.
      PFV_MWSKZ = 'S1'.
      PFWA_ITEM_IO-MWSK1 = '0'.
    WHEN '3'.
      PFV_MWSKZ = 'S3'.
      PFWA_ITEM_IO-MWSK1 = 'N'.
    WHEN OTHERS.
  ENDCASE.
  PFWA_ITEM_IO-KBETR = 0.
  CALL FUNCTION 'GET_TAX_PERCENTAGE'
    EXPORTING
      ALAND   = 'TW'
      DATAB   = PFV_DATAB_I
      MWSKZ   = PFV_MWSKZ
      TXJCD   = ''
    TABLES
      T_FTAXP = PF_FTAXP.
  READ TABLE PF_FTAXP INDEX 1.

  CHECK PF_FTAXP-KBETR > 0.
  PFWA_ITEM_IO-KBETR = PF_FTAXP-KBETR / 10.

ENDFORM.                    " GET_TAX_VALUE
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_ZPD2_FROM_ZPDH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPDH_I  text
*      -->P_PF_ZPD2  text
*----------------------------------------------------------------------*
FORM GET_DATA_ZPD2_FROM_ZPDH  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                       PF_ZPD2_O STRUCTURE ZPD2.
  DATA: PF_ZPDH LIKE ZPDH OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_ZPD2_O, PF_ZPD2_O[], PF_ZPDH, PF_ZPDH[].
  APPEND LINES OF PF_ZPDH_I TO PF_ZPDH.
  SORT PF_ZPDH BY PERFI.
  DELETE ADJACENT DUPLICATES FROM PF_ZPDH COMPARING PERFI.
  CHECK PF_ZPDH[] IS NOT INITIAL.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZPD2_O  FROM   ZPD2
                                                  FOR ALL ENTRIES IN PF_ZPDH
                                                  WHERE  PERFI = PF_ZPDH-PERFI.
ENDFORM.                    " GET_DATA_ZPD2_FROM_ZPDH
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_ZPD6_FROM_ZPDH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZPDH_I  text
*      -->P_PF_ZPD6  text
*----------------------------------------------------------------------*
FORM GET_DATA_ZPD6_FROM_ZPDH  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                       PF_ZPD6_O STRUCTURE ZPD6.
  DATA: PF_ZPDH LIKE ZPDH OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_ZPD6_O, PF_ZPD6_O[], PF_ZPDH, PF_ZPDH[].
  APPEND LINES OF PF_ZPDH_I TO PF_ZPDH.
  SORT PF_ZPDH BY PERFI.
  DELETE ADJACENT DUPLICATES FROM PF_ZPDH COMPARING PERFI.
  CHECK PF_ZPDH[] IS NOT INITIAL.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZPD6_O  FROM   ZPD6
                                                  FOR ALL ENTRIES IN PF_ZPDH
                                                  WHERE  PERFI = PF_ZPDH-PERFI.
ENDFORM.                    " GET_DATA_ZPD6_FROM_ZPDH
*&---------------------------------------------------------------------*
*&      Form  SHIPPING_MARK_SPECIAL_RULE
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_SHIPPING_MARK  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                          P_SECON
                                 CHANGING P_CARTO_O.
  DATA: VBAKX LIKE VBAK.
  DATA: PFWA_VBAK LIKE VBAK,
        PV_DEL LIKE LIKP-VBELN,
        PV_SEQ(2) TYPE N,
        PV_FROM(12),
        PV_TO(12).

  IF PFWA_HEAD_I-KUNAG = '0000004091' OR             "Longsys
     PFWA_HEAD_I-KUNAG = '0000004240'.
    PERFORM GET_WORKAREA_VBAK USING     PFWA_HEAD_I-AUBEL
                              CHANGING  PFWA_VBAK.
    IF  PFWA_VBAK-VTWEG = '04' AND
        PFWA_VBAK-SPART = '02'.
      PV_DEL = PFWA_HEAD_I-VBELN.
      SHIFT PV_DEL LEFT DELETING LEADING '0'.
      IF P_SECON = 1.
        PV_SEQ = '01'.
        CONCATENATE PV_DEL PV_SEQ INTO P_CARTO_O.
        CONDENSE P_CARTO_O.
      ELSE.
        CONCATENATE PV_DEL '01' INTO PV_FROM. CONDENSE PV_FROM.
        PV_SEQ = P_SECON.
        CONCATENATE PV_DEL PV_SEQ INTO PV_TO. CONDENSE PV_TO.
        CONCATENATE PV_FROM '-' PV_TO INTO P_CARTO_O SEPARATED BY SPACE.
      ENDIF.
    ENDIF.
  ENDIF.   "End of  "Longsys

ENDFORM.                    " SHIPPING_MARK_SPECIAL_RULE
*&---------------------------------------------------------------------*
*&      Form  UPDATE_ZF32CA_LINE3_SPECIAL
*&---------------------------------------------------------------------*
FORM SP_RULE_FOR_ZF32CA_LINE3 USING    PFWA_HEAD_I STRUCTURE I_HEAD
                                       PFV_NUMB1_I
                              CHANGING PFV_REMARK_O.
  DATA: PFWA_VBAK     LIKE VBAK,
        PFV_VGBEL     TYPE VBELN_VL,
        PFV_SEQNO(2)  TYPE N.

  CHECK PFWA_HEAD_I-KUNAG = '0000004091' OR     "Longsys
        PFWA_HEAD_I-KUNAG = '0000004240'.
  CLEAR: PFV_REMARK_O.
  PERFORM GET_WORKAREA_VBAK USING     PFWA_HEAD_I-AUBEL
                            CHANGING  PFWA_VBAK.
  CHECK PFWA_VBAK-VTWEG = '04' AND
        PFWA_VBAK-SPART = '02'.
  PFV_VGBEL = PFWA_HEAD_I-VBELN.
  PERFORM CONVERSION_EXIT_ALPHA_OUTPUT CHANGING PFV_VGBEL.
  PFV_SEQNO = PFV_NUMB1_I.
  CONCATENATE PFV_VGBEL PFV_SEQNO
    INTO PFV_REMARK_O.
  CONDENSE PFV_REMARK_O.
  CONCATENATE 'C/NO:' PFV_REMARK_O INTO PFV_REMARK_O SEPARATED BY SPACE.

*  IF PFWA_HEAD_I-KUNAG =  '0000004091' OR
*     PFWA_HEAD_I-KUNAG = '0000004240'.
*    SELECT SINGLE * INTO VBAKX FROM VBAK WHERE VBELN = PFWA_HEAD_I-AUBEL.
*    IF VBAKX-VTWEG = '04' AND VBAKX-SPART = '02'.
*      PV_DEL = PFWA_HEAD_I-VBELN.
*      SHIFT PV_DEL LEFT DELETING LEADING '0'.
*      PV_SEQ = P_NUMB1.
*      CONCATENATE PV_DEL PV_SEQ INTO P_MARK.
*      CONDENSE P_MARK.
*      CONCATENATE 'C/NO:' P_MARK INTO P_MARK SEPARATED BY SPACE.
*    ENDIF.
*  ENDIF.   "End of  "Longsys
ENDFORM.                    " UPDATE_ZF32CA_LINE3_SPECIAL
*&---------------------------------------------------------------------*
*&      Form  GET_CURRENCY_FROM_HEADER_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDH  text
*      -->P_PFWA_HEAD_VBELN  text
*      <--P_I_ITEM_TO_WAERK  text
*----------------------------------------------------------------------*
FORM GET_CURRENCY_FROM_HEADER_DATA  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                    USING    PFV_VBELN_I
                                    CHANGING PFV_WAERK_O.
  DATA: PFWA_VBRK LIKE VBRK.
  CLEAR: PFV_WAERK_O.
  PERFORM GET_WORKAREA_VBRK USING     PFV_VBELN_I
                            CHANGING  PFWA_VBRK.
  PFV_WAERK_O = PFWA_VBRK-WAERK.
**沒有值可能是NEW PI的資料
  CHECK PFV_WAERK_O IS INITIAL.
  READ TABLE PF_ZPDH_I WITH KEY PERFI = PFV_VBELN_I.
  CHECK SY-SUBRC = 0.
  PFV_WAERK_O = PF_ZPDH_I-WAERK.

ENDFORM.                    " GET_CURRENCY_FROM_HEADER_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_USING_PI_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_I_ZPDH  text
*      -->P_PF_ZPD2  text
*      -->P_PF_ZPD6  text
*----------------------------------------------------------------------*
FORM GET_USING_PI_TABLE  TABLES   PF_HEAD_I STRUCTURE I_HEAD
                                  PF_VBFA_I STRUCTURE VBFA
                                  PF_ZPDH_I STRUCTURE ZPDH
                                  PF_ZPD2_O STRUCTURE ZPD2
                                  PF_ZPD6_O STRUCTURE ZPD6.
  DATA: PF_VBFA_TMP LIKE VBFA   OCCURS 0 WITH HEADER LINE,
        PF_ZPD2_TMP LIKE ZPD2   OCCURS 0 WITH HEADER LINE,
        PF_ZPD6_TMP LIKE ZPD6   OCCURS 0 WITH HEADER LINE,
        PF_HEAD_TMP LIKE I_HEAD OCCURS 0 WITH HEADER LINE.

  CLEAR: PF_VBFA_TMP, PF_VBFA_TMP[], PF_ZPD2_TMP, PF_ZPD2_TMP[], PF_ZPD6_TMP, PF_ZPD6_TMP[], PF_HEAD_TMP, PF_HEAD_TMP[].
  APPEND LINES OF PF_VBFA_I TO PF_VBFA_TMP.
  DELETE PF_VBFA_TMP WHERE VBTYP_N <> 'U'.

  IF PF_VBFA_TMP[] IS NOT INITIAL.
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_ZPD2_TMP  FROM ZPD2
                                                      FOR ALL ENTRIES IN PF_VBFA_TMP
                                                      WHERE PERFI = PF_VBFA_TMP-VBELN.
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE PF_ZPD6_TMP  FROM ZPD6
                                                      FOR ALL ENTRIES IN PF_VBFA_TMP
                                                      WHERE PERFI = PF_VBFA_TMP-VBELN.
    APPEND LINES OF PF_ZPD2_TMP TO PF_ZPD2_O.
    APPEND LINES OF PF_ZPD6_TMP TO PF_ZPD6_O.
    CLEAR: PF_ZPD2_TMP, PF_ZPD2_TMP[], PF_ZPD6_TMP, PF_ZPD6_TMP[].
  ENDIF.

  IF PF_ZPDH_I[] IS NOT INITIAL.
**先處理取得吃PI的出貨資料
    APPEND LINES OF PF_HEAD_I TO PF_HEAD_TMP.
    DELETE PF_HEAD_TMP WHERE PFLAG IS INITIAL.  "這樣就只會留有吃PI的INVOICE
    IF PF_HEAD_TMP[] IS NOT INITIAL.
      SELECT *
        INTO CORRESPONDING FIELDS OF TABLE PF_ZPD2_TMP  FROM ZPD2
                                                        FOR ALL ENTRIES IN PF_HEAD_TMP
                                                        WHERE VBELN = PF_HEAD_TMP-VBELN.
      SELECT *
        INTO CORRESPONDING FIELDS OF TABLE PF_ZPD6_TMP  FROM ZPD6
                                                        FOR ALL ENTRIES IN PF_HEAD_TMP
                                                        WHERE VBELN = PF_HEAD_TMP-VBELN.
      APPEND LINES OF PF_ZPD2_TMP TO PF_ZPD2_O.
      APPEND LINES OF PF_ZPD6_TMP TO PF_ZPD6_O.
      CLEAR: PF_ZPD2_TMP, PF_ZPD2_TMP[], PF_ZPD6_TMP, PF_ZPD6_TMP[].
    ENDIF.
**再處理PI已出過貨的部份
    PERFORM GET_DATA_ZPD2_FROM_ZPDH TABLES  PF_ZPDH_I
                                            PF_ZPD2_TMP.
    PERFORM GET_DATA_ZPD6_FROM_ZPDH TABLES  PF_ZPDH_I
                                            PF_ZPD6_TMP.
    APPEND LINES OF PF_ZPD2_TMP TO PF_ZPD2_O.
    APPEND LINES OF PF_ZPD6_TMP TO PF_ZPD6_O.
  ENDIF.

  SORT PF_ZPD2_O BY VBELN PERFI SEQNO.                      "U092519
  SORT PF_ZPD6_O BY VBELN PERFI SEQNO.                      "U092519
  DELETE ADJACENT DUPLICATES FROM PF_ZPD2_O.
  DELETE ADJACENT DUPLICATES FROM PF_ZPD6_O.
ENDFORM.                    " GET_USING_PI_TABLE
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VBRK_WITH_NEWPI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDH  text
*      -->P_PFWA_HEAD_VBELN  text
*      <--P_PFWA_VBRK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VBRK_WITH_NEWPI  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                                   USING    PFV_VBELN_I
                                   CHANGING PFWA_VBRK_O STRUCTURE VBRK.

  CLEAR: PFWA_VBRK_O.
  PERFORM GET_WORKAREA_VBRK USING     PFV_VBELN_I
                            CHANGING  PFWA_VBRK_O.
  CHECK PFWA_VBRK_O IS INITIAL.
  READ TABLE PF_ZPDH_I WITH KEY PERFI = PFV_VBELN_I.
  CHECK SY-SUBRC = 0.
  PFWA_VBRK_O-BUKRS = 'PSC'.
  PFWA_VBRK_O-WAERK = PF_ZPDH_I-WAERK.
  PFWA_VBRK_O-KURRF = PF_ZPDH_I-KURRF.
ENDFORM.                    " GET_WORKAREA_VBRK_WITH_NEWPI
*&---------------------------------------------------------------------*
*&      Form  GET_PI_TYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ZPDH  text
*      -->P_I_HEAD_VBELN  text
*      <--P_PFWA_ZPD1_PITYPE  text
*----------------------------------------------------------------------*
FORM GET_PI_TYPE  TABLES   PF_ZPDH_I STRUCTURE ZPDH
                  USING    PFV_VBELN_I
                  CHANGING PFV_PTYPE_O.

  DATA: PFV_LINES_X     TYPE TDLINE,            "接值用!!
        PFV_PTYPE(04)   TYPE C.
  CLEAR: PFV_PTYPE_O.

  PERFORM GET_PI_RATE_PRICE_DATA USING    PFV_VBELN_I
                                 CHANGING PFV_PTYPE
                                          PFV_LINES_X.
  IF PFV_PTYPE = 'PC'.              "以片計價
    PFV_PTYPE_O = 1.
    EXIT.
  ENDIF.

  READ TABLE PF_ZPDH_I WITH KEY PERFI = PFV_VBELN_I.
  CHECK SY-SUBRC = 0.
  PFV_PTYPE_O = PF_ZPDH_I-PITYPE.               "若I_ZPDH有值,以I_ZPDH為主
ENDFORM.                    " GET_PI_TYPE
*&---------------------------------------------------------------------*
*&      Form  GET_NEWPI_INFO_INTO_VBFA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_HEAD_IO  text
*      -->P_I_VBFA  text
*----------------------------------------------------------------------*
FORM GET_NEWPI_INFO_INTO_VBFA  TABLES   PF_HEAD_I   STRUCTURE I_HEAD
                                        PF_VBFA_IO  STRUCTURE VBFA.
  DATA: PF_ZPD2     LIKE ZPD2   OCCURS 0 WITH HEADER LINE,
        PF_HEAD_TMP LIKE I_HEAD OCCURS 0 WITH HEADER LINE,
        PF_VBFA_TMP LIKE VBFA   OCCURS 0 WITH HEADER LINE.
  CLEAR: PF_HEAD_TMP, PF_HEAD_TMP[], PF_VBFA_TMP, PF_VBFA_TMP[].

**只留下有使用PI的BILLING
  APPEND LINES OF PF_HEAD_I TO PF_HEAD_TMP.
  DELETE PF_HEAD_TMP WHERE PFLAG = ''.

  LOOP AT PF_HEAD_TMP.
    PERFORM GET_DATA_ZPD2_FROM_VBELN  TABLES PF_ZPD2
                                      USING  PF_HEAD_TMP-VBELN.
    CHECK PF_ZPD2[] IS NOT INITIAL.
    LOOP AT PF_ZPD2.
**檢查PI號碼是否有在 PF_VBFA_IO的LIST中,沒有就要新增
      READ TABLE PF_VBFA_IO WITH KEY VBELN = PF_ZPD2-PERFI.
      CHECK SY-SUBRC <> 0.
      PF_VBFA_TMP-VBELN   = PF_ZPD2-PERFI.
      PF_VBFA_TMP-VBTYP_N = 'U'.
      APPEND PF_VBFA_TMP.
      CLEAR: PF_VBFA_TMP.
    ENDLOOP.
  ENDLOOP.
  CHECK PF_VBFA_TMP[] IS NOT INITIAL.
  APPEND LINES OF PF_VBFA_TMP TO PF_VBFA_IO.

ENDFORM.                    " GET_NEWPI_INFO_INTO_VBFA
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZPDH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_VBRK_IO_VBELN  text
*      <--P_PFWA_ZPDH  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZPDH  USING    PFV_VBELN_I
                        CHANGING PFWA_ZPDH_O STRUCTURE ZPDH.
  CLEAR: PFWA_ZPDH_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZPDH_O  FROM  ZPDH
                                              WHERE PERFI = PFV_VBELN_I.
ENDFORM.                    " GET_WORKAREA_ZPDH
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_VEKP_UEVEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VBFA_VBELN  text
*      <--P_PFWA_VEKP  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_VEKP_UEVEL    USING    PFV_VENUM_I
                                CHANGING PFWA_VEKP_O STRUCTURE VEKP.
  CLEAR: PFWA_VEKP_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_VEKP_O FROM  VEKP
                                             WHERE VENUM = PFV_VENUM_I
                                             AND   UEVEL = ''.
ENDFORM.                    " GET_WORKAREA_VEKP_UEVEL
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_MARA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_BOXES_S_VHILM  text
*      <--P_PFWA_MARA  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_MARA  USING    PFV_MATNR_I
                        CHANGING PFWA_MARA_O STRUCTURE MARA.
  CLEAR: PFWA_MARA_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_MARA_O  FROM  MARA
                                              WHERE MATNR = PFV_MATNR_I.
ENDFORM.                    " GET_WORKAREA_MARA
*&---------------------------------------------------------------------*
*&      Form  GET_SHIPPING_PLANT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_HEAD  text
*      <--P_P_ZF32CA_SHIP_PLANT  text
*----------------------------------------------------------------------*
FORM GET_SHIPPING_PLANT  USING    PFWA_HEAD_I STRUCTURE I_HEAD
                         CHANGING PFV_SPLANT_O.
  DATA: PFWA_LIKP   LIKE LIKP,
        PFWA_ZF32CA LIKE ZF32CA.
  CLEAR: PFV_SPLANT_O.
  CASE PFWA_HEAD_I-VKORG.
    WHEN 'MAX1'.
      PERFORM GET_WORKAREA_LIKP USING     PFWA_HEAD_I-VBELN
                                CHANGING  PFWA_LIKP.
      CASE PFWA_LIKP-ZSITE.
        WHEN '8A'.
          PFV_SPLANT_O = 'MAX1'.
        WHEN '8B'.
          PFV_SPLANT_O = 'MAX2'.
        WHEN OTHERS.
          PFV_SPLANT_O = 'MAX1'.
      ENDCASE.
    WHEN 'PSC1'.
      CASE SY-UNAME.
        WHEN 'PSC1WM3'.
          PFV_SPLANT_O = 'PSC1'.
        WHEN 'PSC1WM4'.
          PFV_SPLANT_O = 'PSC1'.
        WHEN OTHERS.
          PERFORM GET_WORKAREA_ZF32CA_F32SERNO USING    PFWA_HEAD_I-VBELN
                                                        '1'
                                               CHANGING PFWA_ZF32CA.
          CHECK PFWA_ZF32CA-SHIP_PLANT IS NOT INITIAL.
          PFV_SPLANT_O = PFWA_ZF32CA-SHIP_PLANT.
      ENDCASE.
    WHEN OTHERS.
  ENDCASE.
*  CASE I_HEAD-VKORG.                                            "Ship plant 判斷
*    WHEN 'MAX1'.                                          "8 inch
*      P_ZF32CA-SHIP_PLANT = 'MAX1'.
*    WHEN  'PSC1'.                                         "12 inch
*      IF SY-UNAME = 'PSC1WM3'.
*        P_ZF32CA-SHIP_PLANT = 'PSC1'.
*      ELSEIF SY-UNAME = 'PSC1WM4'.
*        P_ZF32CA-SHIP_PLANT = 'PSC2'.
*      ELSE.
*        SELECT SINGLE * FROM ZF32CA WHERE VBELN = I_HEAD-VBELN
*                                      AND F32_SERNO = '1'.
*        IF SY-SUBRC = 0 AND ZF32CA-SHIP_PLANT <> SPACE.
*          P_ZF32CA-SHIP_PLANT = ZF32CA-SHIP_PLANT.
*        ENDIF.
*      ENDIF.
*  ENDCASE.
ENDFORM.                    " GET_SHIPPING_PLANT
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZF32CA_F32SERNO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I_VBELN  text
*      -->P_9097   text
*      <--P_PFWA_ZF32CA  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZF32CA_F32SERNO  USING    PFV_VGBEL_I
                                            PFV_SERNO_I
                                   CHANGING PFWA_ZF32CA_O STRUCTURE ZF32CA.
  CLEAR: PFWA_ZF32CA_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZF32CA_O  FROM  ZF32CA
                                                WHERE VBELN     = PFV_VGBEL_I
                                                AND   F32_SERNO = PFV_SERNO_I.
ENDFORM.                    " GET_WORKAREA_ZF32CA_F32SERNO
*&---------------------------------------------------------------------*
*&      Form  GET_FLOW_DATA_VBFA_HANDINGUNIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VBFA  text
*      -->P_PF_VBFA  text
*      -->P_I_HEAD_VBELN  text
*----------------------------------------------------------------------*
FORM GET_FLOW_DATA_VBFA_HANDINGUNIT  TABLES   PF_VBFA_I STRUCTURE VBFA
                                              PF_VBFA_O STRUCTURE VBFA
                                     USING    PFV_VGBEL_I.
  CLEAR: PF_VBFA_O, PF_VBFA_O[].
  APPEND LINES OF PF_VBFA_I TO PF_VBFA_O.
  DELETE PF_VBFA_O WHERE VBELV <> PFV_VGBEL_I.
  DELETE PF_VBFA_O WHERE VBTYP_N <> 'X'.
  CHECK PF_VBFA_O IS INITIAL.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_VBFA_O FROM   VBFA
                                                 WHERE  VBELV   = PFV_VGBEL_I
                                                 AND    VBTYP_N = 'X'.
ENDFORM.                    " GET_FLOW_DATA_VBFA_HANDINGUNIT
*&---------------------------------------------------------------------*
*&      Form  GET_BOX_LBH_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_BOXES_S_VHILM  text
*      <--P_P_BOXES_S_LAENG  text
*      <--P_P_BOXES_S_BREIT  text
*      <--P_P_BOXES_S_HOEHE  text
*----------------------------------------------------------------------*
FORM GET_BOX_LBH_VALUE  USING    PFV_MATNR_I
                        CHANGING PFV_LAENG_IO
                                 PFV_BREIT_IO
                                 PFV_HOEHE_IO.
  DATA: PFWA_MARA   LIKE MARA.
  CHECK PFV_LAENG_IO = 0 AND
        PFV_BREIT_IO = 0 AND
        PFV_HOEHE_IO = 0.
  PERFORM GET_WORKAREA_MARA USING     PFV_MATNR_I         "Material No.
                            CHANGING  PFWA_MARA.
  CHECK PFWA_MARA IS NOT INITIAL.
  SPLIT PFWA_MARA-GROES AT 'X'
    INTO PFV_LAENG_IO PFV_BREIT_IO PFV_HOEHE_IO.

ENDFORM.                    " GET_BOX_LBH_VALUE
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSDNXP3B2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM_IO_VGBEL  text
*      -->P_PF_ITEM_IO_VGPOS  text
*      <--P_PFWA_3B2  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSDNXP3B2  USING    PFV_VGBEL_I
                                      PFV_VGPOS_I
                             CHANGING PFWA_ZSDNXP3B2_O STRUCTURE ZSDNXP3B2.
  CLEAR: PFWA_ZSDNXP3B2_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZSDNXP3B2_O FROM ZSDNXP3B2
                                                  WHERE VBELN = PFV_VGBEL_I
                                                  AND   UECHA = PFV_VGPOS_I.
ENDFORM.                    " GET_WORKAREA_ZSDNXP3B2
*&---------------------------------------------------------------------*
*&      Form  GET_DATA_ZBCOD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZBCOD  text
*      -->P_PF_HEAD_I_VGBEL  text
*----------------------------------------------------------------------*
FORM GET_DATA_ZBCOD  TABLES   PF_ZBCOD_O STRUCTURE ZBCOD
                     USING    PFV_VGBEL_I.
  CLEAR: PF_ZBCOD_O, PF_ZBCOD_O[].
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE PF_ZBCOD_O FROM  ZBCOD
                                                  WHERE VBELN = PFV_VGBEL_I.
ENDFORM.                    " GET_DATA_ZBCOD
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZSDMX02
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ZMX3_MAXPO  text
*      -->P_PF_ZMX3_MXINO  text
*      <--P_PFWA_ZMX2  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZSDMX02  USING    PFV_MAXPO_I
                                    PFV_MXINO_I
                           CHANGING PFWA_ZSDMX02_O STRUCTURE ZSDMX02.
  CLEAR: PFWA_ZSDMX02_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZSDMX02_O  FROM  ZSDMX02
                                                 WHERE MAXPO = PFV_MAXPO_I
                                                 AND   MXINO = PFV_MXINO_I.
ENDFORM.                    " GET_WORKAREA_ZSDMX02
*&---------------------------------------------------------------------*
*&      Form  GET_WAFERQTY_BY_PRODTYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_I_PRODTYPE  text
*      -->P_PF_LIPS_I  text
*      <--P_PF_ITEM_IO  text
*----------------------------------------------------------------------*
FORM GET_WAFERQTY_BY_PRODTYPE  USING    PFWA_HEAD_I  STRUCTURE I_HEAD
                                        PFV_QTY_I
                               CHANGING PFWA_ITEM_IO STRUCTURE I_ITEM.
  IF PFWA_HEAD_I-ZTYPE = 'I' OR
     PFWA_HEAD_I-ZTYPE = 'F'.
    CHECK PFWA_HEAD_I-PRODTYPE = 'D'.
    PFWA_ITEM_IO-DCEMN = PFV_QTY_I.       "SHIP QTY(die qty)
    CHECK PFWA_ITEM_IO-DWEMN <> 0.
    MOVE 'ST' TO PFWA_ITEM_IO-WEMEH.
  ENDIF.

  IF PFWA_HEAD_I-ZTYPE = 'P'.
    CHECK PFWA_HEAD_I-PRODTYPE = 'D'.
    CHECK PFWA_ITEM_IO-DWEMN <> 0.
    MOVE 'ST' TO PFWA_ITEM_IO-WEMEH.
  ENDIF.
ENDFORM.                    " GET_WAFERQTY_BY_PRODTYPE
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZMWHJH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_HEAD_IO_VGBEL  text
*      <--P_PFWA_ZMWHJH  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZMWHJH  USING    PFV_VGBEL_I
                          CHANGING PFWA_ZMWHJH_O STRUCTURE ZMWHJH.
  CLEAR: PFWA_ZMWHJH_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZMWHJH_O  FROM  ZMWHJH
                                                WHERE VBELN = PFV_VGBEL_I.
ENDFORM.                    " GET_WORKAREA_ZMWHJH
*&---------------------------------------------------------------------*
*&      Form  SP_RULE_FOR_ITEM_BY_CUSTGP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PF_ITEM_IO  text
*      -->P_PFWA_HEAD_I  text
*----------------------------------------------------------------------*
FORM SP_RULE_FOR_ITEM_BY_CUSTGP  TABLES   PF_ITEM_IO  STRUCTURE I_ITEM
                                 USING    PFWA_HEAD_I STRUCTURE I_HEAD.
  DATA: PFWA_ZZAUSP   LIKE ZZAUSP,
        PFV_TDNAM(16) TYPE C,
        PFV_TLINE(30) TYPE C.

  CHECK PFWA_HEAD_I-KUNAG IN R_KTC.
  LOOP AT PF_ITEM_IO WHERE VBELN = PFWA_HEAD_I-VBELN
                     AND   ZTYPE = PFWA_HEAD_I-ZTYPE.
    CLEAR: PFV_TDNAM.
    CONCATENATE PF_ITEM_IO-AUBEL PF_ITEM_IO-AUBEL
      INTO PFV_TDNAM.
    PERFORM GET_SHIP_TO_PN    USING     PFV_TDNAM
                              CHANGING  PFV_TLINE.
    IF PFV_TLINE <> ''.
      CONCATENATE 'End Custom P/N:' PFV_TLINE
        INTO PF_ITEM_IO-4TH1.
    ENDIF.
**- KTC Group Show 14碼 part no
    PERFORM GET_WORKAREA_ZZAUSP USING PF_ITEM_IO-WERKS
                                      PF_ITEM_IO-MATNR
                             CHANGING PFWA_ZZAUSP.
    CHECK P_JOBTPS <> 'E' AND P_JOBTPS <> 'N'.
    CHECK PF_ITEM_IO-WERKS = 'PSC4' AND
          PFWA_ZZAUSP-PRODTYPE <> 'P' AND
          PFWA_ZZAUSP-PRODTYPE <> 'S'.
    PF_ITEM_IO-MATNR = PF_ITEM_IO-MATNR+0(14).
  ENDLOOP.
ENDFORM.                    " SP_RULE_FOR_ITEM_BY_CUSTGP
*&---------------------------------------------------------------------*
*&      Form  GET_WORKAREA_ZZVBAK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PFWA_ITEM_I_AUBEL  text
*      <--P_PFWA_ZZVBAK  text
*----------------------------------------------------------------------*
FORM GET_WORKAREA_ZZVBAK  USING    PFV_AUBEL_I
                          CHANGING PFWA_ZZVBAK_O STRUCTURE ZZVBAK.
  CLEAR: PFWA_ZZVBAK_O.
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF PFWA_ZZVBAK_O  FROM  ZZVBAK
                                                WHERE VBELN = PFV_AUBEL_I.
ENDFORM.                    " GET_WORKAREA_ZZVBAK
