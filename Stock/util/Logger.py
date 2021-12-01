import logging
import os
from datetime import datetime


# dir_path = 'logs/'   # 設定 logs 目錄
# filename = "{:%Y%m%d_%H%M}".format(datetime.now()) + '.log'     
filename = "{:%Y%m%d}".format(datetime.now()) + "_Order.log"     
# 設定檔名

def create_logger(log_folder):
    # config
    logging.captureWarnings(True)   # 捕捉 py waring message
    formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
    my_logger = logging.getLogger('py.warnings')    # 捕捉 py waring message
    my_logger.setLevel(logging.INFO)
 
    # 若不存在目錄則新建
    if not os.path.exists(log_folder):
        os.makedirs(log_folder)
 
    # file handler
    fileHandler = logging.FileHandler(log_folder + '/' + filename, 'w', 'utf-8')
    fileHandler.setFormatter(formatter)
    my_logger.addHandler(fileHandler)
 
    # console handler
    consoleHandler = logging.StreamHandler()
    consoleHandler.setLevel(logging.DEBUG)
    consoleHandler.setFormatter(formatter)
    my_logger.addHandler(consoleHandler)
 
    return my_logger
