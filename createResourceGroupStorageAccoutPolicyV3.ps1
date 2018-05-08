# Connect to Azure
#Login-AzureRmAccount

# Check if resource group is required
$rg_required = Read-Host "Is a new resource group required?(y/n)"
if ($rg_required -eq "y") {
    # Ask for path to resource group .csv and check it exists
    $rg_CSV_Path = Read-Host "Enter the full path to the Resource Group file"
    $path = Test-Path $rg_CSV_Path
    if ($path -eq $true){
        Write-Host "The file is there"
    } else {
        Write-Host "Cannot find the file, double check it exists and try again"
        exit 1
    }
    $path = $null

    # Ask for path to tags CSV and check it exists
    $tagCSV_Path = Read-Host "Enter the full path to the tags CSV"
    $path = Test-Path $tagCSV_Path
    if ($path -eq $true){
        Write-Host "The file is there"
    } else {
        Write-Host "Cannot find the file, double check it exists and try again"
        exit 1
    }
    $path = $null


    # Set variables for creating new Resource Group
    $csv = Import-Csv $rg_CSV_Path

    Write-Host "Getting details from '$rg_CSV_Path' for new Resource Group"

    $nameRG = $csv.name
    $locationRG = $csv.location

    # Create Resource Group
    Write-Host "The resource name will be '$nameRG' and the location will be '$locationRG'"

    New-AzureRmResourceGroup -Name $nameRG -Location $locationRG
    
    # Create hashtable from tagCSV
    $tagCSV = Import-Csv $tagCSV_Path

    $tags=@{}
    foreach($r in $tagCSV)
    {
        $tags[$r.Name]=$r.Value
    }

    # Set Resouce Group Tags
    Set-AzureRmResourceGroup -Name $nameRG -Tag $tags

} elseif($rg_required -eq "n") {
    Write-Host "Moving on"
} else {
    Write-Host "Invalid entry, exiting"
    sleep -seconds 5
    exit 1
}

# Check if storage account is required
$sa_required = Read-Host "Is a new storage account required?(y/n)"
if ($sa_required -eq "y") {
    # Ask for path to storage account .csv and check it exists
    $sa_CSV_Path = Read-Host "Enter the full path to the Storage Account file"
    $path = Test-Path $sa_CSV_Path
    if ($path -eq $true){
        Write-Host "The file is there"
    } else {
        Write-Host "Cannot find the file, double check it exists and try again"
        exit 1
    }
    $path = $null

    # Get variables for Storage Account
    $csv = Import-Csv $sa_CSV_Path

    Write-Host "Getting details from '$sa_CSV_Path' for new Storage Account"

    $nameSA = $csv.name
    $skuSA = $csv.sku


    #### Create Storage Account
    Write-Host "The Storage account with name '$nameSA' and SKU '$skuSA' will be created in the '$nameRG' recource group and located in '$locationRG'"
    $storageAccount = New-AzureRmStorageAccount -ResourceGroupName $nameRG `    -Name $nameSA `    -Location $locationRG `    -SkuName $skuSA

} elseif($sa_required -eq "n") {
    Write-Host "Moving on"
} else {
    Write-Host "Invalid entry, exiting"
    sleep -seconds 5
    exit 1
}

# Check is resource policy is required
$rp_required = Read-Host "Is a new resource policy rewuired?(y/n)"
if ($rp_required -eq "y") {

    # Get subsription ID
    $subID = Read-Host "Please enter the subsription ID in the format '/subscriptions/XXXXXXXXXXXXX'"

    # Get the path to allowed resource types .csv and check it exists
    $resources_Path = Read-Host "Enter the full path to the file with allowed resource types"
    $path = Test-Path $resources
    if ($path -eq $true){
        Write-Host "The file is there"
    } else {
        Write-Host "Cannot find the file, double check it exists and try again"
        exit 1
    }
    $path = $null


    #### Create and apply Policy Definition

    # Array of resource types
    $resources = Import-Csv $resources_Path
    $type = $resources.Allowed

    # Define policy
    $definition = New-AzureRmPolicyDefinition -Name "allowed-resourcetypes" -DisplayName "Allowed resource types" -description "This policy enables you to specify the resource types that your organization can deploy." -Policy 'C:\$Darragh\_Work\Netherlands\Interviews\Assignments\Sentia\resourceTypes.json' -Parameter 'C:\$Darragh\_Work\Netherlands\Interviews\Assignments\Sentia\listOfResourceTypesAllowed.json' -Mode All
    $definition

    # Apply policy passing in resource group, subscription ID, resource types
    $assignment = New-AzureRMPolicyAssignment -Name $nameRG -Scope $subID  -listOfResourceTypesAllowed $type -PolicyDefinition $definition
    $assignment

} elseif($rp_required -eq "n") {
    Write-Host "Done"
} else {
    Write-Host "Invalid entry, exiting"
    sleep -seconds 5
    exit 1
}
