import os

import yaml


class DBConfig:

    def __init__(self, file):

        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), file)

        with open(path, 'r') as f:
            params = yaml.safe_load(f)

        self.username = params['username']
        self.password = params['password']
        self.host = params['host']
        self.port = params['port']
        self.db_name = params['db_name']