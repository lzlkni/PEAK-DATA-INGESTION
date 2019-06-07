/*

Terraform script for PEAK D&I environment provision

*/

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  version         = "1.15.0"
}

# Random passwords
resource "random_string" "win_admin_pwd" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#"
}

resource "random_string" "tab_admin_pwd" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#"
}

resource "random_string" "hdi_pwd" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#"
}

resource "random_string" "hdi_ssh_pwd" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!@#"
}


# Resource groups
resource "azurerm_resource_group" "di_gateway" {
  name     = "rg-${var.env}-${var.region}-${var.team}-gateway"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_network" {
  name     = "rg-${var.env}-${var.region}-${var.team}-network"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_storage" {
  name     = "rg-${var.env}-${var.region}-${var.team}-storage"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_tableau" {
  name     = "rg-${var.env}-${var.region}-${var.team}-tableau"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_monitoring" {
  name     = "rg-${var.env}-${var.region}-${var.team}-monitoring"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_keyvault" {
  name     = "rg-${var.env}-${var.region}-${var.team}-keyvault"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_analytics" {
  name     = "rg-${var.env}-${var.region}-${var.team}-analytics"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_recovery" {
  name     = "rg-${var.env}-${var.region}-${var.team}-recovery"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_resource_group" "di_event" {
  name     = "rg-${var.env}-${var.region}-${var.team}-event"
  location = "${var.location}"

  tags {
    environment = "${var.env}"
  }
}

# virtual network
resource "azurerm_virtual_network" "di" {
  name                = "vn-${var.env}-${var.region}-${var.team}"
  address_space       = ["${var.vn_addr_space}"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_network.name}"

  tags {
    environment = "${var.env}"
  }
}

# subnets
resource "azurerm_subnet" "di" {
  name                      = "sn-${var.env}-${var.region}-${var.team}"
  resource_group_name       = "${azurerm_resource_group.di_network.name}"
  virtual_network_name      = "${azurerm_virtual_network.di.name}"
  network_security_group_id = "${azurerm_network_security_group.di.id}"
  address_prefix            = "${var.subnet_ip_range_tableau}"
}

resource "azurerm_subnet" "di_gw" {
  name                 = "sn-${var.env}-${var.region}-${var.team}-appgw"
  resource_group_name  = "${azurerm_resource_group.di_network.name}"
  virtual_network_name = "${azurerm_virtual_network.di.name}"
  network_security_group_id = "${azurerm_network_security_group.di_gw.id}"
  address_prefix       = "${var.subnet_ip_range_gw}"
}

resource "azurerm_subnet" "di_hdi" {
  name                 = "sn-${var.env}-${var.region}-${var.team}-hdi"
  resource_group_name  = "${azurerm_resource_group.di_network.name}"
  virtual_network_name = "${azurerm_virtual_network.di.name}"
  network_security_group_id = "${azurerm_network_security_group.di_hdi.id}"
  address_prefix       = "${var.subnet_ip_range_hdi}"
}

# pubc ip for Tableau server VM (might not needed for production)
resource "azurerm_public_ip" "di_tableau" {
  name                         = "pip-${var.env}-${var.region}-${var.team}-tableau"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.di_network.name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.env}"
  }
}

