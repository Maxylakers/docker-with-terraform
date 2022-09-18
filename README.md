* Create the credentials needed to access the Linux VM once created.

- Generate SSH Key:
ssh-keygen -t rsa
- Check for created key in path:
ls -l ~/.ssh


- Check to get the VM IP address using:
terrform state list (gram the vm state name and replace accordingly)
terraform state show azurerm_linux_virtual_machine.VM

- ssh into the Linux VM by replacing the IP accordingly using:
ssh -i ~/.ssh/terraformkey adminuser@40.68.162.244

- While logged into the Linux VM, check system info:
lsb_release -a


-- Aim
- Using the Custom Data argument, we have bootstrapped our Linux instance and install the Docker engine. Which then allows us to have a linux instance deployed with Docker ready for development.

-- Using a Provisioner (unlike other resources, a provisioner's success or failure is not recorded or managed by state) to configure the VS code on our local terminal to be able to ssh into our remote VM directly at deployment.


-- Next we use a Data Source to get the IP address of the server. This is best in areas where we do not have access to the state files of the deployments.