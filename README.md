# SIOS DataKeeper Azure template deployment demo.

# Create SIOS DataKeeper Standalone
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-standalone%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines: both a primary and backup AD domain controller, and 2 Sios DataKeeper nodes. All VMs are running Windows Server 2012 R2.

# Create SIOS DataKeeper Clustered File Server 
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines in total: a primary AD domain controller, 2 Sios DataKeeper nodes, and a client vm; all running Windows Server 2012 R2 DataCenter.

# Create SIOS DataKeeper Clustered SQL Server
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 4 virtual machines in total: a primary AD domain controller, 2 Sios DataKeeper nodes with SQL 2014 installed, and a client vm; all running Windows Server 2012 R2 DataCenter.

# Create SIOS DataKeeper Clustered SQL Server in an Existing Domain
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-sql-cluster-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates 2 Sios DataKeeper nodes with SQL 2014 installed, and a client vm; all running Windows Server 2012 R2 DataCenter.

# Add SIOS DataKeeper Node to Clustered SQL Resource
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Fdatakeeper-domainjoin%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
This template creates a single virtual machine running Windows Server 2012 R2, SQL 2014 SP1 Evaluation, and SIOS DataKeeper Cluster Edition 8.3.0. The VM is joined to an exisitng domain and cluster.


# TEST
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcarrollh%2FsiosDataKeeper-demo%2Fmaster%2Ftest%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
Deployment testing template.
