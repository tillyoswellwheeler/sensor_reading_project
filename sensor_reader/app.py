import falcon
import json

from .config import DBConfig
from .db import Database


db_config = DBConfig('db_config.yaml')
db = Database(
    host=db_config.host,
    username=db_config.username,
    password=db_config.password,
    port=db_config.port,
    db_name=db_config.db_name
    )

class ReadingsResource(object):
    def on_get(self, req, resp, box_id, from_date, to_date):
        result = db.get_reading(box_id, from_date, to_date)
        resp.text = json.dumps(result, indent=4, sort_keys=True, default=str)
        resp.status = falcon.HTTP_200


app = application = falcon.App()

readings = ReadingsResource()
app.add_route('/readings/{box_id}/{from_date}/{to_date}', readings)
