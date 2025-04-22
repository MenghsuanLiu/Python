# %%
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import pandas as pd
import json
import os
import shioaji as sj
from datetime import datetime
import math
import requests

class ExcelUploadWindow:
    def __init__(self, username):
        self.username = username
        self.df = None
        
        # 讀取使用者ID
        config_path = os.path.join(os.path.dirname(__file__), 'config', 'init.json')
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            # 找到對應的使用者ID
            self.user_id = next(
                user['id'] 
                for user_key, user in config['users'].items() 
                if isinstance(user, dict) and user.get('name') == username
            )
            self.ca_path = next(
                user['ca_path']
                for user_key, user in config['users'].items() 
                if isinstance(user, dict) and user.get('name') == username
            )

        # 建立主視窗
        self.root = tk.Tk()
        self.root.title(f"Excel 上傳系統 - {username}")
        self.root.geometry("900x600")

        # 建立主框架
        self.main_frame = ttk.Frame(self.root, padding="20")
        self.main_frame.pack(fill="both", expand=True)

        # 建立按鈕框架
        button_frame = ttk.Frame(self.main_frame)
        button_frame.pack(pady=10)
        
        # 上傳與下載按鈕並排
        ttk.Button(button_frame, text="選擇 Excel 檔案", 
                  command=self.upload_excel).pack(side="left", padx=5)
                       
        ttk.Button(button_frame, text="下載Excel範例", 
                  command=self.download_template).pack(side="left", padx=5)

        # 新增檢查Remark的Checkbox
        self.check_all = tk.BooleanVar(value=True)
        ttk.Checkbutton(button_frame, text="全部下單", 
                       variable=self.check_all).pack(side="left", padx=5)
        # 建立表格框架
        self.table_frame = ttk.Frame(self.main_frame)
        self.table_frame.pack(fill="both", expand=True)

        # 新增總金額框架 (在表格框下方)
        total_frame = ttk.Frame(self.table_frame)
        total_frame.pack(fill="x", pady=5)
        
        # 建立總金額標籤並靠右對齊
        self.total_label = ttk.Label(total_frame, text="總預計費用: 0")
        self.total_label.pack(side="right", padx=5)
        
        # 建立上方工具列框架
        tools_frame = ttk.Frame(self.table_frame)
        tools_frame.pack(fill="x", pady=5)
        
        # 金額輸入框移到右側
        amount_frame = ttk.Frame(tools_frame)
        amount_frame.pack(side="right", padx=10)
        ttk.Label(amount_frame, text="輸入每檔目標金額:").pack(side="left")
        
        # 驗證函數
        def validate_amount(P):
            if len(P) > 5:  # 限制長度
                return False
            if P == "":  # 允許空值
                return True
            return P.isdigit()  # 只允許數字
        
        vcmd = self.root.register(validate_amount)
        self.amount_entry = ttk.Entry(amount_frame, width=10, 
                                    validate="key",
                                    validatecommand=(vcmd, '%P'),
                                    justify='right')
        self.amount_entry.pack(side="left")
        self.amount_entry.insert(0, "100")
        self.amount_entry.bind('<KeyRelease>', self.on_amount_change)

        # 表格操作按鈕框架
        table_buttons_frame = ttk.Frame(tools_frame)
        table_buttons_frame.pack(side="left", fill="x")
        
        # 建立按鈕並設定為禁用狀態
        self.add_row_btn = ttk.Button(table_buttons_frame, text="新增列", 
                                     command=self.add_row, state="disabled")
        self.add_row_btn.pack(side="left", padx=5)
        
        self.del_row_btn = ttk.Button(table_buttons_frame, text="刪除列", 
                                     command=self.delete_row, state="disabled")
        self.del_row_btn.pack(side="left", padx=5)

        self.clear_btn = ttk.Button(table_buttons_frame, text="清除資料", 
                                   command=self.clear_data, state="disabled")
        self.clear_btn.pack(side="left", padx=5)

        # 建立 Treeview 用於顯示數據
        self.tree = ttk.Treeview(self.table_frame)
        self.tree.pack(fill="both", expand=True)

        # 新增捲軸
        scrollbar_y = ttk.Scrollbar(self.table_frame, orient="vertical", 
                                  command=self.tree.yview)
        scrollbar_y.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar_y.set)

        # 綁定雙擊事件
        self.tree.bind("<Double-1>", self.on_double_click)

        # 建立編輯框
        self.entry_popup = None

        # # 保存按鈕
        # ttk.Button(self.main_frame, text="保存修改", 
        #           command=self.save_changes).pack(pady=10)
                  
        # 新增產生訂單按鈕
        ttk.Button(self.main_frame, text="產生訂單", 
                  command=self.generate_order).pack(pady=10)

        # 建立訊息框架
        self.message_frame = ttk.LabelFrame(self.main_frame, text="系統訊息")
        self.message_frame.pack(fill="x", pady=10)
        
        # 建立訊息文字框 (設為唯讀)
        self.message_text = tk.Text(self.message_frame, height=4, wrap=tk.WORD, state="disabled")
        self.message_text.pack(fill="x", padx=5, pady=5)
        
        # 新增捲軸
        scrollbar = ttk.Scrollbar(self.message_frame, command=self.message_text.yview)
        scrollbar.pack(side="right", fill="y")
        self.message_text.configure(yscrollcommand=scrollbar.set)

        # Add after tree configuration
        # self.tree.tag_configure('price_diff', background='yellow')
        self.tree.tag_configure('price_invalid', foreground='red')  # Change to bright red

        # 登入功能
    def login_api(self):
        # 讀取登入資訊
        config_path = os.path.join(os.path.dirname(__file__), 'config', 'init.json')
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            login_info = config['login']

        # 初始化API
        api = sj.Shioaji()
        
        # 登入
        api.login(
            login_info['token'],
            login_info['key'],
            contracts_cb=lambda security_type: print(f"{security_type} fetch done.")
        )
        return api
    
    def show_message(self, message, level="info"):
        color = {
            "info": "black",
            "warning": "orange",
            "error": "red"
        }.get(level, "black")
        
        # 暫時啟用文字框以插入訊息
        self.message_text.config(state="normal")
        
        # 插入時間戳記和訊息
        from datetime import datetime
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.message_text.insert("1.0", f"[{timestamp}] {message}\n")
        
        # 設定顏色
        line_start = "1.0"
        line_end = "2.0"
        self.message_text.tag_add(level, line_start, line_end)
        self.message_text.tag_config(level, foreground=color)
        
        # 自動捲動到最新訊息
        self.message_text.see("1.0")
        
        # 恢復唯讀狀態
        self.message_text.config(state="disabled")

    def update_button_states(self, enable=True):
        state = "normal" if enable else "disabled"
        self.add_row_btn.configure(state=state)
        self.del_row_btn.configure(state=state)
        self.clear_btn.configure(state="error")

    def on_amount_change(self, event=None):
        if self.df is not None:
            self.recalculate_qty()
            self.update_table()

    def calculate_total_amount(self):
        if self.df is not None and 'Amount' in self.df.columns:
            total = int(round(self.df['Amount'].sum()))  # 改為無條件捨去到整數
            self.total_label.config(text=f"總預計費用: {total:,}")

    def recalculate_qty(self):
        target_amount = int(self.amount_entry.get())
        for index, row in self.df.iterrows():
            try:
                price = float(row['price'])
                if price > 0:
                    qty = math.ceil(target_amount / price)
                    self.df.at[index, 'Qty'] = qty
                    self.df.at[index, 'Amount'] = round(qty * price, 1)
            except:
                continue
        self.calculate_total_amount()  # 更新總金額

    def get_stock_data(self):
        """從TWSE和TPEx API取得每日交易資料"""
        stock_data = {}
        try:
            # 取得上市資料
            twse_url = "https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL"
            twse_response = requests.get(twse_url)
            if twse_response.status_code == 200:
                for item in twse_response.json():
                    stock_data[item['Code']] = {
                        'Close': item['ClosingPrice'],
                        'Name': item['Name']
                    }
            
            # 取得上櫃資料
            tpex_url = "https://www.tpex.org.tw/openapi/v1/tpex_mainboard_daily_close_quotes"
            tpex_response = requests.get(tpex_url)
            if tpex_response.status_code == 200:
                for item in tpex_response.json():
                    stock_data[item['SecuritiesCompanyCode']] = {
                        'Close': item['Close'],
                        'Name': item['CompanyName'],
                        'LimitUp': item['NextLimitUp'],
                        'LimitDown': item['NextLimitDown']
                    }
            
            return stock_data
        except Exception as e:
            self.show_message(f"取得股價資料失敗: {str(e)}", "warning")
            return {}

    def upload_excel(self):
        try:
            file_path = filedialog.askopenfilename(
                filetypes=[("Excel files", "*.xlsx *.xls")]
            )
            if file_path:
                self.df = pd.read_excel(file_path)
                # 新增價格欄位和股票名稱欄位
                if 'StockName' not in self.df.columns:
                    self.df.insert(
                        list(self.df.columns).index('StockID') + 1, 
                        'StockName', 
                        None
                    )
                if '漲停價' not in self.df.columns:
                    self.df['漲停價'] = None
                if '跌停價' not in self.df.columns:
                    self.df['跌停價'] = None
                if '收盤價' not in self.df.columns:
                    漲停價_idx = self.df.columns.get_loc('漲停價') if '漲停價' in self.df.columns else len(self.df.columns)
                    self.df.insert(漲停價_idx, '收盤價', None)
                if 'Qty' not in self.df.columns:
                    price_idx = list(self.df.columns).index('price')
                    self.df.insert(price_idx + 1, 'Qty', None)
                if 'Amount' not in self.df.columns:
                    qty_idx = list(self.df.columns).index('Qty')
                    self.df.insert(qty_idx + 1, 'Amount', None)
                if 'Remark' not in self.df.columns:  # Add Remark column
                    self.df['Remark'] = ''

                # 取得TWSE資料
                twse_data = self.get_stock_data()  # 修改方法名稱
                
                # 取得價格資訊
                api = self.login_api()
                target_amount = int(self.amount_entry.get())
                
                for index, row in self.df.iterrows():
                    try:
                        stock_id = str(row['StockID'])
                        contract = api.Contracts.Stocks[stock_id]
                        stock_info = twse_data.get(stock_id, {})
                        self.df.at[index, 'StockName'] = stock_info.get('Name', contract.name)
                        self.df.at[index, '收盤價'] = stock_info.get('Close', contract.reference)
                        self.df.at[index, '漲停價'] = stock_info.get('LimitUp',contract.limit_up)
                        self.df.at[index, '跌停價'] = stock_info.get('LimitDown',contract.limit_down)
                        # self.df.at[index, 'Close'] = stock_info.get('Close')
                        
                        # 處理 price 欄位的特殊值
                        price_value = str(row['price'])
                        if price_value == '-':
                            price = contract.limit_down
                            self.df.at[index, 'price'] = price
                        elif price_value == '+':
                            price = contract.limit_up
                            self.df.at[index, 'price'] = price
                        else:
                            price = float(price_value)
                            
                        # 檢查價格是否超出限制
                        if price > float(contract.limit_up):
                            self.df.at[index, 'Remark'] = '價格超過漲停'
                        elif price < float(contract.limit_down):
                            self.df.at[index, 'Remark'] = '價格低於跌停'
                        else:
                            self.df.at[index, 'Remark'] = ''
                            
                        # 計算可買數量和金額 (金額到小數點1位)
                        if price > 0:
                            qty = math.ceil(target_amount / price)
                            self.df.at[index, 'Qty'] = qty
                            self.df.at[index, 'Amount'] = round(qty * price, 1)
                            
                    except Exception as e:
                        self.show_message(f"無法取得股票 {row['StockID']} 的資訊: {str(e)}", "warning")
                
                api.logout()
                self.update_table()
                self.update_button_states(True)
                self.calculate_total_amount()  # 更新總金額
                self.show_message("Excel 檔案上傳成功！")
        except Exception as e:
            self.show_message(f"上傳失敗：{str(e)}", "error")
            self.update_button_states(False)

    def update_table(self):
        # 清空現有表格
        for item in self.tree.get_children():
            self.tree.delete(item)

        # 設定欄位 (加入序號欄位)
        columns = ['序號'] + list(self.df.columns)
        self.tree["columns"] = columns
        self.tree["show"] = "headings"

        # 設定欄位標題
        for column in columns:
            self.tree.heading(column, text=column)
            self.tree.column(column, width=100)
            
            # 設定欄位對齊方式
            if column == '序號':
                self.tree.column(column, anchor='center')  # 置中對齊
                self.tree.tag_configure('seq_column', background='#E8E8E8')
            elif column in ['StockID', 'StockName']:  # 加入 StockName 靠左對齊
                self.tree.column(column, anchor='w')
            elif column in ['Qty', 'price', 'Amount', '漲停價', '跌停價', '收盤價']:
                self.tree.column(column, anchor='e')
            else:
                self.tree.column(column, anchor='e')

        # 插入數據 (加入序號)
        for i, row in self.df.iterrows():
            values = [str(i+1)] + list(row)
            tags = ['seq_column']
            
            # 檢查收盤價和Close是否不同
            try:
    
                # 檢查價格是否超出限制
                if pd.notna(row['Remark']) and row['Remark'] != '':
                    tags.append('price_invalid')
            except:
                pass
                
            self.tree.insert("", "end", values=values, tags=tuple(tags))

    def save_changes(self):
        try:
            # 獲取修改後的數據
            data = []
            for item in self.tree.get_children():
                data.append(self.tree.item(item)["values"])
            
            # 更新 DataFrame
            self.df = pd.DataFrame(data, columns=self.df.columns)
            messagebox.showinfo("成功", "修改已保存！")
        except Exception as e:
            messagebox.showerror("錯誤", f"保存失敗：{str(e)}")

    def on_double_click(self, event):
        # 獲取點擊的項目
        region = self.tree.identify("region", event.x, event.y)
        if (region != "cell"):
            return

        # 獲取點擊的列和欄
        column = self.tree.identify_column(event.x)
        item = self.tree.identify_row(event.y)
        
        if not item or not column:
            return

        # 獲取欄位索引及名稱
        col_num = int(column[1]) - 1
        col_name = self.tree["columns"][col_num]
        
        # 檢查是否為不可編輯的欄位
        protected_columns = ['序號', 'StockName', 'Amount', '收盤價',  '漲停價', '跌停價', 'Remark']
        if col_name in protected_columns:
            return

        # 獲取單元格資訊
        cell_value = self.tree.item(item)['values'][col_num]

        # 獲取單元格的座標
        x, y, w, h = self.tree.bbox(item, column)

        # 刪除現有的編輯框
        if self.entry_popup:
            self.entry_popup.destroy()

        # 建立新的編輯框
        self.entry_popup = ttk.Entry(self.tree)
        self.entry_popup.insert(0, cell_value)
        self.entry_popup.select_range(0, tk.END)
        
        # 設定編輯框位置
        self.entry_popup.place(x=x, y=y, width=w, height=h)
        self.entry_popup.focus_set()

        # 綁定確認編輯事件
        self.entry_popup.bind("<Return>", 
            lambda e: self.on_entry_confirm(item, col_num))
        self.entry_popup.bind("<FocusOut>", 
            lambda e: self.on_entry_confirm(item, col_num))

    def on_entry_confirm(self, item, col_num):
        if self.entry_popup:
            # 獲取新值
            new_value = self.entry_popup.get()
            
            # 更新表格數據
            current_values = list(self.tree.item(item)['values'])
            current_values[col_num] = new_value
            self.tree.item(item, values=current_values)
            
            # 取得欄位名稱
            col_name = self.tree["columns"][col_num]
            
            # 如果修改的是price或Qty,重新計算Amount
            if col_name in ['price', 'Qty']:
                try:
                    # 取得目前列的price和qty值
                    item_values = self.tree.item(item)['values']
                    price_idx = self.tree["columns"].index('price')
                    qty_idx = self.tree["columns"].index('Qty')
                    price = float(item_values[price_idx])
                    qty = int(item_values[qty_idx])
                    
                    # 計算新的Amount
                    amount = round(price * qty, 1)
                    
                    # 更新Amount欄位
                    amount_idx = self.tree["columns"].index('Amount')
                    current_values[amount_idx] = amount
                    self.tree.item(item, values=current_values)
                    
                    # 更新DataFrame
                    self.save_table_to_df()
                    
                    # 重新計算總金額
                    self.calculate_total_amount()
                except:
                    pass
            
            # 刪除編輯框
            self.entry_popup.destroy()
            self.entry_popup = None

    def download_template(self):
        try:
            template_df = pd.DataFrame({
                'StockID': ['2330', '2317', '6770'],
                'price': ["-", "+", "13.0"]  # 更新範例，使用 "-" 和 "+" 符號
            })
            
            # 讓使用者選擇存檔位置
            file_path = filedialog.asksaveasfilename(
                defaultextension='.xlsx',
                filetypes=[("Excel files", "*.xlsx")],
                initialfile='order_sample.xlsx'
            )
            
            if file_path:
                template_df.to_excel(file_path, index=False)
                self.show_message("範例檔案已下載！")
        except Exception as e:
            self.show_message(f"下載範例失敗：{str(e)}", "error")

    def save_skipped_orders(self, skipped_orders):
        """存儲未下單的資料"""
        if skipped_orders:
            try:
                df_skipped = pd.DataFrame(skipped_orders)
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"skipped_orders_{timestamp}.xlsx"
                filepath = filedialog.asksaveasfilename(
                    defaultextension='.xlsx',
                    filetypes=[("Excel files", "*.xlsx")],
                    initialfile=filename
                )
                if filepath:
                    df_skipped.to_excel(filepath, index=False)
                    self.show_message(f"未下單資料已儲存至: {filepath}")
            except Exception as e:
                self.show_message(f"儲存未下單資料失敗: {str(e)}", "error")

    def generate_order(self):
        if self.df is None:
            self.show_message("請先上傳Excel檔案！", "warning")
            return
            
        try:
            # 呼叫登入函數
            api = self.login_api()

            # 憑證登入 - 使用使用者的ID和CA路徑
            api.activate_ca(
                ca_path=self.ca_path,
                ca_passwd=self.user_id,
                person_id=self.user_id
            )
            self.show_message(self.user_id)
            # 取得所有帳號並找出登入者的帳號
            accounts = api.list_accounts()
            target_account_index = next(
                (i for i, account in enumerate(accounts)
                if account.person_id == self.user_id),
                None
            )
            
            if target_account_index is None:
                self.show_message("找不到對應的帳號", "error")
                return
                
            # 切換至登入者帳號
            api.set_default_account(account=accounts[target_account_index])
            self.show_message("登入成功！")
            self.show_message(api.stock_account)
            self.show_message(self.user_id)
            self.show_message(self.ca_path)

            # 初始化未下單清單和計數器
            skipped_orders = []
            success_count = 0
            
            # 處理每一筆股票下單
            for _, row in self.df.iterrows():
                stock_id = str(row['StockID'])
                
                # 根據checkbox狀態決定是否檢查Remark
                if not self.check_all.get() and pd.notna(row['Remark']) and row['Remark'] != '':
                    skipped_orders.append(row.to_dict())
                    self.show_message(f"股票 {stock_id} 因備註：{row['Remark']}，不進行下單", "warning")
                    continue
                    
                try:
                    price = row['price']
                    quantity = int(row['Qty'])
                    contract = api.Contracts.Stocks[stock_id]
                    
                    # 建立訂單資料
                    order = api.Order(
                        price=price,
                        quantity=quantity,
                        action="Buy",
                        price_type="LMT",
                        order_type="ROD",
                        order_lot="IntradayOdd",
                        account=api.stock_account
                    )
                    
                    # 下單
                    trade = api.place_order(contract, order)
                    if trade.status.status_code == "0":
                        success_count += 1
                        self.show_message(f"股票 {stock_id} 下單成功，委託價: {price}，委託書號: {trade.order.ordno}，網路單號: {trade.order.seqno}，狀態: {trade.status.msg}")
                    else:
                        self.show_message(f"股票 {stock_id} 下單失敗，委託價: {price}，原因: {trade.status.msg}")
                        skipped_orders.append(row.to_dict())
                        
                except Exception as e:
                    self.show_message(f"股票 {stock_id} 下單失敗，原因: {str(e)}", "error")
                    skipped_orders.append(row.to_dict())
            
            # 顯示下單統計
            total_orders = len(self.df)
            skipped_count = len(skipped_orders)
            self.show_message(f"下單完成！總共 {total_orders} 筆訂單，成功 {success_count} 筆，未下單 {skipped_count} 筆")
            
            # 儲存未下單資料
            if skipped_orders:
                self.save_skipped_orders(skipped_orders)
                
            api.logout()

        except Exception as e:
            self.show_message(f"下單失敗：{str(e)}", "error")
            try:
                api.logout()
            except:
                pass

    def add_row(self):
        # 新增空白列 (包含序號)
        row_count = len(self.tree.get_children()) + 1
        empty_row = [str(row_count)] + [""] * len(self.df.columns if self.df is not None else 3)
        self.tree.insert("", "end", values=empty_row)
        self.save_table_to_df()

    def delete_row(self):
        # 獲取選中的項目
        selected_items = self.tree.selection()
        if not selected_items:
            self.show_message("請先選擇要刪除的列", "warning")
            return
            
        # 刪除選中的列
        for item in selected_items:
            self.tree.delete(item)
        self.save_table_to_df()
        self.show_message("已刪除選中的列")

    def clear_data(self):
        self.df = None
        for item in self.tree.get_children():
            self.tree.delete(item)
        self.update_button_states(False)
        self.total_label.config(text="總預計費用: 0")  # 清除總金額
        self.show_message("已清除所有資料")

    def save_table_to_df(self):
        # 將表格數據保存到DataFrame (排除序號欄位)
        data = []
        for item in self.tree.get_children():
            values = self.tree.item(item)["values"]
            data.append(values[1:])  # 排除序號欄位
        
        if data:  # 確保有數據
            self.df = pd.DataFrame(data, columns=self.df.columns)
            # 重新計算總金額
            self.calculate_total_amount()
        else:
            self.df = None

    def run(self):
        self.root.mainloop()

