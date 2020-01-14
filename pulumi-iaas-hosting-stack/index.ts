import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new pulumi.Config();
const vpc_base = config.get("vpc_base") || "192.168.200";
const cost_center = config.get("cost_center") || "tinn";
const region = config.get("region") || "us-east-1";
const db_user = config.get("db_user") || "meetupdbuser";
const db_password = config.get("db_password") || "awsmeetupdbPwd!0";
const ssh_location = config.get("ssh_location") || "0.0.0.0/0";
const instance_type = (config.get("instance_type") || "t2.small") as aws.ec2.InstanceType;
const ec2_key_name = config.get("ec2_key_name") || "aws-meetup-group-key";

const main = new aws.ec2.Vpc("main", {
    cidrBlock: `${vpc_base}.0/24`,
    enableDnsHostnames: true,
    enableDnsSupport: true,
    tags: {
        CostCenter: cost_center,
    },
});
const publicSubnet = new aws.ec2.Subnet("public", {
    availabilityZone: `${region}a`,
    cidrBlock: `${vpc_base}.0/25`,
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const db_subnet_main = new aws.ec2.Subnet("db-subnet-main", {
    availabilityZone: `${region}a`,
    cidrBlock: `${vpc_base}.128/26`,
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const db_subnet_failover = new aws.ec2.Subnet("db-subnet-failover", {
    availabilityZone: `${region}b`,
    cidrBlock: `${vpc_base}.192/26`,
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const vpc_internet_gwInternetGateway = new aws.ec2.InternetGateway("vpc-internet-gw", {
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const vpc_route_table = new aws.ec2.RouteTable("vpc-route-table", {
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const public_subnet_route_association = new aws.ec2.RouteTableAssociation("public-subnet-route-association", {
    routeTableId: vpc_route_table.id,
    subnetId: publicSubnet.id,
});
const vpc_internet_gwDefaultRouteTable = new aws.ec2.DefaultRouteTable("vpc-internet-gw", {
    defaultRouteTableId: vpc_route_table.id,
    routes: [{
        cidrBlock: "0.0.0.0/0",
        gatewayId: vpc_internet_gwInternetGateway.id,
    }],
    tags: {
        CostCenter: cost_center,
    },
});
const amzn = aws.getAmi({
    filters: [
        {
            name: "name",
            values: ["amzn-ami-hvm-*"],
        },
        {
            name: "virtualization-type",
            values: ["hvm"],
        },
    ],
    mostRecent: true,
    owners: [
        "amazon",
        "self",
    ],
});
const ec2_sg = new aws.ec2.SecurityGroup("ec2-sg", {
    egress: [{
        cidrBlocks: ["0.0.0.0/0"],
        fromPort: 0,
        protocol: "-1",
        toPort: 0,
    }],
    ingress: [
        {
            cidrBlocks: [ssh_location],
            fromPort: 22,
            protocol: "tcp",
            toPort: 22,
        },
        {
            cidrBlocks: ["0.0.0.0/0"],
            fromPort: 8080,
            protocol: "tcp",
            toPort: 8080,
        },
    ],
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const web = new aws.ec2.Instance("web", {
    ami: amzn.id,
    associatePublicIpAddress: true,
    instanceType: instance_type,
    keyName: ec2_key_name,
    securityGroups: [ec2_sg.id],
    subnetId: publicSubnet.id,
    tags: {
        CostCenter: cost_center,
    },
});
const db_subnet_group = new aws.rds.SubnetGroup("db-subnet-group", {
    subnetIds: [
        db_subnet_main.id,
        db_subnet_failover.id,
    ],
    tags: {
        CostCenter: cost_center,
    },
});
const db_sg = new aws.ec2.SecurityGroup("db-sg", {
    ingress: [{
        fromPort: 3306,
        protocol: "tcp",
        securityGroups: [ec2_sg.id],
        toPort: 3306,
    }],
    tags: {
        CostCenter: cost_center,
    },
    vpcId: main.id,
});
const defaultInstance = new aws.rds.Instance("default", {
    allocatedStorage: 5,
    dbSubnetGroupName: db_subnet_group.id,
    engine: "mysql",
    engineVersion: "5.7",
    instanceClass: "db.t2.micro",
    name: "defaultdb",
    parameterGroupName: "default.mysql5.7",
    password: db_password,
    skipFinalSnapshot: true,
    storageType: "gp2",
    // multi_az = true
    tags: {
        CostCenter: cost_center,
    },
    username: db_user,
    vpcSecurityGroupIds: [db_sg.id],
});
