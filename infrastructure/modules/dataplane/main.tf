

resource "aws_launch_template" "eks_asg_launch_template_ondemand" {
    name = "eks_asg_launch_template_ondemand"
    block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 80
      volume_type           = "gp2"
    }
  }
  instance_type =  var.dataplane.instance_type

  iam_instance_profile {
     name = var.dataplane.iam_instance_profile
  }

  image_id = data.aws_ami.eks_worker_al2023.id
  vpc_security_group_ids = var.dataplane.sg_ids
  user_data = base64encode(templatefile("${path.module}/userdata_al2023.sh", {
    nodeconfig_content = templatefile("${path.module}/nodeconfig.yaml", {
      ClusterName     = var.dataplane.cluster_name
      ClusterEndpoint = var.eks_cluster_endpoint
      ClusterCA       = var.eks_cluster_ca
      AmiId          = data.aws_ami.eks_worker_al2023.id
      cidr            = var.dataplane.vpc_cidr
      GroupName      = "eks_asg_launch_template_ondemand"
    })
  }))

  tags = {
    Environment = var.environment
    "eks:cluster-name" = var.dataplane.cluster_name
  }
}


resource "aws_autoscaling_group" "eks_asg_ondemand_2cpu_4ram" {
    vpc_zone_identifier  = [var.dataplane.private_subnet_ids[0]]
    name = "eks_asg_launch_template_ondemand"
    desired_capacity = 1
    min_size =  1
    max_size = 1
    health_check_grace_period =  15
    health_check_type = "EC2"
    termination_policies = ["OldestLaunchTemplate", "OldestInstance"]
    launch_template {
      id = aws_launch_template.eks_asg_launch_template_ondemand.id
      version = "$Latest"
    }

    lifecycle {
      ignore_changes = [ desired_capacity ]
      create_before_destroy = true
    }


  tag {
    key                 = "eks:cluster-name"
    value               = var.dataplane.cluster_name
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/lifecycle"
    value               = "Ec2Normal"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/intent"
    value               = "apps"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/topology.kubernetes.io/zone"
    value               = var.dataplane.private_subnet_zones[0]
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.dataplane.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.dataplane.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
