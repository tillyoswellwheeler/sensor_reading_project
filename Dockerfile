FROM python:3.8-rc-slim-stretch

# Set the working directory to /app
WORKDIR /sensor_reader

# Copy the current directory contents into the container at /app
ADD . /sensor_reader

# RUN pip install -r ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose 500 for the api
EXPOSE 5000

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:5000", "-w"]