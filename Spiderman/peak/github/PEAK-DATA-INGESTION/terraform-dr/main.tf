/*

Terraform script for PEAK D&I environment provision

*/

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  version         = "1.7.0"
}

#storage account
resource "azurerm_storage_account" "di" {
  name                     = "sacct${var.env}${var.region}${var.project}${var.team}"
  resource_group_name      = "rg-${var.env}-${var.region}-${var.team}-storage"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags {
    environment = "${var.env}"
  }
}


# avaliability set for Tableau server VM
resource "azurerm_availability_set" "di_tableau" {
  name                         = "as-${var.env}-${var.region}-${var.team}-tableau"
  location                     = "${var.location}"
  resource_group_name          = "rg-${var.env}-${var.region}-${var.team}-tableau"
  managed                      = "true"
  platform_update_domain_count = "1"
  platform_fault_domain_count  = "1"

  tags {
    environment = "${var.env}"
  }
}
 data "azurerm_virtual_network" "di"{
     name="vn-${var.env}-${var.region}-${var.team}"
     resource_group_name="rg-${var.env}-${var.region}-${var.team}-network"
 }
data "azurerm_subnet" "di_hdi" {
  name                 = "sn-${var.env}-${var.region}-${var.team}-hdi"
  virtual_network_name = "${data.azurerm_virtual_network.di.name}"
  resource_group_name  = "rg-${var.env}-${var.region}-${var.team}-network"
}

data "azurerm_subnet" "di" {
  name                 = "sn-${var.env}-${var.region}-${var.team}"
  virtual_network_name = "${data.azurerm_virtual_network.di.name}"
  resource_group_name  = "rg-${var.env}-${var.region}-${var.team}-network"
}

# data "azurerm_storage_account" "di" {
#   name                     = "sacct${var.env}hk${var.project}${var.team}"
#   resource_group_name      = "rg-${var.env}-hk-${var.team}-storage"

# }
data "azurerm_key_vault_secret" "hdi_pwd" {
  name      = "hdi-pwd"
  vault_uri = "https://kv-${var.env}-hk-${var.project}-${var.team}.vault.azure.net/"
}
data "azurerm_key_vault_secret" "hdi_ssh_pwd" {
  name      = "hdi-ssh-pwd"
  vault_uri = "https://kv-${var.env}-hk-${var.project}-${var.team}.vault.azure.net/"
}

data "azurerm_key_vault_secret" "win_admin_pwd" {
  name      = "win-admin-pwd"
  vault_uri = "https://kv-${var.env}-hk-${var.project}-${var.team}.vault.azure.net/"
}


data "azurerm_key_vault_secret" "tab_admin_pwd" {
  name      = "tab-admin-pwd"
  vault_uri = "https://kv-${var.env}-hk-${var.project}-${var.team}.vault.azure.net/"
}



# log analytics
resource "azurerm_log_analytics_workspace" "di" {
  name                = "la-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "Southeast Asia"
  resource_group_name = "rg-${var.env}-${var.region}-${var.team}-monitoring"
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
  resource_group_name   = "rg-${var.env}-${var.region}-${var.team}-monitoring"
  workspace_resource_id = "${azurerm_log_analytics_workspace.di.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.di.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

# HDInsight for Spark and NIFI
resource "azurerm_template_deployment" "hdi_spark_nifi" {
  name                = "hdi-${var.env}-${var.region}-${var.project}-${var.team}-deployment"
  resource_group_name = "rg-${var.env}-${var.region}-${var.team}-analytics"
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
    "clusterLoginPassword" = "${data.azurerm_key_vault_secret.hdi_pwd.value}"
    "sshUserName"          = "${var.hdi_ssh_user}"
    "sshPassword"          = "${data.azurerm_key_vault_secret.hdi_ssh_pwd.value}"
    "storageAcctName"      = "${azurerm_storage_account.di.name}"
    "storageAcctKey"       = "${azurerm_storage_account.di.primary_access_key}"
    "VNetID"               = "${data.azurerm_virtual_network.di.id}"
    "subnetID"             = "${data.azurerm_subnet.di_hdi.id}"
    "nifiInstallerUrl"     = "${var.nifi_installer_url}"
    "pyLibInstallerUrl"    = "${var.py_lib_installer_url}"
    "headNodeSize"         = "${var.head_node_size}"
    "headNodeCount"        = "${var.head_node_count}"
    "workerNodeSize"       = "${var.worker_node_size}"
    "workerNodeCount"      = "${var.worker_node_count}"
  }

  deployment_mode = "Incremental"
}

resource "azurerm_public_ip" "di_tableau" {
  name                         = "pip-${var.env}-${var.region}-${var.team}-tableau"
  location                     = "${var.location}"
  resource_group_name          = "rg-${var.env}-${var.region}-${var.team}-network"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.env}"
  }
}

# Network interface for Tableau server VM
resource "azurerm_network_interface" "di_tableau" {
  name                      = "nic-${var.env}-${var.region}-${var.team}-tableau"
  location                  = "${var.location}"
  resource_group_name       = "rg-${var.env}-${var.region}-${var.team}-network"

  ip_configuration {
    name                          = "ip-${var.env}-${var.region}-${var.team}-tableau"
    subnet_id                     = "${data.azurerm_subnet.di.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.di_tableau.id}"
  }

  tags {
    environment = "${var.env}"
  }
}

resource "azurerm_virtual_machine" "di_tableau" {
  name                  = "vm-${var.env}-${var.region}-${var.project}-${var.team}-tableau"
  location              = "${var.location}"
  resource_group_name   = "rg-${var.env}-${var.region}-${var.team}-tableau"
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
    admin_password = "${data.azurerm_key_vault_secret.win_admin_pwd.value}"
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
resource "azurerm_virtual_machine_extension" "di_tableau" {
  name                 = "TableauInstallation"
  location             = "${var.location}"
  resource_group_name  = "rg-${var.env}-${var.region}-${var.team}-tableau"
  virtual_machine_name = "${azurerm_virtual_machine.di_tableau.name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {        
		"fileUris": ["${var.blob_uri}"],        
		"commandToExecute": "powershell.exe -ExecutionPolicy unrestricted -NoProfile -NonInteractive -File installtableau.ps1 -adminusr ${var.tab_admin_user} -adminpwd ${data.azurerm_key_vault_secret.tab_admin_pwd.value} -license ${var.tableau_license} > tableauinstall.log"
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
  resource_group_name  = "rg-${var.env}-${var.region}-${var.team}-tableau"
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
