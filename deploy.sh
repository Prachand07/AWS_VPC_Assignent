
#!/bin/bash

# Variables
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_A_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_C_CIDR="10.0.2.0/24"
REGION="us-east-1"  # Change to your desired region

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
echo "Created VPC with ID: $VPC_ID"

# Create Public Subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_A_CIDR --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
echo "Created Public Subnet: $PUBLIC_SUBNET_ID"

# Create Private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_C_CIDR --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
echo "Created Private Subnet: $PRIVATE_SUBNET_ID"

# Create and Attach Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION
echo "Created and attached Internet Gateway: $IGW_ID"

# Create NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --region $REGION --query 'AllocationId' --output text)
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_ID --allocation-id $EIP_ALLOC_ID --region $REGION --query 'NatGateway.NatGatewayId' --output text)
echo "Created NAT Gateway: $NAT_GW_ID"

# Create Route Tables
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_ROUTE_TABLE_ID --region $REGION

PRIVATE_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_ID --route-table-id $PRIVATE_ROUTE_TABLE_ID --region $REGION

# Create Security Groups
PUBLIC_SG_ID=$(aws ec2 create-security-group --group-name PublicSG --description "Public Security Group" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
PRIVATE_SG_ID=$(aws ec2 create-security-group --group-name PrivateSG --description "Private Security Group" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)

# Allow inbound SSH and HTTP from anywhere to Public SG
aws ec2 authorize-security-group-ingress --group-id $PUBLIC_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $PUBLIC_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION

# Allow inbound SSH from Public SG to Private SG
aws ec2 authorize-security-group-ingress --group-id $PRIVATE_SG_ID --protocol tcp --port 22 --source-group $PUBLIC_SG_ID --region $REGION

# Launch EC2 Instances
PUBLIC_INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 --count 1 --instance-type t2.micro --key-name YourKeyPair --security-group-ids $PUBLIC_SG_ID --subnet-id $PUBLIC_SUBNET_ID --region $REGION --query 'Instances[0].InstanceId' --output text)
PRIVATE_INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 --count 1 --instance-type t2.micro --key-name YourKeyPair --security-group-ids $PRIVATE_SG_ID --subnet-id $PRIVATE_SUBNET_ID --region $REGION --query 'Instances[0].InstanceId' --output text)

echo "Launched Public Instance: $PUBLIC_INSTANCE_ID"
echo "Launched Private Instance: $PRIVATE_INSTANCE_ID"
