import requests
import pandas as pd
import json
# import pyodbc
from datetime import datetime
import sys
import logging
import os

# 設置日誌
log_directory = "logs"
if not os.path.exists(log_directory):
    os.makedirs(log_directory)

log_file = os.path.join(log_directory, f"revenue_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# API URLs
api_urls = {
    'twse_p': 'https://openapi.twse.com.tw/v1/opendata/t187ap05_P',
    'twse_l': 'https://openapi.twse.com.tw/v1/opendata/t187ap05_L',
    'tpex_r': 'https://www.tpex.org.tw/openapi/v1/t187ap05_R',
    'tpex_o': 'https://www.tpex.org.tw/openapi/v1/mopsfin_t187ap05_O'
}

# 數據庫連接配置
SERVER = 'your_server_name'
DATABASE = 'your_database_name'
USERNAME = 'your_username'
PASSWORD = 'your_password'

# 統一的表格名稱
TABLE_NAME = 'company_monthly_revenue'

# 創建資料庫連接字符串
conn_str = f'DRIVER={{SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'

def fetch_data_from_api(url, source_name):
    """從指定的 API URL 獲取數據"""
    try:
        response = requests.get(url)
        response.raise_for_status()  # 如果請求返回錯誤狀態碼，拋出異常
        data = response.json()
        logging.info(f"成功從 {source_name} 獲取數據: {len(data)} 條記錄")
        return data
    except requests.exceptions.RequestException as e:
        logging.error(f"從 {source_name} 獲取數據時出錯: {e}")
        return []

def create_table_if_not_exists(cursor):
    """如果表不存在，則創建統一的表"""
    try:
        # 檢查表是否存在
        create_table_sql = f"""
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '{TABLE_NAME}')
        BEGIN
            CREATE TABLE {TABLE_NAME} (
                id INT IDENTITY(1,1) PRIMARY KEY,
                api_source NVARCHAR(20),
                出表日期 NVARCHAR(20),
                資料年月 NVARCHAR(10),
                公司代號 NVARCHAR(10),
                公司名稱 NVARCHAR(100),
                產業別 NVARCHAR(50),
                營業收入_當月營收 NVARCHAR(50),
                營業收入_上月營收 NVARCHAR(50),
                營業收入_去年當月營收 NVARCHAR(50),
                營業收入_上月比較增減 NVARCHAR(20),
                營業收入_去年同月增減 NVARCHAR(20),
                累計營業收入_當月累計營收 NVARCHAR(50),
                累計營業收入_去年累計營收 NVARCHAR(50),
                累計營業收入_前期比較增減 NVARCHAR(20),
                備註 NVARCHAR(500),
                fetch_time DATETIME
            )
        END
        """
        cursor.execute(create_table_sql)
        logging.info(f"確保表 {TABLE_NAME} 存在")
    except pyodbc.Error as e:
        logging.error(f"創建表 {TABLE_NAME} 時出錯: {e}")

def check_data_exists(cursor, source_name, year_month):
    """檢查指定來源和年月的數據是否已存在"""
    try:
        query = f"SELECT COUNT(*) FROM {TABLE_NAME} WHERE api_source = ? AND 資料年月 = ?"
        cursor.execute(query, (source_name, year_month))
        count = cursor.fetchone()[0]
        return count > 0
    except pyodbc.Error as e:
        logging.error(f"檢查 {TABLE_NAME} 中的數據時出錯: {e}")
        return False

def process_and_insert_data(data, source_name, conn):
    """處理並插入數據到統一的SQL表中"""
    if not data:
        logging.warning(f"沒有數據要從 {source_name} 插入")
        return False
    
    try:
        # 將數據轉換為 DataFrame
        df = pd.DataFrame(data)
        
        # 添加 API 來源標識和時間戳
        df['api_source'] = source_name
        df['fetch_time'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # 列名清理 - 將連字符替換為下劃線
        df.columns = [col.replace('-', '_') for col in df.columns]
        
        # 創建游標
        cursor = conn.cursor()
        
        # 確保表格存在
        create_table_if_not_exists(cursor)
        
        # 檢查第一條記錄是否已存在
        if len(df) > 0:
            first_record = df.iloc[0]
            if '資料年月' in first_record and first_record['資料年月']:
                if check_data_exists(cursor, source_name, first_record['資料年月']):
                    logging.info(f"數據已存在於 {TABLE_NAME}，來源：{source_name}，年月：{first_record['資料年月']}，停止程式")
                    return True
        
        # 確保所有必要列都存在
        required_columns = [
            'api_source', '出表日期', '資料年月', '公司代號', '公司名稱', '產業別',
            '營業收入_當月營收', '營業收入_上月營收', '營業收入_去年當月營收',
            '營業收入_上月比較增減(%)', '營業收入_去年同月增減(%)',
            '累計營業收入_當月累計營收', '累計營業收入_去年累計營收',
            '累計營業收入_前期比較增減(%)', '備註', 'fetch_time'
        ]
        
        # 標準化列名
        rename_map = {
            '營業收入_上月比較增減(%)': '營業收入_上月比較增減',
            '營業收入_去年同月增減(%)': '營業收入_去年同月增減',
            '累計營業收入_前期比較增減(%)': '累計營業收入_前期比較增減'
        }
        
        df = df.rename(columns=rename_map)
        
        # 添加缺失的列
        for col in required_columns:
            normalized_col = col
            if col in rename_map.keys():
                normalized_col = rename_map[col]
            
            if normalized_col not in df.columns:
                df[normalized_col] = None
        
        # 選擇表中存在的列
        table_columns = [
            'api_source', '出表日期', '資料年月', '公司代號', '公司名稱', '產業別',
            '營業收入_當月營收', '營業收入_上月營收', '營業收入_去年當月營收',
            '營業收入_上月比較增減', '營業收入_去年同月增減',
            '累計營業收入_當月累計營收', '累計營業收入_去年累計營收',
            '累計營業收入_前期比較增減', '備註', 'fetch_time'
        ]
        
        # 確保所有必要列都在DataFrame中
        existing_columns = [col for col in table_columns if col in df.columns]
        df_to_insert = df[existing_columns]
        
        # 構建SQL插入語句
        columns_str = ', '.join(existing_columns)
        placeholders = ', '.join(['?' for _ in existing_columns])
        insert_query = f"INSERT INTO {TABLE_NAME} ({columns_str}) VALUES ({placeholders})"
        
        # 插入每一行數據
        records_inserted = 0
        for _, row in df_to_insert.iterrows():
            values = tuple(row[col] for col in existing_columns)
            cursor.execute(insert_query, values)
            records_inserted += 1
        
        # 提交事務
        conn.commit()
        logging.info(f"成功將 {records_inserted} 條來自 {source_name} 的記錄插入到 {TABLE_NAME}")
        return False
        
    except (pyodbc.Error, KeyError, ValueError) as e:
        logging.error(f"處理並插入來自 {source_name} 的數據時出錯: {e}")
        logging.error(f"錯誤詳情: {str(e)}")
        return False

def main():
    try:
        logging.info("===== 程式開始執行 =====")
        
        # 連接到 SQL Server
        # conn = pyodbc.connect(conn_str)
        # logging.info("成功連接到 SQL Server 數據庫")
        
        # 處理每個 API
        for source_name, url in api_urls.items():
            logging.info(f"正在處理 {source_name} 數據...")
            # 獲取數據
            data = fetch_data_from_api(url, source_name)
            
            # 處理並插入數據，如果數據已存在則停止程式
            # if process_and_insert_data(data, source_name, conn):
            #     conn.close()
            #     logging.info("找到已存在的數據，程式已停止")
            #     sys.exit(0)
        
        # 關閉連接
        # conn.close()
        logging.info("所有數據處理完成，數據庫連接已關閉")
        logging.info("===== 程式執行完畢 =====")
        
    # except pyodbc.Error as e:
        # logging.error(f"數據庫連接或操作失敗: {e}")
    except Exception as e:
        logging.error(f"程式執行時發生未預期錯誤: {e}")
        logging.exception("異常詳細資訊:")

if __name__ == "__main__":
    main()