# security groups
resource "azurerm_network_security_group" "di" {
  name                = "nsg-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_network.name}"

  security_rule {
    name                       = "AllowWinRmInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["5985","5986"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllRdpInBound"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowJumpHostInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "9443", "443", "8080","80"]
    source_address_prefix      = "${var.jump_host_ip}"
    destination_address_prefix = "${var.subnet_ip_range_tableau}"
  }


  security_rule {
    name                       = "AllowPlatFormInBound"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = ["123.242.248.130/32","210.0.232.132/32","109.133.201.77/32","27.110.77.254/32","27.110.79.204/32"]
    destination_address_prefix = "${var.subnet_ip_range_tableau}"
  }

  security_rule {
    name                       = "AllowVMBackupOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = "Storage.SoutheastAsia"
  }

  security_rule {
    name                       = "AllStorageOutbound"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = "Storage.EastAsia"
  }

  security_rule {
    name                       = "AllSqlOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_ranges    = ["3306", "1433", "11000-11999", "14000-14999"]
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = "Sql.EastAsia"
  }

  security_rule {
    name                       = "AllowKeyVaultOutbound443"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = "AzureKeyVault.EastAsia"
  }

    security_rule {
    name                       = "AllowKeyVaultOutbound80"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = "AzureKeyVault.EastAsia"
  }

  security_rule {
    name                       = "AllowAADOutbound"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_tableau}"
    destination_address_prefix = 	"AzureActiveDirectory"
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_network_security_group" "di_gw" {
  name                = "nsg-${var.env}-${var.region}-${var.project}-${var.team}-gw"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_network.name}"

  security_rule {
    name                       = "AllowInternetHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["203.112.87.220","203.112.82.2","203.112.82.1","203.112.87.138"]
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }

  security_rule {
    name                       = "AllowATMHttpsInbound"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureTrafficManager"
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }

  security_rule {
    name                       = "AllowAppGwHealthCheckInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "65503-65534"
    source_address_prefix      = "Internet"
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }

  security_rule {
    name                       = "AllowJumpHostInBound"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.jump_host_ip}"
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }
  # Remove AllowSubnetInBound is no need
  
  security_rule {
    name                       = "AllowLoadBalancerInBound"
    priority                   = 125
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }
  security_rule {
    name                       = "AllowPlatFormInBound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes  = ["123.242.248.130/32","210.0.232.132/32","109.133.201.77/32","27.110.77.254/32","27.110.79.204/32"]
    destination_address_prefix = "${var.subnet_ip_range_gw}"
  }

  security_rule {  
     name                       = "DenyVnetInbound"  
     priority                   = 1000  
     direction                  = "Inbound"  
     access                     = "Deny"  
     protocol                   = "*"  
     source_port_range          = "*"  
     destination_port_range     = "*"  
     source_address_prefix      = "VirtualNetwork"  
     destination_address_prefix = "VirtualNetwork"  
  } 
    # Remove rule 100 for FOSS concern

  security_rule {  
     name                       = "DenyAllInternatOutBound"  
     priority                   = 120  
     direction                  = "Outbound"  
     access                     = "Deny"     
     protocol                   = "*"  
     source_port_range          = "*"  
     destination_port_range     = "*"  
     source_address_prefix      = "*"  
     destination_address_prefix = "Internet"
  } 


  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_network_security_group" "di_hdi" {
  name                = "nsg-${var.env}-${var.region}-${var.project}-${var.team}-hdi"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_network.name}"

  # Revise to target to Subnet only for FOSS concern
  security_rule {
    name                       = "AllowMsHdiInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = ["168.61.49.99","23.99.5.239","168.61.48.131","138.91.141.162","23.102.235.122","52.175.38.134"]
    destination_address_prefix = "${var.subnet_ip_range_hdi}"
  }

  security_rule {
    name                       = "AllowAppGatewayInBound"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefix      = "${var.subnet_ip_range_gw}"
    destination_address_prefix = "${var.subnet_ip_range_hdi}"
  }

  security_rule {
    name                       = "AllowJumpHostInBound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${var.jump_host_ip}"
    destination_address_prefix = "${var.subnet_ip_range_hdi}"
  }

  security_rule {
    name                       = "AllowSubnetInBound"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "${var.subnet_ip_range_hdi}"
  }

  security_rule {
    name                       = "AllowPlatFormInBound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes  = ["123.242.248.130/32","210.0.232.132/32","109.133.201.77/32","27.110.77.254/32","27.110.79.204/32"]
    destination_address_prefix = "${var.subnet_ip_range_hdi}"
  }

    # Change source to subnet only
  security_rule {
    name                       = "AllStorageOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "Storage.EastAsia"
  }

  security_rule {
    name                       = "AllSqlOutbound"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_ranges    = ["3306", "1433", "11000-11999", "14000-14999"]
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "Sql.EastAsia"
  }
security_rule {
    name                       = "AllowKeyVaultOutbound443"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "AzureKeyVault.EastAsia"
  }

    security_rule {
    name                       = "AllowKeyVaultOutbound80"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "AzureKeyVault.EastAsia"
  }

  security_rule {
    name                       = "AllowAADOutbound"
    priority                   = 140
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "AzureActiveDirectory"
  }

  tags {
    environment = "${var.env}"
  }

    security_rule {
    name                       = "AllowLogAnalytics"
    priority                   = 150
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.subnet_ip_range_hdi}"
    destination_address_prefix = "AzureMonitor"
  }

  tags {
    environment = "${var.env}"
  }
}

