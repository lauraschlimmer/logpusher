# logpusher

A command line tool to import logfiles into a database. New loglines in the file
are constantly added.

To specify which parts of the logline should be extracted and imported into the target table, simply define a REGEX with named capturing groups.
Each group in the REGEX represents a column in the target table.

### Usage

    $ logpusher [OPTIONS]
        -f, --file <file>                Set the path of the logfile to import
        -r, --regex <REGEX>              Set the regex
        -s, --storage <engine>           Set the storage engine
        -c, --connections <num>          Set the number of concurrent connections
            --batch_size <num>           Set the batch size
        -d, --database <db>              Select a database
        -t, --table <tbl>                Select a destination table
        -h, --host <hostname>            Set the hostname of the storage engine
        -p, --port <port>                Set the port of the storage engine
        -q, --quiet                      Run quietly
        -?, --help                       Display this help text and exit


Note that some options may vary depending on the storage engine/database system being used

### Database support

#### SQLite

Example: Import `time` and `server_name` from the logfile into the table access_logs

    $ logpusher -s sqlite -f /logs/access.logs -r "(?<time>\d{10}) (?<server_name>\w+)" -d "test.db" -t access_logs


#### MongoDB

Example: Connect to MongoDB on 127.0.0.1:27017 and import the logfile into the collection access_logs

    $ logpusher -s mongo -f /tmp/logs -r $regex -t access_logs -d "test" -h "127.0.0.1" -p "27017"


#### EventQL

Example: Connect to the EventQL client on localhost:10001 and import the logfile into the table access_logs

    $ regex="(?<time>\d+) (?<server_name>\w+) (?<http_method>\w+) (?<path>.+)"
    $ logpusher -f logs.access_logs -r $regex -t access_logs -h localhost -p 10001 -d dev


