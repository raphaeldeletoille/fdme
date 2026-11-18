variable "prenom" {
  type    = string
  default = "raphael"
}

variable "all_storage" { 
    type = map(object({
        access_tier = optional(string, "Cool")
    }))
    default = {
        sto03 = {
            name = "random01"
        },
        sto02 = {
          access_tier = "Hot"
          name = "random02"
        }
    }
}


variable "all_containers" { 
    type = map(object({
        name = string
    }))
    default = {
        container01 = {
            name = "raphcontainer01"
        },
        container02 = {
            name = "raphcontainer02"
        }
    }
}