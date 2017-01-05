# SIOS DataKeeper CLOUD template deployment demo.

# AWS TEMPLATES
# Create 2 Node SIOS DataKeeper Clustered SQL Server with Domain Controller
<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ESIOS%7Cturl%7Ehttps://s3.amazonaws.com/sios-datakeeper/CloudFormation/sios-master.template" target="_blank">
    <img src="DeployToAWS.png"/>
</a>
This template creates 3 virtual machines: a primary AD domain controller, and 2 Sios DataKeeper nodes. All VMs are running Windows Server 2012 R2.


# AZURE TEMPLATES
# Create 2+ Node SQL Server 2014 Cluster with SIOS DataKeeper Replication on Windows Server (2008R2, 2012R2, or 2016) 
[WIP: Only works for Server 2012R2 currently. Close for 2016, but something in the DSC engine breaks while installing sql last check. Server 2008R2 comes online with local execution policy disabled for scripts, so DSC config doesn't start.]
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster-Win20XX%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 3+ virtual machines: an AD domain controller, and 2+ Sios DataKeeper nodes. All VMs run the same version of Windows Server chosen at time of deployment.

# Create SIOS DataKeeper Replication
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-standalone%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines: both a primary and backup AD domain controller, and 2 Sios DataKeeper nodes. All VMs are running Windows Server 2012 R2.

# Create SIOS DataKeeper Clustered File Server 
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines in total: a primary AD domain controller, 2 Sios DataKeeper nodes, and a client vm; all running Windows Server 2012 R2 DataCenter.

# Create 2 Node SIOS DataKeeper Clustered SQL Server with Client VM
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines in total: a primary AD domain controller, 2 Sios DataKeeper nodes with SQL 2014 installed, and a client vm; all running Windows Server 2012 R2 DataCenter.

# Create 3 Node SIOS DataKeeper Clustered SQL Server
[NON-FUNCTIONAL as the third node fails to join the cluster. This is an issue with clusters created using the Azure_FailoverClusters DSC module.]
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-3node-sql-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines in total: a primary AD domain controller and 3 Sios DataKeeper nodes with SQL 2014 installed; all running Windows Server 2012 R2 DataCenter.

# Create SIOS DataKeeper Clustered SQL Server in an Existing Domain 
(IN THE SAME RESOURCE GROUP IN AZURE)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 2 Sios DataKeeper nodes with SQL 2014 installed, all running Windows Server 2012 R2 DataCenter. It provisions them in the same resource group and availability set as an existing domain controller in Azure.
Creating more than a 2 node cluster in the same region is not advised due to Fault Domain considerations. Adding a 3rd node in a different region would be possible, but would require another internal load balancer, vnet, and subnet.

# Create SIOS DataKeeper Clustered SQL Server in an Existing Domain 
(IN A NEW RESOURCE GROUP) [NON-FUNCTIONAL]
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster-external-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 2 Sios DataKeeper nodes with SQL 2014 installed, all running Windows Server 2012 R2 DataCenter. It provisions them in their own resource group and joins them to a publically accessible domain. 

# Add SIOS DataKeeper Node to Clustered SQL Resource
(Does not work if the cluster has been created using an ARM template. The cluster must have been created by hand for this template to work.)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates a single virtual machine running Windows Server 2012 R2, SQL 2014 SP1 Evaluation, and SIOS DataKeeper Cluster Edition 8.3.0. The VM is joined to an exisitng domain and cluster.


# TEST
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Ftest%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
Deployment testing template.


# TEST - Simple Domain Join a New Server 20XX Node to Existing Domain in Azure 
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Ftest-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This creates a new Server 20XX node and adds it to an existing domain, in an exisitng resource group. 
