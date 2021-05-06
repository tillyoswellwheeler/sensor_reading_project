NOTES for run:
Terraform
----
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
terraform plan 
terraform apply --auto-aprove

EC2 key-pair required
Public IP = http://<ec2-instance-public-ip>

App Run
----
Connect to ec2
docker build #these two steps keep being denied by the ec2 instance on my aws account 
docker run #these two steps keep being denied by the ec2 instance on my aws account

IF not working then
python3 -m venv .venv
pip3 install -r requirements.txt
gunicorn --reload -b 0.0.0.0:8000 sensor_reader.app