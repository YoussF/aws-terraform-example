resource "aws_key_pair" "admin" {
    key_name    =   "admin"
    public_key  =   ""
}

resource "aws_instance" "server1" {
    ami             = "ami-045fa58af83eb0ff4"
    instance_type   = "t2.micro"
    key_name        = "admin"
 } 

