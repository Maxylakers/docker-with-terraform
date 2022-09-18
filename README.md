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