# Network interface for Tableau server VM
resource "azurerm_network_interface" "di_tableau" {
  name                      = "nic-${var.env}-${var.region}-${var.team}-tableau"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.di_network.name}"

  ip_configuration {
    name                          = "ip-${var.env}-${var.region}-${var.team}-tableau"
    subnet_id                     = "${azurerm_subnet.di.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.di_tableau.id}"
  }

  tags {
    environment = "${var.env}"
  }
}

# managed disk for Tableau server VM
resource "azurerm_managed_disk" "di_tableau" {
  name                 = "md-${var.env}-${var.region}-${var.team}-tableau"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.di_tableau.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "100"
}

# avaliability set for Tableau server VM
resource "azurerm_availability_set" "di_tableau" {
  name                         = "as-${var.env}-${var.region}-${var.team}-tableau"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.di_tableau.name}"
  managed                      = "true"
  platform_update_domain_count = "1"
  platform_fault_domain_count  = "1"

  tags {
    environment = "${var.env}"
  }
}

# storage account
resource "azurerm_storage_account" "di" {
  name                     = "sacct${var.env}${var.region}${var.project}${var.team}"
  resource_group_name      = "${azurerm_resource_group.di_storage.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags {
    environment = "${var.env}"
  }
}

# log analytics
resource "azurerm_log_analytics_workspace" "di" {
  name                = "la-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "Southeast Asia"
  resource_group_name = "${azurerm_resource_group.di_monitoring.name}"
  sku                 = "Standard"
  retention_in_days   = 30

  tags {
    environment = "${var.env}"
  }
}

# log analytics solution
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "Containers"
  location              = "Southeast Asia"
  resource_group_name   = "${azurerm_resource_group.di_monitoring.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.di.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.di.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

# Tableau server VM
resource "azurerm_virtual_machine" "di_tableau" {
  name                  = "vm-${var.env}-${var.region}-${var.project}-${var.team}-tableau"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.di_tableau.name}"
  network_interface_ids = ["${azurerm_network_interface.di_tableau.id}"]
  vm_size               = "${var.tableau_vm_size}"
  availability_set_id   = "${azurerm_availability_set.di_tableau.id}"

  # configure OS image
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  # configure OS disk
  storage_os_disk {
    name              = "sod-${var.env}-${var.region}-${var.project}-${var.team}-tableau"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # configure OS profile
  os_profile {
    computer_name  = "${var.team}-tableau"
    admin_username = "${var.admin_user}"
    admin_password = "${random_string.win_admin_pwd.result}"
  }

# Remove disk as not required.

  # os windows config
  os_profile_windows_config {
    provision_vm_agent = "true"
  }

  tags {
    environment = "${var.env}"
  }
}

# recovery vault
resource "azurerm_recovery_services_vault" "di_vault" {
  name                = "rsv-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_recovery.name}"
  sku                 = "standard"
}

# backup policy
resource "azurerm_template_deployment" "recovery_backup_policy" {
  name                = "rbp-${var.env}-${var.region}-${var.project}-${var.team}-deployment"
  resource_group_name = "${azurerm_resource_group.di_recovery.name}"

  template_body = <<DEPLOY
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vaultName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Recovery Services Vault"
      }
    },
    "policyName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Backup Policy"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "eastasia",
      "metadata": {
        "description": "Location for all resources."
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.RecoveryServices/vaults",
      "apiVersion": "2015-11-10",
      "name": "[parameters('vaultName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "RS0",
        "tier": "Standard"
      },
      "properties": {}
    },
    {
      "apiVersion": "2016-06-01",
      "name": "[concat(parameters('vaultName'), '/', parameters('policyName'))]",
      "type": "Microsoft.RecoveryServices/vaults/backupPolicies",
      "dependsOn": [
        "[concat('Microsoft.RecoveryServices/vaults/', parameters('vaultName'))]"
      ],
      "location": "[parameters('location')]",
      "properties": {
        "backupManagementType": "AzureIaasVM",
        "schedulePolicy": {
          "scheduleRunFrequency": "Daily",
          "scheduleRunDays": null,
          "scheduleRunTimes": [ "04:30" ],
          "schedulePolicyType": "SimpleSchedulePolicy"
        },
        "retentionPolicy": {
          "dailySchedule": {
            "retentionTimes": [ "04:30" ],
            "retentionDuration": {
              "count": 30,
              "durationType": "Days"
            }
          },
          "retentionPolicyType": "LongTermRetentionPolicy"
        },
        "timeZone": "China Standard Time"
      }
    }
  ]
}
DEPLOY

  parameters {
    "vaultName"  = "${azurerm_recovery_services_vault.di_vault.name}"
    "policyName" = "HKT0430AM30Days"
    "location"   = "${var.location}"
  }

  deployment_mode = "Incremental"
  depends_on      = ["azurerm_recovery_services_vault.di_vault"]
}