class LoginWindow:
    def __init__(self):
        # 讀取使用者資料
        config_path = os.path.join(os.path.dirname(__file__), 'config', 'init.json')
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                self.users = config['users']
        except FileNotFoundError:
            self.users = {"": ""}
            os.makedirs(os.path.dirname(config_path), exist_ok=True)
            with open(config_path, 'w', encoding='utf-8') as f:
                json.dump({"users": self.users}, f, ensure_ascii=False, indent=4)

        # 建立主視窗
        self.root = tk.Tk()
        self.root.title("登入系統")
        self.root.geometry("300x200")

        # 建立框架
        frame = ttk.Frame(self.root, padding="20")
        frame.pack(fill="both", expand=True)

        # 建立標籤
        ttk.Label(frame, text="請選擇使用者:").pack(pady=10)

        # 建立下拉選單
        self.selected_user = tk.StringVar()
        self.combo = ttk.Combobox(frame, 
                                 textvariable=self.selected_user,
                                 values=[user['name'] for key, user in self.users.items() 
                                       if isinstance(user, dict)],
                                 state="readonly",
                                 width=30)
        self.combo.pack(pady=10)
        self.combo.set("")

        # 建立登入按鈕
        ttk.Button(frame, text="登入", command=self.login).pack(pady=10)

    def login(self):
        if self.selected_user.get() == "":
            messagebox.showwarning("警告", "請選擇使用者!")
            return
        
        self.root.destroy()
        
        # 直接實例化 ExcelUploadWindow (不需要 import)
        upload_window = ExcelUploadWindow(self.selected_user.get())
        upload_window.run()

    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    app = LoginWindow()
    app.run()

# %%
