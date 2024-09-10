**AWS VPC Creation**

**What we'll do:**
1) Create a VPC with CIDR: 10.0.0.0/16
2) Create a public subnet with CIDR: 10.0.1.0/24
3) Create a private subnet with CIDR: 10.0.2.0/24
4) Associate Internet Gateway(IGW) with the VPC
5) Set up a NAT Gateway in the public subnet
6) Create an instance in each subnet
7) Ensuring the public instance can be accessed from the internet
8) Ensuring the private instance can access the internet but cannot be accessed directly from the internet.

**Run the following Commands in CloudShell**

```bash
curl -lo https://raw.githubusercontent.com/Prachand07/AWS_VPC_Assignent/2744fa3f967ff70b81ed58b5e1c00958fe6d64f4/deploy.sh
sudo chmod +x deploy.sh
./deploy.sh
```
**Congratulations 🎉 for completing the Lab !**