# add the Tableau vm to recovery vault
resource "null_resource" "di_vault_tableau_vm" {
  provisioner "local-exec" {
    command = "sleep 30; az backup protection enable-for-vm --resource-group ${azurerm_resource_group.di_recovery.name} --vault-name ${azurerm_recovery_services_vault.di_vault.name} --vm $(az vm show -g ${azurerm_resource_group.di_tableau.name} -n ${azurerm_virtual_machine.di_tableau.name} --query id | sed 's/\"//g') --policy-name HKT0430AM30Days"
  }

  depends_on = ["azurerm_virtual_machine.di_tableau", "azurerm_template_deployment.recovery_backup_policy"]
}

# VM extension for Tableau server installation
resource "azurerm_virtual_machine_extension" "di_tableau" {
  name                 = "TableauInstallation"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.di_tableau.name}"
  virtual_machine_name = "${azurerm_virtual_machine.di_tableau.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {        
		"fileUris": ["${var.blob_uri}","${var.blob_uri_init}"],        
		"commandToExecute": "powershell.exe -ExecutionPolicy unrestricted -NoProfile -NonInteractive -File installtableau.ps1 -adminusr ${var.tab_admin_user} -adminpwd ${random_string.tab_admin_pwd.result} -license ${var.tableau_license} > tableauinstall.log"
	}
SETTINGS

  tags {
    environment = "${var.env}"
  }
}

# VM entension for log analytics
resource "azurerm_virtual_machine_extension" "di_tableau_log_analytics" {
  name                 = "MicrosoftMonitoringAgent"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.di_tableau.name}"
  virtual_machine_name = "${azurerm_virtual_machine.di_tableau.name}"
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"
  depends_on           = ["azurerm_virtual_machine_extension.di_tableau"]

  settings = <<SETTINGS
    { "workspaceId": "${azurerm_log_analytics_workspace.di.workspace_id}"	}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    { "workspaceKey": "${azurerm_log_analytics_workspace.di.primary_shared_key}" }
PROTECTED_SETTINGS

  tags {
    environment = "${var.env}"
  }
}

# public ip for application gateway
resource "azurerm_public_ip" "gw" {
  name                         = "pip-${var.env}-${var.region}-${var.team}-appgw"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.di_gateway.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${var.env}-${var.region}-${var.team}-tableau"

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_public_ip" "nifi" {
  name                         = "pip-${var.env}-${var.region}-${var.team}-nifigw"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.di_gateway.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${var.env}-${var.region}-${var.team}-nifi"

  tags {
    environment = "${var.env}"
  }
}

# application gateway for Tableau web server
resource "azurerm_application_gateway" "di_tableau" {
  name                = "ag-${var.env}-${var.region}-${var.team}-tableau"
  resource_group_name = "${azurerm_resource_group.di_gateway.name}"
  location            = "${var.location}"

  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gatewayPrivateIP"
    subnet_id = "${azurerm_subnet.di_gw.id}"
  }

  frontend_port {
    name = "httpsFrontendPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontendPublicIP"
    public_ip_address_id = "${azurerm_public_ip.gw.id}"
  }

  backend_address_pool {
    name            = "tableauBackendPool"
    ip_address_list = ["${azurerm_network_interface.di_tableau.private_ip_address}"]
  }

  backend_http_settings {
    name                       = "httpsBackendSetting"
    cookie_based_affinity      = "Disabled"
    port                       = 443
    protocol                   = "Https"
    request_timeout            = 14400
    authentication_certificate = [ { name = "tableauSslCertificate" } ]
  }

  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "frontendPublicIP"
    frontend_port_name             = "httpsFrontendPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGatewaySslCertificate"
  }

  request_routing_rule {
    name                       = "tableauRequestRouting"
    rule_type                  = "Basic"
    http_listener_name         = "httpsListener"
    backend_address_pool_name  = "tableauBackendPool"
    backend_http_settings_name = "httpsBackendSetting"
  }

  ssl_certificate {
    name     = "appGatewaySslCertificate"
    data     = "${base64encode(file("data/app-gateway-cert-${var.test_or_prod}.pfx"))}"
    password = "${var.app_gw_cert_pwd}"
  }

  authentication_certificate {
    name = "tableauSslCertificate"
    data = "${base64encode(file("data/tableau-cert-${var.test_or_prod}.cer"))}"
  }

  tags {
    environment = "${var.env}"
  }
}

