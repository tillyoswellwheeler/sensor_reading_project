import os
import sensor_reader_project

# Replace with your app's method of configuration
config = sensor_reader_project.get_config(os.environ['sensor_reader_project_CONFIG'])

# uWSGI will look for this variable
application = sensor_reader_project.create_app(config)