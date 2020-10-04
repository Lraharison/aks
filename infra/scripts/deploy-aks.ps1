
$SubscriptionName = "Pay-As-You-Go"
$Location = "Canada East"
$Date = Get-Date -Format "ddMMyyyyHHmm"
$ResourceGroupName = "RG-AKS-" + $Date
$VirtualNetworkName = "VN-AKS-" + $Date
$SubnetName = "Subnet-AKS-" + $Date
$ClusterName = "aks" + $Date
$OutputFileName = "output_" + $Date + ".json"
$OutputFilePath = ".\" + $OutputFileName

New-Item -Path . -Name $OutputFileName -ItemType "file"

$Subscription = Get-AzSubscription -SubscriptionName $SubscriptionName

Write-Host "Creating resource group $ResourceGroupName"
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

Write-Host "Creating virtual network and subnet"

$VirtualNetwork = New-AzVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name $VirtualNetworkName `
    -AddressPrefix 10.201.0.0/16

$SubnetConfig = Add-AzVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -AddressPrefix 10.201.0.0/22 `
    -VirtualNetwork $VirtualNetwork    

$VirtualNetwork | Set-AzVirtualNetwork

Write-Host "Create SP for AKS"
$Sp = New-AzADServicePrincipal 
$Secret = [System.Net.NetworkCredential]::new("", $Sp.Secret).Password

Write-Host "Assign role to SP"
$Scope = "/subscriptions/" + $Subscription.Id + "/resourceGroups/" + $ResourceGroupName
New-AzRoleAssignment -RoleDefinitionName Contributor -Scope $Scope -ObjectId $Sp.Id

$Output = '{"resourceGroupName":"' + $ResourceGroupName + '","spId":"' + $Sp.Id + '"}'
Add-Content -Path $OutputFilePath -Value $Output

Write-Host "Deploy AKS"
$SecureId = ConvertTo-SecureString $Sp.ApplicationId -AsPlainText -Force
$SecureSecret = ConvertTo-SecureString $Secret -AsPlainText -Force
$VnetSubnetID = "/subscriptions/" + $Subscription.Id + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Network/virtualNetworks/" + $VirtualNetworkName + "/subnets/" + $SubnetName
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile ../templates/aks.json `
    -TemplateParameterFile ../templates/aks-parameters.json `
    -clusterName $ClusterName `
    -dnsPrefix $ClusterName `
    -agentVMSize Standard_DS2_v2 `
    -vnetSubnetID $VnetSubnetID `
    -servicePrincipalClientId $SecureId `
    -servicePrincipalClientSecret $SecureSecret

Write-Host "Deployment is done"    