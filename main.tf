provider "aws" {
    region = "us-east-1"
# use environment variables in terminal before terraform plan
}

# 1. Create vpc
resource "aws_vpc" "dev-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "dev"
    }
}
# 2. Create Internet Gateway
    # > to send traffic out to the internet for the web server
resource "aws_internet_gateway" "falcon-app" {
    vpc_id = aws_vpc.dev-vpc.id
    tags = {
        Name = "dev"
    }
}

# 3. Create Custom Route Table
resource "aws_route_table" "dev-route-table" {
    vpc_id = aws_vpc.dev-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.falcon-app.id #means the traffic flow from the private subnet can go to the public internet
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.falcon-app.id #means the traffic flow from the private subnet can go to the public internet
    }  

    tags = {
        Name = "dev"
    }
}
# 4. Create a Subnet
    # > must be associated to a route table
    # > Subnet where our web server will live within

resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "dev-subnet"
    }
}

# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.dev-route-table.id
}

# 6. Create a Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
    name        = "allow_web_traffic"
    description = "Allow web traffic - ports 22,80,443"
    vpc_id      = aws_vpc.dev-vpc.id

    ingress {
        description      = "HTTPS"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
  }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow_web"
    }
}

# 7. Create a network interface with an ip in the subnet taht was created in step 4

resource "aws_network_interface" "web-server-falcon-app" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}
# 8. Assign an elastic IP to the network interface created in step 7
    # >Must be declared after the internet gateway has been deployed 
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-falcon-app.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.falcon-app]
}

# 9. Create IAM permission for ec2 to access s3 bucket

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2-policy"
  role = aws_iam_role.ec2-role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
})
}



resource "aws_iam_role" "ec2-role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
})
}


# # Create EC2 Instance Profile
# resource "aws_iam_instance_profile" "ec2-profile" {
#     name = "ec2-profile"
#     role = aws_iam_role.ec2-role.name
# }

# # Adding IAM Policies to give full access to S3 bucket

# 11. Create Ubuntu server and install/enable apache2 and docker

resource "aws_instance" "falcon-web-server" {
    ami = "ami-0d5eff06f840b45e9"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a" #need to hard code availibity zone so that your ec2 instance is created in the same availability zone as the subnet you create
    # iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
    key_name = "dev-key-east"
    
    network_interface {
        device_index = 0 #first netwrok interface of the device
        network_interface_id = aws_network_interface.web-server-falcon-app.id
    }

    user_data = <<-EOF
                #! /bin/bash
                sudo apt update -y
                sudo amazon-linux-extras install docker
                sudo service docker start
                sudo usermod -a -G docker ec2-user
                sudo yum install git -y
                cd /home
                sudo git clone https://github.com/tillyoswellwheeler/sensor_reading_project.git
                
                EOF

    tags = {
        Name = "falcon_app"
    }
}