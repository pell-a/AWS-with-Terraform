resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      "Name" = "my_vpc" 
    }
}

resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-2a"

    tags = {
      "Name" = "public_subnet_1" 
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-2b"

    tags = {
      "Name" = "public_subnet_2" 
    }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
      "Name" = "my_igw" 
    }
}

resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "default_route" {
	route_table_id = aws_route_table.my_route_table.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "route_1" {
    subnet_id = aws_subnet.public_subnet_1.id
    route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "route_2" {
    subnet_id = aws_subnet.public_subnet_2.id
    route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "asg_security_group" {
	name = "asg-security-group"
	vpc_id = aws_vpc.my_vpc.id

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		security_groups = [aws_security_group.alb_security_group.id]
	}
	
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		security_groups = [aws_security_group.alb_security_group.id]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		security_groups = [aws_security_group.alb_security_group.id]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "alb_security_group" {
	name = "alb-security-group"
	vpc_id = aws_vpc.my_vpc.id

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks= ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_launch_template" "my_lt" {
	name_prefix = "pella-instance-"
	image_id = "ami-0fc82f4dabc05670b"
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.asg_security_group.id]
	key_name = aws_key_pair.tfstate_ssh_key.key_name

	tag_specifications {
		resource_type = "instance"
		
		tags = {
			"Name" = "pella-lt"
		}
	}
	user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World!" > /var/www/html/index.html
              EOF
  )
}

resource "aws_autoscaling_group" "my_asg" {
	name = "pella-asg"
	vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

	min_size = 1
	max_size = 4
	desired_capacity = 1

	health_check_type = "EC2"
	health_check_grace_period = 300

	target_group_arns = [aws_lb_target_group.server_lb_tg.arn]

	launch_template {
		id = aws_launch_template.my_lt.id
		version = "$Latest"
	}

	tag {
		key = "Name"
		value = "pella-asg"
		propagate_at_launch = true
	}
}

resource "aws_lb" "server_lb" {
	name = "server-lb"
	load_balancer_type = "application"
	subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
	security_groups = [aws_security_group.alb_security_group.id]
}

resource "aws_lb_target_group" "server_lb_tg" {
	name = "server-lb-tg"
	port = 80
	protocol = "HTTP"
	vpc_id = aws_vpc.my_vpc.id
	target_type = "instance"

	health_check {
		path = "/"
		interval = 30
		timeout = 5
		healthy_threshold = 3
		unhealthy_threshold = 3
	}
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.server_lb.arn
	port = "80"
	protocol = "HTTP"

	default_action {
		type = "forward"
		target_group_arn = aws_lb_target_group.server_lb_tg.arn
	}
}

resource "aws_key_pair" "tfstate_ssh_key" {
	key_name = "tfstate-ssh-key"
	public_key = file("${path.module}/tfstate-ssh-key.pub")
}

