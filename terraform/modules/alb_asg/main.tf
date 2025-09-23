  # ==============================
  # Application Load Balancer
  # ==============================
  resource "aws_lb" "this" {
    name               = var.alb_name
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.lb_security_group]
    subnets            = var.public_subnets
  }

  resource "aws_lb_target_group" "this" {
    name        = "${var.alb_name}-tg"
    port        = 8000
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = var.vpc_id

    health_check {
      path                = "/"
      matcher             = "200"
      interval            = 30
      timeout             = 5
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }

  resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.this.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  # ==============================
  # Auto Scaling Group / Launch Template
  # ==============================
  resource "aws_launch_template" "this" {
    name_prefix   = "${var.alb_name}-lt"
    image_id      = var.ami_id
    instance_type = var.instance_type
    key_name      = var.key_name

    user_data = base64encode(var.user_data)
    update_default_version = true
    vpc_security_group_ids = [var.ec2_security_group_id]

    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "${var.alb_name}-instance"
      }
    }
  }

  resource "aws_autoscaling_group" "this" {
    desired_capacity    = var.desired_capacity
    max_size            = var.max_size
    min_size            = var.min_size
    vpc_zone_identifier = var.private_subnets

    launch_template {
      id = aws_launch_template.this.id
    }

    target_group_arns = [aws_lb_target_group.this.arn]
  }

  # ==============================
  # Scaling Policies & Alarms
  # ==============================
  resource "aws_autoscaling_policy" "scale_out" {
    name                   = "${var.alb_name}-scale-out"
    autoscaling_group_name = aws_autoscaling_group.this.name
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = 1
    cooldown               = 300
  }

  resource "aws_autoscaling_policy" "scale_in" {
    name                   = "${var.alb_name}-scale-in"
    autoscaling_group_name = aws_autoscaling_group.this.name
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = -1
    cooldown               = 300
  }

  resource "aws_cloudwatch_metric_alarm" "cpu_high" {
    alarm_name          = "${var.alb_name}-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 85

    alarm_actions = [aws_autoscaling_policy.scale_out.arn]
    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.this.name
    }
  }

  resource "aws_cloudwatch_metric_alarm" "cpu_low" {
    alarm_name          = "${var.alb_name}-cpu-low"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 30

    alarm_actions = [aws_autoscaling_policy.scale_in.arn]
    dimensions = {
      AutoScalingGroupName = aws_autoscaling_group.this.name
    }
  }