# application gateway for nifi web server
resource "azurerm_application_gateway" "di_nifi" {
  name                = "ag-${var.env}-${var.region}-${var.team}-nifi"
  resource_group_name = "${azurerm_resource_group.di_gateway.name}"
  location            = "${var.location}"

  sku {
    name     = "Standard_Medium"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gatewayPrivateIP"
    subnet_id = "${azurerm_subnet.di_gw.id}"
  }

  frontend_port {
    name = "httpsFrontendPort"
    port = 443
  }

#   frontend_ip_configuration {
#     name                          = "frontendPrivateIP"
#     subnet_id                     = "${azurerm_subnet.di_gw.id}"
#     private_ip_address_allocation = "Dynamic"
#   }

  frontend_ip_configuration {
    name                 = "frontendPublicIP"
    public_ip_address_id = "${azurerm_public_ip.nifi.id}"
  }

  backend_address_pool {
    name = "nifiBackendPool"
  }

  backend_http_settings {
    name                       = "httpBackendSetting"
    cookie_based_affinity      = "Disabled"
    port                       = 9443
    protocol                   = "Https"
    request_timeout            = 20
  }

  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "frontendPublicIP"
    frontend_port_name             = "httpsFrontendPort"
    protocol                       = "Https"
    ssl_certificate_name           = "appGatewaySslCertificate"
  }

  request_routing_rule {
    name                       = "nifiRequestRouting"
    rule_type                  = "Basic"
    http_listener_name         = "httpsListener"
    backend_address_pool_name  = "nifiBackendPool"
    backend_http_settings_name = "httpBackendSetting"
  }

  ssl_certificate {
    name     = "appGatewaySslCertificate"
    data     = "${base64encode(file("data/app-gateway-cert-${var.test_or_prod}.pfx"))}"
    password = "${var.app_gw_cert_pwd}"
  }

  tags {
    environment = "${var.env}"
  }
}

# key vault
resource "azurerm_key_vault" "di" {
  name                = "kv-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_keyvault.name}"
  tenant_id           = "${var.tenant_id}"

  sku {
    name = "standard"
  }

  access_policy {
    tenant_id = "${var.tenant_id}"
    object_id = "${var.object_id}"

    key_permissions = [
      "get",
      "list",
      "update",
      "create",
      "import",
      "get",
      "delete",
      "recover",
      "backup",
      "restore",
    ]

    secret_permissions = [
      "get",
      "list",
      "set",
      "get",
      "delete",
      "recover",
      "backup",
      "restore",
    ]
  }

  tags {
    environment = "${var.env}"
  }
}

# Set the secrets into the key vault
resource "null_resource" "di_secret_win_admin_user" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name win-admin-user --value '${var.admin_user}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_win_admin_pwd" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name win-admin-pwd --value '${random_string.win_admin_pwd.result}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_tab_admin_user" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name tab-admin-user --value '${var.tab_admin_user}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_tab_admin_pwd" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name tab-admin-pwd --value '${random_string.tab_admin_pwd.result}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_hdi_user" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name hdi-user --value '${var.hdi_user}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_hdi_pwd" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name hdi-pwd --value '${random_string.hdi_pwd.result}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}

resource "null_resource" "di_secret_hdi_ssh_user" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name hdi-ssh-user --value '${var.hdi_ssh_user}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}


resource "null_resource" "di_secret_hdi_ssh_pwd" {
  provisioner "local-exec" {
    command = "az keyvault secret set --vault-name ${azurerm_key_vault.di.name} --name hdi-ssh-pwd --value '${random_string.hdi_ssh_pwd.result}'"
  }

  depends_on = ["azurerm_key_vault.di"]
}
# Create AAD Application for NiFi
resource "azurerm_azuread_application" "nifi" {
  name                       = "adapp-nifi-${var.env}-${var.project}-${var.team}"
  homepage                   = "https://${azurerm_public_ip.nifi.domain_name_label}.eastasia.cloudapp.azure.com/nifi" 
  reply_urls                 = ["https://${azurerm_public_ip.nifi.domain_name_label}.eastasia.cloudapp.azure.com/nifi-api/access/oidc/callback"]  
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
}

