import pymysql


class InvalidParameter(Exception):
    def __init__(self, message):
        self.message = message


class Database:
    def __init__(self, host, username, password, port, db_name):
        self.host = host
        self.port = port
        self.db = db_name
        self.user = username
        self.password = password

    def __connect__(self):
        self.connection = pymysql.connect(
            host=self.host,
            user=self.user,
            password=self.password,
            port=self.port,
            db=self.db,
            cursorclass=pymysql.cursors.DictCursor
            )
        self.cursor = self.connection.cursor()

    def __disconnect__(self):
        self.connection.close()

    def get_reading(self, box_id, from_date, to_date):
        self.__connect__()
        # IS this safer?
        # params = {
        #     'box_id': box_id,
        #     'from_date': from_date,
        #     'to_date': to_date
        # }
        # query = '''
        # SELECT box_id, sensor_id, name, unit, reading, reading_ts
        # FROM test_db.readings
        # RIGHT JOIN test_db.readings ON sensors.id = readings.box_id
        # WHERE DATE(reading_ts) BETWEEN (%(from_date)s AND %(to_date)s)
        # AND box_id = %(box_id)s"
        # '''
        # self.cursor.execute(query, params)

        query = """
        SELECT
        box_id,
        sensor_id,
        name,
        unit,
        reading,
        reading_ts
        FROM
        test_db.sensors
        LEFT JOIN test_db.readings ON sensors.id = readings.box_id
        WHERE
        DATE(reading_ts) BETWEEN ({from_date}
        AND {to_date})
        AND box_id = "{box_id}"
        GROUP BY
        box_id,
        sensor_id,
        name,
        unit,
        reading,
        reading_ts;
        """.format(to_date=to_date, from_date=from_date, box_id=box_id)

        self.cursor.execute(query)
        result = self.cursor.fetchall()
        if not result:
            self.__disconnect__()
            raise InvalidParameter("Box ID value not in database.")
            # make this more generic? don't know if invalid datetimes will raise issues
        self.__disconnect__()
        return result
    
    def get_all(self):
        self.__connect__()
        # IS this safer?
        # params = {
        #     'box_id': box_id,
        #     'from_date': from_date,
        #     'to_date': to_date
        # }
        # query = '''
        # SELECT box_id, sensor_id, name, unit, reading, reading_ts
        # FROM test_db.readings
        # RIGHT JOIN test_db.readings ON sensors.id = readings.box_id
        # WHERE DATE(reading_ts) BETWEEN (%(from_date)s AND %(to_date)s)
        # AND box_id = %(box_id)s"
        # '''
        # self.cursor.execute(query, params)

        query = """
        SELECT
        box_id,
        sensor_id,
        name,
        unit,
        reading,
        reading_ts
        FROM
        test_db.sensors
        LEFT JOIN test_db.readings ON sensors.id = readings.box_id
        GROUP BY
        box_id,
        sensor_id,
        name,
        unit,
        reading,
        reading_ts;
        """

        self.cursor.execute(query)
        result = self.cursor.fetchall()
        if not result:
            self.__disconnect__()
            # raise InvalidParameter("NBox ID value not in database.")
            # make this more generic? don't know if invalid datetimes will raise issues
        self.__disconnect__()
        return result

