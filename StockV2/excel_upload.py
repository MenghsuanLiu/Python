import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import pandas as pd
import json
import os
import shioaji as sj
from tkcalendar import DateEntry  # 新增 import
from datetime import datetime

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
        self.root.geometry("800x600")

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

        # 新增日期選擇框架
        date_frame = ttk.Frame(self.main_frame)
        date_frame.pack(fill="x", pady=5)
        ttk.Label(date_frame, text="最近交易日期:").pack(side="left", padx=5)
        self.date_picker = DateEntry(date_frame, width=12, 
                                   background='darkblue',
                                   foreground='white',
                                   borderwidth=2,
                                   date_pattern='yyyy-mm-dd',
                                   locale='zh_TW')
        self.date_picker.pack(side="left", padx=5)
        self.date_picker.bind("<<DateEntrySelected>>", self.update_closing_prices)

        # 建立表格框架
        self.table_frame = ttk.Frame(self.main_frame)
        self.table_frame.pack(fill="both", expand=True)
        
        # 新增表格操作按鈕框架
        table_buttons_frame = ttk.Frame(self.table_frame)
        table_buttons_frame.pack(fill="x", pady=5)
        
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
        self.clear_btn.configure(state=state)

    def update_closing_prices(self, event=None):
        if self.df is None:
            return
            
        try:
            # 取得選擇的日期
            selected_date = self.date_picker.get_date()
            date_str = selected_date.strftime('%Y/%m/%d')

            # 呼叫登入函數
            api = self.login_api()

            # 更新收盤價
            closing_prices = []
            limit_up_prices = []
            limit_down_prices = []
            
            for stock_id in self.df['股號']:
                try:
                    contract = api.Contracts.Stocks[str(stock_id)]
                    if contract.update_date != date_str:
                        closing_prices.append(None)
                        limit_up_prices.append(None)
                        limit_down_prices.append(None)
                    else:
                        closing_prices.append(contract.reference)
                        limit_up_prices.append(contract.limit_up)
                        limit_down_prices.append(contract.limit_down)
                except Exception as e:
                    self.show_message(f"無法取得股票 {stock_id} 的價格資訊: {str(e)}", "warning")
                    closing_prices.append(None)
                    limit_up_prices.append(None)
                    limit_down_prices.append(None)

            # 更新DataFrame和表格
            self.df['收盤價'] = closing_prices
            self.df['漲停價'] = limit_up_prices
            self.df['跌停價'] = limit_down_prices
            self.update_table()
            self.show_message(f"已更新收盤價 (日期: {date_str})")
            api.logout()
        except Exception as e:
            self.show_message(f"更新收盤價失敗：{str(e)}", "error")

    def upload_excel(self):
        try:
            file_path = filedialog.askopenfilename(
                filetypes=[("Excel files", "*.xlsx *.xls")]
            )
            if file_path:
                self.df = pd.read_excel(file_path)
                # 新增價格欄位
                if '漲停價' not in self.df.columns:
                    self.df['漲停價'] = None
                if '跌停價' not in self.df.columns:
                    self.df['跌停價'] = None
                if '收盤價' not in self.df.columns:
                    self.df['收盤價'] = None
                    
                self.update_closing_prices()
                self.update_button_states(True)
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
            elif column in ['股號', '股名']:
                self.tree.column(column, anchor='w')  # 靠左對齊
            else:
                self.tree.column(column, anchor='e')  # 靠右對齊

        # 插入數據 (加入序號)
        for i, row in self.df.iterrows():
            values = [str(i+1)] + list(row)
            self.tree.insert("", "end", values=values, tags=('seq_column',))

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
        if region != "cell":
            return

        # 獲取點擊的列和欄
        column = self.tree.identify_column(event.x)
        item = self.tree.identify_row(event.y)
        
        if not item or not column:
            return

        # 獲取欄位索引
        col_num = int(column[1]) - 1
        
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
            
            # 刪除編輯框
            self.entry_popup.destroy()
            self.entry_popup = None

    def download_template(self):
        try:
            # 建立範例DataFrame
            template_df = pd.DataFrame({
                '股號': ['2330', '2317', '6770'],
                '股名': ['台積電', '鴻海', '力積電'],
                '下單數量(股)': [1, 1, 5],
                'price': ["L", "H", 13.0]  # 新增價格欄位
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

            # 處理每一筆股票下單
            for _, row in self.df.iterrows():
                stock_id = str(row['股號'])
                quantity = int(row['下單數量(股)'])
                price_type = str(row['price']).upper()
                
                # 取得商品資訊
                contract = api.Contracts.Stocks[stock_id]
                
                # 根據price欄位決定價格和價格類型
                if price_type == 'L':
                    price = contract.limit_down
                    order_price_type = "LMT"
                elif price_type == 'H':
                    price = contract.limit_up
                    order_price_type = "LMT"
                elif price_type == '0':
                    price = 0
                    order_price_type = "MKT"
                else:
                    price = float(price_type)

                # 建立訂單資料
                order = api.Order(
                    price=price,
                    quantity=quantity,
                    action="Buy",
                    price_type=order_price_type,
                    order_type="ROD",
                    order_lot="IntradayOdd",
                    account=api.stock_account
                )
                
                # 下單
                trade = api.place_order(contract, order)
                if trade.status.status_code == "0":
                    self.show_message(f"股票 {stock_id} 下單成功，委託價: {price}，委託書號: {trade.order.ordno}，網路單號: {trade.order.seqno}，狀態: {trade.status.msg}")
                else:
                    self.show_message(f"股票 {stock_id} 下單失敗，委託價: {price}，原因: {trade.status.msg}")
                
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
        self.show_message("已清除所有資料")

    def save_table_to_df(self):
        # 將表格數據保存到DataFrame (排除序號欄位)
        data = []
        for item in self.tree.get_children():
            values = self.tree.item(item)["values"]
            data.append(values[1:])  # 排除序號欄位
        
        if data:  # 確保有數據
            self.df = pd.DataFrame(data, columns=self.df.columns)
        else:
            self.df = None

    def run(self):
        self.root.mainloop()