# HDInsight for Spark and NIFI
resource "azurerm_template_deployment" "hdi_spark_nifi" {
  name                = "hdi-${var.env}-${var.region}-${var.project}-${var.team}-deployment"
  resource_group_name = "${azurerm_resource_group.di_analytics.name}"
  depends_on          = [ "azurerm_storage_account.di" ]

  template_body = <<DEPLOY
  {
    "$schema": "http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
    "contentVersion": "0.9.0.0",
    "parameters": {
        "clusterName": {
            "type": "string",
            "metadata": {
                "description": "The name of the HDInsight cluster to create."
            }
        },
        "clusterLoginUserName": {
            "type": "string",
            "defaultValue": "hdiadmin",
            "metadata": {
                "description": "These credentials can be used to submit jobs to the cluster and to log into cluster dashboards."
            }
        },
        "clusterLoginPassword": {
            "type": "securestring",
            "metadata": {
                "description": "The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
        },
        "location": {
            "type": "string",
            "defaultValue": "eastasia",
            "metadata": {
                "description": "The location where all azure resources will be deployed."
            }
        },
        "clusterVersion": {
            "type": "string",
            "defaultValue": "3.6",
            "metadata": {
                "description": "HDInsight cluster version."
            }
        },
        "clusterKind": {
            "type": "string",
            "defaultValue": "SPARK",
            "metadata": {
                "description": "The type of the HDInsight cluster to create."
            }
        },
        "sshUserName": {
            "type": "string",
            "defaultValue": "hdisshuser",
            "metadata": {
                "description": "These credentials can be used to remotely access the cluster."
            }
        },
        "sshPassword": {
            "type": "securestring",
            "metadata": {
                "description": "The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
        },
        "storageAcctName": {
          "type": "string",
          "metadata": {
                "description": "The linked storage account name."
            }
        },
        "storageAcctKey": {
          "type": "string",
          "metadata": {
                "description": "The linked storage account key."
            }
        },
        "VNetID": {
          "type": "string",
          "metadata": {
                "description": "The VNet ID."
            }
        },
        "subnetID": {
          "type": "string",
          "metadata": {
                "description": "The Subnet ID."
            }
        },
        "nifiInstallerUrl": {
            "type": "string",
            "defaultValue": "https://peakdiautomation.blob.core.windows.net/nifi/nifi-1.6-installer-v03.sh",
            "metadata": {
                "description": "The URL for the Apache Nifi installer script."
            }
        },
        "pyLibInstallerUrl": {
            "type": "string",
            "defaultValue": "https://peakdiautomation.blob.core.windows.net/nifi/3rd-party-python-lib-v01.sh",
            "metadata": {
                "description": "The URL for the third party Python libararies."
            }
        },
        "headNodeSize": {
            "type": "string",
            "defaultValue": "Standard_D12_V2",
            "metadata": {
                "description": "The head node VM size."
            }
        },
        "headNodeCount": {
            "type": "string",
            "defaultValue": "2",
            "metadata": {
                "description": "Number of head nodes."
            }
        },
        "workerNodeSize": {
            "type": "string",
            "defaultValue": "Standard_D13_V2",
            "metadata": {
                "description": "The worker node VM size."
            }
        },
        "workerNodeCount": {
            "type": "string",
            "defaultValue": "2",
            "metadata": {
                "description": "Number of worker nodes."
            }
            }
    },
    "resources": [
        {
            "apiVersion": "2015-03-01-preview",
            "name": "[parameters('clusterName')]",
            "type": "Microsoft.HDInsight/clusters",
            "location": "[parameters('location')]",
            "dependsOn": [],
            "properties": {
                "clusterVersion": "[parameters('clusterVersion')]",
                "osType": "Linux",
                "tier": "standard",
                "clusterDefinition": {
                    "kind": "[parameters('clusterKind')]",
                    "componentVersion": {
                        "Spark": "2.3"
                    },
                    "configurations": {
                        "gateway": {
                            "restAuthCredential.isEnabled": true,
                            "restAuthCredential.username": "[parameters('clusterLoginUserName')]",
                            "restAuthCredential.password": "[parameters('clusterLoginPassword')]"
                        }
                    }
                },
                "storageProfile": {
                    "storageaccounts": [
                        {
                            "name": "[concat(parameters('storageAcctName'),'.blob.core.windows.net')]",
                            "isDefault": true,
                            "container": "[parameters('clusterName')]",
                            "key": "[parameters('storageAcctKey')]"
                        }
                    ]
                },
                "computeProfile": {
                    "roles": [
                        {
                            "name": "headnode",
                            "minInstanceCount": 1,
                            "targetInstanceCount": "[parameters('headNodeCount')]",
                            "hardwareProfile": {
                                "vmSize": "[parameters('headNodeSize')]"
                            },
                            "osProfile": {
                                "linuxOperatingSystemProfile": {
                                    "username": "[parameters('sshUserName')]",
                                    "password": "[parameters('sshPassword')]"
                                }
                            },
                            "virtualNetworkProfile": {
                                "id": "[parameters('VNetID')]",
                                "subnet": "[parameters('subnetID')]"
                            }
                        },
                        {
                            "name": "workernode",
                            "minInstanceCount": 1,
                            "targetInstanceCount": "[parameters('workerNodeCount')]",
                            "hardwareProfile": {
                                "vmSize": "[parameters('workerNodeSize')]"
                            },
                            "osProfile": {
                                "linuxOperatingSystemProfile": {
                                    "username": "[parameters('sshUserName')]",
                                    "password": "[parameters('sshPassword')]"
                                }
                            },
                            "virtualNetworkProfile": {
                                "id": "[parameters('VNetID')]",
                                "subnet": "[parameters('subnetID')]"
                            }

                        }
                    ]
                }
            }
        }
    ],
    "outputs": {
      "cluster": {
        "type": "object",
        "value": "[reference(resourceId('Microsoft.HDInsight/clusters',parameters('clusterName')))]"
      }
    }
  }
DEPLOY

  parameters {
    "clusterName"          = "hdi-${var.env}-${var.region}-${var.project}-${var.team}"
    "location"             = "${var.location}"
    "clusterLoginUserName" = "${var.hdi_user}"
    "clusterLoginPassword" = "${random_string.hdi_pwd.result}"
    "sshUserName"          = "${var.hdi_ssh_user}"
    "sshPassword"          = "${random_string.hdi_ssh_pwd.result}"
    "storageAcctName"      = "${azurerm_storage_account.di.name}"
    "storageAcctKey"       = "${azurerm_storage_account.di.primary_access_key}"
    "VNetID"               = "${azurerm_virtual_network.di.id}"
    "subnetID"             = "${azurerm_subnet.di_hdi.id}"
    "nifiInstallerUrl"     = "${var.nifi_installer_url}"
    "pyLibInstallerUrl"    = "${var.py_lib_installer_url}"
    "headNodeSize"         = "${var.head_node_size}"
    "headNodeCount"        = "${var.head_node_count}"
    "workerNodeSize"       = "${var.worker_node_size}"
    "workerNodeCount"      = "${var.worker_node_count}"
  }

  deployment_mode = "Incremental"
}

# EventHub
resource "null_resource" "di_storage_container_ehub" {
  provisioner "local-exec" {
    command = "az storage container create --name ${var.ehub_storage_container} --account-name ${azurerm_storage_account.di.name} --public-access off"
  }

  depends_on = ["azurerm_storage_account.di"]
}

resource "azurerm_template_deployment" "event_hub" {
  name                = "ehub-${var.env}-${var.region}-${var.project}-${var.team}-deployment"
  resource_group_name = "${azurerm_resource_group.di_event.name}"
  depends_on          = ["null_resource.di_storage_container_ehub"]

  template_body = <<DEPLOY
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "eventhubsNamespace": {
            "type": "String"
        },
        "eventhubsName": {
            "type": "String"
        },
        "AuthorizationRules_RootManageSharedAccessKey_name": {
            "defaultValue": "RootManageSharedAccessKey",
            "type": "String"
        },
        "consumergroups_$Default_name": {
            "defaultValue": "$Default",
            "type": "String"
        },
        "storageAccountResourceId": {
            "type": "String"
        },
        "storageContainerName": {
            "type": "String"
        },
        "messageRetentionInDays": {
            "type": "String"
        },
        "partitionCount": {
            "type": "String"
        },
        "intervalInSeconds": {
            "type": "String"
        },
        "location": {
          "type": "string",
          "defaultValue": "Southeast Asia",
          "metadata": {
            "description": "Location for all resources."
          }
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.EventHub/namespaces",
            "sku": {
                "name": "Standard",
                "tier": "Standard",
                "capacity": 5
            },
            "name": "[parameters('eventhubsNamespace')]",
            "apiVersion": "2017-04-01",
            "location": "[parameters('location')]",
            "tags": {},
            "scale": null,
            "properties": {
                "isAutoInflateEnabled": true,
                "maximumThroughputUnits": 20
            },
            "dependsOn": []
        },
        {
            "type": "Microsoft.EventHub/namespaces/AuthorizationRules",
            "name": "[concat(parameters('eventhubsNamespace'), '/', parameters('AuthorizationRules_RootManageSharedAccessKey_name'))]",
            "apiVersion": "2017-04-01",
            "location": "[parameters('location')]",
            "scale": null,
            "properties": {
                "rights": [
                    "Listen",
                    "Manage",
                    "Send"
                ]
            },
            "dependsOn": [
                "[resourceId('Microsoft.EventHub/namespaces', parameters('eventhubsNamespace'))]"
            ]
        },
        {
            "type": "Microsoft.EventHub/namespaces/eventhubs",
            "name": "[concat(parameters('eventhubsNamespace'), '/', parameters('eventhubsName'))]",
            "apiVersion": "2017-04-01",
            "location": "[parameters('location')]",
            "scale": null,
            "properties": {
                "messageRetentionInDays": "[parameters('messageRetentionInDays')]",
                "partitionCount": "[parameters('partitionCount')]",
                "status": "Active",
                "captureDescription": {
                    "enabled": true,
                    "encoding": "Avro",
                    "destination": {
                        "name": "EventHubArchive.AzureBlockBlob",
                        "properties": {
                            "storageAccountResourceId": "[parameters('storageAccountResourceId')]",
                            "blobContainer": "[parameters('storageContainerName')]",
                            "archiveNameFormat": "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
                        }
                    },
                    "intervalInSeconds": "[parameters('intervalInSeconds')]",
                    "sizeLimitInBytes": 314572800
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.EventHub/namespaces', parameters('eventhubsNamespace'))]"
            ]
        },
        {
            "type": "Microsoft.EventHub/namespaces/eventhubs/consumergroups",
            "name": "[concat(parameters('eventhubsNamespace'), '/', parameters('eventhubsName'), '/', parameters('consumergroups_$Default_name'))]",
            "apiVersion": "2017-04-01",
            "location": "[parameters('location')]",
            "scale": null,
            "properties": {},
            "dependsOn": [
                "[resourceId('Microsoft.EventHub/namespaces', parameters('eventhubsNamespace'))]",
                "[resourceId('Microsoft.EventHub/namespaces/eventhubs', parameters('eventhubsNamespace'), parameters('eventhubsName'))]"
            ]
        }
    ]
}
DEPLOY

  parameters {
    "eventhubsNamespace"          = "ehubns-${var.env}-${var.region}-${var.project}-${var.team}"
    "eventhubsName"               = "ehub-${var.env}-${var.region}-${var.project}-${var.team}"
    "storageContainerName"        = "${var.ehub_storage_container}"
    "storageAccountResourceId"    = "${azurerm_storage_account.di.id}"
    "messageRetentionInDays"      = "${var.ehub_message_retention_in_days}"
    "partitionCount"              = "${var.ehub_partition_count}"
    "intervalInSeconds"           = "${var.ehub_interval_in_seconds}"
  }

  deployment_mode = "Incremental"
}

# Container for the NIFI jobs
resource "null_resource" "di_storage_container_batches" {
  provisioner "local-exec" {
    command = "az storage container create --name peak-di-batches --account-name ${azurerm_storage_account.di.name} --public-access off"
  }

  depends_on = ["azurerm_storage_account.di"]
}

resource "null_resource" "di_storage_container_events" {
  provisioner "local-exec" {
    command = "az storage container create --name peak-di-events --account-name ${azurerm_storage_account.di.name} --public-access off"
  }

  depends_on = ["azurerm_storage_account.di"]
}

# Traffic Manager
resource "azurerm_resource_group" "di_traffic_manager" {
  name     = "rg-${var.env}-global-${var.team}"
  location = "${var.location}"
}
resource "azurerm_traffic_manager_profile" "di_tm_profile" {
  name                = "tableaupaymebiz"
  resource_group_name = "${azurerm_resource_group.di_traffic_manager.name}"

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "tableau.paymebiz"
    ttl           = 100
  }

  monitor_config {
    protocol = "https"
    port     = 443
    path     = "/"
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_traffic_manager_endpoint" "di_tm_hk_endpoint" {
  name                = "ep-${var.env}-${var.region}-${var.team}"
  resource_group_name = "${azurerm_resource_group.di_traffic_manager.name}"
  profile_name        = "${azurerm_traffic_manager_profile.di_tm_profile.name}"
  target_resource_id  = "${azurerm_public_ip.gw.id}"
  type                = "azureEndpoints"
  weight              = 1
}