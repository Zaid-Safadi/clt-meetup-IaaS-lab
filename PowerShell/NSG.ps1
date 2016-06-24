#Create Netowrk Security Group and apply it to VNet with two subnets to model a DMZ/Backend network environment 

Login-AzureRmAccount
$ResourceGroupName = "clt-meetup-resg"
$VNetName = "clt-meetup-vnet"
$NSGName = "clt-meetup-nsg"
$DeploymentLocation = "eastus2"
$FrontendAddress = "192.168.1.0/24"
$BackendAddress = "192.168.2.0/24"


#Allow RDP to VMs on the entire VNet
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name "Allow-RDP" -Direction Inbound -Priority 110 -Access Allow -SourceAddressPrefix INTERNET -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange '3389' -Protocol Tcp -Description "Enable RDP to $VNetName VNet"

#Allow incoming http internet traffic on port 80 to the forntend subnet
$httpRule = New-AzureRmNetworkSecurityRuleConfig -Name "Allow-HTTP" -Direction Inbound -Priority 120 -Access Allow -SourceAddressPrefix INTERNET -SourcePortRange * -DestinationAddressPrefix $FrontendAddress -DestinationPortRange '80' -Protocol Tcp -Description "Enable HTTP to $VNetName VNet"

#Allow secure https incoming internet traffic on port 443 to the forntend subnet
$httpsRule = New-AzureRmNetworkSecurityRuleConfig -Name "Allow-HTTPs" -Direction Inbound -Priority 130 -Access Allow -SourceAddressPrefix INTERNET -SourcePortRange * -DestinationAddressPrefix $FrontendAddress -DestinationPortRange '443' -Protocol Tcp -Description "Enable HTTPs to $VNetName VNet"

#Allow traffic from the Frontend subnet to the backend subnet on port 3306 only (database)
$allowFrontToBackRule = New-AzureRmNetworkSecurityRuleConfig -Name "Allow-Database-backend " -Direction Inbound -Priority 140 -Access Allow -SourceAddressPrefix $FrontendAddress -SourcePortRange * -DestinationAddressPrefix $BackendAddress -DestinationPortRange '3306' -Protocol Tcp -Description "Enable MySQL DB to backend subnet from dmz"

#Deny all other incoming traffic from the internet on the entire VNet
$denyInternetRule = New-AzureRmNetworkSecurityRuleConfig -Name "Deny-Internet-External" -Direction Inbound -Priority 210 -Access Deny -SourceAddressPrefix INTERNET -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange * -Protocol * -Description "Isolate the $VNetName VNet from the Internet"

#Deny all other incoming traffic from the frontend to the backend subnet
$denyFrontToBackRule = New-AzureRmNetworkSecurityRuleConfig -Name "Deny-Frontend-Backend" -Direction Outbound -Priority 220 -Access Deny -SourceAddressPrefix $FrontendAddress -SourcePortRange * -DestinationAddressPrefix $BackendAddress -DestinationPortRange * -Protocol * -Description "Deny Frontend clssubnet access to Backend subnet"

#Dent internet on the backend subnet (prevent internet browsing and downloading)    
$denyInternetFromBackend = New-AzureRmNetworkSecurityRuleConfig -Name "Deny-Backend-Internet" -Direction Outbound -Priority 200 -Access Deny -SourceAddressPrefix $BackendAddress -SourcePortRange * -DestinationAddressPrefix Internet -DestinationPortRange * -Protocol * -Description "Block Internet"

#Create new NSG
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName -Location $DeploymentLocation -SecurityRules $rdpRule,$httpRule,$httpsRule,$denyInternetRule,$denyFrontToBackRule,$denyInternetFromBackend

#Get exsiting VNet
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName 

#Apply NSG on the frontend subnet
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name Frontend -NetworkSecurityGroup $nsg -AddressPrefix $FrontendAddress

#Apply NSG on the backend subnet
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name Backend -NetworkSecurityGroup $nsg -AddressPrefix $BackendAddress

#Apply changes to the VNet
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet