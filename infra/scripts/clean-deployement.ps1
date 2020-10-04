
$OutputFile = $args[0]
$Object = Get-Content -Raw -Path $OutputFile | ConvertFrom-Json
Remove-AzResourceGroup -Name $Object.resourceGroupName -Force
Remove-AzRoleAssignment -ObjectId $Object.spId -RoleDefinitionName Contributor
Remove-AzADServicePrincipal -ObjectId $Object.spId -Force