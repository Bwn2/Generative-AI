walker init {
    std.log("Hello from init");
}

walker server {
    has port = 8080;
    has host = "0.0.0.0";
    with entry {
        std.log("Server starting on " + self.host + ":" + str(self.port));
        yield;
    }
}