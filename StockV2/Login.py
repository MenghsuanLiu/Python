import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import json
import os

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
        self.combo.set("")  # 設定預設值為空白

        # 建立登入按鈕
        ttk.Button(frame, text="登入", command=self.login).pack(pady=10)

    def login(self):
        if self.selected_user.get() == "":
            messagebox.showwarning("警告", "請選擇使用者!")
            return
        
        self.root.destroy()
        
        # 開啟上傳視窗
        from excel_upload import ExcelUploadWindow
        upload_window = ExcelUploadWindow(self.selected_user.get())
        upload_window.run()

    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    app = LoginWindow()
    app.run()