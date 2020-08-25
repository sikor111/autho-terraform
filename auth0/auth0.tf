variable "auth0_clients" {
  type = map(object({
    callbacks = list(string)
  }))
  default = {
   "test" = {
      callbacks = ["https://custom-callback.cosm"]
    }
  }
}

variable "auth0_apis" {
  type = map(object({
    identifier = string,
    signing_alg = string,
    scopes = list(object({
      value = string,
      description = string
    }))
    granted_apis = map(list(string))

  }))
  default = {
   "example resource server" = {
      identifier = "https://custom-callback.com"
      signing_alg = null
      scopes = [
        {
          value = "read:appointments",
          description = "allow to read"
        },
        {
          value = "write:appointments",
          description = "allow to read"
        }
       
      ]

      granted_apis = {
        "test" = ["aa","bb"]
      }
    }
  }
}

locals{
  client_grants = flatten([
    for apikey, api in var.auth0_apis :[
      for clientkey, client in api.granted_apis : {
        apikey = apikey
        clientkey = clientkey
        grants = client
      }
    ]
  ])
}


resource auth0_client "clients"{
    for_each = var.auth0_clients

    name = each.key
    callbacks = each.value.callbacks

}

resource auth0_resource_server "apis"{
    for_each = var.auth0_apis

    name = each.key
    identifier = each.value.identifier
    signing_alg = each.value.signing_alg

    dynamic "scopes" {
      for_each =  each.value.scopes
      content{
        value = scopes.value.value
        description = scopes.value.description
      }
    }
    

}


resource auth0_client_grant grants{
    for_each = {
      for a in local.client_grants : "${a.apikey}.${a.clientkey}" => a
    }

    client_id = auth0_client.clients[each.value.clientkey].client_id
    audience = auth0_resource_server.apis[each.value.apikey].identifier
    scope = each.value.grants
}