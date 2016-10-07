# logpusher

A command line tool to import logfiles into a database. New loglines in the file
are constantly added.


    $ logpusher -f logs/access.logs -r "(?<time>\d{10}) (?<server_name>\w+)" -t access.logs -h localhost -p 10001


The pattern of the logline is indicated by a regex with named capturing groups.
Each group represents a column in the target table.

###Database support
EventQL

### Usage
    $ logpusher [OPTIONS]

        -f, --file filename              Set the logfile to import
        -r, --regex regex                The Regex of the logline
        -t, --table table                Set the table name
        -h, --host hostname              Set the hostname
        -p, --port port                  Set the port
        -u, --user username              Set the username
            --password password          Set the password
        -d, --database db                Set the database
            --auth_token auth_token      Set the auth token
        -v, --[no-]verbose               Run verbosely
            --help                       help


### Example
In our example we want to upload a simple logfile that records time, server name,
HTTP method and path for each access to our EventQL database.

Logfile

    1475682457 fr01 GET /
    1475682458 fr05 POST /account/new
    1475682461 fr01 GET /
    1475682459 fr03 GET /products
    1475682460 fr02 GET /about
    1475682460 fr02 GET /images/about.png

The regex for our logfile is

    (?<time>\d+) (?<server_name>\w+) (?<http_method>\w+) (?<path>\w+)

Now we can upload the logfile to our table access_logs

    regex="(?<time>\d+) (?<server_name>\w+) (?<http_method>\w+) (?<path>.+)"
    logpusher -f logs.access_logs -r $regex -t access_logs -h localhost -p 10001 -d dev
