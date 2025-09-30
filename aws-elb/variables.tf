variable "server_port" {
    description    = "The port of the server will use for HTTP requests
    type           = number
    default        = 8080
}

variable "elb_port" {
    description    = The port ELB will use for the HTTP requests"
    type           = number
    default        = 80
}