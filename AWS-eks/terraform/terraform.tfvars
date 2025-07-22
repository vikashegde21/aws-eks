aws_region = "ap-south-1"
cluster_name = "travel-webapp-cluster"
cluster_version = "1.27"
node_group_desired_size = 2
node_group_max_size = 4
node_group_min_size = 1
instance_types = ["t3.medium"]
ecr_image_uri = "418544663637.dkr.ecr.ap-south-1.amazonaws.com/travel_webpage"