/*

Terraform script for PEAK D&I environment provision

*/

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  version         = "1.7.0"
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

# public ip for Tableau server VM (might not needed for production)
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


# avaliability set for Tableau server VM
# Setup advance for failover testing
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

# recovery vault
resource "azurerm_recovery_services_vault" "di_vault" {
  name                = "rsv-${var.env}-${var.region}-${var.project}-${var.team}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.di_recovery.name}"
  sku                 = "standard"
}

resource "azurerm_traffic_manager_endpoint" "di_tm_sg_endpoint" {
  name                = "ep-${var.env}-${var.region}-${var.team}"
  resource_group_name = "rg-${var.env}-global-${var.team}"
  profile_name        = "tm-${var.env}-global-${var.team}"
  target_resource_id  = "${azurerm_public_ip.gw.id}"
  type                = "azureEndpoints"
  weight              = 2
}