# logpusher

A command line tool to import logfiles into a database. New loglines in the file
are constantly added.


    $ logpusher -s sqlite -f /logs/access.logs -r "(?<time>\d{10}) (?<server_name>\w+)" -d "test.db" -t access_logs 


The regex with named capturing groups determines the data that should be extracted from the logline.
Each group represents a column in the target table.

### Database support

#### SQLite

    $ logpusher -s sqlite [OPTIONS]
        -f, --file <file>                Set the path of the logfile to import
        -r, --regex <REGEX>              Set the regex
        -c, --connections <num>          Set the number of concurrent connections
            --batch_size <num>           Set the batch size
        -d, --database <db>              Select a database
        -t, --table <tbl>                Select a destination table
        -q, --quiet                      Run quietly
        -?, --help                       Display this help text and exit


    $ logpusher -s sqlite -f /logs/access.logs -r "(?<time>\d{10}) (?<server_name>\w+)" -d "test.db" -t access_logs

Imports the `time` and `server_name` from the logfile into the table access_logs

#### EventQL

    $ logpusher -s eventql [OPTIONS]
        -f, --file <file>                Set the path of the logfile to import
        -r, --regex <REGEX>              Set the regex
        -c, --connections <num>          Set the number of concurrent connections
            --batch_size <num>           Set the batch size
        -d, --database <db>              Select a database
        -t, --table <tbl>                Select a destination table
        -h, --host <hostname>            Set the hostname of the storage engine
        -p, --port <port>                Set the port of the storage engine
        -q, --quiet                      Run quietly
        -?, --help                       Display this help text and exit


    $ regex="(?<time>\d+) (?<server_name>\w+) (?<http_method>\w+) (?<path>.+)"
    $ logpusher -f logs.access_logs -r $regex -t access_logs -h localhost -p 10001 -d dev

Connects to the EventQL client on localhost:10001 and imports the logfile into the table access_logs

