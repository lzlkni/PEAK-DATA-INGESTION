variable "subscription_id" {
  description = "SubscriptionID"
}

variable "location" {
  description = "Location of resources"
  default     = "Southeast Asia"
}

variable "env" {
  description = "The tag of resource"
  default     = "sit"
}

variable "region" {
  description = "region"
  default     = "sg"
}

variable "project" {
  description = "project name"
  default     = "peak"
}

variable "team" {
  description = "team in project"
  default     = "di"
}

variable "blob_uri" {
  description = "tableau installation powershell blob uri"
  default     = "https://peakdiautomation.blob.core.windows.net/tableau/installtableau.ps1"
}

variable "nifi_installer_url" {
  description = "The URL for the Apache Nifi installer script."
  default     = "https://peakdiautomation.blob.core.windows.net/nifi/nifi-1.6-installer-v03.sh"
}

variable "py_lib_installer_url" {
  description = "The URL for the third party Python libararies."
  default     = "https://peakdiautomation.blob.core.windows.net/nifi/3rd-party-python-lib-v01.sh"
}

variable "head_node_size" {
  description = "The head node VM size."
  default     = "Standard_D12_V2"
}

variable "head_node_count" {
  description = "Number of head nodes."
  default     = "2"
}

variable "worker_node_size" {
  description = "The worker node VM size."
  default     = "Standard_D13_V2"
}

variable "worker_node_count" {
  description = "Number of worker nodes."
  default     = "2"
}


variable "hdi_user" {
  description = "The user name for HDInsight"
  default     = "hdiadmin"
}

variable "hdi_ssh_user" {
  description = "The SSH user name for HDInsight"
  default     = "hdisshuser"
}
variable "tableau_vm_size" {
  default = "Standard_DS13_v2"
  description = "The size of the Tableau server VM"
}

variable "admin_user" {
  description = "Administrator of the new vm"
  default     = "winadmin"
}

variable "tab_admin_user" {
  description = "Administrator of tableau"
  default     = "tabadmin"
}variable "tableau_license" {
  description = "The Tableau license key"
}

